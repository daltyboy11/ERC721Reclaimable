// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {IERC721Reclaimable} from "./interfaces/IERC721Reclaimable.sol";

contract ERC721Reclaimable is IERC721Reclaimable, ERC721 {
    mapping(uint256 => address) private _titleOwners;
    mapping(address => uint256) private _titleBalances;
    mapping(uint256 tokenId => address) private _tokenTitleApprovals;
    mapping(address titleOwner => mapping(address titleOperator => bool)) private _titleOperatorApprovals;

    uint256 private immutable _titleTransferFee;
    address private immutable _titleFeeRecipient;

    constructor(
        string memory name,
        string memory symbol,
        uint256 __titleTransferFee,
        address __titleFeeRecipient
    ) ERC721(name, symbol) {
        _titleTransferFee = __titleTransferFee;
        _titleFeeRecipient = __titleFeeRecipient;
    }

    /// @inheritdoc IERC721Reclaimable
    function titleTransferFee() external override view returns (uint256) {
        return _titleTransferFee;
    }

    /// @inheritdoc IERC721Reclaimable
    function titleTransferFeeRecipient() external override view returns (address) {
        return _titleFeeRecipient;
    }

    /// @inheritdoc IERC721Reclaimable
    function claimOwnership(uint256 _tokenId)
        public
        payable
        override
        onlyTitleOwnerOrOperatorOrApproved(_tokenId)
    {
        address titleOwner = _titleOwners[_tokenId];
        address assetOwner = this.ownerOf(_tokenId);
        _transfer(assetOwner, titleOwner, _tokenId);
        emit OwnershipClaim(titleOwner, assetOwner, _tokenId);
    }

    /// @inheritdoc IERC721Reclaimable
    function titleTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override payable onlyTitleOwnerOrOperatorOrApproved(_tokenId) {
        if (_titleOwners[_tokenId] != _from) {
            revert NotTitleOwner(_from);
        }
        if (msg.value < _titleTransferFee) {
            revert InsufficientTitleTransferFee(_from, _to, _tokenId, msg.value);
        }

        _titleOwners[_tokenId] = _to;
        _titleBalances[_to] += 1;
        _titleBalances[_from] -= 1;

        // Clear approval
        delete _tokenTitleApprovals[_tokenId];

        // Transfer the title transfer fee to the receiver
        (bool success, ) = _titleFeeRecipient.call{value: msg.value}("");
        require(success, "Transfer failed");

        emit TitleTransfer(_from, _to, _tokenId);
    }

    /// @inheritdoc IERC721Reclaimable
    function titleOwnerOf(uint256 _tokenId) public view override returns (address) {
        return _titleOwners[_tokenId];
    }

    /// @inheritdoc IERC721Reclaimable
    function titleApprove(address _to, uint256 _tokenId) public payable override {
        _tokenTitleApprovals[_tokenId] = _to;
        emit TitleApproval(msg.sender, _to, _tokenId);
    }

    /// @inheritdoc IERC721Reclaimable
    function getTitleApproved(uint256 _tokenId) public view override returns (address) {
        return _tokenTitleApprovals[_tokenId];
    }

    /// @inheritdoc IERC721Reclaimable
    function setTitleApprovalForAll(address _operator, bool _approved) public override {
        _titleOperatorApprovals[msg.sender][_operator] = _approved;
        emit TitleApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @inheritdoc IERC721Reclaimable
    function isTitleApprovedForAll(address _titleOwner, address _titleOperator) public view override returns (bool) {
        return _titleOperatorApprovals[_titleOwner][_titleOperator];
    }

    /// @inheritdoc IERC721Reclaimable
    function titleBalanceOf(address _titleOwner) public view override returns (uint256) {
        return _titleBalances[_titleOwner];
    }

    function mint(address to, uint256 tokenId) internal {
        _mint(to, tokenId);
        _titleMint(to, tokenId);
    }

    function _titleMint(address _to, uint256 _tokenId) internal {
        require(_to != address(0), "Cannot mint to 0 address");
        require(_titleOwners[_tokenId] == address(0), "Title already minted");
        _titleOwners[_tokenId] = _to;
        _titleBalances[_to] += 1;
        emit TitleTransfer(address(0), _to, _tokenId);
    }

    modifier onlyTitleOwnerOrOperator(uint256 tokenId) {
        address titleOwner = _titleOwners[tokenId];
        bool isTitleOwner = titleOwner == msg.sender;
        bool isApprovedForAll = this.isTitleApprovedForAll(titleOwner, msg.sender);
        if (!isTitleOwner && !isApprovedForAll) {
            revert InvalidTitleApprover(msg.sender);
        }
        _;
    }

    modifier onlyTitleOwnerOrOperatorOrApproved(uint256 tokenId) {
        address titleOwner = _titleOwners[tokenId];
        bool isTitleOwner = titleOwner == msg.sender;
        bool isApproved = this.getTitleApproved(tokenId) == msg.sender;
        bool isApprovedForAll = this.isTitleApprovedForAll(titleOwner, msg.sender);
        if (!isApproved && !isTitleOwner && !isApprovedForAll) revert NotTitleOwnerOrApprovedOrOperator(tokenId, msg.sender);
        _;
    }

    error NotTitleOwner(address _address);
    error NotTitleOwnerOrApprovedOrOperator(uint256 _tokenId, address _address);
    error InvalidTitleApprover(address _address);
    error TitleTransferFromInvalidTitleOwner(address _from, address _to, uint256 _tokenId);
    error InsufficientTitleTransferFee(address _from, address _to, uint256 _tokenId, uint256 _amount);
}