***********************************************************************
* 			Administrative data import
***********************************************************************
*																	  
*	PURPOSE:  Import the adminstrative data provided by Cepex	  *																	  
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
use "${raw}/enterprises.dta", clear

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
sort program, stable
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
* 	PART 4:  merge rct firms to Cepex universe of firms  					  
***********************************************************************

	* merge RCT sample with Cepex firm population
sort ndgcf, stable
merge 1:m ndgcf using "${intermediate}/cepex_inter.dta" 
codebook ndgcf if _merge == 3

/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                           258
        from master                       258  (_merge==1)
        from using                          0  (_merge==2)

    Matched                             1,530  (_merge==3)
    -----------------------------------------
*/


	* order
order ID ndgcf id? year _merge value quantity, first
sort  ndgcf year, stable

save "${intermediate}/cepex_panel_raw", replace // before cepex_long



***********************************************************************
* 	PART archive: 	archived code
***********************************************************************
/*

{
	* merge RCT sample with Cepex firm population
sort ndgcf, stable
merge 1:m ndgcf using "${raw}/temp_cepex1.dta" 
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

gen matched = .
	replace matched = 1 if match == 3
	replace matched = 0 if match == 1

	* now merge with Cepex firm data with totals

sort ndgcf, stable
merge 1:m ndgcf using "${raw}/temp_cepex2.dta" 
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

drop match _merge
	
}
