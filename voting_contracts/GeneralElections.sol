// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './Voter.sol';
import './Candidate.sol';
import './ElectionOfficer.sol';

contract GeneralElections{

    struct vote{

        uint voterId;
        uint candidateId;
        uint timeStamp;
    }

    Voter v;
    Candidate c;

    uint public immutable electionStart = block.timestamp + 3 days;
    uint public immutable electionEnd = electionStart + 1 weeks;

    uint public immutable bufferStart = electionEnd + 2 days;
    uint public immutable bufferEnd = bufferStart + 1 weeks;

    uint public totalVotes=0;
    
    vote [] votes;
    event voteRegistered(string message);

    modifier electionTime(){

        require(block.timestamp >= electionStart, "The election has not started yet");
        require(block.timestamp <= electionEnd, "The election has already ended");
        _;
    }

    //The voter should be allowed to vote
    modifier verifiedVoter(uint _voterId){
        require(v.isVoterAllowedToVote(_voterId), "Following Voter is not allowed to vote");
        _;
    }

    //The candidate should be allowed to contest
    modifier verifiedCandidate(uint _candidateId){
        require(c.isCandidateAllowedToContest(_candidateId), "Following candidate not allowed to contest");
        _;
    }

    modifier alreadyVoted(uint _voterId){
        
        require(!v.hasVoterVoted(_voterId), "The voter has already voted");
        _;
    }

    //The voter and the contesting candidate should be from same constituency
    modifier sameConstituency(uint _voterId, uint _candidateId){

        require(c.getCandidateConstituency(_candidateId) == v.getVoterConstituency(_voterId), "Both entities are from different constituency");
        _;
    }
    
    function registerVote(uint _voterId, uint _candidateId) electionTime verifiedVoter(_voterId) verifiedCandidate(_candidateId) alreadyVoted(_voterId) 
    sameConstituency(_voterId, _candidateId) public {

        votes.push(vote(_voterId, _candidateId, block.timestamp));
        totalVotes++;
        v.updateVoterAfterVote(_voterId);
        emit voteRegistered("Your vote is cast successfully. Thank you for voting");
    }

    constructor(address _candidate, address _voter){

        c = Candidate(_candidate);
        v = Voter(_voter);
    }
}