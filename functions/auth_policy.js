"use strict";

const {HttpsError} = require("firebase-functions/v2/https");

function authenticatedUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in before continuing.");
  }
  return uid;
}

function verifiedCustomerUid(request) {
  const uid = authenticatedUid(request);
  const phoneNumber = request.auth && request.auth.token &&
    request.auth.token.phone_number;
  if (typeof phoneNumber !== "string" || phoneNumber.length < 8) {
    throw new HttpsError(
      "failed-precondition",
      "Verify your phone number before making a payment.",
    );
  }
  return uid;
}

module.exports = {authenticatedUid, verifiedCustomerUid};
