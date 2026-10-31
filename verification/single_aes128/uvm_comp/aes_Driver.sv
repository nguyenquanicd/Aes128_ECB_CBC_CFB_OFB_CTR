//--------------------------------------
//Project  :  The UVM environemnt for AES128
//File name:  aes_Sequence.sv
//Author   :  Nguyễn Hùng Quân, Phan Văn Thành, Nguyễn Thành Công, Trần Hữu Toàn
//Page     :  VLSI Technology
//--------------------------------------
class aes_Driver extends uvm_driver #(aes_Transaction);
     // Makes this scoreboard more re-usable
	`uvm_component_utils(aes_Driver)
	
     //1. Declare the virtual interface
     virtual interface aes_Interface ifAes_inst;
     aes_Transaction aesPacket;
     bit [7:0] int_delay;
     
     //3. Class constructor with two arguments
     function new (string name = "aes_Driver", uvm_component parent = null);
         super.new(name, parent);
     endfunction: new
	 
     //4. Build phase
     // - super.build_phase is called and executed first
     // - Configure the component before creating it
     // - Create the UVM component
     virtual function void build_phase(uvm_phase phase);
         super.build_phase(phase);
         //All of the functions in uvm_config_db are static, using :: to call them
         //If the call "get" is unsuccessful, the fatal is triggered
         if (!uvm_config_db#(virtual interface aes_Interface)::get(this,"","aes_Interface",ifAes_inst)) begin
             //`uvm_fatal(ID, MSG)
             //ID: message tag
             //MSG message text
             //get_full_name returns the full hierarchical name of the driver object
	         // kiem tra connection!!!
             //`uvm_fatal("NON-aes_Interface", {"A virtual interface must be set for: ", get_full_name(), ".ifAes_inst"})
			 //`uvm_fatal("....", $psprintf("... %s ...", get_full_name()));
			 `uvm_fatal (get_type_name(), "Didnt get handle to virtual interface if_name")
         end
         `uvm_info(get_full_name(), "Build phase completed.", UVM_LOW)
     endfunction
	 
     //5. Run phase
     //Execute methods of Driver in run_phase
     virtual task run_phase (uvm_phase phase);
	     super.run_phase(phase);
         begin
	         // Check Reset
	         if (ifAes_inst.aes_rst_n == 1) begin
	             // Initilize 
	             ifAes_inst.aes_cipher_en   <= 1'b0;
	   	         ifAes_inst.aes_chain_en    <= 1'b0;
				 ifAes_inst.aes_decipher_en <=1'b0;
				 
	   	         // Task get_seq_and_drive
                 get_seq_and_drive (aesPacket);
	         end
         end
     endtask
  
     //Get a transaction -> convert to signal level (Drive DUT) -> wait for completing
     virtual task get_seq_and_drive(aes_Transaction userTransaction);
         forever begin
             @ (posedge ifAes_inst.aes_clk);
	             //check ready
	             if (ifAes_inst.aes_ready == 1) begin
                         //The seq_item_port.get_next_item is used to get items from the sequencer
                         seq_item_port.get_next_item(userTransaction);
                        
	   		             if (userTransaction.aes_chain_en == 1)
	   		  	     	 if (userTransaction.aes_new_chain ==1)
	   		  	     			ifAes_inst.aes_chain_en <= 0;
	   		             convert_seq2signal(userTransaction);
                         // Report the done execution
                         seq_item_port.item_done();
	   	         end
         end
     endtask: get_seq_and_drive
	 
     //Convert the sequence (a transaction) to signal level
     virtual task convert_seq2signal (aes_Transaction userTransaction);	
	     // Get delay cycle for IDLE state
	     int_delay = userTransaction.aes_blockDelay;
	
	     // Create delay clock followed by aes_blockDelay and also IDLE state
	     repeat (int_delay)
	     begin
	         @ (posedge ifAes_inst.aes_clk);
	     end
		 
	     // START state
	     // send control signal to drive
	     if (userTransaction.aes_cipher_en == 1) begin
	         ifAes_inst.aes_cipher_en <= 1'b1;
	         ifAes_inst.aes_decipher_en <= 1'b0;
	     end
	     else begin
	          ifAes_inst.aes_cipher_en <= 1'b0;
	          ifAes_inst.aes_decipher_en <= 1'b1;
	     end
	     ifAes_inst.aes_chain_en <= userTransaction.aes_chain_en;
	     // send data signal
	     ifAes_inst.aes_data_in[127:0] <= userTransaction.aes_data_in[127:0];
	     ifAes_inst.aes_key[127:0] <= userTransaction.aes_key[127:0];
	     ifAes_inst.aes_mode[3:0] <= userTransaction.aes_mode[3:0];
         ifAes_inst.aes_init_vector[127:0] <= userTransaction.aes_init_vector[127:0];
	     ifAes_inst.aes_segment_len[3:0] <= userTransaction.aes_segment_len[3:0];
	     
	     @(posedge ifAes_inst.aes_clk); // End of START stage
		     //BUSY stage
	         ifAes_inst.aes_cipher_en <= 1'b0;
	         ifAes_inst.aes_decipher_en <= 1'b0;
			 //DONE
     endtask: convert_seq2signal
  //
endclass: aes_Driver