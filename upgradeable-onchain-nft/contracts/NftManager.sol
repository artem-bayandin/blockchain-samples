// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/access/Ownable.sol';

import { INftManager, INftMinter, INftMintingAllowance, INftDataStorage, KeyValuePair } from './Interfaces.sol';
import { WithAppBeacon } from './WithAppBeacon.sol';

contract NftManager is INftManager, Ownable, WithAppBeacon {
    constructor(address _appBeacon) WithAppBeacon(_appBeacon) { }

    function isToggleAppBeaconAllowed() public override view returns (bool) {
        return msg.sender == owner();
    }

    function mint(string memory _name, uint256 _age)
    public
    payable
    override
    returns (uint256) {
        INftMinter nftMinter = _getNftMinter();
        address allo = _getNftMintingAllowanceAddress();
        address msgSender = _msgSender();
        if (allo != address(0)) {
            require(
                INftMintingAllowance(allo).mintingIsAllowed(msgSender, _name, _age),
                string(abi.encodePacked("Minting of NFT is not allowed."))
            );
        }
        uint256 tokenId = nftMinter.mint{value:msg.value}(msgSender, _name, _age);
        _sampleOfStoringDataIntoStorage(tokenId);
        return tokenId;
    }

    function _sampleOfStoringDataIntoStorage(uint256 _tokenId)
    private {
        address storageAddress = _getNftDataStorageAddress();
        if (storageAddress == address(0)) {
            return;
        }
        KeyValuePair[] memory kvp = new KeyValuePair[](1);
        kvp[0] = KeyValuePair("myProp1Key", "123-777");
        INftDataStorage(storageAddress).upsert(_tokenId, kvp);
    }
    
    function _getNftMinter() private view returns (INftMinter) {
        address a = appBeacon.get("NftMinter");
        requireBeaconAddress(a);
        return INftMinter(a);
    }

    function _getNftMintingAllowanceAddress() private view returns (address) {
        return appBeacon.get("NftMintingAllowance");
    }

    function _getNftDataStorageAddress() private view returns (address) {
        return appBeacon.get("NftDataStorage");
    }
}