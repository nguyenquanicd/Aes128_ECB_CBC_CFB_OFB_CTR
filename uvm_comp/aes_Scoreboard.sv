//--------------------------------------
//Project  :  The UVM environemnt for AES128
//File name:  aes_Sequence.sv
//Author   :  Nguyễn Hùng Quân, Phan Văn Thành, Nguyễn Thành Công, Trần Hữu Toàn
//Page     :  VLSI Technology
//--------------------------------------

//import "DPI-C" context function main_aes(uint8_t mode, uint8_t xcrypt, uint8_t* key, uint8_t* in, uint8_t* iv, uint8_t* out, uint8_t sbit)

class aes_Scoreboard extends uvm_scoreboard;

    // Makes this scoreboard more re-usable
	`uvm_component_utils(aes_Scoreboard)
	
	// This is standard code for all components
	function new (string name = "aes_Scoreboard", uvm_component parent = null);
	    super.new(name, parent);
	endfunction
	
	// Declare analysis port
	uvm_analysis_imp #(aes_Transaction, aes_Scoreboard) ip_fromMonitor;
	
	// Instantiate the analysis port, becasue afterall, its a class object
	function void buid_phase(uvm_phase phase);
	    ip_fromMonitor = new ("ip_fromMonitor",this);
	endfunction
	
	// Define action to be taken when a packer is received via the declare analysis port
	virtual function void write (aesTransaction);
	    `uvm_info("write","Scoreboard get AES-transaction", UVM_LOW);
	endfunction
	
	virtual task run_phase(uvm_phase phase);
	    super.run_phase(phase);
		
	    // TODO
		
	endtask
	
	virtual function void check_phase (uvm_phase phase);
        // TODO
    endfunction		
endclass