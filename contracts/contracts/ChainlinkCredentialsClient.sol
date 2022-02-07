// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ChainlinkCredentialsClient is AccessControl, ChainlinkClient {
    using Chainlink for Chainlink.Request;
    
    bytes32 public jobId;
    uint256 private fee;

    struct Request {
        address recipient;
        bytes32 credentialId;
    }
    // This is so the contract can keep track of who to assign the result to when it comes back.
    // TODO: Receive this info directly from Chainlink response instead of storing them on-chain?
    mapping(bytes32 => Request) public requestIdToRequest;

    constructor() {
        setPublicChainlinkToken();
        setChainlinkOracle(0x05928fEAD8d5B126B510F7e6F848D47e37B73d27);
        jobId = "b1d42cd54a3a4200b1f725a68e48aad7";
        fee = 0.05 * 10 ** 18;
    }
    
    /**
     * Initial request
     */
    function _requestVCIssuance(bytes4 functionSelector, address to, bytes32 credentialId, string memory credentialSubject, string memory credentialName) internal {
        Chainlink.Request memory request = buildOperatorRequest(jobId, functionSelector);
        
        request.add("subject", credentialSubject);
        request.add("title", credentialName);

        // Sends the request
        bytes32 requestId = sendOperatorRequest(request, fee);
        
        requestIdToRequest[requestId] = Request(to, credentialId);
    }
    
   
    function setJobId (bytes32 newJobId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        jobId = newJobId;
    }
    
    function setOracleAddress (address newOracleAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        setChainlinkOracle(newOracleAddress);
    }
    
    function setFee (uint256 newFee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        fee = newFee;
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function withdrawLINK() public onlyRole(DEFAULT_ADMIN_ROLE) {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }
}