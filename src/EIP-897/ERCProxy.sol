// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ERCProxy {
  // Bir kontrat proxy midir kontrol etmemizi sağlar
  // Eğer proxy hep aynı adrese yönlendiriyorsa 1 döner
  // Eğer implementation değişebiliyorsa 2 döner
  function proxyType() external pure returns(uint256 proxyTypeId);
  
  // Delegatecall'ın çağrıları ileteceği adres
  function implementation() external view returns(address codeAddr);
}