//////////////////////////////////////////////////////////////////////////////////////////
// convert.sv - It reads the floating input and convert into PDP8 floating format       //
// Date : May 5, 2018                                                                   //
// Author: Kirtan Mehta, Vinoth GV, Mohammad Suheb Zameer, Chenyang Li                  //
//                                                                                      //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////

module convert;

integer fpread,fp_out;
shortreal temp;
shortreal value;

bit [63:0] fpvalue;
bit [7:0]  exp_bias;
bit sign;
bit [22:0]significant;

shortreal arg;
string format;

    initial
    begin
	
        fpread = $fopen("fp_data", "r");
        fp_out = $fopen("fp_out");
    
        if(!($value$plusargs("arg=%f", arg)))
        begin
            while (!$feof(fpread))
            begin
                temp = $fscanf(fpread, "%f", value);      
                calculate;            
                #1;
            
            end
	    end 
        
        else 
        begin
		    value = arg;
		    calculate;
	    end

	
    end
    
    task calculate;
        fpvalue = $shortrealtobits(value);
        exp_bias = (fpvalue[30:23]);
        significant = fpvalue[22:0];
        sign = fpvalue[31];
        display;
    endtask

    task display;

        void '($value$plusargs("format=%s", format));

        if (($value$plusargs("arg=%f", arg)) && (format == "o"))
        begin
            $display("%o\n%o\n%o\n", {4'b0000,exp_bias},{sign, significant[22:12]}, significant[11:0]);
        end
        
        else if ($value$plusargs("arg=%f", arg))
        begin
            $dsiplay("%h\n%h\n%h\n", {4'b0000,exp_bias},{sign, significant[22:12]}, significant[11:0]);
        end

        else begin
        if(format == "o")
            $fdisplay(fp_out,"%o\n%o\n%o", {4'b0000,exp_bias},{sign, significant[22:12]}, significant[11:0]);

        else
            $fdsiplay(fp_out,"%h\n%h\n%h", {4'b0000,exp_bias},{sign, significant[22:12]}, significant[11:0]);
        end
    endtask

// initial begin
//     void '($value$plusargs("format=%s", format));

//     if (($value$plusargs("arg=%f", arg)) && (format == "o"))
//     begin
//         $monitor("%o\n%o\n%o\n", {4'b0000,exp_bias},{sign, significant[22:12]}, significant[11:0]);
//     end
    
//     else if ($value$plusargs("arg=%f", arg))
//     begin
//         $monitor("%h\n%h\n%h\n", {4'b0000,exp_bias},{sign, significant[22:12]}, significant[11:0]);
//     end

// end

// initial begin
// 	void '($value$plusargs("format=%s", format));
	
//     if(format == "o")
// 		$fmonitor(fp_out,"%o\n%o\n%o", {4'b0000,exp_bias},{sign, significant[22:12]}, significant[11:0]);

// 	else
//     	$fmonitor(fp_out,"%h\n%h\n%h", {4'b0000,exp_bias},{sign, significant[22:12]}, significant[11:0]);
// end

endmodule
