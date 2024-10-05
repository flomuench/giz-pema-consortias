***********************************************************************
* 			Descriptive Statistics in master file *					  
***********************************************************************
*																	  
*	PURPOSE: Understand the structure of the data from the endline					  
*																	  
*	OUTLINE: 	PART 1: Paths
*				PART 2: Endline statistics	  

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

if "`c(username)'" == "MUNCHFA" | "`c(username)'" == "fmuench"  {
	set scheme stcolor
} 
	else {

set scheme s1color
		
	}
	

***********************************************************************
* 	PART 2: Endline statistics
***********************************************************************
* create word document
set graphics on


putpdf clear
putpdf begin 
putpdf paragraph

putpdf text ("Consortia: Endline Statistics"), bold linebreak

putpdf text ("Date: `c(current_date)'"), bold linebreak
putpdf paragraph, halign(center) 

****** Section 1: Response rate & take-up ******
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 1: Survey Progress Overview"), bold
{
* response rate
graph bar (count) attest if surveyround ==3, over(treatment) blabel(total, format(%9.0fc)) ///
	title("Number of companies that have validated their answers", pos(12)) ///
	ytitle("Number of entries")
graph export el_reponse_rate.png, width(5000) replace
putpdf paragraph, halign(center)
putpdf image el_reponse_rate.png, width(5000)
putpdf pagebreak

graph bar (sum) refus, over(treatment) blabel(total, format(%9.0fc)) by(surveyround, note("{bf:Note}: There are 176 firms in total. 87 in treatment, and 89 in control. ML & EL response rates are 82% & 68%.") title("Attrition") rows(1))  ///
	ytitle("Number of companies") ///
	ylabel(0(5)35, nogrid) 
graph export "${master_output}/figures/response_rate/el_attritionrate.png", replace
putpdf paragraph, halign(center)
putpdf image el_attritionrate.png
putpdf pagebreak


graph bar (count) attest if surveyround ==3, over(take_up) blabel(total, format(%9.0fc)) ///
	title("Number of companies that have validated their answers", pos(12)) ///
	ytitle("Number of entries")
graph export el_reponse_rate_take_up.png, width(5000) replace
putpdf paragraph, halign(center)
putpdf image el_reponse_rate_take_up.png, width(5000)
putpdf pagebreak

graph bar (sum) refus if surveyround == 3, over(take_up) blabel(total, format(%9.0fc)) ///
	title("Endline refusal") note("Date: `c(current_date)'") ///
	ytitle("Number of entries") ///
	ylabel(0(5)20, nogrid) 
graph export el_reponse_rate_take_up.png, width(5000) replace
putpdf paragraph, halign(center)
putpdf image el_reponse_rate_take_up.png, width(5000)
putpdf pagebreak

* Take-up 
gen one = 1

graph bar (sum) one if treatment == 1 & surveyround != 1, blabel(total, format(%9.0fc)) over(take_up) by(surveyround, note("")) ///
	legend (pos(1) row(1) label(1 "Drop-out") label(2 "Participate")) ///
	ytitle("Number of firms")	
graph export "${master_output}/figures/take_up/take_up.png", replace
putpdf paragraph, halign(center)
putpdf image takeup.png
putpdf pagebreak

* Take up by consortia
graph bar (sum) one if surveyround == 3 & treatment == 1, blabel(total, format(%9.0fc)) over(take_up) by(pole, note("")) ///
	legend (pos(1) row(1) label(1 "Drop-out") label(2 "Participate")) ///
	ytitle("Number of firms")
graph export "${master_output}/figures/take_up/takeup_pole.png", replace
putpdf paragraph, halign(center)
putpdf image takeup_pole.png
putpdf pagebreak

graph bar (sum) one if surveyround != 1 & treatment == 1, blabel(total, format(%9.0fc)) over(take_up) by(pole surveyround, note("") cols(2)) ///
	legend (pos(1) row(1) label(1 "Drop-out") label(2 "Participate")) ///
	ytitle("Number of firms")
graph export "${master_output}/figures/take_up/takeup_pole_surveyround.png", replace


}

****** Section 2: innovation ******
{
cd "${master_output}/figures/endline/innovation"
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 2: Innovation"), bold

	*Innovated or not ?
graph bar (mean) innovated if surveyround ==3, over(treatment, label(labs(small))) blabel(total, format(%9.2fc) gap(-0.2)) ///
	ylabel(0(0.25)1, nogrid) 
	gr export el_innovated_share.png, replace
	putpdf paragraph, halign(center) 
	putpdf image el_innovated_share.png
	putpdf pagebreak 

graph bar (mean) innovated if surveyround ==3, over(take_up, label(labs(small))) blabel(total, format(%9.2fc) gap(-0.2)) ///
	ylabel(0(0.25)1, nogrid) 
	gr export el_innovated_take_up.png, replace
	putpdf paragraph, halign(center) 
	putpdf image el_innovated_take_up.png
	putpdf pagebreak 
	
	*Products or services innovations
betterbar inno_product_imp inno_product_new inno_none if surveyround==3, over(take_up) barlab ci ///
	title("Products or services innovations", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_psinnovation.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_psinnovation.png, width(6000)
putpdf pagebreak

	*Type of innovations
betterbar proc_prod_correct proc_mark_correct inno_org_correct if surveyround==3, over(take_up) barlab ci ///
	title("Type of innovations", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_typeinnovation.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_typeinnovation.png, width(6000)
putpdf pagebreak

	*Source of the innovation	
betterbar inno_mot_cons inno_mot_cont inno_mot_eve inno_mot_client inno_mot_dummyother if surveyround==3, over(take_up) barlab ci ///
	title("Source of innovations", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_sourceinnovation.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_sourceinnovation.png, width(6000)
putpdf pagebreak


* Entreprise model
graph bar (count) if surveyround == 3, over(entreprise_model) over(take_up)  blabel(total, format(%9.1fc) gap(-0.2)) ///
	legend (pos(6) row(3)) ///
	subtitle("Entreprise model")
gr export el_entreprise_model.png, replace
putpdf paragraph, halign(center) 
putpdf image el_entreprise_model.png
putpdf pagebreak

*Endline Innovation practices index
gr tw ///
	(kdensity ipi if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram ipi if treatment == 1 & take_up == 1 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity ipi if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram ipi if treatment == 1 & take_up == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity ipi if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram ipi if treatment == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Endline Distribution of Innovation practices index}", size(medium)) ///
	subtitle("{it:Index calculated based on z-score method}") ///
	xtitle("Innovation practices index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
					 3 "Control group") ///
               c(1) pos(6) ring(6)) ///
	name(ipi_el, replace)
graph export ipi_el.png, replace
putpdf paragraph, halign(center) 
putpdf image ipi_el.png
putpdf pagebreak

*Endline Innovation practices index - points
gr tw ///
	(kdensity inno_points if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram inno_points if treatment == 1 & take_up == 1 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity inno_points if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram inno_points if treatment == 1 & take_up == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity inno_points if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram inno_points if treatment == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Endline Distribution of Innovation practices index}", size(medium)) ///
	subtitle("{it:Index calculated based on points}") ///
	xtitle("Innovation practices index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
					 3 "Control group") ///
               c(1) pos(6) ring(6)) ///
	name(inno_points_el, replace)
graph export inno_points_el.png, replace
putpdf paragraph, halign(center) 
putpdf image inno_points_el.png
putpdf pagebreak

*Endline Corrected Innovation practices index
gr tw ///
	(kdensity ipi_correct if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram ipi_correct if treatment == 1 & take_up == 1 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity ipi_correct if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram ipi_correct if treatment == 1 & take_up == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity ipi_correct if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram ipi_correct if treatment == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Endline Distribution of Innovation practices index (corrected)}", size(medium)) ///
	subtitle("{it:Index calculated based on z-score method}") ///
	xtitle("Innovation practices index (corrected)") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
					 3 "Control group") ///
               c(1) pos(6) ring(6)) ///
	name(ipi_correct_el, replace)
graph export ipi_correct_el.png, replace
putpdf paragraph, halign(center) 
putpdf image ipi_correct_el.png
putpdf pagebreak

*Endline Corrected Innovation practices index - points
gr tw ///
	(kdensity correct_inno_points if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram correct_inno_points if treatment == 1 & take_up == 1 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity correct_inno_points if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram correct_inno_points if treatment == 1 & take_up == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity correct_inno_points if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram correct_inno_points if treatment == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Endline Distribution of Innovation practices index (corrected)}", size(medium)) ///
	subtitle("{it:Index calculated based on points}") ///
	xtitle("Innovation practices index (corrected)") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
					 3 "Control group") ///
               c(1) pos(6) ring(6)) ///
	name(correct_inno_points_el, replace)
graph export correct_inno_points_el.png, replace
putpdf paragraph, halign(center) 
putpdf image correct_inno_points_el.png
putpdf pagebreak

}

****** Section 3: Export ******
{
cd "${master_output}/figures/endline/export"
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 3: Export"), bold

*** FOR PRESENTATION
	* Export dummy
lab var export_1 "Exported 2023/2024"
betterbar export_1 if surveyround == 3, over(treatment) barlab ci v ///
	ylabel(0(.1)1,labsize(medium) angle(horizontal)) ///
	xlabel(, labsize(medium)) ///
		legend (pos(6) row(1))
graph export correct_inno_points_el.png, replace

	* Export countries
betterbar exp_pays_w95 if surveyround == 3, over(treatment) barlab ci v ///
	ylabel(0(.5)2,labsize(medium) angle(horizontal)) ///
	xlabel(, labsize(medium)) ///
		legend (pos(6) row(1))
graph export correct_inno_points_el.png, replace

	* Sales growthS
lab var ca_rel_growth "Growth relative to baseline"
betterbar ca_rel_growth if surveyround == 3 & ca_rel_growth <= 6.5, over(treatment) barlab ci v ///
	ylabel(0(.1)2,labsize(medium) angle(horizontal)) ///
	xlabel(, labsize(medium)) ///
	legend (pos(6) row(1)) 

	
ksmirnov ca_rel_growth if surveyround == 3 & ca_rel_growth < 6.5, by(treatment)
ksmirnov ca_rel_growth_w95 if surveyround == 3, by(treatment)

ksmirnov ca_w95_rel_growth if surveyround == 3, by(take_up)
ksmirnov ca_rel_growth_w95 if surveyround == 3, by(take_up)
ttest ca_rel_growth_w95 if surveyround == 3, by(take_up)


reg ca_rel_growth_w95 i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
ivreg2 ca_rel_growth_w95 i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
	
twoway  (kdensity ca_rel_growth if treatment == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(.5)) ///
        (kdensity ca_rel_growth if treatment == 0 & surveyround == 3, lp(l) lc(green) yaxis(2)  bw(.5)), ///
		xtitle("Growth rate of sales relative to baseline") ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group" ///
                     2 "Control group") ///
               col(1) pos(6) ring(6)) 
			   
twoway  (kdensity ca_rel_growth if treatment == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(.5)) ///
        (kdensity ca_rel_growth if treatment == 0 & surveyround == 3, lp(l) lc(green) yaxis(2)  bw(.5)), ///
		xtitle("Growth rate of sales relative to baseline") ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group" ///
                     2 "Control group") ///
               col(1) pos(6) ring(6)) 
			   
			   
			   
twoway  (kdensity ca_rel_growth_w95 if take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(.5)) ///
        (kdensity ca_rel_growth_w95 if take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2)  bw(.5)), ///
		xtitle("Growth rate of sales relative to baseline") ///
        legend(rows(3) symxsize(small) ///
               order(1 "Take-up = 1" ///
                     2 "Take-up = 0 (incl. control group)") ///
               col(1) pos(6) ring(6)) 
			   
twoway  (kdensity profit_rel_growth_w95 if take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(.5)) ///
        (kdensity profit_rel_growth_w95 if take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2)  bw(.5)), ///
		xtitle("Growth rate of profits relative to baseline") ///
        legend(rows(3) symxsize(small) ///
               order(1 "Take-up = 1" ///
                     2 "Take-up = 0 (incl. control group)") ///
               col(1) pos(6) ring(6)) 
			   

twoway  (kdensity ca_abs_growth_w95 if take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2)) ///
        (kdensity ca_abs_growth_w95 if take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2)), ///
		xtitle("Nominal Growth of Sales Relative to Baseline") ///
        legend(rows(3) symxsize(small) ///
               order(1 "Take-up = 1" ///
                     2 "Take-up = 0 (incl. control group)") ///
               col(1) pos(6) ring(6)) 	
			  
			   
egen tot_sales_el_t = sum(ca_w95) if treatment == 1 & surveyround == 3		   
egen tot_sales_el_c = sum(ca_w95) if treatment == 0 & surveyround == 3	  
sum tot_sales_el_t
local t = r(mean)	 
sum tot_sales_el_c   
local c = r(mean)

display `t' - `c' 			// 5,095,520 --> additional sales!
display (`t' - `c')*0.19	// 968,148.8 --> additional tax return!


egen tot_sales_el_t = sum(ca_w95) if treatment == 1 & surveyround == 3		   
egen tot_sales_el_c = sum(ca_w95) if treatment == 0 & surveyround == 3	  
sum tot_sales_el_t
local t = r(mean)	 
sum tot_sales_el_c   
local c = r(mean)

display `t' - `c'
display (`t' - `c')*0.19


twoway  (kdensity ca_w95 if take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2)) ///
        (kdensity ca_w95 if take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2)), ///
		xtitle("Sales, winsorized") ///
        legend(rows(3) symxsize(small) ///
               order(1 "Take-up = 1" ///
                     2 "Take-up = 0 (incl. control group)") ///
               col(1) pos(6) ring(6)) 	

	
twoway  (kdensity ca_rel_growth if treatment == 1 & surveyround == 3 & ca_rel_growth <= 6.5, lp(l) lc(maroon) yaxis(2) bw(.5)) ///
        (kdensity ca_rel_growth if treatment == 0 & surveyround == 3 & ca_rel_growth <= 6.5, lp(l) lc(green) yaxis(2)  bw(.5)), ///
		xtitle("Growth rate of sales relative to baseline") ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group" ///
                     2 "Control group") ///
               col(1) pos(6) ring(6)) 
	
	
* Export: direct, indirect, no export
graph bar (mean) export_1 export_2 export_3 if surveyround == 3, over(take_up) percentage blabel(total, format(%9.1fc) gap(-0.2)) ///
    legend (pos(6) row(6) label (1 "Direct export") label (2 "Indirect export") ///
	label (3 "No export")) ///
	title("Firm & export status", pos(12)) 
gr export el_firm_exports.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_firm_exports.png, width(5000)
putpdf pagebreak

*export or not 2023
graph pie if surveyround == 3, over(exported) by(take_up) plabel(_all percent, format(%9.0f) size(medium)) ///
    graphregion(fcolor(none) lcolor(none)) bgcolor(white) legend(pos(6)) ///
    title("Did the company export in 2023 (based on export turnover) ?", pos(12) size(small))
gr export export_2023_pie.png, replace
putpdf paragraph, halign(center) 
putpdf image export_2023_pie.png, width(5000)
putpdf pagebreak

* export or not 2023 by pole
graph bar (mean) exported if surveyround == 3, over(take_up) by(pole, title("Exported in 2023", pos(12) size(large)) note("")) ///
    graphregion(fcolor(none) lcolor(none)) bgcolor(white) legend(pos(6)) ///
	ytitle("Share of firms", size(medlarge)) ///
	ylabel(0(0.1)0.5)
gr export exported_2023_pole.png, replace

*export or not 2024
graph pie if surveyround == 3, over(exported_2024) by(take_up) plabel(_all percent, format(%9.0f) size(medium)) ///
    graphregion(fcolor(none) lcolor(none)) bgcolor(white) legend(pos(6)) ///
    title("Did the company export in 2024 (based on export turnover) ?", pos(12) size(small))
gr export export_2024_pie.png, replace
putpdf paragraph, halign(center) 
putpdf image export_2024_pie.png, width(5000)
putpdf pagebreak

graph bar (mean) exported_2024 if surveyround == 3, over(take_up) by(pole, title("Exported in 2024", pos(12) size(large)) note("")) ///
    graphregion(fcolor(none) lcolor(none)) bgcolor(white) legend(pos(6)) ///
	ytitle("Share of firms", size(medlarge)) ///
	ylabel(0(0.1)0.5)
gr export exported_2024_pole.png, replace

* Reasons for not exporting
graph bar (mean) export_41 export_42 export_43 export_44 export_45 if surveyround == 3, over(take_up) percentage blabel(total, format(%9.1fc) gap(-0.2)) ///
    legend (pos(6) row(6) label (1 "Not profitable") label (2 "Did not find clients abroad") ///
	label (3 "Too complicated") label (4 "Requires too much investment") label (5 "Binary other reason")) ///
	ylabel(0(20)100, nogrid)  ///
	title("Reasons for not exporting", pos(12)) 
gr export el_no_exports.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_no_exports.png, width(5000)
putpdf pagebreak

graph bar (mean) export_41 export_42 export_43 export_44 export_45 if surveyround == 3, over(take_up) by(pole, note("") title("Reasons for not exporting", pos(12))) percentage blabel(total, format(%9.1fc) gap(-0.2)) ///
    legend (pos(6) row(6) label (1 "Not profitable") label (2 "Did not find clients abroad") ///
	label (3 "Too complicated") label (4 "Requires too much investment") label (5 "Binary other reason")) ///
	ylabel(0(20)100, nogrid)  

*No of export destinations
sum exp_pays
stripplot exp_pays_w95 if surveyround == 3, by(treatment, note("")) jitter(4) vertical ///
		ytitle("Number of countries") ///
		ylabel(0(1)5) ///
		name(el_exp_pays_treat, replace)
    gr export el_exp_pays_treat.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_exp_pays_treat.png, width(5000)
	putpdf pagebreak

stripplot exp_pays_w95 if surveyround == 3, by(take_up, note("")) jitter(4) vertical ///
		ytitle("Number of countries") ///
		ylabel(0(1)5) ///
		name(el_exp_pays_takeup, replace)
    gr export el_exp_pays_takeup.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_exp_pays_takeup.png, width(5000)
	putpdf pagebreak

	twoway (kdensity exp_pays if treatment == 0 & surveyround == 3, lcolor(blue) lpattern(solid) legend(label(1 "Control"))) ///
	   (kdensity exp_pays if treatment == 1 & surveyround == 3, lcolor(red) lpattern(dash) legend(label(2 "Treatment"))), ///
       legend(symxsize(small) order(1 "Control" 2 "Treatment")) ///
	   title("Number of export countries", pos(12) size(medium)) ///
	   xtitle("Number of countries",size(medium)) ///
	   ytitle("Densitiy", size(medium))
gr export el_exp_pays_treat_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_exp_pays_treat_kdens.png, width(5000)
putpdf pagebreak

twoway  (kdensity exp_pays_w99 if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(2)) ///
        (kdensity exp_pays_w99 if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(2)) ///
        (kdensity exp_pays_w99 if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(2)) ///
        , ///
		title("Number of export countries", pos(12) size(medium)) ///
	xtitle("Number of countries") ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) 
gr export el_exp_pays_takeup_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_exp_pays_takeup_kdens.png, width(5000)
putpdf pagebreak


 graph box exp_pays if exp_pays > 0 & surveyround == 3, over(treatment) blabel(total, format(%9.2fc)) ///
	title("Number of export countries", pos(12))
gr export el_exp_pays_treat_box.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_exp_pays_treat_box.png, width(5000)
putpdf pagebreak

 graph box exp_pays if exp_pays > 0 & surveyround == 3, over(take_up) blabel(total, format(%9.2fc)) ///
	title("Number of export countries", pos(12))
gr export el_exp_pays_takeup_box.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_exp_pays_takeup_box.png, width(5000)
putpdf pagebreak

*No of export destinations SSA
sum exp_pays_ssa
stripplot exp_pays_ssa if surveyround == 3, by(treatment) jitter(4) vertical ///
		ytitle("Number of SSA countries") ///
		title("Number of export countries",size(medium) pos(12)) ///
		name(el_exp_ssapays_treat, replace)
    gr export el_exp_ssapays_treat.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_exp_ssapays_treat.png, width(5000)
	putpdf pagebreak

stripplot exp_pays_ssa if surveyround == 3, by(take_up) jitter(4) vertical ///
		ytitle("Number of SSA countries") ///
		title("Number of export countries",size(medium) pos(12)) ///
		name(el_ssaexp_pays_takeup, replace)
    gr export el_ssaexp_pays_takeup.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_ssaexp_pays_takeup.png, width(5000)
	putpdf pagebreak

	twoway (kdensity exp_pays_ssa if treatment == 0 & surveyround == 3, lcolor(blue) lpattern(solid) legend(label(1 "Control"))) ///
	   (kdensity exp_pays_ssa if treatment == 1 & surveyround == 3, lcolor(red) lpattern(dash) legend(label(2 "Treatment"))), ///
       legend(symxsize(small) order(1 "Control" 2 "Treatment")) ///
	   title("Number of export countries", pos(12) size(medium)) ///
	   xtitle("Number of  SSA countries",size(medium)) ///
	   ytitle("Densitiy", size(medium))
gr export el_ssaexp_pays_treat_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_ssaexp_pays_treat_kdens.png, width(5000)
putpdf pagebreak

twoway  (kdensity exp_pays_ssa if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(1.5)) ///
        (kdensity exp_pays_ssa if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(1.5)) ///
        (kdensity exp_pays_ssa if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
        , ///
		title("Number of export SSA countries", pos(12) size(medium)) ///
	xtitle("Number of countries") ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) 
gr export el_exp_ssapays_takeup_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_exp_ssapays_takeup_kdens.png, width(5000)
putpdf pagebreak

 graph box exp_pays_ssa if exp_pays_ssa > 0 & surveyround == 3, over(treatment) blabel(total, format(%9.2fc)) ///
	title("Number of export SSA countries", pos(12))
gr export el_exp_ssapays_treat_box.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_exp_ssapays_treat_box.png, width(5000)
putpdf pagebreak

 graph box exp_pays_ssa if exp_pays_ssa > 0 & surveyround == 3, over(take_up) blabel(total, format(%9.2fc)) ///
	title("Number of export SSA countries", pos(12))
gr export el_exp_ssapays_takeup_box.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_exp_ssapays_takeup_box.png, width(5000)
putpdf pagebreak

*International clients
sum clients
stripplot clients if surveyround == 3, by(treatment) jitter(4) vertical ///
		ytitle("Number of clients") ///
		title("Number of International clients" , pos(12)) ///
		name(el_clients_treat, replace)
    gr export el_clients_treat.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_clients_treat.png, width(5000)
	putpdf pagebreak

stripplot clients if surveyround == 3, by(take_up) jitter(4) vertical ///
		ytitle("Number of clients") ///
		title("Number of International clients" , pos(12)) ///
		name(el_exp_pays_takeup, replace)
    gr export el_clients_takeup.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_clients_takeup.png, width(5000)
	putpdf pagebreak

	twoway (kdensity clients if treatment == 0 & surveyround == 3, lcolor(blue) lpattern(solid) legend(label(1 "Control"))) ///
	   (kdensity clients if treatment == 1 & surveyround == 3, lcolor(red) lpattern(dash) legend(label(2 "Treatment"))), ///
       legend(symxsize(small) order(1 "Control" 2 "Treatment")) ///
		xtitle("Number of clients") ///
		title("Number of International clients" , pos(12)) ///
	   ytitle("Densitiy", size(medium))
gr export el_clients_treat_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_clients_treat_kdens.png, width(5000)
putpdf pagebreak

twoway  (kdensity clients if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(1.5)) ///
        (kdensity clients if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(1.5)) ///
        (kdensity clients if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
        , ///
		xtitle("Number of clients") ///
		title("Number of International clients" , pos(12)) ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) 
gr export el_clients_takeup_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_clients_takeup_kdens.png, width(5000)
putpdf pagebreak

 graph box clients if clients > 0 & surveyround == 3, over(treatment) blabel(total, format(%9.2fc)) ///
		title("Number of International clients" , pos(12)) 
gr export el_int_clients_treat_box.png
putpdf paragraph, halign(center) 
putpdf image el_int_clients_treat_box.png, width(5000)
putpdf pagebreak

 graph box clients if clients > 0 & surveyround == 3, over(take_up) blabel(total, format(%9.2fc)) ///
	title("Number of International clients" , pos(12)) 
gr export el_clients_takeup_box.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_clients_takeup_box.png, width(5000)
putpdf pagebreak
	
*export practices
betterbar exp_pra_rexp exp_pra_foire exp_pra_sci exprep_norme exp_pra_vent if surveyround == 3, over(take_up) barlab ci ///
	title("Export practices", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_expprac.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_expprac.png, width(6000)
putpdf pagebreak

*export practices SSA
betterbar ssa_action1 ssa_action2 ssa_action3 ssa_action4 if surveyround == 3, over(take_up) barlab ci ///
	title("Export practices in SSA", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_exppracSSA.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_exppracSSA.png, width(6000)
putpdf pagebreak

*export cost perception
	 betterbar expp_cost if surveyround == 3, over(take_up) barlab ci ///
    title("Perception of export costs", pos(12)) note("1 = very low, 7= very high", pos(6)) ///
    ylabel(0(1)7, nogrid) ///
    ytitle("Mean perception of export costs")
gr export el_export_costs.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_export_costs.png, width(5000)
putpdf pagebreak

*export benefits perception
	 betterbar expp_ben if surveyround == 3, over(take_up) barlab ci ///
    title("Perception of export benefits", pos(12)) note("1 = very low, 7= very high", pos(6)) ///
    ylabel(0(1)7, nogrid) ///
    ytitle("Mean perception of export benefits")
gr export el_export_bene.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_export_bene.png, width(5000)
putpdf pagebreak


*Endline Export readiness index
gr tw ///
	(kdensity eri if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram eri if treatment == 1 & take_up == 1 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity eri if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram eri if treatment == 1 & take_up == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity eri if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram eri if treatment == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Endline Distribution of Export readiness index}") ///
	subtitle("{it:Index calculated based on z-score method}") ///
	xtitle("Export readiness index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
					 3 "Control group") ///
               c(1) pos(6) ring(6)) ///
	name(eri_el, replace)
graph export eri_el.png, replace
putpdf paragraph, halign(center) 
putpdf image eri_el.png
putpdf pagebreak

*Endline Export readiness index points
gr tw ///
	(kdensity eri_points if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram eri_points if treatment == 1 & take_up == 1 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity eri_points if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram eri_points if treatment == 1 & take_up == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity eri_points if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram eri_points if treatment == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Endline Distribution of Export readiness index}") ///
	subtitle("{it:Index calculated based on points}") ///
	xtitle("Export readiness index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
					 3 "Control group") ///
               c(1) pos(6) ring(6)) ///
	name(eri_points_el, replace)
graph export eri_points_el.png, replace
putpdf paragraph, halign(center) 
putpdf image eri_points_el.png
putpdf pagebreak


*Endline Export readiness SSA index
gr tw ///
	(kdensity eri_ssa if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram eri_ssa if treatment == 1 & take_up == 1 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity eri_ssa if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram eri_ssa if treatment == 1 & take_up == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity eri_ssa if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram eri_ssa if treatment == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Endline Distribution of Export readiness SSA index}") ///
	subtitle("{it:Index calculated based on z-score method}") ///
	xtitle("Export readiness SSA index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
					 3 "Control group") ///
               c(1) pos(6) ring(6)) ///
	name(eri_ssa_el, replace)
graph export eri_ssa_el.png, replace
putpdf paragraph, halign(center) 
putpdf image eri_ssa_el.png
putpdf pagebreak

*Endline Export readiness SSA index- points
gr tw ///
	(kdensity eri_ssa_points if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram eri_ssa_points if treatment == 1 & take_up == 1 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity eri_ssa_points if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram eri_ssa_points if treatment == 1 & take_up == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity eri_ssa_points if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram eri_ssa_points if treatment == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Endline Distribution of Export readiness SSA index}") ///
	subtitle("{it:Index calculated based on points}") ///
	xtitle("Export readiness SSA index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
					 3 "Control group") ///
               c(1) pos(6) ring(6)) ///
	name(eri_ssa_points_el, replace)
graph export eri_ssa_points_el.png, replace
putpdf paragraph, halign(center) 
putpdf image eri_ssa_points_el.png
putpdf pagebreak

*Endline Export performance index
gr tw ///
	(kdensity epp if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram epp if treatment == 1 & take_up == 1 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity epp if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram epp if treatment == 1 & take_up == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity epp if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram epp if treatment == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Endline Distribution of Export performance index}") ///
	subtitle("{it:Index calculated based on z-score method}") ///
	xtitle("Export performance index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
					 3 "Control group") ///
               c(1) pos(6) ring(6)) ///
	name(epp_el, replace)
graph export epp_el.png, replace
putpdf paragraph, halign(center) 
putpdf image epp_el.png
putpdf pagebreak

}

****** Section 4: Employees ******
{
cd "${master_output}/figures/endline/compta"
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 4: The Firm"), bold

*emp
twoway  (kdensity employes if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(1.5)) ///
        (kdensity employes if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(1.5)) ///
        (kdensity employes if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
        , ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) ///
	   title("Number of full-time employees", pos(12)) ///
	   xtitle("Number of full-time employees",size(medium)) 
gr export el_fte_treat_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_fte_treat_kdens.png, width(5000)
putpdf pagebreak

preserve
collapse (mean) employes if employes!=666 & employes!=777 & employes!=888 & employes!=999 & employes!=1234 , by(surveyround treatment take_up)
twoway (connected employes surveyround if treatment == 1 & take_up == 1) (connected employes surveyround if treatment == 1 & take_up == 0) (connected employes surveyround if treatment == 0), xlabel (1(1)3) ytitle("Mean of number of employees") xtitle("1- Baseline 2- Midline 3-Endline") legend(label(1 Control) label(2 Present)) /// 
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) 
graph export did_plot2_employes.png, replace	
restore

*female empl
twoway  (kdensity car_empl1 if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(1.5)) ///
        (kdensity car_empl1 if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(1.5)) ///
        (kdensity car_empl1 if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
        , ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
					 col(1) pos(6) ring(6)) ///
	   title("Number of female employees", pos(12)) ///
	   xtitle("Number of female employees",size(medium)) 
gr export el_ftefemale_treat_kdens.png, replace
putpdf paragraph, halign(center) 
putpdf image el_ftefemale_treat_kdens.png, width(5000)
putpdf pagebreak

preserve
collapse (mean) car_empl1 if car_empl1!=666 & car_empl1!=777 & car_empl1!=888 & car_empl1!=999 & car_empl1!=1234 , by(surveyround treatment take_up)
twoway (connected car_empl1 surveyround if treatment == 1 & take_up == 1) (connected car_empl1 surveyround if treatment == 1 & take_up == 0) (connected car_empl1 surveyround if treatment == 0), xlabel (1(1)3) ytitle("Mean of number of female employees") xtitle("1- Baseline 2- Midline 3-Endline") legend(label(1 Control) label(2 Present)) /// 
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) 
graph export did_plot2_car_empl1.png, replace	
restore	

*youth
twoway  (kdensity car_empl2 if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(1.5)) ///
        (kdensity car_empl2 if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(1.5)) ///
        (kdensity car_empl2 if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
        , ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) ///
	   title("Number of young employees (less than 36)", pos(12)) ///
	   xtitle("Number of young employees (less than 36)",size(medium)) 
gr export el_fteyouth_treat_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_fteyouth_treat_kdens.png, width(5000)
putpdf pagebreak


preserve
collapse (mean) car_empl2 if car_empl2!=666 & car_empl2!=777 & car_empl2!=888 & car_empl2!=999 & car_empl2!=1234 , by(surveyround treatment take_up)
twoway (connected car_empl2 surveyround if treatment == 1 & take_up == 1) (connected car_empl2 surveyround if treatment == 1 & take_up == 0) (connected car_empl2 surveyround if treatment == 0), xlabel (1(1)3) ytitle("Mean of number of young employees") xtitle("1- Baseline 2- Midline 3-Endline") legend(label(1 Control) label(2 Present)) /// 
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) 
graph export did_plot2_car_empl2.png, replace	
restore	
}


****** Section 5: Management******
{
cd "${master_output}/figures/endline/management"	
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 5: Management"), bold

*performance indicators
betterbar man_fin_per_ind man_fin_per_pro man_fin_per_qua man_fin_per_sto man_fin_per_emp man_fin_per_liv man_fin_per_fre if surveyround==3, over(take_up) barlab ci ///
	title("Performance indicators", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_perfindic.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_perfindic.png, width(6000)
putpdf pagebreak

*performance frequency
betterbar man_fin_per_fre if surveyround==3, over(take_up) barlab ci ///
	title("KPIs tracking frequency", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_KPItrack.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_KPItrack.png, width(6000)
putpdf pagebreak

*management activities
betterbar man_fin_pra_bud man_fin_pra_pro man_fin_pra_dis if surveyround==3, over(take_up) barlab ci ///
	title("Management activities", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_manact.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_manact.png, width(6000)
putpdf pagebreak

*marketing source
betterbar man_source_cons man_source_pdg man_source_fam man_source_even man_source_formation man_source_autres if surveyround==3, over(take_up) barlab ci ///
	title("Marketing strategies source", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_marksource.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_marksource.png, width(6000)
putpdf pagebreak

*Endline Management practices index
gr tw ///
	(kdensity mpi if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram mpi if treatment == 1 & take_up == 1 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity mpi if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram mpi if treatment == 1 & take_up == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity mpi if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram mpi if treatment == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Endline Distribution of Management practices index}") ///
	subtitle("{it:Index calculated based on z-score method}") ///
	xtitle("Management practices index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
					 3 "Control group") ///
               c(1) pos(6) ring(6)) ///
	name(mpi_el, replace)
graph export mpi_el.png, replace
putpdf paragraph, halign(center) 
putpdf image mpi_el.png
putpdf pagebreak

*Endline Management practices index- points
gr tw ///
	(kdensity mpi_points if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram mpi_points if treatment == 1 & take_up == 1 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity mpi_points if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram mpi_points if treatment == 1 & take_up == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity mpi_points if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram mpi_points if treatment == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Endline Distribution of Management practices index}") ///
	subtitle("{it:Index calculated based on points}") ///
	xtitle("Management practices index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
					 3 "Control group") ///
               c(1) pos(6) ring(6)) ///
	name(mpi_points_el, replace)
graph export mpi_points_el.png, replace
putpdf paragraph, halign(center) 
putpdf image mpi_points_el.png
putpdf pagebreak


}

****** Section 6: Network******
{
cd "${master_output}/figures/endline/network"
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 6: Network"), bold

*associations
twoway  (kdensity net_association if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(1.5)) ///
        (kdensity net_association if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(1.5)) ///
        (kdensity net_association if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
        , ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) ///
	   title("Number of formal asssociations membership", pos(12)) ///
	   xtitle("Number of formal asssociations membership",size(medium)) 
gr export el_assoc_treat_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_assoc_treat_kdens.png, width(5000)
putpdf pagebreak

* male
twoway  (kdensity net_size3_m if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(1.5)) ///
        (kdensity net_size3_m if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(1.5)) ///
        (kdensity net_size3_m if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
        , ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) ///
	   title("Male entrepreneurs discussions about business", size(medium)) ///
	   xtitle("Number of male entrepreneurs met",size(medium)) 
gr export el_network_density_m.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_network_density_m.png, width(5000)
putpdf pagebreak


		* female
			* Take up
twoway  (kdensity net_gender3 if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(1.5)) ///
        (kdensity net_gender3 if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(1.5)) ///
        (kdensity net_gender3 if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
        , ///
		legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) ///
	   title("Female entrepreneurs discussions about business", size(medium)) ///
	   xtitle("Number of female entrepreneurs met",size(medium)) 
	   
			* T vs. C
  sum     net_gender3_w99 if treatment == 0 
  local   control_mean = r(mean) 
  sum     net_gender3_w99 if treatment == 1
  local   treatment_mean = r(mean)
  
twoway  (kdensity net_gender3_w99 if treatment == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(1.5)) ///
        (kdensity net_gender3_w99 if treatment == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(1.5)) ///
		, ///
		 xline(`control_mean', lcolor(green) lpattern(dash)) ///
         xline(`treatment_mean', lcolor(maroon) lpattern(dash)) ///
		legend(rows(3) symxsize(small) ///
               order(1 "Treatment group" ///
                     2 "Control group") ///
               col(1) pos(6) ring(6)) ///
			xtitle("Female entrepreneurs regularly met to discuss business",size(medium)) ///
	   note("{bf:Note}: Variable shows endline responses and is winsorised at the 99% percent level.")
gr export "${master_output}/figures/endline/network/el_network_density_f.png", width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_network_density_f.png, width(5000)
putpdf pagebreak

*consortium femme female met
sum net_gender3_giz,d
histogram net_gender3_giz, width(1) frequency addlabels xlabel(0(2)30, nogrid format(%9.0f)) discrete ///
	xline(`r(mean)', lpattern(1)) xline(`r(p50)', lpattern()) ///
	title("Female entrepneurs met during consortia activities", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal)) ///
	text(100 `r(mean)' "Mean", size(vsmall) place(e)) ///
	text(100 `r(p50)' "Median", size(vsmall) place(w))
graph export el_femmet.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_femmet.png, width(6000)
putpdf pagebreak

	* Female entrepreneur contacts relative to number known via GIZ
graph bar net_gender3_w99 net_gender3_giz_w99 if surveyround == 3 & treatment == 1, over(take_up, lab(labsize(medsmall))) ///
	legend(order(1 "Female Entrepreneurs in Network" ///
		   2 "Female Entrepreneurs known via Consortium") ///
		   pos(6) rows(2) size(medsmall)) ///
		   ylab(, labsize(medsmall))
	note("The figure only considers firms in the treatment group.")
graph export "${master_output}/figures/endline/network/el_fem_vs_femgiz.png", width(6000) replace 


* Female vs. Male entrepreneurs in network



*net services
betterbar net_services_pratiques net_services_produits net_services_mark net_services_sup net_services_contract net_services_confiance net_services_autre if surveyround==3, over(take_up) barlab ci ///
	title("Network services", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_netserv.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_netserv.png, width(6000)
putpdf pagebreak

* Interactions between CEO	
betterbar net_coop_pos net_coop_neg if surveyround==3, over(take_up) barlab ci ///
	title("Perception of interactions", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_netcoop.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_netcoop.png, width(6000)
putpdf pagebreak

*net coop
betterbar netcoop1 netcoop2 netcoop3 netcoop4 netcoop5 netcoop6 netcoop7 netcoop8 netcoop9 netcoop10 if surveyround==3, over(take_up) barlab ci ///
	title("Network interactions", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_netcoop.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_netcoop.png, width(6000)
putpdf pagebreak

*Endline network index
gr tw ///
	(kdensity network if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram network if treatment == 1 & take_up == 1 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity network if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram network if treatment == 1 & take_up == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity network if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram network if treatment == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Endline Distribution of Network Index}") ///
	subtitle("{it:Index calculated based on z-score method}") ///
	xtitle("Network index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
					 3 "Control group") ///
               c(1) pos(6) ring(6)) ///
	name(network_el, replace)
graph export network_el.png, replace
putpdf paragraph, halign(center) 
putpdf image network_el.png
putpdf pagebreak

}

****** Section 7: Entrepreneurial Confidence ******
{
cd "${master_output}/figures/endline/confidence"
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 7: Entrepreneurial Self-Confidence"), bold

*efficency 
betterbar car_efi_fin1 car_efi_man car_efi_motiv if surveyround==3, over(take_up) barlab ci ///
	title("Entrepneurship efficency", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_entrep_effi.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_entrep_effi.png, width(6000)
putpdf pagebreak

*locus of control 
betterbar car_loc_env car_loc_exp car_loc_soin if surveyround==3, over(take_up) barlab ci ///
	title("Entrepneurship Locus", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_entrep_loc.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_entrep_loc.png, width(6000)
putpdf pagebreak

*listexp
*graph bar list_exp, over(list_group) - where list_exp provides the number of confirmed affirmations).
graph bar listexp if surveyround==3, over(list_group_el, relabel(1 "Non-sensitive" 2 "Sensitive  incl." 3 "Non-sensitive" 4 "Sensitive incl.")) over(take_up) ///
	blabel(total, format(%9.2fc) gap(-0.2)) ///
	title("List experiment question") ///
ytitle("No. of affirmations") ///
ylabel(0(1)3.2, nogrid) 
gr export el_bar_listexp.png, replace
putpdf paragraph, halign(center) 
putpdf image el_bar_listexp.png
putpdf pagebreak

graph bar listexp if surveyround==3, over(list_group_el, relabel(1 "Non-sensitive" 2 "Sensitive  incl." 3 "Non-sensitive" 4 "Sensitive incl.")) over(treatment) ///
	blabel(total, format(%9.2fc) gap(-0.2)) ///
	title("List experiment question") ///
ytitle("No. of affirmations") ///
ylabel(0(1)3.2, nogrid) 
gr export el_bar_listexp.png, replace
putpdf paragraph, halign(center) 
putpdf image el_bar_listexp.png
putpdf pagebreak

*Endline Female Effifacy index
gr tw ///
	(kdensity female_efficacy if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram female_efficacy if treatment == 1 & take_up == 1 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity female_efficacy if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram female_efficacy if treatment == 1 & take_up == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity female_efficacy if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram female_efficacy if treatment == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Endline Distribution of Female Effifacy index}") ///
	subtitle("{it:Index calculated based on z-score method}") ///
	xtitle("Female Effifacy index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
					 3 "Control group") ///
               c(1) pos(6) ring(6)) ///
	name(female_efficacy_el, replace)
graph export female_efficacy_el.png, replace
putpdf paragraph, halign(center) 
putpdf image female_efficacy_el.png
putpdf pagebreak

*Endline Female Effifacy index - points
gr tw ///
	(kdensity female_efficacy_points if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram female_efficacy_points if treatment == 1 & take_up == 1 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity female_efficacy_points if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram female_efficacy_points if treatment == 1 & take_up == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity female_efficacy_points if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram female_efficacy_points if treatment == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Endline Distribution of Female Effifacy index}") ///
	subtitle("{it:Index calculated based on points}") ///
	xtitle("Female Effifacy index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
					 3 "Control group") ///
               c(1) pos(6) ring(6)) ///
	name(female_efficacy_points_el, replace)
graph export female_efficacy_points_el.png, replace
putpdf paragraph, halign(center) 
putpdf image female_efficacy_points_el.png
putpdf pagebreak

*Endline Female Locus of control index
gr tw ///
	(kdensity female_loc if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram female_loc if treatment == 1 & take_up == 1 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity female_loc if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram female_loc if treatment == 1 & take_up == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity female_loc if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram female_loc if treatment == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Endline Distribution of Female Locus of control index}") ///
	subtitle("{it:Index calculated based on z-score method}") ///
	xtitle("Female Locus of control index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
					 3 "Control group") ///
               c(1) pos(6) ring(6)) ///
	name(female_loc_el, replace)
graph export female_loc_el.png, replace
putpdf paragraph, halign(center) 
putpdf image female_loc_el.png
putpdf pagebreak

*Endline Female Locus of control index - points
gr tw ///
	(kdensity female_loc_points if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram female_loc_points if treatment == 1 & take_up == 1 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity female_loc_points if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram female_loc_points if treatment == 1 & take_up == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity female_loc_points if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram female_loc_points if treatment == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Endline Distribution of Female Locus of control index}") ///
	subtitle("{it:Index calculated based on points}") ///
	xtitle("Female Locus of control index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
					 3 "Control group") ///
               c(1) pos(6) ring(6)) ///
	name(female_loc_points_el, replace)
graph export female_loc_points_el.png, replace
putpdf paragraph, halign(center) 
putpdf image female_loc_points_el.png
putpdf pagebreak

*Endline Female Entrepreneurial empowerment index
gr tw ///
	(kdensity genderi if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram genderi if treatment == 1 & take_up == 1 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity genderi if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram genderi if treatment == 1 & take_up == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity genderi if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram genderi if treatment == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Endline Distribution of Female Entrepreneurial empowerment index}", size(medium)) ///
	subtitle("{it:Index calculated based on z-score method}") ///
	xtitle("Female Entrepreneurial empowerment index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
					 3 "Control group") ///
               c(1) pos(6) ring(6)) ///
	name(genderi_el, replace)
graph export genderi_el.png, replace
putpdf paragraph, halign(center) 
putpdf image genderi_el.png
putpdf pagebreak

*Endline Female Entrepreneurial empowerment index- points
gr tw ///
	(kdensity genderi_points if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram genderi_points if treatment == 1 & take_up == 1 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity genderi_points if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram genderi_points if treatment == 1 & take_up == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity genderi_points if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram genderi_points if treatment == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Endline Distribution of Female Entrepreneurial empowerment index}", size(medium)) ///
	subtitle("{it:Index calculated based on points}") ///
	xtitle("Female Entrepreneurial empowerment index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
					 3 "Control group") ///
               c(1) pos(6) ring(6)) ///
	name(genderi_points_el, replace)
graph export genderi_points_el.png, replace
putpdf paragraph, halign(center) 
putpdf image genderi_points_el.png
putpdf pagebreak
}

****** Section 8: Accounting******
{
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 8.1: Export"), bold
{
cd "${master_output}/figures/endline/compta"

*** Sales
{
    * Chiffre d'affaires total en dt en 2023 
egen ca_95p = pctile(ca), p(95)
graph bar ca if ca<ca_95p & ca>0 & surveyround==3 & ca!=666 & ca!=777 & ca!=888 & ca!=999 & ca!=1234, blabel(total, format(%9.2fc)) over(take_up) over (surveyround) ///
	title("Turnover in 2023") ///
	ytitle("Mean 2023 turnover")
gr export el_bar_ca_2023.png, replace
putpdf paragraph, halign(center) 
putpdf image el_bar_ca_2023.png
putpdf pagebreak
	
sum ca
stripplot ca_w99 if ca_w99>0 & surveyround==3 & ca!=666 & ca!=777 & ca!=888 & ca!=999 & ca!=1234 , jitter(4) vertical yline(`=r(mean)', lcolor(red)) ///
		title("Total turnover in 2023",size(medium) pos(12)) ///
		ytitle("Amount in TND") ///
		name(el_ca, replace)
    gr export el_ca.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_ca.png, width(5000)
	putpdf pagebreak

stripplot ca if  ca<ca_95p & ca>0 & surveyround==3 & ca!=666 & ca!=777 & ca!=888 & ca!=999 & ca!=1234 , by(take_up) jitter(4) vertical  ///
		title("Total turnover in 2023",size(medium) pos(12)) ///
		ytitle("Amount in TND") ///
		name(el_ca_treat, replace)
    gr export el_ca_treat.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_ca_treat.png, width(5000)
	putpdf pagebreak

preserve
collapse (mean) ca if  ca<ca_95p & ca!=666 & ca!=777 & ca!=888 & ca!=999 & ca!=1234 , by(surveyround treatment take_up)
twoway (connected ca surveyround if treatment == 1 & take_up == 1) (connected ca surveyround if treatment == 1 & take_up == 0) (connected ca surveyround if treatment == 0), xlabel (1(1)3) ytitle("Mean of total turnover") xtitle("1- Baseline 2- Midline 3-Endline") legend(label(1 Control) label(2 Present)) ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) 
graph export did_plot2_ca.png, replace
restore	
	
	* total sales
		* abs
			* el
twoway ///
	(kdensity ca if treatment == 1 & take_up == 1 & surveyround == 3 & ca > 0, lp(l) lc(maroon) yaxis(2)) ///
    (kdensity ca if treatment == 1 & take_up == 0 & surveyround == 3 & ca > 0, lp(l) lc(green) yaxis(2)) ///
    (kdensity ca if treatment == 0 & surveyround == 3 & ca > 0, lp(l) lc(navy) yaxis(2)) ///
        , ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) ///
	   title("Total turnover in 2023", pos(12)) ///
	   xtitle("Total turnover",size(medium)) 
	  
			* bl
twoway ///
	(kdensity ca if treatment == 1 & take_up == 1 & surveyround == 1 & ca > 0, lp(l) lc(maroon) yaxis(2)) ///
    (kdensity ca if treatment == 1 & take_up == 0 & surveyround == 1 & ca > 0, lp(l) lc(green) yaxis(2)) ///
    (kdensity ca if treatment == 0 & surveyround == 1 & ca > 0, lp(l) lc(navy) yaxis(2)) ///
        , ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) ///
	   title("Total turnover", pos(12)) ///
	   xtitle("Total turnover",size(medium)) 
	   
	   * ihs
	   
twoway ///
	(kdensity ihs_ca_w95_k1 if treatment == 1 & take_up == 1 & surveyround == 3 & ca > 0, lp(l) lc(maroon) yaxis(2) bw(1.5)) ///
    (kdensity ihs_ca_w95_k1 if treatment == 1 & take_up == 0 & surveyround == 3 & ca > 0, lp(l) lc(green) yaxis(2) bw(1.5)) ///
    (kdensity ihs_ca_w95_k1 if treatment == 0 & surveyround == 3 & ca > 0, lp(l) lc(navy) yaxis(2) bw(1.5)) ///
        , ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) ///
	   title("Total turnover in 2023", pos(12)) ///
	   xtitle("Total turnover",size(medium)) 
gr export el_ca_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_ca_kdens.png, width(5000)
putpdf pagebreak

		* distribution of growth rates in ca
twoway ///
	(kdensity ca_rel_growth if treatment == 1 & take_up == 1 & surveyround == 3 & ca_rel_growth < 5, lp(l) lc(maroon) yaxis(2)) ///
    (kdensity ca_rel_growth if treatment == 1 & take_up == 0 & surveyround == 3 & ca_rel_growth < 5, lp(l) lc(green) yaxis(2)) ///
    (kdensity ca_rel_growth if treatment == 0 & surveyround == 3 & ca_rel_growth < 5, lp(l) lc(navy) yaxis(2)) ///
        , ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) ///
	   title("Total turnover", pos(12)) ///
	   xtitle("Growth rate",size(medium)) 
	   
		* distribution of growth rates in profit
twoway ///
	(kdensity profit_rel_growth if treatment == 1 & take_up == 1 & surveyround == 3 & profit_rel_growth, lp(l) lc(maroon) yaxis(2)) ///
    (kdensity profit_rel_growth if treatment == 1 & take_up == 0 & surveyround == 3 & profit_rel_growth, lp(l) lc(green) yaxis(2)) ///
    (kdensity profit_rel_growth if treatment == 0 & surveyround == 3 & profit_rel_growth, lp(l) lc(navy) yaxis(2)) ///
        , ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) ///
	   title("Profit", pos(12)) ///
	   xtitle("Growth rate",size(medium)) 
	   
	   
	   

		
 graph box ca if ca<ca_95p & ca>0 & surveyround==3 & ca!=666 & ca!=777 & ca!=888 & ca!=999 & ca!=1234, over(take_up) blabel(total, format(%9.2fc)) ///
	title("Total turnover in 2023 in TND", pos(12))
gr export el_ca_box.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_ca_box.png, width(5000)
putpdf pagebreak

    * Chiffre d'affaires total en dt en 2024 
egen ca_2024_95p = pctile(ca_2024), p(95)
graph bar ca_2024 if ca_2024<ca_2024_95p & ca_2024>0 & surveyround==3 & ca_2024!=666 & ca_2024!=777 & ca_2024!=888 & ca_2024!=999 & ca_2024!=1234, blabel(total, format(%9.2fc)) over(take_up) over (surveyround) ///
	title("Turnover in 2024") ///
	ytitle("Mean 2024 turnover")
gr export el_bar_ca_2024.png, replace
putpdf paragraph, halign(center) 
putpdf image el_bar_ca_2024.png
putpdf pagebreak
	
sum ca_2024
stripplot ca_2024 if  ca_2024<ca_2024_95p & ca_2024>0 & surveyround==3 & ca_2024!=666 & ca_2024!=777 & ca_2024!=888 & ca_2024!=999 & ca_2024!=1234 , jitter(4) vertical yline(`=r(mean)', lcolor(red)) ///
		title("Total turnover in 2024",size(medium) pos(12)) ///
		ytitle("Amount in TND") ///
		name(el_ca, replace)
    gr export el_ca_2024.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_ca_2024.png, width(5000)
	putpdf pagebreak

stripplot ca_2024 if  ca_2024<ca_2024_95p & ca_2024>0 & surveyround==3 & ca_2024!=666 & ca_2024!=777 & ca_2024!=888 & ca_2024!=999 & ca_2024!=1234 , by(take_up) jitter(4) vertical  ///
		title("Total turnover in 2024",size(medium) pos(12)) ///
		ytitle("Amount in TND") ///
		name(el_ca_2024_treat, replace)
    gr export el_ca_2024_treat.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_ca_2024_treat.png, width(5000)
	putpdf pagebreak
/*	
twoway  (kdensity ca_2024 if treatment == 1 & take_up == 1 & surveyround == 3 & ca_2024<ca_2024_95p & ca_2024>0 & ca_2024!=666 & ca_2024!=777 & ca_2024!=888 & ca_2024!=999 & ca_2024!=1234 , lp(l) lc(maroon) yaxis(2) bw(1.5)) ///
        (kdensity ca_2024 if treatment == 1 & take_up == 0 & surveyround == 3 & ca_2024<ca_2024_95p & ca_2024>0 & ca_2024!=666 & ca_2024!=777 & ca_2024!=888 & ca_2024!=999 & ca_2024!=1234 , lp(l) lc(green) yaxis(2) bw(1.5)) ///
        (kdensity ca_2024 if treatment == 0 & surveyround == 3 & ca_2024<ca_2024_95p & ca_2024>0 & ca_2024!=666 & ca_2024!=777 & ca_2024!=888 & ca_2024!=999 & ca_2024!=1234 , lp(l) lc(navy) yaxis(2) bw(0.4)) ///
        , ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) ///
	   title("Total turnover in 2024", pos(12)) ///
	   xtitle("Total turnover",size(medium)) 
gr export el_ca_2024_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_ca_2024_kdens.png, width(5000)
putpdf pagebreak
*/	  
	   
 graph box ca if ca_2024<ca_95p & ca_2024>0 & surveyround==3 & ca_2024!=666 & ca_2024!=777 & ca_2024!=888 & ca_2024!=999 & ca_2024!=1234, over(take_up) blabel(total, format(%9.2fc)) ///
	title("Total turnover in 2024 in TND", pos(12))
gr export el_ca_2024_box.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_ca_2024_box.png, width(5000)
putpdf pagebreak

}

*** Export
{

   *Chiffre d'affaires à l'export en dt en 2023
egen ca_exp_95p = pctile(ca_exp), p(95)
graph bar ca_exp if ca_exp<ca_exp_95p & ca_exp>0 & surveyround==3 & ca_exp!=666 & ca_exp!=777 & ca_exp!=888 & ca_exp!=999 & ca_exp!=1234, blabel(total, format(%9.2fc)) over(take_up) over (surveyround) ///
	title("Export turnover in 2023") ///
	ytitle("Mean 2023 export turnover")
gr export el_bar_ca_exp.png, replace
putpdf paragraph, halign(center) 
putpdf image el_bar_ca_exp.png
putpdf pagebreak
	
sum ca_exp_w99
stripplot ca_exp_w95 if ca_exp_w95>0 & surveyround==3, jitter(4) vertical yline(`=r(mean)', lcolor(red)) ///
		title("Export turnover in 2023",size(medium) pos(12)) ///
		ytitle("Amount in TND") ///
		name(el_ca_exp, replace)
    gr export el_ca_exp.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_ca_exp.png, width(5000)
	putpdf pagebreak

stripplot ca_exp_w95 if surveyround==3, by(take_up) jitter(4) vertical  ///
		title("Export turnover in 2023",size(medium) pos(12)) ///
		ytitle("Amount in TND") ///
		name(el_ca_exp_treat, replace)
    gr export el_ca_exp_treat.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_ca_exp_treat.png, width(5000)
	putpdf pagebreak
	
kdensity ca_exp_w95 if surveyround == 3
	
preserve
collapse (mean) ca_exp if  ca_exp <ca_exp_95p & ca_exp!=666 & ca_exp!=777 & ca_exp!=888 & ca_exp!=999 & ca_exp!=1234 , by(surveyround take_up treatment)
twoway (connected ca_exp surveyround if treatment == 1 & take_up == 1) (connected ca_exp surveyround if treatment == 1 & take_up == 0) (connected ca_exp surveyround if treatment == 0), xlabel (1(1)3) ytitle("Mean of export turnover") xtitle("1- Baseline 2- Midline 3-Endline") legend(label(1 Control) label(2 Present)) ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) 
graph export did_plot2_ca_exp.png, replace
restore	

* pre treatment export distribution
twoway ///
 (kdensity ca_exp_w95 if treatment == 1 & take_up == 1 & surveyround == 1, lp(l) lc(maroon) yaxis(2) bw(50000)) ///
 (kdensity ca_exp_w95 if treatment == 1 & take_up == 0 & surveyround == 1, lp(l) lc(green) yaxis(2) bw(50000)) ///
 (kdensity ca_exp_w95 if treatment == 0 & surveyround == 1, lp(l) lc(navy) yaxis(2) bw(50000)) ///
        , ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) ///
	   title("Export turnover in 2021", pos(12)) ///
	   xtitle("Export turnover",size(medium)) 
* post treatment export distribution
twoway ///
 (kdensity ca_exp_w95 if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(50000)) ///
 (kdensity ca_exp_w95 if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(50000)) ///
 (kdensity ca_exp_w95 if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(50000)) ///
        , ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) ///
	   title("Export turnover in 2023", pos(12)) ///
	   xtitle("Export turnover",size(medium)) 
gr export el_ca_exp_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_ca_exp_kdens.png, width(5000)
putpdf pagebreak

twoway ///
 (kdensity ihs_ca_exp_w95_k1 if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(50000)) ///
 (kdensity ihs_ca_exp_w95_k1 if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(50000)) ///
 (kdensity ihs_ca_exp_w95_k1 if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(50000)) ///
        , ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) ///
	   title("Export turnover in 2023", pos(12)) ///
	   xtitle("Export turnover",size(medium)) 



  
	* domestic sales
twoway ///
 (kdensity ca_tun if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(50000)) ///
 (kdensity ca_tun if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(50000)) ///
 (kdensity ca_tun if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(50000)) ///
        , ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) ///
	   title("Domestic turnover in 2023", pos(12)) ///
	   xtitle("Domestic turnover",size(medium)) 
	   
	twoway ///
 (kdensity ihs_catun2024_w95_k1 if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2)) ///
 (kdensity ihs_catun2024_w95_k1 if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2)) ///
 (kdensity ihs_catun2024_w95_k1 if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2)) ///
        , ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) ///
	   title("Domestic turnover in 2023", pos(12)) ///
	   xtitle("Domestic turnover",size(medium)) 
	   
	   

  
  
  
  
	   
 graph box ca_exp if ca_exp<ca_exp_95p & ca_exp>0 & surveyround==3 & ca_exp!=666 & ca_exp!=777 & ca_exp!=888 & ca_exp!=999 & ca_exp!=1234, over(take_up) blabel(total, format(%9.2fc)) ///
	title("Export turnover in 2023", pos(12))
gr export el_ca_exp_box.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_ca_exp_box.png, width(5000)
putpdf pagebreak
 
 
   *Chiffre d'affaires à l'export en dt en 2024
egen ca_exp_2024_95p = pctile(ca_exp_2024), p(95)
graph bar ca_exp_2024 if ca_exp_2024<ca_exp_2024_95p & ca_exp_2024>0 & surveyround==3 & ca_exp_2024!=666 & ca_exp_2024!=777 & ca_exp_2024!=888 & ca_exp_2024!=999 & ca_exp_2024!=1234, blabel(total, format(%9.2fc)) over(take_up) over (surveyround) ///
	title("Export turnover in 2024") ///
	ytitle("Mean 2024 export turnover")
gr export el_bar_ca_exp_2024.png, replace
putpdf paragraph, halign(center) 
putpdf image el_bar_ca_exp_2024.png
putpdf pagebreak
	
sum ca_exp_2024
stripplot ca_exp_2024 if  ca_exp_2024<ca_exp_2024_95p & ca_exp_2024>0 & surveyround==3 & ca_exp_2024!=666 & ca_exp_2024!=777 & ca_exp_2024!=888 & ca_exp_2024!=999 & ca_exp_2024!=1234 , jitter(4) vertical yline(`=r(mean)', lcolor(red)) ///
		title("Export turnover in 2024",size(medium) pos(12)) ///
		ytitle("Amount in TND") ///
		name(el_ca_exp_2024, replace)
    gr export el_ca_exp_2024.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_ca_exp_2024.png, width(5000)
	putpdf pagebreak

stripplot ca_exp_2024 if ca_exp_2024<ca_exp_2024_95p & ca_exp_2024>0 & surveyround==3 & ca_exp_2024!=666 & ca_exp_2024!=777 & ca_exp_2024!=888 & ca_exp_2024!=999 & ca_exp_2024!=1234 , by(take_up) jitter(4) vertical  ///
		title("Export turnover in 2024",size(medium) pos(12)) ///
		ytitle("Amount in TND") ///
		name(el_ca_exp_2024_treat, replace)
    gr export el_ca_exp_2024_treat.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_ca_exp_2024_treat.png, width(5000)
	putpdf pagebreak
/*	
twoway  (kdensity ca_exp_2024 if treatment == 1 & take_up == 1 & surveyround == 3 & ca_exp_2024<ca_exp_2024_95p & ca_exp_2024>0 & ca_exp_2024!=666 & ca_exp_2024!=777 & ca_exp_2024!=888 & ca_exp_2024!=999 & ca_exp_2024!=1234 , lp(l) lc(maroon) yaxis(2) bw(1.5)) ///
        (kdensity ca_exp_2024 if treatment == 1 & take_up == 0 & surveyround == 3 & ca_exp_2024<ca_exp_2024_95p & ca_exp_2024>0 & ca_exp_2024!=666 & ca_exp_2024!=777 & ca_exp_2024!=888 & ca_exp_2024!=999 & ca_exp_2024!=1234 , lp(l) lc(green) yaxis(2) bw(1.5)) ///
        (kdensity ca_exp_2024 if treatment == 0 & surveyround == 3 & ca_exp<ca_exp_2024_95p & ca_exp_2024>0 & ca_exp_2024!=666 & ca_exp_2024!=777 & ca_exp_2024!=888 & ca_exp_2024!=999 & ca_exp_2024!=1234 , lp(l) lc(navy) yaxis(2) bw(0.4)) ///
        , ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) ///
	   title("Export turnover in 2024", pos(12)) ///
	   xtitle("Export turnover",size(medium)) 
gr export el_ca_exp_2024_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_ca_exp_2024_kdens.png, width(5000)
putpdf pagebreak
*/	  
	   
 graph box ca_exp_2024 if ca_exp_2024<ca_exp_2024_95p & ca_exp_2024>0 & surveyround==3 & ca_exp_2024!=666 & ca_exp_2024!=777 & ca_exp_2024!=888 & ca_exp_2024!=999 & ca_exp_2024!=1234, over(take_up) blabel(total, format(%9.2fc)) ///
	title("Export turnover in 2024", pos(12))
gr export el_ca_exp_2024_box.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_ca_exp_2024_box.png, width(5000)
putpdf pagebreak

}

*** Profit

{  
  	*Bénéfices/Perte 2023
graph pie if surveyround==3, over(profit_2023_category) plabel(_all percent, format(%9.0f) size(medium)) graphregion(fcolor(none) lcolor(none)) ///
   bgcolor(white) legend(pos(6)) ///
   title("Did the company make a loss or a profit in 2023?", pos(12))
   gr export profit_2023_category.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image profit_2023_category.png, width(5000)
	putpdf pagebreak
	
graph pie if surveyround==3, over(profit_2023_category) by(take_up) plabel(_all percent, format(%9.0f) size(medium)) ///
    graphregion(fcolor(none) lcolor(none)) bgcolor(white) legend(pos(6)) ///
    title("Did the company make a loss or a profit in 2023?", pos(12) size(small))
   gr export profit_2023_category_treat.png, replace
	putpdf paragraph, halign(center) 
	putpdf image profit_2023_category_treat.png, width(5000)
	putpdf pagebreak

	*Profit en dt en 2023
sum profit
stripplot profit if surveyround==3 & profit!=666 & profit!=777 & profit!=888 & profit!=999 & profit!=1234, jitter(4) vertical yline(`=r(mean)', lcolor(red)) ///
		ytitle("Amount in TND") ///
		title("Company profit in 2023",size(medium) pos(12)) ///
		name(el_profit, replace)
    gr export el_profit.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_profit.png, width(5000)
	putpdf pagebreak

stripplot profit if surveyround==3 & profit!=666 & profit!=777 & profit!=888 & profit!=999 & profit!=1234, by(treatment) jitter(4) vertical ///
		ytitle("Amount in TND") ///
		title("Company profit in 2023",size(medium) pos(12)) ///
		name(el_profit_treat, replace)
		
stripplot profit if surveyround==3 & profit!=666 & profit!=777 & profit!=888 & profit!=999 & profit!=1234, by(take_up) jitter(4) vertical ///
		ytitle("Amount in TND") ///
		title("Company profit in 2023",size(medium) pos(12)) ///
		name(el_profit_treat, replace)
    gr export el_profit_treat.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_profit_treat.png, width(5000)
	putpdf pagebreak
/*
twoway  (kdensity profit if treatment == 1 & take_up == 1 & surveyround==3 & profit!=666 & profit!=777 & profit!=888 & profit!=999 & profit!=1234, lp(l) lc(maroon) yaxis(2) bw(1.5)) ///
        (kdensity profit if treatment == 1 & take_up == 0 & surveyround==3 & profit!=666 & profit!=777 & profit!=888 & profit!=999 & profit!=1234, lp(l) lc(green) yaxis(2) bw(1.5)) ///
        (kdensity profit if treatment == 0 & surveyround==3 & profit!=666 & profit!=777 & profit!=888 & profit!=999 & profit!=1234, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
        , ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) ///
	   title("Company profit in 2023", pos(12)) ///
	   xtitle("Amount in TND",size(medium)) 
gr export el_profit_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_profit_kdens.png, width(5000)
putpdf pagebreak
*/
	
 graph box profit if surveyround==3 & profit!=666 & profit!=777 & profit!=888 & profit!=999 & profit!=1234, over(take_up) blabel(total, format(%9.2fc)) ///
	title("Company profit in 2023 in TND", pos(12))
gr export el_profit_box.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_profit_box.png, width(5000)
putpdf pagebreak

preserve
collapse (mean) profit if profit!=666 & profit!=777 & profit!=888 & profit!=999 & profit!=1234 , by(surveyround take_up treatment)
twoway (connected profit surveyround if treatment == 1 & take_up == 1) (connected profit surveyround if treatment == 1 & take_up == 0) (connected profit surveyround if treatment == 0), xlabel (1(1)3) ytitle("Mean of profit") xtitle("1- Baseline 2- Midline 3-Endline") legend(label(1 Control) label(2 Present)) ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) 		   
graph export did_plot2_profit.png, replace
restore	

	*Bénéfices/Perte 2024
graph pie if surveyround==3, over(profit_2024_category) plabel(_all percent, format(%9.0f) size(medium)) graphregion(fcolor(none) lcolor(none)) ///
   bgcolor(white) legend(pos(6)) ///
   title("Did the company make a loss or a profit in 2024?", pos(12))
   gr export profit_2024_category.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image profit_2024_category.png, width(5000)
	putpdf pagebreak
	
	graph pie if surveyround==3, over(profit_2024_category)  by(take_up) plabel(_all percent, format(%9.0f) size(medium)) graphregion(fcolor(none) lcolor(none)) ///
   bgcolor(white) legend(pos(6)) ///
   title("Did the company make a loss or a profit in 2024?", pos(12) size(small))
   gr export profit_2024_category_treat.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image profit_2024_category_treat.png, width(5000)
	putpdf pagebreak
	
*Profit en dt en 2024
sum profit_2024
stripplot profit_2024 if surveyround==3 & profit_2024!=666 & profit_2024!=777 & profit_2024!=888 & profit_2024!=999 & profit_2024!=1234, jitter(4) vertical yline(`=r(mean)', lcolor(red)) ///
		ytitle("Amount in TND") ///
		title("Company profit in 2024",size(medium) pos(12)) ///
		name(el_profit_2024, replace)
    gr export el_profit_2024.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_profit_2024.png, width(5000)
	putpdf pagebreak

stripplot profit if surveyround==3 & profit_2024!=666 & profit_2024!=777 & profit_2024!=888 & profit_2024!=999 & profit_2024!=1234, by(take_up) jitter(4) vertical ///
		ytitle("Amount in TND") ///
		title("Company profit in 2024",size(medium) pos(12)) ///
		name(el_profit_treat, replace)
    gr export el_profit_2024_treat.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_profit_2024_treat.png, width(5000)
	putpdf pagebreak
/*
twoway  (kdensity profit if treatment == 1 & take_up == 1 & surveyround==3 & profit_2024!=666 & profit_2024!=777 & profit_2024!=888 & profit_2024!=999 & profit_2024!=1234, lp(l) lc(maroon) yaxis(2) bw(1.5)) ///
        (kdensity profit if treatment == 1 & take_up == 0 & surveyround==3 & profit_2024!=666 & profit_2024!=777 & profit_2024!=888 & profit_2024!=999 & profit_2024!=1234, lp(l) lc(green) yaxis(2) bw(1.5)) ///
        (kdensity profit if treatment == 0 & surveyround==3 & profit_2024!=666 & profit_2024!=777 & profit_2024!=888 & profit_2024!=999 & profit_2024!=1234, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
        , ///
        legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
                     3 "Control group") ///
               col(1) pos(6) ring(6)) ///
	   title("Company profit in 2023", pos(12)) ///
	   xtitle("Amount in TND",size(medium)) 
gr export el_profit_2024_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_profit_2024_kdens.png, width(5000)
putpdf pagebreak
*/
	
 graph box profit if surveyround==3 & profit_2024!=666 & profit_2024!=777 & profit_2024!=888 & profit_2024!=999 & profit_2024!=1234, over(take_up) blabel(total, format(%9.2fc)) ///
	title("Company profit in 2024 in TND", pos(12))
gr export el_profit_2024_box.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_profit_2024_box.png, width(5000)
putpdf pagebreak 

*Endline Business performance index
gr tw ///
	(kdensity bpi if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram bpi if treatment == 1 & take_up == 1 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity bpi if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram bpi if treatment == 1 & take_up == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity bpi if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram bpi if treatment == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Endline Distribution of Business performance index}", size(medium)) ///
	subtitle("{it:Index calculated based on z-score method}") ///
	xtitle("Business performance index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
					 3 "Control group") ///
               c(1) pos(6) ring(6)) ///
	name(bpi_el, replace)
graph export bpi_el.png, replace
putpdf paragraph, halign(center) 
putpdf image bpi_el.png
putpdf pagebreak

*Endline Business performance index
gr tw ///
	(kdensity bpi if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram bpi if treatment == 1 & take_up == 1 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity bpi if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram bpi if treatment == 1 & take_up == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity bpi if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram bpi if treatment == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Endline Distribution of Business performance index}", size(medium)) ///
	subtitle("{it:Index calculated based on z-score method}") ///
	xtitle("Business performance index") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
					 3 "Control group") ///
               c(1) pos(6) ring(6)) ///
	name(bpi_el, replace)
graph export bpi_el.png, replace
putpdf paragraph, halign(center) 
putpdf image bpi_el.png
putpdf pagebreak

*Endline Business performance index in 2024
gr tw ///
	(kdensity bpi_2024 if treatment == 1 & take_up == 1 & surveyround == 3, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram bpi_2024 if treatment == 1 & take_up == 1 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(maroon)) ///
	(kdensity bpi_2024 if treatment == 1 & take_up == 0 & surveyround == 3, lp(l) lc(green) yaxis(2) bw(0.4)) ///
	(histogram bpi_2024 if treatment == 1 & take_up == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity bpi_2024 if treatment == 0 & surveyround == 3, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram bpi_2024 if treatment == 0 & surveyround == 3, freq w(.1) recast(scatter) msize(small) mc(navy)) ///
	, ///
	title("{bf:Endline Distribution of Business performance index in 2024}", size(medium)) ///
	subtitle("{it:Index calculated based on z-score method}") ///
	xtitle("Business performance index in 2024") ///
	ytitle("Number of observations", axis(1)) ///
	ytitle("Densitiy", axis(2)) ///
	legend(rows(3) symxsize(small) ///
               order(1 "Treatment group, participated" ///
                     2 "Treatment group, absent" ///
					 3 "Control group") ///
               c(1) pos(6) ring(6)) ///
	name(bpi_2024_el, replace)
graph export bpi_2024_el.png, replace
putpdf paragraph, halign(center) 
putpdf image bpi_2024_el.png
putpdf pagebreak

}

}

****** Section 8.2: Accounting CHECK******
{

putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 8.2: Accounting checks"), bold

*CA x BENEFICE 2024
twoway scatter ca_2024 profit_2024, mlabel(id_plateforme)
gr export el_caXbene2024.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_caXbene2024.png, width(5000)
putpdf pagebreak

*CA x BENEFICE 2023
twoway scatter ca profit if surveyround ==3, mlabel(id_plateforme)
gr export el_caXbene2023.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_caXbene2023.png, width(5000)
putpdf pagebreak

*CA x CA EXPORT 2024
twoway scatter ca_2024 ca_exp_2024, mlabel(id_plateforme)
gr export el_caXcaexp2024.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_caXcaexp2024.png, width(5000)
putpdf pagebreak

*CA x CA EXPORT 2023
twoway scatter ca ca_exp if surveyround ==3, mlabel(id_plateforme)
gr export el_caXcaexp2023.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_caXcaexp2023.png, width(5000)
putpdf pagebreak

*CA x empl 2024
twoway scatter ca_2024 employes if surveyround ==3, mlabel(id_plateforme)
gr export el_caXempl2024.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_caXempl2024.png, width(5000)
putpdf pagebreak

*CA x empl 2023
twoway scatter ca employes if surveyround ==3, mlabel(id_plateforme)
gr export el_caXempl2023.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_caXempl2023.png, width(5000)
putpdf pagebreak

*CA EXPORT x empl 2024
twoway scatter ca_exp_2024 employes if surveyround ==3, mlabel(id_plateforme)
gr export el_caexpXempl2024.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_caexpXempl2024.png, width(5000)
putpdf pagebreak

*CA EXPORT x empl 2023
twoway scatter ca_exp employes if surveyround ==3, mlabel(id_plateforme)
gr export el_caexpXempl2023.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_caexpXempl2023.png, width(5000)
putpdf pagebreak

*BENEFICE x empl 2024
twoway scatter profit_2024 employes if surveyround ==3, mlabel(id_plateforme)
gr export el_beneXempl2024.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_beneXempl2024.png, width(5000)
putpdf pagebreak

*BENEFICE x empl 2023
twoway scatter profit employes if surveyround ==3, mlabel(id_plateforme)
gr export el_beneXempl2023.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_beneXempl2023.png, width(5000)
putpdf pagebreak

}

****** Section 9: Intervention******
{
cd "${master_output}/figures/endline/intervention"
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 9: Intervention"), bold

* Interactions outside the consortium 
sum int_contact, d
histogram int_contact, width(1) frequency xlabel(0(1)12, nogrid format(%9.0f)) discrete ///
	xline(`r(mean)', lpattern(1)) xline(`r(p50)', lpattern()) /// 	title("Interactions outside consortia", position(12)) ///
	ylabel(0(1)10,labsize(medsmall) angle(horizontal)) ///
	xtitle("Consortia members contacted outside activities", size(medlarge)) ///
	ytitle("Frequency", size(medlarge)) ///
	text(10 `r(mean)' "Mean", size(vsmall) place(e))
graph export el_interac_cons.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_interac_cons.png, width(6000)
putpdf pagebreak

*Benefits of being part of a consortium
graph bar (sum) int_ben_network int_ben_professional int_ben_export int_ben_personal if surveyround == 3 & take_up == 1, ///
	ytitle("Number of firms", size(large)) ///
	ylabel(0(5)35,labsize(medlarge) angle(horizontal)) ///
	legend(rows(4) size(large) ///
               order(1 "Network" ///
                     2 "Professional Development" ///
					 3 "Export" ///
					 4 "Personal Development") ///
               c(1) pos(6) ring(6)) ///
	note("{bf: Note}: Based on responses from 44 out of 46 firms that decided to join a consortium.", span size(medlarge))
graph export int_ben.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image int_ben.png, width(6000)
putpdf pagebreak

*Benefits of being part of a consortium
graph bar (sum) int_incv_conflict int_incv_diversity int_incv_workload int_incv_impl if surveyround == 3 & take_up == 1, ///
	ytitle("Number of firms", size(large)) ///
	ylabel(0(5)35,labsize(medlarge) angle(horizontal)) ///
	legend(rows(4) size(large) ///
               order(1 "Personal Conflicts" ///
                     2 "Members' Diversity" ///
					 3 "Workload" ///
					 4 "Consortia Implementation ") ///
               c(1) pos(6) ring(6)) ///
	note("{bf: Note}: Based on responses from 44 out of 46 firms that decided to join a consortium.", span size(medlarge))
graph export int_incv.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image int_incv.png, width(6000)
putpdf pagebreak


graph bar (mean) refus_1 refus_2 refus_3 refus_4 refus_6 refus_5  if surveyround == 3 & int_refus != "",  ///
	title("Reasons for not joining the consortium", position(12)) ///
		legend(rows(3) symxsize(small) ///
               order(1 "Members different/not beneficial" ///
                     2 "Members are competitors" ///
					 3 "Collaboration is personally challenging" ///
					 4 "Collaboration requires time" ///
					 5 "Consortium implementation" ///
					 6 "Others") ///
               c(1) pos(6) ring(6)) /// 0(0.025)0.15
	ylabel(0.1(0.1)0.8,labsize(medsmall) angle(horizontal)) ///
	note("{bf:Note}: Based on 19 responses among 41 drop-outs.", span)
graph export reasons_drop_out.png, width(6000) replace 


graph bar (count) refus_1 refus_2 refus_3 refus_4 refus_5  if surveyround == 3, over(pole) ///
	title("Disadvantages from the consortium", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))



}


***********************************************************************
* 	PART 4:  save pdf
***********************************************************************
	* change directory to progress folder

	* pdf
putpdf save "endline_statistics", replace


