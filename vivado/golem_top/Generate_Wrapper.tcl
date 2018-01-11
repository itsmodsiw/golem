set origin_dir [file dirname [info script]]

make_wrapper -files [get_files $origin_dir/golem_top/golem_top.srcs/sources_1/bd/design_1/design_1.bd] -top
add_files -norecurse -force $origin_dir/golem_top/golem_top.srcs/sources_1/bd/design_1/hdl/design_1_wrapper.v
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
