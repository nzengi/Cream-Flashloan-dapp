const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Ethos Reserve Token", function () {
  let ethosReserve;
  let owner;
  let user1;
  let user2;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    const EthosReserve = await ethers.getContractFactory("EthosReserve");
    ethosReserve = await EthosReserve.deploy();
    await ethosReserve.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await ethosReserve.owner()).to.equal(owner.address);
    });

    it("Should assign the total supply to the owner", async function () {
      const ownerBalance = await ethosReserve.balanceOf(owner.address);
      expect(await ethosReserve.totalSupply()).to.equal(ownerBalance);
    });

    it("Should have correct token metadata", async function () {
      expect(await ethosReserve.name()).to.equal("Ethos Reserve");
      expect(await ethosReserve.symbol()).to.equal("ERSV");
      expect(await ethosReserve.decimals()).to.equal(18);
    });

    it("Should have correct initial supply", async function () {
      const expectedSupply = ethers.parseEther("100000000"); // 100M ERSV
      expect(await ethosReserve.totalSupply()).to.equal(expectedSupply);
    });
  });

  describe("Token Transfers", function () {
    it("Should transfer tokens between accounts", async function () {
      const transferAmount = ethers.parseEther("1000");

      await ethosReserve.transfer(user1.address, transferAmount);
      expect(await ethosReserve.balanceOf(user1.address)).to.equal(
        transferAmount
      );
    });

    it("Should fail if sender doesn't have enough tokens", async function () {
      const initialOwnerBalance = await ethosReserve.balanceOf(owner.address);

      await expect(
        ethosReserve.connect(user1).transfer(owner.address, 1)
      ).to.be.revertedWithCustomError(ethosReserve, "ERC20InsufficientBalance");

      expect(await ethosReserve.balanceOf(owner.address)).to.equal(
        initialOwnerBalance
      );
    });
  });

  describe("Minting", function () {
    it("Should allow owner to mint tokens", async function () {
      const mintAmount = ethers.parseEther("10000");
      const initialBalance = await ethosReserve.balanceOf(user1.address);

      await ethosReserve.mint(user1.address, mintAmount);

      expect(await ethosReserve.balanceOf(user1.address)).to.equal(
        initialBalance + mintAmount
      );
    });

    it("Should fail if non-owner tries to mint", async function () {
      const mintAmount = ethers.parseEther("10000");

      await expect(
        ethosReserve.connect(user1).mint(user2.address, mintAmount)
      ).to.be.revertedWithCustomError(
        ethosReserve,
        "OwnableUnauthorizedAccount"
      );
    });
  });

  describe("Burning", function () {
    it("Should allow users to burn their own tokens", async function () {
      const transferAmount = ethers.parseEther("1000");
      const burnAmount = ethers.parseEther("500");

      await ethosReserve.transfer(user1.address, transferAmount);
      const balanceBeforeBurn = await ethosReserve.balanceOf(user1.address);

      await ethosReserve.connect(user1).burn(burnAmount);

      expect(await ethosReserve.balanceOf(user1.address)).to.equal(
        balanceBeforeBurn - burnAmount
      );
    });

    it("Should fail if user tries to burn more than they have", async function () {
      const transferAmount = ethers.parseEther("1000");
      const burnAmount = ethers.parseEther("1500");

      await ethosReserve.transfer(user1.address, transferAmount);

      await expect(
        ethosReserve.connect(user1).burn(burnAmount)
      ).to.be.revertedWithCustomError(ethosReserve, "ERC20InsufficientBalance");
    });
  });

  describe("Reserve Backing", function () {
    it("Should allow owner to add reserve backing", async function () {
      const tokenAddress = user1.address; // Mock token address
      const amount = ethers.parseEther("1000");

      await ethosReserve.addReserveBacking(tokenAddress, amount);

      expect(await ethosReserve.reserveBacking(tokenAddress)).to.equal(amount);
    });

    it("Should allow owner to remove reserve backing", async function () {
      const tokenAddress = user1.address;
      const addAmount = ethers.parseEther("1000");
      const removeAmount = ethers.parseEther("300");

      await ethosReserve.addReserveBacking(tokenAddress, addAmount);
      await ethosReserve.removeReserveBacking(tokenAddress, removeAmount);

      expect(await ethosReserve.reserveBacking(tokenAddress)).to.equal(
        addAmount - removeAmount
      );
    });

    it("Should fail if trying to remove more than available", async function () {
      const tokenAddress = user1.address;
      const addAmount = ethers.parseEther("1000");
      const removeAmount = ethers.parseEther("1500");

      await ethosReserve.addReserveBacking(tokenAddress, addAmount);

      await expect(
        ethosReserve.removeReserveBacking(tokenAddress, removeAmount)
      ).to.be.revertedWith("Insufficient reserve");
    });
  });

  describe("Events", function () {
    it("Should emit ReserveAdded event", async function () {
      const tokenAddress = user1.address;
      const amount = ethers.parseEther("1000");

      await expect(ethosReserve.addReserveBacking(tokenAddress, amount))
        .to.emit(ethosReserve, "ReserveAdded")
        .withArgs(tokenAddress, amount);
    });

    it("Should emit ReserveRemoved event", async function () {
      const tokenAddress = user1.address;
      const addAmount = ethers.parseEther("1000");
      const removeAmount = ethers.parseEther("500");

      await ethosReserve.addReserveBacking(tokenAddress, addAmount);

      await expect(
        ethosReserve.removeReserveBacking(tokenAddress, removeAmount)
      )
        .to.emit(ethosReserve, "ReserveRemoved")
        .withArgs(tokenAddress, removeAmount);
    });
  });
});
