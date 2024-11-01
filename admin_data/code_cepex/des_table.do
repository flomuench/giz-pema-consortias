

foreach var of varlist ca_ttc_dt moyennes ca_export_dt total_wage export_value ///
import_value {
gen d_`var' = `var' > 0 & `var' !=.

}

gen d_profit = resultatall_dt != .

gen foreign = nationalite == "002"

** generate new job creation

gen l_emp = moyennes[_n-1]
gen created_jobs = moyennes - l_emp 

global descript treatment foreign agee d_* ca_ttc_dt moyennes ca_export_dt total_wage export_value import_value
eststo drop *
eststo stats_all: quietly estpost summarize $descript ,d
eststo stats_12: quietly estpost summarize $descript if annee == 2017,d
eststo stats_14: quietly estpost summarize $descript if annee == 2020,d
eststo stats_17: quietly estpost summarize $descript if annee == 2021,d
eststo stats_16: quietly estpost summarize $descript if annee == 2022,d
eststo stats_all_t: quietly estpost summarize $descript ,d
eststo stats_12_t: quietly estpost summarize $descript if annee == 2017 & treatment == 1,d
eststo stats_14_t: quietly estpost summarize $descript if annee == 2020 & treatment == 1,d
eststo stats_16_t: quietly estpost summarize $descript if annee == 2022 & treatment == 1,d
eststo stats_17_t: quietly estpost summarize $descript if annee == 2021 & treatment == 1,d

esttab stats_all stats_12 stats_14 stats_17 stats_16 stats_all_t stats_12_t stats_14_t stats_17_t stats_16_t, ///
	cells("mean(fmt(2))" "sd(fmt(2) par)") mtitles("Panel" "2017" "2020" "2021" "2022" "Panel_t" "2017_t" "2020_t" "2021_t" "2022_t") nonum ///
	label replace  brackets gap ///
	starlevels(* 0.1 ** 0.05 *** 0.01) collabels(none)
	
eststo drop *
