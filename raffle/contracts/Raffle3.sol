// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.7;

// import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
// import '@openzeppelin/contracts/access/Ownable.sol';
// import 'github.com/smartcontractkit/chainlink/blob/master/contracts/src/v0.8/VRFConsumerBase.sol';

// import 'github.com/Uniswap/v2-core/blob/816075049f811f1b061bca81d5d040b96f4c07eb/contracts/interfaces/IUniswapV2Factory.sol';
// import 'github.com/Uniswap/v2-core/blob/816075049f811f1b061bca81d5d040b96f4c07eb/contracts/interfaces/IUniswapV2Pair.sol';

// import "github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/interfaces/IQuoter.sol";

// // chainlink price feed
// // https://docs.chain.link/docs/get-the-latest-price/#solidity
// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// /*
// // uniswap interfaces are taken from 
// // https://github.com/jklepatch/eattheblocks/tree/b9318560a7358847193ef5959c38c967999c7a71/screencast/138-defi-programming-uniswap/contracts
// interface IUniswapFactory {
//     function getExchange(address token) external view returns (address exchange);
// }

// interface IUniswapExchange {
//     // Get Prices
//     function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
//     function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold);
//     function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
//     function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256 tokens_sold);
// }
// */

// contract NonReentrant3 {
//     bool private contractLocked;
//     mapping(string => bool) lockedMethods;
//     mapping(string => mapping(address => bool)) lockedMethodsForUsers;

//     modifier lockContract(string memory _message) {
//         requireNotLockedContract(_message);
//         contractLocked = true;
//         _;
//         contractLocked = false;
//     }

//     modifier lockContractWithNoRelease(string memory _message) {
//         requireNotLockedContract(_message);
//         contractLocked = true;
//         _;
//     }
    
//     modifier releaseLockedContract(string memory _message) {
//         require(contractLocked, _message);
//         _;
//         contractLocked = false;
//     }
    
//     modifier contractIsNotLocked(string memory _message) {
//         requireNotLockedContract(_message);
//         _;
//     }

//     modifier lockMethod(string memory _methodName, string memory _message) {
//         requireNotLockedContract("Contract is locked.");
//         requireNotLockedMethod(_methodName, _message);
//         lockedMethods[_methodName] = true;
//         _;
//         lockedMethods[_methodName] = false;
//     }

//     modifier lockMethodForUser(string memory _methodName, address _sender, string memory _message) {
//         requireNotLockedContract("Contract is locked.");
//         requireNotLockedMethod(_methodName, "Method is locked.");
//         requireNotLockedMethodForUser(_methodName, _sender, _message);
//         lockedMethodsForUsers[_methodName][_sender] = true;
//         _;
//         lockedMethodsForUsers[_methodName][_sender] = false;
//     }

//     function requireNotLockedContract(string memory _message) private view {
//         require(!contractLocked, _message);
//     }

//     function requireNotLockedMethod(string memory _methodName, string memory _message) private view {
//         require(!lockedMethods[_methodName], _message);
//     }

//     function requireNotLockedMethodForUser(string memory _methodName, address _sender, string memory _message) private view {
//         require(!lockedMethodsForUsers[_methodName][_sender], _message);
//     }
// }

// struct Bids3 {
//     address[] tokens;
//     uint256 totalChance;
//     mapping(address => uint256) amounts;
// }

// struct WinnerRecord3 {
//     address winner;
//     uint256 timestamp;
//     bool hasWithdrawn;
//     uint256 ethPrize;
//     address[] tokens;
//     mapping(address => uint256) tokenAmounts;
// }

// /*
//     VRFConsumerBase
    
//         Ethereum Mainnet
//             LINK Token      0x514910771AF9Ca656af840dff83E8264EcF986CA
//             VRF Coordinator 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952
//             Key Hash        0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445
//             Fee (info)      2 LINK = 2 000 000 000 000 000 000
    
//         Polygon (Matic) Mainnet
//             LINK Token      0xb0897686c545045aFc77CF20eC7A532E3120E0F1
//             VRF Coordinator 0x3d2341ADb2D31f1c5530cDC622016af293177AE0
//             Key Hash        0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da
//             Fee (info)      0.0001 LINK = 100 000 000 000 000
    
//         Polygon (Matic) Mumbai Testnet
//             LINK Token      0x326C977E6efc84E512bB9C30f76E30c160eD06FB
//             VRF Coordinator 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255
//             Key Hash        0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4
//             Fee (info)      0.0001 LINK = 100 000 000 000 000
    
//         Kovan Testnet
//             LINK Token      0xa36085F69e2889c224210F603D836748e7dC0088
//             VRF Coordinator 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
//             Key Hash        0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
//             Fee (info)      0.1 LINK = 100 000 000 000 000 000
    
//         Rinkeby Testnet
//             LINK Token      0x01BE23585060835E02B77ef475b0Cc51aA1e0709
//             VRF Coordinator 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
//             Key Hash        0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
//             Fee (info)      0.1 LINK = 100 000 000 000 000 000
    
// */

// /*
//     Uniswap
    
//         IUniswapV2Factory   0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
//         IQuoter             0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6
// */

// contract Raffle3 is Ownable, NonReentrant3, VRFConsumerBase {
//     // 2 ** 256 - 1
//     uint256 constant MAX_ALLOWANCE = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
//     uint256 maxPlayers;
//     uint256 ticketFee;
//     uint256 collectedFee;
    
//     // game state
//     enum GameStates{ GAMING, ROLLING, RANDOM_REQUEST_ID_FAILED, RANDOM_RECEIVED, WINNER_CHOSEN }
//     GameStates gameState;
//     bytes32 randomRequestId;
    
//     // parameters for randomness via VRFConsumerBase
//     bytes32 internal keyHash;
//     uint256 internal randomnessFee;
//     // chailink price feed
//     // AggregatorV3Interface linkPriceFeed;

//     // parameters for prices
//     address uniswapFactoryAddress;
//     IUniswapV2Factory uniswapFactory;
//     address weth = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
//     IQuoter quoter;
    
//     // current players in a game
//     address[] players;
//     // helps to define whether address is playing at the moment
//     mapping(address => bool) activePlayers;
//     // bids by player
//     mapping(address => Bids3) bids;
    
//     // current tokens in a game
//     address[] tokens;
//     // amount deposited by each token
//     mapping(address => uint256) bidsByToken;
    
//     // winner => timestamp[]
//     mapping(address => uint256[]) winnerTimestamps;
//     // winner => timestamp => WinnerRecord
//     mapping(address => mapping(uint256 => WinnerRecord3)) winners;
    
//     event MaxPlayersNumberChanged(uint256 oldValue, uint256 newValue);
//     event TicketFeeChanged(uint256 oldValue, uint256 newValue);
//     event BidRegistered(address indexed player, address token, uint256 amount); // add gameId aka counter
//     event PaymentReceived(address sender, uint256 amount);
//     event Rolling(bytes32 indexed randomRequestId);
//     event RandomCallbackReceived(bytes32 indexed randomRequestId, uint256 value);
//     event GameRandomValueCalculated(uint256 randomNumber, uint256 mod, uint256 value);
//     event WinnerAddressIsChosen(address indexed winner, uint256 timestamp);
//     event WinningAssigned(address indexed winner, uint256 timestamp, uint256 ethAmount);
    
//     event LogInfo(string message);

//     /*
//     constructor(
//         uint256 _maxPlayers
//         , uint256 _ticketFee
//         // parameters for randomness
//         , address _linkToken
//         , address _vrfCoordinator
//         , bytes32 _keyHash
//         , uint256 _randomnessFee // in wei
//         // parameters for prices
//         , address _uniswapFactoryAddress
//     ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
//         maxPlayers = _maxPlayers;
//         ticketFee = _ticketFee;
//         collectedFee = 0;
        
//         keyHash = _keyHash;
//         randomnessFee = _randomnessFee;

//         setupUniswap(_uniswapFactoryAddress);
//     }
//     */
//     // RINKEBY CTOR FOR SIMPLICITY
//     constructor() VRFConsumerBase(0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, 0x01BE23585060835E02B77ef475b0Cc51aA1e0709) {
//         maxPlayers = 100;
//         ticketFee = 0;
//         collectedFee = 0;
        
//         keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
//         randomnessFee = 100000000000000000;

//         setupUniswap(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
//         setupQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
//     }

//     function setupUniswap(address _uniswapFactoryAddress) public onlyOwner {
//         uniswapFactory = IUniswapV2Factory(_uniswapFactoryAddress);
//     }

//     function setupQuoter(address _quoterAddress) public onlyOwner {
//         quoter = IQuoter(_quoterAddress);
//     }
    
//     // this fucking shit works.
//     function getPriceFromChainlink(address _proxy)
//     public
//     view
//     returns (
//       uint80 roundId,
//       int256 price,
//       uint256 startedAt,
//       uint256 updatedAt,
//       uint80 answeredInRound
//     ) {
//         (
//             roundId, 
//             price,
//             startedAt,
//             updatedAt,
//             answeredInRound
//         ) = AggregatorV3Interface(_proxy).latestRoundData();
//     }
    
//     /*
//     function getUniswapExchange(address _token) public returns(IUniswapExchange) {
//         emit LogInfo("UNI exch requested");
//         IUniswapExchange exchange = IUniswapExchange(uniswapFactory.getExchange(_token));
//         emit LogInfo("UNI exch filled");
//         return exchange;
//     }

//     function getTokenToEthPrice(address _token, uint256 _tokenAmount) public returns(uint256) {
//         emit LogInfo("TokenToEthPrice requested");
//         IUniswapExchange exchange = getUniswapExchange(_token);
//         emit LogInfo("TokenToEthPrice exch filled");
//         uint256 price = exchange.getTokenToEthInputPrice(_tokenAmount);
//         emit LogInfo("TokenToEthPrice exch price filled");
//         return price;
//     }
//     */
    
//     // cost: 0.00005 ETH
//     // this method returns not a price, but a 'cumulativePrice' - kinda sum of all the previous prices 
//     event PriceFilled(uint256 price0, uint256 price1);
//     function getUniswapPair(address _token) public {
//         emit LogInfo("price requested");
//         // function getPair(address tokenA, address tokenB) external view returns (address pair);
//         IUniswapV2Pair pair = IUniswapV2Pair(uniswapFactory.getPair(weth, _token));
//         emit LogInfo("pair filled");
//         uint256 price0 = pair.price0CumulativeLast();
//         emit LogInfo("price0 filled");
//         uint256 price1 = pair.price1CumulativeLast();
//         emit LogInfo("price1 filled");
//         emit PriceFilled(price0, price1);
//     }

    
//     function getEstimatedEthPrice(address _token, uint256 _amount) public pure returns(uint256) {
//         // TODO
//         return _amount;
//     }

//     // do not use it on-chain, gas inefficient!
//     // possible solution - if onlyOwner is rolling, then get prices on rolling on a 'frontend' side,
//     // such is treated to be more gas efficient
//     // https://soliditydeveloper.com/uniswap3
//     function quoteExactOutputSingle(address _token, uint256 _amount) public returns(uint256) {
//         if (_token == weth) {
//             return _amount; // if a user deposits weth
//         }

//         return quoter.quoteExactOutputSingle(
//             _token,
//             weth,
//             0, // fee
//             _amount,
//             0 // sqrtPriceLimitX96
//         );
//     }
    
//     /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
//     /// @param tokenIn The token being swapped in
//     /// @param tokenOut The token being swapped out
//     /// @param fee The fee of the token pool to consider for the pair
//     /// @param amountIn The desired input amount
//     /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
//     /// @return amountOut The amount of `tokenOut` that would be received
//     function quoteExactInputSingle(
//         address tokenIn,
//         address tokenOut,
//         uint24 fee,
//         uint256 amountIn,
//         uint160 sqrtPriceLimitX96
//     ) public payable returns (uint256 amountOut) {
//         return quoter.quoteExactInputSingle(tokenIn, tokenOut, fee, amountIn, sqrtPriceLimitX96);
//     }
    
//     /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
//     /// @param tokenIn The token being swapped in
//     /// @param tokenOut The token being swapped out
//     /// @param fee The fee of the token pool to consider for the pair
//     /// @param amountOut The desired output amount
//     /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
//     /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
//     function quoteExactOutputSingle(
//         address tokenIn,
//         address tokenOut,
//         uint24 fee,
//         uint256 amountOut,
//         uint160 sqrtPriceLimitX96
//     ) public payable returns (uint256 amountIn) {
//         return quoter.quoteExactOutputSingle(tokenIn, tokenOut, fee, amountOut, sqrtPriceLimitX96);
//     }
    
//     // to accept eth sent to the contract
//     receive() external payable {
//         emit PaymentReceived(msg.sender, msg.value);
//     }
    
//     function deposit(address _token, uint256 _amount)
//         public
//         payable
//         lockMethodForUser("deposit", msg.sender, "Reentrancy detected")
//         contractIsNotLocked("Someone is already rolling, please wait until new game starts.")
//         {
//         // DATA FROM MSG
        
//         address msgSender = msg.sender;
//         uint256 msgValue = msg.value;
        
//         // REQUIRE
//         emit LogInfo("deposit started");
        
//         require(msgValue >= ticketFee, "You should pay to play.");
        
//         // uint256 allowedToTransfer = IERC20(_token).allowance(msgSender, address(this));
//         // require(allowedToTransfer >= _amount, "Please allow to transfer tokens.");
        
//         require(players.length < maxPlayers, "All seats are taken, rolling is in progress");
        
//         // ACT
//         emit LogInfo("passed require section");
        
//         // if player is not yet registered - register it
//         if (!activePlayers[msgSender]) {
//             activePlayers[msgSender] = true;
//             players.push(msgSender);
//             emit LogInfo("player added");
//         } else {
//             emit LogInfo("player exists");
//         }
        
//         // alter player's bids
//         Bids3 storage playerBids = bids[msgSender];
//         if (playerBids.amounts[_token] == 0) {
//             playerBids.tokens.push(_token);
//         }
//         playerBids.amounts[_token] += _amount;
        
//         emit LogInfo("quirying price...");
        
//         // playerBids.totalChance += getTokenToEthPrice(_token, _amount);
//         // getUniswapPair(_token);
//         playerBids.totalChance += getEstimatedEthPrice(_token, _amount);
        
//         emit LogInfo("price received");
        
//         bidsByToken[_token] += _amount;
        
//         emit LogInfo("bids updated");
        
//         // PERFORM $ OPERATIONS
        
//         // send tokens to contract
//         // IERC20(_token).transferFrom(msgSender, address(this), _amount);
        
//         emit LogInfo("token transferred");
        
//         // collect fee
//         collectedFee += msgValue;
        
//         emit LogInfo("collected fee updated");
//     }
    
//     function roll() public onlyOwner lockContractWithNoRelease("Someone is already rolling") {
//         require(LINK.balanceOf(address(this)) >= randomnessFee, "Not enough LINK to request randomness.");
//         randomRequestId = 0;
//         gameState = GameStates.ROLLING;
//         randomRequestId = requestRandomness(keyHash, randomnessFee);
//         emit Rolling(randomRequestId);
//     }
    
//     function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
//         emit RandomCallbackReceived(_requestId, _randomness);
//         if (_requestId != randomRequestId) {
//             gameState = GameStates.RANDOM_REQUEST_ID_FAILED;
//             revert("Random requestId does not coinsides");
//         }
//         gameState = GameStates.RANDOM_RECEIVED;
//         randomCallbackReceived(_randomness);
//     }

//     function randomCallbackReceived(uint256 _randomNumber) public releaseLockedContract("Bonus is already rolled.") {
//         // totalChanceSum = sum of totalChance
//         uint256 totalChanceSum = _calcCurrentTotalChance();

//         // final random number
//         uint256 finalRandomNumber = _randomNumber % totalChanceSum;
        
//         emit GameRandomValueCalculated(_randomNumber, totalChanceSum, finalRandomNumber);
        
//         chooseWinner(finalRandomNumber, totalChanceSum);
//     }

//     function chooseWinner(uint256 _random, uint256 _totalChanceSum) private {
//         address winner;
//         uint256 totalChanceSum = 0;
//         uint256 playersLength = players.length;
//         if (_totalChanceSum / 2 > _random) {
//             // random is in the first half
//             uint256 current = 0;
//             for (uint256 i = 0; i < playersLength; i++) {
//                 current += bids[players[i]].totalChance;
//                 if (current >= _random) {
//                     // this is the winner
//                     winner = players[i];
//                     i = playersLength;
//                 }
//             }
//         } else {
//             // random is in the second half
//             uint256 current = totalChanceSum;
//             // TODO not a good idea to use int256
//             for (int256 i = int256(playersLength - 1); i >= 0; i--) {
//                 current -= bids[players[uint256(i)]].totalChance;
//                 if (current >= _random) {
//                     // this is the winner
//                     winner = players[uint256(i)];
//                     i = 0;
//                 }
//             }
//         }
        
//         emit WinnerAddressIsChosen(winner, block.timestamp);
        
//         assignTokens(payable(winner));
//     }
    
//     function assignTokens(address payable _winner) private {
//         // transfer all the tokens + fee
//         // what is our benefit?
        
//         uint256 timestamp = block.timestamp;
        
//         WinnerRecord3 storage winRecord = winners[_winner][timestamp];
        
//         winRecord.winner = _winner;
//         winRecord.timestamp = timestamp;
//         winRecord.hasWithdrawn = false;
        
//         // copy eth data and clear it
//         uint256 ethToSend = collectedFee;
//         collectedFee = 0;
//         winRecord.ethPrize = ethToSend;
        
//         // copy token data and clear it
//         uint256 tokensLen = tokens.length;
//         for (uint256 i = 0; i < tokensLen; i++) {
//             address token = tokens[i];
//             uint256 amount = bidsByToken[token];
            
//             winRecord.tokens.push(token);
//             winRecord.tokenAmounts[token] = amount;
            
//             // clear assigned tokens
//             delete bidsByToken[token];
//         }
        
//         // clear as much as possible
//         uint256 playersLen = players.length;
//         for (uint256 i = 0; i < playersLen; i++) {
//             address player = players[i];
//             delete activePlayers[player];
//             delete bids[player];
//         }
        
//         delete players;
//         delete tokens;
        
//         emit WinningAssigned(winRecord.winner, winRecord.timestamp, winRecord.ethPrize);
//     }

//     /* REGION PRIVATE */

//     function _calcCurrentTotalChance() private view returns(uint256) {
//         uint256 totalChanceSum = 0;
//         uint256 playersLength = players.length;
//         for (uint8 i = 0; i < playersLength; i++) {
//             totalChanceSum += bids[players[i]].totalChance;
//         }
//         return totalChanceSum;
//     }
    
//     /* REGION GETTERS / SETTERS */
    
//     function getMaxAllowance() public pure returns(uint256) {
//         return MAX_ALLOWANCE;
//     }

//     function setMaxPlayers(uint256 _maxPlayers) public onlyOwner {
//         require(_maxPlayers > 1, "There should be at least 2 players.");
//         uint256 oldValue = maxPlayers;
//         maxPlayers = _maxPlayers;
//         emit MaxPlayersNumberChanged(oldValue, maxPlayers);
//     }
    
//     function setTicketFee(uint256 _ticketFee) public onlyOwner {
//         require(_ticketFee > 0, "Fee should be greate than 0.");
//         uint256 oldValue = ticketFee;
//         ticketFee = _ticketFee;
//         emit TicketFeeChanged(oldValue, ticketFee);
//     }

//     /* REGION HELPERS */
    
//     function _getMaxPlayers() public view returns(uint256) {
//         return maxPlayers;
//     }
    
//     function _getTicketFee() public view returns(uint256){
//         return ticketFee;
//     }
    
//     function _getCollectedFee() public view returns(uint256){
//         return collectedFee;
//     }
    
//     function _getUserChance(address _address) public view returns(uint256) {
//         return bids[_address].totalChance;
//     }

//     function _getPlayers() public view returns(address[] memory) {
//         return players;
//     }

//     function _isPlayerActive(address _player) public view returns(bool) {
//         return activePlayers[_player];
//     }

//     function _getPlayerChance1000(address _player) public view returns(uint256 value, uint32 base) {
//         return _getPlayerChance(_player, 1000);
//     }

//     function _getPlayerChance(address _player, uint32 _base) public view returns(uint256 value, uint32 base) {
//         uint256 totalChances = _calcCurrentTotalChance();
//         uint256 playerValue = bids[_player].totalChance;
//         return (playerValue * _base / totalChances, _base);
//     }

//     function _getPlayerBidsTokens(address _player) public view returns (address[] memory) {
//         return bids[_player].tokens;
//     }

//     function _getPlayerBidTokenAmount(address _player, address _token) public view returns(uint256) {
//         return bids[_player].amounts[_token];
//     }

//     function _getTokens() public view returns(address[] memory) {
//         return tokens;
//     }

//     function _getTokenBid(address _token) public view returns(uint256) {
//         return bidsByToken[_token];
//     }

//     function _getWinnerTimestamps(address _winner) public view returns(uint256[] memory) {
//         return winnerTimestamps[_winner];
//     }

//     function _getWinnerRecord(address _winner, uint256 _timestamp) public view returns(address winner, uint256 timestamp, bool hasWithdrawn, uint256 ethPrize, address[] memory tokenAddresses) {
//         WinnerRecord3 storage rec = winners[_winner][_timestamp];
//         return (rec.winner, rec.timestamp, rec.hasWithdrawn, rec.ethPrize, rec.tokens);
//     }
    
//     function _getWinnerTokenAmount(address _winner, uint256 _timestamp, address _token) public view returns(uint256) {
//         return winners[_winner][_timestamp].tokenAmounts[_token];
//     }
    
//     function approve(address _token) public {
//         IERC20(_token).approve(address(this), MAX_ALLOWANCE);
//     }
// }