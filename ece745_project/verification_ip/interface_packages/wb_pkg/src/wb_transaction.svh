class wb_transaction extends ncsu_transaction;
  `ncsu_register_object(wb_transaction)

  typedef wb_transaction this_type;
  static this_type type_handle = get_type();
    
    typedef bit [7:0] bit8;
  typedef bit8 dynamic_arr[];

  static function this_type get_type();
      if(type_handle == null)
        type_handle = new();
      return type_handle;
    endfunction

    virtual function wb_transaction get_type_handle();
       return get_type();
     endfunction

bit [WB_ADDR_WIDTH-1:0] wb_addr;
bit [WB_DATA_WIDTH-1:0] wb_data, cmdr_data;
wb_op_t wb_op;

static bit irq = 0; // in order to differentiate from wb_i2c_transaction

function new(string name="");
    super.new(name);
endfunction

virtual function string convert2string();
automatic iicmb_reg_ofst_t tmp_addr = iicmb_reg_ofst_t'(wb_addr);
automatic iicmb_cmdr_t tmp_cmd = iicmb_cmdr_t'(wb_data[2:0]);
    if(tmp_addr==CMDR)
        return {super.convert2string(),$sformatf("WISHBONE ADDRESS:CMDR WRITE ENABLE:%s DATA:%s",map_we_name[wb_op], map_cmd_name[tmp_cmd] )};
    else
        return {super.convert2string(),$sformatf("WISHBONE ADDRESS ADDRESS:%x WRITE ENABLE:%s DATA:0x%x", map_reg_ofst_name[tmp_addr],map_we_name[wb_op], wb_data)};
endfunction


virtual function this_type set_data(bit [WB_DATA_WIDTH-1:0] data);
    this.wb_data = data;
    return this;
endfunction

virtual function this_type set_addr(bit [WB_ADDR_WIDTH-1:0] addr);
    this.wb_addr = addr;
    return this;
endfunction

virtual function this_type set_op(wb_op_t OP);
    this.wb_op = OP;
    return this;
endfunction

virtual function bit [8-1:0] get_addr();
      return this.wb_addr;
endfunction

virtual function bit get_op();
      return this.wb_op;
endfunction

virtual function bit [WB_DATA_WIDTH-1:0] get_data_0();
      return this.wb_data;
endfunction

virtual function bit compare (wb_transaction rhs);
    return  (this.get_addr() == rhs.get_addr()) && (this.get_data() == rhs.get_data());

endfunction

virtual function automatic dynamic_arr get_data();
      dynamic_arr return_dyn_arr;
      return_dyn_arr = new[0];
      return_dyn_arr[0] = this.wb_data;
      return return_dyn_arr;
endfunction


endclass
