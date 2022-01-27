// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/*
  Diyelim ki standard UUPS Proxy kontratımız ve 
  bir Implementation kontratımız var 

  contract ImplementationV1 {
    address owner = "0xdeadbeef";
    uint256 totalSupply = 10;
  }

  Eğer kontratın ikinci versiyonunda bu değişkenlerin yeri değiştirilirse

  contract ImplementationV2 {
    uint256 totalSupply;
    address owner;
  }

  totalSupply = 3735928559 (uint256(0xdeadbeef))
  owner = 0x000000000000a (10 = 0xa) olur. Bunun sebebi Solidity'nin değişkenleri
  bulunduğu slot üzerinden değerlendirmesi.

  (Geri kalan kısıtlamalar için bkz. [1])

  Bunun üzerinden gelmek için iki yol var
  1. Append Only Storage
  Eğer storage'ı ayrı bir kontratta tutup, bu kontrata sadece ekleme yapılırsa
  hiçbir slot'un yeri değişmez ve sıkıntı çözülür.
  Compound ComptrollerStorage altında bu pattern'ı kullanıyor.

  -------------------------------------------------------
  contract Storage1 {
    uint256 value1;
    uint256 value2;
  }

  contract Storage2 is Storage1 {
    uint256 value3;
  }

  contract Storage3 is Storage2 {
    address address1;
  }
  -------------------------------------------------------

  Bu sayede kontrat state'i istenilen kadar arttırılabilir, ama geriye dönük bir
  düzeltme yapılamaz. Ayrıca inheritance sırası karıştırılırsa değişkenler karışır

  2. Eternal Storage
  Bu yaklaşımda değişkenler mappinglerde tutulur ve bu sayede yeni eklenen 
  değişkenler bir sonraki slotta değil değişken ismine bağlı bir slotta tutulur.
  PolyMath tokenları bu pattern'ı kullanıyor.

  > 1. slotta bulunan mappingdeki "value" key'i
    keccak256(keccak256("value") . 1)'de bulunur
    (0x73b13facbbcce6722fabab30ec75e38eccaf4affe5369ddfa10eeee348dea5fd)

  Bu yaklaşımda immutable storage ihtiyacı kalkar ama bu sefer de yazım yanlışları
  compiler hatası vermez, ayrıca diğer kontratlarla uyumsuz garip bir kod oluşur.

  Genelde kullanımı önerilmiyor

  [1]: https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#modifying-your-contracts
  [2]: https://blog.openzeppelin.com/smart-contract-upgradeability-using-eternal-storage/
*/
contract EternalStorage {
    mapping(bytes32 => uint256) internal  uint256Storage;
    mapping(bytes32 => string)  internal  stringStorage;
    mapping(bytes32 => address) internal  addressStorage;
    mapping(bytes32 => bytes)   internal  bytesStorage;
    mapping(bytes32 => bool)    internal  boolStorage;
    mapping(bytes32 => int256)  internal  intStorage;
}

contract Implementation is EternalStorage {
  function setTotalSupply(uint256 value) external {
    uint256Storage["totalSupply"] = value;
  }

  function getTotalSupply() external view returns(uint256) {
    return uint256Storage["totalSupply"];
  }
}