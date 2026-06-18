module CPU_multicycle
	(input i_Switch_1,
	input i_Switch_2,
	input i_Clk,
	input i_UART_RX,
	output o_Out,
	output [7:0] o_reg0,
	output o_UART_TX,
	output o_TX_Active,
	output o_LED_1,
	output o_LED_2,
	output o_LED_3,
	output o_LED_4
	);

	reg [7:0] r_PC_CPU = 7'b0000000;
	reg [7:0] registers [0:15];
	reg is_Halted = 1'b1;
	reg [15:0] instruction = 16'b0000000000000000;
	reg [2:0] r_SM_CPU = 3'b000;
	reg [3:0] r_OPCODE = 4'b0000;
	reg [3:0] r_reg1 = 4'b0000;
	reg [3:0] r_reg2 = 4'b0000;
	reg [7:0] immediate = 8'b00000000;
	reg [7:0] pc_next;
	reg [7:0] result = 8'b00000000;
	reg reg_Write = 1'b0;
	reg mem_Write = 1'b0;
	reg take_branch = 1'b0;
	reg [7:0] branch_target;
	wire [15:0] mem_rdata;
	wire [7:0] mem_addr;
	wire [15:0] mem_wdata;
	wire mem_we;
	reg load_pending = 1'b0;
    reg [3:0] load_reg = 4'b0000;
	reg [7:0] memory_counter = 8'b00000000;
	reg [2:0] r_SM_PROGRAM = 3'b000;
	reg [7:0]  CPU_mem_addr;   
	reg [15:0] CPU_mem_wdata;  
	reg        CPU_mem_we;
	reg [7:0]  prog_mem_addr;
	reg [15:0] prog_mem_wdata;
	reg        prog_mem_we;
	reg [15:0] prog_instruction;
	reg r_LED_1;
	reg r_LED_2;
	reg r_LED_3;
	reg r_LED_4 = 1'b0;
	reg [7:0] r_RX_Byte;
	reg r_RX_DV;
	reg is_Halted2;
	reg [15:0] load_data;
	
	initial
	begin
	registers[0] = 8'b0;
	registers[1] = 8'b0;
	registers[2] = 8'b0;
	registers[3] = 8'b0;
	registers[4] = 8'b0;
	registers[5] = 8'b0;
	registers[6] = 8'b0;
	registers[7] = 8'b0;
	registers[8] = 8'b0;
	registers[9] = 8'b0;
	registers[10] = 8'b0;
	registers[11] = 8'b0;
	registers[12] = 8'b0;
	registers[13] = 8'b0;
	registers[14] = 8'b0;
	registers[15] = 8'b0;
	end
	
	
	parameter IDLE = 3'b000;
	parameter WRITE = 3'b001;
	parameter WRITE2 = 3'b010;
	parameter WRITE3 = 3'b011;
	parameter WRITE4 = 3'b100;
	parameter WRITE5 = 3'b101;

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
	parameter MEMWAIT2 = 3'b101;
	parameter WRITEBACK = 3'b110;
	parameter HALTED = 3'b111;
	
	
	wire [7:0] w_RX_Byte;
	wire w_RX_DV;
	wire w_TX_Active;
	wire w_TX_Serial;
	wire w_Halted;
		
	UART_RX #(.CLKS_PER_BIT(217)) Inst
	(.i_Clk(i_Clk),
	.i_RX_Serial(i_UART_RX),
	.o_RX_DV(w_RX_DV),
	.o_RX_Byte(w_RX_Byte));
	
	UART_TX #(.CLKS_PER_BIT(217)) Inst3
	(.i_Clock(i_Clk),
	.i_TX_DV(w_RX_DV),
	.i_TX_Byte(w_RX_Byte),
	.o_TX_Active(w_TX_Active),
	.o_TX_Serial(w_TX_Serial),
	.o_TX_Done());
	
	

	always @(posedge i_Clk)
	begin
		if (is_Halted)
			r_LED_3 <= 1'b1;
		
		if (~is_Halted)
			r_LED_4 <= 1'b1;
		if(is_Halted2 == 1'b1)
			is_Halted <= 1'b1;
	r_RX_DV <= w_RX_DV;
	r_RX_Byte <= w_RX_Byte;
		if(i_Switch_2)
		begin
		r_LED_4 <= 1'b0;
		r_LED_3 <= 1'b0;
		is_Halted <= 1'b1;
		end
		if (i_Switch_1)
			begin
				memory_counter <= 0;
				r_LED_1 <= 1'b0;
				r_LED_2 <= 1'b0;
				r_LED_3 <= 1'b0;
				r_LED_4 <= 1'b0;
				is_Halted <= 1'b0;
			end
		if (is_Halted )
		begin	
			case (r_SM_PROGRAM)
				IDLE : 
				begin
					if (r_RX_DV && r_RX_Byte >= 8'h61 && r_RX_Byte <= 8'h70)
					begin
						prog_mem_addr  <= memory_counter;
						prog_instruction[15:12] <= (r_RX_Byte - 8'h61);           
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
					if (r_RX_DV && r_RX_Byte >= 8'h61 && r_RX_Byte <= 8'h70)
					begin
						prog_instruction[11:8] <= (r_RX_Byte - 8'h61);           
						r_SM_PROGRAM   <= WRITE2;
						
					end
					else 
					begin             
						r_SM_PROGRAM   <= WRITE;
					end
				end
				
				WRITE2 : 
				begin
					if (r_RX_DV && r_RX_Byte >= 8'h61 && r_RX_Byte <= 8'h70)
					begin
						prog_instruction[7:4] <= (r_RX_Byte - 8'h61);           
						r_SM_PROGRAM   <= WRITE3;
					end
					else 
					begin             
						r_SM_PROGRAM   <= WRITE2;
					end
				end
				
				WRITE3 : 
				begin
					if (r_RX_DV && r_RX_Byte >= 8'h61 && r_RX_Byte <= 8'h70)
					begin
						prog_instruction[3:0] <= (r_RX_Byte - 8'h61);
						r_SM_PROGRAM   <= WRITE4;
					end
					else 
					begin             
						r_SM_PROGRAM   <= WRITE3;
					end
				end
				
				WRITE4 : 
				begin
					prog_mem_we <= 1'b1;
					prog_mem_wdata <= prog_instruction;
					r_SM_PROGRAM <= WRITE5;
				end
				
				WRITE5 :
				begin
					prog_mem_we <= 1'b0;
					memory_counter <= memory_counter + 1;
					r_SM_PROGRAM <= IDLE;
				end
				
				default :
				r_SM_PROGRAM <= IDLE;
			endcase	
		end
		else
		begin
			prog_mem_we <= 1'b0;
			r_SM_PROGRAM <= IDLE;
		end
	end
	
	
	
	
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
							reg_Write <= 1'b1;
						end
						
						STORE :
						begin
							CPU_mem_addr  <= registers[r_reg2];
							CPU_mem_wdata <= registers[r_reg1];
							CPU_mem_we    <= 1'b1;
							r_SM_CPU <= MEMWAIT;
							reg_Write <= 1'b0;
						end
						
						HALT : 
						begin
							is_Halted2 <= 1'b1;
							r_SM_CPU <= WRITEBACK;
						end
						
					endcase
				end
				
				MEMWAIT : 
				begin
					r_SM_CPU <= MEMWAIT2;
				end
				
				MEMWAIT2 : 
				begin
					load_data <= mem_rdata;
					r_SM_CPU <= WRITEBACK;
					load_pending <= 1'b0;
				end
				
				WRITEBACK :
				begin
					CPU_mem_we <= 1'b0;
					if (reg_Write && r_OPCODE == LOAD)
					begin
						registers[load_reg] <= load_data[7:0];
					end
					else if (reg_Write)
					begin
						registers[r_reg1] <= result;
					end
					reg_Write <= 1'b0;
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
				is_Halted2 <= 0;
			end
		end
		
	end
	
	assign w_Halted = is_Halted2;
	assign o_Out = r_PC_CPU[0] ^ result[0] ^ registers[0][0] ^ registers[15][0];
	assign mem_addr  = (is_Halted) ? prog_mem_addr  : ((r_SM_CPU == FETCH1) ? r_PC_CPU : CPU_mem_addr);
	assign mem_wdata = (is_Halted) ? prog_mem_wdata : CPU_mem_wdata;
	assign mem_we    = (is_Halted) ? prog_mem_we    : CPU_mem_we;
	assign o_reg0 = registers[1];
	assign o_UART_TX = w_TX_Active ? w_TX_Serial : 1'b1;
	assign o_TX_Active = w_TX_Active;
	assign o_LED_1 = r_LED_1;
	assign o_LED_2 = r_LED_2;
	assign o_LED_3 = r_LED_3;
	assign o_LED_4 = r_LED_4;
	
	
endmodule
		