# Blockchain-Based Electronic Voting System

A decentralized, secure, and transparent electronic voting system built on Ethereum blockchain using Solidity smart contracts.

## 🏗️ System Architecture

This voting system consists of **4 interconnected smart contracts** that work together to provide a complete electoral solution:

### Core Contracts

1. **`ElectionOfficer.sol`** - Manages election officials and commissioner
2. **`Voter.sol`** - Handles voter registration and management  
3. **`Candidate.sol`** - Manages candidate registration and verification
4. **`GeneralElections.sol`** - Orchestrates the actual voting process

### System Roles

- **Election Commissioner** - Root authority with supreme control
- **Election Officers** - Appointed officials who verify participants
- **Voters** - Verified individuals who can cast votes
- **Candidates** - Verified individuals who can contest elections

## 🚀 Features

### Security & Transparency
- **Immutable voting records** stored on blockchain
- **Public verification** of all transactions
- **Role-based access control** with strict permissions
- **Time-based restrictions** for registration and voting periods

### User Management
- **Voter verification** using Aadhar numbers (12-byte unique identifiers)
- **Candidate verification** with security deposits
- **Emergency removal** capabilities for invalid participants
- **Comprehensive data tracking** and statistics

### Voting Process
- **One vote per voter** per election
- **Constituency-based** candidate selection
- **Automatic result calculation**
- **Real-time vote counting**

## 🛠️ Technology Stack

- **Blockchain**: Ethereum
- **Smart Contracts**: Solidity 0.8.19
- **Development Framework**: Hardhat
- **Testing**: Mocha + Chai
- **JavaScript Library**: Ethers.js v6
- **Language**: JavaScript/Node.js

## 📋 Prerequisites

- Node.js (v16 or higher)
- npm or yarn package manager
- Basic understanding of Ethereum and Solidity

## 🚀 Installation & Setup

### 1. Clone the Repository
```bash
git clone <repository-url>
cd CSDL7022-Blockchain
```

### 2. Install Dependencies
```bash
npm install
```

### 3. Compile Smart Contracts
```bash
npx hardhat compile
```

### 4. Run Tests
```bash
npx hardhat test
```

## 🔧 Configuration

### Hardhat Configuration
The system uses Hardhat for development and testing:

```javascript
// hardhat.config.js
module.exports = {
  solidity: "0.8.19",
  networks: {
    hardhat: {
      chainId: 1337
    }
  },
  mocha: {
    timeout: 40000
  }
};
```

### Network Setup
- **Hardhat Network**: Default development network (chainId: 1337)
- **Local Node**: Run `npx hardhat node` for local blockchain
- **Test Networks**: Configure additional networks as needed

## 📜 Smart Contract Details

### ElectionOfficer.sol

**Purpose**: Manages election officials and commissioner authority

**Key Functions**:
- `electElectionOfficers(address[] memory _officers)` - Appoint new officers
- `isElecCommissioner()` - Check if caller is commissioner
- `isElecCommissionerAddress(address _address)` - Check if address is commissioner

**Data Structures**:
- `electionCommissioner` - Immutable commissioner address
- `isOfficer` - Mapping of officer addresses
- `officerList` - Array of all officers

### Voter.sol

**Purpose**: Handles voter registration and management

**Key Functions**:
- `registerAsVoter(bytes12 _aadharNumber, string memory _name, string memory _constituency)` - Voter registration
- `setGeneralElection(address _generalElection)` - Connect to main election contract
- `emergencyRemoveVoter(address _voterAddress)` - Remove invalid voters

**Data Structures**:
- `voter` struct: id, name, aadharNumber, constituency, isVerified, hasVoted
- `voterMap` - Mapping of address to voter data
- `voterIds` - Mapping of ID to address

### Candidate.sol

**Purpose**: Manages candidate registration and verification

**Key Functions**:
- `candidateRegistration(string memory _name, string memory _constituency, string memory _party)` - Candidate registration
- `candidateVerification(address _candidateAddress, bool _isVerified)` - Verify candidates
- `emergencyRemoveCandidate(address _candidateAddress)` - Remove invalid candidates

**Data Structures**:
- `candidate` struct: name, constituency, party, securityDeposit, isVerified, canContest
- `candidates` - Mapping of address to candidate data
- `isCandidate` - Boolean mapping for quick lookups

### GeneralElections.sol

**Purpose**: Orchestrates the voting process and calculates results

**Key Functions**:
- `castVote(address _candidateAddress)` - Record a vote
- `getElectionResults()` - Calculate and return results
- `getVoteDetails(address _voterAddress)` - Get voter's vote information

**Data Structures**:
- `vote` struct: voterAddress, candidateAddress, timestamp
- `ElectionResult` struct: candidateAddress, voteCount, constituency
- `votes` - Array of all votes cast

## 🔄 Deployment Process

### 1. Deploy Contracts
```bash
npx hardhat run deploy_voting_system.js
```

### 2. Contract Setup
The deployment script automatically:
- Deploys all 4 contracts
- Sets up inter-contract relationships
- Configures the election commissioner
- Establishes initial system state

### 3. Post-Deployment
After deployment:
- Appoint election officers using `electElectionOfficers()`
- Set up voting periods and constituencies
- Begin voter and candidate registration

## 🧪 Testing

### Test Coverage
The system includes **27 comprehensive tests** covering:

- **Contract Deployment** - Proper contract initialization
- **Access Control** - Permission verification for all functions
- **Voter Management** - Registration, verification, and removal
- **Candidate Management** - Registration, verification, and deposits
- **Voting Process** - Vote casting and validation
- **Data Retrieval** - Statistics and result calculation
- **Emergency Functions** - Administrative override capabilities

### Running Tests
```bash
# Run all tests
npx hardhat test

# Run specific test file
npx hardhat test test/test_voting_system.js

# Run with detailed output
npx hardhat test --verbose
```

### Test Structure
Tests are organized into logical suites:
- **Contract Deployment Tests**
- **Access Control Tests**
- **Voter Management Tests**
- **Candidate Management Tests**
- **Voting Process Tests**
- **Data Retrieval and Statistics Tests**
- **Emergency Functions Tests**

## 🔐 Security Features

### Access Control
- **Modifiers** ensure only authorized users can call functions
- **Role-based permissions** with clear hierarchy
- **Immutable variables** prevent tampering

### Data Integrity
- **Immutable voting records** once cast
- **Public verification** of all transactions
- **Time-based restrictions** prevent manipulation

### Financial Security
- **Security deposits** for candidates
- **Automatic refunds** for removed candidates
- **Protected payment functions**

## 📊 Usage Examples

### 1. Voter Registration
```javascript
// Register a new voter
await voter.connect(voter1).registerAsVoter(
  "0x313233343536373839303132", // Aadhar number (hex)
  "John Doe",                    // Name
  "Constituency A"               // Constituency
);
```

### 2. Candidate Registration
```javascript
// Register a new candidate
await candidate.connect(candidate1).candidateRegistration(
  "Jane Smith",                  // Name
  "Constituency A",              // Constituency
  "Democratic Party",            // Party
  { value: ethers.parseEther("1") } // Security deposit
);
```

### 3. Casting a Vote
```javascript
// Cast a vote for a candidate
await generalElections.connect(voter1).castVote(candidate1.address);
```

### 4. Getting Results
```javascript
// Get election results
const results = await generalElections.getElectionResults();
```

## 🚨 Emergency Functions

### Voter Removal
```javascript
// Emergency remove a voter (commissioner only)
await voter.connect(commissioner).emergencyRemoveVoter(voterAddress);
```

### Candidate Removal
```javascript
// Emergency remove a candidate (commissioner only)
await candidate.connect(commissioner).emergencyRemoveCandidate(candidateAddress);
```

## 🔍 Monitoring & Analytics

### Available Statistics
- **Total voters** and candidates
- **Vote counts** by constituency
- **Verification status** of participants
- **Financial deposits** and refunds
- **Voting participation** rates

### Data Access
All data is publicly accessible through view functions:
- `getVoterCount()` - Total registered voters
- `getCandidateCount()` - Total registered candidates
- `getElectionResults()` - Complete voting results
- `getVoteDetails()` - Individual vote information

## 🌐 Network Deployment

### Local Development
```bash
# Start local blockchain
npx hardhat node

# Deploy to local network
npx hardhat run deploy_voting_system.js --network localhost
```

### Test Networks
```bash
# Deploy to testnet (e.g., Sepolia)
npx hardhat run deploy_voting_system.js --network sepolia
```

### Mainnet Deployment
```bash
# Deploy to mainnet (use with caution)
npx hardhat run deploy_voting_system.js --network mainnet
```

## 🐛 Troubleshooting

### Common Issues

1. **Compilation Errors**
   - Ensure Solidity version compatibility
   - Check for syntax errors in contracts
   - Verify import statements

2. **Deployment Failures**
   - Check network configuration
   - Verify account balances
   - Ensure proper contract dependencies

3. **Test Failures**
   - Run `npx hardhat clean` and recompile
   - Check test environment setup
   - Verify contract addresses in tests

### Debug Commands
```bash
# Clean and recompile
npx hardhat clean
npx hardhat compile

# Run specific test with debugging
npx hardhat test --grep "test name"

# Check contract artifacts
npx hardhat artifacts
```

## 📚 API Reference

### Contract Functions

#### ElectionOfficer
- `electElectionOfficers(address[] memory _officers)`
- `isElecCommissioner() returns (bool)`
- `isElecCommissionerAddress(address _address) returns (bool)`

#### Voter
- `registerAsVoter(bytes12 _aadharNumber, string memory _name, string memory _constituency)`
- `setGeneralElection(address _generalElection)`
- `emergencyRemoveVoter(address _voterAddress)`

#### Candidate
- `candidateRegistration(string memory _name, string memory _constituency, string memory _party)`
- `candidateVerification(address _candidateAddress, bool _isVerified)`
- `emergencyRemoveCandidate(address _candidateAddress)`

#### GeneralElections
- `castVote(address _candidateAddress)`
- `getElectionResults() returns (ElectionResult[] memory)`
- `getVoteDetails(address _voterAddress) returns (vote memory)`

## 🤝 Contributing

### Development Workflow
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

### Code Standards
- Follow Solidity style guide
- Include comprehensive tests
- Document all public functions
- Use meaningful variable names

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Check the troubleshooting section
- Review the test files for usage examples
- Consult the Solidity documentation

## 🔮 Future Enhancements

### Planned Features
- **Multi-constituency support** with weighted voting
- **Advanced privacy** using zero-knowledge proofs
- **Mobile application** for voter interface
- **Real-time notifications** for election updates
- **Advanced analytics** and reporting tools

### Scalability Improvements
- **Layer 2 solutions** for high-volume elections
- **Batch processing** for multiple operations
- **Optimized gas usage** for cost efficiency
- **Modular contract architecture** for easy upgrades

---

**Note**: This system is designed for educational and demonstration purposes. For production use in real elections, additional security audits, legal compliance, and real-world testing are required.
