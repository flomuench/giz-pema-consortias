***********************************************************************
* 			midline generate									  	  
***********************************************************************
*																	    
*	PURPOSE: generate midline variables				  							  
*																	  
*																	  
*	OUTLINE:			
*	1) Import data & generate surveyround										  
*	1) Additional calculated variables
* 	3) Indices
*
*																	  															      
*	Author:  	Ayoub Chamakhi, Kais Jomaa, Amina Bousnina		 												  
*	ID variaregise: 	id_plateforme 			  					  
*	Requires: ml_intermediate.dta 	  								  
*	Creates:  ml_final.dta			                          
*																	  
***********************************************************************
* 	PART 1:  Import data 			
***********************************************************************

use "${ml_intermediate}/ml_intermediate", clear

gen surveyround = 2
lab var surveyround "1-baseline 2-midline 3-endline"

***********************************************************************
* 	PART 2:  Additional calculated variables
***********************************************************************
										  
	* 2.1 create and label variable for each answer of net_coop, inno_mot & att_jour, att_hor, att_strat, att_cont using regex
	
generate inno_type1 = regexm(inno_types, "inno_produit")
generate inno_type2 = regexm(inno_types, "inno_process")
generate inno_type3 = regexm(inno_types, "inno_lieu")
generate inno_type4 = regexm(inno_types, "inno_commerce")
generate inno_type0 = regexm(inno_types, "inno_aucune")
label var inno_type0 "product change"
label var inno_type1 "process change"
label var inno_type2 "place change"
label var inno_type3 "commerce change"
label var inno_type4 "no change"

generate inno_mot1 = regexm(inno_mot, "inno_mot_idee")
generate inno_mot2 = regexm(inno_mot, "inno_mot_cons")
generate inno_mot3 = regexm(inno_mot, "inno_mot_cont")
generate inno_mot4 = regexm(inno_mot, "inno_mot_eve")
generate inno_mot5 = regexm(inno_mot, "inno_mot_emp")
generate inno_mot6 = regexm(inno_mot, "inno_mot_test")
generate inno_mot7 = regexm(inno_mot, "inno_mot_autre")
label var inno_mot1 "Idée personnelle"
label var inno_mot2 "Consultant"
label var inno_mot3 "Contact affaires"
label var inno_mot4 "Evenement"
label var inno_mot5 "Employée"
label var inno_mot6 "Normes"
label var inno_mot7 "Autres"
	
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

generate listexp1 = regexm(listexp, "Je soutiens et encourage toujours mon équipe.")
generate listexp2 = regexm(listexp, "Je rêvais d'être une femme qui réussit quand j'étais enfant.")
generate listexp3 = regexm(listexp, "J'essaie de faire de mon mieux dans mon travail.")
generate listexp4 = regexm(listexp, "Je me sens obligée à consulter mon mari (ou un autre homme dans ma famille) avant de prendre des décisions pour l'entreprise.")



    *Convert the below variables in numeric (non float variables)
local destrvar inno_mot1 inno_mot2 inno_mot3 inno_mot4 inno_mot5 inno_mot6 inno_mot7 
foreach x of local destrvar {
destring `x', replace
format `x' %25.0fc
}
	
	* 2.2 Create calculated variables

	* Creation of positive and negative network cooperation variables
generate net_coop_pos = netcoop1 + netcoop2 + netcoop3 + netcoop7 + netcoop9
label var net_coop_pos "Positive answers for the the perception of interactions between CEOs" 
generate net_coop_neg = netcoop4 + netcoop5 + netcoop6 + netcoop8 + netcoop10
label var net_coop_neg "Negative answers for the the perception of interactions between CEOs" 

	* Create variable to know if personal idea or not
generate inno_pers = 0
replace inno_pers = 1 if inno_mot1 == 1 
replace inno_pers = 1 if inno_mot5 == 1 
replace inno_pers = 1 if inno_mot6 == 1
label var inno_pers "Innovation coming from a personal/ employee inniative "

	* Create continuous variable for number of innovation: 
generate num_inno = inno_produit +inno_process + inno_lieu + inno_commerce
label var num_inno "Number of different types innovation introduced by a firm"

* create a new variable for survey start: 
generate survey_started= 0
replace survey_started= 1 if _merge == 3
label var survey_started "Number of firms which started the survey"
label values survey_started yesno

* Create a dummy that gives the percentage of women that ask their husbands for advice for strategic business decision-making
generate listexp_perc_husband = listexp4 / (listexp1 + listexp2 + listexp3)


//2.3 time used to fill survey
/*{
format date %td
replace heuredébut = ustrregexra( heuredébut ,"h",":")
replace heuredébut = ustrregexra( heuredébut ,"`",":")
replace heuredébut = substr(heuredébut,1,length(heuredébut)-2)
str2time heuredébut, generate(eheuredébut)

replace heurefin = ustrregexra( heurefin ,"h",":")
replace heurefin = ustrregexra( heurefin ,"`",":")
replace heurefin = substr(heurefin,1,length(heurefin)-2)
str2time heurefin, generate(eheurefin)

* Creation of the time variable
gen etime = eheurefin - eheuredébut
gen etime_positive = abs(etime)
time2str etime_positive, generate(time) seconds
label var time "durée du questionnaire par entreprise"

gen str8 stime = time
gen shours = substr(stime, 1, 2) //takes the first two digits//
gen hours = real(shour) //reads first two digits as number
gen sminutes = substr(stime, 4, 2)
gen minutes = real(sminutes)
gen sseconds = substr(stime, 7, 2)
gen seconds = real(sseconds)
gen time_secs = 3600*hours + 60*minutes + seconds
gen time_mins = time_secs/60
label var time_secs "Durée du questionnaire par entreprise en secondes"
label var time_mins "Durée du questionnaire par entreprise en minutes"

drop etime etime_positive eheuredébut eheurefin shours sminutes minutes sseconds seconds stime
}*/

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
/*
egen miss0 = rowmiss(entr_idee - produit1)
egen miss1 = rowmiss(inno_produit - inno_mot)
egen miss2 = rowmiss (inno_rd - profit_2021)
egen miss3 = rowmiss (car_efi_fin1 - att_adh5)
egen miss4 = rowmiss (att_strat)
egen miss5 = rowmiss (att_cont)
egen miss6 = rowmiss (att_jour - support1)
gen miss = miss0 + miss1 + miss2 +miss3 +miss4+miss5+miss6
*egen nomiss1 = rownonmiss(entr_idee - profit_2021)
*egen nomiss2 = rownonmiss (car_efi_fin1 - support7)
*gen nomiss= nomiss1 + nomiss2
*/
 ***********************************************************************
* 	PART 5: Generate variable to assess completed answers			  										  
***********************************************************************

generate survey_completed= 0
replace survey_completed= 1 if miss == 0
label var survey_completed "Number of firms which fully completed the survey"
label values survey_completed yesno




	* save dta file
save "${ml_fina}/ml_final", replace