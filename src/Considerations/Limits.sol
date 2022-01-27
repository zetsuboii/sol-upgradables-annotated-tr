// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/*
  Upgradeable kontratlar yazarken dikkat edilecek bazı noktalar var
  * Constructor kullanılamaz
    * Onun yerine kontratlar içerisinde bir kere çağırılabilen initialize
      fonksiyonu bulunur
    * Inherit edilen kontratlar da constructor kullanamaz. Parent kontratlarda
      da aynı şekilde initialize fonksiyonu bulunmalı 
  * Default value atanamaz
  * Kontrat içerisinde kontrat oluşturulamaz
    * Eğer böyle bir şey isteniyorsa, kontrat dışarıda oluşturulup içeride 
      bu kontratın adresini alıp içerisindeki initialize fonksiyonunu çağıran
      bir yapı olmalı
  * Implementation'da public selfdestruct/delegatecall olmamalı
    * Herkes proxy'den bağımsız implementation'ı çağırabileceği için bu iki
      komut ile implementation kontratı yok edilebilir.
      Eğer UUPS kullanılıyorsa bu tüm kontratı kilitler, diğer türlü de yeni
      bir implementation'a geçmek zorunda kalınır
*/

contract Base {
  uint256 baseValue;
  bool private initialized;

  function initialize(uint256 startBaseValue) public {
    require(!initialized, "Can't initialize twice");
    initialized = true; 
    baseValue = startBaseValue;
  }
}

contract ImplV1 is Base {
    uint256 value;
    bool private initialized;

    /*
      Bu fonksiyon constructor gibi düşünülebilir,
      bir kere çağırılacağından emin olmak için initialized değişkeni
      kullandık. 
    */
    function initialize(uint256 startValue, uint256 baseStartValue) public {
      require(!initialized, "Can't initialize twice");
      initialized = true;
      value = startValue;

      // Bu fonksiyon çağrılmazsa Base kontratındaki değerler güncellenmez
      Base.initialize(baseStartValue);
    }

    function getValue() external view returns(uint256) {
        return value;
    }

    function setValue(uint256 newValue) external {
        value = newValue;
    }
}

contract ImplV2 is Base {
    uint256 value;
    bool private initialized;

    function initialize(uint256 startValue, uint256 baseStartValue) public {
      require(!initialized, "Can't initialize twice");
      initialized = true;
      value = startValue;
      
      Base.initialize(baseStartValue);
    }

    function getValue() external view returns(uint256) {
        return value;
    }

    function setValue(uint256 newValue) external {
        value = newValue*2;
    }
}

// From ClassicProxy.sol
contract Proxy {
  bytes32 private constant implementationSlot = 
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc; 

  bytes32 private constant adminSlot =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  constructor(address baseImplementation) {
    bytes32 slotImpl = implementationSlot;
    bytes32 slotAdmin = adminSlot;
    
    assembly {
      sstore(slotAdmin, caller())
      sstore(slotImpl, baseImplementation)
    }
  }

  function _fallback() internal {
    bytes32 slotImpl = implementationSlot;

    assembly {
      calldatacopy(0, 0, calldatasize())

      let impl := sload(slotImpl)
      let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)

      returndatacopy(0, 0, returndatasize())

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