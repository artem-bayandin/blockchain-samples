// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


interface IRandomnessOracle {
    function askOracleForRandomness() external returns(bytes32 _requestId);
}


interface IRandomnessReceiver {
    function randomnessSucceeded(bytes32 _requestId, uint256 _randomNumber) external;
    function randomnessFailed(bytes32 _requestId, string memory _errorMessage) external;
}