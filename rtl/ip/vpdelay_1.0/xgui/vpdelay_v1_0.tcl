# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0" -display_name {AXI Bus Config}]
  ipgui::add_param $IPINST -name "C_S00_AXI_DATA_WIDTH" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "C_S00_AXI_ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S00_AXI_BASEADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S00_AXI_HIGHADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S00_AXIS_TDATA_WIDTH" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "C_M00_AXIS_TDATA_WIDTH" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "C_M00_AXIS_START_COUNT" -parent ${Page_0}

  #Adding Page
  set Beamforming_Config [ipgui::add_page $IPINST -name "Beamforming Config"]
  ipgui::add_param $IPINST -name "AXI_CLOCK_CYCLE_NS" -parent ${Beamforming_Config}
  ipgui::add_param $IPINST -name "FREEZE_TIMEOUT_MS" -parent ${Beamforming_Config}
  ipgui::add_param $IPINST -name "WAVE_VELOCITY_MPS" -parent ${Beamforming_Config}
  ipgui::add_param $IPINST -name "MAXIMUM_ARRAY_SIZE_MM" -parent ${Beamforming_Config}
  ipgui::add_param $IPINST -name "MAXIMUM_SAMPLING_FREQ_HZ" -parent ${Beamforming_Config}
  ipgui::add_param $IPINST -name "FRAME_HEADER" -parent ${Beamforming_Config} -widget comboBox
  ipgui::add_param $IPINST -name "FRAME_TAILER" -parent ${Beamforming_Config} -widget comboBox
  ipgui::add_param $IPINST -name "ADC_DATA_WIDTH_BIT" -parent ${Beamforming_Config}
  ipgui::add_param $IPINST -name "ADC_CHANNEL_COUNT" -parent ${Beamforming_Config}


}

proc update_PARAM_VALUE.ADC_CHANNEL_COUNT { PARAM_VALUE.ADC_CHANNEL_COUNT } {
	# Procedure called to update ADC_CHANNEL_COUNT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADC_CHANNEL_COUNT { PARAM_VALUE.ADC_CHANNEL_COUNT } {
	# Procedure called to validate ADC_CHANNEL_COUNT
	return true
}

proc update_PARAM_VALUE.ADC_DATA_WIDTH_BIT { PARAM_VALUE.ADC_DATA_WIDTH_BIT } {
	# Procedure called to update ADC_DATA_WIDTH_BIT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADC_DATA_WIDTH_BIT { PARAM_VALUE.ADC_DATA_WIDTH_BIT } {
	# Procedure called to validate ADC_DATA_WIDTH_BIT
	return true
}

proc update_PARAM_VALUE.AXI_CLOCK_CYCLE_NS { PARAM_VALUE.AXI_CLOCK_CYCLE_NS } {
	# Procedure called to update AXI_CLOCK_CYCLE_NS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXI_CLOCK_CYCLE_NS { PARAM_VALUE.AXI_CLOCK_CYCLE_NS } {
	# Procedure called to validate AXI_CLOCK_CYCLE_NS
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

proc update_PARAM_VALUE.MAXIMUM_ARRAY_SIZE_MM { PARAM_VALUE.MAXIMUM_ARRAY_SIZE_MM } {
	# Procedure called to update MAXIMUM_ARRAY_SIZE_MM when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MAXIMUM_ARRAY_SIZE_MM { PARAM_VALUE.MAXIMUM_ARRAY_SIZE_MM } {
	# Procedure called to validate MAXIMUM_ARRAY_SIZE_MM
	return true
}

proc update_PARAM_VALUE.MAXIMUM_SAMPLING_FREQ_HZ { PARAM_VALUE.MAXIMUM_SAMPLING_FREQ_HZ } {
	# Procedure called to update MAXIMUM_SAMPLING_FREQ_HZ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MAXIMUM_SAMPLING_FREQ_HZ { PARAM_VALUE.MAXIMUM_SAMPLING_FREQ_HZ } {
	# Procedure called to validate MAXIMUM_SAMPLING_FREQ_HZ
	return true
}

proc update_PARAM_VALUE.WAVE_VELOCITY_MPS { PARAM_VALUE.WAVE_VELOCITY_MPS } {
	# Procedure called to update WAVE_VELOCITY_MPS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.WAVE_VELOCITY_MPS { PARAM_VALUE.WAVE_VELOCITY_MPS } {
	# Procedure called to validate WAVE_VELOCITY_MPS
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

proc update_MODELPARAM_VALUE.FREEZE_TIMEOUT_MS { MODELPARAM_VALUE.FREEZE_TIMEOUT_MS PARAM_VALUE.FREEZE_TIMEOUT_MS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FREEZE_TIMEOUT_MS}] ${MODELPARAM_VALUE.FREEZE_TIMEOUT_MS}
}

proc update_MODELPARAM_VALUE.AXI_CLOCK_CYCLE_NS { MODELPARAM_VALUE.AXI_CLOCK_CYCLE_NS PARAM_VALUE.AXI_CLOCK_CYCLE_NS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXI_CLOCK_CYCLE_NS}] ${MODELPARAM_VALUE.AXI_CLOCK_CYCLE_NS}
}

proc update_MODELPARAM_VALUE.WAVE_VELOCITY_MPS { MODELPARAM_VALUE.WAVE_VELOCITY_MPS PARAM_VALUE.WAVE_VELOCITY_MPS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.WAVE_VELOCITY_MPS}] ${MODELPARAM_VALUE.WAVE_VELOCITY_MPS}
}

proc update_MODELPARAM_VALUE.MAXIMUM_ARRAY_SIZE_MM { MODELPARAM_VALUE.MAXIMUM_ARRAY_SIZE_MM PARAM_VALUE.MAXIMUM_ARRAY_SIZE_MM } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MAXIMUM_ARRAY_SIZE_MM}] ${MODELPARAM_VALUE.MAXIMUM_ARRAY_SIZE_MM}
}

proc update_MODELPARAM_VALUE.MAXIMUM_SAMPLING_FREQ_HZ { MODELPARAM_VALUE.MAXIMUM_SAMPLING_FREQ_HZ PARAM_VALUE.MAXIMUM_SAMPLING_FREQ_HZ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MAXIMUM_SAMPLING_FREQ_HZ}] ${MODELPARAM_VALUE.MAXIMUM_SAMPLING_FREQ_HZ}
}

proc update_MODELPARAM_VALUE.FRAME_HEADER { MODELPARAM_VALUE.FRAME_HEADER PARAM_VALUE.FRAME_HEADER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FRAME_HEADER}] ${MODELPARAM_VALUE.FRAME_HEADER}
}

proc update_MODELPARAM_VALUE.FRAME_TAILER { MODELPARAM_VALUE.FRAME_TAILER PARAM_VALUE.FRAME_TAILER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FRAME_TAILER}] ${MODELPARAM_VALUE.FRAME_TAILER}
}

proc update_MODELPARAM_VALUE.ADC_DATA_WIDTH_BIT { MODELPARAM_VALUE.ADC_DATA_WIDTH_BIT PARAM_VALUE.ADC_DATA_WIDTH_BIT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADC_DATA_WIDTH_BIT}] ${MODELPARAM_VALUE.ADC_DATA_WIDTH_BIT}
}

proc update_MODELPARAM_VALUE.ADC_CHANNEL_COUNT { MODELPARAM_VALUE.ADC_CHANNEL_COUNT PARAM_VALUE.ADC_CHANNEL_COUNT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADC_CHANNEL_COUNT}] ${MODELPARAM_VALUE.ADC_CHANNEL_COUNT}
}

