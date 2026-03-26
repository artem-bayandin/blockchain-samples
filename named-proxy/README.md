# named-beacon-proxy

Disclaimer: although the code is copied from my commercial projects, don't forget to DYOR before using it.

## Description

Given standard OZ Beacons, it may only store a single reference to an implementation. But what if you wish to store all your project references in a single contract, and fetch it via proxies? What if you have no wish to deploy a contract to store just a single reference?

So, here goes an upgraded version of Beacon - `NamedBeacon`, which you may deploy just once and manage all your references in a single place. ABI is simple:
- `registerImplementation(bytes32 _referenceId, address _implementation) external`
- `getImplementation(bytes32 _referenceId) external view returns (address _implementation)`.

Ok, then, given standard OZ BeaconProxy, it has the next disadvantages:
- it refers to a single Beacon,
- it stores beacon address in local storage and in a slot of `ERC1967Utils`,
- it contains extra logic you won't need although you will deploy this logic many times, urgh.

So, here goes an improved `NamedBeaconProxy` - which stores an immutable ref to the beacon, as well as an immutable reference id for the implementation it refers to ( `constructor(address _beacon, bytes32 _implementationReferenceId, bytes memory _data) payable` ). Immutability allows to avoid storage collision, as well as strictly assign the beacon and implementation ref id to the proxy. Once you need to change a ref - all the logic is in NamedBeacon.

## Usage flow

1. deploy `NamedBeacon`
2. deploy your contract(s) implementation(s)
3. register reference(s) to your implementation(s) in `NamedBeacon` (beacon will act as a "service locator")
4. for each needed implementation to be targeted, deploy `NamedBeaconProxy` with beacon address and implementation reference id
5. have fun
6. in case you need to change the implementation address, simply assign a new value in `NamedBeacon` under the previously registered reference id - and the whole system will now use it

- p1-3 are shown in `beaconFixture` for `Beacon` tests;
- p4+ are shown in `beaconProxyFixture` for `NamedBeaconProxy` tests

## Project commands and techs used

- Hardhat 3.1.6
- Solidity 0.8.33
- `yarn` - install dependencies
- `yarn hcf` - shortcut for `yarn hardhat compile --force` to compile smart contracts
- `yarn ht` - shortcut for `yarn hardhat test` to run all tests
