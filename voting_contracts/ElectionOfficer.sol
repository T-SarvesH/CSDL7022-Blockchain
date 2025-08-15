// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ElectionOfficer{

    //Timestart and Timeend for a limited registration window (Will not change even if multiple contract instances are deployed)
    uint immutable timeStart = block.timestamp;
    uint immutable timeEnd = timeStart + 3 days;

    uint immutable electionStart = timeEnd + 1 weeks;
    uint immutable electionEnd = electionStart + 1 days;

    struct electionOfficer{

        string name;
        uint id;
        uint allotedConstituency;
    }

    //All important members 
    mapping(address => electionOfficer) Map;
    mapping (address => bool) isOfficer;
    mapping (uint => bool) constituencyMapping;

    address [] electionOfficers;
    
    uint electionOfficerCount = 0;
    address public immutable electionCommissioner;

    event OfficerAssigned(address officer, uint constituency);

    modifier onlyElectionCommissioner(){

        require(msg.sender == electionCommissioner, "Only the Election Commissioner can perform this action");
        _;
    }

    modifier registrationOpen(){

        require(block.timestamp <= timeEnd , "The Time for registering new officers has elapsed");
        _;
    }


    function isElecOfficer(address officerAddress) public view returns (bool){

        return isOfficer[officerAddress];
    }
    
    //Elect election officers (Permission: Election Commissioner)
    function electElectionOfficers(address officerAddress, string calldata name, uint id, uint allotedConstituency) public onlyElectionCommissioner registrationOpen{

        require(id > 0, "Officer ID must be positive");
        require(allotedConstituency > 0, "Constituency must be positive");
        require(!constituencyMapping[allotedConstituency], "This constituency already has a officer alloted");
        require(!isOfficer[officerAddress], "This officer is already elected");

        electionOfficer memory eo = electionOfficer(name, id, allotedConstituency);
        Map[officerAddress] = eo;
        isOfficer[officerAddress] = true;
        constituencyMapping[allotedConstituency] = true;
        electionOfficers.push(officerAddress);
        ++electionOfficerCount;

        emit OfficerAssigned(officerAddress, allotedConstituency);
    }

    //Get officer by Address
    function getOfficerByAddress(address officerAddress) public view returns (electionOfficer memory){

        bool dec = isElecOfficer(officerAddress);
        require(dec, "The address is not of a Election Officer");

        return Map[officerAddress];
    }

    constructor () {

        electionCommissioner = address(msg.sender);
    }
}