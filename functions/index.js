"use strict";

const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const Stripe = require("stripe");

initializeApp();

const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");
const db = getFirestore();

function authenticatedUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in before making a payment.");
  }
  return uid;
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
    const uid = authenticatedUid(request);
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
    const uid = authenticatedUid(request);
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