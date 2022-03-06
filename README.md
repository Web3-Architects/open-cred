# Open_Cred

This repository is used to generate credentials that are both non-transferable NFTs and Verifiable Credentials at the same time. 
It uses Chainlink and an AWS Lambda function.

For context and a full overview of the project, please read this blog post first: 
https://blog.raphaelroullet.com/hybrid-crypto-credentials-decentralized-learning/

## Project structure

### VC Issuer
Path: `/lambda/vc-issuer`

This module is responsible for generating Verifiable Credentials from the data received.
Authentication is done with Ceramic and an Ed25519Provider.
=> A SEED and ENTITY_NAME must be provided as environment variables.

Start locally with `sam local start-api --env-vars env.json --port 6000`

### External adapter
Path: `/external-adapter`

External adapter for a Chainlink node. It simply bridges requests with the VC Issuer.

Start locally with `yarn start`

### Contracts
Path: `/contracts`
- `ChainlinkCredentialsClient.sol`: Chainlink client which handles jobs, fees, oracle requests.
- `OpenCredentials.sol` (inherits ChainlinkCredentialsClient): Responsible for receiving requests to issue credentials. It uses the Chainlink client and VCNFT contracts to fulfill them.
- `VCNFT.sol`: ERC721 smart contract for the on-chain part of the hybrid credentials. Modified to prevent transfers.

**Rinkeby deployments**:  
OpenCredentials: 0x27187729F39de1bEB68e9Aa4E3D52240DD409730  
VCNFT (for Open_Classes): 0x0D7f626141Ab3866533f98b4D4406b23e8bE7608


## Chainlink
### Job Definition used

```TOML
type = "directrequest"
schemaVersion = 1
name = "vc_issuer_3"
contractAddress = "<ORACLE_ADDRESS>"
maxTaskDuration = "0s"
observationSource = """
    decode_log   [type=ethabidecodelog
                  abi="OracleRequest(bytes32 indexed specId, address requester, bytes32 requestId, uint256 payment, address callbackAddr, bytes4 callbackFunctionId, uint256 cancelExpiration, uint256 dataVersion, bytes data)"
                  data="$(jobRun.logData)"
                  topics="$(jobRun.logTopics)"]

    decode_cbor  [type=cborparse data="$(decode_log.data)"]
    fetch        [type=bridge name="vc_issuer_local" requestData="{\\"id\\": $(jobSpec.externalJobID), \\"data\\": { \\"subject\\": $(decode_cbor.subject), \\"title\\": $(decode_cbor.title)}}"]
    parse        [type=jsonparse path="data,result" data="$(fetch)"]
    encode_data  [type=ethabiencode abi="(bytes32 requestId, bytes tokenURI)" data="{\\"requestId\\": $(decode_log.requestId),  \\"tokenURI\\": $(parse)}"]
    encode_tx    [type=ethabiencode
                  abi="fulfillOracleRequest2(bytes32 requestId, uint256 payment, address callbackAddress, bytes4 callbackFunctionId, uint256 expiration, bytes data)"
                  data="{\\"requestId\\": $(decode_log.requestId), \\"payment\\": $(decode_log.payment), \\"callbackAddress\\": $(decode_log.callbackAddr), \\"callbackFunctionId\\": $(decode_log.callbackFunctionId), \\"expiration\\": $(decode_log.cancelExpiration), \\"data\\": $(encode_data)}"
                 ]
    submit_tx    [type=ethtx to="<ORACLE_ADDRESS>" data="$(encode_tx)"]

    decode_log -> decode_cbor -> fetch -> parse -> encode_data -> encode_tx -> submit_tx
"""
externalJobID = "<job_id>"
```
