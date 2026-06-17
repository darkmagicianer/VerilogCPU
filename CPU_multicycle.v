module CPU_base2
	(input i_Switch_1,
	input i_Clk,
	output o_Out
	);

	reg [7:0] r_PC_CPU = 0;
	reg [7:0] registers [0:15];
	reg is_Halted = 0;
	reg [15:0] instruction = 0;
	reg [2:0] r_SM_CPU = 0;
	reg [3:0] r_OPCODE = 0;
	reg [3:0] r_reg1 = 0;
	reg [3:0] r_reg2 = 0;
	reg [7:0] immediate = 0;
	reg [7:0] pc_next;
	reg [7:0] result = 0;
	reg reg_Write = 0;
	reg mem_Write = 0;
	reg take_branch = 0;
	reg [7:0] branch_target;
	wire [15:0] mem_rdata;
	reg [7:0] mem_addr;
	reg [15:0] mem_wdata;
	reg mem_we;

	parameter LOADI = 4'b0000;
	parameter ADDI = 4'b0001;
	parameter ADD = 4'b0010;
	parameter JUMP = 4'b0011;
	parameter JZ = 4'b0100;
	parameter JNZ = 4'b0101;
	parameter LOAD = 4'b0110;
	parameter STORE = 4'b0111;
	parameter HALT = 4'b1111;

	parameter FETCH = 3'b000;
	parameter DECODE = 3'b001;
	parameter EXECUTE = 3'b010;
	parameter WRITEBACK = 3'b011;
	parameter HALTED = 3'b100;
	
	
	SB_RAM40_4K ram0 ( 
	.RDATA(mem_rdata), 
	.RADDR(mem_addr), 
	.RCLK(i_Clk), 
	.RCLKE(1'b1), 
	.WADDR(mem_addr), 
	.WCLK(i_Clk), 
	.WCLKE(mem_we), 
	.WDATA(mem_wdata), 
	.MASK(16'h0000) 
	);
	
	

	always @(posedge i_Clk)
	begin
		if (is_Halted == 0)
		begin
			case (r_SM_CPU)
				FETCH : 
				begin
					reg_Write <= 0;
					mem_Write <= 0;
					instruction <= memory[r_PC_CPU];
					r_SM_CPU <= DECODE;
				end
				
				DECODE : 
				begin
					r_OPCODE <= instruction[15:12];
					r_reg1 <= instruction[11:8];
					r_reg2 <= instruction[7:4];
					immediate <= instruction[7:0];
					r_SM_CPU <= EXECUTE;
				end
				
				EXECUTE : 
				begin
					take_branch = 0; 
					
					if (r_opcode == JZ)
						take_branch = (registers[r_reg1] == 0);
					else if (r_opcode == JNZ)
						take_branch = (registers[r_reg1] != 0);
					else if (r_opcode == JUMP)
						take_branch = 1;

					branch_target = immediate;

					if (take_branch)
						pc_next = branch_target;
					else
						pc_next = r_PC_CPU + 1;
					
					r_PC_CPU <= pc_next;
						
					case (r_OPCODE)
						LOADI :
						begin
							result <= immediate;
							reg_Write <= 1'b1;
						end
						
						ADDI :
						begin
							result <= registers[r_reg1] + immediate;
							reg_Write <= 1'b1;
						end
						
						ADD :
						begin
							result <= registers[r_reg1] + registers[r_reg2];
							reg_Write <= 1'b1;
						end
						
						LOAD : 
						begin
							result <= memory[registers[r_reg2]];
							reg_Write <= 1'b1;
						end
						
						STORE :
						begin
							result <= registers[r_reg1];
							mem_Write <= 1'b1;
						end
						
						HALT : 
						begin
							is_Halted <= 1'b1;
						end
					endcase
					r_SM_CPU <= WRITEBACK;
				end
				
				WRITEBACK :
				begin
					if (mem_Write)
						memory[registers[r_reg2]] <= result;
					if (reg_Write)
					begin
						registers[r_reg1] <= result;
					end
					r_SM_CPU <= FETCH;
				end

			endcase
		end
		
		else 
		begin
			if (i_Switch_1)
			begin
				r_PC_CPU <= 0;
				r_SM_CPU <= FETCH;
				is_Halted <= 0;
			end
		end
		
	end
endmodule
		