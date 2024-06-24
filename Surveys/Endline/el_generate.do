***********************************************************************
* 			endline generate									  	  
***********************************************************************
*																	    
*	PURPOSE: generate endline variables				  							  
*																	  
*																	  
*	OUTLINE:			
*	1) Import data & generate surveyround										  
*	1) Additional calculated variables
* 	3) Indices
*
*																	  															      
*	Author:  	Amira Bouziri, Kais Jomaa, Eya Hanefi		 												  
*	ID variaregise: 	id_plateforme 			  					  
*	Requires: el_intermediate.dta 	  								  
*	Creates:  el_final.dta			                          
*																	  
***********************************************************************
* 	PART 1:  Import data 			
***********************************************************************

use "${el_intermediate}/el_intermediate", clear

***********************************************************************
* 	PART 2:  Generate survey round dummy
***********************************************************************
gen surveyround = 3
lab var surveyround "1-baseline 2-midline 3-endline"

***********************************************************************
* 	PART 3:  el_produits
***********************************************************************
generate el_produit1 = regexm(el_products, "el_produit1")
lab var el_produit1 " Best selling product or service"

generate el_produit2 = regexm(el_products, "2")
lab var el_produit2 "Second best selling product or service"

generate el_produit3 = regexm(el_products, "el_produit3")
lab var el_produit3 "Third best selling product or service" 
***********************************************************************
* 	PART 4:  Create continuous variable for number of innovation
*********************************************************************** 

generate inno_none = regexm(inno_produit, "0")
lab var inno_none "No innovation introduced"

generate inno_improve = regexm(inno_produit, "1")
lab var inno_improve "Improved existing products/services"

generate inno_new = regexm(inno_produit, "2")
lab var el_produit3 "Introduced new products/services" 

generate inno_both = inno_improve + inno_new
label var inno_both "Improved & introduced new products/services"

***********************************************************************
* 	PART 5:  Create continuous variable for inspiration of innovation
*********************************************************************** 

generate inno_mot_cons = regexm(inno_mot, "1")
lab var inno_mot_cons "Consultant"

generate inno_mot_cont = regexm(inno_mot, "2")
lab var inno_mot_cont "Other entrepreneurs"

generate inno_mot_eve = regexm(inno_mot, "3")
lab var inno_mot_eve "Event, international fair"

generate inno_mot_client = regexm(inno_mot, "4")
lab var inno_mot_client "Clients"

lab var inno_mot_other "Other"

generate inno_mot_total = inno_mot_cons + inno_mot_cont + inno_mot_eve + inno_mot_client + inno_mot_other
lab var inno_mot_client "Total of innovation inspirations"

***********************************************************************
* 	PART 6:  inno_mot
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
* 	PART 7: net_coop
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
* 	PART 8: Export
***********************************************************************

generate export_1 = regexm(export, 1)

generate export_2 = regexm(export, 2)

generate export_3 = regexm(export, 3)

drop export

label var export_1 "Direct export"
label var export_2 "Indirect export"
label var export_3 "No export"

generate export_41 = regexm(export_4, 1)


generate export_42 = regexm(export_4, 2)


generate export_43 = regexm(export_4, 3)


generate export_44 = regexm(export_4, 4)


generate export_45 = regexm(export_4, 5)


drop export_4

label var export_41 "Not profitable"
label var export_42 "Did not find clients abroad"
label var export_43 "Too complicated"
label var export_44 "Requires too much investment"
label var export_45 "Other"


***********************************************************************
* 	PART 10: Refusal to participate in consortium
***********************************************************************
generate refus_1 = regexm(int_refus, "1")
lab var refus_1 "Other companies are either not economically beneficial or very different"

generate refus_2 = regexm(int_refus, "2")
lab var refus_2 "Other companies are direct competitors, collaboration is not possible"

generate refus_3 = regexm(int_refus, "3")
lab var refus_3 "Collaboration with other women entrepreneurs is challenging on a personal level"

generate refus_4 = regexm(int_refus, "4")
lab var refus_4 "Collaboration require time that they don't have due to other priority"

generate refus_5 = regexm(int_refus, "5")
lab var refus_5 "Others" 

***********************************************************************
* 	PART 11: Generate variable to assess number of missing values per firm			  										  
***********************************************************************
	* section 1: innovation
egen miss_inno = rowmiss(inno_produit inno_process inno_lieu inno_commerce inno_mot)
	
	* section 2: network
egen miss_network = rowmiss(net_nb_f net_nb_m net_nb_qualite net_coop)
	
	* section 3: management practices
egen miss_management = rowmiss(man_fin_num man_fin_per_fre man_hr_ind man_hr_pro man_ind_awa man_source)

	* section 4: export readiness
egen miss_eri = rowmiss(exp_pra_foire exp_pra_sci exp_pra_rexp exp_pra_cible exp_pra_mission exp_pra_douane exp_pra_plan exprep_inv exprep_couts)
	
	* section 5: gender empowerment
egen miss_gender = rowmiss(car_efi_fin1 car_efi_nego car_efi_conv car_loc_succ car_loc_env listexp)
	
	* section 6: accounting/KPI
egen miss_accounting = rowmiss(employes car_empl1 car_empl2 car_empl3 car_empl4 ca ca_exp profit)

	* section 7: SSA export readiness
egen miss_eri_ssa = rowmiss(ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5)

	* create the sum of missing values per company
gen missing_values = miss_inno + miss_network + miss_management + miss_eri + miss_gender + miss_accounting
lab var missing_values "missing values per company"


***********************************************************************
* 	PART 12: Generate variable to assess completed answers		  										  
***********************************************************************
generate survey_completed= 0
replace survey_completed= 1 if missing_values == 0
label var survey_completed "Number of firms which fully completed the survey"
label values survey_completed yesno


***********************************************************************
* 	PART 13:  Generate variables for companies who answered on phone	
***********************************************************************
gen survey_phone = 0
lab var survey_phone "Comapnies who answered the survey on phone (with enumerators)" 


label define Surveytype 1 "Phone" 0 "Online"
label values survey_phone Surveytype


***********************************************************************
* 	PART 14:  generate normalized financial data (per employee)
***********************************************************************
local varn investissement comp_ca2023 comp_ca2024 comp_exp2023 comp_exp2024 comp_benefice2023 comp_benefice2024

foreach x of local varn { 
gen n`x' = 0
replace n`x' = . if `x' == 666
replace n`x' = . if `x' == 777
replace n`x' = . if `x' == 888
replace n`x' = . if `x' == 999
replace n`x' = `x'/empl if n`x'!= .
}

***********************************************************************
* 	PART 15: save dta file  										  
***********************************************************************
save "${el_final}/el_final", replace
