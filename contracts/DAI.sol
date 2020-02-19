pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Context.sol";

contract LawEnforcementRole is Context, Ownable {
    address public lawEnforcementRole;

    event LawEnforcementRoleSet(address indexed account);
    event LawEnforcementRoleRemoved(address indexed account);

    modifier onlyLawEnforcementRole() {
        require(_msgSender() == lawEnforcementRole, "LawEnforcementRole: only lawEnforcement role");
        _;
    }

    /**
     * @dev Sets a new law enforcement role address.
     * @param _newLawEnforcementRole The new address allowed to freeze/unfreeze addresses and seize their tokens.
     */
    function setLawEnforcementRole(address _newLawEnforcementRole) public {
        require(_msgSender() == lawEnforcementRole || _msgSender() == owner(), "LawEnforcementRole: only lawEnforcement role or owner");
        require(_newLawEnforcementRole != address(0), "LawEnforcementRole: cannot set lawEnforcement role to zero address");
        require(lawEnforcementRole != _newLawEnforcementRole, "LawEnforcementRole: lawEnforcementRole == _newLawEnforcementRole");

        lawEnforcementRole = _newLawEnforcementRole;
        emit LawEnforcementRoleSet(_newLawEnforcementRole);
    }

    function removeLawEnforcementRole() public onlyOwner {
        require(lawEnforcementRole != address(0), "LawEnforcementRole: lawEnforcementRole is already empty");

        emit LawEnforcementRoleRemoved(lawEnforcementRole);
        lawEnforcementRole = address(0);
    }
}

contract Freezable is LawEnforcementRole {
    mapping (address => bool) public frozens;

    event AddressFrozen(address indexed account);
    event AddressUnfrozen(address indexed account);

    modifier onlyFrozen(address _account) {
        require(frozens[_account], "Freezable: address is not frozen");
        _;
    }

    modifier onlyNonFrozen(address _account) {
        require(!frozens[_account], "Freezable: address is already frozen");
        _;
    }

    function freeze(address _account) public onlyLawEnforcementRole onlyNonFrozen(_account) {
        require(_account != address(0), "Freezable: can not freeze zero address");

        frozens[_account] = true;
        emit AddressFrozen(_account);
    }

    function unfreeze(address _account) public onlyLawEnforcementRole onlyFrozen(_account) {
        frozens[_account] = false;
        emit AddressUnfrozen(_account);
    }
}

contract MinterRole is Ownable {
    address public minter;

    event MinterSet(address indexed account);
    event MinterRemoved(address indexed account);

    modifier onlyMinter() {
        require(_msgSender() == minter, "MinterRole: only minter");
        _;
    }

    /**
     * @dev Sets a new minter address.
     * @param _newMinter The address allowed to mint tokens.
     */
    function setMinter(address _newMinter) public {
        require(_msgSender() == minter || _msgSender() == owner(), "MinterRole: only minter or owner");
        require(_newMinter != address(0), "MinterRole: cannot set minter to zero address");
        require(minter != _newMinter, "MinterRole: minter == _newMinter");

        minter = _newMinter;
        emit MinterSet(_newMinter);
    }

    function removeMinter() public onlyOwner {
        require(minter != address(0), "MinterRole: minter is already empty");

        emit MinterRemoved(minter);
        minter = address(0);
    }
}

contract SupplyControllable is ERC20, MinterRole, Freezable {
    event SupplyIncreased(address indexed account, uint256 indexed amount);
    event SupplyDecreased(address indexed account, uint256 indexed amount);

    /**
     * @dev Increases the total supply by minting the specified number of tokens to the _account.
     * @param _amount The number of tokens to add.
     * @return A boolean that indicates if the operation was successful.
     */
    function _increaseSupply(address _account, uint256 _amount) internal {
        _mint(_account, _amount);
        emit SupplyIncreased(_account, _amount);
    }

    /**
     * @dev Increases the total supply by minting the specified number of tokens to the _account.
     * @param _amount The number of tokens to add.
     * @return A boolean that indicates if the operation was successful.
     */
    function increaseSupply(address _account, uint256 _amount) public onlyMinter onlyNonFrozen(_account) returns (bool success) {
        _increaseSupply(_account, _amount);
        return true;
    }

    /**
     * @dev Destroys `_amount` tokens from the caller.
     */
    function _decreaseSupply(address _account, uint256 _amount) internal {
        _burn(_account, _amount);
        emit SupplyDecreased(_account, _amount);
    }
}

contract SweeperRole is Ownable {
    /// @dev  The sole authorized caller of delegated transfer control ('sweeping').
    mapping (address => bool) public sweepers;

    event SweeperAdded(address indexed account);
    event SweeperRemoved(address indexed account);

    modifier onlySweeper(address _account) {
        require(sweepers[_account], "SweeperRole: account is not sweeper");
        _;
    }

    modifier onlyNonSweeper(address _account) {
        require(!sweepers[_account], "SweeperRole: account is sweeper");
        _;
    }

    /**
     * @dev Add a new sweeper.
     * @param _account The address for new sweeper.
     */
    function addSweeper(address _account) public onlyNonSweeper(_account) onlyOwner {
        require(_account != address(0), "SweeperRole: sweeper cannot be zero address");
        sweepers[_account] = true;
        emit SweeperAdded(_account);
    }

    function removeSweeper(address _account) public onlySweeper(_account) onlyOwner {
        require(_account != address(0), "SweeperRole: sweeper cannot be zero address");
        sweepers[_account] = false;
        emit SweeperRemoved(_account);
    }

}

contract Sweepable is ERC20, SweeperRole, SupplyControllable {
    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }

    // keccak256(abi.encode(address(this), "sweep"));
    struct SweepMessage {
        string message;
    }

    bytes32 public constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 public constant SWEEPMESSAGE_TYPEHASH = keccak256(
        "SweepMessage(string message)"
    );

    bytes32 public DOMAIN_SEPARATOR;

    /** @dev  The static message to be signed by an external account that
     * signifies their permission to forward their balance to any arbitrary
     * address. This is used to consolidate the control of all accounts
     * backed by a shared keychain into the control of a single key.
     * Initialized as the concatenation of the address of this contract
     * and the word "sweep". This concatenation is done to prevent a replay
     * attack in a subsequent contract, where the sweep message could
     * potentially be replayed to re-enable sweeping ability.
     */
    bytes32 public SWEEP_MESSAGE_HASH;

    /** @dev  The mapping that stores whether the address in question has
     * enabled sweeping its contents to another account or not.
     * If an address maps to "true", it has already enabled sweeping,
     * and thus does not need to re-sign the `sweepMessage` to enact the sweep.
     */
    mapping (address => bool) public sweepAccounts;

    function hash(EIP712Domain memory _eip712Domain) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(_eip712Domain.name)),
            keccak256(bytes(_eip712Domain.version)),
            _eip712Domain.chainId,
            _eip712Domain.verifyingContract
        ));
    }

    function hash(SweepMessage memory _sweepMessage) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SWEEPMESSAGE_TYPEHASH,
            keccak256(bytes(_sweepMessage.message))
        ));
    }

    event SweepEnabled(address indexed account);

    /** @notice  Enables the delegation of transfer control for many
     * accounts to the sweeper account, transferring any balances
     * as well to the given destination.
     *
     * @dev  An account delegates transfer control by signing the
     * value of `_sweepMessage`. The sweeper account is the only authorized
     * caller of this function, so it must relay signatures on behalf
     * of accounts that delegate transfer control to it. Enabling
     * delegation is idempotent and permanent. If the account has a
     * balance at the time of enabling delegation, its balance is
     * also transfered to the given destination account `_to`.
     * NOTE: transfers to the zero address are disallowed.
     *
     * @param  _vs  The array of recovery byte components of the ECDSA signatures.
     * @param  _rs  The array of 'R' components of the ECDSA signatures.
     * @param  _ss  The array of 'S' components of the ECDSA signatures.
     */
    function enableSweep(uint8[] memory _vs, bytes32[] memory _rs, bytes32[] memory _ss) public onlySweeper(_msgSender()) {
        require((_vs.length == _rs.length) && (_vs.length == _ss.length), "Sweepable: length of signatures should equal");

        uint256 numSignatures = _vs.length;

        for (uint256 i = 0; i < numSignatures; ++i) {
            address account = ecrecover(SWEEP_MESSAGE_HASH, _vs[i], _rs[i], _ss[i]);

            // ecrecover returns 0 on malformed input
            require(account != address(0), "Sweepable: malformed input of signature");
            sweepAccounts[account] = true;
            emit SweepEnabled(account);
        }
    }

    /** @notice  For accounts that have delegated, transfer control
      * to the sweeper, this function transfers their balances to the given
      * destination.
      *
      * @dev The sweeper account is the only authorized caller of
      * this function. This function accepts an array of addresses to have their
      * balances transferred for gas efficiency purposes.
      * NOTE: any address for an account that has not been previously enabled
      * will be ignored.
      * NOTE: transfers to the zero address are disallowed.
      *
      * @param  _froms  The addresses to have their balances swept.
      */
    function replaySweep(address[] memory _froms) public onlySweeper(_msgSender()) {
        uint256 lenFroms = _froms.length;

        for (uint256 i = 0; i < lenFroms; ++i) {
            address from = _froms[i];

            require(sweepAccounts[from], "Sweepable: some accounts are not the sweep account");
            uint256 fromBalance = balanceOf(from);

            if (fromBalance > 0) {
                _decreaseSupply(from, fromBalance);
            }
        }
    }
}

contract RemoteBurnRole is Ownable {
    address public remoteBurner;

    event RemoteBurnerSet(address indexed account);
    event RemoteBurnerRemoved(address indexed account);

    modifier onlyRemoteBurner() {
        require(_msgSender() == remoteBurner, "RemoteBurnerRole: only remote burner");
        _;
    }

    /**
     * @dev Sets a new remote burner address.
     * @param _newRemoteBurner The address allowed to remote burn tokens.
     */
    function setRemoteBurner(address _newRemoteBurner) public onlyOwner {
        require(_newRemoteBurner != address(0), "RemoteBurnRole: cannot set remote burner to zero address");
        require(remoteBurner != _newRemoteBurner, "RemoteBurnRole: remoteBurner == _newRemoteBurner");

        remoteBurner = _newRemoteBurner;
        emit RemoteBurnerSet(_newRemoteBurner);
    }

    function removeRemoteBurner() public onlyOwner {
        require(remoteBurner != address(0), "RemoteBurnRole: remoteBurner is already empty");

        emit RemoteBurnerRemoved(remoteBurner);
        remoteBurner = address(0);
    }
}

contract RemoteBurnable is RemoteBurnRole, Freezable, SupplyControllable {
    event FrozenAddressBurned(address indexed account, uint256 indexed amount);

    function remoteBurn(address _account, uint256 _amount) public onlyRemoteBurner onlyFrozen(_account) {
        _decreaseSupply(_account, _amount);
        emit FrozenAddressBurned(_account, _amount);
    }

}

/** @notice We have to naming parameters of this contract
  * without start with '_' because we have to follow to EIP712 standard.
  * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#example
  */
contract Permitable is Sweepable {
    mapping (address => uint256) public nonces;

    bytes32 public constant PERMIT_TYPEHASH = keccak256(
        "Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)"
    );

    function permitHash(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed
    )
    internal
    pure
    returns (bytes32)
    {
        return keccak256(abi.encode(
            PERMIT_TYPEHASH,
            holder,
            spender,
            nonce,
            expiry,
            allowed
        ));
    }

    // --- Approve by signature ---
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
    external
    {
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            permitHash(holder, spender, nonce, expiry, allowed)
        ));

        require(holder != address(0), "DAI: holder address can not be 0x00");
        require(holder == ecrecover(digest, v, r, s), "DAI: invalid signature");
        require(expiry == 0 || now <= expiry, "DAI: signature has expired");
        require(nonce == nonces[holder]++, "DAI: invalid nonce");
        uint256 amount = allowed ? uint256(-1) : 0;

        _approve(holder, spender, amount);
    }
}

contract Implementation is RemoteBurnable, Permitable {
    string public name;
    string public symbol;
    uint256 public decimals;

    // INITIALIZATION DATA
    bool private initialized = false;

    /**
     * @dev sets 0 initials tokens, the owner, and the supplyController.
     * this serves as the constructor for the proxy but compiles to the
     * memory model of the Implementation contract.
     */
    function initialize(address _minter) public {
        require(!initialized, "already initialized");

        _transferOwnership(_msgSender());

        name = "DAI";
        symbol = "DAI";
        decimals = 18;
        minter = _minter;

        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name: "DAI",
            version: '1',
            chainId: 1,
            verifyingContract: address(this)
        }));

        SWEEP_MESSAGE_HASH = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            hash(SweepMessage("sweep"))
        ));

        initialized = true;
    }

    constructor() public {
        initialize(_msgSender());
    }

    function transfer(
        address _recipient,
        uint256 amount
    )
    public
    onlyNonFrozen(_msgSender())
    onlyNonFrozen(_recipient)
    returns (bool)
    {
        _transfer(_msgSender(), _recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `_sender` and `_recipient` cannot be the zero address.
     * - `_sender` must have a balance of at least `_amount`.
     * - the caller must have allowance for `_sender`'s tokens of at least
     * `_amount`.
     */
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
    public
    onlyNonFrozen(_msgSender())
    onlyNonFrozen(_sender)
    onlyNonFrozen(_recipient)
    returns (bool)
    {
        if (allowance(_sender, _msgSender()) != uint(-1)) {
            _approve(_sender, _msgSender(), allowance(_sender, _msgSender()).sub(_amount, "DAI: transfer _amount exceeds allowance"));
        }
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        revert("DAI: Overwrite this function for avoid to using");
    }
}
