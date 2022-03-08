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
*	Author:  	Fabian Scheifele, Kais Jomaa & Siwar Jakim							  
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
* 	PART 2:  Automatic corrections
***********************************************************************
* 2.1 Remove commas, dots, dt and dinar from numeric vars


*2.2 Turn zero, zéro into 0 for all numeric vars


*2.3 Use strim trim to remove space BETWEEN numbers/characters in accounting variables*


*2.4 Remove linking words like un, une, des,les, from product descriptions




***********************************************************************
* 	PART 3:  Manual correction (by variable not by row)
***********************************************************************
*3.1 Translate arab product names and inno_mot_autre, autresapreciser to french*



*3.2 Manually Transform any remaining "word numerics" to actual numerics 




*3.3 Mark any non-numerical answers to numeric questions as check=1



*3.4 Translate and code entr_idee (Low priority, only at the end of the survey, when more time)



***********************************************************************
* 	EXAMPLE CODE FOR : use regular expressions to correct variables 		  			
***********************************************************************
/* for reference and guidance, regularly these commands are used in this section
gen XXX = ustrregexra(XXX, "^216", "")
gen id_adminrect = ustrregexm(id_admin, "([0-9]){6,7}[a-z]")

*replace id_adminrige = $check_again if id_adminrect == 1
lab def correct 1 "correct" 0 "incorrect"
lab val id_adminrect correct

*/
/*
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
* 	EXAMPLE CODE:  Replace string with numeric values		  			
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
* 	PART 4:  Convert remaining strings to numerical variabales (to be adapted to consortia)	  			
***********************************************************************

***********************************************************************
* 	PART 5:  Highlight problematic, non-sensical values for open-ended questions  			
***********************************************************************

* Correction de la variable investcom_2021
*replace investcom_2021 = "`check_again'" if investcom_2021== "a"
*replace investcom_2021 = "30000" if investcom_2021== "trente milles dinars"


***********************************************************************
* 	PART 6: 	Rename and homogenize the products		  			
***********************************************************************

	* Example
	/*
replace entr_produit1 = "céramique"  if entr_produit1=="ciramic"
replace entr_produit1 = "tuiles"  if entr_produit1=="9armoud"
replace entr_produit1 = "dattes"  if entr_produit1=="tmar"
replace entr_produit1 = "maillots de bain"  if entr_produit1=="mayo de bain"
*/

***********************************************************************
* 	PART 7:  Import categorisation for opend ended QI questions (DONT KNOW YET WHAT TO DO)
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
* 	PART 8:  Convert data types to the appropriate format
***********************************************************************
* 8.1 Convert close ended questions to integers*




* 8.2 Destring remaining numerical vars
* local destrvar XX
*foreach x of local destrvar { 
*destring `x', replace
/*
local destrvar investcom_futur investcom_2021 dig_revenues_ecom comp_benefice2020 car_carempl_div1 car_carempl_dive2 car_carempl_div3 compexp_2020 comp_ca2020
foreach x of local destrvar {
destring `x', replace
format `x' %25.0fc
}
*/


***********************************************************************
* 	PART 9:  Identify and remove duplicates 
***********************************************************************





***********************************************************************
* 	PART 10:  autres / miscellaneous adjustments
***********************************************************************

*/
***********************************************************************
* 	Save the changes made to the data		  			
***********************************************************************
cd "$bl_intermediate"
save "bl_inter", replace
