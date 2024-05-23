***********************************************************************
* 			Export database for endline								  *
***********************************************************************
*	PURPOSE: Correct and update contact-information of participants
*																	  
*	OUTLINE: 	PART 1: Import analysis data
*				PART 2: Import pii information
*				PART 3: Export the final excel
*	Author:  	Kais jomaa & Eya Hanefi						    
*	ID variable: id_platforme		  					  
*	Requires: ecommerce_master_final.dta, take_up_ecommerce.xlsx 
*			  web_information.xlsx, midline_contactlist
*	Creates:endline_contactlist.xlsx		



*Part1: Import analysis data 

use "${master_final}/consortium_final", clear

keep id_plateforme treatment pole entr_idee entr_bien produit1 produit2 produit3 take_up take_up_per refus closed desistement_consortium 
sort id_plateforme
quietly by id_plateforme: gen dup = cond(_N==1,0,_n)
drop if dup>1 
drop dup 

* Part2 Import pii information 
preserve 
use "${master_final}/consortium_pii_final", clear
drop if id_plateforme==.
destring id_plateforme,replace
save  "${master_final}/consortium_pii_final", replace 
restore
merge 1:1 id_plateforme using "${master_final}/consortium_pii_final", force 

/*
    Result                           # of obs.
    -----------------------------------------
    not matched                             0
    matched                               176  (_merge==3)
    -----------------------------------------

*/ 
drop eligible date_created code_douane matricule_cnss codepostal _merge comment mothercompany random_number_ml rank 

*Part3 Export the final excel 
export excel "${master_final}/endline_contactlist.xlsx",firstrow(variables) replace
