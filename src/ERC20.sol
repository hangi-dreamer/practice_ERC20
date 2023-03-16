// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/console.sol";


contract ERC20 {
    mapping(address => uint256) private balances;
    mapping(address => uint256) private _nonces;
    mapping(address => mapping(address => uint256)) private allowances;
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    string private _version;
    uint8 private _decimals;

    address private _admin;
    bytes32 private constant DOMAIN_SEPARATOR = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)");
    bytes32 private constant PERMIT_HASH_STRUCT = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant SALT_IN_DOMAIN_SEPARATOR = keccak256("this is salt, not sugar.");

    bool is_paused;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _n, string memory _s) {
        _name = _n;
        _symbol = _s;
        _decimals = 18;
        _totalSupply = 100 ether;
        balances[msg.sender] = 100 ether;
        _admin = msg.sender;
        _version = "init";
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "Not Admin");

        _;
    }

    modifier checkNotPaused() {
        require(is_paused == false);

        _;
    }

    function pause() onlyAdmin public {
        require(msg.sender == _admin);
        require(is_paused == false);

        is_paused = true;
    }

    function resume() onlyAdmin public {
        require(is_paused);

        is_paused = false;
    }

    function _setVersion(string memory _v) onlyAdmin checkNotPaused public {
        _version = _v;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) checkNotPaused public {
        require(deadline >= block.timestamp);

        bytes32 structHash = _toStructHash(owner, spender, value, _nonces[owner], deadline);
        require(ecrecover(_toTypedDataHash(structHash), v, r, s) == owner, "INVALID_SIGNER");

        allowances[owner][spender] = value;
        _nonces[owner]++;
    }

    function nonces(address _addr) public returns (uint) {
        return _nonces[_addr];
    }

    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR, keccak256(bytes(name())), version(), address(this), salt_domainSeparator()));
    }

    function salt_domainSeparator() public view returns (bytes32) {
        return SALT_IN_DOMAIN_SEPARATOR;
    }

    function _toStructHash(
        address owner,
        address spender,
        uint256 value,
        uint256 nonce,
        uint256 deadline
    ) private returns (bytes32) {
        return keccak256(abi.encode(
                PERMIT_HASH_STRUCT,
                owner,
                spender,
                value,
                nonce,
                deadline
            ));
    }

    function _toTypedDataHash(bytes32 structHash) public view returns (bytes32) {
        // https://eips.ethereum.org/EIPS/eip-712
        return keccak256(abi.encode("\x19\x01", domainSeparator(), structHash));
    }

    function name() public view returns (string memory){
        return _name;
    }

    function version() public view returns (string memory){
        return _version;
    }

    function symbol() public view returns (string memory){
        return _symbol;
    }

    function decimals() public view returns (uint8){
        return _decimals;
    }

    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256){
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) checkNotPaused external returns (bool success){
        require(_to != address(0), "transfer to the zero address");
        require(balances[msg.sender] >= _value, "value exeeds balance");

        unchecked {
            balances[msg.sender] -= _value; // 내 잔고보다 큰 값이 _value가 들어오면 integer underflow 발생함. 0.8 이상에선 revert됨.
            balances[_to] += _value;
        }

        emit Transfer(msg.sender, _to, _value);
    }

    function approve(address _spender, uint256 _value) checkNotPaused public returns (bool success) {
        require(_spender != address(0), "approve to the zero address");

        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _to) public view returns (uint256 value) {
        return allowances[_owner][_to];
    }

    function transferFrom(address _from, address _to, uint256 _value) checkNotPaused external returns (bool success) {
        require(_to != address(0), "transfer to the zero address");
        require(balances[_from] >= _value, "value exeeds balance");

        uint256 currentAllowance = allowance(_from, _to);
        if (currentAllowance != type(uint256).max){
            require(currentAllowance >= _value, "insufficient allowance");

            unchecked {
                allowances[_from][_to] -= _value;
            }
        }

        require(balances[_from] >= _value, "value exceeds balance");
        unchecked {
            balances[_from] -= _value;
            balances[_to] += _value;
        }

        emit Transfer(_to, _to, _value);
    }

    function _mint(address _owner, uint256 _value) checkNotPaused internal {
        require(_owner != address(0), "mint to the zero address");
        _totalSupply += _value;
        unchecked {
            balances[_owner] += _value;
        }

        emit Transfer(address(0), _owner, _value);
    }
    function _burn(address _owner, uint256 _value) checkNotPaused internal {
        require(_owner != address(0), "burn from the zero address");
        require(balances[_owner] >= _value, "burn amount exceeds balance");

        unchecked {
            balances[_owner] -= _value;
            _totalSupply -= _value;
        }

        emit Transfer(_owner, address(0), _value);
    }
}
