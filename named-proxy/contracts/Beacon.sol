// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title Beacon
/// @notice A Beacon with all the references registered.
/// @dev Seems to be a good version, so just needs minor changes to be used under proxy.
/// @dev Review visibility modifiers.
/// @dev Simplified version not to store list of registered names.
/// @dev Registered names should be fetched from raised events `ImplementationRegistered(string indexed name, address previous, address current)`
/// @dev For ref name use `keccak256(abi.encodePacked("MY_REF_NAME"))`
contract Beacon {
    /// @notice Owner of the beacon
    /// @dev Should be set in ctor or init function
    address public owner;

    /// @notice Main storage of implementations
    mapping(bytes32 imlpId => address imlpAddress) internal implementations;

    /// @notice Event emitted when a reference was added, altered, or removed
    event ImplementationRegistered(bytes32 indexed name, address previous, address current);

    // ctor
    constructor (address _owner) {
        require (_owner != address(0));
        owner = _owner;
    }

    // Region Beacon

    /// @notice Returns an address of an implementation, registered under _name. If no reference is found, returns address(0).
    /// @param _name Unique name of the referenced contract
    function getImplementation(bytes32 _name) external view returns (address _implementation) {
        return implementations[_name];
    }

    /// @notice Registers implementation _address under given _name.
    /// @param _name Unique name of the referenced contract
    /// @param _address Address of implementation
    function registerImplementation(bytes32 _name, address _address) external {
        _requireOwner();

        address current = implementations[_name];
        implementations[_name] = _address;

        emit ImplementationRegistered(_name, current, _address);
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

    function _requireOwner() internal view {
        require (msg.sender == owner);
    }

    // endregion
}