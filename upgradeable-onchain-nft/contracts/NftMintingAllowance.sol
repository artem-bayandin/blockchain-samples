// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import { StringComparison } from './libs/StringComparison.sol';
import { INftMintingAllowance } from './Interfaces.sol';

contract NftMintingAllowance is INftMintingAllowance {
    using StringComparison for string;
    
    // this placeholder exists, as implementation might read from the state
    uint256 private ___placeholder = 123;

    function mintingIsAllowed(address _msgSender, string memory _name, uint256 _age)
    public
    override
    view
    returns (bool) {
        return ___placeholder > 0
        && _msgSender != address(0)
        && _name._notEqualToEmpty()
        && _age > 1;
    }
}