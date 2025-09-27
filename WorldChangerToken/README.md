# WorldChangerToken - ERC-20 Based Carbon Credit Token for Emissions Trading System (ETS)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-^0.8.20-blue.svg)](https://soliditylang.org/)

## Introduction

WorldChangerToken (WCCC) is an innovative ERC-20 compliant smart contract designed to revolutionize global carbon markets through a decentralized Emissions Trading System (ETS). Each token represents a fungible unit of carbon credit (e.g., 1 ton of CO2 equivalent), enabling transparent trading, compliance tracking, and environmental accountability on the Ethereum blockchain.

Inspired by the ERC-20 standard from Ethereum.org and built using audited OpenZeppelin libraries, this contract facilitates:
- Regulatory minting of allowances.
- Burning for emission offsets.
- Pausing for emergency halts.
- Role-based access control to prevent unauthorized actions.

This could change the blockchain world by democratizing carbon trading, reducing fraud, and promoting sustainable practices. For more on ERC-20 fundamentals, see the [Ethereum Developer Docs](https://ethereum.org/en/developers/docs/standards/tokens/erc-20/).

## What is an ERC-20 Token?

Tokens on Ethereum can represent various assets:
- Reputation points in platforms.
- In-game skills or items.
- Financial shares or fiat currencies (e.g., USD).
- Commodities like gold.
- And more, such as carbon credits in this case.

The ERC-20 standard ensures interoperability, allowing tokens to integrate seamlessly with wallets, exchanges, and other dApps. As per OpenZeppelin docs, ERC-20 tokens are fungible—each unit is identical in type and value, like ETH itself.

## Prerequisites

- Basic understanding of Ethereum accounts and smart contracts.
- Familiarity with token standards (e.g., from "Mastering Ethereum" by Andreas M. Antonopoulos and Dr. Gavin Wood).
- Tools: Solidity compiler (>=0.8.20), Remix IDE, Hardhat, or Foundry for deployment.

## Features

- **Fungibility**: Tokens are interchangeable, ideal for carbon allowances.
- **Minting**: Restricted to `MINTER_ROLE` (e.g., regulators issue credits based on emission caps).
- **Burning**: Users burn tokens to comply with emissions, retiring them permanently.
- **Pausing**: `PAUSER_ROLE` can halt transfers during audits or crises.
- **Access Control**: Role-based permissions using OpenZeppelin's `AccessControl`.
- **Ownership**: Deployer owns initially; can transfer or renounce.
- **Decimals**: 18 for precise fractional credits (e.g., 1.5 tons).
- **Custom Errors**: For gas efficiency and clear revert messages (e.g., `OnlyMinterCanMint()`).

Example functionalities (from EIP-20):
- Transfer tokens between accounts.
- Query balances and total supply.
- Approve third-party spending.

## Installation

1. **Install Dependencies**:
   - Use npm: `npm install @openzeppelin/contracts`.

2. **Contract Code**:
   Copy the provided Solidity code into `WorldChangerToken.sol`.

3. **Compile**:
   Use Remix or Hardhat: `npx hardhat compile`.

## Deployment

Deploy via Remix, Hardhat, or ethers.js:

```javascript
const WorldChangerToken = await ethers.getContractFactory("WorldChangerToken");
const token = await WorldChangerToken.deploy(1000000); // Initial supply: 1M tokens
await token.deployed();
console.log("Deployed at:", token.address);
```

- **Constructor Argument**: `initialSupply` (uint256) - Mints to deployer if >0.
- **Gas Optimization**: Use immutable variables where possible; test on testnets like Sepolia.

After deployment:
- Grant roles: `token.grantRole(MINTER_ROLE, regulatorAddress);`.
- Verify on Etherscan for transparency.

## Usage

### Minting Tokens
```solidity
// Only minter
token.mint(recipient, 1000 * 10**18); // Mint 1000 WCCC
```

### Transferring Tokens
```solidity
token.transfer(to, 500 * 10**18); // Transfer 500 WCCC
```

### Burning Tokens
```solidity
token.burn(100 * 10**18); // Burn 100 WCCC for compliance
```

### Pausing/Unpausing
```solidity
// Only pauser
token.pause();
token.unpause();
```

### Querying
```solidity
uint balance = token.balanceOf(address);
uint supply = token.totalSupply();
```

**Note on Decimals**: Amounts are in wei-like units. To send 5 WCCC: `5 * 10**18`. Override `decimals()` if needed, but 18 is standard for precision.

For a preset with more features (e.g., minter-pauser), see OpenZeppelin's `ERC20PresetMinterPauser`.

## Best Practices

- **Security**: Inherit from audited OpenZeppelin contracts to mitigate reentrancy, overflow, etc. Always audit before mainnet (e.g., via Cyfrin or OpenZeppelin).
- **Error Handling**: Use custom errors over require for gas savings.
- **Testing**: Write tests with Foundry/Chai:
  ```javascript
  it("should mint only by minter", async () => {
    await expect(token.connect(nonMinter).mint(addr, 1)).to.be.revertedWithCustomError(token, "OnlyMinterCanMint");
  });
  ```
- **Upgradability**: Use UUPS proxies for future upgrades.
- **Compliance**: Integrate oracles (e.g., Chainlink) for real emission data. Align with legal ETS frameworks (inspired by Solana ETS thesis for scalability ideas).
- **Gas Optimization**: Minimize storage reads/writes; batch operations.
- **Documentation**: Keep README updated; use GitHub Discussions for issues.

For advanced topics, refer to "Mastering Ethereum" for dApp building or the Solana ETS thesis for cross-chain inspirations.

## License

MIT License. See [LICENSE](LICENSE) file.
