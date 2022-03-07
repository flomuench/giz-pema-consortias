***********************************************************************
* 			baseline generate									  	  
***********************************************************************
*																	    
*	PURPOSE: generate baseline variables				  							  
*																	  
*																	  
*	OUTLINE:														  
*	1) Sum up points of info questions
* 	2) Indices
*
*																	  															      
*	Author:  	Fabian Scheifele						  
*	ID variaregise: 	id_plateforme (example: 777)			  					  
*	Requires: bl_inter.dta 	  								  
*	Creates:  bl_inter.dta			                          
*																	  
***********************************************************************
* 	PART 1:  Create and label vars that are sums of multiple answer questions			
***********************************************************************

use "${bl_intermediate}/bl_inter", clear
/*
g dig_con2 = 0 
replace dig_con2 = 1 if dig_con2_correct
lab var dig_con2 "Correct response to question about digital markets"

g dig_con4 = 0
replace dig_con4 = 1 if dig_con4_rech == 1
lab var dig_con4 "Correct response to question about online ads"

g dig_con6_score = 0
replace dig_con6_score = dig_con6_score + 0.33 if dig_con6_referencement_payant == 1
lab var dig_con6_score "Score on question about Google Ads"

g dig_presence_score = 0
replace dig_presence_score = 0.33 if dig_presence1 == 1
replace dig_presence_score = dig_presence_score + 0.33 if dig_presence2 == 1
replace dig_presence_score = dig_presence_score + 0.33 if dig_presence3 == 1
lab var dig_presence_score "Score on question about online presence channels"

g dig_presence3_exscore = 0
replace dig_presence3_exscore = 0.125 if dig_presence3_ex1 == 1
lab var dig_presence3_exscore "Score on examples of digital channels used"

*/
**********************************************************************
* 	PART 2:  Additional calculated variables
***********************************************************************
/*
g time_survey= heurefin-heuredébut
lab var time_survey "Time used to complete the survey"



*/
/*
***********************************************************************
* 	PART 3: factor variable gender 			  										  
***********************************************************************
label define sex 1 "female" 0 "male"
tempvar Gender
encode rg_gender, gen(`Gender')
drop rg_gender
rename `Gender' rg_gender_rep
replace rg_gender = 0 if rg_gender == 2
lab values rg_gender sex

tempvar Genderpdg
encode rg_sex_pdg, gen(`Genderpdg')
drop rg_sex_pdg
rename `Genderpdg' rg_gender_pdg
replace rg_gender_pdg = 0 if rg_gender_pdg == 2
lab values rg_gender_pdg sex
*/
***********************************************************************
* 	PART 4: Generate variable to assess number of missing values per firm			  										  
***********************************************************************

egen miss1 = rowmiss(entr_idee - profit_2021)
egen miss2 = rowmiss (car_efi_fin1 - att_cont5)
gen miss = miss1 + miss2
egen nomiss1 = rownonmiss(entr_idee - profit_2021)
egen nomiss2 = rownonmiss (car_efi_fin1 - att_cont5)
gen nomiss= nomiss1 + nomiss2

list 

*/
*/
	* save dta file
cd "$bl_intermediate"
save "bl_inter", replace
