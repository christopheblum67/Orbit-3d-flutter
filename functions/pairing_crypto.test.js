'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const {decode32, digest, encryptToken, validEnvelope} = require('./pairing_crypto');

test('encrypts a token for the TV key with authenticated context', () => {
  const tv = crypto.generateKeyPairSync('x25519');
  const publicKey = tv.publicKey.export({format: 'der', type: 'spki'}).subarray(-32).toString('base64url');
  const secret = crypto.randomBytes(32).toString('base64url');
  const envelope = encryptToken('test-token', publicKey, secret);
  assert.equal(validEnvelope(envelope), true);
  assert.equal(JSON.stringify(envelope).includes('test-token'), false);
  const prefix = Buffer.from('302a300506032b656e032100', 'hex');
  const ephemeral = crypto.createPublicKey({
    key: Buffer.concat([prefix, Buffer.from(envelope.key, 'base64url')]),
    format: 'der',
    type: 'spki',
  });
  const shared = crypto.diffieHellman({privateKey: tv.privateKey, publicKey: ephemeral});
  const label = Buffer.from('orbit-pairing/v1/token');
  const key = crypto.hkdfSync('sha256', shared, decode32(secret), label, 32);
  const decipher = crypto.createDecipheriv('aes-256-gcm', key, Buffer.from(envelope.nonce, 'base64url'));
  decipher.setAAD(label);
  decipher.setAuthTag(Buffer.from(envelope.mac, 'base64url'));
  assert.equal(Buffer.concat([decipher.update(Buffer.from(envelope.ciphertext, 'base64url')), decipher.final()]).toString(), 'test-token');
});

test('rejects malformed or oversized envelopes and noncanonical secrets', () => {
  const value = Buffer.alloc(32, 4).toString('base64url');
  assert.equal(decode32(value).length, 32);
  assert.equal(digest(value).length, 64);
  assert.throws(() => decode32(value + '='));
  assert.throws(() => decode32('4892'));
  assert.equal(validEnvelope({key: value, nonce: '', ciphertext: 'x', mac: ''}), false);
  assert.equal(validEnvelope({key: value, nonce: Buffer.alloc(12).toString('base64url'), ciphertext: Buffer.alloc(2049).toString('base64url'), mac: Buffer.alloc(16).toString('base64url')}), false);
});
