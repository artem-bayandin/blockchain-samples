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

## Release increments

### milestone [d4503c6](https://github.com/artem-bayandin/blockchain-samples/commit/d4503c63119c2e5f5f601d2b9430e8f272b097e2)

- samples of tests for `deposit()` were added (validates amounts of tokens deposited, and collected fee);
- RaffleExtended contract was extracted from Raffle not to pollute Raffle with getters/setters for tests;
- interfaces and implementations of oracles were split into separate files.

Notes. Most likely, there will be a pause in development after this milestone, as all the major practices are implemented. To the moment, game contracts contain around 1k lines of code, plus test files contain another 1k lines of code.

### milestone [99c6fe8](https://github.com/artem-bayandin/blockchain-samples/commit/99c6fe8fa48f71540510fbe165a3ae545dd35ea7)

_An outstanding milestone: Raffle game contract is from now abstracted from oracles, both price oracle and randomness oracle via its interfaces, what makes it easy to implemented a new oracle and switch the game to a new address. And all you need - just implement oracles as [IPriceOracle](https://github.com/artem-bayandin/blockchain-samples/blob/99c6fe8fa48f71540510fbe165a3ae545dd35ea7/raffle/contracts/PriceOracle.sol) and [IRandomnessOracle](https://github.com/artem-bayandin/blockchain-samples/blob/99c6fe8fa48f71540510fbe165a3ae545dd35ea7/raffle/contracts/RandomnessOracle.sol), and for randomness Raffle needs to implement [IRandomnessReceiver](https://github.com/artem-bayandin/blockchain-samples/blob/99c6fe8fa48f71540510fbe165a3ae545dd35ea7/raffle/contracts/RandomnessOracle.sol), as its functions are called when a number is generated._
<br/>
<br/>
Migration file was updated. Test environment setup was updated. `truffle compile` succeeds. `truffle migrate --network development [--reset]` succeeds. `truffle test --network devtest` succeeds.
<br/>
<br/>
Next to do: code tests, refactor contracts if needed.

### milestone [a900a1f](https://github.com/artem-bayandin/blockchain-samples/commit/a900a1f1b1230b6f896e4f7f2a5534b0b3df79d4)

Improved:

- obsolete Raffle3.sol file was deleted;
- added test mocks for erc20 tokens;
- added test mocks for chainlink price oracles;
- migration migrates (`truffle migrate --network development --reset`)
- environment for tests is done (`truffle test --network devtest`) (does not include open issue with mocking randomizer)

Next:
- extract interfaces and create an abstraction over chainlink randomizer, so that it could be possible to switch and/or mock a randomizer;
- tests.

### milestone [492018f](https://github.com/artem-bayandin/blockchain-samples/commit/492018f92d33e8eb6c526953753acfed4da9b48a)

- [done] added `withdraw` functionality for a winner;
- [done] refactored rolling the wheel, so that manually it'll require 2 steps: a) set the game status to 'rolling'; b) input 'random' number and trigger selection of a winner;
- [done] created a custom ERC20 token to be able to test the code;
- [almost] refactored roles (move method locks into Adminable.sol);

### milestone [407967a](https://github.com/artem-bayandin/blockchain-samples/commit/407967af9e59f8cb3a1bef8448776fa6e21dc76c)

Chainlink data providers refactored:

- two oracles are prepared for EHT Mainnet and Rankeby Testnet;
- it's now possible to add a chainlink proxy address for a token;
- Token-ETH value is now calculated right;
- Rankeby price oracle successfully tested on Rankeby.

Next steps:

- add `withdraw` functionality for a winner;
- refactor rolling the wheel, so that manually it'll require 2 steps: a) set the game status to 'rolling'; b) input 'random' number and trigger selection of a winner;
- create a custom ERC20 token to be able to test the code;
- refactor more (move roles management (admin rights) into an abstract base class);
- code truffle tests;
- code minimal UI.

### milestone [6fbe5d0](https://github.com/artem-bayandin/blockchain-samples/tree/6fbe5d0c9fd517066e5f2f643ef18160debf91dc)
- [Raffle3.sol](https://github.com/artem-bayandin/blockchain-samples/blob/6fbe5d0c9fd517066e5f2f643ef18160debf91dc/raffle/contracts/Raffle3.sol) - a playground to manually test the logic and oracles. Manually, it works, being deployed to Rinkeby;
- [Raffle.sol](https://github.com/artem-bayandin/blockchain-samples/blob/6fbe5d0c9fd517066e5f2f643ef18160debf91dc/raffle/contracts/Raffle.sol) - a cleaned version of Raffle3.sol, not yet tested, but ready to;
- token allowance should be covered on a frontend, unlimited permissions will be requested (approve 2 ** 256 - 1);
- `withdraw` function is not yet implemented;
- chainlink data providers should be later moved into separate files, notations are to be added;
- no tests at the moment; (sample of truffle tests might be found [here](https://github.com/artem-bayandin/blockchain-satisfactor/tree/master/test), although it will be refactored soon);
- no UI at the moment (sample of React UI folder structure might be found [here](https://github.com/artem-bayandin/blockchain-satisfactor/tree/master/src), although it will be refactored soon).
