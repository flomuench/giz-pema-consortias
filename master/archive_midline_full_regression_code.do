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
* 	PART 1.9: Network regression (Quality of adivce)	
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
* 	PART 1.11: Export investment regression
***********************************************************************
	* ATE, ancova
			* no significant baseline differences
reg exprep_inv i.treatment if surveyround == 1, vce(hc3)

			* pure mean comparison at midline 
eststo exi1, r: reg exprep_inv i.treatment if surveyround == 2, vce(hc3)
estadd local bl_control "No"
estadd local strata "No"
		
			* ancova without stratification dummies 
eststo exi2, r: reg exprep_inv i.treatment l.exprep_inv, cluster(id_plateforme) /*lagged value (l): include the value of the variable in previous survey_round*/
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies 
eststo exi3, r: reg exprep_inv i.treatment l.exprep_inv i.strata_final, cluster(id_plateforme) /*include the control variables pour les différentes stratas+ lagged value*/
estadd local bl_control "Yes"
estadd local strata "Yes"

			* DiD 
eststo exi4, r: xtreg exprep_inv i.treatment##i.surveyround i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"			

	* ATT, IV (participation in phase 1 meetings) 
eststo exi5, r:ivreg2 exprep_inv l.exprep_inv i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"
estimates store iv_exi5

	* ATT, IV (participation in consortium)
eststo exi6, r:ivreg2 exprep_inv l.exprep_inv i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"

local regressions exi1 exi2 exi3 exi4 exi5 exi6
esttab `regressions' using "ml_exprep_inv.tex", replace ///
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
* 	PART 1.13: Locus of control regression
***********************************************************************
	* ATE, ancova
	
			* no significant baseline differences
reg female_loc i.treatment if surveyround == 1, vce(hc3)

			* pure mean comparison at midline 
eststo flc1, r: reg female_loc i.treatment if surveyround == 2, vce(hc3)
estadd local bl_control "No"
estadd local strata "No"
		
			* ancova without stratification dummies 
eststo flc2, r: reg female_loc i.treatment l.female_loc, cluster(id_plateforme) /*lagged value (l): include the value of the variable in previous survey_round*/
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies 
eststo flc3, r: reg female_loc i.treatment l.female_loc i.strata_final, cluster(id_plateforme) /*include the control variables pour les différentes stratas+ lagged value*/
estadd local bl_control "Yes"
estadd local strata "Yes"

			* DiD 
eststo flc4, r: xtreg female_loc i.treatment##i.surveyround i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"			

	* ATT, IV (participation in phase 1 meetings) 
eststo flc5, r:ivreg2 female_loc l.female_loc i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"
estimates store iv_flc5

	* ATT, IV (participation in consortium)
eststo flc6, r:ivreg2 female_loc l.female_loc i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"

local regressions flc1 flc2 flc3 flc4 flc5 flc6
esttab `regressions' using "ml_female_loc.tex", replace ///
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
* 	PART 1.14:  Locus of self efficacy regression
***********************************************************************
	* ATE, ancova
	
			* no significant baseline differences
reg female_efficacy i.treatment if surveyround == 1, vce(hc3)

			* pure mean comparison at midline 
eststo fse1, r: reg female_efficacy i.treatment if surveyround == 2, vce(hc3)
estadd local bl_control "No"
estadd local strata "No"
		
			* ancova without stratification dummies 
eststo fse2, r: reg female_efficacy i.treatment l.female_efficacy, cluster(id_plateforme) /*lagged value (l): include the value of the variable in previous survey_round*/
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies 
eststo fse3, r: reg female_efficacy i.treatment l.female_efficacy i.strata_final, cluster(id_plateforme) /*include the control variables pour les différentes stratas+ lagged value*/
estadd local bl_control "Yes"
estadd local strata "Yes"

			* DiD 
eststo fse4, r: xtreg female_efficacy i.treatment##i.surveyround i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"			

	* ATT, IV (participation in phase 1 meetings) 
eststo fse5, r:ivreg2 female_efficacy l.female_efficacy i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"
estimates store iv_fse5

	* ATT, IV (participation in consortium)
eststo fse6, r:ivreg2 female_efficacy l.female_efficacy i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"

local regressions fse1 fse2 fse3 fse4 fse5 fse6
esttab `regressions' using "ml_female_efficacy.tex", replace ///
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
* 	PART 1.16: Sales 	
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
esttab `regressions' using "ml_ca.tex", replace ///
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
* 	PART 1.17: Export sales 		
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
* 	PART 1.18: Profits	
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
* 	PART 1.19: Number of employees	
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

	


***********************************************************************
* 	PART 1.15:  Positive words regression
***********************************************************************
	* ATE, ancova
	
			* no significant baseline differences
reg net_coop_pos i.treatment if surveyround == 1, vce(hc3)

			* pure mean comparison at midline 
eststo ncp1, r: reg net_coop_pos i.treatment if surveyround == 2, vce(hc3)
estadd local bl_control "No"
estadd local strata "No"
		
			* ancova without stratification dummies 
eststo ncp2, r: reg net_coop_pos i.treatment l.net_coop_pos, cluster(id_plateforme) /*lagged value (l): include the value of the variable in previous survey_round*/
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies 
eststo ncp3, r: reg net_coop_pos i.treatment l.net_coop_pos i.strata_final, cluster(id_plateforme) /*include the control variables pour les différentes stratas+ lagged value*/
estadd local bl_control "Yes"
estadd local strata "Yes"

			* DiD 
eststo ncp4, r: xtreg net_coop_pos i.treatment##i.surveyround i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"			

	* ATT, IV (participation in phase 1 meetings) 
eststo ncp5, r:ivreg2 net_coop_pos l.net_coop_pos i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"
estimates store iv_ncp5

	* ATT, IV (participation in consortium)
eststo ncp6, r:ivreg2 net_coop_pos l.net_coop_pos i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"

local regressions ncp1 ncp2 ncp3 ncp4 ncp5 ncp6
esttab `regressions' using "ml_net_coop_pos.tex", replace ///
	mtitles("Mean comparison" "Ancova" "Ancova" "DiD" "ATT" "ATT") ///
	label ///
	b(3) ///
	se(3) ///
	drop(*.strata_final) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls" "bl_control Y0 control") ///
	addnotes("Column (1) presents estimates for a simple mean comparison between treatment and control group at midline."  "Column (2) presents an ANCOVA specification without strata controls." "Column (3) presents an ANCOVA specification with strata controls." "Column (4) provides estimates from a difference-in-difference specification." "Column (5) estimates are based on 2SLS instrumental variable estimation where treatment assignment is the instrument for treatment participation." "(1) uses robust standard errors. In (2)-(5) standard errors are clustered at the firm level to account for multiple observations per firm")