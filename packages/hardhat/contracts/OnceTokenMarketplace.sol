// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

//to do: How to integrate in the minting function an Id card (but with privacy), so we know when someone dies but without exposing who it is to the blockchain?
//set a function: When the 10/5 years has passed and the person has not died, the payout backed is returned to the Insurance company.
//set a function: When the insured dies, who owns the NFT is paid with the total amount backed. -> this function can be set into the marketplace contract.

contract OnceToken is ERC721Enumerable{
  using Counters for Counters.Counter;

  Counters.Counter public _tokenIds;
  Counters.Counter private _insuredIds;
  address public marketplace;

  IERC20 public tokenAddress;

  //TIME tokens required for minting an NFT 
  uint256 public rate = 100 * 10 ** 18;

  constructor (address _tokenAddress) ERC721("Extra-Life", "LIFE") {
    tokenAddress = IERC20(_tokenAddress);
  }

  //setting a governance oracle/DAO that will grants access for minting Once NFTs
  //So who pass the Once KYC system will have the permission for minting:
  address public ownerGovernance = 0x08ADb3400E48cACb7d5a5CB386877B3A159d525C;

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
    require(exists1(_address) == false, "This address already is granted");
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
    //premium for insurance
    uint256 premium;
    //boolean for knowing if the nft was backed or not:
    bool backed;
    //the amount of money the insured wants to be backed for his premium, in case of death who owns the nfts can claim the reward:
    uint256 payout;
    //who backs this nft will be the insurer
    address insurer;
    //if the assurance was already called, if so this nft does not own more value:
    bool assuranceTriggered;
  }

  event NFTMinted (uint256 id, address creator, string uri, uint256 premium, bool backed, uint256 payout);

  mapping(uint256 => Item) public Items; //id => Item

  

  //when minting the user pass the uri, the premium (its the msg.value) and the amount the wants in case of dead (payout)
  function mint(string memory uri, uint256 _payout) public payable returns (uint256){
    require(exists1(msg.sender) == true, "You are not an allowed insured");
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();
    _safeMint(msg.sender, newItemId);
    approve(address(this), newItemId);

    //transfer to this contract the minimum amount of Time token required for minting:
    tokenAddress.transferFrom(msg.sender, address(this), rate);



    Items[newItemId] = Item({
      id: newItemId, 
      creator: msg.sender,
      uri: uri,
      premium: msg.value,
      backed: false,
      payout: _payout,
      insurer: msg.sender,
      assuranceTriggered: false
    });

    emit NFTMinted(Items[newItemId].id, Items[newItemId].creator, Items[newItemId].uri, Items[newItemId].premium, Items[newItemId].backed, Items[newItemId].payout);
    return newItemId;
  }

  //now the Insurance company (or a single person) can do the payout payment (so the contract can allocate it into a liquidity pool for example) and "buy" the assurance:
  function buyInsurance(uint256 tokenId) public payable {
    require(msg.value == Items[tokenId].payout, "Value for backing the insurance incorrect");
    require(Items[tokenId].backed == false, "This insurance was already backed");
    Items[tokenId].backed = true;
    Items[tokenId].insurer = msg.sender;
    uint256 _premium = Items[tokenId].premium;

    //transfer the premium amount to the Insurance company and the value to the marketplace:
    (bool sent, ) = payable(msg.sender).call{value: _premium}("");
    require(sent, "Failed to send Ether/Matic");
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
    return Items[tokenId].uri;
  }

  function fetchPayoutAmount(uint256 tokenId) public view returns (uint256){
    return Items[tokenId].payout;
  }

  function setMarketplace(address market) public {
    require(msg.sender == ownerGovernance, "Only the DAO governance can set the marketplace");
    marketplace = market;
  }

  function fetchTokensIds() public view returns(uint256){
      return _tokenIds.current();
  }

  uint256 poolFee = 0.01 ether;
  function setPoolFee(uint256 _poolFee) public {
      require(msg.sender == ownerGovernance, "Only the ownerGovernance can set the pool's fee!!" );
      poolFee = _poolFee;
  }

  //getPayout is triggered when the insured dies - who owns the nft will get the payout:
  function getPayout(uint256 _tokenId) public {
    require(msg.sender == ownerGovernance, "Only the ownerGovernance can withdraw!!");
    require(Items[_tokenId].assuranceTriggered == false, "This assurance was already called");

    //here, as we are going to use superfluid, lets set and particular address:
    address payable _to = payable(ownerOf(_tokenId));

    uint256 payout = Items[_tokenId].payout - poolFee;
    
    Items[_tokenId].assuranceTriggered = true;

    //transfer the payout amount to the NFT owner:
    (bool sent, ) = payable(_to).call{value: payout}("");
    require(sent, "Failed to send Ether/Matic");
  }

  //getAmountBack is triggered when the timestamp in the insurance contract has passed and the insured has not died, the money goes back to the insurer:
  function getAmountBack(uint256 _tokenId) public {
    require(msg.sender == ownerGovernance, "Only the ownerGovernance can withdraw!!");  
    require(Items[_tokenId].assuranceTriggered == false, "This assurance was already called");

    address payable _to = payable(Items[_tokenId].insurer);

    uint256 payout = Items[_tokenId].payout - poolFee;

    Items[_tokenId].assuranceTriggered = true;

    //transfer the payout amount to the insurer:
    (bool sent, ) = payable(_to).call{value: payout}("");
    require(sent, "Failed to send Ether/Matic");
  }


    //MARKETPLACE:

    struct ItemForSale {
        uint256 id;
        uint256 tokenId;
        address payable seller;
        uint256 price;
        bool isSold;
    }

    ItemForSale[] public itemsForSale;
    mapping(uint256 => bool) public activeItems;

    event itemAddedForSale(uint256 id, uint256 tokenId, uint256 price);
    event itemSold(uint256 id, address buyer, uint256 price);   



    modifier IsForSale(uint256 id){
        require(!itemsForSale[id].isSold, "Item is already sold");
        _;
    }

    modifier ItemExists(uint256 id){
        require(id < itemsForSale.length && itemsForSale[id].id == id, "Could not find item");
        _;
  }


    function putItemForSale(uint256 tokenId, uint256 price) 
        external 
        payable
        returns (uint256){
        require(!activeItems[tokenId], "Item is already up for sale");
        require(msg.value == poolFee, "msg.value must be equal to pool fee");
        require(Items[tokenId].backed == true, "This NFT was not backed yet");
        require(ownerOf(tokenId) == msg.sender, "You are not the token owner");

        uint256 newItemId = itemsForSale.length;
        itemsForSale.push(ItemForSale({
            id: newItemId,
            tokenId: tokenId,
            seller: payable(msg.sender),
            price: price,
            isSold: false
        }));
        activeItems[tokenId] = true;

        assert(itemsForSale[newItemId].id == newItemId);
        emit itemAddedForSale(newItemId, tokenId, price);
        return newItemId;
    }

    // Creates the sale of a marketplace item 
    // Transfers ownership of the item, as well as funds between parties (and gives a little of fees for the Once pool if we want)
    // I need to check if this is okay, here we give the listingPrice for our pool, as the nft was sold.
    function buyItem(uint256 id) 
        ItemExists(id)
        IsForSale(id)
        payable 
        external {
        require(msg.value >= itemsForSale[id].price, "Not enough funds sent");
        require(msg.sender != itemsForSale[id].seller);

        itemsForSale[id].isSold = true;
        activeItems[itemsForSale[id].tokenId] = false;

        _transfer(itemsForSale[id].seller, msg.sender, itemsForSale[id].tokenId);
        payable(itemsForSale[id].seller).transfer(msg.value - poolFee);

        emit itemSold(id, msg.sender, itemsForSale[id].price);
        }

    function totalItemsForSale() public view returns(uint256) {
        return itemsForSale.length;
    }

    function withdrawToken() public {
        require(msg.sender == ownerGovernance, "Only the ownerGovernance can withdraw the tokens.");
        tokenAddress.transfer(msg.sender, tokenAddress.balanceOf(address(this)));
    }
}
