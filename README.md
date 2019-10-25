# Aes128_ECB_CBC_CFB_OFB_CTR
AES128 IP core supports ECB, CBC, CFB, OFB and CTR mode

1) File structure

aes128.sv - TOP module
  
  |- aes128_cipher_top.sv - TOP of cipher module
  
    |- aes128_cipher_core.sv - Cipher core
    
    |- aes128_key_expansion.sv - Key expansion
  
  |- aes128_cipher_inv_top.sv - TOP of cipher inversion (decipher) module
  
    |- aes128_cipher_core_inv.sv - Cipher inversion core
    
    |- aes128_key_expansion_inv.sv - Key expansion inversion
  
2) Detail description (Vietnamese)

http://nguyenquanicd.blogspot.com/search/label/AES?&max-results=5

-END-
