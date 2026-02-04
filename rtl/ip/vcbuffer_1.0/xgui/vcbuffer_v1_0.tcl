# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0" -display_name {AXI Bus Config}]
  ipgui::add_param $IPINST -name "C_S00_AXIS_TDATA_WIDTH" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "C_S00_AXI_DATA_WIDTH" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "C_S00_AXI_ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S00_AXI_BASEADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S00_AXI_HIGHADDR" -parent ${Page_0}

  #Adding Page
  set Buffer_Config [ipgui::add_page $IPINST -name "Buffer Config"]
  ipgui::add_param $IPINST -name "FREEZE_TIMEOUT_MS" -parent ${Buffer_Config}
  ipgui::add_param $IPINST -name "AXI_CLOCK_CYCLE_NS" -parent ${Buffer_Config}
  ipgui::add_param $IPINST -name "BRAM_DATA_WIDTH" -parent ${Buffer_Config}
  set CIRCULAR_BUFFER_POINTS [ipgui::add_param $IPINST -name "CIRCULAR_BUFFER_POINTS" -parent ${Buffer_Config}]
  set_property tooltip {Circular BRAM Buffer Frame Points (BRAM size must greater than this x 40 bytes)} ${CIRCULAR_BUFFER_POINTS}
  ipgui::add_param $IPINST -name "FRAME_HEADER" -parent ${Buffer_Config} -widget comboBox
  ipgui::add_param $IPINST -name "FRAME_TAILER" -parent ${Buffer_Config} -widget comboBox


}

proc update_PARAM_VALUE.AXI_CLOCK_CYCLE_NS { PARAM_VALUE.AXI_CLOCK_CYCLE_NS } {
	# Procedure called to update AXI_CLOCK_CYCLE_NS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXI_CLOCK_CYCLE_NS { PARAM_VALUE.AXI_CLOCK_CYCLE_NS } {
	# Procedure called to validate AXI_CLOCK_CYCLE_NS
	return true
}

proc update_PARAM_VALUE.BRAM_DATA_WIDTH { PARAM_VALUE.BRAM_DATA_WIDTH } {
	# Procedure called to update BRAM_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BRAM_DATA_WIDTH { PARAM_VALUE.BRAM_DATA_WIDTH } {
	# Procedure called to validate BRAM_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.CIRCULAR_BUFFER_POINTS { PARAM_VALUE.CIRCULAR_BUFFER_POINTS } {
	# Procedure called to update CIRCULAR_BUFFER_POINTS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CIRCULAR_BUFFER_POINTS { PARAM_VALUE.CIRCULAR_BUFFER_POINTS } {
	# Procedure called to validate CIRCULAR_BUFFER_POINTS
	return true
}

proc update_PARAM_VALUE.FRAME_HEADER { PARAM_VALUE.FRAME_HEADER } {
	# Procedure called to update FRAME_HEADER when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FRAME_HEADER { PARAM_VALUE.FRAME_HEADER } {
	# Procedure called to validate FRAME_HEADER
	return true
}

proc update_PARAM_VALUE.FRAME_TAILER { PARAM_VALUE.FRAME_TAILER } {
	# Procedure called to update FRAME_TAILER when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FRAME_TAILER { PARAM_VALUE.FRAME_TAILER } {
	# Procedure called to validate FRAME_TAILER
	return true
}

proc update_PARAM_VALUE.FREEZE_TIMEOUT_MS { PARAM_VALUE.FREEZE_TIMEOUT_MS } {
	# Procedure called to update FREEZE_TIMEOUT_MS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FREEZE_TIMEOUT_MS { PARAM_VALUE.FREEZE_TIMEOUT_MS } {
	# Procedure called to validate FREEZE_TIMEOUT_MS
	return true
}

proc update_PARAM_VALUE.C_S00_AXIS_TDATA_WIDTH { PARAM_VALUE.C_S00_AXIS_TDATA_WIDTH } {
	# Procedure called to update C_S00_AXIS_TDATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXIS_TDATA_WIDTH { PARAM_VALUE.C_S00_AXIS_TDATA_WIDTH } {
	# Procedure called to validate C_S00_AXIS_TDATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to update C_S00_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S00_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to update C_S00_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S00_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_BASEADDR { PARAM_VALUE.C_S00_AXI_BASEADDR } {
	# Procedure called to update C_S00_AXI_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_BASEADDR { PARAM_VALUE.C_S00_AXI_BASEADDR } {
	# Procedure called to validate C_S00_AXI_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_HIGHADDR { PARAM_VALUE.C_S00_AXI_HIGHADDR } {
	# Procedure called to update C_S00_AXI_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_HIGHADDR { PARAM_VALUE.C_S00_AXI_HIGHADDR } {
	# Procedure called to validate C_S00_AXI_HIGHADDR
	return true
}


proc update_MODELPARAM_VALUE.C_S00_AXIS_TDATA_WIDTH { MODELPARAM_VALUE.C_S00_AXIS_TDATA_WIDTH PARAM_VALUE.C_S00_AXIS_TDATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXIS_TDATA_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXIS_TDATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.FREEZE_TIMEOUT_MS { MODELPARAM_VALUE.FREEZE_TIMEOUT_MS PARAM_VALUE.FREEZE_TIMEOUT_MS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FREEZE_TIMEOUT_MS}] ${MODELPARAM_VALUE.FREEZE_TIMEOUT_MS}
}

proc update_MODELPARAM_VALUE.AXI_CLOCK_CYCLE_NS { MODELPARAM_VALUE.AXI_CLOCK_CYCLE_NS PARAM_VALUE.AXI_CLOCK_CYCLE_NS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXI_CLOCK_CYCLE_NS}] ${MODELPARAM_VALUE.AXI_CLOCK_CYCLE_NS}
}

proc update_MODELPARAM_VALUE.BRAM_DATA_WIDTH { MODELPARAM_VALUE.BRAM_DATA_WIDTH PARAM_VALUE.BRAM_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BRAM_DATA_WIDTH}] ${MODELPARAM_VALUE.BRAM_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.CIRCULAR_BUFFER_POINTS { MODELPARAM_VALUE.CIRCULAR_BUFFER_POINTS PARAM_VALUE.CIRCULAR_BUFFER_POINTS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CIRCULAR_BUFFER_POINTS}] ${MODELPARAM_VALUE.CIRCULAR_BUFFER_POINTS}
}

proc update_MODELPARAM_VALUE.FRAME_HEADER { MODELPARAM_VALUE.FRAME_HEADER PARAM_VALUE.FRAME_HEADER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FRAME_HEADER}] ${MODELPARAM_VALUE.FRAME_HEADER}
}

proc update_MODELPARAM_VALUE.FRAME_TAILER { MODELPARAM_VALUE.FRAME_TAILER PARAM_VALUE.FRAME_TAILER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FRAME_TAILER}] ${MODELPARAM_VALUE.FRAME_TAILER}
}

