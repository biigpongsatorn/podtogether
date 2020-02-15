pragma solidity ^0.5.0;

import {ERC20Mintable} from "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";
import {ERC20Detailed} from "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";

contract PodToken is ERC20Mintable, ERC20Detailed {
    constructor(string memory _name, string memory _symbol, uint8 _decimal)
        ERC20Detailed(_name, _symbol, _decimal) public {
            
        }
}