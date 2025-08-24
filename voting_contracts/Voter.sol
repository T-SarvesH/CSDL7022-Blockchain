// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//For voter based data model and its methods
import './ElectionOfficer.sol';

contract Voter{

    uint immutable startTime = block.timestamp;
    uint immutable endTime = startTime + 1 weeks;

    uint immutable electionStart = endTime + 1 weeks;
    uint immutable electionEnd = electionStart + 1 days;

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
        require(e.isElecCommissioner(), "Only the election Commissioner can perform this");
        require(gElect == address(0), "Election already set");
        gElect = _generalElection;
        electionCommission = msg.sender;
    }

    constructor (address _ElectionOfficerAddr) {

        e = ElectionOfficer(_ElectionOfficerAddr);
    }
    
}