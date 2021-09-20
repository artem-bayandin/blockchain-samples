# Raffle game

## Description
Kind of a Raffle lottery game.
<br/>
User 'buys' a ticket and deposits ERC20 tokens to have a higher chance to win.
- fee for participation might be applied;
- chanceToWin = personalChanceToWin / sumOfUsersChances;
- personalChanceToWin = ETH value, equivalent to the deposited amount of ERC20 tokens.
<br/>
'Wheel' is rolled manually. It is possible to roll it with a predefined random value (function rollTheDice(uint256 randomNumber)), or using a Chainlink randomness oracle (function rollTheDice()). At this point the game status becomes "Rolling", so that no one was able to deposit or roll the wheel.
<br/>
When a valid random number is found, sumOfUsersChances is calculated. To find a winner, the game simply summs personalChances one by one, until the number reaches (randomNumber % sumOfUsersChances). When a winner is found, accumulated fee and all the tokens are assigned to a winner. The winner needs to manually withdraw its tokens (to avoid some vulnerabilities). When tokens are re-assigned, the game is open to play again.
<br/>
<br/>
Example.
<br/>
User deposits 1 LINK to the game. LINK / ETH = 0.008, fee applied = 0.0001 ETH, personalChanceToWin = 0.008 ETH.
<br/>
User additionally deposits 1 BNB. BNB / ETH 0.12, fee applied = 0.0001 ETH, personalChanceToWin = 0.128 ETH.
<br/>
Other users deposit coins for 5 ETH in sum. Final chanceToWin for our user is 0.128 / 5 = 0.0256, what is 2.56%. Final value of tokens = 5 ETH + fee * numberOfDeposits.

## Release increments

### commit [407967a](https://github.com/artem-bayandin/blockchain-samples/commit/407967af9e59f8cb3a1bef8448776fa6e21dc76c)

Chainlink data providers refactored:

- two oracles are prepared for EHT Mainnet and Rankeby Testnet;
- it's now possible to add a chainlink proxy address for a token;
- Token-ETH value is now calculated right;
- Rankeby price oracle successfully tested on Rankeby.

Next steps:

- create a custom ERC20 token to be able to test the code;
- refactor more (move roles management (admin rights) into an abstract base class);
- code truffle tests;
- code minimal UI.

### commit [6fbe5d0](https://github.com/artem-bayandin/blockchain-samples/tree/6fbe5d0c9fd517066e5f2f643ef18160debf91dc)
- [Raffle3.sol](https://github.com/artem-bayandin/blockchain-samples/blob/6fbe5d0c9fd517066e5f2f643ef18160debf91dc/raffle/contracts/Raffle3.sol) - a playground to manually test the logic and oracles. Manually, it works, being deployed to Rinkeby;
- [Raffle.sol](https://github.com/artem-bayandin/blockchain-samples/blob/6fbe5d0c9fd517066e5f2f643ef18160debf91dc/raffle/contracts/Raffle.sol) - a cleaned version of Raffle3.sol, not yet tested, but ready to;
- token allowance should be covered on a frontend, unlimited permissions will be requested (approve 2 ** 256 - 1);
- 'withdraw' function is not yet implemented;
- chainlink data providers should be later moved into separate files, notations are to be added;
- no tests at the moment; (sample of truffle tests might be found [here](https://github.com/artem-bayandin/blockchain-satisfactor/tree/master/test), although it will be refactored soon);
- no UI at the moment (sample of React UI folder structure might be found [here](https://github.com/artem-bayandin/blockchain-satisfactor/tree/master/src), although it will be refactored soon).
