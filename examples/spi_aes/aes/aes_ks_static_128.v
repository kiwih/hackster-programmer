module aes_ks_static_128 #(
	parameter [127:0] key_i = 128'h00112233445566778899aabbccddeeff
)(
	input wire [3:0] index0,
	input wire [3:0] index,
	output wire [127:0] rk0,
	output wire [127:0] rk
//	output wire [127:0] rks_o [0:10]	
);
wire [127:0] rks_o [0:10];

assign rk0 = rks_o[index0];
assign rk = rks_o[index];

function [7:0] rconi;
	input [3:0] i;
	begin
		case(i)
		0: rconi = 8'h01;
		1: rconi = 8'h02;
		2: rconi = 8'h04;
		3: rconi = 8'h08;
		4: rconi = 8'h10;
		5: rconi = 8'h20;
		6: rconi = 8'h40;
		7: rconi = 8'h80;
		8: rconi = 8'h1b;
		9: rconi = 8'h36;
		default: rconi = 8'h00;
		endcase
	end
endfunction

genvar i;

assign rks_o[0][127:0] = key_i[127:0];

generate
	for(i=1; i<11; i=i+1) begin: key_schedule
		wire [31:0] w0_last = rks_o[i-1][127:96];
		wire [31:0] w1_last = rks_o[i-1][95:64];
		wire [31:0] w2_last = rks_o[i-1][63:32];
		wire [31:0] w3_last = rks_o[i-1][31:0];

		wire [31:0] w0_last_rot = {w3_last[23:0], w3_last[31:24]};
		wire [31:0] w0_last_sub;
		`ifdef SBOX_GF
			aes_sbox ks_inst0(.U(w0_last_rot[7:0]),   .dec(1'b0), .S(w0_last_sub[7:0]));
			aes_sbox ks_inst1(.U(w0_last_rot[15:8]),  .dec(1'b0), .S(w0_last_sub[15:8]));
			aes_sbox ks_inst2(.U(w0_last_rot[23:16]), .dec(1'b0), .S(w0_last_sub[23:16]));
			aes_sbox ks_inst3(.U(w0_last_rot[31:24]), .dec(1'b0), .S(w0_last_sub[31:24]));
		`else
			aes_sbox_lut ks_inst0(.byte_in(w0_last_rot[7:0]),   .dec(1'b0), .byte_out(w0_last_sub[7:0]));
			aes_sbox_lut ks_inst1(.byte_in(w0_last_rot[15:8]),  .dec(1'b0), .byte_out(w0_last_sub[15:8]));
			aes_sbox_lut ks_inst2(.byte_in(w0_last_rot[23:16]), .dec(1'b0), .byte_out(w0_last_sub[23:16]));
			aes_sbox_lut ks_inst3(.byte_in(w0_last_rot[31:24]), .dec(1'b0), .byte_out(w0_last_sub[31:24]));
		`endif
		wire [31:0] g = w0_last_sub ^ {rconi(i-1), 8'h00, 8'h00, 8'h00};

		wire [31:0] w0_new = w0_last ^ g;
		wire [31:0] w1_new = w1_last ^ w0_new;
		wire [31:0] w2_new = w2_last ^ w1_new;
		wire [31:0] w3_new = w3_last ^ w2_new;

		assign rks_o[i] = {w0_new, w1_new, w2_new, w3_new};
	end
endgenerate

endmodule
