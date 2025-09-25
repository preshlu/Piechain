# Pizza Chain Empire Smart Contract

A decentralized pizza restaurant investment platform built on the Stacks blockchain. Operate pizza restaurants, invest in franchise chains, and earn profit tokens based on your restaurant performance.

## 🍕 Overview

Pizza Chain Empire allows users to:
- Invest in different types of pizza restaurant chains
- Earn passive income through profit tokens
- Manage restaurant operations during economic cycles
- Emergency bankruptcy protection during recession periods

## 📋 Contract Features

### Core Functionality
- **Fungible Token**: `pizza-profit` - The native token for earning and trading profits
- **Investment System**: Invest in restaurant chains with different risk/reward profiles
- **Profit Distribution**: Automatic profit calculation based on investment amount and time
- **Economic Cycles**: Recession mode with bankruptcy protection mechanisms

### Restaurant Chain Types
1. **Food Truck** - Low cost (4 tokens), moderate profit (80% margin)
2. **Local Shop** - Medium cost (7 tokens), good profit (115% margin)
3. **Franchise Store** - High cost (10 tokens), high profit (160% margin)

## 🚀 Getting Started

### Prerequisites
- Stacks wallet (Hiro Wallet, Xverse, etc.)
- STX tokens for transaction fees
- Basic understanding of smart contracts

### Deployment
```bash
# Install Clarinet
npm install -g @hirosystems/clarinet-cli

# Clone the repository
git clone <your-repo-url>
cd pizza-chain-empire

# Check contract syntax
clarinet check

# Run tests
clarinet test

# Deploy to testnet
clarinet deploy --testnet
```

## 📖 Contract Functions

### Public Functions

#### `launch-pizza-empire()`
- **Description**: Initialize the pizza empire with default restaurant chains
- **Access**: CEO only
- **Returns**: `(ok true)` on success
- **Initial Setup**: 
  - Mints 600,000 pizza-profit tokens to CEO
  - Creates 3 default restaurant chains

#### `open-restaurant-chain(brand-name, cost, margin)`
- **Description**: Create a new restaurant chain type
- **Parameters**:
  - `brand-name`: Chain name (max 30 characters)
  - `cost`: Investment cost (1-1000 tokens)
  - `margin`: Profit margin (1-500%)
- **Access**: CEO only
- **Returns**: `(ok new-restaurant-id)`

#### `invest-in-restaurant(restaurant-id, investment)`
- **Description**: Invest tokens in a specific restaurant chain
- **Parameters**:
  - `restaurant-id`: Target restaurant chain ID
  - `investment`: Amount of pizza-profit tokens to invest
- **Returns**: `(ok true)` on successful investment
- **Effects**: 
  - Transfers tokens to contract
  - Updates ownership records
  - Pays pending profits if reinvesting

#### `sell-restaurant-stake(restaurant-id, amount)`
- **Description**: Sell part or all of your restaurant investment
- **Parameters**:
  - `restaurant-id`: Restaurant chain ID
  - `amount`: Amount of tokens to withdraw
- **Returns**: `(ok true)` on successful sale
- **Effects**: 
  - Pays all pending profits
  - Returns invested tokens to user

#### `declare-bankruptcy(restaurant-id)`
- **Description**: Emergency exit during recession with reduced returns
- **Parameters**:
  - `restaurant-id`: Restaurant chain to exit
- **Access**: Only during recession mode
- **Returns**: `(ok recovery-amount)`
- **Fee**: 20% bankruptcy fee applied

#### `set-recession-mode(active)`
- **Description**: Toggle recession mode on/off
- **Parameters**:
  - `active`: Boolean to enable/disable recession
- **Access**: CEO only
- **Effects**: Enables/disables bankruptcy functions

### Read-Only Functions

#### `get-franchise-ownership(owner, restaurant-id)`
- **Description**: Get investment details for a specific owner and restaurant
- **Returns**: `{investment-amount: uint, last-profit-block: uint}`

#### `get-restaurant-chain-info(restaurant-id)`
- **Description**: Get detailed information about a restaurant chain
- **Returns**: Chain details including brand name, costs, and operating status

#### `get-empire-stats()`
- **Description**: Get overall empire statistics
- **Returns**: Total value, recession status, and chain count

## 💰 Profit Calculation

Profits are calculated using the formula:
```
profit = (investment × days-operating × profit-per-customer × profit-margin) / (total-chain-value × 100)
```

Where:
- `investment`: Your invested amount
- `days-operating`: Blocks since last profit collection
- `profit-per-customer`: Base profit rate (default: 6 tokens)
- `profit-margin`: Chain-specific multiplier
- `total-chain-value`: Total investments in the chain

## ⚠️ Error Codes

| Code | Error | Description |
|------|-------|-------------|
| 101 | `ERR-NOT-CEO` | Function restricted to CEO only |
| 102 | `ERR-INVALID-INVESTMENT` | Invalid investment amount |
| 103 | `ERR-NO-RESTAURANT-OWNED` | No ownership stake found |
| 104 | `ERR-RESTAURANT-CLOSED` | Restaurant chain not operating |
| 105 | `ERR-INVALID-RESTAURANT` | Restaurant ID doesn't exist |
| 106 | `ERR-INVALID-COST` | Cost outside valid range (1-1000) |
| 107 | `ERR-INVALID-MARGIN` | Margin outside valid range (1-500) |
| 108 | `ERR-EMPTY-BRAND-NAME` | Brand name cannot be empty |

## 🔒 Security Features

- **Input Validation**: All user inputs are validated before processing
- **Access Control**: Admin functions restricted to contract deployer
- **Overflow Protection**: Safe arithmetic operations
- **State Consistency**: Atomic operations prevent partial state updates
- **Emergency Exits**: Bankruptcy mechanism during economic downturns

## 🧪 Testing

```bash
# Run all tests
clarinet test

# Run specific test file
clarinet test tests/pizza_test.ts

# Coverage report
clarinet test --coverage
```

## 📊 Usage Examples

### Basic Investment Flow
1. Deploy contract and launch empire
2. Invest in a restaurant chain: `(contract-call? .pizza-chain invest-in-restaurant u0 u100)`
3. Wait for profits to accumulate (based on block height)
4. Sell stake: `(contract-call? .pizza-chain sell-restaurant-stake u0 u50)`

### Advanced Operations
1. Create custom restaurant chain (CEO only)
2. Monitor empire statistics
3. Use bankruptcy protection during recessions
