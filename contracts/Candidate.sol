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
    uint immutable regEnd = block.timestamp + 1 weeks;
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
        // Check if the ElectionOfficer contract is properly connected
        require(address(e) != address(0), "ElectionOfficer not connected");
        
        // Check if the caller is the commissioner
        bool isCommissioner = e.isElecCommissionerAddress(msg.sender);
        require(isCommissioner, "Only the Election Commissioner can perform this");
        
        require(gElect == address(0), "Election already set");
        gElect = _generalElection;
        electionCommission = msg.sender;
    }

    // New functions to support enhanced voting system
    function getCandidatesByConstituency(uint _constituencyId) public view returns (address[] memory) {
        uint count = 0;
        
        // First pass: count candidates in constituency
        for (uint i = 1; i < primKey; i++) {
            address candidateAddr = candidateIds[i];
            if (candidateAddr != address(0) && candidates[candidateAddr].constituencyId == _constituencyId && candidates[candidateAddr].canContest) {
                count++;
            }
        }
        
        // Second pass: create array with candidates
        address[] memory constituencyCandidates = new address[](count);
        uint index = 0;
        
        for (uint i = 1; i < primKey; i++) {
            address candidateAddr = candidateIds[i];
            if (candidateAddr != address(0) && candidates[candidateAddr].constituencyId == _constituencyId && candidates[candidateAddr].canContest) {
                constituencyCandidates[index] = candidateAddr;
                index++;
            }
        }
        
        return constituencyCandidates;
    }

    function getCandidateIdByAddress(address _candidateAddress) external view returns (uint) {
        require(isCandidate[_candidateAddress], "Address is not a registered candidate");
        return candidates[_candidateAddress].candidateId;
    }

    function getCandidateDetails(uint _candidateId) external view returns (
        string memory name,
        string memory politicalParty,
        uint age,
        uint constituencyId,
        bool canContest,
        bool isVerified
    ) {
        address candidateAddr = candidateIds[_candidateId];
        require(candidateAddr != address(0), "Candidate not found");
        
        candidate memory c = candidates[candidateAddr];
        return (
            c.name,
            c.politicalParty,
            c.age,
            c.constituencyId,
            c.canContest,
            verifiedCandidates[candidateAddr]
        );
    }

    function getTotalCandidatesByConstituency(uint _constituencyId) external view returns (uint) {
        uint count = 0;
        for (uint i = 1; i < primKey; i++) {
            address candidateAddr = candidateIds[i];
            if (candidateAddr != address(0) && candidates[candidateAddr].constituencyId == _constituencyId && candidates[candidateAddr].canContest) {
                count++;
            }
        }
        return count;
    }

    function getAllCandidates() external view returns (address[] memory) {
        address[] memory allCandidates = new address[](totalCandidates);
        uint index = 0;
        
        for (uint i = 1; i < primKey; i++) {
            address candidateAddr = candidateIds[i];
            if (candidateAddr != address(0)) {
                allCandidates[index] = candidateAddr;
                index++;
            }
        }
        
        return allCandidates;
    }

    function getConstituencyCandidates(uint _constituencyId) external view returns (
        address[] memory candidateAddresses,
        string[] memory names,
        string[] memory politicalParties,
        uint[] memory ages
    ) {
        address[] memory addresses = getCandidatesByConstituency(_constituencyId);
        string[] memory candidateNames = new string[](addresses.length);
        string[] memory parties = new string[](addresses.length);
        uint[] memory candidateAges = new uint[](addresses.length);
        
        for (uint i = 0; i < addresses.length; i++) {
            candidate memory c = candidates[addresses[i]];
            candidateNames[i] = c.name;
            parties[i] = c.politicalParty;
            candidateAges[i] = c.age;
        }
        
        return (addresses, candidateNames, parties, candidateAges);
    }

    // Emergency functions for election management
    function emergencyRemoveCandidate(address _candidateAddress) external {
        require(e.isElecCommissionerAddress(msg.sender), "Only Election Commissioner can perform this action");
        require(isCandidate[_candidateAddress], "Candidate not found");
        
        // Refund security deposit
        uint deposit = candidates[_candidateAddress].securityDeposit;
        if (deposit > 0) {
            payable(_candidateAddress).transfer(deposit);
        }
        
        // Remove candidate
        delete candidates[_candidateAddress];
        delete isCandidate[_candidateAddress];
        delete verifiedCandidates[_candidateAddress];
        
        totalCandidates--;
        totalDeposits -= deposit;
    }

    function getCandidateStatistics() external view returns (
        uint totalRegistered,
        uint totalVerified,
        uint totalConstituencies,
        uint totalDepositsCollected
    ) {
        // Count unique constituencies using a different approach
        uint uniqueConstituencies = 0;
        uint[] memory constituencies = new uint[](100); // Assume max 100 constituencies
        uint constituencyIndex = 0;
        
        for (uint i = 1; i < primKey; i++) {
            address candidateAddr = candidateIds[i];
            if (candidateAddr != address(0)) {
                uint constituencyId = candidates[candidateAddr].constituencyId;
                bool found = false;
                
                // Check if constituency already counted
                for (uint j = 0; j < constituencyIndex; j++) {
                    if (constituencies[j] == constituencyId) {
                        found = true;
                        break;
                    }
                }
                
                if (!found) {
                    constituencies[constituencyIndex] = constituencyId;
                    constituencyIndex++;
                    uniqueConstituencies++;
                }
            }
        }
        
        return (totalCandidates, getVerifiedCandidateCount(), uniqueConstituencies, totalDeposits);
    }

    function getVerifiedCandidateCount() internal view returns (uint) {
        uint count = 0;
        for (uint i = 1; i < primKey; i++) {
            address candidateAddr = candidateIds[i];
            if (candidateAddr != address(0) && verifiedCandidates[candidateAddr]) {
                count++;
            }
        }
        return count;
    }

    constructor(address _electionOfficerAddr){
        require(_electionOfficerAddr != address(0), "Invalid ElectionOfficer address");
        e = ElectionOfficer(_electionOfficerAddr);
    }
    
    // Function to check ElectionOfficer connection
    function getElectionOfficerAddress() external view returns (address) {
        return address(e);
    }
    
    // Getter function for isCandidate mapping
    function isCandidateRegistered(address _candidateAddress) external view returns (bool) {
        return isCandidate[_candidateAddress];
    }
}