***********************************************************************
* 			master do file midline survey, Export consortias		  *					  
***********************************************************************
*																	  
*	PURPOSE: make all data work reproducible from first import to analysis
* 	for all team members & outsiders								  
*																	  
*	OUTLINE: 	PART 1: Set standard settings & install packages	  
*				PART 2: Prepare dynamic folder paths & globals		  
*				PART 3: Run all do-files                          											  
*																	  
*	Author:  	Ayoub Chamakhi, Kais Jomaa, Amina Bousnina							    
*	ID variable: 		  					  
*	Requires:  	  										  
*	Creates:  
***********************************************************************
* 	PART 1: 	Set standard settings & install packages			  
***********************************************************************

	* set standard settings
version 15
clear all
graph drop _all
scalar drop _all
set more off
set varabbrev off // stops stata from referring to variables if only one part is the same
set graphics on /* switch off to on to display graphs */
capture program drop zscore /* drops the program programname */
qui cap log c

	* install packages
/*
ssc install ietoolkit, replace /* for iebaltab */
ssc install randtreat, replace /* for randtreat --> random allocation */
ssc install blindschemes, replace /* for plotplain --> scheme for graphic2al visualisations */
net install http://www.stata.com/users/kcrow/tab2docx
ssc install betterbar, replace
ssc install mdesc , replace
ssc install reclink, replace
ssc install matchit, replace
ssc install strgroup, replace
ssc install stripplot, replace
net install http://www.stata.com/users/kcrow/tab2docx
ssc install labutil, replace
ssc install asdoc, replace
ssc install psmatch2, replace
ssc install winsor, replace
ssc install missingplot, replace

net from https://www.sealedenvelope.com/
net install time.pkg
*/
	* define graph scheme for visual outputs
set scheme plotplain

***********************************************************************
* 	PART 2: 	Prepare dynamic folder paths & globals			  	  *
***********************************************************************
		* define user
	if "`c(username)'" == "amira.bouziri" | "`c(username)'" == "SIWAR" | "`c(username)'"  == "Fabian Scheifele" | "`c(username)'" == "my rog" | "`c(username)'" == "Amina" | "`c(username)'" == "ayoub" | "`c(username)'" == "Azra" {
	global person =  "G:/.shortcut-targets-by-id/1bVknNNmRT3qZhosLmEQwPJeB-O24_QKT"
	} 
	
	else {
	global person = "G:/Meine Ablage" 
}
		* dynamic folder path for gdrive(data,output), github(code), backup(local computer)
if c(os) == "Windows" {
	global bl_gdrive = "${person}/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/2-baseline"
	global ml_gdrive = "${person}/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/3-midline"
	global ml_github = "C:/Users/`c(username)'/Documents/GitHub/giz-pema-consortias/surveys/Midline"
	global consortia_master ="${person}/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data"
}
else if c(os) == "MacOSX" {
	global bl_gdrive = "/Volumes/GoogleDrive/My Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/2-baseline"
	global ml_gdrive = "/Volumes/GoogleDrive/My Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/3-midline"
	global ml_github = "/Users/`c(username)'/Documents/GitHub/giz-pema-consortias/surveys/Midline"
	global consortia_master ="/Volumes/GoogleDrive/My Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/6-master"
}

		* paths within gdrive
		*baseline path
global bl_final = "${bl_gdrive}/final"

			* data
global ml_raw = "${ml_gdrive}/raw"
global ml_intermediate "${ml_gdrive}/intermediate"
global ml_final = "${ml_gdrive}/final"
global ml_checks = "${ml_gdrive}/checks"
global ml_output = "${ml_gdrive}/output"


			* set seeds for replication
set seed 1231234
set sortseed 1231234
		

***********************************************************************

* 	PART 3: 	Run do-files for data cleaning & survey progress

***********************************************************************
/* --------------------------------------------------------------------
	PART 3.0: Import & raw data
	creates: ml_intermediate 
	requires: ml_raw.xlsx
----------------------------------------------------------------------*/		
if (1) do "${ml_github}/ml_import.do"
/* --------------------------------------------------------------------
	PART 3.1: Clean raw data & save as intermediate data
----------------------------------------------------------------------*/	
if (1) do "${ml_github}/ml_clean.do"
/* --------------------------------------------------------------------
	PART 3.2: Correct & save intermediate data
----------------------------------------------------------------------*/	
if (1) do "${ml_github}/ml_correct.do"
/* --------------------------------------------------------------------
	PART 3.3: Generate variables for analysis or implementation
----------------------------------------------------------------------*/	
if (1) do "${ml_github}/ml_generate.do"
/* --------------------------------------------------------------------
	PART 3.6: Export pdf with descriptive statistics on responses
----------------------------------------------------------------------*/	
if (1) do "${ml_github}/ml_statistics.do"

