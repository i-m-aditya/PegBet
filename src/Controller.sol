// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {AggregatorV3Interface} from "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {VaultFactory} from "./VaultFactory.sol";
import {Vault} from "./Vault.sol";

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

contract Controller {
    using FixedPointMathLib for uint256;
    address public owner;

    address public vaultFactoryAddress;

    error MarketDoesNotExist();

    // temp
    function getVaultFactoryAddress() public view returns (address) {
        return vaultFactoryAddress;
    }

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

    event DepegTriggered(uint256 marketId, uint256 epochId);

    function getLatestPrice(address assetAddress) public returns (uint256) {
        // address usdcAddress = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
        AggregatorV3Interface priceFeed = AggregatorV3Interface(assetAddress);

        string memory description = priceFeed.description();

        emit Log(description);
        // emit Log("getLatestPrice");
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function triggerDepeg(uint256 marketId, uint256 epochId) public onlyOwner {
        // address usdcAddress = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
        VaultFactory vaultFactory = VaultFactory(vaultFactoryAddress);

        address payable[] memory vaultsAddresses = vaultFactory
            .getVaultsForMaketId(marketId);

        if (
            vaultsAddresses[0] == address(0) || vaultsAddresses[1] == address(0)
        ) {
            revert MarketDoesNotExist();
        }

        Vault riskVault = Vault(payable(vaultsAddresses[0]));
        Vault premiumVault = Vault(payable(vaultsAddresses[1]));

        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            riskVault.oracle()
        );

        (, int256 price, , , ) = priceFeed.latestRoundData();

        require(
            price < riskVault.strikePrice(),
            "Controller: price is more than strike price"
        );

        uint256 premiumFinalTVL = premiumVault.vaultFinalTVL(epochId);
        uint256 riskFinalTVL = riskVault.vaultFinalTVL(epochId);

        riskVault.transferAssets(epochId, address(premiumVault), riskFinalTVL);
        premiumVault.transferAssets(
            epochId,
            address(riskVault),
            premiumFinalTVL
        );

        premiumVault.setVaultClaimableTVL(epochId, riskFinalTVL);
        riskVault.setVaultClaimableTVL(epochId, premiumFinalTVL);

        // End Epoch after depeging
        riskVault.setEpochState(epochId, 2);
        premiumVault.setEpochState(epochId, 2);

        emit DepegTriggered(marketId, epochId);
    }

    function expireEpochWithoutDepeg(uint256 marketId) public onlyOwner {
        VaultFactory vaultFactory = VaultFactory(vaultFactoryAddress);

        address payable[] memory marketVaults = vaultFactory
            .getVaultsForMaketId(marketId);

        Vault riskVault = Vault(marketVaults[0]);
        Vault premiumVault = Vault(marketVaults[1]);

        uint256 premiumFinalTVL = premiumVault.vaultFinalTVL(marketId);
        uint256 riskFinalTVL = riskVault.vaultFinalTVL(marketId);

        premiumVault.setVaultClaimableTVL(marketId, 0);
        riskVault.setVaultClaimableTVL(
            marketId,
            premiumFinalTVL + riskFinalTVL
        );

        riskVault.setEpochState(marketId, 2);
        premiumVault.setEpochState(marketId, 2);
    }

    function expireNullEpoch(uint256 marketId) public onlyOwner {
        VaultFactory vaultFactory = VaultFactory(vaultFactoryAddress);
        address payable[] memory marketVaults = vaultFactory
            .getVaultsForMaketId(marketId);

        Vault riskVault = Vault(marketVaults[0]);
        Vault premiumVault = Vault(marketVaults[1]);

        uint256 premiumFinalTVL = premiumVault.vaultFinalTVL(marketId);
        uint256 riskFinalTVL = riskVault.vaultFinalTVL(marketId);

        premiumVault.setVaultClaimableTVL(marketId, premiumFinalTVL);
        riskVault.setVaultClaimableTVL(marketId, riskFinalTVL);

        riskVault.setEpochState(marketId, 1);
        premiumVault.setEpochState(marketId, 1);
    }

    function stopDepositsAndStartEpoch(uint256 marketId) public onlyOwner {
        VaultFactory vaultFactory = VaultFactory(vaultFactoryAddress);

        address payable[] memory vaultsAddress = vaultFactory
            .getVaultsForMaketId(marketId);

        Vault riskVault = Vault(vaultsAddress[0]);
        Vault premiumVault = Vault(vaultsAddress[1]);

        riskVault.setEpochState(marketId, 1);
        premiumVault.setEpochState(marketId, 1);
    }
}
