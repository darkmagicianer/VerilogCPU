module CPU_base2
	(input i_Switch_1,
	input i_Clk,
	input i_UART_RX,
	output o_Out
	);

	reg [7:0] r_PC_CPU = 0;
	reg [7:0] registers [0:15];
	reg is_Halted = 1'b1;
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
	wire [7:0] mem_addr;
	wire [15:0] mem_wdata;
	wire mem_we;
	reg load_pending = 0;
    reg [3:0] load_reg = 0;
	reg [7:0] memory_counter = 0;
	reg r_SM_PROGRAM = 0;
	reg [7:0]  CPU_mem_addr;   
	reg [15:0] CPU_mem_wdata;  
	reg        CPU_mem_we;
	reg [7:0]  prog_mem_addr;
	reg [15:0] prog_mem_wdata;
	reg        prog_mem_we;
	
	wire [7:0] w_RX_Byte;
	wire w_RX_DV;
		
	UART_RX #(.CLKS_PER_BIT(217)) Inst
	(.i_Clk(i_Clk),
	.i_RX_Serial(i_UART_RX),
	.o_RX_DV(w_RX_DV),
	.o_RX_Byte(w_RX_Byte));

	always @(posedge i_Clk)
	begin
		if (is_Halted)
		begin
			if (i_Switch_1)
				memory_counter <= 0;
			case (r_SM_PROGRAM)
				IDLE : 
				begin
					if (w_RX_DV && w_RX_Byte >= 7'h61 && w_RX_Byte <= 7'h6E)
					begin
						prog_mem_addr  <= memory_counter;
						prog_mem_wdata <= w_RX_Byte - 7'h61; 
						prog_mem_we    <= 1'b1;              
						r_SM_PROGRAM   <= WRITE;
					end
					else 
					begin
						prog_mem_we    <= 1'b0;               
						r_SM_PROGRAM   <= IDLE;
					end
				end
				
				WRITE : 
				begin
					prog_mem_we <= 1'b0;
					r_SM_PROGRAM <= IDLE;
					memory_counter <= memory_counter + 1;
				end
			endcase	
		end
		else
		begin
			prog_mem_we <= 1'b0;
			r_SM_PROGRAM <= IDLE;
		end
	end
	
	parameter IDLE = 1'b0;
	parameter WRITE = 1'b1;

	parameter LOADI = 4'b0000;
	parameter ADDI = 4'b0001;
	parameter ADD = 4'b0010;
	parameter JUMP = 4'b0011;
	parameter JZ = 4'b0100;
	parameter JNZ = 4'b0101;
	parameter LOAD = 4'b0110;
	parameter STORE = 4'b0111;
	parameter SUBI = 4'b1000;
	parameter SUB = 4'b1001;
	parameter XOR = 4'b1010;
	parameter AND = 4'b1011;
	parameter OR = 4'b1100;
	parameter HALT = 4'b1111;

	parameter FETCH1 = 3'b000;
	parameter FETCH2 = 3'b001;
	parameter DECODE = 3'b010;
	parameter EXECUTE = 3'b011;
	parameter MEMWAIT = 3'b100;
	parameter WRITEBACK = 3'b101;
	parameter HALTED = 3'b110;
	
	
	SB_RAM40_4K ram0 ( 
	.RDATA(mem_rdata), 
	.RADDR(mem_addr), 
	.RCLK(i_Clk), 
	.RCLKE(1'b1),               
	.RE(1'b1),                  
	.WADDR(mem_addr), 
	.WCLK(i_Clk), 
	.WCLKE(1'b1),             
	.WE(mem_we),               
	.WDATA(mem_wdata), 
	.MASK(16'h0000) 
	);
	
	

	always @(posedge i_Clk)
	begin
		if (is_Halted == 0)
		begin
			case (r_SM_CPU)
				FETCH1 : 
				begin
					reg_Write <= 0;
					CPU_mem_we <= 0;
					CPU_mem_addr <= r_PC_CPU;
					r_SM_CPU <= FETCH2;
				end
				
				FETCH2 : 
				begin
					instruction <= mem_rdata;
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
					
					if (r_OPCODE == JZ)
						take_branch = (registers[r_reg1] == 0);
					else if (r_OPCODE == JNZ)
						take_branch = (registers[r_reg1] != 0);
					else if (r_OPCODE == JUMP)
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
							r_SM_CPU <= WRITEBACK;
						end
						
						ADDI :
						begin
							result <= registers[r_reg1] + immediate;
							reg_Write <= 1'b1;
							r_SM_CPU <= WRITEBACK;
						end
						
						ADD :
						begin
							result <= registers[r_reg1] + registers[r_reg2];
							reg_Write <= 1'b1;
							r_SM_CPU <= WRITEBACK;
						end
						
						SUBI : 
						begin
							result <= registers[r_reg1] - immediate;
							reg_Write <= 1'b1;
							r_SM_CPU <= WRITEBACK;
						end
						
						SUB : 
						begin
							result <= registers[r_reg1] - registers[r_reg2];
							reg_Write <= 1'b1;
							r_SM_CPU <= WRITEBACK;
						end
						
						AND : 
						begin
							result <= registers[r_reg1] & registers[r_reg2];
							reg_Write <= 1'b1;
							r_SM_CPU <= WRITEBACK;
						end
						
						XOR : 
						begin
							result <= registers[r_reg1] ^ registers[r_reg2];
							reg_Write <= 1'b1;
							r_SM_CPU <= WRITEBACK;
						end
						
						OR : 
						begin
							result <= registers[r_reg1] | registers[r_reg2];
							reg_Write <= 1'b1;
							r_SM_CPU <= WRITEBACK;
						end
						
						LOAD : 
						begin
							CPU_mem_addr <= registers[r_reg2];
							load_reg <= r_reg1;
							load_pending <= 1'b1;
							r_SM_CPU  <= MEMWAIT;
						end
						
						STORE :
						begin
							CPU_mem_addr  <= registers[r_reg2];
							CPU_mem_wdata <= registers[r_reg1];
							CPU_mem_we    <= 1'b1;
							r_SM_CPU <= WRITEBACK;
						end
						
						HALT : 
						begin
							is_Halted <= 1'b1;
						end
					endcase
				end
				
				MEMWAIT : 
				begin
					load_pending <= 1'b0;
					r_SM_CPU <= WRITEBACK;
				end
				
				WRITEBACK :
				begin
					CPU_mem_we <= 1'b0;
					if (reg_Write && r_OPCODE == LOAD)
					begin
						registers[load_reg] <= mem_rdata;
					end
					else if (reg_Write)
					begin
						registers[r_reg1] <= result;
					end
					r_SM_CPU <= FETCH1;
				end

			endcase
		end
		
		else 
		begin
			if (i_Switch_1)
			begin
				r_PC_CPU <= 0;
				r_SM_CPU <= FETCH1;
				is_Halted <= 0;
			end
		end
		
	end
	
	assign o_Out = r_PC_CPU[0] ^ result[0] ^ registers[0][0] ^ registers[15][0];
	assign mem_addr  = (is_Halted) ? prog_mem_addr  : CPU_mem_addr;
	assign mem_wdata = (is_Halted) ? prog_mem_wdata : CPU_mem_wdata;
	assign mem_we    = (is_Halted) ? prog_mem_we    : CPU_mem_we;
	
endmodule
		