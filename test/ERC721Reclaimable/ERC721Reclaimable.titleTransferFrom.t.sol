// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC721ReclaimableBaseTest} from "./ERC721Reclaimable.base.t.sol";
import {IERC721Reclaimable} from "../../src/interfaces/IERC721Reclaimable.sol";

contract ERC721ReclaimableTitleTransferFromTest is ERC721ReclaimableBaseTest {
    function executeTitleTransfer(address from, address to, uint256 tokenId, uint256 fee) private {
        vm.deal(from, fee);
        vm.prank(from);
        nft.titleTransferFrom{ value: fee }(from, to, tokenId);
    }

    function testTitleTransferFromRevertsForInsuffcientFunds(uint256 amount) public {
        amount = bound(amount, 0, nft.titleTransferFee() - 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC721Reclaimable.InsufficientTitleTransferFee.selector,
                address(this),
                address(1),
                1,
                amount
            )
        );
        executeTitleTransfer(address(this), address(1), 1, amount);
    }

    function testTitleTransferFromCallableByTitleOwner() public {
        executeTitleTransfer(address(this), address(0), 0, nft.titleTransferFee());
    }

    function testTitleTransferFromCallableByTokenApprovedOperator() public {
        nft.titleApprove(address(1), 2);
        executeTitleTransfer(address(1), address(0), 2, nft.titleTransferFee());
    }

    function testTitleTransferFromCallableByAllApprovedOperator() public {
        nft.setTitleApprovalForAll(address(1), true);
        executeTitleTransfer(address(1), address(0), 0, nft.titleTransferFee());
        executeTitleTransfer(address(1), address(0), 1, nft.titleTransferFee());
    }

    function testTitleTransferFromChangesTitleOwner() public {
        executeTitleTransfer(address(this), address(1), 9, nft.titleTransferFee());
        assertEq(nft.titleOwnerOf(9), address(1));
    }

    function testTitleTransferFromTransfersTheTitleFee() public {
        uint balanceBefore = TITLE_FEE_RECIPIENT.balance;
        executeTitleTransfer(address(this), address(1), 9, nft.titleTransferFee());
        uint balanceAfter = TITLE_FEE_RECIPIENT.balance;
        assertEq(balanceAfter - balanceBefore, nft.titleTransferFee());
    }

    function testTitleTransferFromDoesNotChangeAssetOwnership() public {
        executeTitleTransfer(address(this), address(1), 3, nft.titleTransferFee());
        assertEq(nft.ownerOf(3), address(this));
    }

    function testTitleTransferFromEmitsTitleTransferEvent() public {
        vm.expectEmit(true, true, true, true);
        emit IERC721Reclaimable.TitleTransfer(address(this), address(5), 1);
        executeTitleTransfer(address(this), address(5), 1, nft.titleTransferFee());
    }
}