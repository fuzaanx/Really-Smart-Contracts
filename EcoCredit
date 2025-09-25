// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title EcoCredit
 * @Author Mir Mohmmad Luqman // X/Twitter: @mirmohmadluqman
 * @dev ERC-20 token for carbon credits. Extends standard with minting controls, fees, and recovery.
 * Solves ERC-20 reception issues with rescue function. Inspired by ethereum.org ERC-20 docs.
 * Roles: DEFAULT_ADMIN_ROLE (deployer), VERIFIER_ROLE (minting), PAUSER_ROLE (pausing).
 */
contract EcoCredit is ERC20, ERC20Burnable, Pausable, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 public constant FEE_BASIS_POINTS = 10; // 0.1% fee (10 / 10000)
    address public treasury; // Funds green projects

    event CreditsMinted(address indexed to, uint256 amount, string verificationId);
    event FeeCollected(address indexed from, uint256 feeAmount);
    event TokensRescued(address indexed token, address indexed to, uint256 amount);

    error InsufficientBalance(uint256 available, uint256 required);
    error InvalidRecipient(address recipient);
    error UnauthorizedMint();

    /**
     * @dev Constructor: Sets name/symbol, mints initial supply to deployer, grants roles.
     * @param initialSupply Initial credits (in wei, e.g., 1e18 for 1 ton).
     * @param _treasury Address for fee collection.
     */
    constructor(uint256 initialSupply, address _treasury) ERC20("EcoCredit", "ECO") {
        if (_treasury == address(0)) revert InvalidRecipient(_treasury);
        treasury = _treasury;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(VERIFIER_ROLE, msg.sender); // Deployer starts as verifier
        _grantRole(PAUSER_ROLE, msg.sender);

        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Mint new credits (only verifiers). Requires verificationId for auditability.
     * Best Practice: Integrate with oracle (e.g., Chainlink) for off-chain verification.
     */
    function mint(address to, uint256 amount, string calldata verificationId) external onlyRole(VERIFIER_ROLE) {
        if (to == address(0)) revert InvalidRecipient(to);
        if (bytes(verificationId).length == 0) revert UnauthorizedMint(); // Enforce proof

        _mint(to, amount);
        emit CreditsMinted(to, amount, verificationId);
    }

    /**
     * @dev Override transfer: Applies fee if not burning. Pausable for emergencies.
     * Solves composability: Fees auto-fund treasury without extra txs.
     */
    function transfer(address to, uint256 amount) public override whenNotPaused returns (bool) {
        if (to == address(this)) revert InvalidRecipient(to); // Prevent self-transfer loss (ERC-20 issue fix)

        uint256 fee = (amount * FEE_BASIS_POINTS) / 10000;
        uint256 netAmount = amount - fee;

        if (balanceOf(msg.sender) < amount) revert InsufficientBalance(balanceOf(msg.sender), amount);

        super.transfer(to, netAmount);
        if (fee > 0) {
            super.transfer(treasury, fee);
            emit FeeCollected(msg.sender, fee);
        }

        return true;
    }

    /**
     * @dev Rescue stuck ERC-20 tokens (including this one) sent accidentally.
     * Admin-only. Solves major ERC-20 problem: ~$80M lost (per docs).
     * Best Practice: Use only for emergencies; log for transparency.
     */
    function rescueTokens(address token, address to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (to == address(0)) revert InvalidRecipient(to);
        IERC20(token).safeTransfer(to, amount);
        emit TokensRescued(token, to, amount);
    }

    /**
     * @dev Pause/unpause transfers (e.g., for upgrades or exploits).
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Update treasury (admin-only).
     */
    function setTreasury(address newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newTreasury == address(0)) revert InvalidRecipient(newTreasury);
        treasury = newTreasury;
    }

    // Best Practice: Override decimals if needed (default 18)
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
}
