
`timescale 1 ns / 1 ps

	module vfir_v1_0_S00_AXIS #
	(
		// Users to add parameters here

		parameter integer BRAM_DATA_WIDTH	     = 32,   /* BRAM data width */
		parameter integer MAXIMUM_FILTER_LENGTH  = 512,

		parameter integer C_S_AXI_DATA_WIDTH     = 32,

		parameter [31: 0] FRAME_HEADER           = 32'h0000_FFF0,
		parameter [31: 0] FRAME_TAILER           = 32'h0000_FF0F,

		// User parameters ends
		// Do not modify the parameters beyond this line

		// AXI4Stream sink: Data Width
		parameter integer C_S_AXIS_TDATA_WIDTH	= 32
	)
	(
		/* Internal Interface */

		input wire [C_S_AXI_DATA_WIDTH-1:0] fir_length,  /* FIR Length */
		input wire [C_S_AXI_DATA_WIDTH-1:0] fir_scale,  /* FIR Scale */

		input wire run_enable,  /* HIGH = Run enable */
		input wire software_rst,  /* HIGH = Reset */

		input wire len_update_trigger,  /* all update, clear data in fir bank, rising edge trigger */
		input wire coef_update_trigger,  /* coefficient & scale update, will not clear data, rising edge trigger */

		output wire refreshed,  /* HIGH = indicate FIR data line refreshed */
		output wire len_updated,  /* HIGH = indicate LEN update completed */
		output wire coef_updated,  /* HIGH = indicate Coefficient update completed */

		input wire axis_sending_busy,  /* HIGH = axis master is sending */
		output wire axis_trigger_sending,  /* Trigger axis master to send, rising edge trigger */
		output wire signed [C_S_AXIS_TDATA_WIDTH-1:0] fir_output,  /* FIR output */
		
		/* BRAM Interface */

		input wire  [BRAM_DATA_WIDTH-1:0] bram_dout,

		output wire [BRAM_DATA_WIDTH-1:0] bram_addr,
		output wire [BRAM_DATA_WIDTH-1:0] bram_din,  /* not in use */

		output wire [(BRAM_DATA_WIDTH/8)-1:0] bram_we,

		output wire bram_clk,  /* assign to AXIS_ACLK */
		output wire bram_en,
		output wire bram_rst,  /* Do not used */

		/* AXI4-Stream Interface */

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
		input wire  S_AXIS_TLAST,  /* Do not used */
		// Data is in valid
		input wire  S_AXIS_TVALID
	);
	
	function integer clogb2 (input integer bit_depth);
	  begin
	    for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
	      bit_depth = bit_depth >> 1;
	  end
	endfunction

	localparam TRUE = 1'b1,
	           FALSE = 1'b0;

	localparam HIGH = 1'b1,
	           LOW = 1'b0;

	localparam ADC_DATA_WIDTH = 16;
	localparam ADC_CHANNELS = 16;

	localparam FRAME_WORD_NUMBER                = 10;  /* Data Header & Data Tailer included */
	localparam FRAME_WORD_DATA_NUMBER           = FRAME_WORD_NUMBER - 2;   /* Data Header & Data Tailer excluded */

	localparam MAXIMUM_COEFFICIENT_NUMBER = MAXIMUM_FILTER_LENGTH * ADC_CHANNELS;

	localparam BRAM_READING_WE = {(BRAM_DATA_WIDTH/8){1'b0}};

	localparam MUL_RESULT_BIT_NUM = BRAM_DATA_WIDTH + ADC_DATA_WIDTH + 1;
	localparam BRAM_ADDR_INCREMENT = BRAM_DATA_WIDTH/8;

	localparam AXIS_RECEIVE_BUFFER_ADDR_SIZE = clogb2(FRAME_WORD_DATA_NUMBER + 1);
	localparam FIR_LENGTH_BIT_NUM = clogb2(MAXIMUM_FILTER_LENGTH + 2);  /* 512 */
	localparam EXTERNAL_BRAM_ADDR_SIZE = clogb2(MAXIMUM_COEFFICIENT_NUMBER + 2);  /* 512 * 16 */

	localparam INVALID_COEF_POINTER = MAXIMUM_FILTER_LENGTH;  /* INVALID COEF_POINTER */
	
	/* AXI-Stream & FIR States */

	localparam [3:0] AXIS_CHECK_RUN_STATUS        = 4'd0,  /* Check run stage, wait here */
	                 AXIS_WAIT_FOR_DATA_HEADER    = 4'd1,  /* Wait for data header, wait here */
	                 AXIS_RECEIVE_DATA            = 4'd2,  /* Receive data */
					 AXIS_WAIT_FOR_DATA_TAILER    = 4'd3,  /* Wait for data tailer, wait here */
					 AXIS_UNPACKING               = 4'd4,  /* Unpacking */
					 AXIS_CHECK_FIR_READY         = 4'd5,  /* Check if FIR Filter Bank in IDLE, wait here */
					 AXIS_PUSH_TO_FIR_LINE        = 4'd6,  /* Push data to FIR Data Line */
					 AXIS_TRIGGER_FIR             = 4'd7,  /* Trigger FIR calculation */
					 AXIS_WAIT_FOR_FIR_START      = 4'd8;  /* Wait for FIR start */

	localparam [3:0] FIR_WAIT_FOR_TRIGGER         = 4'd0,  /* IDLE: Wait for trigger */
	                 FIR_CHECK_COEF_UPDATE        = 4'd1,  /* Check coefficient update, wait here */
					 FIR_PIPELINE_CALCULATION     = 4'd2,  /* FIR calculate */
					 FIR_GET_SCALE_RESULT         = 4'd3,  /* Unpacking raw result */
					 FIR_WAIT_SENDING_IDLE        = 4'd4,  /* Wait AXI-S master ready, wait here */
					 FIR_TRIGGER_SENDING          = 4'd5,  /* Trigger sending */
					 FIR_WAIT_FOR_SENDING_START   = 4'd6;  /* Wait for sending start */

	localparam [3:0] LEN_UPDATE_WAIT_FOR_TRIGGER       = 4'd0,  /* Wait for update */
					 LEN_MAKE_SYSTEM_UPDATE_RESET      = 4'd1,  /* Make system reset */
					 LEN_CHECK_RESET_FLAGS             = 4'd2,  /* Check system reset flags */
					 LEN_UPDATE_LENGTH                    = 4'd3,  /* Update Length */
					 LEN_RELEASE_COEF_UPDATE_RESET     = 4'd4,  /* Release coef update */
					 LEN_TRIGGER_COEF_UPDATE           = 4'd5,  /* Trigger coef update */
					 LEN_WAIT_COEF_UPDATE_START        = 4'd6,  /* Wait for coef update start */
					 LEN_WAIT_COEF_UPDATE_DOWN         = 4'd7,  /* Wait for coef update down */
					 LEN_RELEASE_SYSTEM_UPDATE_RESET   = 4'd8;  /* Release system reset */

	localparam [3:0] COEF_UPDATE_WAIT_FOR_TRIGGER      = 4'd0,  /* Wait for update */
		    		 COEF_UPDATE_CHECK_FIR_CALCULATING = 4'd1,  /* Check if FIR is calculating, wait here */
					 COEF_UPDATE_SCALE                 = 4'd2,  /* Update Coefficient */
					 COEF_UPDATE_COEFFICIENT           = 4'd3;  /* Update Scale */

	/* ------------------------- System Related --------------------------- */

	reg software_rst_sync = FALSE;
	reg run_enable_sync = FALSE;

	reg refreshed_reg = FALSE;

	reg coef_update_trigger_sync1 = FALSE;
	reg coef_update_trigger_sync2 = FALSE;
	reg len_update_trigger_sync1 = FALSE;
	reg len_update_trigger_sync2 = FALSE;

	reg coef_updated_reg = FALSE;
	reg len_updated_reg = FALSE;

	reg coef_triggered_by_len = FALSE;  /* in LEN, TRUE = trigger coef update */

	wire len_update_is_triggered = (len_update_trigger_sync1 && !len_update_trigger_sync2);
	wire coef_update_is_triggered = ((coef_update_trigger_sync1 && !coef_update_trigger_sync2) || coef_triggered_by_len);  /* can also be triggered by len update */

	assign coef_updated = coef_updated_reg;
	assign len_updated = len_updated_reg;

	reg [FIR_LENGTH_BIT_NUM-1:0] fir_length_updated = MAXIMUM_FILTER_LENGTH;  /* FIR Length (use this in calculation) */
	reg signed [C_S_AXI_DATA_WIDTH-1:0] fir_scale_updated = 0;  /* FIR Scale (use this in calculation) */

	reg [EXTERNAL_BRAM_ADDR_SIZE-1:0] fir_coef_number_updated = MAXIMUM_COEFFICIENT_NUMBER;  /* coef number (use this in loading) */

	/* ------------------------ AXI-Stream Related ----------------------- */
	
	reg signed [ADC_DATA_WIDTH-1:0] current_adc_channel_data [ADC_CHANNELS-1:0];  /* [i] is channel i+1 */
	reg [C_S_AXIS_TDATA_WIDTH - 1: 0] axis_receive_buffer[0: FRAME_WORD_DATA_NUMBER-1];  /* AXI-S slave buffer */

	reg trigger_fir_reg = FALSE;  /* HIGH = Trigger FIR calculation */

	reg [AXIS_RECEIVE_BUFFER_ADDR_SIZE - 1: 0] axis_received_count = 0;

	reg [3:0] axis_state = AXIS_CHECK_RUN_STATUS;

	/* ------------------------ FIR Bank Related ----------------------- */

	/* Internal FIR Filter Signal Bank */

	(* ram_style="block" *) reg signed [ADC_DATA_WIDTH-1:0] fir_data_line_ch1  [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [ADC_DATA_WIDTH-1:0] fir_data_line_ch2  [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [ADC_DATA_WIDTH-1:0] fir_data_line_ch3  [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [ADC_DATA_WIDTH-1:0] fir_data_line_ch4  [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [ADC_DATA_WIDTH-1:0] fir_data_line_ch5  [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [ADC_DATA_WIDTH-1:0] fir_data_line_ch6  [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [ADC_DATA_WIDTH-1:0] fir_data_line_ch7  [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [ADC_DATA_WIDTH-1:0] fir_data_line_ch8  [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [ADC_DATA_WIDTH-1:0] fir_data_line_ch9  [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [ADC_DATA_WIDTH-1:0] fir_data_line_ch10 [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [ADC_DATA_WIDTH-1:0] fir_data_line_ch11 [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [ADC_DATA_WIDTH-1:0] fir_data_line_ch12 [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [ADC_DATA_WIDTH-1:0] fir_data_line_ch13 [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [ADC_DATA_WIDTH-1:0] fir_data_line_ch14 [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [ADC_DATA_WIDTH-1:0] fir_data_line_ch15 [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [ADC_DATA_WIDTH-1:0] fir_data_line_ch16 [MAXIMUM_FILTER_LENGTH-1:0];

	reg [FIR_LENGTH_BIT_NUM-1:0] fir_data_line_pointer = 0;  /* current fir data line pointer (newest data pointer+1) */
	reg [FIR_LENGTH_BIT_NUM-1:0] last_fir_data_line_pointer = 0;  /* last fir line pointer (newest data pointer) */

	reg [FIR_LENGTH_BIT_NUM-1:0] fir_coef_calculate_pointer = 0;  /* fir calculate pointer for coef */
	reg [FIR_LENGTH_BIT_NUM-1:0] fir_data_calculate_pointer = 0;  /* fir calculate pointer for data */

	reg [3:0] fir_state = FIR_WAIT_FOR_TRIGGER;

	reg axis_trigger_sending_reg = FALSE;  /* Rising edge to trigger AXI-Stream master sending */
	reg axis_sending_busy_sync = FALSE;  /* sync to axis_sending_busy */

	reg signed [C_S_AXIS_TDATA_WIDTH-1:0] fir_output_reg = 0;  /* fir_output */

	reg signed [ADC_DATA_WIDTH-1:0] fir_data_raw [ADC_CHANNELS-1:0];  /* current fir data */
	reg signed [ADC_DATA_WIDTH-1:0] fir_data [ADC_CHANNELS-1:0];  /* current fir data */

	reg signed [BRAM_DATA_WIDTH-1:0] fir_coef_raw [ADC_CHANNELS-1:0];  /* current fir coef */
	reg signed [BRAM_DATA_WIDTH-1:0] fir_coef [ADC_CHANNELS-1:0];  /* current fir coef */

	reg signed [MUL_RESULT_BIT_NUM-1:0] fir_mul_result_stage0 [ADC_CHANNELS-1:0];  /* stage 0, 16 */
	reg signed [MUL_RESULT_BIT_NUM-1:0] fir_mul_result_stage1 [ADC_CHANNELS-1:0];  /* stage 1, 16 */
	reg signed [MUL_RESULT_BIT_NUM-1:0] fir_mul_result_stage2 [ADC_CHANNELS/2-1:0];  /* stage 2, 8 */
	reg signed [MUL_RESULT_BIT_NUM-1:0] fir_mul_result_stage3 [ADC_CHANNELS/4-1:0];  /* stage 3, 4 */
	reg signed [MUL_RESULT_BIT_NUM-1:0] fir_mul_result_stage4 [ADC_CHANNELS/8-1:0];  /* stage 4, 2 */
	reg signed [MUL_RESULT_BIT_NUM-1:0] fir_mul_result_stage5 = 0;  /* stage 5, 1 */
	reg signed [MUL_RESULT_BIT_NUM-1:0] fir_raw_output = 0;  /* stage 5, output */

	reg fir_stage01_complete_flag = FALSE;  /* TRUE = stage 0.1 complete */
	reg fir_stage_latency_complete_flag = FALSE; /* TRUE = stage 0 complete */
	reg fir_stage02_complete_flag = FALSE;  /* TRUE = stage 0.2 complete */
	reg fir_stage1_complete_flag = FALSE;  /* TRUE = stage 1 complete */
	reg fir_stage2_complete_flag = FALSE;  /* TRUE = stage 2 complete */
	reg fir_stage3_complete_flag = FALSE;  /* TRUE = stage 3 complete */
	reg fir_stage4_complete_flag = FALSE;  /* TRUE = stage 4 complete */
	reg fir_stage5_complete_flag = FALSE;  /* TRUE = stage 5 complete */
	reg fir_stage_output_complete_flag = FALSE;  /* TRUE = all stage complete */
	reg fir_pipeline_complete_flag = FALSE;  /* TRUE = pipeline complete */

	wire fir_busy = (fir_state != FIR_WAIT_FOR_TRIGGER);
	wire fir_is_calculating = (fir_state == FIR_PIPELINE_CALCULATION);
	
	assign fir_output = fir_output_reg;
	
	/* --------------------- Update Module Related -------------------- */

	/* Internal FIR Filter Coefficient Bank */

	(* ram_style="block" *) reg signed [BRAM_DATA_WIDTH-1:0] fir_coef_line_ch1  [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [BRAM_DATA_WIDTH-1:0] fir_coef_line_ch2  [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [BRAM_DATA_WIDTH-1:0] fir_coef_line_ch3  [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [BRAM_DATA_WIDTH-1:0] fir_coef_line_ch4  [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [BRAM_DATA_WIDTH-1:0] fir_coef_line_ch5  [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [BRAM_DATA_WIDTH-1:0] fir_coef_line_ch6  [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [BRAM_DATA_WIDTH-1:0] fir_coef_line_ch7  [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [BRAM_DATA_WIDTH-1:0] fir_coef_line_ch8  [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [BRAM_DATA_WIDTH-1:0] fir_coef_line_ch9  [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [BRAM_DATA_WIDTH-1:0] fir_coef_line_ch10 [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [BRAM_DATA_WIDTH-1:0] fir_coef_line_ch11 [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [BRAM_DATA_WIDTH-1:0] fir_coef_line_ch12 [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [BRAM_DATA_WIDTH-1:0] fir_coef_line_ch13 [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [BRAM_DATA_WIDTH-1:0] fir_coef_line_ch14 [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [BRAM_DATA_WIDTH-1:0] fir_coef_line_ch15 [MAXIMUM_FILTER_LENGTH-1:0];
	(* ram_style="block" *) reg signed [BRAM_DATA_WIDTH-1:0] fir_coef_line_ch16 [MAXIMUM_FILTER_LENGTH-1:0];

	reg [3:0] len_update_state = LEN_UPDATE_WAIT_FOR_TRIGGER;
	reg [3:0] coef_update_state = COEF_UPDATE_WAIT_FOR_TRIGGER;

	reg update_system_reset = FALSE;  /* TRUE = Reset AXI-S & FIR */
	reg update_coef_reset = FALSE;  /* TRUE = Reset COEF */

	reg axis_have_reset = FALSE;  /* axis module have reset */
	reg fir_have_reset = FALSE;  /* fir module have reset */
	reg coef_have_reset = FALSE;  /* coef module have reset */

	reg [FIR_LENGTH_BIT_NUM-1:0] fir_length_sync = MAXIMUM_FILTER_LENGTH;
	reg signed [C_S_AXI_DATA_WIDTH-1:0] fir_scale_sync = 0;

	reg [EXTERNAL_BRAM_ADDR_SIZE-1:0] coef_loaded_count = 0;
	reg [7:0] coef_current_channel = 0;
	reg [FIR_LENGTH_BIT_NUM-1:0] coef_current_offset = 0;
	reg coef_save_enable = FALSE;  /* sync to bram_en, latency = 2 */

	reg signed [BRAM_DATA_WIDTH-1:0] bram_data = 0;  /* data from external BRAM */
	reg [EXTERNAL_BRAM_ADDR_SIZE-1:0] bram_addr_reg = 0;  /* bram address control */
	reg bram_en_reg = FALSE;  /* bram enable */

	reg bram_en_sync = FALSE;  /* bram enable (latency 1) */
	
	wire coef_update_busy = (coef_update_state != COEF_UPDATE_WAIT_FOR_TRIGGER);
	
	/* ------------------------- assigns ------------------------------- */

	assign refreshed = refreshed_reg;
	assign axis_trigger_sending = axis_trigger_sending_reg;

	assign bram_addr = bram_addr_reg;
	assign bram_en = bram_en_reg;
	assign bram_we = {(BRAM_DATA_WIDTH/8){1'b0}};
	assign bram_clk = S_AXIS_ACLK;
	assign S_AXIS_TREADY = ((axis_state == AXIS_WAIT_FOR_DATA_HEADER || 
						     axis_state == AXIS_RECEIVE_DATA || 
							 axis_state == AXIS_WAIT_FOR_DATA_TAILER) && !axis_have_reset);
	
	`define FIR_S00_AXIS_HAND_SHACK (S_AXIS_TREADY && S_AXIS_TVALID)

	integer i;

	/* -------------------------------------------------------------------------- */
	/* --------------------------- System Related ------------------------------- */
	/* -------------------------------------------------------------------------- */

	always @(posedge S_AXIS_ACLK) begin
		if (S_AXIS_ARESETN == 1'b0) begin
			software_rst_sync <= FALSE;
			run_enable_sync <= FALSE;
			axis_sending_busy_sync <= FALSE;
		end else begin
			software_rst_sync <= software_rst;
			run_enable_sync <= run_enable;
			axis_sending_busy_sync <= axis_sending_busy;
		end
	end

	/* -------------------------------------------------------------------------- */
	/* ------------------------ AXI-Stream Domain ------------------------------- */
	/* -------------------------------------------------------------------------- */

	/* -------------------------------- FLAGS ---------------------------------- */

	always @(posedge S_AXIS_ACLK) begin
		if (S_AXIS_ARESETN == 1'b0 || software_rst_sync || update_system_reset) begin
			axis_state <= AXIS_CHECK_RUN_STATUS;
			axis_have_reset <= TRUE;
		end else begin
			axis_have_reset <= FALSE;
			case (axis_state)
				AXIS_CHECK_RUN_STATUS: begin
					if (run_enable_sync) axis_state <= AXIS_WAIT_FOR_DATA_HEADER;
					else axis_state <= axis_state;
				end
				AXIS_WAIT_FOR_DATA_HEADER: begin
					if (`FIR_S00_AXIS_HAND_SHACK) begin
						if (S_AXIS_TDATA == FRAME_HEADER) axis_state <= AXIS_RECEIVE_DATA;
						else axis_state <= axis_state;
					end else begin
						axis_state <= axis_state;
					end
				end
				AXIS_RECEIVE_DATA: begin
					if (`FIR_S00_AXIS_HAND_SHACK) begin
						if (axis_received_count >= FRAME_WORD_DATA_NUMBER - 1) axis_state <= AXIS_WAIT_FOR_DATA_TAILER;
						else axis_state <= axis_state;
					end else begin
						if (axis_received_count >= FRAME_WORD_DATA_NUMBER) axis_state <= AXIS_WAIT_FOR_DATA_TAILER;
						else axis_state <= axis_state;
					end
				end
				AXIS_WAIT_FOR_DATA_TAILER: begin
					if (`FIR_S00_AXIS_HAND_SHACK) begin
						if (S_AXIS_TDATA == FRAME_TAILER) axis_state <= AXIS_UNPACKING;
						else axis_state <= AXIS_CHECK_RUN_STATUS;  /* ERROR condition */
					end else begin
						axis_state <= axis_state;
					end
				end
				AXIS_UNPACKING: begin
					axis_state <= AXIS_CHECK_FIR_READY;
				end
				AXIS_CHECK_FIR_READY: begin
					if (fir_busy) axis_state <= axis_state;
					else axis_state <= AXIS_PUSH_TO_FIR_LINE;
				end
				AXIS_PUSH_TO_FIR_LINE: begin
					axis_state <= AXIS_TRIGGER_FIR;
				end
				AXIS_TRIGGER_FIR: begin
					axis_state <= AXIS_WAIT_FOR_FIR_START;
				end
				AXIS_WAIT_FOR_FIR_START: begin
					if (fir_busy) axis_state <= AXIS_CHECK_RUN_STATUS;
					else axis_state <= axis_state;
				end
				default: axis_state <= AXIS_CHECK_RUN_STATUS;
			endcase
		end
	end

	/* ----------------------------- REGISTERS -------------------------------- */

	always @(posedge S_AXIS_ACLK) begin
		if (S_AXIS_ARESETN == 1'b0 || software_rst_sync || update_system_reset) begin
			axis_received_count <= 0;
			fir_data_line_pointer <= 0;
			last_fir_data_line_pointer <= 0;
			trigger_fir_reg <= LOW;
			refreshed_reg <= FALSE;
			for (i = 0; i < FRAME_WORD_DATA_NUMBER; i = i + 1) begin
				current_adc_channel_data[2*i] <= 0;
				current_adc_channel_data[2*i+1] <= 0;
			end
		end else begin
			case (axis_state)
				AXIS_CHECK_RUN_STATUS: begin
					trigger_fir_reg <= LOW;
				end
				AXIS_WAIT_FOR_DATA_HEADER: begin
					axis_received_count <= 0;
					trigger_fir_reg <= LOW;
				end
				AXIS_RECEIVE_DATA: begin
					trigger_fir_reg <= LOW;
					if (`FIR_S00_AXIS_HAND_SHACK) begin
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
					trigger_fir_reg <= LOW;
				end
				AXIS_UNPACKING: begin
					for (i = 0; i < FRAME_WORD_DATA_NUMBER; i = i + 1) begin
						current_adc_channel_data[2*i] <= $signed(axis_receive_buffer[i][15:0]);
						current_adc_channel_data[2*i+1] <= $signed(axis_receive_buffer[i][31:16]);
					end
				end
				AXIS_CHECK_FIR_READY: begin
					trigger_fir_reg <= LOW;
				end
				AXIS_PUSH_TO_FIR_LINE: begin
					trigger_fir_reg <= LOW;
					last_fir_data_line_pointer <= fir_data_line_pointer;  /* last pointer to newest data */
					if (fir_data_line_pointer >= fir_length_updated - 1) begin
						fir_data_line_pointer <= 0;
						refreshed_reg <= TRUE;
					end else begin
						fir_data_line_pointer <= fir_data_line_pointer + 1;
						refreshed_reg <= FALSE;
					end
					fir_data_line_ch1 [fir_data_line_pointer] <= current_adc_channel_data[0];
					fir_data_line_ch2 [fir_data_line_pointer] <= current_adc_channel_data[1];
					fir_data_line_ch3 [fir_data_line_pointer] <= current_adc_channel_data[2];
					fir_data_line_ch4 [fir_data_line_pointer] <= current_adc_channel_data[3];
					fir_data_line_ch5 [fir_data_line_pointer] <= current_adc_channel_data[4];
					fir_data_line_ch6 [fir_data_line_pointer] <= current_adc_channel_data[5];
					fir_data_line_ch7 [fir_data_line_pointer] <= current_adc_channel_data[6];
					fir_data_line_ch8 [fir_data_line_pointer] <= current_adc_channel_data[7];
					fir_data_line_ch9 [fir_data_line_pointer] <= current_adc_channel_data[8];
					fir_data_line_ch10[fir_data_line_pointer] <= current_adc_channel_data[9];
					fir_data_line_ch11[fir_data_line_pointer] <= current_adc_channel_data[10];
					fir_data_line_ch12[fir_data_line_pointer] <= current_adc_channel_data[11];
					fir_data_line_ch13[fir_data_line_pointer] <= current_adc_channel_data[12];
					fir_data_line_ch14[fir_data_line_pointer] <= current_adc_channel_data[13];
					fir_data_line_ch15[fir_data_line_pointer] <= current_adc_channel_data[14];
					fir_data_line_ch16[fir_data_line_pointer] <= current_adc_channel_data[15];
				end
				AXIS_TRIGGER_FIR: begin
					trigger_fir_reg <= HIGH;
				end
				AXIS_WAIT_FOR_FIR_START: begin
					if (fir_busy) trigger_fir_reg <= LOW;
					else trigger_fir_reg <= HIGH;
				end
				default: begin
					axis_received_count <= 0;
					trigger_fir_reg <= LOW;
					refreshed_reg <= FALSE;
					fir_data_line_pointer <= 0;
					last_fir_data_line_pointer <= 0;
				end
			endcase
		end
	end

	/* -------------------------------------------------------------------------- */
	/* ------------------------------ LEN Update -------------------------------- */
	/* -------------------------------------------------------------------------- */

	/* ---------------------------------- SYNC ---------------------------------- */

	always @(posedge S_AXIS_ACLK) begin
		if (S_AXIS_ARESETN == 1'b0 || software_rst_sync) begin
			len_update_trigger_sync1 <= FALSE;
			len_update_trigger_sync2 <= FALSE;
			fir_length_sync <= MAXIMUM_FILTER_LENGTH;
		end else begin
			len_update_trigger_sync1 <= len_update_trigger;
			len_update_trigger_sync2 <= len_update_trigger_sync1;
			if (fir_length <= MAXIMUM_FILTER_LENGTH) fir_length_sync <= fir_length;
			else fir_length_sync <= fir_length_sync;
		end
	end

	/* -------------------------------- FLAGS ---------------------------------- */

	always @(posedge S_AXIS_ACLK) begin
		if (S_AXIS_ARESETN == 1'b0 || software_rst_sync) begin
			len_update_state <= LEN_UPDATE_WAIT_FOR_TRIGGER;
		end else begin
			case (len_update_state)
			LEN_UPDATE_WAIT_FOR_TRIGGER: begin
				if (len_update_is_triggered) len_update_state <= LEN_MAKE_SYSTEM_UPDATE_RESET;
				else len_update_state <= len_update_state;
			end
			LEN_MAKE_SYSTEM_UPDATE_RESET: begin
				len_update_state <= LEN_CHECK_RESET_FLAGS;
			end
			LEN_CHECK_RESET_FLAGS: begin
				if (axis_have_reset && fir_have_reset && coef_have_reset) len_update_state <= LEN_UPDATE_LENGTH;
				else len_update_state <= len_update_state;
			end
			LEN_UPDATE_LENGTH: begin
				len_update_state <= LEN_RELEASE_COEF_UPDATE_RESET;
			end
			LEN_RELEASE_COEF_UPDATE_RESET: begin
				if (coef_have_reset) len_update_state <= len_update_state;
				else len_update_state <= LEN_TRIGGER_COEF_UPDATE;
			end
			LEN_TRIGGER_COEF_UPDATE: begin
				len_update_state <= LEN_WAIT_COEF_UPDATE_START;
			end
			LEN_WAIT_COEF_UPDATE_START: begin
				if (coef_update_busy) len_update_state <= LEN_WAIT_COEF_UPDATE_DOWN;
				else len_update_state <= len_update_state;
			end
			LEN_WAIT_COEF_UPDATE_DOWN: begin
				if (coef_update_busy) len_update_state <= len_update_state;
				else len_update_state <= LEN_RELEASE_SYSTEM_UPDATE_RESET;
			end
			LEN_RELEASE_SYSTEM_UPDATE_RESET: begin
				if (axis_have_reset || fir_have_reset || coef_have_reset) len_update_state <= len_update_state;
				else len_update_state <= LEN_UPDATE_WAIT_FOR_TRIGGER;
			end
			endcase	
		end
	end

	/* ----------------------------- REGISTERS --------------------------------- */

	always @(posedge S_AXIS_ACLK) begin
		if (S_AXIS_ARESETN == 1'b0 || software_rst_sync) begin
			update_coef_reset <= FALSE;
			update_system_reset <= FALSE;
			coef_triggered_by_len <= FALSE;
			fir_length_updated <= MAXIMUM_FILTER_LENGTH;
			len_updated_reg <= FALSE;
		end else begin
			case (len_update_state)
			LEN_UPDATE_WAIT_FOR_TRIGGER: begin
				/* Reset: not reset */
				update_coef_reset <= FALSE;
				update_system_reset <= FALSE;
				/* Trigger: no */
				coef_triggered_by_len <= FALSE;
				len_updated_reg <= TRUE;
			end
			LEN_MAKE_SYSTEM_UPDATE_RESET: begin
				/* Reset: reset system & coef */
				update_coef_reset <= TRUE;  /* reset */
				update_system_reset <= TRUE;  /* reset */
				/* Trigger: no */
				coef_triggered_by_len <= FALSE;
				len_updated_reg <= FALSE;
			end
			LEN_CHECK_RESET_FLAGS: begin
				/* Reset: reset system & coef */
				update_coef_reset <= TRUE;  /* reset */
				update_system_reset <= TRUE;  /* reset */
				/* Trigger: no */
				coef_triggered_by_len <= FALSE;
				len_updated_reg <= FALSE;
			end
			LEN_UPDATE_LENGTH: begin
				/* Reset: reset system & coef */
				update_coef_reset <= TRUE;  /* reset */
				update_system_reset <= TRUE;  /* reset */
				/* Trigger: no */
				fir_length_updated <= fir_length_sync;
				fir_coef_number_updated <= fir_length_sync * ADC_CHANNELS;
				coef_triggered_by_len <= FALSE;
				len_updated_reg <= FALSE;
			end
			LEN_RELEASE_COEF_UPDATE_RESET: begin
				/* Reset: reset system */
				update_coef_reset <= FALSE;
				update_system_reset <= TRUE;  /* reset */
				/* Trigger: no */
				coef_triggered_by_len <= FALSE;
				len_updated_reg <= FALSE;
			end
			LEN_TRIGGER_COEF_UPDATE: begin
				/* Reset: reset system */
				update_coef_reset <= FALSE;
				update_system_reset <= TRUE;  /* reset */
				/* Trigger: yes */
				coef_triggered_by_len <= TRUE;  /* trigger */
				len_updated_reg <= FALSE;
			end
			LEN_WAIT_COEF_UPDATE_START: begin
				/* Reset: reset system */
				update_coef_reset <= FALSE;
				update_system_reset <= TRUE;  /* reset */
				/* Trigger: yes */
				if (coef_update_busy) coef_triggered_by_len <= FALSE;
				else coef_triggered_by_len <= TRUE;  /* trigger */
				len_updated_reg <= FALSE;
			end
			LEN_WAIT_COEF_UPDATE_DOWN: begin
				/* Reset: reset system */
				update_coef_reset <= FALSE;
				update_system_reset <= TRUE;  /* reset */
				/* Trigger: no */
				coef_triggered_by_len <= FALSE;
				len_updated_reg <= FALSE;
			end
			LEN_RELEASE_SYSTEM_UPDATE_RESET: begin
				/* Reset: no */
				update_coef_reset <= FALSE;
				update_system_reset <= FALSE;
				/* Trigger: no */
				len_updated_reg <= FALSE;
				coef_triggered_by_len <= FALSE;
			end
			endcase	
		end
	end

	/* -------------------------------------------------------------------------- */
	/* ------------------------------ COEF Update ------------------------------- */
	/* -------------------------------------------------------------------------- */

	/* ---------------------------------- SYNC ---------------------------------- */

	always @(posedge S_AXIS_ACLK) begin
		if (S_AXIS_ARESETN == 1'b0 || software_rst_sync || update_coef_reset) begin
			coef_update_trigger_sync1 <= FALSE;
			coef_update_trigger_sync2 <= FALSE;
			fir_scale_sync <= 0;

			bram_en_sync <= 0;
		end else begin
			coef_update_trigger_sync1 <= coef_update_trigger;
			coef_update_trigger_sync2 <= coef_update_trigger_sync1;
			fir_scale_sync <= $signed(fir_scale);

			bram_en_sync <= bram_en_reg;
		end
	end

	/* -------------------------------- FLAGS ---------------------------------- */

	always @(posedge S_AXIS_ACLK) begin
		if (S_AXIS_ARESETN == 1'b0 || software_rst_sync || update_coef_reset) begin
			coef_have_reset <= TRUE;
			coef_update_state <= COEF_UPDATE_WAIT_FOR_TRIGGER;
		end else begin
			coef_have_reset <= FALSE;
			case (coef_update_state)
			COEF_UPDATE_WAIT_FOR_TRIGGER: begin
				if (coef_update_is_triggered) coef_update_state <= COEF_UPDATE_CHECK_FIR_CALCULATING;
				else coef_update_state <= coef_update_state;
			end
			COEF_UPDATE_CHECK_FIR_CALCULATING: begin
				if (fir_is_calculating) coef_update_state <= coef_update_state;
				else coef_update_state <= COEF_UPDATE_SCALE;
			end
			COEF_UPDATE_SCALE: begin
				coef_update_state <= COEF_UPDATE_COEFFICIENT;
			end
			COEF_UPDATE_COEFFICIENT: begin
				if (coef_current_channel >= 8'd16) coef_update_state <= COEF_UPDATE_WAIT_FOR_TRIGGER;
				else coef_update_state <= coef_update_state;
			end
			default: begin
				coef_update_state <= COEF_UPDATE_WAIT_FOR_TRIGGER;
			end
			endcase
		end
	end

	/* ------------------------------ REGISTERS -------------------------------- */

	always @(posedge S_AXIS_ACLK) begin
		if (S_AXIS_ARESETN == 1'b0 || software_rst_sync || update_coef_reset) begin
			bram_en_reg <= FALSE;
			bram_addr_reg <= 0;
			fir_scale_updated <= 0;
			coef_loaded_count <= 0;
			coef_save_enable <= FALSE;
			coef_updated_reg <= FALSE;
		end else begin
			case (coef_update_state)
			COEF_UPDATE_WAIT_FOR_TRIGGER: begin
				bram_en_reg <= FALSE;
				bram_addr_reg <= 0;
				coef_loaded_count <= 0;
				coef_save_enable <= FALSE;
				coef_updated_reg <= TRUE;
			end
			COEF_UPDATE_CHECK_FIR_CALCULATING: begin
				bram_en_reg <= FALSE;
				bram_addr_reg <= 0;
				coef_loaded_count <= 0;
				coef_save_enable <= FALSE;
				coef_updated_reg <= FALSE;
			end
			COEF_UPDATE_SCALE: begin
				fir_scale_updated <= fir_scale_sync;
				bram_en_reg <= TRUE;
				bram_addr_reg <= 0;
				coef_loaded_count <= 0;
				coef_save_enable <= FALSE;
				coef_updated_reg <= FALSE;
			end
			COEF_UPDATE_COEFFICIENT: begin

				coef_updated_reg <= FALSE;

				if (bram_en_reg) begin
					bram_addr_reg <= bram_addr_reg + BRAM_ADDR_INCREMENT;  /* Address + 4 bytes */
					coef_loaded_count <= coef_loaded_count + 1;
					if (coef_loaded_count >= fir_coef_number_updated - 1) bram_en_reg <= FALSE;  /* BRAM en control */
					else bram_en_reg <= TRUE;
				end else begin
					bram_addr_reg <= bram_addr_reg;
					if (coef_loaded_count >= fir_coef_number_updated) bram_en_reg <= FALSE;
					else bram_en_reg <= TRUE;  /* continue read */
				end

				if (bram_en_sync) begin  /* aligned to data */
					bram_data <= $signed(bram_dout);
					coef_save_enable <= TRUE;  /* aligned to data out */
				end else begin
					bram_data <= 0;
					coef_save_enable <= FALSE;
				end

			end
			default: begin
				bram_en_reg <= FALSE;
				bram_addr_reg <= 0;
				fir_scale_updated <= 0;
				coef_loaded_count <= 0;
				coef_save_enable <= FALSE;
				coef_updated_reg <= FALSE;
			end
			endcase
		end
	end

	always @(posedge S_AXIS_ACLK) begin  /* Save to internal bram */
		if (S_AXIS_ARESETN == 1'b0 || software_rst_sync || update_coef_reset) begin
			coef_current_channel <= 0;
			coef_current_offset <= 0;
		end else begin
			if (coef_update_state == COEF_UPDATE_COEFFICIENT) begin
				if (coef_save_enable) begin  /* Save enable */
					if (coef_current_channel <= 8'd15) begin
						/* Pointer */
						if (coef_current_offset >= fir_length_updated - 1) begin
							coef_current_offset <= 0;
							coef_current_channel <= coef_current_channel + 1;
						end else begin
							coef_current_offset <= coef_current_offset + 1;
							coef_current_channel <= coef_current_channel;
						end
						/* Save */
						case (coef_current_channel)
							8'd0:  fir_coef_line_ch1 [coef_current_offset] <= bram_data;
							8'd1:  fir_coef_line_ch2 [coef_current_offset] <= bram_data;
							8'd2:  fir_coef_line_ch3 [coef_current_offset] <= bram_data;
							8'd3:  fir_coef_line_ch4 [coef_current_offset] <= bram_data;
							8'd4:  fir_coef_line_ch5 [coef_current_offset] <= bram_data;
							8'd5:  fir_coef_line_ch6 [coef_current_offset] <= bram_data;
							8'd6:  fir_coef_line_ch7 [coef_current_offset] <= bram_data;
							8'd7:  fir_coef_line_ch8 [coef_current_offset] <= bram_data;
							8'd8:  fir_coef_line_ch9 [coef_current_offset] <= bram_data;
							8'd9:  fir_coef_line_ch10[coef_current_offset] <= bram_data;
							8'd10: fir_coef_line_ch11[coef_current_offset] <= bram_data;
							8'd11: fir_coef_line_ch12[coef_current_offset] <= bram_data;
							8'd12: fir_coef_line_ch13[coef_current_offset] <= bram_data;
							8'd13: fir_coef_line_ch14[coef_current_offset] <= bram_data;
							8'd14: fir_coef_line_ch15[coef_current_offset] <= bram_data;
							8'd15: fir_coef_line_ch16[coef_current_offset] <= bram_data;
							default:;
						endcase
					end else begin
						coef_current_offset <= coef_current_offset;
						coef_current_channel <= coef_current_channel;
					end
				end else begin
					coef_current_offset <= coef_current_offset;
					coef_current_channel <= coef_current_channel;
				end
			end else begin
				coef_current_channel <= 0;
				coef_current_offset <= 0;
			end
		end
	end

	/* -------------------------------------------------------------------------- */
	/* ---------------------------- FIR Filter Bank ----------------------------- */
	/* -------------------------------------------------------------------------- */

	/* ---------------------------------- SYNC ---------------------------------- */

	/* --------------------------------- FLAGS ---------------------------------- */

	always @(posedge S_AXIS_ACLK) begin  /* Save to internal bram */
		if (S_AXIS_ARESETN == 1'b0 || software_rst_sync || update_system_reset) begin
			fir_state <= FIR_WAIT_FOR_TRIGGER;
			fir_have_reset <= TRUE;
		end else begin
			fir_have_reset <= FALSE;
			case (fir_state)
			FIR_WAIT_FOR_TRIGGER: begin
				if (trigger_fir_reg) fir_state <= FIR_CHECK_COEF_UPDATE;
				else fir_state <= fir_state;
			end
			FIR_CHECK_COEF_UPDATE: begin
				if (coef_update_busy) fir_state <= fir_state;
				else fir_state <= FIR_PIPELINE_CALCULATION;
			end
			FIR_PIPELINE_CALCULATION: begin
				if (fir_pipeline_complete_flag) fir_state <= FIR_GET_SCALE_RESULT;
				else fir_state <= fir_state;
			end
			FIR_GET_SCALE_RESULT: begin
				fir_state <= FIR_WAIT_SENDING_IDLE;
			end
			FIR_WAIT_SENDING_IDLE: begin
				if (axis_sending_busy_sync) fir_state <= fir_state;
				else fir_state <= FIR_TRIGGER_SENDING;
			end
			FIR_TRIGGER_SENDING: begin
				fir_state <= FIR_WAIT_FOR_SENDING_START;
			end
			FIR_WAIT_FOR_SENDING_START: begin
				if (axis_sending_busy_sync) fir_state <= FIR_WAIT_FOR_TRIGGER;
				else fir_state <= fir_state;
			end
			default: fir_state <= FIR_WAIT_FOR_TRIGGER;
			endcase
		end
	end

	/* ------------------------------ REGISTERS --------------------------------- */

	always @(posedge S_AXIS_ACLK) begin  /* Save to internal bram */
		if (S_AXIS_ARESETN == 1'b0 || software_rst_sync || update_system_reset) begin
			axis_trigger_sending_reg <= FALSE;
			fir_output_reg <= 0;
		end else begin
			case (fir_state)
			FIR_WAIT_FOR_TRIGGER: begin
				axis_trigger_sending_reg <= FALSE;
			end
			FIR_CHECK_COEF_UPDATE: begin
				axis_trigger_sending_reg <= FALSE;
			end
			FIR_PIPELINE_CALCULATION: begin
				axis_trigger_sending_reg <= FALSE;
			end
			FIR_GET_SCALE_RESULT: begin
				fir_output_reg <= fir_scale_updated * fir_raw_output;
				axis_trigger_sending_reg <= FALSE;
			end
			FIR_WAIT_SENDING_IDLE: begin
				axis_trigger_sending_reg <= FALSE;
			end
			FIR_TRIGGER_SENDING: begin
				axis_trigger_sending_reg <= TRUE;
			end
			FIR_WAIT_FOR_SENDING_START: begin
				if (axis_sending_busy_sync) axis_trigger_sending_reg <= FALSE;
				else axis_trigger_sending_reg <= TRUE;
			end
			default: axis_trigger_sending_reg <= FALSE;
			endcase
		end
	end

	always @(posedge S_AXIS_ACLK) begin
		if (S_AXIS_ARESETN == 1'b0 || software_rst_sync || update_system_reset) begin
			/* Pointer */
			fir_coef_calculate_pointer <= 0;
			fir_data_calculate_pointer <= 0;
			/* Pipeline stages */
			for (i = 0; i < ADC_CHANNELS; i = i + 1) begin
				fir_data[i] <= 0;
				fir_coef[i] <= 0;
				fir_data_raw[i] <= 0;
				fir_coef_raw[i] <= 0;
			end
			for (i = 0; i < ADC_CHANNELS; i = i + 1) fir_mul_result_stage0[i] <= 0;
			for (i = 0; i < ADC_CHANNELS; i = i + 1) fir_mul_result_stage1[i] <= 0;
			for (i = 0; i < ADC_CHANNELS/2; i = i + 1) fir_mul_result_stage2[i] <= 0;
			for (i = 0; i < ADC_CHANNELS/4; i = i + 1) fir_mul_result_stage3[i] <= 0;
			fir_mul_result_stage4[0] <= 0;
			fir_mul_result_stage4[1] <= 0;
			fir_mul_result_stage5 <= 0;
			fir_raw_output <= 0;
			/* Flags */
			fir_stage01_complete_flag <= FALSE;
			fir_stage_latency_complete_flag <= FALSE;
			fir_stage02_complete_flag <= FALSE;
			fir_stage1_complete_flag <= FALSE;
			fir_stage2_complete_flag <= FALSE;
			fir_stage3_complete_flag <= FALSE;
			fir_stage4_complete_flag <= FALSE;
			fir_stage5_complete_flag <= FALSE;
			fir_stage_output_complete_flag <= FALSE;
			fir_pipeline_complete_flag <= FALSE;
		end else begin
			if (fir_state == FIR_PIPELINE_CALCULATION) begin

				if (fir_coef_calculate_pointer != INVALID_COEF_POINTER) begin

					/* Next data pointer */

					/* output = sigma(h{i}x{i}), i = 0, 1, ..., L - 1. */
					/* x(0) = newest data, x(L - 1) = latest data */

					if (fir_data_calculate_pointer == 0) fir_data_calculate_pointer <= fir_length_updated - 1;
					else fir_data_calculate_pointer <= fir_data_calculate_pointer - 1;

					/* Next coefficient pointer */

					if (fir_coef_calculate_pointer >= fir_length_updated - 1) fir_coef_calculate_pointer <= INVALID_COEF_POINTER;  /* the end */
					else fir_coef_calculate_pointer <= fir_coef_calculate_pointer + 1;

					/* Read data & coef from FIR line */

					fir_data_raw[0]  <= fir_data_line_ch1 [fir_data_calculate_pointer];
					fir_data_raw[1]  <= fir_data_line_ch2 [fir_data_calculate_pointer];
					fir_data_raw[2]  <= fir_data_line_ch3 [fir_data_calculate_pointer];
					fir_data_raw[3]  <= fir_data_line_ch4 [fir_data_calculate_pointer];
					fir_data_raw[4]  <= fir_data_line_ch5 [fir_data_calculate_pointer];
					fir_data_raw[5]  <= fir_data_line_ch6 [fir_data_calculate_pointer];
					fir_data_raw[6]  <= fir_data_line_ch7 [fir_data_calculate_pointer];
					fir_data_raw[7]  <= fir_data_line_ch8 [fir_data_calculate_pointer];
					fir_data_raw[8]  <= fir_data_line_ch9 [fir_data_calculate_pointer];
					fir_data_raw[9]  <= fir_data_line_ch10[fir_data_calculate_pointer];
					fir_data_raw[10] <= fir_data_line_ch11[fir_data_calculate_pointer];
					fir_data_raw[11] <= fir_data_line_ch12[fir_data_calculate_pointer];
					fir_data_raw[12] <= fir_data_line_ch13[fir_data_calculate_pointer];
					fir_data_raw[13] <= fir_data_line_ch14[fir_data_calculate_pointer];
					fir_data_raw[14] <= fir_data_line_ch15[fir_data_calculate_pointer];
					fir_data_raw[15] <= fir_data_line_ch16[fir_data_calculate_pointer];

					fir_coef_raw[0]  <= fir_coef_line_ch1 [fir_data_calculate_pointer];
					fir_coef_raw[1]  <= fir_coef_line_ch2 [fir_data_calculate_pointer];
					fir_coef_raw[2]  <= fir_coef_line_ch3 [fir_data_calculate_pointer];
					fir_coef_raw[3]  <= fir_coef_line_ch4 [fir_data_calculate_pointer];
					fir_coef_raw[4]  <= fir_coef_line_ch5 [fir_data_calculate_pointer];
					fir_coef_raw[5]  <= fir_coef_line_ch6 [fir_data_calculate_pointer];
					fir_coef_raw[6]  <= fir_coef_line_ch7 [fir_data_calculate_pointer];
					fir_coef_raw[7]  <= fir_coef_line_ch8 [fir_data_calculate_pointer];
					fir_coef_raw[8]  <= fir_coef_line_ch9 [fir_data_calculate_pointer];
					fir_coef_raw[9]  <= fir_coef_line_ch10[fir_data_calculate_pointer];
					fir_coef_raw[10] <= fir_coef_line_ch11[fir_data_calculate_pointer];
					fir_coef_raw[11] <= fir_coef_line_ch12[fir_data_calculate_pointer];
					fir_coef_raw[12] <= fir_coef_line_ch13[fir_data_calculate_pointer];
					fir_coef_raw[13] <= fir_coef_line_ch14[fir_data_calculate_pointer];
					fir_coef_raw[14] <= fir_coef_line_ch15[fir_data_calculate_pointer];
					fir_coef_raw[15] <= fir_coef_line_ch16[fir_data_calculate_pointer];

					fir_stage01_complete_flag <= FALSE;

				end else begin
					for (i = 0; i < ADC_CHANNELS; i = i + 1) begin
						fir_data[i] <= 0;
						fir_coef[i] <= 0;
						fir_data_raw[i] <= 0;
						fir_coef_raw[i] <= 0;
					end
					fir_data_calculate_pointer <= fir_data_calculate_pointer;
					fir_coef_calculate_pointer <= fir_coef_calculate_pointer;

					fir_stage01_complete_flag <= TRUE;
				end

				/* pipeline stages */

				for (i = 0; i < ADC_CHANNELS; i = i + 1) begin
					fir_data[i] <= fir_data_raw[i];
					fir_coef[i] <= fir_coef_raw[i];
				end
				for (i = 0; i < ADC_CHANNELS; i = i + 1) fir_mul_result_stage0[i] <= fir_data[i] * fir_coef[i];
				for (i = 0; i < ADC_CHANNELS; i = i + 1) fir_mul_result_stage1[i] <= fir_mul_result_stage0[i] >>> 30;
				for (i = 0; i < ADC_CHANNELS/2; i = i + 1) fir_mul_result_stage2[i] <= fir_mul_result_stage1[2*i] + fir_mul_result_stage1[2*i+1];
				for (i = 0; i < ADC_CHANNELS/4; i = i + 1) fir_mul_result_stage3[i] <= fir_mul_result_stage2[2*i] + fir_mul_result_stage2[2*i+1];
				fir_mul_result_stage4[0] <= fir_mul_result_stage3[0] + fir_mul_result_stage3[1];
				fir_mul_result_stage4[1] <= fir_mul_result_stage3[2] + fir_mul_result_stage3[3];
				fir_mul_result_stage5 <= fir_mul_result_stage4[0] + fir_mul_result_stage4[1];

				/* output */

				fir_raw_output <= fir_raw_output + fir_mul_result_stage5;

				/* complete flags */

				fir_stage_latency_complete_flag <= fir_stage01_complete_flag;
				fir_stage02_complete_flag <= fir_stage_latency_complete_flag;
				fir_stage1_complete_flag <= fir_stage02_complete_flag;
				fir_stage2_complete_flag <= fir_stage1_complete_flag;
				fir_stage3_complete_flag <= fir_stage2_complete_flag;
				fir_stage4_complete_flag <= fir_stage3_complete_flag;
				fir_stage5_complete_flag <= fir_stage4_complete_flag;
				fir_stage_output_complete_flag <= fir_stage5_complete_flag;
				fir_pipeline_complete_flag <= fir_stage_output_complete_flag;

			end else if (fir_state == FIR_GET_SCALE_RESULT) begin  /* Reserve the result for 2 cycles */
				fir_raw_output <= fir_raw_output;
			end else begin  /* clear data */
				fir_raw_output <= 0;
				/* Flags */
				fir_stage01_complete_flag <= FALSE;
				fir_stage_latency_complete_flag <= FALSE;
				fir_stage02_complete_flag <= FALSE;
				fir_stage1_complete_flag <= FALSE;
				fir_stage2_complete_flag <= FALSE;
				fir_stage3_complete_flag <= FALSE;
				fir_stage4_complete_flag <= FALSE;
				fir_stage5_complete_flag <= FALSE;
				fir_stage_output_complete_flag <= FALSE;
				fir_pipeline_complete_flag <= FALSE;
				/* pointer: coef = 0, data = oldest */
				fir_coef_calculate_pointer <= 0;
				fir_data_calculate_pointer <= last_fir_data_line_pointer;  /* to newest data pointer */
			end
		end
	end

	endmodule
