// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

interface IERC721Reclaimable {
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

    /**
     * As the title owner, exercise your right to reclaim ownership of the asset.
     */
    function claimOwnership(uint256 tokenId) external;

    /**
     * Transfer title. The exchange is responsible for enforcing applicable royalty fees.
     */
    function titleTransferFrom(address to, address from, uint256 tokenId) external;

    function titleOwnerOf(uint256 tokenId) external view returns (address);

    function titleApprove(address to, uint256 tokenId) external;

    function getTitleApproved(uint256 tokenId) external view returns (address);

    function setTitleApprovalForAll(address operator, bool approved) external;

    function isTitleApprovedForAll(address titleOwner, address titleOperator) external view returns (bool);

    error NotTitleOwner(address _address);
    error NotTitleOwnerOrTitleOperator(address _address);
    error TitleTransferFromInvalidTitleOwner(address to, uint256 tokenId);
}