// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC721ReclaimableBaseTest} from "./ERC721Reclaimable.base.t.sol";
import {IERC721Reclaimable} from "../src/interfaces/IERC721Reclaimable.sol";

contract ERC721ReclaimableTitleTransferFromTest is ERC721ReclaimableBaseTest {
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
}