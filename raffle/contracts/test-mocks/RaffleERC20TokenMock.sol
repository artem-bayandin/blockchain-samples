// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


// ERC20 token implementation for tests
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

import '../Adminable.sol';


/// @title RaffleERC20TokenMock
/// @notice ERC20 token mock to be used in tests
/// @dev Admin permission management might be moved into a separate abstract contract.
contract RaffleERC20TokenMock is ERC20, Adminable {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) { }
    
    /// @notice Mints token to a msg.sender
    function mint(address _to, uint256 _amount)
    public
    onlyAdmin {
        _mint(_to, _amount);
    }
}


contract LinkMock is RaffleERC20TokenMock {
    constructor(string memory _name, string memory _symbol) RaffleERC20TokenMock(_name, _symbol) { }
}
contract DaiMock is RaffleERC20TokenMock {
    constructor(string memory _name, string memory _symbol) RaffleERC20TokenMock(_name, _symbol) { }
}
contract BnbMock is RaffleERC20TokenMock {
    constructor(string memory _name, string memory _symbol) RaffleERC20TokenMock(_name, _symbol) { }
}