***********************************************************************
* 			consortia master do files: generate variables  
***********************************************************************
*																	  
*	PURPOSE: create variables based on merged data			  
*																	  
*	OUTLINE: 	PART I: PII data
*					PART 1: clean regis_final	  
*
*				PART II: Analysis data
*					PART 3: 
*																	  
*	Authors:  	Florian Münch, Kaïs Jomaa, Ayoub Chamakhi & Amina Bousnina						    
*	ID variable: id_platforme		  					  
*	Requires:  	consortium__master_inter.dta
*	Creates:	consortium__master_final.dta
***********************************************************************
********************* 	I: PII data ***********************************
***********************************************************************	
{
***********************************************************************
* 	PART 1:    import data  
***********************************************************************
use "${master_intermediate}/consortium_pii_inter", clear

***********************************************************************
* 	PART 2:  generate dummy account contact information missing
***********************************************************************
gen comptable_missing = 0, a(comptable_email)
	replace comptable_missing = 1 if comptable_numero == . & comptable_email == ""
	replace comptable_missing = 1 if comptable_numero == 88888888 & comptable_email == "nsp@nsp.com"
	replace comptable_missing = 1 if comptable_numero == 88888888 & comptable_email == "refus@refus.com"
	replace comptable_missing = 1 if comptable_numero == 99999999 & comptable_email == "nsp@nsp.com"


***********************************************************************
* 	PART 3:    Add Tunis to rg_adresse using PII data 
***********************************************************************

*gen dummy if tunis in variable
gen contains_tunis = strpos(rg_adresse, "tunis") > 0 | strpos(rg_adresse, "tunisia") > 0

*gen new rg_adresse just in case
gen rg_adresse_modified = rg_adresse

*add tunis if it does not contain it or tunisia
replace rg_adresse_modified = rg_adresse_modified + ", tunis" if !contains_tunis

***********************************************************************
* 	PART 4:  save
***********************************************************************
save "${master_final}/consortium_pii_final", replace

}


***********************************************************************
********************* 	II: Analysis data *****************************
***********************************************************************	
use "${master_intermediate}/consortium_inter", clear

***********************************************************************
* 	PART 1:  generate take-up variable
***********************************************************************
{
* PHASE 1 of the treatment: "consortia creation"
	*  label variables from participation "presence_ateliers"
local take_up_vars "webinairedelancement rencontre1atelier1 rencontre1atelier2 rencontre2atelier1 rencontre2atelier2 rencontre3atelier1 rencontre3atelier2 eventcomesa rencontre456 atelierconsititutionjuridique"

lab def presence_status 0 "Drop-out" 1 "Participate"

foreach var of local take_up_vars {
	gen `var'1 = `var'
	replace `var'1 = "1" if `var' == "présente"  | `var' == "désistement"
	replace `var'1 = "0" if `var' == "absente"
	drop `var'
	destring `var'1, replace
	rename `var'1 `var'
	lab values `var' presence_status
}
	

	* Create take-up percentage per firm
egen take_up_per = rowtotal(webinairedelancement rencontre1atelier1 rencontre1atelier2 rencontre2atelier1 rencontre2atelier2 rencontre3atelier1 rencontre3atelier2 eventcomesa rencontre456 atelierconsititutionjuridique), missing
replace take_up_per = take_up_per/10
replace take_up_per = 0 if surveyround == 1
replace take_up_per = 0 if surveyround == 2 & treatment == 0 

	* create a take_up
replace desistement_consortium = 1 if id_plateforme == 1040
replace desistement_consortium = 1 if id_plateforme == 1192

gen take_up = 0, a(take_up_per)
replace take_up= 1 if treatment == 1 & desistement_consortium != 1
lab var take_up "Consortium member"
lab values take_up presence_status

	* create a status variable for surveys
gen status = (take_up_per > 0 & take_up_per < .)


* PHASE 2 of the treatment: "consortia export promotion"
replace take_up = 0 if id_plateforme == 991 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 991 & surveyround ==3
replace take_up = 0 if id_plateforme == 994 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 994 & surveyround ==3
replace take_up = 0 if id_plateforme == 996 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 996 & surveyround ==3

replace take_up = 0 if id_plateforme == 998 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 998 & surveyround ==3

replace take_up = 0 if id_plateforme == 1015 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1015 & surveyround ==3

replace take_up = 0 if id_plateforme == 1019 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1019 & surveyround ==3

replace take_up = 0 if id_plateforme == 1022 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1022 & surveyround ==3

replace take_up = 0 if id_plateforme == 1026 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1026 & surveyround ==3

replace take_up = 0 if id_plateforme == 1028 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1028 & surveyround ==3

replace take_up = 0 if id_plateforme == 1035 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1035 & surveyround ==3

replace take_up = 0 if id_plateforme == 1037 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1037 & surveyround ==3

replace take_up = 0 if id_plateforme == 1040 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1040 & surveyround ==3

replace take_up = 0 if id_plateforme == 1045 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1045 & surveyround ==3

replace take_up = 0 if id_plateforme == 1051  & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1051 & surveyround ==3

replace take_up = 0 if id_plateforme == 1059 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1059 & surveyround ==3

replace take_up = 0 if id_plateforme == 1061 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1061 & surveyround ==3

replace take_up = 0 if id_plateforme == 1079 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1079 & surveyround ==3

replace take_up = 0 if id_plateforme == 1087 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1087 & surveyround ==3

replace take_up = 0 if id_plateforme == 1089 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1089 & surveyround ==3

replace take_up = 0 if id_plateforme == 1097 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1097 & surveyround ==3

replace take_up = 0 if id_plateforme == 1128 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1128 & surveyround ==3

replace take_up = 0 if id_plateforme == 1136 & surveyround ==3 
replace desistement_consortium = 1 if id_plateforme == 1136 & surveyround ==3

replace take_up = 0 if id_plateforme == 1146 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1146 & surveyround ==3

replace take_up = 0 if id_plateforme == 1150 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1150 & surveyround ==3

replace take_up = 0 if id_plateforme == 1162 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1162 & surveyround ==3

replace take_up = 0 if id_plateforme == 1166 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1166 & surveyround ==3

replace take_up = 0 if id_plateforme == 1169 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1169 & surveyround ==3

replace take_up = 0 if id_plateforme == 1184 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1184 & surveyround ==3

replace take_up = 0 if id_plateforme == 1192 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1192 & surveyround ==3

replace take_up = 0 if id_plateforme == 1194 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1194 & surveyround ==3

replace take_up = 0 if id_plateforme == 1195 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1195 & surveyround ==3

replace take_up = 0 if id_plateforme == 1201 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1201 & surveyround ==3

replace take_up = 0 if id_plateforme == 1214 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1214 & surveyround ==3
 
replace take_up = 0 if id_plateforme == 1219 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1219 & surveyround ==3

replace take_up = 0 if id_plateforme == 1225 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1225 & surveyround ==3

replace take_up = 0 if id_plateforme == 1231 & surveyround ==3 
replace desistement_consortium = 1 if id_plateforme == 1231 & surveyround ==3

replace take_up = 0 if id_plateforme == 1233 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1233 & surveyround ==3

replace take_up = 0 if id_plateforme == 1241 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1241 & surveyround ==3

replace take_up = 0 if id_plateforme == 1242 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1242 & surveyround ==3

replace take_up = 0 if id_plateforme == 1247 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1247 & surveyround ==3

* Mise à jour des drop out : modification faite par Eya le 18/10/2024 

replace take_up = 0 if id_plateforme == 1159 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1159 & surveyround ==3

replace take_up = 0 if id_plateforme == 985 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 985 & surveyround ==3

replace take_up = 0 if id_plateforme == 1031 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1031 & surveyround ==3

replace take_up = 0 if id_plateforme == 1074 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1074 & surveyround ==3

replace take_up = 0 if id_plateforme == 1004 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1004 & surveyround ==3 

replace take_up = 0 if id_plateforme == 1098 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1098 & surveyround ==3

replace take_up = 0 if id_plateforme == 1155 & surveyround ==3
replace desistement_consortium = 1 if id_plateforme == 1155 & surveyround ==3

}

***********************************************************************
* 	PART 2:  survey attrition (refusal to respond to survey)	
***********************************************************************
{
gen refus = 0 // zero for baseline as randomization only among respondents
lab var refus "Comapnies who refused to answer the survey" 

		* midline
replace refus = 1 if id_plateforme == 994 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1014 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1132 & surveyround == 2 // refusé de répondre et ne souhaitent ne plus être contactées
replace refus = 1 if id_plateforme == 1094 & surveyround == 2 // refusé de répondre et ne souhaitent ne plus être contactées
replace refus = 1 if id_plateforme == 1025 & surveyround == 2 // refusé de répondre et ne souhaitent ne plus être contactées
replace refus = 1 if id_plateforme == 1061 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1079 & surveyround == 2 // refus de répondre (baseline & midline) 
replace refus = 1 if id_plateforme == 1247 & surveyround == 2 // Demande de Eya de ne plus les contacter
replace refus = 1 if id_plateforme == 998  & surveyround == 2 // Demande de Eya de ne plus les contacter
replace refus = 1 if id_plateforme == 1067 & surveyround == 2 //Demande d'enlever tous ses informations de la base de contact
replace refus = 1 if id_plateforme == 1136 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1026 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1089 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1109 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1144 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1169 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1172 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1194 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1234 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1237 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1056 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1074 & surveyround == 2 //refus de répondre
replace refus = 1 if id_plateforme == 1110 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1137 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1158 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1162 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1166 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1202 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1235 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1245 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1112 & surveyround == 2 //Refus de répondre 


replace refus = 0 if id_plateforme == 1193 & surveyround == 2 //Refus de répondre aux informations comptables (survey not completed)
replace refus = 0 if id_plateforme == 1040 & surveyround == 2 //Refus de répondre aux informations comptables & employés (survey not completed)
replace refus = 0 if id_plateforme == 1057 & surveyround == 2 //Refus de répondre aux informations comptables & employés
replace refus = 0 if id_plateforme == 1219 & surveyround == 2 //Refus de répondre aux informations comptables & employés (survey not completed)
replace refus = 0 if id_plateforme == 1071 & surveyround == 2 //Refus de répondre aux corions comptables
replace refus = 0 if id_plateforme == 1022 & surveyround == 2 //Refus de répondre aux informations comptables & employés
replace refus = 0 if id_plateforme == 1015 & surveyround == 2 //Refus de répondre aux informations comptables & employés
replace refus = 0 if id_plateforme == 1068 & surveyround == 2 //Refus de répondre aux informations comptables
replace refus = 1 if id_plateforme == 1168 & surveyround == 2 // Refus de répondre aux informations comptables

		* endline
local id  994 995 997 998 1004 1008 1014  1025 1033 1042 1045 1056 1067 1074 1079 1089 1090 1093 1094 1109 1110 1123 1124  1136 1137  1146  1155 1158 1161 1162 1163 1165 1166 1172 1175 1188 1194 1199 1201 1202 1204 1214 1219 1223 1233 1235 1237 1241 1242 
foreach var of local id {
	replace refus = 1 if surveyround == 3 & id_plateforme == `var'
}
}

***********************************************************************
* 	PART 3:  entreprise no longer in operations	
***********************************************************************
{		
gen closed = . 
replace closed = 0 if refus == 0
lab var closed "Companies that are no longer operating"
replace closed = 1 if id_plateforme == 989 /*entreprise n'est plus en activité depuis 2022*/
replace closed = 1 if id_plateforme == 1083 /*lentreprise  ferme depuis 2 ans donc elle na pas donne le chiffres dafffaire et le matricule fiscale: Entreprise inexistante, elle n'a meme pas demaré. La CEO ne veut plus q'on l'appelle , elle m'a dit que c'est un harcelement. */
replace closed = 1 if id_plateforme == 1127 /*l'entreprise est fermée fin 2022 : pas d'activité en 2023 et 2024*/
replace closed = 1 if id_plateforme == 1154 /*L'entreprise est fermée depuis 2 ans*/

* replace company-level outcomes with zero if company has ceased operations, but not indivudal level outcomes
	* only replace if missing value
local el_variables inno_proc_met inno_proc_log inno_proc_prix inno_proc_sup inno_proc_autres entreprise_model ///
exp_pays exp_pays_ssa clients clients_ssa clients_ssa_commandes exp_pra_rexp exp_pra_foire exp_pra_sci exprep_norme exp_pra_vent ssa_action1 ssa_action2 ssa_action3 ssa_action4 expp_cost expp_ben ///
 employes car_empl1 car_empl2 /// 
 man_fin_per_ind man_fin_per_pro man_fin_per_qua man_fin_per_sto man_fin_per_emp man_fin_per_liv man_fin_per_fre man_fin_pra_bud man_fin_pra_pro man_fin_pra_dis man_ind_awa ///
 ca ca_exp comp_ca2023_intervalles ca_2024 ca_exp_2024 comp_ca2024_intervalles ///
 profit_2023_category profit_2024_category profit profit_2024 profit_2023_category_perte profit_2023_category_gain profit_2024_category_perte profit_2024_category_gain ///
 inno_improve inno_new inno_both export_1 ///
 export_2 export_41 export_42 export_43 export_44 export_45 refus_1 refus_2 refus_3 refus_4 refus_5

foreach var of local el_variables {
    replace `var' = 0 if surveyround == 3 & closed == 1 & `var' == .
}


	* put not exported = 0 (if no response) 
replace export_3 = 1 if surveyround == 3 & export_3 == . & closed == 1
replace export_2 = 0 if surveyround == 3 & export_2 == . & closed == 1
replace export_1 = 0 if surveyround == 3 & export_1 == . & closed == 1


*replace export_3 = 1 if surveyround == 3 & id_plateforme == 989	 // stopped operating
*replace export_3 = . if surveyround == 3 & id_plateforme == 998	 // did not respond
*replace export_3 = . if surveyround == 3 & id_plateforme == 1119 // verified based on el database

* individual level outcomes --> do not include
// netcoop1 netcoop2 netcoop3 netcoop4 netcoop5 netcoop6 netcoop7 netcoop8 netcoop9 netcoop10 net_coop_pos net_coop_neg net_association net_size3 net_size4 net_gender3 net_gender4 net_gender3_giz net_services_pratiques net_services_produits net_services_mark net_services_sup net_services_contract net_services_confiance net_services_autre car_efi_fin1 car_efi_man
// car_efi_motiv car_loc_env car_loc_exp car_loc_soin listexp
// int_contact attest  
//  inno_none inno_mot_cons inno_mot_cont inno_mot_eve inno_mot_client inno_mot_dummyother inno_mot_total  

}



***********************************************************************
* 	PART 4:   Create domestic sales + costs + positive profit  
***********************************************************************
{
* Domestic sales
	* for survey years
gen ca_tun = .
	replace ca_tun = ca - ca_exp if ca_exp != . & ca != .
*	replace ca_tun = ca if ca_exp == 0 & ca != .
*	replace ca_tun = ca_exp if ca == 0 & ca_exp != .
	

lab var ca_tun "Domestic sales"
	* first 6 months in 2024
gen ca_tun_2024 = .
	replace ca_tun_2024 = ca_2024 - ca_exp_2024 if ca_exp_2024 != . & ca_2024 != .
*	replace ca_tun_2024 = ca_2024 if ca_exp_2024 == . & ca_2024 != .
*	replace ca_tun_2024 = ca_exp_2024 if ca_2024 == . & ca_exp_2024 != .

lab var ca_tun_2024 "Domestic sales 2024"


	* pre-treatment periods
forvalues year=2018(1)2020 {
		gen ca_tun_`year' = ca_`year' - ca_exp`year' if ca_exp`year' != . & ca_`year' != . 
}

format %25.0fc ca_tun ca_tun_2024 ca ca_2024 ca_exp ca_exp_2024 profit profit_2024 ca_tun_2018 ca_tun_2019 ca_tun_2020

	
* Profitable dummy
gen profit_pos = (profit > 0)
	* replace all MVs
replace profit_pos = . if profit == .
	* replace for endline with binary response
replace profit_pos = profit_2023_category if surveyround == 3 & profit_pos == .
lab var profit_pos "Profit > 0"

	*profit2024 positive = profit_2024_category
	
* Costs (winsorised costs in Part 11 Winsorisation)
gen costs = ca - profit
lab var costs "Costs"

}

***********************************************************************
* 	PART 4:   Replace 2024 variables with their baseline value (otherwise no Y0 in regresssion)  
***********************************************************************
local vars "ca_2024 ca_exp_2024 profit_2024 ca_tun_2024"
local basevars "ca ca_exp profit ca_tun"
foreach v of local vars {
	gettoken basevar basevars : basevars
	replace `v' = `basevar' if surveyround == 1
}


***********************************************************************
*	PART 5: Export - dummies
***********************************************************************
{
* Exported
replace exported = (ca_exp > 0)
replace exported = . if ca_exp == .
lab var exported "Export sales > 0"

* Exported to SSA
gen exported_ssa = (exp_pays_ssa > 0)
replace exported_ssa = . if exp_pays_ssa == .
lab var exported_ssa "Exported to SSA"

* Share of SSA in total export countries
gen exp_ssa_ratio = exp_pays_ssa / exp_pays
lab var exp_ssa_ratio "% SSA over total export countries"

* Invested in export (only midline, not endline)
gen exp_invested = (exp_inv > 0)
replace exp_invested = . if exp_inv == .
lab var exp_invested "Export investment > 0"

}



***********************************************************************
*	PART 6: Innovation
***********************************************************************	
{
* Product innovations
	* number of innovations
		* no corion
egen innovations_prod = rowtotal(inno_produit inno_improve inno_new), missing
		* corions
egen innovations_prod_cor = rowtotal(inno_produit inno_improve_cor inno_new_cor), missing

	* innovated binary
		* no corions
bys id_plateforme (surveyround): gen innovated_prod = (innovations_prod > 0)
	replace innovated_prod = . if innovations_prod == .
		* corions
bys id_plateforme (surveyround): gen innovated_prod_cor = (innovations_prod_cor > 0)
	replace innovated_prod_cor = . if innovations_prod_cor == .
	
* proc innovations
	* number of innovations
		* no correction
egen innovations_proc = rowtotal(inno_commerce inno_lieu inno_process inno_proc_met inno_proc_sup inno_proc_log inno_proc_prix), missing
		* correction
egen innovations_proc_cor = rowtotal(inno_commerce inno_lieu inno_process inno_proc_met_cor inno_proc_sup_cor inno_proc_log_cor inno_proc_prix_cor), missing

	* innovated binary
		* no correction
bys id_plateforme (surveyround): gen innovated_proc = (innovations_proc > 0)
	replace innovated_proc = . if innovations_proc == .
		* correction
bys id_plateforme (surveyround): gen innovated_proc_cor = (innovations_proc_cor > 0)
	replace innovated_proc_cor = . if innovations_proc_cor == .
	
	
*br id_plateforme surveyround innovations innovated
lab var innovations_prod "Total innovations process"
lab var innovated_prod "Innovated process"
lab var innovations_proc "Total innovations process"
lab var innovated_proc "Innovated process"

lab var innovations_prod_cor "Total innovations product cored"
lab var innovated_prod_cor "Innovated product cored"
lab var innovations_proc_cor "Total innovations product cored"
lab var innovated_proc_cor "Innovated product cored"

}

***********************************************************************
*	PART 7: network size
***********************************************************************	
{
	* create total network size
gen net_size =.
		* combination of female and male CEOs at midline
replace net_size = net_nb_f + net_nb_m if surveyround ==2
		* combination of within family and outside family at baseline
replace net_size = net_nb_fam + net_nb_dehors if surveyround ==1

		* combination of CEOs & family/friends at endline
replace net_size = net_size3 + net_size4 if surveyround == 3

lab var net_size "Network size"

	* has female entrepreneur contact
gen net_female_entr = (net_gender3 > 0)
replace net_female_entr = . if net_gender3 == .
lab var net_female_entr "Discussed business with female entrepreneur"

gen net_female_friend = (net_gender4 > 0)
replace net_female_friend = . if net_gender4 == .
lab var net_female_friend "Discussed business with female friend"

}


***********************************************************************
* 	PART 8:   Create the indices based on a z-score			  
***********************************************************************
{
	*Definition of all variables that are being used in index calculation
local management "man_fin_per_fre car_loc_exp man_hr_obj man_hr_feed man_pro_ano man_fin_enr man_fin_profit man_fin_per man_mark_prix man_mark_div man_mark_clients man_mark_offre man_mark_pub man_hr_pro man_fin_num man_fin_per_qua man_fin_per_emp man_fin_per_liv man_fin_pra_bud man_fin_pra_pro man_fin_pra_dis man_ind_awa man_fin_per_ind man_fin_per_pro man_fin_per_sto"

local export "exported export_1 export_2 exp_pra_foire exp_pra_sci exp_pra_rexp exp_pra_cible exp_pra_mission exp_pra_douane exp_pra_plan exprep_norme exp_inv exprep_couts exp_pays exp_afrique exp_pra_vent"

local confidence "car_efi_fin1 car_efi_nego car_efi_conv car_init_prob car_init_init car_init_opp car_loc_succ car_loc_env car_loc_insp car_efi_man car_efi_motiv car_loc_soin"

local exp_ssa "ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5 exp_pays_ssa clients_ssa clients_ssa_commandes"

local kpis "employes profit ca ca_exp ca_tun ca_2024 ca_exp_2024 profit_2024"

local networks "net_association net_size3 net_gender3_giz net_services_pratiques net_services_produits net_services_mark net_services_sup net_services_contract net_services_confiance net_services_autre net_coop_pos net_coop_neg"

local innovation "inno_produit inno_improve inno_new inno_improve_cor inno_new_cor inno_commerce inno_lieu inno_process inno_proc_met inno_proc_sup inno_proc_log inno_proc_prix inno_proc_met_cor inno_proc_sup_cor inno_proc_log_cor inno_proc_prix_cor innovations_prod innovations_prod_cor innovations_proc innovations_proc_cor  innovated_proc innovated_proc_cor"	

local allvars `management' `export' `confidence' `exp_ssa' `kpis' `networks' `innovation'             
ds `allvars', has(type string)

	* Create torary variable
foreach var of local allvars {
	g t_`var' = `var'
    replace t_`var' = . if `var' == 999 // don't know transformed to missing values
    replace t_`var' = . if `var' == 888 
    replace t_`var' = . if `var' == 777 
    replace t_`var' = . if `var' == 666 
	replace t_`var' = . if `var' == -999 // added - since we transformed profit into negative in endline
    replace t_`var' = . if `var' == -888
    replace t_`var' = . if `var' == -777
    replace t_`var' = . if `var' == -666
    replace t_`var' = . if `var' == 1234 
}

	* calculate z-score for each individual outcome
		* write a program calculates the z-score
			* if you re-run the code, execture before: 
capture program drop zscore
program define zscore /* opens a program called zscore */
	sum `1' if treatment == 0 & surveyround == `2'
	gen `1'z`2' = (`1' - r(mean))/r(sd) /* new variable gen is called --> varnamez */
end


		* create empty variable that will be replaced with z-scores
foreach var of local allvars {
	g t_`var'z = .
	
}
		* calculate z-score surveyround & variable specific
levelsof surveyround, local(survey)
foreach s of local survey {
			* calcuate the z-score for each variable
	foreach var of local allvars {
		zscore t_`var' `s'
		replace t_`var'z = t_`var'z`s' if surveyround == `s'
		drop t_`var'z`s'
	}
}


	* calculate the index value: average of zscores 
			* networking
egen network = rowmean(t_net_associationz t_net_size3z t_net_gender3_gizz t_net_services_pratiquesz t_net_services_produitsz t_net_services_markz t_net_services_supz t_net_services_contractz t_net_services_confiancez t_net_services_autrez t_net_coop_posz t_net_coop_negz)

egen net_services_mean = rowmean(net_services_pratiques net_services_produits net_services_mark net_services_sup net_services_contract net_services_confiance)

egen net_services_total = rowtotal(net_services_pratiques net_services_produits net_services_mark net_services_sup net_services_contract net_services_confiance), missing

			* export readiness index (eri)
egen eri = rowtotal(t_exprep_normez t_exp_pra_ciblez t_exp_pra_missionz t_exp_pra_douanez t_exp_pra_planz t_exp_pra_rexpz t_exp_pra_foirez t_exp_pra_sciz t_exp_pra_ventz)			
			
			* export readiness SSA index (eri_ssa)
egen eri_ssa = rowmean(t_ssa_action1z t_ssa_action2z t_ssa_action3z t_ssa_action4z t_ssa_action5z t_exp_pays_ssaz t_clients_ssaz t_clients_ssa_commandesz) 

			* export performance
egen epi = rowmean(t_exportedz t_export_1z t_export_2z t_exp_paysz t_ca_expz)

			*Innovation product index
egen ii_prod = rowmean(t_inno_improvez t_inno_newz t_inno_produitz) 
egen ii_prod_cor = rowmean (t_inno_improve_corz t_inno_new_corz t_inno_produitz)	

			*Innovation process index
egen ii_proc = rowmean(t_inno_proc_metz t_inno_proc_logz t_inno_proc_prixz t_inno_proc_supz t_inno_processz t_inno_commercez t_inno_lieuz) 

egen ii_proc_cor = rowmean(t_inno_proc_met_corz t_inno_proc_log_corz t_inno_proc_prix_corz t_inno_proc_sup_corz t_inno_processz t_inno_commercez t_inno_lieuz)		
	
			* business performance
egen bpi = rowmean(t_employesz t_caz t_profitz)
egen bpi_2024 = rowmean(t_employesz t_ca_2024z t_profit_2024z)


			* management practices (mpi)
egen mpi = rowmean(t_man_hr_objz t_man_hr_feedz t_man_pro_anoz t_man_fin_enrz t_man_fin_profitz t_man_fin_perz t_man_hr_proz t_man_fin_numz t_man_fin_per_frez t_man_fin_pra_budz t_man_fin_pra_proz t_man_fin_pra_disz t_man_ind_awaz) // added at midline: man_ind_awa man_fin_per_fre instead of man_fin_per, man_hr_feed, man_hr_pro	

		
			* marketing practices index (marki)
egen marki = rowmean(t_man_mark_prixz t_man_mark_divz t_man_mark_clientsz t_man_mark_offrez t_man_mark_pubz)
egen mpmarki = rowmean(mpi marki)
			
			* female empowerment index (genderi)
				* locus of control "believe that one has control over outcome, as opposed to external forces"
				* efficacy "the ability to produce a desired or intended result."
				* sense of initiative
egen female_efficacy = rowmean(t_car_efi_fin1z t_car_efi_negoz t_car_efi_convz t_car_efi_manz t_car_efi_motivz)
egen female_initiative = rowmean(t_car_init_probz t_car_init_initz t_car_init_oppz)
egen female_loc = rowmean(t_car_loc_succz t_car_loc_envz t_car_loc_inspz t_car_loc_expz t_car_loc_soinz)

egen genderi = rowmean(t_car_efi_fin1z t_car_efi_negoz t_car_efi_convz t_car_efi_manz t_car_efi_motivz t_car_init_probz t_car_init_initz t_car_init_oppz t_car_loc_succz t_car_loc_envz t_car_loc_inspz t_car_loc_expz t_car_loc_soinz)

		* labeling
label var network "Network"
label var eri "Export readiness"
label var eri_ssa "Export readiness SSA"
*label var epp "Export performance"
label var mpi "Management practices"
label var marki "Marketing practices"
label var female_efficacy "Effifacy"
label var female_initiative "Initiaitve"
label var female_loc "Locus of control"
label var genderi "Entrepreneurial empowerment"
label var ii_prod "Product innovation index"
label var ii_prod_cor "Product innovation index corrected"
label var ii_proc "Process innovation index"
label var ii_proc_cor "Process innovation index corrected"
label var bpi "Business performance index"
label var bpi_2024 "Business performance index"

}

***********************************************************************
* 	PART 9:   Create the indices as total points		  
***********************************************************************
{
	* find out max. points
sum t_man_hr_obj t_man_hr_feed t_man_pro_ano t_man_fin_enr t_man_fin_profit t_man_fin_per t_man_hr_pro t_man_fin_num t_man_fin_per_ind t_man_fin_per_pro t_man_fin_per_qua t_man_fin_per_sto t_man_fin_per_emp t_man_fin_per_liv t_man_fin_per_fre t_man_fin_pra_bud t_man_fin_pra_pro t_man_fin_pra_dis t_man_ind_awa
sum t_man_mark_prix t_man_mark_div t_man_mark_clients t_man_mark_offre t_man_mark_pub
sum t_exprep_norme t_exp_pra_cible t_exp_pra_mission t_exp_pra_douane t_exp_pra_plan t_exp_pra_rexp t_exp_pra_foire t_exp_pra_sci t_exp_pra_vent
sum t_car_efi_fin1 t_car_efi_nego t_car_efi_conv t_car_efi_man t_car_efi_motiv t_car_init_prob t_car_init_init t_car_init_opp t_car_loc_succ t_car_loc_env t_car_loc_insp t_car_loc_env t_car_loc_exp t_car_loc_soin
sum t_exprep_norme t_exp_inv t_exprep_couts t_exp_pays t_exp_afrique

*sum t_inno_improve t_inno_new t_inno_proc_met t_inno_proc_log t_inno_proc_prix t_inno_proc_sup
*sum t_proc_prod_cor t_proc_mark_cor t_inno_org_cor t_inno_improve_cor t_inno_new_cor		
	
	* create total points per index dimension
			* export readiness index (eri) 
egen eri_points = rowtotal(exprep_norme exp_pra_cible exp_pra_mission exp_pra_douane exp_pra_plan exp_pra_rexp exp_pra_foire exp_pra_sci exp_pra_vent), missing			
			
			* export readiness SSA index (eri_ssa) 
egen eri_ssa_points = rowtotal(ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5), missing

			* management practices (mpi)  
egen mpi_points = rowtotal(man_hr_obj man_hr_feed man_pro_ano man_fin_enr man_fin_profit man_fin_per t_man_hr_pro man_fin_num man_fin_per_ind man_fin_per_pro man_fin_per_qua man_fin_per_sto man_fin_per_emp man_fin_per_liv man_fin_per_fre man_fin_pra_bud man_fin_pra_pro man_fin_pra_dis man_ind_awa), missing

* calculate "adoption rate" for better comparison to Bloom et al. 2013, 2020
gen mpi_rate = .
	replace mpi_rate = mpi_points/8 if surveyround == 1
	replace mpi_rate = mpi_points/5 if surveyround == 2
	replace mpi_rate = mpi_points/12 if surveyround == 3
			
			* marketing practices index (marki) 
egen marki_points = rowtotal(man_mark_prix man_mark_div man_mark_clients man_mark_offre man_mark_pub), missing
			
			*Innovation index
/*
egen inno_points = rowtotal(inno_improve inno_new inno_proc_met inno_proc_log inno_proc_prix inno_proc_sup inno_proc_autres), missing 
egen cor_inno_points = rowtotal (proc_prod_cor proc_mark_cor inno_org_cor inno_improve_cor inno_new_cor)
*/			
			* female empowerment index (genderi)
				* locus of control "believe that one has control over outcome, as opposed to external forces"
				* efficacy "the ability to produce a desired or intended result."
				* sense of initiative
egen female_efficacy_points = rowtotal(car_efi_fin1 car_efi_nego car_efi_conv car_efi_man car_efi_motiv), missing
egen female_initiative_points = rowtotal(car_init_prob car_init_init car_init_opp), missing
egen female_loc_points = rowtotal(car_loc_succ car_loc_env car_loc_insp car_loc_exp car_loc_soin), missing

egen genderi_points = rowtotal(car_efi_fin1 car_efi_nego car_efi_conv car_efi_man car_efi_motiv car_init_prob car_init_init car_init_opp car_loc_succ car_loc_env car_loc_insp car_loc_env car_loc_exp car_loc_soin), missing


* create averages for self-effifacy & locus of control (not pre-specified, but to compare effect size with Alibhai et al. 2019)
egen female_efficacy_mean = rowmean(car_efi_fin1 car_efi_nego car_efi_conv car_efi_man car_efi_motiv) // ignores missing values
egen female_loc_mean = rowmean(car_loc_succ car_loc_env car_loc_insp car_loc_env car_loc_exp car_loc_soin)

		* labeling
label var eri_points "Export readiness index points"
label var eri_ssa_points "Export readiness SSA index points"
label var mpi_points "Management practices index points"
label var marki_points "Marketing practices index points"
lab var female_efficacy_points "Entrepreneurial ability (points)"
lab var female_loc_points "Entrepreneurial control (points)"
label var genderi_points "Gender index points"

*label var inno_points "Innovation practices index points"
*label var cor_inno_points "cored innovation practices index points"

	* drop torary vars		  										  
drop t_*

}

***********************************************************************
*	PART 10: Continuous outcomes (winsorization + ihs-transformation)
***********************************************************************
{
	* log-transform capital invested
foreach var of varlist capital ca employes {
	gen l`var' = log(`var')	
	replace l`var' = . if `var' == .
}
	
	* quantile transform profits --> see Delius and Sterck 2020 : https://oliviersterck.files.wordpress.com/2020/12/ds_cash_transfers_microenterprises.pdf
gen profit_pct = .
	egen profit_pct1 = rank(profit) if surveyround == 1	& !inlist(profit, -777, -888, -999, .)	// use egen rank to get the rank of each value in the distribution of profits
	sum profit if surveyround == 1 & !inlist(profit, -777, -888, -999, .)
	replace profit_pct = profit_pct1/(`r(N)' + 1) if surveyround == 1			// divide by N + 1 to get a percentile for each observation
	
	egen profit_pct2 = rank(profit) if surveyround == 2 & !inlist(profit, -777, -888, -999, .)
	sum profit if surveyround == 2 & !inlist(profit, -777, -888, -999, .)
	replace profit_pct = profit_pct2/(`r(N)' + 1) if surveyround == 2

	egen profit_pct3 = rank(profit) if surveyround == 3 & !inlist(profit, -777, -888, -999, 999, 888, 777, 1234, .)
	sum profit if surveyround == 3 & !inlist(profit, -777, -888, -999, .)
	replace profit_pct = profit_pct3/(`r(N)' + 1) if surveyround == 3


	*egen profit_pct4 = rank(comp_benefice2024) if surveyround == 3 & !inlist(comp_benefice2024, -777, -888, -999, 1234, .)
	*sum profit if surveyround == 3 & !inlist(profit, -777, -888, -999, .)
	*replace profit_pct = profit_pct2/(`r(N)' + 1) if surveyround == 3
	
	drop profit_pct1 profit_pct2 profit_pct3
	
	* winsorize
		* winsorize all outcomes (but profit)
local wins_vars "capital ca ca_exp ca_tun exp_inv employes car_empl1 car_empl2 inno_rd net_size net_nb_f net_nb_m net_nb_dehors net_nb_fam ca_2024 net_size3 net_size4 net_gender3 net_size3_m net_size4_m net_gender4 net_gender3_giz ca_exp_2024 exp_pays exp_pays_ssa  clients clients_ssa clients_ssa_commandes prni pr2024ni cani ca2024ni ca_2018 ca_2019 ca_2020 ca_tun_2018 ca_tun_2019 ca_tun_2020 ca_exp2018 ca_exp2019 ca_exp2020"

foreach var of local wins_vars {
		gen `var'_w99 = `var'
		gen `var'_w95 = `var'
}

forvalues s = 1(1)3 {
	foreach var of local wins_vars {
		replace `var' = . if `var' == 999  // don't know transformed to missing values
		replace `var' = . if `var' == 888 
		replace `var' = . if `var' == 777 
		replace `var' = . if `var' == 666 
		replace `var' = . if `var' == -999 // added - since we transformed profit into negative in endline
		replace `var' = . if `var' == -888 
		replace `var' = . if `var' == -777 
		replace `var' = . if `var' == -666 
		replace `var' = . if `var' == 1234
		
	quietly tab `var' if surveyround == `s'
	if (`r(N)' > 0) {	
		sum `var' if surveyround == `s', d
		replace `var'_w99 = `r(p99)' if `var' > `r(p99)' & surveyround ==  `s' & `var' != .
		*winsor `var' if surveyround == `s', suffix(_`s'w99) cuts(0 99)  // winsorize
		*replace `var'_w99 = `var'_`s'w99 if surveyround ==  `s'
		
		sum `var' if surveyround == `s', d
		replace `var'_w95 = `r(p95)' if `var' > `r(p95)' & surveyround ==  `s' & `var' != .
		*winsor `var' if surveyround == `s', suffix(_`s'w95) cuts(0 95)  // winsorize
		*replace `var'_w95 = `var'_`s'w95 if surveyround ==  `s'
				}
			}
		}

gen profit_w99 = .
gen profit_w95 = .

		* profit
forvalues s = 1(1)3 {
	winsor2 profit if surveyround == `s', suffix(_`s'w99) cuts(1 99) // winsorize also at lowest percentile to reduce influence of negative outliers
	replace profit_w99 = profit_`s'w99 if surveyround == `s'
	
	winsor2 profit if surveyround == `s', suffix(_`s'w95) cuts(5 95) // winsorize also at lowest percentile to reduce influence of negative outliers
	replace profit_w95 = profit_`s'w95 if surveyround == `s'
}
	winsor2 profit_2024, suffix(_w99) cuts(1 99) // winsorize also at lowest percentile to reduce influence of negative outliers
	winsor2 profit_2024, suffix(_w95) cuts(5 95) // winsorize also at lowest percentile to reduce influence of negative outliers

************ generate winsorised costs & domestic sales ************
* 
gen lca_w95 = log(ca_w95)

* costs
gen costs_w99 = ca_w99 - profit_w99
lab var costs_w99 "Costs wins. 99th"

gen costs_w95 = ca_w95 - profit_w95
lab var costs_w95 "Costs wins. 95th"

* costs_2024
gen costs_2024_w99 = ca_2024_w99 - profit_2024_w99
lab var costs_2024_w99 "Costs 2024 wins. 99th"

gen costs_2024_w95 = ca_2024_w95 - profit_2024_w95
lab var costs_2024_w95 "Costs 2024 wins. 95th"

* domestic sales
gen ca_tun_2024_w99 = ca_2024_w99 - ca_exp_2024_w99
lab var ca_tun_2024_w99 "Domestic sales 2024 wins. 99th"

gen ca_tun_2024_w95 = ca_2024_w95 - ca_exp_2024_w95
lab var ca_tun_2024_w95 "Domestic sales 2024 wins. 95th"

************ label winsorised variables used for regressions ************
lab var exp_pays_w95 "N. of Export countries"
lab var exp_pays_w99 "N. of Export countries"

lab var clients_w99 "N. of Clients abroad"
lab var clients_w95 "N. of Cliebts abroad"

lab var clients_ssa_w99 "N. of Clients SSA"
lab var clients_ssa_w95 "N. of Cliebts SSA"

************************************************************

	* find optimal k before ihs-transformation
		* see Aihounton & Henningsen 2021 for methodological approach

		* put all ihs-transformed outcomes in a list
local ys "employes_w99 car_empl1_w99 car_empl2_w99 ca_tun_w99 ca_exp_w99 ca_w99 profit_w99 costs_w99 ca_tun_2024_w99 ca_exp_2024_w99 ca_2024_w99 profit_2024_w99 costs_2024_w99 employes_w95 car_empl1_w95 car_empl2_w95 ca_tun_w95 ca_exp_w95 ca_w95 profit_w95 costs_w95 ca_tun_2024_w95 ca_exp_2024_w95 ca_2024_w95 profit_2024_w95 costs_2024_w95 exp_inv_w99 exp_inv_w95 prni_w99 pr2024ni_w99 cani_w99 ca2024ni_w99 prni_w95 pr2024ni_w95 cani_w95 ca2024ni_w95 ca_2018_w95 ca_2019_w95 ca_2020_w95 ca_exp2018_w95 ca_exp2019_w95 ca_exp2020_w95 ca_tun_2018_w95 ca_tun_2019_w95 ca_tun_2020_w95"
     
		* check how many zeros
foreach var of local ys {
		sum `var' if surveyround == 2 & !inlist(`var', -777, -888, -999,.)
		local N = `r(N)'
		sum `var' if `var' == 0 & surveyround == 2
		local zeros = `r(N)'
		scalar perc = `zeros'/`N'
		if perc > 0.05 {
			display "`var' has `zeros' zeros out of `N' non-missing observations ("perc "%)."
			}
	scalar drop perc
}

		* generate re-scaled outcome variables
foreach var of local ys {
				* k = 1, 10^3-10^6
	if !inlist(`var', employes_w99, car_empl1_w99, car_empl2_w99) {
		gen `var'_k1   = `var'
		forvalues k = 3(1)6 {
			local i = `k' - 1
			gen `var'_k`i' = `var' / 10^`k' if !inlist(`var', ., -777, -888, -999)
			lab var `var'_k`i' "`var' wins., scaled by 10^`k'" 
			}
	}
				* k = 1, 10^1-10^3
	else {
		gen `var'_k1   = `var'
		forvalues k = 1(1)3 {
			local i = 1 +`k'
			gen `var'_k`i' = `var' / 10^`k' if !inlist(`var', ., -777, -888, -999)
			lab var `var'_k`i' "`var' wins., scaled by 10^`k'" 
			}
		}
	}

		* ihs-transform all rescaled numerical variables
foreach var of local ys {
		ihstrans `var'_k?, prefix(ihs_) 
}

/*		* visualize distribution of ihs-transformed, rescaled variables
foreach var of local ys {
	if !inlist(`var', employes_w99, car_empl1_w99, car_empl2_w99) {
		local powers "1 10^3 10^4 10^5 10^6"
		forvalues i = 1(1)5 {
			gettoken power powers : powers
				if `var' == profit_w99 {
				histogram ihs_`var'_k`i', start(-16) width(1)  ///
					name(`var'`i', replace) ///
					title("IHS-Tranformed `var': K = `power'")
					}
				else {
				histogram ihs_`var'_k`i', start(0) width(1)  ///
					name(`var'`i', replace) ///
					title("IHS-Tranformed `var': K = `power'")
					}					
				}
	gr combine `var'1 `var'2 `var'3 `var'4 `var'5, row(2)
	gr export "${master_figures}/scale_`var'.png", replace
				}
	else {
		local powers "1 10^1 10^2 10^3"
		forvalues i = 1(1)4 {
			gettoken power powers : powers
			histogram ihs_`var'_k`i', start(0) width(1)  ///
				name(`var'`i', replace) ///
				title("IHS-Tranformed `var': K = `power'")
				}
	gr combine `var'1 `var'2 `var'3 `var'4, row(2)
	gr export "${master_figures}/scale_`var'.png", replace
	}
}
*/		
		* generate Y0 + missing baseline to be able to run final regression
			* at midline use only for mht
foreach var of local ys {
			* generate YO
	bys id_plateforme (surveyround): gen `var'_first = `var'[_n == 1]					// filter out baseline value
	egen `var'_y0 = min(`var'_first), by(id_plateforme)								// create variable = bl value for all three surveyrounds by id
	replace `var'_y0 = 0 if inlist(`var'_y0, ., -777, -888, -999)		// replace this variable = zero if missing
	drop `var'_first														// clean up
	lab var `var'_y0 "Y0 `var'"
	
		* generate missing baseline dummy
	gen miss_bl_`var' = 0 if surveyround == 1											// gen dummy for baseline
	replace miss_bl_`var' = 1 if surveyround == 1 & inlist(`var',., -777, -888, -999)	// replace dummy 1 if variable missing at bl
	egen missing_bl_`var' = min(miss_bl_`var'), by(id_plateforme)									// expand dummy to ml, el
	lab var missing_bl_`var' "YO missing, `var'"
	drop miss_bl_`var'
}

		* run final regression & collect r-square in Excel file
				* create excel document
putexcel set "${master_figures}/scale_k.xlsx", replace

				* define table title
putexcel A1 = "Selection of optimal K", bold border(bottom) left
	
				* create top border for variable names
putexcel A2:H2 = "", border(top)
	
				* define column headings
putexcel A2 = "", border(bottom) hcenter
putexcel B2 = "Employees", border(bottom) hcenter
putexcel C2 = "Female employees", border(bottom) hcenter
putexcel D2 = "Young employees", border(bottom) hcenter
putexcel E2 = "Domestic sales", border(bottom) hcenter
putexcel F2 = "Export sales", border(bottom) hcenter
putexcel G2 = "Total sales", border(bottom) hcenter
putexcel H2 = "Profit", border(bottom) hcenter
putexcel I2 = "Costs", border(bottom) hcenter

	
				* define rows
putexcel A3 = "k = 1", border(bottom) hcenter
putexcel A4 = "k = 10^2", border(bottom) hcenter
putexcel A5 = "k = 10^3", border(bottom) hcenter
putexcel A6 = "k = 10^4", border(bottom) hcenter
putexcel A7 = "k = 10^5", border(bottom) hcenter
putexcel A7 = "k = 10^6", border(bottom) hcenter

				* run the main specification regression looping over all values of k
xtset id_plateforme surveyround, delta(1)
local columns "B C D"
foreach var of varlist employes_w99 car_empl1_w99 car_empl2_w99 {
	local row = 3
	gettoken column columns : columns
	forvalues i = 1(1)4 {
		reg ihs_`var'_k`i' i.treatment l.`var' i.missing_bl_`var' i.strata_final, cluster(id_plateforme)
		local r2 = e(r2)
		putexcel `column'`row' = `r2', hcenter nformat(0.000)  // `++row'
			local row = `row' + 1
	}
}

local columns "E F G H I"
foreach var of varlist ca_tun_w99 ca_exp_w99 ca_w99 profit_w99 costs_w99 {
	local row = 3
	gettoken column columns : columns
	forvalues i = 1(1)5 {
			reg ihs_`var'_k`i' i.treatment l.`var' i.missing_bl_`var' i.strata_final, cluster(id_plateforme)
			local r2 = e(r2)
			putexcel `column'`row' = `r2', hcenter nformat(0.000)  // `++row'
			local row = `row' + 1
	}
}



		* drop all the created variables
drop missing_bl_* // *_k?
drop *_y0

		* label optimal k variables & k = 1 for consistency checks
*lab var ihs_exp_inv_w99_k1 "Export investment"
*lab var ihs_exp_inv_w99_k4 "Export investment"
lab var ihs_ca_exp_w99_k1 "Export sales"
lab var ihs_ca_exp_w99_k4 "Export sales"
lab var ihs_ca_tun_w99_k1  "Domestic sales"
lab var ihs_ca_tun_w99_k4  "Domestic sales" 
lab var ihs_ca_w99_k1 "Total sales" 
lab var ihs_ca_w99_k4 "Total sales" 
lab var ihs_profit_w99_k1 "Profit" 
lab var ihs_profit_w99_k2 "Profit"
lab var ihs_profit_w99_k3 "Profit" 
lab var ihs_profit_w99_k4 "Profit"
lab var profit_pct "Profit"
lab var ihs_employes_w99_k1 "Employees"
lab var car_empl1_w99_k1 "Female employees"
lab var car_empl2_w99_k1 "Young employees"
lab var ihs_employes_w99_k3 "Employees" 
lab var car_empl1_w99_k3 "Female employees"
lab var net_size3_w99 "Network all contacts, Winsorized 99th Percentile"
lab var net_size3_m_w99 "Network male contacts, Winsorized 99th Percentile"
lab var net_gender3_w99 "Network female contacts, Winsorized 99th Percentile"
lab var net_size4_w99 "Network all contacts, Winsorized 99th Percentile"
lab var net_size4_m_w99 "Network male contacts, Winsorized 99th Percentile"
lab var net_gender4_w99 "Network female contacts, Winsorized 99th Percentile"

lab var net_size3_w95 "Network all contacts, Winsorized 95th Percentile"
lab var net_size3_m_w95 "Network male contacts, Winsorized 95th Percentile"
lab var net_gender3_w95 "Network female contacts, Winsorized 95th Percentile"
lab var net_size4_w95 "Network all contacts, Winsorized 95th Percentile"
lab var net_size4_m_w95 "Network male contacts, Winsorized 95th Percentile"
lab var net_gender4_w95 "Network female contacts, Winsorized 95th Percentile"

gen net_pratiques = net_services_pratiques 
gen net_produits = net_services_produits
gen net_mark = net_services_mark
gen net_sup = net_services_sup
gen net_contract = net_services_contract
gen net_confiance = net_services_confiance
gen net_autre = net_services_autre

}



***********************************************************************
* 	PART 11:   generate survey-to-survey growth rates
***********************************************************************
{
	* accounting variables
local acccounting_vars "ca ca_exp ca_tun profit employes car_empl1 car_empl2"
foreach var of local acccounting_vars {
	bys id_plateforme (surveyround): g `var'_rel_growth = (`var' - `var'[1])/`var'[1]
	bys id_plateforme (surveyround): g `var'_abs_growth = `var' - `var'[1]

}

	* winsorize growth rates
local wins_vars "ca_rel_growth profit_rel_growth ca_abs_growth profit_abs_growth"
foreach var of local wins_vars {
		gen `var'_w99 = `var'
		gen `var'_w95 = `var'
}
forvalues s = 1(1)3 {
	foreach var of local wins_vars {	
	quietly tab `var' if surveyround == `s'
	if (`r(N)' > 0) {	
		sum `var' if surveyround == `s', d
		replace `var'_w99 = `r(p99)' if `var' > `r(p99)' & surveyround ==  `s' & `var' != .
		replace `var'_w99 = `r(p1)' if `var' < `r(p1)' & surveyround ==  `s' & `var' != .

		*winsor `var' if surveyround == `s', suffix(_`s'w99) cuts(0 99)  // winsorize
		*replace `var'_w99 = `var'_`s'w99 if surveyround ==  `s'
		
		sum `var' if surveyround == `s', d
		replace `var'_w95 = `r(p95)' if `var' > `r(p95)' & surveyround ==  `s' & `var' != .
		replace `var'_w95 = `r(p5)' if `var' < `r(p5)' & surveyround ==  `s' & `var' != .

		*winsor `var' if surveyround == `s', suffix(_`s'w95) cuts(0 95)  // winsorize
		*replace `var'_w95 = `var'_`s'w95 if surveyround ==  `s'
				}
			}
		}


/*
use links to understand the code syntax for creating the accounting variables' growth rates:
-https://www.statalist.org/forums/forum/general-stata-discussion/general/1474123-changing-the-base-year-and-creating-an-index-from-that-year-in-a-time-series
- https://www.stata.com/statalist/archive/2008-10/msg00661.html
- https://www.stata.com/support/faqs/statistics/time-series-operators/

*/
}

***********************************************************************
*	PART 12: network composition: ratios
***********************************************************************	
{
	* gender ratio for entrepreneur contacts
gen net_gender3_ratio = net_gender3_w95/net_size3_m_w95
gen net_female3_share = net_gender3_w95/net_size3_w95

	* Ratio contacts via GIZ out of total female entrepreneurs
		* first replace GIZ 0 for control group
replace net_gender3_giz = 0 if treatment == 0
gen net_giz_ratio = net_gender3_giz/net_gender3_w95
lab var net_giz_ratio "% female entrepreneurs met via consortium"


}


***********************************************************************
* 	PART 13: (endline) generate YO + missing baseline dummies	
***********************************************************************
{
*rename long var

forvalues p = 95(4)99 { 
rename clients_ssa_commandes_w`p' orderssa_w`p'

rename ihs_ca_tun_2024_w`p'_k5 ihs_catun2024_w`p'_k5
rename ihs_ca_tun_2024_w`p'_k4 ihs_catun2024_w`p'_k4
rename ihs_ca_tun_2024_w`p'_k3 ihs_catun2024_w`p'_k3
rename ihs_ca_tun_2024_w`p'_k2 ihs_catun2024_w`p'_k2
rename ihs_ca_tun_2024_w`p'_k1 ihs_catun2024_w`p'_k1


rename ihs_ca_tun_w`p'_k5 ihs_catun_w`p'_k5
rename ihs_ca_tun_w`p'_k4 ihs_catun_w`p'_k4
rename ihs_ca_tun_w`p'_k3 ihs_catun_w`p'_k3
rename ihs_ca_tun_w`p'_k2 ihs_catun_w`p'_k2
rename ihs_ca_tun_w`p'_k1 ihs_catun_w`p'_k1



rename ihs_profit_2024_w`p'_k5 ihs_profit2024_w`p'_k5
rename ihs_profit_2024_w`p'_k4 ihs_profit2024_w`p'_k4
rename ihs_profit_2024_w`p'_k3 ihs_profit2024_w`p'_k3
rename ihs_profit_2024_w`p'_k2 ihs_profit2024_w`p'_k2
rename ihs_profit_2024_w`p'_k1 ihs_profit2024_w`p'_k1


rename ihs_ca_exp_2024_w`p'_k1 ihs_caexp2024_w`p'_k1
rename ihs_ca_exp_2024_w`p'_k2 ihs_caexp2024_w`p'_k2
rename ihs_ca_exp_2024_w`p'_k3 ihs_caexp2024_w`p'_k3
rename ihs_ca_exp_2024_w`p'_k4 ihs_caexp2024_w`p'_k4
rename ihs_ca_exp_2024_w`p'_k5 ihs_caexp2024_w`p'_k5
}

{
	* results for optimal k
		* k = 10^3 --> employees, female employees, young employees
		* k = 10^4 --> domestic sales, export sales, total sales, exp_inv
	* collect all ys in string
local network "network net_size net_size_w99 net_size_w95 net_nb_qualite net_coop_pos net_coop_neg net_nb_f_w99 net_nb_f_w95 net_nb_m_w99 net_nb_m_w95 net_nb_fam net_nb_dehors famille2 net_association net_size3 net_size3_m net_gender3 net_gender3_giz netcoop1 netcoop2 netcoop3 netcoop4 netcoop5 netcoop6 netcoop7 netcoop8 netcoop9 netcoop10 net_size3_w99 net_size3_m_w99 net_gender3_w99 net_size4_w99 net_size4_m_w99 net_gender4_w99 net_gender3_giz_w99 net_size3_w95 net_size3_m_w95 net_gender3_w95 net_size4_w95 net_size4_m_w95 net_gender4_w95 net_pratiques net_produits net_mark net_sup net_contract net_confiance net_autre net_gender3_ratio net_giz_ratio"

local empowerment "genderi female_efficacy female_loc female_efficacy_mean female_loc_mean listexp car_efi_fin1 car_efi_man car_efi_motiv car_loc_env car_loc_exp car_loc_soin"

local mp "mpi mpi_rate man_fin_per_ind man_fin_per_pro man_fin_per_qua man_fin_per_sto man_fin_per_emp man_fin_per_liv man_fin_per_fre man_fin_pra_bud man_fin_pra_pro man_fin_pra_dis man_source_cons man_source_pdg man_source_fam man_source_even man_source_autres man_fin_per"

local innovation " ii_proc ii_proc_cor ii_prod ii_prod_cor inno_improve inno_new inno_produit inno_improve_cor inno_new_cor inno_commerce inno_lieu inno_process inno_proc_met inno_proc_sup inno_proc_log inno_proc_prix inno_proc_met_cor inno_proc_sup_cor inno_proc_log_cor inno_proc_prix_cor innovations_prod innovated_prod innovations_prod_cor innovated_prod_cor innovations_proc innovations_proc_cor  innovated_proc innovated_proc_cor"

local export_readiness "eri eri_ssa exp_invested ihs_exp_inv_w99_k1 ihs_exp_inv_w99_k4 exported ca_exp exprep_couts ssa_action1 ssa_action2 ssa_action3 ssa_action4 exp_pra_rexp exp_pra_foire exp_pra_sci exprep_norme exp_pra_vent expp_cost expp_ben export_1 export_2 export_3 exported_2024 export_41 export_42 export_43 export_44 export_45 exp_pays_ssa_w99 exp_pays_ssa_w95" // add at endline: ihs_exp_pays_w99_k1 epp

local business_performance99 "ca lca lca_w95 closed ihs_catun_w99_k1 ihs_catun_w99_k2 ihs_catun_w99_k3 ihs_catun_w99_k5 ihs_catun_w99_k4 ihs_catun2024_w99_k1 ihs_catun2024_w99_k2 ihs_catun2024_w99_k3 ihs_catun2024_w99_k5 ihs_catun2024_w99_k4 ihs_ca_w99_k1 ihs_ca_w99_k4 profit_pos profit_pct ihs_employes_w99_k1 car_empl1_w99_k1 car_empl2_w99_k1 ihs_employes_w99_k3 car_empl1_w99_k3 car_empl2_w99_k3 ihs_costs_w99_k4 marki ihs_costs_w99_k1 ca_w99 profit_w99 clients_w99 clients_ssa_w99 orderssa_w99 exp_pays_w99 ca_tun_w99 ca_tun_2024_w99 ca_2024_w99 ca_exp_w99 ca_exp_2024_w99 costs_w99 costs_2024_w99 profit_2024_w99 employes_w99 car_empl1_w99 car_empl2_w99 ihs_ca_2024_w99_k4  ihs_ca_exp_w99_k4 ihs_caexp2024_w99_k4 ihs_costs_2024_w99_k4 ihs_profit_w99_k4 ihs_profit2024_w99_k4 ihs_caexp2024_w99_k1 ihs_ca_exp_w99_k1 ihs_caexp2024_w99_k2 ihs_ca_exp_w99_k2 ihs_caexp2024_w99_k3 ihs_ca_exp_w99_k3 ihs_profit2024_w99_k1 ihs_profit_w99_k1 ihs_profit2024_w99_k2 ihs_profit_w99_k2 ihs_profit2024_w99_k3 ihs_profit_w99_k3 profit_2024_category bpi bpi_2024 ihs_ca_2024_w99_k1 ihs_costs_2024_w99_k1 ihs_profit2024_w99_k5 ihs_profit_w99_k5 profit_2023_category ihs_pr2024ni_w99_k1 ihs_prni_w99_k1 ihs_pr2024ni_w99_k2 ihs_prni_w99_k2 ihs_pr2024ni_w99_k3 ihs_prni_w99_k3 ihs_pr2024ni_w99_k4 ihs_prni_w99_k4 ihs_pr2024ni_w99_k5 ihs_prni_w99_k5"

local business_performance95 "ihs_catun_w95_k1 ihs_catun_w95_k2 ihs_catun_w95_k3 ihs_catun_w95_k5 ihs_catun_w95_k4 ihs_catun2024_w95_k1 ihs_catun2024_w95_k2 ihs_catun2024_w95_k3 ihs_catun2024_w95_k5 ihs_catun2024_w95_k4 ihs_ca_w95_k1 ihs_ca_w95_k4 ihs_employes_w95_k1 car_empl1_w95_k1 car_empl2_w95_k1 ihs_employes_w95_k3 car_empl1_w95_k3 car_empl2_w95_k3 ihs_costs_w95_k4 ihs_costs_w95_k1 ca_w95 profit_w95 clients_w95 clients_ssa_w95 orderssa_w95 exp_pays_w95 ca_tun_w95 ca_tun_2024_w95 ca_2024_w95 ca_exp_w95 ca_exp_2024_w95 costs_w95 costs_2024_w95 profit_2024_w95 employes_w95 car_empl1_w95 car_empl2_w95 ihs_ca_2024_w95_k4  ihs_ca_exp_w95_k4 ihs_caexp2024_w95_k4 ihs_costs_2024_w95_k4 ihs_profit_w95_k4 ihs_profit2024_w95_k4 ihs_caexp2024_w95_k1 ihs_ca_exp_w95_k1 ihs_caexp2024_w95_k2 ihs_ca_exp_w95_k2 ihs_caexp2024_w95_k3 ihs_ca_exp_w95_k3 ihs_profit2024_w95_k1 ihs_profit_w95_k1 ihs_profit2024_w95_k2 ihs_profit_w95_k2 ihs_profit2024_w95_k3 ihs_profit_w95_k3 ihs_ca_2024_w95_k1 ihs_costs_2024_w95_k1"
local ys `network' `empowerment' `mp' `innovation' `export_readiness' `business_performance99'  `business_performance95'

	* gen dummy + replace missings with zero at bl
foreach var of local ys {
		* only do this for variables that have been included at baseline,
			* here condition: <176 missing values
	quietly count if missing(`var') & surveyround == 1
	local na = `r(N)'
	if `na' < 176 {
		
		* Create missing BL dummy on firm level
		gen t_miss_bl_`var' = (`var' == . & surveyround == 1) 
		egen missing_bl_`var' = max(t_miss_bl_`var'), by(id_plateforme)
		drop t_miss_bl_`var'
		
		* Replace BL of outcome variable with zero to keep in regression
		replace `var' = 0 if `var' == . & surveyround == 1
	}
}

	* generate Y0 --> baseline value for ancova & mht
foreach var of local ys {
	quietly count if missing(`var') & surveyround == 1
	local na = `r(N)'
	if `na' < 176 {
		* generate YO
	bys id_plateforme (surveyround): gen `var'_first = `var'[_n == 1]					// filter out baseline value
	egen `var'_y0 = min(`var'_first), by(id_plateforme)								// create variable = bl value for all three surveyrounds by id
	replace `var'_y0 = 0 if inlist(`var'_y0, ., -777, -888, -999)		// replace this variable = zero if missing
	drop `var'_first														// clean up
	lab var `var'_y0 "Y0 `var'"
	}
   }	
 }
}

***********************************************************************
* 	PART 14: Tunis dummy	
***********************************************************************
gen tunis = (gouvernorat == 10 | gouvernorat == 20 | gouvernorat == 11) // Tunis
gen city = (gouvernorat == 10 | gouvernorat == 20 | gouvernorat == 11 | gouvernorat == 30 | gouvernorat == 40) // Tunis, Sfax, Sousse
lab var tunis "HQ in Tunis"
lab var city "HQ in Tunis, Sousse, Sfax"

***********************************************************************
* 	PART 15: Entreprise Size
***********************************************************************
{
* Generate entrep_size variable and label it
gen entrep_size = .
lab var entrep_size "1- small, 2- large"

* Replace entrep_size values based on conditions
replace entrep_size = 1 if employes <= 5
replace entrep_size = 2 if employes > 5
replace entrep_size = . if employes ==.

label define entrep_size_label 1 "Small" 2 "Large"
label values entrep_size entrep_size_label

* Generate entrep_size variable and label it
gen entrep_size2 = .
lab var entrep_size2 "1- small, 2- large"

* Replace entrep_size values based on conditions
replace entrep_size2 = 1 if employes <= 10
replace entrep_size2 = 2 if employes > 10
replace entrep_size2 = . if employes ==.

label define entrep_size_label2 1 "Small" 2 "Large"
label values entrep_size2 entrep_size_label2
}

***********************************************************************
* 	PART 16: Digital consortia dummy	
***********************************************************************
gen cons_dig = (pole == 4)

***********************************************************************
* 	PART 17: peer effects: baseline peer quality	
***********************************************************************	
{
	* loop over all peer quality baseline characteristics
local labels `" "management practices" "entrepreneurial confidence" "export performance" "business size" "profit" "'
local peer_vars "mpmarki genderi profit" // epp 
foreach var of local peer_vars {
	* get labels for new variables
	gettoken label labels : labels
	
			* generate rank for top3 within each consortium
				* top1: among all firms being offered treatment (for take-up prediction)
		gsort pole treatment surveyround -`var'
		by pole treatment surveyround: gen rank1_`var' = _n
		egen peer_top1_`var' = mean(`var') if rank1_`var' < 4 & treatment == 1 & surveyround == 1, by(pole)
		egen temp_peer_top1_`var' = min(peer_top1_`var') if treatment == 1, by(pole)
		drop peer_top1_`var'
		rename temp_peer_top1_`var' peer_top1_`var'

				* top2: among all treated firms (for peer effect estimation)
		gsort pole take_up surveyround -`var'
		by pole take_up surveyround: gen rank2_`var' = _n
		egen peer_top2_`var' = mean(`var') if rank2_`var' < 4 & take_up == 1 & surveyround == 1, by(pole)
		egen temp_peer_top2_`var' = min(peer_top2_`var') if take_up == 1, by(pole)
		drop peer_top2_`var'
		rename temp_peer_top2_`var' peer_top2_`var'

		lab var peer_top1_`var' "Top-3 peer average bl `label'"
		lab var peer_top2_`var' "Top-3 peer average bl `label'"

			* generate 
		gen peer_avg1_`var' = .
		gen peer_avg2_`var' = .	
		lab var peer_avg1_`var' "Peer average bl `label'"
		lab var peer_avg2_`var' "Peer average bl `label'"
			* loop over each observation
		gsort -treatment surveyround id_plateforme
		forvalues i = 1(1)87 {
			sum pole in `i' 			// get consortium of the observation
			local pole = r(mean)
				* average for all invited to treatment (for take-up predictions), but i
			sum `var' if `i' != _n & pole == `pole' & surveyround == 1 & treatment == 1
			replace peer_avg1_`var' = r(mean) in `i'	 
				* average for all that took-up treatment (for peer-effect estimation), but i
			sum `var' if `i' != _n & pole == `pole' & surveyround == 1 & take_up == 1
			replace peer_avg2_`var' = r(mean) in `i'
	}
			replace peer_avg2_`var' = . if take_up == 0


}

	* revisit the result
sort treatment pole surveyround
*br id_plateforme treatment take_up pole surveyround peer_*
sort treatment surveyround id_plateforme, stable

	* extend to panel, gen distance
local peer_vars "mpmarki genderi profit" // epp
local labels `" "management practices" "entrepreneurial confidence" "export performance" "business size" "profit" "'
foreach var of local peer_vars {
	* get the labels
	gettoken label labels : labels
	forvalues i = 1(1)2 {
	* extend to panel
	bysort id_plateforme (surveyround treatment): replace peer_avg`i'_`var' = peer_avg`i'_`var'[_n-1] if treatment == 1 & peer_avg`i'_`var' == .
		* gen distance
	gen peer_d_avg`i'_`var' = peer_avg`i'_`var' - `var'
	gen peer_d_top`i'_`var' = peer_top`i'_`var' - `var'
	lab var peer_d_avg`i'_`var' "distance to peer average `label'"
	lab var peer_d_top`i'_`var' "distance to top-3 average `label'"
	}
}


	* generate survey-to-survey growth rates
local y_vars "genderi mpi ihs_profit_w99_k1"
foreach var of local y_vars {
		bys id_plateforme: g `var'_abs_growth = D.`var' if `var' != -999 | `var' != -888
			bys id_plateforme: replace `var'_abs_growth = . if `var' == -999 | `var' == -888
}
*bys id_plateforme: g `var'_rel_growth = D.`var'/L.`var'
*bys id_plateforme: replace `var'_rel_growth = . if `var' == -999 | `var' == -888

}


***********************************************************************
* 	PART 18: create cluster variable for twoway clustered SE	
***********************************************************************	
* variable defined as in Cai and Szeidl (2018)
gen consortia_cluster = id_plateforme
	replace consortia_cluster = pole if treatment == 1
	
	
***********************************************************************
* 	PART 19: create post dummy for DiD as Cai and Szeidl (2018)	
***********************************************************************	
gen post = (surveyround > 1)


***********************************************************************
* 	PART final save:    save as final consortium_database
***********************************************************************
save "${master_final}/consortium_final", replace

/*
* export lists for GIZ
preserve 
keep if surveyround == 1
keep id_plateforme year_created pole subsector_corrige produit?
merge 1:1 id_plateforme using "${master_final}/consortium_pii_final"
export excel id_plateforme treatment nom_rep position_rep tel_pdg email_pdg year_created pole subsector_corrige produit? using "${master_final}/eya_list.xlsx", firstrow(var) replace
restore
*/
