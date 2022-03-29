`timescale 1ns / 1ps
`define SYSCLOCK_FREQ 100000000

//======================================================================================================================
// button() - Detects the high-going or low-going edge of a pin 
//
// Input:  clk = system clock
//         pin = the pin to look for an edge on
//
// Output:  q = 1 if an active-going edge is detected, otherwise 0
//
// Notes: edge detection is fully debounced.  q only goes high if a specified pin is still active
//        10ms after the active-going edge was initially detected 
//======================================================================================================================
module button#(parameter ACTIVE=1) (input clk, input pin, output q);
    
    parameter [31:0] DEBOUNCE_PERIOD = `SYSCLOCK_FREQ / 100;

    // If ACTIVE=1, an active edge is low-to-high.  If ACTIVE=0, an active edge is high-to-low
    localparam ACTIVE_EDGE = ACTIVE ? 2'b01 : 2'b10;
    
    // All three bits of button_sync start out in the "inactive" state
    logic [2:0] button_sync = ACTIVE ? 3'b000 : 3'b111;
    
    // This count will clock down as a debounce timer
    logic [31:0] debounce_clock = 0;
    
    // This will be 1 on any clock cycle that a fully debounced active-going edge is detected
    logic edge_detected = 0;    
    
    // We're going to check for edges on every clock cycle
    always @(posedge clk) begin

        // Bit 2 is the oldest reliable state
        // Bit 1 is the newst reliable state
        // Bit 0 should be considered metastable        
        button_sync = (button_sync << 1) | pin;
        
        // Presume for the moment that we haven't detected the active-going edge of the button        
        edge_detected <= 0;       
        
        // If the debounce clock is about to expire, find out of the user-specfied pin is still active
        if (debounce_clock == 1) begin
            edge_detected <= (button_sync[1] == ACTIVE);
            debounce_clock <= 0;
        end
        
        // Otherwise, if the debounce clock is still counting down, decrement it
        else if (debounce_clock != 0) begin
            debounce_clock <= debounce_clock - 1;
        end  
        
        // If the pin is high and was previously low, start the debounce clock
        if (button_sync[2:1] == ACTIVE_EDGE) debounce_clock <= DEBOUNCE_PERIOD;
    end
    
    // The output wire always reflects the state of the 'edge_detected' register
    assign q = edge_detected;
    
endmodule
//======================================================================================================================
