"use strict";

const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const Stripe = require("stripe");

const {
  authenticatedUid,
  verifiedCustomerUid,
} = require("./auth_policy");

initializeApp();

const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");
const db = getFirestore();

async function deleteQueryInBatches(query) {
  while (true) {
    const snapshot = await query.limit(400).get();
    if (snapshot.empty) return;

    const batch = db.batch();
    snapshot.docs.forEach((document) => batch.delete(document.ref));
    await batch.commit();

    if (snapshot.size < 400) return;
  }
}

function validatedAmount(value) {
  if (!Number.isInteger(value) || value < 50 || value > 100000) {
    throw new HttpsError("invalid-argument", "The payment amount is invalid.");
  }
  return value;
}

exports.createPaymentIntent = onCall(
  {secrets: [stripeSecretKey]},
  async (request) => {
    const uid = verifiedCustomerUid(request);
    const amount = validatedAmount(request.data && request.data.amount);
    const currency = String(request.data && request.data.currency || "usd").toLowerCase();
    const fulfillment = String(request.data && request.data.fulfillmentMethod || "delivery");
    const idempotencyKey = String(request.data && request.data.idempotencyKey || "");

    if (currency !== "usd") {
      throw new HttpsError("invalid-argument", "Only USD payments are supported.");
    }
    if (fulfillment !== "delivery" && fulfillment !== "pickup") {
      throw new HttpsError("invalid-argument", "The fulfillment method is invalid.");
    }
    if (!/^[A-Za-z0-9_-]{16,120}$/.test(idempotencyKey)) {
      throw new HttpsError("invalid-argument", "The payment request is invalid.");
    }

    const stripe = new Stripe(stripeSecretKey.value());
    try {
      const intent = await stripe.paymentIntents.create(
        {
          amount,
          currency,
          payment_method_types: ["card"],
          metadata: {
            firebaseUid: uid,
            fulfillmentMethod: fulfillment,
            app: "hungry_spot",
          },
        },
        {idempotencyKey: `${uid}_${idempotencyKey}`},
      );

      return {
        paymentIntentClientSecret: intent.client_secret,
        paymentIntentId: intent.id,
      };
    } catch (error) {
      console.error("Unable to create Stripe PaymentIntent", error);
      throw new HttpsError("internal", "The secure payment could not be started.");
    }
  },
);

exports.verifyPaymentIntent = onCall(
  {secrets: [stripeSecretKey]},
  async (request) => {
    const uid = verifiedCustomerUid(request);
    const paymentIntentId = String(request.data && request.data.paymentIntentId || "");
    if (!/^pi_[A-Za-z0-9_]+$/.test(paymentIntentId)) {
      throw new HttpsError("invalid-argument", "The payment reference is invalid.");
    }

    const stripe = new Stripe(stripeSecretKey.value());
    try {
      const intent = await stripe.paymentIntents.retrieve(paymentIntentId);
      if (intent.metadata.firebaseUid !== uid) {
        throw new HttpsError("permission-denied", "This payment belongs to another customer.");
      }
      if (intent.status !== "succeeded") {
        throw new HttpsError("failed-precondition", "The card payment is not complete.");
      }

      await db.collection("stripePayments").doc(intent.id).set({
        customerId: uid,
        amountCents: intent.amount_received || intent.amount,
        currency: intent.currency,
        fulfillmentMethod: intent.metadata.fulfillmentMethod,
        status: intent.status,
        verifiedAt: FieldValue.serverTimestamp(),
      }, {merge: true});

      return {
        status: intent.status,
        amountCents: intent.amount_received || intent.amount,
        currency: intent.currency,
      };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      console.error("Unable to verify Stripe PaymentIntent", error);
      throw new HttpsError("internal", "The secure payment could not be verified.");
    }
  },
);

exports.deleteAccount = onCall(async (request) => {
  const uid = authenticatedUid(request);

  try {
    await deleteQueryInBatches(
      db.collection("orders").where("customerId", "==", uid),
    );
    await deleteQueryInBatches(
      db.collection("stripePayments").where("customerId", "==", uid),
    );
    await db.collection("users").doc(uid).delete();

    try {
      await getAuth().deleteUser(uid);
    } catch (error) {
      if (error && error.code !== "auth/user-not-found") throw error;
    }

    return {status: "deleted"};
  } catch (error) {
    console.error("Unable to delete Hungry Spot account", {uid, error});
    throw new HttpsError(
      "failed-precondition",
      "The account could not be deleted yet.",
    );
  }
});
