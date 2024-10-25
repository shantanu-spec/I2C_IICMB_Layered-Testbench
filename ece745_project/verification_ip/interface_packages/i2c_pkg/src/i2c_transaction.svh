class i2c_transaction extends  ncsu_transaction; 
	`ncsu_register_object(i2c_transaction)

	typedef i2c_transaction this_type;
    static this_type type_handle = get_type();
  
  typedef bit [7:0] bit8;
  typedef bit8 dynamic_arr_t[];

    static function this_type get_type();
        if(type_handle == null)
          type_handle = new();
        return type_handle;
      endfunction

      virtual function i2c_transaction get_type_handle();
         return get_type();
       endfunction

	bit [I2C_DATA_WIDTH-1:0] i2c_data [];
	bit [I2C_ADDR_WIDTH-1:0] i2c_addr;
	i2c_op_t i2c_op;
	bit ack;
	  bit       transfer_complete;    


	function new(string name = "");
		super.new(name);
	endfunction : new

	virtual function string convert2string();
		if(this.i2c_op == I2C_WRITE)
			return {super.convert2string(), $sformatf("I2C WRITE DATA: %p", i2c_data)};
		else
			return {super.convert2string(), $sformatf("I2C READ DATA: %p", i2c_data)};
	endfunction

	virtual function bit compare (i2c_transaction rhs);
		return  (this.get_addr() == rhs.get_addr()) && (this.get_data() == rhs.get_data());
	endfunction

	virtual function this_type set_data(bit [I2C_DATA_WIDTH-1:0] data_buffer [$]);
		this.i2c_data = new [data_buffer.size()];
		this.i2c_data = {>>{data_buffer}};
		return this;
	endfunction

 

	function this_type set_op(i2c_op_t op);
		this.i2c_op = op;
		return this;
	endfunction

	virtual function bit [8-1:0] get_addr();
		
	      return {this.ack, this.i2c_addr};
	endfunction

	virtual function bit get_op();
	      return this.i2c_op;
	endfunction

	virtual function bit [8-1:0] get_data_0();
	      return this.i2c_data[0];
	endfunction

	virtual function dynamic_arr_t get_data();
		dynamic_arr_t return_dyn_arr;
          return_dyn_arr = i2c_data;
          return return_dyn_arr;
    endfunction

  virtual function void add_to_wave(int transaction_viewing_stream_h);
    super.add_to_wave(transaction_viewing_stream_h);
    $add_attribute(transaction_view_h, i2c_op, "op");
    $add_attribute(transaction_view_h, i2c_addr, "addr");
    $add_attribute(transaction_view_h, i2c_data[0], "data");
  
 

    $free_transaction(transaction_view_h);
  endfunction

endclass
