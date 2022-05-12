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
  Counters.Counter private _insuredIds;
  address public marketplace;

  //setting a governance oracle/DAO that will grants access for minting Once NFTs
  //So who pass the Once KYC system will have the permission for minting:
  address payable ownerGovernance;

  //Creating the insured structs:
  struct Insured {
    uint256 id;
    address insured;
  }

  event insuredGranted(uint256 id, address insured);

  mapping(uint256 => Insured) public Insureds;

  //So here, with the the governance address, we grant for the user the possibility to mint Once NFTs (after checking the KYC):
  function grantInsuranceMint(address _address) public returns(uint256){
    require(msg.sender == ownerGovernance, "Only the DAO governance can set this role");
    _insuredIds.increment();
    uint256 newInsuredId = _insuredIds.current();
    Insureds[newInsuredId] = Insured ({
      id: newInsuredId,
      insured: _address
    });

    emit insuredGranted(Insureds[newInsuredId].id, Insureds[newInsuredId].insured);
    return newInsuredId;
  }

  //remove grant to insured:
  function removeGrantToInsured(uint256 num) public{
    require(msg.sender == ownerGovernance, "Only the DAO governance can do it");
    delete Insureds[num];
  }

  //return Insured address by Id:
  function fetchInsured(uint256 num) public view returns(address){
    return Insureds[num].insured;
  }

  //function for checking if address is granted for minting
  function exists1(address _address) internal view returns (bool) {
    uint count = _insuredIds.current();
    for (uint i = 0; i < count + 1; i++) {
        if (Insureds[i].insured == _address) {
            return true;
        }
    }

    return false;
  }

  //Creating the nfts struct:
  struct Item {
    uint256 id;
    address creator;
    string uri;//metadata url
  }

  event NFTMinted (uint256 id, address creator, string uri);

  mapping(uint256 => Item) public Items; //id => Item

  constructor () ERC721("OnceToken", "ONCE") {}

  function mint(string memory uri) public returns (uint256){
    require(exists1(msg.sender) == true, "You are not an allowed insured");
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();
    _safeMint(msg.sender, newItemId);
    approve(marketplace, newItemId);

    Items[newItemId] = Item({
      id: newItemId, 
      creator: msg.sender,
      uri: uri
    });

    emit NFTMinted(Items[newItemId].id, Items[newItemId].creator, Items[newItemId].uri);
    return newItemId;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
    return Items[tokenId].uri;
  }

  function setMarketplace(address market) public {
    require(msg.sender == ownerGovernance, "Only the DAO governance can set the marketplace");
    marketplace = market;
  }

}