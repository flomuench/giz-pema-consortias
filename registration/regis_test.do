***********************************************************************
* 			registration progress, eligibility, firm characteristics
***********************************************************************
*																	   
*	PURPOSE: 		check whether string answer to open questions are 														 
*					logical
*	OUTLINE:														  
*	1)				progress		  		  			
*	2)  			eligibility					 
*	3)  			characteristics							  
*																	  
*	ID variaregise: 	id (example: f101)			  					  
*	Requires: regis_inter.dta & regis_checks_survey_progress.do 	  
*	Creates:  regis_inter.dta			  
*																	  
***********************************************************************
* 	PART 1:  set environment + create pdf file for export		  			
***********************************************************************
	* import file
use "${regis_intermediate}/regis_inter", clear

***********************************************************************
* 	PART 2:  extreme values of chiffre d'affaire		  			
***********************************************************************
	* extremely high values
	
		* distribution CA 
sum ca_2020, d /* 95% = 2,472,000 ; 99% = 25,500,000  */
graph box ca_2020, marker(1, mlab(id_plateforme) mlabangle(alt) mlabsize(tiny))
	/* id's: 1120, 1108, 1011, 1220, 1092, 1103 */

		* distribution CA exports
sum ca_exp2020, d /* 95% = 549,000 ; 99% = 2,183,790  */
graph box ca_exp2020, marker(1, mlab(id_plateforme) mlabangle(alt) mlabsize(tiny))
	/* id's: 1120, 1108, 1011, 1220, 1092, 1103 */
	
		* distribution fte (make sur CA export is not driven by size
graph box rg_fte, marker(1, mlab(id_plateforme) mlabangle(alt) mlabsize(tiny))
	/* id's: 1026 1092 1207 1227 1052 1201 1071 1103 1170*/
	
		* distribution of export sales per employee
sum exp_labor_productivity, d /* 95% = 41,778 ; 99% = 183,000 */
graph box exp_labor_productivity, marker(1, mlab(id_plateforme) mlabangle(alt) mlabsize(tiny))
	/* id's 1048 1059 1942 995 1888 1242*/

		* CA export
sum ca_exp2020, d
histogram ca_exp2020 if ca_exp2020 > 10000000 & ca_exp2020 > 0
graph box ca_exp2020 if ca_exp2020 > 10000000 & ca_exp2020 > 0, marker(1, mlab(id_plateforme) mlabangle(alt) mlabsize(tiny))
br if ca_exp2020 > 10000000 & ca_exp2020 > 0 & eligible == 1

		* CA export labor productivity
graph box exp_labor_productivity, marker(1, mlab(id_plateforme) mlabangle(alt) mlabsize(tiny))

		* CA
hist ca_2020 if ca_2020 > 10000000 & ca_2020 > 0
graph box ca_2020 if ca_2020 > 10000000 & ca_2020 > 0, marker(1, mlab(id_plateforme) mlabangle(alt) mlabsize(tiny))
		
		* CA labor produditivity
graph box labor_productivity, marker(1, mlab(id_plateforme) mlabangle(alt) mlabsize(tiny))

	* check for extremely low values
*br if ca_2020 < 50 & ca_2020 > 0
*br ca_* rg_fte if ca_2020 < 500 & ca_2020 > 0


	* generate dummy for firms that need checking
gen ca_check = 0

	* identify firm with 0 CA and CA export in 2020 created in 2020 or before
replace ca_check =1 if ca_2020 == 0 & ca_exp2020 == 0 & year_created < 2021
	* identify firms that have astonishingly low CA & > 2 employees 
replace ca_check =1 if ca_2020 < 500 & ca_2020 > 0 & rg_fte > 2

	* identify firms with very high CA
forvalues x = 2018(1)2020 {
	replace ca_check =1 if ca_`x' > 2000000 & ca_`x' < . /* > 2 million = 95 percentile */
}
	* identify firms with very high CA export
forvalues x = 2018(1)2020 {
	replace ca_check =1 if ca_`x' > 550000 & ca_`x' < . /* > 550,000 = 95 percentile */
}	
	* identify firms with very high labor or export labor productivity
replace ca_check =1 if exp_labor_productivity > 40000 & exp_labor_productivity < . /* > 40,000 CA per employee */
replace ca_check =1 if labor_productivity > 150000 & labor_productivity < .  /* > 150,000 CA per employee */
	
	* identify firms with CA export > CA
forvalues x = 2018(1)2020 {
	replace ca_check =1 if ca_`x' < ca_exp`x'
}

***********************************************************************
* 	PART 6:  Save the changes made to the data + save pdf
***********************************************************************
	* set export directory
cd "$regis_intermediate"

	* save dta file
save "regis_inter", replace

