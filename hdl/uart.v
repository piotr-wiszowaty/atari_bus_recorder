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

module uart (
	input clock,
	input rxd,
	output txd,
	input cts,
	output rts,
	input [7:0] tx_data,
	output [7:0] rx_data,
	input read_enable,
	input write_enable,
	output rx_data_ready,
	output tx_fifo_full,
	input reset);

parameter BIT_LENGTH = 2083;    // 19200 baud

wire [7:0] rx_fifo_in;
wire [7:0] tx_fifo_out;
wire rx_empty;
wire rx_full;
wire rx_wrreq;
wire tx_rdreq;
wire tx_empty;

assign rts = rx_full;
assign rx_data_ready = ~rx_empty;

uart_fifo rx_fifo (
	.clock(clock),
	.data(rx_fifo_in),
	.rdreq(read_enable),
	.sclr(reset),
	.wrreq(rx_wrreq),
	.q(rx_data),
	.empty(rx_empty),
	.full(rx_full));

uart_rx rx (
	.clock(clock),
	.rxd(rxd),
	.data(rx_fifo_in),
	.write_enable(rx_wrreq),
	.bit_length(BIT_LENGTH - 1));

uart_fifo tx_fifo (
	.clock(clock),
	.data(tx_data),
	.rdreq(tx_rdreq),
	.sclr(reset),
	.wrreq(write_enable),
	.q(tx_fifo_out),
	.empty(tx_empty),
	.full(tx_fifo_full));

uart_tx tx (
	.clock(clock),
	.txd(txd),
	.data(tx_fifo_out),
	.data_ready(~tx_empty & ~cts),
	.read_enable(tx_rdreq),
	.bit_length(BIT_LENGTH - 1));

endmodule
