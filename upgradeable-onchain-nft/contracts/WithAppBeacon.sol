// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import { IAppBeacon } from './Interfaces.sol';

/*
    Base contract for cases, when an AppBeacon is needed inside a contract.
*/
abstract contract WithAppBeacon {
    IAppBeacon internal appBeacon;

    modifier toggleAppBeaconAllowed() {
        require(isToggleAppBeaconAllowed(), "You are not allowed to perform the operation.");
        _;
    }

    constructor(address _appBeacon) {
        appBeacon = IAppBeacon(_appBeacon);
    }

    function toggleAppBeacon(address _appBeacon) public toggleAppBeaconAllowed {
        appBeacon = IAppBeacon(_appBeacon);
    }

    function requireBeaconAddress(address _address) internal pure {
        if (_address == address(0)) {
            revert("AppBeacon is not properly set up.");
        }
    }

    // this method is needed to restrict overriding an appBeacon for non-authorized users
    function isToggleAppBeaconAllowed() public virtual view returns (bool);
}