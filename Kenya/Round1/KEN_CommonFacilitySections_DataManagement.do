clear
clear matrix
clear mata
capture log close
set more off
numlabel, add

*Kenya implemended both facility modules
*There are both 
*	(1) overlapping contents (vaccine readiness and PPE availability) and 
*	(2) overlapping sample design (Level 4)

*This code is kenya specific and: 
*1) merges data from two modules (CHES & Hospital case management)
*2) calculates indicator estimates for overlapping contents using merged data
*3) creates indicator estimate data for dashboards and chartbook - using pooled data.  

*  DATA IN:	cleaned facility-level data
*  DATA OUT to chartbook: 
*		1. summary estimates of indicators in Chartbook and, for dashboards, as a datafile 	

/* TABLE OF CONTENTS*/

* A. SETTING <<<<<<<<<<========== MUST BE ADAPTED: 1. directories and local
* B. Merge
* C. Create and export indicator estimate data 
*****F.1. Calculate estimates 
*****F.2. Export indicator estimate data to chart book 

**************************************************************
* A. SETTING 
**************************************************************

*** Directory for the country 
*cd "C:\Users\Yoonjoung Choi\World Health Organization\BANICA, Sorin - HSA unit\3 Country implementation & learning\1 HFAs for COVID-19\Kenya"
cd "C:\Users\ctaylor\OneDrive - World Health Organization\HSA unit\3 Country implementation & learning\1 HFAs for COVID-19\Kenya"
dir

*** Define a directory for the chartbook, if different from the main directory 
global chartbookdir "C:\Users\ctaylor\OneDrive - World Health Organization\HSA unit\3 Country implementation & learning\1 HFAs for COVID-19\Kenya\Tools\CommonFacilitySections"
*global chartbookdir "C:\Users\YoonJoung Choi\World Health Organization\BANICA, Sorin - HSA unit\3 Country implementation & learning\1 HFAs for COVID-19\Kenya\CEHS"


*** Define local macro for the survey 
local country	 		 Kenya /*country name*/	
local round 			 1 /*round*/			

*** local macro for analysis: no change needed  
local today=c(current_date)
local c_today= "`today'"
global date=subinstr("`c_today'", " ", "",.)

**************************************************************
* B. MERGE  
**************************************************************
	
use "Tools/CEHS/CEHS_`country'_R`round'.dta", clear
		gen xresult = q1104==1
		gen module_CEHS = 1
		
		/*
		tab zlevel xresult, m
		list facilitycode z* q1104 if xresult!=1
		*/
	keep country round month year facilitycode z* xppe* xvac* xresult weight module_*
	drop xvaccine* xppedispose xvac_score xvac_100 xvac_50 zlevel_* zlevel4 zcounty
			
	sort facilitycode
	save temp.dta, replace
	
use "Tools/Case-Mgmt/COVID19HospitalReadiness_`country'_R`round'.dta", clear
		gen xresult = q904==1	
		gen module_CaseManagement = 1
		
		/*
		tab zlevel xresult, m
		list facilitycode z* q1104 if xresult!=1
		*/
		
	keep country round month year facilitycode z* xppe* xvac* xresult weight module_*
	drop zlevel_* zlevel4
		
	sort facilitycode
	merge facilitycode using temp.dta
	
		tab zlevel _merge, m /*there are some mismatches here - e.g., level 5 in CEHS*/ 
		tab xresult _merge, m
		tab zlevel xresult, m
			
	gen module=""
		replace module = "CaseManagement" if _merge==1
		replace module = "CEHS" if _merge==2
		replace module = "Both" if _merge==3
		
	gen zlevel_3cat=""
		replace zlevel_3cat="Level 2-3" if zlevel=="Level2" | zlevel=="Level3"
		replace zlevel_3cat="Level 4" if zlevel=="Level4"
		replace zlevel_3cat="Level 5-6" if zlevel=="Level5" | zlevel=="Level6"
		
		tab zlevel module, m
			
			* TABLE 2 for the KENYA report 
			tab zlevel , 
			tab zlevel module_CEHS, 
			tab zlevel module_CaseManagement, 
		
		drop _merge
				*ok
save "Tools/CommonFacilitySections/CommonFacilitySections_`country'_R`round'.dta", replace 
export delimited using "Tools/CommonFacilitySections/CommonFacilitySections_`country'_R`round'.csv", replace 
*okok
*export excel using "$chartbookdir\KEN_CEHS_Chartbook.xlsx", sheet("Facility-level cleaned data") sheetreplace firstrow(variables) nolabel
			
**************************************************************
* C. Create indicator estimate data 
**************************************************************
*cd "C:\Users\YoonJoung Choi\World Health Organization\BANICA, Sorin - HSA unit\3 Country implementation & learning\1 HFAs for COVID-19\Kenya\CommonFacilitySections"
cd "C:\Users\ctaylor\World Health Organization\BANICA, Sorin - HSA unit\3 Country implementation & learning\1 HFAs for COVID-19\Kenya\CommonFacilitySections"

use CommonFacilitySections_`country'_R`round'.dta, clear
	
	gen obs=1 	
	gen obs_vac=1 	if xvac==1
	
	save temp.dta, replace 
	
*****F.1. Calculate estimates 

	use temp.dta, clear
	collapse (count) obs* (mean) x* [iweight=weight], by(country round month year  )
		gen group="All"
		gen grouplabel="All"
		save summary_CommonFacilitySections_`country'_R`round'.dta, replace 
		
	use temp.dta, clear
	collapse (count) obs* (mean) x* [iweight=weight], by(country round month year  zurban)
		gen group="Location"
		gen grouplabel=""
			replace grouplabel="Rural" if zurban==0
			replace grouplabel="Urban" if zurban==1
				
		append using summary_CommonFacilitySections_`country'_R`round'.dta, force
		save summary_CommonFacilitySections_`country'_R`round'.dta, replace 

	use temp.dta, clear
	collapse (count) obs* (mean) x* [iweight=weight], by(country round month year  zlevel_3cat)
		gen group="Level"
		gen grouplabel=zlevel_3cat
					
		append using summary_CommonFacilitySections_`country'_R`round'.dta
		save summary_CommonFacilitySections_`country'_R`round'.dta, replace 
		
	use temp.dta, clear
	collapse (count) obs* (mean) x* [iweight=weight], by(country round month year  zpub)
		gen group="Sector"
		gen grouplabel=""
			replace grouplabel="Non-public" if zpub==0
			replace grouplabel="Public" if zpub==1
				
		append using summary_CommonFacilitySections_`country'_R`round'.dta		
		save summary_CommonFacilitySections_`country'_R`round'.dta, replace 
	
	
	* convert proportion to %
	foreach var of varlist x*{
		replace `var'=round(`var'*100, 1)	
		}
	
			* But, convert back variables that were incorrectly converted (e.g., occupancy rates, score)
			foreach var of varlist *_score {
				replace `var'=round(`var'/100, 1)
				}
	
	tab group round, m
	
	* organize order of the variables by section in the questionnaire  
	order country round year month group grouplabel obs obs_* 
		
	sort country round grouplabel
	
save summary_CommonFacilitySections_`country'_R`round'.dta, replace 

export delimited using summary_CommonFacilitySections_`country'_R`round'.csv, replace 

*****F.2. Export indicator estimate data to chartbook AND dashboard

use summary_CommonFacilitySections_`country'_R`round'.dta, clear

	gen updatedate = "$date"

	local time=c(current_time)
	gen updatetime=""
	replace updatetime="`time'"
	
export excel using "$chartbookdir\KEN_Common_chartbook.xlsx", sheet("Indicator estimate data") sheetreplace firstrow(variables) nolabel keepcellfmt
*export delimited using "C:\Users\YoonJoung Choi\Dropbox\0 iSquared\iSquared_WHO\ACTA\4.ShinyApp\Kenya\summary_CommonFacilitySections_`country'_R`round'.csv", replace 

erase temp.dta

END OF DATA CLEANING AND MANAGEMENT 

