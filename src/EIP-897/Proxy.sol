// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERCProxy.sol";

contract Proxy is ERCProxy {
  // EIP-1967 slotları
  bytes32 private constant implementationSlot = 
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc; 

  bytes32 private constant adminSlot =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  // EIP-897 sabiti
  uint256 private constant UPGRADEABLE = 2;

  constructor(address baseImplementation) {
    assembly {
      // admin = msg.sender
      sstore(adminSlot, caller())
      // implementation = baseImplementation
      sstore(implementationSlot, baseImplementation)
    }
  }

  // EIP-897 fonksiyonları 
  function proxyType() external pure returns(uint256 proxyTypeId) {
    return UPGRADEABLE;
  }

  function implementation() external view returns(address codeAddr) {
    assembly {
      codeAddr := sload(implementationSlot)
    }
  }

  // Implementation adresini değiştirir
  function upgradeTo(address newImplementation) external {
    address admin;

    assembly { admin := sload(adminSlot) }
    
    if(msg.sender != admin) {
      // Eğer admin değilse implementation'a yönlendiriyoruz
      _fallback();
    }
    else {
      assembly {
        // Implementation'ı değiştir
        sstore(implementationSlot, newImplementation)
      } 
    }
  }

  // Delegate call işlemini yapar
  function _fallback() internal {
    assembly {
      // Calldata'daki veriyi memory'nin 0 kısmına kopyala
      // Normalde assembly içerisinde yeni değişkenler free memory pointerına
      // kopyalanır, böyle yaparak proxy'deki memory baştan yazılıyor.
      // calldatacopy(from, to, size)
      calldatacopy(0, 0, calldatasize())

      // Implementation adresini al
      let impl := sload(implementationSlot)

      /* 
       Delegate call'ı gerçekleştir. Delegate call değişkenleri
       - gas:         kullanılacak gaz
       - address:     call yapılacak address
       - argsOffset:  fonksiyon argümanları nerede başlıyor?
                        calldata'yı 0'a kopyaladığımız için bu 0 olacak
       - argsSize:    fonksiyon argümanlarını boyutu ne?
                        calldatasize() calldata'daki datanın tamamını iletir
       - retOffset:   dönen değerleri nereye kopyalanacak?
       - retSize:     dönen değerlerin boyutu ne?

       retOffset ve retSize daha bilinmediği için 0 olacak
      */
      let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
    
      // Dönen data'yı memory'nin 0 kısmına kopyala
      // returndatacopy(from, to, size)
      returndatacopy(0, 0, returndatasize())

      // Eğer delegatecall hata verirse 0 döndürecek, bu durumda rever yapacağız
      // revert(from, size)
      // return(from, size)
      switch result
      case 0  { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }

  fallback() external payable {
    _fallback();
  }

  receive() external payable {
    _fallback();
  }
}

contract ImplV1 {
    uint256 value;
    function getValue() external view returns(uint256) {
        return value;
    }

    function setValue(uint256 newValue) external {
        value = newValue;
    }
}

contract ImplV2 {
    uint256 value;
    function getValue() external view returns(uint256) {
        return value;
    }

    function setValue(uint256 newValue) external {
        value = newValue*2;
    }
}