# Aes128_ECB_CBC_CFB_OFB_CTR
AES128 IP core supports ECB, CBC, CFB, OFB and CTR mode (NOTE: ONLY RTL Code is available now, the simulation environment is building and NOT completed)

1) File structure
rtl/

aes128.sv - TOP module
  
  |- aes128_cipher_top.sv - TOP of cipher module
  
    |- aes128_cipher_core.sv - Cipher core
    
    |- aes128_key_expansion.sv - Key expansion
  
  |- aes128_cipher_inv_top.sv - TOP of cipher inversion (decipher) module
  
    |- aes128_cipher_core_inv.sv - Cipher inversion core
    
    |- aes128_key_expansion_inv.sv - Key expansion inversion
 
 pat/ - testcases (testbenches)
 
 sim/ - execute a simulation at here
 
 uvm_comp/ - all UVM component files and test models
 
 checker/ - some individual checkers if any
 
  
2) Detail description (Vietnamese)

http://nguyenquanicd.blogspot.com/search/label/AES?&max-results=5

-END-
