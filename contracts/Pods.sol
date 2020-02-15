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

  uint256 public rate = 1e18;

  constructor(string memory _name, string memory _symbol, uint8 _decimal, address _daiAddress, address _poolTogetherAddress) ERC20Detailed(_name, _symbol, _decimal) public {
    daiAddress = _daiAddress;
    poolTogetherAddress = _poolTogetherAddress;
  }

  function joinPod (uint256 _amount) public returns (bool) {
    require(_transferFrom(_amount), 'Can not transfer from this address');
    require(_depositPool(_amount), 'Can not deposit to PoolTogether');
    uint256 currentRate = 
    uint256 podDaiAmount = _amount.mul(currentRate);
  }

  function _depositPool (uint256 _amount) internal returns (bool) {
    PoolTogetherInterface poolTogether = PoolTogetherInterface(poolTogetherAddress);
    poolTogetherAddress.depositPool(_amount);
    return bool
  }

  function withdrawPod (uint256 _amount) public returns (bool) {
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
