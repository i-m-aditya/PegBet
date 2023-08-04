// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {AggregatorV3Interface} from "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// import {EACAggregatorProxy} from "chainlink/contracts/src/v0.8/EACAggregatorProxy.sol";

contract Controller {
    constructor() {}

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
}
