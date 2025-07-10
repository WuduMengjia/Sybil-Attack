// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract MockNFT is ERC721Enumerable {
    address public minter;
    uint256 public maxSupply;
    uint256 public currentTokenId;

    constructor(uint256 _maxSupply) ERC721("MockNFT", "MNFT") {
        minter = msg.sender;
        maxSupply = _maxSupply;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "Not minter");
        _;
    }

    // 批量铸造NFT
    function mintBatch(address[] calldata to) external onlyMinter {
        for (uint256 i = 0; i < to.length; i++) {
            mint(to[i]);
        }
    }

    // 铸造单个NFT
    function mint(address to) public onlyMinter {
        require(currentTokenId < maxSupply, "Max supply reached");
        uint256 tokenId = ++currentTokenId;
        _mint(to, tokenId);
    }

    // 设置新的铸造者
    function setMinter(address _minter) external onlyMinter {
        minter = _minter;
    }
}    
