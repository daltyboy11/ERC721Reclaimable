// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC721Royalty} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {IERC721Reclaimable} from "./interfaces/IERC721Reclaimable.sol";

contract ERC721Reclaimable is IERC721Reclaimable, ERC721Royalty {
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

    function claimOwnership(uint256 tokenId) public override onlyTitleOwnerOrTitleOperator(tokenId) {
        address titleOwner = _titleOwners[tokenId];
        address assetOwner = this.ownerOf(tokenId);
        _transfer(assetOwner, titleOwner, tokenId);
        emit OwnershipClaimed(titleOwner, assetOwner, tokenId);
    }

    function titleTransferFrom(address to, address from, uint256 tokenId) public override onlyTitleOwnerOrTitleOperator(tokenId) {
        if (to != _titleOwners[tokenId]) revert TitleTransferFromInvalidTitleOwner(to, tokenId);

        _titleOwners[tokenId] = from;

        // Clear approval
        delete _tokenTitleApprovals[tokenId];
        emit TitleTransfer(to, from, tokenId);
    }

    function titleOwnerOf(uint256 tokenId) public view override returns (address) {
        return _titleOwners[tokenId];
    }

    function titleApprove(address to, uint256 tokenId) public override onlyTitleOwner(tokenId) {
        _tokenTitleApprovals[tokenId] = to;
        emit TitleApproval(msg.sender, to, tokenId);
    }

    function getTitleApproved(uint256 tokenId) public view override returns (address) {
        return _tokenTitleApprovals[tokenId];
    }

    function setTitleApprovalForAll(address operator, bool approved) public override {
        _titleOperatorApprovals[msg.sender][operator] = approved;
        emit TitleApprovalForAll(msg.sender, operator, approved);
    }

    function isTitleApprovedForAll(address titleOwner, address titleOperator) public view override returns (bool) {
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

    modifier onlyTitleOwner(uint256 tokenId) {
        if (msg.sender != _titleOwners[tokenId]) revert NotTitleOwner(msg.sender);
        _;
    }

    modifier onlyTitleOwnerOrTitleOperator(uint256 tokenId) {
        address titleOwner = _titleOwners[tokenId];
        bool isTitleOwner = titleOwner == msg.sender;
        bool isApproved = this.getTitleApproved(tokenId) == msg.sender;
        bool isApprovedForAll = this.isTitleApprovedForAll(titleOwner, msg.sender);
        if (!isApproved && !isTitleOwner && !isApprovedForAll) revert NotTitleOwnerOrTitleOperator(msg.sender);
        _;
    }
}