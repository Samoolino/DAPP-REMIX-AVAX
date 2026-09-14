// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IERC20Funded {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IRouterV2Funded {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

/// @notice Archive template for inventory-funded execution without a flashloan.
/// @dev Uses tokens already held by this contract. Profit is not guaranteed.
contract LiquidityFundedExecutor {
    address public immutable owner;
    bool public paused;
    uint256 public minProfit;
    mapping(address => bool) public approvedRouters;

    event RouteExecuted(address indexed router, address indexed tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);
    event RouterApprovalChanged(address indexed router, bool approved);
    event PauseChanged(bool paused);
    event MinProfitChanged(uint256 value);
    event InventoryDeposited(address indexed token, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    constructor(uint256 minimumProfit) {
        owner = msg.sender;
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

    function depositToken(address token, uint256 amount) external onlyOwner {
        require(token != address(0) && amount > 0, "INVALID_DEPOSIT");
        // The transfer into this contract is intentionally performed by the wallet.
        // This event records the expected inventory change after a successful transfer.
        emit InventoryDeposited(token, amount);
    }

    function executeRoute(
        address router,
        address inputToken,
        uint256 amountIn,
        uint256 minAmountOut,
        address[] calldata path,
        uint256 deadline
    ) external onlyOwner returns (uint256 amountOut) {
        require(!paused, "PAUSED");
        require(approvedRouters[router], "ROUTER_NOT_APPROVED");
        require(amountIn > 0 && path.length >= 2, "INVALID_ROUTE");
        require(path[0] == inputToken, "BAD_PATH_START");
        require(deadline >= block.timestamp, "DEADLINE_EXPIRED");
        require(IERC20Funded(inputToken).balanceOf(address(this)) >= amountIn, "INSUFFICIENT_INVENTORY");
        require(IERC20Funded(inputToken).approve(router, amountIn), "APPROVE_FAILED");

        uint256[] memory amounts = IRouterV2Funded(router).swapExactTokensForTokens(
            amountIn, minAmountOut, path, address(this), deadline
        );
        amountOut = amounts[amounts.length - 1];
        require(amountOut >= amountIn + minProfit, "PROFIT_FLOOR");
        emit RouteExecuted(router, inputToken, amountIn, path[path.length - 1], amountOut);
    }

    function withdrawToken(address token, address to, uint256 amount) external onlyOwner {
        require(to != address(0), "TO_ZERO");
        require(IERC20Funded(token).transfer(to, amount), "TRANSFER_FAILED");
    }
}
