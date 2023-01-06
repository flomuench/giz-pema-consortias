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
use "$ml_final/ml_final", clear

	* set directory to checks folder
cd "$ml_output"
set graphics off
set scheme s1color

	* create pdf document
putpdf clear
putpdf begin 
putpdf paragraph

putpdf text ("Consortias: survey progress, firm characteristics"), bold linebreak

putpdf text ("Date: `c(current_date)'"), bold linebreak


***********************************************************************
* 	PART 2:  Survey progress		  			
***********************************************************************
putpdf paragraph, halign(center) 
putpdf text ("consortias : midline survey progress")

{
	* Share of firms that started the survey
count if survey_started==1
gen share= (`r(N)'/181)*100
graph bar share, blabel(total, format(%9.2fc)) ///
	title("La part des entreprises qui au moins ont commence à remplir") note("Date: `c(current_date)'") ///
	ytitle("Number of entries")
graph export ml_responserate.png, replace
putpdf paragraph, halign(center)
putpdf image ml_responserate.png
putpdf pagebreak
drop share
	
format %-td date 
graph twoway histogram date, frequency width(1) ///
		tlabel(04mar2022(1)01apr2022, angle(60) labsize(vsmall)) ///
		ytitle("responses") ///
		title("{bf:Midline survey: number of responses}") 
gr export ml_survey_response_byday.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_survey_response_byday.png
putpdf pagebreak
		
	
	* firms with complete entries
count if survey_completed==1
gen share= (`r(N)'/181)*100
graph bar share, blabel(total, format(%9.2fc)) ///
	title("La part des entreprises avec reponses complète") 
gr export complete_responses.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_complete_responses.png
putpdf pagebreak
drop share
*/
	* firms with validated entries
count if validation==1
gen share= (`r(N)'/181)*100
graph bar share, blabel(total, format(%9.2fc)) ///
	title("La part des entreprises avec reponses validés")
gr export ml_validated_responses.png, replace
putpdf paragraph, halign(center) 
putpdf ml_image validated_responses.png
putpdf pagebreak
drop share

*Quality of advice*

sum net_nb_qualite,d
histogram net_nb_qualite, width(1) frequency addlabels xlabel(0(1)10, nogrid format(%9.0f)) discrete ///
	xline(`r(mean)', lpattern(1)) xline(`r(p50)', lpattern(dash)) ///
	ytitle("No. of firms") ///
	xtitle("Quality of advice of the business network") ///
	ylabel(0(5)50 , nogrid) ///
	text(100 `r(mean)' "Mean", size(small) place(e)) ///
	text(100 `r(p50)' "Median", size(small) place(e))
gr export ml_quality_advice.png, replace
putpdf paragraph, halign(center) 
putpdf ml_quality_advice.png
putpdf pagebreak	

	*Number of female and male CEO met*
graph bar net_nb_m net_nb_f, over(pole, relabel(1 "Agriculture" 2"Handcrafts& Cosmetics" 3"Services" 4"IT")) over(treatment)stack ///
	ytitle("Person") ///
	ylabel(0(2)16, nogrid) ///
	legend(order(1 "Male CEO" 2 "Female CEO") pos(6))
gr export ml_CEO_met, replace
putpdf paragraph, halign(center) 
putpdf ml_CEO_met.png
putpdf pagebreak	

graph bar (mean) net_nb_m net_nb_f , over(treatment) blabel(total, format(%9.2fc) gap(-0.2))  ///
	title("Number of female vs male CEO met") ///
	ylabel(0(1)11, nogrid) /// 
	legend(order(1 "Male CEO" 2 "Female CEO") pos(6))
	gr export ml_mean_CEO_met, replace	
putpdf paragraph, halign(center) 
putpdf ml_mean_CEO_met.png
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
	xlabel(0(5)35, nogrid format(%9.0f)) ///
	name(network_density, replace)
gr export ml_network_density.png, replace
putpdf paragraph, halign(center) 
putpdf ml_network_density.png
putpdf pagebreak	

*graph bar list_exp, over(list_group) - where list_exp provides the number of confirmed affirmations).
graph bar listexp, over(list_group, sort(1) relabel(1"Non-sensitive" 2"Sensitive option incl.")) ///
	blabel(total, format(%9.2fc) gap(-0.2)) ///
ytitle("No. of affirmations") ///
ylabel(0(1)3.2, nogrid) 
gr export ml_bar_listexp.png, replace
putpdf paragraph, halign(center) 
putpdf ml_bar_listexp.png
putpdf pagebreak

*Interactions between CEO	
graph bar (mean) net_coop_pos net_coop_neg, blabel(total, format(%9.1fc) gap(-0.2)) ///
	legend (pos(6) row(6) label (1 "Positive answers for the perception of interactions between CEOs") label(2 "Negative answers for the perception of interactions between CEOs")) ///
	title("Perception of interactions between CEOs") ///
	ylabel(0(1)3, nogrid) 
gr export ml_perceptions_interactions.png, replace
putpdf paragraph, halign(center) 
putpdf ml_perceptions_interactions.png
putpdf pagebreak
	
graph hbar netcoop5 netcoop7 netcoop2 netcoop1 netcoop3 netcoop9 netcoop8 netcoop10 netcoop4 netcoop6, blabel(total, format(%9.2fc) gap(-0.2))  ///
	legend (pos(6) row(6) label (1 "Power") label(2 "Partnership") ///
	label(3 "Communicate") label(4 "Win") label(5 "Trust") ///
	label(6 "Connect") label(7 "Opponent") label(8 "Dominate") ///
	label(9 "Beat") label(10 "Retreat")) ///
	title("Perception of interactions between CEOs") ///
	ylabel(0(0.5)0.7, nogrid) 
gr export ml_perceptions_interactions_details.png, replace
putpdf paragraph, halign(center) 
putpdf ml_perceptions_interactions_details.png
putpdf pagebreak
	
*Locus of control
graph hbar (mean)  car_loc_succ car_loc_exp car_loc_env, blabel(total, format(%9.2fc) gap(-0.2)) ///
	legend (pos(6) row(6) label (1 "Able to determine the success of her business") label (2 "Master export administrative and logistic procedures") ///
	label  (3 "Control over the internal and external environment of the firm") ) ///
	title("Locus of control for female entrepreuneurs") ///
	ylabel(0(1)5, nogrid) 
gr export ml_locuscontrol.png, replace
putpdf paragraph, halign(center) 
putpdf ml_locuscontrol.png
putpdf pagebreak
	
*Locus of entrepreuneurhsip
graph hbar (mean) car_efi_conv car_efi_nego car_efi_fin1, blabel(total, format(%9.2fc) gap(-0.2)) ///
	legend (pos(6) row(9) label(1 "Manage to convince employees and partners to agree") label(2 "Negotiate the affairs of the company well") ///
	label(3 "Have the skills to access new sources of funding")size(vsmall)) ///
	title("Locus of entrepreuneurhsip for female entrepreuneurs") ///
	ylabel(0(1)5, nogrid)    
gr export ml_locusefi.png, replace
putpdf paragraph, halign(center) 
putpdf ml_locusefi.png
putpdf pagebreak	
	
*bar chart and boxplots of accounting variable by poles
     * variable ca_2022:
egen ca_2022_95p = pctile(ca_2022), p(95)
graph bar ca_2022 if ca_2022<ca_2022_95p, over(pole, sort(1)) blabel(total, format(%9.2fc))
gr export ml_bar_ca_2022.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_bar_ca_2022.png
putpdf pagebreak

stripplot ca_2022 if ca_2022<ca_2022_95p, over(pole) vertical
gr export ml_strip_ca_2022.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_strip_ca_2022.png
putpdf pagebreak

     * variable ca_exp_2022:
egen ca_exp_2022_95p = pctile(ca_exp_2022), p(95)
graph bar ca_exp_2022 if ca_exp_2022<ca_exp_2022_95p, over(pole, sort(1)) blabel(total, format(%9.2fc))
gr export ml_bar_ca_exp_2022.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_bar_ca_exp_2022.png
putpdf pagebreak

stripplot ca_exp_2022 if ca_exp_2022<ca_exp_2022_95p , over(pole) vertical
gr export ml_strip_ca_exp_2022.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_strip_ca_exp_2022.png
putpdf pagebreak

     * variable profit_2022:
egen profit_2022_95p = pctile(profit_2022), p(95)
graph bar profit_2022 if profit_2022<profit_2022_95p, over(pole, sort(1)) blabel(total, format(%9.2fc))
gr export ml_bar_profit_2022.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_bar_profit_2022.png
putpdf pagebreak

stripplot profit_2022 if profit_2022<profit_2022_95p, over(pole) vertical
gr export ml_strip_profit_2022.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_strip_profit_2022.png
putpdf pagebreak

     * variable exprep_inv:
egen exprep_inv_95p = pctile(exprep_inv), p(95)
graph bar exprep_inv if exprep_inv<exprep_inv_95p, over(pole, sort(1)) blabel(total, format(%9.2fc))
gr export ml_bar_exprep_inv.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_bar_exprep_inv.png
putpdf pagebreak

stripplot exprep_inv if exprep_inv<exprep_inv_95p, over(pole) vertical
gr export ml_strip_exprep_inv.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_strip_exprep_inv.png
putpdf pagebreak

*scatter plots between CA and CA_Exp
scatter ca_exp_2022 ca_2022 if ca_2022<ca_2022_95p & ca_exp_2022<ca_exp_2022_95p, title("Proportion des bénéfices d'exportation par rapport au bénéfice total")
gr export ml_scatter_ca.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_scatter_ca.png
putpdf pagebreak

*scatter plots between CA_Exp and exprep_inv
scatter ca_exp_2022 exprep_inv if ca_exp_2022<ca_exp_2022_95p & exprep_inv<exprep_inv_95p, title("Part de l'investissement dans la préparation des exportations par rapport au CA à l'exportation")
gr export ml_scatter_exprep.png, replace
putpdf paragraph, halign(center) 
putpdf ml_image scatter_exprep.png
putpdf pagebreak

*scatter plots by pole
forvalues x = 1(1)4 {
		* between CA and CA_Exp
twoway (scatter ca_2022 ca_exp_2022 if ca_2022<ca_2022_95p & ca_exp_2022<ca_exp_2022_95p & pole == `x' , title("Proportion de CA exp par rapport au CA- pole`x'")) || ///
(lfit ca_2022 ca_exp_2022 if ca_2022<ca_2022_95p & ca_exp_2022<ca_exp_2022_95p & pole == `x', lcol(blue))
gr export ml_scatter_capole.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_scatter_capole.png
putpdf pagebreak
}

*Export management/readiness
graph hbar (mean) exp_pra_cible exp_pra_plan exp_pra_mission exp_pra_douane exp_pra_foire exp_pra_rexp exp_pra_sci, blabel(total, format(%9.1fc) gap(-0.2)) ///
	legend (pos(6) row(7) label (1 "Undertake an analysis of target export markets") label(2 "Maintain or develop an export plan") ///
	label(3 "Undertake a trade mission/travel to one of target markets") label(4 "Access the customs website") label(5 "Participate in international trade exhibitions/fairs") ///
	label(6 "Designate an employee in charge of export-related activities") label(7 "Engage or work with an international trading company")size(vsmall)) ///
	title("Export Readiness Practices") ///
	ylabel(0(0.2)1, nogrid)    
gr export ml_erp.png, replace
putpdf paragraph, halign(center) 
putpdf image ml_erp.png
putpdf pagebreak	
	

	
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
}
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

