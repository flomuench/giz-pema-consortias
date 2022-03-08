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

*/
**********************************************************************
* 	PART 2:  Additional calculated variables
***********************************************************************
										  
	* 2.1 create and label variable for each answer of net_coop, inno_mot & att_jour, att_hor using regex
	
generate netcoop1 = regexm(net_coop, "1")
generate netcoop2 = regexm(net_coop, "2")
generate netcoop3 = regexm(net_coop, "3")
generate netcoop4 = regexm(net_coop, "4")
generate netcoop5 = regexm(net_coop, "5")
generate netcoop6 = regexm(net_coop, "6")
generate netcoop7 = regexm(net_coop, "7")
generate netcoop8 = regexm(net_coop, "8")
generate netcoop9 = regexm(net_coop, "9")
generate netcoop10 = regexm(net_coop, "10")

/*
	
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

* 2.2 create variables for list experiment
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


*/


/*2.3 time used to fill survey

g time_survey= heurefin-heuredébut
*lab var time_survey "Time used to complete the survey"


* 2.4 CREATE nb_dehors_famille/(net_nb_dehors_famille+ net_nb_famille)

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
egen miss2 = rowmiss (car_efi_fin1 - support7)
gen miss = miss1 + miss2
*egen nomiss1 = rownonmiss(entr_idee - profit_2021)
*egen nomiss2 = rownonmiss (car_efi_fin1 - support7)
*gen nomiss= nomiss1 + nomiss2

 

*/
*/
	* save dta file
cd "$bl_intermediate"
save "bl_inter", replace
