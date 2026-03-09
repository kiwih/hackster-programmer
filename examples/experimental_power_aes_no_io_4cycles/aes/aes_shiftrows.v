module aes_shiftrows(
    input wire [127:0] shr_i,
    output wire [127:0] shr_o,
    input wire inverse
);

assign shr_o = inverse ? {
    shr_i[127:120], shr_i[ 23: 16], shr_i[ 47: 40], shr_i[ 71: 64],
    shr_i[ 95: 88], shr_i[119:112], shr_i[ 15:  8], shr_i[ 39: 32],
    shr_i[ 63: 56], shr_i[ 87: 80], shr_i[111:104], shr_i[  7:  0],
    shr_i[ 31: 24], shr_i[ 55: 48], shr_i[ 79: 72], shr_i[103: 96]
} : {
    shr_i[127:120], shr_i[ 87: 80], shr_i[ 47: 40], shr_i[  7:  0],
    shr_i[ 95: 88], shr_i[ 55: 48], shr_i[ 15:  8], shr_i[103: 96],
    shr_i[ 63: 56], shr_i[ 23: 16], shr_i[111:104], shr_i[ 71: 64],
    shr_i[ 31: 24], shr_i[119:112], shr_i[ 79: 72], shr_i[ 39: 32]
};

endmodule
