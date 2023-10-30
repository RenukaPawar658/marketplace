const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTMarketplace", function () {
  let nftMarketplace;
  let nftContract;
  let tokenContract;
  let user1,user2;
  const tokenURI = "ipfs://tokenURI";
  
  before(async () => {
    [user1,user2] = await ethers.getSigners();

    const NFTMarketplace = await ethers.getContractFactory("NFTMarketplace");
    nftMarketplace = await NFTMarketplace.deploy();
    await nftMarketplace.deployed();

    const NFTContract = await ethers.getContractFactory("NFT");
    nftContract = await NFTContract.deploy();
    await nftContract.deployed();

    const TokenContract = await ethers.getContractFactory("ERC20Token");
    tokenContract = await TokenContract.deploy();
    await nftContract.deployed();

    const mintedTx = await nftContract.safeMint(user1.address, tokenURI);
    const mintedReceipt = await mintedTx.wait();
    mintedTokenId = mintedReceipt.events[0].args.tokenId.toNumber();
  });

  describe("listItem", function () {
    it("should list an NFT on the marketplace", async function () {
      const priceInTokens = ethers.utils.parseEther("10");

    //minting a NFT and Capture the Minted event to extract the tokenId
     const mintedTx = await nftContract.safeMint(user1.address, tokenURI);
     const mintedReceipt = await mintedTx.wait();
     mintedTokenId = mintedReceipt.events[0].args.tokenId.toNumber();
     //approve by user1 to nftMarketplace contract
     await nftContract.connect(user1).approve(nftMarketplace.address,mintedTokenId);

      //user1 list the NFT for sale    
      const Item = await nftMarketplace.connect(user1).listItem(nftContract.address,mintedTokenId , priceInTokens);
     ///----------------
     // User1 lists the NFT for sale
  // const listItemTx = await nftMarketplace.connect(user1).listItem(nftContract.address, mintedTokenId, priceInTokens);
    //const listItemReceipt = await listItemTx.wait();

    // Verify that the NFT has been listed successfully
   // const item = await nftMarketplace.idToMarketplaceItem(listItemReceipt.events[0].args.itemId.toNumber());
   
});

    it("should not list an already listed NFT", async function () {
      const priceInTokens = ethers.utils.parseEther("1");

     const mintedTx = await nftContract.safeMint(user1.address, tokenURI);
     const mintedReceipt = await mintedTx.wait();
     
    mintedTokenId = mintedReceipt.events[0].args.tokenId.toNumber();
    
    await nftContract.connect(user1).approve(nftMarketplace.address,mintedTokenId);
     
    // First listing
      await nftMarketplace.listItem(nftContract.address, mintedTokenId, priceInTokens);

      // Second listing attempt should fail
      await expect(nftMarketplace.listItem(nftContract.address, mintedTokenId, priceInTokens)).to.be.revertedWith(
        "Already Ragistered NFT"
      );
    });

    it("should not list an NFT with a zero price", async function () {
      const zeroPrice = ethers.utils.parseEther("0");
      
     const mintedTx = await nftContract.safeMint(user1.address, tokenURI);
     const mintedReceipt = await mintedTx.wait();
     mintedTokenId = mintedReceipt.events[0].args.tokenId.toNumber();
      await expect(nftMarketplace.listItem(nftContract.address, mintedTokenId , zeroPrice)).to.be.revertedWith(
        "Price must be above zero in Tokens with decimal places"
      );
    });

    it("should not list an NFT you do not own", async function () {
      const priceInTokens = ethers.utils.parseEther("1");
      await expect(nftMarketplace.connect(user2).listItem(nftContract.address,mintedTokenId , priceInTokens)).to.be.revertedWith(
        "you don't own this NFT"
      );
    });

    it("should not list an NFT that is not approved for the marketplace", async function () {
      const priceInTokens = ethers.utils.parseEther("1");
      await expect(nftMarketplace.listItem(nftContract.address,mintedTokenId, priceInTokens)).to.be.revertedWith(
        "Not approved for Marketplace"
      );
    });
  });

   
  describe("unlistItem", function () {
    it("should unlist an NFT from the marketplace by the owner", async function () {
      const priceInTokens = ethers.utils.parseEther("1");

      await nftContract.connect(user1).approve(nftMarketplace.address,mintedTokenId);
      await nftMarketplace.listItem(nftContract.address, mintedTokenId, priceInTokens);
      await nftMarketplace.unlistItem(mintedTokenId, 1, user1);

      const marketplaceItem = await nftMarketplace.idToMarketplaceItem[1];

     expect(marketplaceItem.owner).to.equal("0x0000000000000000000000000000000000000000");

    });

    it("should not allow another user to unlist an NFT", async function () {
      const nftContractAddress = "0xNFTContractAddress"; // Replace with a real NFT contract address
      const tokenId = 1;
      const priceInTokens = ethers.utils.parseEther("1");

      await nftMarketplace.listItem(nftContractAddress, tokenId, priceInTokens);

      await expect(
        nftMarketplace.connect(anotherUser).unlistItem(tokenId, 1)
      ).to.be.revertedWith("you don't own this Item");
    });

    it("should transfer the NFT back to the owner upon unlisting", async function () {
      const nftContractAddress = "0xNFTContractAddress"; // Replace with a real NFT contract address
      const tokenId = 1;
      const priceInTokens = ethers.utils.parseEther("1");

      await nftMarketplace.listItem(nftContractAddress, tokenId, priceInTokens);

      await nftMarketplace.unlistItem(tokenId, 1, { from: owner });

      const nft = await ethers.getContractAt("IERC721", nftContractAddress);
      const newOwner = await nft.ownerOf(tokenId);

      expect(newOwner).to.equal(owner.address);
    });

    it("should delete the NFT listing upon unlisting", async function () {
      const nftContractAddress = "0xNFTContractAddress"; // Replace with a real NFT contract address
      const tokenId = 1;
      const priceInTokens = ethers.utils.parseEther("1");

      await nftMarketplace.listItem(nftContractAddress, tokenId, priceInTokens);

      await nftMarketplace.unlistItem(tokenId, 1, { from: owner });

      const marketplaceItem = await nftMarketplace.idToMarketplaceItem(1);

      expect(marketplaceItem.owner).to.equal("0x0000000000000000000000000000000000000000");
    });
  });

});


