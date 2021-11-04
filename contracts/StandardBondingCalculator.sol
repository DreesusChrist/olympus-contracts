// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;


import "./libraries/FixedPoint.sol";
import "./libraries/Address.sol";
import "./libraries/SafeERC20.sol";

// import "./interfaces/IERC20Metadata.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IBondingCalculator.sol";
import "./interfaces/IUniswapV2ERC20.sol";
import "./interfaces/IUniswapV2Pair.sol";

contract OlympusBondingCalculator is IBondingCalculator {
    using FixedPoint for *;

    IERC20 immutable OHM;

    constructor( address _OHM ) {
        require( _OHM != address(0) );
        OHM = IERC20( _OHM );
    }

    function getKValue( address _pair ) public view override returns ( uint k_ ) {
        uint token0 = IERC20( IUniswapV2Pair( _pair ).token0() ).decimals();
        uint token1 = IERC20( IUniswapV2Pair( _pair ).token1() ).decimals();
        uint decimals = token0.add( token1 ).sub( IERC20( _pair ).decimals() );

        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair( _pair ).getReserves();
        k_ = reserve0.mul(reserve1).div( 10 ** decimals );
    }

    function getTotalValue( address _pair ) public view override returns ( uint _value ) {
        _value = getKValue( _pair ).sqrrt().mul(2);
    }

    function valuation( address _pair, uint256 amount_ ) external view override returns ( uint256 _value ) {
        uint256 totalValue = getTotalValue( _pair );
        uint256 totalSupply = IUniswapV2Pair( _pair ).totalSupply();

        _value = totalValue.mul( FixedPoint.fraction( amount_, totalSupply ).decode112with18() ).div( 1e18 );
    }

    function markdown( address _pair ) external view override returns ( uint256 ) {
        ( uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair( _pair ).getReserves();

        uint256 reserve;
        if ( IUniswapV2Pair( _pair ).token0() == address( OHM ) ) {
            reserve = reserve1;
        } else {
            reserve = reserve0;
        }
        return reserve.mul( 2 * ( 10 ** IERC20(address(OHM)).decimals() ) ).div( getTotalValue( _pair ) );
    }
}
