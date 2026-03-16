
`timescale 1 ns / 1 ps

	/* AXI-Stream Master, without CRC calculation */

	module vadc_v1_0_M00_AXIS #
	(
		parameter integer USR_CLK_CYCLE_NS  = 20,   /* unit: ns, clock cycle of [adc_clk] (e.g. 20 ns for 50 MHz) */
              		  T_CYCLE_NS            = 5000, /* unit: ns, t_cycle of AD7606 (refer to data sheet) */
          	  		  T_RESET_NS            = 50,   /* unit: ns, t_reset of AD7606 (refer to data sheet) */
          	  		  T_CONV_MIN_NS         = 3450, /* unit: ns, min t_conv of AD7606 (refer to data sheet) */
          	  		  T_CONV_MAX_NS         = 4150, /* unit: ns, max t_conv of AD7606 (refer to data sheet) */
          	  		  T1_NS                 = 40,   /* unit: ns, t1 of AD7606 (refer to data sheet) */
          	  		  T2_NS                 = 25,   /* unit: ns, t2 of AD7606 (refer to data sheet) */
          	  		  T10_NS                = 25,   /* unit: ns, t10 of AD7606 (refer to data sheet) */
          	  		  T11_NS                = 15,   /* unit: ns, t11 of AD7606 (refer to data sheet) */
          	  		  T14_NS                = 25,   /* unit: ns, t14 of AD7606 (refer to data sheet) */
          	  		  T15_NS                = 6,    /* unit: ns, t15 of AD7606 (refer to data sheet) */
          	  		  T26_NS                = 25,   /* unit: ns, t15 of AD7606 (refer to data sheet) */

		parameter integer CONTROL_REGISTER_WIDTH = 32,        /* control register width */

		/* Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH. */

		parameter integer C_M_AXIS_TDATA_WIDTH	 = 32,

		/* Start init_count is the number of clock cycles the master will wait before initiating/issuing any transaction. */

		parameter integer C_M_START_COUNT	     = 32,

		/* Data Header & Data Tailer */

		parameter [31: 0] FRAME_HEADER           = 32'h0000_FFF0,
		parameter [31: 0] FRAME_TAILER           = 32'h0000_FF0F

	)
	(
		output wire [CONTROL_REGISTER_WIDTH - 1: 0]  error_flags,
		output wire                                  ready,

		input wire [CONTROL_REGISTER_WIDTH - 1: 0]   sampling_clk_increment,
		input wire [CONTROL_REGISTER_WIDTH - 1: 0]   sampling_points,
		input wire                                   last_frame,
		input wire                                   software_rst,
		input wire                                   continuous_sampling,

		input wire                                   one_frame_sampling_trigger, /* rising edge to trigger */

		input wire                                   adc_clk,                    /* clock for ADC, 100 MHz or 50 MHz */
		input wire                                   adc_rst_n,                  /* reset signal for ADC */

		/* ---------------------------------- ADC-A hardware signals -------------------------------------------- */

		input wire          adc_a_hw_busy,        /* BUSY pin of the AD7606 chip */
    	input wire          adc_a_hw_first_data,  /* FIRSTDATA pin of the AD7606 chip */
    	input wire [15: 0]  adc_a_hw_data,        /* D0 - D15 Pins of the AD7606 chip */

    	output wire         adc_a_hw_convst,      /* CONVST pin of the AD7606 chip (CONVRST_A and CONVRST_B are connected together) */
    	output wire         adc_a_hw_rd,          /* RD# pin of the AD7606 chip */
    	output wire         adc_a_hw_cs,          /* CS# pin of the AD7606 chip */
    	output wire         adc_a_hw_range,       /* RANGE pin of the AD7606 chip */
    	output wire [2: 0]  adc_a_hw_os,          /* OS0 - OS2 pins of the AD7606 chip (Not used) */
    	output wire         adc_a_hw_mode_select, /* PAR#/SER/BYTE_SEL pin of the AD7606 chip */
    	output wire         adc_a_hw_reset,       /* RESET pin of the AD7606 chip */
    	output wire         adc_a_hw_stby_n,      /* STBY# pin of the AD7606 */

		/* ---------------------------------- ADC-B hardware signals -------------------------------------------- */

		input wire          adc_b_hw_busy,        /* BUSY pin of the AD7606 chip */
    	input wire          adc_b_hw_first_data,  /* FIRSTDATA pin of the AD7606 chip */
    	input wire [15: 0]  adc_b_hw_data,        /* D0 - D15 Pins of the AD7606 chip */

    	output wire         adc_b_hw_convst,      /* CONVST pin of the AD7606 chip (CONVRST_A and CONVRST_B are connected together) */
    	output wire         adc_b_hw_rd,          /* RD# pin of the AD7606 chip */
    	output wire         adc_b_hw_cs,          /* CS# pin of the AD7606 chip */
    	output wire         adc_b_hw_range,       /* RANGE pin of the AD7606 chip */
    	output wire [2: 0]  adc_b_hw_os,          /* OS0 - OS2 pins of the AD7606 chip (Not used) */
    	output wire         adc_b_hw_mode_select, /* PAR#/SER/BYTE_SEL pin of the AD7606 chip */
    	output wire         adc_b_hw_reset,       /* RESET pin of the AD7606 chip */
    	output wire         adc_b_hw_stby_n,      /* STBY# pin of the AD7606 */

		/* ---------------------------------- AXI-Stream Interface -------------------------------------------- */

		output wire [(C_M_AXIS_TDATA_WIDTH / 8) - 1: 0] M_AXIS_TKEEP,
		input wire                                      M_AXIS_ACLK,
		input wire                                      M_AXIS_ARESETN,

		/* 
		   Master Stream Ports. 
		   TVALID indicates that the master is driving a valid transfer, 
		   A transfer takes place when both TVALID and TREADY are asserted. 
		*/

		output wire                                     M_AXIS_TVALID,

		/* 
		   TDATA is the primary payload that is used to provide the 
		   data that is passing across the interface from the master. 
		*/

		output wire [C_M_AXIS_TDATA_WIDTH - 1: 0]       M_AXIS_TDATA,

		/* 
		   TSTRB is the byte qualifier that indicates 
		   whether the content of the associated byte of TDATA is 
		   processed as a data byte or a position byte. 
		*/

		output wire [(C_M_AXIS_TDATA_WIDTH / 8) - 1: 0] M_AXIS_TSTRB,

		/* TLAST indicates the boundary of a packet. */

		output wire                                     M_AXIS_TLAST,

		/* TREADY indicates that the slave can accept a transfer in the current cycle. */

		input wire                                      M_AXIS_TREADY,

		/* ------------------------------------- DEBUG ----------------------------------- */

		output wire [3:0] DEBUG_system_state,
		output wire [3:0] DEBUG_sampling_state,
		output wire [3:0] DEBUG_axis_state,
		output wire [31:0] DEBUG_global_sent_points

	);
	
	localparam DEFAULT_CLOCK_INCREMENT       = 12500;
	localparam DEFAULT_SAMPLING_POINTS       = 1024;
	localparam HIGH                          = 1'b1,
			   LOW                           = 1'b0;
	localparam TRUE                          = 1'b1,
			   FALSE                         = 1'b0;
	localparam FRAME_WORD_NUMBER             = 10;
	localparam DATA_WORD_NUMBER              = FRAME_WORD_NUMBER - 2;
	localparam MINIUM_SAMPLING_CLK_INCREMENT = (1000_000_000 / 150_000) / USR_CLK_CYCLE_NS + 1;  // 150 kHz max

	localparam SYSTEM_STATE__IDLE                          = 4'd0,  /* wait for trigger */
			   SYSTEM_STATE__INIT_SYNC_PARAM               = 4'd1,  /* sync parameters */
			   SYSTEM_STATE__SEND_STREAM                   = 4'd2;  /* send stream */

	localparam SAMPLING_STATE__CHECK_COMPLETE              = 4'd0,  /* Check complete flags */
			   SAMPLING_STATE__WAIT_SAMPLING_START         = 4'd1,  /* Wait for sampling start */
			   SAMPLING_STATE__WAIT_SAMPLING_END           = 4'd2,  /* Wait for sampling end */
			   SAMPLING_STATE__WAIT_SENDING_END            = 4'd3,  /* Wait for AXI-Stream send complete */
			   SAMPLING_STATE__PACK_DATA_TO_BUFFER         = 4'd4,  /* Pack data to AXI-Stream buffer */
			   SAMPLING_STATE__TRIGGER_AXIS_SENDING        = 4'd5,  /* Trigger AXI-Stream sending */
			   SAMPLING_STATE__WAIT_FOR_AXIS_SENDING_START = 4'd6;  /* Wait for AXI-Stream sending start */

	localparam AXIS_STATE__IDLE                            = 4'd0,  /* Idle, waiting for trigger */
			   AXIS_STATE__SEND_STREAM                     = 4'd1;  /* Send data to AXI-Stream */

	reg [3:0] system_state = SYSTEM_STATE__IDLE;  /* system state */
	reg [3:0] sampling_state = SAMPLING_STATE__CHECK_COMPLETE;  /* system state */
	reg [3:0] axis_state = AXIS_STATE__IDLE;  /* system state */

	reg [31:0] global_sent_points = 0;  /* Point count sent by AXI-Stream */
	reg [7:0] axis_words_sent_points = 0;  /* Word sent count */

	reg axis_sending_trigger_reg = LOW;  /* HIGH to trigger */
	
	reg  	                            axis_tlast = FALSE;  /* AXI-Stream T_LAST */
	reg [C_M_AXIS_TDATA_WIDTH - 1 : 0] 	axis_tdata = 0; /* AXI-Stream T_DATA */

	reg module_ready = FALSE;  /* Indicate module ready */

	reg software_rst_sync__axi = FALSE;  /* software reset */

	reg software_rst_sync0__adc = FALSE;  /* software reset, ADC_CLK domain */
	reg software_rst_sync1__adc = FALSE;  /* software reset, ADC_CLK domain */
	reg software_rst_sync__adc = FALSE;  /* software reset, ADC_CLK domain */

	reg one_frame_trigger_sync0 = FALSE;
	reg one_frame_trigger_sync1 = FALSE;

	reg [CONTROL_REGISTER_WIDTH - 1: 0] sci_reg_sync0 = DEFAULT_CLOCK_INCREMENT;  /* ADC_CLK domain */
	reg [CONTROL_REGISTER_WIDTH - 1: 0] sci_reg_sync1 = DEFAULT_CLOCK_INCREMENT;  /* ADC_CLK domain */
	reg [CONTROL_REGISTER_WIDTH - 1: 0] sci_reg = DEFAULT_CLOCK_INCREMENT;  /* ADC_CLK domain */

	reg [CONTROL_REGISTER_WIDTH - 1: 0] sci_reg_sync0__axi = DEFAULT_CLOCK_INCREMENT;  /* AXIS_CLK domain */
	reg [CONTROL_REGISTER_WIDTH - 1: 0] sci_reg_sync1__axi = DEFAULT_CLOCK_INCREMENT;  /* AXIS_CLK domain */
	reg [CONTROL_REGISTER_WIDTH - 1: 0] sci_reg_sync__axi = DEFAULT_CLOCK_INCREMENT;  /* AXIS_CLK domain */

	reg [CONTROL_REGISTER_WIDTH - 1: 0] sampling_clk_count = 0;  /* ADC_CLK domain */

	reg [3:0] system_state_sync0 = SYSTEM_STATE__IDLE;  /* ADC_CLK domain */
	reg [3:0] system_state_sync1 = SYSTEM_STATE__IDLE;  /* ADC_CLK domain */
	reg [3:0] system_state_sync = SYSTEM_STATE__IDLE;  /* ADC_CLK domain */

	reg sampling_clk_reg = FALSE;  /* ADC_CLK domain */

	reg [CONTROL_REGISTER_WIDTH - 1: 0] sp_reg = 1024;

	reg [C_M_AXIS_TDATA_WIDTH - 1: 0] axis_buffer[0: DATA_WORD_NUMBER];  /* buffer[i] is data frame [i] */
	
	wire [15: 0] adc_a_ch1;
	wire [15: 0] adc_a_ch2;
	wire [15: 0] adc_a_ch3;
	wire [15: 0] adc_a_ch4;
	wire [15: 0] adc_a_ch5;
	wire [15: 0] adc_a_ch6;
	wire [15: 0] adc_a_ch7;
	wire [15: 0] adc_a_ch8;

	wire [15: 0] adc_b_ch1;
	wire [15: 0] adc_b_ch2;
	wire [15: 0] adc_b_ch3;
	wire [15: 0] adc_b_ch4;
	wire [15: 0] adc_b_ch5;
	wire [15: 0] adc_b_ch6;
	wire [15: 0] adc_b_ch7;
	wire [15: 0] adc_b_ch8;

	wire sampling_clk = sampling_clk_reg;
	
	wire adc_a_sampling;
	wire adc_a_ready;
	wire [3: 0] adc_a_err;

	wire adc_b_sampling;
	wire adc_b_ready;
	wire [3: 0] adc_b_err;

	wire axis_hand_shake = M_AXIS_TVALID && M_AXIS_TREADY;

	assign M_AXIS_TVALID = (axis_state == AXIS_STATE__SEND_STREAM);
	assign M_AXIS_TLAST	 = axis_tlast;
	assign M_AXIS_TDATA = axis_tdata;

	assign M_AXIS_TSTRB = {(C_M_AXIS_TDATA_WIDTH / 8){1'b1}};
	assign M_AXIS_TKEEP = {(C_M_AXIS_TDATA_WIDTH / 8){1'b1}};

	assign ready = module_ready;
	assign error_flags = {{(CONTROL_REGISTER_WIDTH - 8){1'b0}}, adc_b_err[3: 0], adc_a_err[3: 0]};

	assign DEBUG_system_state = system_state;
	assign DEBUG_sampling_state = sampling_state;
	assign DEBUG_axis_state = axis_state;
	assign DEBUG_global_sent_points = global_sent_points;

	/* --------------------------------------------- SYNC -------------------------------------------- */

	/* RESET */

	always @(posedge M_AXIS_ACLK) begin
		if (!M_AXIS_ARESETN) begin
			software_rst_sync__axi <= FALSE;
		end else begin
			software_rst_sync__axi <= software_rst;
		end
	end

	always @(posedge adc_clk) begin
		if (!adc_rst_n) begin
			software_rst_sync0__adc <= FALSE;
			software_rst_sync1__adc <= FALSE;
			software_rst_sync__adc <= FALSE;
		end else begin
			software_rst_sync0__adc <= software_rst;
			software_rst_sync1__adc <= software_rst_sync0__adc;
			software_rst_sync__adc <= software_rst_sync1__adc;
		end
	end

	/* OTHER FLAGS */

	always @(posedge M_AXIS_ACLK) begin
		if (!M_AXIS_ARESETN || software_rst_sync__axi) begin
			one_frame_trigger_sync0 <= FALSE;
			one_frame_trigger_sync1 <= FALSE;
			sp_reg <= DEFAULT_SAMPLING_POINTS;
			sci_reg_sync0__axi <= DEFAULT_CLOCK_INCREMENT;
			sci_reg_sync1__axi <= DEFAULT_CLOCK_INCREMENT;
			sci_reg_sync__axi <= DEFAULT_CLOCK_INCREMENT;
		end else begin
			one_frame_trigger_sync0 <= one_frame_sampling_trigger;
			one_frame_trigger_sync1 <= one_frame_trigger_sync0;
			sci_reg_sync0__axi <= sci_reg;
			sci_reg_sync1__axi <= sci_reg_sync0__axi;
			sci_reg_sync__axi <= sci_reg_sync1__axi;
			sp_reg <= sampling_points;
		end
	end

	wire frame_trigger_rising_edge = (one_frame_trigger_sync0 && !one_frame_trigger_sync1);

	always @(posedge adc_clk) begin
		if (!adc_rst_n || software_rst_sync__adc) begin
			sci_reg_sync0 <= DEFAULT_CLOCK_INCREMENT;
			sci_reg_sync1 <= DEFAULT_CLOCK_INCREMENT;
			sci_reg <= DEFAULT_CLOCK_INCREMENT;
			system_state_sync0 <= SYSTEM_STATE__IDLE;
			system_state_sync1 <= SYSTEM_STATE__IDLE;
			system_state_sync <= SYSTEM_STATE__IDLE;
		end else begin
			sci_reg_sync0 <= sampling_clk_increment;
			sci_reg_sync1 <= sci_reg_sync0;
			sci_reg <= sci_reg_sync1;
			system_state_sync0 <= system_state;
			system_state_sync1 <= system_state_sync0;
			system_state_sync <= system_state_sync1;
		end
	end

	/* --------------------------------------- Sampling clock ---------------------------------------- */

	always @(posedge adc_clk) begin
		if (!adc_rst_n || software_rst_sync__adc) begin
			sampling_clk_reg <= FALSE;
			sampling_clk_count <= 0;
		end else begin
			if (system_state_sync == SYSTEM_STATE__SEND_STREAM) begin
				if (sampling_clk_count >= sci_reg - 1) begin
					sampling_clk_count <= 0;
					sampling_clk_reg <= ~sampling_clk_reg;
				end else begin
					sampling_clk_count <= sampling_clk_count + 1;
					sampling_clk_reg <= sampling_clk_reg;
				end
			end else begin
				sampling_clk_reg <= FALSE;
				sampling_clk_count <= 0;
			end
		end
	end

	/* ----------------------------------------------------------------------------------------------- */
	/* ---------------------------------------- System state ----------------------------------------- */
	/* ----------------------------------------------------------------------------------------------- */

	always @(posedge M_AXIS_ACLK) begin
		if (!M_AXIS_ARESETN || software_rst_sync__axi) begin
			system_state <= SYSTEM_STATE__IDLE;
		end else begin
			case (system_state)
			SYSTEM_STATE__IDLE: begin
				if (frame_trigger_rising_edge) system_state <= SYSTEM_STATE__INIT_SYNC_PARAM;
				else system_state <= system_state;
			end
			SYSTEM_STATE__INIT_SYNC_PARAM: begin
				if (sp_reg == sampling_points && sci_reg_sync__axi == sampling_clk_increment) system_state <= SYSTEM_STATE__SEND_STREAM;
				else system_state <= system_state;
			end
			SYSTEM_STATE__SEND_STREAM: begin
				if (!continuous_sampling && global_sent_points >= sp_reg) system_state <= SYSTEM_STATE__IDLE;
				else system_state <= system_state;
			end
			default: begin
				system_state <= SYSTEM_STATE__IDLE;
			end
			endcase
		end
	end

	always @(posedge M_AXIS_ACLK) begin
		if (!M_AXIS_ARESETN || software_rst_sync__axi) begin
			module_ready <= TRUE;
		end else begin
			case (system_state)
			SYSTEM_STATE__IDLE:  module_ready <= TRUE;
			SYSTEM_STATE__INIT_SYNC_PARAM: module_ready <= FALSE;
			SYSTEM_STATE__SEND_STREAM: module_ready <= FALSE;
			default: module_ready <= TRUE;
			endcase
		end
	end

	/* ----------------------------------------------------------------------------------------------- */
	/* ---------------------------------- AXI-Stream sending state ----------------------------------- */
	/* ----------------------------------------------------------------------------------------------- */

	always @(posedge M_AXIS_ACLK) begin
		if (!M_AXIS_ARESETN || software_rst_sync__axi) begin
			axis_state <= AXIS_STATE__IDLE;
			global_sent_points <= 0;
		end else begin
			case (axis_state)
			AXIS_STATE__IDLE: begin
				if (axis_sending_trigger_reg) axis_state <= AXIS_STATE__SEND_STREAM;
				else axis_state <= axis_state;
			end
			AXIS_STATE__SEND_STREAM: begin
				if (axis_hand_shake) begin
					if (axis_words_sent_points >= FRAME_WORD_NUMBER - 1) begin
						axis_state <= AXIS_STATE__IDLE;
						global_sent_points <= global_sent_points + 1;
					end
					else axis_state <= axis_state;
				end else begin
					if (axis_words_sent_points >= FRAME_WORD_NUMBER) begin
						axis_state <= AXIS_STATE__IDLE;
						global_sent_points <= global_sent_points + 1;
					end
					else axis_state <= axis_state;
				end
			end
			endcase
		end
	end

	always @(posedge M_AXIS_ACLK) begin
		if (!M_AXIS_ARESETN || software_rst_sync__axi) begin
			axis_tdata <= 0;
			axis_tlast <= FALSE;
			axis_words_sent_points <= 0;
		end else begin
			case (axis_state)
			AXIS_STATE__IDLE: begin
				axis_words_sent_points <= 0;
				axis_tdata <= FRAME_HEADER;
				axis_tlast <= FALSE;
			end
			AXIS_STATE__SEND_STREAM: begin
				if (axis_hand_shake) begin
					axis_words_sent_points <= axis_words_sent_points + 1;
					if (axis_words_sent_points <= DATA_WORD_NUMBER - 1) axis_tdata <= axis_buffer[axis_words_sent_points];
					else if (axis_words_sent_points <= DATA_WORD_NUMBER) begin
						axis_tdata <= FRAME_TAILER;
						if (!continuous_sampling && global_sent_points >= sp_reg - 1 && last_frame) axis_tlast <= TRUE;
						else axis_tlast <= FALSE;
					end else begin
						axis_tlast <= FALSE;
						axis_tdata <= 0;
					end
				end
			end
			endcase
		end
	end

	/* ----------------------------------------------------------------------------------------------- */
	/* ------------------------------------- Sampling state ------------------------------------------ */
	/* ----------------------------------------------------------------------------------------------- */

	always @(posedge M_AXIS_ACLK) begin
		if (!M_AXIS_ARESETN || software_rst_sync__axi) begin
			sampling_state <= SAMPLING_STATE__CHECK_COMPLETE;
		end else begin
			if (system_state == SYSTEM_STATE__SEND_STREAM) begin
				case (sampling_state)
				SAMPLING_STATE__CHECK_COMPLETE: begin
					if (continuous_sampling) sampling_state <= SAMPLING_STATE__WAIT_SAMPLING_START;
					else if (!continuous_sampling && global_sent_points < sp_reg) sampling_state <= SAMPLING_STATE__WAIT_SAMPLING_START;
					else sampling_state <= sampling_state;
				end
				SAMPLING_STATE__WAIT_SAMPLING_START: begin
					if (adc_a_sampling && adc_b_sampling) sampling_state <= SAMPLING_STATE__WAIT_SAMPLING_END;
					else sampling_state <= sampling_state;
				end
				SAMPLING_STATE__WAIT_SAMPLING_END: begin
					if (!adc_a_sampling && !adc_b_sampling) sampling_state <= SAMPLING_STATE__WAIT_SENDING_END;
					else sampling_state <= sampling_state;
				end
				SAMPLING_STATE__WAIT_SENDING_END: begin
					if (axis_state == AXIS_STATE__IDLE) sampling_state <= SAMPLING_STATE__PACK_DATA_TO_BUFFER;
					else sampling_state <= sampling_state;
				end
				SAMPLING_STATE__PACK_DATA_TO_BUFFER: begin
					sampling_state <= SAMPLING_STATE__TRIGGER_AXIS_SENDING;
				end
				SAMPLING_STATE__TRIGGER_AXIS_SENDING: begin
					sampling_state <= SAMPLING_STATE__WAIT_FOR_AXIS_SENDING_START;
				end
				SAMPLING_STATE__WAIT_FOR_AXIS_SENDING_START: begin
					if (axis_state == AXIS_STATE__SEND_STREAM) sampling_state <= SAMPLING_STATE__CHECK_COMPLETE;
					else sampling_state <= sampling_state;
				end
				default: begin
					sampling_state <= SAMPLING_STATE__CHECK_COMPLETE;
				end
				endcase
			end else begin
				sampling_state <= SAMPLING_STATE__CHECK_COMPLETE;
			end
		end
	end

	always @(posedge M_AXIS_ACLK) begin
		if (!M_AXIS_ARESETN || software_rst_sync__axi) begin
			axis_sending_trigger_reg <= LOW;
		end else begin
			if (system_state == SYSTEM_STATE__SEND_STREAM) begin
				case (sampling_state)
				SAMPLING_STATE__CHECK_COMPLETE: axis_sending_trigger_reg <= LOW;
				SAMPLING_STATE__WAIT_SAMPLING_START: axis_sending_trigger_reg <= LOW;
				SAMPLING_STATE__WAIT_SAMPLING_END: axis_sending_trigger_reg <= LOW;
				SAMPLING_STATE__WAIT_SENDING_END: axis_sending_trigger_reg <= LOW;
				SAMPLING_STATE__PACK_DATA_TO_BUFFER: begin
					axis_sending_trigger_reg <= LOW;
					axis_buffer[0] <= {adc_a_ch2, adc_a_ch1};
					axis_buffer[1] <= {adc_a_ch4, adc_a_ch3};
					axis_buffer[2] <= {adc_a_ch6, adc_a_ch5};
					axis_buffer[3] <= {adc_a_ch8, adc_a_ch7};

					axis_buffer[4] <= {adc_b_ch2, adc_b_ch1};
					axis_buffer[5] <= {adc_b_ch4, adc_b_ch3};
					axis_buffer[6] <= {adc_b_ch6, adc_b_ch5};
					axis_buffer[7] <= {adc_b_ch8, adc_b_ch7};
				end
				SAMPLING_STATE__TRIGGER_AXIS_SENDING: axis_sending_trigger_reg <= HIGH;
				SAMPLING_STATE__WAIT_FOR_AXIS_SENDING_START: begin
					if (axis_state == AXIS_STATE__SEND_STREAM) axis_sending_trigger_reg <= LOW;
					else axis_sending_trigger_reg <= HIGH;
				end
				default: begin
					axis_sending_trigger_reg <= LOW;
				end
				endcase
			end else begin
				axis_sending_trigger_reg <= LOW;
			end
		end
	end

    ad7606 #(

        .USR_CLK_CYCLE_NS(USR_CLK_CYCLE_NS),                      /* unit: ns, clock cycle of [usr_clk] (e.g. 20 ns for 50 MHz) */
        .T_CYCLE_NS(T_CYCLE_NS),                    /* unit: ns, t_cycle of AD7606 (refer to data sheet) */
        .T_RESET_NS(T_RESET_NS),                      /* unit: ns, t_reset of AD7606 (refer to data sheet) */
        .T_CONV_MIN_NS(T_CONV_MIN_NS),                    /* unit: ns, min t_conv of AD7606 (refer to data sheet) */
        .T_CONV_MAX_NS(T_CONV_MAX_NS),                    /* unit: ns, max t_conv of AD7606 (refer to data sheet) */
        .T1_NS(T1_NS),                      /* unit: ns, t1 of AD7606 (refer to data sheet) */
        .T2_NS(T2_NS),                      /* unit: ns, t2 of AD7606 (refer to data sheet) */
        .T10_NS(T10_NS),                      /* unit: ns, t10 of AD7606 (refer to data sheet) */
        .T11_NS(T11_NS),                      /* unit: ns, t11 of AD7606 (refer to data sheet) */
        .T14_NS(T14_NS),                      /* unit: ns, t14 of AD7606 (refer to data sheet) */
        .T15_NS(T15_NS),                       /* unit: ns, t15 of AD7606 (refer to data sheet) */
        .T26_NS(T26_NS)                       /* unit: ns, t15 of AD7606 (refer to data sheet) */

    )
    vuprs_adc_a(

        /* -------------------------------------------- User interface ------------------------------------------ */

        .usr_trigger(sampling_clk),                   /* Sample Enable, rising edge trigger, must be smaller than 100 kHz */
        .usr_clk(adc_clk),                       /* System Clock, corresponding to USR_CLK_CYCLE_NS  */
        .usr_rst(adc_rst_n),                       /* Reset this module, falling edge trigger */

        .usr_channel1(adc_a_ch1),                  /* Data of channel-V1, 16 bit */
        .usr_channel2(adc_a_ch2),                  /* Data of channel-V2, 16 bit */
        .usr_channel3(adc_a_ch3),                  /* Data of channel-V3, 16 bit */
        .usr_channel4(adc_a_ch4),                  /* Data of channel-V4, 16 bit */
        .usr_channel5(adc_a_ch5),                  /* Data of channel-V5, 16 bit */
        .usr_channel6(adc_a_ch6),                  /* Data of channel-V6, 16 bit */
        .usr_channel7(adc_a_ch7),                  /* Data of channel-V7, 16 bit */
        .usr_channel8(adc_a_ch8),                  /* Data of channel-V8, 16 bit */

        .usr_error(adc_a_err),                     /* Error flags */

        .usr_sampling(adc_a_sampling),                  /* sampling,      1 = in sampling (do not trigger); 0 = is idle */
        .usr_ready(adc_a_ready),                     /* Reset Down,    1 = complete to create a HIGH pulse for hardware RESET pin */

        /* ------------------------------------------ Hardware interface ---------------------------------------- */

        .hw_busy(adc_a_hw_busy),                       /* BUSY pin of the AD7606 chip */
        .hw_first_data(adc_a_hw_first_data),                 /* FIRSTDATA pin of the AD7606 chip  */
        .hw_data(adc_a_hw_data),                       /* D0 - D15 Pins of the AD7606 chip */

        .hw_convst(adc_a_hw_convst),                     /* CONVST pin of the AD7606 chip (CONVRST_A and CONVRST_B are connected together) */
        .hw_rd(adc_a_hw_rd),                         /* RD# pin of the AD7606 chip */
        .hw_cs(adc_a_hw_cs),                         /* CS# pin of the AD7606 chip */
        .hw_range(adc_a_hw_range),                      /* RANGE pin of the AD7606 chip */
        .hw_os(adc_a_hw_os),                         /* OS0 - OS2 pins of the AD7606 chip (Not used) */
        .hw_mode_select(adc_a_hw_mode_select),                /* PAR#/SER/BYTE_SEL pin of the AD7606 chip */
        .hw_reset(adc_a_hw_reset),                      /* RESET pin of the AD7606 chip */
        .hw_stby_n(adc_a_hw_stby_n)                      /* STBY# pin of the AD7606 */

     );

	 ad7606 #(

        .USR_CLK_CYCLE_NS(USR_CLK_CYCLE_NS),                      /* unit: ns, clock cycle of [usr_clk] (e.g. 20 ns for 50 MHz) */
        .T_CYCLE_NS(T_CYCLE_NS),                    /* unit: ns, t_cycle of AD7606 (refer to data sheet) */
        .T_RESET_NS(T_RESET_NS),                      /* unit: ns, t_reset of AD7606 (refer to data sheet) */
        .T_CONV_MIN_NS(T_CONV_MIN_NS),                    /* unit: ns, min t_conv of AD7606 (refer to data sheet) */
        .T_CONV_MAX_NS(T_CONV_MAX_NS),                    /* unit: ns, max t_conv of AD7606 (refer to data sheet) */
        .T1_NS(T1_NS),                      /* unit: ns, t1 of AD7606 (refer to data sheet) */
        .T2_NS(T2_NS),                      /* unit: ns, t2 of AD7606 (refer to data sheet) */
        .T10_NS(T10_NS),                      /* unit: ns, t10 of AD7606 (refer to data sheet) */
        .T11_NS(T11_NS),                      /* unit: ns, t11 of AD7606 (refer to data sheet) */
        .T14_NS(T14_NS),                      /* unit: ns, t14 of AD7606 (refer to data sheet) */
        .T15_NS(T15_NS),                       /* unit: ns, t15 of AD7606 (refer to data sheet) */
        .T26_NS(T26_NS)                       /* unit: ns, t15 of AD7606 (refer to data sheet) */

    )
    vuprs_adc_b(

        /* -------------------------------------------- User interface ------------------------------------------ */

        .usr_trigger(sampling_clk),                   /* Sample Enable, rising edge trigger, must be smaller than 100 kHz */
        .usr_clk(adc_clk),                       /* System Clock, corresponding to USR_CLK_CYCLE_NS  */
        .usr_rst(adc_rst_n),                       /* Reset this module, falling edge trigger */

        .usr_channel1(adc_b_ch1),                  /* Data of channel-V1, 16 bit */
        .usr_channel2(adc_b_ch2),                  /* Data of channel-V2, 16 bit */
        .usr_channel3(adc_b_ch3),                  /* Data of channel-V3, 16 bit */
        .usr_channel4(adc_b_ch4),                  /* Data of channel-V4, 16 bit */
        .usr_channel5(adc_b_ch5),                  /* Data of channel-V5, 16 bit */
        .usr_channel6(adc_b_ch6),                  /* Data of channel-V6, 16 bit */
        .usr_channel7(adc_b_ch7),                  /* Data of channel-V7, 16 bit */
        .usr_channel8(adc_b_ch8),                  /* Data of channel-V8, 16 bit */

        .usr_error(adc_b_err),                     /* Error flags */

        .usr_sampling(adc_b_sampling),                  /* sampling,      1 = in sampling (do not trigger); 0 = is idle */
        .usr_ready(adc_b_ready),                     /* Reset Down,    1 = complete to create a HIGH pulse for hardware RESET pin */

        /* ------------------------------------------ Hardware interface ---------------------------------------- */

        .hw_busy(adc_b_hw_busy),                       /* BUSY pin of the AD7606 chip */
        .hw_first_data(adc_b_hw_first_data),                 /* FIRSTDATA pin of the AD7606 chip  */
        .hw_data(adc_b_hw_data),                       /* D0 - D15 Pins of the AD7606 chip */

        .hw_convst(adc_b_hw_convst),                     /* CONVST pin of the AD7606 chip (CONVRST_A and CONVRST_B are connected together) */
        .hw_rd(adc_b_hw_rd),                         /* RD# pin of the AD7606 chip */
        .hw_cs(adc_b_hw_cs),                         /* CS# pin of the AD7606 chip */
        .hw_range(adc_b_hw_range),                      /* RANGE pin of the AD7606 chip */
        .hw_os(adc_b_hw_os),                         /* OS0 - OS2 pins of the AD7606 chip (Not used) */
        .hw_mode_select(adc_b_hw_mode_select),                /* PAR#/SER/BYTE_SEL pin of the AD7606 chip */
        .hw_reset(adc_b_hw_reset),                      /* RESET pin of the AD7606 chip */
        .hw_stby_n(adc_b_hw_stby_n)                      /* STBY# pin of the AD7606 */

     );

	// User logic ends

	endmodule
