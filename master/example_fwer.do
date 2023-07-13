***********************************************************************
* 			Master regression analysis	- RCT female export consortia			  
***********************************************************************
*																	  
*	PURPOSE: Create regression table for one outcome family including p-and q-values												  
*
*														  
*	Authors:  	Florian Münch						    
*	ID variable: id_platforme		  					  
*	Requires:  	consortium_final.dta

***********************************************************************
* 	Part 0: 	set the stage		  
***********************************************************************
		* please replace with directory on your computer
use "${master_final}/sample_clarke", clear

		* declare panel data
xtset id_plateforme surveyround, delta(1)


***********************************************************************
* 	PART 1: Correct for MHT - FWER - Entrepreneurial Confidence
***********************************************************************

		* only ITTs
rwolf2 ///
	(reg genderi treatment l.genderi i.missing_bl_genderi i.strata_final, cluster(id_plateforme)) /// ITT first variable
	 (reg female_efficacy treatment l.female_efficacy i.missing_bl_female_efficacy i.strata_final, cluster(id_plateforme)) /// ITT second variable
	 (reg female_loc treatment l.female_loc i.missing_bl_female_loc i.strata_final, cluster(id_plateforme)), /// ITT third variable
	indepvars(treatment, treatment, treatment) ///
	   seed(110723) reps(999) usevalid strata(strata_final) verbose
	   
	  * ITTs, IV ToT 
rwolf2 ///
	(reg genderi treatment l.genderi i.missing_bl_genderi i.strata_final, cluster(id_plateforme)) /// ITT first variable
	(ivreg2 genderi l.genderi i.missing_bl_genderi i.strata_final (take_up = treatment), cluster(id_plateforme)) /// TOT first variable
	 (reg female_efficacy treatment l.female_efficacy i.missing_bl_female_efficacy i.strata_final, cluster(id_plateforme)) /// ITT second variable
	 (ivreg2 female_efficacy l.female_efficacy i.missing_bl_female_efficacy i.strata_final (take_up = treatment), cluster(id_plateforme)) /// TOT second variable
	 (reg female_loc treatment l.female_loc i.missing_bl_female_loc i.strata_final, cluster(id_plateforme)) /// ITT third variable
	 (ivreg2 female_loc l.female_loc i.missing_bl_female_loc i.strata_final (take_up = treatment), cluster(id_plateforme)), /// TOT third variable
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up) ///
	   seed(110723) reps(999) usevalid strata(strata_final)

	   
