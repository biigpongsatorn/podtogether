pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/GSN/Context.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

interface DaiInterface {
  function transfer(address _recipient, uint256 amount) public returns (bool);
}

contract MockPooltogether is Ownable, Context {
  uint256 public interestRate;
  uint256 public totalSupply;

  uint public oneYearPeriod = 31622400;
  uint public startTime;

  address public daiAddress;

  mapping (address => uint256) public balances;

  constructor(address _daiAddress) public {
    interestRate = 8;
    startTime = block.timestamp;
    daiAddress = _daiAddress;
  }

  function setInterestRate (uint256 _rate) public {
    interestRate = _rate;
  }

  function depositPool (uint256 _amount) public {
    balances[_msgSender()] = balances[_msgSender()].add(_amount);
    totalSupply = totalSupply.add(_amount);
  }

  function withdrawPool (uint256 _amount) public {
    balances[_msgSender()] = balances[_msgSender()].sub(_amount);
    totalSupply = totalSupply.sub(_amount);
  }

  function calculateReward () public view returns (uint256) {
    return totalSupply.mul(interestRate).div(100).mul(block.timestamp.sub(start)).div(oneYearPeriod));
  }

  function transferReward(address _winner, uint256 _amount) {
    DaiInterface dai = DaiInterface(daiAddress);
    dai.transfer(_winner, _amount);
  }

  function claimReward (address winner) public {
    uint256 reward = calculateReward();
    transfer(winner, reward);
    startTime = block.timestamp;
  }
}
