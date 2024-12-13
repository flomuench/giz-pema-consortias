***********************************************************************
* 			Administrative data Import									  		  
***********************************************************************
*																	  
*	PURPOSE:  Import the adminstrative data provided by Cepex
*																	  
*																	  
*	OUTLINE:														  
*	1)	Import Cepex data and list of firms from all programmes 
*	2)	Make corrections to prepare mergers
*	3)  Merge and save  file      					  
*	4)  Save  file      					  
*																	  									  			
*
*	Authors:  	Florian Muench & Teo Firpo
*	ID variable: 	id (example: f101)			  					  
*	Requires: BI-STAT-GIZ-Octobre2024.xlsx  
				/// BI-STATOctobre2024.xlsx 
				/// Entreprises (1).xlsx
*	Creates: cepex_raw.dta 															  

***********************************************************************
* 	PART 1: 	Import Cepex data and list of firms from all programmes 
***********************************************************************

	* import Cepex data (without product breakdown)
import excel "${data}/BI-STAT-GIZ-Octobre2024.xlsx", firstrow clear
	
	* drop useless vars
	
drop Libelle_Pays Libelle_NDP

gen ndgcf = substr(CODEDOUANE, 1, strlen(CODEDOUANE) - 1)

	* rename variables so there is not clash with the other dataset 
	
forvalues i = 2020(1)2024 {
	rename SumVALEUR_`i' total_revenue_`i'
	rename Sum_Qte_`i' total_qty_`i'
	
	lab var total_revenue_`i' "Total revenue in `i'"
	lab var total_qty_`i' "Total quantity of exports in `i'"
}
 
drop if ndgcf==""

save "${data}/temp_cepex1.dta", replace

	
	* import Cepex data (with product breakdown)
	
import excel "${data}/BI-STAT-GIZ-2-Octobre2024.xlsx", firstrow clear
	
	* a few observations are encoded wrong, drop them
	
drop if O!=.

drop O P Q R

gen ndgcf = substr(CODEDOUANE, 1, strlen(CODEDOUANE) - 1)

save "${data}/temp_cepex2.dta", replace

	* reshape & collapse to create a panel version of the data
reshape long SumVALEUR_ Sum_QTE_, i(CODEDOUANE) j(year)


	* now load file linking Cepex id to programs' ids
	
import excel "${data}/Entreprises (1).xlsx", firstrow clear

	* make sure only real observations
encode id_plateforme, gen(id)	
sum id
keep in 1/`r(N)'
order id, first
sort id, stable
 

***********************************************************************
* 	PART 2:  make corrections to prepare merger  					  
***********************************************************************
{	
	* FROM OTHER FILE DELETE AFTER 
	* make manual corrections
		* AQE
		
replace matricule_fiscale = "0982278R" if id_plateforme == "f151"  // 0 added 
replace matricule_fiscale = "0047723H" if id_plateforme == "f157"  // 0 added 
		* CF
replace matricule_fiscale = "0036107D" if id_plateforme == "1094"  // 0 removed
replace matricule_fiscale = "0506696A" if id_plateforme == "1124"  // A added as placeholder
replace matricule_fiscale = "1661975A" if id_plateforme == "1182"  // A added as placeholder
replace matricule_fiscale = "3736633A" if id_plateforme == "1185"  // A added as placeholder
replace matricule_fiscale = "0448873K" if id_plateforme == "1190"  // 0 added 
replace matricule_fiscale = "0584547S" if id_plateforme == "1193"  // 0 added
replace matricule_fiscale = "0240688H" if id_plateforme == "1197"  // 0 added, H to end
replace matricule_fiscale = "1733053A" if id_plateforme == "1233"  // A added as placeholder
		* Ecommerce
replace matricule_fiscale = "1554011A" if id_plateforme == "381"  // A added as placeholder
replace matricule_fiscale = "0615241H" if id_plateforme == "679"  // 0 added
replace matricule_fiscale = "0655112G" if id_plateforme == "841"  // 0 added
replace matricule_fiscale = "1066365A" if id_plateforme == "508"  // A added as placeholder

	* rename fiscal identifier for consistency with Cepex
gen mf_len = strlen(matricule_fiscale)
br if mf_len != 8
		* potentially correct mf here manually
gen ndgcf = substr(matricule_fiscale, 1, strlen(matricule_fiscale) - 1)

	* drop cases w/o matricule fiscale
drop if ndgcf == "" // 4 obs, all from AQE f127, f142, f266, f283
}
	
***********************************************************************
* 	PART 3:  check and adjust for duplicates & firms that are in all three programs  					  
***********************************************************************
{
	* check duplicates
duplicates report matricule_fiscale
/*
Duplicates in terms of matricule_fiscale

--------------------------------------
   copies | observations       surplus
----------+---------------------------
        1 |          511             0
        2 |           96            48 /// firms that were in all 2 programs
        3 |           15            10 /// firms that were in all 3 programs
--------------------------------------

*/

duplicates tag matricule_fiscale, gen(dup)

gen program_num = .
	replace program_num = 1 if dup == 0
	replace program_num = 2 if dup == 1
	replace program_num = 3 if dup == 2
lab var program_num "programs per firm"

	* corrections
		* drop firms with double registration
drop if matricule_fiscale == "0009951F" & firmname == "SCAPCB"
drop if matricule_fiscale == "1270897M" & id_plateforme == "f176"
drop if matricule_fiscale == "1548345W" & id_plateforme == "f306"
drop if matricule_fiscale == "0976398L" & id_plateforme == "f164"


	* create program dummies to have one row per company
codebook ndgcf
* unique values:  564                      missing "":  0/618
* 564 unique firms, with some participating
encode programme, gen(program)
drop programme exporter
rename strata_final strata
reshape wide id id_plateforme firmname matricule_fiscale treatment take_up strata program_num, i(ndgcf) j(program)
/* Result: 
Data                               long   ->   wide
-----------------------------------------------------------------------------
Number of obs.                      618   ->     564
Number of variables                  13   ->      28
j variable (3 values)           program   ->   (dropped)
xij variables:
                                     id   ->   id1 id2 id3
                          id_plateforme   ->   id_plateforme1 id_plateforme2 id_plateforme3
                               firmname   ->   firmname1 firmname2 firmname3
                      matricule_fiscale   ->   matricule_fiscale1 matricule_fiscale2 matricule_fiscale3
                              treatment   ->   treatment1 treatment2 treatment3
                                take_up   ->   take_up1 take_up2 take_up3
                                 strata   ->   strata1 strata2 strata3
                            program_num   ->   program_num1 program_num2 program_num3
-----------------------------------------------------------------------------

. 

*/	
order id? id_plateforme? matricule_fiscale? firmname? treatment? take_up? strata? program_num?

	* create a program dummy
forvalues x = 1(1)3 {
gen program`x' = .
	replace program`x' = 1 if treatment`x' != .
	replace program`x' = 0 if treatment`x' == .
		}
lab var program1 "AQE"
lab var program2 "CF"
lab var program3 "Ecommerce"

egen program4 = rowmax(program1 program2 program3)
order program4, a(program3)


		
}

***********************************************************************
* 	PART 3:  merge rct firms to Cepex universe of firms  					  
***********************************************************************
{
	* merge RCT sample with Cepex firm population
sort ndgcf, stable
merge 1:m ndgcf using "${data}/temp_cepex1.dta" 
codebook ndgcf if _merge == 3
/* 
unique values:  306                      missing "":  0/306
result merge:
    Result                           # of obs.
    -----------------------------------------
    not matched                           258
        from master                       258  (_merge==1)
        from using                          0  (_merge==2)

    matched                               306  (_merge==3)
    -----------------------------------------

*/

rename _merge match

	* now merge with Cepex firm data with totals

sort ndgcf, stable
merge 1:m ndgcf using "${data}/temp_cepex2.dta" 
codebook ndgcf if _merge == 3

/*
result merge: 
    Result                           # of obs.
    -----------------------------------------
    not matched                           258
        from master                       258  (_merge==1)
        from using                          0  (_merge==2)

    matched                             5,324  (_merge==3)
    -----------------------------------------

	unique values:  306                      missing "":  0/5,324
*/

drop match


/*FROM OTHER FILE DELETE AFTER 

BALANCE - PRE TREATMENT BALANCE TABLE 2020 compare treatment vs control for the whole sampple and then each program

	* gen dummy for RCT firms vs. rest of firm population
gen sample = (_merge == 3)
lab var sample "sample vs. rest of firm population"

local balancevar "MoyenneS Masse_Salariale ExportV ExportP ImportV ImportP CA_TTC_DT CA_Local_DT CA_Export_DT"
iebaltab `balancevar' if annee == 2020, ///
    grpvar(sample) vce(robust) format(%12.2fc) replace ///
    ftest rowvarlabels ///
    savetex("${tab_all}/baltab_admin_population")

local balancevar "MoyenneS Masse_Salariale ExportV ExportP ImportV ImportP CA_TTC_DT CA_Local_DT CA_Export_DT"	
iebaltab `balancevar' if annee == 2020, ///
    grpvar(sample) vce(robust) format(%12.2fc) replace ///
    ftest rowvarlabels ///
    savexlsx("${tab_all}/baltab_admin_population")

local programs "aqe cf ecom"
forvalues x = 1(1)3 {
gettoken p programs : programs
preserve 
keep if sample == 0 | program`x' == 1  
local balancevar "MoyenneS Masse_Salariale ExportV ExportP ImportV ImportP CA_TTC_DT CA_Local_DT CA_Export_DT"
iebaltab `balancevar' if annee == 2020, ///
    grpvar(sample) vce(robust) format(%12.2fc) replace ///
    ftest rowvarlabels ///
    savetex("${tab_`p'}/baltab_admin_population")

local balancevar "MoyenneS Masse_Salariale ExportV ExportP ImportV ImportP CA_TTC_DT CA_Local_DT CA_Export_DT"	
iebaltab `balancevar' if annee == 2020, ///
    grpvar(sample) vce(robust) format(%12.2fc) replace ///
    ftest rowvarlabels ///
    savexlsx("${tab_`p'}/baltab_admin_population")
restore
}*/	
	
}


***********************************************************************
* 	PART 3: 	save merged file
***********************************************************************

save "${data}/cepex_raw.dta", replace

erase "${data}/temp_cepex1.dta"

erase "${data}/temp_cepex2.dta"
