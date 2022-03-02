***********************************************************************
* 			baseline generate									  	  
***********************************************************************
*																	    
*	PURPOSE: generate baseline variables				  							  
*																	  
*																	  
*	OUTLINE:														  
*	1) Sum up points of info questions
* 	2) Indices
*
*																	  															      
*	Author:  	Teo Firpo & Florian Muench & Kais Jomaa							  
*	ID variaregise: 	id_plateforme (example: 777)			  					  
*	Requires: bl_inter.dta 	  								  
*	Creates:  bl_inter.dta			                          
*																	  
***********************************************************************
* 	PART 1:  Sum points in info questions 			
***********************************************************************

use "${bl_intermediate}/bl_inter", clear
/*
g dig_con2 = 0 
replace dig_con2 = 1 if dig_con2_correct
lab var dig_con2 "Correct response to question about digital markets"

g dig_con4 = 0
replace dig_con4 = 1 if dig_con4_rech == 1
lab var dig_con4 "Correct response to question about online ads"

g dig_con6_score = 0
replace dig_con6_score = dig_con6_score + 0.33 if dig_con6_referencement_payant == 1
lab var dig_con6_score "Score on question about Google Ads"

g dig_presence_score = 0
replace dig_presence_score = 0.33 if dig_presence1 == 1
replace dig_presence_score = dig_presence_score + 0.33 if dig_presence2 == 1
replace dig_presence_score = dig_presence_score + 0.33 if dig_presence3 == 1
lab var dig_presence_score "Score on question about online presence channels"

g dig_presence3_exscore = 0
replace dig_presence3_exscore = 0.125 if dig_presence3_ex1 == 1
lab var dig_presence3_exscore "Score on examples of digital channels used"


**********************************************************************
* 	PART 2:  Additional variables
***********************************************************************

	* Calculate export revenues, digital revenues and profits as percentage of total revenues
g exp_per = compexp_2020/comp_ca2020
lab var exp_per "Export revenues as percentage of total revenues"


	* Calculate variables as percentage of employees: 
	
g dig_mar_res_per =  dig_marketing_respons/fte
lab var dig_mar_res_per "FTEs working on digital marketing as percentage"



** NEED TO ADD FTES TO CREATE dig_marketing_respons and expprepres_per as % of FTEs

	* Bring together exp_pays_avant21 and exp_pays_21
	
g exp_pays_all = exp_pays_avant21 + exp_pays_21


**********************************************************************
* 	PART 3:  Index calculation based on z-score		
***********************************************************************

calculation of indeces is based on Kling et al. 2007 and adopted from Mckenzie et al. 2018
JDE pre-analysis publication:
1: calculate z-score for each individual outcome
2: average the z-score of all individual outcomes --> this is the index value
	--> implies: no absolute evaluation but relative to all other firms
	--> requires: firms w/o missing values
3: average the three index values to get the QI index for firms
	--> implies: same weight for all three dimensions
*/
*Definition of all variables that are being used in index calculation*
local allvars man_hr_obj man_hr_feed man_pro_ano man_fin_enr man_fin_profit man_fin_per man_mark_prix man_mark_div man_mark_clients man_mark_offre man_mark_pub exp_pra_foire exp_pra_sci exp_pra_rexp exp_pra_cible exp_pra_mission exp_pra_douane exp_pra_plan expprep_norme exprep_inv exprep_couts exp_pays exp_pays_principal exp_afrique

*IMPORTANT MODIFICATION: Missing values, Don't know, refuse or needs check answers are being transformed to zeros*
foreach var of local  allvars {
	replace `var' = 0 if `var' == .
	replace `var' = 0 if `var' == -999
	replace `var' = 0 if `var' == -888
	replace `var' = 0 if `var' == -777
	replace `var' = 0 if `var' == -1998
	replace `var' = 0 if `var' == -1776 
	replace `var' = 0 if `var' == -1554
	
}

	* calculate z-score for each individual outcome
	* write a program calculates the z-score
	* capture program drop zscore
	
program define zscore /* opens a program called zscore */
	sum `1'
	gen `1'z = (`1' - r(mean))/r(sd)   /* new variable gen is called --> varnamez */
end

	* calculate z score for all variables that are part of the index
	// removed dig_marketing_respons, dig_service_responsable and expprepres_per bcs we don't have fte data without matching (& abs value doesn't make sense)
local mngtvars man_hr_obj man_hr_feed man_pro_ano man_fin_enr man_fin_profit man_fin_per 
local markvars man_mark_prix man_mark_div man_mark_clients man_mark_offre man_mark_pub 
local exportmngt exp_pra_foire exp_pra_sci exp_pra_rexp exp_pra_cible exp_pra_mission exp_pra_douane exp_pra_plan 
local exportprep expprep_norme exprep_inv exprep_couts exp_pays exp_pays_principal exp_afrique 
local exportcombined exp_pra_foire exp_pra_sci exp_pra_rexp exp_pra_cible exp_pra_mission exp_pra_douane exp_pra_plan expprep_norme exprep_inv exprep_couts exp_pays exp_pays_principal exp_afrique


foreach z in mngtvars markvars exportmngt exportprep exportcombined{
	foreach x of local `z'  {
			zscore `x' 
		}
}	

		* calculate the index value: average of zscores 

egen mngtvars = rowmean(man_hr_objz man_hr_feedz man_pro_anoz man_fin_enrz man_fin_profitz man_fin_perz)
egen markvars = rowmean(eman_mark_prixz man_mark_divz man_mark_clientsz man_mark_offrez man_mark_pubz )
egen exportmngt = rowmean(exp_pra_foirez exp_pra_sciz exp_pra_rexpz exp_pra_ciblez exp_pra_missionz exp_pra_douanez exp_pra_planz)
egen exportprep = rowmean(expprep_normez exprep_invz exprep_coutsz exp_paysz exp_pays_principalz exp_afriquez)
egen exportcombined = rowmean(exp_pra_foirez exp_pra_sciz exp_pra_rexpz exp_pra_ciblez exp_pra_missionz exp_pra_douanez exp_pra_planz expprep_normez exprep_invz exprep_coutsz exp_paysz exp_pays_principalz exp_afriquez)

label var mngtvars   "Management practices index"
label var markvars "Marketing practices index"
label var exportmngt "Export management index"
label var exportprep "Export readiness index"
label var exportcombined "Combined export practices index"



//drop scalar_issue



**************************************************************************
* 	PART 4: Create sum of scores of indices (not zscores) for comparison		  										  
**************************************************************************

egen raw_mngtvars = rowtotal(`mngtvars')

egen raw_markvars = rowtotal(`markvars')

egen raw_exportmngt = rowtotal(`exportmngt')

egen raw_exportprep = rowtotal(`exportprep')

egen raw_exportcombined = rowtotal(`exportcombined')

label var raw_mngtvars   "Management practices raw index"
label var raw_markvars "Marketing practices raw index"
label var raw_exportmngt "Export management raw index"
label var raw_exportprep "Export readiness raw index"
label var raw_exportcombined "Combined export practices raw index"



tempvar Sector
encode sector, gen(`Sector')
drop sector
rename `Sector' sector
lab values sector sector_name


format %-25.0fc *sector
/*
***********************************************************************
* 	PART 2: factor variable gender 			  										  
***********************************************************************
label define sex 1 "female" 0 "male"
tempvar Gender
encode rg_gender, gen(`Gender')
drop rg_gender
rename `Gender' rg_gender_rep
replace rg_gender = 0 if rg_gender == 2
lab values rg_gender sex

tempvar Genderpdg
encode rg_sex_pdg, gen(`Genderpdg')
drop rg_sex_pdg
rename `Genderpdg' rg_gender_pdg
replace rg_gender_pdg = 0 if rg_gender_pdg == 2
lab values rg_gender_pdg sex

***********************************************************************
* 	PART 3: factor variable onshore 			  										  
***********************************************************************
lab def onshore 1 "résidente" 0 "non résidente"
encode rg_onshore, gen(rg_resident)
replace rg_resident = 0 if rg_resident == 1
replace rg_resident = 1 if rg_resident == 2
drop rg_onshore
lab val rg_resident onshore
lab var rg_resident "HQ en Tunisie"

***********************************************************************
* 	PART 4: factor variable produit exportable		  										  
***********************************************************************
lab def exportable 1 "produit exportable" 0 "produit non exportable"
encode rg_exportable, gen(rg_produitexp)
replace rg_produitexp = 0 if rg_produitexp == 1
replace rg_produitexp = 1 if rg_produitexp == 2
drop rg_exportable
lab val rg_produitexp exportable
lab var rg_produitexp "Entreprise pense avoir un produit exportable"

***********************************************************************
* 	PART 5: factor variable intention exporter			  										  
***********************************************************************
lab def intexp 1 "intention export" 0 "pas d'intention à exporter"
encode rg_intexp, gen(rg_intention)
replace rg_intention = 0 if rg_intention == 1
replace rg_intention = 1 if rg_intention == 2
drop rg_intexp
lab val rg_intention intexp
lab var rg_intention "Entreprise a l'intention d'exporter dans les prochains 12 mois"

***********************************************************************
* 	PART 6: dummy une opération d'export			  										  
***********************************************************************
lab def oper_exp 1 "Opération d'export" 0 "Pas d'opération d'export"
encode rg_export, gen(rg_oper_exp)
replace rg_oper_exp = 0 if rg_oper_exp == 1
replace rg_oper_exp = 1 if rg_oper_exp == 2
drop rg_export
lab val rg_oper_exp oper_exp
lab var rg_oper_exp "Entreprise a realisé une opération d'export"

***********************************************************************
* 	PART 7: factor variable export status		  										  
***********************************************************************
encode rg_exportstatus, gen(rg_expstatus)
drop rg_exportstatus
lab var rg_expstatus "Régime d'export de l'entreprise"


***********************************************************************
* 	PART 8: age
***********************************************************************
gen rg_age = round((td(30nov2021)-date_created)/365.25,2)
order rg_age, a(date_created)

***********************************************************************
* 	PART 8: dummy site web ou réseau social
***********************************************************************
gen presence_enligne = (rg_siteweb != "" | rg_media != ""), b(rg_siteweb)
lab def enligne 1 "présente enligne" 0 "ne pas présente enligne"
lab values presence_enligne enligne

***********************************************************************
* 	PART 10: eligibiliy dummy
***********************************************************************
gen eligible = (id_admin_correct == 1 & rg_resident == 1 & rg_fte >= 6 & rg_fte <= 199 & rg_produitexp == 1 & rg_intention == 1 & rg_oper_exp == 1 & rg_age>=2)
lab def eligible 1 "éligible" 0 "inéligible"
lab val eligible eligible

		* eligible if matricule fiscal is corrected
gen eligible_sans_matricule = (rg_resident == 1 & rg_fte >= 6 & rg_fte <= 199 & rg_produitexp == 1 & rg_intention == 1 & rg_oper_exp == 1 & rg_age>=2)
lab def eligible2 1 "éligible sans matricule" 0 "inéligible sans matricule"
lab val eligible_sans_matricule eligible2

		* alternative definition of eligibility
			* intention to export rather than one export operation
gen eligible_alternative = (rg_resident == 1 & rg_fte >= 6 & rg_fte <= 199 & rg_produitexp == 1 & rg_intention == 1 & rg_age>=2)
lab val eligible_alternative eligible

		* eligibility including also no webpage or social network
gen eligible_presence_enligne = (presence_enligne == 1 & id_admin_correct == 1 & rg_resident == 1 & rg_fte >= 6 & rg_fte <= 199 & rg_produitexp == 1 & rg_intention == 1 & rg_oper_exp == 1 & rg_age>=2)
lab def eligible_enligne 1 "éligible avec présence en ligne" 0 "éligible sans présence en ligne"
lab val eligible_presence_enligne eligible_enligne


***********************************************************************
* 	PART 10: Surplus contact information from registration
***********************************************************************
	* show all the different duplicates that are also eligible (requires running gen.do first)
*browse if dup_firmname > 0 | dup_emailpdg > 0 & eligible_sans_matricule == 1

	* telephone numbers

gen rg_telephone2 = ""
replace rg_telephone2 = "21698218074" if id_plateforme == 886
replace rg_telephone2 = "71380080" if id_plateforme == 190

		
	* email adresses
gen rg_email2 = ""
replace rg_email2 = "intissarmersni1987@gmail.com" if id_plateforme == 777
replace rg_email2 = "anoha.consulting@gmail.com" if id_plateforme == 886
replace rg_email2 = "karim.architecte@yahoo.fr" if id_plateforme == 673
replace rg_email2 = "ccf.jeridi@planet.tn" if id_plateforme == 630

	
	* physical adress
gen rg_adresse2 = ""
replace rg_adresse2 = "av ahmed mrad, cité des pins boumhel bassatine 2097" if id_plateforme == 497
replace rg_adresse2 = "rue de l'usine charguia2" if id_plateforme == 768
replace rg_adresse2 = "000, zi ettaamir, sousse 4003" if id_plateforme == 748


	* Other corrections
replace rg_position_rep= "senior consultant" if id_plateforme == 886



	* drop duplicates
drop if id_plateforme == 357
drop if id_plateforme == 610
drop if id_plateforme == 133


*Notes: 
*id_plateforme 398/414 are not duplicates (different companies belong to the same group)
*id_plateforme 503/515 are not duplicates (different companies belong to the same group)
*id_plateforme 658/675 are not duplicates (different companies belong to the same group)
*id_plateforme 205/274 are not duplicates (missing values)


***********************************************************************
* 	Save the changes made to the data		  			
***********************************************************************
	* set export directory
cd "$bl_intermediate"

	* export file with potentially eligible companies
gen check = 0
replace check = 1 if id_admin_correct == 0 | presence_enligne == 0

preserve
	keep if eligible_sans_matricule == 1
	rename rg_siteweb site_web 
	rename rg_media reseaux_sociaux
	rename id_admin matricule_fiscale
	rename rg_resident onshore
	rename rg_fte employes
	rename rg_produitexp produit_exportable
	rename rg_intention intention_export
	rename rg_oper_exp operation_export
	rename date_created_stÏr date_creation
	rename firmname nom_entreprise
	rename rg_codedouane code_douane
	rename rg_matricule matricule_cnss
	order nom_entreprise date_creation matricule_fiscale code_douane matricule_cnss operation_export 
	local varlist "nom_entreprise date_creation matricule_fiscale code_douane matricule_cnss operation_export site_web reseaux_sociaux onshore employes produit_exportable intention_export"
	export excel `varlist' using ecommerce_eligibes_pme if eligible_sans_matricule == 1, firstrow(var) replace
restore

*/
*/
	* save dta file
cd "$bl_intermediate"
save "bl_inter", replace
