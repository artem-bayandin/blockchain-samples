// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library StringComparison {
    function _equalToEmpty(string memory _a)
    internal
    pure
    returns (bool) {
        return keccak256(bytes(_a)) == keccak256(bytes(""));
    }
    function _notEqualToEmpty(string memory _a)
    internal
    pure
    returns (bool) {
        return keccak256(bytes(_a)) != keccak256(bytes(""));
    }

    function _equalTo(string memory _a, string memory _b)
    internal
    pure
    returns (bool) {
        return keccak256(bytes(_a)) == keccak256(bytes(_b));
    }

    function _notEqualTo(string memory _a, string memory _b)
    internal
    pure
    returns (bool) {
        return keccak256(bytes(_a)) != keccak256(bytes(_b));
    }
}