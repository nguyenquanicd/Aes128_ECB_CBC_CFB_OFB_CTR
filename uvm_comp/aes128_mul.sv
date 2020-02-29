//-----------------------------------------------------------
// Author: Nguyen Hung Quan
// Website: http://nguyenquanicd.blogspot.com/
//-----------------------------------------------------------
//===================================================================
// Function:	Multiplication in GF(2^8)
//            1) Multiplication
//            2) modulo m(x) = x^8 + x^4 + x^3 + x + 1
//===================================================================
function logic [7:0] mul2;
  input [7:0] mul2_in;
  mul2[7:0] = (mul2_in[7] == 1'b1)?
              ({mul2_in[6:0], 1'b0} ^ 8'b0001_1011)
  				    : {mul2_in[6:0], 1'b0};
endfunction
//
function logic [7:0] mul3;
  input [7:0] mul3_in;
  mul3[7:0] = mul2(mul3_in[7:0]) ^ mul3_in[7:0];
endfunction
//Multiplication of the MixColumns matrix and a column of state matrix
function logic [31:0] mixcol;
  input [31:0] mixcol_in;
  mixcol[31:24] = mul2(mixcol_in[31:24]) ^ mul3(mixcol_in[23:16]) ^ mixcol_in[15:8]       ^ mixcol_in[7:0];
  mixcol[23:16] = mixcol_in[31:24]       ^ mul2(mixcol_in[23:16]) ^ mul3(mixcol_in[15:8]) ^ mixcol_in[7:0];
  mixcol[15:8]  = mixcol_in[31:24]       ^ mixcol_in[23:16]       ^ mul2(mixcol_in[15:8]) ^ mul3(mixcol_in[7:0]);
  mixcol[7:0]   = mul3(mixcol_in[31:24]) ^ mixcol_in[23:16]       ^ mixcol_in[15:8]       ^ mul2(mixcol_in[7:0]);
endfunction