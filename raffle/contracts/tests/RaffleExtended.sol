// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import '../Raffle.sol';


/// @title RaffleExtended
/// @notice Extension of Raffle contract for tests, so that initial Raffle was not polluted with business useless functions
contract RaffleExtended is Raffle {
    constructor(
        uint256 _maxPlayers
        , uint256 _maxTokens
        , uint256 _ticketFee
        , address _randomnessOracleAddress
        , address _priceOracleAddress
    ) Raffle(_maxPlayers, _maxTokens, _ticketFee, _randomnessOracleAddress, _priceOracleAddress) { }

    function __getMaxPlayers() 
    public
    view
    returns (uint256) {
        return maxPlayers;
    }

    function __getMaxTokens() 
    public
    view
    returns (uint256) {
        return maxTokens;
    }
    
    function __getTicketFee() 
    public
    view
    returns (uint256) {
        return ticketFee;
    }

    function __getRandomnessOracleAddress()
    public
    view
    returns (address) {
        return address(randomnessOracle);
    }

    function __getPriceOracleAddress()
    public
    view
    returns (address) {
        return address(priceOracle);
    }
    
    function __getCollectedFee()
    public
    view
    returns (uint256) {
        return collectedFee;
    }
    
    function __getGameStatus() 
    public
    view
    returns (uint8) {
        return uint8(gameStatus);
    }
    
    function __getRandomnessRequestId() 
    public
    view
    returns (bytes32) {
        return randomnessRequestId;
    }

    function __getPlayers() 
    public
    view
    returns (address[] memory) {
        return players;
    }

    function __isPlayerActive(address _player) 
    public
    view
    returns (bool) {
        return activePlayers[_player];
    }
    
    function __getUserChance(address _address) 
    public
    view
    returns (uint256) {
        return bids[_address].totalChance;
    }

    function __getPlayerChance1000(address _player) 
    public
    view
    returns (uint256 value, uint32 base) {
        return __getPlayerChance(_player, 1000);
    }

    function __getPlayerChance(address _player, uint32 _base) 
    public
    view
    returns (uint256 value, uint32 base) {
        uint256 totalChances = _calcCurrentTotalChance();
        uint256 playerValue = bids[_player].totalChance;
        return (playerValue * _base / totalChances, _base);
    }

    function __getPlayerBidsTokens(address _player) 
    public
    view
    returns (address[] memory) {
        return bids[_player].tokens;
    }

    function __getPlayerBidTokenAmount(address _player, address _token) 
    public
    view
    returns (uint256) {
        return bids[_player].amounts[_token];
    }

    function __getTokens() 
    public
    view
    returns (address[] memory) {
        return tokens;
    }

    function __getTokenBid(address _token) 
    public
    view
    returns (uint256) {
        return bidsByToken[_token];
    }

    function __getWinnerTimestamps(address _winner) 
    public
    view
    returns (uint256[] memory) {
        return winnerTimestamps[_winner];
    }

    function __getWinnerRecord(address _winner, uint256 _timestamp) 
    public
    view
    returns (
        address winner
        , uint256 timestamp
        , bool hasWithdrawn
        , uint256 ethPrize
        , address[] memory tokenAddresses
    ) {
        WinnerRecord storage rec = winners[_winner][_timestamp];
        return (rec.winner, rec.timestamp, rec.hasWithdrawn, rec.ethPrize, rec.tokens);
    }
    
    function __getWinnerTokenAmount(address _winner, uint256 _timestamp, address _token) 
    public
    view
    returns (uint256) {
        return winners[_winner][_timestamp].tokenAmounts[_token];
    }
}