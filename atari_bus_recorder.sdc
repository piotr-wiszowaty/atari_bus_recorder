create_clock -name clock_50 -period 20.000 [get_ports {clock_50}]
create_clock -name channel[1] -period 560.000 [get_ports {channel[1]}]
derive_pll_clocks
derive_clock_uncertainty
