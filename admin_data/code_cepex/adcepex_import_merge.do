***********************************************************************
* 			Administrative data import
***********************************************************************
*																	  
*	PURPOSE:  Import the adminstrative data provided by Cepex	  *																	  
*	OUTLINE:														  
*	1)	Import Cepex data and list of firms from all programmes 
*	2)	Make corrections to prepare mergers
*	3)  Merge and save  file      					  
*	4)  Save  file      					  
*	  			
*
*	Authors:  	Florian Muench & Teo Firpo
*	ID variable: 	id (example: f101)			  					  
*	Requires: BI-STAT-GIZ-Octobre2024.xlsx  
				/// BI-STATOctobre2024.xlsx 
				/// Entreprises (1).xlsx
*	Creates: cepex_raw.dta 															  
***********************************************************************
* 	PART 1: Import list with all firms from the three programs 
***********************************************************************	
import excel "${raw}/Entreprises (1).xlsx", firstrow clear

	* make sure only real observations
encode id_plateforme, gen(id)	
sum id
keep in 1/`r(N)'
order id, first
sort id, stable

save "${raw}/enterprises.dta", replace


***********************************************************************
* 	PART 2: Import Cepex data and list of firms from all programmes 
***********************************************************************

	* import Cepex data (without product breakdown)
import excel "${raw}/BI-STAT-GIZ-Octobre2024.xlsx", firstrow clear
	
	* drop useless vars
	
drop Libelle_Pays Libelle_NDP

gen ndgcf = substr(CODEDOUANE, 1, strlen(CODEDOUANE) - 1)

	* rename variables so there is not clash with the other dataset 
	
forvalues i = 2020(1)2024 {
	rename SumVALEUR_`i' total_revenue_`i'
	rename Sum_Qte_`i' total_qty_`i'
	
	lab var total_revenue_`i' "Total revenue in `i'"
	lab var total_qty_`i' "Total quantity of exports in `i'"
}
 
drop if ndgcf==""

save "${raw}/temp_cepex1.dta", replace

	
	* import Cepex data (with product breakdown)
	
import excel "${raw}/BI-STAT-GIZ-2-Octobre2024.xlsx", firstrow clear
	
	* a few observations are encoded wrong, drop them
	
drop if O!=.

drop O P Q R

gen ndgcf = substr(CODEDOUANE, 1, strlen(CODEDOUANE) - 1)

save "${raw}/temp_cepex2.dta", replace



***********************************************************************
* 	PART 3: Import Cepex data and list of firms from all programmes 
***********************************************************************
save "${raw}/cepex_raw.dta", replace

erase "${raw}/temp_cepex1.dta"

erase "${raw}/temp_cepex2.dta"
