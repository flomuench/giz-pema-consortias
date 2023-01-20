***********************************************************************
* 			Midline progress, firm characteristics
***********************************************************************
*																	   
*	PURPOSE: 		Create statistics on firms
*	OUTLINE:														  
*	1)				progress		  		  			
*	2)  			eligibility					 
*	3)  			characteristics							  
*	Authors:  	Ayoub Chamakhi, Kaïs Jomaa, Amina Bousnina							    				  
*	ID variaregise: 	id (example: f101)			  					  
*	Requires: ml_final.dta 
*	Creates:  ml_output.dta & midline_statistics		  
*																	  
***********************************************************************
* 	PART 1:  set environment + create pdf file for export		  			
***********************************************************************
	* import file
use "${ml_final}/ml_final", clear

	* set directory to checks folder
cd "$ml_output"
set graphics on
set scheme s1color

	* create pdf document
putpdf clear
putpdf begin 
putpdf paragraph

putpdf text ("Consortias: survey progress, firm characteristics"), bold linebreak

putpdf text ("Date: `c(current_date)'"), bold linebreak


***********************************************************************
* 	PART 2:  Generate the visualisations		  			
***********************************************************************
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 1: Survey Progress Overview"), bold

*** Section 1: Survey progress
	*Number of firms that started survey on specific date
format %-td date 
graph twoway histogram date, frequency width(1) ///
		tlabel(11jan2023(1)20feb2023, angle(60) labsize(vsmall)) ///
		ytitle("responses") ///
		title("{bf:Midline survey: number of responses}") 
gr export ml_survey_response_byday.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_survey_response_byday.png
putpdf pagebreak	

*Genarte shre of answers
sum id_plateforme 
gen share1= (`r(N)'/176)*100

count if survey_completed==1
gen share2= (`r(N)'/176)*100

count if validation==1
gen share3= (`r(N)'/176)*100

* Share of firms that started the survey
graph bar share*, blabel(total, format(%9.2fc)) ///
	legend (pos(6) row(6) label(1 "Started answering") label (2 "Answers completed") ///
	label  (3 "Answers validated")) ///
	title("Started, Completed, Validated") note("Date: `c(current_date)'") ///
	ytitle("share of total sample") ///
	ylabel(0(10)100, nogrid) 
graph export ml_responserate.png, replace
putpdf paragraph, halign(center)
putpdf image ml_responserate.png
putpdf pagebreak

drop share1 share2 share3


	* response rate by treatment status
graph bar (sum) survey_completed validation, over(treatment) blabel(total, format(%9.2fc)) ///
	legend (pos(6) row(1) label(1 "Answers completed") ///
	label(2 "Answers validated")) ///
	title("Completed & validated by treatment status") note("Date: `c(current_date)'") ///
	ytitle("Number of entries") ///
	ylabel(0(10)100, nogrid) 
graph export ml_responserate_tstatus.png, replace
putpdf paragraph, halign(center)
putpdf image ml_responserate_tstatus.png
putpdf pagebreak

	* Number of missing answers per section - all
graph hbar (sum) miss_inno miss_network miss_management miss_eri miss_gender miss_accounting, over(treatment) blabel(total, format(%9.1fc) gap(-0.2)) ///
	legend (pos(6) row(2) label(1 "Innovation ") label(2 "Network ") ///
	label(3 "Management") label(4 "Export readiness") ///
	label(5 "Gender ") label(6 "Accounting ")) ///
	title("Sum of missing answers per section") ///
	subtitle("sample: all initiated surveys") ///
	ylabel(0(5)100, nogrid) 
gr export ml_missing_asnwers_all.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_missing_asnwers_all.png
putpdf pagebreak

* Number of missing answers per section

graph hbar (sum) miss_inno miss_network miss_management miss_eri miss_gender miss_accounting if validation == 1, over(treatment) blabel(total, format(%9.1fc) gap(-0.2)) ///
	legend (pos(6) row(2) label(1 "Innovation ") label(2 "Network ") ///
	label(3 "Management") label(4 "Export readiness") ///
	label(5 "Gender ") label(6 "Accounting ")) ///
	title("Sum of missing answers per section") ///
	subtitle("sample: all completed surveys") ///

* Number of missing answers per section
graph hbar (count) miss_accounting miss_eri miss_gender miss_inno miss_management miss_network, over(treatment) blabel(total, format(%9.1fc) gap(-0.2)) ///
	legend (pos(6) row(6) label(1 "Accounting section") label (2 "Export readiness section") ///
	label  (3 "Gender section") label  (4 "Innovation section") ///
	label  (5 "Management section") label  (5 "Network section")) ///
	title("Number of missing answer per section") ///
	ylabel(0(5)50, nogrid) 
gr export ml_missing_asnwers.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_missing_asnwers.png
putpdf pagebreak	

	* How the company responded to the questionnaire
graph bar (count), over(survey_phone) over(treatment) blabel(total) ///
	name(formation, replace) ///
	ytitle("Number of companies") ///
	title("How the company responded to the questionnaire")
graph export ml_type_of_surveyanswer.png, replace
putpdf paragraph, halign(center)
putpdf image ml_type_of_surveyanswer.png
putpdf pagebreak

****** Section 2: innovation ******
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 2: Innovation"), bold

	* Type of innovation
graph hbar (mean) inno_produit inno_process inno_lieu inno_commerce inno_aucune, over(treatment) blabel(total, format(%9.1fc) gap(-0.2)) ///
	legend (pos(6) row(6) label(1 "Innovation product modification") label (2 "Innovation process modification") ///
	label  (3 "Innovation place of work") label  (4 "Innovation marketing") ///
	label  (5 "No innovation")) ///
	title("Type of innovation") ///
	ylabel(0(0.25)1, nogrid) 
gr export ml_typeinnovation_share.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_typeinnovation_share.png
putpdf pagebreak	

graph hbar (sum) inno_produit inno_process inno_lieu inno_commerce inno_aucune, over(treatment) blabel(total, format(%9.1fc) gap(-0.2)) ///
	legend (pos(6) row(6) label(1 "Innovation product modification") label (2 "Innovation process modification") ///
	label  (3 "Innovation place of work") label  (4 "Innovation marketing") ///
	label  (5 "No innovation")) ///
	title("Type of innovation") 
gr export ml_typeinnovation.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_typeinnovation.png
putpdf pagebreak	


*Source of the innovation	
graph hbar (mean) inno_mot1 inno_mot2 inno_mot3 inno_mot4 inno_mot5 inno_mot6,over(treatment) blabel(total, format(%9.2fc) gap(-0.2)) ///
	legend (pos(6) row(6) label(1 "Personal idea") label (2 "Consultant") ///
	label  (3 "Business contact") label  (4 "Event") ///
	label  (5 "Employee") label  (6 "Standards and norms")) ///
	title("Source of innovation") ///
	ylabel(0(0.1)0.5, nogrid) 
	gr export ml_source_inno_share.png, replace
	putpdf paragraph, halign(center) 
	putpdf image ml_source_inno_share.png
	putpdf pagebreak

graph hbar (sum) inno_mot1 inno_mot2 inno_mot3 inno_mot4 inno_mot5 inno_mot6, over(treatment) blabel(total, format(%9.2fc) gap(-0.2)) ///
	legend (pos(6) row(6) label(1 "Personal idea") label (2 "Consultant") ///
	label  (3 "Business contact") label  (4 "Event") ///
	label  (5 "Employee") label  (6 "Standards and norms")) ///
	title("Source of innovation") 
	gr export ml_source_inno.png, replace
	putpdf paragraph, halign(center) 
	putpdf image ml_source_inno.png
	putpdf pagebreak
	
	
****** Section 3: Networks ******
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 3: Networks"), bold
	* Number of female and male CEO met
graph bar net_nb_m net_nb_f, over(treatment)stack ///
	title("Number of female and male CEO met") ///
	ytitle("Person") ///
	ylabel(0(2)16, nogrid) ///
	legend(order(1 "Male CEO" 2 "Female CEO") pos(6))
gr export ml_CEO_met.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_CEO_met.png
putpdf pagebreak	

graph bar (mean) net_nb_m net_nb_f , over(treatment) blabel(total, format(%9.2fc) gap(-0.2))  ///
	title("Number of female vs male CEO met") ///
	legend(order(1 "Male CEO" 2 "Female CEO") pos(6))
 gr export ml_mean_CEO_met.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_mean_CEO_met.png
putpdf pagebreak	
	
tw ///
	(kdensity net_nb_m, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram net_nb_m, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity net_nb_f, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram net_nb_f, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	, ///
	xtitle("Distribution of female vs male CEO met", size(vsmall)) ///
	ytitle("Densitiy", axis(2) size(vsmall)) ///	
	legend(symxsize(small) order(1 "Male CEO" 2 "Female CEO")  pos(6) row(1)) ///
	name(network_density, replace)
gr export ml_network_density.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_network_density.png
putpdf pagebreak	

	* Quality of advice 
sum net_nb_qualite,d
histogram net_nb_qualite, width(1) frequency addlabels xlabel(0(1)10, nogrid format(%9.0f)) discrete ///
	xline(`r(mean)', lpattern(1)) xline(`r(p50)', lpattern()) ///
	ytitle("No. of firms") ///
	xtitle("Quality of advice of the business network") ///
	ylabel(0(5)50 , nogrid) ///
	text(100 `r(mean)' "Mean", size(small) place(e)) ///
	text(100 `r(p50)' "Median", size(small) place(e))
gr export ml_quality_advice.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_quality_advice.png
putpdf pagebreak	

*Interactions between CEO	
graph bar (mean) net_coop_pos net_coop_neg, over(treatment) blabel(total, format(%9.1fc) gap(-0.2)) ///
	legend (pos(6) row(6) label (1 "Positive answers for the perception of interactions between CEOs") label(2 "Negative answers for the perception of interactions between CEOs")) ///
	title("Perception of interactions between CEOs") ///
	ylabel(0(1)3, nogrid) 
gr export ml_perceptions_interactions.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_perceptions_interactions.png
putpdf pagebreak
	
graph hbar netcoop7 netcoop2 netcoop1 netcoop3 netcoop9 netcoop8 netcoop10 netcoop4 netcoop6 netcoop5, over(treatment) blabel(total, format(%9.2fc) gap(-0.2))  ///
	legend (pos(6) row(6) label (1 "Trust") label(2 "Partnership") ///
	label(3 "Communicate") label(4 "Win") label(5 "Power") ///
	label(6 "Connect") label(7 "Opponent") label(8 "Dominate") ///
	label(9 "Beat") label(10 "Retreat")) ///
	title("Perception of interactions between CEOs") ///
	ylabel(0(0.5)0.7, nogrid) 
gr export ml_perceptions_interactions_details.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_perceptions_interactions_details.png
putpdf pagebreak

****** Section 3: Management practices ****** 
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 3: Management practices"), bold

		* Key Performance indicators (KPIs)
graph hbar (percent), over(man_fin_per, relabel(1 "aucun" 2 "1-2" 3 "3-9" 4 "10+")) over(treatment) blabel(total, format(%9.1fc) gap(-0.2)) ///
    title("Number of KPIs") ///
	ylabel(0(5)50, nogrid)
gr export ml_performance.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_performance.png
putpdf pagebreak

		* KPIs frequency
graph hbar (mean) man_fin_per_fre, over(treatment) blabel(total, format(%9.2fc) gap(-0.2)) ///
    legend (pos(2) row(3) size(vsmall)) ///
    title ("Frequency KPIs") ///
	ylabel (0(0.25)1, nogrid)
gr export ml_performance_frequency.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_performance_frequency.png
putpdf pagebreak

		* Frequency employees performance
graph hbar (mean) man_hr_ind, over(treatment) blabel(total, format(%9.2fc) gap(-0.2)) ///
    legend (pos(2) row(3) size(vsmall)) ///
    title ("Frequency Employees Performance") ///
	ylabel (0(0.25)1, nogrid)
gr export ml_performance_employees.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_performance_employees.png
putpdf pagebreak

	/*	* Employees Incentives
graph hbar (mean) man_hr_obj, over(treatment) blabel(total, format(%9.2fc) gap(-0.2)) ///
    legend (pos(2) row(3) size(vsmall)) ///
    title ("Employees Incentives") ///
*/ 

*Employees motivation
graph hbar (mean) man_hr_obj, over(treatment) blabel(total, format(%9.2fc) gap(-0.2)) ///
    legend (pos(2) row(3) size(vsmall)) ///
    title ("Employees Motivation") ///
	ylabel (0(0.25)1, nogrid)
gr export ml_motivation_employees.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_motivation_employees.png
putpdf pagebreak

		* Employees goal awareness
graph hbar (mean) man_ind_awa, over(treatment) blabel(total, format(%9.2fc) gap(-0.2)) ///
    legend (pos(2) row(3) size(vsmall)) ///
    title ("Employmees Awareness of Firms' Goals") ///
	  ylabel (0(0.25)1, nogrid)
gr export ml_goal_awa.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_goal_awa.png
putpdf pagebreak

		* Source of new management strategies
graph bar (mean) man_source1 man_source2 man_source3 man_source4 man_source5 man_source6 man_source7,over(treatment) blabel(total, format(%9.2fc) gap(-0.2)) ///
	legend (pos(6) row(6) label(1 "Consultant") label (2 "Business contact") ///
	label  (3 "Employees") label  (4 "Family") ///
	label  (5 "Event") label  (6 "No new strategy") label (7 "Other sources")) ///
	title("Source of New Management Strategies") ///
	ylabel(0(0.25)1, nogrid) 
	gr export ml_source_share_strategy.png, replace
	putpdf paragraph, halign(center) 
	putpdf image ml_source_share_strategy.png
	putpdf pagebreak


graph bar (sum) man_source1 man_source2 man_source3 man_source4 man_source5 man_source6 man_source7,over(treatment) blabel(total, format(%9.2fc) gap(-0.2)) ///
	legend (pos(6) row(6) label(1 "Consultant") label (2 "Business contact") ///
	label  (3 "Employees") label  (4 "Family") ///
	label  (5 "Event") label  (6 "No new strategy") label (7 "Other sources")) ///
	title("Source of New Management Strategies") 
	gr export ml_source_strategy.png, replace
	putpdf paragraph, halign(center) 
	putpdf image ml_source_strategy.png
	putpdf pagebreak

****** Section 4: Export management and readiness ******
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 4: Export readiness"), bold

	* Export Knowledge questions
graph hbar (mean) exp_kno_ft_co exp_kno_ft_ze, over(treatment) blabel(total, format(%9.1fc) gap(-0.2)) ///
	legend (pos(6) row(1) label (1 "COMESA") label(2 "ZECLAF") size(vsmall)) ///
	title("Export Knowledge") ///
	ylabel(0(0.2)1, nogrid)    
gr export ml_ex_k.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_ex_k.png
putpdf pagebreak	
	
*Export management/readiness
graph bar (mean) exp_pra_cible exp_pra_plan exp_pra_mission exp_pra_douane exp_pra_foire exp_pra_rexp exp_pra_sci, over(treatment) blabel(total, format(%9.1fc) gap(-0.2)) ///
	legend (pos(6) row(4) label (1 "Analysis of target markets") label(2 "Develop export plan") ///
	label(3 "Trade mission to target market") label(4 "Access customs website") label(5 "Participate in international trade fairs") ///
	label(6 "Employee for export activities") label(7 "Work with an international trading company")size(small)) ///
	title("Export Readiness Practices") ///
	ylabel(0(0.25)1, nogrid)    
gr export ml_erp.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_erp.png
putpdf pagebreak	
	
* Export preparation investment	
egen exprep_inv_95p = pctile(exprep_inv), p(95)
graph bar exprep_inv if exprep_inv<exprep_inv_95p, over(treatment) blabel(total, format(%9.2fc)) ///
	title("Investment in export readiness")
gr export ml_bar_exprep_inv.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_bar_exprep_inv.png
putpdf pagebreak

stripplot exprep_inv if exprep_inv<exprep_inv_95p, over(treatment) vertical ///
	title("Investment in export readiness")
gr export ml_strip_exprep_inv.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_strip_exprep_inv.png
putpdf pagebreak	

*Export costs perception	
graph hbar (mean) exprep_couts, over(treatment) blabel(total, format(%9.1fc) gap(-0.2)) ///
	title("Export preparation costs") ///
	ylabel(0(0.25)1, nogrid)    
gr export ml_exprep_couts.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_exprep_couts.png
putpdf pagebreak	

****** Section 5: Characteristics of the company****** 
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 5: Entrepreneurial empowerment"), bold
 
	* Locus of efficience
graph hbar (mean) car_efi_conv car_efi_fin1 car_efi_nego, over(treatment) blabel(total, format(%9.2fc) gap(-0.2)) /// 
	legend (pos(6) row(9) label(1 "Able to motivate the employees in my company") label(2 "Able to attract customers for my business") ///
	label(3 "Have the skills to access new sources of funding")size(vsmall)) ///
	title("Locus of efficience for female entrepreuneurs") ///
	ylabel(0(1)5, nogrid)    
gr export ml_locusefi.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_locusefi.png
putpdf pagebreak


*Locus of control
graph hbar (mean)  car_loc_succ car_loc_exp car_loc_env, over(treatment) blabel(total, format(%9.2fc) gap(-0.2)) ///
	legend (pos(6) row(6) label (1 "Introduce my company & product internationally") label (2 "Master export administrative and logistic procedures") ///
	label  (3 "Comfortable making new business contacts") ) ///
	title("Locus of control for female entrepreuneurs") ///
	ylabel(0(1)5, nogrid)    
gr export ml_locuscontrol.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_locuscontrol.png
putpdf pagebreak
	

*graph bar list_exp, over(list_group) - where list_exp provides the number of confirmed affirmations).
graph bar listexp, over(list_group, sort(1) relabel(1"Non-sensitive" 2"Sensitive  incl.")) over(treatment) ///
	blabel(total, format(%9.2fc) gap(-0.2)) ///
	title("List experiment question") ///
ytitle("No. of affirmations") ///
ylabel(0(1)3.2, nogrid) 
gr export ml_bar_listexp.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_bar_listexp.png
putpdf pagebreak


****** Section 6: Accounting section ****** 
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 6: Accounting indicators"), bold

*bar chart and boxplots of accounting variable by treatment
     * variable ca_2022:
egen ca_95p = pctile(ca), p(95)
graph bar ca if ca<ca_95p, blabel(total, format(%9.2fc)) ///
	title("Turnover in 2022")
gr export ml_bar_ca_2022.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_bar_ca_2022.png
putpdf pagebreak

stripplot ca if ca<ca_95p, over(treatment) vertical ///
	title("Turnover in 2022")
gr export ml_strip_ca_2022.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_strip_ca_2022.png
putpdf pagebreak

     * variable ca_exp_2022:
egen ca_exp_95p = pctile(ca_exp), p(95)
graph bar ca_exp if ca_exp<ca_exp_95p, over(treatment) blabel(total, format(%9.2fc)) ///
	title("Export turnover in 2022")
gr export ml_bar_ca_exp_2022.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_bar_ca_exp_2022.png
putpdf pagebreak

stripplot ca_exp if ca_exp<ca_exp_95p , over(treatment) vertical ///
	title("Export turnover in 2022")
gr export ml_strip_ca_exp_2022.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_strip_ca_exp_2022.png
putpdf pagebreak

     * variable profit_2022:
egen profit_95p = pctile(profit), p(95)
graph bar profit if profit<profit_95p, over(treatment) blabel(total, format(%9.2fc)) ///
	title("Profit in 2022")
gr export ml_bar_profit_2022.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_bar_profit_2022.png
putpdf pagebreak

stripplot profit if profit<profit_95p, over(treatment) vertical ///
	title("Profit in 2022")
gr export ml_strip_profit_2022.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_strip_profit_2022.png
putpdf pagebreak

*scatter plots between CA and CA_Exp
scatter ca_exp ca if ca<ca_95p & ca_exp<ca_exp_95p, title("Proportion des bénéfices d'exportation par rapport au bénéfice total",size(medium))
gr export ml_scatter_ca.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_scatter_ca.png
putpdf pagebreak

*scatter plots between CA_Exp and exprep_inv
scatter ca_exp exprep_inv if ca_exp<ca_exp_95p & exprep_inv<exprep_inv_95p, title("Part de l'investissement dans la préparation des exportations par rapport au CA à l'exportation",size(small))
gr export ml_scatter_exprep.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_scatter_exprep.png
putpdf pagebreak



****** Section 7: Employees & ASS activities ******
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 7: Employment & SSA activities"), bold

**** Africa-related actions********************
graph bar (sum) ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5, over(treatment) ///
	blabel(total, format(%9.2fc) size(vsmall)) ///
	title ("ASS activities") ///
	ytitle("Sum of affirmative firms") ///
	legend(pos (6) col(2) label(1 "Potential client in SSA") label(2 "Commercial partner in SSA") label(3 "External finance for export costs") label(4 "Investment in sales structure") label(5 "Digital innovation or communication system") size(small))
gr export ml_ssa_action.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_ssa_action.png
putpdf pagebreak

graph bar (mean) ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5, over(treatment) ///
	blabel(total, format(%9.2fc) size(vsmall)) ///
	title ("ASS activities") ///
	ytitle("Share of affirmative firms") ///
	legend(pos (6) col(2) label(1 "Potential client in SSA") label(2 "Commercial partner in SSA") label(3 "External finance for export costs") label(4 "Investment in sales structure") label(5 "Digital innovation or communication system") size(small))
gr export ml_ssa_action_share.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_ssa_action_share.png
putpdf pagebreak

**** Employment********************

 * Generate graphs to see difference of employment between baseline & midline
*Bart chart: sum
graph bar (sum) empl if empl >= 0, over(treatment, label(labs(small))) ///
	blabel(total, format(%9.0fc) size(vsmall)) ///
	title("Sum of full time employees") 
gr export fte_details_sum_bar.png, replace
putpdf paragraph, halign(center) 
putpdf image fte_details_sum_bar.png
putpdf pagebreak

graph bar (sum) car_empl1 if car_empl1 >= 0, over(treatment, label(labs(small))) ///
	blabel(total, format(%9.0fc) size(vsmall)) ///
		title("Sum of female employees")  
gr export fte_femmes_details_sum_bar.png, replace
putpdf paragraph, halign(center) 
putpdf image fte_femmes_details_sum_bar.png
putpdf pagebreak

graph bar (sum) car_empl4 if car_empl4 >= 0, over(treatment, label(labs(small))) ///
	blabel(total, format(%9.0fc) size(vsmall)) ///
	title("Sum of part time employees")  
gr export pte_details_sum_bar.png, replace
putpdf paragraph, halign(center) 
putpdf image pte_details_sum_bar.png
putpdf pagebreak

graph bar (sum) car_empl2 if car_empl2 >= 0, over(treatment, label(labs(small))) ///
	blabel(total, format(%9.0fc) size(vsmall)) ///
	title("Sum of young employees") 
gr export young_employees_details_sum_bar.png, replace
putpdf paragraph, halign(center) 
putpdf image young_employees_details_sum_bar.png
putpdf pagebreak

*Bart chart: mean
graph bar (mean) empl if empl >= 0, over(treatment, label(labs(small))) ///
	blabel(total, format(%9.0fc) size(vsmall)) ///
	title("Mean of full time employees") 
gr export fte_details_mean_bar.png, replace
putpdf paragraph, halign(center) 
putpdf image fte_details_mean_bar.png
putpdf pagebreak

graph bar (mean) car_empl1 if car_empl1 >= 0, over(treatment, label(labs(small))) ///
	blabel(total, format(%9.0fc) size(vsmall)) ///
	title("Mean of female employees") 
gr export fte_femmes_details_mean_bar.png, replace
putpdf paragraph, halign(center) 
putpdf image fte_femmes_details_mean_bar.png
putpdf pagebreak

graph bar (mean) car_empl4 if car_empl4 >= 0, over(treatment, label(labs(small))) ///
	blabel(total, format(%9.0fc) size(vsmall)) ///
	title("Mean of part time employees")
gr export pte_details_mean_bar.png, replace
putpdf paragraph, halign(center) 
putpdf image pte_details_mean_bar.png
putpdf pagebreak

graph bar (mean) car_empl2 if car_empl2 >= 0, over(treatment, label(labs(small))) ///
	blabel(total, format(%9.0fc) size(vsmall)) ///
	title("Mean of young employees")  
gr export young_employees_details_mean_bar.png, replace
putpdf paragraph, halign(center) 
putpdf image young_employees_details_mean_bar.png
putpdf pagebreak







*local inno_vars 
*missingplot `inno_vars', labels mlabcolor(blue)

	* network vars
*local 
*missingplot, variablenames labels mlabcolor(blue)

* Add visualisation for missing values per section	





	
*Statistics with average time per survey
/*graph bar (mean) time_survey, blabel(total) ///
	title("Temps moyen pour remplir le sondage") 
gr export temps_moyen_sondage.png, replace
putpdf paragraph, halign(center) 
putpdf image temps_moyen_sondage.png
sum time_survey,d
putpdf paragraph
putpdf text ("Survey time statistics"), linebreak bold
putpdf text ("min. `: display %9.0g `r(min)'' minutes, max. `: display %9.0g `r(max)'' minutes & median `: display %9.0g `r(p50)'' minutes."), linebreak
putpdf pagebreak*/
/*
		* CA, CA export
gen w_ca2021_usd=w_ca2021/3
sum w_ca2021_usd,d
graph bar w_ca2021_usd, over(pole, relabel(1 "Agriculture" 2"Handcrafts& Cosmetics" 3"Services" 4"IT")) ///
	yline(`r(mean)', lpattern(1)) yline(`r(p50)', lpattern(dash)) ///
	ytitle("USD") ///
	ylabel (0(100000)200000 , nogrid) ///
	text(`r(mean)' 0.1 "Mean", size(vsmall) place(n)) ///
	text(`r(p50)'  0.1 "Median", size(vsmall) place(n) )
	gr export "$bl_output/donor/ca_mean.png", replace
	
sum employes,d
graph bar employes, over(pole, relabel(1 "Agriculture" 2"Handcrafts& Cosmetics" 3"Services" 4"IT")) ///
	yline(`r(mean)', lpattern(1)) yline(`r(p50)', lpattern(dash)) ///
	ytitle("No. of Employees") ///
	ylabel(0(2)22 , nogrid) ///
	text(`r(mean)' 0.1 "Mean", size(vsmall) place(n)) ///
	text(`r(p50)'  0.1 "Median", size(vsmall) place(n) )
	gr export "$bl_output/donor/employees.png", replace
*/
***********************************************************************
* 	PART 7:  save pdf
***********************************************************************
	* pdf
putpdf save "midline_statistics", replace

