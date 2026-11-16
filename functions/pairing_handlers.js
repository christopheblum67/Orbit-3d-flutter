'use strict';

const crypto = require('node:crypto');
const {decode32, digest, encryptToken, validEnvelope} = require('./pairing_crypto');

function createHandlers({db, authService, Timestamp, HttpsError}) {
  const sessions = db.collection('pairing_sessions_v1');
  const owners = db.collection('pairing_owners_v1');
  const invalid = () => new HttpsError('failed-precondition', 'Session invalide ou expirée.');

  function authenticate(request, anonymous) {
    const auth = request.auth;
    const provider = auth?.token?.firebase?.sign_in_provider;
    if (!auth || typeof provider !== 'string' || (provider === 'anonymous') !== anonymous) {
      throw new HttpsError('unauthenticated', 'Compte incompatible avec cette opération.');
    }
    return auth;
  }

  function sessionReference(secret) {
    try {
      return sessions.doc(digest(secret));
    } catch (_) {
      throw invalid();
    }
  }

  function validSession(data) {
    return data && data.expiresAt instanceof Timestamp &&
      data.expiresAt.toMillis() > Date.now();
  }

  async function createTvPairing(request) {
    const auth = authenticate(request, true);
    try { decode32(request.data?.publicKey); } catch (_) { throw invalid(); }
    const secret = crypto.randomBytes(32).toString('base64url');
    const ref = sessionReference(secret);
    const owner = owners.doc(auth.uid);
    const expiresAt = Timestamp.fromMillis(Date.now() + 5 * 60 * 1000);
    await db.runTransaction(async (tx) => {
      const existing = (await tx.get(owner)).data();
      if (existing?.expiresAt instanceof Timestamp && existing.expiresAt.toMillis() > Date.now()) {
        throw new HttpsError('resource-exhausted', 'Une session est déjà active.');
      }
      tx.create(ref, {ownerUid: auth.uid, publicKey: request.data.publicKey, expiresAt, status: 'pending'});
      tx.set(owner, {sessionId: ref.id, expiresAt});
    });
    return {secret, expiresAt: expiresAt.toMillis()};
  }

  async function approveTvPairing(request) {
    const auth = authenticate(request, false);
    const {secret, publicKey, phrase} = request.data || {};
    const ref = sessionReference(secret);
    try { decode32(publicKey); } catch (_) { throw invalid(); }
    if (!validEnvelope(phrase)) throw invalid();
    const initial = (await ref.get()).data();
    if (!validSession(initial) || initial.status !== 'pending' || initial.publicKey !== publicKey) throw invalid();
    const user = await authService.getUser(auth.uid);
    const token = await authService.createCustomToken(auth.uid);
    let tokenEnvelope;
    try { tokenEnvelope = encryptToken(token, publicKey, secret); } catch (_) { throw invalid(); }
    await db.runTransaction(async (tx) => {
      const data = (await tx.get(ref)).data();
      if (!validSession(data) || data.status !== 'pending' || data.publicKey !== publicKey) throw invalid();
      tx.update(ref, {
        status: 'approved',
        approvedUid: auth.uid,
        accountLabel: (user.email || user.displayName || 'Compte Google').slice(0, 256),
        phrase,
        token: tokenEnvelope,
      });
    });
    return {approved: true};
  }

  async function checkTvPairing(request) {
    const auth = authenticate(request, true);
    const ref = sessionReference(request.data?.secret);
    const data = (await ref.get()).data();
    if (!validSession(data) || data.ownerUid !== auth.uid) throw invalid();
    return data.status === 'approved'
      ? {status: 'approved', accountLabel: data.accountLabel}
      : {status: 'pending'};
  }

  async function consumeTvPairing(request) {
    const auth = authenticate(request, true);
    const ref = sessionReference(request.data?.secret);
    const owner = owners.doc(auth.uid);
    return db.runTransaction(async (tx) => {
      const data = (await tx.get(ref)).data();
      if (!validSession(data) || data.ownerUid !== auth.uid || data.status !== 'approved') throw invalid();
      tx.delete(ref);
      tx.delete(owner);
      return {uid: data.approvedUid, phrase: data.phrase, token: data.token};
    });
  }

  async function cancelTvPairing(request) {
    const auth = authenticate(request, true);
    const ref = sessionReference(request.data?.secret);
    const owner = owners.doc(auth.uid);
    await db.runTransaction(async (tx) => {
      const data = (await tx.get(ref)).data();
      const ownerData = (await tx.get(owner)).data();
      if (!data || data.ownerUid !== auth.uid) return;
      tx.delete(ref);
      if (ownerData?.sessionId === ref.id) tx.delete(owner);
    });
    return {canceled: true};
  }

  return {createTvPairing, approveTvPairing, checkTvPairing, consumeTvPairing, cancelTvPairing};
}

module.exports = {createHandlers};
