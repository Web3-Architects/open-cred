// const axios = require('axios')
// const url = 'http://checkip.amazonaws.com/';
const { Ed25519Provider } = require("key-did-provider-ed25519");
const KeyResolver = require("key-did-resolver");
const { DID } = require("dids");
const { CeramicClient } = require("@ceramicnetwork/http-client");
const { TileDocument } = require("@ceramicnetwork/stream-tile");

const { hexStringToUint8Array } = require("./utils/conversions");

const API_URL = "https://gateway-clay.ceramic.network";
const ceramic = new CeramicClient(API_URL);

if (!process.env.SEED || !process.env.ENTITY_NAME) {
  throw new Error("Env variables must be defined");
}
const seed = hexStringToUint8Array(process.env.SEED);

const provider = new Ed25519Provider(seed);
const did = new DID({ provider, resolver: KeyResolver.default.getResolver() });
ceramic.did = did;
ceramic.did.setProvider(provider);

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
    await ceramic.did.authenticate();
    // Read the DID string - this will throw an error if the DID instance is not authenticated
    console.log("Authenticated DID:", ceramic.did.id);
    if (!ceramic.did.id) throw new Error("No ceramic.did.id");
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
      sub: ceramic.did.id,
      nbf: Math.floor(Date.now() / 1000),
      vc: credentialsData,
    },
    { did: ceramic.did.id }
  );
  console.log(`jws`, jws);

  const finalDocument = {
    ...credentialsData,
    proof: {
      type: "JsonWebSignature2020",
      created: new Date().toISOString(),
      proofPurpose: "assertionMethod",
      verificationMethod:
        "https://ceramicnetwork.github.io/js-did/classes/did.html#verifyjws",
      jws,
    },
  };
  console.info(`Credentials document: `, finalDocument);

  let streamId = "";
  console.log("Issuer DID", ceramic.did.id);

  try {
    const doc = await TileDocument.create(ceramic, finalDocument, {
      controllers: [ceramic.did.id],
    });

    streamId = doc.id.toString();
    // streamId =
    //   "kjzl6cwe1jw148ooqyinbqzeiwgkew118waumozfdbsl02yypaj5ict3iffzvne";
    console.log(`streamId: `, streamId);
  } catch (err) {
    console.error(`error creating Tile: `, err);
    throw err;
  }

  try {
    response = {
      statusCode: 200,
      body: JSON.stringify({
        credentials: credentialsData,
        streamId: streamId,
      }),
    };
  } catch (err) {
    console.log(err);
    return err;
  }

  return response;
};
