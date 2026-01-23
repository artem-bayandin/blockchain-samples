// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Proxy } from "@openzeppelin/contracts/proxy/Proxy.sol";
import { INamedBeacon } from "./NamedBeacon.sol";

/// @dev Based on BeaconProxy and ERC1967Utils from OZ
/// Intended to be used with a predefined beacon address and a predefined implementation name.
/// That's why these two parameters are immutable and set in the ctor. Contract storage is not affected by these values.
contract NamedBeaconProxy is Proxy {
    // An immutable address for the beacon to avoid unnecessary SLOADs before each delegate call.
    address private immutable beacon;
    // Unique name of the referenced contract
    bytes32 private immutable implementationName;

    /**
     * @notice Emitted when the beacon is upgraded
     * @param beacon Address of the beacon
     */
    event BeaconUpgraded(address indexed beacon);
    /**
     * @notice Emitted when the implementation name is set
     * @param implementationName Unique name of the referenced contract
     */
    event ImplementationNameSet(bytes32 indexed implementationName);

    /**
     * @dev An upgrade function sees `msg.value > 0` that may be lost.
     */
    error NonPayable();
    /**
     * @dev The `beacon` of the proxy is invalid.
     */
    error InvalidBeacon(address beacon);
    /**
     * @dev The `implementation` of the proxy is invalid.
     */
    error InvalidImplementation(address implementation);
    /**
     * @dev The `implementation` was not found in the beacon by the reference name.
     */
    error ImplementationNotFound(bytes32 implementationName);

    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializing the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {INamedBeacon}.
     * - `implementationName` must be a valid name of the referenced contract, and this reference must be registered in the beacon.
     * - If `data` is empty, `msg.value` must be zero.
     */
    constructor(address _beacon, bytes32 _implementationName, bytes memory _data) payable {
        // set beacon
        if (_beacon.code.length == 0) {
            revert InvalidBeacon(_beacon);
        }
        beacon = _beacon;
        emit BeaconUpgraded(_beacon);

        // set implementation name
        address implementationFromBeacon = INamedBeacon(_beacon).getImplementation(_implementationName);
        if (implementationFromBeacon.code.length == 0) {
            revert InvalidImplementation(implementationFromBeacon);
        }
        implementationName = _implementationName;
        emit ImplementationNameSet(_implementationName);

        // initialize if data is provided
        if (_data.length > 0) {
            Address.functionDelegateCall(implementationFromBeacon, _data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        address impl = INamedBeacon(beacon).getImplementation(implementationName);
        if (impl == address(0)) {
            revert ImplementationNotFound(implementationName);
        }
        if (impl.code.length == 0) {
            revert InvalidImplementation(impl);
        }
        return impl;
    }

    /**
     * @dev TODO: What's the purpose of this function?
     */
    receive() external payable {}


    /* *** *** *** ** *** ** *** *** *** *\
       Below goes copy from ERC1967Utils
       Events are renamed, as there is nothing related to IERC1967 Storage Slots
    \* *** *** *** ** *** ** *** *** *** */
    

    /**
     * @dev Reverts if `msg.value` is not zero. It can be used to avoid `msg.value` stuck in the contract
     * if an upgrade doesn't perform an initialization call.
     */
    function _checkNonPayable() private {
        if (msg.value > 0) {
            revert NonPayable();
        }
    }
}
