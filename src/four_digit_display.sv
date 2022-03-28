`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/28/2022 03:37:05 PM
// Design Name: 
// Module Name: four_digit_display
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////




`timescale 1ns / 1ps


//======================================================================================================================
// clock_divider() - Divides the input clock down by 100,000
//======================================================================================================================
module seven_seg_clock_divider(input i_clk, output o_clk);
    reg [31:0] r_counter = 0;
    reg r_clk = 0;

    always @(posedge i_clk) begin
        if (r_counter == 99999)
          begin
            r_clk <= ~r_clk;
            r_counter <= 0;
          end
        else
          begin
            r_counter <= r_counter + 1;
          end
    end
    
    assign o_clk = r_clk;
endmodule    
//======================================================================================================================
    

//======================================================================================================================
// seven_seg() - Drives the right-most 4 7-segment displays
//======================================================================================================================
module seven_seg
    (
        input         i_clk,
        input [15:0]  i_bcd,
        output [7:0]  o_cathode,
        output [7:0]  o_anode
    );

    reg [7:0] r_cathode;
    reg [7:0] r_anode;
    reg [0:1] r_digit = 0;
    reg [3:0] r_bcd;

    // w_slow_clk is a divided down clock.  At a 100 MHz system clock, w_slow_clock is 1000 Hz
    wire w_slow_clk;
    seven_seg_clock_divider u0(i_clk, w_slow_clk);

    always @(posedge w_slow_clk) begin
    
        case (r_digit)
            0:
              begin
                  r_anode <= 8'b11111110;
                  r_bcd = i_bcd[3:0];
                  r_digit <= 1;              
              end
              
              
            1:
              begin
                  r_anode <= 8'b11111101;
                  r_bcd = i_bcd[7:4];
                  r_digit <= 2;              
              end
              
            2:
              begin
                  r_anode <= 8'b11111011;
                  r_bcd = i_bcd[11:8];              
                  r_digit <= 3;
              end
            
            3:
              begin
                  r_anode <= 8'b11110111;
                  r_bcd = i_bcd[15:12];              
                  r_digit <= 0;
              end
          endcase

    end


    always @(r_bcd)
    begin
        case (r_bcd)
            0       : r_cathode = 8'b00111111;
            1       : r_cathode = 8'b00000110;
            2       : r_cathode = 8'b01011011;
            3       : r_cathode = 8'b01001111;
            4       : r_cathode = 8'b01100110;
            5       : r_cathode = 8'b01101101;
            6       : r_cathode = 8'b01111101;
            7       : r_cathode = 8'b00000111;
            8       : r_cathode = 8'b01111111;
            9       : r_cathode = 8'b01100111;
            default : r_cathode = 8'b00000000; 
        endcase
    end

    assign o_cathode = ~r_cathode;
    assign o_anode = r_anode;

endmodule
//======================================================================================================================


//======================================================================================================================
// four_digit_display - Drives a 4-digit block of 7-segment displays
//======================================================================================================================
module four_digit_display
(
    input i_clk,
    input  [15:0] i_value,
    output [7:0] o_cathode,
    output [7:0] o_anode 
);

    // States that our FSM walks thru
    parameter s_IDLE         = 0;
    parameter s_WAIT_FOR_BCD = 1;

    // The current state of our FSM
    reg r_state = s_IDLE;

    // On any clock cycle that this is a '1', the BCD FSM starts
    reg r_start_bcd_engine = 0;

    // This will be '1' when r_bcd contains the result of the most recent conversion
    reg r_dv;
    
    // When the conversion to BCD is complete, the output of the BCD module gets stored here
    reg  [15:0] r_bcd;
    
    // This is the value we are currently displaying
    reg [15:0] r_current_value = 59999;
    
    // A FSM that converts the binary value in 'i_value' into BCD stored in 'r_bcd'
    binary_to_bcd#(.INPUT_WIDTH(16), .DECIMAL_DIGITS(4)) u1(i_clk, i_value, r_start_bcd_engine, r_bcd, r_dv);

    // A block of four 7-segment displays
    seven_seg u2(i_clk, r_bcd, o_cathode, o_anode); 

    always @(posedge i_clk) begin
      
        // By default, we aren't starting the BCD engine this clock cycle
        r_start_bcd_engine <= 0;
    
        // The FSM that stores our count in BCD into the r_bcd register
        case (r_state)

        // We're waiting for i_value to change           
        s_IDLE:
          begin 
            if (i_value != r_current_value)  begin
              r_current_value    <= i_value;
              r_start_bcd_engine <= 1;
              r_state            <= s_WAIT_FOR_BCD;
            end
          end

        //  We're waiting for the BCD conversion to complete         
        s_WAIT_FOR_BCD:
          begin
            if (r_dv) begin
              r_state <= s_IDLE;
            end
          end
                  
        endcase
    end



endmodule
//======================================================================================================================

