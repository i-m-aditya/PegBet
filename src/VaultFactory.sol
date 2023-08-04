// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract VaultFactory {
    function createVault() public returns (address) {
        Vault vault = new Vault();
        return address(vault);
    }
}
