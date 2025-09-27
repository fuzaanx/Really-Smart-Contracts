// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title WorldChangerToken
 * @dev An innovative ERC-20 token contract designed for an Emissions Trading System (ETS).
 * This contract represents fungible carbon credits, allowing transparent, decentralized trading
 * to combat climate change. It includes minting controlled by an authority (e.g., government or regulator),
 * burning for compliance (e.g., offsetting emissions), pausing for emergencies, and access control
 * for secure management. This could revolutionize global carbon markets by reducing fraud, increasing
 * efficiency, and promoting environmental accountability.
 *
 * Best Practices:
 * - Inherits from OpenZeppelin contracts for security and standardization (audited code).
 * - Uses AccessControl for role-based permissions (e.g., MINTER_ROLE).
 * - Includes pausability to halt transfers in case of issues.
 * - Burnable to allow users to retire credits after use.
 * - Ownable for initial setup and renouncing ownership if needed.
 * - Error handling via custom revert messages and require statements.
 * - Decimals set to 18 for precision in fractional credits.
 * - Events for transparency and off-chain tracking.
 */
contract WorldChangerToken is ERC20, ERC20Burnable, ERC20Pausable, AccessControl, Ownable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // Custom errors for better gas efficiency and clarity
    error OnlyMinterCanMint();
    error ZeroAmountNotAllowed();
    error ContractPaused();

    /**
     * @dev Constructor to initialize the token.
     * @param initialSupply The initial supply of tokens to mint to the deployer.
     * Sets up roles and mints initial supply.
     */
    constructor(uint256 initialSupply) ERC20("WorldChanger Carbon Credit", "WCCC") Ownable(msg.sender) {
        // Grant roles to the contract deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);

        // Mint initial supply if provided
        if (initialSupply > 0) {
            _mint(msg.sender, initialSupply * 10 ** decimals());
        }
    }

    /**
     * @dev Mint new tokens, restricted to MINTER_ROLE.
     * @param to The address to mint tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        if (amount == 0) revert ZeroAmountNotAllowed();
        _mint(to, amount);
    }

    /**
     * @dev Pause the contract, restricted to PAUSER_ROLE.
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause the contract, restricted to PAUSER_ROLE.
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Override to add paused check before transfers.
     */
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Pausable) {
        if (paused()) revert ContractPaused();
        super._update(from, to, value);
    }

    /**
     * @dev decimals override for custom precision if needed (default 18).
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
}
