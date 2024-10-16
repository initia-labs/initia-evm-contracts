pragma solidity ^0.8.24;

interface ConnectOracle {
    struct Price {
        uint256 price;
        uint256 timestamp;
        uint64 height;
        uint64 nonce;
        uint64 decimal;
        uint64 id;
    }

    function get_all_currency_pairs() external returns (string memory);
    function get_price(string memory base, string memory quote) external returns (Price memory);
    function get_prices(string[] memory pair_ids) external returns (Price[] memory);
}
