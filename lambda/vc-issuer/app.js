// const axios = require('axios')
// const url = 'http://checkip.amazonaws.com/';
const { DID } = require("dids");
const KeyResolver = require("key-did-resolver");
const { Ed25519Provider } = require("key-did-provider-ed25519");

const { hexStringToUint8Array } = require("./utils/conversions");

if (!process.env.SEED || !process.env.ENTITY_NAME) {
  throw new Error("Env variables must be defined");
}
const seed = hexStringToUint8Array(process.env.SEED);

const provider = new Ed25519Provider(seed);
const did = new DID({ provider, resolver: KeyResolver.default.getResolver() });

let response;
let InvalidRequestReponse = {
  statusCode: 400,
  body: "Invalid request",
};

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
  } catch (e) {
    console.error(`Error authenticating did`, e);
    return e;
  }
  const { queryStringParameters } = event;

  if (!queryStringParameters) return InvalidRequestReponse;

  const { subject, ...certificateDetails } = queryStringParameters;

  if (!subject) return InvalidRequestReponse;

  const credentialsData = {
    "@context": ["https://www.w3.org/2018/credentials/v1"],
    type: ["VerifiableCredential"],
    credentialSubject: {
      id: subject,
      certificate: {
        entity: process.env.ENTITY_NAME,
        ...certificateDetails,
      },
    },
    issuanceDate: new Date().toISOString(),
  };

  // Create a JWS - this will throw an error if the DID instance is not authenticated
  const jws = await did.createJWS(
    {
      sub: did.id,
      nbf: Math.floor(Date.now() / 1000),
      vc: credentialsData,
    },
    { did: did.id }
  );

  const finalDocument = { credentials: credentialsData, jws };
  console.info(`Credentials document: `, finalDocument);

  try {
    // const ret = await axios(url);
    response = {
      statusCode: 200,
      body: JSON.stringify({
        credentials: credentialsData,
        streamId: "mockStreamId",
      }),
    };
  } catch (err) {
    console.log(err);
    return err;
  }

  return response;
};
