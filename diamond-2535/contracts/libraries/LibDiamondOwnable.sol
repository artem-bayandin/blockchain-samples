// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;
/******************************************************************************\
* Author: Artem Bayandin <bayandin.artem.official@gmail.com>
* 
* The lib was extracted from LibDiamond to separate ownership functionality from the diamond.
/******************************************************************************/

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

error LibInitialized(string libName);

library LibDiamondOwnable {
    error LibDiamondMustBeContractOwner(address caller);

    bytes32 constant STORAGE_POSITION = keccak256("diamond.standard.lib-ownable.storage");

    struct Storage {
        // owner of the contract
        address contractOwner;
    }

    function getStorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly ("memory-safe") {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        Storage storage ds = getStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = getStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == getStorage().contractOwner, LibDiamondMustBeContractOwner(msg.sender));
    }
}
