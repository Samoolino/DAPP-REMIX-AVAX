// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20Pangolin {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IPangolinPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
}

interface IRouterV2Pangolin {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

/// @title Pangolin Two-Router Flash-Swap Arbitrage
/// @notice Controlled-test template for a Pangolin/V2-style pair flash swap followed
///         by two allowlisted router swaps and same-token repayment.
/// @dev This contract is NOT mainnet-ready until the configured pair's callback,
///      fee model, token addresses and router interfaces are independently verified.
contract PangolinTwoRouterArbitrage {
    address public immutable owner;
    IPangolinPair public immutable pair;
    bool public paused;
    uint256 public minProfit;

    mapping(address => bool) public approvedRouters;

    uint256 private activeAmount;
    address private activeAsset;

    event FlashSwapStarted(address indexed asset, uint256 amount, address routerA, address routerB);
    event FlashSwapSettled(address indexed asset, uint256 amount, uint256 fee, uint256 profit);
    event RouterApprovalChanged(address indexed router, bool approved);
    event PauseChanged(bool paused);
    event MinProfitChanged(uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    constructor(address pairAddress, uint256 minimumProfit) {
        require(pairAddress != address(0), "PAIR_ZERO");
        owner = msg.sender;
        pair = IPangolinPair(pairAddress);
        minProfit = minimumProfit;
    }

    function setRouter(address router, bool approved) external onlyOwner {
        require(router != address(0), "ROUTER_ZERO");
        approvedRouters[router] = approved;
        emit RouterApprovalChanged(router, approved);
    }

    function setPaused(bool value) external onlyOwner {
        paused = value;
        emit PauseChanged(value);
    }

    function setMinProfit(uint256 value) external onlyOwner {
        minProfit = value;
        emit MinProfitChanged(value);
    }

    /// @notice Start a V2-style pair flash swap and execute a two-router round trip.
    /// @param asset Token borrowed from the configured pair.
    /// @param amount Amount borrowed.
    /// @param routerA First approved router.
    /// @param routerB Second approved router.
    /// @param minOutA Minimum output from the first swap.
    /// @param minOutB Minimum output from the second swap, denominated in the borrowed asset.
    /// @param pathA Swap path from borrowed asset to intermediate asset.
    /// @param pathB Swap path from intermediate asset back to borrowed asset.
    /// @param deadline Shared swap deadline.
    function flashSwap(
        address asset,
        uint256 amount,
        address routerA,
        address routerB,
        uint256 minOutA,
        uint256 minOutB,
        address[] calldata pathA,
        address[] calldata pathB,
        uint256 deadline
    ) external onlyOwner {
        require(!paused, "PAUSED");
        require(amount > 0, "ZERO_AMOUNT");
        require(activeAmount == 0, "LOAN_ACTIVE");
        require(approvedRouters[routerA] && approvedRouters[routerB], "ROUTER_NOT_APPROVED");
        require(pathA.length >= 2 && pathB.length >= 2, "PATH_TOO_SHORT");
        require(pathA[0] == asset, "BAD_PATH_A_START");
        require(pathB[0] == pathA[pathA.length - 1], "PATH_MISMATCH");
        require(pathB[pathB.length - 1] == asset, "BAD_PATH_B_END");
        require(deadline >= block.timestamp, "DEADLINE_EXPIRED");
        require(asset == pair.token0() || asset == pair.token1(), "ASSET_NOT_IN_PAIR");

        activeAmount = amount;
        activeAsset = asset;

        bytes memory data = abi.encode(routerA, routerB, minOutA, minOutB, pathA, pathB, deadline);
        emit FlashSwapStarted(asset, amount, routerA, routerB);

        if (asset == pair.token0()) {
            pair.swap(amount, 0, address(this), data);
        } else {
            pair.swap(0, amount, address(this), data);
        }

        require(activeAmount == 0, "CALLBACK_NOT_SETTLED");
    }

    /// @notice V2/Pangolin-style flash-swap callback.
    function pangolinCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        require(!paused, "PAUSED");
        require(msg.sender == address(pair), "ONLY_PAIR");
        require(sender == address(this), "BAD_SENDER");
        require(activeAmount > 0, "NO_ACTIVE_LOAN");

        uint256 borrowed = amount0 > 0 ? amount0 : amount1;
        address asset = amount0 > 0 ? pair.token0() : pair.token1();
        require(borrowed == activeAmount && asset == activeAsset, "LOAN_MISMATCH");

        (
            address routerA,
            address routerB,
            uint256 minOutA,
            uint256 minOutB,
            address[] memory pathA,
            address[] memory pathB,
            uint256 deadline
        ) = abi.decode(data, (address, address, uint256, uint256, address[], address[], uint256));

        require(approvedRouters[routerA] && approvedRouters[routerB], "ROUTER_NOT_APPROVED");
        require(pathA.length >= 2 && pathB.length >= 2, "PATH_TOO_SHORT");
        require(pathA[0] == asset, "BAD_PATH_A_START");
        require(pathB[0] == pathA[pathA.length - 1], "PATH_MISMATCH");
        require(pathB[pathB.length - 1] == asset, "BAD_PATH_B_END");
        require(deadline >= block.timestamp, "DEADLINE_EXPIRED");

        require(IERC20Pangolin(asset).approve(routerA, borrowed), "APPROVE_A_FAILED");
        uint256[] memory first = IRouterV2Pangolin(routerA).swapExactTokensForTokens(
            borrowed,
            minOutA,
            pathA,
            address(this),
            deadline
        );
        uint256 intermediate = first[first.length - 1];

        require(IERC20Pangolin(pathB[0]).approve(routerB, intermediate), "APPROVE_B_FAILED");
        IRouterV2Pangolin(routerB).swapExactTokensForTokens(
            intermediate,
            minOutB,
            pathB,
            address(this),
            deadline
        );

        // V2-style 0.3% fee assumption. Verify the actual deployed pair before use.
        uint256 fee = (borrowed * 3) / 997 + 1;
        uint256 repayment = borrowed + fee;
        uint256 balance = IERC20Pangolin(asset).balanceOf(address(this));
        require(balance >= repayment + minProfit, "PROFIT_FLOOR");
        require(IERC20Pangolin(asset).transfer(address(pair), repayment), "REPAY_FAILED");

        uint256 profit = balance - repayment;
        activeAmount = 0;
        activeAsset = address(0);
        emit FlashSwapSettled(asset, borrowed, fee, profit);
    }

    function rescueToken(address token, address to, uint256 amount) external onlyOwner {
        require(to != address(0), "TO_ZERO");
        require(IERC20Pangolin(token).transfer(to, amount), "TRANSFER_FAILED");
    }
}
