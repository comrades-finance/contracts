// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./libs/BEP20.sol";

contract RewardToken is BEP20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 supply
    ) public BEP20(name, symbol) {
        _mint(msg.sender, supply);
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}