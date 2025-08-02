class write_only_test extends base_test;
  `uvm_component_utils(write_only_test)
    
    write_base_sequence wseq;   
    read_base_sequence rseq;

    function new(string name = "write_only_test", uvm_component parent = null);
            super.new(name, parent);                
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        wseq = write_base_sequence::type_id::create("wseq");
        rseq = read_base_sequence::type_id::create("rseq");
        wseq.scenario = 2; // write_only
        rseq.scenario = 2; // write_only
        wseq.num_transactions = 30; // Set number of transactions for write sequence
        rseq.num_transactions = 30; // Set number of transactions for read sequence
        `uvm_info(get_type_name(), "Write only test build_phase completed", UVM_LOW)
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Write only test run_phase started", UVM_LOW)
        fork
        wseq.start(m_env.m_write_agent.m_sequencer);
        rseq.start(m_env.m_read_agent.m_sequencer);
        join
        phase.drop_objection(this);
    endtask
endclass