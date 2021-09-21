// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import '@chainlink/contracts/src/v0.8/VRFConsumerBase.sol';
import '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';


contract LinkTokenMock is LinkTokenInterface {
    function allowance(address owner, address spender)
    override
    external
    pure
    returns (uint256 remaining) {
        owner = address(0);
        spender = address(0);
        return 2 ** 128;
    }

    function approve(address spender, uint256 value)
    override
    external
    pure
    returns (bool success) {
        spender = address(0);
        value = 0;
        return true;
    }

    function balanceOf(address owner)
    override
    external
    pure
    returns (uint256 balance) {
        owner = address(0);
        return 2 ** 128;
    }

    function decimals()
    override
    external
    pure
    returns (uint8 decimalPlaces) {
        return 18;
    }

    function decreaseApproval(address spender, uint256 addedValue)
    override
    external
    pure
    returns (bool success) {
        spender = address(0);
        addedValue = 0;
        return true;
    }

    function increaseApproval(address spender, uint256 subtractedValue)
    override
    external {
        // empty
    }

    function name()
    override
    external
    pure
    returns (string memory tokenName) {
        return 'LINK mock';
    }

    function symbol()
    override
    external
    pure
    returns (string memory tokenSymbol) {
        return 'LINKMock';
    }

    function totalSupply()
    override
    external
    pure
    returns (uint256 totalTokensIssued) {
        return 2 ** 128;
    }

    function transfer(address to, uint256 value)
    override
    external
    pure
    returns (bool success) {
        to = address(0);
        value = 0;
        return true;
    }

    // called
    function transferAndCall(address to, uint256 value, bytes calldata data)
    override
    external
    pure
    returns (bool success) {
        to = address(0);
        value = 0;
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
    override
    external
    pure
    returns (bool success) {
        from = address(0);
        to = address(0);
        value = 0;
        return true;
    }
}