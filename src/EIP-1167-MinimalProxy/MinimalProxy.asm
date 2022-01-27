# Eğer business logic gereği aynı kodu birden fazla deploy etmek gerekiyorsa
# tek görevi bir adresteki kontratı deploy etmek olan minimal proxy'ler kullanılabilir

# Minimal Proxy 45 byte büyüklüğünde bir deployment kodudur
# 363d3d373d3d3d363d73<srcAddress>5af43d82803e903d91602b57fd5bf3 
# srcAddr: Kodun tek seferliğine deploy edildiği adres

#  OPCODE ARGS (decimal)      STACK AFTER EXEC.
#  --------------------------------------------------------------------------------
#  İlk 8 opcode constructor kodu
#  Constructor kodları asıl bytecode'u döndüren giriş kodudur
#  RETURNDATASIZE stack'e 0 pushlamak için kullanılmış

01. RETURNDATASIZE             # 0. 0x00
02. PUSH1 0x2d (dec. 45)       # 0. 0x2d  1. 0x00
04. DUP1                       # 0. 0x2d  1. 0x2d  1. 0x00
05. PUSH1 0x0a (dec. 10)       # 0. 0x0a  1. 0x2d  2. 0x2d  3. 0x00
07. RETURNDATASIZE             # 0. 0x00  1. 0x0a  2. 0x2d  3. 0x2d  4. 0x00
#   0x00 memory slotuna ilk 10 byte'tan sonraki 45 byte kopyalanıyor
#   İşe bakın ki constructor kodunun byte-length'i 10 ve devamındaki kodun 
#   byte-length'i 45 :)
08. CODECOPY                   # 0. 0x2d  1. 0x00 
09. DUP2                       # 0. 0x00  1. 0x2d  2. 0x00
10. RETURN                     # 0. 0x00

#   Blokzincirde yer alan asıl kod aşağıdaki 45 byte
#   Gelen herhangi bir çağrıda bu kodlar çalışacak

#   msg.data memory'e kopyalanır
01. CALLDATASIZE               # 0. cds   1. 0x00
02. RETURNDATASIZE             # 0. 0x00  1. cds   2. 0x00
03. RETURNDATASIZE             # 0. 0x00  1. 0x00  2. cds   3. 0x00
04. CALLDATACOPY               # 0. 0x00

#   delegatecall ile kontrat çağırılır
05. RETURNDATASIZE             # 0. 0x00  1. 0x00
06. RETURNDATASIZE             # 0. 0x00  1. 0x00  2. 0x00
07. RETURNDATASIZE             # 0. 0x00  1. 0x00  2. 0x00  3. 0x00 
08. CALLDATASIZE               # 0. cds   1. 0x00  2. 0x00  3. 0x00  4. 0x00
09. RETURNDATASIZE             # 0. 0x00  1. cds   2. 0x00  3. 0x00  4. 0x00  5. 0x00
10. PUSH20 srcAddress          # 0. src   1. 0x00  2. cds   3. 0x00  4. 0x00  5. 0x00  6. 0x00
30. GAS                        # 0. gas   1. src   2. 0x00  3. cds   4. 0x00  5. 0x00  6. 0x00  7. 0x00
31. DELEGATECALL               # 0. sucs  1. 0x00  2. 0x00

#   dönen değer memory'e kopyalanır
32. RETURNDATASIZE             # 0. rds   1. sucs  2. 0x00  3. 0x00
33. DUP3                       # 0. 0x00  1. rds   2. sucs  3. 0x00  4. 0x00
34. DUP1                       # 0. 0x00  1. 0x00  2. rds   3. sucs  4. 0x00  5. 0x00
35. RETURNDATACOPY             # 0. sucs  1. 0x00  2. 0x00

36. SWAP1                      # 0. 0x00  1. sucs  2. 0x00
37. RETURNDATASIZE             # 0. rds   1. 0x00  2. sucs  3. 0x00
38. SWAP2                      # 0. sucs  1. 0x00  2. rds   3. 0x00
39. PUSH1 0x2b (dec. 43)       # 0. 0x2b  1. sucs  2. 0x00  3. rds   4. 0x00

#   Eğer success 0'dan başka bir değer ise 43. komuta atlar
41. JUMPI                      # 0. 0x00  1. rds   3. 0x00
|  
|   #   Eğer success 0 ise buradaki revert'a gelir ve hata döner
>>  42. REVERT                     # 0. 0x00
|
|   #   Jump yapılan noktalara JUMPDEST konulur
>>  43. JUMPDEST                   # 0. 0x00  1. rds   3. 0x00
    #   DELEGATECALL'dan dönen değer kullanıcıya döndürülür 
    44. RETURN                     # 0. 0x00