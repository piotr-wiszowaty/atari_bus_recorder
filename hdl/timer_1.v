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

module timer_1 (
	input clock,
	input start,
	output running);

parameter SIZE = 32;
parameter RESET_VALUE = -40000000;

reg [SIZE-1:0] counter = 0;

assign running = |counter;

always @(posedge clock) begin
	if (start)
		counter <= RESET_VALUE;
	else if (running)
		counter <= counter + 1'b1;
end
	
endmodule
	
