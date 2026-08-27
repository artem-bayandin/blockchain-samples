Samples of my code in blockchain domain. General tech stack is: Solidity, React, Hardhat.

Code might not be gas-efficient, nor it has to be protected against all the 100500% of existing vulnerabilities. It's just a sample. So if you think "it shouldn't be done like this", just ask me and I'll explain why this or that decision has been taken.

Some code exists in current repo, another is split within other repos.

## Named proxy (2026)

*[the code and extended description is here](https://github.com/artem-bayandin/named-beacon-proxy)*

Given standard OZ Beacons, it may only store a single reference to an implementation. But what if you wish to store all your project references in a single contract, and fetch it via proxies?

So, here goes an upgraded version of Beacon - `NamedBeacon`, which implements `setImplementation(bytes32 _refName, address _addr) external` and `getImplementation(bytes32 _refName) view returns (address _impl)`.
Then goes a specifically improved `NamedBeaconProxy` - which stores an immutable ref to the beacon, as well as an immutable reference id for the implementation it refers to. Immutability allows to avoid storage collision, as well as strictly assign the beacon and implementation ref id to the proxy.

## Diamond-2535 (2026)

*[the code and extended description is here](https://github.com/artem-bayandin/diamond-2535)*

Delegate work from your system to one of registered implementations. The original code was slightly improved as well as upgraded to up-to-date versions of Hardhat (3.1.6) and Solidity (0.8.33).

Refer to [mudgen/diamond](https://github.com/mudgen/diamond)

## Utils (2021)

During code development, some interesting gems happen to be created, and I've put some into my [blockchain-utils](https://github.com/artem-bayandin/blockchain-utils) repo (for now includes Roles management, and some interfaces for Chainlink ecosystem).

## Raffle (2021)

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

## Upgradeable On-chain NFT (2021)

*[the code and extended description is here](https://github.com/artem-bayandin/blockchain-samples/tree/master/upgradeable-onchain-nft)*

Covers the next topics:

- total of 7 Solidity contracts: NFT, TokenURI, Image, Storage, Manager, Allowance, Beacon;
- interfaces;
- building metadata and image on-chain;
- ability to easily replace ANY of the contracts, even NFT one. In addition, you may switch restrictions to mint NFTs, the logic of minting, the data that is stored, the way metadata is stored and retrieved, the way an image is being built and shown on a marketplace like Opensea;
- **600 lines of code, 100 lines of deployment scripts**, 7 contracts, 7 interfaces, 1 base abstract contract.

## Reference to 'Replaceable' contracts (metamorphic)

Mechanics to replace a contract at a specific address. Yes, REPLACE, not just "upgrade". A funky project (clone), that was forgotten. Moreover, with the Solidity updates (somewhere in 0.8.[0..28]), it might be not possible to achieve this with the latest Sol features.

Refer to [0age/metamorphic](https://github.com/0age/metamorphic)
