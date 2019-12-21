class aes_Agent extends uvm_agent;
  //Register to Factory
  `uvm_component_utils(aes_Agent)
  //Declare Sequencer and Driver
  aes_Driver    aes_Driver_inst;
  aes_Sequencer aes_Sequencer_inst;
  //Constructor
  function new(string name = "aes_Agent", uvm_component parent);
      super.new(name, parent);
  endfunction
  //Build Driver and Sequencer objects
  function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      aes_Driver_inst    = aes_Driver::type_id::create("aes_Driver_inst",this);
      aes_Sequencer_inst = aes_Sequencer::type_id::create("aes_Sequencer_inst",this);
  endfunction
  //Connect Driver and Sequencer via a couple export/port
  function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      aes_Driver_inst.seq_item_port.connect(aes_Sequencer_inst.seq_item_export);
  endfunction
  //
endclass: aes_Agent