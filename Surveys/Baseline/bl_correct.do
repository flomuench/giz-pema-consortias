***********************************************************************
* 			consortias baseline survey corrections                    *	
***********************************************************************
*																	    
*	PURPOSE: correct all incoherent responses				  							  
*																	  
*																	  
*	OUTLINE:														  
*	1)		Define non-response categories 		
*   2)		Manually fix wrong answers 	  				  
* 	3) 		Use regular expressions to correct variables
*	4)   	Replace string with numeric values						  
*	5)  	Convert string to numerical variaregises	  				  
*	6)  	Convert problematic values for open-ended questions		  
*	7)  	Traduction reponses en arabe au francais				  
*   8)      Rename and homogenize the observed values                   
*	9)		Import categorisation for opend ended QI questions
*	10)		Remove duplicates
*
*																	  															      
*	Author:  	Florian Muench & Kais Jomaa							  
*	ID variaregise: 	id (example: f101)			  					  
*	Requires: bl_inter.dta 	  								  
*	Creates:  bl_inter.dta			                          
*																	  
***********************************************************************
* 	PART 1:  Define non-response categories  			
***********************************************************************
use "${bl_intermediate}/bl_inter", clear

{
	* replace "-" with missing value
ds, has(type string) 
local strvars "`r(varlist)'"
foreach x of local strvars {
		replace `x' = "" if `x' == "-"
	}
	
scalar not_know    = -999
scalar refused     = -888
scalar check_again = -777

local not_know    = -999
local refused     = -888
local check_again = -777

	* replace, gen, label
gen check = 0
gen questions_needing_checks = ""
gen commentsmsb = ""
*/
}

***********************************************************************
* 	PART 2:  Manually fix wrong answers
***********************************************************************

{
* Needs check
//replace needs_check = 1 if id_plateforme = 572== "a"
//replace needs_check = 1 if id_plateforme = 572 == "aa"


/*
* Questions needing check
*replace questions_needing_check = "investcom_2021/investcom_futur" if id_plateforme==572
*replace questions_needing_check = "exp_pays_21" if id_plateforme==757
*replace questions_needing_check = "comp_benefice2020" if id_plateforme==592
*replace needs_check = 1 if id_plateforme == 592
*replace questions_needing_check = "compexp_2020/comp_ca2020/comp_benefice2020" if id_plateforme==365
*replace questions_needing_check = "dig_revenues_ecom" if id_plateforme==375
replace questions_needing_check = "comp_benefice2020" if id_plateforme == 89
replace needs_check = 1 if id_plateforme == 89



***********************************************************************
* 	PART 3: use regular expressions to correct variables 		  			
***********************************************************************
/* for reference and guidance, regularly these commands are used in this section
gen XXX = ustrregexra(XXX, "^216", "")
gen id_adminrect = ustrregexm(id_admin, "([0-9]){6,7}[a-z]")

*replace id_adminrige = $check_again if id_adminrect == 1
lab def correct 1 "correct" 0 "incorrect"
lab val id_adminrect correct

*/

* Correction des variables investissement
replace investcom_2021 = ustrregexra( investcom_2021,"k","000")
//replace investcom_futur = ustrregexra( investcom_futur,"dinars","")
//replace investcom_futur = ustrregexra( investcom_futur,"dt","")
//replace investcom_futur = ustrregexra( investcom_futur,"k","000")

* Enlever tout les déterminants du nom des produits
{
replace entr_produit1 = ustrregexra( entr_produit1 ,"la ","")
replace entr_produit1 = ustrregexra( entr_produit1 ,"le ","")
replace entr_produit1 = ustrregexra( entr_produit1 ,"les ","")
replace entr_produit1 = ustrregexra( entr_produit1 ,"un ","")
replace entr_produit1 = ustrregexra( entr_produit1 ,"une ","")
replace entr_produit1 = ustrregexra( entr_produit1 ,"des ","")

replace entr_produit2 = ustrregexra( entr_produit2 ,"la ","")
replace entr_produit2 = ustrregexra( entr_produit2 ,"le ","")
replace entr_produit2 = ustrregexra( entr_produit2 ,"les ","")
replace entr_produit2 = ustrregexra( entr_produit2 ,"un ","")
replace entr_produit2 = ustrregexra( entr_produit2 ,"une ","")
replace entr_produit2 = ustrregexra( entr_produit2 ,"des ","")

replace entr_produit3 = ustrregexra( entr_produit3 ,"la ","")
replace entr_produit3 = ustrregexra( entr_produit3 ,"le ","")
replace entr_produit3 = ustrregexra( entr_produit3 ,"les ","")
replace entr_produit3 = ustrregexra( entr_produit3 ,"un ","")
replace entr_produit3 = ustrregexra( entr_produit3 ,"une ","")
replace entr_produit3 = ustrregexra( entr_produit3 ,"des ","")

replace id_base_repondent = ustrregexra( id_base_repondent ,"mme ","")

replace investcom_futur = ustrregexra( investcom_futur ," dinars","")



* Remplacer tout les points par des virgules & Enlever les virgules au niveau des numéros de téléphone



***********************************************************************
* 	PART 4:  Replace string with numeric values		  			
***********************************************************************
{
*Remplacer les textes de la variable investcom_2021
replace investcom_2021 = "100000" if investcom_2021== "100000dt"
replace investcom_2021 = "18000" if investcom_2021== "huit mille dinars"
replace investcom_2021 = "0" if investcom_2021== "zéro"


replace investcom_2021 = "`refused'" if investcom_2021 == "-888"
replace investcom_2021 = "`not_know'" if investcom_2021 == "-999"
replace investcom_2021 = "`not_know'" if investcom_2021 == "لا اعرف"

}

***********************************************************************
* 	PART 5:  Convert string to numerical variabales	  			
***********************************************************************
* local destrvar XX
*foreach x of local destrvar { 
*destring `x', replace
local destrvar investcom_futur investcom_2021 dig_revenues_ecom comp_benefice2020 car_carempl_div1 car_carempl_dive2 car_carempl_div3 compexp_2020 comp_ca2020
foreach x of local destrvar {
destring `x', replace
format `x' %25.0fc
}

***********************************************************************
* 	PART 6:  Convert problematic values for open-ended questions  			
***********************************************************************

* Correction de la variable investcom_2021
*replace investcom_2021 = "`check_again'" if investcom_2021== "a"
*replace investcom_2021 = "30000" if investcom_2021== "trente milles dinars"


***********************************************************************
* 	PART 7:  Traduction reponses en arabe au francais		  			
***********************************************************************

*Traduction des produits principaux de l'entreprise
replace entr_produit1 = "Farine à la tomate" if entr_produit1 == "فارينة طماطم"


***********************************************************************
* 	PART 8: 	Rename and homogenize the observed values		  			
***********************************************************************

	* Sectionname
replace entr_produit1 = "céramique"  if entr_produit1=="ciramic"
replace entr_produit1 = "tuiles"  if entr_produit1=="9armoud"
replace entr_produit1 = "dattes"  if entr_produit1=="tmar"
replace entr_produit1 = "maillots de bain"  if entr_produit1=="mayo de bain"


***********************************************************************
* 	PART 9:  Import categorisation for opend ended QI questions
***********************************************************************
{
/*
	* the manually handed categories are in the folder data/AQE/surveys/midline/categorisation/copies
			* q42, q15c5, q18m5, q10n5, q10r5, q21example
local categories "argument-vente source-informations-conformité source-informations-metrologie source-normes source-reglements-techniques verification-intrants-fournisseurs"
foreach x of local categories {
	preserve

	cd "$bl_categorisation"
	
	import excel "${bl_categorisation}/Copie de categories-`x'.xlsx", firstrow clear
	
	duplicates drop id, force

	cd "$bl_intermediate"

	save "`x'", replace

	restore

	merge 1:1 id using `x'
	
	save, replace

	drop if _merge == 2 /* drops all non matched rows from coded categories */
	
	drop _merge
	}
	* format variables

format %-25s q42 q42c q15c5 q18m5 q10n5 q10r5 q21example q15c5c q18m5c q10n5c q10r5c q21examplec

	* visualise the categorical variables
			* argument de vente
codebook q42c /* suggère qu'il y a 94 valeurs uniques doit etre changé */
graph hbar (count), over(q42c, lab(labs(tiny)))
			* organisme de certification
graph hbar (count), over(q15c5c, lab(labs(tiny)))
graph hbar (count), over(q10n5c, lab(labs(tiny)))


	* label variable categories
lab var q42f "(in-) formel argument de vente"
*/
}


***********************************************************************
* 	PART 10:  Convert data types to the appropriate format
***********************************************************************
* Convert string variable to integer variables


***********************************************************************
* 	PART 11:  Identify and remove duplicates 
***********************************************************************

* Dropping duplicates:
{

drop if id_plateforme == 813
	
}

* Correcting the second duplicates:
{
replace id_base_repondent= "sana farjallah" if id_plateforme == 108
replace entr_produit1= "skit solaire connecté réseau,site isolé et pompage solaire" if id_plateforme == 108
replace i= "africa@growatt.pro" if id_plateforme == 108

	* Drop incomplete answers (only once the survey is complete!!!)
	
//keep if complete==1

	* Check remaining duplicates (after manual corrections above)
	
bysort id_plateforme:  gen dup = cond(_N==1,0,_n)	

	// 350 total obs | 239 unique

	* Check which observations are more complete
	
ds, has(type numeric)
local all_nums `r(varlist)'

egen sum_allvars = rowtotal(`all_nums')

	* Drop duplicates that are less complete

bysort id_plateforme: egen max_length = max(sum_allvars)

// Suggestion to check which are duplicates – turn duplicate observations
// that is shorter (ie has fewer answers) into dup==4

replace dup = 4 if dup>0 & sum_allvars<max_length

// you can now sort id_plateforme dup and check if indeed the one coded 4 
// is to be dropped
drop if dup ==4 & attest!=1 & attest2!=1 & acceptezvousdevalidervosré!=1

drop if id_plateforme == 70 & dup == 4
drop if id_plateforme == 82 & dup == 4
drop if id_plateforme == 91 & dup == 4

/*
drop if dup>0 & sum_allvars<max_length

drop dup

bysort id_plateforme:  gen dup = cond(_N==1,0,_n)	
 
keep if dup<2
*/



***********************************************************************
* 	PART 11:  autres / miscellaneous adjustments
***********************************************************************
	* correct the response categories for moyen de communication
*replace moyen_com = "site institution gouvernmentale" if moyen_com == "site web d'une autre institution gouvernementale" 
*replace moyen_com = "bulletin d'information giz" if moyen_com == "bulletin d'information de la giz"

*/
***********************************************************************
* 	Save the changes made to the data		  			
***********************************************************************
cd "$bl_intermediate"
save "bl_inter", replace
