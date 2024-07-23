// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/ICosmos.sol";
import "./utils/jsmnSolLib.sol";
import "./utils/IsoToUnix.sol";

contract Slinky {
    struct Price {
        uint256 price;
        uint256 timestamp;
        uint64 height;
        uint64 nonce;
        uint64 decimal;
        uint64 id;
    }

    address cosmosContract;

    constructor() {}

    function get_all_currency_pairs() external returns (string memory) {
        string memory path = "/slinky.oracle.v1.Query/GetAllCurrencyPairs";
        string memory req = "{}";
        return ICosmos(cosmosContract).query_cosmos(path, req);
    }

    function get_price(string memory base, string memory quote) external returns (Price memory) {
        string memory path = "/slinky.oracle.v1.Query/GetPrice";

        string[] memory join_strs = new string[](5);
        join_strs[0] = '{"currency_pair": {"Base": "';
        join_strs[1] = base;
        join_strs[2] = '", "Quote": "';
        join_strs[3] = quote;
        join_strs[4] = '"}}';
        string memory req = join(join_strs, "");
        string memory queryRes = COSMOS_CONTRACT.query_cosmos(path, req);

        uint256 returnValue;
        JsmnSolLib.Token[] memory tokens;
        uint256 actualNum;
        (returnValue, tokens, actualNum) = JsmnSolLib.parse(queryRes, 15);

        return get_price_from_tokens(queryRes, tokens, 0);
    }

    function get_prices(string[] memory pair_ids) external returns (Price[] memory) {
        string memory path = "/slinky.oracle.v1.Query/GetPrices";
        string memory req = string.concat(string.concat('{"currency_pair_ids":["', join(pair_ids, '","')), '"]}');
        uint256 numberElements = 3 + pair_ids.length * 15;

        string memory queryRes = COSMOS_CONTRACT.query_cosmos(path, req);

        uint256 returnValue;
        JsmnSolLib.Token[] memory tokens;
        uint256 actualNum;
        (returnValue, tokens, actualNum) = JsmnSolLib.parse(queryRes, numberElements);

        Price[] memory response = new Price[](actualNum / 15);
        uint256 index = 3;
        while (index < actualNum) {
            response[index / 15] = get_price_from_tokens(queryRes, tokens, index);
            index = index + 15;
        }

        return response;
    }

    function join(string[] memory strs, string memory separator) internal pure returns (string memory) {
        uint256 len = strs.length;
        string memory res = strs[0];
        for (uint256 i = 1; i < len; i++) {
            res = string.concat(res, separator);
            res = string.concat(res, strs[i]);
        }

        return res;
    }

    function get_price_from_tokens(string memory json, JsmnSolLib.Token[] memory tokens, uint256 priceObjectIndex)
        internal
        pure
        returns (Price memory)
    {
        string memory priceStr =
            JsmnSolLib.getBytes(json, tokens[priceObjectIndex + 4].start, tokens[priceObjectIndex + 4].end);
        uint256 price = uint256(JsmnSolLib.parseInt(priceStr));

        string memory timestampStr =
            JsmnSolLib.getBytes(json, tokens[priceObjectIndex + 6].start, tokens[priceObjectIndex + 6].end);
        uint256 timestamp = IsoToUnix.convertDateTimeStringToTimestamp(timestampStr);

        string memory heightStr =
            JsmnSolLib.getBytes(json, tokens[priceObjectIndex + 8].start, tokens[priceObjectIndex + 8].end);
        uint64 height = uint64(uint256(JsmnSolLib.parseInt(heightStr)));

        string memory nonceStr =
            JsmnSolLib.getBytes(json, tokens[priceObjectIndex + 10].start, tokens[priceObjectIndex + 10].end);
        uint64 nonce = uint64(uint256(JsmnSolLib.parseInt(nonceStr)));

        string memory decimalStr =
            JsmnSolLib.getBytes(json, tokens[priceObjectIndex + 12].start, tokens[priceObjectIndex + 12].end);
        uint64 decimal = uint64(uint256(JsmnSolLib.parseInt(decimalStr)));

        string memory idStr =
            JsmnSolLib.getBytes(json, tokens[priceObjectIndex + 14].start, tokens[priceObjectIndex + 14].end);
        uint64 id = uint64(uint256(JsmnSolLib.parseInt(idStr)));

        return Price({price: price, timestamp: timestamp, height: height, nonce: nonce, decimal: decimal, id: id});
    }
}
