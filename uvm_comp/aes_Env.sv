//--------------------------------------
//Project  :  The UVM environemnt for AES128
//File name:  aes_Env.sv
//Author   :  Nguyễn Hùng Quân, Phan Văn Thành, Nguyễn Thành Công, Trần Hữu Toàn
//Page     :  VLSI Technology
//--------------------------------------

class aes_Env extends uvm_env
    `uvm_component_utils(aes_Env)
	
	aes_Agent        aes_Agent_inst;
	aes_Scoreboard   aes_Scoreboard_inst;
	
	// Constructure
	function new(string name, uvm_component parent);
	    super.new(name,parent);
	endfunction
	
	// Build phase: Create the components
	function void build_phase(uvm_phase phase);
	    super.build_phase(phase);
		aes_Agent_inst        = aes_Agent::type_id::create("aes_Agent_inst",this);
		aes_Scoreboard_inst   = aes_Scoreboard::type_id::create("aes_Scoreboard_inst",this);
	endfunction
	
	// Connec phase: Connecting monitor and scoreboard port
	function void connect_Phase(uvm_phase phase);
	    aes_Agent_inst.aes_Monitor_inst.ap_toScoreboard.connect(aes_Scoreboard_inst.ip_fromMonitor);
	endfunction
	
endclass