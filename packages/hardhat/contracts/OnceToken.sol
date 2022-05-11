// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

//to do: For a user be able to mint, he needs to be approved. So we need to set some modifier where only
//approved users can mint nfts.

contract OnceToken is ERC721Enumerable{
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;
  address public marketplace;

  struct Item {
    uint256 id;
    address creator;
    string uri;//metadata url
  }

  mapping(uint256 => Item) public Items; //id => Item

  constructor () ERC721("OnceToken", "ONCE") {}

  function mint(string memory uri) public returns (uint256){
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();
    _safeMint(msg.sender, newItemId);
    approve(marketplace, newItemId);

    Items[newItemId] = Item({
      id: newItemId, 
      creator: msg.sender,
      uri: uri
    });

    return newItemId;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
    return Items[tokenId].uri;
  }

  function setMarketplace(address market) public {
    //require(msg.sender ==);
    marketplace = market;
  }

}