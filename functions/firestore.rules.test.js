"use strict";

const fs = require("node:fs");
const path = require("node:path");
const {after, before, beforeEach, test} = require("node:test");

const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const {
  addDoc,
  collection,
  doc,
  getDoc,
  setDoc,
} = require("firebase/firestore");

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "hungry-spot-phone-rules-test",
    firestore: {
      rules: fs.readFileSync(
        path.join(__dirname, "..", "firestore.rules"),
        "utf8",
      ),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

after(async () => {
  await testEnv.cleanup();
});

function validCashOrder(customerId) {
  return {
    customerId,
    status: "placed",
    fulfillmentMethod: "delivery",
    paymentMethod: "cash_on_delivery",
    paymentStatus: "pending",
    orderNumber: "HS-TEST-1",
    customerEmail: "customer@example.com",
    receiverName: "Customer",
    phone: "+923001234567",
    deliveryAddress: "Test address",
    items: [{id: "burger-1", quantity: 1}],
    subtotal: 10,
    deliveryFee: 2,
    serviceFee: 1,
    discount: 0,
    etaMinMinutes: 30,
    etaMaxMinutes: 40,
    total: 13,
  };
}

test("private profiles require ownership and a verified phone claim", async () => {
  const verified = testEnv.authenticatedContext("customer-1", {
    phone_number: "+923001234567",
  }).firestore();
  const unverified = testEnv.authenticatedContext("customer-1").firestore();
  const other = testEnv.authenticatedContext("customer-2", {
    phone_number: "+923009999999",
  }).firestore();

  await assertSucceeds(setDoc(doc(verified, "users/customer-1"), {
    uid: "customer-1",
    phone: "+923001234567",
  }));
  await assertFails(setDoc(doc(unverified, "users/customer-1"), {
    uid: "customer-1",
  }));
  await assertFails(getDoc(doc(other, "users/customer-1")));
});

test("private orders require ownership and a verified phone claim", async () => {
  const verified = testEnv.authenticatedContext("customer-1", {
    phone_number: "+923001234567",
  }).firestore();
  const unverified = testEnv.authenticatedContext("customer-1").firestore();
  const other = testEnv.authenticatedContext("customer-2", {
    phone_number: "+923009999999",
  }).firestore();

  await assertSucceeds(addDoc(
    collection(verified, "orders"),
    validCashOrder("customer-1"),
  ));
  await assertFails(addDoc(
    collection(unverified, "orders"),
    validCashOrder("customer-1"),
  ));

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "orders/order-2"),
      validCashOrder("customer-2"));
  });
  await assertFails(getDoc(doc(verified, "orders/order-2")));
  await assertSucceeds(getDoc(doc(other, "orders/order-2")));
});

test("signed-out clients still cannot access private customer data", async () => {
  const anonymous = testEnv.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(anonymous, "users/customer-1")));
  await assertFails(addDoc(
    collection(anonymous, "orders"),
    validCashOrder("customer-1"),
  ));
});
