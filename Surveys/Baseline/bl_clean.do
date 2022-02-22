************************************************************************
* 			consortias baseline clean					 		  	  *	  
***********************************************************************
*																	  
*	PURPOSE: clean consortias baseline raw data	& save as intermediate				  	  			
*																	  
*																	  
*	OUTLINE:														  
*	1)		Format string & numerical variables				          
*	2)   	Drop all text windows from the survey					  
*	3)  	Make all variables names lower case						  
*	4)  	Order the variables in the data set						  	  
*	5)  	Rename the variables									  
*	6)  	Label the variables										  
*   7) 		Removing trailing & leading spaces from string variables	
*   8) 		Remove observations for incomplete entries									 
*																	  													      
*	Author:     	Teo Firpo						    
*	ID variable: 	id_plateforme (identifiant)			  					  
*	Requires:       bl_raw.dta 	  										  
*	Creates:        bl_inter.dta			                                  
***********************************************************************
* 	PART 1: 	Format string & numerical & date variables		  			
***********************************************************************

use "${bl_raw}/bl_raw", clear

{
	* string
ds, has(type string) 
local strvars "`r(varlist)'"
format %-20s `strvars'

	* make all string obs lower case
foreach x of local strvars {
replace `x'= lower(`x')
}
	* numeric 
ds, has(type numeric) 
local numvars "`r(varlist)'"
format %-25.2fc `numvars'

	* dates
		* creation
format Date %td


}
	* keep dates as string variables for RA quality checks
gen date_creation_string = Datedecréation
format date_creation_string %td
tostring date_creation_string, replace u force

gen date_inscription_string = Dateinscription
format date_inscription_string %td
tostring date_inscription_string, replace u force


/* --------------------------------------------------------------------
	PART 1.2: Turn binary questions numerical 
----------------------------------------------------------------------*/
/*
local binaryvars Acceptezvousenregistrement  Nomdelapersonne Nomdelentreprise id_ident2 dig_con1 dig_con3 dig_con5 dig_presence1 dig_presence2 dig_presence3 dig_marketing_lien expprep_cible  dig_vente dig_marketing_ind1 attest attest2 dig_service_satisfaction expprep_norme expprep_demande rg_oper_exp carsoutien_gouvern perc_com1 perc_com2 exp_afrique car_ecom_prive exp_avant21 info_neces
 
foreach var of local binaryvars {
	capture replace `var' = "1" if strpos(`var', "oui")
	capture replace `var' = "0" if strpos(`var', "non")
	capture replace `var' = "-999" if strpos(`var', "sais")
	capture replace `var' = "-1200" if strpos(`var', "prévu")
	capture destring `var', replace
}



/* --------------------------------------------------------------------
	PART 1.3: Fix mutliple choice questions
----------------------------------------------------------------------*/
{
	
* entr_bien_service
	
//capture encode entr_bien_service, gen(entr_service_bien)

* car_sex_pdg
/*
replace car_sex_pdg = "1" if car_sex_pdg == "femme أنثى"
replace car_sex_pdg = "2" if car_sex_pdg == "homme ذكر"
destring car_sex_pdg, replace

* car_pdg_educ

replace car_pdg_educ = "1" if car_pdg_educ == "aucune scolarité, école primaire, secondaire (sans obtention du bac) ماقراش/ تعليم ابتدائي / تعليم ثانوي (ما خذاش البكالوريا)"
replace car_pdg_educ = "1" if car_pdg_educ == "formation professionnelle diplômante (bts/ btp...)  تكوين مهني (يمكن من الحصول على شهادة)"
replace car_pdg_educ = "2" if car_pdg_educ == "diplôme de l'enseignement secondaire (baccalauréat) متحصل على شهادة ختم التعليم الثانوي (البكالوريا)"
replace car_pdg_educ = "3" if car_pdg_educ == "enseignement supérieur (diplôme universitaire) متحصل على شهادة جامعية"
replace car_pdg_educ = "-999" if car_pdg_educ == "ne sais pas (ne pas lire) - ما نعرفش (ما تقراش)"
destring car_pdg_educ, replace
*/	
	
* variable dig_con2
gen dig_con2_internationale = 0
replace dig_con2_internationale = 1 if strpos(dig_con2, "r1")

gen dig_con2_correct = 0
replace dig_con2_correct = 1 if strpos(dig_con2, "1")

gen dig_con2_pas_paiement = 0
replace dig_con2_pas_paiement = 1 if strpos(dig_con2, "r3")



* Surlesquellesdesmarketplaces

g dig_presence3_ex1 = 0
replace dig_presence3_ex1 = 1 if strpos(Surlesquellesdesmarketplaces, "r1")

g dig_presence3_ex2 = 0
replace dig_presence3_ex2= 1 if strpos(Surlesquellesdesmarketplaces, "r2")

g dig_presence3_ex3 = 0
replace dig_presence3_ex3= 1 if strpos(Surlesquellesdesmarketplaces, "r3")

g dig_presence3_ex4 = 0
replace dig_presence3_ex4= 1 if strpos(Surlesquellesdesmarketplaces, "r4")

g dig_presence3_ex5 = 0
replace dig_presence3_ex5= 1 if strpos(Surlesquellesdesmarketplaces, "r5")

g dig_presence3_ex6 = 0
replace dig_presence3_ex6= 1 if strpos(Surlesquellesdesmarketplaces, "r6")

g dig_presence3_ex7 = 0
replace dig_presence3_ex7= 1 if strpos(Surlesquellesdesmarketplaces, "r7")

g dig_presence3_ex8 = 0
replace dig_presence3_ex8= 1 if strpos(Surlesquellesdesmarketplaces, "r8")

g dig_presence3_exnsp = 0
replace dig_presence3_exnsp= 1 if strpos(Surlesquellesdesmarketplaces, "-999")



* dig_miseajour1

local vars_misea dig_miseajour2 dig_miseajour1 dig_miseajour3

foreach var of local vars_misea {
	replace `var' = "0" if `var' == "jamais / أبدا"
	replace `var' = "0.25" if `var' == "annuellement / سنويا"
	replace `var' = "0.5" if `var' == "mensuellement / شهريا"
	replace `var' = "0.75" if `var' == "hebdomadairement / أسبوعيا"
	replace `var' = "1" if `var' == "plus qu'une fois par semaine / أكثر من مرة في الأسبوع"
	destring `var', replace
	} 
	
* dig_payment
local vars_payments dig_payment1 dig_payment2 dig_payment3

foreach var of local vars_payments {
	replace `var' = "0.5" if `var' == "seulement commander en ligne, mais le paiement se fait par d'autres moyens (virement, mandat postal, cash-on-delivery...)  / تكمندي منو فقط وتخلص بوسائل أخرى"
	replace `var' = "1" if `var' == "commander et payer en ligne /  تكمندي وتخلص منو"
	replace `var' = "0" if `var' == "ni commander ni payer en ligne / لا تكمندي لا تخلص"
	destring `var', replace
}

***********************************************************************
* 	PART 2: 	Drop all unneeded columns and rows from the survey		  			
***********************************************************************

*drop VARNAMES

drop dig_con2 dig_con6 Surlesquellesdesmarketplaces dig_marketing_num19 dig_con4 dig_logistique_retour 

drop if Id_plateforme==.

* 	Drop incomplete entries

gen complete = 0 

replace complete = 1 if attest ==1 | attest2 ==1 |  Acceptezvousdevalidervosré ==1 

// keep if complete == 1

// drop complete
*/
***********************************************************************
* 	PART 3: 	Make all variables names lower case		  			
***********************************************************************
rename *, lower

***********************************************************************
* 	PART 4: 	Order the variables in the data set		  			
***********************************************************************
/*
order id_plateforme heure date attest attest2 acceptezvousdevalidervosré survey_type


***********************************************************************
* 	PART 5: 	Rename the variables as needed
***********************************************************************
{
	* Section identification
rename id id_plateforme
rename groupe treatment

	* Section informations personnelles répresentantes
rename nometprénomdudelaparticipa rg_nom_rep
rename qualitéfonction rg_position_rep
rename sexe rg_gender_rep
rename téléphonedudelaparticipante rg_telrep 
rename adressemaildudelaparticipan rg_emailrep
rename téléphonedudelagérante rg_telpdg
rename adressemaildudelagérante rg_emailpdg
rename sexedudelagérante rg_sex_pdg
rename adressesiègesociale rg_adresse 
rename raisonsociale firmname 

	* Section présence en ligne
rename sitedelentreprise rg_siteweb 
rename réseausocialdelentreprise rg_media 

	* Section accounting
rename chiffredaffaires2018 ca_2018
rename chiffredaffairesexport2018 ca_exp2018 
rename chiffredaffaires2019 ca_2019
rename chiffredaffairesexport2019 ca_exp2019
rename chiffredaffaires2020 ca_2020
rename chiffredaffairesexport2020 ca_exp2020

	* Section firm characteristics
			* Legal
rename formejuridique rg_legalstatus
rename matriculecnss rg_matricule 
rename identifiantunique id_admin
rename codedouane rg_codedouane
rename entreprise rg_onshore 
			* Controls
rename datedecréation date_created
rename effectiftotal rg_fte
rename nbrdefemmessalariée rg_fte_femmes 
rename capitalsocial rg_capital 
*rename domaine sector
rename secteurdactivité subsector
rename secteurdactivitémisàjour subsector_corrige 

foreach x in subsector subsector_corrige {
	replace `x' = lower(stritrim(strtrim(`x')))
}

			* Export
rename régime rg_exportstatus
rename avezvousentaméuneopérationd rg_export
rename estcequevousavezunproduit rg_exportable 
rename avezvouslintentiondexporter rg_intexp

	* Section suivi
rename commentavezvousapprisdelex moyen_com
rename politiquedeconfidentialité rg_confidentialite
rename partagerutiliserlesdonnéesco rg_partage_donnees
rename enregistrermescoordonnéessur rg_enregistrement_coordonnees

*rename commentairesequipetuberlinms commentairesequipemsb
	
}

***********************************************************************
* 	PART 6: 	Label the variables		  			
***********************************************************************
{
		* Section contact details
*lab var X ""
lab var  entr_histoire "histoire de l'entreprise"
lab var  entr_bien_service "est ce que l'entreprise vend un bien, un service ou les 2"
lab var entr_produit1 "produit/service principal de l'entreprise 1"
lab var entr_produit2 "produit/service principal de l'entreprise 2"
lab var entr_produit3 "produit/service principal de l'entreprise 3"

}
{
		* Section contact details
*lab var X ""
label variable rg_nom_rep "nom et prénom du representant"
label variable rg_position_rep "qualité & fonction du representant"
label variable rg_gender_rep "sexe du representant"
label variable rg_telrep "téléphone du representant"
label variable rg_emailrep "adresse mail du representant"
label variable rg_telpdg "téléphone du PDG"
label variable rg_emailpdg "adresse mail du PDG"
label variable rg_sex_pdg "sexe du PDG"
label variable rg_adresse "adresse du siège social"
label variable firmname "nom de l'entreprise"

	* Section présence en ligne
label variable rg_siteweb "site web de l'entreprise"
label variable rg_media "réseau  social de l'entreprise"

	* Section accounting
lab var ca_2018 "chiffre d'affaires 2018"
lab var ca_2019 "chiffre d'affaires 2019"
lab var ca_2020 "chiffre d'affaires 2020"

lab var ca_exp2018 "chiffre d'affaires export 2018"
lab var ca_exp2019 "chiffre d'affaires export 2019"
lab var ca_exp2020 "chiffre d'affaires export 2020"

	* Section firm characteristics
			* Legal
label variable rg_legalstatus "forme juridique"
label variable rg_matricule "matricule CNSS"
label variable id_admin "matricule fiscale"
label variable rg_codedouane "code douane"
label variable rg_onshore "entreprise résidente en Tunisie"

			* Controls
label variable date_created "Date création de l'entreprise"
label variable rg_fte "nombre d'employés de l'entreprise"
label variable rg_fte_femmes "nombre d'employées féminin de l'entreprise"
label variable rg_capital "capital social"
*label variable sector "domaine"
label variable subsector " secteur d'acvitivté"
label variable subsector_corrige " subsector d'acvitivté corrigé"

			* Export
label variable rg_exportstatus "régime d'exportation"
label variable rg_export "est-ce que l'entreprise a au moins une opération d'export"
label variable rg_exportable "est ce que l'entreprise a un produit exportable"
label variable rg_intexp "intention d'exporter ou non"

	* Section suivi
label variable moyen_com "moyen de communication ayant permis de découvrir l'existence du programme"
label variable rg_confidentialite "Partager utiliser les données confidentielles"
label variable rg_partage_donnees "Partager/utiliser les données collectées et anonymisées"
label variable rg_enregistrement_coordonnees "Enregistrer mes coordonnées sur sa base de données"

		* Section eligibility
}

***********************************************************************
* 	PART 7: Removing trail and leading spaces in from string variables  			
***********************************************************************
* Creating global according to the variable type
global varstring info_compt2 exp_afrique_principal exp_pays_principal_21 car_attend1 car_attend2 car_attend3 exp_produit_services_avant21 exp_produit_services21 entr_histoire entr_bien_service entr_produit1 entr_produit2 entr_produit3 dig_presence3_exemples_autres investcom_benefit3_1 investcom_benefit3_2 investcom_benefit3_3 expprep_norme2
global numvars info_compt1 dig_revenues_ecom comp_benefice2020 comp_ca2020 compexp_2020 tel_sup2 tel_sup1 car_carempl_div1 car_carempl_dive2 car_carempl_div3 dig_marketing_respons investcom_futur investcom_2021 expprep_responsable exp_pays_avant21 exp_pays_principal_avant21 exp_pays_21


{
ds, has(type string) 
local strvars "`r(varlist)'"
foreach x of local strvars {
replace `x' = stritrim(strtrim(`x'))
}
}

*/
***********************************************************************
* 	Save the changes made to the data		  			
***********************************************************************
cd "$bl_intermediate"
save "bl_inter", replace
