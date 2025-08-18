// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//For voter based data model and its methods
import './ElectionOfficer.sol';

contract Voter{

    uint immutable startTime = block.timestamp;
    uint immutable endTime = block.timestamp + 10 minutes ;

    uint immutable electionStart = block.timestamp + 10 minutes;
    uint immutable electionEnd = block.timestamp + 15 minutes;

    address public gElect;
    address public electionCommission;

    ElectionOfficer e;
    
    //Get a mapping of Officers and constituencies assigned
    struct voter{

        uint id;
        string name;
        uint age;
        bytes32 aadharNumber;
        bytes32 voterIdNumber;
        uint ConstituencyId;
        bool hasVoted;
        bool hasRegistered;
        bool isAllowedToVote; // This would be verified later by the respective Election officer
    }

    mapping(address => voter) voterMap;
    mapping (uint => address) voterIds;

    uint public voterCount = 0;
    uint public primKey=1;

    // From ElectionOfficer Module
    modifier registrationOpen(){

        require(block.timestamp <= endTime && block.timestamp >= startTime, "The registration period is over");
        _;
    } 

    modifier isOfficeFromSameConstituency(address officerAddress, address voterAddress){
        
        require(voterMap[voterAddress].id > 0, "Voter not found");

        require(
            e.isElecOfficer(officerAddress) 
            && e.getOfficerByAddress(officerAddress).allotedConstituency == voterMap[voterAddress].ConstituencyId, 
            "Cannot verify the voter as both are from different constituencies"
        );

        _;
    }

    modifier isElectionLive (){

        require(block.timestamp <= electionEnd && block.timestamp >= electionStart, "The election has ended");
        _;
    }

    modifier isVoterVerified(address voterAddress){

        require(!voterMap[voterAddress].isAllowedToVote, "Voter is already verified");
        _;
    }   
    
    modifier isVoterRegistered(address voterAddress){

        require(!voterMap[voterAddress].hasRegistered, "Voter is already registered");
        _;  
    }

    modifier fromGeneralElections(){

        require(msg.sender == gElect, "This can be called only from General Elections");
        _;
    }

    function registerAsVoter(string calldata _name,
        uint _age,
        bytes12 _aadharNumber,
        string memory _voterIdNumber,
        uint _ConstituencyId) public registrationOpen isVoterRegistered(address(msg.sender)) returns (string memory){

            bytes32 hashedAadhar = keccak256(abi.encodePacked(_aadharNumber));
            bytes32 hashedVoterId = keccak256(abi.encodePacked(_voterIdNumber));
            
            voter memory v = voter(primKey, _name, _age, hashedAadhar, hashedVoterId, _ConstituencyId, false, true, false);
            voterMap[address(msg.sender)] = v;
            voterIds[primKey] = address(msg.sender);

            ++primKey;
            ++voterCount;

            return "The voter is registered successfully. Now he awaits for approval";
    }

    function verifyVoters(address voterAddress, bytes12 _aadharNumber,
        string memory _voterIdNumber, bool decision) isOfficeFromSameConstituency(address(msg.sender), voterAddress) isVoterVerified(voterAddress) public returns (string memory){
            
            //For verification we using aadhar card and VoterId
            bytes32 hashedAadhar = keccak256(abi.encodePacked(_aadharNumber));
            bytes32 hashedVoterId = keccak256(abi.encodePacked(_voterIdNumber));

            voter storage v = voterMap[voterAddress];
            require(v.id > 0, "Voter not present in DB");
            require(v.aadharNumber == hashedAadhar, "Aadhar card number mismatch");
            require(v.voterIdNumber == hashedVoterId, "Voter ID number mismatch");

            if(decision){
                v.isAllowedToVote = decision;
            }
        
            return decision? "Voter Successfully verified and can vote": "Voter not registered as not following the specified rules";
    }

    //External functions (Only callable by general election contract)
    function isVoterAllowedToVote(uint _voterId) view external fromGeneralElections returns (bool){

        address voterAddress = voterIds[_voterId];
        require(voterAddress != address(0) && voterMap[voterAddress].id == _voterId, "Voter not found");

        return voterMap[voterAddress].isAllowedToVote;
    }

    function getVoterConstituency(uint _voterId) view external fromGeneralElections returns (uint){

        address voterAddress = voterIds[_voterId];
        require(voterAddress != address(0) && voterMap[voterAddress].id == _voterId, "Voter not found");

        return voterMap[voterAddress].ConstituencyId;
    }

    function hasVoterVoted(uint _voterId) view external fromGeneralElections returns (bool){

        address voterAddress = voterIds[_voterId];
        require(voterAddress != address(0) && voterMap[voterAddress].id == _voterId, "Voter not found");
        return voterMap[voterAddress].hasVoted;
    }

    function updateVoterAfterVote(uint _voterId) external fromGeneralElections{

        address voterAddress = voterIds[_voterId];
        require(voterAddress != address(0) && voterMap[voterAddress].id == _voterId, "Voter not found");
        voterMap[voterAddress].hasVoted = true;
    }

    function setGeneralElection(address _generalElection) external {
        // Check if the ElectionOfficer contract is properly connected
        require(address(e) != address(0), "ElectionOfficer not connected");
        
        // Check if the caller is the commissioner
        bool isCommissioner = e.isElecCommissionerAddress(msg.sender);
        require(isCommissioner, "Only the election Commissioner can perform this");
        
        require(gElect == address(0), "Election already set");
        gElect = _generalElection;
        electionCommission = msg.sender;
    }

    // New functions to support enhanced voting system
    function getVoterDetails(uint _voterId) external view returns (
        string memory name,
        uint age,
        uint constituencyId,
        bool hasVoted,
        bool isAllowedToVote,
        bool hasRegistered
    ) {
        address voterAddress = voterIds[_voterId];
        require(voterAddress != address(0), "Voter not found");
        
        voter memory v = voterMap[voterAddress];
        return (
            v.name,
            v.age,
            v.ConstituencyId,
            v.hasVoted,
            v.isAllowedToVote,
            v.hasRegistered
        );
    }

    function getVotersByConstituency(uint _constituencyId) external view returns (address[] memory) {
        uint count = 0;
        
        // First pass: count voters in constituency
        for (uint i = 1; i < primKey; i++) {
            address voterAddr = voterIds[i];
            if (voterAddr != address(0) && voterMap[voterAddr].ConstituencyId == _constituencyId) {
                count++;
            }
        }
        
        // Second pass: create array with voters
        address[] memory constituencyVoters = new address[](count);
        uint index = 0;
        
        for (uint i = 1; i < primKey; i++) {
            address voterAddr = voterIds[i];
            if (voterAddr != address(0) && voterMap[voterAddr].ConstituencyId == _constituencyId) {
                constituencyVoters[index] = voterAddr;
                index++;
            }
        }
        
        return constituencyVoters;
    }

    function getVoterTurnout(uint _constituencyId) external view returns (uint totalVoters, uint votedVoters) {
        uint total = 0;
        uint voted = 0;
        
        for (uint i = 1; i < primKey; i++) {
            address voterAddr = voterIds[i];
            if (voterAddr != address(0) && voterMap[voterAddr].ConstituencyId == _constituencyId) {
                total++;
                if (voterMap[voterAddr].hasVoted) {
                    voted++;
                }
            }
        }
        
        return (total, voted);
    }

    function getVoterStatistics() external view returns (
        uint totalRegistered,
        uint totalVerified,
        uint totalVoted,
        uint totalConstituencies
    ) {
        uint verified = 0;
        uint voted = 0;
        uint[] memory constituencies = new uint[](100); // Assume max 100 constituencies
        uint constituencyIndex = 0;
        uint uniqueConstituencies = 0;
        
        for (uint i = 1; i < primKey; i++) {
            address voterAddr = voterIds[i];
            if (voterAddr != address(0)) {
                if (voterMap[voterAddr].isAllowedToVote) {
                    verified++;
                }
                if (voterMap[voterAddr].hasVoted) {
                    voted++;
                }
                
                uint constituencyId = voterMap[voterAddr].ConstituencyId;
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
        
        return (voterCount, verified, voted, uniqueConstituencies);
    }

    function getAllVoters() external view returns (address[] memory) {
        address[] memory allVoters = new address[](voterCount);
        uint index = 0;
        
        for (uint i = 1; i < primKey; i++) {
            address voterAddr = voterIds[i];
            if (voterAddr != address(0)) {
                allVoters[index] = voterAddr;
                index++;
            }
        }
        
        return allVoters;
    }

    function getVoterByAddress(address _voterAddress) external view returns (
        uint id,
        string memory name,
        uint age,
        uint constituencyId,
        bool hasVoted,
        bool isAllowedToVote
    ) {
        require(voterMap[_voterAddress].id > 0, "Voter not found");
        
        voter memory v = voterMap[_voterAddress];
        return (
            v.id,
            v.name,
            v.age,
            v.ConstituencyId,
            v.hasVoted,
            v.isAllowedToVote
        );
    }

    // Emergency functions for election management
    function emergencyRemoveVoter(address _voterAddress) external {
        require(e.isElecCommissionerAddress(msg.sender), "Only Election Commissioner can perform this action");
        require(voterMap[_voterAddress].id > 0, "Voter not found");
        
        uint voterId = voterMap[_voterAddress].id;
        
        // Remove voter
        delete voterMap[_voterAddress];
        delete voterIds[voterId];
        
        voterCount--;
    }

    function updateVoterConstituency(address _voterAddress, uint _newConstituencyId) external {
        require(e.isElecOfficer(msg.sender), "Only Election Officer can perform this action");
        require(voterMap[_voterAddress].id > 0, "Voter not found");
        
        voterMap[_voterAddress].ConstituencyId = _newConstituencyId;
    }

    function getConstituencyVoterCount(uint _constituencyId) external view returns (uint) {
        uint count = 0;
        for (uint i = 1; i < primKey; i++) {
            address voterAddr = voterIds[i];
            if (voterAddr != address(0) && voterMap[voterAddr].ConstituencyId == _constituencyId) {
                count++;
            }
        }
        return count;
    }

    // Enhanced verification functions
    function bulkVerifyVoters(address[] memory _voterAddresses, bool[] memory _decisions) external {
        require(_voterAddresses.length == _decisions.length, "Arrays length mismatch");
        require(e.isElecOfficer(msg.sender), "Only Election Officer can perform this action");
        
        for (uint i = 0; i < _voterAddresses.length; i++) {
            address voterAddr = _voterAddresses[i];
            bool decision = _decisions[i];
            
            if (voterMap[voterAddr].id > 0 && !voterMap[voterAddr].isAllowedToVote) {
                voterMap[voterAddr].isAllowedToVote = decision;
            }
        }
    }

    constructor (address _ElectionOfficerAddr) {
        require(_ElectionOfficerAddr != address(0), "Invalid ElectionOfficer address");
        e = ElectionOfficer(_ElectionOfficerAddr);
    }
    
    // Function to check ElectionOfficer connection
    function getElectionOfficerAddress() external view returns (address) {
        return address(e);
    }
}