// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ChainlinkCredentialsClient.sol";
import "./IOpenCredentials.sol";
import "./IVCNFT.sol";

contract OpenCredentials is IOpenCredentials, AccessControl, ChainlinkCredentialsClient {
    
    IVCNFT public vcNFT;
    // @dev Maps contract's address to credential id
    mapping(address => bytes32) public addressToCredentialId;

    constructor(address nftAddress_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        vcNFT = IVCNFT(nftAddress_);
    }

    // `contractAddress` must not be the zero-address
    // `credentialId` must not be 0
    function setCredentialId(address contractAddress, bytes32 credentialId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        addressToCredentialId[contractAddress] = credentialId;
    } 

    function issueCredentials(address to, string memory credentialSubject, string memory credentialName) external override {
        bytes32 credentialId = addressToCredentialId[msg.sender];
        require(credentialId != 0, "No credential id assigned");
       _requestVCIssuance(this.fulfillVCIssuance.selector, to, credentialId, credentialSubject, credentialName);
    }

    /**
     * Callback function
     */
    function fulfillVCIssuance(bytes32 requestId, bytes memory tokenURI) public recordChainlinkFulfillment(_requestId) {
        Request memory request = requestIdToRequest[requestId];
        vcNFT.mint(request.recipient, request.credentialId, string(abi.encodePacked(tokenURI)));
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