// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {AggregatorV3Interface} from "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {VaultFactory} from "./VaultFactory.sol";
import {Vault} from "./Vault.sol";

contract Controller {
    address public owner;

    address public vaultFactoryAddress;

    constructor(address _vaultFactoryAddress) {
        owner = msg.sender;
        vaultFactoryAddress = _vaultFactoryAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Controller: not owner");
        _;
    }

    event Log(string message);
    event Log2(uint80 message);

    function getLatestPrice(address assetAddress) public returns (uint256) {
        // address usdcAddress = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
        AggregatorV3Interface priceFeed = AggregatorV3Interface(assetAddress);

        string memory description = priceFeed.description();

        emit Log(description);
        // emit Log("getLatestPrice");
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function triggerDepeg(uint256 marketId) public returns (uint256) {
        // address usdcAddress = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
        VaultFactory vaultFactory = VaultFactory(vaultFactoryAddress);

        address[] memory marketVaults = vaultFactory.marketVaults(marketId);

        AggregatorV3Interface priceFeed = AggregatorV3Interface(assetAddress);

        (, int256 price, , , ) = priceFeed.latestRoundData();

        Vault riskVault = Vault(marketVaults[0]);
        Vault premiumVault = Vault(marketVaults[1]);

        require(
            price <= riskVault.strikePrice(),
            "Controller: price is less than strike price"
        );

        uint256 riskFinalTVL = riskVault.vaultFinalTVL();

        uint256 premiumFinalTVL = premiumVault.vaultFinalTVL();

        premiumVault.setVaultClaimableTVL(riskFinalTVL);
        riskVault.setVaultClaimableTVL(premiumFinalTVL);

        // End Epoch after depeging
        riskVault.setEpochState(2);
        premiumVault.setEpochState(2);
    }

    function expireEpochWithoutDepeg(
        uint256 marketId
    ) public returns (uint256) {
        VaultFactory vaultFactory = VaultFactory(vaultFactoryAddress);

        address[] memory marketVaults = vaultFactory.marketVaults(marketId);

        Vault riskVault = Vault(marketVaults[0]);
        Vault premiumVault = Vault(marketVaults[1]);

        uint256 premiumFinalTVL = premiumVault.vaultFinalTVL();
        uint256 riskFinalTVL = riskVault.vaultFinalTVL();

        riskVault.setVaultClaimableTVL(premiumFinalTVL + riskFinalTVL);

        riskVault.setEpochState(2);
        premiumVault.setEpochState(2);
    }

    function stopDepositsAndStartEpoch(uint256 pegMarketId) public onlyOwner {
        VaultFactory vaultFactory = VaultFactory(vaultFactoryAddress);

        address[] memory pegMarkets = vaultFactory.pegMarkets(pegMarketId);

        Vault riskVault = Vault(pegMarkets[0]);
        Vault premiumVault = Vault(pegMarkets[1]);

        riskVault.setEpochState(1);
        premiumVault.setEpochState(1);
    }
}
