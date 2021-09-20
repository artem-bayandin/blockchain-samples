// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// IERC20 to transfer playable tokens
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
// onlyOwner modifier
import '@openzeppelin/contracts/access/Ownable.sol';
// random number oracle (Chainlink)
import 'github.com/smartcontractkit/chainlink/blob/master/contracts/src/v0.8/VRFConsumerBase.sol';
// on-chain price oracle (Chainlink)
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';


/// @title IChainlinkDataFeeder
/// @notice Interface for a price oracle
/// @dev Deployment: a) deploy a PriceOracle; b) deploy a Raffle, passing address(PriceOracle) into ctor; c) call PriceOracle.addAdmin(address(Raffle)) to allow Raflle to administrate PriceOracle
interface IChainlinkDataFeeder {
    /// @notice Main function of a PriceOracle - get ETH equivalent of a ERC20 token
    function getEthEquivalent(address _token, uint256 _amount) external view returns(uint256);
    
    /// @notice Returns a list of tokens, for which prices might be queried
    function getAvailableTokens() external view returns(AvailableTokensToDeposit[] memory);
    
    /// @notice Returns true if token is in the list of avalable tokens
    function isTokenAvailable(address _token) external view returns(bool);
    
    /// @dev Region: functions for management

    /// @notice Adds a chainlink proxy of a token-to-usd pair
    function addTokenToUsd(address _token, string memory _label, address _proxy, uint8 _decimals) external;

    /// @notice Adds a chainlink proxy of a token-to-eth pair
    function addTokenToEth(address _token, string memory _label, address _proxy, uint8 _decimals) external;

    /// @notice Sets ETH price proxy address and amount of decimals of ETH
    function setEthTokenProxy(address _proxy, uint8 _decimals) external;

    /// @notice Allows an address to manage PriceOracle
    function addAdmin(address _admin) external;

    /// @notice Removes an address from admins
    function removeAdmin(address _admin) external;
    
    /// @dev Region: functions for tests

    /// @notice Returns the collection of addresses that are currently admins of the PriceOracle
    function __getOracleAdmins() external view returns(address[] memory);
}


/// @title ChainlinkDataFeedTokenRecord
/// @notice Struct represents token proxy to query price via chainlink price oracle
struct ChainlinkDataFeedTokenRecord {
    address token;
    string label;
    address proxy;
    uint8 decimals;
}


/// @title AvailableTokensToDeposit
struct AvailableTokensToDeposit {
    address token;
    string label;
}


/// @title ChainlinkDataFeederBase
/// @notice Base abstract PriceOracle contract with all the logic
/// @dev Inherited contracts should set the list of token proxies using setEthTokenProxy, addTokenToUsd, addTokenToEth
abstract contract ChainlinkDataFeederBase is IChainlinkDataFeeder {
    /// @notice An array of token addresses for which price is fetched via Token-USD and ETH-USD scheme
    address[] private usdTokens;
    /// @notice Map of 'usd-based' tokens proxies
    mapping(address => ChainlinkDataFeedTokenRecord) private usdTokenMap;
    
    /// @notice An array of token addresses for which price is fetched via Token-ETH scheme
    address[] private ethTokens;
    /// @notice Map of 'eth-based' tokens proxies
    mapping(address => ChainlinkDataFeedTokenRecord) private ethTokenMap;
    
    /// @notice Helper map to distinguish Token-USD-ETH vs Token-ETH proxies
    mapping(address => bool) usdToken;
    
    /// @notice ETH proxy address
    address private ethProxy;
    /// @notice ETH decimals
    uint8 private ethDecimals;
    
    /// @notice An array of addresses who has admin permissions
    address[] private admins;
    /// @notice Map of admin addresses to faster distinguish whether a user has admin roles
    mapping(address => bool) adminMap;
    
    /// @notice Validates if msg.sender has admin permissions
    modifier isAdmin() {
        address msgSender = msg.sender;
        require(adminMap[msgSender], "You do not have permissions to perform current operation.");
        _;
    }
    
    constructor() {
        address msgSender = msg.sender;
        admins.push(msgSender);
        adminMap[msgSender] = true;
    }

    /// @notice Main function of a PriceOracle - get ETH equivalent of a ERC20 token
    function getEthEquivalent(address _token, uint256 _amount)
    override
    public
    view
    returns(uint256) {
        uint256 ethPrice = 1 * 10 ** ethDecimals;

        ChainlinkDataFeedTokenRecord memory rec;
        if (usdToken[_token]) {
            // query both eth and token price
            rec = usdTokenMap[_token];
            // query eth price
            ethPrice = uint256(_getEthPriceFromChainlink());
        } else {
            rec = ethTokenMap[_token];
        }
        uint256 price = uint256(_getPriceFromChainlink(rec.proxy));

        if (rec.decimals > ethDecimals) {
            ethPrice *= 1 * 10 ** (rec.decimals - ethDecimals);
        } else if (rec.decimals < ethDecimals) {
            price *= 1 * 10 ** (ethDecimals - rec.decimals);
        }

        uint256 value = price * _amount / ethPrice;
        return value;
    }

    /// @notice Returns a list of tokens, for which prices might be queried
    function getAvailableTokens()
    override
    public
    view
    returns(AvailableTokensToDeposit[] memory) {
        uint256 usdTokensLen = usdTokens.length;
        uint256 ethTokensLen = ethTokens.length;
        
        AvailableTokensToDeposit[] memory result = new AvailableTokensToDeposit[](usdTokensLen + ethTokensLen);

        for (uint256 i = 0; i < usdTokensLen; i++) {
            ChainlinkDataFeedTokenRecord memory item = usdTokenMap[usdTokens[i]];
            result[i] = AvailableTokensToDeposit(item.token, item.label);
        }

        for (uint256 i = usdTokensLen; i < usdTokensLen + ethTokensLen; i++) {
            ChainlinkDataFeedTokenRecord memory item = ethTokenMap[ethTokens[i - usdTokensLen]];
            result[i] = AvailableTokensToDeposit(item.token, item.label);
        }

        return result;
    }

    /// @notice Returns true if token is in the list of avalable tokens
    function isTokenAvailable(address _token)
    override
    public
    view
    returns(bool) {
        return usdTokenMap[_token].token != address(0) || ethTokenMap[_token].token != address(0);
    }

    /// @dev Region: owner functions

    /// @notice Adds a chainlink proxy of a token-to-usd pair
    function addTokenToUsd(address _token, string memory _label, address _proxy, uint8 _decimals)
    override
    public
    isAdmin {
        ChainlinkDataFeedTokenRecord memory rec = ChainlinkDataFeedTokenRecord(_token, _label, _proxy, _decimals);
        usdTokens.push(_token);
        usdTokenMap[_token] = rec;
        usdToken[_token] = true;
    }
    
    /// @notice Adds a chainlink proxy of a token-to-eth pair
    function addTokenToEth(address _token, string memory _label, address _proxy, uint8 _decimals)
    override
    public
    isAdmin {
        ChainlinkDataFeedTokenRecord memory rec = ChainlinkDataFeedTokenRecord(_token, _label, _proxy, _decimals);
        ethTokens.push(_token);
        ethTokenMap[_token] = rec;
    }
    
    /// @notice Sets ETH price proxy address and amount of decimals of ETH
    function setEthTokenProxy(address _proxy, uint8 _decimals)
    override
    public
    isAdmin {
        ethProxy = _proxy;
        ethDecimals = _decimals;
    }
    
    /// @notice Allows an address to manage PriceOracle
    function addAdmin(address _admin)
    override
    public
    isAdmin {
        if (!adminMap[_admin]) {
            admins.push(_admin);
            adminMap[_admin] = true;
        }
    }

    /// @notice Removes an address from admins
    function removeAdmin(address _admin)
    override
    public
    isAdmin {
        require(admins.length > 1, "At least 1 admin should be assigned");
        if (adminMap[_admin]) {
            adminMap[_admin] = false;
            uint256 adminLen = admins.length;
            for (uint256 i = 0; i < adminLen; i++) {
                if (admins[i] == _admin) {
                    if (i != adminLen) {
                        admins[i] = admins[adminLen - 1];
                    }
                    admins.pop();
                    break;
                }
            }
        }
    }

    /// @dev Region: private

    function _getEthPriceFromChainlink()
    private
    view
    returns (int256 price) {
        (, price, , , ) = AggregatorV3Interface(ethProxy).latestRoundData();
    }

    function _getPriceFromChainlink(address _proxy)
    private
    view
    returns (int256 price) {
        (, price, , , ) = AggregatorV3Interface(_proxy).latestRoundData();
    }

    /*
    function _getPriceFromChainlink(address _proxy)
    private
    view
    returns (
      uint80 roundId,
      int256 price,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) {
        (
            roundId, 
            price,
            startedAt,
            updatedAt,
            answeredInRound
        ) = AggregatorV3Interface(_proxy).latestRoundData();
    }
    */
    
    /// @dev Region: for tests
    
    /// @notice Returns the collection of addresses that are currently admins of the PriceOracle
    function __getOracleAdmins()
    override
    public
    view
    returns(address[] memory) {
        return admins;
    }
}


/// @title ChainlinkDataFeederInEthMainnet
/// @notice PriceOracle setting for ETH Mainnet
contract ChainlinkDataFeederInEthMainnet is ChainlinkDataFeederBase {
    constructor () {
        setEthTokenProxy(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419, 8);
        
        addTokenToEth(0x514910771AF9Ca656af840dff83E8264EcF986CA, "LINK", 0xDC530D9457755926550b59e8ECcdaE7624181557, 18);
        addTokenToEth(0x6B175474E89094C44Da98b954EedeAC495271d0F, "DAI", 0x773616E4d11A78F511299002da57A0a94577F1f4, 18);
        addTokenToEth(0xB8c77482e45F1F44dE1745F52C74426C631bDD52, "BNB", 0xc546d2d06144F9DD42815b8bA46Ee7B8FcAFa4a2, 18);
        addTokenToEth(0xE1Be5D3f34e89dE342Ee97E6e90D405884dA6c67, "TRX", 0xacD0D1A29759CC01E8D925371B72cb2b5610EA25, 8);
        addTokenToEth(0xE41d2489571d322189246DaFA5ebDe1F4699F498, "ZRX", 0x2Da4983a622a8498bb1a21FaE9D8F6C664939962, 18);
    }
}


/// @title ChainlinkDataFeederInRinkeby
/// @notice PriceOracle setting for Rinkeby Testnet
contract ChainlinkDataFeederInRinkeby is ChainlinkDataFeederBase {
    constructor () {
        setEthTokenProxy(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e, 8);
        
        // addresses of tokens relate to contracts in etherscan, not a rinkeby one - when deploying find the valid ones
        addTokenToUsd(0x514910771AF9Ca656af840dff83E8264EcF986CA, "LINK", 0xd8bD0a1cB028a31AA859A21A3758685a95dE4623, 8);
        addTokenToEth(0x6B175474E89094C44Da98b954EedeAC495271d0F, "DAI", 0x74825DbC8BF76CC4e9494d0ecB210f676Efa001D, 18);
        addTokenToUsd(0xB8c77482e45F1F44dE1745F52C74426C631bDD52, "BNB", 0xcf0f51ca2cDAecb464eeE4227f5295F2384F84ED, 8);
        addTokenToUsd(0xE1Be5D3f34e89dE342Ee97E6e90D405884dA6c67, "TRX", 0xb29f616a0d54FF292e997922fFf46012a63E2FAe, 8);
        addTokenToUsd(0xE41d2489571d322189246DaFA5ebDe1F4699F498, "ZRX", 0xF7Bbe4D7d13d600127B6Aa132f1dCea301e9c8Fc, 8);
    }
}


/// @title Raffle game
/// @notice Kinda lottery game, when a user has to buy ticket to participate,
/// @notice and his chance to win equals to the ETH value of ERC20 tokens, which a player has transferred to the game.
/// @notice When a dice is rolled and a winner is found, all the collected fees alongside with all the collected tokens are transferred to the winner.
/// @dev Two ways to work with random numbers are implemented:
/// @dev - owner triggers a dice, and random number is requested from an oracle;
/// @dev - owner triggers a dice with a random number (in this case, this might be triggered manually from UI, or from server using HDWalletProvider).
contract Raffle is Ownable, VRFConsumerBase {

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

    /// @notice Chainlink randomness key hash
    bytes32 immutable private randomnessKeyHash;
    /// @notice Chainlink randomness fee
    uint256 immutable private randomnessFee;
    /// @notice Chainlink randomness request id
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
    
    /// @notice Price oracle
    IChainlinkDataFeeder private priceOracle;

    event PaymentReceived(address indexed msgSender, uint256 msgValue);
    event Deposited(address indexed msgSender, address indexed token, uint256 amount, uint256 chanceIncrement, uint256 totalChance, uint256 timestamp);
    event RollingManual(uint256 timestamp);
    event RollingWithOracle(uint256 timestamp);
    event RandomnessRequested(uint256 timestamp, bytes32 indexed randomnessRequestId);
    event RandomNumberManuallySet(uint256 randomNumber, uint256 timestamp);
    event FixingFailedOracleRandomness(bytes32 indexed randomnessRequestId, uint256 randomNumber, uint256 timestamp);
    event RandomnessCallbackReceived(bytes32 indexed randomnessRequestId, uint256 randomNumber);
    event RandomnessGameStatusOnFullfilledFailed(uint8 gameStatus, bytes32 indexed randomnessRequestId, bytes32 indexed receivedRandomnessRequestId, uint256 randomNumber);
    event RandomnessRequestIdFailed(bytes32 indexed randomnessRequestId, bytes32 indexed receivedRandomnessRequestId, uint256 randomNumber);
    event RandomValueCalculated(uint256 receivedRandomNumber, uint256 totalChanceSum, uint256 finalRandomNumber);
    event WinnerAddressIsChosen(address indexed winner, uint256 timestamp);
    event PrizeAssigned(address indexed winner, uint256 timestamp, uint256 ethPrize);
    event GameRestarted(uint256 timestamp);
    event MaxPlayersNumberChanged(uint256 oldValue, uint256 newValue);
    event MaxTokensNumberChanged(uint256 oldValue, uint256 newValue);
    event TicketFeeChanged(uint256 oldValue, uint256 newValue);

    /// @dev deployable ctor
    /// @param _maxPlayers max number of players to play a single game; needed to limit a for-loop
    /// @param _maxTokens max number of tokens to be deposited in a single game; needed to limit a for-loop
    /// @param _ticketFee a fee for a single deposit action
    /// @param _vrfCoordinator a static address of Chainlink vrfCoordinator for randomness, depends on a network
    /// @param _linkToken a static address of Chainlink LINK token to be used for randomness, depends on a network
    /// @param _randomnessKeyHash a static hash for Chainlink randomness, depends on a network
    /// @param _randomnessFee a static fee for randomness, depends on a network
    /// @param _priceOracleAddress ad address of a PriceOracle
    /*
    constructor (
        uint256 _maxPlayers
        , uint256 _maxTokens
        , uint256 _ticketFee
        , address _vrfCoordinator
        , address _linkToken
        , bytes32 _randomnessKeyHash
        , uint256 _randomnessFee
        , address _priceOracleAddress
    )
    VRFConsumerBase(_vrfCoordinator, _linkToken)
    {
        maxPlayers = _maxPlayers;
        maxTokens = _maxTokens;
        ticketFee = _ticketFee;
        randomnessKeyHash = _randomnessKeyHash;
        randomnessFee = _randomnessFee;
        priceOracle = IChainlinkDataFeeder(_priceOracleAddress);
    }
    */

    /// @dev Ctor for RinkebyNetwork (for simplicity)
    
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

    /// @notice Allows a user only single call of a method.
    modifier noDepositReentrancy() {
        address msgSender = msg.sender;
        require(!_isUserLockedToDeposit(msgSender), "Reentrancy detected.");
        _lockUserToDeposit(msgSender);
        _;
        _unlockUserToDeposit(msgSender);
    }

    /// @notice Validates the expected gameStatus
    modifier requireGameStatus(GameStatus _expected) {
        require(gameStatus == _expected, "Invalid current game status.");
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
    requireGameStatus(GameStatus.GAMING) {
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

    /// @notice Admin function to roll the dice and find a winner.
    /// @notice Utilizes a Chainlink random generator
    function rollTheDice()
    public 
    onlyOwner
    requireGameStatus(GameStatus.GAMING) {
        require(LINK.balanceOf(address(this)) >= randomnessFee, "Not enough LINK to use Oracle for randomness.");
        // pause game
        _startRolling(false);
        // roll the dice
        randomnessRequestId = requestRandomness(randomnessKeyHash, randomnessFee);
        emit RandomnessRequested(block.timestamp, randomnessRequestId);
    }

    /// @notice Admin function to roll the dice and find a winner.
    /// @notice Manually sets the random number
    function rollTheDice(uint256 _randomNumber)
    public 
    onlyOwner
    requireGameStatus(GameStatus.GAMING) {
        // pause game
        _startRolling(true);
        emit RandomNumberManuallySet(_randomNumber, block.timestamp);
        _proceedWithRandomNumber(_randomNumber);
    }

    /// @notice Admin function to fix a possible issue when random number was requested from an oracle, but validations failed for any reason. See more 'fulfillRandomness'.
    /// @notice Replaces oracless random number with namually entered one.
    function fixRolling(uint256 _randomNumber)
    public 
    onlyOwner
    requireGameStatus(GameStatus.RANDOM_REQUEST_FAILED) {
        emit FixingFailedOracleRandomness(randomnessRequestId, _randomNumber, block.timestamp);
        _proceedWithRandomNumber(_randomNumber);
    }

    /// @dev Region: Randomness callback

    /// @notice VRFConsumerBase callback function when random number was generated.
    /// @dev Performs some validations, and if failed, sets gameStatus to RANDOM_REQUEST_FAILED, and an issue should be resolved via 'fixRolling'.
    function fulfillRandomness(bytes32 _requestId, uint256 _randomNumber)
    internal
    override {
        emit RandomnessCallbackReceived(_requestId, _randomNumber);

        if (gameStatus != GameStatus.GAMING) {
            gameStatus = GameStatus.RANDOM_REQUEST_FAILED;
            emit RandomnessGameStatusOnFullfilledFailed(uint8(gameStatus), randomnessRequestId, _requestId, _randomNumber);
            revert("Invalid current game status. Ask your admin to manually fix the issue.");
        }

        if (_requestId != randomnessRequestId) {
            gameStatus = GameStatus.RANDOM_REQUEST_FAILED;
            emit RandomnessRequestIdFailed(randomnessRequestId, _requestId, _randomNumber);
            revert("Randomness requestIds do not coinside. Ask your admin to roll the dice manually.");
        }

        _proceedWithRandomNumber(_randomNumber);
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
    onlyOwner {
        require(_maxPlayers > 1, "There should be at least 2 players.");
        uint256 oldValue = maxPlayers;
        maxPlayers = _maxPlayers;
        emit MaxPlayersNumberChanged(oldValue, maxPlayers);
    }

    /// @notice Sets the max number of different ERC20 tokens to be deposited within one game
    function setMaxTokens(uint256 _maxTokens)
    public
    onlyOwner {
        require(_maxTokens >= 1, "There should be at least 1 token allowed for deposit.");
        uint256 oldValue = maxTokens;
        maxTokens = _maxTokens;
        emit MaxTokensNumberChanged(oldValue, maxTokens);
    }
    
    /// @notice Sets the ticket fee to deposit tokens
    function setTicketFee(uint256 _ticketFee)
    public
    onlyOwner {
        require(_ticketFee > 0, "Fee should be greate than 0.");
        uint256 oldValue = ticketFee;
        ticketFee = _ticketFee;
        emit TicketFeeChanged(oldValue, ticketFee);
    }
    
    /// @notice Updates the address of a PriceOracle
    function setPriceOracle(address _oracleAddress)
    public
    onlyOwner {
        require(_oracleAddress != address(priceOracle), "PriceOracle address should not be the same as existing one.");
        priceOracle = IChainlinkDataFeeder(_oracleAddress);
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
    
    function __getRandomnessKeyHash() 
    public
    view
    returns (bytes32) {
        return randomnessKeyHash;
    }
    
    function __getRandomnessFee() 
    public
    view
    returns (uint256) {
        return randomnessFee;
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
    
    function __getOracleAdmins()
    public
    view
    returns(address[] memory) {
        return priceOracle.__getOracleAdmins();
    }
}