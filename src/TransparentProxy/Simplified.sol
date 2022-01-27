// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/*
    Kullanan projeler: dYdX, PoolTogether, USDC

    Eğer proxy kontratlarının içerisinde herkesin çağırabileceği
    bir fonksiyon bulunursa ve bu fonksiyonun selector'u implementation'daki
    fonksiyon ile aynı olursa proxy kontratı üzerindeki fonksiyon çağrılır.

    Buna "Function Clashing" deniyor.

    TransparentUpgradeableProxy pattern en basit haliyle proxy kontratında 
    admin hariç kimsenin bir fonksiyon çağıramamasını ve admin için de 
    sadece upgrade fonksiyonlarının tutulmasını amaçlar.

    Kontratı deploy edenin de kontratın diğer fonksiyonlarından 
    yararlanmasını isteyebiliriz diye OpenZeppelin TranparentProxy yanında
    "proxy'nin proxy'si" ProxyAdmin kontratını kullanır.
    
    Böylece asıl deploy işlemini ProxyAdmin kontratı yapar. Deployer eğer 
    proxy'i değiştirmek isterse ProxyAdmin kontratı ile, eğer kontratı 
    kullanmak isterse de TranparentUpgradeableProxy kontratı ile 
    etkileşir.

    [1]: https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies
    [2]: https://forum.openzeppelin.com/t/beware-of-the-proxy-learn-how-to-exploit-function-clashing/1070
*/
contract TransparentAdminUpgradeableProxy {

    address implementation;
    address admin;

    function _fallback() private {
        require(msg.sender != admin);
        (bool success, ) = implementation.delegatecall(msg.data);
        require(success);
    }
    
    fallback() external payable {
        _fallback();
    }
    
    function upgrade(address newImplementation) external {
        if (msg.sender != admin) _fallback();
        implementation = newImplementation;
    }
}

