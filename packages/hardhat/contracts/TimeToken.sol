// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Stakeable.sol";
import "./Ownable.sol";

contract TimeToken is ERC20Stakeable, Ownable {
    constructor(string memory _name, string memory _symbol)
        ERC20Stakeable(_name, _symbol)
    {
        _mint(msg.sender, 10000000 * 10 ** 18);
    }

    // Functions for modifying  staking mechanism variables:

    // Set rewards per hour as x/10.000.000 (Example: 100.000 = 1%)
    function setRewards(uint256 _rewardsPerHour) public onlyOwner {
        rewardsPerHour = _rewardsPerHour;
    }

    // Set the minimum amount for staking in wei
    function setMinStake(uint256 _minStake) public onlyOwner {
        minStake = _minStake;
    }

    // Set the minimum time that has to pass for a user to be able to restake rewards
    function setCompFreq(uint256 _compoundFreq) public onlyOwner {
        compoundFreq = _compoundFreq;
    }
}
