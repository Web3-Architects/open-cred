// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ChainlinkCredentialsClient is AccessControl, ChainlinkClient {
    using Chainlink for Chainlink.Request;
    
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    
    bytes32 public result;

    constructor() {
        setPublicChainlinkToken();
        oracle = 0x57b17F79de7fF73AD58e32BB6E6BB8712Ab4142A;
        jobId = "2c2cc2dd5936435080800825f75ad4ea";
        fee = 0.05 * 10 ** 18;
    }
    
    /**
     * Initial request
     */
    function _requestVCIssuance(string memory subject, string memory credentialName, bytes4 functionSelector) internal returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), functionSelector);
        
        request.add("subject", subject);
        request.add("title", credentialName);
        
        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
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