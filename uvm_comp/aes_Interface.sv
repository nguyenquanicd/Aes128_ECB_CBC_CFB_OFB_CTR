interface ifAes();

//input DUT
  logic           aes_clk;
  logic           aes_rstn;
  logic           aes_cipher_en;
  logic           aes_chain_en;
  logic [127:0]   aes_data_in;
  logic [127:0]   aes_key;
  logic [3:0]     aes_mode;
  logic [127:0]   aes_init_vector;
  logic [3:0]     aes_segment_len;
//output DUT
  logic [127:0]   aes_data_out;
  
endinterface