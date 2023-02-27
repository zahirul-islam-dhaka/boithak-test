********************************************************************************
** 	TITLE: 		Data preparation.do
**
**	PROJECT:	Moogdho Bhai, DHS data 
**
**	PURPOSE:	Prepare data for Map preparation
**
**	AUTHOR:		Zahirul Islam
**
**	CONTACT: 	zahirul.
**
**	CREATED: 	29 October 2022
**
**		  	 __  __  ___ __     _____          __    ___ __      
**	 	 /\ |__)/  `|__ |  \   |__/  \|  ||\ ||  \ /\ ||/  \|\ | 
**		/~~\|  \\__,|___|__/   |  \__/\__/| \||__//~~\||\__/| \|  
** 	   www.arced.foundation;  https://github.com/ARCED-Foundation 
**					                                                           	
********************************************************************************


**# Table of Content
*------------------------------------------------------------------------------*

*	All of the chapter heading of this do file has used bookmark which is ///
*	readable by Stata 17. If you are not a Stata 17 user, please search for ///
*	(**#) to identify the chapter headings.

********************************************************************************


**# setup Stata
*------------------------------------------------------------------------------*
	
	cls
	clear 			all
	macro drop 		_all
	version 		17
	set min_memory 	1g 
	set maxvar 		32767
	set more 		off
	discard 
	set seed 		87235
	set sortseed 	98237
	set niceness 	1
	set traced 		1
	pause 			on


**# Global Path
*------------------------------------------------------------------------------*
		
	* Setup working directory
	*------------------------
		if "$cwd" ~= "" cd "$cwd"
		else global cwd "`c(pwd)'"
		sysdir set PLUS "../01_Ado/"
    

	* Baseline Data Folder
	*---------------------
		gl rawspath			"${cwd}/../../03_Data/03_Raw"
		gl cleanpath		"${cwd}/../../03_Data/06_Clean"
		
	* Install user programs
	*----------------------
		cap which geoinpoly
		if _rc ssc install geoinpoly
		
		cap which shp2dta
		if _rc ssc install shp2dta
		
		cap which geojson
		if _rc net install geotools, from(http://www.radyakin.org/stata/geotools/beta)
		
		cap which glevelsof
		if _rc ssc install gtools
		
**# Convert shape file
*------------------------------------------------------------------------------*
	cap confirm file "${rawspath}/union_data.dta"
	
	if _rc {
		shp2dta using 	"${rawspath}/bgd_adm_bbs_20201113_shp/bgd_adm_bbs_20201113_SHP/bgd_admbnda_adm4_bbs_20201113.shp", ///
						data("${rawspath}/union_data")  ///
						coor("${rawspath}/union_coor") 
	}
	

	
**# Find upazila name
*------------------------------------------------------------------------------*
	import excel using "${rawspath}/2022_kiln_deaths_edited.xlsx", first clear 
	
	geoinpoly Latitude Longitude using "${rawspath}/union_coor.dta"
	
	merge m:1 _ID using 	"${rawspath}/union_data", ///
							keep(master match) nogen ///
							keepusing(ADM3_EN ADM4_EN)
							
	lab var ADM3_EN "Upazila"	
	lab var ADM4_EN "Union"
	export excel using "${cleanpath}/2022_kiln_deaths_edited.xlsx", ///
						firstrow(varl) replace		
	
	
**# Produce grey area geojson
*------------------------------------------------------------------------------*
	
	/*-------------------------------------------------
	
			This method does not work right.
			So, instead we will just add a filter
			in the shape file dbf and work on mapbox
			directly.
			
	----------------------------------------------------
	
	
	u "${rawspath}/upazila_coor", clear
	// drop if mi(_X)
	
	g geo  = string(_X) + "," + string(_Y)
	drop _X _Y
	
	g allgeo = ""

	glevelsof _ID, loc(IDS) clean 
	foreach id of loc IDS {
		qui glevelsof geo if _ID==`id', clean loc(`id'_geo) separate(";")
		qui replace allgeo = "``id'_geo'" if _ID == `id' 
		di "`id' " _cont
	}
	
	gduplicates drop _ID, force
	
	merge m:1 _ID using "${rawspath}/upazila_data"
	drop geo
	
	// shapefile save allgeo using "${rawspath}/upazila_data", type(polygon)
	geojson save allgeo using "${rawspath}/upazila_data.geojson", features("Polygon")
	
	
	---------------------------------------------------------------------------*/
	xx
	import excel using "${rawspath}/upazila_treat_assignment.xls", clear first
	
	tempfile treat 
	save 	`treat'
	
	import dbase using "${rawspath}/Upazila/bgd_admbnda_adm3_bbs_20201113.dbf", clear
	
	merge 1:1 ADM3_PCODE using `treat', nogen update replace keepusing(exclude treat)
	recode exclude (miss=1)
	
	export dbase using "${rawspath}/Upazila/bgd_admbnda_adm3_bbs_20201113.dbf", replace
	
python:

tilesets create mehrabali.upazila --recipe H:/.shortcut-targets-by-id/1M-ACuCF9PzC3Ks8mC92-k7PxHQrJucbv/R&D_2022/Brick_Kiln_Dashboard_NUS_2022/02_Resources/02_Program/02_Codes/basic-recipe.json --name "upazila"
end

! curl "https://api.mapbox.com/tilesets/v1/mehrabali?access_token=sk.eyJ1IjoibWVocmFiYWxpIiwiYSI6ImNsYXFtamdxNzAyamczcG8zNHg4cHg3ZTcifQ.fedfU3HuXSo8b8nQMIIBUA"