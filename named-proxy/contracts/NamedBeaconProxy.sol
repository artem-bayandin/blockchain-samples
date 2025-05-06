// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { ERC1967Utils } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import { Beacon } from "./Beacon.sol";

/// @title NamedBeaconProxy
/// @dev When deployed, refers to the only one beacon. Beacon address cannot be modified later. Ref name too.
contract NamedBeaconProxy is BeaconProxy {
    bytes32 private immutable implementationName;

    error NamedImplementationNotFound();

    /// @dev Ctor
    /// @dev `bytes memory` is not passed to the super due to implementation of `ERC1967Utils.upgradeBeaconToAndCall`
    /// @dev The logic of upgradeBeaconToAndCall is copied to current ctor
    constructor(address _beacon, bytes memory _data, bytes32 _implementationName) payable BeaconProxy(_beacon, "") {
        implementationName = _implementationName;

        if (_data.length > 0) {
            Address.functionDelegateCall(_implementation(), _data);
        } else {
            _checkNonPayable();
        }
    }

    /// @dev Overrides standard func to read an implementation by ref name
    function _implementation() internal view virtual override returns (address _impl) {
        address impl = Beacon(_getBeacon()).getImplementation(implementationName);
        require (impl != address(0), NamedImplementationNotFound());
        return impl;
    }

    receive() external payable {}

    // Below goes copy from ERC1967Utils

    /**
     * @dev An upgrade function sees `msg.value > 0` that may be lost.
     */
    error ERC1967NonPayable();
    /**
     * @dev Reverts if `msg.value` is not zero. It can be used to avoid `msg.value` stuck in the contract
     * if an upgrade doesn't perform an initialization call.
     */
    function _checkNonPayable() internal {
        if (msg.value > 0) {
            revert ERC1967NonPayable();
        }
    }
}