#---------------------------------------------
#Compilation
#---------------------------------------------
vlog -work work  \
            +define+UVM_CMDLINE_NO_DPI \
            +define+UVM_REGEX_NO_DPI \
            +define+UVM_NO_DPI \
			+incdir+E:/MY_PROJECT/02_TOOL/UVM_package/uvm-1.2/uvm-1.2/src \
            -sv \
            ../uvm_comp/aes_Interface.sv \
            ../rtl/aes128_cipher_core.sv \
            ../rtl/aes128_cipher_core_inv.sv \
            ../rtl/aes128_cipher_inv_top.sv \
            ../rtl/aes128_cipher_top.sv \
            ../rtl/aes128_key_expansion.sv \
            ../rtl/aes128_key_expansion_inv.sv \
            ../rtl/aes128.sv \
            ../uvm_comp/aes_Testbench.sv \
            -timescale 1ns/1ns \
            -l vlog.log \
            +cover

#---------------------------------------------
#Simulation
#---------------------------------------------
vsim -novopt work.aes_Testbench \
  +UVM_TESTNAME=aes_Test \
  +UVM_VERBOSITY=UVM_LOW \
  -coverage \
  -l vsim.log

#---------------------------------------------
#Run
#---------------------------------------------
run 10ns