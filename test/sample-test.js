const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Distributor", function () {

  let distributor;

  beforeEach(async () => {
    [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
    const Distributor = await ethers.getContractFactory("Distributor");
    distributor = await Distributor.deploy();
    await distributor.deployed();
  });

  describe("Contribution limits", () => {

    it("Change max contribution", async function () {
      await distributor.connect(owner).changeMaxContribution(ethers.utils.parseEther('12'))
      expect(await distributor.maxContribution()).to.equal(ethers.utils.parseEther('12'));
    });
    
    it("Change min contribution", async function () {
      await distributor.connect(owner).changeMinContribution('200')
      expect(await distributor.minContribution()).to.equal('200');
    });

  })

  describe("Ownership", () => {

    it("Only owner can transfer ownership", async function () {
      await expect(distributor.connect(addr1).transferOwnership(await addr1.getAddress())).to.be.revertedWith(
        'MUST_BE_OWNER'
      );
    });

    it("Transfer ownership", async function () {
      await distributor.connect(owner).transferOwnership(await addr1.getAddress())
      expect(await distributor.owner()).to.be.equal(await addr1.getAddress());
    });

  })

  describe("Contributions", () => {
    it("Contributions over max amount", async function () {
      await distributor.connect(owner).contribute({ value: ethers.utils.parseEther('6') })
      await expect(distributor.connect(owner).contribute({ value: ethers.utils.parseEther('6') })).to.be.revertedWith(
        'CONTRIBUTION_TOO_HIGH'
      );
    });

    it("Contributions under min amount", async function () {
      await expect(distributor.connect(owner).contribute({ value: ethers.utils.parseEther('0.01') })).to.be.revertedWith(
        'CONTRIBUTION_TOO_LOW'
      );
    });

    it("Users contribution", async function () {
      await distributor.connect(addr1).contribute({ value: ethers.utils.parseEther('2') })
      await distributor.connect(addr2).contribute({ value: ethers.utils.parseEther('3') })
      expect(await distributor.contributions(addr1.getAddress())).to.be.equal(ethers.utils.parseEther('2'));
      expect(await distributor.contributions(addr2.getAddress())).to.be.equal(ethers.utils.parseEther('3'));
      expect(await distributor.contributorsAmount()).to.be.equal('2');
    });

  })

  describe("Withdraw", () => {

    beforeEach(async () => {
      await distributor.connect(owner).contribute({ value: ethers.utils.parseEther('1') })
      await distributor.connect(addr1).contribute({ value: ethers.utils.parseEther('2') })
      await distributor.connect(addr2).contribute({ value: ethers.utils.parseEther('3') })
    });
  

    it("Withdrawal locked", async function () {
      await expect(distributor.connect(addr1).withdraw()).to.be.revertedWith(
        'WITHDRAWALS_ARE_LOCKED'
      );
    });

    it("Withdrawals opened", async function () {

      await distributor.connect(owner).unlockWithdrawals()

      let contributors = [owner, addr1, addr2]

      for (let i = 0; i < contributors.length; i++) {
        const element = contributors[i];
        await distributor.connect(element).withdraw()        
      }

      for (let i = 0; i < contributors.length; i++) {
        const element = contributors[i];
        if((ethers.utils.parseEther('2') - parseInt(await element.getBalance()))*100>1 ){
          expect.fail('Redistribution error')
        }
      }

      let balance = await distributor.provider.getBalance(distributor.address);
      expect(balance).to.be.equal('0');
      expect(await distributor.contributorsAmount()).to.be.equal('0');

      let accBalance;
      for (let i = 0; i < contributors.length; i++) {
        const element = contributors[i];
        accBalance = await distributor.contributions(element.getAddress())
        expect(accBalance).to.be.equal('0');
      }
    });

    describe('Retire', () =>{

      it("No funds", async function () {
        await expect(distributor.connect(addr3).retire()).to.be.revertedWith(
          'NO_AVAILABLE_FUNDS'
        );
      });

      it("Sucessful retirement", async function () {
        await distributor.connect(addr1).retire()
        expect(await distributor.contributions(addr1.getAddress())).to.be.equal('0');
        expect(await distributor.contributorsAmount()).to.be.equal('2');
      });

    })
  })
});


