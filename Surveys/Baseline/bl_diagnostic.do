***********************************************************************
* 			baseline progress, firm characteristics
***********************************************************************
*																	   
*	PURPOSE: 		Create diagnostic to be shared with all firms
*	OUTLINE:														  
*	1)				progress		  		  			
*	2)  			eligibility					 
*	3)  			characteristics							  
*																	  
*	ID variables			  					  
*	Requires: bl_final.dta 
*	Creates:  bl_final.dta			  
*																	  
***********************************************************************
* 	PART 1:  set environment		  			
***********************************************************************
	* import file
use "$bl_final/bl_final", clear

	* set directory to checks folder
cd "$bl_output"

***********************************************************************
* 	PART 2: create word document + define the title and header
***********************************************************************
	* create pdf document
putdocx clear
putdocx begin 
putdocx paragraph

	* define title and header
putdocx text ("Diagnostic de l'entreprise"), bold linebreak
putdocx text ("Date: Avril 2022"), linebreak


***********************************************************************
* 	PART 3: statistics to be included in the word file
***********************************************************************
	* pratiques de management (mngtvars)
	
	
	
	* pratiques de marketing (markvars)

	
	* management de l'export (markvars)

	
	* export readiness (markvars)

	
***********************************************************************
* 	PART 3: statistics to be included in the word file
***********************************************************************
