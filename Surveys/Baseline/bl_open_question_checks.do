***********************************************************************
* 			baseline survey checks of string/open questions
***********************************************************************
*																	   
*	PURPOSE: 		check whether string answer to open questions are 														 
*					logical
*	OUTLINE:														  
*	1)				Create wordfile for export		  		  			
*	2)  			Identify vars that should be numerical but aren't						 
*	3)  			Check for & visualise duplicates
*	4)  			Open question variables							  
*																	  
*	ID variable: 	id_plateforme (example: 373)			  					  
*	Requires: bl_inter.dta & bl_checks_survey_progress.do 	  
*	Creates:  bl_inter.dta			  
*																	  
***********************************************************************
* 	PART 1:  Create word file for export		  			
***********************************************************************
	* import file
use "${bl_intermediate}/bl_inter", clear

	* set directory to checks folder
cd "$bl_checks"

	* create word document
putdocx clear
putdocx begin
putdocx paragraph
putdocx text ("Quality checks variables: baseline consortias training"), bold

***********************************************************************
* 	PART 2:  Identify variables that should be numerical but aren't	  			
***********************************************************************
<<<<<<< Updated upstream
local numvars ca_2018 ca_exp2018 ca_2019 ca_exp2019 ca_2020 ca_exp2020 ca_2021 ca_exp_2021 profit_2021 ca_2020_cor ca_exp2020_cor ca_2019_cor ca_exp2019_cor ca_2018_cor ca_exp_2018_cor exprep_inv inno_rd
=======

local numvars inno_rd net_nb_fam net_nb_dehors net_time exprep_inv exp_pays ca_2021 ca_exp_2021 comp_benefice2021 ca_2020 ca_2019 ca_2018  ca_exp2020  ca_exp2019 ca_exp2018  ca_2020_cor car_empl1  car_empl2 car_empl3 car_empl4 car_empl5  famille2
>>>>>>> Stashed changes

local correct_vars 
local incorrect_vars 

foreach v of local numvars {
	capture confirm numeric variable `v'
                if !_rc {
                        local correct_vars `correct_vars' `v'
                }
                else {
                        local incorrect_vars `incorrect_vars'  `v'
                }
}

local list_vars "`incorrect_vars'"

putdocx paragraph
putdocx text ("String vars that should be numerical but aren't: `list_vars' –––> go back to bl_correct and fix these until they're numerical'") 
putdocx paragraph


***********************************************************************
* 	PART 3:  Check for & visualise duplicates		  			
***********************************************************************

		* put all variables to for which we want to check for duplicates into a local
local dupcontrol id_plateforme 

		* generate a variable = 1 if the observation of the variable has a duplicate
foreach x of local dupcontrol {
gen duplabel`x' = .
duplicates tag `x', gen(dup`x')
replace duplabel`x' = id_plateforme if dup`x' > 0

}
		* visualise and save the visualisations

/*alternative code for jitter dot plots instead of bar plots which allow to identify the id of the duplicate response:
gen duplabel = .
replace duplabel = id_plateforme if dup_id_admin > 0 | dup_firmname > 0 | dup_rg_nom_rep > 0 | dup_rg_telrep > 0 | dup_rg_emailrep > 0 | dup_rg_telpdg > 0 | dup_rg_emailpdg > 0
stripplot id_plateforme, over(dup_firmname) jitter(4) vertical mlabel(duplabel) /* alternative: scatter id_plateforme dup_firmname, jitter(4) mlabel(duplabel) */
code for bar plot:
gr bar (count), over(dup_`x') ///
		name(`x') ///
		title(`x') ///
		ytitle("Nombre des observations") ///
		blabel(bar)
*/		

foreach x of local dupcontrol {
stripplot id_plateforme, over(dup`x') jitter(4) vertical  ///
		name(`x', replace) ///
		title(`x') ///
		ytitle("ID des observations") ///
		mlabel(duplabel`x')
}
		* combine all the graphs into one figure
gr combine `dupcontrol'
gr export duplicates.png, replace
		
		* put the figure into the pdf
putdocx paragraph, halign(center)
putdocx image duplicates.png

		* indicate to RA's where to write code to search & remove duplicates
putdocx paragraph
putdocx text ("Go to do-file 'bl_correct' part 10 'Identify duplicates' to examine & potentially remove duplicates manually/via code."), bold
putdocx pagebreak

***********************************************************************
* 	PART 3:  Open question variables		  			
***********************************************************************/*
		* define all the variables where respondent had to enter text

local open_questions ident_base_respondent ident_repondent_position entr_idee produit1 produit2 produit3 exp_pays_principal id_admin att_adh6 att_strat4 att_cont5 support7
				
		* export all the variables into a word document
foreach x of local open_questions {
putdocx paragraph, halign(center)
tab2docx `x'
putdocx pagebreak
}

	
***********************************************************************
* 	End:  save dta, word file		  			
***********************************************************************
	* word file
cd "$bl_checks"
putdocx save "bl-checks-question-ouvertes.docx", replace
	* restore all the observations


