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

    struct ElectionResult {
        uint constituencyId;
        address[] candidateAddresses;
        uint[] voteCounts;
        address[] winners;
        bool isResultDeclared;
        uint declarationTime;
    }

    Voter v;
    Candidate c;
    ElectionOfficer e;

    uint public immutable electionStart = block.timestamp + 10 minutes;
    uint public immutable electionEnd = block.timestamp + 15 minutes;

    uint public immutable bufferStart = block.timestamp + 17 minutes;
    uint public immutable bufferEnd = block.timestamp + 22 minutes;

    uint public totalVotes = 0;
    bool public isElectionPaused = false;
    bool public isElectionCancelled = false;
    
    vote[] votes;
    mapping(uint => uint) public candidateVoteCount; // candidateId => voteCount
    mapping(uint => ElectionResult) public constituencyResults; // constituencyId => result
    mapping(uint => bytes32) public voteProofs; // voterId => vote proof hash
    mapping(bytes32 => bool) public usedProofs; // proof hash => used status
    
    event voteRegistered(string message);
    event ElectionPaused(string reason);
    event ElectionResumed();
    event ElectionCancelled(string reason);
    event ResultDeclared(uint constituencyId, address[] winners, uint[] voteCounts);
    event VoteCounted(uint candidateId, uint voteCount);
    event VoteProofGenerated(uint voterId, bytes32 proofHash);
    event VoteVerified(uint voterId, bool isValid);

    modifier electionTime(){
        require(block.timestamp >= electionStart, "The election has not started yet");
        require(block.timestamp <= electionEnd, "The election has already ended");
        require(!isElectionPaused, "Election is currently paused");
        require(!isElectionCancelled, "Election has been cancelled");
        _;
    }

    modifier onlyElectionCommissioner(){
        require(e.isElecCommissionerAddress(msg.sender), "Only Election Commissioner can perform this action");
        _;
    }

    modifier onlyElectionOfficer(){
        require(e.isElecOfficer(msg.sender), "Only Election Officer can perform this action");
        _;
    }

    modifier electionEnded(){
        require(block.timestamp > electionEnd, "Election is still ongoing");
        _;
    }

    modifier bufferPeriod(){
        require(block.timestamp >= bufferStart && block.timestamp <= bufferEnd, "Not in buffer period");
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
        
        // Update vote count for candidate
        candidateVoteCount[_candidateId]++;
        
        // Generate vote proof
        bytes32 voteProof = generateVoteProof(_voterId, _candidateId);
        voteProofs[_voterId] = voteProof;
        usedProofs[voteProof] = true;
        
        v.updateVoterAfterVote(_voterId);
        emit voteRegistered("Your vote is cast successfully. Thank you for voting");
        emit VoteCounted(_candidateId, candidateVoteCount[_candidateId]);
        emit VoteProofGenerated(_voterId, voteProof);
    }

    // Emergency pause functionality
    function pauseElection(string memory reason) external onlyElectionCommissioner {
        require(!isElectionPaused, "Election is already paused");
        isElectionPaused = true;
        emit ElectionPaused(reason);
    }

    function resumeElection() external onlyElectionCommissioner {
        require(isElectionPaused, "Election is not paused");
        require(block.timestamp <= electionEnd, "Election period has ended");
        isElectionPaused = false;
        emit ElectionResumed();
    }

    function cancelElection(string memory reason) external onlyElectionCommissioner {
        require(!isElectionCancelled, "Election is already cancelled");
        isElectionCancelled = true;
        emit ElectionCancelled(reason);
    }

    // Vote counting and results
    function getVoteCount(uint _candidateId) external view returns (uint) {
        return candidateVoteCount[_candidateId];
    }

    function getTotalVotes() external view returns (uint) {
        return totalVotes;
    }

    function getVoterTurnout(uint) external view returns (uint voterCount, uint voteCount) {
        // This would need to be implemented in Voter contract
        // For now, returning basic info
        return (0, totalVotes); // Placeholder
    }

    // Count votes for a specific constituency
    function countConstituencyVotes(uint _constituencyId) external onlyElectionOfficer bufferPeriod {
        require(!constituencyResults[_constituencyId].isResultDeclared, "Results already declared for this constituency");
        
        // Get all candidates for this constituency
        address[] memory constituencyCandidates = getCandidatesByConstituency(_constituencyId);
        uint[] memory voteCounts = new uint[](constituencyCandidates.length);
        
        // Count votes for each candidate
        for (uint i = 0; i < constituencyCandidates.length; i++) {
            uint candidateId = getCandidateIdByAddress(constituencyCandidates[i]);
            voteCounts[i] = candidateVoteCount[candidateId];
        }
        
        // Find winners (candidates with highest votes)
        address[] memory winners = findWinners(constituencyCandidates, voteCounts);
        
        // Store results
        constituencyResults[_constituencyId] = ElectionResult({
            constituencyId: _constituencyId,
            candidateAddresses: constituencyCandidates,
            voteCounts: voteCounts,
            winners: winners,
            isResultDeclared: true,
            declarationTime: block.timestamp
        });
        
        emit ResultDeclared(_constituencyId, winners, voteCounts);
    }

    // Get election results for a constituency
    function getElectionResults(uint _constituencyId) external view returns (
        address[] memory candidateAddresses,
        uint[] memory voteCounts,
        address[] memory winners,
        bool isResultDeclared,
        uint declarationTime
    ) {
        ElectionResult memory result = constituencyResults[_constituencyId];
        return (
            result.candidateAddresses,
            result.voteCounts,
            result.winners,
            result.isResultDeclared,
            result.declarationTime
        );
    }

    // Helper function to find winners
    function findWinners(address[] memory candidates, uint[] memory voteCounts) internal pure returns (address[] memory) {
        if (candidates.length == 0) return new address[](0);
        
        uint maxVotes = 0;
        uint winnerCount = 0;
        
        // Find maximum votes
        for (uint i = 0; i < voteCounts.length; i++) {
            if (voteCounts[i] > maxVotes) {
                maxVotes = voteCounts[i];
            }
        }
        
        // Count winners
        for (uint i = 0; i < voteCounts.length; i++) {
            if (voteCounts[i] == maxVotes) {
                winnerCount++;
            }
        }
        
        // Create winners array
        address[] memory winners = new address[](winnerCount);
        uint winnerIndex = 0;
        
        for (uint i = 0; i < voteCounts.length; i++) {
            if (voteCounts[i] == maxVotes) {
                winners[winnerIndex] = candidates[i];
                winnerIndex++;
            }
        }
        
        return winners;
    }

    // Helper functions using Candidate contract
    function getCandidatesByConstituency(uint _constituencyId) internal view returns (address[] memory) {
        return c.getCandidatesByConstituency(_constituencyId);
    }

    function getCandidateIdByAddress(address _candidateAddress) internal view returns (uint) {
        return c.getCandidateIdByAddress(_candidateAddress);
    }

    // Get election status
    function getElectionStatus() external view returns (
        bool isActive,
        bool isPaused,
        bool isCancelled,
        uint timeRemaining,
        uint totalVotesCast
    ) {
        bool active = block.timestamp >= electionStart && block.timestamp <= electionEnd && !isElectionPaused && !isElectionCancelled;
        uint remaining = 0;
        
        if (active) {
            remaining = electionEnd > block.timestamp ? electionEnd - block.timestamp : 0;
        }
        
        return (active, isElectionPaused, isElectionCancelled, remaining, totalVotes);
    }

    // Vote verification and audit functions
    function generateVoteProof(uint _voterId, uint _candidateId) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(_voterId, _candidateId, block.timestamp));
    }

    function verifyVote(uint _voterId, uint, bytes32 _proof) external view returns (bool) {
        return voteProofs[_voterId] == _proof && usedProofs[_proof];
    }

    function getVoteProof(uint _voterId) external view returns (bytes32) {
        return voteProofs[_voterId];
    }

    function getVoteDetails(uint _voterId) external view returns (
        uint candidateId,
        uint timestamp,
        bytes32 proof
    ) {
        require(_voterId < votes.length, "Vote not found");
        vote memory voteData = votes[_voterId];
        return (voteData.candidateId, voteData.timeStamp, voteProofs[voteData.voterId]);
    }

    function getAllVotes() external view returns (
        uint[] memory voterIds,
        uint[] memory candidateIds,
        uint[] memory timestamps
    ) {
        uint[] memory vIds = new uint[](votes.length);
        uint[] memory cIds = new uint[](votes.length);
        uint[] memory times = new uint[](votes.length);
        
        for (uint i = 0; i < votes.length; i++) {
            vIds[i] = votes[i].voterId;
            cIds[i] = votes[i].candidateId;
            times[i] = votes[i].timeStamp;
        }
        
        return (vIds, cIds, times);
    }

    constructor(address _candidate, address _voter, address _electionOfficer){
        c = Candidate(_candidate);
        v = Voter(_voter);
        e = ElectionOfficer(_electionOfficer);
    }
}