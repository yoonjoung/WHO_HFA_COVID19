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

*** Directory for this do file and a subfolder for "daily exported CSV file from LimeSurvey"  
cd "C:\Users\YoonJoung Choi\World Health Organization\BANICA, Sorin - HSA unit\1 Admin\Countries\Country Surveys\Kenya\Case-Mgmt"
*cd "C:\Users\ctaylor\World Health Organization\BANICA, Sorin - HSA unit\1 Admin\Countries\Country Surveys\Kenya\Case-Mgmt"
dir

*** Define a directory for the chartbook, if different from the main directory 
global chartbookdir "C:\Users\YoonJoung Choi\World Health Organization\BANICA, Sorin - HSA unit\1 Admin\Countries\Country Surveys\Kenya\Case-Mgmt"
*global chartbookdir "C:\Users\ctaylor\World Health Organization\BANICA, Sorin - HSA unit\1 Admin\Countries\Country Surveys\Kenya\Case-Mgmt"

*** Define local macro for the survey 
local country	 		 Kenya /*country name*/	
local round 			 1 /*round*/		
local year 			 	 2020 /*year of the mid point in data collection*/	
local month 			 12 /*month of the mid point in data collection*/		

*** local macro for analysis: no change needed  
local today=c(current_date)
local c_today= "`today'"
global date=subinstr("`c_today'", " ", "",.)

**************************************************************
* B. Import and drop duplicate cases
**************************************************************

*****B.1. Import raw data from LimeSurvey 

*import delimited "15122020_results-survey447349_codes.csv", case(preserve) clear 
*import delimited "16122020_results-survey447349_codes.csv", case(preserve) clear 
*import delimited "17122020_results-survey447349_codes.csv", case(preserve) clear 
import delimited "18122020_results-survey447349_codes.csv", case(preserve) clear 

	drop if Q101=="Test 1" | Q101=="Test 2" /* KE specific, drop test rows*/ 

	codebook token Q101
		list Q1* if Q101=="" | token=="" /*empty row*/
		
	drop if Q101=="" /* KE specific : dummy line generated from Lime survey? */ 

	export excel using "$chartbookdir\KEN_Hospital_Chartbook.xlsx", sheet("Facility-level raw data") sheetreplace firstrow(variables) nolabel
	
***** Change var names to lowercase
 
	rename *, lower	
	
***** CT - Sorin added variables for the time it takes to complete questions.  We don't need here so delete
	drop *time
	
***** KECT - ID variable comes in weird, so changing name
	rename ïid id
	
*****B.2. Drop duplicate cases 
	
	drop if id==.

	/*check duplicate cases, based on facility code*/
	duplicates tag q101, gen(duplicate) 
				
		rename submitdate submitdate_string			
	gen double submitdate = clock(submitdate_string, "YMD hms") /* KECT - changed to YMD hms from MDY hm*/
		format submitdate %tc
				
		list q101 q102 q104 q105 submitdate* startdate datestamp if duplicate==1 
		
	/*drop duplicates before the latest submission*/ 
	egen double submitdatelatest = max(submitdate) if duplicate==1
						
		format %tcnn/dd/ccYY_hh:MM submitdatelatest
		
		list q101 q102 q104 q105 submitdate* if duplicate==1	
	
	drop if duplicate==1 & submitdate!=submitdatelatest 
	
	/*confirm there's no duplicate cases, based on facility code*/
	duplicates report q101,

	drop duplicate submitdatelatest

**************************************************************
* C. Destring and recoding 
**************************************************************

*****C.1. Change var names to lowercase
 
	rename *, lower

*****C.2. Change var names to drop odd elements "y" "sq" - because of Lime survey's naming convention 
	
	//*KE YC edit begins*//
	drop grouptime* 
	
	*rename (*y) (*) /*when y is at the end */  /* CT - no variables with *y were found*/
	*rename (*y*) (**) /*when y is in the middle */
	*rename (*sqsq*) (*sq*) /*when sq is repeated - no need to */
	*rename (*_sq*) (*_*) /*replace sq with _*/
	
	rename (*sq) (*) /*when ending with sq - no need to */
	rename (*sqsq*) (*_*) /*replace double sq with _*/
	rename (*sq*) (*_*) /*replace sq with _*/
	
	rename (q701_*_a1) (q701_*_001)
	rename (q701_*_a2) (q701_*_002)
	//*KE YC edit ends*//
	
*****C.3. Find non-numeric variables and desting 

	*****************************
	* Section 1
	*****************************
	sum q1*
	codebook q104 q105 q106 q114 q116*
		
	foreach var of varlist q104 q105 q106 q118*{	
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}
	sum q1*		
			
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
	foreach var of varlist q401* q402* {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}			
	d q4*				
	
	/* KECT - q403 and q404 don't exist in the Kenya data, so removed from above */
	
	*****************************
	* Section 5
	*****************************
	sum q5*	
	codebook q502* q503*
	
	foreach var of varlist q502* q503* {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	
	d q5*	
	
	*****************************	
	* Section 6		
	**************************	
	sum q6*	
	codebook q602_* q608 q609_* 
	
	foreach var of varlist q602_* q608  {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	
	d q6*
	
	*****************************	
	* Section 7
	*****************************
	sum q7*	
	codebook q703_* q704_* q706_* q708_* 

	foreach var of varlist q704_* q706_* q708_*  {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	
	d q7*	
	
	*****************************		
	* Section 8: Vaccine 
	*****************************
	sum q8*
	codebook q8031 q807* q810* q811* 
	
	foreach var of varlist q8031 q807* q810* q811* {		
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
	
	#delimit;
	sum
		q118_* 
		q201 q202 
		q311
		q501
		q601 q603 q604 q609_* 
		q704* q705 q707 q708*
		q801 q802 q805 q808 q812* 
		; 
		#delimit cr
		
	#delimit;
	foreach var of varlist 
		q118_* 
		q201 q202 
		q311
		q501
		q601 q603 q604 q609_* 
		q704* q705 q707 q708*
		q801 q802 q805 q808 q812* 
		{;	
		#delimit cr 
		recode `var' 2=0 /*no*/
		}	
		
	#delimit;
	sum
		q401_* q402_* 
		q503_* q602_* q706*
		; 
		#delimit cr		
		
	#delimit;
	foreach var of varlist 
		q401_* q402_* 
		q503_* q602_* q706*
		{;	
		#delimit cr 
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
		1"1. L2: Dispensary or medical clinic"
		2"2. L3: Health centre"
		3"3. L4: Primary hospital"
		4"4. L5: Secondary hospital"
		5"5. L6: Tertiary hospital" ; 
	lab values q105 q105;

	/* KECT - Facility list changed, so changed the define list*/
	
	lab define q106 
		1"1. Government"
		2"2. Private"
		3"3. NGO"
		4"4. Faith-based"
		5"5. Other"; 
	lab values q106 q106; 

	/* KECT - Management type list changed, so changed the define list*/
	
	lab define ppe
		1"1.Currently available for all health workers"
		2"2.Currently available only for some health workers"
		3"3.Currently unavailable for any health workers"
		4"4.Not applicable – never procured or provided" ;
	foreach var of varlist q502* {;
	lab values `var' ppe;	
	};		
	
	lab define availfunc 
		1"1.Yes, functional"
		2"2.Yes, but not functional"
		3"3.No";
	foreach var of varlist 
		q608 q803 q804 {;
	lab values `var' availfunc ;	
	};			

	lab define icepack 
		1"1.Yes, a set of ice packs for all cold boxes"
		2"1.Yes, a set of ice packs only for some cold boxes"
		3"3.No";
	foreach var of varlist q807 q810 {;
	lab values `var' icepack ;	
	};		
	
	lab define icepackfreeze 
		1"1.All"
		2"2.Only some"
		3"3.None-no functional freezer" ;
	lab values q811 icepackfreeze ;	
			
	lab define yesno 1"1. yes" 0"0. no"; 	
	foreach var of varlist 
		q115 q118_* 
		q201 q202 
		q311
		q501
		q601 q603 q604 q609_* 
		q704* q705 q707 q708*
		q801 q802 q805 q808 q812* 
		{;		
	labe values `var' yesno; 
	};
	
	lab define yesnona 1"1. yes" 0"0. no"; 
	foreach var of varlist 
		q401_* q402_* 
		q503_* q602_* q706*
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
	
	tabout updatedate using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", replace ///
		cells(freq col) h2("Date of field check table update") f(0 1) clab(n %)

			split submitdate_string, p(" ")
			gen date=date(submitdate_string1, "YMD") /* KECT - changed to YMD from MDY*/
			format date %td
						
	tabout submitdate_string1 using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Date of interviews (submission date, final)") f(0 1) clab(n %)
			
			gen xresult=q904==1

			gen byte responserate= xresult==1
			label define responselist 0 "Not complete" 1 "Complete"
			label val responserate responselist

	tabout responserate using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Interview response rate") f(0 1) clab(n %) mi
	
	tabout q104 using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("number of interviews by area") f(0 1) clab(n %) mi
		
	tabout q105 using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("number of interviews by hospital type") f(0 1) clab(n %) mi		

			gen double starttime = clock(startdate, "YMD hms") /* KECT - changed to YMD hms from MDY hm*/
			gen double endtime = clock(datestamp, "YMD hms") /* KECT - changed to YMD hms from MDY hm*/
			format %tc starttime
			format %tc endtime
			gen double time = (endtime- starttime)/(1000*60) /*interview length in minute*/
			format time %15.0f
			
			bysort xresult: sum time
			egen time_complete = mean(time) if xresult==1
			egen time_incomplete = mean(time) if xresult==0
				replace time_complete = round(time_complete, .1)
				replace time_incomplete = round(time_incomplete, .1)			
	/*			
	*tabout time xresult using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
	*	cells(freq col) h2("Interview length (minutes): incomplete, complete, and total interviews") f(0 1) clab(n %)	
	tabout time_complete using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Average interview length (minutes), among completed interviews") f(0 1) clab(n %)		
	tabout time_incomplete using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Average interview length (minutes), among incomplete interviews") f(0 1) clab(n %)	
	*/
* Missing responses 

			capture drop missing
			gen missing=0
			foreach var of varlist q904 {	
				replace missing=1 if `var'==.				
				}		
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("0. Missing survery results (among all interviews)") f(0 1) clab(n %)				
		
keep if xresult==1 /*the following calcualtes % missing in select questions among completed interviews*/		
	
			capture drop missing
			gen missing=0
			foreach var of varlist q116 q117 {	
				replace missing=1 if `var'==. & q115==1
				replace missing=1 if q115==.
				}		
			lab values missing yesno
			
	tabout missing using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("1. Missing number of beds when facility provides inpatient services (among completed interviews)") f(0 1) clab(n %)					

			capture drop missing
			gen missing=0
			foreach var of varlist q401_* {	
				replace missing=1 if `var'==.
				}					
			lab values missing yesno	

	tabout missing using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("2. Missing medicines - in one or more of the tracer items (among completed interviews)") f(0 1) clab(n %)							
		
			capture drop missing
			gen missing=0
			foreach var of varlist q502_* {	
				replace missing=1 if `var'==.
				}					
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("3. Missing PPE item - in one or more of the tracer items (among completed interviews)") f(0 1) clab(n %)					

				
			capture drop missing
			gen missing=0
			foreach var of varlist q606 q607 {	
				replace missing=1 if `var'==.
				replace missing=1 if q603!=0
				}					
			lab values missing yesno	

	tabout missing using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("4. Missing PCR capacity  (among completed interviews)") f(0 1) clab(n %)					
						
			capture drop missing
			gen missing=0
			foreach var of varlist q701_* {	
				replace missing=1 if `var'==.
				}					
			lab values missing yesno	

	tabout missing using "$chartbookdir\FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("5. Missing entry in the number of equipment (either the total number or the number of functional) (among completed interviews)") f(0 1) clab(n %)					
			*/
			
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
		*/
	
	/*DEFINE LOCAL FOR THE FOLLOWING*/ 

		local urbanmin			 1 	
		local urbanmax			 1
		
		local minlow		 	 1 /*lowest code for lower-level facilities in Q105*/
		local maxlow		 	 2 /*highest code for lower-level facilities in Q105*/ /*KECT - 2 is code for health centre*/
		local minhigh		 	 3 /*lowest code for hospital/high-level facilities in Q105*/  /*KECT - 3 is code for primary hospital*/
		local maxhigh			 5 /*highest code for hospital/high-level facilities in Q105*/ /*KECT - there is no 88 in Kenya, highest is 6*/
		local primaryhospital   3 /*district hospital or equivalent */	/*KECT - there is no district hospital in Kenya, assume that pimary hospital is closest option*/
		
		local pubmin			 1
		local pubmax			 1
		
		local maxdrug 			 10 /*total medicines asked in q401*/ /*KECT - there are 10 medicines asked about in Kenya*/
	
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

	gen month = `month'
	gen year	=`year'
			
	foreach var of varlist q104 q105 q106{
		tab `var'
		}
		
	gen zurban	=q104>=`urbanmin' & q104<=`urbanmax'
	
	gen zlevel			=""
		replace zlevel	="Level2" if q105==1
		replace zlevel	="Level3" if q105==2
		replace zlevel	="Level4" if q105==3
		replace zlevel	="Level5" if q105==4
		replace zlevel	="Level6" if q105==5
	
	gen zlevel_hospital		=q105>=`minhigh' & q105<=`maxhigh'
	gen zlevel_primhospital	=q105==`primaryhospital'
	gen zlevel_low			=q105>=`minlow'  & q105<=`maxlow'
	
	gen zpub	=q106>=`pubmin' & q106<=`pubmax'
	
	gen zcounty = q101a
	gen zlevel4 = zlevel=="Level4"
		
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
	* Section 3: bed capacity & staff
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
	gen ybed_covid_month = q305b /* KECT - added monthly average COVID occupancy */
	
	*gen xcovid_occ_night = ybed_covid_night/q301 /* KECT calculate % of COVID ready beds occupied by COVID patients, last night */
	*gen xcovid_occ_month = ybed_covid_month/q301 /* KEYC calculate % of COVID ready beds occupied by COVID patients, last month */
	gen xcovid_occ_lastnight = 100*(ybed_covid_night/ybed) /* KECT calculate % of beds occupied by COVID patients, last night  - this in case q301==0? */ 
	gen xcovid_occ_lastmonth = 100*(ybed_covid_month/ybed) /* KEYC calculate % of beds occupied by COVID patients, last month  - this in case q301==0? */

	gen ybed_cap_isolation = q306	
	gen ybed_cap_respiso_o2 = q306b
	gen ybed_convert_respiso = q307
	gen ybed_convert_icu 	 = q308
	
	gen xocc_lastnight = 100* (q309 / ybed) /*KEYC review data and confirm*/
	
	gen ypt_homecare = q310 /* KECT added number of patients sent home for homebased care */
	
	///* KE edit begins*///
	gen xstaffsupport = q311==1
	gen ystaffsupport_num = q312
		replace ystaffsupport_num =. if xstaffsupport!=1
		
	gen xnrshift__day = q313_001
	gen xnrshift__night = q313_002
	
	gen xstaff_test_none = q314_001
	gen xstaff_test_2wk = q314_002
	gen xstaff_test_symp = q314_003
	gen xstaff_test_exp = q314_004
		
	///* KE edit ends*///
	
	*****************************
	* Section 4: Therapeutics
	*****************************
	/*QUESTION: confirm the number of meds: 10 or 12? currently 12 items incldued, though 10 were asked under "meds" */
/*
		gen max=12
		egen temp=rowtotal(q401_*  q402_004 q402_005) /*KEYC edit*/
	gen xdrug_score	=100*(temp/max)
	gen xdrug_100 	=xdrug_score>=100
	gen xdrug_50 	=xdrug_score>=50
		drop max temp
				
		gen max=3
		egen temp=rowtotal(q402_001 q402_002 q402_003 )  /*KEYC edit*/
	gen xsupp_score	=100*(temp/max)
	gen xsupp_100 	=xsupp_score>=100
	gen xsupp_50 	=xsupp_score>=50
		drop max temp

	global itemlist "001 002 003 004 005 006 007 008 009 010" 
	foreach item in $itemlist{	
		gen xdrug__`item' = q401_`item'
		}		
		gen xdrug__011 = q402_004  /*KEYC edit*/
		gen xdrug__012 = q402_005  /*KEYC edit*/
		
	global itemlist "001 002 003"	
	foreach item in $itemlist{	
		gen xsupply__`item' = q402_`item'
		}	
*/
	/* KECT - Changed to Kenya specifics with the disinfectants moved to supplies.  Kept the original in case we change our minds */
		
		gen max=10
		egen temp=rowtotal(q401_*) /*KECT use only drugs included in Kenya's q4.1*/
	gen xdrug_score	=100*(temp/max)
	gen xdrug_100 	=xdrug_score>=100
	gen xdrug_50 	=xdrug_score>=50
		drop max temp
				
		gen max=5
		egen temp=rowtotal(q402_*)  /*KECT use all five supplies in Kenya's q4.2*/
	gen xsupp_score	=100*(temp/max)
	gen xsupp_100 	=xsupp_score>=100
	gen xsupp_50 	=xsupp_score>=50
		drop max temp

	global itemlist "001 002 003 004 005 006 007 008 009 010" 
	foreach item in $itemlist{	
		gen xdrug__`item' = q401_`item' ==1
		}		
		*gen xdrug__011 = q402_004  /*KECT edit*/
		*gen xdrug__012 = q402_005  /*KECT edit*/
		
	global itemlist "001 002 003 004 005"	/*KECT edit*/
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

	global itemlist "001 002 003 004 005 006" 	
	*global itemlist "a b c d"
	foreach item in $itemlist{	
		gen xipcitem__`item' = q503_`item'==1
		}						

		gen max=6
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
	global itemlist "001 002" 	
	foreach item in $itemlist{	
		gen xspcmitem__`item' = q602_`item'==1
		}							
		
		gen max=2
		egen temp=	rowtotal(xspcmitem__*)
	gen xspcmitem_score	=100*(temp/max)
	gen xspcmitem_100 		=xspcmitem_score>=100
	gen xspcmitem_50 		=xspcmitem_score>=50
		drop max temp	
		
	gen xtest			=q603!=1 /*test else where*/
	gen xtesttransport	=q604==1	
	
	/* KEYC revised per numeric var - 
	*		based on the distribution there is a heaping on day 3. */
	* 		Revise the cutoff 	. */
	
	/* KECT changed categories*/
	if q605--.{ /*QUESTION - what do we think 0 means? - Currently being treated as less than a day should it be set as missing?*/
	gen xtesttime_1	=q605<=1 	/*Less than a day*/ /*KECT - Chelsea added*/
	gen xtesttime_2	=q605<=2 	/*less than 2 days*/ 
	gen xtesttime_3 =q605<=3     /*less than 3 days*/ 
	}
	
	foreach var of varlist xtesttime*	{
		replace `var'=. if xtest!=1
		}
		
	gen xpcr 			= q603==1
	gen xpcr_capacity 	= q606/q607
	gen xpcr_equip		= q608==1
		
	foreach var of varlist xpcr_*	{
		replace `var'=. if xpcr!=1
		}	
		
		gen max=2
		egen temp =  rowtotal(xspcmitem_100 xtesttime_3 xpcr_equip)
	gen xdiagcovid_score = 100*(temp/max)
	gen xdiagcovid_100	= xdiagcovid_score >=100
	gen xdiagcovid_50	= xdiagcovid_score >=50
		drop max temp
	
	*****************************
	* Section 7: Equipment 
	*****************************
	///* KEYC edit begins *//
	gen yequip_ventilator 		= q701_003_002
	gen yequip_noninvventilator = q701_004_002
	
		lab var yequip_ventilator "number of functioning equipment: ventilator"
		lab var yequip_noninvventilator "number of functioning equipment: non-invasive ventilator"
		
	global itemlist "001 002 003 004"
	foreach item in $itemlist{	
		gen xequip_anyfunction__`item' = q701_`item'_002>=1 
		}			
		
		gen max=4
		egen temp=rowtotal(xequip_anyfunction_*)
	gen xequip_anyfunction_score	=100*(temp/max)
	gen xequip_anyfunction_100		=xequip_anyfunction_score>=100
	gen xequip_anyfunction_50		=xequip_anyfunction_score>=50
		drop max temp				
				
	global itemlist "001 002 003 004"
	foreach item in $itemlist{	
		gen xequip_allfunction__`item' = q701_`item'_002>=1 & (q701_`item'_002 == q701_`item'_001)
		}			
		
		gen max=4
		egen temp=rowtotal(xequip_allfunction_*)
	gen xequip_allfunction_score	=100*(temp/max)
	gen xequip_allfunction_100		=xequip_allfunction_score>=100
	gen xequip_allfunction_50		=xequip_allfunction_score>=50
		drop max temp				
	
	global itemlist "003 004"
	foreach item in $itemlist{	
		gen xequip_anymalfunction__`item' = q701_`item'_001>=1 & (q701_`item'_002 != q701_`item'_001)
		}			

		egen temp=rowtotal(xequip_anymalfunction__003 xequip_anymalfunction__004)
	gen xequip_anymalfunction=temp>=1
		drop temp
		
		drop xequip_anymalfunction__*
	
	/*	
	global itemlist "001 002 003 004 005"
	foreach item in $itemlist{	
		gen xequip_allmalfunction__`item' = q701_`item'_002==0 & (q701_`item'_003>=1 & q701_`item'_003!=.)
		}			

		egen temp=rowtotal(xequip_allmalfunction_*)
	gen xequip_allmalfunction=temp==5
		drop temp		
	*/
	
	global itemlist "001 002 003 004 005 "
	foreach item in $itemlist{	
		gen xequip_malfunction_reason__`item' = q702_`item'==1 | q703_`item'==1 
		}
	
		foreach var of varlist xequip_malfunction_reason__*{
			replace `var'=. if xequip_anymalfunction!=1
			}
	
	gen xoxygen_concentrator= q704_001==1 
	gen xoxygen_bulk 		= q704_002==1 
	gen xoxygen_cylinder	= q704_003==1 
	gen xoxygen_plant 		= q704_004==1   
	
	gen xoxygen_dist 		= q705==1
	gen xoxygen_dist__er 		= q706_001==1
	gen xoxygen_dist__icu 		= q706_002==1
	gen xoxygen_dist__iso 		= q706_003==1
	
		egen temp=rowtotal(xoxygen_dist__*)
	gen xoxygen_dist_all 		= temp==3  /*piped oxygen distribution in ER, ICU, AND isolation room*/
	gen xoxygen_dist_any 		= temp==3  /*piped oxygen distribution in ER, ICU, OR isolation room*/
	
	gen xocygen_portcylinder	= q707==1
	
	global itemlist "001 002 003 004 "
	foreach item in $itemlist{	
		gen xo2__`item'= q708_`item' ==1 
		}				
		rename xo2__001 xo2__cannula
		rename xo2__002 xo2__mask
		rename xo2__003 xo2__humidifier		
		rename xo2__004 xo2__flowmeter
		
	///* KE edit ends *///

		
	*****************************
	* Section 8: vaccine
	*****************************

	gen xvac= q801==1 | q802==1
	
	gen xvac_av_fridge 		= q803==1 | q803==2
	gen xvac_avfun_fridge 	= q803==1 
	gen xvac_avfun_fridgetemp 	= q803==1 & q804==1
	
	gen xvac_av_coldbox	= q805==1
	
	gen xvac_avfun_coldbox_all		= q805==1 & (q806>=1 & q806!=.) & q807==1
	gen xvac_avfun_coldbox_all_full	= q805==1 & (q806>=1 & q806!=.) & q807==1 & q811==1
	
	gen yvac_avfun_coldbox_all		= q806 if xvac_avfun_coldbox_all==1
	gen yvac_avfun_coldbox_all_full	= q806 if xvac_avfun_coldbox_all==1 & q811==1
	
	gen xvac_av_carrier	= q808==1
	
	gen xvac_avfun_carrier_all		= q808==1 & (q809>=1 & q809!=.) & q810==1	
	gen xvac_avfun_carrier_all_full	= q808==1 & (q809>=1 & q809!=.) & q810==1 & q811==1	
	
	gen yvac_avfun_carrier_all		= q809 if xvac_avfun_carrier_all==1
	gen yvac_avfun_carrier_all_full	= q809 if xvac_avfun_carrier_all==1 & q811==1

	gen xvac_av_outreach = xvac_av_coldbox ==1 | xvac_av_carrier ==1  
	gen xvac_avfun_outreach_all_full = xvac_avfun_coldbox_all_full ==1 | xvac_avfun_carrier_all_full==1  
	
	gen xvac_sharp = q812==1
	
	foreach var of varlist xvac_av* yvac_av*{
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
/*KEYC edit : no sampling weight in Kenya. This section not relevant for Kenya 	
import excel "$chartbookdir\KEN_Hospital_Chartbook.xlsx", sheet("Weight") firstrow clear
	rename *, lower
	sort facilitycode
	merge facilitycode using COVID19HospitalReadiness_`country'_R`round'.dta, 
	
		tab _merge
		drop _merge*
		
	sort id /*this is generated from Lime survey*/
	save COVID19HospitalReadiness_`country'_R`round'.dta, replace 			
*/	

	gen weight=1 /*KEYC edit : create weight=1 to make the program run*/
	
*****E.4. Export clean facility-level data to chart book 

	gen test2="$date" /*KEYC: delete this line after confirming program running correctly*/
	
	save COVID19HospitalReadiness_`country'_R`round'.dta, replace 		

	export delimited using COVID19HospitalReadiness_`country'_R`round'.csv, replace 

	export excel using "$chartbookdir\KEN_Hospital_Chartbook.xlsx", sheet("Facility-level cleaned data") sheetreplace firstrow(variables) nolabel
						
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
	
	save temp.dta, replace 
	
*****F.1. Calculate estimates  /*KEYC - revise to include yequip once section 7 is cleared*/

	use temp.dta, clear
	collapse (count) obs* (mean) x* (sum) ybed* ypt*  yequip* yvac*  [iweight=weight], by(country round month year  )
		gen group="All"
		keep obs* country round month year  group* x* y*
		save summary_COVID19HospitalReadiness_`country'_R`round'.dta, replace 
		
	use temp.dta, clear
	collapse (count) obs* (mean) x* (sum) ybed* ypt*  yequip* yvac*  [iweight=weight], by(country round month year   zurban)
		gen group="Location"
		gen grouplabel=""
			replace grouplabel="1.1 Rural" if zurban==0
			replace grouplabel="1.2 Urban" if zurban==1
		keep obs* country round month year  group* x* y*
		
		append using summary_COVID19HospitalReadiness_`country'_R`round'.dta, force
		save summary_COVID19HospitalReadiness_`country'_R`round'.dta, replace 

	use temp.dta, clear
	collapse (count) obs* (mean) x* (sum) ybed* ypt*  yequip* yvac*  [iweight=weight], by(country round month year   zlevel_hospital)
		gen group="Level"
		gen grouplabel=""
			replace grouplabel="2.1 Level 2-3 facilities" if zlevel_hospital==0
			replace grouplabel="2.2 Level 4-6 facilities" if zlevel_hospital==1
		keep obs* country round month year  group* x* y*
			
		append using summary_COVID19HospitalReadiness_`country'_R`round'.dta
		save summary_COVID19HospitalReadiness_`country'_R`round'.dta, replace 
		
	use temp.dta, clear
	collapse (count) obs* (mean) x* (sum) ybed* ypt*  yequip* yvac*  [iweight=weight], by(country round month year   zpub)
		gen group="Sector"
		gen grouplabel=""
			replace grouplabel="3.1 Non-public" if zpub==0
			replace grouplabel="3.2 Public" if zpub==1
		keep obs* country round month year  group* x* y*
		
		append using summary_COVID19HospitalReadiness_`country'_R`round'.dta		
		save summary_COVID19HospitalReadiness_`country'_R`round'.dta, replace 
		
	use temp.dta, clear
	collapse (count) obs* (sum) ybed* [iweight=weight], by(country round month year   zcounty)
		gen group="County"
		gen grouplabel=zcounty 
		keep obs* country round month year  group* y*
				
		append using summary_COVID19HospitalReadiness_`country'_R`round'.dta		
		save summary_COVID19HospitalReadiness_`country'_R`round'.dta, replace 
		
	use temp.dta, clear
	collapse (count) obs* (sum) ybed* [iweight=weight], by(country round month year   zcounty zlevel)
		gen group="County and Facility level"
		catenate grouplabel = zcounty zlevel, p(-) 
		keep obs* country round month year  group* y*
				
		append using summary_COVID19HospitalReadiness_`country'_R`round'.dta		
		save summary_COVID19HospitalReadiness_`country'_R`round'.dta, replace 	
			
	foreach var of varlist x*{
		replace `var'=round(`var'*100, 1)	
		}
		
	foreach var of varlist xocc* xcovid_occ* xnrshift* xpcr_capacity *score{
		replace `var'=round(`var'/100, 1)	
		}		
	
	tab group round, m

	* organize order of the variables by section in the questionnaire  
	order country round year month group grouplabel obs* 
		
	sort country round grouplabel
	
save summary_COVID19HospitalReadiness_`country'_R`round'.dta, replace 

export delimited using summary_COVID19HospitalReadiness_`country'_R`round'.csv, replace 

*****F.2. Export indicator estimate data to chartbook AND dashboard

use summary_COVID19HospitalReadiness_`country'_R`round'.dta, clear

	gen updatedate = "$date"

	local time=c(current_time)
	gen updatetime=""
	replace updatetime="`time'"

export excel using "$chartbookdir\KEN_Hospital_Chartbook.xlsx", sheet("Indicator estimate data") sheetreplace firstrow(variables) nolabel keepcellfmt
export delimited using "C:\Users\YoonJoung Choi\Dropbox\0 iSquared\iSquared_WHO\ACTA\4.ShinyApp\summary_COVID19HospitalReadiness_`country'_R`round'.csv", replace 

erase temp.dta

END OF DATA CLEANING AND MANAGEMENT 

