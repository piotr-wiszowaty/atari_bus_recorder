//////////////////////////////////////////////////////////////////////////////////
//
// Wirtualny komponent mikrokontrolera pBlazeZH
//
// (C) 2009 Zbigniew Hajduk
// http://zh.prz-rzeszow.pl
// e-mail: zhajduk@prz-rzeszow.pl
//
// Ten kod Ÿród³owy mo¿e podlegaæ wolnej redystrybucji i/lub modyfikacjom 
// na ogólnych zasadach okreœlonych licencj¹ GNU General Public License.
//
// Autor wyra¿a nadziejê, ¿e kod wirtualnego komponentu bêdzie u¿yteczny
// jednak nie udziela ¯ADNEJ GWARANCJI dotycz¹cej jego sprawnoœci
// oraz przydatnoœci dla partykularnych zastosowañ.
//
//////////////////////////////////////////////////////////////////////////////////


module pBlazeZH(input [7:0] IN_PORT,
                input INTERRUPT,RESET,CLK,
                input [17:0] INSTRUCTION,
                output [7:0] OUT_PORT,PORT_ID,
                output reg READ_STROBE,WRITE_STROBE,INTERRUPT_ACK,
                output [9:0] ADDRESS);

reg [7:0] REGISTERS [0:15];
reg [7:0] SCRATCHPAD [0:63];
reg INT_ENABLE,CARRY,ZERO,PR_CARRY,PR_ZERO;
reg [9:0] PC=10'h3ff,pc_next;
wire [9:0] pcp1,top_of_stack;
reg [9:0] STACK [31:0];
reg [4:0] sp,sp_next;
reg jmp,ar,ac,az,cy,z,int_sync;
wire [9:0] aaa=INSTRUCTION[9:0];
wire [7:0] kk=INSTRUCTION[7:0];
wire [3:0] sX=INSTRUCTION[11:8];
wire [3:0] sY=INSTRUCTION[7:4];
wire [7:0] DO_SP,ALU_AND;
wire fetch=(INSTRUCTION[17:13]==5'b00011);
wire store=(INSTRUCTION[17:13]==5'b10111);
wire reti=(INSTRUCTION[17:13]==5'b11100);

wire [7:0] DO2,AI1,ALU_SR,ALU_SL; 
wire [7:0] AI2=(INSTRUCTION[12])?DO2:kk;
reg [7:0] AO,regs_in;
wire parity=^AO;
wire z0=~(|AO);
wire cin;
reg sr_in;
reg [8:0] ALU_ADD_SUB;
wire [5:0] SP_ADDR=AI2[5:0];
wire go=PC!=10'h3ff;
wire rd_strobe=INSTRUCTION[17:13]==5'b00010;
wire wr_strobe=INSTRUCTION[17:13]==5'b10110;
wire skip=(rd_strobe&~READ_STROBE)|(wr_strobe&~WRITE_STROBE);
wire int_req=INT_ENABLE&int_sync&~skip&~READ_STROBE&~WRITE_STROBE;

assign ADDRESS=pc_next;
assign PORT_ID=AI2;
assign OUT_PORT=AI1;
assign pcp1=(int_req|(skip&go))?PC:PC+1;
assign top_of_stack=STACK[sp];

always @(posedge CLK) //(1)
if(RESET) int_sync<=0; else
begin
 if(INT_ENABLE&~int_sync) int_sync<=INTERRUPT;
 if(INTERRUPT_ACK) int_sync<=0;
end

always @(posedge CLK) //(2)
 if(jmp) STACK[sp_next]<=pcp1;

always @(*) //(3)
 if(READ_STROBE) regs_in=IN_PORT;
 else
 if(fetch) regs_in=DO_SP;
 else regs_in=AO;

always @(posedge CLK) //(4)
 if(~int_req&~skip&(ar|READ_STROBE|fetch))REGISTERS[sX]<=regs_in;

always @(posedge CLK) //(5)
 if(store) SCRATCHPAD[SP_ADDR]<=AI1;

assign DO2=REGISTERS[sY]; //(6)
assign AI1=REGISTERS[sX];
assign DO_SP=SCRATCHPAD[SP_ADDR];

always @(*) //(7)
 casex ({INTERRUPT_ACK,CARRY,ZERO,INSTRUCTION[17:10]})
  11'b0xx_1100_00xx: begin pc_next=aaa; jmp=1; sp_next=sp+1; end //call
  11'b01x_1100_0110: begin pc_next=aaa; jmp=1; sp_next=sp+1; end //if CARRY
  11'b00x_1100_0111: begin pc_next=aaa; jmp=1; sp_next=sp+1; end //if NOT CARRY
  11'b0x1_1100_0100: begin pc_next=aaa; jmp=1; sp_next=sp+1; end //if ZERO
  11'b0x0_1100_0101: begin pc_next=aaa; jmp=1; sp_next=sp+1; end //if NOT ZERO
  11'b0xx_1101_00xx: begin pc_next=aaa; jmp=0; sp_next=sp; end //jump
  11'b01x_1101_0110: begin pc_next=aaa; jmp=0; sp_next=sp; end //if CARRY
  11'b00x_1101_0111: begin pc_next=aaa; jmp=0; sp_next=sp; end //if NOT CARRY
  11'b0x1_1101_0100: begin pc_next=aaa; jmp=0; sp_next=sp; end //if ZERO
  11'b0x0_1101_0101: begin pc_next=aaa; jmp=0; sp_next=sp; end //if NOT ZERO
  11'b0xx_1010_10xx: begin pc_next=top_of_stack; jmp=0; sp_next=sp-1; end //RETURN 
  11'b01x_1010_1110: begin pc_next=top_of_stack; jmp=0; sp_next=sp-1; end //RETURN if CARRY
  11'b00x_1010_1111: begin pc_next=top_of_stack; jmp=0; sp_next=sp-1; end //RETURN if NOT CARRY
  11'b0x1_1010_1100: begin pc_next=top_of_stack; jmp=0; sp_next=sp-1; end //RETURN if ZERO
  11'b0x0_1010_1101: begin pc_next=top_of_stack; jmp=0; sp_next=sp-1; end //RETURN if NOT ZERO
  11'b1xx_xxxx_xxxx: begin pc_next=18'h3ffff; jmp=1; sp_next=sp+1; end // interrupt event
  11'b0xx_1110_0000: begin pc_next=top_of_stack; jmp=0; sp_next=sp-1; end //RETURNI
  default: begin pc_next=pcp1; jmp=0; sp_next=sp; end 
 endcase

/**************************  ALU *****************************/
assign ALU_AND=AI1&AI2; //(8)
assign cin=INSTRUCTION[13]?CARRY:1'b0;
assign ALU_SR={sr_in,AI1[7:1]};
assign ALU_SL={AI1[6:0],sr_in};

always @(*)
 if(INSTRUCTION[14]) ALU_ADD_SUB=AI1-AI2-cin;
 else ALU_ADD_SUB=AI1+AI2+cin;

always @(*)
 case(INSTRUCTION[2:0])
  3'b110: sr_in=1'b0;
  3'b111: sr_in=1'b1;
  3'b100: sr_in=AI1[0];
  3'b010: sr_in=AI1[7];
  3'b000: sr_in=CARRY;
  default: sr_in=CARRY;
 endcase

always @(*)
 casex({INSTRUCTION[17:13],INSTRUCTION[3]})
  9'b00000x: {ar,ac,az,cy,z,AO}={5'b10000,AI2}; // LOAD
  9'b00101x: begin {ar,ac,az}={3'b111}; cy=1'b0; z=z0; AO=ALU_AND; end // AND
  9'b00110x: begin {ar,ac,az}={3'b111}; cy=1'b0; z=z0; AO=AI1|AI2; end // OR
  9'b00111x: begin {ar,ac,az}={3'b111}; cy=1'b0; z=z0; AO=AI1^AI2; end // XOR
  9'b01001x: begin {ar,ac,az}={3'b011}; cy=parity; z=z0; AO=ALU_AND; end // TEST
  9'b011xxx: begin {ar,ac,az}={3'b111}; {cy,AO}=ALU_ADD_SUB; z=z0; end // SUB, SUBCY
  9'b01010x: begin {ar,ac,az}={3'b011}; {cy,AO}=ALU_ADD_SUB; z=z0; end // COMPARE
  9'b100001: begin {ar,ac,az}={3'b111}; cy=AI1[0]; AO=ALU_SR; 
                   z=((INSTRUCTION[0])?1'b0:z0); end // SR0,SR1
  9'b100000: begin {ar,ac,az}={3'b111}; cy=AI1[7]; AO=ALU_SL;
                   z=((INSTRUCTION[0])?1'b0:z0); end // SL0,SR1
  default: begin {ar,ac,az}={3'b000}; cy=1'b0; z=1'b0; AO=8'd0; end
 endcase
/******************************************************************/

always @(posedge CLK) //(9)
 if(rd_strobe&~int_req&~READ_STROBE) READ_STROBE<=1'b1;
  else READ_STROBE<=1'b0;

always @(posedge CLK) //(10)
 if(wr_strobe&~int_req&~WRITE_STROBE) WRITE_STROBE<=1'b1;
  else WRITE_STROBE<=1'b0;

always @(posedge CLK) //(11)
begin
 if(RESET) begin
  PC<=10'h3ff; sp<=5'd0;  INT_ENABLE<=1'b0; INTERRUPT_ACK<=1'b0;
 end else
 begin
   if(INTERRUPT_ACK) INTERRUPT_ACK<=1'b0;
   if(~skip)
   begin
    PC<=pc_next; sp<=sp_next;
    if(ac&~int_req) CARRY<=cy;
    if(az&~int_req) ZERO<=z; 
   if(int_req)
   begin
    PR_CARRY<=CARRY; PR_ZERO<=ZERO;
    INT_ENABLE<=1'b0; INTERRUPT_ACK<=1'b1;    
   end else
   begin
    if(reti)
    begin
     CARRY<=PR_CARRY; ZERO<=PR_ZERO;
     if(INSTRUCTION[0]) INT_ENABLE<=1'b1; 
     else INT_ENABLE<=1'b0;
    end else
    if(INSTRUCTION[17:13]==5'b11110) //ENABLE, DISABLE INT
    begin
     if(INSTRUCTION[0]) INT_ENABLE<=1'b1;
     else INT_ENABLE<=1'b0;
    end
   end
  end 
  end   
end
endmodule

