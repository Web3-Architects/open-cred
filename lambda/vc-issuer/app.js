// const axios = require('axios')
// const url = 'http://checkip.amazonaws.com/';
const { DID } = require("dids");
const KeyResolver = require("key-did-resolver");
const { Ed25519Provider } = require("key-did-provider-ed25519");

const seed = hexStringToUint8Array(process.env.SEED);

const provider = new Ed25519Provider(seed);
const did = new DID({ provider, resolver: KeyResolver.getResolver() });

let response;

/**
 *
 * Event doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-input-format
 * @param {Object} event - API Gateway Lambda Proxy Input Format
 *
 * Context doc: https://docs.aws.amazon.com/lambda/latest/dg/nodejs-prog-model-context.html
 * @param {Object} context
 *
 * Return doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html
 * @returns {Object} object - API Gateway Lambda Proxy Output Format
 *
 */
exports.lambdaHandler = async (event, context) => {
  // Authenticate with the provider
  try {
    await did.authenticate();
    // Read the DID string - this will throw an error if the DID instance is not authenticated
    console.info(`Authenticated with did: `, did.id);
  } catch (e) {
    console.error(`Error authenticating did`, e);
    return e;
  }

  // Create a JWS - this will throw an error if the DID instance is not authenticated
  const jws = await did.createJWS({ hello: "world" });
  console.info(`JWS created: `, jws);

  try {
    // const ret = await axios(url);
    response = {
      statusCode: 200,
      body: JSON.stringify(jws),
    };
  } catch (err) {
    console.log(err);
    return err;
  }

  return response;
};
