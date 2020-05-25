onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /i2c_tb/CLK
add wave -noupdate /i2c_tb/SRST
add wave -noupdate /i2c_tb/SDA
add wave -noupdate /i2c_tb/SCL
add wave -noupdate /i2c_tb/DATA_OUT
add wave -noupdate /i2c_tb/sda_dis
add wave -noupdate /i2c_tb/scl_dis
add wave -noupdate /i2c_tb/DUT/current_state
add wave -noupdate /i2c_tb/DUT/next_state
add wave -noupdate /i2c_tb/DUT/start_condition
add wave -noupdate /i2c_tb/DUT/stop_condition
add wave -noupdate /i2c_tb/DUT/data_avaliable
add wave -noupdate /i2c_tb/DUT/data_ready
add wave -noupdate /i2c_tb/DUT/byte_reg
add wave -noupdate /i2c_tb/DUT/data_reg
add wave -noupdate /i2c_tb/DUT/data_count_reg
add wave -noupdate /i2c_tb/DUT/data_count_next
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Falling edge} {18210 ns} 1} {Rising_edge {19810 ns} 1} {{Data valid} {19110 ns} 1} {{Cursor 4} {14770 ns} 0}
quietly wave cursor active 4
configure wave -namecolwidth 228
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {10914 ns} {35490 ns}
