// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IERC20Minimal {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IRouterLike {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
}

contract TokenArbitrage {
    address public immutable owner;
    bool public paused;
    uint256 public minProfit;
    bool public upkeepEnabled;
    address public upkeepTarget;

    event ArbitrageExecuted(address indexed inputToken, address indexed outputToken, uint256 amountIn, uint256 amountOut, uint256 gasUsed, int256 netYield);
    event UpkeepConfigChanged(bool enabled, address target);
    event PauseChanged(bool paused);

    modifier onlyOwner() { require(msg.sender == owner, "ONLY_OWNER"); _; }

    constructor(uint256 minimumProfit) { owner = msg.sender; minProfit = minimumProfit; }

    function executeRoute(address router, address inputToken, uint256 amountIn, uint256 minAmountOut, address[] calldata path, uint256 deadline) external onlyOwner returns (uint256 amountOut) {
        require(!paused && path.length >= 2, "INVALID_STATE");
        require(path[0] == inputToken, "BAD_PATH");
        IERC20Minimal(inputToken).approve(router, amountIn);
        uint256 gasStart = gasleft();
        uint256[] memory amounts = IRouterLike(router).swapExactTokensForTokens(amountIn, minAmountOut, path, address(this), deadline);
        uint256 gasUsed = gasStart - gasleft();
        amountOut = amounts[amounts.length - 1];
        require(amountOut >= amountIn + minProfit, "PROFIT_FLOOR");
        emit ArbitrageExecuted(inputToken, path[path.length - 1], amountIn, amountOut, gasUsed, int256(amountOut) - int256(amountIn));
    }

    function checkUpkeep(bytes calldata) external view returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = upkeepEnabled && !paused && upkeepTarget != address(0);
        performData = abi.encode(upkeepTarget);
    }

    function performUpkeep(bytes calldata performData) external {
        require(upkeepEnabled && !paused, "UPKEEP_DISABLED");
        address target = abi.decode(performData, (address));
        require(target == upkeepTarget, "BAD_TARGET");
        // Deliberately no arbitrary transaction execution: the target is only a registry/configuration hook.
        emit UpkeepConfigChanged(true, target);
    }

    function setUpkeep(bool enabled, address target) external onlyOwner { upkeepEnabled = enabled; upkeepTarget = target; emit UpkeepConfigChanged(enabled, target); }
    function setMinProfit(uint256 value) external onlyOwner { minProfit = value; }
    function setPaused(bool value) external onlyOwner { paused = value; emit PauseChanged(value); }
    function rescueToken(address token, address to, uint256 amount) external onlyOwner { require(IERC20Minimal(token).transfer(to, amount), "TRANSFER_FAILED"); }
}
