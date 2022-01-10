***********************************************************************
* 			registration generate									  	  
***********************************************************************
*																	    
*	PURPOSE: generate registration variables				  							  
*																	  
*																	  
*	OUTLINE:														  
*	1) sector
* 	2) gender
* 	3) onshore / offshore  							  
*	4) produit exportable  
*	5) intention d'exporter 			  
*	6) une opération d'export				  
*   7) export status  
*	8) age
*	9) eligibility	
*
*																	  															      
*	Author:  	Florian Muench & Kais Jomaa							  
*	ID variaregise: 	id (example: f101)			  					  
*	Requires: regis_inter.dta 	  								  
*	Creates:  regis_inter.dta			                          
*																	  
***********************************************************************
* 	PART 1:  Define non-response categories  			
***********************************************************************
use "${regis_intermediate}/regis_inter", clear


***********************************************************************
* 	PART 2: factor variable sector & subsector 			  										  
***********************************************************************

/*label define sector_name 1 "Agriculture & Peche" ///
	2 "Artisanat" ///
	3 "Commerce international" ///
	4 "Industrie" ///
	5 "Services" ///
	6 "TIC" */

label define subsector_name 1 "autres" ///
	2 "pôle d'activités agri-agroalimentaire" ///
	3 "pôle d'activités artisanat" ///
	4 "pôle d'activités cosmétiques" ///
	5 "pôle d'activités de service conseil, education et formation" ///
	6 "pôle d'activités technologies de l'information et de la communication" ///
	7 "pôle d'activités textiles et habillement" ///
	8 "pôle de l'énergie durable et développement durable" ///
	9 "pôle d’activités artisanat" ///
	10 "pôle d’activités de service conseil, education et formation" ///
	11 "pôle d’activités technologies de l’information et de la communication"

/*tempvar Sector
encode sector, gen(`Sector')
drop sector
rename `Sector' sector
lab values sector sector_name */

tempvar Subsector
encode subsector, gen(`Subsector')
drop subsector
rename `Subsector' subsector
lab values subsector subsector_name


format %-25.0fc *sector

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
* 	PART : chiffres d'affaires et chiffres d'affaires à l'export
***********************************************************************
	* change the units
forvalues x = 2018(1)2020 {
	replace ca_`x' = ca_`x'/100000
	lab var ca_`x' "chiffres d'affaires `x' en 100.000"
	replace ca_exp`x' = ca_exp`x'/100000
	lab var ca_exp`x' "chiffres d'affaires export `x' en 100.000"
}

format ca_* %12.2fc


	* generate average for 2018-2020
egen ca_mean = rowmean(ca_2018 ca_2019 ca_2020)
lab var ca_mean "chiffre d'affaires moyenne 2018-2020"
egen ca_exp_mean = rowmean(ca_exp2018 ca_exp2019 ca_exp2020)
lab var ca_mean "chiffre d'affaires export moyenne 2018-2020"

	* gen share of export ca in ca
forvalues x = 2018(1)2020 {
	gen exp_share`x' = ca_exp`x'/ ca_`x'
}
egen mean_exp_share = rowmean(exp_share2018 exp_share2019 exp_share2020)
lab var mean_exp_share "part des exports en CA"

	* gen dummy for firms where ca_exp > ca
gen difca = (ca_exp_mean > ca_mean)


***********************************************************************
* 	PART 10: eligibiliy dummy
***********************************************************************

gen ca_eligible = (ca_mean > 1.5 & ca_mean < . & ca_exp_mean > 0.15 & ca_exp_mean < .)

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
/*
gen rg_telephone2 = ""
replace rg_telephone2 = "21698218074" if id_plateforme == 886
replace rg_telephone2 = "71380080" if id_plateforme == 190

		
	* email adresses
gen rg_email2 = ""
replace rg_email2 = "intissarmersni1987@gmail.com" if id_plateforme == 777
replace rg_email2 = "anoha.consulting@gmail.com" if id_plateforme == 886

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

*/


***********************************************************************
* 	Save the changes made to the data		  			
***********************************************************************
	* set export directory
cd "$regis_intermediate"

	* export file with potentially eligible companies
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
	rename firmname nom_entreprise
	rename rg_codedouane code_douane
	rename rg_matricule matricule_cnss
	order nom_entreprise date_created matricule_fiscale code_douane matricule_cnss operation_export 
	local varlist "nom_entreprise date_created matricule_fiscale code_douane matricule_cnss operation_export site_web reseaux_sociaux onshore employes produit_exportable intention_export"
	export excel `varlist' using consortia_eligibes_pme if eligible_sans_matricule == 1, firstrow(var) replace
restore

	* save dta file
save "regis_inter", replace
