//
//
// Verilog ISA model of the PDP-8. 
//
//
//  Copyright(c) 2006 Mark G. Faust
//
//  Mark G. Faust
//  ECE Department
//  Portland State University
//
//
//
// This is a non-synthesizable model of the PDP-8 at the ISA level.  It's based
// upon DEC documentation and an ISPS description by Mario Barbacci.  Neither I//O
// instructions (opcode 6) nor Group 3 Microinstructions (EAE) are supported.
//
//
// A single object file (pdp8.mem) is read in $readmemh() format and simulated
// beginning at location 200 (octal).

// For each instruction type the instruction count is recorded along with the number
// of cycles (which depends upon addressing mode) consumed.
//
// Upon completion, these along with the total number of cycles
// simulated is printed along with the contents of the L, AC registers.
//

// Except for reading the memory image in hex, we will try report/display everything
// in octal since that's the dominant radix used on the PDP-8 (tools, documentation).
//
  

module PDP8 #(
	parameter OBJFILENAME = "pdp8_fp"
);


`define WORD_SIZE 12			// 12-bit word
`define MEM_SIZE  4096			// 4K memory
// `define OBJFILENAME "/u/kmehta/Documents/comp_arch/pdp8/PDP8-simulator-with-Floating-Point-extension/pdp8_fp"	// input file with object code
`define FP_WORD_SIZE 32			// Floating Point word size
//
// Processor state (note PDP-8 is a big endian system, bit 0 is MSB)
//


reg [0:`WORD_SIZE-1] PC;		// Program counter
reg [0:`WORD_SIZE-1] IR;		// Instruction Register
reg [0:`WORD_SIZE-1] AC;		// accumulator
reg [0:`WORD_SIZE-1] SR;		// front panel switch register
reg [0:`WORD_SIZE-1] MA;		// memory address register
reg        	      L;			// Link register

reg [0:4]  CPage;				// Current page

reg [0:`WORD_SIZE-1] Mem[0:`MEM_SIZE-1];// 4K memory

reg InterruptsOn;				// not currently used
reg InterruptReq;				// not currently used
reg Run;						// Run while 1

//
// Fields in instruction word
//

//
//// Floating Point Accumulator
//
reg [0:`FP_WORD_SIZE-1] FP_AC;		// Floating point Accumulator



`define OpCode		IR[0:2]		// Instruction OpCode
`define IndirectBit	IR[3]		// Indirect Address Bit
`define Page0Bit	IR[4]		// Memory Reference is to Page 0
`define PageAddress	IR[5:11]	// Page Offset


//
// Opcodes
//

parameter
	AND = 0,
	TAD = 1,
	ISZ = 2,
	DCA = 3,
	JMS = 4,
	JMP = 5,
	IOT = 6,
	OPR = 7;

parameter 
		FPCLAC = 0,
		FPLOAD = 1,
		FPSTOR = 2,
		FPADD = 3,
		FPMULT = 4;


//
// Microinstructions
//

`define Group	IR[3]		//  Group = 0 --> Group 1
`define CLA	IR[4]			//  clear AC  (both groups)



//
// Group 1 microinstructions (IR[3] = 0)
//


`define CLL	IR[5]			// clear L
`define CMA	IR[6]			// complement AC
`define CML	IR[7]			// complement L
`define ROT	IR[8:10]		// rotate
`define IAC	IR[11]			// increment AC


//
// Group 2 microinstructions (IR[3] = 1 and IR[11] = 0)
//

`define SMA IR[5]			// skip on minus AC
`define SZA IR[6]			// skip on zero AC
`define SNL IR[7]			// skip on non-zero L
`define SPA IR[5]			// skip on positive AC
`define SNA IR[6]			// skip on non-zero AC
`define SZL IR[7]			// skip on zero L
`define IS  IR[8]			// invert sense of skip
`define OSR IR[9]			// OR with switch register
`define HLT IR[10]			// halt processor



//
// Trace information
//

integer Clocks;
integer TotalClocks;
integer TotalIC;
integer CPI[0:7]; 	// clocks per instruction;
integer  IC[0:7];	// instruction count per instruction;
integer i;



task LoadObj;
  begin
  $readmemh(OBJFILENAME,Mem);
  end
endtask


task Fetch;
	begin
	IR = Mem[PC];
	`ifdef debug
		  $display("CONTENTS OF IR = %o", IR);
		  $display("CONTENTS OF PC = %o", PC);
	`endif
	CPage = PC[0:4];	// Need to maintain this BEFORE PC is incremented for EA calculation
	PC = PC + 1;
	end
endtask


task Execute;
  begin
  case (`OpCode)	
    AND:	begin
			Clocks = Clocks + 2;
			EffectiveAddress(MA);
			AC = AC & Mem[MA];
			end
	
	TAD:	begin
			Clocks = Clocks + 2;
			EffectiveAddress(MA);	
			{L,AC} = {L,AC} + {1'b0,Mem[MA]};
			end
			
	ISZ:	begin
			Clocks = Clocks + 2;
			EffectiveAddress(MA);
			Mem[MA] = Mem[MA] + 1;
			if (Mem[MA] == `WORD_SIZE'o0000)
				PC = PC + 1;
			end
			
	DCA:	begin
			Clocks = Clocks + 2;
			EffectiveAddress(MA);
			Mem[MA] = AC;
			AC = 0;
			end
			
	JMS:	begin
			Clocks = Clocks + 2;
			EffectiveAddress(MA);
			Mem[MA] = PC;
			PC = MA + 1;
			end
			
	JMP:	begin
			Clocks = Clocks + 1;
			EffectiveAddress(PC);
			end
			
	IOT:	begin	
			//$display("IOT instruction at PC = %0o",PC-1," ignored");
			// $display("IOT instruction at PC = %0o",PC-1);
			
			if (IR[3:8] == 6'o55) begin
				
				case (IR[9:11])
				FPCLAC  :begin
					FP_AC = 0;
					`ifdef oct
					$display("FP instruction is FPCLAC , \t\t\t\t\t FP_AC in octal= %o_%o_%o",  FP_AC[0],FP_AC[1:8],FP_AC[9:31]);
					`endif

					`ifdef hex
					$display("FP instruction is FPCLAC , \t\t\t\t\t FP_AC in hex= %h_%h_%h",  FP_AC[0],FP_AC[1:8],FP_AC[9:31]);
					`endif

					`ifdef bin
					$display("FP instruction is FPCLAC , \t\t\t\t\t FP_AC in binary= %b_%b_%b", FP_AC[0],FP_AC[1:8],FP_AC[9:31]);
					`endif
				end 

				FPLOAD  :begin
					FP_load;

					`ifdef oct
					$display("FP instruction is FPLOAD , \t from location = %o , \t FP_AC in octal= %o_%o_%o", MA, FP_AC[0],FP_AC[1:8],FP_AC[9:31]);
					`endif

					`ifdef hex
					$display("FP instruction is FPLOAD , \t from location = %h , \t FP_AC in hex= %h_%h_%h",  MA, FP_AC[0],FP_AC[1:8],FP_AC[9:31]);
					`endif

					`ifdef bin
					$display("FP instruction is FPLOAD , \t from location = %b , \t FP_AC in binary= %b_%b_%b",  MA, FP_AC[0],FP_AC[1:8],FP_AC[9:31]);
					`endif
				end 

				FPSTOR  :begin
					FP_store;
					`ifdef oct
					$display("FP instruction is FPSTOR , \t to location = %o, \t\t FP_AC in octal= %o_%o_%o",  MA, FP_AC[0],FP_AC[1:8],FP_AC[9:31]);
					$display("Memory location = %0o \t value is %o", MA ,Mem[MA]);
					$display("Memory location = %0o \t value is %o", MA+1 ,Mem[MA+1]);
					$display("Memory location = %0o \t value is %o", MA+2 ,Mem[MA+2]);
					`endif

					`ifdef hex
					$display("FP instruction is FPSTOR , \t to location = %h , \t\t FP_AC in hex= %h_%h_%h", MA, FP_AC[0],FP_AC[1:8],FP_AC[9:31]);
					$display("Memory location = %0h \t value is %h", MA ,{4'b0,Mem[MA][4:11]});
					$display("Memory location = %0h \t value is %h", MA+1, Mem[MA+1]);
					$display("Memory location = %0h \t value is %h", MA+2,Mem[MA+2]);
					`endif

					`ifdef bin
					$display("FP instruction is FPSTOR , \t to location = %b , \t\t FP_AC in bin= %b_%b_%b",  MA, FP_AC[0],FP_AC[1:8],FP_AC[9:31]);
					$display("Memory location = %0b \t value is %b", MA, Mem[MA]);
					$display("Memory location = %0b \t value is %b", MA+1,Mem[MA+1]);
					$display("Memory location = %0b \t value is %b", MA+2, Mem[MA+2]);
					`endif
				end 

				FPADD  :begin
					FP_add;
					`ifdef oct
					$display("FP instruction is FPADD , \t from location = %o , \t FP_AC in octal= %o_%o_%o", MA, FP_AC[0],FP_AC[1:8],FP_AC[9:31]);
					`endif

					`ifdef hex
					$display("FP instruction is FPADD , \t from location = %h , \t FP_AC in hex= %h_%h_%h",  MA, FP_AC[0],FP_AC[1:8],FP_AC[9:31]);
					`endif

					`ifdef bin
					$display("FP instruction is FPADD , \t from location = %b , \t FP_AC in bin= %b_%b_%b", MA, FP_AC[0],FP_AC[1:8],FP_AC[9:31]);
					`endif
				end 

				FPMULT  :begin
					FP_mult;
					`ifdef oct
					$display("FP instruction is FPMULT , \t from location = %o , \t FP_AC in octal= %o_%o_%o",  MA, FP_AC[0],FP_AC[1:8],FP_AC[9:31]);
					`endif

					`ifdef hex
					$display("FP instruction is FPMULT , \t from location = %h , \t FP_AC in hex= %h_%h_%h",  MA, FP_AC[0],FP_AC[1:8],FP_AC[9:31]);
					`endif

					`ifdef bin
					$display("FP instruction is FPMULT , \t from location = %b , \t FP_AC in bin= %b_%b_%b",  MA, FP_AC[0],FP_AC[1:8],FP_AC[9:31]);
					`endif
				end 

				default: begin
					$display("FP instruction is incorrect");
				end 
				
				endcase
			end 
		
			end
			
	OPR:	begin
				Clocks = Clocks + 1;
				Operate;
			end
			
	endcase
	
	CPI[`OpCode] = CPI[`OpCode] + Clocks;
	IC[`OpCode] = IC[`OpCode] + 1;
	end
endtask
 
task FP_load;
	begin
		EffectiveAddress_FP(MA);
		FP_AC= {Mem[MA+1][0],Mem[MA][4:11],Mem[MA + 1][1:11],Mem[MA+2]};
		
	end
endtask

task FP_store;
	begin
		  EffectiveAddress_FP(MA);
		  Mem[MA]={4'b0000,FP_AC[1:8]};
		  Mem[MA+1]= {FP_AC[0],FP_AC[9:19]};
		  Mem[MA+2] = FP_AC[20:31];
		//   {Mem[MA+1][0],Mem[MA][4:11],Mem[MA + 1][1:11],Mem[MA+2]} = FP_AC;
	end
endtask

task FP_mult;
	reg sgn;
	reg [0:31]temp;
	// reg signed [0:8] exp;
	reg  [0:8] exp;

	reg [0:23]mant_1 ; 
	reg [0:23]mant_2 ;
	reg [0:47]mant_int ;
	reg [0:47]mant_out;
	reg f;
	integer i;

	begin
		temp = 'b0;
		exp='b0;
		sgn = 'b0;
		mant_1='b0;
		mant_2='b0;
		mant_int='b0;
		mant_out = 'b0;
		i='b0;
        f =0;

		EffectiveAddress_FP(MA);
		
		temp = {Mem[MA+1][0],Mem[MA][4:11],Mem[MA + 1][1:11],Mem[MA+2]};
		// temp = 
		// $display("temp in mult = %b ", temp);
		
		sgn = FP_AC[0]^temp[0];
		// $display("sgn = %b", sgn);
		
		mant_1 = {1'b1,FP_AC[9:31]};
		// $display("mant_1 in mult = %b", mant_1);
		mant_2 = {1'b1,temp[9:31]}; 
		// $display("mant_2 in mult = %b", mant_2);

		for ( i=23; i>=0; i=i-1 )
		begin
			if(mant_2[i] == 1)
			begin
				mant_int = mant_1 << (23-i);
				mant_out = mant_out + mant_int;
			end
		end
		
		// $display("mant_out = %b", mant_out);
		
		// $display("exp 1 = %d", FP_AC[1:8] );
		// $display("exp 2 = %d", temp[1:8] );

         if ((FP_AC[0] == 1 && FP_AC[1:8] =='0) || (temp[0] == 1 && temp[1:8]=='0))
		begin
			FP_AC = {1,8'b0,23'b0};	
			`ifdef debug
			$display("Denormalized Accumulator is %h", FP_AC);
			`endif
		end
		else if((FP_AC[0] == 0 && FP_AC[1:8] =='0) || (temp[0] == 0 && temp[1:8]=='0))
        begin
			FP_AC = {0,8'b0,23'b0};	
			// `ifdef debug
			// $display("Accumulator is %h", FP_AC);
			// `endif	
		end
		
		else if ((FP_AC[1:8] == 255) || (temp[1:8]==255))
        begin
			FP_AC = {1,8'b0,23'b0};
			`ifdef debug	
			$display("NAN or infinity depeding on significant, Accumulator is %h", FP_AC);
			`endif
        end
 
       
        else
        begin
			if (mant_out[0]==1)
			begin
				mant_out = mant_out >>1;
				f=1;
				mant_out[2:24] = (mant_out[23]==1)? mant_out[2:24]+1:mant_out[2:24];    //:(mant_out[23:24==2'b01)?(mant_out[2:+22]+1):mant_out[2:+22];
			end
			
			else if (mant_out[0]==0)
			begin    
				f=0;       
				mant_out[2:24] = (mant_out[23]==1)? mant_out[2:24]+1:mant_out[2:24];     //(mant_out[23:24]==2'b01)?(mant_out[2:+22]+1):mant_out[2:+22];
			end


			exp = FP_AC[1:8] + temp[1:8]+ f - 127;
			// exp = exp + temp[1:8]+ f;  
			// exp = exp - 127 ; 
			// $display("exp = %b", exp);
			if (exp[1:8]>=255)
			begin
				`ifdef debug
				$display("Overflow");
				`endif
				FP_AC = {1,8'b0,23'b0};	
			end 
			else if((exp[1:8] == 255 ) && (mant_out != '0))
			begin
				`ifdef debug
				$display("NAN"); 
				`endif       
				FP_AC = {1,8'b0,23'b0};
			end
			else if((exp[1:8] == 255) && ( mant_out == '0 ))
			begin
				`ifdef debug
				$display("Infinity"); 
				`endif       
				FP_AC = {1,8'b0,23'b0};
			end
			else if ((exp[1:8] ==0) && (mant_out =='b0))      
			begin
				`ifdef debug
				$display("Denormalised"); 
				`endif       
				FP_AC = {1,8'b0,23'b0};
			end
			else if ((exp[1:8]==0))//&&(mant_out =='b0)) 
			begin
				`ifdef debug
				$display("Denormalized"); 
				`endif
				FP_AC = {1,8'b0,23'b0};
			end
			// else if(exp[1:8]<=-128)
			// begin
			// 	$display("underflow");
			// 	FP_AC = {1,8'b0,23'b0};	
			// end
			else
			begin
				FP_AC = {sgn,exp[1:8],mant_out[2:+22]};
			end
			FP_AC = {sgn,exp[1:8],mant_out[2:24]};
			// $display("FP_AC = %b , sgn = %b", FP_AC[0], sgn);
			// $display("FP_AC = %b", FP_AC);
		end
	end
endtask



task FP_add;

	reg sgn_1;
	reg sgn_2;
	reg sgn_out;
	reg [0:31]temp;
	reg [0:7] exp_1;
	reg [0:7] exp_2;
	reg [0:7] exp_out;
	reg [0:7] exp_diff;

	reg  [0:23]mant_1 ; 
	reg  [0:23]mant_2 ;
	reg  [0:23]mant_int ;
	reg  [0:23]mant_out_sub;
	reg  [0:24]mant_out_add;
	integer i;

	begin

		EffectiveAddress_FP(MA); 
		temp = {Mem[MA+1][0],Mem[MA][4:11],Mem[MA + 1][1:11],Mem[MA+2]};
		// $display("temp in mult = %o ", temp);

		exp_1 = FP_AC[1:8];
		exp_2 = temp[1:8];

		// $display("exp_1 = %b", exp_1);
		// $display("exp_2 = %b", exp_2);

		sgn_1 = FP_AC[0];
		sgn_2 = temp[0];
		
		mant_1 = {1'b1,FP_AC[9:31]};
		// $display("mant_1 in ADD = %b", mant_1);
		mant_2 = {1'b1,temp[9:31]}; 
		// $display("mant_2 in ADD = %b", mant_2);

		if (exp_1 == 8'hff  || exp_2 == 8'hff )
		begin
			sgn_out = 1;
			exp_out = 0;
			mant_out_add = 0;

			FP_AC= {sgn_out,exp_out,mant_out_add[2:24]};
			
			`ifdef debug
				$display("Value in FP_AC = %o_%o_%o",  FP_AC[0],FP_AC[1:8],FP_AC[9:31]);
				$display("Output is NaN \n %o \n %o \n %o",{4'b0000,exp_out}, {sgn_out,mant_out_add[2:12]}, mant_out_add[13:24] );
			`endif
		end

		else if (exp_1 == exp_2)
		begin
			// $display(" both exponents are equal");
			if (sgn_1 == sgn_2)
			begin
				// $display("signs are equal");
				mant_out_add = mant_1 + mant_2;
				exp_out = exp_1;
			
				sgn_out = sgn_1;
				if (mant_out_add[0] == 1'b1)
				begin
					mant_out_add = mant_out_add >> 1;
					exp_out = exp_out + 1;
				end

				
				// if (mant_out_add[0] == 1'b1)
				// begin
				// 	if (mant_out_add[24]==1)
				// 	begin	
				// 	mant_out_add = mant_out_add >> 1;
				// 	exp_out = exp_out + 1;
				// 	mant_out_add = mant_out_add +1;
				// 	end
				// end
				FP_AC= {sgn_out,exp_out,mant_out_add[2:24]};
				
				`ifdef debug
				$display("Value in FP_AC = %o_%o_%o",  FP_AC[0],FP_AC[1:8],FP_AC[9:31]);
					$display("Addition output in PDP8 format \n %o \n %o \n %o",{4'b0000,exp_out}, {sgn_out,mant_out_add[2:12]}, mant_out_add[13:24] );
				`endif
			end
			else if (sgn_1 != sgn_2)
			begin
				// $display("signs are not equal");
				
				if (mant_1 == mant_2)
				begin
					mant_out_sub =0;
					sgn_out = 0;
					exp_out = 0;
				end

				else if (mant_1 > mant_2)
				begin
					mant_out_sub = mant_1- mant_2;
					sgn_out = sgn_1;
					exp_out = exp_1;
					for (i = 0; i<23 ; i++)
					begin
						if (mant_out_sub[0] != 1)
						begin
							exp_out = exp_out - 1;
							mant_out_sub = mant_out_sub << 1;
						end
						else 
						 	break;
					end
				end

				
				else if (mant_2 > mant_1)
				begin
					mant_out_sub = mant_2 - mant_1;
					sgn_out = sgn_2;
					exp_out = exp_2;
					for (i = 0; i<23 ; i++)
					begin
						if (mant_out_sub[0] != 1)
						begin
							exp_out = exp_out -1;
							mant_out_sub = mant_out_sub << 1;
					
						end
						else 
						 	break;
					end
				end
				FP_AC= {sgn_out,exp_out,mant_out_sub[1:23]};
				`ifdef debug
				$display("Value in FP_AC = %o_%o_%o",  FP_AC[0],FP_AC[1:8],FP_AC[9:31]);
					$display("Addition output \n %o \n %o \n %o",{4'b0000,exp_out}, {sgn_out,mant_out_sub[1:11]}, mant_out_sub[12:23] );
				`endif
			end

		end

		else if (exp_1 > exp_2)
		begin
			// $display("accumulator exponent is bigger");
			if (sgn_1 == sgn_2)
			begin
				exp_diff = exp_1 - exp_2;
				mant_int = mant_2 >> exp_diff;
				exp_out = exp_1;
				mant_out_add = mant_int + mant_1;
				sgn_out = sgn_1;

				if (mant_out_add[0] == 1'b1)
				begin
					mant_out_add = mant_out_add >> 1;
					exp_out = exp_out + 1;
				end
				// if (mant_out_add[0] == 1'b1)
				// begin
				// 	if (mant_out_add[24]==1)
				// 	begin
						
				// 	mant_out_add = mant_out_add >> 1;
				// 	exp_out = exp_out + 1;
				// 	mant_out_add = mant_out_add +1;
				// 	end
				// end

				FP_AC= {sgn_out,exp_out,mant_out_add[2:24]};

				`ifdef debug
				$display("Value in FP_AC = %o_%o_%o",  FP_AC[0],FP_AC[1:8],FP_AC[9:31]);
					$display("Addition output \n %o \n %o \n %o",{4'b0000,exp_out}, {sgn_out,mant_out_add[2:12]}, mant_out_add[13:24] );
				`endif
			end

			else if (sgn_1 != sgn_2)
			begin
				// $display("signs are not equal");
				exp_diff = exp_1 - exp_2;
				mant_int = mant_2 >> exp_diff;
				exp_out = exp_1;
				mant_out_sub = mant_1 - mant_int;
				sgn_out = sgn_1;

				if (mant_out_sub[0] == 1'b0)
				begin
					mant_out_sub = mant_out_sub << 1;
					exp_out = exp_out - 1;
				end

				FP_AC= {sgn_out,exp_out,mant_out_sub[1:23]};
				`ifdef debug
				$display("Value in FP_AC = %o_%o_%o", FP_AC[0],FP_AC[1:8],FP_AC[9:31]);
					$display("Addition output \n %o \n %o \n %o",{4'b0000,exp_out}, {sgn_out,mant_out_sub[1:11]}, mant_out_sub[12:23] );
				`endif
			end
		end

		else if (exp_2 > exp_1)
		begin
			// $display("temp exp is big");
			if (sgn_1 == sgn_2)
			begin
				exp_diff = exp_2 - exp_1;
				mant_int = mant_1 >> exp_diff;
				exp_out = exp_2;
				mant_out_add = mant_int + mant_2;
				sgn_out = sgn_2;

				if (mant_out_add[0] == 1'b1)
				begin
					mant_out_add = mant_out_add >> 1;
					exp_out = exp_out + 1;
				end
				// if (mant_out_add[0] == 1'b1)
				// begin
				// 	if (mant_out_add[24]==1)
				// 	begin
						
				// 	mant_out_add = mant_out_add >> 1;
				// 	exp_out = exp_out + 1;
				// 	mant_out_add = mant_out_add +1;
				// 	end
				// end

				FP_AC= {sgn_out,exp_out,mant_out_add[2:24]};
				`ifdef debug
				$display("Value in FP_AC = %o_%o_%o",  FP_AC[0],FP_AC[1:8],FP_AC[9:31]);
					$display("Addition output \n %o \n %o \n %o",{4'b0000,exp_out}, {sgn_out,mant_out_add[2:12]}, mant_out_add[13:24] );
				`endif
			end
			else if (sgn_1 != sgn_2)
			begin
				// $display("signs are not equal");
				exp_diff = exp_2 - exp_1;
				mant_int = mant_1 >> exp_diff;
				exp_out = exp_2;
				mant_out_sub = mant_2 - mant_int;
				sgn_out = sgn_2;
				if (mant_out_sub[0] == 1'b0)
				begin
					mant_out_sub = mant_out_sub << 1;
					exp_out = exp_out - 1;
				end
				FP_AC= {sgn_out,exp_out,mant_out_sub[1:23]};
				
				`ifdef debug
				$display("Value in FP_AC = %o_%o_%o",  FP_AC[0],FP_AC[1:8],FP_AC[9:31]);	
					$display("Addition output \n %o \n %o \n %o",{4'b0000,exp_out}, {sgn_out,mant_out_sub[1:11]}, mant_out_sub[12:23] );
				`endif
			end	
		end
		// if (exp_out >= 255)
		// begin
		// 	$display("Overflow; INFINITY VALUE");
		// 	FP_AC= {1,8'b0,23'b0};
		// end


			
		// $display("exp_out = %b", exp_out);
		// $display("mant_int = %b", mant_int);
		// $display("mant_out_sub = %b", mant_out_sub);
		// $display("mant_out_add = %b", mant_out_add);	
	end

endtask

// Compute effective address taking into account indirect and auto-increment.
// Advance Clocks accordingly.  Auto-increment applies to indirect references
// to addresses 10-17 (octal) on page 0.
//
// Note that for auto-increment, this function has the side-effect of incrementing
// memory, so it should be called only once per execute cycle
//


task EffectiveAddress;
  output [0:`WORD_SIZE-1] EA;
  begin
  EA = (`Page0Bit) ? {CPage,`PageAddress} : {5'b00000,`PageAddress};

// $display("CPage = %0o   EA = %0o",CPage,EA);	
  if (`IndirectBit)
	begin
	Clocks = Clocks + 1;
    if (EA[0:8] == 9'b000000001)    // auto-increment
		begin
		$display("                         +   ");
		Clocks = Clocks + 1;
		Mem[EA] = Mem[EA] + 1;
		end
	EA = Mem[EA];
	end
	`ifdef debug 
		$display("EA = %o",EA);
	`endif
	end
endtask
  
  
task EffectiveAddress_FP;
	output  [0:`WORD_SIZE-1] EA;
	begin
		
		EA = Mem[PC];
		`ifdef debug
			$display("EA = %o",EA);
		`endif
			PC = PC +1;
	end	
endtask
  
  
//
// Handle microinstructions.  Some of these are done in parallel, some can
// be combined because they're done sequentially.
//
  
  
task Operate;
  begin
	case (`Group)
	  0:										// Group 1 Microinstructions
		begin
		if (`CLA) AC = 0;
		if (`CLL) L = 0;
		
		if (`CMA) AC = ~AC;
		if (`CML) L = ~L;
		
		if (`IAC) {L,AC} = {L,AC} + 1;
		
		case (`ROT)
			0:	;
			1:	{AC[6:11],AC[0:5]} = AC;		// BSW -- byte swap
			2:	{L,AC} = {AC,L};				// RAL -- left shift/rotate 1x
			3:	{L,AC} = {AC[1:11],L,AC[0]};	// RTL -- left shift/rotate 2x
			4:	{L,AC} = {AC[11],L,AC[0:10]};	// RAR -- right shift/rotate 1x
			5:	{L,AC} = {AC[10:11],L,AC[0:9]};	// RTR  -- right shift/rotate 2x
			6:	$display("Unsupported Group 1 microinstruction at PC = %0o",PC-1," ignored");
			7:	$display("Unsupported Group 1 microinstruction at PC = %0o",PC-1," ignored");
		endcase
		end
		
	  1:
		begin
		case (IR[11])
			0:	begin                           // Group 2 Microinstructions
				SkipGroup;
				if (`CLA) AC = 0;
				if (`OSR) AC = AC | SR;
				if (`HLT) Run = 0;
				end
				
			1:	begin							// Group 3 Microinstructions
				$display("Group 3 microinstruction at PC = %0o",PC-1," ignored");
				end
		endcase
		end
		
	endcase
  end
endtask
 
	
	
	
	
//
// Handle the Skip Group of microinstructions
//
//
	
	
task SkipGroup;
	reg Skip;
    begin
	case (`IS)			
	  0:	begin		// don't invert sense of skip [OR group]
			Skip = 0;
			if ((`SNL) && (L == 1'b1)) Skip = 1;
			if ((`SZA) && (AC == `WORD_SIZE'b0)) Skip = 1;
			if ((`SMA) && (AC[0] == 1'b1)) Skip = 1;			// less than zero
			end
			
	  1:	begin		// invert sense of skip [AND group]
			Skip = 1;
			if ((`SZL) && !(L == 1'b0)) Skip = 0;
			if ((`SNA) && !(AC != `WORD_SIZE'b0)) Skip = 0;
			if ((`SPA) && !(AC[0] == 1'b0)) Skip = 0;
			end
	endcase
	if (Skip)
		PC = PC + 1;
	end	
 endtask



//
// Dump contents of memory
//

task DumpMemory;
    begin
	for (i=0;i<`MEM_SIZE;i=i+1)
	    if (Mem[i] != 0)
			$display("%0o  %o",i,Mem[i]);
			
	end
endtask





initial
  begin
  LoadObj;			    // load memory from object file
  
  DumpMemory;
  
  PC = `WORD_SIZE'o200; // octal 200 start address
  L = 0;			    // initialize accumulator and link
  AC = 0;
  InterruptsOn = 0;
  InterruptReq = 0;
  Run = 1;				// not halted
  
  for (i=0;i<8;i = i + 1)
    begin
		CPI[i] = 0;
		IC[i] = 0;
    end



// $display(" PC L  AC   IR  Op P I + Clocks");
// $display("-------------------------------");

  while (Run)
    begin

    Clocks = 0;
    Fetch;
//	$display("%0o %0o %o %o %0o  %0o %0o",PC-1,L,AC,IR,`OpCode,`Page0Bit,`IndirectBit);
	
    Execute;
	
//    $display("                 %d ",Clocks);
	
    if ((InterruptsOn) && (InterruptReq))
	  begin
	  Mem[0] = PC;		// save PC
	  PC = 1;			// jump to interrupt service routine
	  end
    $display("         ");
	end

//  $display("    %0o %o\n\n",L,AC);
 DumpMemory;
	
  TotalClocks = 0;
  TotalIC = 0;	
  
  for (i=0;i<8;i = i +1)
	begin
	case (i)
	  AND:  $display("%0d AND instructions executed, using %0d clocks",IC[i],CPI[i]);
	
	  TAD:  $display("%0d TAD instructions executed, using %0d clocks",IC[i],CPI[i]);
	
	  ISZ:	$display("%0d ISZ instructions executed, using %0d clocks",IC[i],CPI[i]);
	
	  DCA:	$display("%0d DCA instructions executed, using %0d clocks",IC[i],CPI[i]);
			
	  JMS:	$display("%0d JSM instructions executed, using %0d clocks",IC[i],CPI[i]);
			
	  JMP:	$display("%0d JMP instructions executed, using %0d clocks",IC[i],CPI[i]);
			
	  IOT:	$display("%0d IOT instructions executed, using %0d clocks",IC[i],CPI[i]);
					
	  OPR:	$display("%0d OPR instructions executed, using %0d clocks",IC[i],CPI[i]);
	endcase

	TotalClocks = TotalClocks + CPI[i];
	TotalIC = TotalIC + IC[i];
	end
  $display("---------------------------------------------------------");
  $display("%0d Total instructions executed, using %0d clocks\n",TotalIC, TotalClocks);
  $display("Average CPI        = %4.2f\n",100.0 * TotalClocks/(TotalIC * 100.0));	
  end


endmodule
