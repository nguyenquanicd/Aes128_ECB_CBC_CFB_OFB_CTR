//--------------------------------------
//Project  :  The UVM environemnt for AES128
//File name:  aes_Sequence.sv
//Author   :  Nguyễn Hùng Quân, Phan Văn Thành, Nguyễn Thành Công, Trần Hữu Toàn
//Page     :  VLSI Technology
//--------------------------------------
interface aes_Interface();
//input DUT
  logic           aes_clk;
  logic           aes_rst_n;
  logic           aes_cipher_en;
  logic           aes_decipher_en;
  logic           aes_chain_en;
  logic [127:0]   aes_data_in;
  logic [127:0]   aes_key;
  logic [3:0]     aes_mode;
  logic [127:0]   aes_init_vector;
  logic [3:0]     aes_segment_len;
//output DUT      
  logic [127:0]   aes_data_out;
  logic           aes_ready;
endinterface