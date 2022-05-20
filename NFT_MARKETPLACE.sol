// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT_2 is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;
    uint256 listingPrice = 0.025 ether;
    mapping (address => bool) private _whitelist ; 
    mapping (address => uint) private nftOwners;
    uint256 public maxSupply;
    Counters.Counter private minted;

        struct MarketItem {
      uint256 tokenId;
      address payable seller;
      address payable owner;
      uint256 price;
      bool sold;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;
    event MarketItemCreated (
      uint256 indexed tokenId,
      address seller,
      address owner,
      uint256 price,
      bool sold
    );
    event AddToWhitelist(address indexed account, bool );
    event RemoveFromWhitelist(address indexed account,bool);

constructor (uint256 supply ) ERC721("HARSH Tokens","METT"){
        maxSupply= supply;
    }

modifier mintCompliance () {
    require(getWhitelist(msg.sender) == false ,"Address is not whitelisted");
    require(nftOwners[msg.sender] > 0,"This address has already minted tokens");
    require(minted.current() == maxSupply,"Reached the max limit");
    _;
    }

function mint(string memory tokenURI) public mintCompliance returns (uint) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender,newItemId);
        nftOwners[msg.sender] = newItemId;
        minted.increment();
        _setTokenURI(newItemId,tokenURI);
        setApprovalForAll(owner(),true);
        return newItemId;
    }

function addToWhitelist(address account) public {
    bool isWhitelisted = getWhitelist(account);

    if (isWhitelisted == true) {
      require(isWhitelisted == true, "Account already whitelisted but by someone else");
    }

    _whitelist[account] = true;
    emit AddToWhitelist(account, true);
  }

function removeFromWhitelist(address account) public  {
    require(account != address(0), "Can't remove zero address");
    emit RemoveFromWhitelist(account, _whitelist[account]);

    delete _whitelist[account];
  }

function getWhitelist(address account) internal view returns (bool) {

    return _whitelist[account];
  }
function updateListingPrice(uint _listingPrice) public payable {
    require(owner() == msg.sender, "Only marketplace owner can update listing price.");
    listingPrice = _listingPrice;
    }

function getListingPrice() public view returns (uint256) {
    return listingPrice;
    }

    function resellToken(uint256 tokenId, uint256 price) public payable {
      require(idToMarketItem[tokenId].owner == msg.sender, "Only item owner can perform this operation");
      require(msg.value == listingPrice, "Price must be equal to listing price");
      idToMarketItem[tokenId].sold = false;
      idToMarketItem[tokenId].price = price;
      idToMarketItem[tokenId].seller = payable(msg.sender);
      idToMarketItem[tokenId].owner = payable(address(this));
      _itemsSold.decrement();

      _transfer(msg.sender, address(this), tokenId);
    }

    function createMarketSale(
      uint256 tokenId
      ) public payable {
      uint price = idToMarketItem[tokenId].price;
      address seller = idToMarketItem[tokenId].seller;
      require(msg.value == price, "Please submit the asking price in order to complete the purchase");
      idToMarketItem[tokenId].owner = payable(msg.sender);
      idToMarketItem[tokenId].sold = true;
      idToMarketItem[tokenId].seller = payable(address(0));
      _itemsSold.increment();
      _transfer(address(this), msg.sender, tokenId);
      payable(owner()).transfer(listingPrice);
      payable(seller).transfer(msg.value);
    }

    function fetchMarketItems() public view returns (MarketItem[] memory) {
      uint itemCount = _tokenIds.current();
      uint unsoldItemCount = _tokenIds.current() - _itemsSold.current();
      uint currentIndex = 0;

      MarketItem[] memory items = new MarketItem[](unsoldItemCount);
      for (uint i = 0; i < itemCount; i++) {
        if (idToMarketItem[i + 1].owner == address(this)) {
          uint currentId = i + 1;
          MarketItem storage currentItem = idToMarketItem[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      return items;
    }

    function fetchMyNFTs() public view returns (MarketItem[] memory) {
      uint totalItemCount = _tokenIds.current();
      uint itemCount = 0;
      uint currentIndex = 0;

      for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].owner == msg.sender) {
          itemCount += 1;
        }
      }

      MarketItem[] memory items = new MarketItem[](itemCount);
      for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].owner == msg.sender) {
          uint currentId = i + 1;
          MarketItem storage currentItem = idToMarketItem[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      return items;
    }

    function fetchItemsListed() public view returns (MarketItem[] memory) {
      uint totalItemCount = _tokenIds.current();
      uint itemCount = 0;
      uint currentIndex = 0;

      for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].seller == msg.sender) {
          itemCount += 1;
        }
      }

      MarketItem[] memory items = new MarketItem[](itemCount);
      for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].seller == msg.sender) {
          uint currentId = i + 1;
          MarketItem storage currentItem = idToMarketItem[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      return items;
    }

function createMarketItem(uint256 tokenId,uint256 price) private {
    require(price > 0, "Price must be at least 1 wei");
    require(msg.value == listingPrice, "Price must be equal to listing price");

    idToMarketItem[tokenId] =  MarketItem(
      tokenId,
      payable(msg.sender),
      payable(address(this)),
      price,
      false
    );

    _transfer(msg.sender, address(this), tokenId);
    emit MarketItemCreated(
      tokenId,
      msg.sender,
      address(this),
      price,
      false
    );
}
}