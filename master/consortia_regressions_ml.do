***********************************************************************
* 			Master analysis/regressions				  
***********************************************************************
*																	  
*	PURPOSE: 	Undertake treatment effect analysis of primary and secondary
*				outcomes as well as sub-group/heterogeneity analyses																	  
*
*													
*																	  
*	Authors:  	Florian Münch, Kaïs Jomaa, Ayoub Chamakhi & Amina Bousnina						    
*	ID variable: id_platforme		  					  
*	Requires:  	ecommerce_master_final.dta
*	Creates:

***********************************************************************
* 	Part 0: 	set the stage		  
***********************************************************************

use "${master_final}/consortium_final", clear
		
		* change directory
cd "${master_regressiontables}/midline"

		* declare panel data
xtset id_plateforme surveyround, delta(1)

***********************************************************************
* 	Part 1: 	Midline analysis			  
***********************************************************************

***********************************************************************
* 	PART 1.1: survey attrition 		
***********************************************************************
*test for differential attrition using the PAP specification (cluster SE, strata)
eststo a2, r:reg  refus treatment if surveyround==2, cluster(id_plateforme)
estadd local strata "No"

eststo a3, r:areg  refus treatment if surveyround==2, absorb(strata_final) cluster(id_plateforme)
estadd local strata "Yes"

eststo a4, r:areg  refus i.pole if surveyround==2, absorb(strata_final) cluster(id_plateforme)
estadd local strata "Yes"

eststo a5, r:reg  refus i.pole if surveyround==2, cluster(id_plateforme)
estadd local strata "No"

local regressions a2 a3 a4 a5
esttab `regressions' using "ml_attrition.tex", replace ///
	mtitles("ML attrition" "ML attrition" "ML attrition" "ML attrition") ///
	label ///
	b(3) ///
	se(3) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls") ///
	addnotes("All standard errors are clustered at firm level.")
	
* balance after attrition
	* with outliers (Gourmandise)
iebaltab ca ca_exp profit capital employes fte_femmes age exp_pays exprep_inv exprep_couts inno_rd net_nb_dehors net_nb_fam net_nb_qualite mpi eri if surveyround == 1 & refus == 0, grpvar(treatment) ftest  vce(robust) format(%12.2fc) savexlsx(baltab_midline_all) replace
						 
	* w/o outliers
iebaltab ca ca_exp profit capital employes fte_femmes age exp_pays exprep_inv exprep_couts inno_rd net_nb_dehors net_nb_fam net_nb_qualite mpi eri if surveyround == 1 & refus == 0 & id_plateforme != 1092, grpvar(treatment) ftest vce(robust) format(%12.2fc) savexlsx(baltab_midline_wo_outlier) replace 
			 
			
	
***********************************************************************
* 	PART 1.2: Management practices index		
***********************************************************************
	* ATE, ancova
			* test no significant baseline differences
reg mpi i.treatment if surveyround == 1, vce(hc3)

			* pure mean comparison at midline
eststo mi1, r: reg mpi i.treatment if surveyround == 2, vce(hc3)
estadd local bl_control "No"
estadd local strata "No"
		
			* ancova without stratification dummies
eststo mi2, r: reg mpi i.treatment l.mpi, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies
eststo mi3, r: reg mpi i.treatment l.mpi i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"

	* DiD
eststo mi4, r: xtreg mpi i.treatment##i.surveyround i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"			

	* ATT, IV (participation in phase 1 meetings)
eststo mi5, r:ivreg2 mpi l.mpi i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"
estimates store iv_mi4

	* ATT, IV (participation in consortia)
eststo mi6, r:ivreg2 mpi l.mpi i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"

local regressions mi1 mi2 mi3 mi4 mi5 mi6
esttab `regressions' using "ml_mpi.tex", replace ///
	mtitles("Mean comparison" "Ancova" "Ancova" "DiD" "ATT" "ATT") ///
	label ///
	b(3) ///
	se(3) ///
	drop(*.strata_final) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls" "bl_control Y0 control") ///
	addnotes("Column (1) presents estimates for a simple mean comparison between treatment and control group at midline."  "Column (2) presents an ANCOVA specification without strata controls." "Column (3) presents an ANCOVA specification with strata controls." "Column (4) provides estimates from a difference-in-difference specification." "Column (5) estimates are based on 2SLS instrumental variable estimation where treatment assignment is the instrument for treatment participation." "(1) uses robust standard errors. In (2)-(5) standard errors are clustered at the firm level to account for multiple observations per firm")

***********************************************************************
* 	PART 1.3: Export readiness index		
***********************************************************************
	* ATE, ancova
	
			* no significant baseline differences
reg eri i.treatment if surveyround == 1, vce(hc3)

			* pure mean comparison at midline
eststo ep1, r: reg eri i.treatment if surveyround == 2, vce(hc3)
estadd local bl_control "No"
estadd local strata "No"
		
			* ancova without stratification dummies
eststo ep2, r: reg eri i.treatment l.eri, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies
eststo ep3, r: reg eri i.treatment l.eri i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"

			* DiD
eststo ep4, r: xtreg eri i.treatment##i.surveyround i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"			

	* ATT, IV (participation in phase 1 meetings)
eststo ep5, r:ivreg2 eri l.eri i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"
estimates store iv_ep4

	* ATT, IV (participation in consortium)
eststo ep6, r:ivreg2 eri l.eri i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"

local regressions ep1 ep2 ep3 ep4 ep5 ep6
esttab `regressions' using "ml_eri.tex", replace ///
	mtitles("Mean comparison" "Ancova" "Ancova" "DiD" "ATT" "ATT") ///
	label ///
	b(3) ///
	se(3) ///
	drop(*.strata_final) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls" "bl_control Y0 control") ///
	addnotes("Column (1) presents estimates for a simple mean comparison between treatment and control group at midline."  "Column (2) presents an ANCOVA specification without strata controls." "Column (3) presents an ANCOVA specification with strata controls." "Column (4) provides estimates from a difference-in-difference specification." "Column (5) estimates are based on 2SLS instrumental variable estimation where treatment assignment is the instrument for treatment participation." "(1) uses robust standard errors. In (2)-(5) standard errors are clustered at the firm level to account for multiple observations per firm")

***********************************************************************
* 	PART 1.4: Gender index		
***********************************************************************
	* ATE, ancova
			* no significant baseline differences
reg genderi i.treatment if surveyround == 1, vce(hc3)

			* pure mean comparison at midline
eststo gr1, r: reg genderi i.treatment if surveyround == 2, vce(hc3)
estadd local bl_control "No"
estadd local strata "No"

			* ancova without stratification dummies
eststo gr2, r: reg genderi i.treatment l.genderi, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies
eststo gr3, r: reg genderi i.treatment l.genderi i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"

			* DiD
eststo gr4, r: xtreg genderi i.treatment##i.surveyround i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"			

			* ATT, IV (with 1 session counting as taken up)
eststo gr5, r:ivreg2 genderi l.genderi i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"
estimates store iv_gr4

			* ATT, IV (participation in consortium)
eststo gr6, r:ivreg2 genderi l.genderi i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"

local regressions gr1 gr2 gr3 gr4 gr5 gr6
esttab `regressions' using "ml_genderi.tex", replace ///
	mtitles("Mean comparison" "Ancova" "Ancova" "DiD" "ATT" "ATT") ///
	label ///
	b(3) ///
	se(3) ///
	drop(*.strata_final) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls" "bl_control Y0 control") ///
	addnotes("Column (1) presents estimates for a simple mean comparison between treatment and control group at midline."  "Column (2) presents an ANCOVA specification without strata controls." "Column (3) presents an ANCOVA specification with strata controls." "Column (4) provides estimates from a difference-in-difference specification." "Column (5) estimates are based on 2SLS instrumental variable estimation where treatment assignment is the instrument for treatment participation." "(1) uses robust standard errors. In (2)-(5) standard errors are clustered at the firm level to account for multiple observations per firm")

	
	
***********************************************************************
* 	PART 1.5: Export Readiness index		
***********************************************************************
	* ATE, ancova
			* no significant baseline differences
reg eri i.treatment if surveyround == 1, vce(hc3)

			* pure mean comparison at midline
eststo em1, r: reg eri i.treatment if surveyround == 2, vce(hc3)
estadd local bl_control "No"
estadd local strata "No"

			* ancova without stratification dummies
eststo em2, r: reg eri i.treatment l.eri, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies
eststo em3, r: reg eri i.treatment l.eri i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"

			* DiD
eststo em4, r: xtreg eri i.treatment##i.surveyround i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"			

			* ATT, IV (with 1 session counting as taken up)
eststo em5, r:ivreg2 eri l.eri i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"
estimates store iv_em4

			* ATT, IV (with 1 session counting as taken up)
eststo em6, r:ivreg2 eri l.eri i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"

local regressions em1 em2 em3 em4 em5 em6
esttab `regressions' using "ml_eri.tex", replace ///
	mtitles("Mean comparison" "Ancova" "Ancova" "DiD" "ATT" "ATT") ///
	label ///
	b(3) ///
	se(3) ///
	drop(*.strata_final) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls" "bl_control Y0 control") ///
	addnotes("Column (1) presents estimates for a simple mean comparison between treatment and control group at midline."  "Column (2) presents an ANCOVA specification without strata controls." "Column (3) presents an ANCOVA specification with strata controls." "Column (4) provides estimates from a difference-in-difference specification." "Column (5) estimates are based on 2SLS instrumental variable estimation where treatment assignment is the instrument for treatment participation." "(1) uses robust standard errors. In (2)-(5) standard errors are clustered at the firm level to account for multiple observations per firm")
	

***********************************************************************
* 	PART 1.5: Innovations index		
***********************************************************************
* number of observations
	* ATE, ancova
			* no significant baseline differences
reg innovations i.treatment if surveyround == 1, vce(hc3)

			* pure mean comparison at midline
eststo in1, r: reg innovations i.treatment if surveyround == 2, vce(hc3)
estadd local bl_control "No"
estadd local strata "No"

			* ancova without stratification dummies
eststo in2, r: reg innovations i.treatment l.innovations, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies
eststo in3, r: reg innovations i.treatment l.innovations i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"

			* DiD
eststo in4, r: xtreg innovations i.treatment##i.surveyround i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"			

	* ATT, IV (with 1 session counting as taken up)
eststo in5, r:ivreg2 innovations l.innovations i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"
estimates store iv_in4

	* ATT, IV (with 1 session counting as taken up)
eststo in6, r:ivreg2 innovations l.innovations i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"

local regressions in1 in2 in3 in4 in5 in6
esttab `regressions' using "ml_innovations.tex", replace ///
	mtitles("Mean comparison" "Ancova" "Ancova" "DiD" "ATT" "ATT") ///
	label ///
	b(3) ///
	se(3) ///
	drop(*.strata_final) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls" "bl_control Y0 control") ///
	addnotes("Column (1) presents estimates for a simple mean comparison between treatment and control group at midline."  "Column (2) presents an ANCOVA specification without strata controls." "Column (3) presents an ANCOVA specification with strata controls." "Column (4) provides estimates from a difference-in-difference specification." "Column (5) estimates are based on 2SLS instrumental variable estimation where treatment assignment is the instrument for treatment participation." "(1) uses robust standard errors. In (2)-(5) standard errors are clustered at the firm level to account for multiple observations per firm")
	
	
	
* innovated
	* ATE, ancova
			* no significant baseline differences
logit innovated i.treatment if surveyround == 1, vce(robust)

			* pure mean comparison at midline
eststo in1, r: logit innovated i.treatment if surveyround == 2, vce(robust)
estadd local bl_control "No"
estadd local strata "No"

			* ancova without stratification dummies
eststo in2, r: logit innovated i.treatment l.innovated, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies
eststo in3, r: logit innovated i.treatment l.innovated i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"

			* DiD
eststo in4, r: xtlogit innovated i.treatment##i.surveyround i.strata_final, vce(cluster id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"			

	* ATT, IV (with 1 session counting as taken up)
eststo in5, r:ivreg2 innovated l.innovated i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"
estimates store iv_in4

	* ATT, IV (with 1 session counting as taken up)
eststo in6, r:ivreg2 innovated l.innovated i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"

local logitressions in1 in2 in3 in4 in5 in6
esttab `logitressions' using "ml_innovated.tex", replace ///
	mtitles("Mean comparison" "Ancova" "Ancova" "DiD" "ATT" "ATT") ///
	label ///
	b(3) ///
	se(3) ///
	drop(*.strata_final) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls" "bl_control Y0 control") ///
	addnotes("Columns (1) - (4) present estimates based on logit models." "Column (1) presents estimates for a simple mean comparison between treatment and control group at midline."  "Column (2) presents an ANCOVA specification without strata controls." "Column (3) presents an ANCOVA specification with strata controls." "Column (4) provides estimates from a difference-in-difference specification." "Column (5) estimates are based on 2SLS instrumental variable estimation where treatment assignment is the instrument for treatment participation." "(1) uses robust standard errors. In (2)-(5) standard errors are clustered at the firm level to account for multiple observations per firm")


***********************************************************************
* 	PART 1.6: Network regression (total size)	
***********************************************************************
	* ATE, ancova
	
			* no significant baseline differences
reg net_size i.treatment if surveyround == 1, vce(hc3)

			* pure mean comparison at midline 
eststo ns1, r: reg net_size i.treatment if surveyround == 2, vce(hc3)
estadd local bl_control "No"
estadd local strata "No"
		
			* ancova without stratification dummies 
eststo ns2, r: reg net_size i.treatment l.net_size, cluster(id_plateforme) /*lagged value (l): include the value of the variable in previous survey_round*/
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies 
eststo ns3, r: reg net_size i.treatment l.net_size i.strata_final, cluster(id_plateforme) /*include the control variables pour les différentes stratas+ lagged value*/
estadd local bl_control "Yes"
estadd local strata "Yes"

			* DiD 
eststo ns4, r: xtreg net_size i.treatment##i.surveyround i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"			

	* ATT, IV (participation in phase 1 meetings) 
eststo ns5, r:ivreg2 net_size l.net_size i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"
estimates store iv_ns5

	* ATT, IV (participation in consortium)
eststo ns6, r:ivreg2 net_size l.net_size i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"

local regressions ns1 ns2 ns3 ns4 ns5 ns6
esttab `regressions' using "ml_net_size.tex", replace ///
	mtitles("Mean comparison" "Ancova" "Ancova" "DiD" "ATT" "ATT") ///
	label ///
	b(3) ///
	se(3) ///
	drop(*.strata_final) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls" "bl_control Y0 control") ///
	addnotes("Column (1) presents estimates for a simple mean comparison between treatment and control group at midline."  "Column (2) presents an ANCOVA specification without strata controls." "Column (3) presents an ANCOVA specification with strata controls." "Column (4) provides estimates from a difference-in-difference specification." "Column (5) estimates are based on 2SLS instrumental variable estimation where treatment assignment is the instrument for treatment participation." "(1) uses robust standard errors. In (2)-(5) standard errors are clustered at the firm level to account for multiple observations per firm")

***********************************************************************
* 	PART 1.7: Network regression (female network)	
***********************************************************************
	* ATE, ancova
	
			* pure mean comparison at midline 
eststo nf1, r: reg net_nb_f i.treatment if surveyround == 2, vce(hc3)
estadd local bl_control "No"
estadd local strata "No"
		
			* ancova without stratification dummies 
eststo nf2, r: reg net_nb_f i.treatment, cluster(id_plateforme) 
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies 
eststo nf3, r: reg net_nb_f i.treatment i.strata_final, cluster(id_plateforme) 
estadd local bl_control "Yes"
estadd local strata "Yes"

			/* DiD (create an aggreate variable for network size)
eststo ep4, r: xtreg net_nb_f i.treatment##i.surveyround i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"			
*/
	* ATT, IV (participation in phase 1 meetings) 
eststo nf4, r:ivreg2 net_nb_f i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"
estimates store iv_nf4

	* ATT, IV (participation in consortium)
eststo nf5, r:ivreg2 net_nb_f i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"

local regressions nf1 nf2 nf3 nf4 nf5
esttab `regressions' using "ml_net_nb_f.tex", replace ///
	mtitles("Mean comparison" "Ancova" "Ancova" "ATT" "ATT") ///
	label ///
	b(3) ///
	se(3) ///
	drop(*.strata_final) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls" "bl_control Y0 control") ///
	addnotes("Column (1) presents estimates for a simple mean comparison between treatment and control group at midline."  "Column (2) presents an ANCOVA specification without strata controls." "Column (3) presents an ANCOVA specification with strata controls." "Column (4) estimates are based on 2SLS instrumental variable estimation where treatment assignment is the instrument for treatment participation." "(1) uses robust standard errors. In (2)-(5) standard errors are clustered at the firm level to account for multiple observations per firm")

	
***********************************************************************
* 	PART 1.8: Network regression (male network)	
***********************************************************************
	* ATE, ancova
	
			* pure mean comparison at midline (create an aggreate variable for network size)
eststo nm1, r: reg net_nb_m i.treatment if surveyround == 2, vce(hc3)
estadd local bl_control "No"
estadd local strata "No"
		
			* ancova without stratification dummies 
eststo nm2, r: reg net_nb_m i.treatment, cluster(id_plateforme) 
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies 
eststo nm3, r: reg net_nb_m i.treatment i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"

			/* DiD 
eststo ep4, r: xtreg eri i.treatment##i.surveyround i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"			
*/
	* ATT, IV (participation in phase 1 meetings) 
eststo nm4, r:ivreg2 net_nb_m i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"
estimates store iv_nm4

	* ATT, IV (participation in consortium)
eststo nm5, r:ivreg2 net_nb_m i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"

local regressions nm1 nm2 nm3 nm4 nm5 
esttab `regressions' using "ml_net_nb_m.tex", replace ///
	mtitles("Mean comparison" "Ancova" "Ancova" "ATT" "ATT") ///
	label ///
	b(3) ///
	se(3) ///
	drop(*.strata_final) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls" "bl_control Y0 control") ///
	addnotes("Column (1) presents estimates for a simple mean comparison between treatment and control group at midline."  "Column (2) presents an ANCOVA specification without strata controls." "Column (3) presents an ANCOVA specification with strata controls." "Column (4) estimates are based on 2SLS instrumental variable estimation where treatment assignment is the instrument for treatment participation." "(1) uses robust standard errors. In (2)-(5) standard errors are clustered at the firm level to account for multiple observations per firm")


***********************************************************************
* 	PART 1.8: Network regression (Quality of adivce)	
***********************************************************************
* ATE, ancova
			* no significant baseline differences
reg net_nb_qualite i.treatment if surveyround == 1, vce(hc3)

			* pure mean comparison at midline
eststo nq1, r: reg net_nb_qualite i.treatment if surveyround == 2, vce(hc3)
estadd local bl_control "No"
estadd local strata "No"

			* ancova without stratification dummies
eststo nq2, r: reg net_nb_qualite i.treatment l.net_nb_qualite, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies
eststo nq3, r: reg net_nb_qualite i.treatment l.net_nb_qualite i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"

			* DiD
eststo nq4, r: xtreg net_nb_qualite i.treatment##i.surveyround i.strata_final, vce(cluster id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"			

	* ATT, IV (with 1 session counting as taken up)
eststo nq5, r:ivreg2 net_nb_qualite l.net_nb_qualite i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"
estimates store iv_in4

	* ATT, IV (with 1 session counting as taken up)
eststo nq6, r:ivreg2 net_nb_qualite l.net_nb_qualite i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"

local regressions nq1 nq2 nq3 nq4 nq5 nq6
esttab `regressions' using "ml_net_nb_qualite.tex", replace ///
	mtitles("Mean comparison" "Ancova" "Ancova" "DiD" "ATT" "ATT") ///
	label ///
	b(3) ///
	se(3) ///
	drop(*.strata_final) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls" "bl_control Y0 control") ///
	addnotes("Columns (1) - (4) present estimates based on logit models." "Column (1) presents estimates for a simple mean comparison between treatment and control group at midline."  "Column (2) presents an ANCOVA specification without strata controls." "Column (3) presents an ANCOVA specification with strata controls." "Column (4) provides estimates from a difference-in-difference specification." "Column (5) estimates are based on 2SLS instrumental variable estimation where treatment assignment is the instrument for treatment participation." "(1) uses robust standard errors. In (2)-(5) standard errors are clustered at the firm level to account for multiple observations per firm")

	
	
***********************************************************************
* 	PART 1.9: SSA Export Readiness index		
***********************************************************************
	* ATE, ancova
			* pure mean comparison at midline
eststo esa1, r: reg eri_ssa i.treatment if surveyround == 2, vce(hc3)
estadd local bl_control "No"
estadd local strata "No"

			* ancova without stratification dummies
eststo esa2, r: reg eri_ssa i.treatment l.eri, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies
eststo esa3, r: reg eri_ssa i.treatment l.eri i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"

			* ATT, IV (with 1 session counting as taken up)
eststo esa4, r:ivreg2 eri_ssa l.eri i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"
estimates store iv_esa4

			* ATT, IV (with 1 session counting as taken up)
eststo esa5, r:ivreg2 eri_ssa l.eri i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"

local regressions esa1 esa2 esa3 esa4 esa5
esttab `regressions' using "ml_eri_ssa.tex", replace ///
	mtitles("Mean comparison" "Ancova" "Ancova" "ATT" "ATT") ///
	label ///
	b(3) ///
	se(3) ///
	drop(*.strata_final) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls" "bl_control Y0 control") ///
	addnotes("Column (1) presents estimates for a simple mean comparison between treatment and control group at midline."  "Column (2) presents an ANCOVA specification without strata controls." "Column (3) presents an ANCOVA specification with strata controls." "Column (4) estimates are based on 2SLS instrumental variable estimation where treatment assignment is the instrument for treatment participation." "(1) uses robust standard errors. In (2)-(5) standard errors are clustered at the firm level to account for multiple observations per firm")
	
***********************************************************************
* 	PART 1.10: Sales 	
***********************************************************************
	* ATE, ancova
			* no significant baseline differences
reg ihs_ca_w99 i.treatment if surveyround == 1, vce(hc3)

			* pure mean comparison at midline
eststo sa1, r: reg ihs_ca_w99 i.treatment if surveyround == 2, vce(hc3)
estadd local bl_control "No"
estadd local strata "No"

			* ancova without stratification dummies
eststo sa2, r: reg ihs_ca_w99 i.treatment l.ihs_ca_w99, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies
eststo sa3, r: reg ihs_ca_w99 i.treatment l.ihs_ca_w99 i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"

			* DiD
eststo sa4, r: xtreg ihs_ca_w99 i.treatment##i.surveyround i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"			

			* ATT, IV (with 1 session counting as taken up)
eststo sa5, r:ivreg2 ihs_ca_w99 l.ihs_ca_w99 i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"
estimates store iv_sa4

			* ATT, IV (with 1 session counting as taken up)
eststo sa6, r:ivreg2 ihs_ca_w99 l.ihs_ca_w99 i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"

local regressions sa1 sa2 sa3 sa4 sa5 sa6
esttab `regressions' using "ml_sales.tex", replace ///
	mtitles("Mean comparison" "Ancova" "Ancova" "DiD" "ATT" "ATT") ///
	label ///
	b(3) ///
	se(3) ///
	drop(*.strata_final) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls" "bl_control Y0 control") ///
	addnotes("Column (1) presents estimates for a simple mean comparison between treatment and control group at midline."  "Column (2) presents an ANCOVA specification without strata controls." "Column (3) presents an ANCOVA specification with strata controls." "Column (4) provides estimates from a difference-in-difference specification." "Column (5) estimates are based on 2SLS instrumental variable estimation where treatment assignment is the instrument for treatment participation." "(1) uses robust standard errors. In (2)-(5) standard errors are clustered at the firm level to account for multiple observations per firm")
	

***********************************************************************
* 	PART 1.8: Export sales 		
***********************************************************************
	* ATE, ancova
			* no significant baseline differences
reg ihs_ca_exp_w99 i.treatment if surveyround == 1, vce(hc3)

			* pure mean comparison at midline
eststo esa1, r: reg ihs_ca_exp_w99 i.treatment if surveyround == 2, vce(hc3)
estadd local bl_control "No"
estadd local strata "No"

			* ancova without stratification dummies
eststo esa2, r: reg ihs_ca_exp_w99 i.treatment l.ihs_ca_exp_w99, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies
eststo esa3, r: reg ihs_ca_exp_w99 i.treatment l.ihs_ca_exp_w99 i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"

			* DiD
eststo esa4, r: xtreg ihs_ca_exp_w99 i.treatment##i.surveyround i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"			

			* ATT, IV (with 1 session counting as taken up)
eststo esa5, r:ivreg2 ihs_ca_exp_w99 l.ihs_ca_exp_w99 i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"
estimates store iv_esa4

			* ATT, IV (with 1 session counting as taken up)
eststo esa6, r:ivreg2 ihs_ca_exp_w99 l.ihs_ca_exp_w99 i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"

local regressions esa1 esa2 esa3 esa4 esa5 esa6
esttab `regressions' using "ml_exports_sales.tex", replace ///
	mtitles("Mean comparison" "Ancova" "Ancova" "DiD" "ATT" "ATT") ///
	label ///
	b(3) ///
	se(3) ///
	drop(*.strata_final) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls" "bl_control Y0 control") ///
	addnotes("Column (1) presents estimates for a simple mean comparison between treatment and control group at midline."  "Column (2) presents an ANCOVA specification without strata controls." "Column (3) presents an ANCOVA specification with strata controls." "Column (4) provides estimates from a difference-in-difference specification." "Column (5) estimates are based on 2SLS instrumental variable estimation where treatment assignment is the instrument for treatment participation." "(1) uses robust standard errors. In (2)-(5) standard errors are clustered at the firm level to account for multiple observations per firm")
	
***********************************************************************
* 	PART 1.9: Profits	
***********************************************************************

			* pure mean comparison at midline
eststo pr1, r: reg ihs_profit_w99 i.treatment if surveyround == 2, vce(hc3)
estadd local bl_control "No"
estadd local strata "No"
		
			* ancova without stratification dummies
eststo pr2, r: reg ihs_profit_w99 i.treatment l.ihs_profit_w99, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies
eststo pr3, r: reg ihs_profit_w99 i.treatment l.ihs_profit_w99 i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"

			* DiD
eststo pr4, r: xtreg ihs_profit_w99 i.treatment##i.surveyround i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"			

	* ATT, IV (participation in phase 1 meetings)
eststo pr5, r:ivreg2 ihs_profit_w99 l.ihs_profit_w99 i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"
estimates store iv_pr4

	* ATT, IV (participation in consortium)
eststo pr6, r:ivreg2 ihs_profit_w99 l.ihs_profit_w99 i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"

local regressions pr1 pr2 pr3 pr4 pr5 pr6
esttab `regressions' using "ml_profits.tex", replace ///
	mtitles("Mean comparison" "Ancova" "Ancova" "DiD" "ATT" "ATT") ///
	label ///
	b(3) ///
	se(3) ///
	drop(*.strata_final) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls" "bl_control Y0 control") ///
	addnotes("Column (1) presents estimates for a simple mean comparison between treatment and control group at midline."  "Column (2) presents an ANCOVA specification without strata controls." "Column (3) presents an ANCOVA specification with strata controls." "Column (4) provides estimates from a difference-in-difference specification." "Column (5) estimates are based on 2SLS instrumental variable estimation where treatment assignment is the instrument for treatment participation." "(1) uses robust standard errors. In (2)-(5) standard errors are clustered at the firm level to account for multiple observations per firm")	
	
***********************************************************************
* 	PART 1.10: Number of employees	
***********************************************************************
	* ATE, ancova
	
			* no significant baseline differences
reg ihs_employes_w99 i.treatment if surveyround == 1, vce(hc3)

			* pure mean comparison at midline
eststo em1, r: reg ihs_employes_w99 i.treatment if surveyround == 2, vce(hc3)
estadd local bl_control "No"
estadd local strata "No"
		
			* ancova without stratification dummies
eststo em2, r: reg ihs_employes_w99 i.treatment l.ihs_employes_w99, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies
eststo em3, r: reg ihs_employes_w99 i.treatment l.ihs_employes_w99 i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"

			* DiD
eststo em4, r: xtreg ihs_employes_w99 i.treatment##i.surveyround i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"			

	* ATT, IV (participation in phase 1 meetings)
eststo em5, r:ivreg2 ihs_employes_w99 l.ihs_employes_w99 i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"
estimates store iv_em4

	* ATT, IV (participation in consortium)
eststo em6, r:ivreg2 ihs_employes_w99 l.ihs_employes_w99 i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"

local regressions em1 em2 em3 em4 em5 em6
esttab `regressions' using "ml_employees.tex", replace ///
	mtitles("Mean comparison" "Ancova" "Ancova" "DiD" "ATT" "ATT") ///
	label ///
	b(3) ///
	se(3) ///
	drop(*.strata_final) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls" "bl_control Y0 control") ///
	addnotes("Column (1) presents estimates for a simple mean comparison between treatment and control group at midline."  "Column (2) presents an ANCOVA specification without strata controls." "Column (3) presents an ANCOVA specification with strata controls." "Column (4) provides estimates from a difference-in-difference specification." "Column (5) estimates are based on 2SLS instrumental variable estimation where treatment assignment is the instrument for treatment participation." "(1) uses robust standard errors. In (2)-(5) standard errors are clustered at the firm level to account for multiple observations per firm")
	
/*
preserve
keep if surveyround==1

wyoung ihs_revenue95 ihs_exports95 ihs_w95_dig_rev20 knowledge_index dig_marketing_index dig_presence_weightedz, cmd(regress OUTCOMEVAR treatment , cluster(id_plateforme)) cluster(id_plateforme) familyp(treatment) ///
	subgroup(ml_attrit) bootstraps(1000) seed(8291)
restore

*test for selective attrition on key outcome variables
eststo a_sel5,r:areg  ihs_exports95 treatment##ml_attrit if surveyround==1, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"

eststo a_sel6, r:areg  ihs_revenue95 treatment##ml_attrit if surveyround==1, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"

eststo a_sel7, r:areg  ihs_w95_dig_rev20 treatment##ml_attrit if surveyround==1, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"

eststo a_sel8, r:areg  exp_pays_avg treatment##ml_attrit if surveyround==1, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"

eststo a_sel9, r:areg  knowledge_index treatment##ml_attrit if surveyround==1, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"

eststo a_sel10, r:areg  dig_marketing_index treatment##ml_attrit if surveyround==1, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"

eststo a_sel11, r:areg  dig_presence_weightedz treatment##ml_attrit if surveyround==1, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"

local regressions a_sel5 a_sel6 a_sel7 a_sel8 a_sel9 a_sel10 a_sel11
esttab `regressions' using "ml_sel_attrition.tex", replace ///
	mtitles("IHS Exports" "IHS Total Rev." "IHS Digital Rev." "No. of exp. countries" "Knowledge" "Dig.Marketing" "Online Presence") ///
	label ///
	b(3) ///
	se(3) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls") ///
	addnotes("All standard errors are clustered at firm level.")


***********************************************************************
* 	PART 1.4: Digital revenues (missing values to zero and dummy out)		
***********************************************************************
*First replace missing values by zeros and create dummy for these values

gen dig_revenues_ecom_miss = 0 
replace dig_revenues_ecom_miss = 1 if ihs_w95_dig_rev20 == .
gen ihs_w95_dig_rev20_imputed= ihs_w95_dig_rev20 
replace ihs_w95_dig_rev20_imputed=0 if dig_revenues_ecom_miss==1

eststo dig_rev7, r:reg ihs_w95_dig_rev20_imputed i.treatment l.ihs_w95_dig_rev20_imputed dig_revenues_ecom_miss i.strata, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"


***********************************************************************
* 	PART 2: Digital revenues (missing values to zero and dummy out)		
***********************************************************************
local ml_results ki3 ki6 pres3 pres6 dig_mark3 dig_mark6 dig_rev3 dig_rev6
esttab `ml_results' using "reg_table_ml.tex", replace ///
	mgroups("E-commerce & Dig.Marketing Knowledge" "Online presence" "Digital marketing" "E-commerce revenues", ///
		pattern(1 0 1 0 1 0 1 0)) ///
	mtitles("ATE" "LATE" "ATE" "LATE" "ATE" "LATE" "ATE" "LATE" ) ///
	label ///
	b(3) ///
	se(3) ///
	drop(*.strata) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls" "bl_control Baseline control") ///
	addnotes("All estimates are ANCOVA estimations, controlling for baseline values of the outcomes and strata." "Standard errors are clustered at the firm level to account for multiple observations per firm.")

	
***********************************************************************
* 	PART 3: Plot the regression estimates		
***********************************************************************
set scheme burd

*Plotting the regression estimates of the midline
cd "${master_gdrive}/output/GIZ_presentation_graphs"
coefplot ki3 pres3 dig_mark3 dig_rev3, bylabel("Average Treatment Effect (Treatment vs. Control)") keep (*treatment) drop(take_up _cons)  xline(0) ///
	coeflabels(*treatment = "Treatment", labsize(vsmall)) ///
	xlabel(-1(0.5)2,labsize(vsmall)) xscale(range(-1(0.5)2)) /// 
	xtitle("Standardized Coefficients", size (vsmall)) ///
	leg(off) ///
	title("Average Treatment Effect (Treatment vs. Control)", size (small) pos(12) span) ///
	saving(midline_treatment_coefplot, replace)  fysize(40)

coefplot ki6 pres6 dig_mark6 dig_rev6, bylabel("Effect only on participating firms") keep (take_up) drop(*treatment _cons) xline(0)||, ///
	coeflabels(take_up = "Take-up    ", labsize(vsmall)) /// 
	xlabel(-1(0.5)2,labsize(vsmall)) xscale(range(-1(0.5)2)) /// 
	xtitle("Standardized Coefficients", size (vsmall)) ///
	legend(position(6) size (vsmall) ///
	col(2) order(2 "Dig.Marketing Knowledge"  4 "Online presence" 6 "Digital marketing" 8 "E-commerce revenues")) ///
	title("Effect only on participating firms", size (small) pos(12) span)  ///
	saving(midline_takeup_coefplot, replace) fysize(50)

graph combine midline_treatment_coefplot.gph midline_takeup_coefplot.gph, colfirst ycommon col(1) iscale(*1.4)
gr export midline_coefplot.png, replace
*/	
		 

	
