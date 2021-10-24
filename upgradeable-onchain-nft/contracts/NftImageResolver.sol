// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/utils/Strings.sol';

import { Base64 } from './libs/Base64.sol';
import { INftImageResolver } from './Interfaces.sol';

contract NftImageResolver is INftImageResolver {
    using Strings for uint256;

    function getImage(string memory _name, uint256 _age)
    public
    override
    pure
    returns (string memory) {
        return string(abi.encodePacked('"image":"data:image/svg+xml;base64,', _buildImage(_name, _age), '"'));
    }

    function _buildImage(string memory _name, uint256 _age)
    private
    pure
    returns (string memory) {
        return Base64.encode(
            bytes(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350" text-anchor="middle"><rect style="fill:rgba(255,87,51,0.87)" rx="20" ry="20" width="100%" height="100%"/><rect x="20" y="20" width="310" height="310" fill="#ccc" fill-opacity="0.15"/><foreignObject x="40" y="40" width="270" height="270"><div xmlns="http://www.w3.org/1999/xhtml" style="font-family:Arial;font-size:16px;text-align:center"><div>Lorem ipsum dolor sit amet.</div><div style="font-size:40px;margin:10px 0;overflow-wrap:break-word;">',
                    _name,
                    '</div><a href="',
                    _age.toString(),
                    '</div></div></foreignObject></svg>'
                )
            )
        );
    }
/*
<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350" text-anchor="middle">
    <rect style="fill:rgba(255,87,51,0.87)" rx="20" ry="20" width="100%" height="100%"/>
    <rect x="20" y="20" width="310" height="310" fill="#ccc" fill-opacity="0.15"/>
    <foreignObject x="40" y="40" width="270" height="270">
        <div xmlns="http://www.w3.org/1999/xhtml" style="font-family:Arial;font-size:16px;text-align:center">
            <div>Lorem ipsum dolor sit amet.</div>
            <div style="font-size:40px;margin:10px 0;overflow-wrap:break-word;">Arthur</div>
            <div style="font-size:60px;">30</div>
        </div>
    </foreignObject>
</svg>
*/
}