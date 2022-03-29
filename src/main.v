`timescale 1ns / 1ps
`define SYSCLOCK_FREQ 100000000
`define COUNTER_WIDTH 16





//======================================================================================================================
// button() - Detects highgoing edges of a pin (for instance, a button)
//
// Input:  clk = system clock
//         pin = the pin to look for a high-going edge on
//
// Output:  q = 1 if a high-going edge is detected, otherwise 0
//
// Notes: edge detection is fully debounced.  q only goes high if a specified pin is still high
//        10ms after the high-going edge was initially detected 
//======================================================================================================================
module button(input clk, input pin, output q);
    
    parameter [31:0] DEBOUNCE_PERIOD = `SYSCLOCK_FREQ / 200;
    
    logic [2:0] button_sync = 0;

    reg [31:0] debounce_clock = 0;
    reg edge_detected = 0;    
    
    // We're going to check for edges on every clock cycle
    always @(posedge clk) begin

        // Bit 2 is the oldest reliable state
        // Bit 1 is the newst reliable state
        // Bit 0 should be considered metastable        
        button_sync = (button_sync << 1) | pin;
        
        // Presume for the moment that we haven't detected the active-going edge of the button        
        edge_detected <= 0;       
        
        // If the debounce clock is about to expire, find out of the user-specicied pin is still high
        if (debounce_clock == 1) begin
            edge_detected <= button_sync[1];
            debounce_clock <= 0;
        end
        
        // Otherwise, the debounce clock is still counting down, decrement it
        else if (debounce_clock != 0) begin
            debounce_clock <= debounce_clock - 1;
        end  
        
        // If the pin is high and was previously low, start the debounce clock
        if (button_sync[2:1] == 2'b01) debounce_clock <= DEBOUNCE_PERIOD;
    end
    
    // The output wire always reflects the state of the 'edge_detected' register
    assign q = edge_detected;
    
endmodule
//======================================================================================================================





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
    button u1(clk, BTNU, w_button_edge);

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



