# diamond-2535

Disclaimer: although the code is copied from my commercial projects, don't forget to DYOR before using it.

## Description

Improved version of [mudgen/diamond-3-hardhat](https://github.com/mudgen/diamond-3-hardhat)

- switched to the latest versions (hardhat: 3.1.6, solidity: 0.8.33), including smart contracts, scripts, sample script
- `LibDiamondOwnable` extracted into a separate lib, as you will definitely need this in your facets, and moving it into a separate libs lets you move less extra code into your facets
- some minor tweaks in contracts and scripts

## Usage flow

See the `scripts/sample.ts` file.

You may also run it like `yarn hrun scripts/sample.ts`.

## Project commands and techs used

- Hardhat 3.1.6
- Solidity 0.8.33
- `yarn` - install dependencies
- `yarn hcf` - shortcut for `yarn hardhat compile --force` to compile smart contracts
- `yarn ht` - shortcut for `yarn hardhat test` to run all tests
