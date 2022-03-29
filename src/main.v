`timescale 1ns / 1ps
`define SYSCLOCK_FREQ 100000000
`define COUNTER_WIDTH 16


//======================================================================================================================
// main() - Top level module
//======================================================================================================================
module main
    (
        input clk,
        input rst_n,
        input BTNU,
        
        output LED16_B,
        
        // The 16 green LEDs
        output [15:0] led,
        
        // The anodes of the rightmost four 7-segment displays 
        output [7:0] AN,
        
        // THe cathods of the 7-segment dispalsy
        output [7:0] SEG
    );
  
   
    // This has a '1' on every clock cycle for which a high-going button-edge is detected
    wire w_button_edge;

    // Variable that tracks how many times the button has been pressed
    reg [`COUNTER_WIDTH-1:0] r_counter = 0;
    
    // This detects fully debounced high-going edges from the button
    button#(.ACTIVE(1)) u1(clk, BTNU, w_button_edge);

    // This displays a value on a four-digit 7-segment display
    four_digit_display u2(clk, r_counter, SEG, AN);

    always @(posedge clk) begin
        if (w_button_edge) r_counter <= r_counter + 1;
    end 
             
    // Light up the blue LED whenever our pushbutton is being pressed
    assign LED16_B = BTNU;
    
    // Display the current count in binary on the 16 green LEDs
    assign led = r_counter;

endmodule
//======================================================================================================================



