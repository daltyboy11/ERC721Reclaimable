// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {TitleExchangeBaseTest} from "./TitleExchange.base.t.sol";
import {TitleExchange} from "../../src/TitleExchange.sol";

contract TitleExchangeSubmitAskTest is TitleExchangeBaseTest {
    function testValidUntilInThePastReverts(uint256 validUntil) public {
        validUntil = bound(validUntil, 0, block.timestamp);
        vm.warp(validUntil);
        vm.expectRevert(
            abi.encodeWithSelector(TitleExchange.InvalidValidUntil.selector)
        );
        exchange.submitAsk({
            nft: nft,
            tokenId: 0,
            salePrice: 0,
            validUntil: validUntil
        });
    }

    function testNonTitleOwnerNonOperatorReverts(address fraudster) public {
        vm.assume(fraudster != address(this));
        vm.expectRevert(
            abi.encodeWithSelector(
                TitleExchange.NotTitleOwnerOrTitleOperator.selector,
                nft,
                0,
                fraudster
            )
        );
        vm.prank(fraudster);
        exchange.submitAsk({
            nft: nft,
            tokenId: 0,
            salePrice: 0,
            validUntil: block.timestamp + 1
        });
    }

    function testTitleOwnerCanSubmitAsk() public {
        exchange.submitAsk({
            nft: nft,
            tokenId: 0,
            salePrice: 0,
            validUntil: block.timestamp + 1
        });
    }

    function testTokenOperatorCanSubmitAsk(address operator) public {
        vm.assume(operator != address(this));
        nft.titleApprove(operator, 0);
        vm.startPrank(operator);
        exchange.submitAsk({
            nft: nft,
            tokenId: 0,
            salePrice: 0,
            validUntil: block.timestamp + 1
        });
    }

    function testContractOperatorCanSubmitAsk(address operator) public {
        vm.assume(operator != address(this));
        nft.setTitleApprovalForAll(operator, true);
        vm.startPrank(operator);
        exchange.submitAsk({
            nft: nft,
            tokenId: 0,
            salePrice: 0,
            validUntil: block.timestamp + 1
        });
    }

    function testSubmitAskSetsCorrectData(
        uint tokenId,
        uint salePrice,
        uint validUntil
    ) public {
        tokenId = bound(tokenId, 0, 9);
        validUntil = bound(validUntil, block.timestamp + 1, type(uint).max);

        exchange.submitAsk({
            nft: nft,
            tokenId: tokenId,
            salePrice: salePrice,
            validUntil: validUntil
        }); 

        (
            uint _tokenId,
            uint _salePrice,
            address _titleOwner,
            uint _titleTransferFee,
            uint _validUntil
        ) = exchange.asks(nft, tokenId);

        assertEq(_tokenId, tokenId);
        assertEq(_salePrice, salePrice);
        assertEq(_titleOwner, nft.titleOwnerOf(tokenId));
        assertEq(_titleTransferFee, nft.titleTransferFee());
        assertEq(_validUntil, validUntil);
    }

    function testResubmitAskOverwritesData(
        uint tokenId,
        uint salePrice1,
        uint validUntil1,
        uint salePrice2,
        uint validUntil2
    ) public {
        tokenId = bound(tokenId, 0, 9);
        validUntil1 = bound(validUntil1, block.timestamp + 1, type(uint).max);
        validUntil2 = bound(validUntil2, block.timestamp + 1, type(uint).max);

        exchange.submitAsk({
            nft: nft,
            tokenId: tokenId,
            salePrice: salePrice1,
            validUntil: validUntil1
        });
        exchange.submitAsk({
            nft: nft,
            tokenId: tokenId,
            salePrice: salePrice2,
            validUntil: validUntil2
        });

        (
            uint _tokenId,
            uint _salePrice,
            address _titleOwner,
            uint _titleTransferFee,
            uint _validUntil
        ) = exchange.asks(nft, tokenId);

        assertEq(_tokenId, tokenId);
        assertEq(_salePrice, salePrice2);
        assertEq(_titleOwner, nft.titleOwnerOf(tokenId));
        assertEq(_titleTransferFee, nft.titleTransferFee());
        assertEq(_validUntil, validUntil2);
    }
}