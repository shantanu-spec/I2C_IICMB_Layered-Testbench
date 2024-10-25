//Shantanu Mukhopadhyay_200541793 ECE 745 Project 2

`timescale 1ns / 10ps
import i2c_enum_type::*;
import ncsu_pkg::*;
import i2c_pkg::*;
import wb_pkg::*;
import i2cmb_env_pkg::*;

module top();

parameter int WB_ADDR_WIDTH = 32;
parameter int WB_DATA_WIDTH = 16;

//Defining parameters for I2C BFM
parameter int NUM_I2C_BUSSES = 1; // number of Slave buses
parameter int I2C_ADDR_WIDTH = 7; // address width of the I2C slaves
parameter int I2C_DATA_WIDTH = 8; // data width of I2C

bit  clk = 1'b0;
bit  rst = 1'b1;
wire cyc;
wire stb;
wire we;
tri1 ack;
wire irq;
wire [1:0] adr;
wire [7:0] dat_wr_o;
wire [7:0] dat_rd_i;

tri  [NUM_I2C_BUSSES-1:0] scl;
tri  [NUM_I2C_BUSSES-1:0] sda;


//instantiating the i2cmb_test class
i2cmb_test test;

// ****************************************************************************
// Clock generator
initial begin : clk_gen
  forever
  begin 
  #5 clk = ~clk;
  end
end

// ****************************************************************************
// Reset generator afte 113 ns
initial begin : rst_gen
#113 rst  = 1'b0; 
end
// ****************************************************************************
// Instantiating the Wishbone master Bus Functional Model
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
  // Shred signals
  .dat_o(dat_wr_o),
  .dat_i(dat_rd_i)
  );

// ****************************************************************************
//Instantiate the I2C BFM
i2c_if #(
  .I2C_ADDR_WIDTH(I2C_ADDR_WIDTH),
  .I2C_DATA_WIDTH(I2C_DATA_WIDTH)
)
i2c_bus(
  //I2c signals
  .scl_i(scl),
  .sda_i(sda)
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
    // -- I2C interfaces:
    .scl_i(scl),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
    .sda_i(sda),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
    .scl_o(scl),         //   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
    .sda_o(sda)          //   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
    // ------------------------------------
  );

initial begin : test_flow
/*• Place virtual interface handles into ncsu_config_db
• Construct the test class
• Execute the run task of the test after reset is released
• Execute $finish after test complete*/

    ncsu_config_db#(virtual wb_if)::set("test.env.wb_agent", wb_bus);
    ncsu_config_db#(virtual i2c_if)::set("test.env.i2c_agent", i2c_bus);

    test = new("test",null);
    wait ( rst == 1);


    test.run(); 
    $finish();
  end

endmodule