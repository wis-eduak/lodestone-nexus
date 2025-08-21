# LodeStone Nexus

> **Bitcoin-Anchored NFT Engine with Staking & Governance**

A secure, production-ready NFT primitive for tokenized real-world assets on Stacks, featuring comprehensive staking mechanics and governance token rewards that settle to Bitcoin.

[![Clarity](https://img.shields.io/badge/Clarity-3.0-blue)](https://clarity-lang.org/)
[![Stacks](https://img.shields.io/badge/Stacks-Blockchain-orange)](https://stacks.co/)
[![License](https://img.shields.io/badge/License-ISC-green.svg)](LICENSE)

## Overview

LodeStone Nexus provides a sophisticated framework for creating and managing asset-backed NFTs that leverage Bitcoin's security through the Stacks blockchain. The contract implements a complete lifecycle management system including minting, transferring, staking, and governance participation.

### Key Features

- **🔒 Bitcoin-Anchored Security**: Leverages Stacks' Bitcoin settlement for ultimate security
- **💎 Asset-Backed NFTs**: Support for tokenizing real-world assets with metadata validation
- **🎯 Staking Mechanism**: Time-based reward accrual system for locked NFTs
- **🏛️ Governance Integration**: Proportional governance token distribution based on asset value and stake duration
- **🛡️ Comprehensive Security**: Rigorous input validation, owner authorization, and state management
- **📊 Rich Metadata**: Detailed asset tracking with type classification and value attribution

## Architecture

### System Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Real World    │    │   LodeStone     │    │     Bitcoin     │
│     Assets      │◄──►│     Nexus       │◄──►│   Settlement    │
│                 │    │   (Stacks)      │    │     Layer       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   Governance    │
                    │     Tokens      │
                    └─────────────────┘
```

### Contract Architecture

The LodeStone Nexus contract is structured around three core components:

#### 1. **NFT Core** (`bitcoin-backed-nft`)

- Non-fungible token primitive with 32-byte buffer identifiers
- Immutable token definition with Clarity 3.0 compliance
- Standard NFT operations with enhanced metadata support

#### 2. **Storage Layer**

```clarity
nft-metadata      → Core asset information and ownership tracking
nft-staking       → Staking state and block height tracking  
governance-tokens → User governance token balances
```

#### 3. **Validation Framework**

- Token ID validation (non-empty, length constraints)
- Asset type validation (UTF-8 string, 1-50 characters)
- Asset value validation (positive integer, max 1M units)

### Data Flow

#### Minting Flow

```
Asset Data Input → Validation → NFT Creation → Metadata Storage → Token Assignment
```

#### Staking Flow

```
NFT Selection → Ownership Verification → Staking Lock → Reward Accrual Start → State Update
```

#### Unstaking Flow

```
Unlock Request → Time Calculation → Reward Computation → Governance Credit → NFT Release
```

## Smart Contract API

### Public Functions

#### `mint-nft`

Creates a new asset-backed NFT with validated metadata.

**Parameters:**

- `token-id` (buff 32): Unique identifier for the NFT
- `asset-type` (string-utf8 50): Classification of the underlying asset
- `asset-value` (uint): Numeric value representing asset worth

**Returns:** `(response (buff 32) uint)`

#### `transfer-nft`

Transfers NFT ownership between principals (blocked if staked).

**Parameters:**

- `token-id` (buff 32): NFT identifier
- `sender` (principal): Current owner
- `recipient` (principal): New owner

**Returns:** `(response bool uint)`

#### `stake-nft`

Locks NFT to begin governance reward accrual.

**Parameters:**

- `token-id` (buff 32): NFT to stake

**Returns:** `(response bool uint)`

#### `unstake-nft`

Releases staked NFT and credits proportional governance rewards.

**Formula:** `reward = (asset-value × staked-blocks) ÷ 10000`

**Parameters:**

- `token-id` (buff 32): Staked NFT identifier

**Returns:** `(response uint uint)` - Calculated reward amount

#### `burn-nft`

Permanently destroys an unstaked NFT.

**Parameters:**

- `token-id` (buff 32): NFT to destroy

**Returns:** `(response bool uint)`

#### `redeem-governance-tokens`

Withdraws accumulated governance token balance.

**Returns:** `(response uint uint)` - Redeemed token amount

### Read-Only Functions

#### `get-nft-metadata`

Retrieves comprehensive NFT information.

**Parameters:**

- `token-id` (buff 32): NFT identifier

**Returns:** Optional metadata record

#### `get-governance-tokens`

Queries user's governance token balance.

**Parameters:**

- `user` (principal): Account to query

**Returns:** `uint` - Current balance

### Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u1 | `ERR-UNAUTHORIZED` | Insufficient permissions |
| u2 | `ERR-NOT-FOUND` | NFT does not exist |
| u3 | `ERR-ALREADY-MINTED` | Token ID already in use |
| u4 | `ERR-INVALID-TRANSFER` | Transfer preconditions not met |
| u5 | `ERR-STAKING-ERROR` | Staking operation failed |
| u6 | `ERR-INSUFFICIENT-BALANCE` | Insufficient governance tokens |
| u7 | `ERR-INVALID-INPUT` | Invalid parameter values |
| u8 | `ERR-INVALID-TOKEN` | Malformed token identifier |

## Development Setup

### Prerequisites

- [Clarinet CLI](https://github.com/hirosystems/clarinet) >= 2.0
- [Node.js](https://nodejs.org/) >= 18.0
- [Git](https://git-scm.com/)

### Installation

```bash
# Clone the repository
git clone https://github.com/wis-eduak/lodestone-nexus.git
cd lodestone-nexus

# Install dependencies
npm install

# Verify contract syntax
clarinet check

# Run test suite
npm test
```

### Project Structure

```
lodestone-nexus/
├── contracts/
│   └── lodestone-nexus.clar      # Main contract implementation
├── tests/
│   └── lodestone-nexus.test.ts   # Comprehensive test suite
├── settings/
│   ├── Devnet.toml              # Development network config
│   ├── Testnet.toml             # Testnet configuration
│   └── Mainnet.toml             # Production network config
├── Clarinet.toml                # Project configuration
├── package.json                 # Dependencies and scripts
└── README.md                    # This file
```

## Testing

Run the comprehensive test suite to validate contract functionality:

```bash
# Execute all tests
npm test

# Run with coverage report
npm run test:report

# Watch mode for development
npm run test:watch

# Check contract validity
clarinet check
```

## Deployment

### Network Configurations

The contract includes configurations for multiple Stacks networks:

- **Devnet**: Local development and testing
- **Testnet**: Public testing environment
- **Mainnet**: Production Bitcoin-anchored deployment

### Deployment Commands

```bash
# Deploy to testnet
clarinet integrate

# Deploy to mainnet (requires setup)
clarinet deploy --network mainnet
```

## Security Considerations

### Access Control

- Owner-only functions enforce `tx-sender` verification
- Multi-layered authorization checks prevent unauthorized operations
- State consistency maintained through atomic operations

### Input Validation

- Comprehensive parameter validation for all public functions
- Buffer length constraints prevent overflow attacks
- Numeric bounds checking for asset values

### Staking Security

- Staked NFTs cannot be transferred or burned
- Reward calculations use safe arithmetic operations
- State transitions are atomic and reversible

### Best Practices

- Follow principle of least privilege
- Validate all inputs at function boundaries
- Use explicit error handling with descriptive codes
- Maintain consistent state across operations

## Contributing

We welcome contributions to improve LodeStone Nexus:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Guidelines

- Follow Clarity best practices and conventions
- Maintain comprehensive test coverage
- Include detailed documentation for new features
- Ensure backward compatibility when possible

## License

This project is licensed under the ISC License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- **Stacks Foundation** for the robust blockchain infrastructure
- **Clarity Language** team for the secure smart contract platform
- **Bitcoin Community** for the foundational security model
