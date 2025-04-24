// SPDX-License-Identifier: Unlicense
pragma solidity =0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";
import {V3PositionHelper, Position} from "../src/V3PositionHelper.sol";
import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

contract V3PositionHelperTest is Test {
    V3PositionHelper private positionHelper;
    INonfungiblePositionManager private positionManager;

    // Example Arbitrum user holding several Uniswap V3 positions
    address constant TEST_USER = 0x3808699Baf43ba988d1e9acd64237DEA36c61593;
    // Uniswap V3 NonfungiblePositionManager on Arbitrum
    address constant MANAGER_ADDRESS = 0xF0cBce1942A68BEB3d1b73F0dd86C8DCc363eF49;

    function setUp() public {
        // Fork Arbitrum mainnet for testing against live data
        string memory arbUrl = vm.envString("ARB_MAINNET_RPC_URL");
        uint256 forkId = vm.createFork(arbUrl);
        vm.selectFork(forkId);

        // Deploy helper and set the on-chain position manager
        positionHelper = new V3PositionHelper();
        positionManager = INonfungiblePositionManager(MANAGER_ADDRESS);
    }

    /// @notice Should return all positions for TEST_USER
    function testFetchAllUserPositions() public {
        uint256 total = positionManager.balanceOf(TEST_USER);
        Position[] memory positions = positionHelper.getUserPositions(positionManager, TEST_USER, 0, total);

        // Expect count to match on-chain balance
        assertEq(positions.length, total);

        // Each position must reference a valid pool (token0 != zero)
        for (uint256 i = 0; i < positions.length; i++) {
            assertTrue(positions[i].token0 != address(0), "token0 should not be zero");
        }
    }

    /// @notice Tests paging over user positions
    function testFetchUserPositionsInPages() public {
        uint256 total = positionManager.balanceOf(TEST_USER);
        if (total < 2) return; // nothing to page

        uint256 half = total / 2;

        // Fetch first half
        Position[] memory firstHalf = positionHelper.getUserPositions(positionManager, TEST_USER, 0, half);
        assertEq(firstHalf.length, half);

        // Fetch remaining positions
        Position[] memory secondHalf = positionHelper.getUserPositions(positionManager, TEST_USER, half, total);
        assertEq(secondHalf.length, total - half);

        // Ensure pages do not overlap by comparing tokenIds
        assertTrue(firstHalf[half - 1].tokenId != secondHalf[0].tokenId, "Pages should not overlap");
    }

    /// @notice Skipping beyond the user's position count returns an empty array
    function testSkipBeyondBalanceReturnsEmpty() public {
        uint256 total = positionManager.balanceOf(TEST_USER);
        Position[] memory empty = positionHelper.getUserPositions(positionManager, TEST_USER, total + 10, 5);
        assertEq(empty.length, 0, "Expected no positions when skipping past end");
    }

    /// @notice Sanity-check specific token IDs manually
    function testFetchSpecificPositions() public {
        // Hardcoded sample IDs (must exist on Arbitrum)
        uint256[] memory samples = new uint256[](3);
        samples[0] = 69;
        samples[1] = 420;
        samples[2] = 666;

        for (uint256 i = 0; i < samples.length; i++) {
            uint256 id = samples[i];
            Position memory pos = positionHelper.getPosition(positionManager, id);

            // Pool addresses must be valid
            assertTrue(pos.token0 != address(0), "token0 must be non-zero");
            assertTrue(pos.token1 != address(0), "token1 must be non-zero");

            // Verify owed fees never underflow
            (, , , , , , , , , , uint128 storedOwed0, uint128 storedOwed1) = positionManager.positions(id);
            assertTrue(pos.tokensOwed0 >= storedOwed0, "tokensOwed0 should be >= storedOwed0");
            assertTrue(pos.tokensOwed1 >= storedOwed1, "tokensOwed1 should be >= storedOwed1");
        }
    }
}
