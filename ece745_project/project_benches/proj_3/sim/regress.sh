make clean compile
#make run_cli GEN_TRANS_TYPE=i2cmb_generator TEST_SEED=random
make run_cli GEN_TRANS_TYPE=i2cmb_generator_register_test TEST_SEED=random
make run_cli GEN_TRANS_TYPE=i2cmb_generator_fsm_functionality_test TEST_SEED=random
make run_cli GEN_TRANS_TYPE=i2cmb_generator_control_functionality_test TEST_SEED=random
make merge_coverage
make view_coverage