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
use "${final}/rct_rne_final", clear

	* set panel
sort ID annee, stable

	* set graphics output window on
set graphics on
	
***********************************************************************
* 	PART 1:  Missing values per variable
***********************************************************************
{

/*
* test code for one variable
count if ca_ttc == . & annee == 2022
	gen mvs_tot = r(N)
	lab var mvs_tot "MVs ca_ttc"
count if ca_ttc != . & annee == 2022
	gen obs_tot = r(N)
	lab var obs_tot "N ca_ttc"

graph hbar (min) mvs_tot obs_tot if	annee == 2022, showyvars legend(off) ///
		title("2022")
*/
	
* all variable in one plot
local vars "ca_ttc"
local vars "ca_ttc ca_local ca_export resultat_bic_dt resultat_bnc_dt revenupp_dt resultatpm_dt profit benefices_dt pertes_dt total_wage export_value export_weight import_value import_weight employees wages cost"
forvalues year = 2020(1)2022 { 
foreach var of local vars {
	* get missing values
	count if `var' == . & annee == `year'
		gen mvs_tot_`var' = r(N)
		label variable mvs_tot_`var' "MVs `var'"
	* get non missing values 
	count if `var' != . & annee == `year'
		gen obs_tot_`var' = r(N)
		label variable obs_tot_`var' "N `var'"
	}	

	* visualize missing values
local mvs "mvs_tot_ca_ttc mvs_tot_ca_local mvs_tot_ca_export mvs_tot_resultat_bic_dt mvs_tot_resultat_bnc_dt mvs_tot_revenupp_dt mvs_tot_resultatpm_dt mvs_tot_profit mvs_tot_benefices_dt mvs_tot_pertes_dt mvs_tot_total_wage mvs_tot_export_value mvs_tot_export_weight mvs_tot_import_value mvs_tot_import_weight mvs_tot_employees mvs_tot_wages mvs_tot_cost"
graph hbar (min) `mvs' if	annee == `year', showyvars legend(off) ///
		title("Missing values") ///
		blabel(total, pos(outside) format(%9.0f)) ///
		ylabel(0(50)600, angle(45)) ///
		ytitle("") ///
		name(miss_`year', replace)
gr export "${fig_all}/miss_`year'.pdf", replace
	
	* visualize observations
local obs "obs_tot_ca_ttc obs_tot_ca_local obs_tot_ca_export obs_tot_resultat_bic_dt obs_tot_resultat_bnc_dt obs_tot_revenupp_dt obs_tot_resultatpm_dt obs_tot_profit obs_tot_benefices_dt obs_tot_pertes_dt obs_tot_total_wage obs_tot_export_value obs_tot_export_weight obs_tot_import_value obs_tot_import_weight obs_tot_employees obs_tot_wages obs_tot_cost"
graph hbar (min) `obs' if	annee == `year', showyvars legend(off) /// showyvars
		title("Available Observations") ///
		blabel(total, pos(outside) format(%9.0f)) ///
		ylabel(0(50)600, angle(45)) ///
		ytitle("") ///
		name(obs_`year', replace)
gr export "${fig_all}/obs_`year'.pdf", replace
	
gr combine miss_`year' obs_`year', ///
		title("`year'") ///
		note("{bf:Note}: Total number of observations is 567.")
gr export "${fig_all}/miss_obs_`year'.pdf", replace

	* clean up
drop mvs_* obs_*

}
	
}
	

***********************************************************************
* 	PART 1:  Continuous vars kdensity plots
***********************************************************************
{

/*
	* Test code		 
count if ca_ttc != . & annee == 2022
	local obs_tot = r(N)
	display `obs_tot'
count ca_ttc if ca_ttc != . & annee == 2022 & treatment1 == 1
	local obs_t = r(N)
count ca_ttc if ca_ttc != . & annee == 2022 & treatment1 == 0
	local obs_c = r(N)

ksmirnov ca_ttc if annee == 2022, by(treatment1)
		local pvd = r(p)
		local pvd : display %3.2f `pvd'

		display `pvd'

ttest ca_ttc if annee == 2022, by(treatment1)
		local pvt_z = r(p)
		local pvt_u = r(p_u)
		local pvt_l = r(p_l)
		local pvt_z : display %3.2f `pvt_z'
		local pvt_u : display %3.2f `pvt_u'
		local pvt_l : display %3.2f `pvt_l'

display `pvt_z'
display `pvt_l'

		r(p_u) =  .21179356057972
                r(p_l) =  .78820643942028
                  r(p) =  .4235871211594401


tw ///
	(kdensity ca_ttc if treatment1 == 1  & annee == 2022, lp(l) lc(maroon) yaxis(2)) ///
	(kdensity ca_ttc if treatment1 == 0  & annee == 2022, lp(l) lc(navy) yaxis(2)) ///
	, name(ca_ttc_dens, replace) ///
	xtitle("ca_ttc", size(medium)) ///
	ytitle("Densitiy", axis(2) size(medium)) ///	
        legend(order(1 "Treatment group (`obs_t')" ///
                     2 "Control group (`obs_c')") /// 
					 pos(6) row(3)) ///
	note("{bf: Note=: Number of observations is `obs_tot'.")
gr export "${fig_all}/ca_ttc_dens.pdf", replace
*/

* Code starts

	* put all continuous variables in a list/local
local sales_abs "ca_ttc ca_local ca_export"
display `sales_abs'	
local sales_win "ca_ttc_w95 ca_local_w95 ca_export_w95"
local sales_ihs "ihs_ca_ttc_w95 ihs_ca_local_w95 ihs_ca_export_w95"
local profit_abs "profit cost employees"
local profit_win "profit_w95 cost_w95 employees_w95"
local profit_ihs "ihs_profit_w95 ihs_cost_w95 ihs_employees_w95"

local trade_abs "export_value export_weight export_value export_weight price_exp price_imp"
local trade_win "export_value_w95 export_weight_w95 export_value_w95 export_weight_w95 price_exp_w95 price_imp_w95"
local trade_ihs "ihs_export_value_w95 ihs_export_weight_w95 ihs_export_value_w95 ihs_export_weight_w95 lprice_exp_w95 lprice_imp_w95"

local vars `sales_abs' `sales_win' `sales_ihs' `profit_abs' `profit_win' `profit_ihs' `trade_abs' `trade_win' `trade_ihs'
display `vars'	

	* Take - up
local programs "aqe cf ecom all"
local year "2022"
forvalues x = 1(1)4 {
	gettoken p programs : programs
foreach var of local vars {
	* get number of observations
	count if `var' != . & annee == `year' & program`x' == 1
		local obs_tot = r(N)
	count if `var' != . & annee == `year' & take_up`x' == 1
		local obs_t = r(N)
	count if `var' != . & annee == `year' & take_up`x' == 0
		local obs_c = r(N)
		
	* get p-values for test in difference of distribution and mean
if `obs_tot' > 30 {
ksmirnov `var' if annee == `year', by(take_up`x')
		local pvd = r(p)
		local pvd : display %3.2f `pvd'

ttest `var' if annee == `year', by(take_up`x')
		local pvt_z = r(p)
		local pvt_u = r(p_u)
		local pvt_l = r(p_l)
		local pvt_z : display %3.2f `pvt_z'
		local pvt_u : display %3.2f `pvt_u'
		local pvt_l : display %3.2f `pvt_l'
		
		}
		
	* visualise
tw ///
	(kdensity `var' if take_up`x' == 1  & annee == `year', lp(l) lc(maroon) yaxis(2)) ///
	(kdensity `var' if take_up`x' == 0  & annee == `year', lp(l) lc(navy) yaxis(2)) ///
	, name(`var'_dens, replace) ///
	xtitle("`var'", size(medium)) ///
	ytitle("Densitiy", axis(2) size(medium)) ///	
        legend(order(1 "Take-up = 1 (N = `obs_t')" ///
                     2 "Take-up = 0 (N = `obs_c')") /// 
					 pos(6) row(1)) ///
	note("{bf:Note}:" "Total number of observations is `obs_tot'. Year is `year'." "P-value of Kolgomorov-Smirnov test is `pvd'." "P-values of t-test are `pvt_z' (2-sided), `pvt_u' (upper) & `pvt_l' (lower).")
gr export "${fig_`p'}/`var'_dens_tu_`year'.pdf", replace
	}				 
}	


	
	* T vs C
forvalues x = 1(1)4 {
	gettoken p programs : programs
foreach var of local vars {
	* get number of observations
	count if `var' != . & annee == `year' & program`x' == 1
		local obs_tot = r(N)
	count if `var' != . & annee == `year' & treatment`x' == 1
		local obs_t = r(N)
	count if `var' != . & annee == `year' & treatment`x' == 0
		local obs_c = r(N)
		
	* get p-values for test in difference of distribution and mean
if `obs_tot' > 30 {
ksmirnov `var' if annee == `year', by(treatment`x')
		local pvd = r(p)
		local pvd : display %3.2f `pvd'

ttest `var' if annee == `year', by(treatment`x')
		local pvt_z = r(p)
		local pvt_u = r(p_u)
		local pvt_l = r(p_l)
		local pvt_z : display %3.2f `pvt_z'
		local pvt_u : display %3.2f `pvt_u'
		local pvt_l : display %3.2f `pvt_l'
}
		
	* visualise
tw ///
	(kdensity `var' if treatment`x' == 1  & annee == `year', lp(l) lc(maroon)) ///
	(kdensity `var' if treatment`x' == 0  & annee == `year', lp(l) lc(navy)) ///
	, name(`var'_dens, replace) ///
	xtitle("`var'", size(medium)) ///
	ytitle("Densitiy", size(medium)) ///	
        legend(order(1 "Treatment (N = `obs_t')" ///
                     2 "Control(N = `obs_c')") /// 
					 pos(6) row(1)) ///
	note("{bf:Note}:" "Total number of observations is `obs_tot'. Year is `year'." "P-value of Kolgomorov-Smirnov test is `pvd'." "P-values of t-test are `pvt_z' (2-sided), `pvt_u' (upper) & `pvt_l' (lower).")
gr export "${fig_`p'}/`var'_dens_tc_`year'.pdf", replace
	}				 
}	
}	



***********************************************************************
* 	PART 2:  Bar Graph for binary variables
***********************************************************************
lab var exported "exported (yes = 1)"
lab var profitable "made profit (yes = 1)"
		* exported yes/no
local programs "aqe cf ecom all"
local year "2022"
forvalues x = 1(1)4 {
		gettoken p programs : programs
foreach var of varlist exported {  //  profitable (only 12 obs for 2022 Oct 24, add once updated

	* get number of observations
	count if `var' != . & annee == `year' & program`x' == 1
		local obs_tot = r(N)
	count if `var' != . & annee == `year' & treatment`x' == 1
		local obs_t = r(N)
	count if `var' != . & annee == `year' & treatment`x' == 0
		local obs_c = r(N)
		
	* get p-values for test in difference of mean
ttest `var' if annee == `year', by(treatment`x')
		local pvt_z = r(p)
		local pvt_u = r(p_u)
		local pvt_l = r(p_l)
		local pvt_z : display %3.2f `pvt_z'
		local pvt_u : display %3.2f `pvt_u'
		local pvt_l : display %3.2f `pvt_l'
		
		* visualize T vs C
		betterbar `var' if annee == `year', over(treatment`x') ///
		ci /// 
		barlab ///
		v ///
		legend(order(1 "Control (N = `obs_c')" ///
					 2 "Treatment (N = `obs_t')")  /// 
						 pos(6) row(1)) ///
		note("{bf:Note}:" "Total number of observations is `obs_tot'. Year is `year'." "P-values of t-test are `pvt_z' (2-sided), `pvt_u' (upper) & `pvt_l' (lower).")
	gr export "${fig_`p'}/`var'_bar_tc_`year'.pdf", replace
	
		* visualize Take-up
	* get number of observations
	count if `var' != . & annee == `year' & program`x' == 1
		local obs_tot = r(N)
	count if `var' != . & annee == `year' & take_up`x' == 1
		local obs_t = r(N)
	count if `var' != . & annee == `year' & take_up`x' == 0
		local obs_c = r(N)
		
	* get p-values for test in difference of mean
ttest `var' if annee == `year', by(take_up`x')
		local pvt_z = r(p)
		local pvt_u = r(p_u)
		local pvt_l = r(p_l)
		local pvt_z : display %3.2f `pvt_z'
		local pvt_u : display %3.2f `pvt_u'
		local pvt_l : display %3.2f `pvt_l'
		
		* visualize T vs C
		betterbar `var' if annee == `year', over(take_up`x') ///
		ci /// 
		barlab ///
		v ///
		legend(order(1 "Take-up = 0 (N = `obs_c')" ///
					 2 "Take-up = 1 (N = `obs_t')" ///
					 )  /// 
						 pos(6) row(1)) ///
		note("{bf:Note}:" "Total number of observations is `obs_tot'. Year is `year'." "P-values of t-test are `pvt_z' (2-sided), `pvt_u' (upper) & `pvt_l' (lower).")
	gr export "${fig_`p'}/`var'_bar_tu_`year'.pdf", replace
		
		
	}
}







*test code
	* get number of observations
	count if profitable != . & annee == 2022 & program1 == 1
		local obs_tot = r(N)
	count if profitable != . & annee == 2022 & treatment1 == 1
		local obs_t = r(N)
	count if profitable != . & annee == 2022 & treatment1 == 0
		local obs_c = r(N)
		
	* get p-values for test in difference of mean
ttest profitable if annee == 2022, by(treatment1)
		local pvt_z = r(p)
		local pvt_u = r(p_u)
		local pvt_l = r(p_l)
		local pvt_z : display %3.2f `pvt_z'
		local pvt_u : display %3.2f `pvt_u'
		local pvt_l : display %3.2f `pvt_l'
		
		* visualize T vs C
		betterbar profitable if annee == 2022, over(treatment1) ///
		ci /// 
		barlab ///
		v ///
		legend(order(1 "Treatment group (`obs_t')" ///
					 2 "Control group (`obs_c')")  /// 
						 pos(6) row(1)) ///
		note("{bf:Note}:" "Total number of observations is `obs_tot'. Year is 2022." "P-values of t-test are `pvt_z' (2-sided), `pvt_u' (upper) & `pvt_l' (lower).")
	gr export "${fig_`p'}/profitable_bar.pdf", replace
	
		
