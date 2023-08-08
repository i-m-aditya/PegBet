// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";

import {ERC1155Supply} from "openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";

contract PartialFungibleVault is ERC1155Supply {
    ERC20 public immutable asset;
    string public name;
    string public symbol;
    bytes internal constant EMPTY = "";

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC1155("") {
        name = _name;
        symbol = _symbol;
        asset = _asset;
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        _mint(account, id, amount, data);
    }

    function totalAssets(uint256 id) public view returns (uint256) {
        return totalSupply(id);
    }

    receive() external payable {}
}
