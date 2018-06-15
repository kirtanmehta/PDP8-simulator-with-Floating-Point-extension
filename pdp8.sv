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
  

module PDP8();


`define WORD_SIZE 12			// 12-bit word
`define MEM_SIZE  4096			// 4K memory
`define OBJFILENAME "/u/chenyang/Documents/PDP8-simulator-with-Floating-Point-extension/pdp8_fp.mem"	// input file with object code
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
  $readmemh(`OBJFILENAME,Mem);
  end
endtask


task Fetch;
  begin
  IR = Mem[PC];
  $display("CONTENTS OF IR = %o", IR);
  $display("CONTENTS OF PC = %o", PC);
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
			$display("IOT instruction at PC = %0o",PC-1);
			
			if (IR[3:8] == 6'o55) begin
				
				case (IR[9:11])
				FPCLAC  :begin
				  	$display("FP instruction is FPCLAC");
					FP_AC = 0;
					$display("Value at FP_AC = %o", FP_AC);
				end 

				FPLOAD  :begin
				  	$display("FP instruction is FPLOAD");
					FP_load;
					$display("Value at FP_AC in octal = %o", FP_AC);
					$display("Value at FP_AC in hex = %h", FP_AC);
				end 

				FPSTOR  :begin
				  	$display("FP instruction is FPSTOR");
					FP_store;
					$display("Value at FP_AC in octal = %o", FP_AC);
					$display("Value at FP_AC in hex = %h", FP_AC);
				end 

				FPADD  :begin
				  	$display("FP instruction is FPADD");
					FP_add;
					$display("Value at FP_AC = %o", FP_AC);
				end 

				FPMULT  :begin
				  	$display("FP instruction is FPMULT");
					  FP_mult;
					  $display("Value at FP_AC = %o", FP_AC);
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
		$display("Mem[MA][4:11] = %o", Mem[MA][4:11]);
		//FP_AC = {Mem[MA][4:11],Mem[MA + 1], Mem[MA+2]};
		FP_AC= {Mem[MA+1][0],Mem[MA][4:11],Mem[MA + 1][1:11],Mem[MA+2]};
	end
endtask

task FP_store;
	begin
	  	EffectiveAddress_FP(MA);
		//{Mem[MA][4:11],Mem[MA + 1], Mem[MA+2]} = FP_AC;
		{Mem[MA+1][0],Mem[MA][4:11],Mem[MA + 1][1:11],Mem[MA+2]} = FP_AC;
		$display("%o", Mem[MA][4:11]);
		$display("%o", Mem[MA+1]);
		$display("%o", Mem[MA+2]);
	end
endtask

task FP_mult;
	//reg [11:0] row_1, row_2, row_3;
	reg sgn;
	reg [0:31]temp;
	// reg [0:7] exp;
	integer exp;

	reg [0:23]mant_1 ; 
	reg [0:23]mant_2 ;
	reg [0:47]mant_int ;
	reg [0:47]mant_out;
	
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

		EffectiveAddress_FP(MA);
		
		//temp = {Mem[MA][4:11],Mem[MA + 1], Mem[MA+2]};
		temp = {Mem[MA+1][0],Mem[MA][4:11],Mem[MA + 1][1:11],Mem[MA+2]};
		$display("temp in mult = %o ", temp);
		sgn = FP_AC[0]^temp[0];
		

		mant_1 = {1'b1,FP_AC[9:31]};
		$display("mant_1 in mult = %b", mant_1);
		mant_2 = {1'b1,temp[9:31]}; 
		$display("mant_2 in mult = %b", mant_2);

		for ( i=23; i>=0; i=i-1 )
		begin
			$display ("value of i = %d", 23-i);
			if(mant_2[i] == 1)
			begin
				mant_int = mant_1 << (23-i);
				mant_out = mant_out + mant_int;
			end
		end
		
		$display("mant_out = %b", mant_out);
		
		$display("exp 1 = %d", FP_AC[1:8] );
		$display("exp 2 = %d", temp[1:8] );
		
		if (mant_out[0]==1)
		begin
			exp = FP_AC[1:8] + temp[1:8] - 127 +1; 
			$display("exp value in mult = %d", exp);
			mant_out = mant_out >> 1;
			FP_AC = {sgn,exp[7:0],mant_out[2:+22]};	
			$display("Multiplication output \n %o \n %o \n %o",{4'b000,exp[7:0]}, {sgn,mant_out[2:12]}, mant_out[13:24] ); 
		end

		else if (mant_out[0] == 0)
		begin
			exp = FP_AC[1:8] + temp[1:8] - 127;
			$display("exp value in mult = %d", exp);
			FP_AC = {sgn,exp[7:0],mant_out[2:+22]};
			$display("Multiplication output \n %o \n %o \n %o",{4'b000,exp[7:0]}, {sgn,mant_out[2:12]}, mant_out[13:24] );
		end

		
		
		// FP_AC = {sgn,exp[7:0],mant_out[2:+22]};

		// $display("Multiplication output \n %o \n %o \n %o",{4'b000,exp[7:0]}, {sgn,mant_out[2:12]}, mant_out[13:24] );
	end

endtask


task FP_add;

	reg sgn;
	reg [0:31]temp;
	reg [0:7] exp_1;
	reg [0:7] exp_2;
	reg [0:7] exp_out;
	reg [0:7] exp_diff;

	reg [0:23]mant_1 ; 
	reg [0:23]mant_2 ;
	reg [0:24]mant_int ;
	reg [0:24]mant_out;

	begin

		EffectiveAddress_FP(MA); 
		temp = {Mem[MA+1][0],Mem[MA][3:10],Mem[MA + 1][1:11],Mem[MA+2]};
		$display("temp in mult = %o ", temp);

		exp_1 = FP_AC[1:8];
		exp_2 = temp[1:8];

		mant_1 = {1'b1,FP_AC[9:31]};
		$display("mant_1 in ADD = %b", mant_1);
		mant_2 = {1'b1,temp[9:31]}; 
		$display("mant_2 in ADD = %b", mant_2);

		if (exp_1 == exp_2)
		begin
			$display(" both exponents are equal");
			mant_out = mant_1 + mant_2;
			exp_out = exp_1;	
		end

		else if (exp_1 > exp_2)
		begin
			$display("accumulator exponent is bigger");
			exp_diff = exp_1 - exp_2;
			mant_int = mant_2 >> exp_diff;
			exp_out = exp_1;
			mant_out = mant_int + mant_1; 
		end

		else if (exp_2 > exp_1)
		begin
			$display("temp exp is big");
			exp_diff = exp_2 - exp_1;
			mant_int = mant_1 >> exp_diff;
			exp_out = exp_2;
			mant_out = mant_int + mant_2;
		end
		
		else
		begin
			$display("chutiya kata");
		end
		
		if (mant_out[0] == 1'b1)
		begin
			mant_out = mant_out >> 1;
			exp_out = exp_out + 1;
			// $display("mantissa output = %");
		end

		else
		begin
			$display("vapas chutiya kata");
		end

		$display("Multiplication output \n %o \n %o \n %o",{4'b000,exp[7:0]}, {sgn,mant_out[2:12]}, mant_out[13:24] );
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
 $display("EA = %o",EA);
  end
endtask
  
  
task EffectiveAddress_FP;
	output  [0:`WORD_SIZE-1] EA;
	begin
		//PC = PC +1;
	  	EA = Mem[PC];
		//MEM[EA] = MEM[EA]+3;
		// EA = Mem[EA];
		$display("EA = %o",EA);
		//PC = PC+1;

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
	$display("Value of RUN = %d", Run);
	$display("Opcode value =%d", `OpCode);
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
//  DumpMemory;
	
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
