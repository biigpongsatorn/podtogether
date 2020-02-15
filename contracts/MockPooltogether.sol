pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/GSN/Context.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

interface DaiInterface {
  function transfer(address _recipient, uint256 _amount) external returns (bool);
  function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);
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
    startTime = 0;
    daiAddress = _daiAddress;
  }

  function setInterestRate (uint256 _rate) public {
    interestRate = _rate;
  }

  function depositPool (uint256 _amount) public {
    _transferFrom(_amount);
    balances[_msgSender()] = balances[_msgSender()].add(_amount);
    if (totalSupply === 0) {
      startTime = block.timestamp
    }
    totalSupply = totalSupply.add(_amount);
  }

  function withdrawPool (uint256 _amount) public {
    balances[_msgSender()] = balances[_msgSender()].sub(_amount);
    totalSupply = totalSupply.sub(_amount);
  }

  function calculateReward () public view returns (uint256) {
    if (startTime === 0) {
      return 0;
    }
    return totalSupply.mul(interestRate).mul(block.timestamp.sub(startTime)).div(oneYearPeriod).div(100);
  }

  function _transferFrom(uint256 _amount) internal {
    DaiInterface dai = DaiInterface(daiAddress);
    dai.transferFrom(_msgSender(), address(this), _amount);
  }

  function _transferReward(address _winner, uint256 _amount) internal {
    DaiInterface dai = DaiInterface(daiAddress);
    dai.transfer(_winner, _amount);
  }

  function claimReward (address _winner) public {
    uint256 rewardAmount = calculateReward();
    _transferReward(_winner, rewardAmount);
    startTime = block.timestamp;
  }
}
