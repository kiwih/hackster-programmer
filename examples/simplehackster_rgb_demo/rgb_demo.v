`default_nettype none

module rgb_demo (
    input wire ICE_CLK,
    input wire PI_ICE_BTN,
    output wire ICE_LED, RGB_R, RGB_G, RGB_B
);

wire CLK_10MHz;
assign CLK_10MHz = ICE_CLK;

wire BTN;
assign BTN = PI_ICE_BTN;

wire LED;
assign ICE_LED = LED;

reg rgb_r_pwm = 0;
reg rgb_g_pwm = 1;
reg rgb_b_pwm = 0;

SB_RGBA_DRV
  RGB_DRV(.CURREN(1'b1),
          .RGBLEDEN(1'b1),
          .RGB0PWM(rgb_r_pwm),
          .RGB1PWM(rgb_g_pwm),
          .RGB2PWM(rgb_b_pwm),
          .RGB0(RGB_R),
          .RGB1(RGB_G),
          .RGB2(RGB_B));

//clock divider to 100kHz
reg [23:0] counter_100kHz_div;
reg clk_100kHz = 0;
always @(posedge CLK_10MHz) begin
    if(counter_100kHz_div == 24'd99) begin
        counter_100kHz_div <= 0;
        clk_100kHz <= ~clk_100kHz;
    end else begin
        counter_100kHz_div <= counter_100kHz_div + 1;
    end
end

//clock divider to 500Hz
reg [23:0] counter_500Hz_div;
reg clk_500Hz = 0;
always @(posedge CLK_10MHz) begin
    if(counter_500Hz_div == 24'd19999) begin
        counter_500Hz_div <= 0;
        clk_500Hz <= ~clk_500Hz;
    end else begin
        counter_500Hz_div <= counter_500Hz_div + 1;
    end
end


reg [7:0] rgb_r_amount = 8'b00000000;
reg [7:0] rgb_g_amount = 8'b00000000;
reg [7:0] rgb_b_amount = 8'b00000000;

reg [7:0] rgb_counter = 8'b00000000;
always @(posedge clk_100kHz) begin
    //set the pwm for each rgb based on current value of the counter
    if(rgb_counter == 8'b11111111) begin
        rgb_counter <= 8'b00000000;
    end else begin
        rgb_counter <= rgb_counter + 1;
    end
    rgb_r_pwm <= rgb_counter < rgb_r_amount ? 1 : 0;
    rgb_g_pwm <= rgb_counter < rgb_g_amount ? 1 : 0;
    rgb_b_pwm <= rgb_counter < rgb_b_amount ? 1 : 0;
end

reg [2:0] rgb_color_state = 0;
//8 colors of the rainbow
//rgb(255, 0, 0)
localparam RGB_COLOR_RED = 0;
//rgb(255, 255, 0)
localparam RGB_COLOR_YELLOW = 1;
//rgb(0, 255, 0)
localparam RGB_COLOR_GREEN = 2;
//rgb(0, 255, 255)
localparam RGB_COLOR_CYAN = 3;
//rgb(0, 0, 255)
localparam RGB_COLOR_BLUE = 4;
//rgb(255, 0, 255)
localparam RGB_COLOR_MAGENTA = 5;
//rgb(255, 255, 255)
localparam RGB_COLOR_WHITE = 6;
//rgb(0, 0, 0)
localparam RGB_COLOR_BLACK = 7;

//have the amount of each color changing to create a rainbow effect
always @(posedge clk_500Hz) begin
    //count the amounts of each rgb until the values are correct for each color, then advance to the next color
    case(rgb_color_state)
        RGB_COLOR_RED: begin
            //if the red amount is at max, go to the next color
            //(we finish at 255, 0, 0)
            if(rgb_r_amount == 8'b11111111) begin
                rgb_color_state <= RGB_COLOR_YELLOW;
            end else begin
                rgb_r_amount <= rgb_r_amount + 1;
            end
        end
        RGB_COLOR_YELLOW: begin
            //if the green amount is at max, go to the next color
            //(we finish at 255, 255, 0)
            if(rgb_g_amount == 8'b11111111) begin
                rgb_color_state <= RGB_COLOR_GREEN;
            end else begin
                rgb_g_amount <= rgb_g_amount + 1;
            end
        end
        RGB_COLOR_GREEN: begin
            //if the red amount is at min, go to the next color
            //(we finish at 0, 255, 0)
            if(rgb_r_amount == 8'b00000000) begin
                rgb_color_state <= RGB_COLOR_CYAN;
            end else begin
                rgb_r_amount <= rgb_r_amount - 1;
            end
        end
        RGB_COLOR_CYAN: begin
            //if the blue amount is at max, go to the next color
            //(we finish at 0, 255, 255)
            if(rgb_b_amount == 8'b11111111) begin
                rgb_color_state <= RGB_COLOR_BLUE;
            end else begin
                rgb_b_amount <= rgb_b_amount + 1;
            end
        end
        RGB_COLOR_BLUE: begin
            //if the green amount is at min, go to the next color
            //(we finish at 0, 0, 255)
            if(rgb_g_amount == 8'b00000000) begin
                rgb_color_state <= RGB_COLOR_MAGENTA;
            end else begin
                rgb_g_amount <= rgb_g_amount - 1;
            end
        end
        RGB_COLOR_MAGENTA: begin
            //if the red amount is at max, go to the next color
            //(we finish at 255, 0, 255)
            if(rgb_r_amount == 8'b11111111) begin
                rgb_color_state <= RGB_COLOR_WHITE;
            end else begin
                rgb_r_amount <= rgb_r_amount + 1;
            end
        end
        RGB_COLOR_WHITE: begin
            //if the blue amount is at max, go to the next color
            //(we finish at 255, 255, 255)
            if(rgb_g_amount == 8'b11111111) begin
                rgb_color_state <= RGB_COLOR_BLACK;
            end else begin
                rgb_g_amount <= rgb_g_amount + 1;
            end
        end
        RGB_COLOR_BLACK: begin
            //if the red amount is at min, go to the next color
            //(we finish at 0, 0, 0)
            if(rgb_r_amount == 8'b00000000) begin
                rgb_color_state <= RGB_COLOR_RED;
            end else begin
                rgb_r_amount <= rgb_r_amount - 1;
                rgb_g_amount <= rgb_r_amount - 1;
                rgb_b_amount <= rgb_r_amount - 1;
            end
        end
    endcase
end

//used to set maximum brightness of the RGB LEDs
defparam RGB_DRV.CURRENT_MODE = "0b0";
defparam RGB_DRV.RGB0_CURRENT = "0b000111"; //r
defparam RGB_DRV.RGB1_CURRENT = "0b000111"; //g
defparam RGB_DRV.RGB2_CURRENT = "0b001111"; //b

// 10MHz clock divider to 1Hz
reg [23:0] counter;
reg led_state = 0;
always @(posedge CLK_10MHz) begin
    if(BTN == 1) begin
        led_state <= 1;
    end else if(counter == 24'd9999999) begin
        counter <= 0;
        led_state <= ~led_state;
    end else begin
        counter <= counter + 1;
    end
end

assign LED = led_state;

//*/

endmodule
