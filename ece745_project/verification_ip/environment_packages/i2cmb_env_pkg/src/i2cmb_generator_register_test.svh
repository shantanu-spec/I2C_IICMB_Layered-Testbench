class i2cmb_generator_register_test extends i2cmb_generator;
`ncsu_register_object(i2cmb_generator_register_test)

bit [7:0] reset_value[iicmb_reg_ofst_t];
bit [7:0] mask_value[iicmb_reg_ofst_t]; 

function new(string name="", ncsu_component_base parent=null);
	super.new(name, parent);

	reset_value[CSR] = 8'h00;
	reset_value[DPR] = 8'h00;
	reset_value[CMDR] = 8'h80;
	reset_value[FSMR] = 8'h00;

	mask_value[CSR] = 8'hc0;
	mask_value[DPR] = 8'h00; 
	mask_value[CMDR] = 8'h17;

	mask_value[FSMR] = 8'h00;

endfunction

virtual task run();


    $display("\n****************************************************************************************");
    $display("                       TEST : REGISTER BLOCK TEST START          ");
    $display("****************************************************************************************\n");

    $display("\n********************** CASE 1.TEST REGISTER RESET VALUE AFTER SYSTEM RESET **********************\n");

    // test order: FSMR(3) -> CMDR(2) -> DPR(1)-> CSR(0)
    for(int i=3; i>=0 ;i--)begin
        automatic iicmb_reg_ofst_t addr_ofst = iicmb_reg_ofst_t'(i);
        super.wb_agt0.bl_put_ref(trans_r[addr_ofst]);
        assert(trans_r[addr_ofst].wb_data == reset_value[addr_ofst])  $display("{\n%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b           TEST CORRECT\n", map_reg_ofst_name[addr_ofst], trans_r[addr_ofst].wb_data);
    	else $fatal("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b          TEST INCORRECT", map_reg_ofst_name[addr_ofst],trans_r[addr_ofst].wb_data);
    end

    // enable core
    void'(trans_w[CSR].set_data( CSR_E | CSR_IE));
	super.wb_agt0.bl_put_ref(trans_w[CSR]);

    $display("\n**********************CASE 2.TEST REGISTER RESET VALUE AFTER ENABLE CORE ************************\n");

    // test order: FSMR(3) -> CMDR(2) -> DPR(1)-> CSR(0)
    for(int i=3; i>=0 ;i--)begin
        automatic iicmb_reg_ofst_t addr_ofst = iicmb_reg_ofst_t'(i);
        super.wb_agt0.bl_put_ref(trans_r[addr_ofst]);
        if(addr_ofst == CSR)begin
            assert(trans_r[addr_ofst].wb_data == mask_value[CSR] )  $display("{\n%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b             TEST CORRECT\n", map_reg_ofst_name[iicmb_reg_ofst_t'(addr_ofst)], trans_r[addr_ofst].wb_data);
            else $fatal("{%s REGISTER DEFAULT VALUE AFTER RESET CORE}           TEST INCORRECT :%b", map_reg_ofst_name[iicmb_reg_ofst_t'(addr_ofst)],trans_r[addr_ofst].wb_data);
        end else begin
            assert(trans_r[addr_ofst].wb_data == reset_value[addr_ofst])  $display("{\n%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b           TEST CORRECT\n", map_reg_ofst_name[iicmb_reg_ofst_t'(addr_ofst)], trans_r[addr_ofst].wb_data);
            else $fatal("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b          TEST INCORRECT", map_reg_ofst_name[iicmb_reg_ofst_t'(addr_ofst)],trans_r[addr_ofst].wb_data);
        end
    end

  
  

    // reset core
    void'(trans_w[CSR].set_data( (~CSR_E) & (~CSR_IE) ));
    super.wb_agt0.bl_put_ref(trans_w[CSR]);

  
    for(int i=3; i>=0 ;i--)begin
        automatic iicmb_reg_ofst_t addr_ofst = iicmb_reg_ofst_t'(i);
        void'(trans_w[addr_ofst].set_data( 8'hff ));
        super.wb_agt0.bl_put_ref(trans_w[addr_ofst]);

        super.wb_agt0.bl_put_ref(trans_r[addr_ofst]);
    end

 

    // enable core
    void'(trans_w[CSR].set_data( CSR_E | CSR_IE));
    super.wb_agt0.bl_put_ref(trans_w[CSR]);

    // test order: FSMR(3) -> CMDR(2) -> DPR(1)-> CSR(0)
    for(int i=3; i>=0 ;i--)begin
        automatic iicmb_reg_ofst_t addr_ofst = iicmb_reg_ofst_t'(i);
        void'(trans_w[addr_ofst].set_data( 8'hff ));
        super.wb_agt0.bl_put_ref(trans_w[addr_ofst]);

        super.wb_agt0.bl_put_ref(trans_r[addr_ofst]);
      end

    $display("\n**********************CASE 3.TESTING REGISTER ALIASING AFTER ENABLING THE CORE******************\n");

    for(int i=0; i<4 ;i++)begin
        automatic iicmb_reg_ofst_t addr_ofst_1 = iicmb_reg_ofst_t'(i);
        automatic iicmb_reg_ofst_t addr_ofst_2;

        void'(trans_w[addr_ofst_1].set_data( 8'hff ));
        super.wb_agt0.bl_put_ref(trans_w[addr_ofst_1]);
        for(int k=0; k<4 ;k++)begin
            if( k == i ) continue;
            addr_ofst_2 = iicmb_reg_ofst_t'(k);
            assert(trans_r[addr_ofst_2].wb_data == mask_value[addr_ofst_2])  $display("{\n%s UNCHANGED WHEN WRITING TO %s}            TEST PASSED \n", map_reg_ofst_name[addr_ofst_2],map_reg_ofst_name[addr_ofst_1] );
            else $fatal("{%s ALIASED WHEN WRITING TO %s}            TEST FAILED ", map_reg_ofst_name[addr_ofst_2],map_reg_ofst_name[addr_ofst_1] );
        end
    end
    $display("\n****************************************************************************************");
    $display("                       TEST : REGISTER BLOCK TEST PASS          ");
    $display("****************************************************************************************\n");
    
    $display("|''||''|'||''''|.|'''||''||''|         '||'''|,  /.\    .|'''| .|'''| '||''''|'||'''|. ");
    $display("   ||    ||   . ||       ||             ||   || // \\   ||     ||      ||   .  ||   || ");
    $display("   ||    ||'''| `|'''|,  ||             ||...|'//...\\  `|'''|,`|'''|, ||'''|  ||   || ");
    $display("   ||    ||      .   ||  ||             ||    //     \\  .   || .   || ||      ||   || ");
    $display("  .||.  .||....| |...|' .||.           .||  .//       \\.|...|' |...|'.||....|.||...|' \n");
 endtask

endclass
