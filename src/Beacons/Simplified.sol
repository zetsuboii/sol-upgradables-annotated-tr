// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/*
  Diamond pattern'da tek bir proxy ile birden fazla kontratla etkileşebiliyorduk.
  Beacon Pattern da birçok proxy'nin aynı implementation'la etkileşmesini amaçlar.
  
  Bu sayede implementation değiştiğinde proxy'leri tek tek güncelleme gereği ortadan
  kalkar.

  Implementation Beacon kontratı üzerinde bulunur ve Proxy'ler her işlemden önce
  proxy'i beacon kontratından alır. Bu durumda proxy'ler sadece immutable bir beacon
  tutar, bu sayede de storage'ı kullanmaz.

  Beacon pattern'da deployment proxy deployment'ı ucuzlar, işlem başına harcanan gaz
  artar.
*/
contract BeaconProxy {
  Beacon immutable beacon;
  constructor(Beacon beaconAddr) { beacon = beaconAddr; }

  fallback() external payable {
    address implementation = beacon.implementation();
    (bool success, ) = implementation.delegatecall(msg.data);
    require(success);
  }

}

contract Beacon {
  address owner;
  address public implementation;
  constructor() { owner = msg.sender; }

  function upgrade(address newImplementation) external {
    require(msg.sender == owner, "Only owner");
    implementation = newImplementation;
  }
}