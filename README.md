# Open_Cred



# Chainlink
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
