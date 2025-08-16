const { ethers } = require("hardhat");

async function main() {
    console.log("🚀 Deploying Voting System Contracts...\n");

    // Get the signers
    const [deployer] = await ethers.getSigners();
    console.log("Deploying with account:", deployer.address);

    // Get the contract factories
    const ElectionOfficer = await ethers.getContractFactory("ElectionOfficer");
    const Voter = await ethers.getContractFactory("Voter");
    const Candidate = await ethers.getContractFactory("Candidate");
    const GeneralElections = await ethers.getContractFactory("GeneralElections");

    // Deploy contracts in order
    console.log("📋 Deploying ElectionOfficer contract...");
    const electionOfficer = await ElectionOfficer.connect(deployer).deploy();
    await electionOfficer.waitForDeployment();
    console.log("✅ ElectionOfficer deployed to:", await electionOfficer.getAddress());

    console.log("👥 Deploying Voter contract...");
    const voter = await Voter.connect(deployer).deploy(await electionOfficer.getAddress());
    await voter.waitForDeployment();
    console.log("✅ Voter deployed to:", await voter.getAddress());

    console.log("🏛️ Deploying Candidate contract...");
    const candidate = await Candidate.connect(deployer).deploy(await electionOfficer.getAddress());
    await candidate.waitForDeployment();
    console.log("✅ Candidate deployed to:", await candidate.getAddress());

    console.log("🗳️ Deploying GeneralElections contract...");
    const generalElections = await GeneralElections.connect(deployer).deploy(
        await candidate.getAddress(),
        await voter.getAddress(),
        await electionOfficer.getAddress()
    );
    await generalElections.waitForDeployment();
    console.log("✅ GeneralElections deployed to:", await generalElections.getAddress());

    // Set up contract relationships
    console.log("\n🔗 Setting up contract relationships...");
    
    console.log("Setting GeneralElections in Voter contract...");
    console.log("Deployer address:", deployer.address);
    console.log("ElectionOfficer address:", await electionOfficer.getAddress());
    
    // Check if deployer is commissioner
    const isCommissioner = await electionOfficer.isElecCommissioner();
    console.log("Is deployer commissioner?", isCommissioner);
    
    // Check commissioner address
    const commissionerAddress = await electionOfficer.getCommissionerAddress();
    console.log("Commissioner address:", commissionerAddress);
    
    // Check Voter's ElectionOfficer connection
    const voterElectionOfficerAddr = await voter.getElectionOfficerAddress();
    console.log("Voter's ElectionOfficer address:", voterElectionOfficerAddr);
    
    const voterTx = await voter.connect(deployer).setGeneralElection(await generalElections.getAddress());
    await voterTx.wait();
    console.log("✅ Voter contract linked to GeneralElections");

    console.log("Setting GeneralElections in Candidate contract...");
    
    // Check Candidate's ElectionOfficer connection
    const candidateElectionOfficerAddr = await candidate.getElectionOfficerAddress();
    console.log("Candidate's ElectionOfficer address:", candidateElectionOfficerAddr);
    
    const candidateTx = await candidate.connect(deployer).setGeneralElection(await generalElections.getAddress());
    await candidateTx.wait();
    console.log("✅ Candidate contract linked to GeneralElections");

    // Add some sample election officers
    console.log("\n👮‍♂️ Setting up sample election officers...");
    
    console.log("Election Commissioner:", deployer.address);

    // Add election officers for constituencies 1, 2, and 3
    const officerAddresses = [
        "0x70997970C51812dc3A010C7d01b50e0d17dc79C8", // Hardhat account 1
        "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC", // Hardhat account 2
        "0x90F79bf6EB2c4f870365E785982E1f101E93b906"  // Hardhat account 3
    ];

    const officerNames = ["Officer 1", "Officer 2", "Officer 3"];
    const constituencies = [1, 2, 3];

    for (let i = 0; i < officerAddresses.length; i++) {
        console.log(`Adding officer for constituency ${constituencies[i]}...`);
        const tx = await electionOfficer.connect(deployer).electElectionOfficers(
            officerAddresses[i],
            officerNames[i],
            constituencies[i]
        );
        await tx.wait();
        console.log(`✅ Officer ${officerNames[i]} added for constituency ${constituencies[i]}`);
    }

    console.log("\n🎉 Voting System Deployment Complete!");
    console.log("\n📋 Contract Addresses:");
    console.log("ElectionOfficer:", await electionOfficer.getAddress());
    console.log("Voter:", await voter.getAddress());
    console.log("Candidate:", await candidate.getAddress());
    console.log("GeneralElections:", await generalElections.getAddress());
    
    console.log("\n🔑 Sample Election Officers:");
    for (let i = 0; i < officerAddresses.length; i++) {
        console.log(`Constituency ${constituencies[i]}: ${officerAddresses[i]} (${officerNames[i]})`);
    }

    console.log("\n📝 Next Steps:");
    console.log("1. Register voters using the Voter contract");
    console.log("2. Register candidates using the Candidate contract");
    console.log("3. Verify voters and candidates using Election Officers");
    console.log("4. Start voting when election period begins");
    console.log("5. Count votes and declare results");

    // Export addresses for testing
    return {
        electionOfficer: await electionOfficer.getAddress(),
        voter: await voter.getAddress(),
        candidate: await candidate.getAddress(),
        generalElections: await generalElections.getAddress()
    };
}

// Execute deployment
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Deployment failed:", error);
        process.exit(1);
    });
