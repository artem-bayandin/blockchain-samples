// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import '../IRandomnessOracle.sol';


contract RandomnessOracleMock is IRandomnessOracle {

    // TODO:
    // - add internal counter
    // - as _requestId return hash
    // - func setupRandomValue(uint value) or func generateRandomValue()

    function askOracleForRandomness()
    override
    external
    returns(bytes32 _requestId) {

    }
}