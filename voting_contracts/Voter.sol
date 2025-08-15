// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//For voter based data model and its methods
import './Candidate.sol';
import './ElectionOfficer.sol';

contract Voter{

    uint immutable startTime = block.timestamp;
    uint immutable endTime = startTime + 1 weeks;

    ElectionOfficer e;
    ElectionOfficer.Map []  public electionOfficers;

    constructor(address _ElectionOfficerAddr){

        e = ElectionOfficer(_ElectionOfficerAddr);
        electionOfficers = e.getAllOfficers();
    }

    
    //Get a mapping of Officers and constituencies assigned
    struct voter{

        string name;
        uint age;
        bytes32 aadharNumber;
        bytes32 voterId;
        uint ConstituencyId;
        bool hasVoted;
        bool hasRegistered;
        bool isAllowedToVote; // This would be verified later by the respective Election officer
        int registeredVoteTo; //Contains the id of the candidate the voter has voted
    }

    mapping(address => voter) voterMap;
    address [] voterAddresses;

    int public voterCount = 0;

    modifier isEndTimeLapsed(){

        require(block.timestamp <= endTime && block.timestamp >= startTime, "The registration period is over");
        _;
    } 


    function registerAsVoter(string calldata name,
        uint age,
        bytes12 aadharNumber,
        string memory voterId,
        uint ConstituencyId) public returns  (string memory){

            bytes32 hashedAadhar = keccak256(abi.encodePacked(aadharNumber));
            bytes32 hashedVoterId = keccak256(abi.encodePacked(voterId));
            
            voter memory v = voter(name, age, hashedAadhar, hashedVoterId, ConstituencyId, false, false, false, -1);
            voterMap[address(msg.sender)] = v;
            voterAddresses.push(address(msg.sender));
            ++voterCount;

            return "The voter is registered successfully. Now he awaits for approval";
    }

    function verifyVoters(bytes12 aadharNumber,
        string memory voterId, bool decision) public view{

            bytes32 hashedAadhar = keccak256(abi.encodePacked(aadharNumber));
            bytes32 hashedVoterId = keccak256(abi.encodePacked(voterId));

    }
    
}