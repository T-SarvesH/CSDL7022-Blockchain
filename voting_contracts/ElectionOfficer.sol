// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ElectionOfficer{

    //Timestart and Timeend for a limited registration window
    uint immutable timeStart = block.timestamp;
    uint immutable timeEnd = timeStart + 3 days;

    struct electionOfficer{

        string name;
        uint id;
        uint allotedConstituency;
    }

    struct Map{

        address mapper;
        electionOfficer e;
    }

    
    //All important members 

    //Set to 1 as electionCommissioner has to be there
    uint electionOfficerCount = 0;
    bool isElecCommssionerSet = false;

    address public immutable electionCommissioner;
    Map [] electionOfficers;

    modifier isElecComsnrSet(){

        require(isElecCommssionerSet==false, "The Election Commissioner is already elected");
        _;
    }

    modifier isElecComsnr(){

        require(msg.sender == electionCommissioner, "Only the Election Commissioner can elect the new officers");
        _;
    }

    modifier isTimeElapsed(){

        require(block.timestamp <= timeEnd && block.timestamp >= timeStart, "The Time for registering new officers has elapsed");
        _;
    }
    
    function electElectionOfficers(string calldata name, uint id, uint allotedConstituency, address Officer) public isElecComsnr isTimeElapsed returns (string memory){

        electionOfficer memory eo = electionOfficer(name, id, allotedConstituency);
        Map memory M = Map(Officer, eo);
        electionOfficers.push(M);
        ++electionOfficerCount;
        return "The election officer is now successfully assigned";
    }

    function getOfficerByAddress(address officerAddress) public view returns (electionOfficer memory){

        for(uint i=0; i<electionOfficers.length; ++i){

            if(electionOfficers[i].mapper == officerAddress)
            return electionOfficers[i].e;
        }
        
    }

    constructor () {

        isElecCommssionerSet = true;
        electionCommissioner = address(msg.sender);
    }
}