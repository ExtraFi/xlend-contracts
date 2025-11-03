// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import '../interfaces/IChainlinkAggregator.sol';
import '../interfaces/IVeloTwapPriceAdapter.sol';
import '../interfaces/IVeloPool.sol';
import '../../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import '../../dependencies/openzeppelin/contracts/SafeCast.sol';

/**
 * @title VeloPriceAdapter
 * @author ExtraFi Team
 * @notice Price adapter to calculate price of (Asset / Base) pair using VeloPool (Target / Base)
 *         and Chainlink Data Feeds for the BaseAsset.
 *         For example, it can be used to calculate EXTRA / USD
 *         based on the (EXTRA / ETH) exchange ratio and the ETH / USD Chainlink price feed.
 *
 * @dev This contract is intended solely for indexing and displaying AMM asset prices.
 *      The prices retrieved by this contract are not manipulation-resistant and do not include any protective mechanisms.
 *      DO NOT use the prices from this contract as a source of truth for risk-critical operations such as liquidations,
 *      collateral valuation, or protocol-level decision-making.
 *      This contract is designed for informational and frontend display purposes only.
 */
contract VeloPriceAdapter is IVeloTwapPriceAdapter {
  using SafeCast for uint256;

  // velo pool of the target asset, eg. EXTRA/WETH Pool
  IVeloPool public immutable VELO_POOL;

  // baseAsset's chainlink feeeds used to calculate the price of target price
  IChainlinkAggregator public immutable BASE_AGGREGATOR;

  address public immutable BASE_ASSET;
  address public immutable TARGET_ASSET;

  uint8 internal baseDecimals;
  uint8 internal targetDecimals;
  uint8 internal chainlinkDecimals;
  uint8 internal _decimals;

  string private _description;

  constructor(
    address _pool,
    address _baseAggregator,
    address _baseAsset,
    uint8 __decimals,
    string memory __description
  ) {
    VELO_POOL = IVeloPool(_pool);
    BASE_AGGREGATOR = IChainlinkAggregator(_baseAggregator);

    BASE_ASSET = _baseAsset;

    (address token0, address token1) = VELO_POOL.tokens();
    require(_baseAsset == token0 || _baseAsset == token1, '!B');
    TARGET_ASSET = _baseAsset == token0 ? token1 : token0;

    baseDecimals = IERC20Detailed(BASE_ASSET).decimals();
    targetDecimals = IERC20Detailed(TARGET_ASSET).decimals();
    chainlinkDecimals = BASE_AGGREGATOR.decimals();

    _decimals = __decimals;
    _description = __description;
  }

  function latestAnswer() external view override returns (int256) {
    int256 xRate = VELO_POOL.getAmountOut(10 ** targetDecimals, TARGET_ASSET).toInt256();
    require(xRate > 0, '!xR');

    int256 basePrice = BASE_AGGREGATOR.latestAnswer();
    require(basePrice > 0, '!BP');

    uint256 price = (uint256(xRate) * uint256(basePrice) * (10 ** _decimals)) /
      (10 ** chainlinkDecimals) /
      (10 ** baseDecimals);

    return price.toInt256();
  }

  function description() external view override returns (string memory) {
    return _description;
  }

  function decimals() external view override returns (uint8) {
    return _decimals;
  }
}
