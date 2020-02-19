pragma solidity ^0.5.0;

import "./Ownable.sol";
import "./Context.sol";
import "./SafeMath.sol";

interface DaiInterface {
  function transfer(address _recipient, uint256 _amount) external returns (bool);
  function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
}

contract MockPooltogether is Ownable {
  using SafeMath for uint256;
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
    DaiInterface dai = DaiInterface(daiAddress);
    dai.transferFrom(_msgSender(), address(this), _amount);
    balances[_msgSender()] = balances[_msgSender()].add(_amount);
    totalSupply = totalSupply.add(_amount);
  }

  function withdrawPool (uint256 _amount) public {
    DaiInterface dai = DaiInterface(daiAddress);
    dai.transfer(_msgSender(), _amount);
    balances[_msgSender()] = balances[_msgSender()].sub(_amount);
    totalSupply = totalSupply.sub(_amount);
  }

  function calculateReward () public view returns (uint256) {
    return totalSupply.mul(interestRate).mul(block.timestamp.sub(startTime)).div(oneYearPeriod).div(100);
  }

  function claimReward (address _winner) public {
    uint256 rewardAmount = calculateReward();
    balances[_winner] = balances[_winner].add(rewardAmount);
    totalSupply = totalSupply.add(rewardAmount);
    startTime = block.timestamp;
  }

  function balanceOf (address _account) public view returns (uint256) {
    return balances[_account];
  }
}
