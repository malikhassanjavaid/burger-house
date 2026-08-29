"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  authenticatedUid,
  verifiedCustomerUid,
} = require("./auth_policy");

test("verifiedCustomerUid accepts a trusted phone claim", () => {
  assert.equal(
    verifiedCustomerUid({
      auth: {
        uid: "customer-1",
        token: {phone_number: "+923001234567"},
      },
    }),
    "customer-1",
  );
});

test("verifiedCustomerUid rejects authenticated users without a phone", () => {
  assert.throws(
    () => verifiedCustomerUid({auth: {uid: "customer-1", token: {}}}),
    (error) => error.code === "failed-precondition",
  );
  assert.throws(
    () => verifiedCustomerUid({
      auth: {uid: "customer-1", token: {phone_number: "123"}},
    }),
    (error) => error.code === "failed-precondition",
  );
});

test("account deletion keeps the authenticated-only helper", () => {
  assert.equal(
    authenticatedUid({auth: {uid: "incomplete-customer", token: {}}}),
    "incomplete-customer",
  );
});

test("both helpers reject signed-out requests", () => {
  assert.throws(
    () => authenticatedUid({}),
    (error) => error.code === "unauthenticated",
  );
  assert.throws(
    () => verifiedCustomerUid({}),
    (error) => error.code === "unauthenticated",
  );
});
