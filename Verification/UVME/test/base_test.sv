class base_test extends uvm_test;
  `uvm_component_utils(base_test)

  env m_env;
  write_base_sequence wseq;
  read_base_sequence rseq;

  function new(string name = "base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_env = env::type_id::create("m_env", this);
    wseq = write_base_sequence::type_id::create("wseq");
    rseq = read_base_sequence::type_id::create("rseq");
    `uvm_info(get_type_name(), "Base test build_phase completed", UVM_LOW)
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
    `uvm_info(get_type_name(), "Base test end_of_elaboration_phase completed", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    // Configure scoreboard for data integrity priority mode
    configure_scoreboard_for_test();
    
    fork
      // Sequence starting should be done in derived tests
      wseq.start(m_env.m_write_agent.m_sequencer);
      rseq.start(m_env.m_read_agent.m_sequencer);
    join
    
    // Get and report data integrity statistics
    report_data_integrity_stats();
    
    `uvm_info(get_type_name(), "Base test run_phase - sequences should be applied in derived tests", UVM_LOW)
    phase.drop_objection(this);
  endtask
  
  // Function to configure scoreboard settings for different test types
  function void configure_scoreboard_for_test();
    // Default configuration: Enable data integrity priority and level mismatch tolerance
    m_env.m_scoreboard.set_data_integrity_priority(1'b1);
    m_env.m_scoreboard.set_level_mismatch_tolerance(1'b1);
    `uvm_info(get_type_name(), "Scoreboard configured for data integrity priority mode", UVM_MEDIUM)
  endfunction
  
  // Function to get and report data integrity statistics
  function void report_data_integrity_stats();
    int total_ops, sim_ops, errors;
    m_env.m_scoreboard.get_data_integrity_stats(total_ops, sim_ops, errors);
    `uvm_info(get_type_name(), $sformatf("Data Integrity Statistics: Total_Ops=%0d, Simultaneous_Ops=%0d, Errors=%0d", total_ops, sim_ops, errors), UVM_LOW)
  endfunction
endclass 