// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;  // 最新稳定版（2026年2月18日发布，修复高危 transient storage bug）

contract AllInParty {
    
    string public constant name     = "AllInParty";
    string public constant symbol   = "AIP";
    uint8  public constant decimals = 18;
    
    uint256 private immutable TOTAL_SUPPLY = 1_000_000_000 * 10**18;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /*
     * 【重要安全提醒 - ERC-20 批准竞争条件（EIP-20 标准固有风险）】
     * 本合约严格遵循 ERC-20 标准，实现标准的 approve 函数。
     * 当用户将非零授权额度改为另一个非零值时（例如 100 → 200），存在经典竞态条件：
     * 恶意 spender 可监控 mempool，前跑 transferFrom(旧额度)，然后在新 approve 上链后 transferFrom(新额度)，总共扣旧 + 新（例如 300 而非 200）。
     * 
     * 此风险自 ERC-20 诞生起就存在，非本合约独有，已被社区广泛认可。
     * 
     * 缓解方式（强烈推荐）：
     * 1. 修改授权时，先调用 approve(spender, 0)，等待交易确认上链。
     * 2. 再调用 approve(spender, 新额度)。
     * 3. 大多数现代钱包（MetaMask、Rainbow 等）和 DEX 前端（Uniswap、1inch 等）已自动处理此两步。
     * 4. 如果使用无限批准（approve max_uint），可避免反复修改额度。
     * 
     * 合约内部使用 require 回滚机制，确保失败时交易 revert，外部函数安全返回 true。
     * 无 owner、无增发、无暂停、无税、无黑名单、无后门、无升级。
     */

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

    // 内部转账：返回 bool，失败 revert
    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "transfer from the zero address");
        require(to   != address(0), "transfer to the zero address");
        
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "transfer amount exceeds balance");

        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to]   += amount;
        }

        emit Transfer(from, to, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner  != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = _allowances[owner][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}