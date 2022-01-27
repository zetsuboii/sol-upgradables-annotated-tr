// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/*
  EIP-1822: Universal Upgradeable Proxies(UUPS)

  TransparentUpgradeableProxy'nin bir alternatifi olarak UUPS'ta
  upgrade fonksiyonları implementation kontratında yer alır.

  + Proxy daha hafif olur, daha ucuz deployment
  + Solidity compiler function name clash'ları kendi tespit edebilir
    (çünkü tüm fonksiyonlar aynı kontratta)

  - Eğer implementation'lardan biri upgrade mekanizmasını içermezse
    kontrat bir daha upgrade edilemez

  ### Storage Clash & Unstructured Storage ###

  Proxy'lerde asıl kontratın kodu kopyalanır ve proxy içerisinde çağırılır

  -------------------------------------------------------
  Implementation.sol:
  uint256 v;
  
  function setV(uint256 newV) external {
    v = newV;
  }

  Proxy.sol:
  setV(10)'dan önce     -->       setV(10)'den sonra
  Slot: Değer                     Slot: Değer
  ----------------                ----------------
  0   : 0x000..000                0   : 0x000..00a (0xa == 10)
  1   : 0x000..000                1   : 0x000..000
  -------------------------------------------------------

  Buradaki sıkıntı şu ki eğer proxy kontratının ilk slotunda başka bir değer
  varsa Implementation setV fonksiyonunu çağırdığında v değişkenini değil
  proxy'deki o değişkeni değiştirir.

  -------------------------------------------------------
  Implementation.sol @ 0x4ad..b12
  contract Implementation {
    uint256 v;
    
    function setV(uint256 newV) external {
      v = newV;
    }
  }

  Proxy.sol:
  contract Proxy {
    address implementation;
  }

  setV(10)'dan önce     -->       setV(10)'den sonra
  Slot: Değer                     Slot: Değer
  ----------------                ----------------
  0   : 0x4ad..b12                0   : 0x000..00a (0xa == 10)
  1   : 0x000..000                1   : 0x000..000

  (
    setV fonksiyonu implementation'ın üzerinde 10 yazdığı için artık
    proxy çalışamaz
  )
  -------------------------------------------------------

  Bu sorunun çözümü için implementation adresi ilk slota değil, üzerine
  yazılması mümkün olmayan bir storage slot'una yazılır. Bu durumda 
  hash collision olma ihtimali 1/2^256 yani neredeyse 0 olur

  Buna OpenZeppelin "Unstructured Storage Pattern" diyor.

  Bu storage slot'u EIP-1822 standardına göre keccak256("PROXIABLE")'dır.
  Hemen ardından gelen EIP-1967 bu slot isimlerini daha standard bir hale soktu.

  Logic/Implementation adresi (UUPS sadece bunu kullanıyor)
  -> bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
  =  0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc 

  Beacon Adresi
  -> bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)
  =  0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50

  Admin Adres
  -> bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
  =  0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
  
  [1]: https://eips.ethereum.org/EIPS/eip-1822
  [2]: https://eips.ethereum.org/EIPS/eip-1967
*/
contract UUPSProxy {
  //  bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
  bytes32 private constant implementationSlot = 
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc; 

  constructor(address baseImplementation) {
    bytes32 slot = implementationSlot;
    assembly {
      // Adresi belirlediğimiz slota yazıyoruz
      // Implementation da aynı yöntemle aynı slota yeni
      // adresi yazabilir
      sstore(slot, baseImplementation)
    }
  }

  fallback() external payable {
    bytes32 slot = implementationSlot;
    
    assembly {
      // Öncesinde kaydettiğimiz slottan kontrat
      // adresini al
      let implementation := sload(slot)

      // Adres üzerinden delegatecall yap
      // delegatecall(gas, address, argsOffset, argsSize, returnOffset, returnSize)
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
    
      // Eğer delegatecall 0 dönerse hata ver yoksa return yap
      // NOT: Doğru yazımı böyle değil, sadece gösterim amaçlı
      switch result
      case 0  { revert(0, 0)}
      default { return(0, 0)}
    }
  }
}

abstract contract UUPSProxiable {
  address admin;

  constructor() { admin = msg.sender; }

  function upgrade(address newImplementation) external {
    require(msg.sender == admin);

    bytes32 implementationSlot = 
      0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc; 
    
    assembly {
      sstore(implementationSlot, newImplementation)
    }
  }
}
