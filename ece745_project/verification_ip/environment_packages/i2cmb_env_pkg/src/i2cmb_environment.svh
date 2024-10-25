class i2cmb_environment extends ncsu_component;

i2cmb_env_configuration env_config;
wb_configuration wb_config;
i2c_configuration i2c_cfg0;

wb_agent wb_agt;
i2c_agent i2c_agt;
i2cmb_predictor predictor;
i2cmb_scoreboard scoreboard;
i2cmb_coverage_wb wb_coverage;
i2cmb_coverage_i2c i2c_config;

function new(string name="", ncsu_component_base parent=null);
    super.new(name, parent);
endfunction

function void set_configuration(i2cmb_env_configuration cfg);
	env_config = cfg;
    wb_config = new(cfg.get_name());
    i2c_cfg0 = new(cfg.get_name());
endfunction


virtual function void build();
	wb_agt = new("wb_agent", this);
    wb_agt.set_configuration(wb_config);
	wb_agt.build();
	i2c_agt = new("i2c_agent", this);
    i2c_agt.set_configuration(i2c_cfg0);
	i2c_agt.build();
	wb_coverage = new("wb_coverage", this);
	wb_coverage.set_configuration(env_config);
	wb_coverage.build();
    i2c_config = new("i2c_coverage", this);
	i2c_config.set_configuration(env_config);
	i2c_config.build();
	predictor = new("predictor", this);
    predictor.set_configuration(env_config);
	predictor.build();
	scoreboard = new("scoreboard", this);
	scoreboard.build();

	i2c_agt.connect_subscriber(scoreboard);
    i2c_agt.connect_subscriber(i2c_config);
    wb_agt.connect_subscriber(wb_coverage);
    wb_agt.connect_subscriber(predictor);

    predictor.set_scoreboard(scoreboard);
endfunction

function wb_agent get_wb_agent();
	return wb_agt;
endfunction

function i2c_agent get_i2c_agent();
	return i2c_agt;
endfunction

virtual task run();
 	wb_agt.run();
	i2c_agt.run();
    fork scoreboard.run(); join_none
endtask

endclass
