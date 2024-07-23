// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {TitleExchangeBaseTest} from "./TitleExchange.base.t.sol";
import {TitleExchange} from "../../src/TitleExchange.sol";

contract TitleExchangePurchaseTitleTest is TitleExchangeBaseTest {
    function testRevertsIfExpired() public {
        uint validUntil = block.timestamp + 1;
        exchange.submitAsk({
            nft: nft,
            tokenId: 0,
            salePrice: 1 ether,
            validUntil: validUntil 
        });
        vm.warp(validUntil + 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                TitleExchange.AskExpired.selector,
                nft,
                0,
                validUntil
            )
        );
        exchange.purchaseTitle(nft, 0);
    }

    function testRevertsForInsufficientFunds(uint amount) public {
        amount = bound(amount, 0, 1 ether + nft.titleTransferFee() - 1);
        exchange.submitAsk({
            nft: nft,
            tokenId: 0,
            salePrice: 1 ether,
            validUntil: block.timestamp + 1
        });
        vm.expectRevert(
            abi.encodeWithSelector(
                TitleExchange.InsufficientFunds.selector,
                nft,
                0,
                1 ether + nft.titleTransferFee()
            )
        );
        vm.deal(address(this), amount);
        exchange.purchaseTitle{ value: amount }(nft, 0);
    }

    function testRevertsIfTitleOwnerChanged(address newTitleOwner) public {
        vm.assume(newTitleOwner != address(this));

        exchange.submitAsk({
            nft: nft,
            tokenId: 0,
            salePrice: 1 ether,
            validUntil: block.timestamp + 1
        });

        vm.deal(address(this), nft.titleTransferFee());
        nft.titleTransferFrom{ value: nft.titleTransferFee() }(address(this), newTitleOwner, 0);

        assertEq(nft.titleOwnerOf(0), newTitleOwner);

        uint totalCost = 1 ether + nft.titleTransferFee();
        vm.deal(address(this), totalCost);
        vm.expectRevert(
            abi.encodeWithSelector(
                TitleExchange.TitleOwnerChanged.selector,
                nft,
                0,
                newTitleOwner,
                address(this)
            )
        );
        exchange.purchaseTitle{ value: totalCost }(nft, 0);
    }

    function testSuccess(
        address buyer,
        uint tokenId,
        uint salePrice
    ) public {
        vm.assume(buyer != address(this));
        tokenId = bound(tokenId, 0, 9);
        salePrice = bound(salePrice, 0, 1000 ether - nft.titleTransferFee());

        exchange.submitAsk({
            nft: nft,
            tokenId: tokenId,
            salePrice: salePrice,
            validUntil: block.timestamp + 1
        });
        nft.titleApprove(address(exchange), tokenId);

        uint sellerBalanceBefore = address(this).balance;

        uint transferFee = nft.titleTransferFee();
        uint totalCost = salePrice + transferFee;
        vm.deal(buyer, totalCost);
        vm.prank(buyer);
        vm.expectEmit(true, true, true, true);
        emit TitleExchange.TitlePurchased({
            nft: nft,
            tokenId: tokenId,
            buyer: buyer,
            titleTransferFee: transferFee,
            salePrice: salePrice
        });
        exchange.purchaseTitle{ value: totalCost }(nft, tokenId);

        // Seller's balance increased by sale price
        uint sellerBalanceAfter = address(this).balance;
        assertEq(sellerBalanceAfter - sellerBalanceBefore, salePrice);

        // Balance of the exchange has not changed
        assertEq(address(exchange).balance, 0);

        // Ask is deleted
        (
            uint _tokenId,
            uint _salePrice,
            address _titleOwner,
            uint _titleTransferFee,
            uint _validUntil
        ) = exchange.asks(nft, tokenId);
        assertEq(_tokenId, 0);
        assertEq(_salePrice, 0);
        assertEq(_titleOwner, address(0));
        assertEq(_titleTransferFee, 0);
        assertEq(_validUntil, 0);

        // Title owner is now the buyer
        assertEq(nft.titleOwnerOf(tokenId), buyer);
    }
}