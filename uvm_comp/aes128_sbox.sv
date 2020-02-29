//-----------------------------------------------------------
// Author: Nguyen Hung Quan
// Website: http://nguyenquanicd.blogspot.com/
//-----------------------------------------------------------
//-----------------------------------------------------
// Function: Calculate S-Box and inverse S-Box for AES
//-----------------------------------------------------
//-----------------------------------------------------
// Multiple 2 operands in GF(2^2)
//-----------------------------------------------------
function logic [1:0] mulGf22;
  input [1:0] mulGf22_in0;
  input [1:0] mulGf22_in1;
  //
  mulGf22[1] = (mulGf22_in0[1] & mulGf22_in1[1])
             ^ (mulGf22_in0[0] & mulGf22_in1[1])
             ^ (mulGf22_in0[1] & mulGf22_in1[0]);
  //           
  mulGf22[0] = (mulGf22_in0[1] & mulGf22_in1[1])
             ^ (mulGf22_in0[0] & mulGf22_in1[0]);
endfunction

//-----------------------------------------------------
// Multiple 2 operands in GF(2^4)
//-----------------------------------------------------
function logic [3:0] mulGf24;
  input [3:0] operand0;
  input [3:0] operand1;
  //
  logic [1:0] operand0_msb;
  logic [1:0] operand0_lsb;
  logic [1:0] operand1_msb;
  logic [1:0] operand1_lsb;
  logic [1:0] operand0_xor;
  logic [1:0] operand1_xor;
  logic [1:0] mul_msb0_msb1;
  logic [1:0] mul_xor0_xor1;
  logic [1:0] mul_lsb0_lsb1;
  logic [1:0] xPhi;
  //
  operand0_msb[1:0] = operand0[3:2];
  operand0_lsb[1:0] = operand0[1:0];
  operand1_msb[1:0] = operand1[3:2];
  operand1_lsb[1:0] = operand1[1:0];
  //XOR IN
  operand0_xor[1:0] = operand0_msb[1:0] ^ operand0_lsb[1:0];
  operand1_xor[1:0] = operand1_msb[1:0] ^ operand1_lsb[1:0];
  //Multiplication
  mul_msb0_msb1[1:0] = mulGf22(operand0_msb, operand1_msb);
  mul_xor0_xor1[1:0] = mulGf22(operand0_xor, operand1_xor);
  mul_lsb0_lsb1[1:0] = mulGf22(operand0_lsb, operand1_lsb);
  //x Phi
  xPhi[1] = mul_msb0_msb1[1] ^ mul_msb0_msb1[0];
  xPhi[0] = mul_msb0_msb1[1];
  //XOR OUT
  mulGf24[3:2] = mul_xor0_xor1[1:0] ^ mul_lsb0_lsb1[1:0];
  mulGf24[1:0] = xPhi[1:0]          ^ mul_lsb0_lsb1[1:0];
endfunction
//-----------------------------------------------------
// Affine transformation
//-----------------------------------------------------
function logic [7:0] affine;
  input [7:0] after_mulInv;
  //
  affine[0] = after_mulInv[0]
            ^ after_mulInv[4]
            ^ after_mulInv[5]
            ^ after_mulInv[6]
            ^ after_mulInv[7]
            ^ 1'b1;

  affine[1] = after_mulInv[0]
            ^ after_mulInv[1]
            ^ after_mulInv[5]
            ^ after_mulInv[6]
            ^ after_mulInv[7]
            ^ 1'b1;

  affine[2] = after_mulInv[0]
            ^ after_mulInv[1]
            ^ after_mulInv[2]
            ^ after_mulInv[6]
            ^ after_mulInv[7];

  affine[3] = after_mulInv[0]
            ^ after_mulInv[1]
            ^ after_mulInv[2]
            ^ after_mulInv[3]
            ^ after_mulInv[7];

  affine[4] = after_mulInv[0]
            ^ after_mulInv[1]
            ^ after_mulInv[2]
            ^ after_mulInv[3]
            ^ after_mulInv[4];

  affine[5] = after_mulInv[1]
            ^ after_mulInv[2]
            ^ after_mulInv[3]
            ^ after_mulInv[4]
            ^ after_mulInv[5]
            ^ 1'b1;

  affine[6] = after_mulInv[2]
            ^ after_mulInv[3]
            ^ after_mulInv[4]
            ^ after_mulInv[5]
            ^ after_mulInv[6]
            ^ 1'b1;
  
  affine[7] = after_mulInv[3]
            ^ after_mulInv[4]
            ^ after_mulInv[5]
            ^ after_mulInv[6]
            ^ after_mulInv[7];
endfunction
//-----------------------------------------------------
// Inverse Affine transformation
//-----------------------------------------------------
function logic [7:0] affineInv;
  input [7:0] before_mulInv;
  //
  affineInv[0] = before_mulInv[2]
            ^ before_mulInv[5]
            ^ before_mulInv[7]
            ^ 1'b1;

  affineInv[1] = before_mulInv[0]
            ^ before_mulInv[3]
            ^ before_mulInv[6];

  affineInv[2] = before_mulInv[1]
            ^ before_mulInv[4]
            ^ before_mulInv[7]
            ^ 1'b1;

  affineInv[3] = before_mulInv[0]
            ^ before_mulInv[2]
            ^ before_mulInv[5];

  affineInv[4] = before_mulInv[1]
            ^ before_mulInv[3]
            ^ before_mulInv[6];

  affineInv[5] = before_mulInv[2]
            ^ before_mulInv[4]
            ^ before_mulInv[7];

  affineInv[6] = before_mulInv[0]
            ^ before_mulInv[3]
            ^ before_mulInv[5];
  
  affineInv[7] = before_mulInv[1]
            ^ before_mulInv[4]
            ^ before_mulInv[6];
endfunction

function logic [7:0] mulGf28Inv;
  input [7:0] invInput;
  logic [7:0] after_imp;
  logic [3:0] imp_msb;
  logic [3:0] imp_lsb;
  logic [3:0] square;
  logic [3:0] xLamda;
  logic [3:0] lsb_xor_msb;
  logic [3:0] lsb_mulGf24;
  logic [3:0] xor_branch;
  logic [3:0] inv_branch;
  logic [7:0] imp_inv_in;
  //---------------------------------
  //Isomorphic mapping
  //---------------------------------
  after_imp[7] =   invInput[7]
                 ^ invInput[5];
                 
  after_imp[6] =   invInput[7]
                 ^ invInput[6]
                 ^ invInput[4]
                 ^ invInput[3]
                 ^ invInput[2]
                 ^ invInput[1];
  
  after_imp[5] =   invInput[7]
                 ^ invInput[5]
                 ^ invInput[3]
                 ^ invInput[2];
  
  after_imp[4] =   invInput[7]
                 ^ invInput[5]
                 ^ invInput[3]
                 ^ invInput[2]
                 ^ invInput[1];
  
  after_imp[3] =   invInput[7]
                 ^ invInput[6]
                 ^ invInput[2]
                 ^ invInput[1];
  
  after_imp[2] =   invInput[7]
                 ^ invInput[4]
                 ^ invInput[3]
                 ^ invInput[2]
                 ^ invInput[1];
  
  after_imp[1] =   invInput[6]
                 ^ invInput[4]
                 ^ invInput[1];
  
  after_imp[0] =   invInput[6]
                 ^ invInput[1]
                 ^ invInput[0];
  
  imp_msb[3:0] = after_imp[7:4];
  imp_lsb[3:0] = after_imp[3:0];
  //---------------------------------
  //MSB branch calculation
  //---------------------------------
  //Square
  square[3] = imp_msb[3];
  square[2] = imp_msb[3] ^ imp_msb[2];
  square[1] = imp_msb[2] ^ imp_msb[1];
  square[0] = imp_msb[3] ^ imp_msb[1] ^ imp_msb[0];
  //x Lambda
  xLamda[3] = square[2] ^ square[0];
  xLamda[2] = ^square[3:0];
  xLamda[1] = square[3];
  xLamda[0] = square[2];
  //---------------------------------
  //LSB branch calculation
  //---------------------------------
  //XOR with MSB
  lsb_xor_msb[3:0] = imp_msb[3:0] ^ imp_lsb[3:0];
  //Multiplication
  lsb_mulGf24[3:0] = mulGf24(lsb_xor_msb, imp_lsb);
  //---------------------------------
  //XOR MSB branch and LAB branch
  //---------------------------------
  xor_branch[3:0] = xLamda[3:0] ^ lsb_mulGf24[3:0];
  //---------------------------------
  //Multiplication inverse in GF(2^4)
  //---------------------------------
  case (xor_branch[3:0])
    4'h0: inv_branch[3:0] = 4'h0;
    4'h1: inv_branch[3:0] = 4'h1;
    4'h2: inv_branch[3:0] = 4'h3;
    4'h3: inv_branch[3:0] = 4'h2;
    4'h4: inv_branch[3:0] = 4'hF;
    4'h5: inv_branch[3:0] = 4'hC;
    4'h6: inv_branch[3:0] = 4'h9;
    4'h7: inv_branch[3:0] = 4'hB;
    4'h8: inv_branch[3:0] = 4'hA;
    4'h9: inv_branch[3:0] = 4'h6;
    4'ha: inv_branch[3:0] = 4'h8;
    4'hb: inv_branch[3:0] = 4'h7;
    4'hc: inv_branch[3:0] = 4'h5;
    4'hd: inv_branch[3:0] = 4'hE;
    4'he: inv_branch[3:0] = 4'hD;
    4'hf: inv_branch[3:0] = 4'h4;
    default: inv_branch[3:0] = 4'hx;
  endcase
  //---------------------------------
  //Final multiplication
  //---------------------------------
  imp_inv_in[7:4] = mulGf24(after_imp[7:4], inv_branch[3:0]);
  imp_inv_in[3:0] = mulGf24(lsb_xor_msb[3:0], inv_branch[3:0]);
  //---------------------------------
  //Isomorphic inverse
  //---------------------------------
  mulGf28Inv[7] = imp_inv_in[7]
            ^ imp_inv_in[6]
            ^ imp_inv_in[5]
            ^ imp_inv_in[1];
                 
  mulGf28Inv[6] = imp_inv_in[6]
            ^ imp_inv_in[2];
  
  mulGf28Inv[5] = imp_inv_in[6]
            ^ imp_inv_in[5]
            ^ imp_inv_in[1];
  
  mulGf28Inv[4] = imp_inv_in[6]
            ^ imp_inv_in[5]
            ^ imp_inv_in[4]
            ^ imp_inv_in[2]
            ^ imp_inv_in[1];
  
  mulGf28Inv[3] = imp_inv_in[5]
            ^ imp_inv_in[4]
            ^ imp_inv_in[3]
            ^ imp_inv_in[2]
            ^ imp_inv_in[1];
  
  mulGf28Inv[2] = imp_inv_in[7]
            ^ imp_inv_in[4]
            ^ imp_inv_in[3]
            ^ imp_inv_in[2]
            ^ imp_inv_in[1];
  
  mulGf28Inv[1] = imp_inv_in[5]
            ^ imp_inv_in[4];
  
  mulGf28Inv[0] = imp_inv_in[6]
            ^ imp_inv_in[5]
            ^ imp_inv_in[4]
            ^ imp_inv_in[2]
            ^ imp_inv_in[0];
endfunction

function logic [7:0] aes128_sbox;
  input [7:0] sbox_in;
  input encrypt_en;
  //
  logic [7:0] mulInvResult;
  logic [7:0] affineInvResult;
  logic [7:0] before_mulInv;
  //Input
  affineInvResult[7:0] = affineInv(sbox_in[7:0]);
  before_mulInv = encrypt_en? sbox_in[7:0]
                : affineInvResult[7:0];
  //Multiplication inverse in GF(2^8)
  mulInvResult[7:0] = mulGf28Inv(before_mulInv[7:0]);
  //Output
  aes128_sbox[7:0] = encrypt_en? 
                     affine(mulInvResult[7:0])
                   : mulInvResult[7:0];
endfunction