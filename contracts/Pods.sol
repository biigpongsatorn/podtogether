pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/GSN/Context.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import {ERC20Mintable} from "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";
import {ERC20Detailed} from "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";

interface DaiInterface {
  function transfer(address _recipient, uint256 _amount) external returns (bool);
  function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);
}

interface PoolTogetherInterface {
  function depositPool (uint256 _amount) external;
  function withdrawPool (uint256 _amount) external;
  function claimReward (address _winner) external;
  function balanceOf (address _account) external returns (uint256);
}

contract Pods is ERC20Mintable, ERC20Detailed {
  using SafeMath for uint256;

  address public daiAddress;
  address public poolTogetherAddress;

  uint256 public totalDeposit;

  constructor(string memory _name, string memory _symbol, uint8 _decimal, address _daiAddress, address _poolTogetherAddress) ERC20Detailed(_name, _symbol, _decimal) public {
    daiAddress = _daiAddress;
    poolTogetherAddress = _poolTogetherAddress;
    totalDeposit = 0;
  }

  function joinPod (uint256 _amount) public returns (bool) {
    require(_transferFrom(_amount), 'Can not transfer from this address');
    uint256 podDaiAmount = getExpectedShareAmount(_amount);
    _depositPool(_amount);
    _mint(_msgSender(), podDaiAmount);
    return true;
  }

  function _depositPool (uint256 _amount) internal returns (bool) {
    PoolTogetherInterface poolTogether = PoolTogetherInterface(poolTogetherAddress);
    poolTogetherAddress.depositPool(_amount);
    totalDeposit = totalDeposit.add(_amount);
    return bool
  }

  function getExpectedShareAmount(uint256 _newAmount) public view returns (uint256) {
    PoolTogetherInterface poolTogether = PoolTogetherInterface(poolTogetherAddress);
    uint256 totalPoolBalance = poolTogether.balanceOf(address(this))
    return totalPoolBalance.add(_newAmount).mul(totalSupply.div(totalPoolBalance)).sub(totalSupply)
  }

  function withdrawPod (uint256 _amount) public returns (bool) {

  }

  function _withdrawPool (uint256 _amount) internal returns (bool) {
    PoolTogetherInterface poolTogether = PoolTogetherInterface(poolTogetherAddress);
    poolTogetherAddress.withdrawPool(_amount);
    totalDeposit = totalDeposit.sub(_amount);
    return bool
  }

  function claimReward () public {

  }

  function getCurrentSupplyInPool () public return (uint256) {

  }

  function _transferFrom(uint256 _amount) internal  returns (bool) {
    DaiInterface dai = DaiInterface(daiAddress);
    dai.transferFrom(_msgSender(), address(this), _amount);
    return bool
  }
}
