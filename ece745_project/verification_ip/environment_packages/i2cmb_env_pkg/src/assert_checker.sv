import ncsu_pkg::*;
import wb_pkg::*;
import i2c_pkg::*;
import i2cmb_env_pkg::*;

interface assert_checker #(
    parameter NUM_I2C_BUSSES = 1
)(
    // System sigals
    input wire clk_i,
    input wire rst_i,
    input wire irq_i,
    // wb master sigals
    input wire cyc_o,
    input wire stb_o,
    input wire ack_i,
    input wire [WB_ADDR_WIDTH-1:0] adr_o,
    input wire we_o,
    // Shared signals
    input wire [WB_DATA_WIDTH-1:0] dat_o,
    input wire [WB_DATA_WIDTH-1:0] dat_i,
    // I2C sigals
    input wire [NUM_I2C_BUSSES-1:0] scl_i,
    input wire [NUM_I2C_BUSSES-1:0] sda_i
);

CMDR_REG cmdr_reg;
CSR_REG csr_reg;
FSMR_REG fsmr_reg = FSMR_REG'(8'd0);
logic DUT_executing_cmd;
logic rd_handshake;
logic wr_handshake;

assign rd_handshake = cyc_o & stb_o & (we_o==WB_READ) & ack_i;
assign wr_handshake = cyc_o & stb_o & (we_o==WB_WRITE) & ack_i;
assign DUT_finish_cmd = cmdr_reg.don|cmdr_reg.nak|cmdr_reg.al|cmdr_reg.err;

always @ (*)begin
        if(adr_o==CSR && wr_handshake) {csr_reg.e, csr_reg.ie, csr_reg.bb, csr_reg.bc, csr_reg.bus_id} = {dat_o[7:6],6'd0};
        else csr_reg = csr_reg;
end
//ASSERTION CHECKER
property irq_not_set_when_irq_bit_reset;
	@(posedge clk_i) !csr_reg.ie |-> !irq_i;
endproperty

assert property(irq_not_set_when_irq_bit_reset) else $fatal("INTERRUPT GENERATED WHEN IE BIT WAS RESET");


always @ (*) begin
    if(adr_o==CMDR && rd_handshake) {cmdr_reg.don, cmdr_reg.nak, cmdr_reg.al, cmdr_reg.err, cmdr_reg.r, cmdr_reg.cmd} = dat_o;
    else cmdr_reg = cmdr_reg;
end


property cmdr_reserve_assert;
    @(posedge clk_i) !cmdr_reg.r;
endproperty

assert property(cmdr_reserve_assert) else $fatal("CMDR REGISTER RESERVED BIT SHOULD NEVER BEEN ASSERTED %p",cmdr_reg);

property dut_never_undefined;
    @(posedge clk_i) !( (!DUT_finish_cmd) && (cmdr_reg.cmd==CMD_NO_USED) );
endproperty

assert property(dut_never_undefined) else $fatal("DUT SHOULD NEVER REQUEST UNDEFINED COMMAND!. %p",cmdr_reg);


endinterface 
