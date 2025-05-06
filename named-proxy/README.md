# named-proxy

## Description

Given standard OZ Beacons, it may only store a single reference to an implementation. But what if you wish to store all your project references in a single contract, and fetch it via proxies?

So, Beacon should implement `setImplementation(bytes32 _refName, address _addr) external` and `getImplementation(bytes32 _refName) view returns (address _impl)`. Then, Proxy should read an appropriate ref from beacon.

## Project setup

`corepack enable`
`yarn init`
`yarn add -D hardhat`
`yarn hardhat init`

## Use cases

Use cases you might find in tests.