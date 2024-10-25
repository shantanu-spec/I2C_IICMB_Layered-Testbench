`timescale 1ns / 10ps

module top();

parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;
parameter int NUM_I2C_BUSSES = 1;

bit  clk = 1'b0;
bit  rst = 1'b1;
wire cyc;
wire stb;
wire we;
tri1 ack;
wire [WB_ADDR_WIDTH-1:0] adr;
wire [WB_DATA_WIDTH-1:0] dat_wr_o;
wire [WB_DATA_WIDTH-1:0] dat_rd_i;

tri  [NUM_I2C_BUSSES-1:0] scl;
tri  [NUM_I2C_BUSSES-1:0] sda;

//access variables for wishbone tasks
bit [WB_ADDR_WIDTH-1:0] addr;
bit [WB_DATA_WIDTH-1:0] data_mon;
bit wenable;
bit [WB_DATA_WIDTH-1:0] cmdr_bit;

//access variables for i2c tasks
// ****************************************************************************
// Clock generator
initial begin :clk_gen
  forever
  begin 
  #5 clk = ~clk;
  end
end

// ****************************************************************************
// Reset generator
initial begin : rst_gen
#113 rst  = 1'b0; 
end

// ****************************************************************************
// Monitor Wishbone bus and display transfers in the transcript
initial 
begin : wb_monitoring
  forever @(posedge clk)
  begin
  wb_bus.master_monitor(addr,data_mon,wenable);

  $display("Address: %x, Data: %x, Write Enable: %b", addr, data_mon, wenable);
  end
end

// ****************************************************************************
// // Define the flow of the simulation
initial begin : test_flow
  
//   //Example1 : Enable the IICMB core after power-up.
  #113 wb_bus.master_write(2'h00,8'b1xxxxxxx);
//   //Example3: Write a byte 0x78 to a slave with address 0x22, residing on I2C bus #5.
  wb_bus.master_write(2'h01,8'b00000101);
  wb_bus.master_write(2'h02,8'bxxxxx110);
    
//   //Wait for interrupt or until DON bit of CMDR reads '1'.
    wb_bus.master_read(2'h02,cmdr_bit);
  while(cmdr_bit[7]) @(posedge clk);
  //  while(!irq) @(posedge clk); 
  

   wb_bus.master_write(2'h02,8'bxxxxx100);

//   //Wait for interrupt or until DON bit of CMDR reads '1'.
wb_bus.master_read(2'h02,cmdr_bit);
  while(cmdr_bit[7]) @(posedge clk);


  wb_bus.master_write(2'h01,8'b01000100);

  wb_bus.master_write(2'h02,8'bxxxxx001);

// //Wait for interrupt or until DON bit of CMDR reads '1'. If instead of DON the NAK bit is '1', then slave doesn't respond.
wb_bus.master_read(2'h02,cmdr_bit);
while(cmdr_bit[7]) @(posedge clk);

  wb_bus.master_write(2'h01,8'b01111000);

  wb_bus.master_write(2'h02,8'bxxxxx001);

//   //Wait for interrupt or until DON bit of CMDR reads '1'.
wb_bus.master_read(2'h02,cmdr_bit);
while(cmdr_bit[7]) @(posedge clk);

  wb_bus.master_write(2'h02,8'bxxxxx101);

// //Wait for interrupt or until DON bit of CMDR reads '1'.
wb_bus.master_read(2'h02,cmdr_bit);
while(cmdr_bit[7]) @(posedge clk);

$finish;

end

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


endmodule
