clear
clear matrix
clear mata
capture log close
set more off
numlabel, add

*This code 
*1) imports and cleans hospital COVID19 case management capacity (aka "hospital products") dataset from Lime Survey, 
*2) creates field check tables for data quality monitoring, and 
*3) creates indicator estimate data for dashboards and chartbook. 

*  DATA IN:	CSV file daily downloaded from Limesurvey 	
*  DATA OUT to chartbook: 
*		1. raw data (as is, downloaded from Limesurvey) in Chartbook  	
*		2. cleaned data with additional analytical variables in Chartbook and, for further analyses, as a datafile 
*		3. summary estimates of indicators in Chartbook and, for dashboards, as a datafile 	

*TWO parts must be updated per country-specific adaptation. See "MUST BE ADAPTED" below 

/* TABLE OF CONTENTS*/

* A. SETTING <<<<<<<<<<========== MUST BE ADAPTED: 1. directories and local
* B. Import and drop duplicate cases
*****B.1. Import raw data from LimeSurvey 
*****B.2. Drop duplicate cases 
* C. Destring and recoding 
*****C.1. Change var names to lowercase	
*****C.2. Change var names to make then coding friendly 
*****C.3. Find non-numeric variables and desting 
*****C.4. Recode yes/no & yes/no/NA
*****C.5. Label values 
* D. Create field check tables 
* E. Create analytical variables 
*****E.1. Country speciic code local <<<<<<<<<<========== MUST BE ADAPTED: 2. local per survey implementation and section 1 
*****E.2. Construct analysis variables 
*****E.3. Merge with sampling weight 
*****E.4. Export clean Respondent-level data to chart book 
* F. Create and export indicator estimate data 
*****F.1. Calculate estimates 
*****F.2. Export indicator estimate data to chart book 

**************************************************************
* A. SETTING 
**************************************************************

*** Directory for this do file 
cd "C:\Users\YoonJoung Choi\Dropbox\0 iSquared\iSquared_WHO\ACTA\3.AnalysisPlan\"

*** Define a directory for the chartbook, if different from the main directory 
global chartbookdir "C:\Users\YoonJoung Choi\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards\"

*** Define a directory for downloaded CSV files from lime survey, if different from the main directory 
*global limesurveydir "C:\Users\YoonJoung Choi\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards\LimeSurvey_DownloadedCSV\"
global limesurveydir "C:\Users\YoonJoung Choi\Dropbox\0 iSquared\iSquared_WHO\ACTA\3.AnalysisPlan\ExportedCSV_FromLimeSurvey\"

*** Define local macro for the survey 
local country	 		 GreecePilot /*country name*/	
local round 			 1 /*round*/		
local year 			 	 2020 /*year of the mid point in data collection*/	
local month 			 9 /*month of the mid point in data collection*/				

*** local macro for analysis: no change needed  
local today=c(current_date)
local c_today= "`today'"
global date=subinstr("`c_today'", " ", "",.)

**************************************************************
* B. Import and drop duplicate cases
**************************************************************

*****B.1. Import raw data from LimeSurvey 

*import delimited ExportedCSV_FromLimeSurvey\LimeSurvey_COVID19HospitalReadiness_GreecePilot_R1.csv, case(preserve) clear 
import delimited "$limesurveydir\LimeSurvey_COVID19HospitalReadiness_GreecePilot_R1.CSV", case(preserve) clear 

	export excel using "$chartbookdir\WHO_COVID19HospitalReadiness_Chartbook.xlsx", sheet("Facility-level raw data") sheetreplace firstrow(variables) nolabel
	
***** Change var names to lowercase
 
	rename *, lower	

*****B.2. Drop duplicate cases 
	
	drop if id==.

	/*check duplicate cases, based on facility code, facility name, location and type*/
	*duplicates tag q101 q102 q104 q105, gen(duplicate) 
	/*check duplicate cases, based on facility code*/
	duplicates tag q101, gen(duplicate) 
				
		rename submitdate submitdate_string			
	gen double submitdate = clock(submitdate_string, "MDY hm")
		format submitdate %tc
				
		list q101 q102 q104 q105 submitdate* startdate datestamp if duplicate==1 
		
	/*drop duplicates before the latest submission*/ 
	egen double submitdatelatest = max(submitdate) if duplicate==1
						
		format %tcnn/dd/ccYY_hh:MM submitdatelatest
		
		list q101 q102 q104 q105 submitdate* if duplicate==1	
	
	drop if duplicate==1 & submitdate!=submitdatelatest 
	
	/*confirm there's no duplicate cases, based on facility code, facility name, location and type*/
	*duplicates report q101 q102 q104 q105,
	/*confirm there's no duplicate cases, based on facility code*/
	duplicates report q101,

	drop duplicate submitdatelatest

*****B.3. Expand Greek data and expand /ONLY FOR GREECE DUMMY DATA/

	sort q101
	gen n=12
	expand n
	
	replace id = _n
	sum id
	
	drop n
	
**************************************************************
* C. Destring and recoding 
**************************************************************

*****C.1. Change var names to lowercase
 
	rename *, lower

*****C.2. Change var names to drop odd elements "y" "sq" - because of Lime survey's naming convention 
	
	rename (*y) (*) /*when y is at the end */
	rename (*y*) (**) /*when y is in the middle */
	*rename (*sqsq*) (*sq*) /*when sq is repeated - no need to */
	*rename (*sq) (*) /*when ending with sq - no need to */

	rename (*_sq*) (*_*) /*replace sq with _*/
	rename (*sq*) (*_*) /*replace sq with _*/
	
	rename (*n) (*) /*when n is at the end */
	
*****C.3. Find non-numeric variables and desting 

	*****************************
	* Section 1
	*****************************
	sum q1*
	
	foreach var of varlist q104 q105 q106 q118*{	
		replace `var' = usubinstr(`var', "A", "", 1) 
		replace `var' = "88" if `var'=="-oth-"
		destring `var', replace 
		}
		
	*****************************	
	* Section 2
	*****************************
	sum q2* /*all numeric*/
	d q2*				
		
	*****************************	
	* Section 3
	*****************************
	sum q3* /*all numeric*/
	d q3*				
	
	*****************************
	* Section 4: Therapeutics
	*****************************
	sum q4*
	foreach var of varlist q401* q402* q403* q404* {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}			
	d q4*				
	
	*****************************
	* Section 5
	*****************************
	sum q5*	
	
	foreach var of varlist q502* q503* {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	
	d q5*	
	
	*****************************	
	* Section 6		
	**************************	
	sum q6*	
	
	foreach var of varlist q602* q605 q608 {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	
	d q6*
	
	*****************************	
	* Section 7
	*****************************
	**************************************************** likely many changes in var name here
	sum q7*/*all numeric*/ 
	d q7*	
		 		
	*****************************		
	* Section 8: Vaccine 
	*****************************
	sum q8*

	foreach var of varlist q808 q811 q813 {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}			
	d q8*
	
	*****************************			
	* Section 9: interview results
	*****************************
	sum q9*
	
	foreach var of varlist q901 q904 {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}			
	d q9*
	
*****C.4. Recode yes/no & yes/no/NA

	sum 

	foreach var of varlist q118_* q609_* {		
		recode `var' 2=0 /*no*/
		}	

	foreach var of varlist q401_* q402_* q404_* q503_* q602_*  {		
		recode `var' 2=0 /*no*/
		recode `var' 3=. /*not applicable*/
		}	
					
*****C.5. Label values 

	#delimit;	
	
	lab define q104 
		1"1. urban" 
		2"2. rural";  
	lab values q104 q104; 
	
	lab define q105 
		1"1.Primary care centre/clinic"
		2"2.First referral hospital (district hospital)"
		3"3.Other general hospital with specialties or single-specialty hospital"
		4"4.Long-term care facility"
		88"5.Other" ; 
	lab values q105 q105;
	
	lab define q106 
		1"1.Government"
		2"2.Private for profit"
		3"3.Private not for profit"
		4"4.Other"; 
	lab values q106 q106; 
	
	lab define ppe
		1"1.Currently available for all health workers"
		2"2.Currently available only for some health workers"
		3"3.Currently unavailable for any health workers"
		4"4.Not applicable – never procured or provided" ;
	foreach var of varlist q502* {;
	lab values `var' ppe;	
	};		
	
	lab define q605
		1"1.<24 hrs"
		2"2.24-47 hrs (1-2 days)"
		3"3.48-72 hrs (2-3 days)"
		4"4.>=72 hrs ( days or longer)" ;
	lab values q605 q605;	

	lab define availfunc 
		1"1.Yes, functional"
		2"2.Yes, but not functional"
		3"3.No";
	foreach var of varlist 
		q608 q804 q805   {;
	lab values `var' availfunc ;	
	};			

	lab define icepack 
		1"1.Yes, a set of ice packs for all cold boxes"
		2"1.Yes, a set of ice packs only for some cold boxes"
		3"3.No";
	foreach var of varlist q808 q811 {;
	lab values `var' icepack ;	
	};		
	
	lab define icepackfreeze 
		1"1.All"
		2"2.Only some"
		3"3.None-no ice packs"
		4"4.None-no functional freezer" ;
	lab values q813 icepackfreeze ;	
		
	lab define yesno 1"1. yes" 0"0. no"; 	
	foreach var of varlist 
		q115 q118* 
		q2* 
		q501
		q601 q603 q604 	
		q801 q802 q806 q809
		{;		
	labe values `var' yesno; 
	};
	
	lab define yesnona 1"1. yes" 0"0. no"; 
	foreach var of varlist 
		q401_* q402_* q404_* q503_* q602_* 
		{;		
	labe values `var' yesnona; 
	};
	
	#delimit cr

**************************************************************
* D. Create field check tables for data quality check  
**************************************************************

* generates daily field check tables in excel

preserve

			gen updatedate = "$date"
	
	tabout updatedate using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_ `round'_$date.xls", replace ///
		cells(freq col) h2("Date of field check table update") f(0 1) clab(n %)

			split submitdate_string, p(" ")
			gen date=date(submitdate_string1, "MDY") 
			format date %td
						
	tabout submitdate_string1 using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("Date of interviews (submission date, final)") f(0 1) clab(n %)
			
			gen xresult=q904==1
			replace xresult=1/*for greece pilot*/
			replace xresult = 0 in 1/*for greece pilot*/
			replace xresult = 0 in 38/*for greece pilot*/
			replace xresult = 0 in 57/*for greece pilot*/
			replace xresult = 0 in 79/*for greece pilot*/

			gen byte responserate= xresult==1
			label define responselist 0 "Not complete" 1 "Complete"
			label val responserate responselist

	tabout responserate using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("Interview response rate") f(0 1) clab(n %)
	
	tabout q104 using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("Number of completed interviews by area") f(0 1) clab(n %)
		
	tabout q105 using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("Number of completed interviews by hospital type") f(0 1) clab(n %)		

			gen double starttime = clock(startdate, "MDY hm")
			gen double endtime = clock(datestamp, "MDY hm")
			format %tc starttime
			format %tc endtime
			gen double time = (endtime- starttime)/(1000*60) /*interview length in minute*/
			format time %15.0f
			
			bysort xresult: sum time
			egen time_complete = mean(time) if xresult==1
			egen time_incomplete = mean(time) if xresult==0
				replace time_complete = round(time_complete, .1)
				replace time_incomplete = round(time_incomplete, .1)			
				
	tabout time xresult using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("Interview length (minutes): incomplete, complete, and total interviews") f(0 1) clab(n %)	
	tabout time_complete using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("Average interview length (minutes), among completed interviews") f(0 1) clab(n %)		
	tabout time_incomplete using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("Average interview length (minutes), among incomplete interviews") f(0 1) clab(n %)	
			
keep if xresult==1 /*the following calcualtes % missing in select questions among completed interviews*/		
	
			capture drop missing
			gen missing=0
			foreach var of varlist q116 q117 {	
				replace missing=1 if `var'==. & q115==1
				replace missing=1 if q115==.
				}		
			lab values missing yesno
			
	tabout missing using "$chartbookdir\FieldCheckTable_CEHS_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("1. Missing number of beds when facility provides inpatient services (among completed interviews)") f(0 1) clab(n %)					

			capture drop missing
			gen missing=0
			foreach var of varlist q401_* {	
				replace missing=1 if `var'==.
				}					
			lab values missing yesno	

	tabout missing using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("2. Missing medicines (either the total number or the number of non-functional) (among completed interviews)") f(0 1) clab(n %)							
		
			capture drop missing
			gen missing=0
			foreach var of varlist q502_* {	
				replace missing=1 if `var'==.
				}					
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("3. Missing PPE item (among completed interviews)") f(0 1) clab(n %)					

				
			capture drop missing
			gen missing=0
			foreach var of varlist q606 q607 {	
				replace missing=1 if `var'==.
				replace missing=1 if q603!=0
				}					
			lab values missing yesno	

	tabout missing using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("4. Missing PCR capacity (either the total number or the number of non-functional) (among completed interviews)") f(0 1) clab(n %)					
			
			capture drop missing
			gen missing=0
			foreach var of varlist q701_* {	
				replace missing=1 if `var'==.
				}					
			lab values missing yesno	

	tabout missing using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("5. Missing number of pulse oxymeter (either the total number or the number of non-functional) (among completed interviews)") f(0 1) clab(n %)					
	
restore
**************************************************************
* E. Create analytical variables 
**************************************************************

*****E.1. Country speciic code local 
	
	/* MUST REVIEW CODING FOR THE FOLLOWING FOUR GROUPS OF VARIABLES */
		/*
		zurban
		zlevel*
		zpub
		staff* 
		*/
	
	/*DEFINE LOCAL FOR THE FOLLOWING*/ 

		local urbanmin			 1 	
		local urbanmax			 1
		
		local minlow		 	 1 /*lowest code for lower-level facilities in Q105*/
		local maxlow		 	 1 /*highest code for lower-level facilities in Q105*/
		local minhigh		 	 2 /*lowest code for hospital/high-level facilities in Q105*/
		local maxhigh			 88 /*highest code for hospital/high-level facilities in Q105*/
		local districthospital   2 /*district hospital or equivalent */	
		
		local pubmin			 1
		local pubmax			 1
		
		local maxdrug 			 12 /*total medicines asked in q401*/
	
*****E.2. Construct analysis variables 

* give prefix z for background characteristics, which can be used as analysis strata     
* give prefix x for binary variables, which will be used to calculate percentage   
* give prefix y for integer/continuous variables, which will be used to calculate total

	*****************************
	* Section 1 
	*****************************
	
	gen country = "`country'"
	gen round =`round'
	
	gen facilitycode=q101

	gen month	=`month'
	gen year	=`year'
			
	foreach var of varlist q104 q105 q106{
		tab `var'
		}
	
	gen zurban	=q104>=`urbanmin' & q104<=`urbanmax'
	
	gen zlevel				=q105
	gen zlevel_hospital		=q105>=`minhigh' & q105<=`maxhigh'
	gen zlevel_disthospital	=q105==`districthospital'
	gen zlevel_low			=q105>=`minlow'  & q105<=`maxlow'
	
	gen zpub	=q106>=`pubmin' & q106<=`pubmax'
	
	lab define zurban 0"Rural" 1"Urban"
	lab define zlevel_hospital 0"Non-hospital" 1"Hospital"
	lab define zpub 0"Non-public" 1"Public"

	lab values zurban zurban
	lab values zlevel_hospital zlevel_hospital
	lab values zpub zpub
	
	lab var id "ID generated from Lime Survey"
	*lab var facilitycode "facility ID from sample list" /*this will be used to merge with sampling weight, if relevant*/
	
	*****************************
	* Section 2: IMST
	*****************************

	gen ximst		= q201==1
	gen ximst_fun	= q202==1
	
	*****************************
	* Section 3: bed caoacity
	*****************************

	gen byte xipt= q115==1
	gen byte xicu= q117>=1 & q117!=.
	lab var xipt "facilities providing IPT services"
	lab var xicu "facilities providing ICU services"
	
	gen ybed 			= q116
	gen ybed_icu 	 	= q117
		replace ybed_icu=0 if xipt==1 & xicu==0 /*assume 0 ICU beds if IPT provided but no ICU beds reported*/
	
	gen ybed_cap_covid 			= q301
	gen ybed_cap_covid_severe 	= q302
	gen ybed_cap_covid_critical = q303
	
	gen ybed_covid_night   = (q304 + q305)/2

	gen ybed_cap_respiso = q306	
	gen ybed_convert_respiso = q307
		
	gen ybed_convert_icu 	 = q308
	
	gen xocc_lastnight = q309
	gen xocc_lastmonth = q310
	
	*****************************
	* Section 4: Therapeutics
	*****************************

		gen max=`maxdrug'
		egen temp=rowtotal(q401_* )
	gen xdrug_score	=100*(temp/max)
	gen xdrug_100 	=xdrug_score>=100
	gen xdrug_50 	=xdrug_score>=50
		drop max temp
				
		gen max=3
		egen temp=rowtotal(q402_* )
	gen xsupp_score	=100*(temp/max)
	gen xsupp_100 	=xsupp_score>=100
	gen xsupp_50 	=xsupp_score>=50
		drop max temp
		
		gen max=5
		egen temp=rowtotal(q404_* )
	gen xsolidarity_score	=100*(temp/max)
	gen xsolidarity_100 	=xsolidarity_score>=100
	gen xsolidarity_50 		=xsolidarity_score>=50
		drop max temp

	global itemlist "001 002 003 004 005 006 007 008 009 010 011 012" 
	*global itemlist "a b c d e f g h i j k l" 
	foreach item in $itemlist{	
		gen xdrug__`item' = q401_`item' ==1
		}		
	global itemlist "001 002 003"	
	*global itemlist "a b c" 
	foreach item in $itemlist{	
		gen xsupply__`item' = q402_`item' ==1
		}	

	*****************************
	* Section 5: IPC 
	*****************************
				
	gen xppe= q501
	
	global itemlist "001 002 003 004 005 006" 
	*global itemlist "a b c d e f"
	foreach item in $itemlist{	
		gen xppe_allsome__`item' = q502_`item'==1 | q502_`item'==2
		}	

		gen max=6
		egen temp=	rowtotal(xppe_allsome__*)
	gen xppe_allsome_score	=100*(temp/max)
	gen xppe_allsome_100 		=xppe_allsome_score>=100
	gen xppe_allsome_50 		=xppe_allsome_score>=50
		drop max temp
	
	global itemlist "001 002 003 004 005 006" 
	*global itemlist "a b c d e f"
	foreach item in $itemlist{	
		gen xppe_all__`item' = q502_`item'==1
		}						

		gen max=6
		egen temp=	rowtotal(xppe_all__*)
	gen xppe_all_score	=100*(temp/max)
	gen xppe_all_100 		=xppe_all_score>=100
	gen xppe_all_50 		=xppe_all_score>=50
		drop max temp

	global itemlist "001 002 003 004" 	
	*global itemlist "a b c d"
	foreach item in $itemlist{	
		gen xipcitem__`item' = q503_`item'==1
		}						

		gen max=4
		egen temp=	rowtotal(xipcitem__*)
	gen xipcitem_score	=100*(temp/max)
	gen xipcitem_100 		=xipcitem_score>=100
	gen xipcitem_50 		=xipcitem_score>=50
		drop max temp
		
	sum xppe* xipc* 

	*****************************
	* Section 6 : LAB
	*****************************
	
	gen xspcm		=q601==1
	global itemlist "001 002 003" 	
	foreach item in $itemlist{	
		gen xspcmitem__`item' = q602_`item'==1
		}							
	*gen xspcm_item	=q602_001==1 & q602_002==1 & q602_003==1
	
		gen max=3
		egen temp=	rowtotal(xspcmitem__*)
	gen xspcmitem_score	=100*(temp/max)
	gen xspcmitem_100 		=xspcmitem_score>=100
	gen xspcmitem_50 		=xspcmitem_score>=50
		drop max temp	
		
	gen xtest			=q603!=1
	gen xtesttransport	=q604==1	
	
	gen xtesttime_24	=q605==1
	gen xtesttime_48	=q605<=2
	gen xtesttime_72	=q605<=3
		
	foreach var of varlist xtesttransport xtesttime*	{ /*YC edit 12/14/2020*/
		replace `var'=. if xtest!=1
		}
	
	gen xpcr 			= q603==1
	gen xpcr_capacity 	= q606/q607
	gen xpcr_equip		= q608==1
		
	foreach var of varlist xpcr_*	{
		replace `var'=. if xpcr!=1
		}	
		
		gen max=2
		egen temp =  rowtotal(xspcmitem_100 xtesttime_48 xpcr_equip)
	gen xdiagcovid_score = 100*(temp/max)
	gen xdiagcovid_100	= xdiagcovid_score >=100
	gen xdiagcovid_50	= xdiagcovid_score >=50
		drop max temp
	
	*****************************
	* Section 7: Equipment 
	*****************************

	gen yequip_ventilator = q701_003_003
	gen yequip_noninvventilator = q701_004_003
	gen yequip_o2concentrator = q701_005_003
	
	global itemlist "001 002 003 004 005"
	foreach item in $itemlist{	
		gen xequip_anyfunction__`item' = q701_`item'_002>=1 & q701_`item'_002!=. /*YC edit 12/13/2020*/
		}			
		
		gen max=5
		egen temp=rowtotal(xequip_anyfunction_*)
	gen xequip_anyfunction_score	=100*(temp/max)
	gen xequip_anyfunction_100		=xequip_anyfunction_score>=100
	gen xequip_anyfunction_50		=xequip_anyfunction_score>=50
		drop max temp				
				
	global itemlist "001 002 003 004 005"
	foreach item in $itemlist{	
		gen xequip_allfunction__`item' = q701_`item'_002>=1 & q701_`item'_002!=. & q701_`item'_003==0 /*YC edit 12/13/2020*/
		}			
		
		gen max=5
		egen temp=rowtotal(xequip_allfunction_*)
	gen xequip_allfunction_score	=100*(temp/max)
	gen xequip_allfunction_100		=xequip_allfunction_score>=100
	gen xequip_allfunction_50		=xequip_allfunction_score>=50
		drop max temp				
	
	global itemlist "001 002 003 004 005"
	foreach item in $itemlist{	
		gen xequip_anymalfunction__`item' = q701_`item'_003>=1 & q701_`item'_003!=.
		}			

		egen temp=rowtotal(xequip_anymalfunction_*)
	gen xequip_anymalfunction=temp>=1
		drop temp
	
	/*	
	global itemlist "001 002 003 004 005"
	foreach item in $itemlist{	
		gen xequip_allmalfunction__`item' = q701_`item'_002==0 & (q701_`item'_003>=1 & q701_`item'_003!=.)
		}			

		egen temp=rowtotal(xequip_allmalfunction_*)
	gen xequip_allmalfunction=temp==5
		drop temp		
	*/
	
	global itemlist "001 002 003 004"
	foreach item in $itemlist{	
		gen xequip_malfunction_reason__`item' = q704_`item'==1 | q706_`item'==1 | q708_`item'==1
		}
	
	foreach var of varlist xequip_malfunction_reason_*{
		replace `var'=. if xequip_anymalfunction!=1
		}
			
	gen xoxygen_portable 	= q709==1 
	gen xoxygen_plant 		= q710==1 
	gen xoxygen_piped 		= q711==1   
	
		egen temp=rowtotal(xoxygen_*)
	gen xoxygen 		= temp==3
	
		drop temp
		
		drop xequip_anymalfunction__*
	
	*****************************
	* Section 8: vaccine
	*****************************
	
	gen xvac= q801==1 | q802==1
	
	gen xvac_av_fridge 		= q804==1 | q804==2
	gen xvac_avfun_fridge 	= q804==1 
	gen xvac_avfun_fridgetemp 	= q804==1 & q805==1
	
	gen xvac_av_coldbox	= q806==1
	
	gen xvac_avfun_coldbox_all		= q806==1 & (q807>=1 & q807!=.) & q808==1
	gen xvac_avfun_coldbox_all_full	= q806==1 & (q807>=1 & q807!=.) & q808==1 & q813==1
	
	gen yvac_avfun_coldbox_all		= q807 if xvac_avfun_coldbox_all==1
	gen yvac_avfun_coldbox_all_full	= q807 if xvac_avfun_coldbox_all==1 & q813==1
	
	gen xvac_av_carrier	= q809==1
	
	gen xvac_avfun_carrier_all		= q809==1 & (q810>=1 & q810!=.) & q811==1	
	gen xvac_avfun_carrier_all_full	= q809==1 & (q810>=1 & q810!=.) & q811==1 & q813==1	
	
	gen yvac_avfun_carrier_all		= q810 if xvac_avfun_carrier_all==1
	gen yvac_avfun_carrier_all_full	= q810 if xvac_avfun_carrier_all==1 & q813==1
		
	gen xvac_av_outreach = xvac_av_coldbox ==1 | xvac_av_carrier ==1  
	gen xvac_avfun_outreach_all_full = xvac_avfun_coldbox_all_full ==1 | xvac_avfun_carrier_all_full==1  	
	
	foreach var of varlist xvac_av* yvac_av* {
		replace `var'=. if xvac!=1
		}	
	
	lab var xvac_av_fridge "has fridge"
	lab var xvac_avfun_fridge "has functioning fridge"
	lab var xvac_avfun_fridgetemp "has functioning fridge with temp log"
	
	lab var xvac_av_coldbox "has coldbox"
	lab var xvac_avfun_coldbox_all "has functioning coldbox, all"
	lab var xvac_avfun_coldbox_all_full "has functioning coldbox with icepacks, all"
	
	lab var xvac_av_carrier "has carrier"
	lab var xvac_avfun_carrier_all "has functioning carrier, all"
	lab var xvac_avfun_carrier_all_full "has functioning carrier with icepacks, all"

	sort facilitycode
	save COVID19HospitalReadiness_`country'_R`round'.dta, replace 		
	
*****E.3. Merge with sampling weight 
import excel "$chartbookdir\WHO_COVID19HospitalReadiness_Chartbook.xlsx", sheet("Weight") firstrow clear
	rename *, lower
	sort facilitycode
	merge facilitycode using COVID19HospitalReadiness_`country'_R`round'.dta, 
	
		tab _merge
		drop _merge*
		
	sort id /*this is generated from Lime survey*/
	save COVID19HospitalReadiness_`country'_R`round'.dta, replace 			
	
*****E.4. Export clean facility-level data to chart book 

	save COVID19HospitalReadiness_`country'_R`round'.dta, replace 		

	export excel using "$chartbookdir\WHO_COVID19HospitalReadiness_Chartbook.xlsx", sheet("Facility-level cleaned data") sheetreplace firstrow(variables) nolabel
	
			************************************************************************************
			**************************************************************************************	
			*Just for Greece Pilot data 
			*create round 2 and 3 datasets 

			use COVID19HospitalReadiness_GreecePilot_R1.dta, clear
				replace round=2
				replace year=2020
				replace month=12
				
				drop if id==26 | id==33
				
				duplicates tag q101 q102 q104 q105, gen(duplicate) 	
				sort q101 id
				drop if q101==q101[_n-1]
						
				gen n=13
				expand n
				replace id = _n
				sum id
			save COVID19HospitalReadiness_GreecePilot_R2.dta, replace 

			use COVID19HospitalReadiness_GreecePilot_R1.dta, clear
				replace round=3
				replace year=2021
				replace month=3
				
				drop if id==22 | id==30
					
				duplicates tag q101 q102 q104 q105, gen(duplicate) 	
				sort q101 id
				drop if q101==q101[_n-1]
						
				gen n=13
				expand n
				replace id = _n
				sum id
			save COVID19HospitalReadiness_GreecePilot_R3.dta, replace 
			**************************************************************************************	
			**************************************************************************************		
			
**************************************************************
* F. Create indicator estimate data 
**************************************************************
use COVID19HospitalReadiness_`country'_R`round'.dta, clear
	
	gen obs=1 	
	gen obs_ipt=1 	if xipt==1
	gen obs_icu=1 	if xicu==1
	gen obs_vac=1 	if xvac==1
	gen obs_spcm=1 	if xspcm==1
	gen obs_test=1 	if xtest==1
	gen obs_pcr=1 	if xpcr==1
	
	gen xresult=q901==1
		replace xresult=1 /*DELETE this line with real data*/
	keep if xresult==1 
	
	save temp.dta, replace 
	
*****F.1. Calculate estimates 

	use temp.dta, clear
	collapse (count) obs* (mean) x* (sum) ybed* yequip*  yvac* [iweight=weight], by(country round month year  )
		gen group="All"
		keep obs* country round month year  group* x* y* yvac*
		save summary_COVID19HospitalReadiness_`country'_R`round'.dta, replace 
		
	use temp.dta, clear
	collapse (count) obs* (mean) x* (sum) ybed* yequip*  yvac* [iweight=weight], by(country round month year   zurban)
		gen group="Location"
		gen grouplabel=""
			replace grouplabel="1.1 Rural" if zurban==0
			replace grouplabel="1.2 Urban" if zurban==1
		keep obs* country round month year  group* x* y* yvac*
		
		append using summary_COVID19HospitalReadiness_`country'_R`round'.dta, force
		save summary_COVID19HospitalReadiness_`country'_R`round'.dta, replace 

	use temp.dta, clear
	collapse (count) obs* (mean) x* (sum) ybed* yequip*  yvac* [iweight=weight], by(country round month year   zlevel_hospital)
		gen group="Level"
		gen grouplabel=""
			replace grouplabel="2.1 Non-hospitals" if zlevel_hospital==0
			replace grouplabel="2.2 Hospitals" if zlevel_hospital==1
		keep obs* country round month year  group* x* y* yvac*
			
		append using summary_COVID19HospitalReadiness_`country'_R`round'.dta
		save summary_COVID19HospitalReadiness_`country'_R`round'.dta, replace 
		
	use temp.dta, clear
	collapse (count) obs* (mean) x* (sum) ybed* yequip*  yvac* [iweight=weight], by(country round month year   zpub)
		gen group="Sector"
		gen grouplabel=""
			replace grouplabel="3.1 Non-public" if zpub==0
			replace grouplabel="3.2 Public" if zpub==1
		keep obs* country round month year  group* x* y* yvac*
		
		append using summary_COVID19HospitalReadiness_`country'_R`round'.dta		
		save summary_COVID19HospitalReadiness_`country'_R`round'.dta, replace 
		
	foreach var of varlist x*{
		replace `var'=round(`var'*100, 1)	
		}
		
	foreach var of varlist xocc* xpcr_capacity *score{
		replace `var'=round(`var'/100, 1)	
		}		
	
	tab group round, m

	* organize order of the variables by section in the questionnaire  
	order country round year month group grouplabel obs* 
		
	sort country round grouplabel
	
save summary_COVID19HospitalReadiness_`country'_R`round'.dta, replace 

export delimited using summary_COVID19HospitalReadiness_`country'_R`round'.csv, replace 
export delimited using "C:\Users\YoonJoung Choi\Dropbox\0 iSquared\iSquared_WHO\ACTA\4.ShinyAppCEHS\summary_COVID19HospitalReadiness_`country'_R`round'.csv", replace 

*****F.2. Export indicator estimate data to chartbook AND dashboard

use summary_COVID19HospitalReadiness_`country'_R`round'.dta, clear

	gen updatedate = "$date"

	local time=c(current_time)
	gen updatetime=""
	replace updatetime="`time'"

export excel using "$chartbookdir\WHO_COVID19HospitalReadiness_Chartbook.xlsx", sheet("Indicator estimate data") sheetreplace firstrow(variables) nolabel keepcellfmt


erase temp.dta

END OF DATA CLEANING AND MANAGEMENT 

