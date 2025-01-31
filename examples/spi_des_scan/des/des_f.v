`default_nettype none

module des_f(
    input wire [1:32] in,
    input wire [1:48] key,
    output wire [1:32] out
);

    wire [1:48] a;

    des_e E(
        .in(in),
        .out(a)
    );

    wire [1:48] b;
    assign b = a ^ key;

    wire [1:32] c;

    des_s1 S1(
        .in(b[1:6]),
        .out(c[1:4])
    );
    des_s2 S2(
        .in(b[7:12]),
        .out(c[5:8])
    );
    des_s3 S3(
        .in(b[13:18]),
        .out(c[9:12])
    );
    des_s4 S4(
        .in(b[19:24]),
        .out(c[13:16])
    );
    des_s5 S5(
        .in(b[25:30]),
        .out(c[17:20])
    );
    des_s6 S6(
        .in(b[31:36]),
        .out(c[21:24])
    );
    des_s7 S7(
        .in(b[37:42]),
        .out(c[25:28])
    );
    des_s8 S8(
        .in(b[43:48]),
        .out(c[29:32])
    );

    wire [1:32] d;

    des_p P(
        .in(c),
        .out(d)
    );

    assign out = d;

endmodule