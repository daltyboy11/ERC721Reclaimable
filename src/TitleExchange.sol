// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC721Reclaimable} from "./ERC721Reclaimable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

contract TitleExchange {
    event AskSubmitted(
        ERC721Reclaimable indexed nft,
        uint256 indexed tokenId,
        address indexed titleOwner,
        uint256 salePrice,
        address royaltyBeneficiary,
        uint256 royaltyAmount
    );

    event TitlePurchased(
        ERC721Reclaimable indexed nft,
        uint256 indexed tokenId,
        address indexed titleBuyer,
        uint256 salePrice,
        address royaltyBeneficiary,
        uint256 royaltyAmount
    );

    struct Ask {
        uint256 tokenId;
        uint256 salePrice;
        address royaltyBeneficiary;
        uint256 royaltyAmount;
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
        (address beneficiary, uint256 royaltyAmount) = nft.royaltyInfo(tokenId, salePrice);
        asks[nft][tokenId] = Ask(tokenId, salePrice, beneficiary, royaltyAmount, validUntil);
        emit AskSubmitted({
            nft: nft,
            tokenId: tokenId,
            titleOwner: nft.titleOwnerOf(tokenId),
            salePrice: salePrice,
            royaltyBeneficiary: beneficiary,
            royaltyAmount: royaltyAmount
        });
    }

    function purchaseTitle(ERC721Reclaimable nft, uint256 tokenId) public payable {
        Ask memory ask = asks[nft][tokenId];
        require(block.timestamp <= ask.validUntil, "Ask expired");
        require(msg.value >= ask.salePrice + ask.royaltyAmount, "Insufficient Funds");
        delete asks[nft][tokenId];
        address titleOwner = nft.titleOwnerOf(tokenId);
        nft.titleTransferFrom(titleOwner, msg.sender, tokenId);
        // Pay the seller
        require(payable(titleOwner).send(ask.salePrice), "Failed to transfer funds to seller");
        // Pay the beneficiary
        require(payable(ask.royaltyBeneficiary).send(ask.royaltyAmount), "Failed to transfer funds to beneficiary");
        emit TitlePurchased({
            nft: nft,
            tokenId: tokenId,
            titleBuyer: msg.sender,
            salePrice: ask.salePrice,
            royaltyBeneficiary: ask.royaltyBeneficiary,
            royaltyAmount: ask.royaltyAmount
        });
    }
}