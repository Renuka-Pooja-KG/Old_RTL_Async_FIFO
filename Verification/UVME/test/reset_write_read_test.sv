class reset_write_read_test extends base_test;
  `uvm_component_utils(reset_write_read_test)

    write_base_sequence wseq;
    read_base_sequence rseq; 

    function new(string name = "reset_write_read_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        wseq = write_base_sequence::type_id::create("wseq");
        rseq = read_base_sequence::type_id::create("rseq");
        wseq.scenario = 5; // reset
        rseq.scenario = 5; // reset
        // wseq.num_transactions = 10; // Set number of transactions for write sequence
        // rseq.num_transactions = 10; // Set number of transactions for read sequence
        `uvm_info(get_type_name(), "Reset-Write-Read test build_phase completed", UVM_LOW)
    endfunction
    
    // Override the base class scoreboard configuration for this specific test
    function void configure_scoreboard_for_test();
        // Enable both data integrity priority and level mismatch tolerance for reset test
        m_env.m_scoreboard.set_data_integrity_priority(1'b1);  // Prioritize data integrity
        m_env.m_scoreboard.set_level_mismatch_tolerance(1'b1); // Enable tolerance for level mismatches
        m_env.m_scoreboard.set_underflow_tolerance(1'b1); // Enable underflow tolerance for reset scenarios
        m_env.m_scoreboard.set_use_actual_rtl_state(1'b1); // Use actual RTL state for better sync handling
        m_env.m_scoreboard.set_reset_scenario_mode(1'b1); // Enable reset scenario mode for better tolerance
        `uvm_info(get_type_name(), "Reset-Write-Read test scoreboard configured for reset scenarios", UVM_MEDIUM)
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Reset-Write-Read test run_phase started", UVM_LOW)
        fork
            wseq.start(m_env.m_write_agent.m_sequencer);
            rseq.start(m_env.m_read_agent.m_sequencer);
        join
        phase.drop_objection(this);
    endtask
endclass