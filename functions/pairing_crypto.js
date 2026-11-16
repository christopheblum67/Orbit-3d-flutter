'use strict';

const crypto = require('node:crypto');
const spkiPrefix = Buffer.from('302a300506032b656e032100', 'hex');

function decode32(value) {
  if (typeof value !== 'string' || !/^[A-Za-z0-9_-]{43}$/.test(value)) {
    throw new Error('Invalid 32-byte value');
  }
  const bytes = Buffer.from(value, 'base64url');
  if (bytes.length !== 32 || bytes.toString('base64url') !== value) {
    throw new Error('Invalid 32-byte value');
  }
  return bytes;
}

function digest(value) {
  return crypto.createHash('sha256').update(decode32(value)).digest('hex');
}

function encryptToken(token, publicKey, secret) {
  const target = crypto.createPublicKey({
    key: Buffer.concat([spkiPrefix, decode32(publicKey)]),
    format: 'der',
    type: 'spki',
  });
  const ephemeral = crypto.generateKeyPairSync('x25519');
  const shared = crypto.diffieHellman({
    privateKey: ephemeral.privateKey,
    publicKey: target,
  });
  const label = Buffer.from('orbit-pairing/v1/token');
  const key = crypto.hkdfSync('sha256', shared, decode32(secret), label, 32);
  const nonce = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, nonce);
  cipher.setAAD(label);
  const ciphertext = Buffer.concat([cipher.update(token, 'utf8'), cipher.final()]);
  return {
    key: ephemeral.publicKey.export({format: 'der', type: 'spki'}).subarray(-32).toString('base64url'),
    nonce: nonce.toString('base64url'),
    ciphertext: ciphertext.toString('base64url'),
    mac: cipher.getAuthTag().toString('base64url'),
  };
}

function validEnvelope(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value) ||
      Object.keys(value).sort().join(',') !== 'ciphertext,key,mac,nonce') return false;
  try {
    decode32(value.key);
    for (const [field, length] of [['nonce', 12], ['mac', 16]]) {
      if (typeof value[field] !== 'string' ||
          value[field].length !== (length === 12 ? 16 : 22) ||
          !/^[A-Za-z0-9_-]+$/.test(value[field])) return false;
      const bytes = Buffer.from(value[field], 'base64url');
      if (bytes.length !== length || bytes.toString('base64url') !== value[field]) return false;
    }
    if (typeof value.ciphertext !== 'string' ||
        value.ciphertext.length > 2731 ||
        !/^[A-Za-z0-9_-]+$/.test(value.ciphertext)) return false;
    const bytes = Buffer.from(value.ciphertext, 'base64url');
    return bytes.length > 0 && bytes.length <= 2048 &&
      bytes.toString('base64url') === value.ciphertext;
  } catch (_) {
    return false;
  }
}

module.exports = {decode32, digest, encryptToken, validEnvelope};
