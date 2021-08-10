// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./VCNFT.sol";
import "./ChainlinkCredentialsClient.sol";

contract OpenCredentials is AccessControl, VCNFT, ChainlinkCredentialsClient {
    
    
    function issueCredentials(string memory subject, string memory credentialName) public onlyRole(MINTER_ROLE) returns (bytes32 requestId) {
       return _requestVCIssuance(subject, credentialName, this.fulfillVCIssuance.selector);
    }
    
     /**
     * Callback function
     */
    function fulfillVCIssuance(bytes32 _requestId, bytes32 _result) public recordChainlinkFulfillment(_requestId) {
        result = _result;
    }
    
     function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ChainlinkCredentialsClient, VCNFT)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}