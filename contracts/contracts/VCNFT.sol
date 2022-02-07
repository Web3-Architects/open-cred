// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IVCNFT.sol";

contract VCNFT is IVCNFT, ERC721, ERC721URIStorage, Pausable, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    Counters.Counter private _tokenIdCounter;
    string baseURI;

    // @dev Maps student => lessonId => balance
    mapping(address => mapping(bytes32 => uint256)) public credentialBalances;
    // TODO: Embed lessonId inside tokenId
    mapping(uint256 => bytes32) public tokenIdToLessonId;


    constructor() ERC721("OpenClassesCredentials", "OCC") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
    
    function setBaseURI(string memory newBaseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = newBaseURI;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function tokenURI(uint256 _tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(_tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mint(address to_, bytes32 lessonId, string memory tokenURI_) external override onlyRole(MINTER_ROLE) {
        _mint(to_, lessonId, tokenURI_);
    }

    function _mint(address to_, bytes32 lessonId, string memory tokenURI_) internal {
        uint256 currentTokenId = _tokenIdCounter.current();

        _safeMint(to_, currentTokenId);
        _setTokenURI(currentTokenId, tokenURI_);
        credentialBalances[to_][lessonId] += 1;
        tokenIdToLessonId[currentTokenId] = lessonId;

        _tokenIdCounter.increment();
    }

    function burn(uint256 tokenId) external {
        bytes32 lessonId = tokenIdToLessonId[tokenId];
        address tokenOwner = ownerOf(tokenId);
        require(tokenOwner == msg.sender || hasRole(BURNER_ROLE, msg.sender), "Unauthorized to burn token");

        credentialBalances[tokenOwner][lessonId] -= 1; 

        _burn(tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
       return super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721)
    {
        require((from == address(0) && to != address(0)) || (from != address(0) && to == address(0)),
            "Only mint or burn transfers are allowed"
        );
        super._beforeTokenTransfer(from, to, tokenId);
    }
}