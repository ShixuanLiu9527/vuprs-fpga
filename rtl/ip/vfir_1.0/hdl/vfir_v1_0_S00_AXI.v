
`timescale 1 ns / 1 ps

	module vfir_v1_0_S00_AXI #
	(
		// Users to add parameters here

		parameter integer MAXIMUM_FILTER_LENGTH  = 512,

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 5
	)
	(
		// Users to add ports here

		output wire [C_S_AXI_DATA_WIDTH-1:0] fir_length,  /* FIR Length */
		output wire [C_S_AXI_DATA_WIDTH-1:0] fir_scale,  /* FIR Scale */

		output wire run_enable,  /* HIGH = Enable */
		output wire software_rst,  /* HIGH = Reset */

		output wire len_update_trigger,  /* all update, clear data in fir bank, rising edge trigger */
		output wire coef_update_trigger,  /* coefficient & scale update, will not clear data, rising edge trigger */

		input wire refreshed,  /* HIGH = indicate FIR data line refreshed */
		input wire len_updated,  /* HIGH = indicate LEN update completed */
		input wire coef_updated,  /* HIGH = indicate Coefficient update completed */

		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY,

		output wire [3:0] DEBUG_len_state_S_AXI,
		output wire [3:0] DEBUG_coef_state_S_AXI,

		output wire DEBUG_update_coef,
		output wire DEBUG_update_len,

		output wire [7:0] DEBUG_update_coef_count
	);

	localparam TRUE = 1'b1,
	           FALSE = 1'b0;

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 2;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 8
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;  /* Reset ([R]/W) */
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;  /* Update FIR Length ([R]/W) */
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;  /* Update FIR Coefficient ([R]/W) */
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;  /* FIR Length (R/W) */
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg4;  /* FIR Coefficient Scale Q16.16 format (R/W) */
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg5;  /* Run Status Control (R/W), [0]: run enable */
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg6;  /* Run Status (R), [0] refreshed, [1]: length updated, [2] coefficient updated */
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg7;  /* Maximum FIR Length (R) */
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;
	reg	 aw_en;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	localparam [3:0] LEN_WAIT_FOR_TRIGGER          = 4'd0,
					 LEN_WAIT_LAST_UPDATE_COMPLETE = 4'd1,
					 LEN_TRIGGER_UPDATE            = 4'd2,
					 LEN_WAIT_UPDATE_START         = 4'd3,
					 LEN_CLEAR_FLAG                = 4'd4;

	localparam [3:0] COEF_WAIT_FOR_TRIGGER          = 4'd0,
					 COEF_WAIT_LAST_UPDATE_COMPLETE = 4'd1,
					 COEF_TRIGGER_UPDATE            = 4'd2,
					 COEF_WAIT_UPDATE_START         = 4'd3,
					 COEF_CLEAR_FLAG                = 4'd4;

	reg [3:0] len_state = LEN_WAIT_FOR_TRIGGER;
	reg [3:0] coef_state = COEF_WAIT_FOR_TRIGGER;
	
	reg [7:0] update_coef_count = 0;

	reg run_enable_reg = FALSE;
	reg software_rst_reg = FALSE;

	reg software_rst_sync = FALSE;

	reg update_length = FALSE;  /* logic control */
	reg update_coef = FALSE;  /* logic control */
	reg update_length_clear_flag = FALSE;  /* logic control */
	reg update_coef_clear_flag = FALSE;  /* logic control */

	reg len_update_trigger_reg = FALSE;
	reg coef_update_trigger_reg = FALSE;

	assign len_update_trigger = len_update_trigger_reg;
	assign coef_update_trigger = coef_update_trigger_reg;
	assign software_rst = software_rst_reg;
	assign run_enable = run_enable_reg;
	assign fir_length = slv_reg3;
	assign fir_scale = slv_reg4;

	assign DEBUG_coef_state_S_AXI = coef_state;
	assign DEBUG_len_state_S_AXI = len_state;
	assign DEBUG_update_coef = update_coef;
	assign DEBUG_update_len = update_length;
	assign DEBUG_update_coef_count = update_coef_count;

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      aw_en <= 1'b1;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
	          aw_en <= 1'b0;
	        end
	        else if (S_AXI_BREADY && axi_bvalid)
	            begin
	              aw_en <= 1'b1;
	              axi_awready <= 1'b0;
	            end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // Write Address latching 
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	        begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 ) begin
	      slv_reg0 <= 0;
	      slv_reg1 <= 0;
	      slv_reg2 <= 0;
	      slv_reg3 <= 0;
	      slv_reg4 <= 0;
	      slv_reg5 <= 0;
	      slv_reg6 <= 0;
	      slv_reg7 <= MAXIMUM_FILTER_LENGTH;
		  software_rst_reg <= FALSE;
		  update_length <= FALSE;
		  update_coef <= FALSE;
		  run_enable_reg <= FALSE;
		  update_coef_count <= 0;
		end else begin
	    if (slv_reg_wren) begin
	        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          3'h0: begin
	            // for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	            //   if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	            //     // Respective byte enables are asserted as per write strobes 
	            //     // Slave register 0
	            //     slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	            //   end  
				software_rst_reg <= TRUE;
			  end
	          3'h1: begin
	            // for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	            //   if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	            //     // Respective byte enables are asserted as per write strobes 
	            //     // Slave register 1
	            //     slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	            //   end  
				update_length <= TRUE;
				update_coef_count <= update_coef_count + 1;
			  end
	          3'h2: begin
	            // for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	            //   if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	            //     // Respective byte enables are asserted as per write strobes 
	            //     // Slave register 2
	            //     slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	            //   end  
				update_coef <= TRUE;
				update_coef_count <= update_coef_count + 1;
			  end
	          3'h3:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h4:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 4
	                slv_reg4[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h5:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 5
	                slv_reg5[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h6:;
	            // for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	            //   if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	            //     // Respective byte enables are asserted as per write strobes 
	            //     // Slave register 6
	            //     slv_reg6[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	            //   end  
	          3'h7:;
	            // for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	            //   if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	            //     // Respective byte enables are asserted as per write strobes 
	            //     // Slave register 7
	            //     slv_reg7[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	            //   end  
	          default : begin
	                    //   slv_reg0 <= slv_reg0;
	                    //   slv_reg1 <= slv_reg1;
	                    //   slv_reg2 <= slv_reg2;
	                      slv_reg3 <= slv_reg3;
	                      slv_reg4 <= slv_reg4;
	                      slv_reg5 <= slv_reg5;
	                    //   slv_reg6 <= slv_reg6;
	                    //   slv_reg7 <= slv_reg7;
	                    end
	        endcase
		end else begin
		  	if (software_rst_sync) software_rst_reg <= FALSE;
			else software_rst_reg <= software_rst_reg;

			if (update_length_clear_flag) update_length <= FALSE;
			else update_length <= update_length;

			if (update_coef_clear_flag) update_coef <= FALSE;
			else update_coef <= update_coef;

			run_enable_reg <= slv_reg5[0];
			slv_reg6 <= {slv_reg6[31:11], update_coef_count, coef_updated, len_updated, refreshed};
		end
	  	end
	end    

	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end    

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
	      // Address decoding for reading registers
	      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	        3'h0   : reg_data_out <= slv_reg0;
	        3'h1   : reg_data_out <= slv_reg1;
	        3'h2   : reg_data_out <= slv_reg2;
	        3'h3   : reg_data_out <= slv_reg3;
	        3'h4   : reg_data_out <= slv_reg4;
	        3'h5   : reg_data_out <= slv_reg5;
	        3'h6   : reg_data_out <= slv_reg6;
	        3'h7   : reg_data_out <= slv_reg7;
	        default : reg_data_out <= 0;
	      endcase
	end

	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      // When there is a valid read address (S_AXI_ARVALID) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada 
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;     // register read data
	        end   
	    end
	end    

	// Add user logic here

	/* ------------------------------------------------------------------- */
	/* ------------------------------ SYNC ------------------------------- */
	/* ------------------------------------------------------------------- */

	always @(posedge S_AXI_ACLK) begin
	  	if (S_AXI_ARESETN == 1'b0) begin
			software_rst_sync <= FALSE;
		end else begin    
			software_rst_sync <= software_rst_reg;
	    end
	end

	/* -------------------------------------------------------------------- */
	/* ------------------------ LEN Update Control ------------------------ */
	/* -------------------------------------------------------------------- */

	/* flags */

	always @(posedge S_AXI_ACLK) begin
	  	if (S_AXI_ARESETN == 1'b0 || software_rst_reg) begin
			len_state <= LEN_WAIT_FOR_TRIGGER;
		end else begin    
			case (len_state)
			LEN_WAIT_FOR_TRIGGER: begin
				if (update_length) len_state <= LEN_WAIT_LAST_UPDATE_COMPLETE;
				else len_state <= len_state;
			end
			LEN_WAIT_LAST_UPDATE_COMPLETE: begin
				if (len_updated) len_state <= LEN_TRIGGER_UPDATE;
				else len_state <= len_state;
			end
			LEN_TRIGGER_UPDATE: begin
				len_state <= LEN_WAIT_UPDATE_START;
			end
			LEN_WAIT_UPDATE_START: begin
				if (len_updated) len_state <= len_state;
				else len_state <= LEN_CLEAR_FLAG;
			end
			LEN_CLEAR_FLAG: begin
				if (update_length) len_state <= len_state;
				else len_state <= LEN_WAIT_FOR_TRIGGER;
			end
			default: len_state <= LEN_WAIT_FOR_TRIGGER;
			endcase
	    end
	end

	/* registers */

	always @(posedge S_AXI_ACLK) begin
	  	if (S_AXI_ARESETN == 1'b0 || software_rst_reg) begin
			update_length_clear_flag <= FALSE;
			len_update_trigger_reg <= FALSE;
		end else begin
			case (len_state)
			LEN_WAIT_FOR_TRIGGER: begin
				update_length_clear_flag <= FALSE;
				len_update_trigger_reg <= FALSE;
			end
			LEN_WAIT_LAST_UPDATE_COMPLETE: begin
				update_length_clear_flag <= FALSE;
				len_update_trigger_reg <= FALSE;
			end
			LEN_TRIGGER_UPDATE: begin
				update_length_clear_flag <= FALSE;
				len_update_trigger_reg <= TRUE;
			end
			LEN_WAIT_UPDATE_START: begin
				update_length_clear_flag <= FALSE;
				if (len_updated) len_update_trigger_reg <= TRUE;
				else len_update_trigger_reg <= FALSE;
			end
			LEN_CLEAR_FLAG: begin
				if (update_length) update_length_clear_flag <= TRUE;
				else update_length_clear_flag <= FALSE;
				len_update_trigger_reg <= FALSE;
			end
			default: begin
				update_length_clear_flag <= FALSE;
				len_update_trigger_reg <= FALSE;
			end
			endcase
	    end
	end

	/* --------------------------------------------------------------------- */
	/* ------------------------ COEF Update Control ------------------------ */
	/* --------------------------------------------------------------------- */

	/* flags */

	always @(posedge S_AXI_ACLK) begin
	  	if (S_AXI_ARESETN == 1'b0 || software_rst_reg) begin
			coef_state <= COEF_WAIT_FOR_TRIGGER;
		end else begin
			case (coef_state)
			COEF_WAIT_FOR_TRIGGER: begin
				if (update_coef) coef_state <= COEF_WAIT_LAST_UPDATE_COMPLETE;
				else coef_state <= coef_state;
			end
			COEF_WAIT_LAST_UPDATE_COMPLETE: begin
				if (coef_updated) coef_state <= COEF_TRIGGER_UPDATE;
				else coef_state <= coef_state;
			end
			COEF_TRIGGER_UPDATE: begin
				coef_state <= COEF_WAIT_UPDATE_START;
			end
			COEF_WAIT_UPDATE_START: begin
				if (coef_updated) coef_state <= coef_state;
				else coef_state <= COEF_CLEAR_FLAG;
			end
			COEF_CLEAR_FLAG: begin
				if (update_coef) coef_state <= coef_state;
				else coef_state <= COEF_WAIT_FOR_TRIGGER;
			end
			default: coef_state <= COEF_WAIT_FOR_TRIGGER;
			endcase
	    end
	end

	/* registers */

	always @(posedge S_AXI_ACLK) begin
	  	if (S_AXI_ARESETN == 1'b0 || software_rst_reg) begin
			update_coef_clear_flag <= FALSE;
			coef_update_trigger_reg <= FALSE;
		end else begin
			case (coef_state)
			COEF_WAIT_FOR_TRIGGER: begin
				update_coef_clear_flag <= FALSE;
				coef_update_trigger_reg <= FALSE;
			end
			COEF_WAIT_LAST_UPDATE_COMPLETE: begin
				update_coef_clear_flag <= FALSE;
				coef_update_trigger_reg <= FALSE;
			end
			COEF_TRIGGER_UPDATE: begin
				update_coef_clear_flag <= FALSE;
				coef_update_trigger_reg <= TRUE;
			end
			COEF_WAIT_UPDATE_START: begin
				update_coef_clear_flag <= FALSE;
				if (coef_updated) coef_update_trigger_reg <= TRUE;
				else coef_update_trigger_reg <= FALSE;
			end
			COEF_CLEAR_FLAG: begin
				if (update_coef) update_coef_clear_flag <= TRUE;
				else update_coef_clear_flag <= FALSE;
				coef_update_trigger_reg <= FALSE;
			end
			default: begin
				update_coef_clear_flag <= FALSE;
				coef_update_trigger_reg <= FALSE;
			end
			endcase
	    end
	end

	// User logic ends

	endmodule
