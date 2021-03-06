// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


// AggregatorV3Interface for tests
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';


/// @title AggregatorV3Mock
/// @notice
/// @dev
abstract contract AggregatorV3Mock is AggregatorV3Interface {
    uint8 private __decimals;
    string private __description;
    uint256 private __version;
    int256 private __latestRoundPrice;

    constructor(uint8 _decimals, int256 _price) {
        __decimals = _decimals;
        __latestRoundPrice = _price;
    }

    function setLatestRoundPrice(int256 _newPrice)
    public {
        __latestRoundPrice = _newPrice;
    }

    function decimals()
    override
    external
    view
    returns (uint8) {
        return __decimals;
    }

    function description()
    override
    external
    view
    returns (string memory) {
        return __description;
    }

    function version()
    override
    external
    view
    returns (uint256) {
        return __version;
    }

    function getRoundData(uint80 _roundId)
    override
    external
    pure
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (_roundId, 0, 0, 0, 0); // hardcoded to zeros, as we do not need that data
    }

    function latestRoundData()
    override
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (0, __latestRoundPrice, 0, 0, 0); // hardcoded to zeros, as we do not need that data
    }
}


contract EthAggregatorMock is AggregatorV3Mock {
    constructor(uint8 _decimals, int256 _price) AggregatorV3Mock(_decimals, _price) { }
}
contract LinkAggregatorMock is AggregatorV3Mock {
    constructor(uint8 _decimals, int256 _price) AggregatorV3Mock(_decimals, _price) { }
}
contract DaiAggregatorMock is AggregatorV3Mock {
    constructor(uint8 _decimals, int256 _price) AggregatorV3Mock(_decimals, _price) { }
}
contract BnbAggregatorMock is AggregatorV3Mock {
    constructor(uint8 _decimals, int256 _price) AggregatorV3Mock(_decimals, _price) { }
}