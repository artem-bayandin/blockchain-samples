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
  - via chainlink oracle (`function rollTheDice()`);
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

## Release increments

### commit [a900a1f](https://github.com/artem-bayandin/blockchain-samples/commit/a900a1f1b1230b6f896e4f7f2a5534b0b3df79d4)

Improved:

- obsolete Raffle3.sol file deleted;
- added test mocks for erc20 tokens;
- added test mocks for chainlink price oracles;
- migration migrates (`truffle migrate --network development --reset`)
- environment for tests is done (`truffle test --network devtest`) (does not include open issue with mocking randomizer)

Questions I have:

- is it possible to move randomizer into a separate contract, so that it could be later injected into the game, instead of inheriting?
- how to mock randomizer? (if inheritance is removed, then it'll be easy to mock it)
- is it 'OK', that I have like the game contract, a contract for custom price oracle, an abstract contract for managing admin permissions (this one should be moved to 'utils' repo), and additionally I have 7 test contracts (mock-like) and I may need more? should I deploy them all in migration for my local network? (so that when deploying to production, I will only deploy the 3)

### commit [492018f](https://github.com/artem-bayandin/blockchain-samples/commit/492018f92d33e8eb6c526953753acfed4da9b48a)

- [done] add `withdraw` functionality for a winner;
- [done] refactor rolling the wheel, so that manually it'll require 2 steps: a) set the game status to 'rolling'; b) input 'random' number and trigger selection of a winner;
- [done] create a custom ERC20 token to be able to test the code;
- [almost] refactor roles (move method locks into Adminable.sol);

### commit [407967a](https://github.com/artem-bayandin/blockchain-samples/commit/407967af9e59f8cb3a1bef8448776fa6e21dc76c)

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

### commit [6fbe5d0](https://github.com/artem-bayandin/blockchain-samples/tree/6fbe5d0c9fd517066e5f2f643ef18160debf91dc)
- [Raffle3.sol](https://github.com/artem-bayandin/blockchain-samples/blob/6fbe5d0c9fd517066e5f2f643ef18160debf91dc/raffle/contracts/Raffle3.sol) - a playground to manually test the logic and oracles. Manually, it works, being deployed to Rinkeby;
- [Raffle.sol](https://github.com/artem-bayandin/blockchain-samples/blob/6fbe5d0c9fd517066e5f2f643ef18160debf91dc/raffle/contracts/Raffle.sol) - a cleaned version of Raffle3.sol, not yet tested, but ready to;
- token allowance should be covered on a frontend, unlimited permissions will be requested (approve 2 ** 256 - 1);
- `withdraw` function is not yet implemented;
- chainlink data providers should be later moved into separate files, notations are to be added;
- no tests at the moment; (sample of truffle tests might be found [here](https://github.com/artem-bayandin/blockchain-satisfactor/tree/master/test), although it will be refactored soon);
- no UI at the moment (sample of React UI folder structure might be found [here](https://github.com/artem-bayandin/blockchain-satisfactor/tree/master/src), although it will be refactored soon).
