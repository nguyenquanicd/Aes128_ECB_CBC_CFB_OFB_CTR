class aes_Sequencer extends uvm_sequencer#(aes_Transaction);
  //Register to Factory
  `uvm_component_utils(aes_Sequencer)
  //Constructor
	function new (string name = "aes_Sequencer", uvm_component parent = null);
		super.new(name,parent);
	endfunction
endclass: aes_Sequencer