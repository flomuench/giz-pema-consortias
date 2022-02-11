***********************************************************************
* 			Registration clean									  		  
***********************************************************************
*																	  
*	PURPOSE: clean Registration raw data					  	  			
*																	  
*																	  
*	OUTLINE:														  
*	1)		Format string & numerical variables				          
*	2)   	Drop all text windows from the survey					  
*	3)  	Make all variables names lower case						  
*	4)  	Order the variables in the data set						  	  
*	5)  	Rename the variables									  
*	6)  	Label the variables										  
*   7) 		Label variable values 								 
*   8) 		Removing trailing & leading spaces from string variables										 
*																	  													      
*	Author:  	Florian Muench & Kais Jomaa & Teo Firpo						    
*	ID variable: 	id (identifiant)			  					  
*	Requires: bl_raw.dta 	  										  
*	Creates:  bl_inter.dta			                                  
***********************************************************************
* 	PART 1: 	Format string & numerical & date variables		  			
***********************************************************************
use "${regis_raw}/regis_raw", clear
	
	* string
ds, has(type string) 
local strvars "`r(varlist)'"
format %-20s `strvars'

	* numeric 
ds, has(type numeric) 
local numvars "`r(varlist)'"
format %-25.0fc `numvars'

	* dates
		* creation, inscription
format Date* %td

	* keep dates as string variables for RA quality checks
gen date_creation_string = Datedecréation
format date_creation_string %td
tostring date_creation_string, replace u force

gen date_inscription_string = Dateinscription
format date_inscription_string %td
tostring date_inscription_string, replace u force

***********************************************************************
* 	PART : Removing trail, leading spaces + lower all letters  			
***********************************************************************
{
ds, has(type string) 
local strvars "`r(varlist)'"
foreach x of local strvars {
replace `x' = lower(stritrim(strtrim(`x')))
}
}
	
***********************************************************************
* 	PART 2: 	Drop all text windows from the survey		  			
***********************************************************************

***********************************************************************
* 	PART 3: 	Make all variables names lower case		  			
***********************************************************************
rename *, lower

***********************************************************************
* 	PART 4: 	Order the variables in the data set		  			
***********************************************************************


***********************************************************************
* 	PART 5: 	Rename the variables in line with GIZ contact list final	  			
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
rename secteurdactivitémisàjourpa subsector_corrige 
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
* 	PART 7: 	Label variables values	  			
***********************************************************************
{
/*
lab def labelname 1 "" 2 "" 3 ""
lab val variablename labelname
*/
}

***********************************************************************
* 	Save the changes made to the data		  			
***********************************************************************
cd "$regis_intermediate"
save "regis_inter", replace
