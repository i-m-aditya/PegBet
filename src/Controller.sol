// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {AggregatorV3Interface} from "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Controller {
    constructor() {
        // priceFeed = AggregatorV2V3Interface(_priceFeed);
    }

    event Log(string message);

    function getLatestPrice(address assetAddress) public returns (uint256) {
        // address usdcAddress = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
        AggregatorV3Interface priceFeed = AggregatorV3Interface(assetAddress);

        emit Log("getLatestPrice");
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }
}
