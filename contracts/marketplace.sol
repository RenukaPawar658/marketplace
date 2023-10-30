// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFTMarketplace is ERC721Holder{
  uint private totalSoldItems;
  uint private totalUnlistedItems;
  uint private itemIDs;
 
  struct MarketplaceListing{
    address payable owner;
    uint256 price;
    uint tokenId;
    uint itemId;
    string tokenURI;
    bool isSold;
    address nftContractAddress;
  }
// nftContractAddress--> tokenId-->NFTListing
mapping(address => mapping(uint => MarketplaceListing)) private listing;
mapping(uint => MarketplaceListing) private idToMarketplaceItem;

struct unListedItem{
  address owner;
  uint tokenId;
  uint deletedItemId;
}
mapping(uint => unListedItem) private unListedItems;

struct soldItem{
  address oldOwner;
  address currentOwner;
  uint256 price;
    uint tokenId;
    string tokenURI;
    address tokenContractAddress;
}
mapping(uint => soldItem) private soldItems;

event ItemListed(address indexed seller, uint indexed tokenId, uint indexed itemId,string tokenURI );
event ItemUnlisted(uint indexed tokenId,string indexed message);
event ItemSold(address indexed buyer,uint indexed tokenId,string indexed message);

//modifier to check Item is not listed
  modifier notListedBefore(address nftAddress,uint tokenId){
    MarketplaceListing storage list = listing[nftAddress][tokenId];
    require(list.price == 0 wei,"Already Ragistered NFT");
    _;
  }
//modifier to check Item is listed
modifier isListed(uint itemId,uint tokenId){
  require(idToMarketplaceItem[itemId].price > 0 wei,"NFT is not Ragistered");
  require(idToMarketplaceItem[itemId].tokenId == tokenId,"itemId or tokenId is incorrect");
  _;
}

function listItem(address nftContractAddress,uint256 tokenId, uint256 priceInTokens)notListedBefore(nftContractAddress, tokenId) external {
  
IERC721 nft = IERC721(nftContractAddress);
require(priceInTokens > 0 wei, "Price must be above zero in Tokens with decimal places");
require(nft.ownerOf(tokenId)== msg.sender,"you don't own this NFT");
require(nft.getApproved(tokenId) == address(this),"Not approved for Marketplace");

string memory tokenURI =IERC721Metadata(nftContractAddress).tokenURI(tokenId);
itemIDs++;
listing [nftContractAddress][tokenId] = MarketplaceListing (payable(msg.sender), priceInTokens, tokenId, itemIDs ,tokenURI,false, nftContractAddress);
idToMarketplaceItem[itemIDs] = listing[nftContractAddress][tokenId];
// Locking the NFT in the marketplace
nft.safeTransferFrom(msg.sender,address(this),tokenId);

emit ItemListed(msg.sender, tokenId, itemIDs , tokenURI );
}

function unlistItem(uint256 tokenId, uint256 itemId) isListed(itemId,tokenId) external {

address _nftContractAddress = idToMarketplaceItem[itemId].nftContractAddress;
address payable _owner = listing[_nftContractAddress][tokenId].owner;
require(_owner  == msg.sender, "you don't own this Item");
totalUnlistedItems++;
unListedItems[totalUnlistedItems] = unListedItem(msg.sender,tokenId,itemId); 

// Unlocking the NFT and transfer it back to the owner
IERC721 nft = IERC721(_nftContractAddress);

if(idToMarketplaceItem[itemId].isSold == true)
{
delete listing[_nftContractAddress][tokenId];
delete idToMarketplaceItem[itemId];
}
else{
nft.safeTransferFrom(address(this), msg.sender ,tokenId);
delete listing[_nftContractAddress][tokenId];
delete idToMarketplaceItem[itemId];
}
emit ItemUnlisted (tokenId, "succefully unlisted Item");
}

function buyItem(uint256 _itemId ,uint256 _tokenId, uint256 _priceInTokens, address tokenContractAddress) isListed(_itemId, _tokenId) external
{
    address nftAddress = idToMarketplaceItem[_itemId].nftContractAddress;
    IERC20 token = IERC20(tokenContractAddress);
    IERC721 nft = IERC721(nftAddress);
   // string memory tokenURI =IERC721Metadata(nftAddress).tokenURI(_tokenId);
    
    require(listing[nftAddress][_tokenId].isSold == false ,"Already sold");
    require(token.balanceOf(msg.sender) >= idToMarketplaceItem[_itemId].price ,"Insufficient balance");
    require(_priceInTokens == idToMarketplaceItem[_itemId].price,"price not match");

    address payable seller =listing[nftAddress][_tokenId].owner;
    token.transferFrom(msg.sender,seller,_priceInTokens);
    nft.safeTransferFrom(address(this), msg.sender, _tokenId);

    totalSoldItems++;
    uint256 soldId = totalSoldItems;
    soldItems[soldId] =soldItem(seller, msg.sender, _priceInTokens, _tokenId, idToMarketplaceItem[_itemId].tokenURI, tokenContractAddress);
    listing[nftAddress][_tokenId].isSold = true;
    listing[nftAddress][_tokenId].owner = payable(msg.sender);
    idToMarketplaceItem[_itemId] = listing[nftAddress][_tokenId];
    emit ItemSold(msg.sender, _tokenId,"succesfully Bought"); 
}

function totalListedItems() external view returns(uint256)
{
    return itemIDs;
}

function totalUnListedItem() external view returns(uint256)
{
    return totalUnlistedItems;
}

function totalSoldItemCount() external view returns(uint256)
{
    return totalSoldItems;
}

function getAllUnListedItems() external view returns(unListedItem[] memory)
{
    uint256 unListedCount = totalUnlistedItems;
    unListedItem[] memory item = new unListedItem[](unListedCount);
    uint256 count =0;
    for(uint i=1; i<=unListedCount; i++)
    {
        if(unListedItems[i].owner != address(0))
        {
            item[count++] = unListedItems[i];
        }
    }
    return item;
}

function getAllSoldItems() external view returns(soldItem[] memory) 
{
uint256 soldCount= totalSoldItems;

soldItem[] memory item = new soldItem[] (soldCount);
uint256 count =0;

for (uint i=1; i < soldCount; i++){
item[count++] = soldItems[i];
}
return item;
}

function getItemId(address nftContractAddress, uint256 tokenId) public view returns (uint) {
    return listing[nftContractAddress][tokenId].itemId;
}

function getItemById(uint256 itemId) external view returns(address owner,uint price,uint tokenId, bool issold, string memory tokenURI,address nftContractAddress)
{
MarketplaceListing storage nftListing =idToMarketplaceItem[itemId];
require(nftListing.owner != address(0),"Item with this ID does not exist");
return (nftListing.owner, nftListing.price, nftListing.tokenId, nftListing.isSold, nftListing.tokenURI, nftListing.nftContractAddress);
}
}
