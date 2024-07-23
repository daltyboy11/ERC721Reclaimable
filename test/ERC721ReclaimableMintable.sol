// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC721Reclaimable} from "../src/ERC721Reclaimable.sol";

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