function hexStringToUint8Array(hexString) {
  return new Uint8Array(
    hexString.match(/.{1,2}/g).map((byte) => parseInt(byte, 16))
  );
}

module.exports = { hexStringToUint8Array };
