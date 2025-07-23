# Blockchain-Based Urban Planning

A decentralized system allowing citizens to participate in city development decisions through token-weighted voting, with governance tokens earned through civic participation.

## Features
- Citizen registration with governance tokens
- Proposal creation and voting system
- Token-weighted voting mechanism
- Civic activity participation rewards
- Reputation system for citizens

## Smart Contract Functions
- `register-citizen`: Register new citizen with initial tokens
- `create-proposal`: Create development proposals
- `vote-on-proposal`: Vote on proposals with tokens
- `participate-in-activity`: Earn tokens through civic participation

## Technology Stack
- Clarity Smart Contract Language
- Stacks Blockchain Platform
- Clarinet Development Framework

# Blockchain-Based Urban Planning

A decentralized system allowing citizens to participate in city development decisions through token-weighted voting, with governance tokens earned through civic participation.

## Project Overview
This smart contract enables transparent and democratic urban planning decisions by allowing citizens to:
- Participate in governance through token-weighted voting
- Earn governance tokens through civic activities
- Create and vote on development proposals
- Build reputation through consistent civic engagement

## Smart Contract Features

### Core Functions
- **Citizen Registration**: `register-citizen()` - Get initial 100 governance tokens
- **Proposal Creation**: `create-proposal()` - Submit development proposals (requires 50+ tokens)
- **Voting System**: `vote-on-proposal()` - Cast token-weighted votes
- **Civic Participation**: `participate-in-activity()` - Earn tokens through civic engagement

### Proposal Categories
- Infrastructure Development
- Zoning Changes  
- Budget Allocation
- Environmental Projects

### Token Economics
- Initial allocation: 100 tokens per citizen
- Minimum proposal requirement: 50 tokens
- Tokens earned through civic activities
- Reputation system for long-term engagement

## Technical Implementation
- Written in Clarity smart contract language
- Deployed on Stacks blockchain
- Total contract size: 295 lines
- Comprehensive error handling and access controls

## Development Setup
1. Install Clarinet: `clarinet --version`
2. Clone repository: `git clone https://github.com/amujied/Blockchain-Based-Urban-Planning.git`
3. Navigate to project: `cd Blockchain-Based-Urban-Planning`
4. Test contract: `clarinet test`
