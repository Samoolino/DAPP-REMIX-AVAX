// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Minimal callback interface for an Avalanche/Pangolin-style pair.
interface IPangolinCalleeLike {
    function pangolinCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external;
}

interface IERC20Like {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IPangolinPairLike {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
}

/// @title AVAX Flash Loan Safe Adapter
/// @notice Reconstructed, auditable template derived from the supplied legacy source.
/// @dev The supplied legacy contract is NOT ported verbatim. Its opaque address decoder
///      and whole-balance transfer are intentionally excluded. This adapter only supports
///      an explicitly configured pair, explicit borrower amount, explicit repayment, and
///      an owner-authorized callback.
contract AVAXFlashLoanSafeAdapter is IPangolinCalleeLike {
    address public immutable owner;
    IPangolinPairLike public immutable pair;
    address public immutable wrappedNative;
    bool public paused;

    uint256 public minProfit;
    uint256 private activeAmount;
    address private activeAsset;
    bytes32 private activeRouteHash;

    event FlashLoanRequested(address indexed asset, uint256 amount, bytes32 routeHash);
    event FlashLoanSettled(address indexed asset, uint256 borrowed, uint256 repaid, uint256 profit);
    event Paused(bool value);

    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "PAUSED");
        _;
    }

    constructor(address pair_, address wrappedNative_, uint256 minProfit_) {
        require(pair_ != address(0) && wrappedNative_ != address(0), "ZERO_ADDRESS");
        owner = msg.sender;
        pair = IPangolinPairLike(pair_);
        wrappedNative = wrappedNative_;
        minProfit = minProfit_;
    }

    function setPaused(bool value) external onlyOwner {
        paused = value;
        emit Paused(value);
    }

    function setMinProfit(uint256 value) external onlyOwner {
        minProfit = value;
    }

    /// @notice Initiates a pair flash swap. The requested asset must be one of the pair tokens.
    /// @param asset Token to borrow from the pair.
    /// @param amount Amount to borrow.
    /// @param routeData Arbitrage data consumed by the controlled callback implementation.
    function flashLoan(address asset, uint256 amount, bytes calldata routeData)
        external
        onlyOwner
        whenNotPaused
    {
        require(asset == pair.token0() || asset == pair.token1(), "UNSUPPORTED_ASSET");
        require(amount > 0, "ZERO_AMOUNT");
        require(activeAmount == 0, "LOAN_ACTIVE");

        activeAmount = amount;
        activeAsset = asset;
        activeRouteHash = keccak256(routeData);

        if (asset == pair.token0()) {
            pair.swap(amount, 0, address(this), routeData);
        } else {
            pair.swap(0, amount, address(this), routeData);
        }

        require(activeAmount == 0, "CALLBACK_NOT_SETTLED");
    }

    /// @dev Pangolin-style flash-swap callback. No arbitrary recipient is decoded from data.
    function pangolinCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata
    ) external override whenNotPaused {
        require(msg.sender == address(pair), "UNTRUSTED_PAIR");
        require(sender == address(this), "BAD_SENDER");
        require(activeAmount > 0, "NO_ACTIVE_LOAN");

        uint256 borrowed = amount0 > 0 ? amount0 : amount1;
        require(borrowed == activeAmount, "AMOUNT_MISMATCH");
        require(activeAsset == (amount0 > 0 ? pair.token0() : pair.token1()), "ASSET_MISMATCH");

        // Strategy execution is intentionally explicit and externalized. This base adapter
        // does not perform opaque self-arbitrage or invent a DEX route.
        uint256 fee = _pairFee(borrowed);
        uint256 repayment = borrowed + fee;
        uint256 balance = IERC20Like(activeAsset).balanceOf(address(this));
        require(balance >= repayment + minProfit, "INSUFFICIENT_REPAYMENT_PROFIT");

        require(IERC20Like(activeAsset).transfer(address(pair), repayment), "REPAY_FAILED");

        uint256 profit = balance - repayment;
        bytes32 routeHash = activeRouteHash;
        activeAmount = 0;
        activeAsset = address(0);
        activeRouteHash = bytes32(0);

        emit FlashLoanSettled(msg.sender, borrowed, repayment, profit);
        emit FlashLoanRequested(address(0), 0, routeHash);
    }

    function _pairFee(uint256 amount) internal pure returns (uint256) {
        // Pangolin V2-style pairs commonly use a 0.3% fee. This value MUST be verified
        // against the deployed pair implementation before any controlled execution.
        return (amount * 3) / 997 + 1;
    }

    function rescueToken(address token, address to, uint256 amount) external onlyOwner {
        require(to != address(0), "ZERO_RECIPIENT");
        require(IERC20Like(token).transfer(to, amount), "RESCUE_FAILED");
    }
}
