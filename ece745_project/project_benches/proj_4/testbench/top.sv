`timescale 1ns / 10ps
module top();

import ncsu_pkg::*;
import wb_pkg::*;
import i2c_pkg::*;
import i2cmb_env_pkg::*;

bit  clk = 1'b0;
bit  rst = 1'b1;
wire cyc;
wire stb;
wire we;
tri  ack;
wire irq;
wire [WB_ADDR_WIDTH-1:0] adr;
wire [WB_DATA_WIDTH-1:0] dat_wr_o;
wire [WB_DATA_WIDTH-1:0] dat_rd_i;

tri  [NUM_I2C_BUSSES] scl;
tri  [NUM_I2C_BUSSES] sda;

iicmb_reg_ofst_t    adr_enum;
iicmb_cmdr_t        dat_o_enum;

//Initialize the test to run the respected tests
i2cmb_test test;

assign adr_enum = iicmb_reg_ofst_t'(adr);
always @ (posedge clk) begin
    dat_o_enum <= (we==WB_WRITE && adr_enum == CMDR)? iicmb_cmdr_t'(dat_wr_o) : dat_o_enum ;
end

// ****************************************************************************
// Clock generator
initial begin : clk_gen
    forever
     #5 clk = ~clk;
end

// ****************************************************************************
// Reset generator afte 113 ns
initial begin : rst_gen
#113 rst  = 1'b0; 
end

// ****************************************************************************

// ****************************************************************************
// Instantiate the I2C slave Bus Functional Model
i2c_if      #(
    .I2C_ADDR_WIDTH(I2C_ADDR_WIDTH),
    .I2C_DATA_WIDTH(I2C_DATA_WIDTH),
    .SLAVE_ADDRESS(I2C_SLAVE_ADDRESS)
)
i2c_bus (
  // Slave signals
  .scl_i(scl[ I2C_BUS_ID ]),
  .sda_i(sda[ I2C_BUS_ID ])
);
// ****************************************************************************
// Instantiate the Wishbone master Bus Functional Model
wb_if       #(
      .ADDR_WIDTH(WB_ADDR_WIDTH),
      .DATA_WIDTH(WB_DATA_WIDTH)
)
wb_bus (
  // System sigals
  .clk_i(clk),
  .rst_i(rst),
  .irq_i(irq),
  // Master signals
  .cyc_o(cyc),
  .stb_o(stb),
  .ack_i(ack),
  .adr_o(adr),
  .we_o(we),
  // Slave signals
  .cyc_i(),
  .stb_i(),
  .ack_o(),
  .adr_i(),
  .we_i(),
  // Shared signals
  .dat_o(dat_wr_o),
  .dat_i(dat_rd_i)
  );


// ****************************************************************************
// Instantiate the DUT - I2C Multi-Bus Controller
\work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_BUSSES)) DUT
  (
    // ------------------------------------
    // -- Wishbone signals:
    .clk_i(clk),         // in    std_logic;                            -- Clock
    .rst_i(rst),         // in    std_logic;                            -- Synchronous reset (active high)
    // -------------
    .cyc_i(cyc),         // in    std_logic;                            -- Valid bus cycle indication
    .stb_i(stb),         // in    std_logic;                            -- Slave selection
    .ack_o(ack),         //   out std_logic;                            -- Acknowledge output
    .adr_i(adr),         // in    std_logic_vector(1 downto 0);         -- Low bits of Wishbone address
    .we_i(we),           // in    std_logic;                            -- Write enable
    .dat_i(dat_wr_o),    // in    std_logic_vector(7 downto 0);         -- Data input
    .dat_o(dat_rd_i),    //   out std_logic_vector(7 downto 0);         -- Data output
    // ------------------------------------
    // ------------------------------------
    // -- Interrupt request:
    .irq(irq),           //   out std_logic;                            -- Interrupt request
    // ------------------------------------
    // ------------------------------------
    // -- I2C master interfaces:
    .scl_i(scl),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
    .sda_i(sda),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
    .scl_o(scl),         //   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
    .sda_o(sda)          //   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
    // ------------------------------------
  );

// ****************************************************************************
// Instantiate the assertion checker interface
assert_checker  #( .NUM_I2C_BUSSES(NUM_I2C_BUSSES) ) assert_checker_DUT (
    // System signals
    .clk_i(clk),
    .rst_i(rst),
    .irq_i(irq),
    // Master signals
    .cyc_o(cyc),
    .stb_o(stb),
    .ack_i(ack),
    .adr_o(adr),
    .we_o(we),
    // Shared signals
    .dat_o(dat_wr_o),
    .dat_i(dat_rd_i),
    // I2C signal
    .scl_i(scl),
    .sda_i(sda)
);


initial begin : test_flow
/*• Place virtual interface handles into ncsu_config_db
• Construct the test class
• Execute the run task of the test after reset is released
• Execute $finish after test complete*/

    ncsu_config_db#(virtual wb_if#(.ADDR_WIDTH(WB_ADDR_WIDTH), .DATA_WIDTH(WB_DATA_WIDTH)))::set("wb_interface", wb_bus);
    ncsu_config_db#(virtual i2c_if#(.I2C_ADDR_WIDTH(I2C_ADDR_WIDTH), .I2C_DATA_WIDTH(I2C_DATA_WIDTH)))::set("i2c_interface", i2c_bus);

    test = new("test", null);
    wait( rst==0 );
    test.run();
   $finish;
end

endmodule
