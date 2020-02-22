//--------------------------------------
//Project  :  The UVM environemnt for AES128
//File name:  aes_Sequence.sv
//Author   :  Nguyễn Hùng Quân, Phan Văn Thành, Nguyễn Thành Công, Trần Hữu Toàn
//Page     :  VLSI Technology
//--------------------------------------

// aes_Monitor is user-given name for this class that has been derived from "uvm_monitor"
class aes_Monitor extends uvm_monitor;
    // [Recommended] Makes this monitor more re-usable
    `uvm_component_utils (aes_Monitor)
	
    //Internal variables
    aes_Transaction coAesTransaction;
    
	// Actual interface object is later obtained by doing a get() call on uvm_config_db
    virtual interface ifAes vifAes;
    
	//Declare analysis ports
    uvm_analysis_port #(aes_Transaction) ap_toScoreboard;
 
    // This is standard code for all components
    function new (string name = "aes_Monitor", uvm_component parent = null);
      super.new (name, parent);
    endfunction
 
  
  
    virtual function void build_phase (uvm_phase phase);
        super.build_phase (phase);
    
        // Create an instance of the declared analysis port
        ap_toScoreboard = new("ap_toScoreboard", this);	
    
        // Get virtual interface handle from the configuration DB
        if(!uvm_config_db#(virtual interface ifAes)::get(this,"","vifAes",vifAes)) begin
	  		`uvm_error("cAesDriver","Can NOT get vifAes!!!")
	    end
	  
        coAesTransaction = aes_Transaction::type_id::create("coAesTransaction",this);
    endfunction 
   
   
    // This is the main piece of monitor code which decides how it has to decode 
    virtual task run_phase (uvm_phase phase);
        // Fork off multiple threads "if" required to monitor the interface,  for example:
        super.run_phase(phase);
	  
	    fork
	        //collect and send data to scoreboard
	        collect_send_data();
	        //check number of cipher_en and decipher_en busy cycles
            check_busy_cycle();
            //check_ready
	        check_ready1();
	        check_ready2();
	        check_ready3();
            //check_chain_en signal
	        check_chain_en1();
	        check_chain_en2();
	        //check cipher_en and decipher_en signals
            check_cipher_decipher_en1();
	        check_cipher_decipher_en2();
	        //check cipher and decipher mode
            check_cipher_decipher_mode();
        join
    endtask
  
    //Collect and send valid data to scoreboard when ready equal 1 and cipher_en or decipher_en equal 1
    virtual task collect_send_data();
	    while(1) begin
	        wait@(vifAes.rst_n=1);
            @(posedge vifAes.clk);
	        if(vifAes.ready==1) begin
	            if(vifAes.cipher_en==1 || vifAes.decipher_en==1) begin
	    	        //Get transaction on interface
	    	        if(vifAes.cipher_en==1) begin
	    	            coAesTransaction.aes_cipher_en <= 1;
	    	        end
	    	        if(vifAes.decipher_en==1) begin
	    	            coAesTransaction.aes_cipher_en <= 0;
	    	        end
	    	        coAesTransaction.aes_chain_en <= vifAes.aes_chain_en;
	    	        coAesTransaction.aes_data_in[127:0] <= vifAes.aes_data_in[127:0];
                    coAesTransaction.aes_key[127:0] <= vifAes.aes_key[127:0];
	    	        coAesTransaction.aes_mode[3:0] <= vifAes.aes_mode[3:0];
	    	        coAesTransaction.aes_init_vector[127:0] <= vifAes.aes_init_vector[127:0];
	    	        coAesTransaction.aes_segment_len[3:0] <= vifAes.aes_segment_len[3:0];
                    
	    	        (posedge vifAes.clk);
	    	        wait@(posedge vifAes.ready);
	    	        //Get transaction on interface
	    	        coAesTransaction.aes_data_out[127:0] <= vifAes.aes_data_out[127:0];
	    	         
                    //Send the ouput valid data to analysis port which is connected to Scoreboard
                    ap_toScoreboard.write(coApbTransaction);
	    	    end
	        end
	    end
    endtask
  
    //check number of cipher and decipher busy cycle  
    bit count;
    virtual task check_busy_cycle();
        while(1) begin
            wait@(vifAes.rst_n=1);
	        @(posedge vifAes.clk);
	        count<=0;
	      
	        fork
	            while(count<11) begin
	                @(posedge vifAes.clk);
	                if(vifAes.cipher_en==0) begin
	                    if(vifAes.ready==0) begin
	  	                    count=count+1;
	  	                end
	  	                else begin
	  	                    `uvm_error("aes_Monitor", "Total number of busy cycles cipher_en is less than number of cycles to perform");
	  	                end
	  	            else begin
	  	                `uvm_error("aes_Monitor", "Cipher_en shouldn't equal 1 when ready equal 0");
	  	            end
	            end
				
	            if(vifAes.ready==0) begin
	                `uvm_error("aes_Monitor", "Total number of busy cycles cipher_en is more than number of cycles to perform");
	            end
				
	            while(count<22) begin
	                @(posedge vifAes.clk);
	                if(vifAes.decipher_en==0) begin
	                    if(vifAes.ready==0) begin
	  	                    count=count+1;
	  	                end
	  	                else begin
	  	                    `uvm_error("aes_Monitor", "Total number of busy cycles decipher_en is less than number of cycles to perform");
	  	                end
	  	            else begin
	  	                `uvm_error("aes_Monitor", "Decipher_en shouldn't equal 1 when ready equal 0");
	  	            end
	            end
				
	            if(vifAes.ready==0) begin
	                `uvm_error("aes_Monitor", "Total number of busy cycles decipher_en is more than number of cycles to perform");
	            end
	        join
	    end  
	endtask
	  
	  
    //check ready signal
    //check ready=1 immediately after reset 	  
    virtual task check_ready1();
        while(1) begin
            wait@(vifAes.rst_n=0);
            if (vifAes.ready == 0) begin
                `uvm_error("aes_Monitor", "Ready signal doesn't equal 1 when starting simulation");
            end
    	end
    endtask
	
    //check ready != {x,z}
    virtual task check_ready2();
        while(1) begin
            wait@(vifAes.rst_n=1);
            case(vifAes.ready)
                1'bx:`uvm_error("aes_Monitor", "Valid of ready shouldn't equal x");
                1'bz:`uvm_error("aes_Monitor", "Valid of ready shouldn't equal z");
            endcase
        end
    endtask
	
    //check ready signal holds the least one clock cycle before starting the next cipher or decipher process
    virtual task check_ready3();
        while(1) begin
            wait@(vifAes.rst_n=1);
            wait@(posedge vifAes.clk);
            wait@(posedge vifAes.ready);
            wait@(posedge vifAes.clk);
            if (vifAes.ready==0) begin
                `uvm_error("aes_Monitor", "Ready signal holds one level less than 1 clock cycle");
            end
        end
    endtask
  
    //check chain_en signal
    //check chain_en != {x,z}
    virtual task check_chain_en1();
        while(1) begin
            wait@(vifAes.rst_n=1);
            case(vifAes.chain_en)
                1'bx:`uvm_error("aes_Monitor", "Valid of chain_en shouldn't equal x");
                1'bz:`uvm_error("aes_Monitor", "Valid of chain_en shouldn't equal z");
            endcase
        end
    endtask

    //check chain_en signal holds the least one clock cycle before starting the next cipher or decipher process		
    virtual task check_chain_en2();  
        while(1) begin
            wait@(vifAes.rst_n=1);
            wait@(posedge vifAes.clk);
            wait@(posedge vifAes.chain_en);
            wait@(posedge vifAes.clk);
      
            if (vifAes.chain_en==1) begin
                `uvm_error("aes_Monitor", "Chain_en signal holds zero level less than 1 clock cycle");
            end
        end
    endtask
  
  
    //check cipher_en and decipher_en signals
    //check: cipher_en != {x,z} and check: decipher_en != {x,z}  
    virtual task check_cipher_decipher_en1();
        while(1) begin
            wait@(vifAes.rst_n=1);
            case@(vifAes.cipher_en)
                1'bx:`uvm_error("aes_Monitor", "Valid of cipher_en shouldn't equal x");
    	        1'bz:`uvm_error("aes_Monitor", "Valid of cipher_en shouldn't equal z");
            endcase
            case@(vifAes.decipher_en)
                1'bx:`uvm_error("aes_Monitor", "Valid of decipher_en shouldn't equal x");
    	        1'bz:`uvm_error("aes_Monitor", "Valid of decipher_en shouldn't equal z");
            endcase 
        end
    endtask
	
    //check: cipher_en and decipher_en signals are just positive in one clock cycle.	
    virtual task check_cipher_decipher_en2();
        while(1) begin
            wait@(vifAes.rst_n=1);
            wait@(posedge vifAes.clk);
            fork
                begin
                    wait@(posedge vifAes.cipher_en);
        	    end
        	    begin
                    wait@(posedge vifAes.decipher_en);
                end
            join
        	
            wait@(posedge vifAes.clk);
          
            if (vifAes.cipher_en==0) begin
                `uvm_error("aes_Monitor", "Cipher_en signal didn't equal 0 after 1 clock cycle");
            end
            if (vifAes.decipher_en==0) begin
                `uvm_error("aes_Monitor", "Decipher_en signal didn't equal 0 after 1 clock cycle");
            end
        end
    endtask

    //check: cipher_en and decipher_en signal didn’t equal 1 at the same time.
    virtual task check_cipher_decipher_mode();
        while(1) begin
            wait@(vifAes.rst_n=1);
            wait@(posedge vifAes.clk);
            if (vifAes.cipher_en==1 && vifAes.decipher_en==1) begin
                `uvm_error("aes_Monitor", "Cipher_en and decipher_en equal 1 at the same time");
            end
        end
    endtask
  
endclass
