// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ElectionOfficer{

    //Timestart and Timeend for a limited registration window (Will not change even if multiple contract instances are deployed)
    uint immutable timeStart = block.timestamp;
    uint immutable timeEnd = block.timestamp + 10 minutes;

    uint immutable electionStart = block.timestamp + 10 minutes;
    uint immutable electionEnd = block.timestamp + 15 minutes;

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
    
    uint public electionOfficerCount = 0;
    uint public primKey = 1;

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

    function isElecCommissioner() public view returns (bool){
        return msg.sender == electionCommissioner;
    }
    
    function isElecCommissionerAddress(address _address) public view returns (bool){
        return _address == electionCommissioner;
    }
    
    function getCommissionerAddress() public view returns (address){
        return electionCommissioner;
    }

    function isElecOfficer(address officerAddress) public view returns (bool){

        return isOfficer[officerAddress];
    }
    
    //Elect election officers (Permission: Election Commissioner)
    function electElectionOfficers(address officerAddress, string calldata name, uint allotedConstituency) public onlyElectionCommissioner registrationOpen{

        require(allotedConstituency > 0, "Constituency must be positive");
        require(!constituencyMapping[allotedConstituency], "This constituency already has a officer alloted");
        require(!isOfficer[officerAddress], "This officer is already elected");

        electionOfficer memory eo = electionOfficer(name, primKey++, allotedConstituency);
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