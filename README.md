# 🎮 EscapeVerse Smart Contract

**EscapeVerse** is a blockchain-based virtual escape room game built on the Stacks blockchain using Clarity. Players solve puzzles to earn fungible tokens (ESCAPE) and collect unique NFTs as rewards.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Contract Architecture](#contract-architecture)
- [Installation](#installation)
- [Usage](#usage)
- [Functions Reference](#functions-reference)
- [Testing](#testing)
- [Deployment](#deployment)
- [Security Considerations](#security-considerations)

## 🎯 Overview

EscapeVerse creates an immersive gaming experience where players navigate through virtual escape rooms, solve cryptographic puzzles, and earn rewards. The smart contract handles room creation, puzzle verification, reward distribution, and player progress tracking entirely on-chain.

### Key Components

- **Fungible Tokens (ESCAPE)**: In-game currency earned by completing rooms
- **NFTs**: Unique collectibles awarded for special achievements
- **Escape Rooms**: Puzzle challenges with varying difficulty levels
- **Player Stats**: Comprehensive tracking of player achievements

## ✨ Features

### For Players

- 🧩 Solve engaging escape room puzzles
- 💰 Earn ESCAPE tokens for each completed room
- 🎨 Collect unique NFTs with metadata
- 📊 Track your progress and statistics
- 🏆 Compete on leaderboards (off-chain integration ready)

### For Administrators

- 🏗️ Create custom escape rooms
- ⚙️ Configure difficulty levels and rewards
- 🔒 Enable/disable rooms dynamically
- 🎁 Update reward structures
- 📈 Monitor player engagement

## 🏗️ Contract Architecture

### Data Structures

#### Fungible Token
```clarity
(define-fungible-token escape-token)
```

#### Non-Fungible Token
```clarity
(define-non-fungible-token escape-nft uint)
```

#### Room Schema
```clarity
{
    name: (string-ascii 50),
    difficulty: uint,
    reward-tokens: uint,
    reward-nft: bool,
    is-active: bool,
    puzzle-hash: (buff 32)
}
```

#### Player Progress Schema
```clarity
{
    completed: bool,
    attempts: uint,
    completion-time: uint,
    nft-claimed: bool
}
```

#### Player Stats Schema
```clarity
{
    total-rooms-completed: uint,
    total-tokens-earned: uint,
    total-nfts-earned: uint
}
```

## 🚀 Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Clarity development environment
- [Stacks CLI](https://docs.stacks.co/docs/command-line-interface) (optional)

### Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/escapeverse.git
cd escapeverse
```

2. Initialize Clarinet project:
```bash
clarinet new escapeverse
cd escapeverse
```

3. Add the contract:
```bash
# Copy EscapeVerse.clar to contracts/
cp path/to/EscapeVerse.clar contracts/
```

4. Update `Clarinet.toml`:
```toml
[project]
name = "escapeverse"

[contracts.escapeverse]
path = "contracts/EscapeVerse.clar"
```

## 💻 Usage

### Initialize Contract

```clarity
(contract-call? .escapeverse initialize)
```

### Create an Escape Room (Admin Only)

```clarity
(contract-call? .escapeverse create-room 
    "The Crypto Vault"           ;; Room name
    u5                            ;; Difficulty (1-10)
    u1000                         ;; Token reward
    true                          ;; NFT reward enabled
    0x1234...                     ;; SHA256 hash of answer
)
```

### Solve a Puzzle (Player)

```clarity
(contract-call? .escapeverse solve-puzzle 
    u1                            ;; Room ID
    0xabcd...                     ;; SHA256 hash of your answer
)
```

### Claim NFT Reward (Player)

```clarity
(contract-call? .escapeverse claim-nft-reward u1)
```

### Check Player Stats

```clarity
(contract-call? .escapeverse get-player-stats 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

## 📚 Functions Reference

### Read-Only Functions

| Function | Parameters | Returns | Description |
|----------|------------|---------|-------------|
| `get-token-name` | None | `(string-ascii 32)` | Returns token name |
| `get-token-symbol` | None | `(string-ascii 10)` | Returns token symbol |
| `get-balance` | `principal` | `uint` | Returns token balance |
| `get-room` | `uint` | `room-data` | Returns room details |
| `get-player-progress` | `principal, uint` | `progress-data` | Returns player's room progress |
| `get-player-stats` | `principal` | `stats-data` | Returns player statistics |
| `get-nft-metadata` | `uint` | `metadata` | Returns NFT metadata |
| `get-total-rooms` | None | `uint` | Returns total number of rooms |

### Public Functions

#### Player Functions

**`solve-puzzle`**
- Parameters: `room-id (uint)`, `answer (buff 32)`
- Awards tokens and marks room as completed
- Returns: `(response bool uint)`

**`claim-nft-reward`**
- Parameters: `room-id (uint)`
- Mints NFT for completed room
- Returns: `(response uint uint)`

**`transfer`**
- Parameters: `amount (uint)`, `sender (principal)`, `recipient (principal)`
- Transfers ESCAPE tokens
- Returns: `(response bool uint)`

**`transfer-nft`**
- Parameters: `token-id (uint)`, `sender (principal)`, `recipient (principal)`
- Transfers escape room NFT
- Returns: `(response bool uint)`

#### Admin Functions

**`initialize`**
- Parameters: None
- Mints initial token supply
- Returns: `(response bool uint)`

**`create-room`**
- Parameters: `name`, `difficulty`, `reward-tokens`, `reward-nft`, `puzzle-hash`
- Creates new escape room
- Returns: `(response uint uint)`

**`toggle-room-status`**
- Parameters: `room-id (uint)`
- Enables/disables room
- Returns: `(response bool uint)`

**`update-room-rewards`**
- Parameters: `room-id (uint)`, `new-tokens (uint)`, `new-nft (bool)`
- Updates room rewards
- Returns: `(response bool uint)`

## 🧪 Testing

### Using Clarinet Console

```bash
clarinet console
```

```clarity
;; Initialize contract
(contract-call? .escapeverse initialize)

;; Create test room
(contract-call? .escapeverse create-room 
    "Test Room" 
    u1 
    u100 
    true 
    0x9c56cc51b374c3ba189210b5b35fe9b2e41e40c8a16a2a2b9fbf3e8e3b2c4c5b)

;; Attempt to solve (answer: "correct")
(contract-call? .escapeverse solve-puzzle 
    u1 
    0x9c56cc51b374c3ba189210b5b35fe9b2e41e40c8a16a2a2b9fbf3e8e3b2c4c5b)

;; Check player stats
(contract-call? .escapeverse get-player-stats tx-sender)
```

### Test Suite Example

Create `tests/escapeverse_test.ts`:

```typescript
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create and solve escape room",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const player = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('escapeverse', 'initialize', [], deployer.address),
            Tx.contractCall('escapeverse', 'create-room', [
                types.ascii("Test Room"),
                types.uint(1),
                types.uint(100),
                types.bool(true),
                types.buff(new Uint8Array(32))
            ], deployer.address),
        ]);
        
        assertEquals(block.receipts.length, 2);
        assertEquals(block.receipts[0].result, '(ok true)');
    }
});
```

Run tests:
```bash
clarinet test
```

## 🚢 Deployment

### Testnet Deployment

1. Configure your wallet in `settings/Devnet.toml`

2. Check contract:
```bash
clarinet check
```

3. Deploy to testnet:
```bash
clarinet deploy --testnet
```

### Mainnet Deployment

1. Review and audit the contract thoroughly

2. Deploy to mainnet:
```bash
clarinet deploy --mainnet
```

3. Initialize the contract:
```bash
stx call_contract_func <contract-address> escapeverse initialize
```

## 🔒 Security Considerations

### Best Practices

1. **Puzzle Hash Storage**: Puzzle answers are stored as SHA256 hashes, preventing reverse engineering
2. **Owner-Only Functions**: Critical functions are protected by owner checks
3. **Double-Claim Prevention**: Players cannot claim rewards multiple times
4. **Input Validation**: All inputs are validated before processing

### Known Limitations

- Once deployed, the contract owner cannot be changed
- Puzzle hashes cannot be updated once a room is created
- Token supply is fixed at initialization

### Audit Recommendations

- [ ] Third-party security audit
- [ ] Formal verification of critical functions
- [ ] Penetration testing
- [ ] Economic model review

## 🎮 Game Design Tips

### Creating Engaging Puzzles

1. **Progressive Difficulty**: Start with difficulty u1-u3 for beginners
2. **Balanced Rewards**: Higher difficulty = more tokens + NFT rewards
3. **Thematic Consistency**: Create puzzle chains with connected narratives
4. **Community Engagement**: Share puzzle hints through social channels

### Reward Structure Examples

| Difficulty | Token Reward | NFT | Rarity |
|------------|--------------|-----|--------|
| 1-3 (Easy) | 100-500 | Yes | Common |
| 4-6 (Medium) | 500-1000 | Yes | Uncommon |
| 7-9 (Hard) | 1000-2000 | Yes | Rare |
| 10 (Expert) | 2000+ | Yes | Legendary |

## 📖 Example Scenarios

### Scenario 1: Basic Room Creation

```clarity
;; Create "The Beginner's Challenge"
(contract-call? .escapeverse create-room 
    "The Beginner's Challenge"
    u1
    u100
    true
    (sha256 "hello"))  ;; Answer: "hello"
```

### Scenario 2: Player Journey

```clarity
;; 1. Player solves room 1
(contract-call? .escapeverse solve-puzzle u1 (sha256 "hello"))
;; Result: Receives 100 ESCAPE tokens

;; 2. Player claims NFT
(contract-call? .escapeverse claim-nft-reward u1)
;; Result: Receives NFT #1

;; 3. Check achievements
(contract-call? .escapeverse get-player-stats tx-sender)
;; Result: {total-rooms-completed: u1, total-tokens-earned: u100, total-nfts-earned: u1}
```

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 🙏 Acknowledgments

- Stacks Foundation for the Clarity language
- Hiro Systems for development tools
- The blockchain gaming community

## 🗺️ Roadmap

- [x] Core contract implementation
- [x] Token and NFT systems
- [ ] Multi-player rooms
- [ ] Time-based challenges
- [ ] Leaderboard integration
- [ ] Cross-chain bridges
- [ ] Mobile app integration
- [ ] VR/AR experience

---

**Built with ❤️ on Stacks Blockchain**