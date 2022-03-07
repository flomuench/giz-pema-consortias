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
* create a categorical variable netcoop
gen netcoop=1 if net_coop== "Gagner"
replace netcoop=2 if net_coop== "Éloigner"
replace netcoop=3 if net_coop== "Communication"
replace netcoop=4 if net_coop== "Partenariat"
replace netcoop=5 if net_coop== "Confiance"
replace netcoop=6 if net_coop== "Adversaire"
replace netcoop=7 if net_coop== "Abattre"
replace netcoop=8 if net_coop== "Connecter"
replace netcoop=9 if net_coop== "Pouvoir"
replace netcoop=10 if net_coop== "Dominer"

*labeling netcoop
label var netcoop "perception of interaction between the enterprises"
*labeling the values of netcoop
label define label_netcoop 1 "Gagner" 2 "Éloigner" 3 "Communication" 4 "Partenariat" 5 "Confiance" 6 "Adversaire" 7 "Abattre" 8 "Connecter" 9 "Pouvoir" 10 "Dominer"
label values netcoop label_netcoop

* create a dummy for the list experiment
gen listexp_percentage=0 
gen listexp_treat=0 
gen listexp_control=0 
replace listexp_treat= mean(listexp) if list_group=1
replace listexp_control= mean(listexp) if list_group=0
replace listexp_percentage= (listexp_treat - listexp_control) *100

*labeling listexp_treat
label var listexp_treat "average list experiment for the treatment group"
*labeling listexp_control
label var listexp_control "average list experiment for the control group"
*labeling listexp_percentage
label var listexp_percentage "percentage mean difference of the list experiment between treatment & control groups"

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
