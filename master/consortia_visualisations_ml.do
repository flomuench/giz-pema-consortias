***********************************************************************
* 			Descriptive Statistics in master file *					  
***********************************************************************
*																	  
*	PURPOSE: Understand the structure of the data from the midline					  
*																	  
*	OUTLINE: 	PART 1: Paths
*				PART 2: Midline statistics	  

*	Authors:  	Florian Münch, Kaïs Jomaa, Ayoub Chamakhi & Amina Bousnina						    
*	ID variable: id_platforme		  					  
*	Requires:  	 ecommerce_data_final.dta

										  
***********************************************************************
* 	PART 1: Paths
***********************************************************************
use "${master_final}/consortium_final", clear

		* change directory to regis folder for merge with regis_final
cd "${master_output}/figures"

		 
*correlation matrix of selected variables
*correlate ca_2021 ca_exp_2021 profit_2021 exprep_inv

set scheme s1color

***********************************************************************
* 	PART 2: Midline statistics
***********************************************************************
* create word document
set scheme s1color
set graphics on
putpdf clear
putpdf begin 
putpdf paragraph

putpdf text ("Consortia: Midline vs Baseline Statistics"), bold linebreak

putpdf text ("Date: `c(current_date)'"), bold linebreak
putpdf paragraph, halign(center) 

{
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 1: Survey Progress Overview"), bold

*** Section 1: Survey status
*Genarte shre of answers
sum validation if surveyround == 1
gen share_bl= (`r(N)'/181)*100 if surveyround == 1

sum validation if surveyround == 2
gen share_ml= (`r(N)'/176)*100 if surveyround == 2

* Share of firms that started the survey
graph bar share*, blabel(total, format(%9.2fc)) ///
	legend (pos(6) row(6) label(1 "Baseline survey") label (2 "Midline survey")) ///
	title("Response rate") ///
	ytitle("share of total sample") ///
	ylabel(0(10)100, nogrid) 
graph export responserate_share.png, replace
putpdf paragraph, halign(center)
putpdf image responserate_share.png
putpdf pagebreak

drop share_bl share_ml

	* Take-up rate per pole
graph bar (count) if surveyround == 2 & treatment == 1,blabel(total, format(%9.0fc)) over(take_up) by(pole, note("")) ///
	legend (pos(1) row(1) label(1 "Drop-out") label(2 "Participate")) ///
	ytitle("Number")
graph export takeup_pole.png, replace
putpdf paragraph, halign(center)
putpdf image takeup_pole.png
putpdf pagebreak

	* response rate by treatment status
graph bar (sum) survey_completed validation, over(surveyround) over(treatment) blabel(total, format(%9.2fc)) ///
	legend (pos(6) row(1) label(1 "Answers completed") ///
	label(2 "Answers validated")) ///
	title("Completed & validated by treatment status") note("Date: `c(current_date)'") ///
	ytitle("Number of entries") ///
	ylabel(0(10)100, nogrid) 
graph export ml_responserate_tstatus.png, replace
putpdf paragraph, halign(center)
putpdf image ml_responserate_tstatus.png
putpdf pagebreak

graph bar (sum) validation, over(treatment) over(surveyround) blabel(total, format(%9.0fc)) ///
	legend (pos(6) row(6) label(1 "Baseline survey") label (2 "Midline survey")) ///
	title("Response rate") ///
	ytitle("Number of responses") ///
	ylabel(0(10)100, nogrid) 
graph export responserate_abs.png, replace
putpdf paragraph, halign(center)
putpdf image responserate_abs.png
putpdf pagebreak


graph bar (sum) validation,over(surveyround) blabel(total, format(%9.2fc)) ///
	bar(1, fcolor(green)) bar(2, fcolor(red)) ///
	legend (pos(6) row(6) label(1 "Baseline survey") label (2 "Midline survey")) ///
	title("Response rate") ///
	ytitle("share of total sample") ///
	ylabel(0(20)200, nogrid) 
graph export responserate_abs.png, replace
putpdf paragraph, halign(center)
putpdf image responserate_abs.png
putpdf pagebreak

graph hbar (sum) survey_completed validation, over(pole) over(treatment) blabel(total, format(%9.2fc)) ///
	legend (pos(6) row(2) label(1 "Answers completed") ///
	label(2 "Answers validated")) ///
	title("Completed & validated by treatment status") note("Date: `c(current_date)'") ///
	ytitle("Number of entries") ///
	ylabel(0(5)30, nogrid) 
graph export ml_responserate_tstatus_pole.png, replace
putpdf paragraph, halign(center)
putpdf image ml_responserate_tstatus_pole.png
putpdf pagebreak


   *Attrition rate 
graph bar (sum) refus, over(treatment) blabel(total, format(%9.0fc)) ///
	title("Midline Attrition") note("Date: `c(current_date)'") ///
	ytitle("Number of entries") ///
	ylabel(0(5)20, nogrid) 
graph export ml_attritionrate.png, replace
putpdf paragraph, halign(center)
putpdf image ml_attritionrate.png
putpdf pagebreak


**** Section 2: Innovation*****
putpdf paragraph, font("Courier", 20)
putpdf text ("Section 2: Innovation"), bold
	*Innovated or not ?
graph bar (mean) innovated if surveyround ==3, over(surveyround, label(labs(small))) over(treatment, label(labs(small))) blabel(total, format(%9.2fc) gap(-0.2)) ///
	ylabel(0(0.25)1, nogrid) 
	gr export ml_innovated_share.png, replace
	putpdf paragraph, halign(center) 
	putpdf image ml_innovated_share.png
	putpdf pagebreak

	*Innovation	
graph bar (mean) inno_produit inno_process inno_lieu inno_commerce, over(surveyround, label(labs(small))) over(treatment, label(labs(small))) blabel(total, format(%9.2fc) gap(-0.2)) ///
	legend (pos(6) row(6) label(1 "Innovation product modification") label (2 "Innovation process modification") ///
	label  (3 "Innovation place of work") label (4 "Innovation marketing") label (5 "No innovation")) ///
	title("Type of innovation") ///
	ylabel(0(0.25)1, nogrid) 
	gr export ml_innovation_share.png, replace
	putpdf paragraph, halign(center) 
	putpdf image ml_innovation_share.png
	putpdf pagebreak

graph hbar (mean) inno_produit inno_process inno_lieu inno_commerce if surveyround == 2, over(pole, label(labs(vsmall))) over(treatment, label(labs(vsmall)) gap(400)) blabel(total, format(%9.2fc) size(tiny) gap(0.2)) ///
	legend (pos(6) row(6) label(1 "Innovation product modification") label (2 "Innovation process modification") ///
	label  (3 "Innovation place of work") label  (4 "Innovation marketing") ///
	label  (5 "No innovation")) ///
	title("Type of innovation in midline (per pole)", size (medium)) ///
	ylabel(0(0.25)1, nogrid) 
	gr export ml_innovation_share_pole.png, replace
	putpdf paragraph, halign(center) 
	putpdf image ml_innovation_share_pole.png
	putpdf pagebreak

	*Source of the innovation	
graph bar (mean) inno_mot1 inno_mot3 inno_mot4 inno_mot5 inno_mot6 inno_mot7, over(surveyround, label(labs(small))) over(treatment, label(labs(small))) blabel(total, format(%9.2fc) gap(-0.2)) ///
	legend (pos(6) row(6) label(1 "Personal idea") label (2 "Consultant") ///
	label  (3 "Business contact") label  (4 "Evenement") ///
	label  (5 "Employee") label  (6 "Standards and norms")) ///
	title("Source of innovation") ///
	ylabel(0(0.25)1, nogrid) 
	gr export ml_source_innovation_share.png, replace
	putpdf paragraph, halign(center) 
	putpdf image ml_source_innovation_share.png
	putpdf pagebreak

graph hbar (mean) inno_mot1 inno_mot3 inno_mot4 inno_mot5 inno_mot6 inno_mot7 if surveyround == 2, over(pole, label(labs(vsmall))) over(treatment, label(labs(vsmall)) gap(400)) blabel(total, format(%9.2fc) size(tiny) gap(0.2)) ///
	legend (pos(6) row(6) label(1 "Personal idea") label (2 "Consultant") ///
	label  (3 "Business contact") label  (4 "Evenement") ///
	label  (5 "Employee") label  (6 "Standards and norms")) ///
	title("Source of innovation in midline (per pole)", size (medium)) ///
	ylabel(0(0.25)1, nogrid) 
	gr export ml_source_innovation_share_pole.png, replace
	putpdf paragraph, halign(center) 
	putpdf image ml_source_innovation_share_pole.png
	putpdf pagebreak

****** Section 3: Networks ******
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 3: Networks"), bold

	*Number of female and male CEO met
graph bar net_nb_m net_nb_f, over(treatment)  blabel(total, format(%9.2fc) gap(-0.2)) stack ///
	title("Mean numbe of female and male CEO met") ///
	ytitle("CEOs") ///
	ylabel(0(2)12, nogrid) ///
	legend(order(1 "Male CEO" 2 "Female CEO") pos(6) rows(1))
gr export ml_CEO_met.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_CEO_met.png
putpdf pagebreak	

graph hbar net_nb_m net_nb_f if surveyround == 2,over(pole) over(treatment) blabel(total, format(%9.2fc) gap(-0.2)) stack ///
	title("Mean number of female and male CEO met in midline (per pole)", size (medium)) ///
	ytitle("CEOs") ///
	ylabel(0(2)12, nogrid) ///
	legend(order(1 "Male CEO" 2 "Female CEO") pos(6) rows(1))
gr export ml_CEO_met_pole.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_CEO_met_pole.png
putpdf pagebreak	


graph bar (sum) net_nb_m net_nb_f , over(treatment) blabel(total, format(%9.0fc) gap(-0.2)) stack  ///
	title("Number of female vs male CEO met") ///
	legend(order(1 "Male CEO" 2 "Female CEO") pos(6))
 gr export ml_mean_CEO_met.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_mean_CEO_met.png
putpdf pagebreak	


graph hbar (sum) net_nb_m net_nb_f if surveyround == 2, over(pole) over(treatment) blabel(total, format(%9.0fc) gap(-0.2)) stack  ///
	title("Number of female vs male CEO met in midline (per pole)", size (medium)) ///
	legend(order(1 "Male CEO" 2 "Female CEO") pos(6))
 gr export ml_mean_CEO_met_pole.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_mean_CEO_met_pole.png
putpdf pagebreak	

	*Plotting distribution of CEO met for the treament group
		* Female CEOs met
tw ///
	(kdensity net_nb_f if treatment == 1, lp(l) lc(maroon) bw(5)) ///
	(kdensity net_nb_f if treatment == 0, lp(l) lc(navy) bw(5)) ///
	, ///
	xtitle("number of CEOs", size(small)) ///
	ytitle("density", size(small)) ///
	legend(symxsize(small) order(1 "Treatment" 2 "Control")  pos(6) row(1)) ///
	name(ml_network_composition_f, replace)
gr export ml_network_composition_f.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_network_composition_f.png
putpdf pagebreak	
	
		* Male CEOs met
tw ///
	(kdensity net_nb_m if treatment == 1, lp(l) lc(maroon) bw(5)) ///
	(kdensity net_nb_m if treatment == 0, lp(l) lc(navy) bw(5)) ///
	, ///
	xtitle("number of CEOs", size(small)) ///
	ytitle("density") ///
	legend(symxsize(small) order(1 "Treatment" 2 "Control")  pos(6) row(1)) ///
	name(ml_network_composition_m, replace)
gr export ml_network_composition_m.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_network_composition_m.png
putpdf pagebreak

		* Male CEOs met
tw ///
	(kdensity net_nb_f if surveyround == 2, lp(l) lc(maroon) bw(5)) ///
	(kdensity net_nb_m if surveyround == 2, lp(l) lc(navy) bw(5)) ///
	, ///
	xtitle("number of CEOs", size(small)) ///
	ytitle("density") ///
	legend(symxsize(small) order(1 "Female contacts" 2 "Male contacts")  pos(6) row(1)) ///
	name(ml_network_composition_all, replace)
gr export ml_network_composition_all.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_network_composition_all.png
putpdf pagebreak

	* Quality of advice 
sum net_nb_qualite,d
twoway (histogram net_nb_qualite if treatment == 0 & surveyround == 2, fcolor(brown%30) lcolor(brown%30)lpattern(solid)) ///                
	   (histogram net_nb_qualite if treatment == 1 & take_up==1 & surveyround == 2 , fcolor(navy%30) lcolor(navy%30) lpattern(solid)) ///
   	   (histogram net_nb_qualite if treatment == 1 & take_up==0 & surveyround == 2 , fcolor(gold%40) lcolor(gold%40) lpattern(solid)), ///
	ytitle("No. of firms")   ///
	legend( row(3) order(1 "Control group (N=89 firms)" 2 "Treatment group, participants (N=55 firms)" 3 "Treatment group, drop-outs (N=32 firms)")) ///     
    ylabel(0(0.1)0.5 , nogrid) ///
	xline(`r(mean)', lpattern(1)) xline(`r(p50)', lpattern()) ///
	text(0.4 `r(mean)' "Mean", size(small) place(e)) ///
	text(0.45  `r(p50)' "Median", size(small) place(e))
gr export quality_advice_treatment.png, replace
putpdf paragraph, halign(center) 
putpdf image quality_advice_treatment.png
putpdf pagebreak	


		*Interactions between CEO	
graph bar (mean) net_coop_pos net_coop_neg, over(treatment) over(surveyround) blabel(total, format(%9.1fc) gap(-0.2)) ///
	legend (pos(6) row(6) label (1 "Positive answers for the perception of interactions between CEOs") label(2 "Negative answers for the perception of interactions between CEOs")) ///
	title("Perception of interactions between CEOs") ///
	ylabel(0(1)3, nogrid) 
gr export ml_perceptions_interactions.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_perceptions_interactions.png
putpdf pagebreak
	
graph hbar (mean) net_coop_pos net_coop_neg if surveyround == 2, over(pole) over(treatment)  blabel(total, format(%9.1fc) gap(-0.2)) ///
	legend (pos(6) row(6) label (1 "Positive answers for the perception") label(2 "Negative answers for the perception")) ///
	title("Perception of interactions between CEOs in the midline", size(small)) ///
	ylabel(0(1)3, nogrid) 
gr export ml_perceptions_interactions_pole.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_perceptions_interactions_pole.png
putpdf pagebreak

		*Positive interaction terms	
graph bar netcoop7 netcoop2 netcoop1 netcoop3 netcoop9, over(treatment) over(surveyround) blabel(total, format(%9.2fc) gap(-0.2)) ///
	legend (pos(6) row(6) label (1 "Partnership") label(2 "Communicate") ///
	label(3 "Win") label(4 "Trust") label(5 "Connect")) ///
	title("Positive views of communication between CEOs") ///
	ylabel(0(0.5)0.7, nogrid) 
gr export ml_perceptions_positive_interactions_details.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_perceptions_positive_interactions_details.png
putpdf pagebreak

graph bar netcoop7 netcoop2 netcoop1 netcoop3 netcoop9 if take_up== 1| treatment == 0,  over(treatment) over(surveyround) blabel(total, format(%9.2fc) gap(-0.2)) ///
	legend (pos(6) row(6) label (1 "Partnership") label(2 "Communicate") ///
	label(3 "Win") label(4 "Trust") label(5 "Connect")) ///
	title("Positive views of communication between CEOs") ///
	ylabel(0(0.5)0.7, nogrid) 
gr export ml_perceptions_positive_interactions_details_takeup.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_perceptions_positive_interactions_details_takeup.png
putpdf pagebreak

graph hbar netcoop7 netcoop2 netcoop1 netcoop3 netcoop8 if surveyround == 2, over(pole) over(treatment) blabel(total, format(%9.2fc) gap(-0.2)) ///
	legend (pos(6) row(6) label (1 "Partnership") label(2 "Communicate") ///
	label(3 "Win") label(4 "Trust") label(5 "Connect")) ///
	title("Positive views of communication between CEOs in the midline", size(small)) ///
	ylabel(0(0.5)0.7, nogrid) 
gr export ml_perceptions_positive_interactions_details_pole.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_perceptions_positive_interactions_details_pole.png
putpdf pagebreak

	*Negative interaction terms	
graph bar netcoop5 netcoop8 netcoop10 netcoop4 netcoop6, over(treatment) over(surveyround) blabel(total, format(%9.2fc) gap(-0.2)) bargap(0) ///
	legend (pos(6) row(3) col(2) label(1 "Power") ///
	label(2 "Opponent") label(3 "Dominate") ///
	label(4 "Beat") label(5 "Retreat")) ///
	title("Negative views of interactions between CEOs") ///
	ylabel(0(0.5)0.7, nogrid) 
gr export ml_perceptions_negative_interactions_details.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_perceptions_negative_interactions_details.png
putpdf pagebreak

graph hbar netcoop5 netcoop8 netcoop10 netcoop4 netcoop6 if surveyround == 2, over(pole) over(treatment) blabel(total, format(%9.2fc) gap(-0.2)) bargap(0) ///
legend (pos(6) row(3) col(2) label(1 "Power") ///
	label(2 "Opponent") label(3 "Dominate") ///
	label(4 "Beat") label(5 "Retreat")) ///
	title("Negative views of interactions between CEOs in the midline", size(small)) ///
	ylabel(0(0.5)0.7, nogrid) 
gr export ml_perceptions_negative_interactions_details_pole.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_perceptions_negative_interactions_details_pole.png
putpdf pagebreak


****** Section 4: Management practices ****** 
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 4: Management practices"), bold

    *Management practices index
tw ///
	(kdensity mpi if treatment == 1 & surveyround == 1, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram mpi if treatment == 1 & surveyround == 1, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity mpi if treatment == 0 & surveyround == 1, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram mpi if treatment == 0 & surveyround == 1, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Full sample}") ///
	subtitle("{it:Index calculated based on z-score method}", size(vsmall)) ///
	xtitle("Management Practices Index", size(vsmall)) ///
	ytitle("Number of observations", axis(1) size(vsmall)) ///
	ytitle("Densitiy", axis(2) size(vsmall)) ///	
	legend(symxsize(small) order(1 "Treatment group" 2 "Control group")) 
	
tw ///
	(kdensity mpi if treatment == 1 & surveyround == 2, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram mpi if treatment == 1 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity mpi if treatment == 0 & surveyround == 2, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram mpi if treatment == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Full sample}") ///
	subtitle("{it:Index calculated based on z-score method}", size(vsmall)) ///
	xtitle("Management Practices Index", size(vsmall)) ///
	ytitle("Number of observations", axis(1) size(vsmall)) ///
	ytitle("Densitiy", axis(2) size(vsmall)) ///	
	legend(symxsize(small) order(1 "Treatment group" 2 "Control group")) 
	graph export mpi_ml.png, replace 
	putpdf paragraph, halign(center) 
	putpdf image mpi_ml.png
	putpdf pagebreak

     *Management practices index take_up
gr tw ///
	(kdensity mpi if treatment == 1 & take_up == 1 & surveyround == 2, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram mpi if treatment == 1 & take_up == 1 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity mpi if treatment == 1 & take_up == 0 & surveyround == 2, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram mpi if treatment == 1 & take_up == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity mpi if treatment == 0 & surveyround == 2, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram mpi if treatment == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Midline Distribution of Management Practices Index}") ///
	subtitle("{it:Index calculated based on z-score method}") ///
	xtitle("Management Practices Index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Density", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, consortium member (N=55 firms)" ///
                     2 "Treatment group, drop-out (N=32 firms)" ///
					 3 "Control group (N=89 firms)") ///
               c(1) pos(6) ring(6)) ///
	name(man_practices_index_ml, replace)
graph export man_practices_index_ml.png, replace
putpdf paragraph, halign(center) 
putpdf image man_practices_index_ml.png
putpdf pagebreak

		* Source of new management strategies
graph bar (mean) man_source1 man_source2 man_source3 man_source4 man_source5 man_source6 man_source7, yvaroptions(sort(1) descending) over(treatment) blabel(total, format(%9.2fc) gap(-0.2)) ///
	legend (pos(6) row(6) label(1 "Consultant") label (2 "Business contact") ///
	label  (3 "Employees") label  (4 "Family") ///
	label  (5 "Event") label  (6 "No new strategy") label (7 "Other sources")) ///
	title("Source of New Management Strategies", pos(12)) ///
	ylabel(0(0.25)1, nogrid) 
	gr export ml_source_share_strategy.png, replace
	putpdf paragraph, halign(center) 
	putpdf image ml_source_share_strategy.png
	putpdf pagebreak

graph hbar (mean) man_source1 man_source2 man_source3 man_source4 man_source5 man_source6 man_source7 if surveyround == 2,over(pole) over(treatment) blabel(total, format(%9.2fc) gap(-0.2)) ///
	legend (pos(6) row(6) label(1 "Consultant") label (2 "Business contact") ///
	label  (3 "Employees") label  (4 "Family") ///
	label  (5 "Event") label  (6 "No new strategy") label (7 "Other sources")) ///
	title("Source of New Management Strategies (midline)", size (medium)) ///
	ylabel(0(0.25)1, nogrid) 
	gr export ml_source_share_strategy_pole.png, replace
	putpdf paragraph, halign(center) 
	putpdf image ml_source_share_strategy_pole.png
	putpdf pagebreak
	
	
		* What management practices did increase in treatment vs. control at midline?
graph hbar (mean) man_fin_num man_fin_per_fre man_hr_ind man_hr_pro man_ind_awa if surveyround == 2, over(treatment) blabel(total, format(%9.2fc) gap(-0.2)) ///
	legend (pos(6) row(6) ///
	label(1 "Nb. KPIs") label (2 "Frequency KPI evaluation") label(3 "Product profit") ///
	label(4 "Employee KPIs") label  (5 "Employee promotion") label(6 "Employee-firm goal awareness"))  ///
	title("Management practices (midline)", size (medium)) ///
	ylabel(0(0.25)1, nogrid) 
	gr export mp_all_ml.png, replace
	putpdf paragraph, halign(center) 
	putpdf image mp_all_ml.png
	putpdf pagebreak
	
	
****** Section 5: Export management and readiness ******
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 5: Export readiness"), bold

	* Export Knowledge questions
graph bar (mean) exp_kno_ft_co exp_kno_ft_ze, over(treatment) blabel(total, format(%9.2fc) gap(-0.2)) ///
	legend (pos(6) row(1) label (1 "COMESA") label(2 "ZECLAF") size(vsmall)) ///
	title("Export Knowledge") ///
	ylabel(0(0.2)1, nogrid) 
gr export ml_ex_k.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_ex_k.png
putpdf pagebreak	

graph bar (mean) exp_kno_ft_co exp_kno_ft_ze, over(pole, label(labs(small))) over(treatment, label(labs(small))) blabel(total, format(%9.2fc) gap(-0.2)) ///
	legend (pos(6) row(1) label (1 "COMESA") label(2 "ZECLAF") size(vsmall)) ///
	title("Export Knowledge") ///
	ylabel(0(0.2)1, nogrid) 
gr export ml_ex_k_pole.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_ex_k_pole.png
putpdf pagebreak

	*Export management/readiness
graph bar (mean) exp_pra_cible exp_pra_plan exp_pra_mission exp_pra_douane exp_pra_foire exp_pra_rexp exp_pra_sci, over(surveyround, label(labs(small))) over(treatment, label(labs(small))) blabel(total, format(%9.1fc) gap(-0.2)) ///
	legend (pos(6) row(4) label (1 "Analysis of target export markets") label(2 "Develop an export plan") ///
	label(3 "Trade mission to one target markets") label(4 "Access the customs website") label(5 "International trade fairs") ///
	label(6 "Employee for export-related activities") label(7 "International trading company")size(vsmall)) ///
	title("Export Readiness Practies") ///
	ylabel(0(0.2)1, nogrid)    
	gr export ml_erp.png, replace
	putpdf paragraph, halign(center) 
	putpdf image ml_erp.png
putpdf pagebreak

graph hbar (mean) exp_pra_cible exp_pra_plan exp_pra_mission exp_pra_douane exp_pra_foire exp_pra_rexp exp_pra_sci if surveyround == 2, over(pole, label(labs(small))) over(treatment, label(labs(small))) blabel(total, format(%9.1fc) gap(-0.2)) ///
	legend (pos(6) row(4) label (1 "Analysis of target export markets") label(2 "Develop an export plan") ///
	label(3 "Trade mission to one target markets") label(4 "Access the customs website") label(5 "International trade fairs") ///
	label(6 "Employee for export-related activities") label(7 "International trading company")size(vsmall)) ///
	title("Export Readiness Practies (midline)") ///
	ylabel(0(0.2)1, nogrid)    
	gr export ml_erp_pole.png, replace
	putpdf paragraph, halign(center) 
	putpdf image ml_erp_pole.png
putpdf pagebreak

   *Export readiness index (eri)
tw ///
	(kdensity eri if treatment == 1 & surveyround == 2, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram eri if treatment == 1 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity eri if treatment == 0 & surveyround == 2, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram eri if treatment == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Midline}") ///
	subtitle("{it:Index calculated based on z-score method}", size(vsmall)) ///
	xtitle("Export Readiness Index", size(vsmall)) ///
	ytitle("Number of observations", axis(1) size(vsmall)) ///
	ytitle("Densitiy", axis(2) size(vsmall)) ///	
	legend(symxsize(small) order(1 "Treatment group" 2 "Control group")) ///
	name(eri_ml, replace)
tw ///
	(kdensity eri if treatment == 1 & surveyround == 1, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram eri if treatment == 1 & surveyround == 1, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity eri if treatment == 0 & surveyround == 1, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram eri if treatment == 0 & surveyround == 1, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Baseline}") ///
	subtitle("{it:Index calculated based on z-score method}", size(vsmall)) ///
	xtitle("Export Readiness Index", size(vsmall)) ///
	ytitle("Number of observations", axis(1) size(vsmall)) ///
	ytitle("Densitiy", axis(2) size(vsmall)) ///	
	legend(symxsize(small) order(1 "Treatment group" 2 "Control group"))  ///
	name(eri_bl, replace)
gr combine eri_ml eri_bl, name(export_readiness_bl_ml, replace)
	graph export export_readiness_bl_ml.png, replace 
	putpdf paragraph, halign(center) 
	putpdf image export_readiness_bl_ml.png
	putpdf pagebreak

    *Export readiness index (eri) take_up
gr tw ///
	(kdensity eri if treatment == 1 & take_up == 1 & surveyround == 2, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram eri if treatment == 1 & take_up == 1 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity eri if treatment == 1 & take_up == 0 & surveyround == 2, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram eri if treatment == 1 & take_up == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity eri if treatment == 0, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram eri if treatment == 0, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Midline Export Readiness Index}") ///
	subtitle("{it:Index calculated based on z-score method}") ///
	xtitle("Export Readiness index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Density", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participants (N=55 firms)" ///
                     2 "Treatment group, drop-outs (N=32 firms)" ///
					 3 "Control group (N=89 firms)") nobox ///
			   region(lstyle(none)) ///
               c(1) pos(6) ring(6)) ///
	name(eri_ml_tup, replace)
gr tw ///
	(kdensity eri if treatment == 1 & take_up == 1 & surveyround == 1, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram eri if treatment == 1 & take_up == 1 & surveyround == 1, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity eri if treatment == 1 & take_up == 0 & surveyround == 1, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram eri if treatment == 1 & take_up == 0 & surveyround == 1, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity eri if treatment == 0, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram eri if treatment == 0, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Baseline Export Readiness Index}") ///
	subtitle("{it:Index calculated based on z-score method}") ///
	xtitle("Export Readiness index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Density", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participants (N=55 firms)" ///
                     2 "Treatment group, drop-outs (N=32 firms)" ///
					 3 "Control group (N=89 firms)") nobox ///
			   region(lstyle(none)) ///
               c(1) pos(6) ring(6)) ///
	name(eri_bl_tup, replace)
gr combine eri_ml_tup eri_bl_tup, name(eri_tup, replace) ycommon xcommon
graph export export_readiness_index_bl_ml.png, replace
putpdf paragraph, halign(center) 
putpdf image export_readiness_index_bl_ml.png
putpdf pagebreak

    * export readiness SSA index (eri_ssa)
tw ///
	(kdensity eri_ssa if treatment == 1 & surveyround == 2, lp(l) lc(maroon) yaxis(2) bw(0.75)) ///
	(histogram eri_ssa if treatment == 1 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity eri_ssa if treatment == 0 & surveyround == 2, lp(l) lc(navy) yaxis(2) bw(0.75)) ///
	(histogram eri_ssa if treatment == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Full sample}") ///
	subtitle("{it:Index calculated based on z-score method}", size(vsmall)) ///
	xtitle("Export Readiness Index SSA", size(vsmall)) ///
	ytitle("Number of observations", axis(1) size(vsmall)) ///
	ytitle("Densitiy", axis(2) size(vsmall)) ///	
	legend(symxsize(small) order(1 "Treatment group" 2 "Control group")) 
	graph export export_readiness_ssa_ml.png, replace 
	putpdf paragraph, halign(center) 
	putpdf image export_readiness_ssa_ml.png
	putpdf pagebreak

    * export readiness SSA index (eri_ssa) take_up
gr tw ///
	(kdensity eri_ssa if treatment == 1 & take_up == 1 & surveyround == 2, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram eri_ssa if treatment == 1 & take_up == 1 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity eri_ssa if treatment == 1 & take_up == 0 & surveyround == 2, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram eri_ssa if treatment == 1 & take_up == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity eri_ssa if treatment == 0, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram eri_ssa if treatment == 0, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Midline Distribution of Export Readiness Index SSA}") ///
	subtitle("{it:Index calculated based on z-score method}") ///
	xtitle("Export Readiness index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Density", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated (N=55 firms)" ///
                     2 "Treatment group, absent (N=32 firms)" ///
					 3 "Control group (N=89 firms)") ///
               c(1) pos(6) ring(6)) ///
	name(export_readiness_ssa_index_ml, replace)
graph export export_readiness_ssa_index_ml.png, replace
putpdf paragraph, halign(center) 
putpdf image export_readiness_ssa_index_ml.png
putpdf pagebreak


* Export preparation investment	
egen exprep_inv_95p = pctile(exprep_inv), p(95)
graph bar exprep_inv if exprep_inv<exprep_inv_95p & exprep_inv > 0, over(surveyround) over(treatment) blabel(total, format(%9.2fc)) ///
	title("Investment in export readiness") ///
	 ytitle( "Mean of Investment in export readiness")
gr export ml_bar_exprep_inv.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_bar_exprep_inv.png
putpdf pagebreak

graph hbar exprep_inv if exprep_inv<exprep_inv_95p & exprep_inv > 0 & surveyround == 2, over(pole) over(treatment) blabel(total, format(%9.2fc)) ///
	title("Investment in export readiness (midline)", size (medium)) ///
	 ytitle( "Mean of Investment in export readiness", size (medium))
gr export ml_bar_exprep_inv_pole.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_bar_exprep_inv_pole.png
putpdf pagebreak

stripplot exprep_inv if exprep_inv<exprep_inv_95p, over(surveyround) by (treatment, note("")) vertical ///
	title("Investment in export readiness")
gr export ml_strip_exprep_inv.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_strip_exprep_inv.png
putpdf pagebreak	

stripplot exprep_inv if exprep_inv<exprep_inv_95p & treatment == 1, over(surveyround) vertical ///
	title("Investment in export readiness (treatment)")
gr export ml_strip_exprep_inv_treatment.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_strip_exprep_inv_treatment.png
putpdf pagebreak	

stripplot exprep_inv if exprep_inv<exprep_inv_95p & treatment == 1, over(surveyround) by (pole, note("")) vertical ///
	title("Investment in export readiness (treatment)", size (small)) ///
	ytitle("Mean", size (small)) ///
	ylabel(, nogrid labsize (small))
gr export ml_strip_exprep_inv_treatment_pole.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_strip_exprep_inv_treatment_pole.png
putpdf pagebreak	

	* Distrubtion of exprep_inv
graph box exprep_inv if exprep_inv<exprep_inv_95p & exprep_inv>0 , over(treatment) over(surveyround) ///
	title("Investment in export readiness (without outliers)") 
gr export ml_dis_exprep_inv.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_dis_exprep_inv.png
putpdf pagebreak

graph hbox exprep_inv if exprep_inv<exprep_inv_95p & exprep_inv>0 , over(pole) over(treatment) over(surveyround) ///
	title("Investment in export readiness (without outliers)", size(medium)) 
gr export ml_dis_exprep_inv_pole.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_dis_exprep_inv_pole.png
putpdf pagebreak

drop exprep_inv_95p

*Export costs perception	
graph bar (mean) exprep_couts, over(surveyround) over(treatment) blabel(total, format(%9.1fc) gap(-0.2)) ///
	title("Export preparation costs") ///
	ylabel(0(1)10, nogrid) ///
    ytitle( "Mean of Export costs perception")
gr export ml_exprep_couts.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_exprep_couts.png
putpdf pagebreak

graph bar (mean) exprep_couts, over(surveyround) over (treatment) by(pole, note("")) blabel(total, format(%9.1fc) gap(-0.2)) ///
	title("Export preparation costs") ///
	ylabel(0(1)10, nogrid) ///
    ytitle( "Mean of Export costs perception")
gr export ml_exprep_couts_pole.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_exprep_couts_pole.png
putpdf pagebreak		
				
****** Section 6: Gender - Entrepreneurial Empowerment ****** 
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 6: Gender - Entrepreneurial empowerment"), bold
/*
*Locus of efficiency	
graph hbar (mean) car_efi_fin1 car_efi_nego car_efi_conv, over(surveyround, label(labs(small))) over(treatment, label(labs(small))) blabel(total, format(%9.2fc) gap(-0.2)) ///
	legend (pos(6) row(6) label(1 "Participant have the skills to access new sources of funding") label (2 "Participant negotiate the affairs of the company well") ///
	label  (3 "Manage to convince employees and partners to agree") ) ///
	title("Locus of control for female entrepreuneurs") ///
	ylabel(0(1)5, nogrid) 
	gr export ml_locusefficiency_share.png, replace
	putpdf paragraph, halign(center) 
	putpdf image ml_locusefficiency_share.png
	putpdf pagebreak
	
*Locus of efficiency	
graph hbar (sum) car_efi_fin1 car_efi_nego car_efi_conv, over(surveyround, label(labs(small))) over(take_up, label(labs(small))) blabel(total, format(%9.2fc) gap(-0.2)) ///
	legend (pos(6) row(6) label(1 "Participant have the skills to access new sources of funding") label (2 "Participant negotiate the affairs of the company well") ///
	label  (3 "Manage to convince employees and partners to agree") ) ///
	title("Locus of control for female entrepreuneurs") ///
	ylabel(0(1)5, nogrid) 
	gr export ml_locusefficiency.png, replace
	putpdf paragraph, halign(center) 
	putpdf image ml_locusefficiency.png
	putpdf pagebreak

*Locus of control	
graph hbar (mean)car_loc_succ car_loc_env,  over(surveyround, label(labs(small))) over(take_up, label(labs(small))) blabel(total, format(%9.2fc) gap(-0.2)) ///
	legend (pos(6) row(6) label(1 "Inspiring other women to become better entrepreneurs") label (2 "Able to determine the success of her business") ///
	label  (3 "Control over the internal and external environment of the firm") ) ///
	title("Locus of control for female entrepreuneurs") ///
	ylabel(0(1)5, nogrid) 
	gr export ml_locuscontrol_share.png, replace
	putpdf paragraph, halign(center) 
	putpdf image ml_locuscontrol_share.png
	putpdf pagebreak
*/

        *Female empowerment index (genderi)
			* Points
tw ///
	(kdensity genderi_points if treatment == 1 & surveyround == 2, lp(l) lc(maroon) yaxis(2) bw(1.5)) ///
	(histogram genderi_points if treatment == 1 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity genderi_points if treatment == 0 & surveyround == 2, lp(l) lc(navy) yaxis(2) bw(1.5)) ///
	(histogram genderi_points if treatment == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Women's Entrepreneurial Empowerment}") ///
	subtitle("{it:midline - points}", size(vsmall)) ///
	xtitle("Female Empowerment Index", size(vsmall)) ///
	ytitle("Number of observations", axis(1) size(vsmall)) ///
	ytitle("Densitiy", axis(2) size(vsmall)) ///	
	legend(symxsize(small) order(1 "Treatment group" 2 "Control group")) 
graph export female_empowerment_ml_points.png, replace 
putpdf paragraph, halign(center) 
putpdf image female_empowerment_ml_points.png
putpdf pagebreak
	
			* z-score
tw ///
	(kdensity genderi if treatment == 1 & surveyround == 2, lp(l) lc(maroon) yaxis(2) bw(1.5)) ///
	(histogram genderi if treatment == 1 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity genderi if treatment == 0 & surveyround == 2, lp(l) lc(navy) yaxis(2) bw(1.5)) ///
	(histogram genderi if treatment == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Women's Entrepreneurial Empowerment}") ///
	subtitle("{it:midline - z-score}", size(vsmall)) ///
	xtitle("Female Empowerment Index", size(vsmall)) ///
	ytitle("Number of observations", axis(1) size(vsmall)) ///
	ytitle("Densitiy", axis(2) size(vsmall)) ///	
	legend(symxsize(small) order(1 "Treatment group" 2 "Control group")) 
graph export female_empowerment_ml.png, replace 
putpdf paragraph, halign(center) 
putpdf image female_empowerment_ml.png
putpdf pagebreak		
		
        *Female empowerment index (genderi) take_up
			* points
gr tw ///
	(kdensity genderi_points if treatment == 1 & take_up == 1 & surveyround == 2, lp(l) lc(maroon) yaxis(2) bw(1.5)) ///
	(histogram genderi_points if treatment == 1 & take_up == 1 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity genderi_points if treatment == 1 & take_up == 0 & surveyround == 2, lp(l) lc(green) yaxis(2) bw(1.5)) ///
	(histogram genderi_points if treatment == 1 & take_up == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity genderi_points if treatment == 0 & surveyround == 2, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram genderi_points if treatment == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Midline Distribution of Female Empowerment Index}") ///
	subtitle("{it: points}") ///
	xtitle("Female Empowerment Index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Density", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated (N=55 firms)" ///
                     2 "Treatment group, absent (N=32 firms)" ///
					 3 "Control group (N=89 firms)") ///
               c(1) pos(6) ring(6)) ///
	name(female_empowerment_index_ml, replace)
graph export female_empowerment_index_ml.png, replace
putpdf paragraph, halign(center) 
putpdf image female_empowerment_index_ml.png
putpdf pagebreak
			
			* z-score
gr tw ///
	(kdensity genderi if treatment == 1 & take_up == 1 & surveyround == 2, lp(l) lc(maroon) yaxis(2) bw(0.3)) ///
	(histogram genderi if treatment == 1 & take_up == 1 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity genderi if treatment == 1 & take_up == 0 & surveyround == 2, lp(l) lc(green) yaxis(2) bw(0.3)) ///
	(histogram genderi if treatment == 1 & take_up == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity genderi if treatment == 0 & surveyround == 2, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram genderi if treatment == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Midline Distribution of Female Empowerment Index}") ///
	subtitle("{it:Index calculated based on z-score method}") ///
	xtitle("Female Empowerment Index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Density", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated (N=55 firms)" ///
                     2 "Treatment group, absent (N=32 firms)" ///
					 3 "Control group (N=89 firms)") ///
               c(1) pos(6) ring(6)) ///
	name(female_empowerment_index_ml, replace)
graph export female_empowerment_index_ml.png, replace
putpdf paragraph, halign(center) 
putpdf image female_empowerment_index_ml.png
putpdf pagebreak

*Women's locus of control index
gr tw ///
	(kdensity female_loc if treatment == 1 & take_up == 1 & surveyround == 2, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram female_loc if treatment == 1 & take_up == 1 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity female_loc if treatment == 1 & take_up == 0 & surveyround == 2, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram female_loc if treatment == 1 & take_up == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity female_loc if treatment == 0 & surveyround == 2, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram female_loc if treatment == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Midline Distribution of Women's locus of control index}") ///
	subtitle("{it:Index calculated based on z-score method}") ///
	xtitle("Women's locus of control index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated (N=55 firms)" /// 56 did actually respond to midline
                     2 "Treatment group, absent (N=32 firms)" /// 24 firms did actually respond to midline
					 3 "Control group (N= 89 firms)") /// 77 responded to midline
               c(1) pos(6) ring(6)) ///
	name(female_loc_ml, replace)
graph export female_loc_ml.png, replace
putpdf paragraph, halign(center) 
putpdf image female_loc_ml.png
putpdf pagebreak

	* Women's entrepreneurial effifacy - z score
gr tw ///
	(kdensity female_efficacy if treatment == 1 & take_up == 1 & surveyround == 2, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram female_efficacy if treatment == 1 & take_up == 1 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity female_efficacy if treatment == 1 & take_up == 0 & surveyround == 2, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram female_efficacy if treatment == 1 & take_up == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity female_efficacy if treatment == 0 & surveyround == 2, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram female_efficacy if treatment == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Midline Distribution of Women's entrepreneurial effifacy index}", size (small)) ///
	subtitle("{it:Index calculated based on z-score method}") ///
	xtitle("Women's entrepreneurial effifacy index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated (N=55 firms)" ///
                     2 "Treatment group, absent (N=32 firms)" ///
					 3 "Control group (N=89 firms)") ///
               c(1) pos(6) ring(6)) ///
	name(female_efficacy_ml, replace)
graph export female_efficacy_ml.png, replace
putpdf paragraph, halign(center) 
putpdf image female_efficacy_ml.png
putpdf pagebreak

*graph bar list_exp, over(list_group) - where list_exp provides the number of confirmed affirmations).
graph bar listexp if surveyround==1, over(list_group, relabel(1"Non-sensitive" 2"Sensitive  incl.")) ///
	blabel(total, format(%9.2fc) gap(-0.2)) ///
	title("List experiment (baseline)") ///
ytitle("No. of affirmations") ///
ylabel(0(1)3.2, nogrid) 
gr export bl_bar_listexp.png, replace
putpdf paragraph, halign(center) 
putpdf image bl_bar_listexp.png
putpdf pagebreak

graph bar listexp if surveyround==2, over(list_group, relabel(1"Non-sensitive" 2"Sensitive  incl.")) over(treatment) ///
	blabel(total, format(%9.2fc) gap(-0.2)) ///
	title("List experiment (midline)") ///
ytitle("No. of affirmations") ///
ylabel(0(1)3.2, nogrid) 
gr export ml_bar_listexp.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_bar_listexp.png
putpdf pagebreak

generate new_listexp = listexp - 2
graph bar new_listexp if surveyround==2, over(list_group, relabel(1"Non-sensitive" 2"Sensitive  incl.")) over(treatment) ///
	blabel(total, format(%9.2fc) gap(-0.2)) ///
	title("List experiment (midline)") ///
ytitle("No. of affirmations") ///
ylabel(0(1)3.2, nogrid) 
gr export ml_bar_new_listexp.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_bar_new_listexp.png
putpdf pagebreak

graph hbar listexp if surveyround == 2, over(list_group, relabel(1"Non-sensitive" 2"Sensitive  incl.")) over(treatment, label(labsize(vsmall))) by(pole, note("")) ///
	blabel(total, format(%9.2fc) gap(-0.2)) ///
	title("List experiment question") ///
ytitle("No. of affirmations") ///
ylabel(0(1)3.2, nogrid labsize(vsmall)) 
gr export ml_bar_listexp_pole.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_bar_listexp_pole.png
putpdf pagebreak

****** Section 7: Accounting section ****** 
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 7: Accounting indicators"), bold

*bar chart and boxplots of accounting variable by treatment
     * variable ca_2022:
egen ca_95p = pctile(ca), p(95)
graph bar ca if ca<ca_95p & ca>0, blabel(total, format(%9.2fc)) over(treatment) over (surveyround) ///
	title("Turnover in 2022") ///
	ytitle( "Mean 2022 turnover")
gr export ml_bar_ca_2022.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_bar_ca_2022.png
putpdf pagebreak

graph hbar ca if ca<ca_95p & ca>0, blabel(total, format(%9.2fc)) over(treatment, label(labsize(vsmall))) over(surveyround, label(labsize(small))) by(pole, note("")) ///
	title("Turnover in 2022") ///
	ytitle( "Mean 2022 turnover") ///
	ylabel(, nogrid labsize(vsmall)) 
gr export ml_bar_ca_2022_pole.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_bar_ca_2022_pole.png
putpdf pagebreak

sum ca, d
stripplot ca if ca <ca_95p & ca>0 , by(treatment surveyround, note("")) jitter(4) vertical ///
	ytitle("Turnover in 2022") ///
	yline(`r(p50)', lpattern(dash)) ///
	text(`r(p50)'  0.1 "Median", size(vsmall) place(n)) ///
name(turnover_ml, replace)
gr export turnover_ml.png, replace


	* Distrubtion of ca
graph box ca if ca<ca_95p & ca>0 , over(treatment) over(surveyround) ///
	title("Turnover in 2022 (without outliers)") 
gr export ml_dis_ca_2022.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_dis_ca_2022.png
putpdf pagebreak

graph hbox ca if ca<ca_95p & ca>0 , over(pole) over(treatment, label(labsize(small))) over(surveyround, label(labsize(medium)))  ///
	title("Turnover in 2022 (without outliers)") 
gr export ml_dis_ca_2022_pole.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_dis_ca_2022_pole.png
putpdf pagebreak

     * variable ca_exp_2022:
egen ca_exp_95p = pctile(ca_exp), p(95)
graph bar ca_exp if ca_exp<ca_exp_95p & ca_exp>0, over(treatment) over (surveyround) blabel(total, format(%9.2fc)) ///
	title("Export turnover in 2022") ///
	ytitle( "Mean 2022 export turnover")
gr export ml_bar_ca_exp_2022.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_bar_ca_exp_2022.png
putpdf pagebreak

graph hbar ca_exp if ca_exp<ca_exp_95p & ca_exp>0, blabel(total, format(%9.2fc)) over(treatment, label(labsize(vsmall))) over(surveyround, label(labsize(small))) by(pole, note("")) ///
	title("Export turnover in 2022") ///
	ytitle( "Mean 2022 export turnover") ///
	ylabel(, nogrid labsize(vsmall)) 
gr export ml_bar_ca_exp_2022_pole.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_bar_ca_exp_2022_pole.png
putpdf pagebreak

sum ca_exp, d
stripplot ca_exp if ca_exp <ca_exp_95p & ca_exp>0, by(treatment surveyround, note("")) jitter(4) vertical ///
	ytitle("Export turnover in 2022") ///
	yline(`r(p50)', lpattern(dash)) ///
	text(`r(p50)'  0.1 "Median", size(vsmall) place(n)) ///
	name(export_turnover_ml, replace)
gr export export_turnover_ml.png, replace

* Distrubtion of ca_export
graph box ca_exp if ca_exp<ca_exp_95p & ca_exp>0, over(treatment) over(surveyround) ///
	title("Export Turnover in 2022 (without outliers)") 
gr export ml_dis_ca_exp_2022.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_dis_ca_exp_2022.png
putpdf pagebreak

graph hbox ca_exp if ca_exp<ca_exp_95p & ca>0 , over(pole) over(treatment, label(labsize(small))) over(surveyround, label(labsize(medium)))  ///
	title("Export Turnover in 2022 (without outliers)") 
gr export ml_dis_ca_exp_2022_pole.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_dis_ca_exp_2022_pole.png
putpdf pagebreak

     * variable profit_2022:
sum profit, d
sum profit if profit == 0 & surveyround == 2 // 11 companies state to have exactly 0 profit
sum profit if profit < 0 & surveyround == 2	& profit != -999 // 20 companies reported a loss at midline

tw ///
	(kdensity ihs_profit_w99 if treatment == 1, lp(l) lc(maroon) bw(5)) ///
	(kdensity ihs_profit_w99 if treatment == 0, lp(l) lc(navy) bw(5)) ///
	, ///
	xtitle("profit (ihs-transformed, winsorized)", size(small)) ///
	ytitle("density", size(small)) ///
	legend(symxsize(small) order(1 "Treatment" 2 "Control")  pos(6) row(1)) ///
	name(ml_profit_distribution, replace)
gr export ml_profit_distribution.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_profit_distribution.png
putpdf pagebreak
	 
egen profit_95p = pctile(profit), p(95) 
graph bar profit if profit<profit_95p & profit > -500000, over(treatment) over (surveyround) blabel(total, format(%9.2fc)) ///
	title("Profit in 2022") ///
	ytitle( "Mean 2022 profit") 
gr export ml_bar_profit_2022.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_bar_profit_2022.png
putpdf pagebreak

graph bar profit if profit<profit_95p & profit > -500000, over(treatment, label(labsize(vsmall))) over(surveyround, label(labsize(small))) by(pole, note("")) blabel(total, format(%9.2fc)) ///
	title("Profit in 2022") ///
	ytitle( "Mean 2022 profit") ///
	ylabel(, nogrid labsize(vsmall)) 
gr export ml_bar_profit_2022_pole.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_bar_profit_2022_pole.png
putpdf pagebreak

sum profit, d
stripplot profit if profit <profit_95p & profit > -500000, by(treatment surveyround, note("")) jitter(4) vertical ///
	ytitle("Profit in 2022") ///
	yline(`r(p50)', lpattern(dash)) ///
	text(`r(p50)' 0 "Median", size(vsmall) place(n)) ///
name(profit_ml, replace)
gr export profit_ml.png, replace

* Distrubtion of profit
graph box profit if profit <profit_95p & profit > -100000, over(treatment) over(surveyround) ///
	title("Profit (without outliers)") 
gr export ml_dis_profit.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_dis_profit.png
putpdf pagebreak

graph hbox profit if profit <profit_95p & profit > -100000, over(pole) over(treatment, label(labsize(small))) over(surveyround, label(labsize(medium))) ///
	title("Profit (without outliers)") 
gr export ml_dis_profit_pole.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_dis_profit_pole.png
putpdf pagebreak

tw ///
	(kdensity ihs_profit_w99 if treatment == 1 & surveyround == 1 , lp(l) lc(maroon) bw(5)) ///
	(kdensity ihs_profit_w99 if treatment == 0 & surveyround == 1 , lp(l) lc(navy) bw(5)) ///
	, ///
	xtitle("profit (ihs-transformed, winsorized)", size(small)) ///
	ytitle("density", size(small)) ///
	legend(symxsize(small) order(1 "Treatment" 2 "Control")  pos(6) row(1)) 
	name(bl_profit_distribution, replace)
graph export bl_profit_distribution.png, replace
putpdf paragraph, halign(center) 
putpdf image bl_profit_distribution.png
putpdf pagebreak

tw ///
	(kdensity ihs_profit_w99 if treatment == 1 & surveyround == 2 , lp(l) lc(maroon) bw(5)) ///
	(kdensity ihs_profit_w99 if treatment == 0 & surveyround == 2 , lp(l) lc(navy) bw(5)) ///
	, ///
	xtitle("profit (ihs-transformed, winsorized)", size(small)) ///
	ytitle("density", size(small)) ///
	legend(symxsize(small) order(1 "Treatment" 2 "Control")  pos(6) row(1)) 
	name(ml_profit_distribution, replace)
graph export ml_profit_distribution.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_profit_distribution.png
putpdf pagebreak

*scatter plots by pole
forvalues x = 1(1)4 {
		* between CA and CA_Exp
twoway (scatter ca ca_exp if ca<ca_95p & ca_exp<ca_exp_95p & pole == `x' , title("Proportion de CA exp par rapport au CA- pole`x'")) || ///
(lfit ca ca_exp if ca<ca_95p & ca_exp<ca_exp_95p & pole == `x', lcol(blue))
gr export scatter_capole.png, replace
putpdf paragraph, halign(center) 
putpdf image scatter_capole.png
putpdf pagebreak


}

drop profit_95p ca_exp_95p ca_95p


****** Section 8: Employees & ASS activities ******
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 8: Employment & SSA activities"), bold

*** Africa-related actions********************
graph bar (sum) ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5, over(treatment) ///
	blabel(total, format(%9.2fc) size(vsmall)) ///
	title ("ASS activities") ///
	ytitle("Sum of affirmative firms") ///
	legend(pos (6) col(2) label(1 "Potential client in SSA") label(2 "Commercial partner in SSA") label(3 "External finance for export costs") label(4 "Investment in sales structure") label(5 "Digital innovation or communication system") size(small))
gr export ml_ssa_action.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_ssa_action.png
putpdf pagebreak

graph hbar (sum) ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5, over(pole, label(labsize(vsmall))) over(treatment, label(labsize(small)))  ///
	blabel(total, format(%9.2fc) size(vsmall)) ///
	title ("ASS activities") ///
	ytitle("Sum of affirmative firms") ///
	legend(pos (6) col(2) label(1 "Potential client in SSA") label(2 "Commercial partner in SSA") label(3 "External finance for export costs") label(4 "Investment in sales structure") label(5 "Digital innovation or communication system") size(small))
gr export ml_ssa_action_pole.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_ssa_action_pole.png
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

graph hbar (mean) ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5, over(pole, label(labsize(vsmall))) over(treatment, label(labsize(small)))  ///
	blabel(total, format(%9.2fc) size(vsmall)) ///
	title ("ASS activities") ///
	ytitle("Share of affirmative firms") ///
	legend(pos (6) col(2) label(1 "Potential client in SSA") label(2 "Commercial partner in SSA") label(3 "External finance for export costs") label(4 "Investment in sales structure") label(5 "Digital innovation or communication system") size(small))
gr export ml_ssa_action_share_pole.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_ssa_action_share_pole.png
putpdf pagebreak

graph bar (count) , over(ssa_action1) over(treatment, label(labs(small))) blabel (bar) ///
title("Midline: Potential buyer in SSA country")
graph export ssa_action1.png, replace
putpdf paragraph, halign(center) 
putpdf image ssa_action1.png
putpdf pagebreak

graph bar (count) , over(ssa_action2) over(treatment, label(labs(small))) blabel (bar) ///
title("Midline: Commercial partner in SSA")
graph export ssa_action2.png, replace
putpdf paragraph, halign(center) 
putpdf image ssa_action2.png
putpdf pagebreak

graph bar (count) , over(ssa_action3) over(treatment, label(labs(small))) blabel (bar) ///
title("Midline: External finance for export costs")
graph export ssa_action3.png, replace
putpdf paragraph, halign(center) 
putpdf image ssa_action3.png
putpdf pagebreak

graph bar (count) , over(ssa_action4) over(treatment, label(labs(small))) blabel (bar) ///
title("Midline: Investment in sales structure")
graph export ssa_action4.png, replace
putpdf paragraph, halign(center) 
putpdf image ssa_action4.png
putpdf pagebreak

graph bar (count) , over(ssa_action5) over(treatment, label(labs(small))) blabel (bar) ///
title("Midline: Digital innovation or communication system")
graph export ssa_action5.png, replace
putpdf paragraph, halign(center) 
putpdf image ssa_action5.png
putpdf pagebreak


**** Employment********************

 * Generate graphs to see difference of employment between baseline & midline
*Bart chart: sum
graph bar (sum) employes if employes >= 0, over(treatment, label(labs(small))) over(surveyround, label(labs(small))) ///
	blabel(total, format(%9.0fc) size(vsmall)) ///
	title("Sum of full time employees") 
gr export fte_details_sum_bar.png, replace
putpdf paragraph, halign(center) 
putpdf image fte_details_sum_bar.png
putpdf pagebreak

graph bar (sum) car_empl1 if car_empl1 >= 0, over(treatment, label(labs(small))) over(surveyround, label(labs(small))) ///
	blabel(total, format(%9.0fc) size(vsmall)) ///
		title("Sum of female employees")  
gr export fte_femmes_details_sum_bar.png, replace
putpdf paragraph, halign(center) 
putpdf image fte_femmes_details_sum_bar.png
putpdf pagebreak

graph bar (sum) car_empl4 if car_empl4 >= 0, over(treatment, label(labs(small))) over(surveyround, label(labs(small))) ///
	blabel(total, format(%9.0fc) size(vsmall)) ///
	title("Sum of part time employees")  
gr export pte_details_sum_bar.png, replace
putpdf paragraph, halign(center) 
putpdf image pte_details_sum_bar.png
putpdf pagebreak

graph bar (sum) car_empl2 if car_empl2 >= 0, over(treatment, label(labs(small))) over(surveyround, label(labs(small))) ///
	blabel(total, format(%9.0fc) size(vsmall)) ///
	title("Sum of young employees") 
gr export young_employees_details_sum_bar.png, replace
putpdf paragraph, halign(center) 
putpdf image young_employees_details_sum_bar.png
putpdf pagebreak

*Bart chart: mean
graph bar (mean) employes if employes >= 0, over(treatment, label(labs(small))) over(surveyround, label(labs(small))) ///
	blabel(total, format(%9.0fc) size(vsmall)) ///
	title("Mean of full time employees") 
gr export fte_details_mean_bar.png, replace
putpdf paragraph, halign(center) 
putpdf image fte_details_mean_bar.png
putpdf pagebreak

graph bar (mean) car_empl1 if car_empl1 >= 0, over(treatment, label(labs(small))) over(surveyround, label(labs(small))) ///
	blabel(total, format(%9.0fc) size(vsmall)) ///
	title("Mean of female employees") 
gr export fte_femmes_details_mean_bar.png, replace
putpdf paragraph, halign(center) 
putpdf image fte_femmes_details_mean_bar.png
putpdf pagebreak

graph bar (mean) car_empl4 if car_empl4 >= 0, over(treatment, label(labs(small))) over(surveyround, label(labs(small))) ///
	blabel(total, format(%9.0fc) size(vsmall)) ///
	title("Mean of part time employees")
gr export pte_details_mean_bar.png, replace
putpdf paragraph, halign(center) 
putpdf image pte_details_mean_bar.png
putpdf pagebreak

graph bar (mean) car_empl2 if car_empl2 >= 0, over(treatment, label(labs(small))) over(surveyround, label(labs(small))) ///
	blabel(total, format(%9.0fc) size(vsmall)) ///
	title("Mean of young employees")  
gr export young_employees_details_mean_bar.png, replace
putpdf paragraph, halign(center) 
putpdf image young_employees_details_mean_bar.png
putpdf pagebreak

* Distribution of employees
egen employes_98p = pctile(employes), p(98) 
graph box employes if employes >= 0 & employes <employes_98p, over(treatment) over(surveyround) ///
	title("Total employees") 
gr export fte_dis.png, replace
putpdf paragraph, halign(center) 
putpdf image fte_dis.png
putpdf pagebreak

egen car_empl1_98p = pctile(car_empl1), p(98) 
graph box car_empl1 if car_empl1 >= 0 & car_empl1 <150, over(treatment) over(surveyround) ///
	title("Female employees") 
gr export female_dis.png, replace
putpdf paragraph, halign(center) 
putpdf image female_dis.png
putpdf pagebreak

egen car_empl2_98p = pctile(car_empl2), p(98)  
graph box car_empl2 if car_empl2 >= 0 & car_empl2 <car_empl2_98p, over(treatment) over(surveyround) ///
	title("Young employees") 
gr export youngemploye_dis.png, replace
putpdf paragraph, halign(center) 
putpdf image youngemploye_dis.png
putpdf pagebreak

egen car_empl4_98p = pctile(car_empl4), p(98)  
graph box car_empl4 if car_empl4 >= 0 & car_empl4 <car_empl4_98p, over(treatment) over(surveyround) ///
	title("Part-time employees") 
gr export pte_dis.png, replace
putpdf paragraph, halign(center) 
putpdf image pte_dis.png
putpdf pagebreak

egen car_empl5_98p = pctile(car_empl5), p(98)  
graph box car_empl5 if car_empl5 >= 0 & car_empl5 <car_empl5_98p, over(treatment) over(surveyround) ///
	title("Qaulified employees") 
gr export pte_dis.png, replace
putpdf paragraph, halign(center) 
putpdf image pte_dis.png
putpdf pagebreak

* Generate graphs to see difference of profit between baseline & midline
preserve
collapse (mean) ihs_profit_w99, by(surveyround treatment take_up)
twoway (connected ihs_profit_w99 surveyround if treatment== 0 & take_up==0) (connected ihs_profit_w99 surveyround if treatment== 1 & take_up==0) (connected ihs_profit_w99 surveyround if treatment== 1 & take_up ==1), xline(1.5) xlabel (1(1)2) ytitle("Mean of profit") xtitle("1- Baseline 2- Midline ") legend(label(1 Control) label(2 Absent) label(3 Present)) ///
ylabel(0(1)8, nogrid) 
graph export ihs_profit_w99_plot2_details.png, replace
putpdf paragraph, halign(center) 
putpdf image ihs_profit_w99_plot2_details.png
putpdf pagebreak
restore
}

putpdf save "comparison_midline_baseline", replace

*blog post graph
graph bar (mean) exp_kno_ft_co exp_kno_ft_ze ssa_action1 exp_invested if surveyround ==2, over(treatment) blabel(total, format(%9.2fc) gap(-0.2)) ///
	legend (pos(6) row(2) label (1 "COMESA") label(2 "ZECLAF") label(3 "Commercial partner in SSA") label(4 "Has invested in exports") size(vsmall)) ///
	title("Export Knowledge") ///
	ylabel(0(0.2)1, nogrid) 
gr export ml_blog.png, replace


***********************************************************************
* 	PART 4:  Mdiline Indexes
***********************************************************************

putpdf clear
putpdf begin 
putpdf paragraph

putpdf text ("Consortia: Midline Indexes"), bold linebreak
putpdf text ("Date: `c(current_date)'"), bold linebreak
putpdf paragraph, halign(center) 

{
* Midline Management Index
gr tw ///
	(kdensity mpi if treatment == 1 & take_up == 1 & surveyround == 2, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram mpi if treatment == 1 & take_up == 1 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity mpi if treatment == 1 & take_up == 0 & surveyround == 2, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram mpi if treatment == 1 & take_up == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity mpi if treatment == 0 & surveyround == 2, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram mpi if treatment == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Midline Distribution of Management Index}") ///
	subtitle("{it:Index calculated based on z-score method}") ///
	xtitle("Management index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated (N=*** firms)" ///
                     2 "Treatment group, absent (N=*** firms)" ///
					 3 "Control group (N=*** firms)") ///
               c(1) pos(6) ring(6)) ///
	name(mngtvars_ml, replace)
graph export mngtvars_ml.png, replace
putpdf paragraph, halign(center) 
putpdf image mngtvars_ml.png
putpdf pagebreak

* Midline Export readiness index	
gr tw ///
	(kdensity eri if treatment == 1 & take_up == 1 & surveyround == 2, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram eri if treatment == 1 & take_up == 1 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity eri if treatment == 1 & take_up == 0 & surveyround == 2, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram eri if treatment == 1 & take_up == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity eri if treatment == 0 & surveyround == 2, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram eri if treatment == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Midline Distribution of Export readiness index}") ///
	subtitle("{it:Index calculated based on z-score method}") ///
	xtitle("Export readiness index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated (N=*** firms)" ///
                     2 "Treatment group, absent (N=*** firms)" ///
					 3 "Control group (N= *** firms)") ///
               c(1) pos(6) ring(6)) ///
	name(exportprep_ml, replace)
graph export exportprep_ml.png, replace
putpdf paragraph, halign(center) 
putpdf image exportprep_ml.png
putpdf pagebreak


	* Midline Gender index	
gr tw ///
	(kdensity genderi if treatment == 1 & take_up == 1 & surveyround == 2, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram genderi if treatment == 1 & take_up == 1 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity genderi if treatment == 1 & take_up == 0 & surveyround == 2, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram genderi if treatment == 1 & take_up == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity genderi if treatment == 0 & surveyround == 2, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram genderi if treatment == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Midline Distribution of Gender index}") ///
	subtitle("{it:Index calculated based on z-score method}") ///
	xtitle("Gender index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated (N=*** firms)" ///
                     2 "Treatment group, absent (N=*** firms)" ///
					 3 "Control group (N= *** firms)") ///
               c(1) pos(6) ring(6)) ///
	name(gendervars_ml, replace)
graph export gendervars_ml.png, replace
putpdf paragraph, halign(center) 
putpdf image gendervars_ml.png
putpdf pagebreak

	* Export readiness SSA index -Z Score
gr tw ///
	(kdensity eri_ssa if treatment == 1 & take_up == 1 & surveyround == 2, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram eri_ssa if treatment == 1 & take_up == 1 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity eri_ssa if treatment == 1 & take_up == 0 & surveyround == 2, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram eri_ssa if treatment == 1 & take_up == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity eri_ssa if treatment == 0 & surveyround == 2, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram eri_ssa if treatment == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Midline Distribution of Export readiness SSA index}") ///
	subtitle("{it:Index calculated based on z-score method}") ///
	xtitle("Export readiness SSA index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated (N=*** firms)" ///
                     2 "Treatment group, absent (N=*** firms)" ///
					 3 "Control group (N= *** firms)") ///
               c(1) pos(6) ring(6)) ///
	name(exportmngt_ml, replace)
graph export exportmngt_ml.png, replace
putpdf paragraph, halign(center) 
putpdf image exportmngt_ml.png
putpdf pagebreak



	* Women's entrepreneurial initiaitve - z score
gr tw ///
	(kdensity female_initiative if treatment == 1 & take_up == 1 & surveyround == 2, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram female_initiative if treatment == 1 & take_up == 1 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity female_initiative if treatment == 1 & take_up == 0 & surveyround == 2, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram female_initiative if treatment == 1 & take_up == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity female_initiative if treatment == 0 & surveyround == 2, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram female_initiative if treatment == 0 & surveyround == 2, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Midline Distribution of Women's entrepreneurial initiaitve index}", size (small)) ///
	subtitle("{it:Index calculated based on z-score method}") ///
	xtitle("Women's entrepreneurial initiaitve index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated (N=*** firms)" ///
                     2 "Treatment group, absent (N=*** firms)" ///
					 3 "Control group (N= *** firms)") ///
               c(1) pos(6) ring(6)) ///
	name(female_initiative_ml, replace)
graph export female_initiative_ml.png, replace
putpdf paragraph, halign(center) 
putpdf image female_initiative_ml.png
putpdf pagebreak


	
}
putpdf save "midline_index_statistics", replace

