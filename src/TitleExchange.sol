// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC721Reclaimable} from "./ERC721Reclaimable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

contract TitleExchange {
    event AskSubmitted(
        ERC721Reclaimable indexed nft,
        uint256 indexed tokenId,
        address indexed titleOwner,
        uint256 titleTransferFee,
        uint256 salePrice
    );

    event TitlePurchased(
        ERC721Reclaimable indexed nft,
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 titleTransferFee,
        uint256 salePrice
    );

    struct Ask {
        uint256 tokenId;
        uint256 salePrice;
        address titleOwner;
        uint256 titleTransferFee;
        uint256 validUntil;
    }

    mapping(ERC721Reclaimable nft => mapping(uint256 tokenId => Ask)) asks;

    /**
     * Allow the title owner to submit an Ask for a title transfer
     */
    function submitAsk(ERC721Reclaimable nft, uint256 tokenId, uint256 salePrice, uint256 validUntil) public {
        require(validUntil > block.timestamp, "Invalid validUntil timestamp");
        require(salePrice > 0, "Cannot sell for 0");
        require(msg.sender == nft.titleOwnerOf(tokenId), "Not title owner");
        asks[nft][tokenId] = Ask({
            tokenId: tokenId,
            salePrice: salePrice,
            titleOwner: msg.sender,
            titleTransferFee: nft.titleTransferFee(),
            validUntil: validUntil
        });
        emit AskSubmitted({
            nft: nft,
            tokenId: tokenId,
            titleOwner: nft.titleOwnerOf(tokenId),
            titleTransferFee: nft.titleTransferFee(),
            salePrice: salePrice
        });
    }

    function purchaseTitle(ERC721Reclaimable nft, uint256 tokenId) public payable {
        Ask memory ask = asks[nft][tokenId];
        require(block.timestamp <= ask.validUntil, "Ask expired");
        require(msg.value >= ask.salePrice + ask.titleTransferFee, "Insufficient Funds");

        delete asks[nft][tokenId];

        address titleOwner = nft.titleOwnerOf(tokenId);
        nft.titleTransferFrom{ value: ask.titleTransferFee }(titleOwner, msg.sender, tokenId);

        // Pay the seller
        require(payable(titleOwner).send(ask.salePrice), "Failed to transfer funds to seller");

        emit TitlePurchased({
            nft: nft,
            tokenId: tokenId,
            buyer: msg.sender,
            titleTransferFee: ask.titleTransferFee,
            salePrice: ask.salePrice
        });
    }
}