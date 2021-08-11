// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./VCNFT.sol";
import "./ChainlinkCredentialsClient.sol";

contract OpenCredentials is AccessControl, VCNFT, ChainlinkCredentialsClient {
    
    
    function issueCredentials(address to, string memory didSubject, string memory credentialName) public onlyRole(MINTER_ROLE) returns (bytes32 requestId) {
       return _requestVCIssuance(this.fulfillVCIssuance.selector, to, didSubject, credentialName);
    }
    
     /**
     * Callback function
     */
    function fulfillVCIssuance(bytes32 _requestId, bytes32 to, bytes32 tokenURI) public recordChainlinkFulfillment(_requestId) {
        _safeMint(address(uint160(uint256(to))), string(abi.encodePacked(tokenURI)));
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