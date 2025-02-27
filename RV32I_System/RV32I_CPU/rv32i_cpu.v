//
//  Author: Prof. Taeweon Suh
//          Computer Science & Engineering
//          Korea University
//  Date: July 14, 2020
//  Description: Skeleton design of RV32I Single-cycle CPU
//

`timescale 1ns/1ns
`define simdelay 1
 
// CPU main module
//// Input 
// Instruction, data from Mem

//// Output
// PC(program counter)
// Memwrite control signal
// Mem address and data to write to MEM 
module rv32i_cpu (
		      input         clk, reset,
            output [31:0] pc,		  		// program counter for instruction fetch
            input  [31:0] inst, 			// incoming instruction
            output        Memwrite, 	// 'memory write' control signal
            output [31:0] Memaddr,  	// memory address 
            output [31:0] MemWdata, 	// data to write to memory
            input  [31:0] MemRdata); 	// data read from memory

  // Wires for some instructions 
  wire        auipc, lui;
  // Control signals for ALU
  wire        alusrc, regwrite;
  wire [4:0]  alucontrol;
  // Control signals for Memory Access
  wire        memtoreg, memwrite;
  // Control signals for Branch instructions(modify PC)
  wire        branch, jal, jalr;
  // Assign wire to output signal
  assign Memwrite = memwrite ;

  // Instantiate Controller
  controller i_controller(
      .opcode		(inst[6:0]), 
		.funct7		(inst[31:25]), 
		.funct3		(inst[14:12]), 
		.auipc		(auipc),
		.lui			(lui),
		.memtoreg	(memtoreg),
		.memwrite	(memwrite),
		.branch		(branch),
		.alusrc		(alusrc),
		.regwrite	(regwrite),
		.jal			(jal),
		.jalr			(jalr),
		.alucontrol	(alucontrol));

  // Instantiate Datapath
  datapath i_datapath(
		.clk				(clk),
		.reset			(reset),
		.auipc			(auipc),
		.lui				(lui),
		.memtoreg		(memtoreg),
		.memwrite		(memwrite),
		.branch			(branch),
		.alusrc			(alusrc),
		.regwrite		(regwrite),
		.jal				(jal),
		.jalr				(jalr),
		.alucontrol		(alucontrol),
		.pc				(pc),
		.inst				(inst),
		.aluout			(Memaddr), 
		.MemWdata		(MemWdata),
		.MemRdata		(MemRdata));

endmodule


//
// Instruction Decoder 
// to generate control signals for datapath
//
module controller(input  [6:0] opcode,
                  input  [6:0] funct7,
                  input  [2:0] funct3,
                  output       auipc,
                  output       lui,
                  output       alusrc,
                  output [4:0] alucontrol,
                  output       branch,
                  output       jal,
                  output       jalr,
                  output       memtoreg,
                  output       memwrite,
                  output       regwrite);

	maindec i_maindec(
		.opcode		(opcode),
		.auipc		(auipc),
		.lui			(lui),
		.memtoreg	(memtoreg),
		.memwrite	(memwrite),
		.branch		(branch),
		.alusrc		(alusrc),
		.regwrite	(regwrite),
		.jal			(jal),
		.jalr			(jalr));

	aludec i_aludec( 
		.opcode     (opcode),
		.funct7     (funct7),
		.funct3     (funct3),
		.alucontrol (alucontrol));


endmodule


//
// RV32I Opcode map = Inst[6:0]
//
`define OP_R			  7'b0110011
`define OP_I_ARITH	7'b0010011
`define OP_I_LOAD  	7'b0000011
`define OP_I_JALR  	7'b1100111
`define OP_S			  7'b0100011
`define OP_B			  7'b1100011
`define OP_U_LUI		7'b0110111
`define OP_J_JAL		7'b1101111
`define OP_U_AUIPC  7'b0010111
`define OP_J_JALR   7'b1100111

//
// Main decoder generates all control signals except alucontrol 
//
//
module maindec(input  [6:0] opcode,
               output       auipc,
               output       lui,
               output       regwrite,
               output       alusrc,
               output       memtoreg, memwrite,
               output       branch, 
               output       jal,
               output       jalr);

  // Control signals
  reg [8:0] controls;
  assign {auipc,      // 1
          lui,        // 2
          regwrite,   // 3
          alusrc,     // 4
			    memtoreg,   // 5
          memwrite,   // 6
          branch,     // 7
          jal,        // 8
			    jalr        // 9
          } = controls;

  // Set type of instructions by opcode 
  always @(*)
  begin
    case(opcode)
      // R type: regwrite
      `OP_R: 			controls <= #`simdelay 9'b0010_0000_0; // R-type
      // I type A: regwrite / alusrc
      `OP_I_ARITH: 	controls <= #`simdelay 9'b0011_0000_0; // I-type Arithmetic
      // I type Load: regwrite / alusrc / mem to reg
      `OP_I_LOAD: 	controls <= #`simdelay 9'b0011_1000_0; // I-type Load
      // S type: alusrc / memwrite
      `OP_S: 			controls <= #`simdelay 9'b0001_0100_0; // S-type Store
      // B type: branch
      `OP_B: 			controls <= #`simdelay 9'b0000_0010_0; // B-type Branch
      // LUI: LUI, regwrite, alusrc
      `OP_U_LUI: 		controls <= #`simdelay 9'b0111_0000_0; // LUI
      // JAL: regwrite, alusrc, jal
      `OP_J_JAL: 		controls <= #`simdelay 9'b0011_0001_0; // JAL
      // JALR: regwrite, alusrc, jalr
      `OP_J_JALR:   controls <= #`simdelay 9'b0011_0000_1;  //JALR
      // AUIPC: auipc, regwrite, alusrc
      `OP_U_AUIPC:  controls <= #`simdelay 9'b1011_0000_0;  //AUIPC      
      // Default: 0
      default:    	controls <= #`simdelay 9'b0000_0000_0; // ???
    endcase
  end

endmodule

//
// ALU decoder generates ALU control signal (alucontrol)
//
module aludec(input      [6:0] opcode,
              input      [6:0] funct7,
              input      [2:0] funct3,
              output reg [4:0] alucontrol);

  always @(*)

    case(opcode)

      `OP_R:   		// R-type
		begin
			case({funct7,funct3})
			 10'b0000000_000: alucontrol <= #`simdelay 5'b00000; // addition (add)
			 10'b0100000_000: alucontrol <= #`simdelay 5'b10000; // subtraction (sub)
			 10'b0000000_111: alucontrol <= #`simdelay 5'b00001; // and (and)
			 10'b0000000_110: alucontrol <= #`simdelay 5'b00010; // or (or)

       //////Lab #3
       //Another Instructions
       10'b0000000_001: alucontrol <= #`simdelay 5'b00100; // SLL
       10'b0000000_010: alucontrol <= #`simdelay 5'b10111; // SLT
       10'b0000000_011: alucontrol <= #`simdelay 5'b11000; // SLTU
       10'b0000000_100: alucontrol <= #`simdelay 5'b00011; // XOR
       10'b0000000_101: alucontrol <= #`simdelay 5'b00101; // SRL
       10'b0100000_101: alucontrol <= #`simdelay 5'b00110; // SRA

          default:         alucontrol <= #`simdelay 5'bxxxxx; // ???
        endcase
		end

      `OP_I_ARITH:   // I-type Arithmetic
		begin
			case({funct3})
			 3'b000:  alucontrol <= #`simdelay 5'b00000; // addition (addi)
			 3'b110:  alucontrol <= #`simdelay 5'b00010; // or (ori)
			 3'b111:  alucontrol <= #`simdelay 5'b00001; // and (andi)

       //////Lab #3
       //Another Instructions
       3'b010:  alucontrol <= #`simdelay 5'b10111;  // SLTI(sub) 
       3'b011:  alucontrol <= #`simdelay 5'b11000;  // SLTIU(sub)
       3'b100:  alucontrol <= #`simdelay 5'b00011;  // XORI(xor)
          default: alucontrol <= #`simdelay 5'bxxxxx; // ???
        endcase
		end

      `OP_I_LOAD: 	// I-type Load (LW, LH, LB...)
      	alucontrol <= #`simdelay 5'b00000;  // addition 

      `OP_B:   		// B-type Branch (BEQ, BNE, ...)
      	alucontrol <= #`simdelay 5'b10000;  // subtraction 

      `OP_S:   		// S-type Store (SW, SH, SB)
      	alucontrol <= #`simdelay 5'b00000;  // addition 

      `OP_U_LUI: 		// U-type (LUI)
      	alucontrol <= #`simdelay 5'b00000;  // addition

      `OP_U_AUIPC:  // U-type (AUIPC)
        alucontrol <= #`simdelay 5'b00000;  // addition

      `OP_J_JAL:
        alucontrol <= #`simdelay 5'b00000;  // addition

      `OP_J_JALR:
        alucontrol <=#`simdelay 5'b00000;

      default: 
      	alucontrol <= #`simdelay 5'b00000;  // 

    endcase
    
endmodule


//
// CPU datapath
//
module datapath(input         clk, reset,
                input  [31:0] inst,
                input         auipc,
                input         lui,
                input         regwrite,
                input         memtoreg,
                input         memwrite,
                input         alusrc, 
                input  [4:0]  alucontrol,
                input         branch,
                input         jal,
                input         jalr,

                output reg [31:0] pc,
                output [31:0] aluout,
                output [31:0] MemWdata,
                input  [31:0] MemRdata);

  wire [4:0]  rs1, rs2, rd;               // 5bit rs1, rs2, rd 
  wire [2:0]  funct3;
  wire [31:0] rs1_data, rs2_data;         // 32 bit source data
  reg  [31:0] rd_data;                    // 32 bit destination data
  wire [20:1] jal_imm;                    // 20 bit imm for jal 
  wire [31:0] se_jal_imm;                 // 32 bit imm for jal
  wire [12:1] br_imm;                     // 12 bit branch imm
  wire [31:0] se_br_imm;                  // 32 bit branch imm
  wire [31:0] se_imm_itype;               // 32 bit imm i-type
  wire [31:0] se_imm_stype;               // 32 bit imm s-type
  wire [31:0] auipc_lui_imm;              // 32 bit imm auipc/lui
  reg  [31:0] alusrc1;                    // 32 bit alu source 1
  reg  [31:0] alusrc2;                    // 32 bit alu source 2
  wire [31:0] branch_dest;
  wire [31:0] jal_dest;      // 32 bit destination for branch and jal 
  wire		  Nflag, Zflag, Cflag, Vflag; 
  wire		  f3beq, f3blt;
  wire		  beq_taken;                    // beq(branch if equal)
  wire		  blt_taken;                    // blt(branch if less than)

  //////Lab #3
  //Add another branch instructions: bne(001), bge(101), bltu(110), bgeu(111)
  wire      f3bne, f3bge, f3bltu, f3bgeu;
  wire      bne_taken, bge_taken, bltu_taken, bgeu_taken;
  wire      b_taken;
  // jalr dest
  wire [31:0] jalr_dest;

  assign rs1 = inst[19:15];
  assign rs2 = inst[24:20];
  assign rd  = inst[11:7];
  assign funct3  = inst[14:12];

  //
  // PC (Program Counter) logic 
  //

  // if funct3 is 000, beq instruction
  assign f3beq  = (funct3 == 3'b000);
  // if funct3 is 100, blt instruction
  assign f3blt  = (funct3 == 3'b100);
  //BNE case
  assign f3bne = (funct3 == 3'b001);
  //BGE case
  assign f3bge = (funct3 == 3'b101);
  //BLTU case
  assign f3bltu = (funct3 == 3'b110);
  //BGEU case
  assign f3bgeu = (funct3 == 3'b111);

  assign beq_taken  = branch & f3beq & Zflag;
  assign blt_taken  = branch & f3blt & (Nflag != Vflag);
  //If ALU output(sub) is not zero = not same
  assign bne_taken = branch & f3bne & (~Zflag);
  //If ALU output is negative and overflow
  assign bge_taken = branch & f3bge & (Nflag == Vflag);
  //If ALU output makes carry
  assign bltu_taken = branch & f3bltu & ~Cflag;
  //If ALU output not makes carry
  assign bgeu_taken = branch & f3bgeu & Cflag;
  //If any branches taken
  assign b_taken = beq_taken | bne_taken | blt_taken | bge_taken | bltu_taken | bgeu_taken;

  //Assign branch destination
  assign branch_dest = pc + se_br_imm[31:0];
  assign jal_dest 	= aluout;
  assign jalr_dest  = aluout & ~1;

  //Select PC 
  always @(posedge clk, posedge reset)
  begin
     if (reset) pc <= 32'b0;
	  else 
	  begin
	      if (b_taken) // If branch_taken, PC is branch destination
				pc <= #`simdelay branch_dest;
		   else if (jal) //  If jal, PC is jal destination
				pc <= #`simdelay jal_dest;
       else if(jalr) 
        pc <= #`simdelay jalr_dest;
		   else           // else just pc + 4
				pc <= #`simdelay (pc + 4);
	  end
  end

  // JAL immediate
  assign jal_imm[20:1] = {inst[31],inst[19:12],inst[20],inst[30:21]};
  assign se_jal_imm[31:0] = {{11{jal_imm[20]}},jal_imm[20:1],1'b0};

  // Branch immediate
  assign br_imm[12:1] = {inst[31],inst[7],inst[30:25],inst[11:8]};
  assign se_br_imm[31:0] = {{19{br_imm[12]}},br_imm[12:1],1'b0};

  // 
  // Register File 
  //
  regfile i_regfile(
    .clk			(clk),
    .we			(regwrite),
    .rs1			(rs1),
    .rs2			(rs2),
    .rd			(rd),
    .rd_data	(rd_data),
    .rs1_data	(rs1_data),
    .rs2_data	(rs2_data));

	assign MemWdata = rs2_data;

	//
	// ALU 
	//
	alu i_alu(
		.a			(alusrc1),
		.b			(alusrc2),
		.alucont	(alucontrol),
		.result	(aluout),
		.N			(Nflag),
		.Z			(Zflag),
		.C			(Cflag),
		.V			(Vflag));

	// 1st source to ALU (alusrc1)
	always@(*)
	begin
		if      (auipc | jal)	alusrc1[31:0]  =  pc;
		else if (lui) 		alusrc1[31:0]  =  32'b0;
		else          		alusrc1[31:0]  =  rs1_data[31:0];
	end
	
	// 2nd source to ALU (alusrc2)
	always@(*)
	begin
		if	     (auipc | lui)			alusrc2[31:0] = auipc_lui_imm[31:0];
		else if (alusrc & memwrite)	alusrc2[31:0] = se_imm_stype[31:0];
    else if (jal & alusrc)    alusrc2[31:0] = se_jal_imm[31:0];
		else if (alusrc)					alusrc2[31:0] = se_imm_itype[31:0];
		else									alusrc2[31:0] = rs2_data[31:0];
	end
	
	assign se_imm_itype[31:0] = {{20{inst[31]}},inst[31:20]};
	assign se_imm_stype[31:0] = {{20{inst[31]}},inst[31:25],inst[11:7]};
	assign auipc_lui_imm[31:0] = {inst[31:12],12'b0};

	// Data selection for writing to RF
	always@(*)
	begin
		if	     (jal | jalr)			rd_data[31:0] = pc + 4;
		else if (memtoreg)	rd_data[31:0] = MemRdata;
		else					    	rd_data[31:0] = aluout;
	end
	
endmodule
