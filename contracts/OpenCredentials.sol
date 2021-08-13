// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./VCNFT.sol";
import "./ChainlinkCredentialsClient.sol";
import "./IOpenCredentials.sol";

contract OpenCredentials is IOpenCredentials, AccessControl, VCNFT, ChainlinkCredentialsClient {
    
    function issueCredentials(address to, string memory credentialSubject, string memory credentialName) external override onlyRole(MINTER_ROLE) {
       _requestVCIssuance(this.fulfillVCIssuance.selector, to, credentialSubject, credentialName);
    }
    
     /**
     * Callback function
     */
    function fulfillVCIssuance(bytes32 _requestId, bytes32 tokenURI) public recordChainlinkFulfillment(_requestId) {
        _safeMint(requestIdToRecipient[_requestId], string(abi.encodePacked(tokenURI)));
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