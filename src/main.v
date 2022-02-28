`timescale 1ns / 1ps
`define SYSCLOCK_FREQ 100000000
`define COUNTER_WIDTH 16


//======================================================================================================================
// pos_edge_detector() - Detects highgoing edges of a pin (for instance, a button)
//
// Input:  clk = system clock
//         pin = the pin to look for a high-going edge on
//
// Output:  q = 1 if a high-going edge is detected, otherwise 0
//
// Notes: edge detection is fully debounced.  q only goes high if a specified pin is still high
//        10ms after the high-going edge was initially detected 
//======================================================================================================================
module pos_edge_detector(input clk, input pin, output q);
    
    parameter [31:0] DEBOUNCE_PERIOD = `SYSCLOCK_FREQ / 200;

    reg previous_pin_state = 0;
    reg [31:0] debounce_clock = 0;
    reg edge_detected = 0;    
    
    // We're going to check for edges on every clock cycle
    always @(posedge clk) begin
                
        edge_detected <= 0;       
        
        // If the debounce clock is about to expire, find out of the user-specicied pin is still high
        if (debounce_clock == 1) begin
            edge_detected <= pin;
            debounce_clock <= 0;
        end
        
        // Otherwise, the debounce clock is still counting down, decrement it
        else if (debounce_clock != 0) begin
            debounce_clock <= debounce_clock - 1;
        end  
        
        // If the pin is high and was previously low, start the debounce clock
        if (pin & ~previous_pin_state) debounce_clock <= DEBOUNCE_PERIOD;
        
        // The 'previous_pin_state" register gets the current state of the pin for 
        // use during the next clock cycle`
        previous_pin_state <= pin;
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
  
    // States that our FSM walks thru
    parameter s_IDLE         = 0;
    parameter s_WAIT_FOR_BCD = 1;
   
    // This has a '1' on every clock cycle for which a high-going button-edge is detected
    wire w_button_edge;

    // Variable that tracks how many times the button has been pressed
    reg [`COUNTER_WIDTH-1:0] r_counter = 0;
    
    // The current state of our FSM
    reg r_state = s_IDLE;

    // On any clock cycle that this is a '1', the BCD FSM starts
    reg r_start_bcd_engine = 0;
    
    // This is the output of the binary_to_bcd module, and contains our count expressed in BCD
    wire [15:0] w_bcd;
    
    // When the conversion to BCD is complete, the output of the BCD module gets stored here
    reg  [15:0] r_bcd;
    
    // A flag that contains a '1' whenever a BCD conversion is complete and 'w_bcd' holds valid data
    wire w_dv;
    
    // This detects fully debounced high-going edges from the button
    pos_edge_detector u1(clk, BTNU, w_button_edge);

    // A FSM that converts the binary value in 'r_counter' into BCD stored in 'w_bcd'
    binary_to_bcd#(.INPUT_WIDTH(16), .DECIMAL_DIGITS(4)) u2(clk, r_counter, r_start_bcd_engine, w_bcd, w_dv);
    
    // A block of 4 7-segment displays
    seven_seg u3(clk, r_bcd, SEG, AN); 

    always @(posedge clk) begin
      
        // By default, we aren't starting the BCD engine this clock cycle
        r_start_bcd_engine <= 0;
      
        // The FSM that stores our count in BCD into the r_bcd register
        case (r_state)

        // We're waiting for w_button_edge to go high           
        s_IDLE:
          begin 
            if (w_button_edge)  begin
              r_counter          <= r_counter + 1;
              r_start_bcd_engine <= 1;
              r_state            <= s_WAIT_FOR_BCD;
            end
          end

        //  We're waiting for the BCD conversion to complete         
        s_WAIT_FOR_BCD:
          begin
            if (w_dv) begin
              r_bcd   <= w_bcd;
              r_state <= s_IDLE;
            end
          end
                  
        endcase
        
        // The reset button resets the counter to 0
        if (!rst_n) begin
          r_counter <= 0;
          r_state   <= s_IDLE;
        end
        
    end 
                 
  
    //assign led = r_counter;
    assign led = r_bcd;
    
    // Light up the blue LED whenever our pushbutton is being pressed
    assign LED16_B = BTNU;
  
    
endmodule
//======================================================================================================================
