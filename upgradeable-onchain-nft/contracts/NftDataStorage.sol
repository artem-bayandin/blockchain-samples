// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/access/Ownable.sol';

import { INftDataStorage, KeyValuePair } from './Interfaces.sol';
import { WithAppBeacon } from './WithAppBeacon.sol';

contract NftDataStorage is INftDataStorage, Ownable, WithAppBeacon {
    uint256[] private tokenIds;
    mapping(uint256 => bool) private tokenExistence;
    mapping(uint256 => KeyValuePair[]) private tokenData;

    modifier onlyOwnerOrManager() {
        address msgSender = _msgSender();
        address nftManagerAddress = appBeacon.get("NftManager");
        require(msgSender == owner()
            || (nftManagerAddress != address(0) && msgSender == nftManagerAddress),
            "You are not allowed to perform the operation.");
        _;
    }

    constructor (address _appBeacon) WithAppBeacon(_appBeacon) { }

    function isToggleAppBeaconAllowed() public override view returns (bool) {
        return msg.sender == owner();
    }

    function upsert(uint256 _tokenId, KeyValuePair[] memory _data)
    public
    override
    onlyOwnerOrManager {
        if (!_tokenExists(_tokenId)) {
            tokenExistence[_tokenId] = true;
            tokenIds.push(_tokenId);
        }
        _rewriteTokenDataInStorage(_tokenId, _data);
    }

    function get(uint256 _tokenId)
    public
    view
    override
    returns (KeyValuePair[] memory) {
        return tokenData[_tokenId];
    }

    function _tokenExists(uint256 _tokenId)
    private
    view
    returns (bool) {
        return tokenExistence[_tokenId];
    }

    function _rewriteTokenDataInStorage(uint256 _tokenId, KeyValuePair[] memory _kvp)
    private {
        delete tokenData[_tokenId];
        KeyValuePair[] storage kvp = tokenData[_tokenId];
        for (uint256 i = 0; i < _kvp.length; i++) {
            kvp.push(_kvp[i]);
        }
    }
}