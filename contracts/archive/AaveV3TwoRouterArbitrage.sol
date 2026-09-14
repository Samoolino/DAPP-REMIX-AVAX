// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IERC20Archive {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IAaveV3PoolArchive {
    function flashLoanSimple(address receiverAddress, address asset, uint256 amount, bytes calldata params, uint16 referralCode) external;
}

interface IRouterV2Archive {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IFlashLoanSimpleReceiverArchive {
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}

/// @notice Archive template for Aave V3 two-router round-trip arbitrage.
/// @dev Profit is NOT guaranteed. The route must prove repayment + premium + minProfit.
contract AaveV3TwoRouterArbitrage is IFlashLoanSimpleReceiverArchive {
    address public immutable owner;
    IAaveV3PoolArchive public immutable pool;
    bool public paused;
    uint256 public minProfit;
    mapping(address => bool) public approvedRouters;

    event FlashLoanStarted(address indexed asset, uint256 amount, address routerA, address routerB);
    event FlashLoanSettled(address indexed asset, uint256 amount, uint256 premium, uint256 profit);
    event RouterApprovalChanged(address indexed router, bool approved);
    event PauseChanged(bool paused);
    event MinProfitChanged(uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    modifier onlyPool() {
        require(msg.sender == address(pool), "ONLY_POOL");
        _;
    }

    constructor(address poolAddress, uint256 minimumProfit) {
        require(poolAddress != address(0), "POOL_ZERO");
        owner = msg.sender;
        pool = IAaveV3PoolArchive(poolAddress);
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

    function requestFlashLoan(
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
        require(approvedRouters[routerA] && approvedRouters[routerB], "ROUTER_NOT_APPROVED");
        require(pathA.length >= 2 && pathB.length >= 2, "PATH_TOO_SHORT");
        require(pathA[0] == asset, "BAD_PATH_A_START");
        require(pathB[0] == pathA[pathA.length - 1], "PATH_MISMATCH");
        require(pathB[pathB.length - 1] == asset, "BAD_PATH_B_END");
        require(deadline >= block.timestamp, "DEADLINE_EXPIRED");

        bytes memory params = abi.encode(routerA, routerB, minOutA, minOutB, pathA, pathB, deadline);
        emit FlashLoanStarted(asset, amount, routerA, routerB);
        pool.flashLoanSimple(address(this), asset, amount, params, 0);
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override onlyPool returns (bool) {
        require(!paused, "PAUSED");
        require(initiator == address(this), "BAD_INITIATOR");

        (
            address routerA,
            address routerB,
            uint256 minOutA,
            uint256 minOutB,
            address[] memory pathA,
            address[] memory pathB,
            uint256 deadline
        ) = abi.decode(params, (address, address, uint256, uint256, address[], address[], uint256));

        require(approvedRouters[routerA] && approvedRouters[routerB], "ROUTER_NOT_APPROVED");
        require(pathA.length >= 2 && pathB.length >= 2, "PATH_TOO_SHORT");
        require(pathA[0] == asset, "BAD_PATH_A_START");
        require(pathB[0] == pathA[pathA.length - 1], "PATH_MISMATCH");
        require(pathB[pathB.length - 1] == asset, "BAD_PATH_B_END");
        require(deadline >= block.timestamp, "DEADLINE_EXPIRED");

        require(IERC20Archive(asset).approve(routerA, amount), "APPROVE_A_FAILED");
        uint256[] memory firstAmounts = IRouterV2Archive(routerA).swapExactTokensForTokens(
            amount, minOutA, pathA, address(this), deadline
        );
        uint256 intermediateAmount = firstAmounts[firstAmounts.length - 1];

        require(IERC20Archive(pathB[0]).approve(routerB, intermediateAmount), "APPROVE_B_FAILED");
        IRouterV2Archive(routerB).swapExactTokensForTokens(
            intermediateAmount, minOutB, pathB, address(this), deadline
        );

        uint256 repayment = amount + premium;
        uint256 balance = IERC20Archive(asset).balanceOf(address(this));
        require(balance >= repayment + minProfit, "PROFIT_FLOOR");
        require(IERC20Archive(asset).approve(address(pool), repayment), "REPAY_APPROVE_FAILED");

        emit FlashLoanSettled(asset, amount, premium, balance - repayment);
        return true;
    }

    function rescueToken(address token, address to, uint256 amount) external onlyOwner {
        require(to != address(0), "TO_ZERO");
        require(IERC20Archive(token).transfer(to, amount), "TRANSFER_FAILED");
    }
}
