// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/*
  EIP897, Transparent Proxy ve UUPS'in ortak noktaları tek bir implementation
  üzerinden çalışmaları.

  Diamond Proxy vtable aracılığıyla birden fazla implementation ile 
  etkileşme imkanı sağlar.

  Bunun için msg.sig'lere karşılık adreslerin geldiği bir implemenations mapping'i
  kullanılır. 
  > balanceOf(address user) çağrıldığında msg.sig "balanceOf(address)" döner
  Bu sayede her bir fonksiyon ayrı bir implementation adresi (facet diye geçiyor)
  üzerinde tutulabilir.

  Bu implementation'lar (facet'ler) storage'dan ayrı olduğu için farklı kontratlar 
  tarafından tekrar tekrar kullanılabilir.

  Implementation'lar arasında storage clash yaşanmaması için her bir kontratın 
  storage'ı ayrı bir struct içerisinde tutulur. Kontratlar bu storage'a isim 
  verip bu ismin hash'inde struct'ı saklar.

  * Bu isimlendirmenin net bir standardı yok, EIP-2535 spesifikasyonunda 
    "diamond.storage.<storage ismi>" kullanılıyor

  * Bu mekanizma bir library içerisinde de yapılabilir. Bu sayede aynı storage 
  kullanmak isteyen bir kontrat bu kütüphane ile etkileşebilir.

  * Sadece storage library üzerinde tutulabileceği gibi tüm implementation 
  da library ile sağlanabilir.

  * Farklı kontratlar aynı storage'ı kullanamaz, bu durumla baş etmek için 
  AppStorage denen başka bir pattern kullanılabilir. Bu pattern'da tüm state AppStorage
  denen bir struct'ta tutulur ve kontratın en başında bu struct tanımlanır

  contract MyFacet {
    AppStorage internal s;
  }

  Böylece kontratın state'ine erişmek isteyen library'ler doğrudan ilk slot'u 
  kullanabilir. 

  (?) Ortak state AppStorage'da, diamond pattern ile alakalı state DiamondStorage'da,
  facet'lere özel state'ler de facet ismine özel slottaki storage'da tutulabilir

  Pattern genel olarak modülerite üzerine kuruludur, hatta bu sebeple upgradeable
  olmayan diamond kontratlar da yazmak mümkündür. Modülerite karşılığında teoride
  sınırsız storage kullanılabilir ama kod daha kompleks bir yapıya bürünür.

  Diamond kullanan bir token için bkz. [4]
  
  [1]: https://eips.ethereum.org/EIPS/eip-2535
  [2]: https://medium.com/1milliondevs/new-storage-layout-for-proxy-contracts-and-diamonds-98d01d0eadb
  [3]: https://dev.to/mudgen/appstorage-pattern-for-state-variables-in-solidity-3lki
  [4]: https://github.com/aavegotchi/ghst-staking/blob/master/contracts/facets/GHSTStakingTokenFacet.sol
*/

struct FirstImplStorage {
  uint256 value1;
}

struct SecondImplStorage {
  uint256 value2;
}

library DiamondStorageLib {
  struct DiamondStorage {
    address owner;
    mapping(address => uint256) balances;
  }

  function diamondStorage() internal pure returns (DiamondStorage storage ds){
    bytes32 dsSlot = keccak256(abi.encodePacked("diamond.storage.diamondStorage"));
    assembly {
      // Storage data atanırken .offset ya da .slot belirtilir, sload kullanılmaz
      ds.slot := dsSlot
    }
  } 

  function setOwner(address owner) external {
    diamondStorage().owner = owner;
  } 

}

contract DiamondProxy {
  mapping(bytes4 => address) implementations;
  
  function changeOwner(address owner) external {
    DiamondStorageLib.DiamondStorage storage ds = 
      DiamondStorageLib.diamondStorage();

    /*
      İlk başta sanki başka bir kontratın storage'ı değiştiriliyor gibi gelse de
      aslında library içerisinde "storage'ın x slot'unu y yap" tarzı ifadeler
      içerdiğinden asıl değişiklik DiamondProxy kontratı içerisinde.

      Bu yüzden başka bir kontrat DiamondStorageLib ile etkileştiğinde ds.owner 
      address(0) olacaktır
    */

    require(ds.owner == msg.sender, "Not owner");
    ds.owner = owner;
  }

  fallback() external payable {
    address implementation = implementations[msg.sig];
    
    (bool success, ) = implementation.delegatecall(msg.data);
    require(success);
  }
}

contract FirstImplementation {
  // Visibility internal olmalı yoksa dışarıdan gelen bir çağrıda storage 
  // değişken döndürülemez
  function firstStorage() internal pure returns(FirstImplStorage storage fs) {
    bytes32 fsSlot = keccak256(abi.encodePacked("diamond.storage.firstStorage"));
    assembly {
      fs.slot := fsSlot
    }
  }
}