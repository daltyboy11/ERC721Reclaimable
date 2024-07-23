// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC721ReclaimableBaseTest} from "./ERC721Reclaimable.base.t.sol";
import {IERC721Reclaimable} from "../../src/interfaces/IERC721Reclaimable.sol";

contract ERC721ReclaimableClaimOwnershipTest is ERC721ReclaimableBaseTest {
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
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC721Reclaimable.NotTitleOwnerOrTitleOperator.selector,
                nonTitleOwner
            )
        );
        nft.claimOwnership(0);
    }

    function testTitleOwnerIsAlsoAssetOwnerCanClaimOwnership() public {
        nft.claimOwnership(0);
    }

    function testTitleApprovedOperatorCanClaimOwnership(
        address titleApprovedOperator,
        address newOwner
    ) public {
        vm.assume(titleApprovedOperator != address(this) && titleApprovedOperator != address(0) && titleApprovedOperator != newOwner);
        vm.assume(newOwner != address(this) && newOwner != address(0));
        nft.titleApprove(titleApprovedOperator, 1);
        nft.transferFrom(address(this), newOwner, 1);
        assertEq(nft.ownerOf(1), newOwner);
        vm.prank(titleApprovedOperator);
        nft.claimOwnership(1);
        assertEq(nft.ownerOf(1), address(this));
    }

    function testTitleAllApprovedOperatorCanClaimOwnership(
        address allTitleApprovedOperator,
        address newOwner
    ) public {
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