//-----------------------------------------------------------
// Author: Nguyen Hung Quan
// Website: http://nguyenquanicd.blogspot.com/
//-----------------------------------------------------------
//-----------------------------------------------------------
// Function: Inverse Rcon of AES-128 used in Inverse Key Expansion
//-----------------------------------------------------------

function logic [31:0] aes128_rcon_inv;
  input [3:0] rkey_sel;
	case (rkey_sel)
		4'd9:	aes128_rcon_inv = 32'h0100_0000;
  	4'd8:	aes128_rcon_inv = 32'h0200_0000;
  	4'd7:	aes128_rcon_inv = 32'h0400_0000;
  	4'd6:	aes128_rcon_inv = 32'h0800_0000;
  	4'd5:	aes128_rcon_inv = 32'h1000_0000;
  	4'd4:	aes128_rcon_inv = 32'h2000_0000;
  	4'd3:	aes128_rcon_inv = 32'h4000_0000;
  	4'd2:	aes128_rcon_inv = 32'h8000_0000;
  	4'd1:	aes128_rcon_inv = 32'h1b00_0000;
  	4'd0:	aes128_rcon_inv = 32'h3600_0000;
  	default: aes128_rcon_inv = 32'h0100_0000;
	endcase
endfunction
