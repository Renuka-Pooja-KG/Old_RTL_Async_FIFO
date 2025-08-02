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
        // Enable both data integrity priority and level mismatch tolerance
            m_env.m_scoreboard.set_data_integrity_priority(1'b1);  // Prioritize data integrity
            m_env.m_scoreboard.set_level_mismatch_tolerance(1'b1); // Enable tolerance for level mismatches
        // wseq.num_transactions = 10; // Set number of transactions for write sequence
        // rseq.num_transactions = 10; // Set number of transactions for read sequence
        `uvm_info(get_type_name(), "Reset-Write-Read test build_phase completed", UVM_LOW)
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