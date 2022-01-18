***********************************************************************
* 			registration corrections									  	  
***********************************************************************
*																	    
*	PURPOSE: correct all incoherent responses				  							  
*																	  
*																	  
*	OUTLINE:														  
*	1)		Define non-response categories 			  				  
* 	2) 		correct unique identifier - matricule fiscal
*	3)   	Replace string with numeric values						  
*	4)  	Convert string to numerical variaregises	  				  
*	5)  	Convert proregisematic values for open-ended questions		  
*	6)  	Traduction reponses en arabe au francais				  
*   7)      Rename and homogenize the observed values                   
*	8)		Import categorisation for opend ended QI questions
*	9)		Remove duplicates
*
*																	  															      
*	Author:  	Florian Muench & Kais Jomaa							  
*	ID variaregise: 	id (example: f101)			  					  
*	Requires: regis_inter.dta 	  								  
*	Creates:  regis_inter.dta			                          
*																	  
***********************************************************************
* 	PART 1:  Define non-response categories  			
***********************************************************************
use "${regis_intermediate}/regis_inter", clear

{
	* replace "-" with missing value
ds, has(type string) 
local strvars "`r(varlist)'"
foreach x of local strvars {
		replace `x' = "" if `x' == "-"
	}
	
scalar not_know    = 77777777777777777
scalar refused     = 99999999999999999
scalar check_again = 88888888888888888

	* replace, gen, label
	
*/
}
gen needs_check = 0
gen questions_needing_check = ""

***********************************************************************
* 	PART 2: use regular expressions to correct variables 		  			
***********************************************************************
/* 
example code: 
gen id_admin_correct = ustrregexm(id_admin, "([0-9]){6,7}[a-z]")
replace rg_nom_rep_cor = ustrregexra( rg_nom_rep_cor ,"mr ","")
replace rg_codedouane_cor = ustrregexra( rg_codedouane_cor ,"/","")
replace autres_cor = "services informatiques" if ustrregexm( autres_cor ,"informatique")== 1
gen rg_telrep_cor = ustrregexra(rg_telrep, "^216", "")

example variables: 
- id_admin, nom_rep etc.

*/ 

* Nombre d'employés dans l'entreprise 
*le nombre d'employes féminin dans l'entreprise doit être inférieur au nombre d'employés total.
gen rg_fte_femmes_cor = rg_fte_femmes
replace rg_fte_femmes_cor = 88888888888888888 if rg_fte < rg_fte_femmes


order rg_fte_femmes_cor, a(rg_fte_femmes)
drop rg_fte_femmes 
rename rg_fte_femmes_cor rg_fte_femmes 

        * Matricule fiscale de l'entreprise:
gen id_admin_cor = id_admin
replace id_admin_cor = ustrregexra( id_admin_cor ,"/","")
replace id_admin_cor = ustrregexra( id_admin_cor ," ","")

order id_admin_cor, a(id_admin)
drop id_admin 
rename id_admin_cor id_admin

		* gen dummy if matricule fiscal is correct: 7 digit, 1 character condition
gen id_admin_correct = ustrregexm(id_admin, "([0-9]){6,7}[a-z]")
order id_admin_correct, a(id_admin)
lab def correct 1 "correct" 0 "incorrect"
lab val id_admin_correct correct


    *correct code de la douane

gen rg_codedouane_cor = rg_codedouane
replace rg_codedouane_cor = ustrregexra(rg_codedouane," ","")
replace rg_codedouane_cor = "1435318s" if rg_codedouane_cor == "1435318/s"

replace questions_needing_check = "rg_codedouane" if id_plateforme == 1002
replace needs_check = 1 if id_plateforme == 1002

order rg_codedouane_cor, a(rg_codedouane)
drop rg_codedouane 
rename rg_codedouane_cor rg_codedouane 


	* correct telephone numbers with regular expressions
		* representative
 gen rg_telrep_cor = ustrregexra(rg_telrep, "^216", "")
replace rg_telrep_cor = ustrregexra( rg_telrep_cor,"[a-z]","")
replace rg_telrep_cor = ustrregexra( rg_telrep_cor," ","")
replace rg_telrep_cor = ustrregexra( rg_telrep_cor,"00216","")
replace rg_telrep_cor = "29530240" if rg_telrep_cor == "(+216)29530240"
replace rg_telrep_cor = "28219916" if rg_telrep_cor == "+21628219916"
replace rg_telrep_cor = "97405671" if rg_telrep_cor == "+21697405671"


/*	* Check all phone numbers having more or less than 8 digits
replace rg_telrep_cor = "$check_again" if strlen( rg_telrep_cor ) != 8

*/
	* Check phone number
gen diff = length(rg_telrep) - length(rg_telrep_cor)
order rg_telrep_cor diff, a(rg_telrep)
*browse rg_telrep* diff
drop rg_telrep diff
rename rg_telrep_cor rg_telrep 

	* Vérifier nom et prénom du representant*
gen rg_nom_rep_cor = ustrlower(rg_nom_rep)
/*
replace rg_nom_rep_cor = "$check_again" if rg_nom_rep_cor == "sawssen" /*le nom de famille manque*/

*/

order rg_nom_rep_cor, a(rg_nom_rep)
drop rg_nom_rep 
rename rg_nom_rep_cor rg_nom_rep

	* Téléphone du de lagérante

gen rg_telpdg_cor = ustrregexra( rg_telpdg, "^216", "")
replace rg_telpdg_cor = subinstr(rg_telpdg_cor, " ", "", .)
replace rg_telpdg_cor = ustrregexra( rg_telpdg_cor,"[a-z]","")
replace rg_telpdg_cor = ustrregexra( rg_telpdg_cor,"00216","")
order rg_telpdg_cor, a(rg_telpdg)
replace rg_telpdg_cor = "52710565" if rg_telpdg_cor == "(+216)52710565"
replace rg_telpdg_cor = "97405671" if rg_telpdg_cor == "+21697405671"

/*
replace rg_telpdg_cor = "$check_again" if rg_telpdg_cor == "82828"

replace questions_needing_check = "rg_telpdg" if id_plateforme == 
replace needs_check = 1 if id_plateforme ==
*/
replace rg_telpdg_cor = "28219916" if rg_telpdg_cor == "+21628219916"

order rg_telpdg_cor, a(rg_telpdg)
drop rg_telpdg
rename rg_telpdg_cor rg_telpdg


    * adresse mail du PDG
gen rg_emailpdg_cor = rg_emailpdg

/*
replace rg_emailpdg_cor = "$check_again" if rg_emailpdg == "yosra.slama@genoviaing"

replace questions_needing_check = "rg_telpdg" if id_plateforme == 
replace needs_check = 1 if id_plateforme ==
*/
order rg_emailpdg_cor, a(rg_emailpdg)
drop rg_emailpdg
rename rg_emailpdg_cor rg_emailpdg

	* variable: Qualité/fonction

gen rg_position_repcor = ustrlower(rg_position_rep)
replace rg_position_repcor = "directrice" if rg_position_rep == "dirctrice"

/*
replace rg_position_repcor = "$check_again" if rg_position_rep == "group task 6 - peer to peer group wee"

*/
replace rg_position_repcor = "gérant" if rg_position_rep == "gerant"
replace rg_position_repcor = "gérante" if rg_position_rep == "gerante"
replace rg_position_repcor = "gérant" if rg_position_rep == "gerant"
replace rg_position_repcor = "gérante" if rg_position_rep == "gérant e"
replace rg_position_repcor = "coo" if rg_position_rep == "c.o.o"
order rg_position_repcor, a(rg_position_rep)
drop rg_position_rep 
rename rg_position_repcor rg_position_rep 

	* variable: Matricule CNSS

gen rg_matricule_cor = ustrregexra(rg_matricule, "[ ]", "")
replace rg_matricule_cor = ustrregexra(rg_matricule_cor, "[/]", "-")
replace rg_matricule_cor = ustrregexra(rg_matricule_cor, "[_]", "-")

		* Format CNSS Number:
gen t1 = ustrregexs(0) if ustrregexm(rg_matricule_cor, "\d{8}")
gen t2 = ustrregexs(0) if ustrregexm(t1, "[0-9][0-9][0-9][0-9][0-9][0-9]")
gen t3 = ustrregexs(0) if ustrregexm(t1, "[0-9][0-9]$") 
gen t4 = t2 + "-" + t3
replace t4 = ustrregexra(t4, "[-]", "") if length(t4)==1
replace rg_matricule_cor = t4 if length(rg_matricule_cor)==8
order rg_matricule_cor , a(rg_matricule)
drop t1 t2 t3 t4 

		* Format CNRPS Number:

gen t1 = ustrregexs(0) if ustrregexm(rg_matricule_cor, "\d{10}")
gen t2 = ustrregexs(0) if ustrregexm(t1, "[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]")
gen t3 = ustrregexs(0) if ustrregexm(t1, "[0-9][0-9]$") 
gen t4 = t2 + "-" + t3
replace t4 = ustrregexra(t4, "[-]", "") if length(t4)==1
replace rg_matricule_cor = t4 if length(rg_matricule_cor)==10
order rg_matricule_cor , a(rg_matricule)
drop t1 t2 t3 t4  
/*
replace rg_matricule_cor = "$check_again" if length(rg_matricule_cor) >= 12 | length(rg_matricule_cor) <= 7
*/
drop rg_matricule
rename rg_matricule_cor rg_matricule

		* Nom de l'entreprise:
gen firmname_cor = firmname
/*
replace firmname_cor = "$check_again" if firmname == "https://www.facebook.com/search/top?q=ol%c3%a9a%20amiri"
replace firmname_cor = "$check_again" if firmname == "suarl"
replace firmname_cor = "$check_again" if firmname == "sarl"
replace firmname_cor = "$check_again" if firmname == "tataouine"

*/
order firmname_cor, a(firmname)
drop firmname 
rename firmname_cor firmname 

		* Adresse de l'entreprise:
gen rg_adresse_cor = ustrlower(rg_adresse) 
/*
replace rg_adresse_cor = "$check_again" if rg_adresse_cor == "17"
replace rg_adresse_cor = "$check_again" if rg_adresse_cor == "rte saltnia, km 5"
replace rg_adresse_cor = "$check_again" if rg_adresse_cor == "rue new ton"
replace rg_adresse_cor = "$check_again" if rg_adresse_cor == "rue mohamed jamoussi"

*/
order rg_adresse_cor, a(rg_adresse)
drop rg_adresse 
rename rg_adresse_cor rg_adresse
        * Site web de l'entreprise:

gen rg_siteweb_corr = rg_siteweb
/*
replace rg_siteweb_corr = "$check_again" if rg_siteweb_corr == "zi mornag"
replace rg_siteweb_corr = "$check_again" if rg_siteweb_corr == "ben arous"
replace rg_siteweb_corr = "$check_again" if rg_siteweb_corr == "ben arous"
replace rg_siteweb_corr = "$check_again" if rg_siteweb_corr == "facebook.comtinhinansac"
replace rg_siteweb_corr = "$not_know" if rg_siteweb_corr == "ksibet el mediouni"
replace rg_siteweb_corr = " " if rg_siteweb_corr == "pas de site"
replace rg_siteweb_corr = "$check_again" if rg_siteweb_corr == "fb:rahmatabletop"
replace rg_siteweb_corr = "$check_again" if rg_siteweb_corr == "gouvernorat de nabeul"
replace rg_siteweb_corr = "$check_again" if rg_siteweb_corr == "les doigts d'or keffois"
replace rg_siteweb_corr = "$check_again" if rg_siteweb_corr == "facebook.comol%c3%a9a-amiri-113583540352584"

*/ 
replace rg_siteweb_corr = ustrregexra( rg_siteweb_corr ,"https://","")
replace rg_siteweb_corr = ustrregexra( rg_siteweb_corr ,"/","")
replace rg_siteweb_corr = ustrregexra( rg_siteweb_corr ,"http:","")
replace rg_siteweb_corr = ustrregexra( rg_siteweb_corr ,"www.","")


order rg_siteweb_corr, a(rg_siteweb)
drop rg_siteweb
rename rg_siteweb_corr rg_siteweb
/*
       * chiffre d'affaire 2018
gen ca_2018_cor = ca_2018
replace ca_2018_cor = "$check_again"  if ca_2018_cor ==0 & date_created < 01/01/2019

order ca_2018_cor, a(ca_2018)
drop ca_2018
rename ca_2018_cor ca_2018
       * chiffre d'affaire 2019
	   
gen ca_2019_cor = ca_2019
replace ca_2019_cor = "$check_again"  if ca_2018_cor ==0 & date_created < 01/01/2020

order ca_2019_cor, a(ca_2019)
drop ca_2019
rename ca_2019_cor ca_2019
	   * chiffre d'affaire 2020
gen ca_2020_cor = ca_2020
replace ca_2020_cor = "$check_again"  if ca_2018_cor ==0 & date_created < 01/01/2021

count if ca_2018_cor ==0 & ca_2019_cor==0 & ca_2020_cor==0
	
order ca_2020_cor, a(ca_2020)
drop ca_2020
rename ca_2020_cor ca_2020

*/

 *Réseau  social de l'entreprise:

gen rg_media_cor = rg_media

replace rg_media_cor = "https://www.facebook.com/Rissala.Kids.Farm/" if rg_media_cor == "rissala kids farm"
replace rg_media_cor = "https://www.facebook.com/tresors.naturels.tunisie/" if rg_media_cor == "laboratoire trésors naturels"
replace rg_media_cor = "https://www.facebook.com/aabacti/" if rg_media_cor == "bacteriolab"
replace rg_media_cor = "https://www.facebook.com/halfawin/" if rg_media_cor == "www,facebook,com/halfawin,7"


replace rg_media_cor = " " if rg_media_cor == "aucun pour le moment"
/*
replace rg_media_cor = "$check_again" if rg_media_cor == "presert"
replace rg_media_cor = "$check_again" if rg_media_cor == "siliana"


*/
replace rg_media_cor = ustrregexra( rg_media_cor ,"https://","")
replace rg_media_cor = ustrregexra( rg_media_cor ,"http:","")


order rg_media_cor, a(rg_media)
drop rg_media
rename rg_media_cor rg_media

       * Capital social de l'entreprise
/*
gen rg_capital_cor = rg_capital

replace rg_capital_cor = "$check_again"  if length(rg_capital) =< 4
replace rg_capital_cor = "$check_again"  if length(rg_capital) >= 7
replace rg_capital_cor = "$check_again"  if rg_capital == "8.88888922661e+16"
*/

***********************************************************************
* 	PART 3:  Check again variables	  			
**************************************************************
replace questions_needing_check = "firmname" if id_plateforme == 987
replace needs_check = 1 if id_plateforme == 987
replace questions_needing_check = "rg_capital" if id_plateforme == 990
replace needs_check = 1 if id_plateforme == 990
replace questions_needing_check = "rg_emailpdg" if id_plateforme == 991
replace needs_check = 1 if id_plateforme == 991
replace questions_needing_check = "rg_capital" if id_plateforme == 993
replace needs_check = 1 if id_plateforme == 993
replace questions_needing_check = "rg_adresse" if id_plateforme == 995
replace needs_check = 1 if id_plateforme == 995 
replace questions_needing_check = "firmname" if id_plateforme == 1003
replace needs_check = 1 if id_plateforme == 1003
replace questions_needing_check = "rg_capital" if id_plateforme == 1005
replace needs_check = 1 if id_plateforme == 1005
replace questions_needing_check = "rg_nom_rep" if id_plateforme == 1008
replace needs_check = 1 if id_plateforme == 1008
replace questions_needing_check = "rg_capital" if id_plateforme == 1013
replace needs_check = 1 if id_plateforme == 1013
replace questions_needing_check = "firmname" if id_plateforme == 1019
replace needs_check = 1 if id_plateforme == 1019
replace questions_needing_check = "rg_capital" if id_plateforme == 1020
replace needs_check = 1 if id_plateforme == 1020
replace questions_needing_check = "rg_siteweb" if id_plateforme == 1021
replace needs_check = 1 if id_plateforme == 1021
replace questions_needing_check = "rg_siteweb" if id_plateforme == 1030
replace needs_check = 1 if id_plateforme == 1030
replace questions_needing_check = "rg_capital" if id_plateforme == 1031
replace needs_check = 1 if id_plateforme == 1031
replace questions_needing_check = "rg_capital" if id_plateforme == 1032
replace needs_check = 1 if id_plateforme == 1032
replace questions_needing_check = "rg_media" if id_plateforme == 1034
replace needs_check = 1 if id_plateforme == 1034
replace questions_needing_check = "rg_capital" if id_plateforme == 1035
replace needs_check = 1 if id_plateforme == 1035
replace questions_needing_check = "rg_siteweb/firmname" if id_plateforme == 1036
replace needs_check = 1 if id_plateforme == 1036
replace questions_needing_check = "rg_capital/rg_siteweb/rg_telrep/rg_telpdg" if id_plateforme == 1037
replace needs_check = 1 if id_plateforme == 1037
replace questions_needing_check = "firmname" if id_plateforme == 1039
replace needs_check = 1 if id_plateforme == 1039
replace questions_needing_check = "rg_capital" if id_plateforme == 1043
replace needs_check = 1 if id_plateforme == 1043
replace questions_needing_check = "firmname" if id_plateforme == 1054
replace needs_check = 1 if id_plateforme == 1054
replace questions_needing_check = "firmname" if id_plateforme == 1057
replace needs_check = 1 if id_plateforme == 1057
replace questions_needing_check = "rg_capital" if id_plateforme == 1063
replace needs_check = 1 if id_plateforme == 1063
replace questions_needing_check = "rg_capital" if id_plateforme == 1068
replace needs_check = 1 if id_plateforme == 1068
replace questions_needing_check = "rg_siteweb" if id_plateforme == 1071
replace needs_check = 1 if id_plateforme == 1071
replace questions_needing_check = "rg_capital" if id_plateforme == 1073
replace needs_check = 1 if id_plateforme == 1073
replace questions_needing_check = "rg_capital" if id_plateforme == 1074
replace needs_check = 1 if id_plateforme == 1074
replace questions_needing_check = "rg_telpdg" if id_plateforme == 1075
replace needs_check = 1 if id_plateforme == 1075
replace questions_needing_check = "rg_telpdg" if id_plateforme == 1083
replace needs_check = 1 if id_plateforme == 1083
replace questions_needing_check = "rg_telpdg" if id_plateforme == 1085
replace needs_check = 1 if id_plateforme == 1085

***********************************************************************
* 	PART 3:  Replace string with numeric values		  			
***********************************************************************

***********************************************************************
* 	PART 4:  Convert string to numerical variaregises	  			
***********************************************************************
local destrvar "rg_fte rg_fte_femmes id_plateforme ca_2018 ca_2019 ca_2020 ca_exp2018 ca_exp2019 ca_exp2020"
foreach x of local destrvar { 
destring `x', replace
}

***********************************************************************
* 	PART 5:  Convert problematic values for open-ended questions  			
***********************************************************************

***********************************************************************
* 	PART 6:  Traduction reponses en arabe au francais		  			
***********************************************************************


***********************************************************************
* 	PART 7: 	Rename and homogenize the observed values		  			
***********************************************************************


***********************************************************************
* 	PART 8:  Identify duplicates (for removal see regis_generate)
***********************************************************************
	* formating the variables for whcih we check duplicates
format firmname rg_emailrep rg_emailpdg %-35s
format id_plateforme %9.0g
sort firmname
	
	* id_plateform
duplicates report id_plateform

	* email
duplicates report rg_emailrep
duplicates report rg_emailpdg
duplicates tag rg_emailpdg, gen(dup_emailpdg)

	* firmname	
duplicates report firmname
duplicates tag firmname, gen(dup_firmname)


***********************************************************************
* 	PART 10:  autres / miscallaneous adjustments
***********************************************************************
/*
	* correct the response categories for moyen de communication
replace moyen_com = "site institution gouvernmentale" if moyen_com == "site web d'une autre institution gouvernementale" 
replace moyen_com = "bulletin d'information giz" if moyen_com == "bulletin d'information de la giz"

	* correct wrong response categories for subsectors
replace subsector = "industries chimiques" if subsector == "industrie chimique"
*/

***********************************************************************
* 	PART:  Test logical values		  			
***********************************************************************
	* In Tunisia, SCA and SA must have a minimum of 5000 TND of capital social
		*All values having a too small capital social (less than 100)
/*
replace capitalsocial_corr = "$check_again" if capitalsocial_corr == "0"
replace capitalsocial_corr = "$check_again" if capitalsocial_corr == "o"
destring capitalsocial_corr, replace
*/

***********************************************************************
* 	Save the changes made to the data		  			
***********************************************************************
cd "$regis_intermediate"
save "regis_inter", replace


***********************************************************************
* 	Export an excel sheet with needs_check variables  			
***********************************************************************


export excel id_plateforme needs_check questions_needing_check semaine etat programme treatment rg_nom_rep rg_position_rep rg_telrep rg_emailrep rg_telpdg rg_emailpdg rg_siteweb rg_media firmname rg_adresse codepostal id_admin id_admin_correct date_created rg_legalstatus rg_codedouane rg_matricule rg_fte rg_fte_femmes rg_capital autres ca_2018 ca_exp2018 ca_2019 ca_exp2019 ca_2020 ca_exp2020 moyenneca moyennecaexport conditioncaetcaexport conditioncaoucaexport moyen_com rg_confidentialite rg_partage_donnees rg_enregistrement_coordonnees dateinscription commentairesequipegiz commentairesequipemsb date_creation_string date_inscription_string dup_emailpdg dup_firmname subsector rg_gender_rep using "fiche_correction", firstrow(variables)

