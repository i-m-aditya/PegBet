// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Vault.sol";

contract VaultFactory {
    // Will hardcode it
    address public owner;

    uint256 public pegIndex;

    constructor() {
        pegIndex = 0;
        // setting deployer as owner
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "VaultFactory: not controller");
        _;
    }

    struct PegbetMarket {
        Vault riskVault;
        Vault premiumVault;
    }

    mapping(uint256 => address[]) public pegMarkets;
    mapping(uint256 => PegbetMarket) public pegbetMarkets;

    function createNewMarket(
        ERC20 _asset,
        string memory _name, // PGB-MIM-998-epoch#RISK
        string memory _symbol, // pgb-mim
        address _oracle,
        uint256 _strikePrice, // strike price multiplied by 10**8
        uint256 startEpoch,
        uint256 endEpoch
    ) external onlyOwner returns (address) {
        require(
            startEpoch < endEpoch,
            "VaultFactory: startEpoch must be less than endEpoch"
        );
        Vault riskVault = new Vault(
            _asset,
            string(abi.encodePacked(_name, "-RISK")),
            _symbol,
            _oracle,
            _strikePrice,
            controller
        );

        Vault premiumVault = new Vault(
            _asset,
            string(abi.encodePacked(_name, "-PREMIUM")),
            _symbol,
            _oracle,
            _strikePrice,
            controller
        );

        pegbetMarkets[pegIndex] = PegbetMarket(riskVault, premiumVault);
        _startNewEpoch(startEpoch, endEpoch, pegIndex);
        pegIndex += 1;
    }

    function _startNewEpoch(
        uint256 startEpoch,
        uint256 endEpoch,
        uint256 _pegIndex
    ) internal {
        Vault riskVault = pegbetMarkets[_pegIndex].riskVault;
        Vault premiumVault = pegbetMarkets[_pegIndex].premiumVault;

        riskVault.startNewEpoch(endEpoch);
        premiumVault.startNewEpoch(endEpoch);
    }
}
