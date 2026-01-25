
`timescale 1 ns / 1 ps

	module vfir_v1_0 #
	(
		// Users to add parameters here

		parameter integer MAXIMUM_FILTER_LENGTH  = 512,
		parameter integer BRAM_DATA_WIDTH	     = 32,   /* BRAM data width */

		parameter [31: 0] FRAME_HEADER           = 32'h0000_FFF0,
		parameter [31: 0] FRAME_TAILER           = 32'h0000_FF0F,

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 5,

		// Parameters of Axi Slave Bus Interface S00_AXIS
		parameter integer C_S00_AXIS_TDATA_WIDTH	= 32,

		// Parameters of Axi Master Bus Interface M00_AXIS
		parameter integer C_M00_AXIS_TDATA_WIDTH	= 32,
		parameter integer C_M00_AXIS_START_COUNT	= 32
	)
	(
		// Users to add ports here

		input wire  [BRAM_DATA_WIDTH-1:0] bram_dout,
		output wire [BRAM_DATA_WIDTH-1:0] bram_addr,
		output wire [BRAM_DATA_WIDTH-1:0] bram_din,  /* not in use */
		output wire [(BRAM_DATA_WIDTH/8)-1:0] bram_we,
		output wire bram_clk,  /* assign to AXIS_ACLK */
		output wire bram_en,
		output wire bram_rst,  /* Do not used */

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
		input wire  m00_axis_tready
	);

	wire [C_S00_AXI_DATA_WIDTH-1:0] fir_length;  /* FIR Length */
	wire [C_S00_AXI_DATA_WIDTH-1:0] fir_scale;  /* FIR Scale */

	wire run_enable;  /* HIGH = Run enable */
	wire software_rst;  /* HIGH = Reset */

	wire len_update_trigger;  /* all update, clear data in fir bank, rising edge trigger */
	wire coef_update_trigger;  /* coefficient & scale update, will not clear data, rising edge trigger */

	wire refreshed;  /* HIGH = indicate FIR data line refreshed */
	wire len_updated;  /* HIGH = indicate LEN update completed */
	wire coef_updated;  /* HIGH = indicate Coefficient update completed */

	wire axis_sending_busy;  /* HIGH = axis master is sending */
	wire axis_trigger_sending;  /* Trigger axis master to send, rising edge trigger */
	wire signed [C_S00_AXIS_TDATA_WIDTH-1:0] fir_output;  /* FIR output */

// Instantiation of Axi Bus Interface S00_AXI
	vfir_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH),
		.MAXIMUM_FILTER_LENGTH(MAXIMUM_FILTER_LENGTH)
	) vfir_v1_0_S00_AXI_inst (
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

		/* Internal connection */

		.fir_length(fir_length),  /* FIR Length */
		.fir_scale(fir_scale),  /* FIR Scale */

		.run_enable(run_enable),  /* HIGH = Enable */
		.software_rst(software_rst),  /* HIGH = Reset */

		.len_update_trigger(len_update_trigger),  /* all update, clear data in fir bank, rising edge trigger */
		.coef_update_trigger(coef_update_trigger),  /* coefficient & scale update, will not clear data, rising edge trigger */

		.refreshed(refreshed),  /* HIGH = indicate FIR data line refreshed */
		.len_updated(len_updated),  /* HIGH = indicate LEN update completed */
		.coef_updated(coef_updated)  /* HIGH = indicate Coefficient update completed */

	);

// Instantiation of Axi Bus Interface S00_AXIS
	vfir_v1_0_S00_AXIS # ( 
		.C_S_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH),
		.BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),   /* BRAM data width */
		.MAXIMUM_FILTER_LENGTH(MAXIMUM_FILTER_LENGTH),
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.FRAME_HEADER(FRAME_HEADER),
		.FRAME_TAILER(FRAME_TAILER)
	) vfir_v1_0_S00_AXIS_inst (
		.S_AXIS_ACLK(s00_axis_aclk),
		.S_AXIS_ARESETN(s00_axis_aresetn),
		.S_AXIS_TREADY(s00_axis_tready),
		.S_AXIS_TDATA(s00_axis_tdata),
		.S_AXIS_TSTRB(s00_axis_tstrb),
		.S_AXIS_TLAST(s00_axis_tlast),
		.S_AXIS_TVALID(s00_axis_tvalid),

		/* Internal wire */

		.fir_length(fir_length),  /* FIR Length */
		.fir_scale(fir_scale),  /* FIR Scale */

		.run_enable(run_enable),  /* HIGH = Run enable */
		.software_rst(software_rst),  /* HIGH = Reset */

		.len_update_trigger(len_update_trigger),  /* all update, clear data in fir bank, rising edge trigger */
		.coef_update_trigger(coef_update_trigger),  /* coefficient & scale update, will not clear data, rising edge trigger */

		.refreshed(refreshed),  /* HIGH = indicate FIR data line refreshed */
		.len_updated(len_updated),  /* HIGH = indicate LEN update completed */
		.coef_updated(coef_updated),  /* HIGH = indicate Coefficient update completed */

		.axis_sending_busy(axis_sending_busy),  /* HIGH = axis master is sending */
		.axis_trigger_sending(axis_trigger_sending),  /* Trigger axis master to send, rising edge trigger */
		.fir_output(fir_output),  /* FIR output */

		/* BRAM control */

		.bram_dout(bram_dout),

		.bram_addr(bram_addr),
		.bram_din(bram_din),  /* not in use */

		.bram_we(bram_we),

		.bram_clk(bram_clk),  /* assign to AXIS_ACLK */
		.bram_en(bram_en),
		.bram_rst(bram_rst)  /* Do not used */
	);

// Instantiation of Axi Bus Interface M00_AXIS
	vfir_v1_0_M00_AXIS # ( 
		.C_M_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH),
		.C_M_START_COUNT(C_M00_AXIS_START_COUNT)
	) vfir_v1_0_M00_AXIS_inst (
		.M_AXIS_ACLK(m00_axis_aclk),
		.M_AXIS_ARESETN(m00_axis_aresetn),
		.M_AXIS_TVALID(m00_axis_tvalid),
		.M_AXIS_TDATA(m00_axis_tdata),
		.M_AXIS_TSTRB(m00_axis_tstrb),
		.M_AXIS_TLAST(m00_axis_tlast),
		.M_AXIS_TREADY(m00_axis_tready),

		/* Internal connection */

		.axis_sending_busy(axis_sending_busy),  /* HIGH = axis master is sending */
		.axis_trigger_sending(axis_trigger_sending),  /* Trigger axis master to send */
		.fir_output(fir_output),
		.software_rst(software_rst)
	);

	// Add user logic here

	// User logic ends

	endmodule
