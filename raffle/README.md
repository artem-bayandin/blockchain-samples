# Raffle game

## Description
Kind of a Raffle lottery game.
<br/>
Some requirements/assumptions:

- a user should deposit ERC20 tokens to have a higher chance to win;
- all the ERC20 tokens and fees collected will become a prize for a winner later on;
- chance to win = ETH equality of ERC20 tokens a player has deposited to the game vs the sum of all the tokens deposited to the game;
- Token/ETH price should be fetched via oracle;
- the wheel is rolled manually (requires an admin panel or a background service on a server, has some trade-offs);
- when the wheel is rolled, gameStatus becomes "Rolling", so that no one was able to deposit or roll the wheel;
- two ways of generating a random number:
  - manual, via manual input of a 'random' number (`function rollTheDice(uint256 randomNumber)`);
  - via randomness oracle (`function rollTheDice()`);
- when a valid random number is found, sumOfUsersChances is calculated. To find a winner, the game simply summs personalChances one by one, until the number reaches (`randomNumber % sumOfUsersChances`);
- when a winner is found, accumulated fee and all the tokens are assigned to a winner;
- the winner needs to manually withdraw its tokens (to avoid some vulnerabilities);
- when tokens are re-assigned, the game is open to play again.

Example.
<br/>
User deposits 1 LINK to the game. LINK / ETH = 0.008, fee applied = 0.0001 ETH, personalChanceToWin = 0.008 ETH.
<br/>
User additionally deposits 1 BNB. BNB / ETH 0.12, fee applied = 0.0001 ETH, personalChanceToWin = 0.128 ETH.
<br/>
Other users deposit coins for 5 ETH in sum. Final chanceToWin for our user is 0.128 / 5 = 0.0256, what is 2.56%. Final value of tokens = 5 ETH + fee * numberOfDeposits.
<br/>
<br/>
Further notes.
- Randomness oracle. Chainlink randomness oracle asks for 2 LINK per request to run on ETH Mainnet, what is not so cheap. To make it cheaper, a separate contract might be created, which will collect requests for randomness (example in milestone [99c6fe8](https://github.com/artem-bayandin/blockchain-samples/commit/99c6fe8fa48f71540510fbe165a3ae545dd35ea7) - [ChainlinkRandomnessOracle](https://github.com/artem-bayandin/blockchain-samples/blob/99c6fe8fa48f71540510fbe165a3ae545dd35ea7/raffle/contracts/RandomnessOracle.sol)). Then some web service will query this contract against new requests received, and if any found, then web service will fill these requests with random values.
- Price oracle. Current chainlink price oracle is abstracted with an interface, but is limited by the number of proxies for tokens and just ETH, Kovan and Rinkeby networks. It'd be nice to implement IPriceOracle for at least Uniswap, 1inch.
