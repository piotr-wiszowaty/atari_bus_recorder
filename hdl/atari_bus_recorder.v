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

module atari_bus_recorder (
	input clock_50,
	input [2:0] button,
	input [9:0] switch,
	output reg [9:0] led = 10'b0,
	input rxd,
	output txd,
	output cts,
	input rts,
	output [7:0] hex0_d,
	output [7:0] hex1_d,
	output [7:0] hex2_d,
	output [7:0] hex3_d,
	output [3:0] vga_r,
	output [3:0] vga_g,
	output [3:0] vga_b,
	output vga_hs,
	output vga_vs,
	input [31:0] channel,
    output reg gpio0_d31 = 1'b0);

// mpu I/O ports
parameter LED_L     = 0;
parameter LED_H     = 1;
parameter T_CONTROL = 2;
parameter T_STATUS  = 2;
parameter U_STATUS  = 3;
parameter U_CONTROL = 3;
parameter U_DATA    = 4;
parameter SWITCH_L  = 6;
parameter SWITCH_H  = 7;
parameter HEX0_D    = 8;
parameter HEX1_D    = 9;
parameter HEX2_D    = 10;
parameter HEX3_D    = 11;
parameter V_STATUS  = 12;
parameter VRAM_A_LO = 13;
parameter VRAM_A_HI = 14;
parameter VRAM_DATA = 15;
parameter VRAM_DATI = 16;
parameter COLR1_R   = 17;
parameter COLR1_G   = 18;
parameter COLR1_B   = 19;
parameter S_STATUS  = 20;
parameter S_CONTROL = 20;
parameter BUTTON    = 20;
parameter S_NEGEDGE = 21;
parameter S_POSEDGE = 22;
parameter SAMPLE_LL = 23;
parameter SAMPLE_LH = 24;
parameter SAMPLE_HL = 25;
parameter SAMPLE_HH = 26;
parameter SAMPLEA_L = 27;
parameter SAMPLEA_H = 28;
parameter TEXT_ADDR = 29;
parameter TEXT_DATA = 30;

wire system_clock;
wire vga_clock;

reg mpu_reset = 1'b1;
wire [7:0] mpu_port_id;
wire [7:0] mpu_in_port;
wire [7:0] mpu_out_port;
wire mpu_read_strobe;
wire mpu_write_strobe;
wire mpu_interrupt_ack;
wire [9:0] mpu_address;
wire [17:0] mpu_instruction;

wire t1_running;
wire t10_running;
wire t100_running;
wire t1000_running;

reg uart_fifo_reset = 1'b0;
wire [7:0] uart_rx_data;
wire uart_write_enable;
wire uart_read_enable;
wire uart_data_ready;
wire uart_tx_fifo_full;

reg [7:0] hex0_r = 8'h00;
reg [7:0] hex1_r = 8'h00;
reg [7:0] hex2_r = 8'h00;
reg [7:0] hex3_r = 8'h00;
wire hex_select_ram_address = switch[3];

reg [3:0] color1_red = 4'b1111;
reg [3:0] color1_green = 4'b1111;
reg [3:0] color1_blue = 4'b1111;
reg [1:0] vga_hsync_r = 2'b11;
reg [1:0] vga_vsync_r = 2'b11;
wire vram_q;
wire vram_q_clock_enable;
reg [11:0] vram_write_address = 12'b0;

wire sampler_negedge_empty;
wire sampler_negedge_full;
wire sampler_posedge_empty;
wire sampler_posedge_full;
reg sampler_clear = 1'b1;
wire [31:0] sampler_out;

reg [15:0] sample_ram_address;
wire [31:0] sample_ram_q;

reg [7:0] text_address;
wire [7:0] text_data;

assign mpu_in_port =
	(mpu_port_id == LED_L) ? led[7:0] :
	(mpu_port_id == LED_H) ? {gpio0_d31, 5'b0, led[9:8]} :
	(mpu_port_id == T_STATUS) ? {4'b0, t1000_running, t100_running, t10_running, t1_running} :
	(mpu_port_id == U_STATUS) ? {6'b0, uart_tx_fifo_full, uart_data_ready} :
	(mpu_port_id == U_DATA) ? uart_rx_data[7:0] :
	(mpu_port_id == SWITCH_L) ? switch[7:0] :
	(mpu_port_id == SWITCH_H) ? {6'b0, switch[9:8]} :
	(mpu_port_id == HEX0_D) ? hex0_r :
	(mpu_port_id == HEX1_D) ? hex1_r :
	(mpu_port_id == HEX2_D) ? hex2_r :
	(mpu_port_id == HEX3_D) ? hex3_r :
	(mpu_port_id == V_STATUS) ? {6'b0, vga_hsync_r[1], vga_vsync_r[1]} :
	(mpu_port_id == VRAM_A_LO) ? vram_write_address[7:0] :
	(mpu_port_id == VRAM_A_HI) ? {4'b0, vram_write_address[11:8]} :
	(mpu_port_id == COLR1_R) ? {4'b0, color1_red} :
	(mpu_port_id == COLR1_G) ? {4'b0, color1_green} :
	(mpu_port_id == COLR1_B) ? {4'b0, color1_blue} :
	(mpu_port_id == S_STATUS) ? {1'b0, button, 1'b0, channel[0], sampler_negedge_full | sampler_posedge_full, sampler_posedge_empty | sampler_negedge_empty} :
	(mpu_port_id == SAMPLE_LL) ? sample_ram_q[7:0] :
	(mpu_port_id == SAMPLE_LH) ? sample_ram_q[15:8] :
	(mpu_port_id == SAMPLE_HL) ? sample_ram_q[23:16] :
	(mpu_port_id == SAMPLE_HH) ? sample_ram_q[31:24] :
    (mpu_port_id == SAMPLEA_L) ? sample_ram_address[7:0] :
    (mpu_port_id == SAMPLEA_H) ? sample_ram_address[15:8] :
	(mpu_port_id == TEXT_DATA) ? text_data :
	8'hff;

always @(posedge system_clock) begin
	mpu_reset <= ~button[0];

	if (mpu_write_strobe)
		if (mpu_port_id == LED_L)
			led[7:0] <= mpu_out_port;
		else if (mpu_port_id == LED_H)
			{gpio0_d31, led[9:8]} <= {mpu_out_port[7], mpu_out_port[1:0]};
		else if (mpu_port_id == U_CONTROL)
			uart_fifo_reset <= mpu_out_port[0];
		else if (mpu_port_id == HEX0_D)
			hex0_r <= mpu_out_port;
		else if (mpu_port_id == HEX1_D)
			hex1_r <= mpu_out_port;
		else if (mpu_port_id == HEX2_D)
			hex2_r <= mpu_out_port;
		else if (mpu_port_id == HEX3_D)
			hex3_r <= mpu_out_port;
		else if (mpu_port_id == VRAM_A_LO)
			vram_write_address[7:0] <= mpu_out_port;
		else if (mpu_port_id == VRAM_A_HI)
			vram_write_address[11:8] <= mpu_out_port[3:0];
		else if (mpu_port_id == VRAM_DATI)
			vram_write_address <= vram_write_address + 12'b1;
		else if (mpu_port_id == COLR1_R)
			color1_red <= mpu_out_port[3:0];
		else if (mpu_port_id == COLR1_G)
			color1_green <= mpu_out_port[3:0];
		else if (mpu_port_id == COLR1_B)
			color1_blue <= mpu_out_port[3:0];
		else if (mpu_port_id == S_CONTROL)
			sampler_clear <= mpu_out_port[0];
		else if (mpu_port_id == SAMPLE_LL)
			sample_ram_address <= sample_ram_address + 16'b1;
		else if (mpu_port_id == SAMPLEA_L)
			sample_ram_address[7:0] <= mpu_out_port;
		else if (mpu_port_id == SAMPLEA_H)
			sample_ram_address[15:8] <= mpu_out_port;
		else if (mpu_port_id == TEXT_ADDR)
			text_address <= mpu_out_port;

	vga_hsync_r <= {vga_hsync_r[0], vga_hs};
	vga_vsync_r <= {vga_vsync_r[0], vga_vs};
end

clock_generator clk_gen (
	.inclk0(clock_50),
	.c0(system_clock),
	.c1(vga_clock));

timer_1 #(.RESET_VALUE(-40000)) t_1ms (
	.clock(system_clock),
	.start((mpu_port_id == T_CONTROL) & mpu_write_strobe & mpu_out_port[0]),
	.running(t1_running));

timer_1 #(.RESET_VALUE(-400000)) t_10ms (
	.clock(system_clock),
	.start((mpu_port_id == T_CONTROL) & mpu_write_strobe & mpu_out_port[1]),
	.running(t10_running));

timer_1 #(.RESET_VALUE(-4000000)) t_100ms (
	.clock(system_clock),
	.start((mpu_port_id == T_CONTROL) & mpu_write_strobe & mpu_out_port[2]),
	.running(t100_running));

timer_1 #(.RESET_VALUE(-40000000)) t_1000ms (
	.clock(system_clock),
	.start((mpu_port_id == T_CONTROL) & mpu_write_strobe & mpu_out_port[3]),
	.running(t1000_running));

uart uart_0 (
	.clock(system_clock),
	.rxd(rxd),
	.txd(txd),
	.cts(rts),
	.rts(cts),
	.tx_data(mpu_out_port),
	.rx_data(uart_rx_data),
	.read_enable(mpu_read_strobe & (mpu_port_id == U_DATA)),
	.write_enable(mpu_write_strobe & (mpu_port_id == U_DATA)),
	.rx_data_ready(uart_data_ready),
	.tx_fifo_full(uart_tx_fifo_full),
	.reset(uart_fifo_reset));

hex_encoder hex_encoder_0 (
	.digit(hex_select_ram_address ? sample_ram_address[3:0] : hex0_r[3:0]),
	.dot(hex_select_ram_address ? 1'b0 : hex0_r[4]),
	.off(hex_select_ram_address ? 1'b0 : hex0_r[5]),
	.segments(hex0_d));

hex_encoder hex_encoder_1 (
	.digit(hex_select_ram_address ? sample_ram_address[7:4] : hex1_r[3:0]),
	.dot(hex_select_ram_address ? 1'b0 : hex1_r[4]),
	.off(hex_select_ram_address ? 1'b0 : hex1_r[5]),
	.segments(hex1_d));

hex_encoder hex_encoder_2 (
	.digit(hex_select_ram_address ? sample_ram_address[11:8] : hex2_r[3:0]),
	.dot(hex_select_ram_address ? 1'b0 : hex2_r[4]),
	.off(hex_select_ram_address ? 1'b0 : hex2_r[5]),
	.segments(hex2_d));

hex_encoder hex_encoder_3 (
	.digit(hex_select_ram_address ? sample_ram_address[15:12] : hex3_r[3:0]),
	.dot(hex_select_ram_address ? 1'b0 : hex3_r[4]),
	.off(hex_select_ram_address ? 1'b0 : hex3_r[5]),
	.segments(hex3_d));

vga_frame_controller vga_frame_ctl (
	.clock(vga_clock),
	.red(vga_r),
	.green(vga_g),
	.blue(vga_b),
	.hsync(vga_hs),
	.vsync(vga_vs),
	.color1({color1_blue, color1_green, color1_red}),
	.data(vram_q),
	.data_clock_enable(vram_q_clock_enable),
	.pattern(switch[4]));

vga_data_controller vga_data_ctl (
	.system_clock(system_clock),
	.write_enable(mpu_write_strobe & ((mpu_port_id == VRAM_DATA) || (mpu_port_id == VRAM_DATI))),
	.write_address(vram_write_address),
	.data(mpu_out_port),
	.vga_clock(vga_clock),
	.q(vram_q),
	.q_clock_enable(vram_q_clock_enable),
	.reset(~vga_vs));

sampler sampler_instance (
	.system_clock(system_clock),
	.channel(channel[31:0]),
	.out(sampler_out),
	.negedge_read_enable(mpu_read_strobe & (mpu_port_id == S_NEGEDGE)),
	.posedge_read_enable(mpu_read_strobe & (mpu_port_id == S_POSEDGE)),
	.posedge_empty(sampler_posedge_empty),
	.posedge_full(sampler_posedge_full),
	.negedge_empty(sampler_negedge_empty),
	.negedge_full(sampler_negedge_full),
	.clear(sampler_clear),
	.s4_mask(switch[0]),
	.s5_mask(switch[1]),
	.cctl_mask(switch[2]));

sample_ram sample_ram_instance (
	.address(sample_ram_address),
	.clock(system_clock),
	.data(sampler_out),
	.wren(mpu_write_strobe & (mpu_port_id == SAMPLE_LL)),
	.q(sample_ram_q));

text_rom text (
	.address(text_address),
	.clock(system_clock),
	.q(text_data));

pBlazeZH mpu (
	.RESET(mpu_reset),
	.CLK(system_clock),
	.INTERRUPT(1'b0),
	.PORT_ID(mpu_port_id),
	.IN_PORT(mpu_in_port),
	.OUT_PORT(mpu_out_port),
	.READ_STROBE(mpu_read_strobe),
	.WRITE_STROBE(mpu_write_strobe),
	.INTERRUPT_ACK(mpu_interrupt_ack),
	.ADDRESS(mpu_address),
	.INSTRUCTION(mpu_instruction));

firmware mpu_firmware (
	.address(mpu_address),
	.q(mpu_instruction),
	.clock(system_clock));

endmodule

