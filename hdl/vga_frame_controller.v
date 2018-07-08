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

module vga_frame_controller (
    input clock,
    output [3:0] red,
    output [3:0] green,
    output [3:0] blue,
    output hsync,
    output vsync,
    input [11:0] color1,
    input data,
    output data_clock_enable,
    input pattern);

// 640x480 @ 60 Hz, pixel clock 25.175 MHz
parameter H_ACTIVE = 640;
parameter H_FRONT_PORCH = 16 - 2;
parameter H_SYNC = 96;
parameter H_BACK_PORCH = 48 + 2;
parameter V_ACTIVE = 480;
parameter V_FRONT_PORCH = 10;
parameter V_SYNC = 2;
parameter V_BACK_PORCH = 33;

reg h_sync = 1'b1;
reg h_back = 1'b0;
reg h_active = 1'b0;
reg h_front = 1'b0;
reg v_sync = 1'b1;
reg v_back = 1'b0;
reg v_active = 1'b0;
reg v_front = 1'b0;
reg [6:0] h_sync_cntr = 7'b0;
reg [5:0] h_back_cntr = 6'b0;
reg [9:0] h_active_cntr = 10'b0;
reg [4:0] h_front_cntr = 5'b0;
reg [1:0] v_sync_cntr = 2'b0;
reg [5:0] v_back_cntr = 6'b0;
reg [8:0] v_active_cntr = 9'b0;
reg [3:0] v_front_cntr = 4'b0;

reg [9:0] h_vram_addr = 10'b0;
reg [8:0] v_vram_addr = 9'b0;

wire active;
reg h_active_t;
reg h_active_tt;
wire [3:0] red_q;
wire [3:0] green_q;
wire [3:0] blue_q;

wire h_end = h_front_cntr == H_FRONT_PORCH - 1;

assign red_q = pattern ? h_active_cntr[4:1] :
               data ? color1[3:0] :
               4'b0;

assign green_q = pattern ? v_active_cntr[4:1] :
                 data ? color1[7:4] :
                 4'b0;

assign blue_q = pattern ? {h_active_cntr[7:6], v_active_cntr[4:3]} :
                data ? color1[11:8] :
                4'b0;

assign active = v_active & h_active_tt;
assign red = active ? red_q : 4'b0;
assign green = active ? green_q : 4'b0;
assign blue = active ? blue_q : 4'b0;

assign hsync = ~h_sync;
assign vsync = ~v_sync;

assign data_clock_enable = h_active & v_active;

always @(posedge clock) begin
    case ({h_sync, h_back, h_active, h_front})
        4'b1000:
            if (h_sync_cntr == H_SYNC - 1)
                {h_sync, h_back, h_active, h_front} <= 4'b0100;
        4'b0100:
            if (h_back_cntr == H_BACK_PORCH - 1)
                {h_sync, h_back, h_active, h_front} <= 4'b0010;
        4'b0010:
            if (h_active_cntr == H_ACTIVE - 1)
                {h_sync, h_back, h_active, h_front} <= 4'b0001;
        4'b0001:
            if (h_front_cntr == H_FRONT_PORCH - 1)
                {h_sync, h_back, h_active, h_front} <= 4'b1000;
    endcase

    case ({v_sync, v_back, v_active, v_front})
        4'b1000:
            if (v_sync_cntr == V_SYNC - 1)
                {v_sync, v_back, v_active, v_front} <= 4'b0100;
        4'b0100:
            if (v_back_cntr == V_BACK_PORCH - 1)
                {v_sync, v_back, v_active, v_front} <= 4'b0010;
        4'b0010:
            if (v_active_cntr == V_ACTIVE - 1)
                {v_sync, v_back, v_active, v_front} <= 4'b0001;
        4'b0001:
            if (v_front_cntr == V_FRONT_PORCH - 1)
                {v_sync, v_back, v_active, v_front} <= 4'b1000;
    endcase

    h_back_cntr <= h_back ? h_back_cntr + 6'b1 : 6'b0;
    h_sync_cntr <= h_sync ? h_sync_cntr + 7'b1 : 7'b0;
    h_active_cntr <= h_active ? h_active_cntr + 10'b1 : 10'b0;
    h_front_cntr <= h_front ? h_front_cntr + 5'b1 : 5'b0;

    v_back_cntr <= h_end ? (v_back ? v_back_cntr + 6'b1 : 6'b0) : v_back_cntr;
    v_sync_cntr <= h_end ? (v_sync ? v_sync_cntr + 2'b1 : 2'b0) : v_sync_cntr;
    v_active_cntr <= h_end ? (v_active ? v_active_cntr + 9'b1 : 9'b0) : v_active_cntr;
    v_front_cntr <= h_end ? (v_front ? v_front_cntr + 4'b1 : 4'b0) : v_front_cntr;

    if (h_end)
        v_vram_addr <= v_vram_addr + 9'b1;
    else if (v_sync)
        v_vram_addr <= 9'b0;

    h_active_t <= h_active;
    h_active_tt <= h_active_t;
end

always @(negedge clock) begin
    if (h_active)
        h_vram_addr <= h_vram_addr + 10'b1;
    else if (h_sync)
        h_vram_addr <= 10'b0;
end

endmodule
