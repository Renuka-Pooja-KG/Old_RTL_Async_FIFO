class strict_level_test extends base_test;
  `uvm_component_utils(strict_level_test)

  function new(string name = "strict_level_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Override the scoreboard configuration for strict level checking
  function void configure_scoreboard_for_test();
    // Disable level mismatch tolerance for strict level checking
    m_env.m_scoreboard.set_data_integrity_priority(1'b1);  // Still prioritize data integrity
    m_env.m_scoreboard.set_level_mismatch_tolerance(1'b0); // Disable tolerance for strict checking
    `uvm_info(get_type_name(), "Scoreboard configured for STRICT level checking mode", UVM_MEDIUM)
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    // Configure scoreboard for strict level checking
    configure_scoreboard_for_test();
    
    // Set scenario for write and read sequences
    wseq.scenario = 3; // read_only scenario
    rseq.scenario = 3; // read_only scenario
    
    fork
      wseq.start(m_env.m_write_agent.m_sequencer);
      rseq.start(m_env.m_read_agent.m_sequencer);
    join
    
    // Get and report data integrity statistics
    report_data_integrity_stats();
    
    `uvm_info(get_type_name(), "Strict level test completed", UVM_LOW)
    phase.drop_objection(this);
  endtask
endclass 