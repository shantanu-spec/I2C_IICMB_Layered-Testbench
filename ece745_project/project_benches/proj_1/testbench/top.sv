//SHANTANU MUKHOPADHYAY_200541793 ECE 745 PROJECT 1

`timescale 1ns / 10ps
import i2c_enum_type::*;

module top();

parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;

//Defining parameters for I2C BFM
parameter int NUM_I2C_BUSSES = 1; // number of Slave buses
parameter int I2C_ADDR_WIDTH = 7; // address width of the I2C slaves
parameter int I2C_DATA_WIDTH = 8; // data width of I2C

typedef bit i2c_op_t;

bit  clk = 1'b0;
bit  rst = 1'b1;
wire cyc;
wire stb;
wire we;
tri1 ack;
wire irq;
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

bit [I2C_DATA_WIDTH-1:0] data_temp [];
bit [I2C_DATA_WIDTH-1:0] read_data [];
i2c_op_t opdata = 0;

bit transfer_complete;
bit [I2C_DATA_WIDTH-1:0] write_data[$];
bit [WB_DATA_WIDTH-1:0] read_data2 [];


// ****************************************************************************
// Clock generator fo 10 ns
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
// // Monitor Wishbone bus and display transfers in the transcript
// initial 
// begin : wb_monitoring
//   forever @(posedge clk)
//   begin
//   wb_bus.master_monitor(addr,data_mon,wenable);

//   $display("Address: %x, Data: %x, Write Enable: %b", addr, data_mon, wenable);
//   end
// end
// ****************************************************************************
//  Monitoring I2C task and display transfers in the transcript

always @(posedge clk) begin: i2c_monitoring
    bit [I2C_ADDR_WIDTH-1:0] addr;
    i2c_op_t op;
    bit [I2C_DATA_WIDTH-1:0] data [];


  i2c_bus.monitor(addr,op,data);
  if(op == 1'b0)
  $display("I2C_BUS WRITE Transfer: Address: %x, Operation: %b, Data: %p", addr,op,data);
  else 
  $display("I2C_BUS READ Transfer:  Address: %x, Operation: %b, Data: %p ", addr,op,data);

end

// ****************************************************************************
//Connecting and driving the I2C bus from DUT and testing our three cases

//Test 1
initial begin :i2c_operations 
      //for writing 32 values to i2c BUS
     i2c_bus.wait_for_i2c_transfer(opdata,write_data); 
     
    read_data=new[32];
    for(int i=0;i<32;i++) begin
    read_data[i]= 100+i;
    end

     // TEst 2reading  32 values from the I2C BUS

      i2c_bus.wait_for_i2c_transfer(opdata,write_data); 
       if (opdata == 1'b1) begin 
        i2c_bus.provide_read_data(read_data,transfer_complete);
       end

       //alternative writing and reading from 63:0 and 64:127
       read_data2 = new[1];
      for (int j = 0;j< 64;j++)
    begin
      read_data2[0] = 63 - j;

      i2c_bus.wait_for_i2c_transfer(opdata, write_data);
    
      i2c_bus.wait_for_i2c_transfer(opdata, write_data);
      if(opdata) i2c_bus.provide_read_data(read_data2, transfer_complete);

    end
end



//*****************************************************************************
//I2C Verification Project 1
initial begin :test_flow

#113 // Operation to start after the negedge reset

wb_bus.master_write(2'h0,8'b11xxxxxx); //Enable core and interrupt bit

  wb_bus.master_write(2'h1,8'b00000101);//DPR ,5 Set ID for Desired Bus
  wb_bus.master_write(2'h2,8'bxxxxx110); //CMDR set bus

  //  Step1: write 32 values from i2c bus
  wait(irq) wb_bus.master_read(2'h2,cmdr_bit); //Wait for interrupt

  $display("\nWRITING 32 VALUES TO I2C");

  //start Command
  wb_bus.master_write(2'h2,8'bxxxxx100);
  wait(irq) wb_bus.master_read(2'h2,cmdr_bit); //Wait for interrupt 
  
  wb_bus.master_write(2'h1,8'b01000100);        //set address of the slave bus 22 to DPR
  wb_bus.master_write(2'h2,8'bxxxxx001);        //write command to CMDR
  wait(irq) wb_bus.master_read(2'h2,cmdr_bit);  //Wait for interrupt


//write 32 values incrementing from 0 to 31
    for(int i = 0; i< 32; i++)
      begin
        wb_bus.master_write(2'h1,i);    // write value to the DPR  
        wb_bus.master_write(2'h2,8'bxxxxx001);  //Write Command to CMDR
        wait(irq) wb_bus.master_read(2'h2,cmdr_bit);    //Wait for interrupt

      end 
      //Stop the transmission
  wb_bus.master_write(2'h2,8'bxxxxx101);          //STOP to CMDR
  wait(irq) wb_bus.master_read(2'h2,cmdr_bit);   //Wait for interrupt


////READ DATA 100 to 131

 $display("\nREADING 32 VALUES TO I2C");

  wb_bus.master_write(2'h1,8'b00000101);          //DPR ,5 Set ID for Desired Bus
  wb_bus.master_write(2'h2,8'bxxxxx110);          //CMDR set bus
  wait(irq) wb_bus.master_read(2'h2, cmdr_bit);   //Wait for interrupt

// start command
  wb_bus.master_write(2'h2,8'bxxxxx100);  
  wait(irq) wb_bus.master_read(2'h2, cmdr_bit);   //Wait for interrupt 

  
 
  wb_bus.master_write(2'h1,8'h89);               // Sending read command to slave 0x22
  
  
  wb_bus.master_write(2'h2,8'bxxxxx001);        // write command to the CMDR
  wait(irq) wb_bus.master_read(2'h2, cmdr_bit);   //Wait for interrupt 
  

  for(int i=100; i<131; i++) begin
 
    wb_bus.master_write(2'h2, 8'bxxxxx010);
    wait(irq) wb_bus.master_read(2'h2, cmdr_bit);   //Wait for interrupt 
    wb_bus.master_read(2'h1, cmdr_bit);
  end

  // read command
  wb_bus.master_write(2'h2,8'bxxxxx011);
  wait(irq) wb_bus.master_read(2'h2, cmdr_bit);   //Wait for interrupt 
  wb_bus.master_read(2'h1, cmdr_bit);
  
  wb_bus.master_write(2'h2,8'bxxxxx101);
  wait(irq) wb_bus.master_read(2'h2, cmdr_bit);   //Wait for interrupt 


  //alternative writes and reads
  $display("\nALTERNATIVE WRITES AND READS");
  for(int i = 0;i < 64; i++) begin
    wb_bus.master_write(2'h2,8'bxxxxx100);          // Start command to CMDR
    wait(irq) wb_bus.master_read(2'h2,cmdr_bit);    // Wait for interrupt 
    wb_bus.master_write(2'h1,8'h44);                // Write byte 0x44 to the DPR
    wb_bus.master_write(2'h2,8'bxxxxx001);          // Write command to CMDR.
    wait(irq) wb_bus.master_read(2'h2,cmdr_bit);    // Wait for interrupt 
    wb_bus.master_write(2'h1, 8'd64 + i);           // increment 64 to 127
    
    
    wb_bus.master_write(2'h2, 8'b00000001);         // Write command to  CMDR
   
    wait(irq) wb_bus.master_read(2'h2,cmdr_bit);    //Wait for interrupt 
    wb_bus.master_write(2'h2,8'bxxxxx100);           // Start command to CMDR.
    wait(irq) wb_bus.master_read(2'h2,cmdr_bit);    //Wait for interrupt
    wb_bus.master_write(2'h1,8'h45);              // write 22 address.
    wb_bus.master_write(2'h2,8'bxxxxx001);          //  Write command enable
    wait(irq) wb_bus.master_read(2'h2,cmdr_bit);    //Wait for interrupt 
    wb_bus.master_write(2'h02, 8'b00000011);
    
    wait(irq) wb_bus.master_read(2'h2,cmdr_bit);      // Wait for interrupt 
    
    wb_bus.master_read(2'h1,data_temp[i]);            // write data to DPR
  end
  wb_bus.master_write(2'h2, 8'b00000101);             // STOP command

    wait(irq) wb_bus.master_read(2'h2,cmdr_bit);    //Wait for interrupt 




$finish;
      
end
//END OF PROJECT 1

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


endmodule
