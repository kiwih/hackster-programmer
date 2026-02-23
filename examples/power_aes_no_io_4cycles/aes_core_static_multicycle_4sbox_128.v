`timescale 1ns / 1ps
`default_nettype none
module aes_core_static_multicycle_4sbox_128 #(
    parameter [127:0] KEY = 128'h00112233445566778899aabbccddeeff
)(
	input wire clk,
    input wire rst_n,
	input wire load_i,
	input wire [127:0] data_i,
	input wire dec_i,
	output wire [127:0] data_o,
	output reg busy_o
);

reg dec_r;
always @(posedge clk)
begin
    if(load_i)
        dec_r <= dec_i;
end

reg [3:0] round;
reg [3:0] start_round;
reg round_count, round_start;
always@(posedge clk)
begin
    if(round_start) begin
        round <= dec_r ? 9 : 1;
        start_round <= dec_r ? 10 : 0;
    end else if(round_count)
        round <= dec_r ? round - 1 : round + 1;
end

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

wire [127:0] text_next;
wire [127:0] text_i;
reg text_i_sel; //1: text_next, 0: rkx0_o
assign text_i = text_i_sel ? text_next : rkx0_o;
reg [127:0] text_o;
reg text_en, text_clr;
always@(posedge clk)
begin
    if(text_clr)
        text_o <= 0;
    else if(text_en)
        text_o <= text_i;
end

assign data_o = text_o;

wire [127:0] roundi = text_o;

wire [127:0] mxci_o;
aes_mixcolumns_inv mxci(
    .mxc_i(roundi),
    .mxc_o(mxci_o)
);

reg shri_i_sel; //1: roundi, 0: mxci_o
wire [127:0] shri_i = shri_i_sel ? roundi : mxci_o;
wire [127:0] shri_o;
aes_shiftrows shri(
    .shr_i(shri_i),
    .shr_o(shri_o),
    .inverse(dec_r)
);

wire [127:0] sbb_i, sbb_o;
assign sbb_i = shri_o; //dec_r ? shri_o : roundi; //if decrypting we're using the inverted stuff, 
                                       //otherwise this is start of encryption

wire [31:0] sbb_col0 = {sbb_i[ 31:0]};
wire [31:0] sbb_col1 = {sbb_i[ 63:32]};
wire [31:0] sbb_col2 = {sbb_i[ 95:64]};
wire [31:0] sbb_col3 = {sbb_i[127:96]};

reg [1:0] sbb_col_sel;
reg sbb_col_sel_clr, sbb_col_sel_inc;
always@(posedge clk)
begin
    if(sbb_col_sel_clr)
        sbb_col_sel <= 0;
    else if(sbb_col_sel_inc)
        sbb_col_sel <= sbb_col_sel + 1;
end

wire [31:0] sbb_i_actual = (sbb_col_sel == 2'd0) ? sbb_col0 :
                           (sbb_col_sel == 2'd1) ? sbb_col1 :
                           (sbb_col_sel == 2'd2) ? sbb_col2 :
                                                  sbb_col3 ; 

wire [31:0] sbb_o_actual;

aes_sboxes4 sbb(
    .sbb_i(sbb_i_actual),
    .dec_r(dec_r),
    .sbb_o(sbb_o_actual)
);

reg [127:0] stext_o_int;
reg stext_en, stext_clr;
always@(posedge clk)
begin
    if(stext_clr)
        stext_o_int <= 0;
    else if(stext_en)
        case(sbb_col_sel)
            2'd0: stext_o_int[ 31: 0]   <= sbb_o_actual;
            2'd1: stext_o_int[ 63:32]   <= sbb_o_actual;
            2'd2: stext_o_int[ 95:64]   <= sbb_o_actual;
            2'd3: stext_o_int[127:96]   <= sbb_o_actual;
        endcase
end

reg silent;
wire [127:0] stext_o = silent ? 0 : stext_o_int;

// signal_amplify sa(
//     .data(sbb_o)
// );


wire [127:0] mxc_o;
aes_mixcolumns mxc(
    .mxc_i(stext_o),
    .mxc_o(mxc_o)
);

reg rkx_i_enc_sel; //1: stext_o, 0: mxc_o
wire [127:0] rkx_i_enc = rkx_i_enc_sel ? stext_o : mxc_o;

wire [127:0] rkx_i = dec_r ? stext_o : rkx_i_enc; //if decrypting we're just using the sbox output,
                                                //if encrypting we now use all the other stuff

assign text_next = rkx_i ^ rk;

localparam [2:0] S_IDLE = 3'd0,
                 S_CLR = 3'd1,
                 S_INIT = 3'd2,
                 S_ROUND_SBOXES = 3'd3,
                 S_ROUND_RK = 3'd4;

reg [2:0] state, next_state;

always@(posedge clk)
    if (!rst_n)
        state <= S_IDLE;
    else
        state <= next_state;

always@(state, load_i, round, start_round, sbb_col_sel) begin
    round_count <= 0;
    round_start <= 0;
    text_en <= 0;
    text_clr <= 0;
    text_i_sel <= 0; //1: text_next, 0: rkx0_o
    shri_i_sel <= 0; //1: roundi, 0: mxci_o
    rkx_i_enc_sel <= 0; //1: stext_o, 0: mxc_o
    stext_en <= 0;
    stext_clr <= 0;
    sbb_col_sel_clr <= 0;
    sbb_col_sel_inc <= 0;
    busy_o <= 0;
    silent <= 0;
    case(state)
        S_IDLE: begin
            if(load_i) begin
                next_state = S_CLR;
            end else
                next_state = S_IDLE;
        end
        S_CLR: begin
            round_start <= 1;
            text_i_sel <= 0; //initial value comes from rkx0_o
            text_clr <= 1; //clear the text
            stext_clr <= 1; //clear the sbox reg text
            sbb_col_sel_clr <= 1; //clear sbox col selector
            busy_o <= 1; //we're busy
            next_state = S_INIT;
        end
        S_INIT: begin
            text_i_sel <= 0; //initial value comes from rkx0_o
            text_en <= 1; //we'll be saving the intermediate
            busy_o <= 1; //we're busy
            next_state = S_ROUND_SBOXES;
        end
        S_ROUND_SBOXES: begin
            shri_i_sel <= dec_r ? (round == 9 ? 1 : 0) : 1; //later rounds of decryption have inverse mix column
            sbb_col_sel_inc <= 1; //increment sbox col selector
            stext_en <= 1; //we'll be saving the sbox output
            busy_o <= 1; //we're busy
            silent <= 1; //don't propagate sbox output yet
            if(sbb_col_sel == 2'd3)
                next_state <= S_ROUND_RK;
            else
                next_state <= S_ROUND_SBOXES;
        end
        S_ROUND_RK: begin
            text_i_sel <= 1; //later rounds take the intermediate
            text_en <= 1; //we'll be saving the intermediate
            round_count <= 1; //we're doing a count
            busy_o <= 1; //we're busy
            rkx_i_enc_sel <= (round == 10) ? 1 : 0; //last round has no mix column if decrypting 
            
            if(round == 0 && start_round == 10 || round == 10 && start_round == 0)
                next_state <= S_IDLE;
            else
                next_state <= S_ROUND_SBOXES;
        end

    endcase
end

endmodule
