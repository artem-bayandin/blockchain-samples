Samples of my code in blockchain domain. General tech stack is: Solidity, React, Truffle, Chai.
<br/>
<br/>
You might be also interested in my *standalone contract samples*, the latter are available in my **[blockchain-utils](https://github.com/artem-bayandin/blockchain-utils)** repo.

## Raffle

*[the code and extended description is here](https://github.com/artem-bayandin/blockchain-samples/tree/master/raffle)*

Covers the next topics:

- depositing eth to the contract, transferring ERC20 tokens;
- price oracle abstraction + Chainlink implementation;
- randomness oracle abstraction + Chainlink implementation;
- "pull-type" of prize withdrawal;
- randomness covered via oracle or manually;
- truffle tests and deployment;
- game statuses, anti-reentrancy defense, and some other basic options/vulnerabilities are covered;
- **1058 lines of code, 100 lines of deployment scripts, 415 lines of integration tests** (tests cover 50% of the app), 4 contracts, 2 interfaces.
- an enterprise-styled code.

## Upgradeable On-chain NFT

*[the code and extended description is here](https://github.com/artem-bayandin/blockchain-samples/tree/master/upgradeable-onchain-nft)*

Covers the next topics:

- total of 7 Solidity contracts: NFT, TokenURI, Image, Storage, Manager, Allowance, Beacon;
- interfaces;
- building metadata and image on-chain;
- ability to easily replace ANY of the contracts, even NFT one. In addition, you may switch restrictions to mint NFTs, the logic of minting, the data that is stored, the way metadata is stored and retrieved, the way an image is being built and shown on a marketplace like Opensea;
- **600 lines of code, 100 lines of deployment scripts**, 7 contracts, 7 interfaces, 1 base abstract contract.

## 'Forum'-like app

*commercial project, will be published when the app is relesed on a blockchain*

Covers the next topics:

- cloning contracts and using different types of proxies,
- upgradeable contracts and routers, upgradeable beacons,
- logic and data storage contracts separation,
- 2 separate upgradeable NFT contracts with marketplaces, storing data on-chain and off-chain,
- earnings for users for their activities;
- **1800 lines of code, 350 lines of deployment scripts, 500 lines of integration tests** (tests cover just basic 'green-ish' functionality), 13 contracts, 13 contract-wrappers for tests (with additional public methods), 11 interfaces, 4 base abstract contracts (on November 3, 2021).
