module CPU_top
	(input i_Switch_1,
	input i_Switch_2,
	input i_Clk,
	input i_UART_RX,
	output o_UARt_TX,
	output o_Segment1_A,
	output o_Segment1_B,
	output o_Segment1_C,
	output o_Segment1_D,
	output o_Segment1_E,
	output o_Segment1_F,
	output o_Segment1_G,
	output o_Segment2_A,
	output o_Segment2_B,
	output o_Segment2_C,
	output o_Segment2_D,
	output o_Segment2_E,
	output o_Segment2_F,
	output o_Segment2_G,
	output o_UART_TX,
	output o_LED_1,
	output o_LED_2,
	output o_LED_3,
	output o_LED_4,
	output o_Out
	);
	
	wire [7:0] w_reg0;
	reg [7:0] r_reg0;
	
	wire w_Segment1_A;
	wire w_Segment1_B;
	wire w_Segment1_C;
	wire w_Segment1_D;
	wire w_Segment1_E;
	wire w_Segment1_F;
	wire w_Segment1_G;
	wire w_Segment2_A;
	wire w_Segment2_B;
	wire w_Segment2_C;
	wire w_Segment2_D;
	wire w_Segment2_E;
	wire w_Segment2_F;
	wire w_Segment2_G;
	wire w_UART_TX;
	wire w_TX_Active;
	wire w_LED_1;
	wire w_LED_2;
	wire w_LED_3;
	wire w_LED_4;
	wire w_out;
	
	CPU_multicycle inst
	(.i_Switch_1(i_Switch_1),
	.i_Switch_2(i_Switch_2),
	.i_Clk(i_Clk),
	.i_UART_RX(i_UART_RX),
	.o_UART_TX(w_UART_TX),
	.o_TX_Active(w_TX_Active),
	.o_Out(w_out),
	.o_reg0(w_reg0),
	.o_LED_1(w_LED_1),
	.o_LED_2(w_LED_2),
	.o_LED_3(w_LED_3),
	.o_LED_4(w_LED_4)
	);
	
	assign o_Out = w_out;
	assign o_UART_TX = w_TX_Active ? w_UART_TX : 1'b1;
	
	
	always @(posedge i_Clk)
	begin
		r_reg0 <= w_reg0;
	end
	
	Project_7_Segment_Top Inst2
	(.i_Clk(i_Clk),
	.i_Switch_1(),
	.binary_num(r_reg0),
	.o_Segment1_A(w_Segment1_A),
	.o_Segment1_B(w_Segment1_B),
	.o_Segment1_C(w_Segment1_C),
	.o_Segment1_D(w_Segment1_D),
	.o_Segment1_E(w_Segment1_E),
	.o_Segment1_F(w_Segment1_F),
	.o_Segment1_G(w_Segment1_G),
	.o_Segment2_A(w_Segment2_A),
	.o_Segment2_B(w_Segment2_B),
	.o_Segment2_C(w_Segment2_C),
	.o_Segment2_D(w_Segment2_D),
	.o_Segment2_E(w_Segment2_E),
	.o_Segment2_F(w_Segment2_F),
	.o_Segment2_G(w_Segment2_G));
	
	
	assign o_Segment2_A = w_Segment2_A;
	assign o_Segment2_B = w_Segment2_B;
	assign o_Segment2_C = w_Segment2_C;
	assign o_Segment2_D = w_Segment2_D;
	assign o_Segment2_E = w_Segment2_E;
	assign o_Segment2_F = w_Segment2_F;
	assign o_Segment2_G = w_Segment2_G;
	
	assign o_Segment1_A = w_Segment1_A;
	assign o_Segment1_B = w_Segment1_B;
	assign o_Segment1_C = w_Segment1_C;
	assign o_Segment1_D = w_Segment1_D;
	assign o_Segment1_E = w_Segment1_E;
	assign o_Segment1_F = w_Segment1_F;
	assign o_Segment1_G = w_Segment1_G;
	
	assign o_LED_1 = w_LED_1;
	assign o_LED_2 = w_LED_2;
	assign o_LED_3 = w_LED_3;
	assign o_LED_4 = w_LED_4;
	
	endmodule