//--------------------------------------
//Project  :  The UVM environemnt for AES128
//File name:  aes_Sequencer.sv
//Author   :  Phan Van Thanh
//Page     :  VLSI Technology
//--------------------------------------
class aes_Agent extends uvm_agent;

    //Register to Factory
    `uvm_component_utils(aes_Agent)
    
    
    //Declare Sequencer and Driver
    aes_Driver      aes_Driver_inst;
    aes_Sequencer   aes_Sequencer_inst;
    aes_Monitor     aes_Monitor_inst;
    
    //Constructor
    function new(string name = "aes_Agent", uvm_component parent);
        super.new(name, parent);
    endfunction
  
    //Build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        aes_Driver_inst    = aes_Driver::type_id::create("aes_Driver_inst",this);
        aes_Sequencer_inst = aes_Sequencer::type_id::create("aes_Sequencer_inst",this);
		aes_Monitor_inst   = aes_Monitor::type_id::create("aes_Monitor_inst",this);
    endfunction
  
    //Connect phase
	//Connect the driver seq_item_port to sequencer seq_item_export 
	//for communication between driver and sequencer in the connect phase
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        aes_Driver_inst.seq_item_port.connect(aes_Sequencer_inst.seq_item_export);
    endfunction
  
endclass