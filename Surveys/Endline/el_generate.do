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
*	Author:  	Florian Muench, Amira Bouziri, Kais Jomaa, Eya Hanefi		 												  
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
{
generate produit1 = regexm(el_products, "el_produit1")
lab var produit1 " Best selling product or service"

generate produit2 = regexm(el_products, "2")
lab var produit2 "Second best selling product or service"

generate produit3 = regexm(el_products, "el_produit3")
lab var produit3 "Third best selling product or service" 

foreach var of varlist produit1 produit2 produit3 {
	replace `var' = . if el_products == ""
}


drop el_products
}

***********************************************************************
* 	PART 4:  Create continuous variable for number of innovation
*********************************************************************** 
{
generate inno_none = regexm(inno_produit, "0")
lab var inno_none "No innovation introduced"

generate inno_improve = regexm(inno_produit, "1")
lab var inno_improve "Improved existing products/services"

generate inno_new = regexm(inno_produit, "2")
lab var inno_new "Introduced new products/services" 

foreach var of varlist inno_none inno_improve inno_new {
	replace `var' = . if inno_produit == ""
}

generate inno_both = (inno_improve == 1 & inno_new == 1)
replace inno_both = . if inno_improve == . & inno_new == . 
label var inno_both "Improved & introduced new products/services"

drop inno_produit
}

***********************************************************************
* 	PART 5:  Create continuous variable for inspiration of innovation
*********************************************************************** 
{
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

foreach var of varlist inno_mot_cons inno_mot_cont inno_mot_eve inno_mot_eve inno_mot_client inno_mot_dummyother {
	replace `var' = . if inno_mot == ""
}

generate inno_mot_total = inno_mot_cons + inno_mot_cont + inno_mot_eve + inno_mot_client + inno_mot_dummyother
lab var inno_mot_total "Total of innovation inspirations"


drop inno_mot

}

***********************************************************************
* 	PART 7: network: net_size_m & net_coop
***********************************************************************
{
* 
gen net_size3_m = net_size3 - net_gender3
lab var net_size3_m "Male entrepreneur business discussion"
 
gen net_size4_m = net_size4 - net_gender4
lab var net_size4_m "Male Family/friends business discussion"


* net_coop
	* generate dummies for each cooperative word	
generate netcoop1 = regexm(net_coop, "/ 1 /") if net_coop != ""
generate netcoop2 = regexm(net_coop, "2") if net_coop != ""
generate netcoop3 = regexm(net_coop, "3") if net_coop != ""
generate netcoop4 = regexm(net_coop, "4") if net_coop != ""
generate netcoop5 = regexm(net_coop, "5") if net_coop != ""
generate netcoop6 = regexm(net_coop, "6") if net_coop != ""
generate netcoop7 = regexm(net_coop, "7") if net_coop != ""
generate netcoop8 = regexm(net_coop, "8") if net_coop != ""
generate netcoop9 = regexm(net_coop, "9") if net_coop != ""
generate netcoop10 = regexm(net_coop, "/ 10 /") if net_coop != ""

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
generate net_coop_pos = netcoop2 + netcoop3 + netcoop7 + netcoop8 + netcoop9
label var net_coop_pos "Positive answers for the the perception of interactions between CEOs" 
generate net_coop_neg = netcoop1 + netcoop4 + netcoop5 + netcoop6 +  netcoop10
label var net_coop_neg "Negative answers for the the perception of interactions between CEOs" 


}

***********************************************************************
* 	PART 8: Export
***********************************************************************
{
	
*** exported based on direct survey answer
generate export_1 = regexm(export, "1")

generate export_2 = regexm(export, "2")

generate export_3 = regexm(export, "3")

* re insert missing values
forvalues x = 1(1)3 {
	replace export_`x' = . if export == ""
}

drop export

*** exported based on export sales
gen exported_2024 = (ca_exp_2024 > 0)
replace exported_2024 = . if ca_exp_2024 == .
lab var exported_2024 "Export sales 2024 > 0"

gen exported= (ca_exp > 0)
replace exported = . if ca_exp == .
lab var exported "Export sales 2023 > 0"



*** reasons for not having exported

label var export_1 "Direct export"
label var export_2 "Indirect export"
label var export_3 "No export"

generate export_41 = regexm(export_4, "1")

generate export_42 = regexm(export_4, "2")

generate export_43 = regexm(export_4, "3")

generate export_44 = regexm(export_4, "4")

generate export_45 = regexm(export_4, "5")

* reinsert missing values
forvalues x = 1(1)5 {
	replace export_4`x' = . if export_4 == ""
}

drop export_4

label var export_41 "Not profitable"
label var export_42 "Did not find clients abroad"
label var export_43 "Too complicated"
label var export_44 "Requires too much investment"
label var export_45 "Other"

* replace ssa orders 0 if it is missing value
replace clients_ssa_commandes = 0 if clients_ssa == 0 

*export = 0 if it does not export
 
replace ca_exp = 0 if export_1 == 0 & id_plateforme != 1059 & ca_exp == . // exported in 2023, stopped in 2024
replace ca_exp_2024 = 0 if export_1 == 0 & ca_exp_2024 == .

*exp_pays = 0 if it does not export_1
replace exp_pays = 0 if export_1 == 0 & export_2 == 0 & exp_pays != .



}

***********************************************************************
* 	PART 9: Refusal to participate in consortium
***********************************************************************
{
generate refus_1 = regexm(int_refus, "1")
lab var refus_1 "Members different/not beneficial"

generate refus_2 = regexm(int_refus, "2")
lab var refus_2 "Members are competitors"

generate refus_3 = regexm(int_refus, "3")
lab var refus_3 "Collaboration is personally challenging"

generate refus_4 = regexm(int_refus, "4")
lab var refus_4 "Collaboration requires time"

generate refus_5 = regexm(int_refus, "5")
lab var refus_5 "Others" 

* if firms mentioned existing categories in open answers, code as 1
replace refus_2 = 1 if id_plateforme ==1134
replace refus_4 = 1 if id_plateforme ==1128
replace refus_4 = 1 if id_plateforme ==1231
replace refus_4 = 1 if id_plateforme ==1192
replace refus_4 = 1 if id_plateforme ==1231
replace refus_4 = 1 if id_plateforme ==996 
replace refus_4 = 1 if id_plateforme ==1097


* create additional categories based on open anwers
gen refus_6 = .
replace refus_6 = 0 if int_refus != "Implementation"
replace refus_6 = 1 if id_plateforme == 1087
replace refus_6 = 1 if id_plateforme == 1097
replace refus_6 = 1 if id_plateforme == 1134
replace refus_6 = 1 if id_plateforme == 1184
replace refus_6 = 1 if id_plateforme == 1247

}

***********************************************************************
* 	PART 10: Generate variable to assess number of missing values per firm			  										  
***********************************************************************
{
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
egen miss_manprac = rowmiss(man_fin_per man_fin_pra_bud man_fin_pra_pro man_fin_pra_dis man_ind_awa)

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
egen miss_extlist = rowmiss(listexp)
	
	* section 15: accounting/KPI
egen miss_accounting = rowmiss(profit profit_2024 ca ca_2024 ca_exp ca_exp_2024)

*each accounting
egen miss_profit = rowmiss(profit)

*each accounting
egen miss_profit_2024 = rowmiss(profit_2024)

*each accounting
egen miss_ca = rowmiss(ca)

*each accounting
egen miss_ca_2024 = rowmiss(ca_2024)

*each accounting
egen miss_ca_exp = rowmiss(ca_exp)

*each accounting
egen miss_ca_exp_2024 = rowmiss(ca_exp_2024)

	* create the sum of missing values per company
gen missing_values = miss_inno + miss_export + miss_exp_pracc + miss_eri_ssa + miss_empl + miss_manindicators + miss_manprac + miss_marksource + miss_network + miss_networkserv + miss_netcoop + miss_carefi + miss_carloc + miss_extlist + miss_accounting
lab var missing_values "missing values per company"

}

***********************************************************************
* 	PART 11: Generate variable to assess completed answers		  										  
***********************************************************************
generate survey_completed= 0
replace survey_completed= 1 if missing_values == 0
label var survey_completed "Number of firms which fully completed the survey"
label values survey_completed yesno


***********************************************************************
* 	PART 12:  Generate variables for companies who answered on phone	
***********************************************************************
*method of answer
gen survey_phone = 1
lab var survey_phone "Comapnies who answered the survey on phone (with enumerators)" 


label define Surveytype 1 "Phone" 0 "Online"
label values survey_phone Surveytype


	*responded online

local ids 983 985 1000 1001 1007 1009 1028 1044 1045 1051 1057 1061 1064 1096 1098 1102 1116 1125 1130 1134 1143 1159 1178 1195 1203 1204 1205 1237 1243 1244 1245


foreach var of local ids {
	replace survey_phone = 0 if id_plateforme == `var'
}


***********************************************************************
* 	PART 13:  generate normalized financial data (per employee)
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

************************************************************************
*	Part 14: Harmonization of open ended questions (benefits&inconnvenients)
*************************************************************************
{

gen int_ben1_correct = int_ben1 
gen int_ben2_correct = int_ben2
gen int_ben3_correct = int_ben3
gen int_ben_autres_correct = int_ben_autres

replace int_ben1_correct = "Export" if int_ben1=="mission a l’export"
replace int_ben1_correct = "Export" if int_ben1=="l'exportation"
replace int_ben2_correct = "Export" if int_ben2=="connaissance afrique"
replace int_ben1_correct = "Export" if int_ben1=="opportunités sur le marché internationaux"
replace int_ben3_correct = "Export" if int_ben3=="des éventements b2b a l'étrange"
replace int_ben3_correct = "Export" if int_ben3=="visibilité internationale"
replace int_ben3_correct = "Export" if int_ben3=="opportunités sur des marchés internationaux"
replace int_ben1_correct = "Export" if int_ben1=="ouverture vers de nouveaux marchés"
replace int_ben1_correct = "Export" if int_ben1=="les avantages/offres de voyage (Rwanda, Dubaï, ...)"
replace int_ben1_correct = "Export" if int_ben1=="etablir des voies pour l'exportation et la prospection"
replace int_ben2_correct = "Export" if int_ben2=="participants foires à l'international"
replace int_ben1_correct = "Export" if int_ben1=="prospection de pays en afrique"
replace int_ben2_correct = "Export" if int_ben2=="ouverture sur des nouveaux marché"
replace int_ben2_correct = "Export" if int_ben2=="l'ouverture sur de nouveaux marchés"
replace int_ben2_correct = "Export" if int_ben2=="organisation des voyages pour accéder au marché à l'export(sénégal)"
replace int_ben2_correct = "Export" if int_ben2=="participation à des grands événements ( exp tunisia africa business meetings)"
replace int_ben1_correct = "Export" if int_ben1=="découverte pour marché étranger"
replace int_ben1_correct = "Export" if int_ben1=="prospection"
replace int_ben2_correct = "Export" if int_ben2=="j'ai trouvé des chemins pour exportation et prospection"
replace int_ben2_correct = "Export" if int_ben2=="prospection du marché"
replace int_ben2_correct = "Export" if int_ben2=="la prospection a échelle international"
replace int_ben3_correct = "Export" if int_ben3=="foire a letranger"
replace int_ben3_correct = "Export" if int_ben3=="des opportunités d'exposition en Arabie Saoudite"
replace int_ben2_correct = "Export" if int_ben2=="connaissances des marchés africains"


generate int_ben_export = regexm(int_ben1_correct, "Export")
	replace int_ben_export = . if int_ben1_correct == ""
foreach var of varlist int_ben2_correct int_ben3_correct int_ben_autres_correct {
	replace int_ben_export = regexm(`var', "Export") if int_ben_export != 1
	replace int_ben_export = . if `var' == "" & int_ben_export == .

	}
lab var int_ben_export "Export"

replace int_ben1_correct = "Professional development" if int_ben1=="apprentissage procedures de l'export"
replace int_ben1_correct = "Professional development" if int_ben1=="aprrentissage pour diriger l'entreprise: marketing"
replace int_ben2_correct = "Professional development" if int_ben2=="apprentissage"
replace int_ben3_correct = "Professional development" if int_ben3=="expériences par rapport aux visites te permettent de faire des analyses / comparaison / évaluation des produits par rapport aux secteurs"
replace int_ben1_correct = "Professional development" if int_ben1=="les formations,"
replace int_ben1_correct = "Professional development" if int_ben1=="formations"
replace int_ben1_correct = "Professional development" if int_ben1=="formation"
replace int_ben3_correct = "Professional development" if int_ben3=="les formations"
replace int_ben3_correct = "Professional development" if int_ben3=="il y a des méthodes de management et de travail . energie positive dans la consortium"
replace int_ben1_correct = "Professional development" if int_ben1=="b2b , les formations"
replace int_ben3_correct = "Professional development" if int_ben3=="développement de l'entreprise"
replace int_ben3_correct = "Professional development" if int_ben3=="augmentation ca"
replace int_ben2_correct = "Professional development" if int_ben2=="les techniques de communication et de ventes"
replace int_ben2_correct = "Professional development" if int_ben2=="cycle de formation"
replace int_ben3_correct = "Professional development" if int_ben3=="Travail sur le produit en restauration"
replace int_ben3_correct = "Professional development" if int_ben3=="les conseils et l'encadrement en générale"
replace int_ben3_correct = "Professional development" if int_ben3=="j'ai appris d'eux les procédures d'export et des techniques digitales"
replace int_ben3_correct = "Professional development" if int_ben3=="diagnostic"
replace int_ben_autres_correct = "Professional development" if int_ben_autres=="financement"

generate int_ben_professional = regexm(int_ben1_correct, "Professional development")
	replace int_ben_professional = . if int_ben1_correct == ""
foreach var of varlist int_ben2_correct int_ben3_correct int_ben_autres_correct {
	replace int_ben_professional = regexm(`var', "Professional development") if int_ben_professional != 1
		replace int_ben_professional = . if `var' == "" & int_ben_professional == .

}
lab var int_ben_professional "Professional Development"


replace int_ben1_correct = "Personal development" if int_ben1=="Le travail sur soi-même"
replace int_ben1_correct = "Personal development" if int_ben1=="communication entre eux"
replace int_ben2_correct = "Personal development" if int_ben2=="Le travail d'équipe"
replace int_ben1_correct = "Personal development" if int_ben1=="relationnelle"
replace int_ben1_correct = "Personal development" if int_ben1=="relationnel"
replace int_ben2_correct = "Personal development" if int_ben2=="brain storming"
replace int_ben_autres = "Personal development" if int_ben_autres=="apprendre comment gérer les conflits"
replace int_ben3_correct = "Personal development" if int_ben3=="solidarité"
replace int_ben2_correct = "Personal development" if int_ben2=="l'apprentissage entre eux"
replace int_ben2_correct = "Personal development" if int_ben2=="esprit d équipe et collaboration"
replace int_ben3_correct = "Personal development" if int_ben3=="Travailler ensemble"
replace int_ben3_correct = "Personal development" if int_ben3=="les entrepreneur elle devient travailler ensemble"
replace int_ben_autres_correct = "Personal development" if int_ben_autres=="à travers le consortium elle commencée de travailler ensemble"


generate int_ben_personal = regexm(int_ben1_correct, "Personal development")
	replace int_ben_personal = . if int_ben1_correct == ""

foreach var of varlist int_ben2_correct int_ben3_correct int_ben_autres_correct {
	replace int_ben_personal = regexm(`var', "Personal development") if int_ben_personal != 1
			replace int_ben_personal = . if `var' == "" & int_ben_personal == .

}
lab var int_ben_personal "Personal Development"


{
replace int_ben1_correct = "Network" if int_ben1=="réseautage et partage d'expériences"
replace int_ben1_correct = "Network" if int_ben1=="le réseau"
replace int_ben1_correct = "Network" if int_ben1=="echange"
replace int_ben1_correct = "Network" if int_ben1=="réseaux"
replace int_ben1_correct = "Network" if int_ben1=="energie entre les chefs de l'entreprise"
replace int_ben1_correct = "Network" if int_ben1=="coopération avec d'autres chefs d'entreprise"
replace int_ben1_correct = "Network" if int_ben1=="réseautage"
replace int_ben1_correct = "Network" if int_ben1=="reseautage"
replace int_ben1_correct = "Network" if int_ben1=="réseautage entre les membres du consortium"
replace int_ben1_correct = "Network" if int_ben1=="les connaissances/ les relations avec d'autre entrepreneure"
replace int_ben1_correct = "Network" if int_ben1=="echange d'expériences"
replace int_ben1_correct = "Network" if int_ben1=="elle a rencontré des gens et elle a eu des relations entre les membres du consortium"
replace int_ben1_correct = "Network" if int_ben1=="nouvelles connaissances"
replace int_ben1_correct = "Network" if int_ben1=="nouvelles contact , convention avec d'autres entreprises"
replace int_ben1_correct = "Network" if int_ben1=="partage des informations"
replace int_ben1_correct = "Network" if int_ben1=="de nouveaux partenaires qui ont débuté à travailler avec moi"
replace int_ben1_correct = "Network" if int_ben1=="partenariat entre les entreprises"
replace int_ben1_correct = "Network" if int_ben1=="le resautage"
replace int_ben1_correct = "Network" if int_ben1=="nouvelles connaissances"
replace int_ben1_correct = "Network" if int_ben1=="des nouvelles connaissance"
replace int_ben1_correct = "Network" if int_ben1=="les échanges"
replace int_ben1_correct = "Network" if int_ben1=="resautage a la chelle naationel"

replace int_ben2_correct = "Network" if int_ben2=="partage et échange avec d'autres femmes: réflexions,avis,visions"
replace int_ben2_correct = "Network" if int_ben2=="synergie avec quelques membres"
replace int_ben2_correct = "Network" if int_ben2=="échange d'expériences"
replace int_ben2_correct = "Network" if int_ben2=="netwark"
replace int_ben2_correct = "Network" if int_ben2=="partage d’expérience"
replace int_ben2_correct = "Network" if int_ben2=="les échanges des informations"
replace int_ben2_correct = "Network" if int_ben2=="les contacts"
replace int_ben2_correct = "Network" if int_ben2=="partage d’expérience"
replace int_ben2_correct = "Network" if int_ben2=="les membres du consortium sont complementaires"
replace int_ben2_correct = "Network" if int_ben2=="nom de bons contacts au sein du consortium"
replace int_ben2_correct = "Network" if int_ben2=="échanges des idées"
replace int_ben2_correct = "Network" if int_ben2=="echange experience"
replace int_ben2_correct = "Network" if int_ben2=="échange des expériences entre les nombres du consortium"
replace int_ben2_correct = "Network" if int_ben2=="coopération avec d'autres femmes chefs d'entreprise"
replace int_ben2_correct = "Network" if int_ben2=="coopérations"

replace int_ben3_correct = "Network" if int_ben3=="collaboration"
replace int_ben3_correct = "Network" if int_ben3=="mutualisation des moyens"
replace int_ben3_correct = "Network" if int_ben3=="les échanges d’expériences entre les membres du consortium"
replace int_ben3_correct = "Network" if int_ben3=="partenariat et expériences"
replace int_ben3_correct = "Network" if int_ben3=="nouvelles relations"
replace int_ben3_correct = "Network" if int_ben3=="profit commun"
replace int_ben3_correct = "Network" if int_ben3=="le partage des données et des informations"
replace int_ben3_correct = "Network" if int_ben3=="cooperation"
replace int_ben3_correct = "Network" if int_ben3=="nouvelles contacts"
replace int_ben3_correct = "Network" if int_ben3=="synergie avec quelques entrepreneurs au sein du gie"
replace int_ben3_correct = "Network" if int_ben3=="faire autre projet /net working"
replace int_ben3_correct = "Network" if int_ben3=="partage d experiences"
replace int_ben3_correct = "Network" if int_ben3=="collaboration"

replace int_ben_autres_correct = "Network" if int_ben_autres=="echenage des information"
}

generate int_ben_network = regexm(int_ben1_correct, "Network")
	replace int_ben_network = . if int_ben1_correct == ""

foreach var of varlist int_ben2_correct int_ben3_correct int_ben_autres_correct {
	replace int_ben_network = regexm(`var', "Network") if int_ben_network != 1
		replace int_ben_network = . if `var' == "" & int_ben_network == .

}
lab var int_ben_network "Network"



gen int_incv1_correct = int_incv1 
gen int_incv2_correct = int_incv2
gen int_incv3_correct = int_incv3
gen int_incv_autres_correct = int_incv_autres


{
replace int_incv1_correct = "Personnal Conflicts " if  int_incv1=="conflit à cause de la différence d'options"
replace int_incv1_correct = "Personnal Conflicts " if  int_incv1=="cconflit internes"
replace int_incv1_correct = "Personnal Conflicts " if  int_incv1=="jalousie entre les membres du consortium"
replace int_incv1_correct = "Personnal Conflicts " if  int_incv1=="le dialogue est compliqué"
replace int_incv2_correct = "Personnal Conflicts " if  int_incv2=="Égoïsme"
replace int_incv1_correct = "Personnal Conflicts " if  int_incv1=="communication difficile au début pour créer un lien social et professionnel entre elles  "
replace int_incv2_correct = "Personnal Conflicts " if  int_incv2=="gère quelque conflits "
replace int_incv1_correct = "Personnal Conflicts " if  int_incv1=="jalousie"
replace int_incv1_correct = "Personnal Conflicts " if  int_incv1=="manque de communication"
replace int_incv1_correct = "Personnal Conflicts " if  int_incv1=="jalousie entre les membres du consortium"
replace int_incv1_correct = "Personnal Conflicts " if  int_incv1=="manque de communication et coordination entre les membres de consortium"
replace int_incv1_correct = "Personnal Conflicts " if  int_incv1=="conflit entre les membres" 
replace int_incv1_correct = "Personnal Conflicts " if  int_incv1=="jalousi" 
replace int_incv1_correct = "Personnal Conflicts " if  int_incv1=="conflit"
replace int_incv1_correct = "Personnal Conflicts " if  int_incv1=="manque de transparence"
replace int_incv1_correct = "Personnal Conflicts " if  int_incv1=="L'ambiance générale"
replace int_incv1_correct = "Personnal Conflicts " if  int_incv1=="respect de statut"
replace int_incv1_correct = "Personnal Conflicts " if  int_incv1=="gestion conflit"
replace int_incv2_correct = "Personnal Conflicts " if  int_incv2=="Beaucoup de membres ont quitté le consortium à cause des conflits internes"
replace int_incv2_correct = "Personnal Conflicts " if  int_incv2=="jalousie"
replace int_incv2_correct = "Personnal Conflicts " if  int_incv2=="manque de communication"
replace int_incv2_correct = "Personnal Conflicts " if  int_incv2=="égoïsme des membres"
replace int_incv2_correct = "Personnal Conflicts " if  int_incv2=="conflit"
replace int_incv2_correct = "Personnal Conflicts " if  int_incv2=="conflits"
replace int_incv2_correct = "Personnal Conflicts " if  int_incv2=="mal honneté"
replace int_incv3_correct = "Personnal Conflicts " if  int_incv3=="manque transparnce"
replace int_incv3_correct = "Personnal Conflicts " if  int_incv3=="non respect de membre"
}



generate int_incv_conflict = regexm(int_incv1_correct, "Personnal Conflicts")
	replace int_incv_conflict = . if int_incv1_correct == ""

foreach var of varlist int_incv2_correct int_incv3_correct int_incv_autres_correct {
	replace int_incv_conflict = regexm(`var', "Personnal Conflicts") if int_incv_conflict != 1
		replace int_incv_conflict = . if `var' == "" & int_incv_conflict == .

}
lab var int_incv_conflict "Personnal Conflicts"


replace int_incv3_correct = "Diversity of members" if  int_incv3=="les niveaux de maturités sont très différents et les attentes également"
replace int_incv_autres_correct = "Diversity of members" if  int_incv_autres=="Notre diversité nous a fait perdre beaucoup de temps et d'énergie pour fixer la meilleure stratégie pour le GIE ==&gt; cumul beaucoup de retard sur ma propre entreprise (voir même une stagnation pendant une longue période)"
replace int_incv3_correct = "Diversity of members" if  int_incv3=="esprit d un manager n accepte  pas l innovation mène à l exclusion"
replace int_incv2_correct = "Diversity of members" if  int_incv2=="absence d’ethique de travail par quelques membres"
replace int_incv1_correct = "Diversity of members" if  int_incv1=="savoir être de quelques membres qui impacte le niveau relationnel dans le consortium"
replace int_incv1_correct = "Diversity of members" if  int_incv1=="absence de competences" 
replace int_incv1_correct = "Diversity of members" if  int_incv1=="diversité des profils et caracteres des membres"
replace int_incv1_correct = "Diversity of members" if  int_incv1=="première expérience dans le travaille coopératif"
replace int_incv1_correct = "Diversity of members" if  int_incv1=="nous"
replace int_incv1_correct = "Diversity of members" if  int_incv1=="coté de communication entre les entrepreneuses"
replace int_incv2_correct = "Diversity of members" if  int_incv2=="communication difficile au début pour créer un lien social et professionnel entre elles"
replace int_incv2_correct = "Diversity of members" if  int_incv2=="Malheureusement, il y une distinction régionale (entre le Sud et le Nord)"
replace int_incv2_correct = "Diversity of members" if  int_incv2=="Je ne peux pas être d'accord avec les idées des participantes"
replace int_incv3_correct = "Diversity of members" if  int_incv3==".manque d'alignement des valeurs et des objectifs. coûts et ressources supplémentaires"


generate int_incv_diversity = regexm(int_incv1_correct, "Diversity of members")
	replace int_incv_diversity = . if int_incv1_correct == ""

foreach var of varlist int_incv2_correct int_incv3_correct int_incv_autres_correct {
	replace int_incv_diversity = regexm(`var', "Diversity of members") if int_incv_diversity != 1
	 replace int_incv_diversity = . if `var' == "" & int_incv_diversity == .

}
lab var int_incv_diversity "Diversity of members"

{
replace int_incv1_correct = "Individual Workload" if  int_incv1=="le temps alloué du formation n'est pas adapté à mon temps personnel just une seule fois"
replace int_incv1_correct = "Individual Workload" if  int_incv1=="le temps allouer au consortium au détriments de son propre entreprise"
replace int_incv1_correct = "Individual Workload" if  int_incv1=="perte d'argent"
replace int_incv2_correct = "Individual Workload" if  int_incv2=="engagement moral"
replace int_incv2_correct = "Individual Workload" if  int_incv2=="Il y'a beaucoup de charge de travail "
replace int_incv1_correct = "Individual Workload" if  int_incv1=="temps consacré important"
replace int_incv1_correct = "Individual Workload" if  int_incv1=="perdre de temps" 
replace int_incv1_correct = "Individual Workload" if  int_incv1=="a location de temps supplémentaire"
replace int_incv1_correct = "Individual Workload" if  int_incv1=="le consortium a entraîné une perte significative de temps et d'argent pour aligner les processus et systèmes, tout se confrontant au manque de maturité des entreprises membres, des conflits culturels, et des lacunes en termes d'honnêteté et de professionnalisme,"
replace int_incv1_correct = "Individual Workload" if  int_incv1=="perdre de temps" 
replace int_incv1_correct = "Individual Workload" if  int_incv1=="perte de temps" 
replace int_incv1_correct = "Individual Workload" if  int_incv1=="le temps alloué au consortium au détriment de son propre entreprise" 
replace int_incv1_correct = "Individual Workload" if  int_incv1=="disponibilite" 
replace int_incv2_correct = "Individual Workload" if  int_incv2=="contribuant ainsi à une perturbation de la performance de mon entreprise"
replace int_incv2_correct = "Individual Workload" if  int_incv2=="perte d'argent"
replace int_incv2_correct = "Individual Workload" if  int_incv2=="il n'y a pas de motivation pour l'équipe"
replace int_incv2_correct = "Individual Workload" if  int_incv2=="perte d'évergie"
replace int_incv3_correct = "Individual Workload" if  int_incv3=="Ca prends trop de temps de ma vie"
replace int_incv3_correct = "Individual Workload" if  int_incv3=="J'ai perdu mon temps et j'ai fait de gros efforts pour assister à toute la cérémonie, et finalement nous avons été victimes d'une grande injustice."
}

generate int_incv_workload = regexm(int_incv1_correct, "Individual Workload")
	replace int_incv_workload = . if int_incv1_correct == ""

foreach var of varlist int_incv2_correct int_incv3_correct int_incv_autres_correct {
	replace int_incv_workload = regexm(`var', "Individual Workload") if int_incv_workload != 1
		 replace int_incv_workload = . if `var' == "" & int_incv_workload == .

}
lab var int_incv_workload "Individual Workload"


{
replace int_incv1_correct = "Program implementation" if  int_incv1=="programme chargé"
replace int_incv1_correct = "Program implementation" if  int_incv1=="Perte du temps (abscence de stratégie claire)"
replace int_incv_autres_correct = "Program implementation" if  int_incv_autres=="La GIZ a pris des décisions critiquées dans le processus de sélection des membres du consortium, ce qui a engendré des problèmes dans tous les GIE.  Critères de sélection flous ou non transparents. Manque d'évaluation des capacités, de la maturité et des engagements des membres des GIE."
replace int_incv3_correct = "Program implementation" if  int_incv3=="les procédures s rigide"
replace int_incv_autres_correct = "Program implementation" if  int_incv_autres=="manque de financement" 
replace int_incv1_correct = "Program implementation" if  int_incv1=="le nombre d'entreprise est très élevés" 
replace int_incv1_correct = "Program implementation" if  int_incv1=="La methode de selection des entreprises"
replace int_incv1_correct = "Program implementation" if  int_incv1=="Mal organisation du gie"
replace int_incv1_correct = "Program implementation" if  int_incv1=="sélection de la part de de giz n'est pas vraiment précise"
replace int_incv1_correct = "Program implementation" if  int_incv1=="les société n'ont pas le même niveau en activité artisanale"
replace int_incv1_correct = "Program implementation" if  int_incv1=="L'entreprise a été victime d'injustice et n'a pas été inscrit dans le groupe malgré un dossier complet"
replace int_incv1_correct = "Program implementation" if  int_incv1=="la manière de sélectionner les entreprises pour la constitution d'un consortium"
replace int_incv2_correct = "Program implementation" if  int_incv2=="limitation des ressources financières"
replace int_incv2_correct = "Program implementation" if  int_incv2=="conflit avec la giz, beaucoup d'idées qui ne sont pas d'accord entre giz et gie"
replace int_incv2_correct = "Program implementation" if  int_incv2=="problèmes au sein des entreprises qui n'est pas financièrement stables"
replace int_incv2_correct = "Program implementation" if  int_incv2=="mauvais chois des destinations choisie"
replace int_incv2_correct = "Program implementation" if  int_incv2=="ma société n'a pas exporté"
replace int_incv2_correct = "Program implementation" if  int_incv2=="il y a une importante hétérogénéité au sein du consortium: certaines entreprises sont encores débutantes alors que d'autres sont bien établies depuis longtemps"
replace int_incv2_correct = "Program implementation" if  int_incv2=="probléme de financement"
replace int_incv2_correct = "Program implementation" if  int_incv2=="le fait d'avoir 3 sous secteurs dans un même consortium"
replace int_incv2_correct = "Program implementation" if  int_incv2=="choix aléatoire des membres"
replace int_incv2_correct = "Program implementation" if  int_incv2=="entreprise ne sont pas toute mature"
replace int_incv3_correct = "Program implementation" if  int_incv3=="les formations qui ont été faites étaient une perte de temps car elles n'étaient pas stratégies car ils n'ont pas le même courant de pensée"
replace int_incv3_correct = "Program implementation" if  int_incv3=="Je n'en profiterai pas financièrement"
replace int_incv3_correct = "Program implementation" if  int_incv3=="les formations qui ont été faites étaient une perte de temps car elles n'étaient pas stratégies car ils n'ont pas le même courant de pensée"
replace int_incv3_correct = "Program implementation" if  int_incv3=="la différence de maturité des entreprises qui constitue le consortium"
}

generate int_incv_impl = regexm(int_incv1_correct, "Program implementation")
	replace int_incv_impl = . if int_incv1_correct == ""

foreach var of varlist int_incv2_correct int_incv3_correct int_incv_autres_correct {
	replace int_incv_impl = regexm(`var', "Program implementation") if int_incv_impl != 1
	 replace int_incv_impl = . if `var' == "" & int_incv_impl == .

}
lab var int_incv_impl "Program implementation"



}

*************************************************************************
*	Part 15: Categorisation products_other
*************************************************************************
{
gen products_other_correct = products_other 

replace products_other_correct ="Learning Disabilities Assessment" if products_other =="depistage de signe de trouble d’apprentissage"
replace products_other_correct ="Home Accessories" if products_other =="pergola et structure en bois"
replace products_other_correct ="Courses and Training" if products_other =="des cours en ligne"
replace products_other_correct ="Kitchenware" if products_other =="organic bowl"
replace products_other_correct ="Kitchenware" if products_other =="service de présentation/ les planches / assiette plat"
replace products_other_correct ="Essential Oils" if products_other =="c'est une gamme composée de 4 produits : mixoil plusplus (poudre/liquide) /mixoil simple / mixoil liquide et poudre"
replace products_other_correct ="Courses and Training" if products_other =="contenus de formation digital"
replace products_other_correct ="Merchandising Products" if products_other =="produits dérivés"
replace products_other_correct ="Essential Oils" if products_other =="huille de pépin de figues de barbarie"
replace products_other_correct ="Human Resources and Technical Consulting" if products_other =="recrutement, assistance technique et  projets de développement"
replace products_other_correct ="Home Accessories" if products_other =="des miroirs fait avec du bois de palmier"
replace products_other_correct ="Graphic Design" if products_other =="les conceptions graphiques"
replace products_other_correct ="Dried Aromatic Herbs" if products_other =="les herbes aromatiques séchées (romarin, armoise, géranium)"
replace products_other_correct ="Make up" if products_other =="maquillage: les crayons, les pinceaux, palette contouring"
replace products_other_correct ="Home Accessories" if products_other =="organisateur de sacs"
replace products_other_correct ="Digital Business Solutions" if products_other =="sollution digital /automotasiation insciption en ligne /sollutions rh et de recrutement /solution de degitalisation de cheques / solutions degitale de courssiers"
replace products_other_correct ="Professional Services" if products_other =="services ( consulting/ project management )"
replace products_other_correct ="Essential Oils" if products_other =="huile de millas"
replace products_other_correct ="Dried Aromatic Herbs" if products_other =="ail en poudre"
replace products_other_correct ="Traditional Clothing" if products_other =="vetement traditionnel: houli et hayek"
replace products_other_correct ="Oils" if products_other =="bouteille d'huile d'olive"
replace products_other_correct ="Dried Aromatic Herbs" if products_other =="harissa et des épices"
replace products_other_correct ="Home Accessories" if products_other ==" frange parfumée"
replace products_other_correct ="logicel ERP" if products_other =="ERP odoo"
replace products_other_correct ="Refrigeration Equipment" if products_other =="ventes et installation equipements frigorifique"
replace products_other_correct ="Water Systems and Irrigation Management" if products_other =="etudes/suivi des travaux des systèmes d alimentation en eau potable et des périmètres irrigués"
replace products_other_correct ="Traditional Pastries" if products_other =="les patisseries traditionnelles"
replace products_other_correct ="Pastry Equipment" if products_other =="concasseur ammande et pistache"
replace products_other_correct ="Fashion accessories" if products_other =="sacs en cuire"
replace products_other_correct ="Skin and Hair care" if products_other =="gel anti douleur,serum des cheuveux, mousse netoyant"


}



************************************************************************
*	Part 16: Create non-intervaled financial values
*************************************************************************
gen prni = profit if profit_2023_category_perte == . & profit_2023_category_gain == .

gen pr2024ni = profit_2024 if profit_2024_category_perte == . & profit_2024_category_gain == .

gen cani = ca if comp_ca2023_intervalles == .

gen ca2024ni = ca_2024 if comp_ca2024_intervalles == .

***********************************************************************
* 	PART 17: save dta file  										  
***********************************************************************
save "${el_final}/el_final", replace
