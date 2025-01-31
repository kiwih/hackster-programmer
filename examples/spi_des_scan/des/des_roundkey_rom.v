module des_roundkey_rom #(
    parameter KEY = 64'hFEF9545BB7A45DFD
)(
    input wire [3:0] round,
    output wire [47:0] roundkey
);

    wire [1:56] key_permuted;

    des_pc1 PC1(
        .in(KEY),
        .out(key_permuted)
    );

    wire [1:56] key_rom_pre_pc2 [0:16];
    wire [1:48] key_rom [1:16];

    assign key_rom_pre_pc2[0] = key_permuted[1:56];

    genvar i;
    generate 
        for(i = 1; i <= 16; i = i + 1) begin : genroundkey
            wire [3:0] roundi = i - 1;
            des_keyrotate KR_l(
                .round(roundi),
                .in(key_rom_pre_pc2[i-1][1:28]),
                .out(key_rom_pre_pc2[i][1:28])
            );
            des_keyrotate KR_r(
                .round(roundi),
                .in(key_rom_pre_pc2[i-1][29:56]),
                .out(key_rom_pre_pc2[i][29:56])
            );
            des_pc2 PC2(
                .in(key_rom_pre_pc2[i]),
                .out(key_rom[i])
            );
        end

    endgenerate

    assign roundkey = key_rom[round+1];

endmodule
