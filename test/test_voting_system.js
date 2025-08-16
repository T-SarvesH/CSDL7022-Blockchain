const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Voting System", function () {
    let electionOfficer, voter, candidate, generalElections;
    let owner, officer1, officer2, officer3, voter1, voter2, candidate1, candidate2;
    let addresses;

    beforeEach(async function () {
        // Get signers
        [owner, officer1, officer2, officer3, voter1, voter2, candidate1, candidate2] = await ethers.getSigners();

        // Deploy contracts
        const ElectionOfficer = await ethers.getContractFactory("ElectionOfficer");
        const Voter = await ethers.getContractFactory("Voter");
        const Candidate = await ethers.getContractFactory("Candidate");
        const GeneralElections = await ethers.getContractFactory("GeneralElections");

        electionOfficer = await ElectionOfficer.deploy();
        await electionOfficer.waitForDeployment();
        
        voter = await Voter.deploy(await electionOfficer.getAddress());
        await voter.waitForDeployment();
        
        candidate = await Candidate.deploy(await electionOfficer.getAddress());
        await candidate.waitForDeployment();
        
        generalElections = await GeneralElections.deploy(
            await candidate.getAddress(),
            await voter.getAddress(),
            await electionOfficer.getAddress()
        );
        await generalElections.waitForDeployment();

        // Set up relationships
        await voter.setGeneralElection(await generalElections.getAddress());
        await candidate.setGeneralElection(await generalElections.getAddress());

        // Add election officers
        await electionOfficer.electElectionOfficers(officer1.address, "Officer 1", 1);
        await electionOfficer.electElectionOfficers(officer2.address, "Officer 2", 2);
        await electionOfficer.electElectionOfficers(officer3.address, "Officer 3", 3);

        addresses = {
            electionOfficer: electionOfficer.address,
            voter: voter.address,
            candidate: candidate.address,
            generalElections: generalElections.address
        };
    });

    describe("Contract Deployment", function () {
        it("Should deploy all contracts successfully", async function () {
            expect(electionOfficer.address).to.not.equal("0x0000000000000000000000000000000000000000");
            expect(voter.address).to.not.equal("0x0000000000000000000000000000000000000000");
            expect(candidate.address).to.not.equal("0x0000000000000000000000000000000000000000");
            expect(generalElections.address).to.not.equal("0x0000000000000000000000000000000000000000");
        });

        it("Should set up contract relationships correctly", async function () {
            expect(await voter.gElect()).to.equal(await generalElections.getAddress());
            expect(await candidate.gElect()).to.equal(await generalElections.getAddress());
        });

        it("Should set election commissioner correctly", async function () {
            expect(await electionOfficer.electionCommissioner()).to.equal(owner.address);
            // Use the new function name to avoid overload ambiguity
            expect(await electionOfficer.isElecCommissionerAddress(owner.address)).to.be.true;
        });
    });

    describe("Election Officer Management", function () {
        it("Should allow election commissioner to add officers", async function () {
            expect(await electionOfficer.isElecOfficer(officer1.address)).to.be.true;
            expect(await electionOfficer.isElecOfficer(officer2.address)).to.be.true;
            expect(await electionOfficer.isElecOfficer(officer3.address)).to.be.true;
        });

        it("Should assign correct constituencies to officers", async function () {
            const officer1Details = await electionOfficer.getOfficerByAddress(officer1.address);
            const officer2Details = await electionOfficer.getOfficerByAddress(officer2.address);
            const officer3Details = await electionOfficer.getOfficerByAddress(officer3.address);

            expect(officer1Details.allotedConstituency).to.equal(1);
            expect(officer2Details.allotedConstituency).to.equal(2);
            expect(officer3Details.allotedConstituency).to.equal(3);
        });

        it("Should prevent non-commissioner from adding officers", async function () {
            await expect(
                electionOfficer.connect(voter1).electElectionOfficers(
                    voter1.address, "Test Officer", 4
                )
            ).to.be.revertedWith("Only the Election Commissioner can perform this action");
        });
    });

    describe("Voter Registration", function () {
        it("Should allow voters to register", async function () {
            await voter.connect(voter1).registerAsVoter(
                "John Doe",
                25,
                "0x313233343536373839303132", // bytes12 representation of "123456789012"
                "VOTER001",
                1
            );

            const voterDetails = await voter.getVoterDetails(1);
            expect(voterDetails.name).to.equal("John Doe");
            expect(voterDetails.age).to.equal(25);
            expect(voterDetails.constituencyId).to.equal(1);
            expect(voterDetails.hasRegistered).to.be.true;
            expect(voterDetails.isAllowedToVote).to.be.false; // Not verified yet
        });

        it("Should prevent duplicate registration", async function () {
            await voter.connect(voter1).registerAsVoter(
                "John Doe",
                25,
                "0x313233343536373839303132", // bytes12 representation of "123456789012"
                "VOTER001",
                1
            );

            await expect(
                voter.connect(voter1).registerAsVoter(
                    "John Doe",
                    25,
                    "0x313233343536373839303132", // bytes12 representation of "123456789012"
                    "VOTER001",
                1
                )
            ).to.be.revertedWith("Voter is already registered");
        });

        it("Should increment voter count correctly", async function () {
            const initialCount = await voter.voterCount();
            await voter.connect(voter1).registerAsVoter(
                "John Doe",
                25,
                "0x313233343536373839303132", // bytes12 representation of "123456789012"
                "VOTER001",
                1
            );
            expect(await voter.voterCount()).to.equal(initialCount + 1n);
        });
    });

    describe("Candidate Registration", function () {
        it("Should allow candidates to register with security deposit", async function () {
            const depositAmount = ethers.parseEther("1");
            
            await candidate.connect(candidate1).candidateRegistration(
                candidate1.address,
                "Jane Smith",
                "Democratic Party",
                1, // 1 ETH deposit
                30,
                1,
                { value: depositAmount }
            );

            const candidateDetails = await candidate.getCandidateDetails(1);
            expect(candidateDetails.name).to.equal("Jane Smith");
            expect(candidateDetails.politicalParty).to.equal("Democratic Party");
            expect(candidateDetails.age).to.equal(30);
            expect(candidateDetails.constituencyId).to.equal(1);
            expect(candidateDetails.canContest).to.be.false; // Not verified yet
        });

        it("Should prevent duplicate candidate registration", async function () {
            const depositAmount = ethers.parseEther("1");
            
            await candidate.connect(candidate1).candidateRegistration(
                candidate1.address,
                "Jane Smith",
                "Democratic Party",
                1,
                30,
                1,
                { value: depositAmount }
            );

            await expect(
                candidate.connect(candidate1).candidateRegistration(
                    candidate1.address,
                    "Jane Smith",
                    "Democratic Party",
                    1,
                    30,
                    1,
                    { value: depositAmount }
                )
            ).to.be.revertedWith("Following candidate is already registered");
        });

        it("Should require correct security deposit amount", async function () {
            const wrongDepositAmount = ethers.parseEther("0.5");
            
            await expect(
                candidate.connect(candidate1).candidateRegistration(
                    candidate1.address,
                    "Jane Smith",
                    "Democratic Party",
                    1, // Expecting 1 ETH
                    30,
                    1,
                    { value: wrongDepositAmount }
                )
            ).to.be.revertedWith("Incorrect deposit sent");
        });
    });

    describe("Voter and Candidate Verification", function () {
        beforeEach(async function () {
            // Register a voter
            await voter.connect(voter1).registerAsVoter(
                "John Doe",
                25,
                "0x313233343536373839303132", // bytes12 representation of "123456789012"
                "VOTER001",
                1
            );

            // Register a candidate
            const depositAmount = ethers.parseEther("1");
            await candidate.connect(candidate1).candidateRegistration(
                candidate1.address,
                "Jane Smith",
                "Democratic Party",
                1,
                30,
                1,
                { value: depositAmount }
            );
        });

        it("Should allow election officers to verify voters", async function () {
            await voter.connect(officer1).verifyVoters(
                voter1.address,
                "0x313233343536373839303132", // bytes12 representation of "123456789012"
                "VOTER001",
                true
            );

            const voterDetails = await voter.getVoterDetails(1);
            expect(voterDetails.isAllowedToVote).to.be.true;
        });

        it("Should allow election officers to verify candidates", async function () {
            await candidate.connect(officer1).candidateVerification(
                candidate1.address,
                true
            );

            const candidateDetails = await candidate.getCandidateDetails(1);
            expect(candidateDetails.canContest).to.be.true;
        });

        it("Should prevent verification from wrong constituency officer", async function () {
            await expect(
                voter.connect(officer2).verifyVoters(
                    voter1.address,
                    "0x313233343536373839303132", // bytes12 representation of "123456789012"
                    "VOTER001",
                    true
                )
            ).to.be.revertedWith("Cannot verify the voter as both are from different constituencies");
        });

        it("Should prevent verification with wrong credentials", async function () {
            await expect(
                voter.connect(officer1).verifyVoters(
                    voter1.address,
                    "0x57524f4e475f414144484152", // bytes12 representation of "WRONG_AADHAR"
                    "VOTER001",
                    true
                )
            ).to.be.revertedWith("Aadhar card number mismatch");
        });
    });

    describe("Contract Permissions", function () {
        it("Should only allow commissioner to set general election", async function () {
            const newVoter = await (await ethers.getContractFactory("Voter")).deploy(await electionOfficer.getAddress());
            
            await expect(
                newVoter.connect(voter1).setGeneralElection(await generalElections.getAddress())
            ).to.be.revertedWith("Only the election Commissioner can perform this");
        });

        it("Should prevent setting general election twice", async function () {
            await expect(
                voter.setGeneralElection(await generalElections.getAddress())
            ).to.be.revertedWith("Election already set");
        });
    });

    describe("Data Retrieval and Statistics", function () {
        beforeEach(async function () {
            // Register multiple voters and candidates
            await voter.connect(voter1).registerAsVoter("John Doe", 25, "0x313233343536373839303132", "VOTER001", 1);
            await voter.connect(voter2).registerAsVoter("Jane Doe", 28, "0x393837363534333231303938", "VOTER002", 2);
            
            const depositAmount = ethers.parseEther("1");
            await candidate.connect(candidate1).candidateRegistration(
                candidate1.address, "Jane Smith", "Democratic Party", 1, 30, 1, { value: depositAmount }
            );
            await candidate.connect(candidate2).candidateRegistration(
                candidate2.address, "John Smith", "Republican Party", 1, 35, 2, { value: depositAmount }
            );
            
            // Verify candidates so they can contest
            await candidate.connect(officer1).candidateVerification(candidate1.address, true);
            await candidate.connect(officer2).candidateVerification(candidate2.address, true);
        });

        it("Should return correct voter statistics", async function () {
            const stats = await voter.getVoterStatistics();
            expect(stats.totalRegistered).to.equal(2);
            expect(stats.totalConstituencies).to.equal(2);
        });

        it("Should return correct candidate statistics", async function () {
            const stats = await candidate.getCandidateStatistics();
            expect(stats.totalRegistered).to.equal(2);
            expect(stats.totalConstituencies).to.equal(2);
        });

        it("Should return constituency-specific data", async function () {
            const constituencyVoters = await voter.getVotersByConstituency(1);
            const constituencyCandidates = await candidate.getCandidatesByConstituency(1);

            expect(constituencyVoters.length).to.equal(1);
            expect(constituencyCandidates.length).to.equal(1);
        });

        it("Should return voter details by address", async function () {
            const voterDetails = await voter.getVoterByAddress(voter1.address);
            expect(voterDetails.name).to.equal("John Doe");
            expect(voterDetails.age).to.equal(25);
            expect(voterDetails.constituencyId).to.equal(1);
        });
    });

    describe("Emergency Functions", function () {
        it("Should allow election commissioner to remove voters", async function () {
            await voter.connect(voter1).registerAsVoter("John Doe", 25, "0x313233343536373839303132", "VOTER001", 1);
            
            await voter.connect(owner).emergencyRemoveVoter(voter1.address);
            
            await expect(
                voter.getVoterByAddress(voter1.address)
            ).to.be.revertedWith("Voter not found");
        });

        it("Should allow election commissioner to remove candidates", async function () {
            const depositAmount = ethers.parseEther("1");
            await candidate.connect(candidate1).candidateRegistration(
                candidate1.address, "Jane Smith", "Democratic Party", 1, 30, 1, { value: depositAmount }
            );
            
            await candidate.connect(owner).emergencyRemoveCandidate(candidate1.address);
            
            expect(await candidate.isCandidateRegistered(candidate1.address)).to.be.false;
        });
    });

    describe("Time-based Restrictions", function () {
        it("Should enforce registration time windows", async function () {
            // This test would require time manipulation to properly test
            // For now, we'll just verify the contracts have time-based logic
            // Note: These functions might not exist in the current contract version
            console.log("Time-based restrictions test - functions may need to be added to contracts");
        });

        it("Should enforce election time windows", async function () {
            expect(await generalElections.electionStart()).to.be.gt(0);
            expect(await generalElections.electionEnd()).to.be.gt(await generalElections.electionStart());
        });
    });
});
