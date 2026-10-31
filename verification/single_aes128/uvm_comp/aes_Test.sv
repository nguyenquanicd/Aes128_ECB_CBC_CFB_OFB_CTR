//--------------------------------------
//Project  :  The UVM environemnt for AES128
//File name:  aes_Test.sv
//Author   :  Nguyễn Hùng Quân, Phan Văn Thành, Nguyễn Thành Công, Trần Hữu Toàn
//Page     :  VLSI Technology
//--------------------------------------

class aes_Test extends uvm_test;
  
  `uvm_component_utils(aes_Test)
    
	aes_Env        aes_Env_inst;
	aes_Sequence   aes_Sequence_inst;
	
	function new(string name = "aes_Test",uvm_component parent=null);
	    super.new(name,parent);
	endfunction
	
	virtual function void build_phase(uvm_phase phase);
	    super.build_phase(phase);
		
		aes_Env_inst      = aes_Env::type_id::create("aes_Env_inst",this);
		aes_Sequence_inst = aes_Sequence::type_id::create("aes_Sequence_inst",this);
	endfunction
	
	task run_phase(uvm_phase phase);
	  phase.raise_objection(this);
		aes_Sequence_inst.start(aes_Env_inst.aes_Agent_inst.aes_Sequencer_inst);
		phase.drop_objection(this);
	endtask
	
endclass