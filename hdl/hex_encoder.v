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

module hex_encoder (
    input [3:0] digit,
    input dot,
    input off,
    output [7:0] segments);

assign segments[7] = off ? 1'b1 : ~dot;
assign segments[6:0] =
    off ? ~7'b0000000 :
    (digit == 4'h0) ? ~7'b0111111 :
    (digit == 4'h1) ? ~7'b0000110 :
    (digit == 4'h2) ? ~7'b1011011 :
    (digit == 4'h3) ? ~7'b1001111 :
    (digit == 4'h4) ? ~7'b1100110 :
    (digit == 4'h5) ? ~7'b1101101 :
    (digit == 4'h6) ? ~7'b1111101 :
    (digit == 4'h7) ? ~7'b0000111 :
    (digit == 4'h8) ? ~7'b1111111 :
    (digit == 4'h9) ? ~7'b1101111 :
    (digit == 4'hA) ? ~7'b1110111 :
    (digit == 4'hb) ? ~7'b1111100 :
    (digit == 4'hC) ? ~7'b0111001 :
    (digit == 4'hd) ? ~7'b1011110 :
    (digit == 4'hE) ? ~7'b1111001 :
                      ~7'b1110001;

endmodule
