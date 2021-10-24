// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

import { INftMinter, INftTokenUriResolver } from './Interfaces.sol';
import { WithAppBeacon } from './WithAppBeacon.sol';

struct MyNft {
    string name;
    uint256 age;
    uint256 createdAt;
}

contract NftMinter is INftMinter, ERC721, Ownable, WithAppBeacon {
    uint256 private fee;
    string constant tokenByIdDoesNotExist = "ERC721Metadata: URI query for nonexistent token.";

    using Counters for Counters.Counter;
    Counters.Counter _idsCounter;

    // general token data
    mapping(uint256 => MyNft) items;

    modifier tokenExists(uint256 _tokenId) {
        require(_exists(_tokenId), tokenByIdDoesNotExist);
        _;
    }

    modifier onlyManagerIfSet() {
        address nftManagerAddress = _getNftManagerAddress();
        require(nftManagerAddress == address(0) || msg.sender == nftManagerAddress,
        "Only manager address is allowed to perform the operation. Get its contract address via 'getManagerAddress()'.");
        _;
    }

    modifier onlyPaid(uint256 _fee) {
        require(msg.value >= _fee, "Fee for the operation is greater than you've send.");
        _;
    }

    constructor(address _appBeacon, string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
        WithAppBeacon(_appBeacon) { }

    function isToggleAppBeaconAllowed() public override view returns (bool) {
        return msg.sender == owner();
    }

    function mint(address _owner, string memory _name, uint256 _age)
    public
    payable
    override
    onlyManagerIfSet
    onlyPaid(fee)
    returns (uint256) {
        return _mint(_owner, _name, _age);
    }

    function getGeneralNftData(uint256 _tokenId)
    public
    override
    view
    returns (string memory _name, uint256 _age) {
        MyNft storage token = items[_tokenId];

        _name = token.name;
        _age = token.age;
    }

    function tokenURI(uint256 _tokenId)
    public
    virtual
    view
    override
    tokenExists(_tokenId)
    returns (string memory) {
        return _getNftTokenUriResolver().getTokenUri(_tokenId);
    }

    function _mint(address _owner, string memory _name, uint256 _age)
    private
    returns (uint256) {
        uint256 tokenId = _idsCounter.current() + 1;

        _safeMint(_owner, tokenId);
        
        _idsCounter.increment();

        MyNft storage token = items[tokenId];

        token.name = _name;
        token.age = _age;
        token.createdAt = block.timestamp;

        return tokenId;
    }

    function _getNftTokenUriResolver() private view returns (INftTokenUriResolver) {
        address a = appBeacon.get("NftTokenUriResolver");
        requireBeaconAddress(a);
        return INftTokenUriResolver(a);
    }

    function _getNftManagerAddress() private view returns (address) {
        return appBeacon.get("NftManager");
    }
}