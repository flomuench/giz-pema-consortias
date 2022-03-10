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
label var netcoop1 "Gagner"
label var netcoop2 "Communication"
label var netcoop3 "Confiance"
label var netcoop4 "Battre"
label var netcoop5 "Pouvoir"
label var netcoop6 "Eloigner"
label var netcoop7 "Partneriat" 
label var netcoop8 "Adversaire"
label var netcoop9 "Connecter" 
label var netcoop10 "Dominer"

generate inno_mot1 = regexm(inno_mot, "inno_mot_idee")
generate inno_mot2 = regexm(inno_mot, "inno_mot_conc")
generate inno_mot3 = regexm(inno_mot, "inno_mot_cons")
generate inno_mot4 = regexm(inno_mot, "inno_mot_cont")
generate inno_mot5 = regexm(inno_mot, "inno_mot_eve")
generate inno_mot6 = regexm(inno_mot, "inno_mot_emp")
generate inno_mot7 = regexm(inno_mot, "inno_mot_test")
generate inno_mot8 = regexm(inno_mot, "inno_mot_autre")
label var inno_mot1 "Idée personnelle."
label var inno_mot2 "Concurrent"
label var inno_mot3 "Consultant"
label var inno_mot4 "Contact affaires"
label var inno_mot5 "Evenement"
label var inno_mot6 "Employée"
label var inno_mot7 "Normes"
label var inno_mot8 "Autres"

generate att_jour1  = regexm(att_jour , "lundi")
generate att_jour2  = regexm(att_jour , "mardi")
generate att_jour3  = regexm(att_jour , "mercredi")
generate att_jour4  = regexm(att_jour , "jeudi")
generate att_jour5  = regexm(att_jour , "vendredi")
generate att_jour6  = regexm(att_jour , "samedi")
generate att_jour7  = regexm(att_jour , "dimanche")
label var att_jour1 "Lundi"
label var att_jour2 "Mardi"
label var att_jour3 "Mercredi"
label var att_jour4 "Jeudi"
label var att_jour5 "Vendredi"
label var att_jour6 "Samedi"
label var att_jour7 "Dimanche"

generate att_hor1 = regexm(att_hor , "att_hor1")
generate att_hor2 = regexm(att_hor , "att_hor2")
generate att_hor3 = regexm(att_hor , "att_hor3")
generate att_hor4 = regexm(att_hor , "att_hor4")
generate att_hor5 = regexm(att_hor , "att_hor5")
label var att_hor1 "8-10h"
label var att_hor2 "9-12h30"
label var att_hor3 "12h30-15h30"
label var att_hor4 "15h30-19h"
label var att_hor5 "18-20h"
 
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
