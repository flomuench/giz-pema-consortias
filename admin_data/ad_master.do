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

	* set standard settings
version 14.2
clear all
graph drop _all
scalar drop _all
set varabbrev off // stops stata from referring to variables if only one part is the same
set graphics on /* switch off to on to display graphs */
capture program drop zscore /* drops the program programname */
qui cap log c

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

***********************************************************************
* 	PART 2: 	Prepare dynamic folder paths & globals			  	  *
***********************************************************************
* Folder paths
global root     = "C:/Users/user/Documents/rct1"
global code     = "${root}/code"
global data     = "${root}/data"
global raw  		= "${data}/raw"
global intermediate = "${data}/intermediate"
global final		= "${data}/final"
global output   = "${root}/output"
global figures  = "${output}/figures"
	global fig_all  		=	"${output}/all"
	global fig_aqe  		= 	"${output}/aqe"
	global fig_ecom  	= 	"${output}/ecommerce"
	global fig_cf  			= 	"${output}/cf"

global tables   = "${output}/tables"

			* set seeds for replication
set seed 8413195
set sortseed 8413195
set max_memory 16g
cap log close
log using "${root}logfile.log", replace 

***********************************************************************
* 	PART 3: 	Run endline do-files			  	 				  *
***********************************************************************
/* --------------------------------------------------------------------
	PART 3.1: Import raw data
	Creates: rct1_rne_inter
----------------------------------------------------------------------*/		
if (1) do "${code}/ad_import_merge.do"
/* --------------------------------------------------------------------
	PART 3.2: Clean data
----------------------------------------------------------------------*/
if (1) do "${code}/ad_clean.do"
/* --------------------------------------------------------------------
	PART 3.3: Correct observations
----------------------------------------------------------------------*/
if (1) do "${code}/ad_correct.do"
/* --------------------------------------------------------------------
	PART 3.4: Generate variables
----------------------------------------------------------------------*/
if (1) do "${code}/ad_generate.do"
/* --------------------------------------------------------------------
	PART 3.5: Identify optimal ihs-transformation
	Creates: rct1_rne_final
----------------------------------------------------------------------*/
if (1) do "${code}/ad_scale.do"
/* --------------------------------------------------------------------
	PART 3.6: Visualize main outcome variables
----------------------------------------------------------------------*/
if (1) do "${code}/ad_visualise.do"
/* --------------------------------------------------------------------
	PART 3.7: Regressions
----------------------------------------------------------------------*/
if (1) do "${code}/ad_regression.do"
}
log close
