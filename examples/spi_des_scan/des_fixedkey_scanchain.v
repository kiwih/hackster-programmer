`default_nettype none

module des_fixedkey_scanchain #(
    parameter KEY = 64'hFEF9545BB7A45DFD
)(
    input wire clk,
    input wire rst_n,

    input wire [63:0] starttext,
    output wire [63:0] finishtext,
    input wire start,
    input wire encrypt_ndecrypt, // 0: decrypt, 1: encrypt
    output wire busy,

    input wire scan_enable,
    input wire scan_in,
    output wire scan_out
);
    
    wire scan_fsm_out;
    wire scan_l_out;
    wire scan_r_out;

    wire [3:0] round;
    wire ld_output, ld_l_r, sel_l_r;
    des_fixedkey_scanchain_fsm fsm(
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .busy(busy),
        .round(round),
        .ld_output(ld_output),
        .ld_l_r(ld_l_r),
        .sel_l_r(sel_l_r), //0 for l0/r0, 1 for r_round/l_round

        .scan_enable(scan_enable),
        .scan_in(scan_in),
        .scan_out(scan_fsm_out)
    );

    wire [1:48] roundkey;
    des_roundkey_rom #(
        .KEY(KEY)
    ) roundkey_rom(
        .round(encrypt_ndecrypt ? round : 4'd15-round),
        .roundkey(roundkey)
    );


    wire [1:64] input_permuted;
    wire [1:32] l0, r0;

    des_ip IP(
        .in(starttext),
        .out(input_permuted)
    );
    assign l0 = input_permuted[1:32];
    assign r0 = input_permuted[33:64];
    wire [1:32] l_round, r_round;

    wire [1:32] l, r;
    wire [1:32] l_next, r_next;

    assign l_next = sel_l_r ? l_round : l0;
    assign r_next = sel_l_r ? r_round : r0;

    //l register
    scan_register #(
        .WIDTH(32)
    ) l_reg (
        .clk(clk),
        .rst(~rst_n),
        .enable(ld_l_r),
        .data_in(l_next),
        .data_out(l),
        .scan_enable(scan_enable),
        .scan_in(scan_fsm_out),
        .scan_out(scan_l_out)
    );

    //r register
    scan_register #(
        .WIDTH(32)
    ) r_reg (
        .clk(clk),
        .rst(~rst_n),
        .enable(ld_l_r),
        .data_in(r_next),
        .data_out(r),
        .scan_enable(scan_enable),
        .scan_in(scan_l_out),
        .scan_out(scan_r_out)
    );

    wire [1:32] d, e;
    des_f F(
        .in(r),
        .key(roundkey),
        .out(d)
    );

    assign e = d ^ l;
    assign l_round = r;
    assign r_round = e;


    //output register
    wire [1:64] output_permuted;
    des_ip_inv FP(
        .in({e, r}),
        .out(output_permuted)
    );

    scan_register #(
        .WIDTH(64)
    ) output_reg (
        .clk(clk),
        .rst(~rst_n),
        .enable(ld_output),
        .data_in(output_permuted),
        .data_out(finishtext),
        .scan_enable(scan_enable),
        .scan_in(scan_r_out),
        .scan_out(scan_out)
    );

   

endmodule
