#!/bin/bash

# Create the ABIs directory if it doesn't exist
mkdir -p abis

# Iterate over all JSON files in the out directory and its subdirectories
find out -name '*.json' | while read -r file; do
    # Extract the contract name from the file path
    contract_name=$(basename "$file" .json)

    # Check if the ABI is not empty using jq
    if jq -e '.abi | length > 0' "$file" > /dev/null; then
        # Extract the ABI and save it to the ABIs directory
        jq '.abi' "$file" > "abis/${contract_name}.abi.json"
        echo "Extracted ABI for $contract_name"
    else
        echo "Skipped $contract_name as its ABI is empty"
    fi
done

echo "All non-empty ABIs have been extracted to the ABIs directory."
