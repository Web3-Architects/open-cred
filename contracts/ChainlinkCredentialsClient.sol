// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ChainlinkCredentialsClient is AccessControl, ChainlinkClient {
    using Chainlink for Chainlink.Request;
    
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    
    // This is so the contract can keep track of who to assign the result to when it comes back.
    mapping(bytes32 => address) public requestIdToRecipient;

    constructor() {
        setPublicChainlinkToken();
        oracle = 0x57b17F79de7fF73AD58e32BB6E6BB8712Ab4142A;
        jobId = "5a16c73a40b94f61a578334d83753872";
        fee = 0.05 * 10 ** 18;
    }
    
    /**
     * Initial request
     */
    function _requestVCIssuance(bytes4 functionSelector, address to, string memory credentialSubject, string memory credentialName) internal {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), functionSelector);
        
        request.add("subject", credentialSubject);
        request.add("title", credentialName);

        // Sends the request
        bytes32 requestId = sendChainlinkRequestTo(oracle, request, fee);
        
        requestIdToRecipient[requestId] = to;
    }
    
   
    function setJobId (bytes32 newJobId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        jobId = newJobId;
    }
    
    function setOracleAddress (address newOracleAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        oracle = newOracleAddress;
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