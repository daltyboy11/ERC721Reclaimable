// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC721ReclaimableBaseTest} from "./ERC721Reclaimable.base.t.sol";
import {IERC721Reclaimable} from "../src/interfaces/IERC721Reclaimable.sol";

contract ERC721ReclaimableTitleOwnerOfTest is ERC721ReclaimableBaseTest {
    function testTitleOwnerOfOwner() public view {
        assertEq(nft.titleOwnerOf(0), address(this));
    }

    function testTitleOwnerOfNotOwner(address notOwner) public view {
        vm.assume(notOwner != address(this));
        assertNotEq(nft.titleOwnerOf(0), notOwner);
    }
}