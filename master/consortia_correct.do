***********************************************************************
* 			consortia master do files: correct 
***********************************************************************
*																	  
*	PURPOSE: correct values in merged data			  
*																	  
*	OUTLINE: 	PART I: PII data
*					PART 1: clean regis_final	  
*
*				PART II: Analysis data
*					PART 3: 
*																	  
*	Author:  	Fabian Scheifele & Siwar Hakim							    
*	ID variable: id_email		  					  
*	Requires:  	 regis_final.dta bl_final.dta 										  
*	Creates:     regis_final.dta bl_final.dta
***********************************************************************
********************* 	I: PII data ***********************************
***********************************************************************	
***********************************************************************
* 	PART 1:    correct leading & trailing spaces	  
***********************************************************************
use "${master_gdrive}/contact_info_master", clear

*remove leading and trailing white space
{
ds, has(type string) 
local strvars "`r(varlist)'"
foreach x of local strvars {
replace `x' = stritrim(strtrim(`x'))
}
}

***********************************************************************
* 	PART 2:   	update matricule fiscale based on national registry
***********************************************************************
replace nom_rep="Nesrine dhahri" if id_plateforme==1040
replace firmname="zone art najet omri" if id_plateforme==1133
replace nom_rep="najet omri" if id_plateforme==1133
replace firmname="flav'or" if id_plateforme==1150
replace firmname="Al chatti Agro" if id_plateforme== 1041
drop NOM_ENTREPRISE nom_entr2 ident_base_respondent ident_nouveau_personne ident_base_respondent2 ident_respondent_position

replace matricule_fiscale = upper(matricule_fiscale)
export excel id_plateforme firmname date_created matricule_fiscale nom_rep rg_adresse codepostal site_web ///
using "${master_gdrive}/matricule_consortium", firstrow(var) sheetreplace

*dummies whether matricule is correct or where it is a matricule of a physical person rather than company
gen matricule_fisc_incorrect=0
gen matricule_physique=0

replace matricule_physique = 1 if id_plateforme == 983
replace matricule_physique = 1 if id_plateforme == 986
replace matricule_physique = 1 if id_plateforme == 989
replace matricule_physique = 1 if id_plateforme == 990
replace matricule_physique = 1 if id_plateforme == 1004
replace matricule_physique = 1 if id_plateforme == 1005
replace matricule_physique = 1 if id_plateforme == 1015
replace matricule_physique = 1 if id_plateforme == 1020
replace matricule_physique = 1 if id_plateforme == 1030
replace matricule_physique = 1 if id_plateforme == 1031
replace matricule_physique = 1 if id_plateforme == 1043
replace matricule_physique = 1 if id_plateforme == 1054
replace matricule_physique = 1 if id_plateforme == 1074
replace matricule_physique = 1 if id_plateforme == 1107
replace matricule_physique = 1 if id_plateforme == 1122
replace matricule_physique = 1 if id_plateforme == 1123
replace matricule_physique = 1 if id_plateforme == 1126
replace matricule_physique = 1 if id_plateforme == 1133
replace matricule_physique = 1 if id_plateforme == 1135
replace matricule_physique = 1 if id_plateforme == 1140
replace matricule_physique = 1 if id_plateforme == 1143
replace matricule_physique = 1 if id_plateforme == 1155
replace matricule_physique = 1 if id_plateforme == 1162
replace matricule_physique = 1 if id_plateforme == 1192
replace matricule_physique = 1 if id_plateforme == 1196
replace matricule_physique = 1 if id_plateforme == 1199
replace matricule_physique = 1 if id_plateforme == 1201
replace matricule_physique = 1 if id_plateforme == 1210
replace matricule_physique = 1 if id_plateforme == 1201
replace matricule_physique = 1 if id_plateforme == 1210
replace matricule_physique = 1 if id_plateforme == 1201
replace matricule_physique = 1 if id_plateforme == 1210
replace matricule_physique = 1 if id_plateforme == 1222
replace matricule_physique = 1 if id_plateforme == 1230
replace matricule_physique = 1 if id_plateforme == 1231
replace matricule_physique = 1 if id_plateforme == 1159
replace matricule_physique = 1 if id_plateforme == 997
replace matricule_physique = 1 if id_plateforme == 1134
replace matricule_physique = 1 if id_plateforme == 1169
replace matricule_physique = 1 if id_plateforme == 1248

replace matricule_fisc_incorrect=1 if id_plateforme == 1013
replace matricule_fisc_incorrect=1 if id_plateforme == 1081
replace matricule_fisc_incorrect=1 if id_plateforme == 1083
replace matricule_fisc_incorrect=1 if id_plateforme == 1094
replace matricule_fisc_incorrect=1 if id_plateforme == 1095
replace matricule_fisc_incorrect=1 if id_plateforme == 1128
replace matricule_fisc_incorrect=1 if id_plateforme == 1146
replace matricule_fisc_incorrect=1 if id_plateforme == 1150
replace matricule_fisc_incorrect=1 if id_plateforme == 1182
replace matricule_fisc_incorrect=1 if id_plateforme == 1185
replace matricule_fisc_incorrect=1 if id_plateforme == 1190
replace matricule_fisc_incorrect=1 if id_plateforme == 1191
replace matricule_fisc_incorrect=1 if id_plateforme == 1193
replace matricule_fisc_incorrect=1 if id_plateforme == 1197
replace matricule_fisc_incorrect=1 if id_plateforme == 1205
replace matricule_fisc_incorrect=1 if id_plateforme == 1214
replace matricule_fisc_incorrect=1 if id_plateforme == 1245


*now replace these two variables for the firms where the ID is not findable on registre-entreprise.tn 
*or physical
replace matricule_fiscale = "0601414N" if id_plateforme == 1033
replace matricule_fiscale = "0334058Y" if id_plateforme == 1092
replace matricule_fiscale = "1680517R" if id_plateforme == 1110
replace matricule_fiscale = "1479684C" if id_plateforme == 1136
replace matricule_fiscale = "0002171D" if id_plateforme == 1137
replace matricule_fiscale = "1585453H" if id_plateforme == 1108
replace matricule_fiscale = "1175102E" if id_plateforme == 1153
replace matricule_fiscale = "1140685D" if id_plateforme == 1161
replace matricule_fiscale = "0448240Y" if id_plateforme == 1159
replace matricule_fiscale = "1225272C" if id_plateforme == 994
replace matricule_fiscale = "1677629Z" if id_plateforme == 997
replace matricule_fiscale = "1721782L" if id_plateforme == 1036
replace matricule_fiscale = "1219150E?" if id_plateforme == 1095
replace matricule_fiscale = "1463126T" if id_plateforme == 1134
replace matricule_fiscale = "1748667A" if id_plateforme == 1191
replace matricule_fiscale = "1179494D?" if id_plateforme == 1205
replace matricule_fiscale = "0111519V" if id_plateforme == 1248



*change also firmname or representatives name if difference found in registry
replace firmname = "el maarifaa ennasr" if id_plateforme == 1033
replace firmname = "zayta" if id_plateforme == 994
replace firmname = "STE AMIRI DE HUILE D'OLIVE KAIROUAN" if id_plateforme == 1036
replace firmname = "decopalm" if id_plateforme == 1128
replace firmname = "bio valley" if id_plateforme == 1191


replace nom_rep = "Fathiya bin Abdul Mawla" if id_plateforme == 1159

replace rg_adresse = "boutique numero 11 Village artisanal Castila 2200 Tozeur" ///
if id_plateforme == 1128

gen mothercompany= ""
replace mothercompany ="Cloudvisualart" if id_plateforme == 1057
gen comment =""
replace comment = "Matricule fiscale is from Ziyad ben Abbas" if id_plateforme==1169

export excel id_plateforme matricule_fiscale firmname matricule_fisc_incorrect ///
using  "${master_gdrive}/matricule_consortium_cepex", sheetreplace firstrow(var)
save "${master_gdrive}/contact_info_master", replace


***********************************************************************
********************* 	II: Analysis data *****************************
***********************************************************************	


***********************************************************************
* 	PART final save:    save as intermediate consortium_database
***********************************************************************
save "${master_intermediate}/consortium_int", replace