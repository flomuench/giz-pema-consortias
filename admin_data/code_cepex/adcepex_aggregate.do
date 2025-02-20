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
*use "${intermediate}/cepex_wide", clear


use "${raw}/cepex_raw.dta", clear


********************************************************************
* 	PART:  basic data preparation	
********************************************************************
{
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


***********************************************************************
* 	PART 4: Fill gaps in panel with zeros
***********************************************************************
{
	* define as panel data
encode ndgcf, gen(ID)
xtset ID year 

	* fill up gaps for firms without exports in specific years
display _N // 1130 
tsfill, full
display _N // 1530

	* replace gaps with zeros instead of missing values
local vars "countries products value quantity"
	foreach var of local vars {
		replace `var' = 0 if `var' == .
	}


	* fill in missing ID information for rows with zeros
decode ID, gen(id)	
drop ndgcf CODEDOUANE
rename id ndgcf
order ID ndgcf year, first
}	
	
***********************************************************************
* 	PART 5: save & continue with merging
***********************************************************************
save "${intermediate}/cepex_inter", replace // before cepex_long
	
