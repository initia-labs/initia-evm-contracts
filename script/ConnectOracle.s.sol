// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {ConnectOracle, Price} from "../src/ConnectOracle.sol";

contract OracleScript is Script {
    ConnectOracle public oracle;

    constructor(address _oracle) {
        oracle = ConnectOracle(_oracle);
    }

    function getPrice(string memory pairId) public {
        vm.startBroadcast();
        Price memory price = oracle.get_price(pairId);
        console.log("Price:", price.price);
        vm.stopBroadcast();
    }

    function getAllCurrencyPairs() public {
        vm.startBroadcast();
        string memory prices = oracle.get_all_currency_pairs();
        console.log("Prices:", prices);
        vm.stopBroadcast();
    }

    function getPrices(
        string[] memory pair_ids
    ) public returns (Price[] memory) {
        return oracle.get_prices(pair_ids);
    }
}
