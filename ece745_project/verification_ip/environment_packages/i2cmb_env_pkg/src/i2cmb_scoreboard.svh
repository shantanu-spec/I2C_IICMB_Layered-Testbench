class i2cmb_scoreboard extends ncsu_component#(.T(i2c_transaction));

T expected_trans;
T actual_trans;
event i2c_done;
event wb_done;

function new(string name="", ncsu_component_base parent=null);
	super.new(name,parent);
endfunction

// call from predictor
virtual function void nb_transport(input T input_trans, output T output_trans);
	    if( i2c_op_t'(input_trans.get_op()) == I2C_READ)begin
	        this.actual_trans = input_trans;
	        ncsu_info("nb_transport()",{"ACTUAL TRANSACTION: ",input_trans.convert2string()},NCSU_NONE);
		end
	    if( i2c_op_t'(input_trans.get_op()) == I2C_WRITE)begin
	        this.expected_trans = input_trans;
	        ncsu_info("nb_transport()",{"EXPECTED TRANSACTION: ",input_trans.convert2string()},NCSU_NONE);
		end
	    ->>wb_done;

endfunction

// call from i2c_agent
virtual function void nb_put(T trans);

	    if(	i2c_op_t'(trans.get_op()) == I2C_WRITE)begin
	        this.actual_trans = trans;
	        ncsu_info("nb_put()",{"ACTUAL TRANSACTION: ",trans.convert2string()},NCSU_NONE);
	    end
	    if( i2c_op_t'(trans.get_op()) == I2C_READ)begin
	        this.expected_trans = trans;
	        ncsu_info("nb_put()",{"EXPECTED TRANSACTION: ",trans.convert2string()},NCSU_NONE);
	    end
	    ->>i2c_done;

endfunction

virtual task run();

    forever begin
        fork
            begin @(i2c_done.triggered); @(wb_done.triggered); end
            begin @(wb_done.triggered); @(i2c_done.triggered); end
        join_any
		disable fork;

        if( !this.expected_trans.compare(actual_trans)) begin
			ncsu_fatal("run()",$sformatf({get_full_name()," COMPARISION ERROR HERE!"}));
		end
		if( this.expected_trans.compare(actual_trans)) ncsu_info("run()",{"TRANSACTION MATCH! ",$sformatf("ACTUAL TRANSACTION= %p, EXPECTED TRANSACTION= %p",actual_trans.get_data(),expected_trans.get_data())},NCSU_NONE);
    end

endtask

endclass
