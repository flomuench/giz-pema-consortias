***********************************************************************
* 			Adminstrative questions/outcome visualisations									  	  
***********************************************************************
*
*	PURPOSE: 				  							  
*																	  																  															      
*	Author:  Florian Muench & Amira Bouziri & Kaïs Jomaa & Ayoub Chamakhi 
*									    
*	  ID variable: 	id (example: f101)			  					  
*	  Requires: ad_final.dta 	  										  
*	  Creates:  ad_final.dta										  
***********************************************************************
* 	PART 0:  Paths 			
***********************************************************************
use "${final}/rct1_rne_final", clear

	* set directory to checks folder
cd "${figures}"

	* set panel
xtset ID annee

	* set graphics output window on
set graphics on

	* create 
		* panel summary table:
local balancevar "ca_ttc_dt moyennes ca_export_dt ca_local_dt resultatall_dt profitable total_wage export_value export_weight import_value price_exp_w99 lprice_exp price_imp_w99 lprice_imp import_weight net_job_creation" 
xtsum `balancevar'

		* balance table
iebaltab `balancevar' if annee == 2022, ///
    grpvar(sample) vce(robust) format(%12.2fc) replace ///
    ftest rowvarlabels ///
    savetex("${tables}/baltab_admin_treatment")


***********************************************************************
* 	PART 1:  line graph over time
***********************************************************************	
{
* for all these variables
local kpis "ca_local_dt ca_ttc_dt resultatall_dt total_wage employees"
local kpis_ihs "ihs_ca_local_dt_w99 ihs_ca_local_dt_w95 ihs_ca_ttc_dt_w99 ihs_ca_ttc_dt_w95 ihs_resultatall_dt_w99 ihs_resultatall_dt_w95 ihs_total_wage_w99 ihs_total_wage_w95 ihs_employees_w99 ihs_employees_w95"

local export "ca_export_dt export_value import_value export_weight import_weight"
local export_ihs "ihs_ca_export_dt_w99 ihs_ca_export_dt_w95 ihs_export_value_w99 ihs_export_value_w95 ihs_import_value_w99 ihs_import_value_w95 ihs_export_weight_w99 ihs_export_weight_w95 ihs_import_weight_w99 ihs_import_weight_w95"

*** for all firms 
	* T vs. C
preserve
collapse (mean) `kpis' `kpis_ihs' `export' `export_ihs' (semean) `kpis' `kpis_ihs' `export' `export_ihs', by(annee treatment)

	***** REPLACE WITH NEW VARNAMES HERE
local ys ""
foreach var of local `ys' {
	twoway ///
		(line `ys' annee if treatment == 1) ///
		(line `ys' annee if treatment == 0), ///
		legend(order(1 "Treatment" ///
					 2 "Control") ///
					 pos(6) row(1)) ///
		name(ad_line_all_`ys', replace)
	gr export "${figures}/ad_line_all_`ys'.pdf", replace
	
}
restore

		* T vs. C
preserve
collapse (mean) `kpis' `kpis_ihs' `export' `export_ihs' (semean) `kpis' `kpis_ihs' `export' `export_ihs', by(annee take_up)

	***** REPLACE WITH NEW VARNAMES HERE
local ys ""
foreach var of local `ys' {
	twoway ///
	(line `ys' annee if take_up == 1) ///
	(line `ys' annee if take_up == 0), ///
	legend(order(1 "Take-Up = 1" ///
				 2 "Take-Up = 0") ///
					 pos(6) row(1)) ///
		name(ad_line_all_`ys', replace)
	gr export "${figures}/ad_line_all_`ys'.pdf", replace
	
}
restore



*** by program
preserve 
local kpis "ca_local_dt ca_ttc_dt resultatall_dt total_wage employees"
local kpis_ihs "ihs_ca_local_dt_w99 ihs_ca_local_dt_w95 ihs_ca_ttc_dt_w99 ihs_ca_ttc_dt_w95 ihs_resultatall_dt_w99 ihs_resultatall_dt_w95 ihs_total_wage_w99 ihs_total_wage_w95 ihs_employees_w99 ihs_employees_w95"

local export "ca_export_dt export_value import_value export_weight import_weight"
local export_ihs "ihs_ca_export_dt_w99 ihs_ca_export_dt_w95 ihs_export_value_w99 ihs_export_value_w95 ihs_import_value_w99 ihs_import_value_w95 ihs_export_weight_w99 ihs_export_weight_w95 ihs_import_weight_w99 ihs_import_weight_w95"


local program "aqe cf ecom"
local ys ""
	* T vs. C
foreach p of local program {
	preserve
	collapse (mean) `kpis' `kpis_ihs' `export' `export_ihs' (semean) `kpis' `kpis_ihs' `export' `export_ihs' if programme == `p', by(annee treatment)
	
	foreach var of local `ys' {	
	
	twoway ///
	(line `ys' annee if treatment == 1) ///
	(line `ys' annee if treatment == 0), ///
	legend(order(1 "Treatment" ///
				 2 "Control") ///
				 pos(6) row(1)) ///
	name(ad_line_`p'_`ys', replace)
gr export "${fig_`p'}/ad_line_`p'_`ys'.pdf", replace
	restore
	}
}

	* Take-Up
foreach p of local program {
	preserve
	collapse (mean) `kpis' `kpis_ihs' `export' `export_ihs' (semean) `kpis' `kpis_ihs' `export' `export_ihs' if programme == `p', by(annee take_up)
	
	foreach var of local `ys' {	
	
	twoway ///
	(line `ys' annee if take_up == 1) ///
	(line `ys' annee if take_up == 0), ///
	legend(order(1 "Take-Up = 1" ///
				 2 "Take-Up = 0") ///
				 pos(6) row(1)) ///
	name(ad_line_`p'_`ys', replace)
gr export "${fig_`p'}/ad_line_`p'_`ys'.pdf", replace
	restore
	}
}

}
	
***********************************************************************
* 	PART 2:  Kdensity plot
***********************************************************************
tw ///
	(kdensity lca_export_dt if treatment == 1 & ca_export_dt >= 0 & annee == 2020 & take_up == 1, lp(l) lc(maroon) yaxis(2) bw(0.5)) ///
	(histogram lca_export_dt if treatment == 1 & ca_export_dt >= 0 & annee == 2020 & take_up == 1, freq recast(scatter) msize(small) mc(green)) ///
	(kdensity lca_export_dt if treatment == 1 & ca_export_dt >= 0 & annee == 2020 & take_up == 0, lp(l) lc(maroon) yaxis(2) bw(0.5)) ///
	(histogram lca_export_dt if treatment == 1 & ca_export_dt >= 0 & annee == 2020 & take_up == 0, freq recast(scatter) msize(small) mc(green)) ///
	(kdensity lca_export_dt if treatment == 0 & ca_export_dt >= 0 & annee == 2020, lp(l) lc(navy) yaxis(2) bw(0.5)) ///
	(histogram lca_export_dt if treatment == 0 & ca_export_dt >= 0 & annee == 2020, freq recast(scatter) msize(small) mc(green)) ///
	, name(ad_ihs_kdens_export_turnover, replace) ///
    title("Log-transformed Export Turnover in 2020", pos(12)) ///
	xtitle("Amount (in TND)", size(medium)) ///
	ytitle("Densitiy", axis(2) size(medium)) ///	
        legend(order(1 "Take-Up" ///
                     2 "Drop-Out" ///
					 3 "Control") /// 
					 pos(6) row(3))




***********************************************************************
* 	PART 3:  better bar binary variables
***********************************************************************


***********************************************************************
* 	PART 4:  treatment (take-up) impact on total sales
***********************************************************************
*