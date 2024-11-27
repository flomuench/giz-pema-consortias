* input path needs to be changed
use "${figures_attrition}/test_sample_for_Ghanem_etal.dta", clear

* try with full specification
attregtest net_size, treatvar(treatment) respvar(el_net_size_refus) stratavar(strata_final) vce(cluster consortia_cluster)

* default SEs
attregtest net_size, treatvar(treatment) respvar(el_net_size_refus) stratavar(strata_final)

* no strata
attregtest net_size, treatvar(treatment) respvar(el_net_size_refus)

* other variable
attregtest mpi, treatvar(treatment) respvar(el_mpi_refus) stratavar(strata_final) vce(cluster consortia_cluster)