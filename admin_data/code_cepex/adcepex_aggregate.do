*******************************************************************
* 	Main regressions - Adminstrative data
*******************************************************************	   
*	PURPOSE: Aggregate from product-firm-year-level to panel & pre-post-level 
*	OUTLINE:														  
*			PART 1: Firm-year-panel level aggregation
*			PART 2: Firm-pre-post level aggregation
*																
*	Author:  	Florian Muench		      
*	ID variable: 	id (example: f101)			  			
*	  Requires: ad_final.dta 	  										  
*	  Creates:  ad_final.dta										  							  
********************************************************************
* 	PART:  set the stage - technicalities	
********************************************************************
use "${intermediate}/cepex_wide", clear


use "${raw}/temp_cepex2.dta", clear


********************************************************************
* 	PART:  basic data preparation	
********************************************************************
* order variables
order ndgcf Libelle_NDP Libelle_Pays SumVALEUR_* Sum_Qte_*

* sort
sort CODEDOUANE Libelle_NDP Libelle_Pays

* format variables
format Libelle_NDP %-30s
format CODEDOUANE %-10s

* destring
	local vars Sum_Qte_2020 SumVALEUR_2021 Sum_Qte_2021 SumVALEUR_2020	
	foreach x of local vars {
		destring `x', replace
	}

***********************************************************************
* 	PART 2: Reshape from wide to long
***********************************************************************
{
	* drop year variables
*drop sumvaleur_* sum_qte_* unit_price* product_name country avg_unit_price*  libelle_pays libelle_ndp length_mf

	* collapse data 
*bysort ndgcf : gen tag = _n == 1

*keep if tag==1

*drop tag 

	* reshape long
reshape long SumVALEUR_ Sum_Qte_, i(ndgcf Libelle_NDP Libelle_Pays) j(year) // num_countries_ num_products_  num_combos_

order CODEDOUANE ndgcf year Libelle_NDP Libelle_Pays
sort CODEDOUANE year Libelle_NDP Libelle_Pays
}

***********************************************************************
* 	PART 3: Collapse into firm-year panel
***********************************************************************
{
	* prepare collapse
		*remove rows (firm-year-product-destination combinations) with zero exports
			* Note: done in preparation for collapse to be able to count export countries & export products for each firm-year
br if SumVALEUR_ == 0 & Sum_Qte_ != 0 // 2 observations
br if SumVALEUR_ != 0 & Sum_Qte_ == 0 // 0 observations

replace SumVALEUR_ = . if SumVALEUR_ == 0 & Sum_Qte_ != 0 // 2 to missing

drop if SumVALEUR_ == 0 & Sum_Qte_ == 0 // (17,296 observations deleted)


	* as collapse does not allow counting unique (or distinct) products & countries, create a tag (=1 if the 1st occurrence for a firm-year-product and firm-year-country combination)
egen product_tag = tag(CODEDOUANE year Libelle_NDP)
egen country_tag = tag(CODEDOUANE year Libelle_Pays)

order product_tag, a(Libelle_NDP)
order country_tag, a(Libelle_Pays)

replace product_tag = . if product_tag == 0  // only nonmissing obs are counted in collapse command
replace country_tag = . if country_tag == 0  // only nonmissing obs are counted in collapse command

	* do collapse
collapse (firstnm) ndgcf (count) countries = country_tag  products = product_tag (sum) value = SumVALEUR_ quantity = Sum_Qte_, by(CODEDOUANE year)

	* sort, order
order ndgcf year, first
	* sort firm-year with year 2022 first
gsort ndgcf -year

}

	* define as panel data
encode ndgcf, gen(ID)
xtset ID year 

	* fill up gaps for firms without exports in specific years
display _N
tsfill, full
display _N

	* does tsfill create 0 or MV? if MV, replace with 0. 
		* generate indicator variable to test if replacement matters for analysis (most likely does)
	gen not_matched = (total_qty_ == .)
	
		* replace missings with 0
replace total_qty_ = 0 if total_qty_ == .
replace total_revenue_ = 0 if total_revenue_ == . 	

* generate time to treat variable for pre-post aggregation
	gen ttt = . 
		replace ttt = year - 2022 if program3 == 1
		replace ttt = year - 2022 if program2 == 1		
		replace ttt = year - 2021 if program1 == 1
		
	lab var ttt "time-to-treatment"
	
	order ttt, a(treatment4)

* gen post variable (= 1 once treatment kicks on, ttt = 0)
	gen post = (ttt >= 0)

	order post, a(ttt)
	
* 	Save the changes made to the data		  			
save "${intermediate}/cepex_long", replace

}

***********************************************************************
* 	PART 2: Collapse into firm pre-post level 
***********************************************************************
{
	

* collapse the data
	collapse (sum) exp_rev_sum = total_revenue_ exp_qty_sum = total_qty_ combo_sum = num_combos_  countries_sum = num_countries_ products_sum = num_products_ (mean) exp_rev_mean = total_revenue_ exp_qty_mean = total_qty_ combos_mean = num_combos_ countries_mean = num_countries_ products_mean = num_products_ (firstnm) treatment1 treatment2 treatment3 treatment4 strata1 strata2 strata3 strata4 take_up1 take_up2 take_up3 take_up4, by(ID post)
	
* 	Save the changes made to the data		  			
save "${intermediate}/cepex_pre_post", replace

}
	
