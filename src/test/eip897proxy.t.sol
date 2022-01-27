// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "ds-test/test.sol";
import "../EIP-897/Proxy.sol";

contract Implementation {
    function getValue() external view returns(uint256) {}
    function setValue(uint256 newValue) external {}
}

contract ContractTest is DSTest {
    Proxy proxy;
    ImplV1 implV1;
    ImplV2 implV2;


    function setUp() public {
        implV1 = new ImplV1();
        implV2 = new ImplV2();
        proxy = new Proxy(address(implV1));
    }

    function testAll() public {
        // Cast proxy to Implementation
        Implementation impl = Implementation(address(proxy));
        
        impl.setValue(5);
        assertEq(impl.getValue(), 5);

        // Upgrade to second version which setsValue to its double
        proxy.upgradeTo(address(implV2));

        impl.setValue(5);
        assertEq(impl.getValue(), 10);
    }
}
