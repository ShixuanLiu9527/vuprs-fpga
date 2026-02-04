
`timescale 1 ns / 1 ps

	module vpdelay_v1_0_S00_AXIS #
	(
		// Users to add parameters here

		parameter WAVE_VELOCITY_MPS              = 346,
		parameter MAXIMUM_ARRAY_SIZE_MM          = 250,
		parameter MAXIMUM_SAMPLING_FREQ_HZ       = 160_000,

		parameter [31: 0] FRAME_HEADER           = 32'h0000_FFF0,
		parameter [31: 0] FRAME_TAILER           = 32'h0000_FF0F,

		parameter ADC_DATA_WIDTH_BIT             = 16,
		parameter ADC_CHANNEL_COUNT              = 16,

		parameter integer C_S_AXI_DATA_WIDTH	 = 32,

		// User parameters ends
		// Do not modify the parameters beyond this line

		// AXI4Stream sink: Data Width
		parameter integer C_S_AXIS_TDATA_WIDTH	 = 32
		
	)
	(
		// Users to add ports here

		input wire freeze,
		input wire software_rst,
		input wire axis_send_busy,

		output wire freezed,
		output wire refreshed,
		output wire send_trigger,

		output wire [(C_S_AXI_DATA_WIDTH/2)-1: 0] max_pdelay,

		/* Pre-delay */

		input wire [C_S_AXI_DATA_WIDTH-1:0]	pdelay_ch1_ch2,    /* [0: 15] pre-delay ch1, [16: 31] pre-delay ch2 */
	    input wire [C_S_AXI_DATA_WIDTH-1:0]	pdelay_ch3_ch4,    /* [0: 15] pre-delay ch3, [16: 31] pre-delay ch4 */
	    input wire [C_S_AXI_DATA_WIDTH-1:0]	pdelay_ch5_ch6,    /* [0: 15] pre-delay ch5, [16: 31] pre-delay ch6 */
	    input wire [C_S_AXI_DATA_WIDTH-1:0]	pdelay_ch7_ch8,    /* [0: 15] pre-delay ch7, [16: 31] pre-delay ch8 */
	    input wire [C_S_AXI_DATA_WIDTH-1:0]	pdelay_ch9_ch10,   /* [0: 15] pre-delay ch9, [16: 31] pre-delay ch10 */
	    input wire [C_S_AXI_DATA_WIDTH-1:0]	pdelay_ch11_ch12,  /* [0: 15] pre-delay ch11, [16: 31] pre-delay ch12 */
	    input wire [C_S_AXI_DATA_WIDTH-1:0]	pdelay_ch13_ch14,  /* [0: 15] pre-delay ch13, [16: 31] pre-delay ch14 */
	    input wire [C_S_AXI_DATA_WIDTH-1:0]	pdelay_ch15_ch16,  /* [0: 15] pre-delay ch15, [16: 31] pre-delay ch16 */

		/* Package data frame */

		output wire [C_S_AXIS_TDATA_WIDTH-1:0]	data_frame1,
	    output wire [C_S_AXIS_TDATA_WIDTH-1:0]	data_frame2,
	    output wire [C_S_AXIS_TDATA_WIDTH-1:0]	data_frame3,
	    output wire [C_S_AXIS_TDATA_WIDTH-1:0]	data_frame4,
	    output wire [C_S_AXIS_TDATA_WIDTH-1:0]	data_frame5,
	    output wire [C_S_AXIS_TDATA_WIDTH-1:0]	data_frame6,
	    output wire [C_S_AXIS_TDATA_WIDTH-1:0]	data_frame7,
	    output wire [C_S_AXIS_TDATA_WIDTH-1:0]	data_frame8,

		// User ports ends
		// Do not modify the ports beyond this line

		// AXI4Stream sink: Clock
		input wire  S_AXIS_ACLK,
		// AXI4Stream sink: Reset
		input wire  S_AXIS_ARESETN,
		// Ready to accept data in
		output wire  S_AXIS_TREADY,
		// Data in
		input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] S_AXIS_TDATA,
		// Byte qualifier
		input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB,
		// Indicates boundary of last packet
		input wire  S_AXIS_TLAST,
		// Data is in valid
		input wire  S_AXIS_TVALID
	);

	function integer clogb2 (input integer bit_depth);
	begin
	    for(clogb2=0; bit_depth>0; clogb2=clogb2+1) bit_depth = bit_depth >> 1;
	end
	endfunction

	localparam TRUE = 1'b1,
	           FALSE = 1'b0;

	localparam FRAME_WORD_NUMBER                = 10;  /* Data Header & Data Tailer included */
	localparam FRAME_WORD_DATA_NUMBER           = FRAME_WORD_NUMBER - 2;   /* Data Header & Data Tailer excluded */

	localparam MAXIMUM_PRE_DELAY_COUNT = ((MAXIMUM_ARRAY_SIZE_MM * MAXIMUM_SAMPLING_FREQ_HZ) / (WAVE_VELOCITY_MPS * 1000)) + 1;

	localparam DELAY_LINE_ADDR_SIZE = clogb2(MAXIMUM_PRE_DELAY_COUNT + 1);
	localparam AXIS_RECEIVE_BUFFER_ADDR_SIZE = clogb2(FRAME_WORD_DATA_NUMBER + 1);

	localparam ACTUAL_BRAM_DEPTH = 1 << DELAY_LINE_ADDR_SIZE;  /* 2 ^ (DELAY_LINE_ADDR_SIZE) */
	localparam ACTUAL_MAXIMUM_PRE_DELAY = ACTUAL_BRAM_DEPTH - 1;
	
	localparam [3: 0] AXIS_WAIT_FOR_DATA_HEADER   = 4'd0,  /* 4 bit */
					  AXIS_RECEIVE_DATA           = 4'd1,
					  AXIS_WAIT_FOR_DATA_TAILER   = 4'd2,
					  AXIS_UNPACKING              = 4'd3,
					  AXIS_PUSH_BRAM              = 4'd4,
					  AXIS_CHECK_FREEZE           = 4'd5,
					  AXIS_READ                   = 4'd6,
					  AXIS_PACKAGE                = 4'd7,
					  AXIS_SEND_DATA_WAIT_IDLE    = 4'd8,
					  AXIS_SEND_DATA_TRIGGER      = 4'd9,
					  AXIS_SEND_DATA_WAIT_START   = 4'd10;

	`ifndef SYNTHESIS
		initial begin
			$display("-----------------------------------------------------------------");
    		$display("[VUPRS synthesis INFO] Module: VUPRS Beamforming Pre-delay Unit");
    		$display("[VUPRS synthesis INFO] MAXIMUM_PRE_DELAY_COUNT = %0d", MAXIMUM_PRE_DELAY_COUNT);
			$display("[VUPRS synthesis INFO] ACTUAL_BRAM_DEPTH = %0d", ACTUAL_BRAM_DEPTH);
			$display("-----------------------------------------------------------------");
		end
	`endif

	/* BRAM delay line */

	(* ram_style="block" *) reg [ADC_DATA_WIDTH_BIT-1:0] ch1_delay_line  [0:ACTUAL_BRAM_DEPTH-1];
	(* ram_style="block" *) reg [ADC_DATA_WIDTH_BIT-1:0] ch2_delay_line  [0:ACTUAL_BRAM_DEPTH-1];
	(* ram_style="block" *) reg [ADC_DATA_WIDTH_BIT-1:0] ch3_delay_line  [0:ACTUAL_BRAM_DEPTH-1];
	(* ram_style="block" *) reg [ADC_DATA_WIDTH_BIT-1:0] ch4_delay_line  [0:ACTUAL_BRAM_DEPTH-1];
	(* ram_style="block" *) reg [ADC_DATA_WIDTH_BIT-1:0] ch5_delay_line  [0:ACTUAL_BRAM_DEPTH-1];
	(* ram_style="block" *) reg [ADC_DATA_WIDTH_BIT-1:0] ch6_delay_line  [0:ACTUAL_BRAM_DEPTH-1];
	(* ram_style="block" *) reg [ADC_DATA_WIDTH_BIT-1:0] ch7_delay_line  [0:ACTUAL_BRAM_DEPTH-1];
	(* ram_style="block" *) reg [ADC_DATA_WIDTH_BIT-1:0] ch8_delay_line  [0:ACTUAL_BRAM_DEPTH-1];
	(* ram_style="block" *) reg [ADC_DATA_WIDTH_BIT-1:0] ch9_delay_line  [0:ACTUAL_BRAM_DEPTH-1];
	(* ram_style="block" *) reg [ADC_DATA_WIDTH_BIT-1:0] ch10_delay_line [0:ACTUAL_BRAM_DEPTH-1];
	(* ram_style="block" *) reg [ADC_DATA_WIDTH_BIT-1:0] ch11_delay_line [0:ACTUAL_BRAM_DEPTH-1];
	(* ram_style="block" *) reg [ADC_DATA_WIDTH_BIT-1:0] ch12_delay_line [0:ACTUAL_BRAM_DEPTH-1];
	(* ram_style="block" *) reg [ADC_DATA_WIDTH_BIT-1:0] ch13_delay_line [0:ACTUAL_BRAM_DEPTH-1];
	(* ram_style="block" *) reg [ADC_DATA_WIDTH_BIT-1:0] ch14_delay_line [0:ACTUAL_BRAM_DEPTH-1];
	(* ram_style="block" *) reg [ADC_DATA_WIDTH_BIT-1:0] ch15_delay_line [0:ACTUAL_BRAM_DEPTH-1];
	(* ram_style="block" *) reg [ADC_DATA_WIDTH_BIT-1:0] ch16_delay_line [0:ACTUAL_BRAM_DEPTH-1];

	reg [ADC_DATA_WIDTH_BIT-1:0] bram_channel_pdelay_data [0: ADC_CHANNEL_COUNT-1];  /* [i] for channel i+1*/
	reg [ADC_DATA_WIDTH_BIT-1:0] axis_received_data_unpacking [0: ADC_CHANNEL_COUNT-1];

	reg [C_S_AXIS_TDATA_WIDTH-1:0]	data_frame1_reg = 0;
	reg [C_S_AXIS_TDATA_WIDTH-1:0]	data_frame2_reg = 0;
	reg [C_S_AXIS_TDATA_WIDTH-1:0]	data_frame3_reg = 0;
	reg [C_S_AXIS_TDATA_WIDTH-1:0]	data_frame4_reg = 0;
	reg [C_S_AXIS_TDATA_WIDTH-1:0]	data_frame5_reg = 0;
	reg [C_S_AXIS_TDATA_WIDTH-1:0]	data_frame6_reg = 0;
	reg [C_S_AXIS_TDATA_WIDTH-1:0]	data_frame7_reg = 0;
	reg [C_S_AXIS_TDATA_WIDTH-1:0]	data_frame8_reg = 0;

	reg [DELAY_LINE_ADDR_SIZE-1: 0] bram_save_pointer = 0;  /* bram_save_pointer is the pointer of channel(i+1) */
	reg [DELAY_LINE_ADDR_SIZE-1: 0] bram_read_pointer [0: ADC_CHANNEL_COUNT-1];  /* bram_read_pointer[i] is the pointer of channel(i+1) */
	reg [DELAY_LINE_ADDR_SIZE-1: 0] channel_pdelay_sync [0: ADC_CHANNEL_COUNT-1];  /* channel_pdelay_sync[i] is the pointer of channel(i+1) */

	reg [(C_S_AXI_DATA_WIDTH/2)-1: 0] max_pdelay_reg = MAXIMUM_PRE_DELAY_COUNT;

	reg  channel_refreshed = FALSE;  /* indicate channels are refreshed */

	reg [C_S_AXIS_TDATA_WIDTH - 1: 0] axis_receive_buffer[0: FRAME_WORD_DATA_NUMBER-1];
	reg [AXIS_RECEIVE_BUFFER_ADDR_SIZE - 1: 0] axis_received_count = 0;

	reg [3: 0] axis_state = AXIS_WAIT_FOR_DATA_HEADER;
	reg freeze_sync = FALSE;
	reg software_rst_sync = FALSE;
	reg axis_send_busy_sync = FALSE;
	
	reg freezed_reg = FALSE;
	reg send_trigger_reg = FALSE;

	assign freezed = freezed_reg;
	assign send_trigger = send_trigger_reg;
	assign refreshed = channel_refreshed;

	assign max_pdelay = max_pdelay_reg;

	assign data_frame1 = data_frame1_reg;
	assign data_frame2 = data_frame2_reg;
	assign data_frame3 = data_frame3_reg;
	assign data_frame4 = data_frame4_reg;
	assign data_frame5 = data_frame5_reg;
	assign data_frame6 = data_frame6_reg;
	assign data_frame7 = data_frame7_reg;
	assign data_frame8 = data_frame8_reg;

	assign S_AXIS_TREADY = (axis_state == AXIS_WAIT_FOR_DATA_TAILER || 
						    axis_state == AXIS_RECEIVE_DATA || 
							axis_state == AXIS_WAIT_FOR_DATA_TAILER);

	`define PRE_DELAY_S00_AXIS_HAND_SHACK  (S_AXIS_TREADY && S_AXIS_TVALID)

	/* -------------------------------------------------------------------------- */
	/* --------------------------------- SYNC ----------------------------------- */
	/* -------------------------------------------------------------------------- */

	integer i;

	always @(posedge S_AXIS_ACLK) begin
		if (S_AXIS_ARESETN == 1'b0) begin
			for (i = 0; i < ADC_CHANNEL_COUNT; i = i + 1) channel_pdelay_sync[i] <= 0;
			freeze_sync <= FALSE;
			software_rst_sync <= FALSE;
			max_pdelay_reg <= ACTUAL_MAXIMUM_PRE_DELAY;
			axis_send_busy_sync <= FALSE;
		end else begin
			
			/* Channel Pre-delay */

			/* Channel 1 & Channel 2 */
			if (pdelay_ch1_ch2[15: 0] <= ACTUAL_MAXIMUM_PRE_DELAY) channel_pdelay_sync[0] <= pdelay_ch1_ch2[15: 0];
			else channel_pdelay_sync[0] <= ACTUAL_MAXIMUM_PRE_DELAY;
			if (pdelay_ch1_ch2[31: 16] <= ACTUAL_MAXIMUM_PRE_DELAY) channel_pdelay_sync[1] <= pdelay_ch1_ch2[31: 16];
			else channel_pdelay_sync[1] <= ACTUAL_MAXIMUM_PRE_DELAY;
			/* Channel 3 & Channel 4 */
			if (pdelay_ch3_ch4[15: 0] <= ACTUAL_MAXIMUM_PRE_DELAY) channel_pdelay_sync[2] <= pdelay_ch3_ch4[15: 0];
			else channel_pdelay_sync[2] <= ACTUAL_MAXIMUM_PRE_DELAY;
			if (pdelay_ch3_ch4[31: 16] <= ACTUAL_MAXIMUM_PRE_DELAY) channel_pdelay_sync[3] <= pdelay_ch3_ch4[31: 16];
			else channel_pdelay_sync[3] <= ACTUAL_MAXIMUM_PRE_DELAY;
			/* Channel 5 & Channel 6 */
			if (pdelay_ch5_ch6[15: 0] <= ACTUAL_MAXIMUM_PRE_DELAY) channel_pdelay_sync[4] <= pdelay_ch5_ch6[15: 0];
			else channel_pdelay_sync[4] <= ACTUAL_MAXIMUM_PRE_DELAY;
			if (pdelay_ch5_ch6[31: 16] <= ACTUAL_MAXIMUM_PRE_DELAY) channel_pdelay_sync[5] <= pdelay_ch5_ch6[31: 16];
			else channel_pdelay_sync[5] <= ACTUAL_MAXIMUM_PRE_DELAY;
			/* Channel 7 & Channel 8 */
			if (pdelay_ch7_ch8[15: 0] <= ACTUAL_MAXIMUM_PRE_DELAY) channel_pdelay_sync[6] <= pdelay_ch7_ch8[15: 0];
			else channel_pdelay_sync[6] <= ACTUAL_MAXIMUM_PRE_DELAY;
			if (pdelay_ch7_ch8[31: 16] <= ACTUAL_MAXIMUM_PRE_DELAY) channel_pdelay_sync[7] <= pdelay_ch7_ch8[31: 16];
			else channel_pdelay_sync[7] <= ACTUAL_MAXIMUM_PRE_DELAY;
			/* Channel 9 & Channel 10 */
			if (pdelay_ch9_ch10[15: 0] <= ACTUAL_MAXIMUM_PRE_DELAY) channel_pdelay_sync[8] <= pdelay_ch9_ch10[15: 0];
			else channel_pdelay_sync[8] <= ACTUAL_MAXIMUM_PRE_DELAY;
			if (pdelay_ch9_ch10[31: 16] <= ACTUAL_MAXIMUM_PRE_DELAY) channel_pdelay_sync[9] <= pdelay_ch9_ch10[31: 16];
			else channel_pdelay_sync[9] <= ACTUAL_MAXIMUM_PRE_DELAY;
			/* Channel 11 & Channel 12 */
			if (pdelay_ch11_ch12[15: 0] <= ACTUAL_MAXIMUM_PRE_DELAY) channel_pdelay_sync[10] <= pdelay_ch11_ch12[15: 0];
			else channel_pdelay_sync[10] <= ACTUAL_MAXIMUM_PRE_DELAY;
			if (pdelay_ch11_ch12[31: 16] <= ACTUAL_MAXIMUM_PRE_DELAY) channel_pdelay_sync[11] <= pdelay_ch11_ch12[31: 16];
			else channel_pdelay_sync[11] <= ACTUAL_MAXIMUM_PRE_DELAY;
			/* Channel 13 & Channel 14 */
			if (pdelay_ch13_ch14[15: 0] <= ACTUAL_MAXIMUM_PRE_DELAY) channel_pdelay_sync[12] <= pdelay_ch13_ch14[15: 0];
			else channel_pdelay_sync[12] <= ACTUAL_MAXIMUM_PRE_DELAY;
			if (pdelay_ch13_ch14[31: 16] <= ACTUAL_MAXIMUM_PRE_DELAY) channel_pdelay_sync[13] <= pdelay_ch13_ch14[31: 16];
			else channel_pdelay_sync[13] <= ACTUAL_MAXIMUM_PRE_DELAY;
			/* Channel 15 & Channel 16 */
			if (pdelay_ch15_ch16[15: 0] <= ACTUAL_MAXIMUM_PRE_DELAY) channel_pdelay_sync[14] <= pdelay_ch15_ch16[15: 0];
			else channel_pdelay_sync[14] <= ACTUAL_MAXIMUM_PRE_DELAY;
			if (pdelay_ch15_ch16[31: 16] <= ACTUAL_MAXIMUM_PRE_DELAY) channel_pdelay_sync[15] <= pdelay_ch15_ch16[31: 16];
			else channel_pdelay_sync[15] <= ACTUAL_MAXIMUM_PRE_DELAY;

			/* flags */

			freeze_sync <= freeze;
			max_pdelay_reg <= ACTUAL_MAXIMUM_PRE_DELAY;
			software_rst_sync <= software_rst;
			axis_send_busy_sync <= axis_send_busy;
		end
	end

	/* -------------------------------------------------------------------------- */
	/* --------------------------------- STATUS --------------------------------- */
	/* -------------------------------------------------------------------------- */

	/* ---------------------------------- FLAGS --------------------------------- */

	always @(posedge S_AXIS_ACLK) begin
		if (S_AXIS_ARESETN == 1'b0 || software_rst_sync) begin
			axis_state <= AXIS_WAIT_FOR_DATA_HEADER;
		end else begin
			case (axis_state)
				AXIS_WAIT_FOR_DATA_HEADER: begin
					if (`PRE_DELAY_S00_AXIS_HAND_SHACK) begin
						if (S_AXIS_TDATA == FRAME_HEADER) axis_state <= AXIS_RECEIVE_DATA;
						else axis_state <= axis_state;
					end else begin
						axis_state <= axis_state;
					end
				end
				AXIS_RECEIVE_DATA: begin
					if (`PRE_DELAY_S00_AXIS_HAND_SHACK) begin
						if (axis_received_count >= FRAME_WORD_DATA_NUMBER - 1) axis_state <= AXIS_WAIT_FOR_DATA_TAILER;
						else axis_state <= axis_state;
					end else begin
						if (axis_received_count >= FRAME_WORD_DATA_NUMBER) axis_state <= AXIS_WAIT_FOR_DATA_TAILER;
						else axis_state <= axis_state;
					end
				end
				AXIS_WAIT_FOR_DATA_TAILER: begin
					if (`PRE_DELAY_S00_AXIS_HAND_SHACK) begin
						if (S_AXIS_TDATA == FRAME_TAILER) axis_state <= AXIS_UNPACKING;
						else axis_state <= AXIS_WAIT_FOR_DATA_HEADER;  /* ERROR condition */
					end else begin
						axis_state <= axis_state;
					end
				end
				AXIS_UNPACKING: begin
					axis_state <= AXIS_PUSH_BRAM;
				end
				AXIS_PUSH_BRAM: begin
					axis_state <= AXIS_CHECK_FREEZE;
				end
				AXIS_CHECK_FREEZE: begin
					if (freeze_sync) axis_state <= AXIS_WAIT_FOR_DATA_HEADER;
					else begin
						if (refreshed) axis_state <= AXIS_READ;
						else axis_state <= AXIS_WAIT_FOR_DATA_HEADER;
					end
				end
				AXIS_READ: begin
					axis_state <= AXIS_PACKAGE;
				end
				AXIS_PACKAGE: begin
					axis_state <= AXIS_SEND_DATA_WAIT_IDLE;
				end
				AXIS_SEND_DATA_WAIT_IDLE: begin
					if (!axis_send_busy_sync) axis_state <= AXIS_SEND_DATA_TRIGGER;
					else axis_state <= axis_state;
				end
				AXIS_SEND_DATA_TRIGGER: begin
					if (send_trigger_reg) axis_state <= AXIS_SEND_DATA_WAIT_START;
					else axis_state <= axis_state;
				end
				AXIS_SEND_DATA_WAIT_START: begin
					if (axis_send_busy_sync) axis_state <= AXIS_WAIT_FOR_DATA_HEADER;
					else axis_state <= axis_state;
				end
				default: axis_state <= AXIS_WAIT_FOR_DATA_HEADER;
			endcase
		end
	end

	/* ------------------------------ REGISTERS ------------------------------- */

	always @(posedge S_AXIS_ACLK) begin
		if (S_AXIS_ARESETN == 1'b0 || software_rst_sync) begin
			for (i = 0; i < ADC_CHANNEL_COUNT; i = i + 1) begin
				bram_read_pointer[i] <= 0;
				bram_channel_pdelay_data[i] <= 0;
				axis_received_data_unpacking[i] <= 0;
			end
			bram_save_pointer <= 0;
			data_frame1_reg <= 0;
			data_frame2_reg <= 0;
			data_frame3_reg <= 0;
			data_frame4_reg <= 0;
			data_frame5_reg <= 0;
			data_frame6_reg <= 0;
			data_frame7_reg <= 0;
			data_frame8_reg <= 0;
			axis_received_count <= 0;
			channel_refreshed <= FALSE;
			freezed_reg <= FALSE;
			send_trigger_reg <= FALSE;
		end else begin
			case (axis_state)
				AXIS_WAIT_FOR_DATA_HEADER: begin
					axis_received_count <= 0;
					send_trigger_reg <= FALSE;
				end
				AXIS_RECEIVE_DATA: begin
					send_trigger_reg <= FALSE;
					if (`PRE_DELAY_S00_AXIS_HAND_SHACK) begin
						/* push data to axis_receive_buffer */
						if (axis_received_count <= FRAME_WORD_DATA_NUMBER - 1) begin
							axis_received_count <= axis_received_count + 1;
							axis_receive_buffer[axis_received_count] <= S_AXIS_TDATA;
						end else begin
							axis_received_count <= axis_received_count;
						end
					end else begin
						axis_received_count <= axis_received_count;
					end
				end
				AXIS_WAIT_FOR_DATA_TAILER: begin
					send_trigger_reg <= FALSE;
				end
				AXIS_UNPACKING: begin
					for (i = 0; i < FRAME_WORD_DATA_NUMBER; i = i + 1) begin
						axis_received_data_unpacking[2*i] <= axis_receive_buffer[i][15: 0];
						axis_received_data_unpacking[2*i+1] <= axis_receive_buffer[i][31: 16];
					end
				end
				AXIS_PUSH_BRAM: begin
					send_trigger_reg <= FALSE;
					/* ------------ Update Read Pointer ----------- */
					for (i = 0; i < ADC_CHANNEL_COUNT; i = i + 1) begin
						if (bram_save_pointer >= channel_pdelay_sync[i]) bram_read_pointer[i] <= bram_save_pointer - channel_pdelay_sync[i];
						else bram_read_pointer[i] <= ACTUAL_BRAM_DEPTH - (channel_pdelay_sync[i] - bram_save_pointer);
					end
					/* ------------ Update Save Pointer ---------- */
					if (bram_save_pointer >= (ACTUAL_BRAM_DEPTH - 1)) begin
						bram_save_pointer <= 0;  /* update pointer */
						channel_refreshed <= TRUE;  /* update refreshed flag */
					end else begin
						bram_save_pointer <= bram_save_pointer + 1;  /* update pointer */
						channel_refreshed <= channel_refreshed;
					end
					/* ------------ Save data to BRAM ----------- */
					ch1_delay_line [bram_save_pointer] <= axis_received_data_unpacking[0];
					ch2_delay_line [bram_save_pointer] <= axis_received_data_unpacking[1];
					ch3_delay_line [bram_save_pointer] <= axis_received_data_unpacking[2];
					ch4_delay_line [bram_save_pointer] <= axis_received_data_unpacking[3];
					ch5_delay_line [bram_save_pointer] <= axis_received_data_unpacking[4];
					ch6_delay_line [bram_save_pointer] <= axis_received_data_unpacking[5];
					ch7_delay_line [bram_save_pointer] <= axis_received_data_unpacking[6];
					ch8_delay_line [bram_save_pointer] <= axis_received_data_unpacking[7];
					ch9_delay_line [bram_save_pointer] <= axis_received_data_unpacking[8];
					ch10_delay_line[bram_save_pointer] <= axis_received_data_unpacking[9];
					ch11_delay_line[bram_save_pointer] <= axis_received_data_unpacking[10];
					ch12_delay_line[bram_save_pointer] <= axis_received_data_unpacking[11];
					ch13_delay_line[bram_save_pointer] <= axis_received_data_unpacking[12];
					ch14_delay_line[bram_save_pointer] <= axis_received_data_unpacking[13];
					ch15_delay_line[bram_save_pointer] <= axis_received_data_unpacking[14];
					ch16_delay_line[bram_save_pointer] <= axis_received_data_unpacking[15];
				end
				AXIS_CHECK_FREEZE: begin
					send_trigger_reg <= FALSE;
					if (freeze_sync) freezed_reg <= TRUE;
					else freezed_reg <= FALSE;
				end
				AXIS_READ: begin
					send_trigger_reg <= FALSE;
					bram_channel_pdelay_data[0]  <= ch1_delay_line [bram_read_pointer[0]];
					bram_channel_pdelay_data[1]  <= ch2_delay_line [bram_read_pointer[1]];
					bram_channel_pdelay_data[2]  <= ch3_delay_line [bram_read_pointer[2]];
					bram_channel_pdelay_data[3]  <= ch4_delay_line [bram_read_pointer[3]];
					bram_channel_pdelay_data[4]  <= ch5_delay_line [bram_read_pointer[4]];
					bram_channel_pdelay_data[5]  <= ch6_delay_line [bram_read_pointer[5]];
					bram_channel_pdelay_data[6]  <= ch7_delay_line [bram_read_pointer[6]];
					bram_channel_pdelay_data[7]  <= ch8_delay_line [bram_read_pointer[7]];
					bram_channel_pdelay_data[8]  <= ch9_delay_line [bram_read_pointer[8]];
					bram_channel_pdelay_data[9]  <= ch10_delay_line[bram_read_pointer[9]];
					bram_channel_pdelay_data[10] <= ch11_delay_line[bram_read_pointer[10]];
					bram_channel_pdelay_data[11] <= ch12_delay_line[bram_read_pointer[11]];
					bram_channel_pdelay_data[12] <= ch13_delay_line[bram_read_pointer[12]];
					bram_channel_pdelay_data[13] <= ch14_delay_line[bram_read_pointer[13]];
					bram_channel_pdelay_data[14] <= ch15_delay_line[bram_read_pointer[14]];
					bram_channel_pdelay_data[15] <= ch16_delay_line[bram_read_pointer[15]];
				end
				AXIS_PACKAGE: begin
					send_trigger_reg <= FALSE;
					data_frame1_reg <= {bram_channel_pdelay_data[1], bram_channel_pdelay_data[0]};
					data_frame2_reg <= {bram_channel_pdelay_data[3], bram_channel_pdelay_data[2]};
					data_frame3_reg <= {bram_channel_pdelay_data[5], bram_channel_pdelay_data[4]};
					data_frame4_reg <= {bram_channel_pdelay_data[7], bram_channel_pdelay_data[6]};
					data_frame5_reg <= {bram_channel_pdelay_data[9], bram_channel_pdelay_data[8]};
					data_frame6_reg <= {bram_channel_pdelay_data[11], bram_channel_pdelay_data[10]};
					data_frame7_reg <= {bram_channel_pdelay_data[13], bram_channel_pdelay_data[12]};
					data_frame8_reg <= {bram_channel_pdelay_data[15], bram_channel_pdelay_data[14]};
				end

				AXIS_SEND_DATA_WAIT_IDLE: begin
					send_trigger_reg <= FALSE;
				end
				AXIS_SEND_DATA_TRIGGER: begin
					send_trigger_reg <= TRUE;  /* trigger! */
				end
				AXIS_SEND_DATA_WAIT_START: begin
					if (axis_send_busy_sync) send_trigger_reg <= FALSE;
					else send_trigger_reg <= TRUE;
				end
				default: begin
					for (i = 0; i < ADC_CHANNEL_COUNT; i = i + 1) begin
						bram_read_pointer[i] <= 0;
						bram_channel_pdelay_data[i] <= 0;
						axis_received_data_unpacking[i] <= 0;
					end
					bram_save_pointer <= 0;
					data_frame1_reg <= 0;
					data_frame2_reg <= 0;
					data_frame3_reg <= 0;
					data_frame4_reg <= 0;
					data_frame5_reg <= 0;
					data_frame6_reg <= 0;
					data_frame7_reg <= 0;
					data_frame8_reg <= 0;
					axis_received_count <= 0;
					channel_refreshed <= FALSE;
					freezed_reg <= FALSE;
					send_trigger_reg <= FALSE;
				end
			endcase
		end
	end

	endmodule
