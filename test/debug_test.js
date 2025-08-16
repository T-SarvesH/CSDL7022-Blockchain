const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Debug Test", function () {
    let electionOfficer, owner;

    beforeEach(async function () {
        [owner] = await ethers.getSigners();
        
        const ElectionOfficer = await ethers.getContractFactory("ElectionOfficer");
        electionOfficer = await ElectionOfficer.deploy();
        await electionOfficer.waitForDeployment();
    });

    it("Should check commissioner setup", async function () {
        console.log("Owner address:", owner.address);
        console.log("ElectionOfficer address:", await electionOfficer.getAddress());
        console.log("Commissioner address:", await electionOfficer.electionCommissioner());
        // Use the new function name to avoid overload ambiguity
        const isCommissionerWithAddress = await electionOfficer.isElecCommissionerAddress(owner.address);
        console.log("Is owner commissioner (with address):", isCommissionerWithAddress);
        
        expect(await electionOfficer.electionCommissioner()).to.equal(owner.address);
        expect(isCommissionerWithAddress).to.be.true;
    });
});
