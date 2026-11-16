'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const {createHandlers} = require('./pairing_handlers');
const {digest} = require('./pairing_crypto');

class Timestamp {
  constructor(ms) { this.ms = ms; }
  toMillis() { return this.ms; }
  static fromMillis(ms) { return new Timestamp(ms); }
}
class HttpsError extends Error {
  constructor(code, message) { super(message); this.code = code; }
}
class Database {
  constructor() { this.docs = new Map(); this.tail = Promise.resolve(); }
  collection(name) {
    return {doc: (id) => {
      const path = `${name}/${id}`;
      return {id, path, get: async () => ({data: () => this.docs.get(path)})};
    }};
  }
  async runTransaction(fn) {
    const previous = this.tail;
    let release;
    this.tail = new Promise((resolve) => { release = resolve; });
    await previous;
    const writes = [];
    const tx = {
      get: async (ref) => ref.get(),
      create: (ref, data) => writes.push(() => {
        if (this.docs.has(ref.path)) throw new Error('Already exists');
        this.docs.set(ref.path, data);
      }),
      set: (ref, data) => writes.push(() => this.docs.set(ref.path, data)),
      update: (ref, data) => writes.push(() => this.docs.set(ref.path, {...this.docs.get(ref.path), ...data})),
      delete: (ref) => writes.push(() => this.docs.delete(ref.path)),
    };
    try {
      const result = await fn(tx);
      for (const write of writes) write();
      return result;
    } finally { release(); }
  }
}

function setup() {
  const db = new Database();
  const authService = {
    getUser: async (uid) => ({email: `${uid}@example.test`}),
    createCustomToken: async (uid) => `token-for-${uid}`,
  };
  const handlers = createHandlers({db, authService, Timestamp, HttpsError});
  const tv = (data = {}, uid = 'tv') => ({auth: {uid, token: {firebase: {sign_in_provider: 'anonymous'}}}, data});
  const phone = (data = {}, uid = 'phone') => ({auth: {uid, token: {firebase: {sign_in_provider: 'google.com'}}}, data});
  const keyPair = crypto.generateKeyPairSync('x25519');
  const publicKey = keyPair.publicKey.export({format: 'der', type: 'spki'}).subarray(-32).toString('base64url');
  const phrase = {
    key: publicKey,
    nonce: Buffer.alloc(12).toString('base64url'),
    ciphertext: Buffer.from('encrypted phrase').toString('base64url'),
    mac: Buffer.alloc(16).toString('base64url'),
  };
  return {db, handlers, tv, phone, publicKey, phrase};
}

test('requires a valid owner, correct QR key, approval and single consumption', async () => {
  const {db, handlers, tv, phone, publicKey, phrase} = setup();
  await assert.rejects(handlers.createTvPairing({data: {publicKey}}), {code: 'unauthenticated'});
  const {secret} = await handlers.createTvPairing(tv({publicKey}));
  await assert.rejects(handlers.createTvPairing(tv({publicKey})), {code: 'resource-exhausted'});
  await assert.rejects(handlers.checkTvPairing(tv({secret}, 'another-tv')), {code: 'failed-precondition'});
  await assert.rejects(handlers.approveTvPairing(tv({secret, publicKey, phrase})), {code: 'unauthenticated'});
  await assert.rejects(handlers.approveTvPairing(phone({secret, publicKey: Buffer.alloc(32, 1).toString('base64url'), phrase})), {code: 'failed-precondition'});
  assert.deepEqual(await handlers.checkTvPairing(tv({secret})), {status: 'pending'});
  const results = await Promise.allSettled([
    handlers.approveTvPairing(phone({secret, publicKey, phrase})),
    handlers.approveTvPairing(phone({secret, publicKey, phrase}, 'other')),
  ]);
  assert.equal(results.filter((r) => r.status === 'fulfilled').length, 1);
  const status = await handlers.checkTvPairing(tv({secret}));
  assert.equal(status.status, 'approved');
  assert.match(status.accountLabel, /@example\.test$/);
  await assert.rejects(handlers.consumeTvPairing(tv({secret}, 'another-tv')), {code: 'failed-precondition'});
  const [first, second] = await Promise.allSettled([
    handlers.consumeTvPairing(tv({secret})),
    handlers.consumeTvPairing(tv({secret})),
  ]);
  const success = [first, second].filter((r) => r.status === 'fulfilled');
  assert.equal(success.length, 1);
  assert.equal(success[0].value.phrase, phrase);
  assert.equal(JSON.stringify(success[0].value.token).includes('token-for-'), false);
  assert.equal(db.docs.has(`pairing_sessions_v1/${digest(secret)}`), false);
});

test('expired sessions cannot be used and cancellation cannot delete a new owner lock', async () => {
  const {db, handlers, tv, phone, publicKey, phrase} = setup();
  const old = await handlers.createTvPairing(tv({publicKey}));
  const path = `pairing_sessions_v1/${digest(old.secret)}`;
  db.docs.get(path).expiresAt = Timestamp.fromMillis(Date.now() - 1);
  db.docs.get('pairing_owners_v1/tv').expiresAt = Timestamp.fromMillis(Date.now() - 1);
  await assert.rejects(handlers.approveTvPairing(phone({secret: old.secret, publicKey, phrase})), {code: 'failed-precondition'});
  const current = await handlers.createTvPairing(tv({publicKey}));
  await handlers.cancelTvPairing(tv({secret: old.secret}));
  assert.equal(db.docs.get('pairing_owners_v1/tv').sessionId, digest(current.secret));
  assert.deepEqual(await handlers.checkTvPairing(tv({secret: current.secret})), {status: 'pending'});
  await handlers.cancelTvPairing(tv({secret: current.secret}));
  await assert.rejects(handlers.checkTvPairing(tv({secret: current.secret})), {code: 'failed-precondition'});
});
