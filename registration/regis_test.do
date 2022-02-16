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

	* set directory to checks folder
cd "$regis_progress"

	* create word document
putpdf begin 
putpdf paragraph

putpdf text ("Consortia: logical tests for data from registration progress"), bold linebreak
putpdf text ("Subsample of eligible companies"), linebreak
putpdf text ("Date: `c(current_date)'"), bold linebreak

	* restrict sample to only firms in 4 sectors eligible (femme pdg, residante, produit et intention export)
preserve
keep if eli_cri == 1

***********************************************************************
* 	PART 2:  extreme values of chiffre d'affaire		  			
***********************************************************************
	* extremely high values

		* CA export
histogram ca_expmean if ca_expmean < 666666666 & ca_expmean > 0
graph box ca_expmean if ca_expmean < 666666666 & ca_expmean > 0, marker(1, mlab(id_plateforme) mlabangle(alt) mlabsize(tiny))


		* CA export labor productivity
gen exp_labor_productivity if ca_mean < 666666666 = ca_mean / rg_fte
graph box exp_labor_productivity, marker(1, mlab(id_plateforme) mlabangle(alt) mlabsize(tiny))

		* CA
hist ca_mean if ca_mean < 666666666 & ca_mean > 0
graph box ca_mean if ca_mean < 666666666 & ca_mean > 0, marker(1, mlab(id_plateforme) mlabangle(alt) mlabsize(tiny))
		
		* CA labor produditivity
gen labor_productivity if ca_mean < 666666666 = ca_mean / rg_fte
graph box labor_productivity, marker(1, mlab(id_plateforme) mlabangle(alt) mlabsize(tiny))

	* check for extremely low values

***********************************************************************
* 	PART 3:  absurd values of capital social		  			
***********************************************************************


	
***********************************************************************
* 	PART 6:  save pdf
***********************************************************************
	* change directory to progress folder
cd "$regis_progress"
	* pdf
putpdf save "consortium-registration-logical-test", replace

	* restore the full data set (not only eligible firms)
restore	
	
	* export excel with list of firms that we need to contact for them to correct
		* their matricule fiscal
cd "$regis_checks"
*export excel potentially_eligible if eligible == 0 & eligible_sans_matricule == 1, firstrow(var) replace

