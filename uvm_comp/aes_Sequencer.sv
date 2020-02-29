//--------------------------------------
//Project  :  The UVM environemnt for AES128
//File name:  aes_Sequencer.sv
//Author   :  Nguyễn Hùng Quân, Phan Văn Thành, Nguyễn Thành Công, Trần Hữu Toàn
//Page     :  VLSI Technology
//--------------------------------------
class aes_Sequencer extends uvm_sequencer#(aes_Transaction);
     //Register to Factory
     `uvm_component_utils(aes_Sequencer)
  
     //Constructor
	 function new (string name = "aes_Sequencer", uvm_component parent = null);
		 super.new(name,parent);
	 endfunction
endclass