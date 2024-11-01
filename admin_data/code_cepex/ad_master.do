
**********************************************************************
* 			Adminstrive master do-file 									  
***********************************************************************
*																	  
*	PURPOSE: make all data work reproducible						  
* 	for all team members & outsiders								  
*																	  
*	OUTLINE: 	PART 1: Set standard settings & install packages	  
*				PART 2: Prepare dynamic folder paths & globals		  
*				PART 3: Run endline do-files                          
*																	  
*																	  
*	Authors:  	Florian Muench & Amira Bouziri & Kaïs Jomaa & Ayoub Chamakhi 						    
*	ID variable: 	id (example: f101)			  					  
*	Requires: ad_data.dta 	  										  
***********************************************************************
* 	PART 1: 	Set standard settings & install packages			  
***********************************************************************
{
	* set standard settings
version 14.2
clear all
graph drop _all
scalar drop _all
set varabbrev off // stops stata from referring to variables if only one part is the same
set graphics on /* switch off to on to display graphs */
capture program drop zscore /* drops the program programname */
qui cap log c
set seed 8413195
set sortseed 8413195
set max_memory 16g

	* install packages
/*
	* visualisation
ssc install betterbar, replace
ssc install blindschemes, replace /* for plotplain --> scheme for graphic2al visualisations */
ssc install scheme-burd, replace

	* data transformation
ssc install winsor, replace
ssc install winsor2, replace
ssc install kdens
ssc install ihstrans

	* data analysis
ssc install ietoolkit, replace /* for iebaltab */

*/

	* define graph scheme for visual outputs
set scheme plotplain
set scheme burd
}


***********************************************************************
* 	PART 2: 	Prepare dynamic folder paths & globals			  	  *
***********************************************************************
{
* Jawhar folder paths
global root     = "C:/Users/user/Documents/rct"
global code     = "${root}/code"
global data     = "${root}/data"
global raw  		= "${data}/raw"
global intermediate = "${data}/intermediate"
global final		= "${data}/final"
global output   = "${root}/output"
global figures  = "${output}/figures"
	global fig_all  = "${figures}/all"
	global fig_ecom  = "${figures}/ecom"
	global fig_cf  = "${figures}/cf"
	global fig_aqe  = "${figures}/aqe"

global tables   = "${output}/tables"
	global tab_all   = "${tables}/all"
	global tab_ecom  = "${tables}/ecom"
	global tab_cf    = "${tables}/cf"
	global tab_aqe   = "${tables}/aqe"


* create log file
cap log close
log using "${root}logfile.log", replace 
} 




***********************************************************************
* 	PART 3: 	Run endline do-files			  	 				  *
***********************************************************************
/* --------------------------------------------------------------------
	PART 3.2: Import raw data
	Creates: rct1_rne_inter
----------------------------------------------------------------------*/		
if (1) do "${code}/ad_import_merge.do"
/* --------------------------------------------------------------------
	PART 3.3: Clean data
----------------------------------------------------------------------*/
if (1) do "${code}/ad_clean.do"
/* --------------------------------------------------------------------
	PART 3.4: Correct observations
----------------------------------------------------------------------*/
if (0) do "${code}/ad_correct.do"
/* --------------------------------------------------------------------
	PART 3.5: Generate variables
	Creates: rct_rne_final
----------------------------------------------------------------------*/
if (1) do "${code}/ad_generate.do"
/* --------------------------------------------------------------------
	PART 3.6: Identify optimal ihs-transformation
----------------------------------------------------------------------*/
if (0) do "${code}/ad_scale.do"
/* --------------------------------------------------------------------
	PART 3.7: Visualize main outcome variables
----------------------------------------------------------------------*/
if (1) do "${code}/ad_visualise.do"
/* --------------------------------------------------------------------
	PART 3.8: Regressions
----------------------------------------------------------------------*/
if (1) do "${code}/ad_regressions.do"
log close
