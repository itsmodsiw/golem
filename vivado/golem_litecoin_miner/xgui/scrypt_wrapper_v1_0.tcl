# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "N_DIFFICULTY_LOG2" -parent ${Page_0}


}

proc update_PARAM_VALUE.N_DIFFICULTY_LOG2 { PARAM_VALUE.N_DIFFICULTY_LOG2 } {
	# Procedure called to update N_DIFFICULTY_LOG2 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.N_DIFFICULTY_LOG2 { PARAM_VALUE.N_DIFFICULTY_LOG2 } {
	# Procedure called to validate N_DIFFICULTY_LOG2
	return true
}


proc update_MODELPARAM_VALUE.N_DIFFICULTY_LOG2 { MODELPARAM_VALUE.N_DIFFICULTY_LOG2 PARAM_VALUE.N_DIFFICULTY_LOG2 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.N_DIFFICULTY_LOG2}] ${MODELPARAM_VALUE.N_DIFFICULTY_LOG2}
}

