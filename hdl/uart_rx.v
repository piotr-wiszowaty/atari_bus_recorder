//    Copyright (C) 2014  Piotr Wiszowaty
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//  
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.

`timescale 1ns / 1ps
module uart_rx(clock, rxd, data, write_enable, bit_length);

parameter BIT_LENGTH_WIDTH = 16;

parameter IDLE  = 4'd0;
parameter START = 4'd1;
parameter BIT0  = 4'd2;
parameter BIT1  = 4'd3;
parameter BIT2  = 4'd4;
parameter BIT3  = 4'd5;
parameter BIT4  = 4'd6;
parameter BIT5  = 4'd7;
parameter BIT6  = 4'd8;
parameter BIT7  = 4'd9;
parameter STOP  = 4'd10;

input clock;
input rxd;
output reg [7:0] data = 8'b00;
output reg write_enable = 1'b0;
input [BIT_LENGTH_WIDTH-1:0] bit_length;    // number of clock periods per bit minus 1

reg [1:0] rxd_rr = 2'b11;

reg [3:0] state = IDLE;
reg [BIT_LENGTH_WIDTH-1:0] bit_time = 0;
wire end_bit = bit_time == bit_length;
wire half_bit = bit_time == {1'b0, bit_length[BIT_LENGTH_WIDTH-1:1]};

always @(posedge clock) begin
    rxd_rr <= {rxd_rr[0], rxd};

    if (state == IDLE) begin
        if (~rxd_rr[1]) state <= START;
    end
    else begin
        if (end_bit) begin
            if (state == START) state <= BIT0;
            else if (state == BIT0) state <= BIT1;
            else if (state == BIT1) state <= BIT2;
            else if (state == BIT2) state <= BIT3;
            else if (state == BIT3) state <= BIT4;
            else if (state == BIT4) state <= BIT5;
            else if (state == BIT5) state <= BIT6;
            else if (state == BIT6) state <= BIT7;
            else if (state == BIT7) state <= STOP;
            else if (state == STOP)
                if (~rxd_rr[1]) state <= START;
                else state <= IDLE;
            else state <= IDLE;
        end
        else if (half_bit) begin
            data <= {rxd_rr[1], data[7:1]};
        end

        if (end_bit & (state == BIT7)) begin
            write_enable <= 1'b1;
        end
        else begin
            write_enable <= 1'b0;
        end

        if (end_bit) begin
            bit_time <= 0;
        end
        else begin
            bit_time <= bit_time + 1'b1;
        end
    end
end

endmodule
