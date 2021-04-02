// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import './libs/IBEP20.sol';

contract TokenLock {
    using SafeMath for uint256;

    struct TokenSet {
        uint256 amount;
        uint256 until;
        uint256 withdrawn;
    }

    mapping(address => mapping(address => TokenSet[])) public locks;

    event Deposit(address indexed token, address indexed user, uint256 amount, uint256 until);
    event Withdraw(address indexed token, address indexed user, uint256 amount, uint256 timestamp);
    event Locked(uint256 amount, uint256 until);

    function deposit(IBEP20 _token, uint256 _amount, uint256 _until) external {
        require(_until > block.timestamp, "Not in future");
        require(_amount > 0, "no amount");

        uint256 balance = _token.balanceOf(msg.sender);
        require(balance >= _amount, "insufficient funds");

        // Don't believe the amount, token could have deflation
        uint256 beforeLockBal = _token.balanceOf(address(this));
        _token.transferFrom(msg.sender, address(this), _amount);
        uint256 afterLockBal = _token.balanceOf(address(this));

        uint256 depositAmount = afterLockBal.sub(beforeLockBal);

        locks[address(_token)][msg.sender].push(TokenSet({
            amount: depositAmount,
            until: _until,
            withdrawn: 0
        }));

        emit Deposit(address(_token), msg.sender, depositAmount, _until);
        emit Locked(depositAmount, _until);
    }

    function withdraw(IBEP20 _token, uint256 _amount) external {
        require(_amount > 0, "no amount");

        uint256 currentAmount = _amount;
        uint256 transferAmount;

        TokenSet[] storage tokenSets = locks[address(_token)][msg.sender];
        for (uint256 i; i<tokenSets.length; i++) {
            uint256 withdrawn;
            uint256 availableAmount = tokenSets[i].amount.sub(tokenSets[i].withdrawn);
            
            if (tokenSets[i].until <= block.timestamp) {
                if (availableAmount <= currentAmount) {
                    withdrawn = availableAmount;
                } else {
                    withdrawn = currentAmount;
                }
            }

            locks[address(_token)][msg.sender][i].withdrawn = withdrawn;
            
            currentAmount = currentAmount.sub(withdrawn);
            transferAmount = currentAmount.add(withdrawn);
        }

        if (transferAmount > 0) {
            _token.transfer(msg.sender, transferAmount);
        }

        emit Withdraw(address(_token), msg.sender, transferAmount, block.timestamp);
    }

}