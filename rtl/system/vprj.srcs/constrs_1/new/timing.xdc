#create_clock -period 10.000 -name pcie_ref_clk [get_ports {pcie_ref_clk_p[0]}]

set_clock_groups -name async_clk_groups -asynchronous -group [get_clocks -include_generated_clocks txoutclk_x0y0] -group [get_clocks -include_generated_clocks adc_clk_in]

#set_clock_groups -name fix_async_warning -asynchronous #    -group [get_clocks userclk1] #    -group [get_clocks clk_out2_vbd_clk_wiz_0_0]

set_clock_groups -name async_clk_groups -asynchronous -group [get_clocks -include_generated_clocks txoutclk_x0y0] -group [get_clocks -include_generated_clocks adc_clk_in]
