// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

//Imports to use Foundry's testing and logging suite
import {Test} from "forge-std/Test.sol";

//Imports to use the LayerZero contracts
import {LZEndpointMock} from "@layerzero-contracts/mocks/LZEndpointMock.sol";
import {OmniCounter_Sepolia} from "../src/OmniCounter_Sepolia.sol";
import {OmniCounter_Mumbai} from "../src/OmniCounter_Mumbai.sol";

/**
 * @title OmniCounterTest
 * @dev This contract is used to test the functionality of the OmniCounter contracts.
 */
contract OmniCounterTest is Test {

    LZEndpointMock public srclzEndpointMock;
    LZEndpointMock public destlzEndpointMock;

    OmniCounter_Sepolia public omniCounter_Sepolia;
    OmniCounter_Mumbai public omniCounter_Mumbai;

    uint16 public constant srcChainId = 1221;
    uint16 public constant destChainId = 4224;

    /**
     * @dev Sets up the initial state for the test.
     */
    function setUp() public {

        vm.deal(address(0x1), 100 ether);
        vm.deal(address(0x2), 100 ether);
        vm.deal(address(0x3), 100 ether);

        vm.prank(address(0x1));
        srclzEndpointMock = new LZEndpointMock(srcChainId);
        destlzEndpointMock = new LZEndpointMock(destChainId);

        vm.prank(address(0x2));
        omniCounter_Sepolia = new OmniCounter_Sepolia(address(srclzEndpointMock));

        vm.prank(address(0x3));
        omniCounter_Mumbai = new OmniCounter_Mumbai(address(destlzEndpointMock));

        vm.deal(address(srclzEndpointMock), 100 ether);
        vm.deal(address(omniCounter_Sepolia), 100 ether);
        vm.deal(address(omniCounter_Mumbai), 100 ether);


        vm.startPrank(address(0x1));
        srclzEndpointMock.setDestLzEndpoint(address(omniCounter_Mumbai), address(destlzEndpointMock));
        destlzEndpointMock.setDestLzEndpoint(address(omniCounter_Sepolia), address(srclzEndpointMock));
        vm.stopPrank();
        
        bytes memory omniCounter_Mumbai_Address = abi.encodePacked(uint160(address(omniCounter_Mumbai)));
        bytes memory omniCounter_Sepolia_Address = abi.encodePacked(uint160(address(omniCounter_Sepolia)));


        vm.prank(address(0x2));
        omniCounter_Sepolia.setTrustedRemoteAddress(destChainId, omniCounter_Mumbai_Address);

        vm.prank(address(0x3));
        omniCounter_Mumbai.setTrustedRemoteAddress(srcChainId, omniCounter_Sepolia_Address);

    }

    /**
     * @dev Tests the counter increment from Sepolia to Mumbai.
    */
    function test_SepoliaToMumbai() public {

        uint counter_initial = omniCounter_Sepolia.counter();

        vm.deal(address(0x10), 100 ether);
        vm.prank(address(0x10));
        omniCounter_Sepolia.incrementCounter{value: 1 ether}(destChainId);
        assertEq(omniCounter_Mumbai.counter(), counter_initial+1);
    }

    /**
     * @dev Tests the counter increment from Mumbai to Sepolia.
    */
    function test_MumbaiToSepolia() public {

        uint counter_initial = omniCounter_Mumbai.counter();

        vm.deal(address(0x10), 100 ether);
        vm.prank(address(0x10));
        omniCounter_Mumbai.incrementCounter{value: 1 ether}(srcChainId);
        assertEq(omniCounter_Sepolia.counter(), counter_initial+1);
    }
 
}
