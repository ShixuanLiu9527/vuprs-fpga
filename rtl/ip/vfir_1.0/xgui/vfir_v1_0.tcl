# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0" -display_name {AXI-Stream Config}]
  ipgui::add_param $IPINST -name "C_S00_AXI_DATA_WIDTH" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "C_S00_AXI_ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S00_AXI_BASEADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S00_AXI_HIGHADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S00_AXIS_TDATA_WIDTH" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "C_M00_AXIS_TDATA_WIDTH" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "C_M00_AXIS_START_COUNT" -parent ${Page_0}

  #Adding Page
  set FIR_Filter_Bank_Config [ipgui::add_page $IPINST -name "FIR Filter Bank Config"]
  ipgui::add_param $IPINST -name "MAXIMUM_FILTER_LENGTH" -parent ${FIR_Filter_Bank_Config}
  ipgui::add_param $IPINST -name "BRAM_DATA_WIDTH" -parent ${FIR_Filter_Bank_Config}
  ipgui::add_param $IPINST -name "FRAME_HEADER" -parent ${FIR_Filter_Bank_Config} -widget comboBox
  ipgui::add_param $IPINST -name "FRAME_TAILER" -parent ${FIR_Filter_Bank_Config} -widget comboBox


}

proc update_PARAM_VALUE.BRAM_DATA_WIDTH { PARAM_VALUE.BRAM_DATA_WIDTH } {
	# Procedure called to update BRAM_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BRAM_DATA_WIDTH { PARAM_VALUE.BRAM_DATA_WIDTH } {
	# Procedure called to validate BRAM_DATA_WIDTH
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

proc update_PARAM_VALUE.MAXIMUM_FILTER_LENGTH { PARAM_VALUE.MAXIMUM_FILTER_LENGTH } {
	# Procedure called to update MAXIMUM_FILTER_LENGTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MAXIMUM_FILTER_LENGTH { PARAM_VALUE.MAXIMUM_FILTER_LENGTH } {
	# Procedure called to validate MAXIMUM_FILTER_LENGTH
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

proc update_PARAM_VALUE.C_S00_AXIS_TDATA_WIDTH { PARAM_VALUE.C_S00_AXIS_TDATA_WIDTH } {
	# Procedure called to update C_S00_AXIS_TDATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXIS_TDATA_WIDTH { PARAM_VALUE.C_S00_AXIS_TDATA_WIDTH } {
	# Procedure called to validate C_S00_AXIS_TDATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M00_AXIS_TDATA_WIDTH { PARAM_VALUE.C_M00_AXIS_TDATA_WIDTH } {
	# Procedure called to update C_M00_AXIS_TDATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M00_AXIS_TDATA_WIDTH { PARAM_VALUE.C_M00_AXIS_TDATA_WIDTH } {
	# Procedure called to validate C_M00_AXIS_TDATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M00_AXIS_START_COUNT { PARAM_VALUE.C_M00_AXIS_START_COUNT } {
	# Procedure called to update C_M00_AXIS_START_COUNT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M00_AXIS_START_COUNT { PARAM_VALUE.C_M00_AXIS_START_COUNT } {
	# Procedure called to validate C_M00_AXIS_START_COUNT
	return true
}


proc update_MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S00_AXIS_TDATA_WIDTH { MODELPARAM_VALUE.C_S00_AXIS_TDATA_WIDTH PARAM_VALUE.C_S00_AXIS_TDATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXIS_TDATA_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXIS_TDATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M00_AXIS_TDATA_WIDTH { MODELPARAM_VALUE.C_M00_AXIS_TDATA_WIDTH PARAM_VALUE.C_M00_AXIS_TDATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M00_AXIS_TDATA_WIDTH}] ${MODELPARAM_VALUE.C_M00_AXIS_TDATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M00_AXIS_START_COUNT { MODELPARAM_VALUE.C_M00_AXIS_START_COUNT PARAM_VALUE.C_M00_AXIS_START_COUNT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M00_AXIS_START_COUNT}] ${MODELPARAM_VALUE.C_M00_AXIS_START_COUNT}
}

proc update_MODELPARAM_VALUE.MAXIMUM_FILTER_LENGTH { MODELPARAM_VALUE.MAXIMUM_FILTER_LENGTH PARAM_VALUE.MAXIMUM_FILTER_LENGTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MAXIMUM_FILTER_LENGTH}] ${MODELPARAM_VALUE.MAXIMUM_FILTER_LENGTH}
}

proc update_MODELPARAM_VALUE.BRAM_DATA_WIDTH { MODELPARAM_VALUE.BRAM_DATA_WIDTH PARAM_VALUE.BRAM_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BRAM_DATA_WIDTH}] ${MODELPARAM_VALUE.BRAM_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.FRAME_HEADER { MODELPARAM_VALUE.FRAME_HEADER PARAM_VALUE.FRAME_HEADER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FRAME_HEADER}] ${MODELPARAM_VALUE.FRAME_HEADER}
}

proc update_MODELPARAM_VALUE.FRAME_TAILER { MODELPARAM_VALUE.FRAME_TAILER PARAM_VALUE.FRAME_TAILER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FRAME_TAILER}] ${MODELPARAM_VALUE.FRAME_TAILER}
}

