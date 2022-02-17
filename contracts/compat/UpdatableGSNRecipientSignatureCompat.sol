/*
    Copyright (c) 2020 Reddit Inc. All rights reserved.
    Redistribution and use in source and binary forms, with or without modification, are permitted provided
    that the following conditions are met:
    1. Redistributions of source code must retain the above copyright notice,
        this list of conditions and the following disclaimer.
    2. Redistributions in binary form must reproduce the above copyright notice,
        this list of conditions and the following disclaimer in the documentation and/or other
        materials provided with the distribution.
    3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse
        or promote products derived from this software without specific prior written permission.
    THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
    BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSEARE DISCLAIMED.
    IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
    CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
    STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
    EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

pragma solidity >=0.5.0 < 0.6.0;

import "./Initializable.sol";

import "./GSNRecipient.sol";
import "./ECDSA.sol";

contract UpdatableGSNRecipientSignatureCompat is InitializableCompat, GSNRecipientCompat {
    using ECDSA for bytes32;

    event SignerUpdated(address signer);

    address private _trustedSigner;

    enum GSNRecipientSignatureErrorCodes {
        INVALID_SIGNER
    }

    /**
     * @dev Sets the trusted signer that is going to be producing signatures to approve relayed calls.
     */
    function initialize(address trustedSigner) public initializer {
        updateSigner(trustedSigner);
        GSNRecipientCompat.initialize();
    }

    /**
     * @dev Ensures that only transactions with a trusted signature can be relayed through the GSN.
     */
    function acceptRelayedCall(
        address relay,
        address from,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata approvalData,
        uint256
    )
        external
        view
        returns (uint256, bytes memory)
    {
        bytes memory blob = abi.encode(
            relay,
            from,
            encodedFunction,
            transactionFee,
            gasPrice,
            gasLimit,
            nonce, // Prevents replays on RelayHub
            getHubAddr(), // Prevents replays in multiple RelayHubs
            address(this) // Prevents replays in multiple recipients
        );
        if (keccak256(blob).toEthSignedMessageHash().recover(approvalData) == _trustedSigner) {
            return _approveRelayedCall();
        } else {
            return _rejectRelayedCall(uint256(GSNRecipientSignatureErrorCodes.INVALID_SIGNER));
        }
    }

    function _preRelayedCall(bytes memory) internal returns (bytes32) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _postRelayedCall(bytes memory, bool, uint256, bytes32) internal {
        // solhint-disable-previous-line no-empty-blocks
    }

    function updateSigner(address trustedSigner) internal {
        require(trustedSigner != address(0), "GSNRecipientSignature: trusted signer is the zero address");
        _trustedSigner = trustedSigner;
        emit SignerUpdated(trustedSigner);
    }
}
