// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ERC20ACL.sol";
import "../src/ERC20Registry.sol";
import "./utils/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract InitiaCustomERC20 is IERC20, Ownable, ERC20Registry, ERC165, ERC20ACL {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IERC20).interfaceId || super.supportsInterface(interfaceId);
    }

    constructor(string memory _name, string memory _symbol, uint8 _decimals) register_erc20 {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal register_erc20_store(recipient) {
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address to, uint256 amount) internal register_erc20_store(to) {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    function transfer(address recipient, uint256 amount) external transferable(recipient) returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount)
        external
        transferable(recipient)
        returns (bool)
    {
        allowance[sender][msg.sender] -= amount;
        _transfer(sender, recipient, amount);
        return true;
    }

    function mint(address to, uint256 amount) external mintable(to) onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external burnable(from) onlyOwner {
        _burn(from, amount);
    }

    function sudoTransfer(address sender, address recipient, uint256 amount) external onlyChain {
        _transfer(sender, recipient, amount);
    }
}