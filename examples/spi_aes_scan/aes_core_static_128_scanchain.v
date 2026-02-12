`timescale 1ns / 1ps
`default_nettype none
module aes_core_static_128_scanchain #(
    parameter [127:0] KEY = 128'h00112233445566778899aabbccddeeff
)(
	input wire clk,
    input wire rst_n,
	input wire load_i,
	input wire [127:0] data_i,
	input wire dec_i,
	output wire [127:0] data_o,
	output reg busy_o,
    output wire done_o,

    input wire scan_enable,
    input wire scan_in,
    output wire scan_out
);

wire dec_r;
wire dec_r_scan_out;
scan_register #(
    .WIDTH(1)
) dec_r_reg (
    .clk(clk),
    .rst(~rst_n),
    .enable(load_i),
    .data_in(dec_i),
    .data_out(dec_r),
    .scan_enable(scan_enable),
    .scan_in(scan_in),
    .scan_out(dec_r_scan_out)
);

wire [1:0] state;
reg [1:0] next_state;
wire state_scan_out;
scan_register #(
    .WIDTH(2)
) state_reg (
    .clk(clk),
    .rst(~rst_n),
    .enable(1'b1),
    .data_in(next_state),
    .data_out(state),
    .scan_enable(scan_enable),
    .scan_in(dec_r_scan_out),
    .scan_out(state_scan_out)
);

wire busy_reg;
wire busy_reg_scan_out;
scan_register #(
    .WIDTH(1)
) busy_reg_reg (
    .clk(clk),
    .rst(~rst_n),
    .enable(1'b1),
    .data_in(busy_o),
    .data_out(busy_reg),
    .scan_enable(scan_enable),
    .scan_in(state_scan_out),
    .scan_out(busy_reg_scan_out)
);

wire done_reg_scan_out;
reg done_set, done_clr;
scan_register #(
    .WIDTH(1)
) done_reg_reg (
    .clk(clk),
    .rst(~rst_n),
    .enable(done_set || done_clr),
    .data_in(done_clr ? 0 : 1), //we're done when we were busy and now we're not
    .data_out(done_o),
    .scan_enable(scan_enable),
    .scan_in(busy_reg_scan_out),
    .scan_out(done_reg_scan_out)
);

//filler 3 bits of scan chain to make it all a multiple of 8
wire filler_scan_out;
scan_register #(
    .WIDTH(3)
) filler_reg (
    .clk(clk),
    .rst(~rst_n),
    .enable(1'b0),
    .data_in(3'b0),
    .data_out(),
    .scan_enable(scan_enable),
    .scan_in(done_reg_scan_out),
    .scan_out(filler_scan_out)
);

wire [3:0] round;
wire round_scan_out;
reg round_start, round_count;
scan_register #(
    .WIDTH(4)
) round_reg (
    .clk(clk),
    .rst(~rst_n),
    .enable(round_start || round_count),
    .data_in(
        round_start ? (dec_r ? 9 : 1) : (dec_r ? round - 1 : round + 1)
    ),
    .data_out(round),
    .scan_enable(scan_enable),
    .scan_in(filler_scan_out),
    .scan_out(round_scan_out)
);

wire [3:0] start_round;
wire start_round_scan_out;
scan_register #(
    .WIDTH(4)
) start_round_reg (
    .clk(clk),
    .rst(~rst_n),
    .enable(round_start),
    .data_in(dec_r ? 10 : 0),
    .data_out(start_round),
    .scan_enable(scan_enable),
    .scan_in(round_scan_out),
    .scan_out(start_round_scan_out)
);

wire [127:0] text_next;
wire [127:0] text_o;
reg text_en, text_clr;
wire text_scan_out;
scan_register #(
    .WIDTH(128)
) text_reg (
    .clk(clk),
    .rst(~rst_n),
    .enable(text_clr || text_en),
    .data_in(text_clr ? 0 : text_next),
    .data_out(text_o),
    .scan_enable(scan_enable),
    .scan_in(start_round_scan_out),
    .scan_out(text_scan_out)
);

assign data_o = text_o;

wire [127:0] rk0, rk;
aes_ks_static_128 #(
    .key_i(KEY)
) aes_ks (
    .index0(start_round),
    .index(round),
    .rk0(rk0),
    .rk(rk)
);

wire [127:0] rkx0_o = data_i ^ rk0;

reg roundi_sel; //1: text, 0: rkx0_o
wire [127:0] roundi = roundi_sel ? text_o : rkx0_o;

wire [127:0] mxci_o;
aes_mixcolumns_inv mxci(
    .mxc_i(roundi),
    .mxc_o(mxci_o)
);

reg shri_i_sel; //1: roundi, 0: mxci_o
wire [127:0] shri_i = shri_i_sel ? roundi : mxci_o;
wire [127:0] shri_o;
aes_shiftrows_inv shri(
    .shr_i(shri_i),
    .shr_o(shri_o)
);

wire [127:0] sbb_i, sbb_o;
assign sbb_i = dec_r ? shri_o : roundi; //if decrypting we're using the inverted stuff, 
                                       //otherwise this is start of encryption

aes_sboxes sbb(
    .sbb_i(sbb_i),
    .dec_r(dec_r),
    .sbb_o(sbb_o)
);

wire [127:0] shr_o;
aes_shiftrows shr(
    .shr_i(sbb_o),
    .shr_o(shr_o)
);

wire [127:0] mxc_o;
aes_mixcolumns mxc(
    .mxc_i(shr_o),
    .mxc_o(mxc_o)
);

reg rkx_i_enc_sel; //1: shr_o, 0: mxc_o
wire [127:0] rkx_i_enc = rkx_i_enc_sel ? shr_o : mxc_o;

wire [127:0] rkx_i = dec_r ? sbb_o : rkx_i_enc; //if decrypting we're just using the sbox output,
                                                //if encrypting we now use all the other stuff

assign text_next = rkx_i ^ rk;


localparam [1:0] S_IDLE = 2'd0,
                 S_INIT = 2'd1,
                 S_FIRST = 2'd2,
                 S_ROUND = 2'd3;

assign scan_out = text_scan_out;

always@(state, load_i, round, start_round) begin
    round_count <= 0;
    round_start <= 0;
    text_en <= 0;
    text_clr <= 0;
    roundi_sel <= 0; //1: text, 0: rkx0_o
    shri_i_sel <= 0; //1: roundi, 0: mxci_o
    rkx_i_enc_sel <= 0; //1: shr_o, 0: mxc_o
    busy_o <= 0;
    done_set <= 0;
    done_clr <= 0;
    case(state)
        S_IDLE: begin
            done_clr <= 1; //clear the done bit
            if(load_i)
                next_state = S_INIT;
            else
                next_state = S_IDLE;
        end
        S_INIT: begin
            round_start <= 1;
            text_clr <= 1; //clear the text
            busy_o <= 1; //we're busy
            next_state = S_FIRST;
        end
        S_FIRST: begin
            roundi_sel <= 0; //first round takes input xor with key
            shri_i_sel <= 1; //first round has no inverse mix column if decrypting
            text_en <= 1; //we'll be saving the intermediate
            round_count <= 1; //we're doing a count
            busy_o <= 1; //we're busy
            next_state = S_ROUND;
        end
        S_ROUND: begin
            roundi_sel <= 1; //later rounds take the intermediate
            shri_i_sel <= 0; //later rounds have inverse mix column
            rkx_i_enc_sel <= 0; //later rounds have mix column
            text_en <= 1; //we'll be saving the intermediate
            round_count <= 1; //we're doing a count
            busy_o <= 1; //we're busy
            rkx_i_enc_sel <= (round == 10) ? 1 : 0; //last round has no mix column if decrypting 
            
            if(round == 0 && start_round == 10 || round == 10 && start_round == 0) begin
                next_state <= S_IDLE;
                done_set <= 1; //we're done after this round
            end else
                next_state <= S_ROUND;
        end

    endcase
end

endmodule
