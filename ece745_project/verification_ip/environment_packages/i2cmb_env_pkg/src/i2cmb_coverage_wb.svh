class i2cmb_coverage_wb extends ncsu_component #(.T(wb_transaction));

i2cmb_env_configuration cfg0;

iicmb_reg_ofst_t wb_addr;
iicmb_cmdr_t iicmb_cmd;
wb_op_t wb_op;
bit [WB_DATA_WIDTH-1:0] wb_data;
CSR_REG csr_reg;
CMDR_REG cmdr_reg;


covergroup WB_coverage;
	wb_addr_offset: coverpoint wb_addr; 	
	wb_operation: coverpoint wb_op; 		
	wb_addrXop: cross wb_addr_offset, wb_operation;
endgroup

covergroup CSR_Regcoverage ;
	CSR_Enable_bit: coverpoint csr_reg.e;
	CSR_Interrupt_Enable_bit: coverpoint csr_reg.ie;
	CSR_Bus_Busy_bit: coverpoint csr_reg.bb;
	CSR_Bus_Captured_bit: coverpoint csr_reg.bc;
	CSR_Bus_ID_bits: coverpoint csr_reg.bus_id { option.auto_bin_max = 4; }
endgroup

covergroup DPR_Regcoverage;
	DPR_Data_Value: coverpoint wb_data { option.auto_bin_max = 4; }
endgroup

covergroup CMDR_coverage;
//TESTING TRANSITIONS IN WISHBONE
	CMDR_Command_transfer: coverpoint cmdr_reg.cmd iff (wb_op == WB_WRITE){
		bins legal_trans[] = (CMD_SET_BUS=>CMD_SET_BUS), (CMD_SET_BUS=>CMD_START), (CMD_SET_BUS=>CMD_STOP), (CMD_SET_BUS=>CMD_WAIT),(CMD_START=>CMD_START), (CMD_START=>CMD_WRITE), 
							(CMD_STOP=>CMD_START), (CMD_STOP=>CMD_SET_BUS), (CMD_STOP=>CMD_WAIT),(CMD_WRITE=>CMD_WRITE), (CMD_WRITE=>CMD_STOP), (CMD_WRITE=>CMD_START), (CMD_WRITE=>CMD_READ_W_NAK), (CMD_WRITE=>CMD_READ_W_AK),
							(CMD_READ_W_AK=>CMD_READ_W_AK), (CMD_READ_W_AK=>CMD_READ_W_NAK), (CMD_READ_W_AK=>CMD_START), (CMD_READ_W_AK=>CMD_STOP),(CMD_READ_W_NAK=>CMD_START), (CMD_READ_W_NAK=>CMD_STOP),
							(CMD_WAIT=>CMD_WAIT), (CMD_WAIT=>CMD_SET_BUS), (CMD_WAIT=>CMD_START), (CMD_WAIT=>CMD_STOP);
	}
endgroup


function void set_configuration(i2cmb_env_configuration cfg);
	cfg0 = cfg;
endfunction

function new(string name= "", ncsu_component_base parent = null);
	super.new(name, parent);
	WB_coverage = new;
	CSR_Regcoverage = new;
	DPR_Regcoverage = new;
	CMDR_coverage = new;
endfunction

virtual function void nb_put(T trans);
	
	if(trans.get_type_handle()==wb_transaction::get_type())begin
		$cast( wb_op , trans.get_op());
		$cast( wb_addr, trans.get_addr());
		wb_data =  trans.get_data_0();

		{cmdr_reg.don, cmdr_reg.nak, cmdr_reg.al, cmdr_reg.err, cmdr_reg.r, cmdr_reg.cmd} = wb_data;
		{csr_reg.e, csr_reg.ie, csr_reg.bb, csr_reg.bc, csr_reg.bus_id} = wb_data;
		if(wb_op == WB_READ && wb_addr==CMDR) assert(cmdr_reg.r == 1'b0) begin end else $fatal("CMDR reserved bit should never be asserted.");

		if(wb_addr==CSR)	CSR_Regcoverage.sample();
		if(wb_addr==DPR) DPR_Regcoverage.sample();
		if(wb_addr==CMDR) CMDR_coverage.sample();
		
		WB_coverage.sample();
	end
endfunction


endclass
