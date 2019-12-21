class aes_Transaction extends uvm_sequence_item;
  rand  bit               aes_cipher_en;
  rand  bit               aes_chain_en; 
  rand  bit [127:0]       aes_data_in; 
  rand  bit [127:0]       aes_key;
  rand  bit [3:0]         aes_mode;
  rand  bit [127:0]       aes_init_vector;
  rand  bit [3:0]         aes_segment_len;
  rand  bit [7:0]         aes_blockDelay; // delay signal
  rand  bit               aes_new_chain;
  logic [127:0]           aes_data_out;
  `uvm_object_utils_begin (aes_Transaction)
  `uvm_field_int(aes_cipher_en, UVM_ALL_ON)
  `uvm_field_int(aes_chain_en, UVM_ALL_ON)
  `uvm_field_int(aes_data_in, UVM_ALL_ON)
  `uvm_field_int(aes_key, UVM_ALL_ON)
  `uvm_field_int(aes_mode, UVM_ALL_ON)
  `uvm_field_int(aes_init_vector, UVM_ALL_ON)
  `uvm_field_int(aes_segment_len, UVM_ALL_ON)
  `uvm_field_int(aes_blockDelay, UVM_ALL_ON)
  `uvm_field_int(aes_new_chain, UVM_ALL_ON)
  `uvm_field_int(aes_data_out, UVM_ALL_ON)
  `uvm_object_utils_end
  //Constructor
  function new (string name = " aes_Transaction ");
    super.new(name);
  endfunction: new
endclass: aes_Transaction


