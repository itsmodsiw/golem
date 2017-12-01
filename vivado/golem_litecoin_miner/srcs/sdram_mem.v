
`timescale 1 ns / 1 ps

module sdram_mem #
  (
   // Users to add parameters here

   // User parameters ends
   // Do not modify the parameters beyond this line

   // Width of ID for for write address, write data, read address and read data
   parameter integer C_S_AXI_ID_WIDTH = 6,
   // Width of S_AXI data bus
   parameter integer C_S_AXI_DATA_WIDTH = 64,
   // Width of S_AXI address bus
   parameter integer C_S_AXI_ADDR_WIDTH = 32
   )
   (
	// Users to add ports here

	// User ports ends
	// Do not modify the ports beyond this line

	// Global Clock Signal
	input wire                                S_AXI_ACLK,
	// Global Reset Signal. This Signal is Active LOW
	input wire                                S_AXI_ARESETN,

    input wire [C_S_AXI_ID_WIDTH-1:0]         S_AXI_AWID,

	// Write address
	input wire [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_AWADDR,
	// Burst length. The burst length gives the exact number of transfers in a burst
	input wire [7 : 0]                        S_AXI_AWLEN,
	// Burst size. This signal indicates the size of each transfer in the burst
	input wire [2 : 0]                        S_AXI_AWSIZE,
	// Burst type. The burst type and the size information,
    // determine how the address for each transfer within the burst is calculated.
	input wire [1 : 0]                        S_AXI_AWBURST,
	// Memory type. This signal indicates how transactions
    // are required to progress through a system.
	input wire [3 : 0]                        S_AXI_AWCACHE,
	// Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
	input wire [2 : 0]                        S_AXI_AWPROT,
	// Write address valid. This signal indicates that
    // the channel is signaling valid write address and
    // control information.
	input wire                                S_AXI_AWVALID,
	// Write address ready. This signal indicates that
    // the slave is ready to accept an address and associated
    // control signals.
	output wire                               S_AXI_AWREADY,
	// Write Data
	input wire [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_WDATA,
	// Write strobes. This signal indicates which byte
    // lanes hold valid data. There is one write strobe
    // bit for each eight bits of the write data bus.
	input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
	// Write last. This signal indicates the last transfer
    // in a write burst.
	input wire                                S_AXI_WLAST,
	// Write valid. This signal indicates that valid write
    // data and strobes are available.
	input wire                                S_AXI_WVALID,
	// Write ready. This signal indicates that the slave
    // can accept the write data.
	output wire                               S_AXI_WREADY,
	// Write response. This signal indicates the status
    // of the write transaction.
	output wire [1 : 0]                       S_AXI_BRESP,
	// Write response valid. This signal indicates that the
    // channel is signaling a valid write response.
	output wire                               S_AXI_BVALID,
	// Response ready. This signal indicates that the master
    // can accept a write response.
	input wire                                S_AXI_BREADY,

    output wire [C_S_AXI_ID_WIDTH-1:0]        S_AXI_BID,




	// Read address. This signal indicates the initial
    // address of a read burst transaction.
	input wire [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_ARADDR,
	// Burst length. The burst length gives the exact number of transfers in a burst
	input wire [7 : 0]                        S_AXI_ARLEN,
	// Burst size. This signal indicates the size of each transfer in the burst
	input wire [2 : 0]                        S_AXI_ARSIZE,
	// Burst type. The burst type and the size information,
    // determine how the address for each transfer within the burst is calculated.
	input wire [1 : 0]                        S_AXI_ARBURST,
	// Memory type. This signal indicates how transactions
    // are required to progress through a system.
	input wire [3 : 0]                        S_AXI_ARCACHE,
	// Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
	input wire [2 : 0]                        S_AXI_ARPROT,
	// Write address valid. This signal indicates that
    // the channel is signaling valid read address and
    // control information.
	input wire                                S_AXI_ARVALID,
	// Read address ready. This signal indicates that
    // the slave is ready to accept an address and associated
    // control signals.
	output wire                               S_AXI_ARREADY,
	// Read Data
	output wire [C_S_AXI_DATA_WIDTH-1 : 0]    S_AXI_RDATA,
	// Read response. This signal indicates the status of
    // the read transfer.
	output wire [1 : 0]                       S_AXI_RRESP,
	// Read last. This signal indicates the last transfer
    // in a read burst.
	output wire                               S_AXI_RLAST,
	// Read valid. This signal indicates that the channel
    // is signaling the required read data.
	output wire                               S_AXI_RVALID,
	// Read ready. This signal indicates that the master can
    // accept the read data and response information.
	input wire                                S_AXI_RREADY

	);

   // AXI4FULL signals
   reg [C_S_AXI_ADDR_WIDTH-1 : 0]             axi_awaddr;
   reg                                        axi_awready;
   reg                                        axi_wready;
   reg [1 : 0]                                axi_bresp;
   reg                                        axi_bvalid;
   reg [C_S_AXI_ADDR_WIDTH-1 : 0]             axi_araddr;
   reg                                        axi_arready;
   reg [5:0]                                  axi_bid;
   reg [7:0]                                  axi_arlen;


   reg [63:0]                                 read_data;
   reg                                        read_data_valid;
   reg                                        read_last;

   wire [31:0]                                read_address;
   wire                                       read_address_valid;
   wire [31:0]                                read_length;

   wire [31:0]                                write_address;
   wire                                       write_address_valid;
   wire [63:0]                                write_data;
   wire                                       write_data_valid;

   wire [C_S_AXI_DATA_WIDTH-1 : 0]            axi_rdata;
   wire [1 : 0]                               axi_rresp;
   wire                                       axi_rlast;
   wire                                       axi_rvalid;
   // aw_wrap_en determines wrap boundary and enables wrapping
   wire                                       aw_wrap_en;
   // ar_wrap_en determines wrap boundary and enables wrapping
   wire                                       ar_wrap_en;
   // aw_wrap_size is the size of the write transfer, the
   // write address wraps to a lower address if upper address
   // limit is reached
   wire                                       integer  aw_wrap_size ;
   // ar_wrap_size is the size of the read transfer, the
   // read address wraps to a lower address if upper address
   // limit is reached
   wire                                       integer  ar_wrap_size ;
   // The axi_awv_awr_flag flag marks the presence of write address valid
   reg                                        axi_awv_awr_flag;
   //The axi_arv_arr_flag flag marks the presence of read address valid
   reg                                        axi_arv_arr_flag;
   // The axi_awlen_cntr internal write address counter to keep track of beats in a burst transaction
   reg [7:0]                                  axi_awlen_cntr;
   //The axi_arlen_cntr internal read address counter to keep track of beats in a burst transaction
   reg [7:0]                                  axi_arlen_cntr;
   //local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
   //ADDR_LSB is used for addressing 32/64 bit registers/memories
   //ADDR_LSB = 2 for 32 bits (n downto 2)
   //ADDR_LSB = 3 for 42 bits (n downto 3)

   localparam integer                         ADDR_LSB = (C_S_AXI_DATA_WIDTH/32)+ 1;
   localparam integer                         OPT_MEM_ADDR_BITS = 7;

   genvar                                     i;
   genvar                                     j;
   genvar                                     mem_byte_index;

   // I/O Connections assignments

   assign S_AXI_AWREADY	= axi_awready;
   assign S_AXI_WREADY	= axi_wready;
   assign S_AXI_BRESP	= axi_bresp;
   assign S_AXI_BVALID  = axi_bvalid;
   assign S_AXI_BID  = axi_bid;

   assign S_AXI_ARREADY	= axi_arready;
   assign S_AXI_RDATA	= axi_rdata;
   assign S_AXI_RRESP	= axi_rresp;
   assign S_AXI_RLAST	= axi_rlast;
   assign S_AXI_RVALID	= axi_rvalid;
   assign  aw_wrap_size = (C_S_AXI_DATA_WIDTH/8 * (S_AXI_AWLEN));
   assign  ar_wrap_size = (C_S_AXI_DATA_WIDTH/8 * (S_AXI_ARLEN));
   assign  aw_wrap_en = ((axi_awaddr & aw_wrap_size) == aw_wrap_size)? 1'b1: 1'b0;
   assign  ar_wrap_en = ((axi_araddr & ar_wrap_size) == ar_wrap_size)? 1'b1: 1'b0;

   // Implement axi_awready generation

   // axi_awready is asserted for one S_AXI_ACLK clock cycle when both
   // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
   // de-asserted when reset is low.


   always @( posedge S_AXI_ACLK )
	 begin
	    if ( S_AXI_ARESETN == 1'b0 )
	      begin
             axi_bid          <= 0;

	      end
	    else
	      begin
             if (S_AXI_AWVALID && S_AXI_AWREADY) begin
                axi_bid <= S_AXI_AWID;

             end
	      end
	 end

   always @( posedge S_AXI_ACLK )
	 begin
	    if ( S_AXI_ARESETN == 1'b0 )
	      begin
	         axi_awready <= 1'b0;
	         axi_awv_awr_flag <= 1'b0;
	      end
	    else
	      begin
	         if (~axi_awready && S_AXI_AWVALID && ~axi_awv_awr_flag)
	           begin
	              // slave is ready to accept an address and
	              // associated control signals
	              axi_awready <= 1'b1;
	              axi_awv_awr_flag  <= 1'b1;
	              // used for generation of bresp() and bvalid
	           end
	         else if (S_AXI_WLAST && axi_wready)
	           // preparing to accept next address after current write burst tx completion
	           begin
	              axi_awv_awr_flag  <= 1'b0;
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
	         axi_awlen_cntr <= 0;
	      end
	    else
	      begin
	         if (~axi_awready && S_AXI_AWVALID && ~axi_awv_awr_flag)
	           begin
	              // address latching
	              axi_awaddr <= S_AXI_AWADDR[C_S_AXI_ADDR_WIDTH - 1:0];
	              // start address of transfer
	              axi_awlen_cntr <= 0;
	           end
	         else if((axi_awlen_cntr <= S_AXI_AWLEN) && axi_wready && S_AXI_WVALID)
	           begin

	              axi_awlen_cntr <= axi_awlen_cntr + 1;

	              case (S_AXI_AWBURST)
	                2'b00: // fixed burst
	                  // The write address for all the beats in the transaction are fixed
	                  begin
	                     axi_awaddr <= axi_awaddr;
	                     //for awsize = 4 bytes (010)
	                  end
	                2'b01: //incremental burst
	                  // The write address for all the beats in the transaction are increments by awsize
	                  begin
	                     axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
	                     //awaddr aligned to 4 byte boundary
	                     axi_awaddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};
	                     //for awsize = 4 bytes (010)
	                  end
	                2'b10: //Wrapping burst
	                  // The write address wraps when the address reaches wrap boundary
	                  if (aw_wrap_en)
	                    begin
	                       axi_awaddr <= (axi_awaddr - aw_wrap_size);
	                    end
	                  else
	                    begin
	                       axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
	                       axi_awaddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};
	                    end
	                default: //reserved (incremental burst for example)
	                  begin
	                     axi_awaddr <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
	                     //for awsize = 4 bytes (010)
	                  end
	              endcase
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
	         if ( ~axi_wready && S_AXI_WVALID && axi_awv_awr_flag)
	           begin
	              // slave can accept the write data
	              axi_wready <= 1'b1;
	           end
	         //else if (~axi_awv_awr_flag)
	         else if (S_AXI_WLAST && axi_wready)
	           begin
	              axi_wready <= 1'b0;
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
	         axi_bvalid <= 0;
	         axi_bresp <= 2'b0;
	      end
	    else
	      begin
	         if (axi_awv_awr_flag && axi_wready && S_AXI_WVALID && ~axi_bvalid && S_AXI_WLAST )
	           begin
	              axi_bvalid <= 1'b1;
	              axi_bresp  <= 2'b0;
	              // 'OKAY' response
	           end
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
	         axi_arv_arr_flag <= 1'b0;
	      end
	    else
	      begin
	         if (/*~axi_arready &&*/ S_AXI_ARVALID && ~axi_arv_arr_flag)
	           begin
	              axi_arready <= 1'b1;
	              axi_arv_arr_flag <= 1'b1;
	           end
	         else if (axi_rvalid && S_AXI_RREADY && axi_rlast)
	           // preparing to accept next address after current read completion
	           begin
	              axi_arv_arr_flag  <= 1'b0;
	           end
	         else
	           begin
	              axi_arready <= 1'b0;
	           end
	      end
	 end
   // Implement axi_araddr latching

   //This process is used to latch the address when both
   //S_AXI_ARVALID and S_AXI_RVALID are valid.
   always @( posedge S_AXI_ACLK )
	 begin
	    if ( S_AXI_ARESETN == 1'b0 )
	      begin
	         axi_araddr     <= 0;
             axi_arlen      <= 0;

	         axi_arlen_cntr <= 0;
	         //   axi_rlast <= 1'b0;
	      end
	    else
	      begin
	         if (~axi_arready && S_AXI_ARVALID && ~axi_arv_arr_flag)
	           begin
	              // address latching
	              axi_araddr     <= S_AXI_ARADDR[C_S_AXI_ADDR_WIDTH - 1:0];
	              // start address of transfer
	              axi_arlen_cntr <= 0;
                  axi_arlen      <= S_AXI_ARLEN;

	              //     axi_rlast <= 1'b0;
	           end
	         else if((axi_arlen_cntr <= axi_arlen) && axi_rvalid && S_AXI_RREADY)
	           begin

	              axi_arlen_cntr <= axi_arlen_cntr + 1;
	              //    axi_rlast <= 1'b0;

	              case (S_AXI_ARBURST)
	                2'b00: // fixed burst
	                  // The read address for all the beats in the transaction are fixed
	                  begin
	                     axi_araddr       <= axi_araddr;
	                     //for arsize = 4 bytes (010)
	                  end
	                2'b01: //incremental burst
	                  // The read address for all the beats in the transaction are increments by awsize
	                  begin
	                     axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
	                     //araddr aligned to 4 byte boundary
	                     axi_araddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};
	                     //for awsize = 4 bytes (010)
	                  end
	                2'b10: //Wrapping burst
	                  // The read address wraps when the address reaches wrap boundary
	                  if (ar_wrap_en)
	                    begin
	                       axi_araddr <= (axi_araddr - ar_wrap_size);
	                    end
	                  else
	                    begin
	                       axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
	                       //araddr aligned to 4 byte boundary
	                       axi_araddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};
	                    end
	                default: //reserved (incremental burst for example)
	                  begin
	                     axi_araddr <= axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB]+1;
	                     //for arsize = 4 bytes (010)
	                  end
	              endcase
	           end
	         /*      else if((axi_arlen_cntr == S_AXI_ARLEN) && ~axi_rlast && axi_arv_arr_flag )
	          begin
	          axi_rlast <= 1'b1;
	        end
	          else if (S_AXI_RREADY)
	          begin
	          axi_rlast <= 1'b0;
	        end
              */
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


   assign axi_rresp  = 0;
   assign axi_rvalid = read_data_valid;
   assign axi_rdata  = {read_data[7:0],read_data[15:8],read_data[23:16],read_data[31:24],read_data[39:32],read_data[47:40],read_data[55:48],read_data[63:56]};
   assign axi_rlast  = read_last;

   // ------------------------------------------
   // -- Example code to access user logic memory region
   // ------------------------------------------

   assign write_address  = axi_awaddr;
   assign write_data  = {S_AXI_WDATA[7:0],S_AXI_WDATA[15:8],S_AXI_WDATA[23:16],S_AXI_WDATA[31:24],S_AXI_WDATA[39:32],S_AXI_WDATA[47:40],S_AXI_WDATA[55:48],S_AXI_WDATA[63:56]};
   assign write_data_valid  = S_AXI_WREADY & S_AXI_WVALID;
   assign write_address_valid = S_AXI_AWREADY & S_AXI_AWVALID;

   assign read_address        = axi_araddr;
   assign read_address_valid  = axi_arready & S_AXI_ARVALID ;
   assign read_length         = S_AXI_ARLEN;



   //---------------------------------------------------------------------
   // INITIALISE TEMP MEMORY FILE
   //---------------------------------------------------------------------

   integer 				    MemFileHandle;

   initial begin
      MemFileHandle  = $fopen("../../../../TestMem.bin", "wb+");

   end
   //----------------------------------------------------------------
   // SAVE WRITE ADDRESSES
   //----------------------------------------------------------------
   reg [31:0] current_write_address;
   reg [31:0] current_read_address;

   reg [7:0]  write_counter;
   reg [7:0]  current_read_length;
   reg [31:0]  read_counter;
   reg [63:0]   read_data_raw;
   integer         count;
   reg             current_read_length_valid;

   integer         fp;


   // produce data structure for memory
   always@(posedge S_AXI_ACLK) begin
      if (S_AXI_ARESETN == 0) begin
	     current_write_address     <= 0;
         write_counter             <= 0;
         current_read_length       <= 0;
         read_counter              <= 0;
         current_read_length_valid <= 0;

         read_data                 <= 0;
         read_data_valid           <= 0;
         read_data_raw             <= 0;
         read_last                 <= 0;
         current_read_address      <= 0;



      end
      else  begin

         read_data                 <= 0;
         read_data_valid           <= 0;
         read_last                 <= 0;
         current_read_length_valid <= 0;



         if (read_address_valid) begin
            current_read_length       <= read_length;
            current_read_length_valid <= 1;
            read_counter              <= 0;
            current_read_address      <= read_address;

         end

         if (write_address_valid) begin
            current_write_address <= write_address;
            write_counter         <= 0;

         end

         if (write_data_valid) begin
            write_counter      <= write_counter+8;

            //$display("%T: Writing 0x%X to 0x%X",$time,current_write_data,(current_write_address+write_counter));
            fp = $fseek(MemFileHandle,(current_write_address+write_counter),0);
    	    for (count = 63; count >= 7 ;count=count-8) begin
	           $fwrite(MemFileHandle,"%c",write_data[count -:8]);
	        end

         end

         if (current_read_length_valid || ((read_data_valid) && (read_counter <= current_read_length))) begin
            read_counter <= read_counter + 1;

            //$display("%T: Reading from 0x%X",$time,read_address);
            fp = $fseek(MemFileHandle,current_read_address+(read_counter*8),0);
            fp = $fread(read_data_raw,MemFileHandle);
            if ($feof(MemFileHandle)  == 0) begin

               read_data                  <= read_data_raw;
            end
            else begin
               read_data <= 0;

            end


            read_data_valid   <= 1;

            if (read_counter == current_read_length)
                read_last <= 1;


         end
      end
   end


endmodule
