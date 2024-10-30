# Player Contracts and Tokenized Salaries System

A blockchain-based smart contract system for managing player contracts, performance-based payments, and tokenized salaries in sports. Built on the Stacks blockchain using Clarity smart contracts.

## Overview

This system provides a comprehensive solution for sports organizations to manage player contracts through blockchain technology, offering automated salary payments, performance-based incentives, and dispute resolution mechanisms.

### Key Features

- **Smart Contract Management**
  - Automated player registration
  - Salary tokenization
  - Performance tracking
  - Bonus calculations

- **Token System**
  - Custom salary tokens
  - Vesting schedules
  - Performance-based minting
  - Team bonus distribution

- **Performance Metrics**
  - Individual performance tracking
  - Team performance monitoring
  - Bonus thresholds
  - Season highlights

- **Team Management**
  - Team performance tracking
  - Bonus pool management
  - Salary cap enforcement
  - Player roster tracking

- **Dispute Resolution**
  - Automated dispute filing
  - Evidence tracking
  - Resolution voting
  - Appeal mechanism

## System Architecture

### Smart Contracts

1. **Main Contract (`player-contract-system-v2`)**
   - Core functionality for player management
   - Token minting and distribution
   - Performance tracking
   - Dispute resolution

### Data Structures

1. **Players Map**
```clarity
{
    base-salary: uint,
    contract-start: uint,
    contract-duration: uint,
    performance-score: uint,
    tokens-issued: uint,
    bonus-threshold: uint,
    team-id: (optional uint),
    vesting-schedule: {
        cliff-period: uint,
        vesting-period: uint,
        vested-amount: uint
    },
    last-claim-height: uint
}
```

2. **Performance Metrics Map**
```clarity
{
    games-played: uint,
    scores: uint,
    assists: uint,
    team-contribution: uint,
    total-performance: uint,
    season-highlights: uint
}
```

3. **Teams Map**
```clarity
{
    team-performance: uint,
    player-count: uint,
    total-salary-cap: uint,
    bonus-pool: uint
}
```

## Usage Guide

### Player Registration

To register a new player:

```clarity
(contract-call? .player-contract-system-v2 register-player-v2
    player-principal
    base-salary
    duration
    bonus-threshold
    team-id
    cliff-period
    vesting-period)
```

### Performance Updates

To update player performance:

```clarity
(contract-call? .player-contract-system-v2 update-performance-metrics
    player-principal
    games
    scores
    assists)
```

### Token Distribution

To mint salary tokens:

```clarity
(contract-call? .player-contract-system-v2 mint-salary-tokens-v2
    player-principal)
```

### Dispute Filing

To file a contract dispute:

```clarity
(contract-call? .player-contract-system-v2 file-dispute
    player-principal
    dispute-type
    evidence-hash)
```

## Security Considerations

1. **Authorization**
   - Only contract owner can perform administrative actions
   - Player-specific actions require proper authorization
   - Team management requires team admin rights

2. **Validation**
   - Salary requirements
   - Performance thresholds
   - Vesting schedule parameters
   - Dispute resolution timeframes

3. **Error Handling**
   - Comprehensive error codes
   - Input validation
   - State checks

## Development Setup

1. Install Clarity Tools:
   ```bash
   npm install -g @stacks/cli
   ```

2. Clone the repository:
   ```bash
   git clone [repository-url]
   ```

3. Deploy contracts:
   ```bash
   clarinet contract-publish [contract-name]
   ```

## Testing

Run the test suite:
```bash
clarinet test
```

Key test scenarios:
- Player registration
- Performance updates
- Token minting
- Dispute resolution
- Team management

## Contract Versions

### Version 2.0 (Current)
- Added token functionality
- Implemented vesting schedules
- Added team performance tracking
- Introduced dispute resolution
- Enhanced performance metrics

### Version 1.0
- Basic player registration
- Simple performance tracking
- Initial bonus calculations
- Basic token structure

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit changes
4. Submit pull request