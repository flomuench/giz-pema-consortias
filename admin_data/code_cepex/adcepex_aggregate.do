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


***********************************************************************
* 	PART 1: Reshape into panel
***********************************************************************
	* 
preserve

	* drop year variables
drop sumvaleur_* sum_qte_* unit_price* product_name country avg_unit_price*  libelle_pays libelle_ndp length_mf

	* collapse data 
bysort ndgcf : gen tag = _n == 1

keep if tag==1

drop tag 

	** reshape long
reshape long total_revenue_ total_qty_ num_countries_ num_products_  num_combos_, i(ndgcf) j(year)

	* sort, order
order ndgcf year, first
	* sort firm-year with year 2022 first
gsort ndgcf -year

	* define as panel data
xtset ndgcf year 

	* fill up gaps for firms without exports in specific years
display _N
tsfill, full
display _N

	* does tsfill create 0 or MV? if MV, replace with 0. 
	

* 	Save the changes made to the data		  			
save "${intermediate}/cepex_long", replace



***********************************************************************
* 	PART 2: Collapse into firm pre-post level ***********************************************************************

* generate time to treat variable for pre-post aggregation
	gen ttt = . 
		replace ttt = 2022 - year if program3 == 1
		replace ttt = 2022 - year if program2 == 1		
		replace ttt = 2021 - year if program1 == 1
		
	lab var ttt "time-to-treatment"

* gen post variable (= 1 once treatment kicks on, ttt = 0)
	gen post = (ttt >= 0)
	
* collapse the data
	collapse ///
	(sum) total_revenue_ total_qty_ num_combos_ num_countries_ num_products_ ///
	(mean) total_revenue_ total_qty_ num_combos_ num_countries_ num_products_
	(firstnm) treatment1 treatment2 treatment3 treatment4 ///
	strata1 strata2 strata3 strata4 ///
	take_up1 take_up2 take_up3 take_up4 ///
	, ///
	by(ID post)
	
* 	Save the changes made to the data		  			
save "${intermediate}/cepex_pre_post", replace
	
	
