// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ChainlinkCredentialsClient.sol";
import "./IOpenCredentials.sol";
import "./IVCNFT.sol";

contract OpenCredentials is IOpenCredentials, AccessControl, ChainlinkCredentialsClient {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    IVCNFT public vcNFT;

    constructor(address nftAddress_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        vcNFT = IVCNFT(nftAddress_);
    }


    function issueCredentials(address to, string memory credentialSubject, string memory credentialName) external override onlyRole(MINTER_ROLE) {
       _requestVCIssuance(this.fulfillVCIssuance.selector, to, credentialSubject, credentialName);
    }
    
     /**
     * Callback function
     */
    function fulfillVCIssuance(bytes32 _requestId, bytes memory tokenURI) public recordChainlinkFulfillment(_requestId) {
        vcNFT.mint(requestIdToRecipient[_requestId], string(abi.encodePacked(tokenURI)));
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ChainlinkCredentialsClient)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setNFTAddress(address newNFTAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        vcNFT = IVCNFT(newNFTAddress);
    }
}