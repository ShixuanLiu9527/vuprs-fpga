
`timescale 1 ns / 1 ps

	module vfir_v1_0_M00_AXIS #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
		parameter integer C_M_AXIS_TDATA_WIDTH	= 32,
		// Start count is the number of clock cycles the master will wait before initiating/issuing any transaction.
		parameter integer C_M_START_COUNT	= 32
	)
	(
		// Users to add ports here

		output wire axis_sending_busy,  /* HIGH = axis master is sending */
		input wire axis_trigger_sending,  /* Trigger axis master to send */
		input wire signed [C_M_AXIS_TDATA_WIDTH-1:0] fir_output,
		input software_rst,

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
		output wire  M_AXIS_TLAST,  /* Not in use */
		// TREADY indicates that the slave can accept a transfer in the current cycle.
		input wire  M_AXIS_TREADY
	);

	localparam TRUE = 1'b1,
	           FALSE = 1'b0;

	localparam [1:0] AXIS_WAIT_FOR_TRIGGER = 2'd0,
					 AXIS_UNPACKING        = 2'd1,
					 AXIS_SEND_DATA        = 2'd2;

	reg axis_sending_busy_reg = FALSE;
	reg [C_M_AXIS_TDATA_WIDTH-1:0] fir_output_to_send = 0;
	reg [C_M_AXIS_TDATA_WIDTH-1:0] axis_tdata = 0;

	reg axis_trigger_sending_sync1 = FALSE;
	reg axis_trigger_sending_sync2 = FALSE;

	reg [1:0] axis_state = AXIS_WAIT_FOR_TRIGGER;

	wire axis_sending_triggered = (axis_trigger_sending_sync1 && !axis_trigger_sending_sync2);

	`define FIR_M00_AXIS_HAND_SHACK (M_AXIS_TVALID && M_AXIS_TREADY)

	assign M_AXIS_TVALID = (axis_state == AXIS_SEND_DATA);
	assign M_AXIS_TDATA = axis_tdata;
	assign M_AXIS_TSTRB = {(C_M_AXIS_TDATA_WIDTH/8){1'b1}};
	assign axis_sending_busy = axis_sending_busy_reg;

	/* SYNC */

	always @(posedge M_AXIS_ACLK) begin
		if (M_AXIS_ARESETN == 1'b0 || software_rst) begin
			axis_trigger_sending_sync1 <= FALSE;
			axis_trigger_sending_sync2 <= FALSE;
			fir_output_to_send <= 0;
		end else begin
			axis_trigger_sending_sync1 <= axis_trigger_sending;
			axis_trigger_sending_sync2 <= axis_trigger_sending_sync1;
			fir_output_to_send <= $unsigned(fir_output);
		end
	end

	/* ------------------------- FLAGS --------------------------- */

	always @(posedge M_AXIS_ACLK) begin
		if (M_AXIS_ARESETN == 1'b0 || software_rst) begin
			axis_state <= AXIS_WAIT_FOR_TRIGGER;
		end else begin
			case (axis_state)
			AXIS_WAIT_FOR_TRIGGER: begin
				if (axis_sending_triggered) axis_state <= AXIS_UNPACKING;
				else axis_state <= axis_state;
			end
			AXIS_UNPACKING: begin
				axis_state <= AXIS_SEND_DATA;
			end
			AXIS_SEND_DATA: begin
				if (`FIR_M00_AXIS_HAND_SHACK) axis_state <= AXIS_WAIT_FOR_TRIGGER;
				else axis_state <= axis_state;
			end
			default: axis_state <= AXIS_WAIT_FOR_TRIGGER;
			endcase
		end
	end

	/* REGISTERS */

	always @(posedge M_AXIS_ACLK) begin
		if (M_AXIS_ARESETN == 1'b0 || software_rst) begin
			axis_tdata <= 0;
			axis_sending_busy_reg <= FALSE;
		end else begin
			case (axis_state)
			AXIS_WAIT_FOR_TRIGGER: begin
				axis_tdata <= fir_output_to_send;
				if (axis_sending_triggered) axis_sending_busy_reg <= TRUE;
				else axis_sending_busy_reg <= FALSE;
			end
			AXIS_UNPACKING: begin
				axis_tdata <= fir_output_to_send;
				axis_sending_busy_reg <= TRUE;
			end
			AXIS_SEND_DATA: begin
				axis_sending_busy_reg <= TRUE;
				axis_tdata <= axis_tdata;
			end
			default: begin
				axis_tdata <= 0;
				axis_sending_busy_reg <= FALSE;
			end
			endcase
		end
	end
	
	endmodule
