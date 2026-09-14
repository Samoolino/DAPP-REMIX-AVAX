// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IERC20Flash { function balanceOf(address account) external view returns (uint256); function approve(address spender, uint256 amount) external returns (bool); function transfer(address to, uint256 amount) external returns (bool); }
interface IAaveV3Pool { function flashLoanSimple(address receiverAddress, address asset, uint256 amount, bytes calldata params, uint16 referralCode) external; }
interface IFlashLoanSimpleReceiver { function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata params) external returns (bool); }
interface IRouterV2 { function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts); }

contract AaveV3FlashArbitrage is IFlashLoanSimpleReceiver {
    address public immutable owner;
    IAaveV3Pool public immutable pool;
    bool public paused;
    uint256 public minProfit;
    mapping(address => bool) public approvedRouters;
    event FlashLoanStarted(address indexed asset, uint256 amount);
    event FlashLoanSettled(address indexed asset, uint256 amount, uint256 premium, uint256 profit);
    event RouterApprovalChanged(address indexed router, bool approved);
    event PauseChanged(bool paused);
    event MinProfitChanged(uint256 value);
    modifier onlyOwner() { require(msg.sender == owner, "ONLY_OWNER"); _; }
    modifier onlyPool() { require(msg.sender == address(pool), "ONLY_POOL"); _; }
    constructor(address poolAddress, uint256 minimumProfit) { require(poolAddress != address(0), "POOL_ZERO"); owner = msg.sender; pool = IAaveV3Pool(poolAddress); minProfit = minimumProfit; }
    function setRouter(address router, bool approved) external onlyOwner { require(router != address(0), "ROUTER_ZERO"); approvedRouters[router] = approved; emit RouterApprovalChanged(router, approved); }
    function setPaused(bool value) external onlyOwner { paused = value; emit PauseChanged(value); }
    function setMinProfit(uint256 value) external onlyOwner { minProfit = value; emit MinProfitChanged(value); }
    function requestFlashLoan(address asset, uint256 amount, address router, uint256 minAmountOut, address[] calldata path, uint256 deadline) external onlyOwner {
        require(!paused, "PAUSED"); require(approvedRouters[router], "ROUTER_NOT_APPROVED"); require(path.length >= 2 && path[0] == asset && path[path.length - 1] == asset, "ROUND_TRIP_REQUIRED"); require(deadline >= block.timestamp, "DEADLINE_EXPIRED");
        emit FlashLoanStarted(asset, amount); pool.flashLoanSimple(address(this), asset, amount, abi.encode(router, minAmountOut, path, deadline), 0);
    }
    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata params) external override onlyPool returns (bool) {
        require(initiator == address(this), "BAD_INITIATOR");
        (address router, uint256 minAmountOut, address[] memory path, uint256 deadline) = abi.decode(params, (address, uint256, address[], uint256));
        require(approvedRouters[router], "ROUTER_NOT_APPROVED"); require(path.length >= 2 && path[0] == asset && path[path.length - 1] == asset, "ROUND_TRIP_REQUIRED"); require(deadline >= block.timestamp, "DEADLINE_EXPIRED");
        require(IERC20Flash(asset).approve(router, amount), "APPROVE_FAILED");
        IRouterV2(router).swapExactTokensForTokens(amount, minAmountOut, path, address(this), deadline);
        uint256 repayment = amount + premium; uint256 balance = IERC20Flash(asset).balanceOf(address(this));
        require(balance >= repayment + minProfit, "PROFIT_FLOOR"); require(IERC20Flash(asset).approve(address(pool), repayment), "REPAY_APPROVE_FAILED");
        emit FlashLoanSettled(asset, amount, premium, balance - repayment); return true;
    }
    function rescueToken(address token, address to, uint256 amount) external onlyOwner { require(to != address(0), "TO_ZERO"); require(IERC20Flash(token).transfer(to, amount), "TRANSFER_FAILED"); }
}
