
`timescale 1 ns / 1 ps

	module vpdelay_v1_0 #
	(
		// Users to add parameters here

		parameter integer FREEZE_TIMEOUT_MS = 10,
		parameter integer AXI_CLOCK_CYCLE_NS = 8,  /* 125 MHz */

		parameter WAVE_VELOCITY_MPS              = 346,
		parameter MAXIMUM_ARRAY_SIZE_MM          = 250,
		parameter MAXIMUM_SAMPLING_FREQ_HZ       = 160_000,

		parameter [31: 0] FRAME_HEADER           = 32'h0000_FFF0,
		parameter [31: 0] FRAME_TAILER           = 32'h0000_FF0F,

		parameter ADC_DATA_WIDTH_BIT             = 16,
		parameter ADC_CHANNEL_COUNT              = 16,

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 6,

		// Parameters of Axi Slave Bus Interface S00_AXIS
		parameter integer C_S00_AXIS_TDATA_WIDTH	= 32,

		// Parameters of Axi Master Bus Interface M00_AXIS
		parameter integer C_M00_AXIS_TDATA_WIDTH	= 32,
		parameter integer C_M00_AXIS_START_COUNT	= 32
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready,

		// Ports of Axi Slave Bus Interface S00_AXIS
		input wire  s00_axis_aclk,
		input wire  s00_axis_aresetn,
		output wire  s00_axis_tready,
		input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
		input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0] s00_axis_tstrb,
		input wire  s00_axis_tlast,
		input wire  s00_axis_tvalid,

		// Ports of Axi Master Bus Interface M00_AXIS
		input wire  m00_axis_aclk,
		input wire  m00_axis_aresetn,
		output wire  m00_axis_tvalid,
		output wire [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
		output wire [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0] m00_axis_tstrb,
		output wire  m00_axis_tlast,
		input wire  m00_axis_tready,

		output wire [3:0] DEBUG_axis_state
	);

	/* M00 AXIS */

	wire send_trigger;
	
	wire [C_M00_AXIS_TDATA_WIDTH-1:0]	data_frame1;
	wire [C_M00_AXIS_TDATA_WIDTH-1:0]	data_frame2;
	wire [C_M00_AXIS_TDATA_WIDTH-1:0]	data_frame3;
	wire [C_M00_AXIS_TDATA_WIDTH-1:0]	data_frame4;
	wire [C_M00_AXIS_TDATA_WIDTH-1:0]	data_frame5;
	wire [C_M00_AXIS_TDATA_WIDTH-1:0]	data_frame6;
	wire [C_M00_AXIS_TDATA_WIDTH-1:0]	data_frame7;
	wire [C_M00_AXIS_TDATA_WIDTH-1:0]	data_frame8;

	/* S00 AXI */

	wire freezed;
	wire refreshed;

	wire [(C_S00_AXI_DATA_WIDTH/2)-1: 0] max_pdelay;

	wire freeze;
	wire software_rst;

	wire [C_S00_AXI_DATA_WIDTH-1:0]	pdelay_ch1_ch2;    /* [0: 15] pre-delay ch1, [16: 31] pre-delay ch2 */
	wire [C_S00_AXI_DATA_WIDTH-1:0]	pdelay_ch3_ch4;    /* [0: 15] pre-delay ch3, [16: 31] pre-delay ch4 */
	wire [C_S00_AXI_DATA_WIDTH-1:0]	pdelay_ch5_ch6;    /* [0: 15] pre-delay ch5, [16: 31] pre-delay ch6 */
	wire [C_S00_AXI_DATA_WIDTH-1:0]	pdelay_ch7_ch8;    /* [0: 15] pre-delay ch7, [16: 31] pre-delay ch8 */
	wire [C_S00_AXI_DATA_WIDTH-1:0]	pdelay_ch9_ch10;   /* [0: 15] pre-delay ch9, [16: 31] pre-delay ch10 */
	wire [C_S00_AXI_DATA_WIDTH-1:0]	pdelay_ch11_ch12;  /* [0: 15] pre-delay ch11, [16: 31] pre-delay ch12 */
	wire [C_S00_AXI_DATA_WIDTH-1:0]	pdelay_ch13_ch14;  /* [0: 15] pre-delay ch13, [16: 31] pre-delay ch14 */
	wire [C_S00_AXI_DATA_WIDTH-1:0]	pdelay_ch15_ch16;  /* [0: 15] pre-delay ch15, [16: 31] pre-delay ch16 */

	wire axis_send_busy;

// Instantiation of Axi Bus Interface S00_AXI
	vpdelay_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH),

		.FREEZE_TIMEOUT_MS(FREEZE_TIMEOUT_MS),
		.AXI_CLOCK_CYCLE_NS(AXI_CLOCK_CYCLE_NS)
	) vpdelay_v1_0_S00_AXI_inst (
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready),

		/* User */

		.freezed(freezed),
		.refreshed(refreshed),

		.max_pdelay(max_pdelay),

		.freeze(freeze),
		.software_rst(software_rst),

		.pdelay_ch1_ch2(pdelay_ch1_ch2),    /* [0: 15] pre-delay ch1, [16: 31] pre-delay ch2 */
	    .pdelay_ch3_ch4(pdelay_ch3_ch4),    /* [0: 15] pre-delay ch3, [16: 31] pre-delay ch4 */
	    .pdelay_ch5_ch6(pdelay_ch5_ch6),    /* [0: 15] pre-delay ch5, [16: 31] pre-delay ch6 */
	    .pdelay_ch7_ch8(pdelay_ch7_ch8),    /* [0: 15] pre-delay ch7, [16: 31] pre-delay ch8 */
	    .pdelay_ch9_ch10(pdelay_ch9_ch10),   /* [0: 15] pre-delay ch9, [16: 31] pre-delay ch10 */
	    .pdelay_ch11_ch12(pdelay_ch11_ch12),  /* [0: 15] pre-delay ch11, [16: 31] pre-delay ch12 */
	    .pdelay_ch13_ch14(pdelay_ch13_ch14),  /* [0: 15] pre-delay ch13, [16: 31] pre-delay ch14 */
	    .pdelay_ch15_ch16(pdelay_ch15_ch16)  /* [0: 15] pre-delay ch15, [16: 31] pre-delay ch16 */
	);

// Instantiation of Axi Bus Interface S00_AXIS
	vpdelay_v1_0_S00_AXIS # ( 
		.C_S_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH),

		.WAVE_VELOCITY_MPS(WAVE_VELOCITY_MPS),
		.MAXIMUM_ARRAY_SIZE_MM(MAXIMUM_ARRAY_SIZE_MM),
		.MAXIMUM_SAMPLING_FREQ_HZ(MAXIMUM_SAMPLING_FREQ_HZ),

		.FRAME_HEADER(FRAME_HEADER),
		.FRAME_TAILER(FRAME_TAILER),

		.ADC_DATA_WIDTH_BIT(ADC_DATA_WIDTH_BIT),
		.ADC_CHANNEL_COUNT(ADC_CHANNEL_COUNT),

		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH)
	) vpdelay_v1_0_S00_AXIS_inst (
		.S_AXIS_ACLK(s00_axis_aclk),
		.S_AXIS_ARESETN(s00_axis_aresetn),
		.S_AXIS_TREADY(s00_axis_tready),
		.S_AXIS_TDATA(s00_axis_tdata),
		.S_AXIS_TSTRB(s00_axis_tstrb),
		.S_AXIS_TLAST(s00_axis_tlast),
		.S_AXIS_TVALID(s00_axis_tvalid),

		/* User */

		.freeze(freeze),
		.software_rst(software_rst),
		.axis_send_busy(axis_send_busy),

		.freezed(freezed),
		.refreshed(refreshed),
		.send_trigger(send_trigger),

		.max_pdelay(max_pdelay),

		/* Pre-delay */

		.pdelay_ch1_ch2(pdelay_ch1_ch2),    /* [0: 15] pre-delay ch1, [16: 31] pre-delay ch2 */
	    .pdelay_ch3_ch4(pdelay_ch3_ch4),    /* [0: 15] pre-delay ch3, [16: 31] pre-delay ch4 */
	    .pdelay_ch5_ch6(pdelay_ch5_ch6),    /* [0: 15] pre-delay ch5, [16: 31] pre-delay ch6 */
	    .pdelay_ch7_ch8(pdelay_ch7_ch8),    /* [0: 15] pre-delay ch7, [16: 31] pre-delay ch8 */
	    .pdelay_ch9_ch10(pdelay_ch9_ch10),   /* [0: 15] pre-delay ch9, [16: 31] pre-delay ch10 */
	    .pdelay_ch11_ch12(pdelay_ch11_ch12),  /* [0: 15] pre-delay ch11, [16: 31] pre-delay ch12 */
	    .pdelay_ch13_ch14(pdelay_ch13_ch14),  /* [0: 15] pre-delay ch13, [16: 31] pre-delay ch14 */
	    .pdelay_ch15_ch16(pdelay_ch15_ch16),  /* [0: 15] pre-delay ch15, [16: 31] pre-delay ch16 */

		/* Package data frame */

		.data_frame1(data_frame1),
	    .data_frame2(data_frame2),
	    .data_frame3(data_frame3),
	    .data_frame4(data_frame4),
	    .data_frame5(data_frame5),
	    .data_frame6(data_frame6),
	    .data_frame7(data_frame7),
	    .data_frame8(data_frame8),

		.DEBUG_axis_state(DEBUG_axis_state)
	);

// Instantiation of Axi Bus Interface M00_AXIS
	vpdelay_v1_0_M00_AXIS # ( 
		.C_M_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH),
		.C_M_START_COUNT(C_M00_AXIS_START_COUNT),

		.FRAME_HEADER(FRAME_HEADER),
		.FRAME_TAILER(FRAME_TAILER)
	) vpdelay_v1_0_M00_AXIS_inst (
		.M_AXIS_ACLK(m00_axis_aclk),
		.M_AXIS_ARESETN(m00_axis_aresetn),
		.M_AXIS_TVALID(m00_axis_tvalid),
		.M_AXIS_TDATA(m00_axis_tdata),
		.M_AXIS_TSTRB(m00_axis_tstrb),
		.M_AXIS_TLAST(m00_axis_tlast),
		.M_AXIS_TREADY(m00_axis_tready),

		/* user */

		.send_trigger(send_trigger),
		.software_rst(software_rst),

		.data_frame1(data_frame1),
	    .data_frame2(data_frame2),
	    .data_frame3(data_frame3),
	    .data_frame4(data_frame4),
	    .data_frame5(data_frame5),
	    .data_frame6(data_frame6),
	    .data_frame7(data_frame7),
	    .data_frame8(data_frame8),

		.axis_send_busy(axis_send_busy)
	);

	// Add user logic here

	// User logic ends

	endmodule
