
# Show available test cases and options
#
run: info

info:
	@echo "/------------------------list of alias name available in make file ----------------------//"
	@echo " along with make pass any of the one parameter to run corresponding test or to open waveform"
	@echo "  all        			 	----> to run all the below test cases use make all command"
	@echo "  base_test  				----> to run the base_test.sv"
	@echo "  reset_test  				----> to run the reset_test.sv"
	@echo "  write_test  				----> to run the write_test.sv"
	@echo "  read_test  				----> to run the read_test.sv"
	@echo "  simultaneous_test  		----> to run the simultaneous_test.sv"
	@echo "  random_test  				----> to run the random_test.sv"
	@echo "  reset_write_read_test  	----> to run the reset_write_read_test.sv"
	@echo "  write_conditions_test  	----> to run the write_conditions_test.sv"
	@echo "  read_conditions_test  	----> to run the read_conditions_test.sv"
	@echo "  memory_access_test  		----> to run the memory_access_test.sv"
	@echo "  full_condition_test  		----> to run the full_condition_test.sv"
	@echo "  empty_condition_test  	----> to run the empty_condition_test.sv"
	@echo "  almost_full_test  		----> to run the almost_full_test.sv"
	@echo "  almost_empty_test  		----> to run the almost_empty_test.sv"
	@echo "  overflow_test  			----> to run the overflow_test.sv"
	@echo "  underflow_test  			----> to run the underflow_test.sv"
	@echo "  write_read_level_test  	----> to run the write_read_level_test.sv"
	@echo "  faster_write_clock_test  	----> to run the faster_write_clock_test.sv"
	@echo "  faster_read_clock_test  	----> to run the faster_read_clock_test.sv"
	@echo "  strict_level_test  		----> to run the strict_level_test.sv (strict level checking)"
	@echo "  data_integrity_focused_test  ----> to run the data_integrity_focused_test.sv (data integrity priority)"
	@echo "  waveform   				----> to open the simvision"
	@echo "  regression 				----> to run the regression & source the cmd and open the imc"
	@echo "  clean      				----> to delete the previous xrun files and cov files"
	@echo "/----------------------------------------------------------------------------------------//"

# Default target that runs all tests
all: base_test reset_test write_test read_test simultaneous_test random_test reset_write_read_test write_conditions_test read_conditions_test memory_access_test full_condition_test empty_condition_test almost_full_test almost_empty_test overflow_test underflow_test write_read_level_test faster_write_clock_test faster_read_clock_test strict_level_test data_integrity_focused_test waveform

# Base test case
base_test:
	@echo "[makefile]  base test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=base_test -uvmhome CDNS-1.1d
	@echo "[makefile]  base test case run is completed successfully"

reset_test:
	@echo "[makefile]  reset test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=reset_test -uvmhome CDNS-1.1d
	@echo "[makefile]  reset test case run is completed successfully"

write_test:
	@echo "[makefile]  write test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=write_only_test -uvmhome CDNS-1.1d
	@echo "[makefile]  write test case run is completed successfully"

read_test:
	@echo "[makefile]  read test case is running"	
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=read_only_test -uvmhome CDNS-1.1d
	@echo "[makefile]  read test case run is completed successfully"

simultaneous_test:
	@echo "[makefile]  simultaneous test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=simultaneous_test -uvmhome CDNS-1.1d
	@echo "[makefile]  simultaneous test case run is completed successfully"

random_test:
	@echo "[makefile]  random test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=random_test -uvmhome CDNS-1.1d
	@echo "[makefile]  random test case run is completed successfully"

reset_write_read_test:
	@echo "[makefile]  random test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=reset_write_read_test -uvmhome CDNS-1.1d
	@echo "[makefile]  random test case run is completed successfully"

write_conditions_test:
	@echo "[makefile]  write conditions test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=write_conditions_test -uvmhome CDNS-1.1d
	@echo "[makefile]  write conditions test case run is completed successfully"

read_conditions_test:
	@echo "[makefile]  read conditions test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=read_conditions_test -uvmhome CDNS-1.1d
	@echo "[makefile]  read conditions test case run is completed successfully"

memory_access_test:
	@echo "[makefile]  memory access test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=memory_access_test -uvmhome CDNS-1.1d
	@echo "[makefile]  memory access test case run is completed successfully"

full_condition_test:
	@echo "[makefile]  full condition test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=full_condition_test -uvmhome CDNS-1.1d
	@echo "[makefile]  full condition test case run is completed successfully"

empty_condition_test:
	@echo "[makefile]  empty condition test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=empty_condition_test -uvmhome CDNS-1.1d
	@echo "[makefile]  empty condition test case run is completed successfully"

almost_full_test:
	@echo "[makefile]  almost full test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=almost_full_test -uvmhome CDNS-1.1d
	@echo "[makefile]  almost full test case run is completed successfully"

almost_empty_test:
	@echo "[makefile]  almost empty test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=almost_empty_test -uvmhome CDNS-1.1d
	@echo "[makefile]  almost empty test case run is completed successfully"

overflow_test:
	@echo "[makefile]  overflow test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=overflow_test -uvmhome CDNS-1.1d
	@echo "[makefile]  overflow test case run is completed successfully"

underflow_test:
	@echo "[makefile]  underflow test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=underflow_test -uvmhome CDNS-1.1d
	@echo "[makefile]  underflow test case run is completed successfully"

write_read_level_test:
	@echo "[makefile]  write read level test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=write_read_level_test -uvmhome CDNS-1.1d
	@echo "[makefile]  write read level test case run is completed successfully"

faster_write_clock_test:
	@echo "[makefile]  faster write clock test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=faster_write_clock_test -uvmhome CDNS-1.1d
	@echo "[makefile]  faster write clock test case run is completed successfully"

faster_read_clock_test:
	@echo "[makefile]  faster read clock test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=faster_read_clock_test -uvmhome CDNS-1.1d
	@echo "[makefile]  faster read clock test case run is completed successfully"

strict_level_test:
	@echo "[makefile]  strict level test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=strict_level_test -uvmhome CDNS-1.1d
	@echo "[makefile]  strict level test case run is completed successfully"

data_integrity_focused_test:
	@echo "[makefile]  data integrity focused test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=data_integrity_focused_test -uvmhome CDNS-1.1d
	@echo "[makefile]  data integrity focused test case run is completed successfully"

# regression
regression:
	@echo "[makefile]  regression running"
	perl sync_fifo_regression.pl test_list.f 1
	source cmd
	imc -exec ./cov_files/cov_merge.cmd
	imc &
	@echo "[makefile]  regression was successfully completed"

# Clean previous run files
clean:
	rm -r *.log *.key xrun.history xcelium.d wave.shm cov_report.txt cov_report_html
	@echo "[makefile]  clean was successfully completed"

# Waveform viewing
waveform:
	simvision wave.shm & 