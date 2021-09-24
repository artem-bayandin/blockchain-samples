// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


interface IPriceOracle {
    /// @notice Main function of a PriceOracle - get ETH equivalent of a ERC20 token
    function getEthEquivalent(address _token, uint256 _amount) external view returns(uint256);

    /// @notice Returns a list of tokens, for which prices might be queried
    function getAvailableTokens() external view returns(PriceOracleToken[] memory);

    /// @notice Returns true if token is in the list of avalable tokens
    function isTokenProxyAvailable(address _token) external view returns(bool);
}


/// @title PriceOracleToken
struct PriceOracleToken {
    address token;
    string label;
}