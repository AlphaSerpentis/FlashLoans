// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract FlashLoan {
    
    address public AAVE_LENDINGPOOL;
    address public USDC_ADDRESS;
    address public OTOKEN_UNISWAP;
    address public UNDERLYING_UNISWAP;
    address public immutable owner;
    
    constructor(
        address _AAVE_LENDINGPOOL,
        address _USDC,
        address _OTOKEN_UNISWAP,
        address _UNDERLYING_UNISWAP
    ) {
        owner = msg.sender;
        AAVE_LENDINGPOOL = _AAVE_LENDINGPOOL;
        USDC_ADDRESS = _USDC;
        OTOKEN_UNISWAP = _OTOKEN_UNISWAP;
        UNDERLYING_UNISWAP = _UNDERLYING_UNISWAP;
    }
    
    modifier onlyOwner {
        _onlyOwner();
        _;
    }
    
    function goodbye() external onlyOwner {
        selfdestruct(payable(owner));
    }
    function changeAaveLendingPool(address _lendingPool) external onlyOwner {
        AAVE_LENDINGPOOL = _lendingPool;
    }
    function changeOTokenUniswap(address _exchange) external onlyOwner {
        OTOKEN_UNISWAP = _exchange;
    }
    function changeUnderlyingUniswap(address _exchange) external onlyOwner {
        UNDERLYING_UNISWAP = _exchange;
    }
    function execute(
        uint256 _borrowEth,
        address _oToken,
        address _optionsContract,
        address _underlying,
        address[] memory _vaults,
        uint256 _oTokenAmt,
        uint256 _exerciseAmt
    ) external onlyOwner {
        uint256 initialBalance = address(this).balance;
        
        borrowFlashLoan(_borrowEth);
        buyOTokens(_oToken, _oTokenAmt);
        exercise(_optionsContract, _oToken, _exerciseAmt, _vaults);
        sellUnderlying(_underlying);
        
        uint256 newBalance = address(this).balance;
        require(
            newBalance >= initialBalance,
            "Cannot repay flash loan!"
        );
        
        repayFlashLoan();
        
        payable(owner).transfer(address(this).balance);
    }
    function borrowFlashLoan(uint256 _borrowEth) internal {
        (bool result,) = AAVE_LENDINGPOOL.call(
            abi.encodeWithSignature(
                ("flashLoan(address,address[],uint256[],uint256[],address,bytes,uint16)"),
                address(this)
                
            )
        );
    }
    function buyOTokens(
        address _oToken,
        uint256 _oTokenAmt
    ) internal {
        // Perform swap
        
        
    }
    function exercise(
        address _optionsContract,
        address _oToken,
        uint256 _exerciseAmt,
        address[] memory _vaults
    ) internal {
        // Approve use
        IERC20 token = IERC20(_oToken);
        token.approve(_optionsContract, _exerciseAmt);
        
        // Perform exercise
        (bool result,) = _optionsContract.call(
            abi.encodeWithSignature(
                ("exercise(uint256,address[])"),
                _exerciseAmt,
                _vaults
            )
        );
    }
    function sellUnderlying(
        address _underlying    
    ) internal {
        // Approve use
        IERC20 token = IERC20(_underlying);
        token.approve(UNDERLYING_UNISWAP, token.balanceOf(address(this)));
        
        // Perform swap back to Ether
    }
    function repayFlashLoan() internal {
        // Repay
    }
    function _onlyOwner() internal view {
        require(
            msg.sender == owner
        );
    }
}
