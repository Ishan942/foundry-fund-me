// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant startingBalance = 10e18;
    uint256 public constant SEND_VALUE = 0.1 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, startingBalance);
    }

    function testMinimumDollar() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        //here the contract is deployed by FundMeTest not us
        //we should check the address of fundMe test is equal to owner
        //address.this refers to the adress that deployed FundMeCOntract
        //msg,sender is the adress thet is executing this test
        // assertEq(fundMe.i_owner(), address(this));
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutMinFunds() public {
        vm.expectRevert(); //the next line should revert
        fundMe.fund(); //this line reverts as the funds sent are zero
    }

    function testFundUpdatesFundedArray() public {
        vm.prank(USER); //the next transaction will be sent by USER address
        //10e18 means 10Ether
        fundMe.fund{value: 10e18}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, 10e18);
    }

    function testAddFundersToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: 10e18}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier fundContract() {
        vm.prank(USER);
        fundMe.fund{value: 10e18}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public fundContract {
        //fund the contract with some money from user account

        vm.expectRevert();
        //vm.expect revers skips over the next vm cheatcodes and only considrs the next line that is not a vm cheat code
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithFunder() public fundContract {
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    // function tesetWithDrawFromMultipleFunders() public fundContract {
    //     uint160 numberOfFunders = 10;
    //     uint160 startingFunderIndex = 1; //cannot be zero as adress 0 cannnot transcat with
    //     for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
    //         hoax(address(i), SEND_VALUE);
    //         fundMe.fund{value: SEND_VALUE}();
    //     }
    //     uint256 startingOwnerBalance = fundMe.getOwner().balance;
    //     uint256 startingFundMeBalance = address(fundMe).balance;

    //     vm.startPrank(fundMe.getOwner());
    //     fundMe.withdraw();
    //     vm.stopPrank();

    //     assert(address(fundMe).balance == 0);
    //     assert(
    //         startingFundMeBalance + startingOwnerBalance ==
    //             fundMe.getOwner().balance
    //     );
    // }

    function testWithdrawFromMultipleFunders() public fundContract {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    function testWithdrawFromMultipleFundersCheap() public fundContract {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2; //cannot be zero as adress 0 cannnot transcat with
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
