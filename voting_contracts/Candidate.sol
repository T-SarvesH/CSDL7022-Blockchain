// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//For Candidate based data model and its methods
//Would be deployed in a particular timeWindow and after that it would be locked
import './ElectionOfficer.sol';

contract Candidate{

    struct candidate{

        uint candidateId;
        uint constituencyId;
        string name;
        string politicalParty;
        uint securityDeposit;
        uint age;
        bool isVoter;
        bool canContest;
    }

    ElectionOfficer e;
    

    mapping (address => candidate) candidates;
    mapping (address => bool) isCandidate;
    mapping (uint => address) candidateIds;
    mapping (address => bool) verifiedCandidates;
    mapping (address => bool) hasWon;

    uint immutable regStart = block.timestamp;
    uint immutable regEnd = regStart + 1 weeks;
    uint public totalCandidates = 0;
    uint totalDeposits;
    uint primKey = 1;

    address public gElect;
    address public electionCommission;
    event successfulRegistration(address candidateAddr, string candidateName);
    event successfulContestant(address candidateAddress, string name, string decision);

    modifier registrationOpen(){

        require(block.timestamp <= regEnd, "Registration period is alredy over");
        _;
    }

    modifier alreadyRegistered(address candidateAddress){

        require(!isCandidate[candidateAddress], "Following candidate is already registered");
        _;
    }

    modifier alreadyVerified(address candidateAddress){

        require(!verifiedCandidates[candidateAddress], "Following candidate is already verified");
        _;
    }

    modifier isOfficeFromSameConstituency(address officerAddress, address candidateAddress){
        
        require(
            e.isElecOfficer(officerAddress) 
            && e.getOfficerByAddress(officerAddress).allotedConstituency == candidates[candidateAddress].constituencyId, 
            "Cannot verify the candidate as both are from different constituencies"
        );

        _;
    }

    modifier fromGeneralElections(){

        require(msg.sender == gElect, "This can be called only from General Elections");
        _;
    }

    function candidateRegistration(address candidateAddress, string calldata name, string calldata politicalParty, uint securityDepositInEthers, uint age, uint constituencyId) public alreadyRegistered(candidateAddress) payable {

        require(msg.value == securityDepositInEthers * 1 ether, "Incorrect deposit sent");

        candidate memory c = candidate(primKey, constituencyId, name, politicalParty, securityDepositInEthers * 1 ether, age, false, false);
        candidates[candidateAddress] = c;
        isCandidate[candidateAddress] = true;
        candidateIds[primKey] = candidateAddress;

        ++primKey;
        ++totalCandidates;
        totalDeposits += msg.value;
        emit successfulRegistration(candidateAddress, name);


    }

    function candidateVerification(address _candidateAddress, bool decision) registrationOpen alreadyVerified(_candidateAddress) isOfficeFromSameConstituency(msg.sender, _candidateAddress)public {

        candidate storage c = candidates[_candidateAddress];

        if(decision){
            
            c.canContest = decision;
            verifiedCandidates[_candidateAddress] = true;
            emit successfulContestant(_candidateAddress, candidates[_candidateAddress].name, "This candidate can successfully contest");
        }

        else 
        emit successfulContestant(_candidateAddress, candidates[_candidateAddress].name, "This candidate cannot contest");
        
    }

    //External functions (Only callable by general election contract)
    function isCandidateAllowedToContest(uint _candidateId) view external fromGeneralElections returns (bool){

        address candidateAddress = candidateIds[_candidateId];
        return candidates[candidateAddress].canContest;
    }

    function getCandidateConstituency(uint _candidateId) view external fromGeneralElections returns (uint){

        address candidateAddress = candidateIds[_candidateId];
        return candidates[candidateAddress].constituencyId;
    }

    function setGeneralElection(address _generalElection) external {
        
        require(e.isElecCommissioner(), "Only the election Commissioner can perform this");
        require(gElect == address(0), "Election already set");
        gElect = _generalElection;
        electionCommission = msg.sender;
    }

    constructor(address _electionOfficerAddr){

        e = ElectionOfficer(_electionOfficerAddr);
    }
}