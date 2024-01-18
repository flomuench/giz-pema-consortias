***********************************************************************
* 			        building a map, e-commerce			   	          *					  
***********************************************************************
*																	  
*	PURPOSE: file for building a map for webscrapped firms data								  
*																	  
*	OUTLINE: 	PART 1: Install packages		  
*				PART 2: Prepare the data	  
*				PART 3: Draw Map                     											  
*																	  
*	Author:  						    
*	ID variable: 		  					  
*	Requires:  	  										  
*	Creates:  
***********************************************************************
* 	PART 1: 	Install package			  
***********************************************************************
	* install map package
/*
ssc install spmap, replace

ssc install geo2xy, replace     

ssc install palettes, replace        

ssc install colrspace, replace

ssc install schemepack, replace


*/

set scheme white_tableau
***********************************************************************
* 	PART 2: 	Prepare the data
************************************************************************
*import excel lat & long
import excel "${map}/consortia_adresse_modified_postlocation", firstrow clear

*destring longitude & latitude
destring latitude, generate(new_latitude) 
destring longitude, generate(new_longitude)

*save .dta
save "${map}/coordinates", replace
clear

*chose directory
cd "${map}"

*transform shape data to .dta
spshape2dta TN_governorates, replace saving(tunisia)

*use
use "${map}/tunisia", replace

***********************************************************************
* 	PART 3: 	Draw Map
***********************************************************************
*draw the map
spmap using tunisia_shp, id(_ID) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red) size(1.5) ocolor(white) osize(*0.5))
graph export map_consortia.png, replace