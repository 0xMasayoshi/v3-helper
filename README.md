# v3-helper

A lightweight set of utilities for interacting with **Uniswap V3 positions**, starting with the included `V3PositionHelper` contract.
This helper returns **real-time fee accruals** for any Uniswap V3 LP NFT, fixing a long‑standing limitation of `INonfungiblePositionManager.positions()` where `tokensOwed0`/`tokensOwed1` become stale.

More helpers may be added in the future — the current implementation focuses solely on the `V3PositionHelper` contract.

---

## Features

- Fetch full Uniswap V3 NFT position data including ticks, liquidity, fee growth, operator, token addresses, etc.
- **Real-time fee computation** using a modified `PositionValue` library
- Batch queries (`getPositions`)
- Paginated user-owned position queries (`getUserPositions`)
- Clean `Position` struct mirroring on-chain values with updated `tokensOwed*`

---

## Contract Overview

### `V3PositionHelper.sol`

Exposes three primary read functions:

| Function | Description |
----------|-------------|
| `getPosition(positionManager, tokenId)` | Returns a full position with **live` tokensOwed0`/`tokensOwed1`** |
| `getPositions(positionManager, tokenIds[])`| Batch version of `getPosition` |
| `getUserPositions(positionManager, user, skip, first)` | Paginated retrieval of all positions owned by a wallet. |

---

## Position Struct

```solidity
struct Position {
    uint256 tokenId;
    uint96 nonce;
    address operator;
    address token0;
    address token1;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    uint128 liquidity;
    uint256 feeGrowthInside0LastX128;
    uint256 feeGrowthInside1LastX128;
    uint128 tokensOwed0;
    uint128 tokensOwed1;
}
```

Mirrors Uniswap's on-chain tuple exactly, with one key improvement: `tokensOwed0`/`tokensOwed1` reflect **current** unclaimed fees.

---

## Usage Example

```solidity
INonfungiblePositionManager pm = INonfungiblePositionManager(POSITION_MANAGER);
V3PositionHelper helper = new V3PositionHelper();

Position memory pos = helper.getPosition(pm, 12345);

// pos.tokensOwed0 / pos.tokensOwed1 now include real-time fee accruals
```

---

## Development

Pure Foundry. No npm, Hardhat, or TypeScript.

Install dependencies:

```sh
forge install
```

Build:

```sh
forge build
```

Run tests:

```sh
forge test
```

---

## Repository Structure

```plain
src/
  V3PositionHelper.sol
  libraries/
    PositionValue.sol    # Modified from @uniswap/v3-periphery
test/
  V3PositionHelper.t.sol
```