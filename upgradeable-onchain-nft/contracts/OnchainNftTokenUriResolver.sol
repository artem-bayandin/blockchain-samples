// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import { Base64 } from './libs/Base64.sol';
import { StringComparison } from './libs/StringComparison.sol';
import { INftTokenUriResolver, INftDataStorage, INftImageResolver, INftMinter, KeyValuePair } from './Interfaces.sol';
import { WithAppBeacon } from './WithAppBeacon.sol';

contract OnchainNftTokenUriResolver is INftTokenUriResolver, Ownable, WithAppBeacon {
    using Strings for uint256;
    using StringComparison for string;

    constructor(address _appBeacon) WithAppBeacon(_appBeacon) { }

    function isToggleAppBeaconAllowed() public override view returns (bool) {
        return msg.sender == owner();
    }

    function getTokenUri(uint256 _tokenId)
    public
    view
    override
    returns (string memory) {
        (string memory name, uint256 age) = _getNftMinter().getGeneralNftData(_tokenId);

        INftDataStorage nftDataStorage = _getNftDataStorage();

        // if no storage is used - just skip this section
        if (address(nftDataStorage) != address(0)) {
            KeyValuePair[] memory kvp = nftDataStorage.get(_tokenId);

            // sample of parsing data
            // for now - only a sample
            string memory myProp1 = "";
            string memory myProp2 = "";
            for (uint256 i = 0; i < kvp.length; i++) {
                if (kvp[i].key._equalTo("myProp1Key")) {
                    myProp1 = kvp[i].value;
                } else if (kvp[i].key._equalTo("myProp2Key")) {
                    myProp2 = kvp[i].value;
                }
            }
        }
        
        return _buildMetadata(name, age);
    }

    function _buildMetadata(string memory _name, uint256 _age)
    private
    view
    returns (string memory) {
        INftImageResolver nftImageResolver = _getNftImageResolver();

        string memory nameStr = string(abi.encodePacked('"name":"', _name, '"'));
        string memory descrStr = string(abi.encodePacked('"description":"NFT sample"'));
        string memory imageStr = address(nftImageResolver) != address(0)
            ? nftImageResolver.getImage(_name, _age)
            : "";
        
        string memory nameAttrStr = string(abi.encodePacked('{"trait_type": "Name","value":"', _name, '"}'));
        string memory ageAttrStr = string(abi.encodePacked('{"trait_type": "Age","value":', _age.toString(), '}'));
        string memory attribStr = string(abi.encodePacked('"attributes":[', nameAttrStr, ',', ageAttrStr, ']'));

        string memory preparedString = string(abi.encodePacked('{', nameStr, ',', descrStr, ',', imageStr, ',', attribStr, '}'));
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(preparedString)))));
    }

    function _getNftMinter() private view returns (INftMinter) {
        address a = appBeacon.get("NftMinter");
        requireBeaconAddress(a);
        return INftMinter(a);
    }

    function _getNftDataStorage() private view returns (INftDataStorage) {
        return INftDataStorage(appBeacon.get("NftDataStorage"));
    }

    function _getNftImageResolver() private view returns (INftImageResolver) {
        return INftImageResolver(appBeacon.get("NftImageResolver"));
    }
}