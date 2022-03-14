***********************************************************************
* 			baseline index calculation									  	  
***********************************************************************
*																	    
*	PURPOSE: generate index variables				  							  
*																	  
*																	  
*	OUTLINE:														  
*	1) Define variables used in index calculation
* 	2) Modify missing values as well as don't know and refuse to zeros
*	3) Create z-score indices
*	4) Create raw indices
*
*																	  															      
*	Author:  	Fabian Scheifele						  
*	ID variaregise: 	id_plateforme (example: 777)			  					  
*	Requires: bl_inter.dta 	  								  
*	Creates:  bl_inter.dta			      
/* 
**********************************************************************
* 	PART 1:  Index calculation based on z-score		
***********************************************************************
use "${bl_intermediate}/bl_inter", clear

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
local allvars man_hr_obj man_hr_feed man_pro_ano man_fin_enr man_fin_profit man_fin_per man_mark_prix man_mark_div man_mark_clients man_mark_offre man_mark_pub exp_pra_foire exp_pra_sci exp_pra_rexp exp_pra_cible exp_pra_mission exp_pra_douane exp_pra_plan expprep_norme exprep_inv exprep_couts exp_pays 

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
local exportprep expprep_norme exprep_inv exprep_couts exp_pays exp_afrique 
local exportcombined exp_pra_foire exp_pra_sci exp_pra_rexp exp_pra_cible exp_pra_mission exp_pra_douane exp_pra_plan expprep_norme exprep_inv exprep_couts exp_pays exp_afrique


foreach z in mngtvars markvars exportmngt exportprep{
	foreach x of local `z'  {
			zscore `x' 
		}
}	

		* calculate the index value: average of zscores 

egen mngtvars = rowmean(man_hr_objz man_hr_feedz man_pro_anoz man_fin_enrz man_fin_profitz man_fin_perz)
egen markvars = rowmean(man_mark_prixz man_mark_divz man_mark_clientsz man_mark_offrez man_mark_pubz )
egen exportmngt = rowmean(exp_pra_foirez exp_pra_sciz exp_pra_rexpz exp_pra_ciblez exp_pra_missionz exp_pra_douanez exp_pra_planz)
egen exportprep = rowmean(expprep_normez exprep_invz exprep_coutsz exp_paysz)
egen exportcombined = rowmean(exp_pra_foirez exp_pra_sciz exp_pra_rexpz exp_pra_ciblez exp_pra_missionz exp_pra_douanez exp_pra_planz expprep_normez exprep_invz exprep_coutsz exp_paysz)

label var mngtvars   "Management practices index"
label var markvars "Marketing practices index"
label var exportmngt "Export management index"
label var exportprep "Export readiness index"
label var exportcombined "Combined export practices index"
//drop scalar_issue



**************************************************************************
* 	PART 2: Create sum of scores of indices (not zscores) for comparison		  										  
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


/*
tempvar Sector
encode sector, gen(`Sector')
drop sector
rename `Sector' sector
lab values sector sector_name


format %-25.0fc *sector
/*
