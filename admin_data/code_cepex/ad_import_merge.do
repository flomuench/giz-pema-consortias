***********************************************************************
* 			Administrative data Import									  		  
***********************************************************************
*																	  
*	PURPOSE:  Import the adminstrative data provided by the INS
*																	  
*																	  
*	OUTLINE:														  
*	1)	import list of firms and variables needed for analysis
*	2)	merge rct firms to RNE universe of firms
*	3)  save merged file      					  
*																	  									  			
*
*	Authors:  	Florian Muench & Amira Bouziri & Kaïs Jomaa & Ayoub Chamakhi 
*	ID variable: 	id (example: f101)			  					  
*	Requires: ins_adminstrative_data.xlsx  
*	Creates: ins_adminstrative_data.dta 															  
***********************************************************************
* 	PART 0: 	import RNE & select latest year to speed up processing
***********************************************************************
/* only execute during first run
use "${raw}/dw2023v", clear

drop if annee < 2018 // speeds up operations

save "${raw}/rne_2018_2023", replace 
*/
***********************************************************************
* 	PART 1: 	import list of firms and variables needed for analysis
***********************************************************************
	* old file 
*use "${raw}/list_RCT.dta", clear

	* new file
import excel "${raw}/Entreprises.xlsx", firstrow clear


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
	* make manual corrections
		* AQE
replace matricule_fiscale = "0966564M" if id_plateforme == "f142"  // Jawhar resarched 
replace matricule_fiscale = "1092914B"  if id_plateforme == "f266" // Jawhar resarched
replace matricule_fiscale = "0941121M" if id_plateforme == "f283"  // Jawhar resarched

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
replace matricule_fiscale = "0931877D" if id_plateforme == "129"  // 0 added
replace matricule_fiscale = "1066365A" if id_plateforme == "508"  // A added as placeholder



	* rename fiscal identifier for consistency with RNE
gen mf_len = strlen(matricule_fiscale)
br if mf_len != 8
		* potentially correct mf here manually
gen ndgcf = substr(matricule_fiscale, 1, strlen(matricule_fiscale) - 1)

	* drop cases w/o matricule fiscale
drop if ndgcf == "" // 1 obs, f127 AQE
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
        1 |          514             0
        2 |           96            48 /// fir,s that were in all 2 programs
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
* unique values:  567                      missing "":  0/622
* 567 unique firms, with some participating
encode programme, gen(program)
drop exporter programme
rename strata_final strata
reshape wide id id_plateforme firmname matricule_fiscale treatment take_up strata program_num, i(ndgcf) j(program)
/* Result: 
Data                               long   ->   wide
-----------------------------------------------------------------------------
Number of obs.                      621   ->     567 
Number of variables                  12   ->      27
j variable (3 values)           program   ->   (dropped)
xij variables:
                                     id   ->   id1 id2 id3
                          id_plateforme   ->   id_plateforme1 id_plateforme2 id_plateforme3
                               firmname   ->   firmname1 firmname2 firmname3
                      matricule_fiscale   ->   matricule_fiscale1 matricule_fiscale2 matricule_fiscale3
                              treatment   ->   treatment1 treatment2 treatment3
                                take_up   ->   take_up1 take_up2 take_up3
                           strata_final   ->   strata_final1 strata_final2 strata_final3
                            program_num   ->   program_num1 program_num2 program_num3
-----------------------------------------------------------------------------
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
* 	PART 3:  merge rct firms to RNE universe of firms  					  
***********************************************************************
{
	* merge RCT sample with RNE firm population
sort ndgcf, stable
merge 1:m ndgcf using "${raw}/rne_2018_2023" // dw2023v for full RNE
codebook ndgcf if _merge == 3

/* 
result merge:
AQE only (full RNE):
    Result                           # of obs.
    -----------------------------------------
    not matched                    16,654,910
        from master                         0  (_merge==1)
        from using                 16,654,910  (_merge==2)

    matched                             3,850  (_merge==3)
    -----------------------------------------
result codebook
unique values:  210                      missing "":  0/3,850

All 3 RCTs (RNE 2018-2022, 2023 version)
. merge 1:m ndgcf using "${raw}/rne_2018_2023" // dw2023v for full RNE

    Result                           # of obs.
    -----------------------------------------
    not matched                     4,295,154
        from master                         6  (_merge==1)
        from using                  4,295,148  (_merge==2)

    matched                             2,662  (_merge==3)
    -----------------------------------------	
*/

	* drop unmatched RCT firms
drop if _merge == 1

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
}	
	
	* drop all the firms in the RNE that are not part of the RCT sample
drop if _merge == 2
}


***********************************************************************
* 	PART 3: 	save merged file
***********************************************************************
save "${raw}/rct_rne_raw", replace

