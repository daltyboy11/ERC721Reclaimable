// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {ERC721Reclaimable} from "../src/ERC721Reclaimable.sol";
import {IERC721Reclaimable} from "../src/interfaces/IERC721Reclaimable.sol";

contract ERC721ReclaimableMintable is ERC721Reclaimable {
    constructor(
        string memory name,
        string memory symbol,
        address royaltyBeneficiary,
        uint96 royaltyBps,
        address minter
    ) ERC721Reclaimable(name, symbol, royaltyBeneficiary, royaltyBps) {
        for (uint256 i = 0; i < 10; i++) {
            mint(minter, i);
        }
    }
}

contract ERC721ReclaimableTest is Test, IERC721Errors {
    ERC721ReclaimableMintable private nft;

    function setUp() public {
        nft = new ERC721ReclaimableMintable(
            "ReclaimableTestNft",
            "RTN",
            address(this),
            200,
            address(this)
        );
    }

    /**
     * titleOwnerOF
     */
    function testTitleOwnerOfOwner() public view {
        assertEq(nft.titleOwnerOf(0), address(this));
    }

    function testTitleOwnerOfNotOwner(address notOwner) public view {
        vm.assume(notOwner != address(this));
        assertNotEq(nft.titleOwnerOf(0), notOwner);
    }

    /**
     * titleTransferFrom
     */
    function testTitleTransferFromCallableByTitleOwner() public {
        nft.titleTransferFrom(address(this), address(0), 0);
    }

    function testTitleTransferFromCallableByTokenApprovedOperator() public {
        nft.titleApprove(address(1), 2);
        vm.prank(address(1));
        nft.titleTransferFrom(address(this), address(0), 2);
    }

    function testTitleTransferFromCallableByAllApprovedOperator() public {
        nft.setTitleApprovalForAll(address(1), true);
        vm.startPrank(address(1));
        nft.titleTransferFrom(address(this), address(0), 0);
        nft.titleTransferFrom(address(this), address(0), 1);
    }

    function testTitleTransferFromChangesTitleOwner() public {
        nft.titleTransferFrom(address(this), address(1), 9);
        assertEq(nft.titleOwnerOf(9), address(1));
    }

    function testTitleTransferFromDoesNotChangeAssetOwnership() public {
        nft.titleTransferFrom(address(this), address(1), 3);
        assertEq(nft.ownerOf(3), address(this));
    }

    function testTitleTransferFromEmitsTitleTransferEvent() public {
        vm.expectEmit(true, true, true, true);
        emit IERC721Reclaimable.TitleTransfer(address(this), address(5), 1);
        nft.titleTransferFrom(address(this), address(5), 1);
    }

    /**
     * transferFrom
     */
    function testTransferFromDoesNotChangeTitleOwnership() public {
        nft.transferFrom(address(this), address(4), 2);
        assertEq(nft.titleOwnerOf(2), address(this));
    }

    function testTransferFromNotCallableByTitleOwnerIfTheyDontOwnIt() public {
        nft.transferFrom(address(this), address(3), 1);
        vm.expectRevert(abi.encodeWithSelector(ERC721InsufficientApproval.selector, 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496, 1));
        nft.transferFrom(address(3), address(this), 1);
    }

    /**
     * claimOwnership
     */
    function testTitleOwnerCanClaimOwnership(address assetOwner) public {
        vm.assume(assetOwner != address(this));
        nft.transferFrom(address(this), assetOwner, 0);
        assertEq(nft.ownerOf(0), assetOwner);
        nft.claimOwnership(0);
        assertEq(nft.ownerOf(0), address(this));
    }

    function testNonTitleOwnerCantClaimOwnership(address nonTitleOwner) public {
        vm.assume(nonTitleOwner != address(this) && nonTitleOwner != address(0));
        nft.transferFrom(address(this), nonTitleOwner, 0);
        assertEq(nft.ownerOf(0), nonTitleOwner);
        vm.prank(nonTitleOwner);
        vm.expectRevert(abi.encodeWithSelector(IERC721Reclaimable.NotTitleOwnerOrTitleOperator.selector, nonTitleOwner));
        nft.claimOwnership(0);
    }

    function testTitleOwnerIsAlsoAssetOwnerCanClaimOwnership() public {
        nft.claimOwnership(0);
    }

    function testTitleApprovedOperatorCanClaimOwnership(address titleApprovedOperator, address newOwner) public {
        vm.assume(titleApprovedOperator != address(this) && titleApprovedOperator != address(0) && titleApprovedOperator != newOwner);
        vm.assume(newOwner != address(this) && newOwner != address(0));
        nft.titleApprove(titleApprovedOperator, 1);
        nft.transferFrom(address(this), newOwner, 1);
        assertEq(nft.ownerOf(1), newOwner);
        vm.prank(titleApprovedOperator);
        nft.claimOwnership(1);
        assertEq(nft.ownerOf(1), address(this));
    }

    function testTitleAllApprovedOperatorCanClaimOwnership(address allTitleApprovedOperator, address newOwner) public {
        vm.assume(allTitleApprovedOperator != address(this) && allTitleApprovedOperator != address(0) && allTitleApprovedOperator != newOwner);
        vm.assume(newOwner != address(this) && newOwner != address(0));
        nft.setTitleApprovalForAll(allTitleApprovedOperator, true);
        nft.transferFrom(address(this), newOwner, 1);
        assertEq(nft.ownerOf(1), newOwner);
        vm.prank(allTitleApprovedOperator);
        nft.claimOwnership(1);
        assertEq(nft.ownerOf(1), address(this));
    }
}