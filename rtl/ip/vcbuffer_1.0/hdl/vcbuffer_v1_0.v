
`timescale 1 ns / 1 ps

	module vcbuffer_v1_0 #
	(
		// Users to add parameters here

		parameter integer FREEZE_TIMEOUT_MS = 10,
		parameter integer AXI_CLOCK_CYCLE_NS = 8,  /* 125 MHz */

		parameter integer BRAM_DATA_WIDTH	     = 32,   /* BRAM data width */
		parameter [32: 0] CIRCULAR_BUFFER_POINTS = 512,  /* Sampling points in one access */

		parameter [31: 0] FRAME_HEADER           = 32'h0000_FFF0,
		parameter [31: 0] FRAME_TAILER           = 32'h0000_FF0F,

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 4,

		// Parameters of Axi Slave Bus Interface S00_AXIS
		parameter integer C_S00_AXIS_TDATA_WIDTH	= 32
	)
	(
		// Users to add ports here

		input wire  [BRAM_DATA_WIDTH-1: 0] bram_dout,  /* Do not used */

		output wire [BRAM_DATA_WIDTH-1: 0] bram_addr,
		output wire [BRAM_DATA_WIDTH-1: 0] bram_din,

		output wire [(BRAM_DATA_WIDTH/8)-1: 0] bram_we,

		output wire bram_clk,  /* assign to AXIS_ACLK */
		output wire bram_en,
		output wire bram_rst,

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
		input wire  s00_axis_tvalid
	);

	wire freeze;
	wire software_rst;
	wire freezed;
	wire refreshed;

// Instantiation of Axi Bus Interface S00_AXI
	vcbuffer_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH),

		.FREEZE_TIMEOUT_MS(FREEZE_TIMEOUT_MS),
		.AXI_CLOCK_CYCLE_NS(AXI_CLOCK_CYCLE_NS),
		.BRAM_DATA_WIDTH(BRAM_DATA_WIDTH)
	) vcbuffer_v1_0_S00_AXI_inst (
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

		/* internal interface */

		.freeze(freeze),
		.software_rst(software_rst),

		.freezed(freezed),
		.refreshed(refreshed),

		.bram_addr(bram_addr)
	);

// Instantiation of Axi Bus Interface S00_AXIS
	vcbuffer_v1_0_S00_AXIS # ( 
		.C_S_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH),

		.BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
		.CIRCULAR_BUFFER_POINTS(CIRCULAR_BUFFER_POINTS),

		.FRAME_HEADER(FRAME_HEADER),
		.FRAME_TAILER(FRAME_TAILER)
	) vcbuffer_v1_0_S00_AXIS_inst (
		.S_AXIS_ACLK(s00_axis_aclk),
		.S_AXIS_ARESETN(s00_axis_aresetn),
		.S_AXIS_TREADY(s00_axis_tready),
		.S_AXIS_TDATA(s00_axis_tdata),
		.S_AXIS_TSTRB(s00_axis_tstrb),
		.S_AXIS_TLAST(s00_axis_tlast),
		.S_AXIS_TVALID(s00_axis_tvalid),

		/* BRAM interface */

		.bram_dout(bram_dout),  /* Do not used */

		.bram_addr(bram_addr),
		.bram_din(bram_din),

		.bram_we(bram_we),

		.bram_clk(bram_clk),
		.bram_en(bram_en),
		.bram_rst(bram_rst),

		/* internal interface */

		.freeze(freeze),
		.software_rst(software_rst),
		.freezed(freezed),
		.refreshed(refreshed)
	);

	// Add user logic here

	// User logic ends

	endmodule
