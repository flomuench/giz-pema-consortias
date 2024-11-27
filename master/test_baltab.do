preserve
keep if surveyround == 1
keep id_plateforme treatment strata_final age employes profit_euro ca_euro ca_tun_euro ca_exp_euro operation_export exp_pays 
rename id_plateforme id

save "${tables_descriptives}/sample_baltab_dime", replace


version 18

local kpis "age employes profit_euro ca_euro ca_tun_euro ca_exp_euro"
local exp "operation_export exp_pays"
local vars "`kpis' `exp' strata_final" 

* calculate F-test "manually"
reg treatment `vars'
testparm `vars'

* create balance to compare F-test with results from regressions
*iebaltab `vars' , grpvar(treatment) ///
		rowvarlabels format(%15.2fc) vce(robust) ///
		covariates(strata_final) ///
		ftest replace ///
		save("${tables_descriptives}/example_ftest")

		
* try to use stats() option - it does not execute on my computer - error message is: option stats() not allowed
iebaltab `vars', grpvar(treatment) ///
		rowvarlabels format(%15.2fc) vce(robust) ///
		covariates(strata_final) ///
		stats(desc(sd) pair(diff)) replace ///
		save("${tables_descriptives}/example_stats")


restore
		