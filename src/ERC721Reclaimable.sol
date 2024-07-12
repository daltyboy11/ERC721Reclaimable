// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721Royalty} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

contract ERC721Reclaimable is ERC721Royalty {
    /**
     * @dev Emitted when `tokenId`'s title is transferred from `from` to `to`.
     */
    event TitleTransfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `titleOwner` enables `approved` to manage the `tokenId`'s title.
     */
    event TitleApproval(address indexed titleOwner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `titleOwner` enables or disables (`approved`) `titleOperator` to manage all of its titles.
     */
    event TitleApprovalForAll(address indexed titleOwner, address indexed titleOperator, bool approved);

    event OwnershipClaimed(address indexed titleOwner, address indexed assetOwner, uint256 tokenId);

    mapping(uint256 => address) private _titleOwners;
    mapping(uint256 tokenId => address) private _tokenTitleApprovals;
    mapping(address titleOwner => mapping(address titleOperator => bool)) private _titleOperatorApprovals;

    constructor(
        string memory name,
        string memory symbol,
        address royaltyBeneficiary,
        uint96 royaltyBps
    ) ERC721(name, symbol) {
        _setDefaultRoyalty(royaltyBeneficiary, royaltyBps);
    }

    /**
     * As the title owner, exercise your right to reclaim ownership of the asset.
     */
    function claimOwnership(uint256 tokenId) public {
        address titleOwner = _titleOwners[tokenId];
        bool isTitleOwner = titleOwner == msg.sender;
        bool isApproved = this.getTitleApproved(tokenId) == msg.sender;
        bool isApprovedForAll = this.isTitleApprovedForAll(titleOwner, msg.sender);
        require(isTitleOwner || isApproved || isApprovedForAll, "Not authorized to claim ownership");
        address assetOwner = this.ownerOf(tokenId);
        _transfer(assetOwner, titleOwner, tokenId);
        emit OwnershipClaimed(titleOwner, assetOwner, tokenId);
    }

    /**
     * Transfer title. The exchange is responsible for enforcing applicable royalty fees.
     */
    function titleTransferFrom(address to, address from, uint256 tokenId) public {
        address oldTitleOwner = _titleOwners[tokenId];
        require(oldTitleOwner == to, "To is not the title owner for this token");

        bool isTitleOwner = oldTitleOwner == msg.sender;
        bool isApproved = this.getTitleApproved(tokenId) == msg.sender;
        bool isApprovedForAll = this.isTitleApprovedForAll(oldTitleOwner, msg.sender);
        require(isTitleOwner || isApproved || isApprovedForAll, "Not authorized to transfer title");

        _titleOwners[tokenId] = from;
        // Clear approval
        delete _tokenTitleApprovals[tokenId];

        emit TitleTransfer(to, from, tokenId);
    }

    function titleOwnerOf(uint256 tokenId) public view returns (address) {
        return _titleOwners[tokenId];
    }

    function titleApprove(address to, uint256 tokenId) public {
        require(_titleOwners[tokenId] == msg.sender, "Not Title Owner");
        _tokenTitleApprovals[tokenId] = to;
        emit TitleApproval(msg.sender, to, tokenId);
    }

    function getTitleApproved(uint256 tokenId) public view returns (address) {
        return _tokenTitleApprovals[tokenId];
    }

    function setTitleApprovalForAll(address operator, bool approved) public {
        _titleOperatorApprovals[msg.sender][operator] = approved;
        emit TitleApprovalForAll(msg.sender, operator, approved);
    }

    function isTitleApprovedForAll(address titleOwner, address titleOperator) public view returns (bool) {
        return _titleOperatorApprovals[titleOwner][titleOperator];
    }

    function mint(address to, uint256 tokenId) internal {
        _mint(to, tokenId);
        _titleMint(to, tokenId);
    }

    function _titleMint(address to, uint256 tokenId) internal {
        require(to != address(0), "Cannot mint to 0 address");
        require(_titleOwners[tokenId] == address(0), "Title already minted");
        _titleOwners[tokenId] = to;
        emit TitleTransfer(address(0), to, tokenId);
    }
}