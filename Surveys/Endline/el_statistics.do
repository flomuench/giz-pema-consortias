***********************************************************************
* 			Endline progress, firm characteristics
***********************************************************************
*																	   
*	PURPOSE: 		Create statistics on firms
*	OUTLINE:														  
*	1)				progress		  		  			
*	2)  			eligibility					 
*	3)  			characteristics							  
*	Authors:  	 Kaïs Jomaa, Eya Hanefi, Amira Bouziri, Ayoub Chamakhi						    				  
*	ID variaregise: 	id (example: f101)			  					  
*	Requires: el_final.dta 
*	Creates:  el_output.dta & endline_statistics		  
*																	  
***********************************************************************
* 	PART 1:  set environment + create pdf file for export		  			
***********************************************************************
	* import file
use "${el_final}/el_final", clear

	* set directory to checks folder
cd "$el_output"
set graphics on
set scheme burd

	* create pdf document
putpdf clear
putpdf begin 
putpdf paragraph

putpdf text ("Consortias: survey progress, firm characteristics"), bold linebreak

putpdf text ("Date: `c(current_date)'"), bold linebreak


***********************************************************************
* 	PART 2:  Survey progress		  			
***********************************************************************
****** Section 1: progress ******
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 1: Survey Progress Overview"), bold
{
* total number of firms starting the survey
graph bar (count), over(treatment) blabel(total, format(%9.0fc)) ///
	title("Number of companies that at least started to fill the survey",size(medium) pos(12)) note("Date: `c(current_date)'") ///
	ytitle("Number of at least initiated survey response")
graph export total.png, width(5000) replace
putpdf paragraph, halign(center)
putpdf image total.png, width(5000)
putpdf pagebreak

*Number of validated
graph bar (count) if attest ==1, over(treatment) blabel(total, format(%9.0fc)) ///
	title("Number of companies that have validated their answers", pos(12)) note("Date: `c(current_date)'") ///
	ytitle("Number of entries")
graph export valide.png, width(5000) replace
putpdf paragraph, halign(center)
putpdf image valide.png, width(5000)
putpdf pagebreak


*share
count if id_plateforme !=.
gen share_started= (`r(N)'/176)*100
graph bar share_started, blabel(total, format(%9.2fc)) ///
	title("Share of companies that at least started to fill the survey") note("Date: `c(current_date)'") ///
	ytitle("Number of complete survey response")
graph export responserate1.png, width(5000) replace
putpdf paragraph, halign(center)
putpdf image responserate1.png, width(5000)
putpdf pagebreak
drop share_started

	* total number of firms starting the survey
count if attest==1
gen share= (`r(N)'/176)*100
graph bar share, blabel(total, format(%9.2fc)) ///
	title("Proportion of companies that have validated their answers" ,size(medium) pos(12)) note("Date: `c(current_date)'") ///
	ytitle("Number of entries")
graph export responserate2.png, width(5000) replace
putpdf paragraph, halign(center)
putpdf image responserate2.png, width(5000)
putpdf pagebreak
drop share

	 *Manière avec laquelle l'entreprise a répondu au questionnaire
graph bar (count), over(survey_phone) blabel(total) ///
	name(formation, replace) ///
	ytitle("Number of firms") ///
	title("How the company responded to the questionnaire?")
graph export type_of_surveyanswer.png, width(5000) replace
putpdf paragraph, halign(center)
putpdf image type_of_surveyanswer.png, width(5000)
putpdf pagebreak

	*timeline of responses
format %-td date 
histogram date, frequency addlabel width(0.5) ///
		tlabel(20jun2024(1)04jul2024, angle(60) labsize(vsmall)) ///
		ytitle("Answers") ///
		title("{bf:Endline survey: number of responses}") 
gr export survey_response_byday.png, replace
putpdf paragraph, halign(center) 
putpdf image survey_response_byday.png
putpdf pagebreak

}

	* Number of missing answers per section - all
graph hbar (sum) miss_inno miss_export miss_exp_pracc miss_eri_ssa miss_empl miss_manindicators miss_manprac miss_marksource miss_network miss_networkserv miss_netcoop miss_carefi miss_carloc miss_extlist miss_accounting, over(treatment) ///
blabel(total, format(%9.1fc) gap(-0.2)) ///
	legend (pos(5) row(6) label(1 "Innovation") label(2 "Export") ///
	label(3 "Export practices") label(4 "Export readiness") ///
	label(5 "Employees ") label(6 "Management Indicators") label(7 "Management prac") ///
	label(8 "Marketing Innov") label(9 "Network") label(10 "Network services") label(11 "Network coop") ///
	label(12 "Efficency") label(13 "Locus of control") label(14 "List experiment") label(15 "Accounting")) ///
	title("Sum of missing answers per section") ///
	subtitle("sample: all initiated surveys") 
gr export el_missing_asnwers_all.png, replace
putpdf paragraph, halign(center) 
putpdf image el_missing_asnwers_all.png
putpdf pagebreak

	* Number of missing answers per section - validated
graph hbar (sum) miss_inno miss_export miss_exp_pracc miss_eri_ssa miss_empl miss_manindicators miss_manprac miss_marksource miss_network miss_networkserv miss_netcoop miss_carefi miss_carloc miss_extlist miss_accounting if attest == 1, over(treatment) blabel(total, format(%9.1fc) gap(-0.2)) ///
	legend (pos(5) row(6) label(1 "Innovation") label(2 "Export") ///
	label(3 "Export practices") label(4 "Export readiness") ///
	label(5 "Employees ") label(6 "Management Indicators") label(7 "Management prac") ///
	label(8 "Marketing Innov") label(9 "Network") label(10 "Network services") label(11 "Network coop") ///
	label(12 "Efficency") label(13 "Locus of control") label(14 "List experiment") label(15 "Accounting")) ///
	subtitle("sample: all validated surveys")
gr export el_missing_asnwers_validated.png, replace
putpdf paragraph, halign(center) 
putpdf image el_missing_asnwers_validated.png
putpdf pagebreak

***********************************************************************
* 	PART 3:  Vizualisations	  			
***********************************************************************
****** Section 2: innovation ******
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 2: Innovation"), bold

	*Products or services innovations
betterbar inno_improve inno_new inno_both inno_none, over(treatment) barlab ci ///
	title("Products or services innovations", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_psinnovation.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_psinnovation.png, width(6000)
putpdf pagebreak

	*Type of innovations
betterbar inno_proc_met inno_proc_log inno_proc_prix inno_proc_sup inno_proc_autres, over(treatment) barlab ci ///
	title("Type of innovations", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_typeinnovation.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_typeinnovation.png, width(6000)
putpdf pagebreak

	*Source of the innovation	
betterbar inno_mot_cons inno_mot_cont inno_mot_eve inno_mot_client inno_mot_dummyother, over(treatment) barlab ci ///
	title("Source of innovations", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_sourceinnovation.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_sourceinnovation.png, width(6000)
putpdf pagebreak


* Entreprise model
graph bar (count), over(entreprise_model) over(treatment)  blabel(total, format(%9.1fc) gap(-0.2)) ///
	legend (pos(6) row(3)) ///
	subtitle("Entreprise model")
gr export el_entreprise_model.png, replace
putpdf paragraph, halign(center) 
putpdf image el_entreprise_model.png
putpdf pagebreak

****** Section 3: Export ******
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 3: Export"), bold

* Export: direct, indirect, no export
graph bar (mean) export_1 export_2 export_3, over(treatment) percentage blabel(total, format(%9.1fc) gap(-0.2)) ///
    legend (pos(6) row(6) label (1 "Direct export") label (2 "Indirect export") ///
	label (3 "No export")) ///
	title("Firm & export status", pos(12)) 
gr export el_firm_exports.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_firm_exports.png, width(5000)
putpdf pagebreak

*export or not 2023
graph pie, over(marginal_exp_2023) by(treatment) plabel(_all percent, format(%9.0f) size(medium)) ///
    graphregion(fcolor(none) lcolor(none)) bgcolor(white) legend(pos(6)) ///
    title("Did the company export in 2023 (based on export turnover) ?", pos(12) size(small))
gr export export_2023_pie.png, replace
putpdf paragraph, halign(center) 
putpdf image export_2023_pie.png, width(5000)
putpdf pagebreak

*export or not 2024
graph pie, over(marginal_exp_2024) by(treatment) plabel(_all percent, format(%9.0f) size(medium)) ///
    graphregion(fcolor(none) lcolor(none)) bgcolor(white) legend(pos(6)) ///
    title("Did the company export in 2024 (based on export turnover) ?", pos(12) size(small))
gr export export_2024_pie.png, replace
putpdf paragraph, halign(center) 
putpdf image export_2024_pie.png, width(5000)
putpdf pagebreak

* Reasons for not exporting
graph bar (mean) export_41 export_42 export_43 export_44 export_45, over(treatment) percentage blabel(total, format(%9.1fc) gap(-0.2)) ///
    legend (pos(6) row(6) label (1 "Not profitable") label (2 "Did not find clients abroad") ///
	label (3 "Too complicated") label (4 "Requires too much investment") label (5 "Binary other reason")) ///
	ylabel(0(20)100, nogrid)  ///
	title("Reasons for not exporting", pos(12)) 
gr export el_no_exports.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_no_exports.png, width(5000)
putpdf pagebreak

*No of export destinations
sum exp_pays
stripplot exp_pays, jitter(4) vertical yline(`=r(mean)', lcolor(red)) ///
		ytitle("Number of countries") ///
		title("Number of export countries" , pos(12)) ///
		name(el_exp_pays, replace)
    gr export el_exp_pays.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_exp_pays.png, width(5000)
	putpdf pagebreak
	
stripplot exp_pays, by(treatment) jitter(4) vertical ///
		ytitle("Number of countries") ///
		title("Number of export countries",size(medium) pos(12)) ///
		name(el_exp_pays_treat, replace)
    gr export el_exp_pays_treat.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_exp_pays_treat.png, width(5000)
	putpdf pagebreak

	twoway (kdensity exp_pays if treatment == 0, lcolor(blue) lpattern(solid) legend(label(1 "Control"))) ///
	   (kdensity exp_pays if treatment == 1, lcolor(red) lpattern(dash) legend(label(2 "Treatment"))), ///
       legend(symxsize(small) order(1 "Control" 2 "Treatment")) ///
	   title("Number of export countries", pos(12) size(medium)) ///
	   xtitle("Number of countries",size(medium)) ///
	   ytitle("Densitiy", size(medium))
gr export el_exp_pays_treat_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_exp_pays_treat_kdens.png, width(5000)
putpdf pagebreak

 graph box exp_pays if exp_pays > 0, over(treatment) blabel(total, format(%9.2fc)) ///
	title("Number of export countries", pos(12))
gr export el_exp_pays_box.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_exp_pays_box.png, width(5000)
putpdf pagebreak

*No of export destinations SSA
sum exp_pays_ssa
stripplot exp_pays, jitter(4) vertical yline(`=r(mean)', lcolor(red)) ///
		ytitle("Number of countries") ///
		title("Number of export countries SSA" , pos(12)) ///
		name(el_exp_paysSSA, replace)
    gr export el_exp_paysSSA.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_exp_paysSSA.png, width(5000)
	putpdf pagebreak
	
stripplot exp_pays_ssa, by(treatment) jitter(4) vertical ///
		ytitle("Number of countries") ///
		title("Number of export countries SSA",size(medium) pos(12)) ///
		name(el_exp_paysSSA_treat, replace)
    gr export el_exp_paysSSA_treat.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_exp_paysSSA_treat.png, width(5000)
	putpdf pagebreak

	twoway (kdensity exp_pays_ssa if treatment == 0, lcolor(blue) lpattern(solid) legend(label(1 "Control"))) ///
	   (kdensity exp_pays_ssa if treatment == 1, lcolor(red) lpattern(dash) legend(label(2 "Treatment"))), ///
       legend(symxsize(small) order(1 "Control" 2 "Treatment")) ///
	   title("Number of export countries SSA", pos(12) size(medium)) ///
	   xtitle("Number of countries",size(medium)) ///
	   ytitle("Densitiy", size(medium))
gr export el_exp_paysSSA_treat_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_exp_paysSSA_treat_kdens.png, width(5000)
putpdf pagebreak

 graph box exp_pays_ssa if exp_pays_ssa > 0, over(treatment) blabel(total, format(%9.2fc)) ///
	title("Number of export countries SSA", pos(12))
gr export el_exp_paysSSA_box.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_exp_paysSSA_box.png, width(5000)
putpdf pagebreak

*International clients
sum clients
stripplot clients, jitter(4) vertical yline(`=r(mean)', lcolor(red)) ///
		ytitle("Number of clients") ///
		title("Number of International clients" , pos(12)) ///
		name(el_clients, replace)
    gr export el_clients.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_clients.png, width(5000)
	putpdf pagebreak
	
stripplot clients, by(treatment) jitter(4) vertical ///
		ytitle("Number of clients") ///
		title("Number of International client",size(medium) pos(12)) ///
		name(el_clients_treat, replace)
    gr export el_clients_treat.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_clients_treat.png, width(5000)
	putpdf pagebreak

	twoway (kdensity clients if treatment == 0, lcolor(blue) lpattern(solid) legend(label(1 "Control"))) ///
	   (kdensity clients if treatment == 1, lcolor(red) lpattern(dash) legend(label(2 "Treatment"))), ///
       legend(symxsize(small) order(1 "Control" 2 "Treatment")) ///
	   title("Number of International clients", pos(12) size(medium)) ///
	   xtitle("Number of clients",size(medium)) ///
	   ytitle("Densitiy", size(medium))
gr export el_clients_treat_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_clients_treat_kdens.png, width(5000)
putpdf pagebreak

 graph box clients if clients > 0, over(treatment) blabel(total, format(%9.2fc)) ///
	title("Number of International clients", pos(12))
gr export el_clients_box.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_clients_box.png, width(5000)
putpdf pagebreak

*International clients SSA
sum clients_ssa
stripplot clients_ssa, jitter(4) vertical yline(`=r(mean)', lcolor(red)) ///
		ytitle("Number of clients") ///
		title("Number of International clients SSA" , pos(12)) ///
		name(el_clientsSSA, replace)
    gr export el_clientsSSA.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_clientsSSA.png, width(5000)
	putpdf pagebreak
	
stripplot clients_ssa, by(treatment) jitter(4) vertical ///
		ytitle("Number of clients") ///
		title("Number of International clients SSA" , pos(12) size(medium)) ///
		name(el_clientsSSA_treat, replace)
    gr export el_clientsSSA_treat.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_clientsSSA_treat.png, width(5000)
	putpdf pagebreak

	twoway (kdensity clients_ssa if treatment == 0, lcolor(blue) lpattern(solid) legend(label(1 "Control"))) ///
	   (kdensity clients_ssa if treatment == 1, lcolor(red) lpattern(dash) legend(label(2 "Treatment"))), ///
       legend(symxsize(small) order(1 "Control" 2 "Treatment")) ///
	   xtitle("Number of International clients SSA",size(medium)) ///
	   ytitle("Densitiy", size(medium))
gr export el_clientsSSA_treat_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_clientsSSA_treat_kdens.png, width(5000)
putpdf pagebreak

 graph box clients_ssa if clients_ssa > 0, over(treatment) blabel(total, format(%9.2fc)) ///
 	title("Number of International clients SSA", pos(12))
gr export el_clientsSSA_box.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_clientsSSA_box.png, width(5000)
putpdf pagebreak

*International orders SSA
sum clients_ssa_commandes
stripplot clients_ssa_commandes, jitter(4) vertical yline(`=r(mean)', lcolor(red)) ///
		ytitle("Number of orders from SSA") ///
		title("Number of orders" , pos(12)) ///
		name(el_ordersSSA, replace)
    gr export el_ordersSSA.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_ordersSSA.png, width(5000)
	putpdf pagebreak
	
stripplot clients_ssa_commandes, by(treatment) jitter(4) vertical ///
		ytitle("Number of orders from SSA") ///
		title("Number of orders",size(medium) pos(12)) ///
		name(el_ordersSSA_treat, replace)
    gr export el_ordersSSA_treat.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_ordersSSA_treat.png, width(5000)
	putpdf pagebreak

	twoway (kdensity clients_ssa_commandes if treatment == 0, lcolor(blue) lpattern(solid) legend(label(1 "Control"))) ///
	   (kdensity clients_ssa_commandes if treatment == 1, lcolor(red) lpattern(dash) legend(label(2 "Treatment"))), ///
       legend(symxsize(small) order(1 "Control" 2 "Treatment")) ///
	   title("Number of orders from SSA", pos(12) size(medium)) ///
	   xtitle("Number of orders",size(medium)) ///
	   ytitle("Densitiy", size(medium))
gr export el_ordersSSA_treat_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_ordersSSA_treat_kdens.png, width(5000)
putpdf pagebreak

 graph box clients_ssa_commandes if clients_ssa_commandes > 0, over(treatment) blabel(total, format(%9.2fc)) ///
	title("Number of orders from SSA", pos(12))
gr export el_ordersSSA_box.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_ordersSSA_box.png, width(5000)
putpdf pagebreak
	
*export practices
betterbar exp_pra_rexp exp_pra_foire exp_pra_sci exp_pra_norme exp_pra_vent, over(treatment) barlab ci ///
	title("Export practices", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_expprac.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_expprac.png, width(6000)
putpdf pagebreak

*export practices SSA
betterbar ssa_action1 ssa_action2 ssa_action3 ssa_action4, over(treatment) barlab ci ///
	title("Export practices in SSA", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_exppracSSA.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_exppracSSA.png, width(6000)
putpdf pagebreak

*export cost perception
	 betterbar expp_cost, over(treatment) barlab ci ///
    title("Perception of export costs", pos(12)) note("1 = very low, 7= very high", pos(6)) ///
    ylabel(0(1)7, nogrid) ///
    ytitle("Mean perception of export costs")
gr export el_export_costs.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_export_costs.png, width(5000)
putpdf pagebreak

*export benefits perception
	 betterbar expp_ben, over(treatment) barlab ci ///
    title("Perception of export benefits", pos(12)) note("1 = very low, 7= very high", pos(6)) ///
    ylabel(0(1)7, nogrid) ///
    ytitle("Mean perception of export benefits")
gr export el_export_bene.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_export_bene.png, width(5000)
putpdf pagebreak

****** Section 4: The Firm ******
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 4: The Firm"), bold

*empl
twoway (kdensity employes if treatment == 0, lcolor(blue) lpattern(solid) legend(label(1 "Control"))) ///
	   (kdensity employes if treatment == 1, lcolor(red) lpattern(dash) legend(label(2 "Treatment"))), ///
       legend(symxsize(small) order(1 "Control" 2 "Treatment")) ///
	   title("Number of full-time employees", pos(12)) ///
	   xtitle("Number of full-time employees",size(medium)) ///
	   ytitle("Densitiy", size(medium))
gr export el_fte_treat_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_fte_treat_kdens.png, width(5000)
putpdf pagebreak

*female empl
twoway (kdensity car_empl1 if treatment == 0, lcolor(blue) lpattern(solid) legend(label(1 "Control"))) ///
	   (kdensity car_empl1 if treatment == 1, lcolor(red) lpattern(dash) legend(label(2 "Treatment"))), ///
       legend(symxsize(small) order(1 "Control" 2 "Treatment")) ///
	   title("Number of female employees", pos(12)) ///
	   xtitle("Number of female employees",size(medium)) ///
	   ytitle("Densitiy", size(medium))
gr export el_ftefemale_treat_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_ftefemale_treat_kdens.png, width(5000)
putpdf pagebreak

*youth
twoway (kdensity car_empl2 if treatment == 0, lcolor(blue) lpattern(solid) legend(label(1 "Control"))) ///
	   (kdensity car_empl2 if treatment == 1, lcolor(red) lpattern(dash) legend(label(2 "Treatment"))), ///
       legend(symxsize(small) order(1 "Control" 2 "Treatment")) ///
	   title("Number of young employees (less than 36)", pos(12)) ///
	   xtitle("Number of young employees (less than 36)",size(medium)) ///
	   ytitle("Densitiy", size(medium))
gr export el_fteyouth_treat_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_fteyouth_treat_kdens.png, width(5000)
putpdf pagebreak

****** Section 5: Management******
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 5: Management"), bold

*performance indicators
betterbar man_fin_per_ind man_fin_per_pro man_fin_per_qua man_fin_per_sto man_fin_per_emp man_fin_per_liv man_fin_per_fre, over(treatment) barlab ci ///
	title("Performance indicators", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_perfindic.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_perfindic.png, width(6000)
putpdf pagebreak

*performance frequency
betterbar man_fin_per_fre, over(treatment) barlab ci ///
	title("KPIs tracking frequency", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_KPItrack.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_KPItrack.png, width(6000)
putpdf pagebreak

*management activities
betterbar man_fin_pra_bud man_fin_pra_pro man_fin_pra_dis, over(treatment) barlab ci ///
	title("Management activities", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_manact.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_manact.png, width(6000)
putpdf pagebreak

*marketing source
betterbar man_source_cons man_source_pdg man_source_fam man_source_even man_source_autres, over(treatment) barlab ci ///
	title("Marketing strategies source", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_marksource.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_marksource.png, width(6000)
putpdf pagebreak

****** Section 6: Network******
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 6: Network"), bold

*associations
twoway (kdensity net_association if treatment == 0, lcolor(blue) lpattern(solid) legend(label(1 "Control"))) ///
	   (kdensity net_association if treatment == 1, lcolor(red) lpattern(dash) legend(label(2 "Treatment"))), ///
       legend(symxsize(small) order(1 "Control" 2 "Treatment")) ///
	   title("Number of formal asssociations membership", pos(12)) ///
	   xtitle("Number of formal asssociations membership",size(medium)) ///
	   ytitle("Densitiy", size(medium))
gr export el_assoc_treat_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_assoc_treat_kdens.png, width(5000)
putpdf pagebreak

* male
tw ///
	(kdensity net_size3_m if treatment == 1, lp(l) lc(maroon) bw(0.5)) ///
	(kdensity net_size3_m if treatment == 0, lp(l) lc(navy) bw(0.5)) ///
	, ///
	xtitle("Male entrepreneurs discussions about business", size(vsmall)) ///
	ytitle("Density", size(vsmall)) ///	
	legend(symxsize(small) order(1 "Treatment" 2 "Control")  pos(6) row(1)) ///
	name(network_density_m, replace)
		
		* female
tw ///
	(kdensity net_gender3 if treatment == 1, lp(l) lc(maroon) bw(0.5)) ///
	(kdensity net_gender3 if treatment == 0, lp(l) lc(navy) bw(0.5)) ///
	, ///
	xtitle("Female entrepreneurs discussions about business", size(vsmall)) ///
	ytitle("Densitiy", size(vsmall)) ///	
	legend(symxsize(small) order(1 "Treatment" 2 "Control")  pos(6) row(1)) ///
	name(network_density_f, replace)
	
gr combine network_density_f network_density_m, name(el_network_density, replace) ycommon
gr export el_network_density.png, replace
putpdf paragraph, halign(center) 
putpdf image el_network_density.png
putpdf pagebreak	

* Number of discussions with family/friends
betterbar net_size4_m net_gender4, over(treatment) barlab ci  ///
	title("Discussions about business")
 gr export el_mean_fafri_met.png, replace
putpdf paragraph, halign(center) 
putpdf image el_mean_fafri_met.png
putpdf pagebreak	
	
		* male
tw ///
	(kdensity net_size4_m if treatment == 1, lp(l) lc(maroon) bw(0.5)) ///
	(kdensity net_size4_m if treatment == 0, lp(l) lc(navy) bw(0.5)) ///
	, ///
	xtitle("Male family/friends discussions about business", size(vsmall)) ///
	ytitle("Density", size(vsmall)) ///	
	legend(symxsize(small) order(1 "Treatment" 2 "Control")  pos(6) row(1)) ///
	name(network_density_fafrim, replace)
		
		* female
tw ///
	(kdensity net_gender4 if treatment == 1, lp(l) lc(maroon) bw(0.5)) ///
	(kdensity net_gender4 if treatment == 0, lp(l) lc(navy) bw(0.5)) ///
	, ///
	xtitle("Female family/friends discussions about business", size(vsmall)) ///
	ytitle("Densitiy", size(vsmall)) ///	
	legend(symxsize(small) order(1 "Treatment" 2 "Control")  pos(6) row(1)) ///
	name(network_density_fafrif, replace)
	
gr combine network_density_fafrim network_density_fafrif, name(el_network_densityfafri, replace) ycommon
gr export el_network_densityfafri.png, replace
putpdf paragraph, halign(center) 
putpdf image el_network_densityfafri.png
putpdf pagebreak

* Number of discussions with m/f other entrepreneurs
betterbar net_size3_m net_gender3, over(treatment) barlab ci  ///
	title("Entrepneurship discussions", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
 gr export el_mean_entrepreneurs_met.png, replace
putpdf paragraph, halign(center) 
putpdf image el_mean_entrepreneurs_met.png
putpdf pagebreak

*consortium femme female met
*efficency 
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

*net services
betterbar net_services_pratiques net_services_produits net_services_mark net_services_sup net_services_contract net_services_confiance net_services_autre, over(treatment) barlab ci ///
	title("Network services", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_netserv.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_netserv.png, width(6000)
putpdf pagebreak

* Interactions between CEO	
betterbar net_coop_pos net_coop_neg, over(treatment) barlab ci ///
	title("Perception of interactions", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_netcoop.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_netcoop.png, width(6000)
putpdf pagebreak

*net coop
betterbar netcoop1 netcoop2 netcoop3 netcoop4 netcoop5 netcoop6 netcoop7 netcoop8 netcoop9 netcoop10, over(treatment) barlab ci ///
	title("Network interactions", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_netcoop.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_netcoop.png, width(6000)
putpdf pagebreak

****** Section 5: Entrepneurship******
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 6: Entrepneurship"), bold

*efficency 
betterbar car_efi_fin1 car_efi_man car_efi_motiv, over(treatment) barlab ci ///
	title("Entrepneurship efficency", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_entrep_effi.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_entrep_effi.png, width(6000)
putpdf pagebreak

*locus of control 
betterbar car_loc_env car_loc_exp car_loc_soin, over(treatment) barlab ci ///
	title("Entrepneurship Locus", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal))
graph export el_entrep_loc.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_entrep_loc.png, width(6000)
putpdf pagebreak

*listexp
*graph bar list_exp, over(list_group) - where list_exp provides the number of confirmed affirmations).
graph bar listexp1, over(list_group_el, relabel(1 "Non-sensitive" 2 "Sensitive  incl." 3 "Non-sensitive" 4 "Sensitive incl.")) over(treatment) ///
	blabel(total, format(%9.2fc) gap(-0.2)) ///
	title("List experiment question") ///
ytitle("No. of affirmations") ///
ylabel(0(1)3.2, nogrid) 
gr export el_bar_listexp.png, replace
putpdf paragraph, halign(center) 
putpdf image el_bar_listexp.png
putpdf pagebreak

****** Section 6: Accounting******
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 7: Accounting"), bold
{
	*Bénéfices/Perte 2023
graph pie, over(profit_2023_category) plabel(_all percent, format(%9.0f) size(medium)) graphregion(fcolor(none) lcolor(none)) ///
   bgcolor(white) legend(pos(6)) ///
   title("Did the company make a loss or a profit in 2023?", pos(12))
   gr export profit_2023_category.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image profit_2023_category.png, width(5000)
	putpdf pagebreak
	
graph pie, over(profit_2023_category) by(treatment) plabel(_all percent, format(%9.0f) size(medium)) ///
    graphregion(fcolor(none) lcolor(none)) bgcolor(white) legend(pos(6)) ///
    title("Did the company make a loss or a profit in 2023?", pos(12) size(small))
   gr export profit_2023_category_treat.png, replace
	putpdf paragraph, halign(center) 
	putpdf image profit_2023_category_treat.png, width(5000)
	putpdf pagebreak
	
    * Chiffre d'affaires total en dt en 2023 
sum ca
stripplot ca if ca!=666 & ca!=888 & ca!=999 , jitter(4) vertical yline(`=r(mean)', lcolor(red)) ///
		title("Total turnover in 2023",size(medium) pos(12)) ///
		ytitle("Amount in TND") ///
		name(el_ca, replace)
    gr export el_ca.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_ca.png, width(5000)
	putpdf pagebreak

stripplot ca if ca!=666 & ca!=888 & ca!=999, by(treatment) jitter(4) vertical  ///
		title("Total turnover in 2023",size(medium) pos(12)) ///
		ytitle("Amount in TND") ///
		name(el_ca_treat, replace)
    gr export el_ca_treat.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_ca_treat.png, width(5000)
	putpdf pagebreak
	
twoway (kdensity ca if treatment == 0 & ca!=666 & ca!=888 & ca!=999, lcolor(blue) lpattern(solid) legend(label(1 "Control"))) ///
       (kdensity ca if treatment == 1 & ca!=666 & ca!=888 & ca!=999 , lcolor(red) lpattern(dash) legend(label(2 "Treatment"))), ///
       legend(symxsize(small) order(1 "Control" 2 "Treatment")) ///
	   title("Total turnover in 2023", pos(12)) ///
	   xtitle("Total turnover",size(medium)) ///
	   ytitle("Densitiy", size(medium))
gr export el_ca_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_ca_kdens.png, width(5000)
putpdf pagebreak
	   
 graph box ca if ca > 0 & ca!=666 & ca!=888 & ca!=999 , over(treatment) blabel(total, format(%9.2fc)) ///
	title("Total turnover in 2023 in TND", pos(12))
gr export el_ca_box.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_ca_box.png, width(5000)
putpdf pagebreak

    * Chiffre d'affaires total en dt en 2024 

sum ca_2024
stripplot ca_2024 if ca_2024!=666 & ca_2024!=888 & ca_2024!=999 , jitter(4) vertical yline(`=r(mean)', lcolor(red)) ///
		title("Total turnover in 2024",size(medium) pos(12)) ///
		ytitle("Amount in TND") ///
		name(el_ca_2024, replace)
    gr export el_ca_2024.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_ca_2024.png, width(5000)
	putpdf pagebreak

stripplot ca_2024 if ca_2024!=666 & ca_2024!=888 & ca_2024!=999 , by(treatment) jitter(4) vertical ///
		title("Total turnover in 2024",size(medium) pos(12)) ///
		ytitle("Amount in TND") ///
		name(el_ca_2024_treat, replace)
    gr export el_ca_2024_treat.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_ca_2024_treat.png, width(5000)
	putpdf pagebreak

twoway (kdensity ca_2024 if treatment == 0 & ca_2024!=666 & ca_2024!=888 & ca_2024!=999 , lcolor(blue) lpattern(solid) legend(label(1 "Control"))) ///
       (kdensity ca_2024 if treatment == 1 & ca_2024!=666 & ca_2024!=888 & ca_2024!=999 , lcolor(red) lpattern(dash) legend(label(2 "Treatment"))), ///
       legend(symxsize(small) order(1 "Control" 2 "Treatment")) ///
	   title("Total turnover in 2024", pos(12)) ///
	   xtitle("Total turnover",size(medium)) ///
	   ytitle("Densitiy", size(medium))
gr export el_ca_2024_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_ca_2024_kdens.png, width(5000)
putpdf pagebreak
	   	
 graph box ca_2024 if ca_2024 > 0 & ca_2024!=666 & ca_2024!=888 & ca_2024!=999, over(treatment) blabel(total, format(%9.2fc)) ///
	title("Total turnover in 2024 in TND", pos(12))
gr export el_ca_2024_box.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_ca_2024_box.png, width(5000)
putpdf pagebreak

   *Chiffre d'affaires à l'export en dt en 2023
 sum ca_exp
stripplot ca_exp if ca_exp!=666 & ca_exp!=888 & ca_exp!=999 , jitter(4) vertical yline(`=r(mean)', lcolor(red)) ///
		title("Export turnover in 2023",size(medium) pos(12)) ///
		ytitle("Amount in TND") ///
		name(el_ca_exp, replace)
    gr export el_ca_exp.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_ca_exp.png, width(5000)
	putpdf pagebreak

stripplot ca_exp if ca_exp!=666 & ca_exp!=888 & ca_exp!=999, by(treatment) jitter(4) vertical ///
		title("Export turnover in 2023",size(medium) pos(12)) ///
		ytitle("Amount in TND") ///
		name(el_ca_exp_treat, replace)
    gr export el_ca_exp_treat.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_ca_exp_treat.png, width(5000)
	putpdf pagebreak
	
twoway (kdensity ca_exp if treatment == 0 & ca_exp!=666 & ca_exp!=888 & ca_exp!=999, lcolor(blue) lpattern(solid) legend(label(1 "Control"))) ///
       (kdensity ca_exp if treatment == 1 & ca_exp!=666 & ca_exp!=888 & ca_exp!=999, lcolor(red) lpattern(dash) legend(label(2 "Treatment"))), ///
       legend(symxsize(small) order(1 "Control" 2 "Treatment")) ///
	   title("Export turnover in 2023", pos(12)) ///
	   xtitle("Export turnover",size(medium)) ///
	   ytitle("Densitiy", size(medium))
gr export el_ca_exp_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_ca_exp_kdens.png, width(5000)
putpdf pagebreak
	
 graph box ca_exp if ca_exp > 0 & ca_exp!=666 & ca_exp!=888 & ca_exp!=999, over(treatment) blabel(total, format(%9.2fc)) ///
	title("Export turnover in 2023 in TND", pos(12))
gr export el_ca_exp_box.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_ca_exp_box.png, width(5000)
putpdf pagebreak

	*Bénéfices/Perte 2024
graph pie, over(profit_2024_category) plabel(_all percent, format(%9.0f) size(medium)) graphregion(fcolor(none) lcolor(none)) ///
   bgcolor(white) legend(pos(6)) ///
   title("Did the company make a loss or a profit in 2024?", pos(12))
   gr export profit_2024_category.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image profit_2024_category.png, width(5000)
	putpdf pagebreak
	
	graph pie, over(profit_2024_category)  by(treatment) plabel(_all percent, format(%9.0f) size(medium)) graphregion(fcolor(none) lcolor(none)) ///
   bgcolor(white) legend(pos(6)) ///
   title("Did the company make a loss or a profit in 2024?", pos(12) size(small))
   gr export profit_2024_category_treat.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image profit_2024_category_treat.png, width(5000)
	putpdf pagebreak
	
   *Chiffre d'affaires à l'export en dt en 2024
sum compexp_2024
stripplot compexp_2024 if compexp_2024!=666 & compexp_2024!=888 & compexp_2024!=999, jitter(4) vertical yline(`=r(mean)', lcolor(red)) ///
		ytitle("Amount in TND") ///
		title("Export turnover in 2024",size(medium) pos(12)) ///
		name(el_compexp_2024, replace)
    gr export el_compexp_2024.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_compexp_2024.png, width(5000)
	putpdf pagebreak
	
stripplot compexp_2024 if compexp_2024!=666 & compexp_2024!=888 & compexp_2024!=999, by(treatment) jitter(4) vertical  ///
		ytitle("Amount in TND") ///
		title("Export turnover in 2024",size(medium) pos(12)) ///
		name(el_compexp_2024_treat, replace)
    gr export el_compexp_2024_treat.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_compexp_2024_treat.png, width(5000)
	putpdf pagebreak

twoway (kdensity compexp_2024 if treatment == 0 & compexp_2024!=666 & compexp_2024!=888 & compexp_2024!=999, lcolor(blue) lpattern(solid) legend(label(1 "Control"))) ///
	   (kdensity compexp_2024 if treatment == 1 & compexp_2024!=666 & compexp_2024!=888 & compexp_2024!=999, lcolor(red) lpattern(dash) legend(label(2 "Treatment"))), ///
       legend(symxsize(small) order(1 "Control" 2 "Treatment")) ///
	   title("Export turnover in 2024", pos(12)) ///
	   xtitle("Export turnover",size(medium)) ///
	   ytitle("Densitiy", size(medium))
gr export el_compexp_2024_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_compexp_2024_kdens.png, width(5000)
putpdf pagebreak

graph box compexp_2024 if compexp_2024 > 0 & compexp_2024!=666 & compexp_2024!=888 & compexp_2024!=999, over(treatment) blabel(total, format(%9.2fc)) ///
	title("Export turnover in 2024 in TND", pos(12))
gr export el_compexp_2024_box.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_compexp_2024_box.png, width(5000)
putpdf pagebreak

 *Profit en dt en 2023
sum profit
stripplot profit if profit!=666 & profit!=888 & profit!=999, jitter(4) vertical yline(`=r(mean)', lcolor(red)) ///
		ytitle("Amount in TND") ///
		title("Company profit in 2023",size(medium) pos(12)) ///
		name(el_profit, replace)
    gr export el_profit.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_ca_exp.png, width(5000)
	putpdf pagebreak

stripplot profit if profit!=666 & profit!=888 & profit!=999, by(treatment) jitter(4) vertical ///
		ytitle("Amount in TND") ///
		title("Company profit in 2023",size(medium) pos(12)) ///
		name(el_profit_treat, replace)
    gr export el_profit_treat.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_profit_treat.png, width(5000)
	putpdf pagebreak

twoway (kdensity profit if treatment == 0 & profit!=666 & profit!=888 & profit!=999, lcolor(blue) lpattern(solid) legend(label(1 "Control"))) ///
	   (kdensity profit if treatment == 1 & profit!=666 & profit!=888 & profit!=999, lcolor(red) lpattern(dash) legend(label(2 "Treatment"))), ///
       legend(symxsize(small) order(1 "Control" 2 "Treatment")) ///
	   title("Company profit in 2023", pos(12)) ///
	   xtitle("Company profit",size(medium)) ///
	   ytitle("Densitiy", size(medium))
gr export el_profit_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_profit_kdens.png, width(5000)
putpdf pagebreak


 graph box profit if profit!=666 & profit!=888 & profit!=999, over(treatment) blabel(total, format(%9.2fc)) ///
	title("Company profit in 2023 in TND", pos(12))
gr export el_profit_box.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_profit_box.png, width(5000)
putpdf pagebreak

 *Profit en dt en 2024
sum profit_2024
stripplot profit_2024 if profit_2024!=666 & profit_2024!=888 & profit_2024!=999 , jitter(4) vertical yline(`=r(mean)', lcolor(red)) ///
		title("Company profit in 2024",size(medium) pos(12)) ///
		ytitle("Amount in TND") ///
		name(el_profit_2024, replace)
    gr export el_profit_2024.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_compexp_2024.png, width(5000)
	putpdf pagebreak
	
stripplot profit_2024 if profit_2024!=666 & profit_2024!=888 & profit_2024!=999 , by(treatment) jitter(4) vertical  ///
		title("Company profit in 2024",size(medium) pos(12)) ///
		ytitle("Amount in TND") ///
		name(el_profit_2024_treat, replace)
    gr export el_profit_2024_treat.png, width(5000) replace
	putpdf paragraph, halign(center) 
	putpdf image el_profit_2024_treat.png, width(5000)
	putpdf pagebreak

twoway (kdensity profit_2024 if treatment == 0 & profit_2024!=666 & profit_2024!=888 & profit_2024!=999 , lcolor(blue) lpattern(solid) legend(label(1 "Control"))) ///
	   (kdensity profit_2024 if treatment == 1 & profit_2024!=666 & profit_2024!=888 & profit_2024!=999 , lcolor(red) lpattern(dash) legend(label(2 "Treatment"))), ///
       legend(symxsize(small) order(1 "Control" 2 "Treatment")) ///
	   title("Company profit in 2024", pos(12)) ///
	   xtitle("Company profit",size(medium)) ///
	   ytitle("Densitiy", size(medium))
gr export el_profit_2024_kdens.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_profit_2024_kdens.png, width(5000)
putpdf pagebreak

 graph box profit_2024 if profit_2024!=666 & profit_2024!=888 & profit_2024!=999 , over(treatment) blabel(total, format(%9.2fc)) ///
	title("Company profit in 2024 in TND", pos(12))
gr export el_profit_2024_box.png, width(5000) replace
putpdf paragraph, halign(center) 
putpdf image el_profit_2024_box.png, width(5000)
putpdf pagebreak
}

****** Section 7: Intervention******
putpdf paragraph,  font("Courier", 20)
putpdf text ("Section 7: Intervention"), bold

*efficency 
sum int_contact, d
histogram int_contact, width(1) frequency addlabels xlabel(0(2)15, nogrid format(%9.0f)) discrete ///
	xline(`r(mean)', lpattern(1)) xline(`r(p50)', lpattern()) ///
	title("Interactions outside consortia", position(12)) ///
	ylabel(,labsize(vsmall) angle(horizontal)) ///
	text(100 `r(mean)' "Mean", size(vsmall) place(e)) ///
	text(100 `r(p50)' "Median", size(vsmall) place(w))
graph export el_interac_cons.png, width(6000) replace 
putpdf paragraph, halign(center) 
putpdf image el_interac_cons.png, width(6000)
putpdf pagebreak

***********************************************************************
* 	PART 4:  save pdf
***********************************************************************
	* change directory to progress folder

	* pdf
putpdf save "endline_statistics", replace
