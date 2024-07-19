***********************************************************************
* 			master do file endline survey, Export consortias		  *					  
***********************************************************************
*																	  
*	PURPOSE: make all data work reproducible from first import to analysis
* 	for all team members & outsiders								  
*																	  
*	OUTLINE: 	PART 1: Set standard settings & install packages	  
*				PART 2: Prepare dynamic folder paths & globals		  
*				PART 3: Run all do-files                          											  
*																	  
*	Author:  	Kais Jomaa, Amira Bouziri, Eya Hanefi, Ayoub Chamakhi						    
*	ID variable: 		  					  
*	Requires:  	  										  
*	Creates:  
***********************************************************************
* 	PART 1: 	Set standard settings & install packages			  
***********************************************************************
{
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
}
***********************************************************************
* 	PART 2: 	Prepare dynamic folder paths & globals			  	  *
***********************************************************************
{
		* define user
	if "`c(username)'" == "amira.bouziri" | "`c(username)'" == "Admin" | "`c(username)'"  == "Fabian Scheifele" | "`c(username)'" == "my rog" | "`c(username)'" == "ayoub" | "`c(username)'" == "Azra" {
		global person =  "G:/.shortcut-targets-by-id/1bVknNNmRT3qZhosLmEQwPJeB-O24_QKT"
	} 
	
	else if "`c(username)'" == "fmuench" {
		global person = "C:/Users/fmuench/Documents"
	}

	else {
		global person = "G:/Meine Ablage" 
}

		* dynamic folder path for gdrive(data,output), github(code), backup(local computer)
if c(os) == "Windows" {
	global bl_gdrive = "${person}/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/2-baseline"
	global ml_gdrive = "${person}/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/3-midline"
	global el_gdrive = "${person}/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/4-endline"
	global el_github = "C:/Users/`c(username)'/Documents/GitHub/giz-pema-consortias/surveys/Endline"
	global consortia_master ="${person}/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data"
}
/* 
 if "`c(username)'" == "Admin" {
	global bl_gdrive = "G:/.shortcut-targets-by-id/12xYjmTKrUaYi6eZ6g684X6a4FfqF7Y0R/1. Intervention III – Consortia/data/2-baseline"
	global ml_gdrive = "G:/.shortcut-targets-by-id/12xYjmTKrUaYi6eZ6g684X6a4FfqF7Y0R/1. Intervention III – Consortia/data/3-midline"
	global el_gdrive = "G:/.shortcut-targets-by-id/12xYjmTKrUaYi6eZ6g684X6a4FfqF7Y0R/1. Intervention III – Consortia/data/4-endline"
	global el_github = "C:/Users/`c(username)'/Documents/GitHub/giz-pema-consortias/surveys/Endline"
	global consortia_master ="G:/.shortcut-targets-by-id/12xYjmTKrUaYi6eZ6g684X6a4FfqF7Y0R/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data"
	} 
*/
else if c(os) == "MacOSX" {
	global bl_gdrive = "/Volumes/GoogleDrive/My Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/2-baseline"
	global ml_gdrive = "/Volumes/GoogleDrive/My Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/3-midline"
	global el_gdrive = "${person}/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/4-endline"
	global el_github = "C:/Users/`c(username)'/Documents/GitHub/giz-pema-consortias/surveys/Endline"
	global consortia_master ="/Volumes/GoogleDrive/My Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/6-master"
}

		* paths within gdrive
		*baseline path
global bl_final = "${bl_gdrive}/final"
        *midline path
global ml_final = "${ml_gdrive}/final"		

			* data
global el_raw = "${el_gdrive}/raw"
global el_intermediate "${el_gdrive}/intermediate"
global el_final = "${el_gdrive}/final"
global el_checks = "${el_gdrive}/checks"
global el_output = "${el_gdrive}/output"

			* master contactlist
global master_final = "${consortia_master}/6-master/final"

			* set seeds for replication
set seed 1231234
set sortseed 1231234

}		

***********************************************************************

* 	PART 3: 	Run do-files for data cleaning & survey progress

***********************************************************************
/* --------------------------------------------------------------------
	PART 3.0: Import & raw data
	creates: el_intermediate 
	requires: el_raw.xlsx
----------------------------------------------------------------------*/		
if (1) do "${el_github}/el_import.do"
/* --------------------------------------------------------------------
	PART 3.1: Clean raw data & save as intermediate data
----------------------------------------------------------------------*/	
if (1) do "${el_github}/el_clean.do"
/* --------------------------------------------------------------------
	PART 3.2: Correct & save intermediate data
----------------------------------------------------------------------*/	
if (1) do "${el_github}/el_correct.do"
/* --------------------------------------------------------------------
	PART 3.3: Generate variables for analysis or implementation
----------------------------------------------------------------------*/	
if (1) do "${el_github}/el_generate.do"
/* --------------------------------------------------------------------
	PART 3.6: Export pdf with descriptive statistics on responses
----------------------------------------------------------------------*/	
if (1) do "${el_github}/el_statistics.do"

