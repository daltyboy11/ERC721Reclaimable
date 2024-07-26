// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC721Reclaimable} from "./ERC721Reclaimable.sol";

contract DaltonERC721Reclaimable is ERC721Reclaimable {
    uint256 public mintFee;
    uint256 public constant MAX_SUPPLY = 100;

    address[] private whitelist;
    string private __baseUri;

    constructor(address[] memory _whitelist, uint256 _mintFee, string memory ___baseUri) 
        ERC721Reclaimable(
            "Poe Token",
            "PNFT",
            0.0003 ether,
            0xAe42B13CF992FeB85eEEf0c8B91FDDbFe721C02c
        ) 
    {
        whitelist = _whitelist;
        mintFee = _mintFee;
        __baseUri = ___baseUri;
    }

    function mint(uint256 tokenId) public payable {
        require(tokenId < MAX_SUPPLY, "Minting over: All tokens have been minted");
        
        bool isWhitelisted = _isWhitelisted(msg.sender);
        if (!isWhitelisted && msg.value < mintFee) {
            revert InsufficientMintFee();
        }

        mint(msg.sender, tokenId);
    }

    function _isWhitelisted(address _address) internal view returns (bool) {
        for (uint256 i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseUri;
    }

    error InsufficientMintFee();
}
