// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

struct KeyValuePair {
    string key;
    string value;
}

/*
    IAppBeacon allows registration and retrieval of contracts that might be replaced later.
*/
interface IAppBeacon {
    // registers or updates the 'address' for 'name'
    function set(string memory _name, address _address) external;
    // returns contract address by name
    function get(string memory _name) external view returns (address);
}

/*
    INftDataStorage allows storing non-business valuable data aside of an NFT itself.
    This is needed for cases, when you plan to extend the data related to an NFT,
    so that NFT only contains some 'basic' data, and this storage contains other pieces of data.
*/
interface INftDataStorage {
    // adds or updates KVP, related to a tokenId, in storage
    function upsert(uint256 _tokenId, KeyValuePair[] memory _data) external;
    // gets all the KVPs that are related to a tokenId
    function get(uint256 _tokenId) external view returns (KeyValuePair[] memory);
}

/*
    INftImageResolver resolves 'image' link in NFT metadata (find more in Opensea NFT metadata description)
*/
interface INftImageResolver {
    // returns Base64 of an image
    function getImage(string memory _name, uint256 _age) external view returns (string memory);
}

/*
    INftTokenUriResolver resolves 'tokenUri' of NFT.
    For On-chain based NFTs it should return a Base64 equivalent (as implemented in OnchainNftTokenUriResolver)
    For Off-chain based NFTs it should return a valid link to ipfs or any other external metadata storage.
*/
interface INftTokenUriResolver {
    // for On-chain based NFTs it should return a Base64 equivalent
    // or Off-chain based NFTs it should return a valid link to ipfs or any other external metadata storage
    function getTokenUri(uint256 _tokenId) external view returns (string memory);
}

/*
    INftMinter - main NFT contract itself. Most likely, this one will never be replaced in an app. But it's possible.
*/
interface INftMinter {
    // mints an nft
    // in current case - with props 'owner', 'name', 'age'
    function mint(address _owner, string memory _name, uint256 _age) external payable returns (uint256);
    // returns a data for an NFT that is stored in the contract
    function getGeneralNftData(uint256 _tokenId) external view returns (string memory _name, uint256 _age);
}

/*
    INftMintingAllowance restricts minting of NFTs, if required by business logic (inside INftMinter).
    Should be used together with INftManager, as INftMinter has no restrictions.
*/
interface INftMintingAllowance {
    // defines whether minting of a token with current params is allowed
    function mintingIsAllowed(address _msgSender, string memory _name, uint256 _age) external view returns (bool);
}

/*
    INftManager - business logic for the overall process.
    Should be used as an entry point to the system.
*/
interface INftManager {
    // mints a token
    function mint(string memory _name, uint256 _age) external payable returns (uint256);
}