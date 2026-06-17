module CPU_base
	(input i_Switch_1,
	input i_Clk,
	output o_Out
	);

	reg [7:0] r_Sum = 0;
	reg [7:0] r_PC_CPU = 0;
	reg [7:0] R0 = 0;
	reg [7:0] R1 = 0;
	reg [15:0] memory [0:255];
	reg halted = 0;
	reg [15:0] instruction = 0;
	reg [7:0] PC_next = 0;

	parameter LOADI = 4'b0000;
	parameter ADDI = 4'b0001;
	parameter ADD = 4'b0010;
	parameter JUMP = 4'b0011;
	parameter HALT = 4'b1111;
	
	
	parameter register0 = 4'b0000;
	parameter register1 = 4'b0001;
	
	initial
	begin
		memory[0] = 16'b0;
		memory[1] = 16'b0001000000000000;
		memory[2] = 16'b0001000000000000;
		memory[3] = 16'b1111000000000000;
	end

	always @(posedge i_Clk)
	begin
		if (halted == 0)
		begin
			instruction <= memory[r_PC_CPU];
			case (instruction[15:12])
			
			LOADI :
			begin
				case (instruction[11:8])
			
					register0 : 
					begin
						R0 <= instruction[7:0];
					end
					
					register1 : 
					begin
						R1 <= instruction[7:0];
					end
				endcase
			end
			
			ADDI :
			begin
				case (instruction[11:8])
					register0 : 
					begin
						R0 <= R0 + instruction[7:0];
					end
					
					register1 : 
					begin
						R1 <= R1 + instruction[7:0];
					end
				endcase
			end
			
			ADD :
			begin
				case (instruction[11:8])
					register0 : 
					begin
						case (instruction[7:4])
							register0 :
								R0 <= R0 + R0;
							register1 : 
								R0 <= R0 + R1;
						endcase
					end
					
					register1 : 
					begin
						case (instruction[7:4])
							register0 :
								R1 <= R1 + R0;
							register1 : 
							R1 <= R1 + R1;
						endcase
					end
				endcase
			end
			endcase
			
			PC_next = r_PC_CPU + 1;
			if (!halted)
			begin
				case (instruction[15:12])

				JUMP:
					PC_next = instruction[7:0];

				HALT:
				begin
					halted <= 1'b1;
					PC_next = r_PC_CPU;
				end
				endcase
			end
			r_PC_CPU <= PC_next;
			
		end
			
	end
	
endmodule
		