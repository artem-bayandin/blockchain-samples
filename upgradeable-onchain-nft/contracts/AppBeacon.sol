// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/access/Ownable.sol';

import { IAppBeacon } from './Interfaces.sol';

contract AppBeacon is IAppBeacon, Ownable {
    string[] names;
    mapping(string => uint256) nameIndecesBased1;
    mapping(string => address) routes;

    function get(string memory _name) public override view returns (address) {
        return routes[_name];
    }

    function set(string memory _name, address _address) public override onlyOwner {
        if (routes[_name] == address(0) && _address != address(0)) {
            // was 0, setting != 0
            _addNameToCollection(_name);
        } else if (routes[_name] != address(0) && _address == address(0)) {
            // was set, clearing
            _removeNameFromCollection(_name);
        }
        routes[_name] = _address;
    }

    function getList() public view onlyOwner returns (string[] memory) {
        return names;
    }

    function _addNameToCollection(string memory _name) private {
        names.push(_name);
        nameIndecesBased1[_name] = names.length;
    }

    function _removeNameFromCollection(string memory _name) private {
        uint256 index = nameIndecesBased1[_name] - 1;
        if (index == names.length - 1) {
            // the last one
            names.pop();
            delete nameIndecesBased1[_name];
        } else {
            // any except the last one
            names[index] = names[names.length - 1];
            names.pop();
            nameIndecesBased1[names[index]] = index + 1;
        }
    }
}