// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//For voter based data model and its methods
import './Candidate.sol';
import './ElectionOfficer.sol';

contract Voter{

    uint immutable startTime = block.timestamp;
    uint immutable endTime = startTime + 1 weeks;

    uint immutable electionStart = endTime + 1 weeks;
    uint immutable electionEnd = electionStart + 1 days;

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
        int registeredVoteTo; //Contains the id of the candidate the voter has voted
    }

    mapping(address => voter) voterMap;
    address [] voterAddresses;
    int public voterCount = 0;

    // From ElectionOfficer Module
    modifier registrationOpen(){

        require(block.timestamp <= endTime && block.timestamp >= startTime, "The registration period is over");
        _;
    } 

    modifier isOfficeFromSameConstituency(address officerAddress, address voterAddress){
        
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

    function registerAsVoter(uint _id, string calldata _name,
        uint _age,
        bytes12 _aadharNumber,
        string memory _voterIdNumber,
        uint _ConstituencyId) public registrationOpen returns (string memory){

            bytes32 hashedAadhar = keccak256(abi.encodePacked(_aadharNumber));
            bytes32 hashedVoterId = keccak256(abi.encodePacked(_voterIdNumber));
            
            voter memory v = voter(_id, _name, _age, hashedAadhar, hashedVoterId, _ConstituencyId, false, true, false, -1);
            voterMap[address(msg.sender)] = v;
            voterAddresses.push(address(msg.sender));
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

    constructor (address _ElectionOfficerAddr) {

        e = ElectionOfficer(_ElectionOfficerAddr);
    }
    
}