# Upgradeable On-chain NFT

This is a sample of Solidity architecture, that allows to build an upgradeable NFT, storing data on-chain. Contains a list of interfaces and their implementations (all the interfaces are described below), plus a deployment script.
<br/>
<br/>
Any* item of the system might be replaced with its updated version. When replaced, its new address should be registered in IAppBeacon instance.
<br/>
.* It might be better not to replace an instance of IAppBeacon, as it's build as a generic one for all possible cases, and simply resolves addresses by contract names (or aliases). So there's no need to be replaced, but you are free to use the code in any way.
<br/>
*Just do not forget to star my repo, haha*.
<br/>
<br/>
*Business use case #1*: you wish to change how NFTs are being shown.
<br/>
Solution: you simply need to code another implementation of INftImageResolver and register it in IAppBeacon - and that's it.
<br/>
<br/>
*Business use case #2*: you wish to store images off-chain (on your own server or ipfs).
<br/>
Solution: code another implementation of INftImageResolver with internal mapping(uint256 => string) which will resolve URIs, register the instance in IAppBeacon.
<br/>
<br/>
*Business use case #3*: you wish to have no restrictions on minting NFTs.
<br/>
Solution: set address of INftMintingAllowance in IAppBeacon to address(0).
<br/>
<br/>
The diagram below shows major calls inside the system. Red circle is a kind of "entry point" for a user - a user need to a) mint a token; b) see it. All the other calls inside a system are restricted to a particular caller (when needed). I hope I have not missed a lot.
<br/>
<br/>
*.drawio* and *.png* files of the diagram ara available in the repo in `diagrams` folder.
<br/>
<br/>
![alt text](https://github.com/artem-bayandin/blockchain-samples/blob/master/upgradeable-onchain-nft/diagrams/Component%20and%20DataFlow.png?raw=true)
<br/>
<br/>
**Have Fun!**

## IAppBeacon

Allows registration and retrieval of contracts that might be replaced later.

```
interface IAppBeacon {
    // registers or updates the 'address' for 'name'
    function set(string memory _name, address _address) external;
    // returns contract address by name
    function get(string memory _name) external view returns (address);
}
```

## INftDataStorage

Allows storing non-business valuable data aside of an NFT itself.
<br/>
This is needed for cases, when you plan to extend the data related to an NFT, so that NFT only contains some 'basic' data, and this storage contains other pieces of data.

```
interface INftDataStorage {
    // adds or updates KVP, related to a tokenId, in storage
    function upsert(uint256 _tokenId, KeyValuePair[] memory _data) external;
    // gets all the KVPs that are related to a tokenId
    function get(uint256 _tokenId) external view returns (KeyValuePair[] memory);
}
```

## INftImageResolver

Resolves 'image' link in NFT metadata (find more in Opensea NFT metadata description).

```
interface INftImageResolver {
    // returns Base64 of an image
    function getImage(string memory _name, uint256 _age) external view returns (string memory);
}
```

## INftTokenUriResolver

Resolves 'tokenUri' of NFT.

- For On-chain based NFTs it should return a Base64 equivalent (as implemented in OnchainNftTokenUriResolver)
- For Off-chain based NFTs it should return a valid link to ipfs or any other external metadata storage.

```
interface INftTokenUriResolver {
    // for On-chain based NFTs it should return a Base64 equivalent
    // or Off-chain based NFTs it should return a valid link to ipfs or any other external metadata storage
    function getTokenUri(uint256 _tokenId) external view returns (string memory);
}
```

## INftMinter

Main NFT contract itself. Most likely, this one will never be replaced in an app. But it's possible.

```
interface INftMinter {
    // mints an nft
    // in current case - with props 'owner', 'name', 'age'
    function mint(address _owner, string memory _name, uint256 _age) external payable returns (uint256);
    // returns a data for an NFT that is stored in the contract
    function getGeneralNftData(uint256 _tokenId) external view returns (string memory _name, uint256 _age);
}
```

## INftMintingAllowance

Restricts minting of NFTs, if required by business logic (inside INftMinter). Should be used together with INftManager, as INftMinter has no restrictions.

```
interface INftMintingAllowance {
    // defines whether minting of a token with current params is allowed
    function mintingIsAllowed(address _msgSender, string memory _name, uint256 _age) external view returns (bool);
}
```

## INftManager

Business logic for the overall process. Should be used as an entry point to the system.

```
interface INftManager {
    // mints a token
    function mint(string memory _name, uint256 _age) external payable returns (uint256);
}
```
