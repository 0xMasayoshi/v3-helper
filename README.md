# v3-helper

A lightweight set of utilities for interacting with **Uniswap V3 positions**, starting with the included `V3PositionHelper` contract.
This helper returns **real-time fee accruals** for any Uniswap V3 LP NFT, fixing a long‑standing limitation of `INonfungiblePositionManager.positions()` where `tokensOwed0`/`tokensOwed1` become stale.

More helpers may be added in the future — the current implementation focuses solely on the `V3PositionHelper` contract.

---

## Features

- Fetch full Uniswap V3 NFT position data including:
  - ticks
  - liquidity
  - feeGrowth values
  - operator, token addresses, etc.
- **Real-time fee computation** using Uniswap's `PositionValue` library
- Batch queries (`getPositions`)
- Paginated user-owned position queries (`getUserPositions`)
- Clean `Position` struct mirroring on-chain values with updated `tokensOwed*`

---

## Contract Overview

### `V3PositionHelper.sol`

The helper exposes three primary read functions:

### `getPosition(positionManager, tokenId)`
Returns a full position with **live** `tokensOwed0`/`tokensOwed1`, recomputed via `PositionValue._fees`.

### `getPositions(positionManager, tokenIds[])`
Batch version of `getPosition`.

### `getUserPositions(positionManager, user, skip, first)`
Efficient paginated retrieval of all positions owned by a wallet.

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

This mirrors Uniswap’s tuple exactly, with one key improvement:
`tokensOwed0`/`tokensOwed1` reflect **current** unclaimed fees.

---

## Usage Example

```solidity
INonfungiblePositionManager pm = INonfungiblePositionManager(POSITION_MANAGER);
V3PositionHelper helper = new V3PositionHelper();

Position memory pos = helper.getPosition(pm, 12345);

// pos.tokensOwed0 / pos.tokensOwed1 now include real-time fee accruals
```

---

## Known Limitations

### 🧩 Pools With Non-Standard Init Code Hashes

`PositionValue._fees` depends on Uniswap's canonical pool address derivation:

```
keccak256(abi.encodePacked(
    hex"ff",
    factory,
    keccak256(abi.encode(token0, token1, fee)),
    POOL_INIT_CODE_HASH
))
```

If a chain/fork/L2 deploys a Uniswap V3 implementation with a **different init code hash**, fee computation will fail or return zeroes because the library cannot locate the pool.

This repo does **not yet** include a mechanism to override or dynamically detect the init code hash.

Possible approaches (future enhancement):
- Allow passing a custom init code hash as a parameter
- Attempt on-chain probing of candidate hashes (expensive; not recommended)

For now, this limitation is simply documented.

---

## Patch Required for `PositionValue`

To access `_fees(...)` externally, the following change was applied via `pnpm patch`:

```diff
- function _fees(...) private view returns (...)
+ function _fees(...) internal view returns (...)
```

This repo expects that patched version of the Uniswap V3 periphery library.

---

## Development

Install dependencies:

```sh
pnpm install
```

Build:

```sh
pnpm compile
```

Foundry:

```sh
forge build
```

Run tests:

```sh
pnpm test:hh
forge test
```

---

## Repository Structure

```
contracts/
  V3PositionHelper.sol
```

Only one helper exists today; more may be added later.

---

## Deployments

| Network  | Address                                    |
| -------- | ------------------------------------------ |
| Ethereum | 0x34026A9b9Cb6DF84880C4B2f778F5965F5679c16 |
| Arbitrum | 0x34026A9b9Cb6DF84880C4B2f778F5965F5679c16 |
| Avalanche | 0x34026A9b9Cb6DF84880C4B2f778F5965F5679c16 |
| Base | 0x34026A9b9Cb6DF84880C4B2f778F5965F5679c16 |
| BSC | 0x34026A9b9Cb6DF84880C4B2f778F5965F5679c16 |
| Linea | 0x34026A9b9Cb6DF84880C4B2f778F5965F5679c16 |
| Optimism | 0x34026A9b9Cb6DF84880C4B2f778F5965F5679c16 |
| Polygon | 0x34026A9b9Cb6DF84880C4B2f778F5965F5679c16 |
| Rootstock | 0x34026A9b9Cb6DF84880C4B2f778F5965F5679c16 |
| Scroll | 0x34026A9b9Cb6DF84880C4B2f778F5965F5679c16 |
| Sonic | 0x34026A9b9Cb6DF84880C4B2f778F5965F5679c16 |
| Hemi | 0x34026A9b9Cb6DF84880C4B2f778F5965F5679c16 |

---