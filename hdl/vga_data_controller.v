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

module vga_data_controller (
    input system_clock,
    input write_enable,
    input [11:0] write_address,
    input [7:0] data,
    input vga_clock,
    output q,
    input q_clock_enable,
    input reset);

reg [9:0] h_counter = 10'b0;
reg [8:0] v_counter = 9'b0;
wire h_end = h_counter == 639;
wire [11:0] vram_read_address = {1'b0, v_counter[8:4], 6'b0} + {3'b0, v_counter[8:4], 4'b0} + {5'b0, h_counter[9:3]};
reg [2:0] h_counter_t;
reg [2:0] h_counter_tt;

wire [7:0] vram_q;
wire [11:0] font_address;
wire [7:0] font_q;

assign font_address = {vram_q, v_counter[3:0]};

mux_8to1 mux (
    .data0(font_q[7]),
    .data1(font_q[6]),
    .data2(font_q[5]),
    .data3(font_q[4]),
    .data4(font_q[3]),
    .data5(font_q[2]),
    .data6(font_q[1]),
    .data7(font_q[0]),
    .sel(h_counter_tt),
    .result(q));

always @(posedge vga_clock) begin
    if (q_clock_enable) begin
        if (h_end) begin
            h_counter <= 10'b0;
            v_counter <= v_counter + 9'b1;
        end
        else begin
            h_counter <= h_counter + 10'b1;
        end
    end
    else if (reset) begin
        h_counter <= 10'b0;
        v_counter <= 9'b0;
    end

    h_counter_t <= h_counter[2:0];
    h_counter_tt <= h_counter_t;
end

video_ram vram (
    .wrclock(system_clock),
    .wraddress(write_address),
    .wren(write_enable),
    .data(data),
    .rdclock(vga_clock),
    .rdaddress(vram_read_address),
    .q(vram_q));

font_8x16 font (
    .address(font_address),
    .clock(vga_clock),
    .q(font_q));

endmodule
