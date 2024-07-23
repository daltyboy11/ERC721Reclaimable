// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {ERC721ReclaimableMintable} from "../ERC721ReclaimableMintable.sol";
import {TitleExchange} from "../../src/TitleExchange.sol";

contract TitleExchangeBaseTest is Test {
    address constant TITLE_FEE_RECIPIENT = address(9248093483458);
    ERC721ReclaimableMintable nft;
    TitleExchange exchange;

    function setUp() public {
        nft = new ERC721ReclaimableMintable({
            name: "ReclaimableTestNft",
            symbol: "RTN",
            titleTransferFee: 1 ether,
            titleFeeRecipient: TITLE_FEE_RECIPIENT,
            minter: address(this)
        });
        exchange = new TitleExchange();
    }
}