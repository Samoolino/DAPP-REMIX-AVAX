// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IPool {
    function flashLoanSimple(address receiverAddress, address asset, uint256 amount, bytes calldata params, uint16 referralCode) external;
}

interface IFlashLoanSimpleReceiver {
    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata params) external returns (bool);
}

contract FlashLoanExample is IFlashLoanSimpleReceiver {
    address public immutable owner;
    IPool public immutable pool;
    bool public paused;

    event FlashLoanExecuted(address indexed asset, uint256 amount, uint256 premiumFee, uint256 gasUsed, int256 netYield);
    event PauseChanged(bool paused);

    modifier onlyOwner() { require(msg.sender == owner, "ONLY_OWNER"); _; }
    modifier onlyPool() { require(msg.sender == address(pool), "ONLY_POOL"); _; }

    constructor(address poolAddress) {
        require(poolAddress != address(0), "POOL_ZERO");
        owner = msg.sender;
        pool = IPool(poolAddress);
    }

    function requestFlashLoan(address asset, uint256 amount, bytes calldata params) external onlyOwner {
        require(!paused, "PAUSED");
        uint256 gasStart = gasleft();
        pool.flashLoanSimple(address(this), asset, amount, params, 0);
        uint256 gasUsed = gasStart - gasleft();
        emit FlashLoanExecuted(asset, amount, 0, gasUsed, 0);
    }

    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata) external override onlyPool returns (bool) {
        require(initiator == address(this), "BAD_INITIATOR");
        uint256 repayment = amount + premium;
        require(IERC20(asset).balanceOf(address(this)) >= repayment, "INSUFFICIENT_REPAYMENT");
        IERC20(asset).approve(address(pool), repayment);
        int256 netYield = int256(IERC20(asset).balanceOf(address(this))) - int256(repayment);
        emit FlashLoanExecuted(asset, amount, premium, 0, netYield);
        return true;
    }

    function setPaused(bool value) external onlyOwner { paused = value; emit PauseChanged(value); }
    function rescueToken(address token, address to, uint256 amount) external onlyOwner { require(IERC20(token).transfer(to, amount), "TRANSFER_FAILED"); }
}
