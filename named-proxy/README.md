# named-proxy

## Description

Given standard OZ Beacons, it may only store a single reference to an implementation. But what if you wish to store all your project references in a single contract, and fetch it via proxies?

So, here goes an upgraded version of Beacon - `NamedBeacon`, which implements `setImplementation(bytes32 _refName, address _addr) external` and `getImplementation(bytes32 _refName) view returns (address _impl)`.
Then goes a specifically improved `NamedBeaconProxy` - which stores an immutable ref to the beacon, as well as an immutable reference id for the implementation it refers to. Immutability allows to avoid storage collision, as well as strictly assign the beacon and implementation ref id to the proxy.

## Project commands

`yarn` - install dependencies
`yarn hcf` - shortcut for `yarn hardhat compile --force` to compile smart contracts
`yarn ht` - shortcut for `yarn hardhat test` to run all tests

## Usage flow

1. deploy `NamedBeacon`
2. deploy your contract(s) implementation(s)
3. register reference(s) to your implementation(s) in `NamedBeacon` (beacon will act as a "service locator")
4. for each needed implementation to be targeted, deploy `NamedBeaconProxy` with beacon address and implementation reference id
5. have fun
6. in case you need to change the implementation address, simply assign a new value in `NamedBeacon` under the previously registered reference id - and the whole system will now use it
