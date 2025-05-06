// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title Implementation1
contract Implementation1 is Initializable {
    uint256 public variable;

    // ctor
    constructor () {
        _disableInitializers();
    }

    // init
    function initialize(uint256 _initValue) external initializer {
        variable = _initValue;
    }

    // external
    function getMe() external view returns (uint256 _value) {
        return variable * 2;
    }
}

/// @title Implementation2
contract Implementation2 is Initializable {
    uint256 public variable;

    // ctor
    constructor () {
        _disableInitializers();
    }

    // init
    function initialize(uint256 _initValue) external initializer {
        variable = _initValue;
    }

    // external
    function getMe() external view returns (uint256 _value) {
        return variable * 3;
    }
}