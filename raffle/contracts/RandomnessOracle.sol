// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


// random number oracle (Chainlink)
import '@chainlink/contracts/src/v0.8/VRFConsumerBase.sol';


interface IRandomnessOracle {
    function askOracle() external returns(bytes32 _requestId);
}


interface IRandomnessReceiver {
    function randomnessSucceeded(bytes32 _requestId, uint256 _randomNumber) external;
    function randomnessFailed(bytes32 _requestId, string memory _errorMessage) external;
}

/// @dev check LINK balance of a contract
/// @dev and/or use delegatecall or something
/// @dev or restrict usage of oracle just to my contract

contract ChainlinkRandomnessOracle is IRandomnessOracle, VRFConsumerBase {
    /// @notice Chainlink randomness key hash
    bytes32 immutable private randomnessKeyHash;

    /// @notice Chainlink randomness fee
    uint256 immutable private randomnessFee;

    /// @notice Requests that have been created
    mapping(bytes32 => bool) createdRequests;
    
    /// @notice Requests that have been processed
    mapping(bytes32 => bool) executedRequests;

    /// @notice Requests results
    mapping(bytes32 => uint256) requestResults;

    /// @notice msg.sender of a request
    mapping(bytes32 => address) requestReceivers;

    /// @notice Event that is being fired when a randomness results was received.
    event RandomnessRequestResult(bytes32 indexed requestId, address indexed receiver, uint256 randomNumber, string result, uint256 timestamp);

    /// @notice Ctor
    /// @param _vrfCoordinator a static address of Chainlink vrfCoordinator for randomness, depends on a network
    /// @param _linkToken a static address of Chainlink LINK token to be used for randomness, depends on a network
    /// @param _randomnessKeyHash a static hash for Chainlink randomness, depends on a network
    /// @param _randomnessFee a static fee for randomness, depends on a network
    constructor(
        address _vrfCoordinator
        , address _linkToken
        , bytes32 _randomnessKeyHash
        , uint256 _randomnessFee
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        randomnessKeyHash = _randomnessKeyHash;
        randomnessFee = _randomnessFee;
    }

    function askOracle()
    override
    external
    returns(bytes32 _requestId) {
        // ask the oracle
        bytes32 requestId = requestRandomness(randomnessKeyHash, randomnessFee);
        // register request
        createdRequests[requestId] = true;
        requestReceivers[requestId] = msg.sender;
        // return
        return requestId;
    }

    /// @notice VRFConsumerBase callback function when random number was generated.
    function fulfillRandomness(bytes32 _requestId, uint256 _randomNumber)
    internal
    override {
        address receiver = requestReceivers[_requestId];

        if (!createdRequests[_requestId]) {
            // unknown request detected
            // most likely, there's no data in mappings
            emit RandomnessRequestResult(_requestId, receiver, _randomNumber, "RequestId is not registered.", block.timestamp);
            return;
        }

        if (receiver == address(0)) {
            // no receiver found
            emit RandomnessRequestResult(_requestId, receiver, _randomNumber, "No receiver for the request was found.", block.timestamp);
            return;
        }
        
        if (executedRequests[_requestId]) {
            // executed request detected
            emit RandomnessRequestResult(_requestId, receiver, _randomNumber, "The request has been executed earlier.", block.timestamp);
            IRandomnessReceiver(receiver).randomnessFailed(_requestId, "The request has been executed earlier.");
        }

        // looks like ok
        executedRequests[_requestId] = true;
        requestResults[_requestId] = _randomNumber;
        emit RandomnessRequestResult(_requestId, receiver, _randomNumber, "The request has succeeded.", block.timestamp);
        IRandomnessReceiver(receiver).randomnessSucceeded(_requestId, _randomNumber);
    }
}