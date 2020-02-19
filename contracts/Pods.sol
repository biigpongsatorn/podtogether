pragma solidity ^0.5.0;

import "./Ownable.sol";
import "./Context.sol";
import "./SafeMath.sol";
import {ERC20Mintable} from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC20/ERC20Mintable.sol";
import {ERC20Detailed} from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC20/ERC20Detailed.sol";

interface DaiInterface {
  function transfer(address _recipient, uint256 _amount) external returns (bool);
  function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
}

interface PoolTogetherInterface {
  function depositPool (uint256 _amount) external;
  function withdrawPool (uint256 _amount) external;
  function claimReward (address _winner) external;
  function balanceOf (address _account) external view returns (uint256);
}

contract Pods is ERC20Mintable, ERC20Detailed, Ownable {
  using SafeMath for uint256;

  address public daiAddress;
  address public poolTogetherAddress;

  uint256 public totalDeposit;

  constructor(string memory _name, string memory _symbol, uint8 _decimal, address _daiAddress, address _poolTogetherAddress) ERC20Detailed(_name, _symbol, _decimal) public {
    daiAddress = _daiAddress;
    poolTogetherAddress = _poolTogetherAddress;
    totalDeposit = 0;
  }

  function depositPod (uint256 _amount) public returns (bool) {
    require(_transferFrom(_amount), 'Can not transfer from this address');
    uint256 shareAmount = getShareAmount(_amount);
    _approveToDepositToPool(_amount);
    _depositPool(_amount);
    _mint(_msgSender(), shareAmount);
    return true;
  }

  function _approveToDepositToPool (uint256 _amount) internal {
      DaiInterface dai = DaiInterface(daiAddress);
      dai.approve(poolTogetherAddress, _amount);
  }

  function _depositPool (uint256 _amount) internal returns (bool) {
    PoolTogetherInterface poolTogether = PoolTogetherInterface(poolTogetherAddress);
    poolTogether.depositPool(_amount);
    totalDeposit = totalDeposit.add(_amount);
    return true;
  }

  function getShareAmount(uint256 _newAmount) public view returns (uint256) {
    if (totalSupply() == 0) {
        return _newAmount;
    }
    PoolTogetherInterface poolTogether = PoolTogetherInterface(poolTogetherAddress);
    uint256 totalPoolBalance = poolTogether.balanceOf(address(this));
    uint256 rate = totalSupply().mul(1e18).div(totalPoolBalance);
    return totalPoolBalance.add(_newAmount).mul(rate).div(1e18).sub(totalSupply());
  }

  function withdrawPod (uint256 _tokenAmount) public returns (bool) {
    uint256 shareAmount = getRedeemedShareAmount(_tokenAmount);
    require(shareAmount <= balanceOf(_msgSender()), 'Your balance is not enough');
    _withdrawPool(_tokenAmount);
    _transferTokenToUser(_tokenAmount);
    _burn(_msgSender(), shareAmount);
    return true;
  }

  function _withdrawPool (uint256 _amount) internal returns (bool) {
    PoolTogetherInterface poolTogether = PoolTogetherInterface(poolTogetherAddress);
    poolTogether.withdrawPool(_amount);
    totalDeposit = totalDeposit.sub(_amount);
    return true;
  }

  function calcurateRate () public view returns (uint256) {
    PoolTogetherInterface poolTogether = PoolTogetherInterface(poolTogetherAddress);
    uint256 totalPoolBalance = poolTogether.balanceOf(address(this));
    return totalPoolBalance.mul(1e18).div(totalSupply());
  }

  function _transferTokenToUser (uint256 _amount) internal returns (bool) {
    DaiInterface dai = DaiInterface(daiAddress);
    dai.transfer(_msgSender(), _amount);
    return true;
  }

  function getRedeemedShareAmount(uint256 _tokenAmount) public view returns (uint256) {
    PoolTogetherInterface poolTogether = PoolTogetherInterface(poolTogetherAddress);
    uint256 totalPoolBalance = poolTogether.balanceOf(address(this));
    uint256 rate = totalPoolBalance.mul(1e18).div(totalSupply());
    return _tokenAmount.mul(1e18).div(rate);
  }

  function getCurrentSupplyInPool () public view returns (uint256) {
    PoolTogetherInterface poolTogether = PoolTogetherInterface(poolTogetherAddress);
    return poolTogether.balanceOf(address(this));
  }

  function _transferFrom(uint256 _amount) internal  returns (bool) {
    DaiInterface dai = DaiInterface(daiAddress);
    dai.transferFrom(_msgSender(), address(this), _amount);
    return true;
  }
}
