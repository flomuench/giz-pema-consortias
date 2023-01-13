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

***********************************************************************
* 	PART 2:  Generate survey round dummy
***********************************************************************
gen surveyround = 2
lab var surveyround "1-baseline 2-midline 3-endline"

***********************************************************************
* 	PART 3:  Create continuous variable for number of innovation
*********************************************************************** 
generate num_inno = inno_produit +inno_process + inno_lieu + inno_commerce
label var num_inno "Number of different types innovation introduced by a firm"

generate inno_aucune = 0
replace inno_aucune = 1 if inno_produit == 0 & inno_process == 0 & inno_lieu == 0 & inno_commerce == 0
label var inno_aucune "No innovation done"

***********************************************************************
* 	PART 4:  inno_mot
***********************************************************************
	* gen dummies for each innovation motivation category
generate inno_mot1 = regexm(inno_mot, "inno_mot_idee")
generate inno_mot2 = regexm(inno_mot, "inno_mot_cons")
generate inno_mot3 = regexm(inno_mot, "inno_mot_cont")
generate inno_mot4 = regexm(inno_mot, "inno_mot_eve")
generate inno_mot5 = regexm(inno_mot, "inno_mot_emp")
generate inno_mot6 = regexm(inno_mot, "inno_mot_test")
generate inno_mot7 = regexm(inno_mot, "inno_mot_autre")

	* lab each dummy/motivation category
label var inno_mot1 "personal idea"
label var inno_mot2 "exchange ideas with a consultant"
label var inno_mot3 "exchange ideas with business network"
label var inno_mot4 "exchange ideas in an event"
label var inno_mot5 "exchange ideas with employees"
label var inno_mot6 "Norms"
label var inno_mot7 "other source for innovation"

	* label the values of each dummy/motivation category + numeric format 
local inno_vars inno_mot1 inno_mot2 inno_mot3 inno_mot4 inno_mot5 inno_mot6 inno_mot7 
foreach x of local inno_vars {
	lab val `x' yesno
	destring `x', replace
	format `x' %25.0fc
}

***********************************************************************
* 	PART 5: net_coop
***********************************************************************
	* generate dummies for each cooperative word
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

	* lab each cooperate word dummy
label var netcoop1 "Win"
label var netcoop2 "Communicate"
label var netcoop3 "Trust"
label var netcoop4 "Beat"
label var netcoop5 "Power"
label var netcoop6 "Retreat"
label var netcoop7 "Partnership" 
label var netcoop8 "Opponent"
label var netcoop9 "Connect" 
label var netcoop10 "Dominate"

	* generate a count of positive & negative cooperative words
generate net_coop_pos = netcoop1 + netcoop2 + netcoop3 + netcoop7 + netcoop9
label var net_coop_pos "Positive answers for the the perception of interactions between CEOs" 
generate net_coop_neg = netcoop4 + netcoop5 + netcoop6 + netcoop8 + netcoop10
label var net_coop_neg "Negative answers for the the perception of interactions between CEOs" 


***********************************************************************
* 	PART 6: Time to complete survey (limited insight given we only see most recent attempt)
***********************************************************************
/*
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
*/

***********************************************************************
* 	PART 7: Generate variable to assess number of missing values per firm			  										  
***********************************************************************
	* section 1: innovation
egen miss_inno = rowmiss(inno_produit inno_process inno_lieu inno_commerce inno_mot)
	
	* section 2: network
egen miss_network = rowmiss(net_nb_f net_nb_m net_nb_qualite net_coop)
	
	* section 3: management practices
egen miss_management = rowmiss(net_nb_f net_nb_m net_nb_qualite net_coop)

	* section 4: export readiness
egen miss_eri = rowmiss(exp_pra_foire exp_pra_sci exp_pra_rexp exp_pra_cible exp_pra_mission exp_pra_douane exp_pra_plan exprep_inv exprep_couts ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5)
	
	* section 5: gender empowerment
egen miss_gender = rowmiss(car_efi_fin1 car_efi_nego car_efi_conv car_loc_succ car_loc_env list_group listexp)
	
	* section 6: accounting/KPI
egen miss_accounting = rowmiss(empl car_empl1 car_empl2 car_empl3 car_empl4 ca ca_exp profit)

	* create the sum of missing values per company
gen missing_values = miss_inno + miss_network + miss_management + miss_eri + miss_gender + miss_accounting
lab var missing_values "missing values per company"


***********************************************************************
* 	PART 8: Generate variable to assess completed answers		  										  
***********************************************************************
generate survey_completed= 0
replace survey_completed= 1 if missing_values == 0
label var survey_completed "Number of firms which fully completed the survey"
label values survey_completed yesno


***********************************************************************
* 	PART 9: save dta file  										  
***********************************************************************
save "${ml_final}/ml_final", replace
