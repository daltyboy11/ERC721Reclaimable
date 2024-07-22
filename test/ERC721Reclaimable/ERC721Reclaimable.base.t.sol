// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {ERC721Reclaimable} from "../../src/ERC721Reclaimable.sol";

contract ERC721ReclaimableMintable is ERC721Reclaimable {
    constructor(
        string memory name,
        string memory symbol,
        uint256 titleTransferFee,
        address titleFeeRecipient,
        address minter
    ) ERC721Reclaimable(name, symbol, titleTransferFee, titleFeeRecipient) {
        for (uint256 i = 0; i < 10; i++) {
            mint(minter, i);
        }
    }
}

contract ERC721ReclaimableBaseTest is Test, IERC721Errors {
    ERC721ReclaimableMintable internal nft;
    address constant ROYALTY_BENEFICIARY = address(9248093483458);

    function setUp() public {
        nft = new ERC721ReclaimableMintable({
            name: "ReclaimableTestNft",
            symbol: "RTN",
            titleTransferFee: 1 ether,
            titleFeeRecipient: ROYALTY_BENEFICIARY,
            minter: address(this)
        });
    }
}