/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.5.0 < 0.6.0;

import "./compat/Initializable.sol";
import "./compat/ERC20.sol";
import "./compat/SafeMath.sol";
import "./compat/Address.sol";
import "./compat/Ownable.sol";
import "./compat/UpdatableGSNRecipientSignatureCompat.sol";

import "./IEthBridgedToken.sol";
import "./Frozen.sol";
import "./EthSubredditPointsCompat.sol";

/*
    SubredditPoints ERC20 token Compatible with Rinkeby implementation/OZ 2.x libraries.
    This one is obsolete and is only preserved if
    it's required to rollback for some reason.
*/

contract EthSubredditPointsObsoleteCompat is InitializableCompat, OwnableCompat, UpdatableGSNRecipientSignatureCompat, ERC20Compat {
    using SafeMath for uint256;
    using Address for address;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
    event DefaultOperatorAdded(address indexed operator);
    event DefaultOperatorRemoved(address indexed operator);

    // ------------------------------------------------------------------------------------
    // VARIABLES BLOCK, MAKE SURE ONLY ADD TO THE END

    string internal _subreddit;
    string internal _name;
    string internal _symbol;

    // operators notion from ERC777, accounts can revoke default operator
    mapping(address => bool) internal _defaultOperators;

    // Maps operators and revoked default operators to state (enabled/disabled)
    mapping(address => mapping(address => bool)) internal _operators;
    mapping(address => mapping(address => bool)) internal _revokedDefaultOperators;

    // operators notion from ERC777, accounts can revoke default operator
    // This isn't ever read from - it's only used to respond to the defaultOperators query.
    address[] internal _defaultOperatorsArray;

    address _distributionContract;

    // END OF VARS
    // ------------------------------------------------------------------------------------

    function initialize(
        address owner_,
        address gsnApprover_,
        address distributionContract_,
        string calldata subreddit_,
        string calldata name_,
        string calldata symbol_,

        address[] calldata defaultOperators_
    ) external initializer {
        require(bytes(subreddit_).length != 0, "SubredditPoints: subreddit can't be empty");
        require(bytes(name_).length != 0, "SubredditPoints: name can't be empty");
        require(bytes(symbol_).length != 0, "SubredditPoints: symbol can't be empty");
        require(owner_ != address(0), "SubredditPoints: owner should not be 0");

        OwnableCompat.initialize(owner_);
        UpdatableGSNRecipientSignatureCompat.initialize(gsnApprover_);

        updateDistributionContract(distributionContract_);

        _subreddit = subreddit_;
        _name = name_;
        _symbol = symbol_;

        _defaultOperatorsArray = defaultOperators_;
        for (uint256 i = 0; i < defaultOperators_.length; i++) {
            _defaultOperators[defaultOperators_[i]] = true;
            emit DefaultOperatorAdded(defaultOperators_[i]);
        }
    }

    function mint(
        address operator,
        address account,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external {
        require(_msgSender() == _distributionContract, "SubredditPoints: only distribution contract can mint points");

        super._mint(account, amount);
        emit Minted(operator, account, amount, userData, operatorData);
    }

    function burn(
        uint256 amount,
        bytes calldata userData
    ) external {
        address account = _msgSender();
        _burn(account, account, amount, userData, "");
    }

    function isOperatorFor(
        address operator,
        address tokenHolder
    ) public view returns (bool) {
        return operator == tokenHolder ||
            (_defaultOperators[operator] && !_revokedDefaultOperators[tokenHolder][operator]) ||
            _operators[tokenHolder][operator];
    }

    function authorizeOperator(address operator) external {
        require(_msgSender() != operator, "SubredditPoints: authorizing self as operator");
        require(address(0) != operator, "SubredditPoints: operator can't have 0 address");

        if (_defaultOperators[operator]) {
            delete _revokedDefaultOperators[_msgSender()][operator];
        } else {
            _operators[_msgSender()][operator] = true;
        }

        emit AuthorizedOperator(operator, _msgSender());
    }

    function revokeOperator(address operator) external {
        require(operator != _msgSender(), "SubredditPoints: revoking self as operator");
        require(address(0) != operator, "SubredditPoints: operator can't have 0 address");

        if (_defaultOperators[operator]) {
            _revokedDefaultOperators[_msgSender()][operator] = true;
        } else {
            delete _operators[_msgSender()][operator];
        }

        emit RevokedOperator(operator, _msgSender());
    }

    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external {
        address operator = _msgSender();
        require(isOperatorFor(operator, sender), "SubredditPoints: caller is not an operator for holder");
        _transfer(sender, recipient, amount);
        emit Sent(operator, sender, recipient, amount, userData, operatorData);
    }

    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external {
        address operator = _msgSender();
        require(isOperatorFor(operator, account), "SubredditPoints: caller is not an operator for holder");
        _burn(operator, account, amount, data, operatorData);
    }

    function defaultOperators() external view returns (address[] memory) {
        return _defaultOperatorsArray;
    }

    function addDefaultOperator(address operator) external onlyOwner {
        require(operator != address(0), "SubredditPoints: operator address shouldn't be 0");
        require(!_defaultOperators[operator], "SubredditPoints: operator already exists");

        _defaultOperatorsArray.push(operator);
        _defaultOperators[operator] = true;

        emit DefaultOperatorAdded(operator);
    }

    function removeDefaultOperator(address operator) external onlyOwner {
        require(operator != address(0), "SubredditPoints: operator address shouldn't be 0");
        require(_defaultOperators[operator], "SubredditPoints: operator doesn't exists");

        for (uint256 i = 0; i < _defaultOperatorsArray.length; i++) {
            if (_defaultOperatorsArray[i] == operator) {
                if (i != (_defaultOperatorsArray.length - 1)) { // if it's not last element, replace it from the tail
                    _defaultOperatorsArray[i] = _defaultOperatorsArray[_defaultOperatorsArray.length-1];
                }
                _defaultOperatorsArray.length = _defaultOperatorsArray.length - 1;
                break;
            }
        }
        delete _defaultOperators[operator];

        emit DefaultOperatorRemoved(operator);
    }

    function _burn(
        address operator,
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal {
        super._burn(account, amount);
        emit Burned(operator, account, amount, userData, operatorData);
    }

    function subreddit() external view returns (string memory) {
        return _subreddit;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function updateGSNApprover(address gsnApprover) external onlyOwner {
        updateSigner(gsnApprover);
    }

    function updateDistributionContract(address distributionContract_) public onlyOwner {
        require(distributionContract_ != address(0), "SubredditPoints: distributionContract should not be 0");
        _distributionContract = distributionContract_;
    }

    function distributionContract() external view returns (address) {
        return _distributionContract;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }
}
