// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {ConnectOracle, Price} from "src/ConnectOracle.sol";
// forge script script/ConnectOracle.s.sol:ConnectOracleDeployScript\
//  --rpc-url $JSON_RPC_URL\
//  --broadcast \
//  --interactives 1

contract ConnectOracleDeployScript is Script {
    ConnectOracle public oracle;

    function run() public {
        vm.startBroadcast();
        oracle = new ConnectOracle();
        console.log("Deployed ConnectOracle:", address(oracle));
        vm.stopBroadcast();
    }
}
