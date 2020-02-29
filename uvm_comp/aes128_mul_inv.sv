//-----------------------------------------------------------
// Author: Nguyen Hung Quan
// Website: http://nguyenquanicd.blogspot.com/
//-----------------------------------------------------------
//===================================================================
// Function:	Multiplication in GF(2^8)
//            1) Multiplication
//            2) modulo m(x) = x^8 + x^4 + x^3 + x + 1
//===================================================================
function logic [7:0] mul2Inv;
  input [7:0] mul2_in;
  mul2Inv[7:0] = (mul2_in[7] == 1'b1)?
              ({mul2_in[6:0], 1'b0} ^ 8'b0001_1011)
  				    : {mul2_in[6:0], 1'b0};
endfunction
//
function logic [7:0] mulInv;
  input [7:0] mul_in;
  input [1:0] mul_sel;
  //
  logic [7:0] mul2_result;
  logic [7:0] mul4_result;
  logic [7:0] mul8_result;
  logic [7:0] mul0e;
  logic [7:0] mul0b;
  logic [7:0] mul0d;
  logic [7:0] mul09;
  //
  mul2_result[7:0] = mul2Inv(mul_in[7:0]);
  mul4_result[7:0] = mul2Inv(mul2_result[7:0]);
  mul8_result[7:0] = mul2Inv(mul4_result[7:0]);
  mul0e[7:0] = mul2_result ^ mul4_result ^ mul8_result;
  mul0b[7:0] = mul2_result ^               mul8_result ^ mul_in[7:0];
  mul0d[7:0] =               mul4_result ^ mul8_result ^ mul_in[7:0];
  mul09[7:0] =                             mul8_result ^ mul_in[7:0];
  case (mul_sel[1:0])
    2'b00: mulInv[7:0] = mul0e[7:0];
    2'b01: mulInv[7:0] = mul0b[7:0];
    2'b10: mulInv[7:0] = mul0d[7:0];
    2'b11: mulInv[7:0] = mul09[7:0];
    default: mulInv[7:0] = mul0e[7:0];
  endcase
endfunction
//Multiplication of the InvMixColumns matrix and a column of state matrix
function logic [31:0] mixcolInv;
  parameter MIX0E = 2'b00;
  parameter MIX0B = 2'b01;
  parameter MIX0D = 2'b10;
  parameter MIX09 = 2'b11;
  //
  input [31:0] mixcolInv_in;
  mixcolInv[31:24] = mulInv(mixcolInv_in[31:24],  MIX0E) 
                     ^ mulInv(mixcolInv_in[23:16],MIX0B) 
                     ^ mulInv(mixcolInv_in[15:8], MIX0D) 
                     ^ mulInv(mixcolInv_in[7:0],  MIX09);
                     
  mixcolInv[23:16] = mulInv(mixcolInv_in[31:24],  MIX09) 
                     ^ mulInv(mixcolInv_in[23:16],MIX0E) 
                     ^ mulInv(mixcolInv_in[15:8], MIX0B) 
                     ^ mulInv(mixcolInv_in[7:0],  MIX0D);
                     
  mixcolInv[15:8]  = mulInv(mixcolInv_in[31:24],  MIX0D) 
                     ^ mulInv(mixcolInv_in[23:16],MIX09) 
                     ^ mulInv(mixcolInv_in[15:8], MIX0E) 
                     ^ mulInv(mixcolInv_in[7:0],  MIX0B);
                     
  mixcolInv[7:0]   = mulInv(mixcolInv_in[31:24],  MIX0B) 
                     ^ mulInv(mixcolInv_in[23:16],MIX0D) 
                     ^ mulInv(mixcolInv_in[15:8], MIX09) 
                     ^ mulInv(mixcolInv_in[7:0],  MIX0E);
endfunction