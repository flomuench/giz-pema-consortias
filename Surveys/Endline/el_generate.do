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

drop el_products
***********************************************************************
* 	PART 4:  Create continuous variable for number of innovation
*********************************************************************** 

generate inno_none = regexm(inno_produit, "0")
lab var inno_none "No innovation introduced"

generate inno_improve = regexm(inno_produit, "1")
lab var inno_improve "Improved existing products/services"

generate inno_new = regexm(inno_produit, "2")
lab var inno_new "Introduced new products/services" 

generate inno_both = inno_improve + inno_new
label var inno_both "Improved & introduced new products/services"

drop inno_produit
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

generate inno_mot_dummyother = regexm(inno_mot, "5")
lab var inno_mot_dummyother "Binary other source of inspiration"

lab var inno_mot_other "Example of other source of inspiration"

generate inno_mot_total = inno_mot_cons + inno_mot_cont + inno_mot_eve + inno_mot_client + inno_mot_dummyother
lab var inno_mot_total "Total of innovation inspirations"

drop inno_mot

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
label var netcoop1 "Jealousy"
label var netcoop2 "Cooperate"
label var netcoop3 "Trust"
label var netcoop4 "Protecting business secrets"
label var netcoop5 "Risks"
label var netcoop6 "Conflict"
label var netcoop7 "Learn" 
label var netcoop8 "Partnership"
label var netcoop9 "Connect" 
label var netcoop10 "Competition"

	* generate a count of positive & negative cooperative words
generate net_coop_pos = netcoop1 + netcoop2 + netcoop3 + netcoop7 + netcoop9
label var net_coop_pos "Positive answers for the the perception of interactions between CEOs" 
generate net_coop_neg = netcoop4 + netcoop5 + netcoop6 + netcoop8 + netcoop10
label var net_coop_neg "Negative answers for the the perception of interactions between CEOs" 

drop net_coop
***********************************************************************
* 	PART 8: Export
***********************************************************************

generate export_1 = regexm(export, "1")

generate export_2 = regexm(export, "2")

generate export_3 = regexm(export, "3")

drop export

label var export_1 "Direct export"
label var export_2 "Indirect export"
label var export_3 "No export"

*export = 0 if it does not export
 
replace ca_exp = 0 if export_1 == 0
replace ca_exp_2024 = 0 if export_1 == 0

generate export_41 = regexm(export_4, "1")

generate export_42 = regexm(export_4, "2")

generate export_43 = regexm(export_4, "3")

generate export_44 = regexm(export_4, "4")

generate export_45 = regexm(export_4, "5")

drop export_4

label var export_41 "Not profitable"
label var export_42 "Did not find clients abroad"
label var export_43 "Too complicated"
label var export_44 "Requires too much investment"
label var export_45 "Other"

* replace ssa orders 0 if it is missing value
replace clients_ssa_commandes = 0 if clients_ssa == 0 
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
* 	PART 11: Network
***********************************************************************
gen net_size3_m = net_size3 - net_gender3
lab var net_size3_m "Male entrepneur business discussion"

gen net_size4_m = net_size4 - net_gender4
lab var net_size4_m "Male Family/friends business discussion"
***********************************************************************
* 	PART 11: Generate variable to assess number of missing values per firm			  										  
***********************************************************************
	* section 1: innovation
egen miss_inno = rowmiss(inno_proc_met inno_proc_log inno_proc_prix inno_proc_sup inno_proc_autres)

	* section 2 export
egen miss_export = rowmiss(exp_pays exp_pays_ssa clients clients_ssa clients_ssa_commandes) if export_3 == 0

	* section 3 export practices
egen miss_exp_pracc = rowmiss(exp_pra_rexp exp_pra_foire exp_pra_sci exprep_norme exp_pra_vent)

	* section 4: SSA export readiness
egen miss_eri_ssa = rowmiss(ssa_action1 ssa_action2 ssa_action3 ssa_action4)

	* section 5: employees
egen miss_empl = rowmiss(employes car_empl1 car_empl2)

	* section 6: management indicators
egen miss_manindicators = rowmiss(man_fin_per_ind man_fin_per_pro man_fin_per_qua man_fin_per_sto man_fin_per_emp man_fin_per_liv)

	* section 7: management practices
egen miss_manprac = rowmiss(man_fin_per_fre man_fin_pra_bud man_fin_pra_pro man_fin_pra_dis man_ind_awa)

	* section 8: marketing source
egen miss_marksource = rowmiss(man_source_cons man_source_pdg man_source_fam man_source_even man_source_autres)

	* section 8: network size
egen miss_network = rowmiss(net_association net_size3 net_size4 net_gender3 net_gender4 net_gender3_giz) if net_size3 > 0 & net_size4 > 0

	* section 10: network services
egen miss_networkserv = rowmiss(net_services_pratiques net_services_produits net_services_mark net_services_sup net_services_contract net_services_confiance net_services_autre) if net_size3 > 0

	*section 11: netcoop
egen miss_netcoop = rowmiss (net_coop_pos net_coop_neg)

	*section 12: car_efi
egen miss_carefi = rowmiss(car_efi_fin1 car_efi_man car_efi_motiv)
	
	*section 13: car_loc
egen miss_carloc = rowmiss(car_loc_env car_loc_exp car_loc_soin)

	*section 14: listexp
egen miss_extlist = rowmiss(listexp1)
	
	* section 15: accounting/KPI
egen miss_accounting = rowmiss(profit profit_2024 ca ca_2024 ca_exp ca_exp_2024)

	

	* create the sum of missing values per company
gen missing_values = miss_inno + miss_export + miss_exp_pracc + miss_eri_ssa + miss_empl + miss_manindicators + miss_manprac + miss_marksource + miss_network + miss_networkserv + miss_netcoop + miss_carefi + miss_carloc + miss_extlist + miss_accounting
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

	*responded online
local ids 983 985 1009 1028 1044 1045 1096 1098 1102 1116 1125 1134 1159 1195 1196 1197 1199 1201 1202 1203 1204 1205

foreach var of local ids {
	replace survey_phone = 1 if id_plateforme == `var'
}

***********************************************************************
* 	PART 14:  Transform categorical variables into continuous variables
***********************************************************************
*ca_intervalles
replace ca = 5000 if comp_ca2023_intervalles == 8
replace ca = 25000 if comp_ca2023_intervalles == 7
replace ca = 100000 if comp_ca2023_intervalles == 6
replace ca = 225000 if comp_ca2023_intervalles == 5
replace ca = 400000 if comp_ca2023_intervalles == 4
replace ca = 600000 if comp_ca2023_intervalles == 3
replace ca = 850000 if comp_ca2023_intervalles == 2
replace ca = 1000000 if comp_ca2023_intervalles == 1

*comp_ca2024_intervalles
replace ca_2024 = 5000 if comp_ca2024_intervalles == 8
replace ca_2024 = 25000 if comp_ca2024_intervalles == 7
replace ca_2024 = 100000 if comp_ca2024_intervalles == 6
replace ca_2024 = 225000 if comp_ca2024_intervalles == 5
replace ca_2024 = 400000 if comp_ca2024_intervalles == 4
replace ca_2024 = 600000 if comp_ca2024_intervalles == 3
replace ca_2024 = 850000 if comp_ca2024_intervalles == 2
replace ca_2024 = 1000000 if comp_ca2024_intervalles == 1

*profit_intervalles
replace profit = 5000 if profit_2023_category_perte == 8
replace profit = 25000 if profit_2023_category_perte == 7
replace profit = 100000 if profit_2023_category_perte == 6
replace profit = 225000 if profit_2023_category_perte == 5
replace profit = 400000 if profit_2023_category_perte == 4
replace profit = 600000 if profit_2023_category_perte == 3
replace profit = 850000 if profit_2023_category_perte == 2
replace profit = 1000000 if profit_2023_category_perte == 1

replace profit = 5000 if profit_2023_category_gain == 8
replace profit = 25000 if profit_2023_category_gain == 7
replace profit = 100000 if profit_2023_category_gain == 6
replace profit = 225000 if profit_2023_category_gain == 5
replace profit = 400000 if profit_2023_category_gain == 4
replace profit = 600000 if profit_2023_category_gain == 3
replace profit = 850000 if profit_2023_category_gain == 2
replace profit = 1000000 if profit_2023_category_gain == 1

*profit_2024_intervalles
replace profit_2024 = 5000 if profit_2024_category_perte == 8
replace profit_2024 = 25000 if profit_2024_category_perte == 7
replace profit_2024 = 100000 if profit_2024_category_perte == 6
replace profit_2024 = 225000 if profit_2024_category_perte == 5
replace profit_2024 = 400000 if profit_2024_category_perte == 4
replace profit_2024 = 600000 if profit_2024_category_perte == 3
replace profit_2024 = 850000 if profit_2024_category_perte == 2
replace profit_2024 = 1000000 if profit_2024_category_perte == 1

replace profit_2024 = 5000 if profit_2024_category_gain == 8
replace profit_2024 = 25000 if profit_2024_category_gain == 7
replace profit_2024 = 100000 if profit_2024_category_gain == 6
replace profit_2024 = 225000 if profit_2024_category_gain == 5
replace profit_2024 = 400000 if profit_2024_category_gain == 4
replace profit_2024 = 600000 if profit_2024_category_gain == 3
replace profit_2024 = 850000 if profit_2024_category_gain == 2
replace profit_2024 = 1000000 if profit_2024_category_gain == 1

replace profit=profit*(-1) if profit_2023_category==0

replace profit_2024=profit_2024*(-1) if profit_2024_category==0

*export = 0 if it does not export
 
replace ca_exp = 0 if export_1 == 0
replace ca_exp_2024 = 0 if export_1 == 0

*marginal_exp_2023
label define ext_exp 0 "Did not export" 1 "Exported"

gen marginal_exp_2023 = 0
lab var marginal_exp_2023 "extensive margin of export based on export turnover 2023"
label values marginal_exp_2023 ext_exp

replace marginal_exp_2023 = 1 if ca_exp > 0 & ca_exp < .


*marginal_exp_2024
gen marginal_exp_2024 = 0
lab var marginal_exp_2024 "extensive margin of export based on export turnover 2024"
label values marginal_exp_2024 ext_exp

replace marginal_exp_2024 = 1 if ca_exp_2024 > 0 & ca_exp_2024 < .

************** Correct financial data so that it is not replaced by intervals FICHE SUIVI **************
// id_plateforme 1005 / entreprise n'est plus en activité depuis aout 2022 elle revient aux production aux mai 2024 elle à une perte de 17000 dt depuis aout 2022 jusquà maintenent donc les cA totale en 2023 0 est en 2024 elle à dit que dans le mois de mai (le mois de retour en production) est de 500 dt 
 
replace ca = 0 if id_plateforme == 1005
replace ca_2024 = 500 if id_plateforme == 1005
replace profit = -5700 if id_plateforme == 1005
replace profit_2024 = -5700 if id_plateforme == 1005


// id_plateforme 1138 / n'a pas donnée les bénéfices en 2024 (elle n'a pas aucun aidé combients)
replace profit_2024 = 999 if id_plateforme == 1138

// id_plateforme 1150 / elle a donné benefice 3000 exactement, mais comme 3000 inferieur à 5000 donc j'ai du mettre dans l'intervalle entre 0 et 9 999. ( pas besoin de retour dans la fiche de correction ) 
replace profit_2024 = 3000 if id_plateforme == 1150

// id_plateforme 1151 /	les benefices en 2024 =0  stable elle a dit jusqua juin est neant 
replace profit_2024 = 0 if id_plateforme == 1151

*id_plateforme 1132 // Refuses to give comptability
local compta_vars "ca comp_ca2023_intervalles ca_2024 comp_ca2024_intervalles ca_exp ca_exp_2024 profit profit_2024 profit_2023_category_perte profit_2023_category_gain profit_2024_category_perte profit_2024_category_gain"

foreach var of local compta_vars {
	replace `var' = 888 if id_plateforme == 1132 
}

	*id_plateforme 1167 // Has no idea about CA 2024
replace ca_2024 = 999 if id_plateforme == 1167

* 	PART 15:  generate normalized financial data (per employee)
***********************************************************************
local varn ca ca_2024 ca_exp ca_exp_2024 profit profit_2024

foreach x of local varn { 
gen n`x' = 0
replace n`x' = . if `x' == 666
replace n`x' = . if `x' == 777
replace n`x' = . if `x' == 888
replace n`x' = . if `x' == 999
replace n`x' = `x'/employes if n`x'!= .
}

***********************************************************************
* 	PART 16: save dta file  										  
***********************************************************************
save "${el_final}/el_final", replace
