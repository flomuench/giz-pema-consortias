***********************************************************************
* 			registration checks of string/open questions
***********************************************************************
*																	   
*	PURPOSE: 		check whether string answer to open questions are 														 
*					logical
*	OUTLINE:														  
*	1)				create wordfile for export		  		  			
*	3)  			open question string variaregises					 
*	4)  			open question numerical variaregises							  
*	5)  			Time and speed test							  
*	6)  			
*																	  
*	ID variaregise: 	id (example: f101)			  					  
*	Requires: regis_inter.dta & regis_checks_survey_progress.do 	  
*	Creates:  regis_inter.dta			  
*																	  
***********************************************************************
* 	PART 1:  create word file for export		  			
***********************************************************************
	* import file
use "${regis_intermediate}/regis_inter", clear

	* set directory to checks folder
cd "$regis_checks"

	* create word document
putdocx begin 
putdocx paragraph
putdocx text ("Quality checks open question variables: registration export consortia des PME femmes"), bold

***********************************************************************
* 	PART 2:  Check for & visualise duplicates		  			
***********************************************************************
		* keep only potentially eligible firms
preserve
*keep if eligibilité == "eligible"
*keep if eligibilité == "eligible" & subsector_corrige == 7 | subsector_corrige == 15 | subsector_corrige == 2 | subsector_corrige == 3 | subsector_corrige == 12 | subsector_corrige == 14

		* put all variables to for which we want to check for duplicates into a local
local dupcontrol id_admin firmname rg_nom_rep rg_telrep rg_emailrep rg_telpdg rg_emailpdg

		* generate a variable = 1 if the observation of the variable has a duplicate
foreach x of local dupcontrol {
gen duplabel`x' = .
duplicates tag `x', gen(dup`x')
replace duplabel`x' = id_plateforme if dup`x' > 0

}
		* visualise and save the visualisations
/*
alternative code for jitter dot plots instead of bar plots which allow to identify the id of the duplicate response:
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
		name(`x') ///
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
putdocx text ("Go to do-file 'regis_correct' part 9 'remove duplicates' to examine & potentially remove duplicates manually/via code."), bold
putdocx pagebreak

***********************************************************************
* 	PART 3:  Open question variables	  			
***********************************************************************
		* sort stable by firmname to identify duplicates by eyeballing based on firmname
sort firmname, stable

		* define all the variables where respondent had to enter text
local regis_open rg_fte rg_fte_femmes date_creation_string date_inscription_string rg_capital rg_position rg_legalstatus rg_siteweb rg_media /// /* firm characteristics */
	   firmname rg_nom_rep rg_telrep rg_telpdg rg_emailrep rg_emailpdg rg_adresse /// /* personal */
	   rg_matricule rg_codedouane /// /* administrative numbers */
	   ca_2018 ca_2019 ca_2020 ca_exp2018 ca_exp2019 ca_exp2020 /* accounting */ 
				
		* export all the variables into a word document
foreach x of local regis_open {
putdocx paragraph, halign(center)
tab2docx `x'
putdocx pagebreak
}



***********************************************************************
* 	End:  save dta, word file		  			
***********************************************************************
	* word file
cd "$regis_checks"
putdocx save "regis-checks-question-ouvertes.docx", replace
	* restore all the observations
restore

