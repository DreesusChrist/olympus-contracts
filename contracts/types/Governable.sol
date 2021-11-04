// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.0;

import "../interfaces/IGovernable.sol";

contract Governable is IGovernable {

    address internal _governor;
    address internal _newGovernor;


    event GovernorPushed(address indexed previousGovernor, address indexed newGovernor);
    event GovernorPulled(address indexed previousGovernor, address indexed newGovernor);


    constructor () {
        _governor = msg.sender;
        emit GovernorPulled( address(0), _governor );
    }

    /* ========== GOVERNOR ========== */

    function governor() public view override returns (address) {
        return _governor;
    }

    modifier onlyGovernor() {
        require( _governor == msg.sender, "Governable: caller is not the governor" );
        _;
    }

    function renounceGovernor() public virtual override onlyGovernor() {
        emit GovernorPushed( _governor, address(0) );
        _governor = address(0);
    }

    function pushGovernor( address newGovernor_ ) public virtual override onlyGovernor() {
        require( newGovernor_ != address(0), "Governable: new governor is the zero address");
        emit GovernorPushed( _governor, newGovernor_ );
        _newGovernor = newGovernor_;
    }
    
    function pullGovernor() public virtual override {
        require( msg.sender == _newGovernor, "Governable: must be new governor to pull");
        emit GovernorPulled( _governor, _newGovernor );
        _governor = _newGovernor;
    }
}