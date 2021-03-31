// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Bonus is Ownable {
    uint256 bonusStartBlock;
    uint256 bonusEndBlock;
    uint256 BONUS_MULTIPLIER = 1;

    event BonusMode(uint256 multiplier, uint256 untilBlock);

    modifier bonusCheck {
        _bonusPreCheck();
        _;
        _bonusPostCheck();
    }

    function resetBonus(uint256 multiplier) external onlyOwner {
        BONUS_MULTIPLIER = multiplier;
    }

    function getBonusMultiplier() public view returns (uint256) {
        return BONUS_MULTIPLIER;
    }

    function _bonusPreCheck() private {
        if (bonusStartBlock == block.number) {
            return;
        }

        uint256 pick = _rand(10000, 64534287523);
        if (pick == 1922) {
            bonusStartBlock = block.number;
            bonusEndBlock = block.number + 14400;
            BONUS_MULTIPLIER = BONUS_MULTIPLIER * 2;
            emit BonusMode(BONUS_MULTIPLIER, bonusEndBlock);
        }
    }

    function _bonusPostCheck() private {
        if (bonusStartBlock == block.number) {
            return;
        }

        if (block.number > bonusEndBlock && BONUS_MULTIPLIER > 1) {
            BONUS_MULTIPLIER = 1;
        }
    }

    function _rand(uint256 max, uint256 salt) private view returns(uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)) +
            block.gaslimit + salt +
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now-salt)) +
            block.number - salt
        )));

        return (seed - ((seed / max) * max));
    }
}