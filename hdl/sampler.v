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

module sampler (
	input system_clock,
	input [31:0] channel,
	output [31:0] out,
	input negedge_read_enable,
	input posedge_read_enable,
	output posedge_empty,
	output posedge_full,
	output negedge_empty,
	output negedge_full,
	input clear,
	input s4_mask,
	input s5_mask,
	input cctl_mask);

//wire vcc = channel[0];
wire fi2 = channel[1];
//wire s4_n = channel[2];
//wire s5_n = channel[3];
//wire cctl_n = channel[4];
//wire rw = channel[5];
//wire [7:0] data = channel[13:6];
//wire [12:0] addr = channel[26:14];

wire write_clock = ~fi2;

wire [31:0] posedge_fifo_q;
wire [31:0] negedge_fifo_q;
reg select = 1'b0;	// 0: posedge, 1:negedge
reg [31:0] channel_latch;
wire s4_n_latch = channel_latch[2];
wire s5_n_latch = channel_latch[3];
wire cctl_n_latch = channel_latch[4];
wire write_enable = ~((s4_n_latch|s4_mask) & (s5_n_latch|s5_mask) & (cctl_n_latch|cctl_mask));

assign out = select ? negedge_fifo_q : posedge_fifo_q;

always @(posedge fi2) begin
	channel_latch <= channel;
end

always @(posedge system_clock) begin
	if (posedge_read_enable | negedge_read_enable)
		select <= negedge_read_enable;
end

sample_fifo negedge_fifo (
	.aclr(clear),
	.data(channel),
	.rdclk(system_clock),
	.rdreq(negedge_read_enable),
	.wrclk(write_clock),
	.wrreq(write_enable),
	.q(negedge_fifo_q),
	.rdempty(negedge_empty),
	.rdfull(negedge_full));

sample_fifo posedge_fifo (
	.aclr(clear),
	.data(channel_latch),
	.rdclk(system_clock),
	.rdreq(posedge_read_enable),
	.wrclk(write_clock),
	.wrreq(write_enable),
	.q(posedge_fifo_q),
	.rdempty(posedge_empty),
	.rdfull(posedge_full));

endmodule
