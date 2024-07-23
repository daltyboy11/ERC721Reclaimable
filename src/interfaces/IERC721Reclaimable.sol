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

    /**
     * @dev Emitted when titleOwner exercises their right to reclaim the asset
     * @param titleOwner The title owner claiming ownership
     * @param assetOwner The asset owner from which the asset was claimed
     * @param tokenId The asset claimed
     */
    event OwnershipClaimed(address indexed titleOwner, address indexed assetOwner, uint256 tokenId);

    function titleTransferFee() external view returns (uint256);

    /**
     * As the title owner, exercise your right to reclaim ownership of the asset.
     */
    function claimOwnership(uint256 tokenId) external;

    /**
     * Transfer title.
     * The title owner, title approved operator, and all title approved operator are authorized to execute a title transfer
     * The exchange is responsible for enforcing applicable royalty fees.
     */
    function titleTransferFrom(address from, address to, uint256 tokenId) external payable;

    /**
     * Title owner of ae asset
     */
    function titleOwnerOf(uint256 tokenId) external view returns (address);

    /**
     * As the title owner, delegate title management to another address
     * 
     * @param to address delegated to
     * @param tokenId asset whose title is being delegated
     */
    function titleApprove(address to, uint256 tokenId) external;

    function getTitleApproved(uint256 tokenId) external view returns (address);

    function setTitleApprovalForAll(address operator, bool approved) external;

    function isTitleApprovedForAll(address titleOwner, address titleOperator) external view returns (bool);

    error NotTitleOwner(address _address);
    error NotTitleOwnerOrTitleOperator(uint256 tokenId, address _address);
    error TitleTransferFromInvalidTitleOwner(address from, address to, uint256 tokenId);
    error InsufficientTitleTransferFee(address from, address to, uint256 tokenId, uint256 amount);
}