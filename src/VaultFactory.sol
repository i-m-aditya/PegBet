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

    // struct PegbetMarket {
    //     Vault riskVault;
    //     Vault premiumVault;
    //     uint256 startEpoch;
    //     uint256 endEpoch;
    // }
    mapping(uint256 => address payable[]) public marketVaults;

    function createNewMarket(
        ERC20 _asset,
        string memory _name, // PGB-MIM-998-epoch#RISK
        string memory _symbol, // pgb-mim
        address _oracle,
        int256 _strikePrice, // strike price multiplied by 10**8
        uint256 startEpoch,
        uint256 endEpoch
    ) external onlyOwner returns (address payable[] memory) {
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
        return marketVaults[marketId];
    }

    function _startNewEpoch(
        uint256 startEpoch,
        uint256 endEpoch,
        uint256 _marketId
    ) internal {
        Vault riskVault = Vault(marketVaults[_marketId][0]);
        Vault premiumVault = Vault(marketVaults[_marketId][1]);

        riskVault.startNewEpoch(endEpoch);
        premiumVault.startNewEpoch(endEpoch);
    }

    function setController(address _controller) external onlyOwner {
        controller = _controller;
    }

    function getVaultsForMaketId(
        uint256 _marketId
    ) external view returns (address payable[] memory) {
        return marketVaults[_marketId];
    }
}
