`timescale 1ns / 1ps


//======================================================================================================================
// clock_divider() - Divides the input clock down by 100,000
//======================================================================================================================
module clock_divider(input i_clk, output o_clk);
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
    clock_divider u0(i_clk, w_slow_clk);

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
