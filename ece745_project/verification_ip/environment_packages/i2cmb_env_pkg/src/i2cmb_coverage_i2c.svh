class i2cmb_coverage_i2c extends ncsu_component #(.T(i2c_transaction));

i2cmb_env_configuration cfg0;

i2c_op_t i2c_op;
bit [I2C_ADDR_WIDTH-1:0] i2c_addr;
bit [I2C_DATA_WIDTH-1:0] i2c_data[];
int i2c_data_arr_size;

//*****************************************************************
// I2C COVERAGE

covergroup I2C_coverage;
	
	i2c_addresstest: coverpoint i2c_addr { option.auto_bin_max = 4; }

	i2c_transfer_size: coverpoint i2c_data_arr_size {
		bins one_transfer = {1};
		bins small_transfer = {[2:10]};
		bins large_transfer = {[11:$]};
	}
	
	i2c_addrXtransSize: cross i2c_addresstest, i2c_transfer_size;


endgroup

function void set_configuration(i2cmb_env_configuration cfg);
	cfg0 = cfg;
endfunction

function new(string name= "", ncsu_component_base parent = null);
	super.new(name, parent);
	I2C_coverage = new;
endfunction

virtual function void nb_put(T trans);


		$cast(i2c_op ,trans.get_op());
		i2c_addr = trans.get_addr();

		i2c_data = trans.get_data();
		i2c_data_arr_size = i2c_data.size();
	
		I2C_coverage.sample();

endfunction

endclass
