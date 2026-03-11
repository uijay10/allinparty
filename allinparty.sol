// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

contract AllInParty {
    string public constant name     = "AllInParty";
    string public constant symbol   = "AIP";
    uint8  public constant decimals = 18;
    
    uint256 private immutable TOTAL_SUPPLY = 1_000_000_000 * 10**18;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        _balances[msg.sender] = TOTAL_SUPPLY;
        emit Transfer(address(0), msg.sender, TOTAL_SUPPLY);
    }

    function totalSupply() external pure returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        return _transfer(from, to, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "from zero");
        require(to   != address(0), "to zero");
        
        uint256 balance = _balances[from];
        require(balance >= amount, "exceeds balance");

        unchecked {
            _balances[from] = balance - amount;
            _balances[to]  += amount;
        }

        emit Transfer(from, to, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner  != address(0), "approve from zero");
        require(spender != address(0), "approve to zero");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 current = _allowances[owner][spender];
        if (current != type(uint256).max) {
            require(current >= amount, "insufficient allowance");
            unchecked { _approve(owner, spender, current - amount); }
        }
    }
}
