
export ECE745_PROJECT_HOME ?= $(PWD)/../../..

include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/ncsu_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/environment_packages/i2cmb_env_pkg/Makefile

GEN_TYPE ?= i2cmb_generator_direct_test 
TEST_SEED ?= random


CLI_DO_COMMANDS = -do " \
                    set NoQuitOnFinish 1; \
                    run -all; \
	 	            do save_coverage.do $(GEN_TYPE); \
                    quit -f;" 

DEBUG_DO_COMMANDS = -do " \
                    set NoQuitOnFinish 1; \
                    do wave.do;\
                    run -a;"\

clean:
	rm -rf work *.wlf transcript i2cmb_test_plan*.ucdb *.vstf *.ucdb

comp_I2C_MB:
	vcom ../rtl/iicmb_int_pkg.vhd
	vcom ../rtl/iicmb_pkg.vhd
	vcom -cover f ../rtl/mbyte.vhd
	vcom ../rtl/mbit.vhd
	vcom ../rtl/bus_state.vhd
	vcom ../rtl/filter.vhd
	vcom ../rtl/conditioner.vhd
	vcom ../rtl/conditioner_mux.vhd
	vcom ../rtl/iicmb_m.vhd
	vcom -cover bes ../rtl/regblock.vhd
	vcom ../rtl/wishbone.vhd
	vcom ../rtl/iicmb_m_wb.vhd


comp_bench: comp_ncsu_pkg comp_wb_pkg comp_wb_if comp_i2c_pkg comp_i2c_if comp_i2cmb_env_pkg
	# vlog $(VLOG_OPT) ../testbench/top.sv
	vlog ../testbench/top.sv

optimize:
	vopt +acc top -o optimized_debug_top_tb

compile:  comp_I2C_MB comp_bench  optimize

simulate:
	# vsim  -i $(VSIM_OPT) $(GUI_DO_COMMANDS) +GEN_TYPE=$(GEN_TYPE) optimized_debug_top_tb
	vsim  -i -classdebug -msgmode both -do "set NoQuitOnFinish 1; do wave.do" optimized_debug_top_tb

run: clean compile
	vsim  -batch $(VSIM_OPT) $(BATCH_DO_COMMANDS) +GEN_TYPE=$(GEN_TYPE) optimized_debug_top_tb
view:
	vsim -view vsim.wlf -do wave.do

debug_3step: clean compile simulate

debug: clean compile simulate

#----------------Project 3 & 4-------------------------------------:
run_cli:
	vsim -c -coverage -sv_seed $(TEST_SEED) $(CLI_DO_COMMANDS) +GEN_TYPE=$(GEN_TYPE) optimized_debug_top_tb

run_gui:
	vsim -coverage -sv_seed $(TEST_SEED) $(DEBUG_DO_COMMANDS) +GEN_TYPE=$(GEN_TYPE) optimized_debug_top_tb

cli: clean compile run_cli

# regress: clean compile
# 	# $(MAKE) run_cli GEN_TYPE=i2cmb_generator
# 	$(MAKE) run_cli GEN_TYPE=i2cmb_generator_register_test
# 	$(MAKE) run_cli GEN_TYPE=i2cmb_generator_fsm_functionality_test
# 	# $(MAKE) run_cli GEN_TYPE=i2cmb_i2c_coverage
# 	# $(MAKE) run_cli GEN_TYPE=i2cmb_coverage
# 	$(MAKE) merge_coverage
# 	$(MAKE) view_coverage

testlist:
	./testlist.sh

regress:
	./regress.sh

merge_coverage:
	xml2ucdb -format Excel ./i2cmb_test_plan.xml ./i2cmb_test_plan.ucdb
	vcover merge -stats=none -strip 0 -totals i2cmb_test_plan_merge.ucdb ./*.ucdb

view_coverage:
	vsim -viewcov ./i2cmb_test_plan_merge.ucdb

report_coverage:
	vcover report -details -html -htmldir covhtmlreport -assert -directive -cvg -code bcefst -threshL 50 -threshH 90 ./sim_and_testplan_merged.ucdb

merge_coverage_with_test_plan:
	rm -f i2cmb_test_plan.ucdb
	vsim -i -do load_ucdbs_and_merge_with_test_plan.do