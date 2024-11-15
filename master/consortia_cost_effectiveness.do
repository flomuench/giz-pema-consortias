***********************************************************************
* 			Master endline analysis/regressions				  
***********************************************************************
*																	  
*	PURPOSE: 	Undertake treatment effect analysis of
*				outcomes
*
*													
*																	  
*	Authors:  	Florian Muench
*	ID variable: id_platforme		  					  
*	Requires:  	consortium_final.dta
***********************************************************************
* 	Part 0: 	set the stage		  
***********************************************************************
{
use "${master_final}/consortium_final", clear

/*	* export dta file for Michael Anderson
preserve
keep id_plateforme surveyround treatment take_up *net_size *net_nb_f *net_nb_m *net_nb_qualite *net_coop_pos strata_final
save "${master_final}/sample.dta", replace
restore
*/

* export dta file for Damian Clarke
/*
preserve
keep id_plateforme surveyround treatment take_up *genderi *female_efficacy *female_loc strata_final
save "${master_final}/sample_clarke.dta", replace
restore
*/	
		* change directory
cd "${master_regressiontables}/endline/regressions"

		* declare panel data
xtset id_plateforme surveyround, delta(1)

		* set graphics on for coefplot
set graphics on

		* set color scheme
if "`c(username)'" == "MUNCHFA" | "`c(username)'" == "fmuench"  {
	set scheme stcolor
} 
	else {

set scheme s1color
		
	}
}



***********************************************************************
* 	Part 1: 	set the stage		  
***********************************************************************
* all respondents
	* calculate total 
egen tot_sales_el_t = sum(ca_w95) if treatment == 1 & surveyround == 3		   
egen tot_sales_el_c = sum(ca_w95) if treatment == 0 & surveyround == 3	  
sum tot_sales_el_t
local t = r(mean)	 
sum tot_sales_el_c   
local c = r(mean)

display `t' - `c' 			// 5,095,520 --> additional sales!
display (`t' - `c')*0.19	// 968,148.8 --> additional tax return!


egen tot_sales_bl_t = sum(ca_w95) if treatment == 1 & surveyround == 1		   
egen tot_sales_bl_c = sum(ca_w95) if treatment == 0 & surveyround == 1	  
sum tot_sales_bl_t
local t = r(mean)	 
sum tot_sales_bl_c   
local c = r(mean) 			

display `t' - `c'			// -3,838,340 --> at baseline, control sales were 3.8 million higher

* but, how many respondents in T & C?
count if ca_w95 != . & surveyround == 3 & treatment == 1 // 62
count if ca_w95 != . & surveyround == 3 & treatment == 0 // 56


* sub-sample of endline respondents
bys id_plateforme: gen el_sales_available = (ca_w95 != .) if surveyround == 3
bys id_plateforme: gen bl_sales_available = (ca_w95 != .) if surveyround == 1

egen el_sales_available_temp = min(el_sales_available), by(id_plateforme)
egen bl_sales_available_temp = min(bl_sales_available), by(id_plateforme)

egen sales_available_bl_el = rowtotal(el_sales_available_temp bl_sales_available_temp)


	* create indicator variables sales-question reponse at each surveyround
bys id_plateforme surveyround: gen sales_available = (ca_w95 != .)
egen sales_available_always = min(sales_available > 0), by(id_plateforme)

	* how many firms responded to sales-question at EL in each group?
codebook ca_w95 if surveyround == 3 & sales_available_always == 1 & treatment == 1 // 53
codebook ca_w95 if surveyround == 3 & sales_available_always == 1 & treatment == 0 // 43

codebook ca_w95 if surveyround == 3 & sales_available_bl_el == 2 & treatment == 1 // 62
codebook ca_w95 if surveyround == 3 & sales_available_bl_el == 2 & treatment == 0 // 56


egen tot_sales_bl_tb = sum(ca_w95) if treatment == 1 & surveyround == 1	& sales_available_always == 1   
egen tot_sales_bl_cb = sum(ca_w95) if treatment == 0 & surveyround == 1	& sales_available_always == 1  
sum tot_sales_bl_t
local t = r(mean)	 
sum tot_sales_bl_c   
local c = r(mean) 