// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


// IERC20 to transfer playable tokens
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


import './Adminable.sol';
import './PriceOracle.sol';
import './RandomnessOracle.sol';


/// @title Raffle game
/// @notice Kinda lottery game, when a user has to buy ticket to participate,
/// @notice and his chance to win equals to the ETH value of ERC20 tokens, which a player has transferred to the game.
/// @notice When a dice is rolled and a winner is found, all the collected fees alongside with all the collected tokens are transferred to the winner.
/// @dev Two ways to work with random numbers are implemented:
/// @dev - owner triggers a dice, and random number is requested from an oracle;
/// @dev - owner triggers a dice with a random number (in this case, this might be triggered manually from UI, or from server using HDWalletProvider).
contract Raffle is Adminable, IRandomnessReceiver {

    /// @notice bids of a player in an ongoing game
    struct Bids {
        /// @notice a list of tokens a player has deposited
        address[] tokens;
        /// @notice ETH value of deposited tokens
        uint256 totalChance;
        /// @notice how much of each token a player has deposited
        mapping(address => uint256) amounts;
    }

    /// @notice a record of all prizes a player has won
    struct WinnerRecord {
        /// @notice an address of a winner
        address winner;
        /// @notice timestamp
        uint256 timestamp;
        /// @notice whether a winner has taken its tokens
        bool hasWithdrawn;
        /// @notice eth amount (see description of 'uint256 collectedFee' below)
        uint256 ethPrize;
        /// @notice an array of tokens a player won
        address[] tokens;
        /// @notice amounts per token a winner won
        mapping(address => uint256) tokenAmounts;
    }

    /// @notice the amount of players that may play a single game
    /// @notice limits future gas fees, when for-looping players array
    uint256 private maxPlayers;

    /// @notice the amount of tokens that might be deposited in a single game
    /// @notice limits future gas fees, when for-looping tokens array
    uint256 private maxTokens;

    /// @notice price to 'get a ticket'
    uint256 private ticketFee;

    /// @notice let's imaging, that we transfer all the collected fees to a winner
    /// @notice no business value, just show a pattern to work with address(this).balance
    uint256 private collectedFee;

    /// @notice states of a game, kinda state machine, to define which functions might be triggered
    enum GameStatus { GAMING, ROLLING, RANDOM_REQUEST_FAILED, RANDOM_RECEIVED, WINNER_CHOSEN }
    /// @notice state variable to store current game state
    GameStatus private gameStatus;

    /// @notice Randomness request id
    bytes32 private randomnessRequestId;

    /// @notice current players in a game
    address[] private players;
    /// @notice helps to define whether address is playing at the moment
    mapping(address => bool) private activePlayers;
    /// @notice bids by player
    mapping(address => Bids) private bids;
    
    /// @notice current tokens in a game
    address[] private tokens;
    /// @notice amount deposited by each token
    mapping(address => uint256) private bidsByToken;
    
    /// @notice maps a winner to games it won
    /// @dev winner => timestamp[]
    mapping(address => uint256[]) private winnerTimestamps;
    /// @notice winner prizes and their state
    /// @dev winner => timestamp => WinnerRecord
    mapping(address => mapping(uint256 => WinnerRecord)) private winners;

    /// @notice reentrancy lock for a player to be able to step into deposit func only once
    address[] playersLockedToDeposit;
    /// @notice reentrancy corresponding mapping
    mapping(address => bool) depositLocks;

    /// @notice reentrancy lock for a player to be able to step into withdraw func only once
    address[] playersLockedToWithdraw;
    /// @notice reentrancy corresponding mapping
    mapping(address => bool) withdrawLocks;

    /// @notice Randomness oracle
    IRandomnessOracle private randomnessOracle;

    /// @notice Price oracle
    IPriceOracle private priceOracle;

    event PaymentReceived(address indexed msgSender, uint256 msgValue);
    event Deposited(address indexed msgSender, address indexed token, uint256 amount, uint256 chanceIncrement, uint256 totalChance, uint256 timestamp);
    event RollingManual(uint256 timestamp);
    event RollingWithOracle(uint256 timestamp);
    event RandomnessRequested(uint256 timestamp, bytes32 indexed randomnessRequestId);
    event RandomNumberManuallySet(uint256 randomNumber, uint256 timestamp);
    event FixingFailedOracleRandomness(bytes32 indexed randomnessRequestId, uint256 randomNumber, uint256 timestamp);
    event RandomnessCallbackReceived(bytes32 indexed randomnessRequestId, uint256 randomNumber, string errorMessage);
    event RandomnessFailedOnGameStatus(uint8 gameStatus, bytes32 indexed randomnessRequestId, bytes32 indexed receivedRandomnessRequestId, uint256 randomNumber);
    event RandomnessFailedOnRequestId(bytes32 indexed randomnessRequestId, bytes32 indexed receivedRandomnessRequestId, uint256 randomNumber);
    event RandomnessFailedExternally(bytes32 requestId, string errorMessage);
    event RandomValueCalculated(uint256 receivedRandomNumber, uint256 totalChanceSum, uint256 finalRandomNumber);
    event WinnerAddressIsChosen(address indexed winner, uint256 timestamp);
    event PrizeAssigned(address indexed winner, uint256 indexed timestamp, uint256 ethPrize);
    event PrizeWithdrawn(address indexed winner, uint256 indexed prizeAssignmentTimestamp, uint256 timestamp, uint256 ethPrize);
    event GameRestarted(uint256 timestamp);
    event MaxPlayersNumberChanged(uint256 oldValue, uint256 newValue);
    event MaxTokensNumberChanged(uint256 oldValue, uint256 newValue);
    event TicketFeeChanged(uint256 oldValue, uint256 newValue);

    /// @dev deployable ctor
    /// @param _maxPlayers max number of players to play a single game; needed to limit a for-loop
    /// @param _maxTokens max number of tokens to be deposited in a single game; needed to limit a for-loop
    /// @param _ticketFee a fee for a single deposit action
    /// @param _randomnessOracleAddress an address of a Randomness oracle
    /// @param _priceOracleAddress an address of a Price oracle
    
    constructor (
        uint256 _maxPlayers
        , uint256 _maxTokens
        , uint256 _ticketFee
        , address _randomnessOracleAddress
        , address _priceOracleAddress
    ) {
        maxPlayers = _maxPlayers;
        maxTokens = _maxTokens;
        ticketFee = _ticketFee;
        randomnessOracle = IRandomnessOracle(_randomnessOracleAddress);
        priceOracle = IPriceOracle(_priceOracleAddress);
    }

    /// @dev Ctor for RinkebyNetwork (for simplicity)
    /*
    constructor(address _priceOracleAddress)
    VRFConsumerBase(0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, 0x01BE23585060835E02B77ef475b0Cc51aA1e0709)
    {
        maxPlayers = 100;
        maxTokens = 100;
        ticketFee = 0;
        randomnessKeyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        randomnessFee = 1 * 10 ** 17; // 0.1 LINK
        priceOracle = IChainlinkDataFeeder(_priceOracleAddress);
    }
    */

    /// @notice Allows a user only single call of a method.
    modifier noDepositReentrancy() {
        address msgSender = msg.sender;
        require(!_isUserLockedToDeposit(msgSender), "Reentrancy detected.");
        _lockUserToDeposit(msgSender);
        _;
        _unlockUserToDeposit(msgSender);
    }

    /// @notice Allows a user only single call of a method.
    modifier noWithdrawReentrancy() {
        address msgSender = msg.sender;
        require(!_isUserLockedToWithdraw(msgSender), "Reentrancy detected.");
        _lockUserToWithdraw(msgSender);
        _;
        _unlockUserToWithdraw(msgSender);
    }

    /// @notice Validates the expected gameStatus
    modifier requireGameStatus(GameStatus _expected) {
        require(gameStatus == _expected, "Invalid current game status.");
        _;
    }
    
    /// @notice Validates that price oracle has a proxy set up for a token
    modifier requireTokenAllowed(address _token) {
        require(priceOracle.isTokenProxyAvailable(_token), "Token is not allowed to be deposited");
        _;
    }

    /// @notice allows contract to receive eth
    receive()
    external
    payable {
        emit PaymentReceived(msg.sender, msg.value);
    }

    /// @dev Region: Public methods

    /// @notice Main function for a player.
    /// @notice Token should be previously approved to be managed by the game
    /// @param _token Address of ERC20 token to deposit
    /// @param _amount Amount of ERC20 token to deposit
    function deposit(address _token, uint256 _amount)
    public
    payable
    noDepositReentrancy
    requireGameStatus(GameStatus.GAMING)
    requireTokenAllowed(_token) {
        // fetch data from msg.*
        address msgSender = msg.sender;
        uint256 msgValue = msg.value;
        
        // require-s
        require(msgValue >= ticketFee, "You should pay to play.");
        require(IERC20(_token).allowance(msgSender, address(this)) >= _amount, "Please allow to transfer tokens.");
        require(players.length < maxPlayers, "All seats are taken, wait for rolling.");

        // if player is not yet registered - register it
        if (!activePlayers[msgSender]) {
            activePlayers[msgSender] = true;
            players.push(msgSender);
        }

        // alter player's bids
        Bids storage playerBids = bids[msgSender];
        if (playerBids.amounts[_token] == 0) {
            playerBids.tokens.push(_token);
        }
        playerBids.amounts[_token] += _amount;
        
        // alter player chances by querying eth value of tokens to deposit
        uint256 chanceIncrement = priceOracle.getEthEquivalent(_token, _amount);
        playerBids.totalChance += chanceIncrement;

        // alter bids by token
        bidsByToken[_token] += _amount;

        // send tokens to contract
        IERC20(_token).transferFrom(msgSender, address(this), _amount);

        // collect fee
        collectedFee += msgValue;

        emit Deposited(msgSender, _token, _amount, chanceIncrement, playerBids.totalChance, block.timestamp);
    }
    
    function withdrawThePrize()
    public
    payable
    noWithdrawReentrancy {
        address msgSender = payable(msg.sender);
        uint256[] memory timestamps = winnerTimestamps[msgSender];
        uint256 timestampsLen = timestamps.length;
        
        if (timestampsLen == 0) {
            return;
        }
        
        // move backward on timestamps
        for (uint256 i = timestampsLen - 1; i >= 0; i--) {
            uint256 ts = timestamps[i];
            WinnerRecord storage rec = winners[msgSender][ts];
            /*
            /// @notice an array of tokens a player won
            address[] tokens;
            /// @notice amounts per token a winner won
            mapping(address => uint256) tokenAmounts;
            */
            
            if (rec.hasWithdrawn) {
                break;
            }
            
            // let it set right now. if user tries to cheat - it won't receive a penny
            rec.hasWithdrawn = true;
            
            uint256 ethPrize = rec.ethPrize;
            rec.ethPrize = 0;
            
            // transfer tokens
            for (uint tokenCounter = 0; tokenCounter < rec.tokens.length; tokenCounter++) {
                address tokenAddress = rec.tokens[tokenCounter];
                uint256 tokenAmount = rec.tokenAmounts[tokenAddress];
                // set to 0
                rec.tokenAmounts[tokenAddress] = 0;
                
                // try to send
                IERC20(tokenAddress).transfer(msgSender, tokenAmount);
            }
            
            if (ethPrize > 0) {
                // send eth
                (bool success,) = msgSender.call{value:ethPrize}("");
                if (success) {
                    // do nothing
                }
            }
            
            emit PrizeWithdrawn(msgSender, ts, block.timestamp, ethPrize);
        }
    }

    /// @notice Admin function to roll the dice and find a winner.
    function rollTheDice()
    public 
    onlyAdmin
    requireGameStatus(GameStatus.GAMING) {
        // pause game
        _startRolling(false);
        // roll the dice
        randomnessRequestId = randomnessOracle.askOracleForRandomness();
        emit RandomnessRequested(block.timestamp, randomnessRequestId);
    }

    /// @notice Admin function to pause game for rolling.
    /// @dev Does not set the random number
    function rollTheDiceManually()
    public 
    onlyAdmin
    requireGameStatus(GameStatus.GAMING) {
        // pause game
        _startRolling(true);
    }
    
    /// @notice Admin function to manually input random u.
    /// @notice Manually sets the random number
    function inputRandomNumberManually(uint256 _randomNumber)
    public 
    onlyAdmin
    requireGameStatus(GameStatus.ROLLING) {
        // roll the dice
        emit RandomNumberManuallySet(_randomNumber, block.timestamp);
        _proceedWithRandomNumber(_randomNumber);
    }

    /// @notice Admin function to fix a possible issue when random number was requested from an oracle, but validations failed for any reason. See more 'fulfillRandomness'.
    /// @notice Replaces oracless random number with namually entered one.
    function fixRolling(uint256 _randomNumber)
    public 
    onlyAdmin
    requireGameStatus(GameStatus.RANDOM_REQUEST_FAILED) {
        emit FixingFailedOracleRandomness(randomnessRequestId, _randomNumber, block.timestamp);
        _proceedWithRandomNumber(_randomNumber);
    }

    /// @dev Region: Randomness callbacks

    function randomnessSucceeded(bytes32 _requestId, uint256 _randomNumber)
    override
    external {
        emit RandomnessCallbackReceived(_requestId, _randomNumber, "");

        if (gameStatus != GameStatus.GAMING) {
            gameStatus = GameStatus.RANDOM_REQUEST_FAILED;
            emit RandomnessFailedOnGameStatus(uint8(gameStatus), randomnessRequestId, _requestId, _randomNumber);
            revert("Invalid current game status. Ask your admin to manually fix the issue.");
        }

        if (_requestId != randomnessRequestId) {
            gameStatus = GameStatus.RANDOM_REQUEST_FAILED;
            emit RandomnessFailedOnRequestId(randomnessRequestId, _requestId, _randomNumber);
            revert("Randomness requestIds do not coinside. Ask your admin to roll the dice manually.");
        }

        _proceedWithRandomNumber(_randomNumber);
    }
    
    function randomnessFailed(bytes32 _requestId, string memory _errorMessage)
    override
    external {
        emit RandomnessCallbackReceived(_requestId, 0, _errorMessage);
        emit RandomnessFailedExternally(_requestId, _errorMessage);
    }

    /// @dev Region: Private methods

    function _isUserLockedToDeposit(address _player)
    private
    view
    returns (bool) {
        return depositLocks[_player];
    }

    function _lockUserToDeposit(address _player)
    private {
        playersLockedToDeposit.push(_player);
        depositLocks[_player] = true;
    }

    function _unlockUserToDeposit(address _player)
    private {
        // remove from array
        uint256 lockedUsersLen = playersLockedToDeposit.length;
        for (uint256 i = 0; i < lockedUsersLen; i++) {
            if (playersLockedToDeposit[i] == _player) {
                if (i != lockedUsersLen - 1) {
                    // replace with the last
                    playersLockedToDeposit[i] = playersLockedToDeposit[lockedUsersLen - 1];
                }
                // pop the last
                playersLockedToDeposit.pop();
                break;
            }
        }
        depositLocks[_player] = false;
    }

    function _isUserLockedToWithdraw(address _player)
    private
    view
    returns (bool) {
        return withdrawLocks[_player];
    }

    function _lockUserToWithdraw(address _player)
    private {
        playersLockedToWithdraw.push(_player);
        withdrawLocks[_player] = true;
    }

    function _unlockUserToWithdraw(address _player)
    private {
        // remove from array
        uint256 lockedUsersLen = playersLockedToWithdraw.length;
        for (uint256 i = 0; i < lockedUsersLen; i++) {
            if (playersLockedToWithdraw[i] == _player) {
                if (i != lockedUsersLen - 1) {
                    // replace with the last
                    playersLockedToWithdraw[i] = playersLockedToWithdraw[lockedUsersLen - 1];
                }
                // pop the last
                playersLockedToWithdraw.pop();
                break;
            }
        }
        withdrawLocks[_player] = false;
    }

    function _startRolling(bool _manualRandomness)
    private {
        gameStatus = GameStatus.ROLLING;
        if (_manualRandomness) {
            emit RollingManual(block.timestamp);
        } else {
            emit RollingWithOracle(block.timestamp);
        }
    }

    function _proceedWithRandomNumber(uint256 _randomNumber)
    private {
        gameStatus = GameStatus.RANDOM_RECEIVED;
        _randomNumberReceived(_randomNumber);
    }

    function _randomNumberReceived(uint256 _randomNumber)
    private {
        uint256 totalChanceSum = _calcCurrentTotalChance();
        uint256 finalRandomNumber = _randomNumber % totalChanceSum;
        emit RandomValueCalculated(_randomNumber, totalChanceSum, finalRandomNumber);
        _chooseWinner(finalRandomNumber, totalChanceSum);
    }

    function _chooseWinner(uint256 _random, uint256 _totalChanceSum)
    private {
        address winner;
        uint256 totalChanceSum = 0;
        uint256 playersLength = players.length;
        if (_totalChanceSum / 2 > _random) {
            // random is in the first half
            uint256 current = 0;
            for (uint256 i = 0; i < playersLength; i++) {
                current += bids[players[i]].totalChance;
                if (current >= _random) {
                    // this is the winner
                    winner = players[i];
                    i = playersLength;
                }
            }
        } else {
            // random is in the second half
            uint256 current = totalChanceSum;
            // TODO not a good idea to use int256
            for (int256 i = int256(playersLength - 1); i >= 0; i--) {
                current -= bids[players[uint256(i)]].totalChance;
                if (current >= _random) {
                    // this is the winner
                    winner = players[uint256(i)];
                    i = 0;
                }
            }
        }
        
        emit WinnerAddressIsChosen(winner, block.timestamp);
        
        _assignTokens(winner);
    }
    
    function _assignTokens(address _winner)
    private {
        uint256 timestamp = block.timestamp;
        
        WinnerRecord storage winRecord = winners[_winner][timestamp];
        
        winRecord.winner = _winner;
        winRecord.timestamp = timestamp;
        winRecord.hasWithdrawn = false;
        
        // copy eth data and clear it
        uint256 ethToSend = collectedFee;
        collectedFee = 0;
        winRecord.ethPrize = ethToSend;
        
        // copy token data and clear it
        uint256 tokensLen = tokens.length;
        for (uint256 i = 0; i < tokensLen; i++) {
            address token = tokens[i];
            uint256 amount = bidsByToken[token];
            
            winRecord.tokens.push(token);
            winRecord.tokenAmounts[token] = amount;
            
            // clear assigned tokens
            delete bidsByToken[token];
        }
        
        // clear as much as possible
        uint256 playersLen = players.length;
        for (uint256 i = 0; i < playersLen; i++) {
            address player = players[i];
            delete activePlayers[player];
            delete bids[player];
        }
        
        delete players;
        delete tokens;
        
        emit PrizeAssigned(winRecord.winner, winRecord.timestamp, winRecord.ethPrize);

        // TODO make sure that we can play the game again
        gameStatus = GameStatus.GAMING;

        emit GameRestarted(block.timestamp);
    }

    function _calcCurrentTotalChance()
    private
    view
    returns (uint256) {
        uint256 totalChanceSum = 0;
        uint256 playersLength = players.length;
        for (uint8 i = 0; i < playersLength; i++) {
            totalChanceSum += bids[players[i]].totalChance;
        }
        return totalChanceSum;
    }

    /// @dev Region: Getters and setters methods

    /// @notice Sets the max number of players to play a single game
    function setMaxPlayers(uint256 _maxPlayers)
    public
    onlyAdmin {
        require(_maxPlayers > 1, "There should be at least 2 players.");
        uint256 oldValue = maxPlayers;
        maxPlayers = _maxPlayers;
        emit MaxPlayersNumberChanged(oldValue, maxPlayers);
    }

    /// @notice Sets the max number of different ERC20 tokens to be deposited within one game
    function setMaxTokens(uint256 _maxTokens)
    public
    onlyAdmin {
        require(_maxTokens >= 1, "There should be at least 1 token allowed for deposit.");
        uint256 oldValue = maxTokens;
        maxTokens = _maxTokens;
        emit MaxTokensNumberChanged(oldValue, maxTokens);
    }
    
    /// @notice Sets the ticket fee to deposit tokens
    function setTicketFee(uint256 _ticketFee)
    public
    onlyAdmin {
        require(_ticketFee > 0, "Fee should be greate than 0.");
        uint256 oldValue = ticketFee;
        ticketFee = _ticketFee;
        emit TicketFeeChanged(oldValue, ticketFee);
    }
    
    /// @notice Updates the address of a RandomnessOracle
    function setRandomnessOracle(address _oracleAddress)
    public
    onlyAdmin {
        require(_oracleAddress != address(randomnessOracle), "RandomnessOracle address should not be the same as existing one.");
        randomnessOracle = IRandomnessOracle(_oracleAddress);
    }
    
    /// @notice Updates the address of a PriceOracle
    function setPriceOracle(address _oracleAddress)
    public
    onlyAdmin {
        require(_oracleAddress != address(priceOracle), "PriceOracle address should not be the same as existing one.");
        priceOracle = IPriceOracle(_oracleAddress);
    }

    /// @dev Region: Public getters for testing

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