transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+C:/Users/gonza/proyectos\ funda/CRodriguez_compu_archi_found_2G1_2025/FPGAController {C:/Users/gonza/proyectos funda/CRodriguez_compu_archi_found_2G1_2025/FPGAController/Spi_slave_module.sv}
vlog -sv -work work +incdir+C:/Users/gonza/proyectos\ funda/CRodriguez_compu_archi_found_2G1_2025/FPGAController {C:/Users/gonza/proyectos funda/CRodriguez_compu_archi_found_2G1_2025/FPGAController/FpgaController.sv}
vlog -sv -work work +incdir+C:/Users/gonza/proyectos\ funda/CRodriguez_compu_archi_found_2G1_2025/FPGAController {C:/Users/gonza/proyectos funda/CRodriguez_compu_archi_found_2G1_2025/FPGAController/Hex_to_7seg_decoder.sv}
vlog -sv -work work +incdir+C:/Users/gonza/proyectos\ funda/CRodriguez_compu_archi_found_2G1_2025/FPGAController {C:/Users/gonza/proyectos funda/CRodriguez_compu_archi_found_2G1_2025/FPGAController/FirtsDecoder_4to2bits.sv}

vlog -sv -work work +incdir+C:/Users/gonza/proyectos\ funda/CRodriguez_compu_archi_found_2G1_2025/FPGAController {C:/Users/gonza/proyectos funda/CRodriguez_compu_archi_found_2G1_2025/FPGAController/alu_tb.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  alu_tb

add wave *
view structure
view signals
run -all
