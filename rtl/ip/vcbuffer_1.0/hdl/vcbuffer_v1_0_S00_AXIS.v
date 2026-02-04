
`timescale 1 ns / 1 ps

	module vcbuffer_v1_0_S00_AXIS #
	(
		// Users to add parameters here

		parameter integer BRAM_DATA_WIDTH	     = 32,   /* BRAM data width */
		parameter [32: 0] CIRCULAR_BUFFER_POINTS = 512,  /* Sampling points in one access */

		parameter [31: 0] FRAME_HEADER           = 32'h0000_FFF0,
		parameter [31: 0] FRAME_TAILER           = 32'h0000_FF0F,

		// User parameters ends
		// Do not modify the parameters beyond this line

		// AXI4Stream sink: Data Width
		parameter integer C_S_AXIS_TDATA_WIDTH	= 32
	)
	(
		// Users to add ports here

		/* Freeze & Reset */

		input wire freeze,
		input wire software_rst,

		output wire freezed,
		output wire refreshed,

		output wire [BRAM_DATA_WIDTH-1: 0] newest_bram_addr,

		/* BRAM Port */

		input wire  [BRAM_DATA_WIDTH-1: 0] bram_dout,  /* Do not used */

		output wire [BRAM_DATA_WIDTH-1: 0] bram_addr,
		output wire [BRAM_DATA_WIDTH-1: 0] bram_din,

		output wire [(BRAM_DATA_WIDTH/8)-1: 0] bram_we,

		output wire bram_clk,  /* assign to AXIS_ACLK */
		output wire bram_en,
		output wire bram_rst,

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
		input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB,  /* do not detected */
		// Indicates boundary of last packet
		input wire  S_AXIS_TLAST,  /* do not detected */
		// Data is in valid
		input wire  S_AXIS_TVALID
	);

	function integer clogb2 (input integer bit_depth);
	begin
	    for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
	    	bit_depth = bit_depth >> 1;
	end
	endfunction

	localparam TRUE                             = 1'b1,
	           FALSE                            = 1'b0;

	localparam FRAME_WORD_NUMBER                = 10;    /* Data Header & Data Tailer included */
	localparam FRAME_WORD_DATA_NUMBER           = FRAME_WORD_NUMBER - 2;   /* Data Header & Data Tailer excluded */

	localparam BRAM_PUSH_POINTER_ADDR_SIZE      = clogb2(FRAME_WORD_NUMBER + 1);
	localparam AXIS_RECEIVE_POINTER_ADDR_SIZE   = clogb2(FRAME_WORD_DATA_NUMBER + 1);

	localparam [2: 0] AXIS_WAIT_FOR_DATA_HEADER = 3'd0,  /* 3 bit, Wait for data header */
	                  AXIS_RECEIVE_DATA         = 3'd1,  /* Receive data */
					  AXIS_WAIT_FOR_DATA_TAILER = 3'd2,  /* Wait for data tailer & Check */
					  AXIS_CHECK_FREEZE         = 3'd3,  /* Check freeze flag */
					  AXIS_PUSH_BRAM            = 3'd4;  /* Push all data to BRAM */

	localparam [(BRAM_DATA_WIDTH/8)-1: 0] BRAM_WE_WRITE = {((BRAM_DATA_WIDTH/8)){1'b1}};  /* 4'b1 = Write */
	localparam BRAM_POINTER_INCREMENT                   = BRAM_DATA_WIDTH/8;  /* increment = 4 bytes */
	localparam CIRCULAR_BUFFER_BYTE_SIZE                = CIRCULAR_BUFFER_POINTS * FRAME_WORD_NUMBER * 4;  /* Buffer points * Frame word bytes (4 byte for 1 word) */

	reg [2: 0] axis_state = AXIS_WAIT_FOR_DATA_HEADER;
	
	reg [BRAM_DATA_WIDTH-1: 0] newest_bram_addr_reg = 0;
	reg [BRAM_DATA_WIDTH-1: 0] bram_addr_reg = 0;
	reg [BRAM_DATA_WIDTH-1: 0] bram_din_reg;

	reg bram_en_reg = FALSE;
	reg bram_rst_reg;

	reg freeze_sync = FALSE;

	reg freezed_reg = FALSE;
	reg refreshed_reg = FALSE;

	reg [AXIS_RECEIVE_POINTER_ADDR_SIZE-1: 0] received_data_count = 0;

	reg [BRAM_PUSH_POINTER_ADDR_SIZE-1: 0] bram_pushed_count = 0;
	
	reg [C_S_AXIS_TDATA_WIDTH - 1: 0] axis_receive_buffer[0: FRAME_WORD_DATA_NUMBER - 1];

	assign S_AXIS_TREADY = (axis_state == AXIS_WAIT_FOR_DATA_HEADER || 
	                        axis_state == AXIS_RECEIVE_DATA || 
							axis_state == AXIS_WAIT_FOR_DATA_TAILER);

	assign bram_clk = S_AXIS_ACLK;
	assign freezed = freezed_reg;
	assign refreshed = refreshed_reg;

	assign bram_addr = bram_addr_reg;
	assign bram_din = bram_din_reg;
	assign bram_we = BRAM_WE_WRITE;
	assign bram_en = bram_en_reg;
	assign newest_bram_addr = newest_bram_addr_reg;

	`define AXIS_HAND_SHACK  (S_AXIS_TREADY && S_AXIS_TVALID)
	`define DATA_PUSHED_TO_BRAM (bram_en)

	/* ------------------------------------------------------------------------------ */
	/* ---------------------------- AXI-Stream State -------------------------------- */
	/* ------------------------------------------------------------------------------ */

	/* ---------------------------------- SYNC -------------------------------------- */

	always @(posedge S_AXIS_ACLK) begin
		if (!S_AXIS_ARESETN || software_rst) begin
			freeze_sync <= FALSE;
		end else begin
			freeze_sync <= freeze;
		end
	end

	/* --------------------------------- FLAGS -------------------------------------- */

	always @(posedge S_AXIS_ACLK) begin
		if (!S_AXIS_ARESETN || software_rst) begin
			axis_state <= AXIS_WAIT_FOR_DATA_HEADER;
			freezed_reg <= FALSE;
		end else begin
			case(axis_state)
				AXIS_WAIT_FOR_DATA_HEADER: begin
					freezed_reg <= FALSE;
					if (`AXIS_HAND_SHACK) begin
						if (S_AXIS_TDATA == FRAME_HEADER) axis_state <= AXIS_RECEIVE_DATA;
						else axis_state <= axis_state;
					end else begin
						axis_state <= axis_state;
					end
				end
				AXIS_RECEIVE_DATA: begin
					freezed_reg <= FALSE;
					if (`AXIS_HAND_SHACK) begin
						if (received_data_count >= (FRAME_WORD_DATA_NUMBER - 1)) axis_state <= AXIS_WAIT_FOR_DATA_TAILER;
						else axis_state <= axis_state;
					end else begin
						if (received_data_count >= FRAME_WORD_DATA_NUMBER) axis_state <= AXIS_WAIT_FOR_DATA_TAILER;
						else axis_state <= axis_state;
					end
				end
				AXIS_WAIT_FOR_DATA_TAILER: begin
					freezed_reg <= FALSE;
					if (`AXIS_HAND_SHACK) begin
						if (S_AXIS_TDATA == FRAME_TAILER) axis_state <= AXIS_CHECK_FREEZE;  /* AXIS_TREADY to LOW */
						else axis_state <= AXIS_WAIT_FOR_DATA_HEADER;  /* ERROR condition, jump to AXIS_WAIT_FOR_DATA_HEADER */
					end else begin
						axis_state <= axis_state;
					end
				end
				AXIS_CHECK_FREEZE: begin  /* Check freeze */
					if (!freeze_sync)  begin
						axis_state <= AXIS_PUSH_BRAM;
						freezed_reg <= FALSE;
					end else begin  /* Freezed by master */
						axis_state <= axis_state;
						freezed_reg <= TRUE;
					end
				end
				AXIS_PUSH_BRAM: begin
					freezed_reg <= FALSE;
					if (`DATA_PUSHED_TO_BRAM) begin
						if (bram_pushed_count >= (FRAME_WORD_NUMBER - 1)) axis_state <= AXIS_WAIT_FOR_DATA_HEADER;
						else axis_state <= axis_state;
					end else begin
						if (bram_pushed_count >= FRAME_WORD_NUMBER) axis_state <= AXIS_WAIT_FOR_DATA_HEADER;
						else axis_state <= axis_state;
					end
				end
				default: begin
					axis_state <= AXIS_WAIT_FOR_DATA_HEADER;
					freezed_reg <= FALSE;
				end
			endcase
		end
	end

	/* --------------------------------- FLAGS -------------------------------------- */

	always @(posedge S_AXIS_ACLK) begin
		if (!S_AXIS_ARESETN || software_rst) begin
			received_data_count <= 0;
		end else begin
			case(axis_state)
				AXIS_WAIT_FOR_DATA_HEADER: begin
					received_data_count <= 0;
				end
				AXIS_RECEIVE_DATA: begin
					if (`AXIS_HAND_SHACK) begin  /* push data to axis_receive_buffer */
						if (received_data_count <= FRAME_WORD_DATA_NUMBER - 1) begin
							received_data_count <= received_data_count + 1;
							axis_receive_buffer[received_data_count] <= S_AXIS_TDATA;
						end else begin
							received_data_count <= received_data_count;
						end
					end else begin
						received_data_count <= received_data_count;
					end
				end
				AXIS_WAIT_FOR_DATA_TAILER: begin
					received_data_count <= received_data_count;
				end
				AXIS_CHECK_FREEZE: begin
					received_data_count <= received_data_count;
				end
				AXIS_PUSH_BRAM: begin
					received_data_count <= received_data_count;
				end
				default: begin
					received_data_count <= received_data_count;
				end
			endcase
		end
	end

	/* ------------------------------------------------------------------------------ */
	/* ---------------------------- BRAM Logic State -------------------------------- */
	/* ------------------------------------------------------------------------------ */

	always @(posedge S_AXIS_ACLK) begin
		if (!S_AXIS_ARESETN || software_rst) begin
			newest_bram_addr_reg <= 0;
			bram_pushed_count <= 0;
			bram_addr_reg <= 0;
			bram_din_reg <= 0;
			bram_en_reg <= FALSE;
			refreshed_reg <= FALSE;
		end else begin
			case(axis_state)
				AXIS_CHECK_FREEZE: begin
					bram_addr_reg <= bram_addr_reg;
					if (!freeze_sync)  begin  /* Not freezed, ready to push BRAM */
						bram_pushed_count <= 0;
						bram_din_reg <= FRAME_HEADER;
						bram_en_reg <= TRUE;
					end else begin  /* Freezed, reset */
						bram_pushed_count <= 0;
						bram_din_reg <= 0;
						bram_en_reg <= FALSE;
					end
				end
				AXIS_PUSH_BRAM: begin
					if (`DATA_PUSHED_TO_BRAM) begin
						/* -------------------------------------------------------------------- */
						/* -------------------- pushed count ---------------------------------- */
						/* -------------------------------------------------------------------- */
						bram_pushed_count <= bram_pushed_count + 1;
						/* -------------------------------------------------------------------- */
						/* --------------- Pointer: bram addr + 4 bytes ----------------------- */
						/* -------------------------------------------------------------------- */
						if (bram_pushed_count <= FRAME_WORD_NUMBER - 1) begin
							if (bram_addr_reg >= CIRCULAR_BUFFER_BYTE_SIZE - BRAM_POINTER_INCREMENT) begin
								bram_addr_reg <= 0;
								refreshed_reg <= TRUE;  /* refreshed to TRUE to indicate refreshed data in the BRAM */
							end else begin
								bram_addr_reg <= bram_addr_reg + BRAM_POINTER_INCREMENT;
								refreshed_reg <= refreshed_reg;
							end
							newest_bram_addr_reg <= bram_addr_reg;  /* LOCKED, valid pointer to newest data */
						end else begin
							bram_addr_reg <= bram_addr_reg;  /* ERROR Condition */
						end
						/* -------------------------------------------------------------------- */
						/* -------------------- data ------------------------------------------ */
						/* -------------------------------------------------------------------- */
						/* reference: 
						case (bram_pushed_count)
							8'd0: bram_din_reg <= axis_receive_buffer[0];
							8'd1: bram_din_reg <= axis_receive_buffer[1];
							8'd2: bram_din_reg <= axis_receive_buffer[2];
							8'd3: bram_din_reg <= axis_receive_buffer[3];
							8'd4: bram_din_reg <= axis_receive_buffer[4];
							8'd5: bram_din_reg <= axis_receive_buffer[5];
							8'd6: bram_din_reg <= axis_receive_buffer[6];
							8'd7: bram_din_reg <= axis_receive_buffer[7];
							8'd8: bram_din_reg <= FRAME_TAILER;
							8'd9: bram_din_reg <= 0;
						endcase
						*/
						if (bram_pushed_count <= FRAME_WORD_NUMBER - 3) bram_din_reg <= axis_receive_buffer[bram_pushed_count];
						else bram_din_reg <= FRAME_TAILER;
						/* -------------------------------------------------------------------- */
						/* -------------------- BRAM EN --------------------------------------- */
						/* -------------------------------------------------------------------- */
						if (bram_pushed_count >= FRAME_WORD_NUMBER - 1) bram_en_reg <= FALSE;
						else bram_en_reg <= TRUE;
					end else begin
						bram_addr_reg <= bram_addr_reg;
						bram_pushed_count <= bram_pushed_count;
						bram_din_reg <= bram_din_reg;
						if (bram_pushed_count >= FRAME_WORD_NUMBER) bram_en_reg <= FALSE;
						else bram_en_reg <= TRUE;
					end
				end
				default: begin
					bram_addr_reg <= bram_addr_reg;
					bram_pushed_count <= bram_pushed_count;
					bram_en_reg <= FALSE;
					bram_din_reg <= 0;
				end
			endcase
		end
	end

	endmodule
