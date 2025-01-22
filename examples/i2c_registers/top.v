`default_nettype none
module top(
    input wire ICE_CLK,
    
    inout wire rp2040_sda, rp2040_scl,
    inout wire periph_sda, periph_scl,

    output reg ICE_LED
);

i2c_reg_and_pass i2c_reg_and_pass_inst (
    .ICE_CLK(ICE_CLK),
    .rp2040_sda(rp2040_sda),
    .rp2040_scl(rp2040_scl),
    .periph_sda(periph_sda),
    .periph_scl(periph_scl)
);