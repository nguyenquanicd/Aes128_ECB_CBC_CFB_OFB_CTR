class aes_Sequence extends uvm_sequence#(aes_Transaction);
  //Register to Factory
  `uvm_object_utils(aes_Sequence)
  `uvm_declare_p_sequencer(aes_Sequencer)
  //Declare a transaction instance
  aes_Transaction aseTransaction_inst;
  //Constructor - create a transaction object
	function new (string name = "aes_Sequence");
		super.new(name);
    aesTransaction_inst = aes_Transaction::type_id::create("aesTransaction_inst");
	endfunction
  //
  //TEST PATTERN is written at here
  //
  task body();
    //Execute 5 transactions
    repeat (8) begin
      #10ns //Execute a new transaction after 10ns
      `uvm_do_on(aesTransaction_inst, p_sequencer)
      `uvm_info("--- aesTransaction_inst: ", $sformatf("\n aes_cipher_en=%h \n aes_chain_en=%h\n aes_data_in=%h\n aes_key=%h\n aes_mode=%h\n aes_init_vector=%h\n aes_segment_len=%h\n aes_blockDelay=%h\n aes_data_out=%h\n ;"
															, aesTransaction_inst.aes_cipher_en
															, aesTransaction_inst.aes_chain_en
															, aesTransaction_inst.aes_data_in
															, aesTransaction_inst.aes_key
															, aesTransaction_inst.aes_mode
															, aesTransaction_inst.aes_init_vector
															, aesTransaction_inst.aes_segment_len
															, aesTransaction_inst.aes_blockDelay
															, aesTransaction_inst.aes_data_out), UVM_LOW);
    end
    #10ns //Delay to be able to see the end transaction on waveform
    `uvm_info("--- COMPLETED SIMULATION ---\n", "", UVM_LOW);
  endtask
endclass: mySequence