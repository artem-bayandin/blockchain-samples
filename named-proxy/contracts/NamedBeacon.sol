// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;
/************************************************************************************************\
* Author: Artem Bayandin <bayandin.artem.official@gmail.com> (https://github.com/artem-bayandin) *
\************************************************************************************************/

interface INamedBeacon {
    /// @notice Returns an address of an implementation, registered under _referenceId. If no reference is found, returns address(0).
    /// @param _referenceId Unique reference id (usually, name) of the referenced contract
    function getImplementation(bytes32 _referenceId) external view returns (address _implementation);

    /// @notice Registers implementation _implementation under given _referenceId.
    /// @param _referenceId Unique ref id of the referenced contract
    /// @param _implementation Address of implementation
    function registerImplementation(bytes32 _referenceId, address _implementation) external;
}

/// @title NamedBeacon
/// @notice A Beacon with all the references registered.
/// @dev Seems to be a good version, so just needs minor changes to be used under proxy.
/// @dev Review visibility modifiers.
/// @dev Simplified version not to store list of registered referneces.
/// @dev Registered references should be fetched from raised events `ImplementationRegistered(string indexed referenceId, address previous, address current)`
/// @dev For ref id use `keccak256(abi.encodePacked("MY_REF_NAME")) - 1`
contract NamedBeacon {
    /// @notice Owner of the beacon
    /// @dev Should be set in ctor or init function
    /// @dev This must be overwritten by your custom auth logic
    address public owner;

    /// @notice Main storage of implementations
    mapping(bytes32 imlpId => address imlpAddress) internal implementations;

    /// @notice Event emitted when a reference was added, altered, or removed
    event ImplementationRegistered(bytes32 indexed referenceId, address previous, address current);

    /// @notice Error thrown when the implementation is invalid (impl != address(0) && impl.code.length == 0)
    error InvalidImplementation(address implementation);

    /// @notice Error thrown when the caller is not the owner
    error UnauthorizedAccess();

    // ctor
    constructor (address _owner) {
        /// @dev This must be overwritten by your custom auth logic
        require (_owner != address(0));
        owner = _owner;
    }

    // Region Beacon

    /// @notice Returns an address of an implementation, registered under _referenceId. If no reference is found, returns address(0).
    /// @param _referenceId Unique ref id of the referenced contract
    function getImplementation(bytes32 _referenceId) external view returns (address _implementation) {
        return implementations[_referenceId];
    }

    /// @notice Registers implementation _implementation under given _referenceId.
    /// @param _referenceId Unique ref id of the referenced contract
    /// @param _implementation Address of implementation
    function registerImplementation(bytes32 _referenceId, address _implementation) external {
        _requireOwner();

        if (_implementation != address(0) && _implementation.code.length == 0) {
            revert InvalidImplementation(_implementation);
        }

        address current = implementations[_referenceId];
        implementations[_referenceId] = _implementation;

        emit ImplementationRegistered(_referenceId, current, _implementation);
    }

    /// @notice Special function to mimic beacon functionality from OZ
    /// @dev Exists only to be compatible with OZ BeaconProxy
    /// @dev BeaconProxy.ctor() => ERC1967Utils.upgradeBeaconToAndCall(beacon, data) => _setBeacon(address newBeacon) => address beaconImplementation = IBeacon(newBeacon).implementation();
    /// @dev 1. this should return a valid address
    /// @dev 2. AND it should be a contract: if (beaconImplementation.code.length == 0) { revert }
    /// @dev Similar issue is in ERC1967Utils.upgradeBeaconToAndCall(address newBeacon, bytes memory data),
    /// @dev on line `Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);`
    /// @dev Given this, 
    function implementation() external view returns (address _current) {
        return address(this);
    }

    // endregion

    // Region Ownable

    /// @dev This must be overwritten by your custom auth logic
    function _requireOwner() internal view {
        require (msg.sender == owner, UnauthorizedAccess());
    }

    // endregion
}
