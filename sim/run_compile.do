vlog -work work  \
            +incdir+C:/questasim64_10.2c/uvm-1.2/src \
            -sv \
            ../rtl/aes128_mul.sv \
            ../rtl/aes128_mul_inv.sv \
            ../rtl/aes128_rcon.sv \
            ../rtl/aes128_rcon_inv.sv \
            ../rtl/aes128_sbox.sv \
            ../rtl/aes128_sbox_inv.sv \
            ../rtl/aes128_cipher_core.sv \
            ../rtl/aes128_cipher_core_inv.sv \
            ../rtl/aes128_cipher_inv_top.sv \
            ../rtl/aes128_cipher_top.sv \
            ../rtl/aes128_key_expansion.sv \
            ../rtl/aes128_key_expansion_inv.sv \
            ../rtl/aes128.sv \
            ../uvm_comp/aes_Interface.sv \
            ../uvm_comp/aes_Testbench.sv