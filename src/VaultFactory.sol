// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Vault.sol";

contract VaultFactory {
    // Will hardcode it
    address public owner;

    address public controller;

    uint256 public marketId;

    constructor() {
        marketId = 0;
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
        uint256 startEpoch;
        uint256 endEpoch;
    }
    mapping(uint256 => address payable[]) public marketVaults;

    function createNewMarket(
        ERC20 _asset,
        string memory _name, // PGB-MIM-998-epoch#RISK
        string memory _symbol, // pgb-mim
        address _oracle,
        int256 _strikePrice, // strike price multiplied by 10**8
        uint256 startEpoch,
        uint256 endEpoch
    ) external onlyOwner returns (uint256) {
        require(
            startEpoch < endEpoch,
            "VaultFactory: startEpoch must be less than endEpoch"
        );
        Vault riskVault = new Vault(
            _asset,
            string(abi.encodePacked(_name, "#RISK")),
            string(abi.encodePacked(_symbol, "#risk")),
            _oracle,
            _strikePrice,
            controller
        );

        Vault premiumVault = new Vault(
            _asset,
            string(abi.encodePacked(_name, "#PREMIUM")),
            string(abi.encodePacked(_symbol, "#premium")),
            _oracle,
            _strikePrice,
            controller
        );

        // indexMarkets[marketId] = PegbetMarket(
        //     riskVault,
        //     premiumVault,
        //     startEpoch,
        //     endEpoch
        // );
        marketId += 1;
        marketVaults[marketId] = [
            payable(address(riskVault)),
            payable(address(premiumVault))
        ];
        _startNewEpoch(startEpoch, endEpoch, marketId);
        return marketId;
    }

    function deployNewExpiryForExistingVault(
        uint256 _marketId,
        uint256 startEpoch,
        uint256 endEpoch
    ) public onlyOwner returns (uint256) {
        require(
            startEpoch < endEpoch,
            "VaultFactory: startEpoch must be less than endEpoch"
        );

        _startNewEpoch(startEpoch, endEpoch, _marketId);

        return marketId;
    }

    function _startNewEpoch(
        uint256 startEpoch,
        uint256 endEpoch,
        uint256 _marketId
    ) internal {
        Vault riskVault = Vault(marketVaults[_marketId][0]);
        Vault premiumVault = Vault(marketVaults[_marketId][1]);

        riskVault.startNewEpoch(startEpoch, endEpoch);
        premiumVault.startNewEpoch(startEpoch, endEpoch);
    }

    function setController(address _controller) external onlyOwner {
        controller = _controller;
    }

    event MarketVault(address payable[] vaults);

    function getVaultsForMaketId(
        uint256 _marketId
    ) external returns (address payable[] memory) {
        emit MarketVault(marketVaults[_marketId]);
        return marketVaults[_marketId];
    }
}
