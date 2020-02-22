//--------------------------------------
//Project  :  The UVM environemnt for AES128
//File name:  aes_Test.sv
//Author   :  Nguyễn Hùng Quân, Phan Văn Thành, Nguyễn Thành Công, Trần Hữu Toàn
//Page     :  VLSI Technology
//--------------------------------------

module aes_Testbench;

    //Clock and reset signal declaration
	bit clk;
	bit reset;
	
	//Clock generation
	always #5 clk = ~clk;
	
	//Reset generationinitial begin
	initial begin
	    reset = 1;
		#5 reset = 0;
	end
	
	//Interface intance
	aes_Interface aes_Interface_inst();
	
	//DUT instance
	aes128 aes_DUT(
	    .clk(aes_Interface_inst.aes_clk),
		.rst_n(aes_Interface_inst.aes_rst_n),
		.cipher_en(aes_Interface_inst.aes_cipher_en),
		.decipher_en(aes_Interface_inst.aes_decipher_en),
		.chain_en(aes_Interface_inst.aes_chain_en),
		.data_in(aes_Interface_inst.aes_data_in),
		.key(aes_Interface_inst.aes_key),
		.mode(aes_Interface_inst.aes_mode),
		.init_vector(aes_Interface_inst.aes_init_vector),
		.segment_len(aes_Interface_inst.aes_segment_len),
		.data_out(aes_Interface_inst.aes_data_out),
		.ready(aes_Interface_inst.aes_ready)
	
	initial begin uvm_config_db#(virtual aes_Interface)::set(uvm_root::get(),"*","vif",aes_Interface_inst);
	//Enable wave dump
	$dumpfile("dump.vcd");
	$dumpvars;
	end
	
	//Calling test
	initial begin 
	    run_test();
	end
	
endmodule