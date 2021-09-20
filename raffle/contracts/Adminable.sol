// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


/// @title Adminable
/// @notice Contains several methods to manage general admins for a contract
/// @dev Kinda 'Ownable', but with extended functions
abstract contract Adminable {
    /// @notice An array of addresses who has admin permissions
    address[] private admins;
    
    /// @notice Map of admin addresses to faster distinguish whether a user has admin roles
    mapping(address => bool) adminMap;

    /// @notice Validates if msg.sender has admin permissions
    modifier onlyAdmin() {
        address msgSender = msg.sender;
        require(adminMap[msgSender], "You do not have permissions to perform current operation.");
        _;
    }
    
    /// @dev Registers msg.sender as an admin
    constructor() {
        address msgSender = msg.sender;
        admins.push(msgSender);
        adminMap[msgSender] = true;
    }

    /// @notice Allows an address to manage PriceOracle
    function addAdmin(address _admin)
    public
    onlyAdmin {
        if (!adminMap[_admin]) {
            admins.push(_admin);
            adminMap[_admin] = true;
        }
    }

    /// @notice Removes an address from admins
    function removeAdmin(address _admin)
    public
    onlyAdmin {
        require(admins.length > 1, "At least 1 admin should be assigned");
        if (adminMap[_admin]) {
            adminMap[_admin] = false;
            uint256 adminLen = admins.length;
            for (uint256 i = 0; i < adminLen; i++) {
                if (admins[i] == _admin) {
                    if (i != adminLen) {
                        admins[i] = admins[adminLen - 1];
                    }
                    admins.pop();
                    break;
                }
            }
        }
    }
    
    /// @notice Returns true if address is in the list of admins
    function isAdmin(address _admin)
    public
    view
    returns(bool) {
        return adminMap[_admin];
    }
    
    /// @notice Returns the collection of addresses that are currently admins
    function getAdmins()
    public
    view
    returns(address[] memory) {
        return admins;
    }
}