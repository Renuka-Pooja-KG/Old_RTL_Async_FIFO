class env extends uvm_env;
  `uvm_component_utils(env)

  write_agent      m_write_agent;
  read_agent       m_read_agent;
  write_coverage   m_write_coverage;
  read_coverage    m_read_coverage;
  scoreboard       m_scoreboard;

  function new(string name = "env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_write_agent    = write_agent::type_id::create("m_write_agent", this);
    m_read_agent     = read_agent::type_id::create("m_read_agent", this);
    m_write_coverage = write_coverage::type_id::create("m_write_coverage", this);
    m_read_coverage  = read_coverage::type_id::create("m_read_coverage", this);
    m_scoreboard     = scoreboard::type_id::create("m_scoreboard", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    m_write_agent.m_monitor.write_analysis_port.connect(m_write_coverage.wr_analysis_imp);
    m_read_agent.m_monitor.read_analysis_port.connect(m_read_coverage.rd_analysis_imp);
    m_write_agent.m_monitor.write_analysis_port.connect(m_scoreboard.write_export);
    m_read_agent.m_monitor.read_analysis_port.connect(m_scoreboard.read_export);

    // m_write_agent.wr_agent_analysis_port.connect(m_write_coverage.wr_analysis_imp);
    // m_read_agent.rd_agent_analysis_port.connect(m_read_coverage.rd_analysis_imp);
    // m_write_agent.wr_agent_analysis_port.connect(m_scoreboard.write_export);
    // m_read_agent.rd_agent_analysis_port.connect(m_scoreboard.read_export);
  endfunction
endclass 