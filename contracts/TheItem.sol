// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.21;

import "@rmrk-team/evm-contracts/contracts/implementations/abstract/RMRKAbstractEquippable.sol";
import "@rmrk-team/evm-contracts/contracts/implementations/utils/RMRKTokenURIEnumerated.sol";
import "@rmrk-team/evm-contracts/contracts/implementations/lazyMintNative/InitDataNativePay.sol";

/**
 * @title EquipabbleToken
 * @author RMRK team
 * @notice Implementation of RMRK equippable module with native token-powered lazy minting.
 */
contract TheItem is
    InitDataNativePay,
    RMRKTokenURIEnumerated,
    RMRKAbstractEquippable
{
    uint256 private _pricePerMint;

    /**
     * @notice Used to initialize the smart contract.
     * @param name Name of the token collection
     * @param symbol Symbol of the token collection
     * @param collectionMetadata URI to the collection's metadata
     * @param baseTokenURI Each token's base URI
     * @param data The `InitData` struct used to pass initialization parameters
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory collectionMetadata,
        string memory baseTokenURI,
        InitData memory data
    )
        RMRKTokenURIEnumerated(baseTokenURI)
        RMRKImplementationBase(
            name,
            symbol,
            collectionMetadata,
            data.maxSupply,
            data.royaltyRecipient,
            data.royaltyPercentageBps
        )
    {
        _pricePerMint = data.pricePerMint;
        transferOwnership(data.royaltyRecipient);
    }


    /**
     * @notice Used to mint a desired number of child tokens to a given parent token.
     * @dev The `data` value of the `_safeMint` method is set to an empty value.
     * @dev Can only be called while the open sale is open.
     * @param to Address of the collection smart contract of the token into which to mint the child token
     * @param numToMint Number of tokens to mint
     * @param destinationId ID of the token into which to mint the new child token
     * @return The ID of the first token to be minted in the current minting cycle
     */
    function nestMint(
        // address minter, // executes if called by orchestrator or minter == msg.sender
        address to,
        uint256 numToMint,
        uint256 destinationId
    ) public payable virtual onlyOwner returns (uint256) {
        (uint256 nextToken, uint256 totalSupplyOffset) = _prepareMint(
            numToMint
        );
        _chargeMints(numToMint);

        for (uint256 i = nextToken; i < totalSupplyOffset; ) {
            _nestMint(to, i, destinationId, "");
            unchecked {
                ++i;
            }
        }

        return nextToken;
    }

    function _chargeMints(uint256 numToMint) internal {
        uint256 price = numToMint * _pricePerMint;
        if (price != msg.value) revert RMRKWrongValueSent();
    }

    /**
     * @notice Used to retrieve the price per mint.
     * @return The price per mint of a single token expressed in the lowest denomination of a native currency
     */
    function pricePerMint() public view returns (uint256) {
        return _pricePerMint;
    }

    /**
     * @notice Used to withdraw the minting proceedings to a specified address.
     * @dev This function can only be called by the owner.
     * @param to Address to receive the given amount of minting proceedings
     * @param amount The amount to withdraw
     */
    function withdrawRaised(address to, uint256 amount) external onlyOwner {
        _withdraw(to, amount);
    }

    /**
     * @notice Used to withdraw the minting proceedings to a specified address.
     * @param _address Address to receive the given amount of minting proceedings
     * @param _amount The amount to withdraw
     */
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}
