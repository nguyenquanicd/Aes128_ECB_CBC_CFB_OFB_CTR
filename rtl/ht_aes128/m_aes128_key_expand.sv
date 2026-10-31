/*
 * Project      : AES-128 ECB/CBC/CFB/OFB/CTR
 * Author       : Nguyen Hung Quan (user)
 * AI Flow      : VLSIT RTL Generator AI Automation Flow
 * AI Flow Page : https://github.com/nguyenquanicd/VLSIT_RTL_Generator_AI_Model
 * Date         : 2026-10-28
 * Description  : Derives and packs AES-128 round keys K0 through K10 from one key.
 */
`timescale 1ns/1ps

module m_aes128_key_expand #(
  localparam logic [31:0] LPARA_AES_BLOCK_WIDTH = 32'd128,
  localparam logic [31:0] LPARA_AES_ROUND_KEYS_WIDTH = 32'd1408,
  localparam logic [31:0] LPARA_AES_ROUND_COUNT = 32'd10
) (
  // Key expansion interface
  input  wire  [LPARA_AES_BLOCK_WIDTH-1:0]      i_key,
  output logic [LPARA_AES_ROUND_KEYS_WIDTH-1:0] o_round_keys
);

  // These signals hold the prior key, next key, S-box word, and round constant.
  logic [LPARA_AES_BLOCK_WIDTH-1:0] w_round_key;
  logic [LPARA_AES_BLOCK_WIDTH-1:0] w_round_key_nxt;
  logic [31:0] w_sub_word;
  logic [7:0] w_round_constant;

  // Round identifiers name the AES-128 round-constant selections.
  typedef enum logic [31:0] {
    ENUM_AES_ROUND_1 = 32'd1,
    ENUM_AES_ROUND_2 = 32'd2,
    ENUM_AES_ROUND_3 = 32'd3,
    ENUM_AES_ROUND_4 = 32'd4,
    ENUM_AES_ROUND_5 = 32'd5,
    ENUM_AES_ROUND_6 = 32'd6,
    ENUM_AES_ROUND_7 = 32'd7,
    ENUM_AES_ROUND_8 = 32'd8,
    ENUM_AES_ROUND_9 = 32'd9,
    ENUM_AES_ROUND_10 = 32'd10
  } aes_round_type_def;

  // Forward AES substitution table from FIPS 197, indexed by one input byte.
  function automatic logic [7:0] f_sbox(input logic [7:0] i_byte);
    begin
      f_sbox = 8'h00;
      case (i_byte)
      8'h00: f_sbox = 8'h63;
      8'h01: f_sbox = 8'h7c;
      8'h02: f_sbox = 8'h77;
      8'h03: f_sbox = 8'h7b;
      8'h04: f_sbox = 8'hf2;
      8'h05: f_sbox = 8'h6b;
      8'h06: f_sbox = 8'h6f;
      8'h07: f_sbox = 8'hc5;
      8'h08: f_sbox = 8'h30;
      8'h09: f_sbox = 8'h01;
      8'h0a: f_sbox = 8'h67;
      8'h0b: f_sbox = 8'h2b;
      8'h0c: f_sbox = 8'hfe;
      8'h0d: f_sbox = 8'hd7;
      8'h0e: f_sbox = 8'hab;
      8'h0f: f_sbox = 8'h76;
      8'h10: f_sbox = 8'hca;
      8'h11: f_sbox = 8'h82;
      8'h12: f_sbox = 8'hc9;
      8'h13: f_sbox = 8'h7d;
      8'h14: f_sbox = 8'hfa;
      8'h15: f_sbox = 8'h59;
      8'h16: f_sbox = 8'h47;
      8'h17: f_sbox = 8'hf0;
      8'h18: f_sbox = 8'had;
      8'h19: f_sbox = 8'hd4;
      8'h1a: f_sbox = 8'ha2;
      8'h1b: f_sbox = 8'haf;
      8'h1c: f_sbox = 8'h9c;
      8'h1d: f_sbox = 8'ha4;
      8'h1e: f_sbox = 8'h72;
      8'h1f: f_sbox = 8'hc0;
      8'h20: f_sbox = 8'hb7;
      8'h21: f_sbox = 8'hfd;
      8'h22: f_sbox = 8'h93;
      8'h23: f_sbox = 8'h26;
      8'h24: f_sbox = 8'h36;
      8'h25: f_sbox = 8'h3f;
      8'h26: f_sbox = 8'hf7;
      8'h27: f_sbox = 8'hcc;
      8'h28: f_sbox = 8'h34;
      8'h29: f_sbox = 8'ha5;
      8'h2a: f_sbox = 8'he5;
      8'h2b: f_sbox = 8'hf1;
      8'h2c: f_sbox = 8'h71;
      8'h2d: f_sbox = 8'hd8;
      8'h2e: f_sbox = 8'h31;
      8'h2f: f_sbox = 8'h15;
      8'h30: f_sbox = 8'h04;
      8'h31: f_sbox = 8'hc7;
      8'h32: f_sbox = 8'h23;
      8'h33: f_sbox = 8'hc3;
      8'h34: f_sbox = 8'h18;
      8'h35: f_sbox = 8'h96;
      8'h36: f_sbox = 8'h05;
      8'h37: f_sbox = 8'h9a;
      8'h38: f_sbox = 8'h07;
      8'h39: f_sbox = 8'h12;
      8'h3a: f_sbox = 8'h80;
      8'h3b: f_sbox = 8'he2;
      8'h3c: f_sbox = 8'heb;
      8'h3d: f_sbox = 8'h27;
      8'h3e: f_sbox = 8'hb2;
      8'h3f: f_sbox = 8'h75;
      8'h40: f_sbox = 8'h09;
      8'h41: f_sbox = 8'h83;
      8'h42: f_sbox = 8'h2c;
      8'h43: f_sbox = 8'h1a;
      8'h44: f_sbox = 8'h1b;
      8'h45: f_sbox = 8'h6e;
      8'h46: f_sbox = 8'h5a;
      8'h47: f_sbox = 8'ha0;
      8'h48: f_sbox = 8'h52;
      8'h49: f_sbox = 8'h3b;
      8'h4a: f_sbox = 8'hd6;
      8'h4b: f_sbox = 8'hb3;
      8'h4c: f_sbox = 8'h29;
      8'h4d: f_sbox = 8'he3;
      8'h4e: f_sbox = 8'h2f;
      8'h4f: f_sbox = 8'h84;
      8'h50: f_sbox = 8'h53;
      8'h51: f_sbox = 8'hd1;
      8'h52: f_sbox = 8'h00;
      8'h53: f_sbox = 8'hed;
      8'h54: f_sbox = 8'h20;
      8'h55: f_sbox = 8'hfc;
      8'h56: f_sbox = 8'hb1;
      8'h57: f_sbox = 8'h5b;
      8'h58: f_sbox = 8'h6a;
      8'h59: f_sbox = 8'hcb;
      8'h5a: f_sbox = 8'hbe;
      8'h5b: f_sbox = 8'h39;
      8'h5c: f_sbox = 8'h4a;
      8'h5d: f_sbox = 8'h4c;
      8'h5e: f_sbox = 8'h58;
      8'h5f: f_sbox = 8'hcf;
      8'h60: f_sbox = 8'hd0;
      8'h61: f_sbox = 8'hef;
      8'h62: f_sbox = 8'haa;
      8'h63: f_sbox = 8'hfb;
      8'h64: f_sbox = 8'h43;
      8'h65: f_sbox = 8'h4d;
      8'h66: f_sbox = 8'h33;
      8'h67: f_sbox = 8'h85;
      8'h68: f_sbox = 8'h45;
      8'h69: f_sbox = 8'hf9;
      8'h6a: f_sbox = 8'h02;
      8'h6b: f_sbox = 8'h7f;
      8'h6c: f_sbox = 8'h50;
      8'h6d: f_sbox = 8'h3c;
      8'h6e: f_sbox = 8'h9f;
      8'h6f: f_sbox = 8'ha8;
      8'h70: f_sbox = 8'h51;
      8'h71: f_sbox = 8'ha3;
      8'h72: f_sbox = 8'h40;
      8'h73: f_sbox = 8'h8f;
      8'h74: f_sbox = 8'h92;
      8'h75: f_sbox = 8'h9d;
      8'h76: f_sbox = 8'h38;
      8'h77: f_sbox = 8'hf5;
      8'h78: f_sbox = 8'hbc;
      8'h79: f_sbox = 8'hb6;
      8'h7a: f_sbox = 8'hda;
      8'h7b: f_sbox = 8'h21;
      8'h7c: f_sbox = 8'h10;
      8'h7d: f_sbox = 8'hff;
      8'h7e: f_sbox = 8'hf3;
      8'h7f: f_sbox = 8'hd2;
      8'h80: f_sbox = 8'hcd;
      8'h81: f_sbox = 8'h0c;
      8'h82: f_sbox = 8'h13;
      8'h83: f_sbox = 8'hec;
      8'h84: f_sbox = 8'h5f;
      8'h85: f_sbox = 8'h97;
      8'h86: f_sbox = 8'h44;
      8'h87: f_sbox = 8'h17;
      8'h88: f_sbox = 8'hc4;
      8'h89: f_sbox = 8'ha7;
      8'h8a: f_sbox = 8'h7e;
      8'h8b: f_sbox = 8'h3d;
      8'h8c: f_sbox = 8'h64;
      8'h8d: f_sbox = 8'h5d;
      8'h8e: f_sbox = 8'h19;
      8'h8f: f_sbox = 8'h73;
      8'h90: f_sbox = 8'h60;
      8'h91: f_sbox = 8'h81;
      8'h92: f_sbox = 8'h4f;
      8'h93: f_sbox = 8'hdc;
      8'h94: f_sbox = 8'h22;
      8'h95: f_sbox = 8'h2a;
      8'h96: f_sbox = 8'h90;
      8'h97: f_sbox = 8'h88;
      8'h98: f_sbox = 8'h46;
      8'h99: f_sbox = 8'hee;
      8'h9a: f_sbox = 8'hb8;
      8'h9b: f_sbox = 8'h14;
      8'h9c: f_sbox = 8'hde;
      8'h9d: f_sbox = 8'h5e;
      8'h9e: f_sbox = 8'h0b;
      8'h9f: f_sbox = 8'hdb;
      8'ha0: f_sbox = 8'he0;
      8'ha1: f_sbox = 8'h32;
      8'ha2: f_sbox = 8'h3a;
      8'ha3: f_sbox = 8'h0a;
      8'ha4: f_sbox = 8'h49;
      8'ha5: f_sbox = 8'h06;
      8'ha6: f_sbox = 8'h24;
      8'ha7: f_sbox = 8'h5c;
      8'ha8: f_sbox = 8'hc2;
      8'ha9: f_sbox = 8'hd3;
      8'haa: f_sbox = 8'hac;
      8'hab: f_sbox = 8'h62;
      8'hac: f_sbox = 8'h91;
      8'had: f_sbox = 8'h95;
      8'hae: f_sbox = 8'he4;
      8'haf: f_sbox = 8'h79;
      8'hb0: f_sbox = 8'he7;
      8'hb1: f_sbox = 8'hc8;
      8'hb2: f_sbox = 8'h37;
      8'hb3: f_sbox = 8'h6d;
      8'hb4: f_sbox = 8'h8d;
      8'hb5: f_sbox = 8'hd5;
      8'hb6: f_sbox = 8'h4e;
      8'hb7: f_sbox = 8'ha9;
      8'hb8: f_sbox = 8'h6c;
      8'hb9: f_sbox = 8'h56;
      8'hba: f_sbox = 8'hf4;
      8'hbb: f_sbox = 8'hea;
      8'hbc: f_sbox = 8'h65;
      8'hbd: f_sbox = 8'h7a;
      8'hbe: f_sbox = 8'hae;
      8'hbf: f_sbox = 8'h08;
      8'hc0: f_sbox = 8'hba;
      8'hc1: f_sbox = 8'h78;
      8'hc2: f_sbox = 8'h25;
      8'hc3: f_sbox = 8'h2e;
      8'hc4: f_sbox = 8'h1c;
      8'hc5: f_sbox = 8'ha6;
      8'hc6: f_sbox = 8'hb4;
      8'hc7: f_sbox = 8'hc6;
      8'hc8: f_sbox = 8'he8;
      8'hc9: f_sbox = 8'hdd;
      8'hca: f_sbox = 8'h74;
      8'hcb: f_sbox = 8'h1f;
      8'hcc: f_sbox = 8'h4b;
      8'hcd: f_sbox = 8'hbd;
      8'hce: f_sbox = 8'h8b;
      8'hcf: f_sbox = 8'h8a;
      8'hd0: f_sbox = 8'h70;
      8'hd1: f_sbox = 8'h3e;
      8'hd2: f_sbox = 8'hb5;
      8'hd3: f_sbox = 8'h66;
      8'hd4: f_sbox = 8'h48;
      8'hd5: f_sbox = 8'h03;
      8'hd6: f_sbox = 8'hf6;
      8'hd7: f_sbox = 8'h0e;
      8'hd8: f_sbox = 8'h61;
      8'hd9: f_sbox = 8'h35;
      8'hda: f_sbox = 8'h57;
      8'hdb: f_sbox = 8'hb9;
      8'hdc: f_sbox = 8'h86;
      8'hdd: f_sbox = 8'hc1;
      8'hde: f_sbox = 8'h1d;
      8'hdf: f_sbox = 8'h9e;
      8'he0: f_sbox = 8'he1;
      8'he1: f_sbox = 8'hf8;
      8'he2: f_sbox = 8'h98;
      8'he3: f_sbox = 8'h11;
      8'he4: f_sbox = 8'h69;
      8'he5: f_sbox = 8'hd9;
      8'he6: f_sbox = 8'h8e;
      8'he7: f_sbox = 8'h94;
      8'he8: f_sbox = 8'h9b;
      8'he9: f_sbox = 8'h1e;
      8'hea: f_sbox = 8'h87;
      8'heb: f_sbox = 8'he9;
      8'hec: f_sbox = 8'hce;
      8'hed: f_sbox = 8'h55;
      8'hee: f_sbox = 8'h28;
      8'hef: f_sbox = 8'hdf;
      8'hf0: f_sbox = 8'h8c;
      8'hf1: f_sbox = 8'ha1;
      8'hf2: f_sbox = 8'h89;
      8'hf3: f_sbox = 8'h0d;
      8'hf4: f_sbox = 8'hbf;
      8'hf5: f_sbox = 8'he6;
      8'hf6: f_sbox = 8'h42;
      8'hf7: f_sbox = 8'h68;
      8'hf8: f_sbox = 8'h41;
      8'hf9: f_sbox = 8'h99;
      8'hfa: f_sbox = 8'h2d;
      8'hfb: f_sbox = 8'h0f;
      8'hfc: f_sbox = 8'hb0;
      8'hfd: f_sbox = 8'h54;
      8'hfe: f_sbox = 8'hbb;
      8'hff: f_sbox = 8'h16;
        default: f_sbox = 8'h00;
      endcase
    end
  endfunction

  // The key schedule rotates and substitutes the previous final word, then applies Rcon.
  always_comb begin : p_com_key_expand
    o_round_keys = '0;
    w_round_key = i_key;
    w_round_key_nxt = '0;
    w_sub_word = '0;
    w_round_constant = 8'h00;
    o_round_keys[127:0] = i_key;
    for (int round_idx = 1; round_idx <= LPARA_AES_ROUND_COUNT; round_idx++) begin
      w_round_constant = 8'h00;
      case (aes_round_type_def'(round_idx))
        ENUM_AES_ROUND_1:  w_round_constant = 8'h01;
        ENUM_AES_ROUND_2:  w_round_constant = 8'h02;
        ENUM_AES_ROUND_3:  w_round_constant = 8'h04;
        ENUM_AES_ROUND_4:  w_round_constant = 8'h08;
        ENUM_AES_ROUND_5:  w_round_constant = 8'h10;
        ENUM_AES_ROUND_6:  w_round_constant = 8'h20;
        ENUM_AES_ROUND_7:  w_round_constant = 8'h40;
        ENUM_AES_ROUND_8:  w_round_constant = 8'h80;
        ENUM_AES_ROUND_9:  w_round_constant = 8'h1b;
        ENUM_AES_ROUND_10: w_round_constant = 8'h36;
        default: w_round_constant = 8'h00;
      endcase
      w_sub_word = {
        f_sbox(w_round_key[23:16]),
        f_sbox(w_round_key[15:8]),
        f_sbox(w_round_key[7:0]),
        f_sbox(w_round_key[31:24])
      } ^ {w_round_constant, 24'd0};
      w_round_key_nxt[127:96] = w_round_key[127:96] ^ w_sub_word;
      w_round_key_nxt[95:64] = w_round_key[95:64] ^ w_round_key_nxt[127:96];
      w_round_key_nxt[63:32] = w_round_key[63:32] ^ w_round_key_nxt[95:64];
      w_round_key_nxt[31:0] = w_round_key[31:0] ^ w_round_key_nxt[63:32];
      w_round_key = w_round_key_nxt;
      o_round_keys[round_idx * LPARA_AES_BLOCK_WIDTH
                   +: LPARA_AES_BLOCK_WIDTH] = w_round_key_nxt;
    end
  end

endmodule
