
`timescale 1 ns / 1 ps

	module vpdelay_v1_0_M00_AXIS #
	(
		// Users to add parameters here

		parameter [31: 0] FRAME_HEADER           = 32'h0000_FFF0,
		parameter [31: 0] FRAME_TAILER           = 32'h0000_FF0F,

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
		parameter integer C_M_AXIS_TDATA_WIDTH	= 32,
		// Start count is the number of clock cycles the master will wait before initiating/issuing any transaction.
		parameter integer C_M_START_COUNT	= 32
	)
	(
		// Users to add ports here

		input wire send_trigger,
		input wire software_rst,

		input wire [C_M_AXIS_TDATA_WIDTH-1:0]	data_frame1,
	    input wire [C_M_AXIS_TDATA_WIDTH-1:0]	data_frame2,
	    input wire [C_M_AXIS_TDATA_WIDTH-1:0]	data_frame3,
	    input wire [C_M_AXIS_TDATA_WIDTH-1:0]	data_frame4,
	    input wire [C_M_AXIS_TDATA_WIDTH-1:0]	data_frame5,
	    input wire [C_M_AXIS_TDATA_WIDTH-1:0]	data_frame6,
	    input wire [C_M_AXIS_TDATA_WIDTH-1:0]	data_frame7,
	    input wire [C_M_AXIS_TDATA_WIDTH-1:0]	data_frame8,

		output wire axis_send_busy,

		// User ports ends
		// Do not modify the ports beyond this line

		// Global ports
		input wire  M_AXIS_ACLK,
		// 
		input wire  M_AXIS_ARESETN,
		// Master Stream Ports. TVALID indicates that the master is driving a valid transfer, A transfer takes place when both TVALID and TREADY are asserted. 
		output wire  M_AXIS_TVALID,
		// TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
		output wire [C_M_AXIS_TDATA_WIDTH-1 : 0] M_AXIS_TDATA,
		// TSTRB is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
		output wire [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] M_AXIS_TSTRB,
		// TLAST indicates the boundary of a packet.
		output wire  M_AXIS_TLAST,
		// TREADY indicates that the slave can accept a transfer in the current cycle.
		input wire  M_AXIS_TREADY
	);

	localparam TRUE = 1'b1,
	           FALSE = 1'b0;
	
	localparam FRAME_WORD_NUMBER                = 10;  /* Data Header & Data Tailer included */

	localparam [1: 0] AXIS_WAIT_FOR_TRIGGER     = 2'd0,
					  AXIS_SEND_DATA            = 2'd1;

	reg trigger_sync1 = FALSE;
	reg trigger_sync2 = FALSE;

	reg [1: 0] axis_state = AXIS_WAIT_FOR_TRIGGER;
	reg [7: 0] axis_sent_count = 0;

	reg software_rst_sync = FALSE;

	reg axis_tvalid = FALSE;
	reg [C_M_AXIS_TDATA_WIDTH-1 : 0] axis_tdata;
	reg axis_tlast = FALSE;

	reg [C_M_AXIS_TDATA_WIDTH-1:0]	data_frame1_sync;
	reg [C_M_AXIS_TDATA_WIDTH-1:0]	data_frame2_sync;
	reg [C_M_AXIS_TDATA_WIDTH-1:0]	data_frame3_sync;
	reg [C_M_AXIS_TDATA_WIDTH-1:0]	data_frame4_sync;
	reg [C_M_AXIS_TDATA_WIDTH-1:0]	data_frame5_sync;
	reg [C_M_AXIS_TDATA_WIDTH-1:0]	data_frame6_sync;
	reg [C_M_AXIS_TDATA_WIDTH-1:0]	data_frame7_sync;
	reg [C_M_AXIS_TDATA_WIDTH-1:0]	data_frame8_sync;

	wire trigger_rising_edge = (trigger_sync1 && !trigger_sync2);

	assign M_AXIS_TVALID = axis_tvalid;
	assign M_AXIS_TDATA = axis_tdata;
	assign M_AXIS_TSTRB = {(C_M_AXIS_TDATA_WIDTH/8){1'b1}};;
	assign M_AXIS_TLAST = axis_tlast;

	assign axis_send_busy = (axis_state != AXIS_WAIT_FOR_TRIGGER);

	`define PRE_DELAY_M00_AXIS_HAND_SHACK (M_AXIS_TREADY && M_AXIS_TVALID)

	/* -------------------------------------------------------------------------- */
	/* --------------------------------- SYNC ----------------------------------- */
	/* -------------------------------------------------------------------------- */

	always @(posedge M_AXIS_ACLK) begin
		if (M_AXIS_ARESETN == 1'b0) begin
			software_rst_sync <= FALSE;
			trigger_sync1 <= FALSE;
			trigger_sync2 <= FALSE;

			data_frame1_sync <= 0;
			data_frame2_sync <= 0;
			data_frame3_sync <= 0;
			data_frame4_sync <= 0;
			data_frame5_sync <= 0;
			data_frame6_sync <= 0;
			data_frame7_sync <= 0;
			data_frame8_sync <= 0;

		end else begin
			software_rst_sync <= software_rst;
			trigger_sync1 <= send_trigger;
			trigger_sync2 <= trigger_sync1;

			data_frame1_sync <= data_frame1;
			data_frame2_sync <= data_frame2;
			data_frame3_sync <= data_frame3;
			data_frame4_sync <= data_frame4;
			data_frame5_sync <= data_frame5;
			data_frame6_sync <= data_frame6;
			data_frame7_sync <= data_frame7;
			data_frame8_sync <= data_frame8;
		end
	end

	/* -------------------------------------------------------------------------- */
	/* --------------------------------- STATUS --------------------------------- */
	/* -------------------------------------------------------------------------- */

	/* --------------------------------- FLAGS ---------------------------------- */

	always @(posedge M_AXIS_ACLK) begin
		if (M_AXIS_ARESETN == 1'b0 || software_rst_sync) begin
			axis_state <= AXIS_WAIT_FOR_TRIGGER;
		end else begin
			case (axis_state)
				AXIS_WAIT_FOR_TRIGGER: begin
					if (trigger_rising_edge) axis_state <= AXIS_SEND_DATA;
					else axis_state <= axis_state;
				end
				AXIS_SEND_DATA: begin
					if (`PRE_DELAY_M00_AXIS_HAND_SHACK) begin
						if (axis_sent_count >= FRAME_WORD_NUMBER - 1) axis_state <= AXIS_WAIT_FOR_TRIGGER;
						else axis_state <= axis_state;
					end else begin
						if (axis_sent_count >= FRAME_WORD_NUMBER) axis_state <= AXIS_WAIT_FOR_TRIGGER;
						else axis_state <= axis_state;
					end
				end
				default: begin
					axis_state <= AXIS_WAIT_FOR_TRIGGER;
				end
			endcase
		end
	end

	/* ------------------------------ REGISTERS ------------------------------ */

	always @(posedge M_AXIS_ACLK) begin
		if (M_AXIS_ARESETN == 1'b0 || software_rst_sync) begin
			axis_sent_count <= 0;
			axis_tdata <= 0;
			axis_tvalid = FALSE;
			axis_tlast = FALSE;
		end else begin
			axis_tlast = FALSE;
			case (axis_state)
				AXIS_WAIT_FOR_TRIGGER: begin
					axis_sent_count <= 0;
					if (trigger_rising_edge) begin
						axis_tvalid = TRUE;
						axis_tdata <= FRAME_HEADER;  /* ready to send Frame Header */
					end else begin
						axis_tvalid = FALSE;
						axis_tdata <= axis_tdata;
					end
				end
				AXIS_SEND_DATA: begin
					if (`PRE_DELAY_M00_AXIS_HAND_SHACK) begin
						axis_sent_count <= axis_sent_count + 1;
						case (axis_sent_count)
							8'd0: axis_tdata <= data_frame1_sync;
							8'd1: axis_tdata <= data_frame2_sync;
							8'd2: axis_tdata <= data_frame3_sync;
							8'd3: axis_tdata <= data_frame4_sync;
							8'd4: axis_tdata <= data_frame5_sync;
							8'd5: axis_tdata <= data_frame6_sync;
							8'd6: axis_tdata <= data_frame7_sync;
							8'd7: axis_tdata <= data_frame8_sync;
							8'd8: axis_tdata <= FRAME_TAILER;
							8'd9: axis_tdata <= 0;
							default: axis_tdata <= 0;
						endcase
						if (axis_sent_count >= FRAME_WORD_NUMBER - 1) axis_tvalid = FALSE;
						else axis_tvalid = TRUE;
					end else begin
						if (axis_sent_count >= FRAME_WORD_NUMBER) axis_tvalid = FALSE;
						else axis_tvalid = TRUE;
					end
				end
				default: begin
					axis_sent_count <= 0;
					axis_tdata <= 0;
					axis_tvalid = FALSE;
				end
			endcase
		end
	end

	endmodule
