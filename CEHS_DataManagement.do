clear
clear matrix
clear mata
capture log close
set more off
numlabel, add

*This code 
*1) imports and cleans Continuity of EHS dataset from Lime Survey, 
*2) creates field check tables for data quality monitoring, and 
*3) creates indicator estimate data for dashboards and chartbook. 

*  DATA IN:	CSV file daily downloaded from Limesurvey 	
*  DATA OUT to chartbook: 
*		1. raw data (as is, downloaded from Limesurvey) in Chartbook  	
*		2. cleaned data with additional analytical variables in Chartbook and, for further analyses, as a datafile 
*		3. summary estimates of indicators in Chartbook and, for dashboards, as a datafile 	

*THREE parts must be updated per country-specific adaptation. See "MUST BE ADAPTED" below 

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
*****E.2. Construct analysis variables <<<<<<<<<<========== MUST BE ADAPTED: 3. country specific staffing - section 2 
*****E.3. Merge with sampling weight 
*****E.4. Export clean Respondent-level data to chart book 
* F. Create and export indicator estimate data 
*****F.1. Calculate estimates 
*****F.2. Export indicator estimate data to chart book 


**************************************************************
* A. SETTING 
**************************************************************

*** Directory for this do file and a subfolder for "daily exported CSV file from LimeSurvey"  
cd "C:\Users\YoonJoung Choi\Dropbox\0 iSquared\iSquared_WHO\ACTA\3.AnalysisPlan\"

*** Define a directory for the chartbook, if different from the main directory 
global chartbookdir "C:\Users\YoonJoung Choi\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards\"

*** Define local macro for the survey 
local country	 		 COUNTRYNAME /*country name*/	
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

import delimited ExportedCSV_FromLimeSurvey\LimeSurvey_CEHS_GreecePilot_R1.csv, case(preserve) clear 
	
	export excel using "$chartbookdir\WHO_CEHS_Chartbook.xlsx", sheet("Facility-level raw data") sheetreplace firstrow(variables) nolabel

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
	
**************************************************************
* C. Destring and recoding 
**************************************************************

*****C.1. Change var names to lowercase
 
	rename *, lower
	
*****C.2. Change var names to drop odd elements "y" "sq" - because of Lime survey's naming convention 
	
	rename (*y) (*) /*when y is at the end */
	rename (*y*) (**) /*when y is in the middle */
	rename (*sqsq*) (*sq*) /*when sq is repeated - no need to */
	rename (*sq) (*) /*when ending with sq - no need to */

	rename (*_sq*) (*_*) /*replace sq with _*/
	rename (*sq*) (*_*) /*replace sq with _*/
	
*****C.3. Find non-numeric variables and desting 

	*****************************
	* Section 1
	*****************************
	sum q1*
	codebook q104 q105 q106 q114 q116*
		
	foreach var of varlist q104 q105 q106 q118*{	
		replace `var' = usubinstr(`var', "A", "", 1) 
		replace `var' = "88" if `var'=="-oth-"
		destring `var', replace 
		}
				
	*****************************	
	* Section 2
	*****************************
	sum q2*
	codebook q203_012 q204 q205other q208
		
	foreach var of varlist q204{	
		replace `var' = usubinstr(`var', "A", "", 1) 
		replace `var' = "88" if `var'=="-oth-"
		destring `var', replace 
		}	
		
	*****************************	
	* Section 3
	*****************************
	sum q3*
	codebook q303 q309 q311
		
	foreach var of varlist q309 {	
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}		
		
	*****************************	
	* Section 4
	*****************************
	sum q4*
	
	codebook q409* q412* q414 q415 q417* q420* 
	
	*foreach var of varlist q409* q412* q414 q415 q417* q420* q422* {	
	foreach var of varlist q409* q412* q414 q415 q417* q420*  {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	
		
	gen RAWq410_006 = q410_006	
		replace q410_006 = "1" if q410_006!=""
		replace q410_006 = "0" if q410_006==""
		destring q410_006, replace
		
	gen RAWq411_012 = q411_012	
		replace q411_012 = "1" if q411_012!=""
		replace q411_012 = "0" if q411_012==""
		destring q411_012, replace		
	
	*****************************
	* Section 5
	*****************************
	sum q5*	
	codebook q507* 
	
	foreach var of varlist q507* {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	
		
	*****************************	
	* Section 6		
	*****************************	
	
	
	*****************************
	* Section 7
	*****************************
	sum q7*
		
	foreach var of varlist q701* q702* q703* {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}			
		
	*****************************	
	* Section 8
	*****************************
	sum q8*
		
	foreach var of varlist q805* q806* q807* q808* q810* q811* {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}			
	 		
	*****************************		
	* Section 9
	*****************************
	sum q9*
	codebook q907 q911
		
	foreach var of varlist q907 q910 q911 {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}			
		
	*****************************			
	* Section 11: interview results
	*****************************
	sum q110*
	codebook q110*
				
*****C.4. Recode yes/no & yes/no/NA

	#delimit;
	sum
		q202  q205_* q206  q207* 
		q301  q303  q304  q307  q308  q310
		q401- q405  q406* q407  q408  q410* q411* q416 q418 q419 q421
		q501  q502  q503* q504  q505* q506
		q601  q602  q603  q605  q606  q607* q608* q609 q610 q612-q617
		q701* q702* q703* q704
		q801- q804  q805* q807* q810* 
		q901- q902  q905  q908 ; 
		#delimit cr
	
	#delimit;
	foreach var of varlist 
		q202  q205_* q206  q207* 
		q301  q303  q304  q307  q308  q310
		q401- q405  q406* q407  q408  q410* q411* q416 q418 q419 q421
		q501  q502  q503* q504  q505* q506
		q601  q602  q603  q605  q606  q607* q608* q609 q610 q612-q617
		q701* q702* q703* q704
		q801- q804  q805* q807* q810* 
		q901- q902  q905  q908 {; 
		#delimit cr		
		recode `var' 2=0 /*no*/
		}

	sum q204 q309 q806* q808* q811*
		
	foreach var of varlist q204 q309 q806* q808* q811* {		
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
	
	lab define q302
		1"1. Yes – user fees exempted only for COVID-19 services"
		2"2. Yes – user fees exempted only for other health services"
		3"3. Yes – user fees exempted for both COVID-19 and other health services"
		4"4. No"; 
	lab values q302 q302; 
	
	lab define q305
		1"1. Yes – for COVID-19 case management services"
		2"2. Yes – for other essential health services"
		3"3. No"
		4"4. Do not know"; 
	lab values q305 q305; 
	
	lab define q306
		1"1.Government"
		2"2.Local community"
		3"3.International organization" 
		4"4.Private" 
		5"5.Do not know";
	lab values q306 q306; 
	
	lab define change
		1"1.Yes, increased"
		2"2.Yes, decreased"
		3"3.No" 
		4"4.N/A";  
	foreach var of varlist q409* q412* q414 q415 q417* q420*{;
	lab values `var' change;	
	};
	
	lab define q417
		1"1.Yes, less frequent"
		2"2.Yes, suspended"
		3"3.No" 
		4"4.N/A";  
	foreach var of varlist q417* {;
	lab values `var' q417;	
	};	
	
	lab define q420
		1"1.Yes, planned & implemented"
		2"2.Yes, planned but not yet implemented"
		3"3.No" 
		4"4.N/A";  
	foreach var of varlist q420* {;
	lab values `var' q420;	
	};	
	
	lab define q422
		1"1.Not at all"	
		2"2.Slightly" 	
		3"3.Moderately" 	
		4"4.Quite a lot"	
		5"5.A great deal";  
	foreach var of varlist q422* {;
	lab values `var' q422;	
	};		

	lab define ppe
		1"1.Currently available for all health workers"
		2"2.Currently available only for some health workers"
		3"3.Currently unavailable for any health workers"
		4"4.Not applicable – never procured or provided" ;
	foreach var of varlist q507* {;
	lab values `var' ppe;	
	};		
	
	lab define q604
		1"1.Yes, PCR"
		2"2.Yes, RDT"
		3"3.No";
	lab values q604 q604;	

	lab define availfunc 
		1"1.Yes, functional"
		2"2.Yes, but not functional"
		3"3.No";
	foreach var of varlist q903 q904  {;
	lab values `var' availfunc ;	
	};			

	lab define icepack 
		1"1.Yes, a set of ice packs for all cold boxes"
		2"1.Yes, a set of ice packs only for some cold boxes"
		3"3.No";
	foreach var of varlist q907 q910  {;
	lab values `var' icepack ;	
	};		
	
	lab define icepackfreeze 
		1"1.All"
		2"2.Only some"
		3"3.None-no ice packs"
		4"4.None-no functional freezer" ;
	lab values q911 icepackfreeze ;	
		
	lab define yesno 1"1. yes" 0"0. no"; 	
	#delimit;
	foreach var of varlist 
		q115 q118* 
		q202  q205_* q206  q207* 
		q301  q303  q304  q307  q308  q310
		q401- q405  q406* q407  q408  q410* q411* q416 q418 q419 q421
		q501  q502  q503* q504  q505* q506
		q601  q602  q603  q605  q606  q607* q608* q609 q610 q612-q617
		q701* q702* q703* q704
		q801- q804  q805* q807* q810* 
		q901- q902  q905  q908 {;		
	labe values `var' yesno; 
	};	

	lab define yesnona 1"1. yes" 0"0. no"; 
	foreach var of varlist q204 q309 q806* q808* q811* {;		
	labe values `var' yesnona; 
	};
	
	#delimit cr

**************************************************************
* D. Create field check tables for data quality check  
**************************************************************

* generates daily field check tables in excel

preserve

			gen updatedate = "$date"
	
	tabout updatedate using "$chartbookdir\FieldCheckTable_CEHS_`country'_ `round'_$date.xls", replace ///
		cells(freq col) h2("Date of field check table update") f(0 1) clab(n %)

			split submitdate_string, p(" ")
			gen date=date(submitdate_string1, "MDY") 
			format date %td
						
	tabout submitdate_string1 using "$chartbookdir\FieldCheckTable_CEHS_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("Date of interviews (submission date, final)") f(0 1) clab(n %)
			
			gen xresult=q1101
				replace xresult=1 /*DELETE this line with real data*/
				
			gen byte responserate= xresult==1
			label define responselist 0 "Not complete" 1 "Complete"
			label val responserate responselist

	tabout responserate using "$chartbookdir\FieldCheckTable_CEHS_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("Interview response rate") f(0 1) clab(n %)
	
	tabout q104 using "$chartbookdir\FieldCheckTable_CEHS_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("Number of completed interviews by area") f(0 1) clab(n %)
		
	tabout q105 using "$chartbookdir\FieldCheckTable_CEHS_`country'_ `round'_$date.xls", append ///
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

	tabout time xresult using "$chartbookdir\FieldCheckTable_CEHS_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("Interview length (minutes): incomplete, complete, and total interviews") f(0 1) clab(n %)	
	tabout time_complete using "$chartbookdir\FieldCheckTable_CEHS_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("Average interview length (minutes), among completed interviews") f(0 1) clab(n %)		
	tabout time_incomplete using "$chartbookdir\FieldCheckTable_CEHS_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("Average interview length (minutes), among incomplete interviews") f(0 1) clab(n %)	

keep if xresult==1 /*the following calcualtes % missing in select questions among completed interviews*/		
		
			capture drop missing
			gen missing=0
			foreach var of varlist q116 q117 {	
				replace missing=1 if `var'==.
				replace missing=. if q115!=1
				}		
			lab values missing yesno
			
	tabout missing using "$chartbookdir\FieldCheckTable_CEHS_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("1. Missing number of beds when facility provides inpatient services (among completed interviews)") f(0 1) clab(n %)					

			capture drop missing
			gen missing=0
			foreach var of varlist q201_002_001 q201_002_002 {	
				replace missing=1 if `var'==.
				}		
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_CEHS_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("2. Missing number of nurses (either the total number or the number who have been infected) (among completed interviews)") f(0 1) clab(n %)					

			capture drop missing
			gen missing=0
			foreach var of varlist q307 {	
				replace missing=1 if `var'==.
				}		
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_CEHS_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("3. Missing salary payment ontime (among completed interviews)") f(0 1) clab(n %)					
		
			capture drop missing
			gen missing=0
			foreach var of varlist q406_* {	
				replace missing=1 if `var'==.
				}		
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_CEHS_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("4. Missing service strategy change (among completed interviews)") f(0 1) clab(n %)							
		
			capture drop missing
			gen missing=0
			foreach var of varlist q409_* {	
				replace missing=1 if `var'==.
				}		
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_CEHS_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("5. Missing OPT service volume change (among completed interviews)") f(0 1) clab(n %)							
		
			capture drop missing
			gen missing=0
			foreach var of varlist q420_* {	
				replace missing=1 if `var'==.
				}		
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_CEHS_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("6. Missing catch-up/restroation (among completed interviews)") f(0 1) clab(n %)							
			
			capture drop missing
			gen missing=0
			foreach var of varlist q507_* {	
				replace missing=1 if `var'==.
				}		
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_CEHS_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("7. Missing PPE availability (among completed interviews)") f(0 1) clab(n %)							
			
			*REVISE CODE FOR SECTION 6 VARIABLES
			capture drop missing
			gen missing=0
			foreach var of varlist q605 {	
				replace missing=1 if `var'==. & q604==4
				*replace missing=. if q604!=4 
				}		
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_CEHS_`country'_ `round'_$date.xls", append ///
		cells(freq col) h2("8. Missing specimen transportation systems (among completed interviews)") f(0 1) clab(n %)							
	
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
			
		local maxtrainingsupport 8 /*total number of training/support items asked in q207*/

		local maxdrug 			 17 /*total medicines asked in q701*/
	
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
	lab var facilitycode "facility ID from sample list" /*this will be used to merge with sampling weight, if relevant*/
	
	*****************************
	* Section 2: staffing 
	*****************************
	
	egen staff_num_total_md=rowtotal(q201_001_001)
	egen staff_num_covid_md=rowtotal(q201_001_002)
	
	egen staff_num_total_nr=rowtotal(q201_002_001)
	egen staff_num_covid_nr=rowtotal(q201_002_002)

	egen staff_num_total_mw=rowtotal(q201_003_001)
	egen staff_num_covid_mw=rowtotal(q201_003_002)

	egen staff_num_total_co=rowtotal(q201_004_001)
	egen staff_num_covid_co=rowtotal(q201_004_002)

	egen staff_num_total_othclinical=rowtotal(q201_003_001 q201_004_001 q201_005_001 q201_006_001 q201_007_001 )
	egen staff_num_covid_othclinical=rowtotal(q201_003_002 q201_004_002 q201_005_002 q201_006_002 q201_007_002 )
	
	egen staff_num_total_clinical=rowtotal(staff_num_total_md staff_num_total_nr staff_num_total_othclinical)
	egen staff_num_covid_clinical=rowtotal(staff_num_covid_md staff_num_covid_nr staff_num_covid_othclinical)
	
	egen staff_num_total_nonclinical=rowtotal(q201_008_001 q201_009_001 q201_010_001 )
	egen staff_num_covid_nonclinical=rowtotal(q201_008_002 q201_009_002 q201_010_002 )
	
	egen staff_num_total_all=rowtotal(staff_num_total_clinical staff_num_total_nonclinical) 
	egen staff_num_covid_all=rowtotal(staff_num_covid_clinical staff_num_covid_nonclinical) 	
	
	gen xabsence=q202==1
	gen xabsence_medical=	q203_003==1 | q203_004==1 
	gen xabsence_structure=	q203_005==1 | q203_006==1 | q203_007==1 
	gen xabsence_social=	q203_008==1 | q203_009==1 | q203_010==1 
			
	gen xhr=q204==1
	gen xhr_shift=		q205_001==1
	gen xhr_increase=	q205_002==1 | q205_003==1 | q205_004==1 | q205_005==1 | q205_006==1 
	gen xhr_increase_exp=	q205_002==1 | q205_003==1 
	gen xhr_increase_new=	q205_004==1 | q205_005==1 | q205_006==1 
	gen xhr_secondment=	q205_007==1
	gen xhr_decrease=	q205_008==1
	
	gen xtraining=q206==1
	global itemlist "001 002 003 004 005 006 007 008"
	foreach item in $itemlist{	
		gen byte xtraining__`item' = q207_`item' ==1
		}		
		
		gen max=4
		egen temp=rowtotal(xtraining__001 xtraining__002 xtraining__003 xtraining__004)
	gen xtraining_score	=100*(temp/max)
	gen xtraining_100 	=xtraining_score>=100
	gen xtraining_50 	=xtraining_score>=50
		drop max temp

		gen max=`maxtrainingsupport'
		egen temp=rowtotal(xtraining__*)
	gen xtrainingsupport_score	=100*(temp/max)
	gen xtrainingsupport_100	=xtrainingsupport_score>=100
	gen xtrainingsupport_50 	=xtrainingsupport_score>=50
		drop max temp		

	/*
	foreach var of varlist xabsence_*{
		replace `var'=, if xabsence!=1
		}
		
	foreach var of varlist xhr_*{
		replace `var'=, if xhr!=1
		}
		
	foreach var of varlist xtraining_* xtrainingsupport_*{
		replace `var'=, if xtraining!=1
		}	
	*/	
		
	sum staff* xabsence* xhr* xtraining* 	

	*****************************
	* Section 3: finance
	*****************************
	
	gen xuserfee=		q301==1
	gen xexempt= 		q302==1 | q302==2 | q302==3 | q303==1
	gen xexempt_covid= 	q302==1 | q302==3
	gen xexempt_other= 	q302==2 | q302==3	
	gen xexempt_vulnp= 	q303==1 
	gen xfeeincrease= 	q304==1 
		
		foreach var of varlist xexempt* xfee{
			replace `var'=. if xuserfee!=1
			}
		
	gen xaddfund = q305==1 | q305==2
	gen xaddfund_gov = q306==1 
	gen xaddfund_other = q306>=2 & q306!=. 

		/*
		foreach var of varlist xaddfund_*{
			replace `var'=. if xaddfund!=1
			}
		*/
		
	gen xfinance_salaryontime 	= q307==1
	gen xfinance_ot 			= q308==1 
	gen xfinance_otontime 	= q309==1 | q309==3
		replace xfinance_otontime = . if xfinance_ot==0
		
	gen xfinance_ontime = xfinance_salaryontime ==1 & (xfinance_otontime==1 | xfinance_otontime==.)
		
	sum xuserfee xexempt* xfee xaddfund* xfinance*
	
	*****************************
	* Section 4: service delivery & utlization  
	*****************************
			
		egen temp=rowtotal(q402 q403 q406*)
	gen xstrategy= temp>=1
		drop temp	
	
	gen xstrategy_reduce= 	q402==1  | q403==1  | q406_001==1 | q406_002==1 | q406_003==1 | q406_004==1 | q406_005==1
	gen xstrategy_reduce_closure= 	q402==1  
	gen xstrategy_reduce_hrchange= 	q403==1  | q406_001==1 | q406_002==1 | q406_003==1 | q406_004==1 | q406_005==1
	gen xstrategy_reduce_reduce= 	q406_001==1 | q406_002==1 | q406_003==1
	gen xstrategy_reduce_redirect= 	q406_004==1
	gen xstrategy_reduce_priority= 	q406_005==1
	gen xstrategy_self= 	q406_007==1
	gen xstrategy_home= 	q406_008==1
	gen xstrategy_remote= 	q406_009==1 
	gen xstrategy_prescription= 	q406_010==1 | q406_011==1 | q406_012==1 
	
	*** Referral/transportation for COVID patients 
	
	gen xcvd_ref		= q407==1	 
	gen xcvd_reftrans	= q407==1 | q408==1	 	 	
	
	***** OPT
	
	global itemlist "001 002 003 004 005 006 007 008 009 010 011 012 013 014 015 016 017 018" 
	foreach item in $itemlist{	
		gen xopt_increase__`item' = q409_`item'==1
		}		
	
	global itemlist "001 002 003 004 005 006 007 008 009 010 011 012 013 014 015 016 017 018" 
	foreach item in $itemlist{	
		gen xopt_decrease__`item' = q409_`item'==2
		}		
		
	global itemlist "001 002 003 004 005 006 007 008 009 010 011 012 013 014 015 016 017 018" 
	foreach item in $itemlist{	
		gen xopt_nochange__`item' = q409_`item'==3
		}		
		
	global itemlist "xopt" 
	foreach item in $itemlist{	
		egen `item'_increase_num=rowtotal(`item'_increase__*) 
		egen `item'_decrease_num=rowtotal(`item'_decrease__*) 
		egen `item'_nochange_num=rowtotal(`item'_nochange__*) 
		gen `item'_increase= `item'_increase_num>=1
		gen `item'_decrease= `item'_decrease_num>=1			
		
		gen  `item'_change=.
			replace `item'_change=1 if `item'_decrease==0 & `item'_increase==0 /*no change in any*/
			replace `item'_change=2 if `item'_decrease==1 & `item'_increase==1 /*mixed*/
			replace `item'_change=3 if `item'_decrease==1 & `item'_increase==0 /*no service volume increased + at least one decreased*/
			replace `item'_change=4 if `item'_decrease==0 & `item'_increase==1 /*no service volume decreased + at least one increased*/
		
		}				
		
		***** OPT BY GROUP OF SERVICES: RMCH Preventive 
		
		global itemlist "002 003 004 005" 
		foreach item in $itemlist{	
			gen xopt_prv_increase__`item' = q409_`item'==1
			}		
		
		global itemlist "002 003 004 005" 
		foreach item in $itemlist{	
			gen xopt_prv_decrease__`item' = q409_`item'==2
			}		
			
		global itemlist "002 003 004 005" 
		foreach item in $itemlist{	
			gen xopt_prv_nochange__`item' = q409_`item'==3
			}				

		***** OPT BY GROUP OF SERVICES: Infectious diseases
		
		global itemlist "001 006 007 008 009 010"
		foreach item in $itemlist{	
			gen xopt_inf_increase__`item' = q409_`item'==1
			}		
		
		global itemlist "001 006 007 008 009 010"
		foreach item in $itemlist{	
			gen xopt_inf_decrease__`item' = q409_`item'==2
			}		
			
		global itemlist "001 006 007 008 009 010"
		foreach item in $itemlist{	
			gen xopt_inf_nochange__`item' = q409_`item'==3
			}	
		
		***** OPT BY GROUP OF SERVICES: NCD
		
		global itemlist "011 012 013 014" 
		foreach item in $itemlist{	
			gen xopt_ncd_increase__`item' = q409_`item'==1
			}		
		
		global itemlist "011 012 013 014" 
		foreach item in $itemlist{	
			gen xopt_ncd_decrease__`item' = q409_`item'==2
			}		
			
		global itemlist "011 012 013 014" 
		foreach item in $itemlist{	
			gen xopt_ncd_nochange__`item' = q409_`item'==3
			}	
	
	global itemlist "xopt_prv xopt_inf xopt_ncd" 
	foreach item in $itemlist{	
		egen `item'_increase_num=rowtotal(`item'_increase__*) 
		egen `item'_decrease_num=rowtotal(`item'_decrease__*) 
		egen `item'_nochange_num=rowtotal(`item'_nochange__*) 
		gen  `item'_increase= `item'_increase_num>=1
		gen  `item'_decrease= `item'_decrease_num>=1	
		
		gen  `item'_change=.
			replace `item'_change=1 if `item'_decrease==0 & `item'_increase==0 /*no change in any*/
			replace `item'_change=2 if `item'_decrease==1 & `item'_increase==1 /*mixed*/
			replace `item'_change=3 if `item'_decrease==1 & `item'_increase==0 /*no service volume increased + at least one decreased*/
			replace `item'_change=4 if `item'_decrease==0 & `item'_increase==1 /*no service volume decreased + at least one increased*/
		}				
		
	lab define groupchange 1"no change" 2"mixed" 3"no increase + at least one decrease" 4"no decrease + at least one increase" 
	foreach var of varlist xopt_change xopt_prv_change xopt_inf_change xopt_ncd_change{
	lab values `var' groupchange
	}
	
	tab xopt_prv_change
	tab xopt_inf_change
	tab xopt_ncd_change
	
	drop xopt_prv_increase__* xopt_prv_decrease__* xopt_prv_nochange__*
	drop xopt_inf_increase__* xopt_inf_decrease__* xopt_inf_nochange__*
	drop xopt_ncd_increase__* xopt_ncd_decrease__* xopt_ncd_nochange__*
	
	***** REASONS for OPT volume changes
					
	global itemlist "001 002 003 004 005 006"
	foreach item in $itemlist{	
		gen xopt_increase_reason__`item' = q410_`item'
		recode xopt_increase_reason__`item'  .= 0
		}
		
	global itemlist "001 002 003 004 005 006 007 008 009 010 011 012" 
	foreach item in $itemlist{			
		gen xopt_decrease_reason__`item' = q411_`item'
		recode xopt_decrease_reason__`item'  .= 0
		}

	global varlist "xopt_increase "
	foreach var in $varlist {
		gen `var'_reason_covidnow 	= `var'_reason__001==1 | `var'_reason__002==1  
		gen `var'_reason_covidafter = `var'_reason__003==1 | `var'_reason__004==1 | `var'_reason__005==1 
		}		
		
	global varlist "xopt_decrease"
	foreach var in $varlist {
		gen `var'_reason_comdemand  = `var'_reason__001==1 | `var'_reason__002==1  
		gen `var'_reason_enviro 	= `var'_reason__003==1 | `var'_reason__004==1 
		gen `var'_reason_intention	= `var'_reason__006==1 | `var'_reason__007==1 | `var'_reason__008==1 | `var'_reason__009==1
		gen `var'_reason_disruption = `var'_reason__010==1 | `var'_reason__011==1 
		}
		
	***** ER
	
	gen xer = q118_001==1

	gen xer_increase= q412_001 ==1
	gen xer_decrease= q412_001 ==2
	gen xer_nochange= q412_001 ==3
	
		foreach var of varlist xer_*{
			replace `var'=. if xer==0
			}	
	
	global itemlist "002 003 004 005"
	foreach item in $itemlist{	
		gen xer_increase__`item' = q412_`item'==1
		
		replace xer_increase__`item' = . if xer==0
		*replace xer_increase__`item' = . if q412_`item'==4
		}
		
	global itemlist "002 003 004 005"
	foreach item in $itemlist{	
		gen xer_decrease__`item' = q412_`item'==2

		replace xer_decrease__`item' = . if xer==0
		*replace xer_decrease__`item' = . if q412_`item'==4		
		}		
	
	***** IPT 
	
	gen xipt = q115==1
	
	gen xbed = q116
	gen xbedrate = q413
	
	gen xipt_increase = q414==1
	gen xipt_decrease = q414==2
	gen xipt_nochange = q414==3

		foreach var of varlist xbed* xipt_*{
			replace `var'=. if xipt==0
			}
		
	***** Pre hospital ER
	
	gen xpreer = q414<=3
	
	gen xpreer_increase = q415==1
	gen xpreer_decrease = q415==2
	gen xpreer_nochange = q415==3
	
		foreach var of varlist xpreer_*{
			replace `var'=. if xpreer==0
			}
			
	***** community outreach
	
	gen xout = q416==1
	
	global itemlist "001 002 003 004 005"
	foreach item in $itemlist{	
		gen xout_decrease__`item' = q417_`item'==1 |  q417_`item'==2
		}

	egen xout_decrease_num=rowtotal(xout_decrease__*) 
			
	gen xout_decrease= xout_decrease_num>=1	
	
		foreach var of varlist xout_*{
			replace `var'=. if xout==0
			}
	
	***** missed appointment 
	
	gen xresto = q418==1 & q419==1	
	gen xresto_imp_preg 	= q420_001==1 
	gen xresto_imp_immunization 	= q420_002==1 
	gen xresto_imp_chronic 	= q420_003==1 
	
	gen xresto_imppln_preg 			= q420_001==1 | q420_001==2
	gen xresto_imppln_immunization 	= q420_002==1 | q420_002==2
	gen xresto_imppln_chronic 		= q420_003==1 | q420_003==2 	
	
		foreach item in preg{
			replace xresto_imp_`item' =. if q420_001>=4
			replace xresto_imppln_`item' =. if q420_001>=4
			}	
		foreach item in immunization{
			replace xresto_imp_`item' =. if q420_002>=4
			replace xresto_imppln_`item' =. if q420_002>=4
			}	
		foreach item in chronic{
			replace xresto_imp_`item' =. if q420_003>=4
			replace xresto_imppln_`item' =. if q420_003>=4
			}				
	
	sum xstrategy* 
	sum xopt_increase xopt_increase_* xopt_increase_reason_* 
	sum xopt_decrease xopt_decrease_* xopt_decrease_reason_*
	sum xer xer_increase_* xer_increase xer_decrease_* xer_decrease
	sum xipt* xpreer*
	sum xout* xresto* 
		

	*****************************
	* Section 5: IPC 
	*****************************
	
	gen xipcpp= q501==1
	
	gen xsafe= q502==1
	global itemlist "001 002 003 004 005 006 007 008 009" 
	foreach item in $itemlist{	
		gen xsafe__`item' = q503_`item' ==1
		}		
	
		gen max=9
		egen temp = rowtotal(xsafe__*)
	gen xsafe_score	=100*(temp/max)
	gen xsafe_100 	=xsafe_score>=100
	gen xsafe_50 	=xsafe_score>=50
		drop max temp
			
	gen xguideline= q504
	global itemlist "001 002 003 004 005" 
	foreach item in $itemlist{	
		gen xguideline__`item' = q505_`item' ==1
		}		
		
		gen max=5
		egen temp=	rowtotal(xguideline__*)
	gen xguideline_score	=100*(temp/max)
	gen xguideline_100 		=xguideline_score>=100
	gen xguideline_50 		=xguideline_score>=50
		drop max temp
				
	gen xppe= q506
	global itemlist "001 002 003 004 005 006" 
	foreach item in $itemlist{	
		gen xppe_allsome__`item' = q507_`item'==1 | q507_`item'==2
		}	

		gen max=6
		egen temp=	rowtotal(xppe_allsome__*)
	gen xppe_allsome_score	=100*(temp/max)
	gen xppe_allsome_100 		=xppe_allsome_score>=100
	gen xppe_allsome_50 		=xppe_allsome_score>=50
		drop max temp
			
	global itemlist "001 002 003 004 005 006" 
	foreach item in $itemlist{	
		gen xppe_all__`item' = q507_`item'==1
		}						

		gen max=6
		egen temp=	rowtotal(xppe_all__*)
	gen xppe_all_score	=100*(temp/max)
	gen xppe_all_100 		=xppe_all_score>=100
	gen xppe_all_50 		=xppe_all_score>=50
		drop max temp
		
	sum xipc* xsafe* xguideline* xppe*

	*****************************
	* Section 7: Therapeutics
	*****************************

		gen max=`maxdrug'
		egen temp=rowtotal(q701_* )
	gen xdrug_score	=100*(temp/max)
	gen xdrug_100 	=xdrug_score>=100
	gen xdrug_50 	=xdrug_score>=50
		drop max temp
				
		gen max=3
		egen temp=rowtotal(q702_* )
	gen xsupp_score	=100*(temp/max)
	gen xsupp_100 	=xsupp_score>=100
	gen xsupp_50 	=xsupp_score>=50
		drop max temp
		
		gen max=5
		egen temp=rowtotal(q703_* )
	gen xvac_score	=100*(temp/max)
	gen xvac_100 	=xvac_score>=100
	gen xvac_50 	=xvac_score>=50
		drop max temp

	global itemlist "001 002 003 004 005 006 007 008 009 010 011 012 013 014 015 016 017" 
	foreach item in $itemlist{	
		gen xdrug__`item' = q701_`item' ==1
		}		
		
	global itemlist "001 002 003" 
	foreach item in $itemlist{	
		gen xsupply__`item' = q702_`item' ==1
		}	
		
	gen xvaccine_child=q409_005>=1 & q409_005<=3	
		
	global itemlist "001 002 003 004 005"
	foreach item in $itemlist{	
		gen xvaccine__`item' = q703_`item' ==1
		}	

	foreach var of varlist xvac_* xvaccine__*{	
		replace `var'	=. if xvaccine_child!=1 
		}		
		
	gen byte xdisrupt_supply = q704==1
		
	*****************************
	* Section 8: 
	*****************************
	
	gen xdiag=q804==1
	
	global itemlist "001 002 003 004 005"
	foreach item in $itemlist{	
		gen xdiag_av_a`item' 	= q805_`item'==1
		}	
		
	global itemlist "001 002 003 004 005"
	foreach item in $itemlist{	
		gen xdiag_avfun_a`item' = q805_`item'==1 & q806_`item'==1 
		}			
		
	gen xhospital = zlevel_hospital==1    	
		
	global itemlist "001 002 003 004 005"
	foreach item in $itemlist{	
		gen xdiag_av_h`item' 	= q807_`item'==1
		replace xdiag_av_h`item' 	= . if xhospital!=1 
		}		
		
	global itemlist "001 002 003 004 005"
	foreach item in $itemlist{	
		gen xdiag_avfun_h`item' = q807_`item'==1 & q808_`item'==1 
		replace xdiag_avfun_h`item' = . if xhospital!=1 
		}		
						
		gen max=5
		egen temp=rowtotal(xdiag_avfun_a*)
	gen xdiagbasic_score	=100*(temp/max)
	gen xdiagbasic_100 	=xdiagbasic_score>=100
	gen xdiagbasic_50 	=xdiagbasic_score>=50
		drop max temp	
		
		gen max=.
			replace max=5 if zlevel_hospital!=1 
			replace max=10 if zlevel_hospital==1 
		egen temp=rowtotal(xdiag_avfun_a* xdiag_avfun_h*)
	gen xdiag_score	=100*(temp/max)
	gen xdiag_100 	=xdiag_score>=100
	gen xdiag_50 	=xdiag_score>=50
		drop max temp				
		
	global itemlist "001 002 003"
	foreach item in $itemlist{	
		gen ximage_av_`item' 	= q810_`item'==1
		replace ximage_av_`item'	=. if xhospital!=1 
		}
		

	global itemlist "001 002 003"
	foreach item in $itemlist{	
		gen ximage_avfun_`item' = q810_`item'==1 & q811_`item'==1 
		replace ximage_avfun_`item' =. if xhospital!=1 
		}		
	
		gen max=3
		egen temp=rowtotal(ximage_avfun_*)
	gen ximage_score	=100*(temp/max)
	gen ximage_100 	=ximage_score>=100
	gen ximage_50 	=ximage_score>=50
		drop max temp	
	
	foreach var of varlist ximage*{	
		replace `var'	=. if xhospital!=1 
		}	
		
	*****************************
	* Section 9: vaccine
	*****************************
	
	gen xvac= q901==1 | q902==1
	
	gen xvac_av_fridge 		= q903==1 | q903==2
	gen xvac_avfun_fridge 	= q903==1 
	gen xvac_avfun_fridgetemp 	= q903==1 & q904==1
	
	gen xvac_av_coldbox	= q905==1
	
	gen xvac_avfun_coldbox_all	= q905==1 & (q906>=1 & q906!=.) & q907==1
	gen xvac_avfun_coldbox_all_full	= q905==1 & (q906>=1 & q906!=.) & q907==1 & q911==1
	
	gen yvac_avfun_coldbox_all	= q906 if xvac_avfun_coldbox_all==1
	gen yvac_avfun_coldbox_all_full	= q906 if xvac_avfun_coldbox_all==1 & q911==1
	
	gen xvac_av_carrier	= q908==1
	
	gen xvac_avfun_carrier_all	= q908==1 & (q909>=1 & q909!=.) & q910==1	
	gen xvac_avfun_carrier_all_full	= q908==1 & (q909>=1 & q909!=.) & q910==1 & q911==1	
	
	gen yvac_avfun_carrier_all	= q909 if xvac_avfun_carrier_all==1
	gen yvac_avfun_carrier_all_full	= q909 if xvac_avfun_carrier_all==1 & q911==1

	gen xvac_av_outreach = xvac_av_coldbox ==1 | xvac_av_carrier ==1  
	gen xvac_avfun_outreach_all_full = xvac_avfun_coldbox_all_full ==1 | xvac_avfun_carrier_all_full==1  
	
	foreach var of varlist xvac_av* {
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
	
	*****************************
	* Section 6: COVID management in primary care setting 
	*****************************	
	
	gen xcvd_team		=q601==1
	gen xcvd_sop		=q602==1
		
	gen xcvd_spcm		=q603==1
	gen xcvd_test		=q603==1 & q604<=3
	gen xcvd_test_pcr		=q603==1 & (q604==1 | q604==3)
	gen xcvd_test_rdt		=q603==1 & (q604==2 | q604==3)
	gen xcvd_spcmtrans		=q603==1 & q604==4 & q605==1
		
	gen xcvd_pt = q606==1

	global itemlist "001 002 003 004 005 006 007 "
	foreach item in $itemlist{	
		gen xcvd_pt__`item' 	= xcvd_pt==1 & q607_`item'==1
		}	
		
		gen max=3
		egen temp=rowtotal(xcvd_pt__001 xcvd_pt__002 xcvd_pt__003)
	gen xcvd_pt_score	=100*(temp/max)
	gen xcvd_pt_100 	=xcvd_pt_score>=100
	gen xcvd_pt_50 		=xcvd_pt_score>=50
		drop max temp	
	
	gen xcvd_ptmild = q607_006==1	
	
	global itemlist "001 002 003 004 005"
	foreach item in $itemlist{	
		gen xcvd_ptmild__`item' 	= xcvd_ptmild==1 & q608_`item'==1
		}	
			
	gen xcvd_guide_ptmild = q609==1				
	gen xcvd_info = q610==1	
	
	gen xcvd_info_moh 	= .
	gen xcvd_info_local	= .
	gen xcvd_info_who 	= .
	gen xcvd_info_prof 	= .
	gen xcvd_info_other	= .
	
	/*
	gen xcvd_info_moh 	= q610==1	& q611_001==1
	gen xcvd_info_local	= q610==1	& q611_002==1
	gen xcvd_info_who 	= q610==1	& q611_003==1
	gen xcvd_info_prof 	= q610==1	& q611_004==1
	gen xcvd_info_other	= q610==1	& q611_005==1
	*/
				
	*****************************
	* Annex
	*****************************

	global itemlist "001 002 003 004"
	foreach item in $itemlist{	
		gen vol_opt_now_`item' 	= qa1_002_`item'
		}
		
	global itemlist "005 006 007 008"
	foreach item in $itemlist{	
		gen vol_opt_last_`item' 	= qa1_002_`item'
		}		
		
	global itemlist "001 002 003 004"
	foreach item in $itemlist{	
		gen vol_ipt_now_`item' 	= qa1_003_`item'
		}
		
	global itemlist "005 006 007 008"
	foreach item in $itemlist{	
		gen vol_ipt_last_`item' 	= qa1_003_`item'
		}		

	global itemlist "001 002 003 004"
	foreach item in $itemlist{	
		gen vol_del_now_`item' 	= qa1_004_`item'
		}
		
	global itemlist "005 006 007 008"
	foreach item in $itemlist{	
		gen vol_del_last_`item' 	= qa1_004_`item'
		}		
		
		
	global itemlist "001 002 003 004"
	foreach item in $itemlist{	
		gen vol_dpt_now_`item' 	= qa1_005_`item'
		}
		
	global itemlist "005 006 007 008"
	foreach item in $itemlist{	
		gen vol_dpt_last_`item' 	= qa1_005_`item'
		}			
	
	sort facilitycode
	save CEHS_`country'_R`round'.dta, replace 		
	
*****E.3. Merge with sampling weight 
import excel "$chartbookdir\WHO_CEHS_Chartbook.xlsx", sheet("Weight") firstrow clear
	rename *, lower
	sort facilitycode
	merge facilitycode using CEHS_`country'_R`round'.dta, 
	
		tab _merge
		drop _merge*
		
	sort id /*this is generated from Lime survey*/
	save CEHS_`country'_R`round'.dta, replace 			
	
*****E.4. Export clean facility-level data to chart book 

	save CEHS_`country'_R`round'.dta, replace 		

	export excel using "$chartbookdir\WHO_CEHS_Chartbook.xlsx", sheet("Facility-level cleaned data") sheetreplace firstrow(variables) nolabel
	
**************************************************************
* F. Create indicator estimate data 
**************************************************************
use CEHS_`country'_R`round'.dta, clear
	
	gen obs=1 	
	gen obs_userfee=1 	if xuserfee==1
	gen obs_ipt=1 	if xipt==1
	gen obs_er=1 	if xer==1
	gen obs_vac=1 	if xvac==1
	gen obs_primary=1 	if zlevel_low==1
		
	global itemlist "opt ipt del dpt"
	foreach item in $itemlist{	
		capture drop temp
		egen temp	= rowtotal(vol_`item'_*)
		gen obshmis_`item' =1 if (temp>0 & temp!=.)
		}			
	
	gen xresult=q1101==1
		replace xresult=1 /*DELETE this line with real data*/
	keep if xresult==1 
	
	save temp.dta, replace 
	
*****F.1. Calculate estimates 

	use temp.dta, clear
	collapse (count) obs obs_* (mean) x* (sum) staff_num* yvac* vol* (count) obshmis* [iweight=weight], by(country round month year  )
		gen group="All"
		keep obs* country round month year  group* x* staff* yvac* vol*
		save summary_CEHS_`country'_R`round'.dta, replace 
		
	use temp.dta, clear
	collapse (count) obs obs_* (mean) x* (sum) staff_num* yvac* vol* (count) obshmis* [iweight=weight], by(country round month year   zurban)
		gen group="Location"
		gen grouplabel=""
			replace grouplabel="1.1 Rural" if zurban==0
			replace grouplabel="1.2 Urban" if zurban==1
		keep obs* country round month year  group* x* staff* yvac* vol*
		
		append using summary_CEHS_`country'_R`round'.dta, force
		save summary_CEHS_`country'_R`round'.dta, replace 

	use temp.dta, clear
	collapse (count) obs obs_* (mean) x* (sum) staff_num* yvac* vol* (count) obshmis* [iweight=weight], by(country round month year   zlevel_hospital)
		gen group="Level"
		gen grouplabel=""
			replace grouplabel="2.1 Non-hospitals" if zlevel_hospital==0
			replace grouplabel="2.2 Hospitals" if zlevel_hospital==1
		keep obs* country round month year  group* x* staff* yvac* vol*
			
		append using summary_CEHS_`country'_R`round'.dta
		save summary_CEHS_`country'_R`round'.dta, replace 
		
	use temp.dta, clear
	collapse (count) obs obs_* (mean) x* (sum) staff_num* yvac* vol* (count) obshmis* [iweight=weight], by(country round month year   zpub)
		gen group="Sector"
		gen grouplabel=""
			replace grouplabel="3.1 Non-public" if zpub==0
			replace grouplabel="3.2 Public" if zpub==1
		keep obs* country round month year  group* x* staff* yvac* vol*
		
		append using summary_CEHS_`country'_R`round'.dta		
		save summary_CEHS_`country'_R`round'.dta, replace 
	
	
	* convert proportion to %
	foreach var of varlist x*{
		replace `var'=round(`var'*100, 1)	
		}
	
			* But, convert back variables that were incorrectly converted (e.g., occupancy rates, score)
			foreach var of varlist xbedrate	*_score *_num {
				replace `var'=round(`var'/100, 1)
				}
	
	* generate staff infection rates useing the pooled data	
	global itemlist "md nr mw co othclinical clinical nonclinical all"
	foreach item in $itemlist{	
		gen staff_pct_covid_`item' = round(100* (staff_num_covid_`item' / staff_num_total_`item' ), 0.1)
		}	
	
	tab group round, m
	
	rename xsafe__004 xsafe__triage
	rename xsafe__005 xsafe__isolation
	
	* organize order of the variables by section in the questionnaire  
	order country round year month group grouplabel obs obs_* staff_num* staff_pct* 
		
	sort country round grouplabel
	
save summary_CEHS_`country'_R`round'.dta, replace 

export delimited using summary_CEHS_`country'_R`round'.csv, replace 
export delimited using "C:\Users\YoonJoung Choi\Dropbox\0 iSquared\iSquared_WHO\ACTA\4.ShinyAppCEHS\summary_CEHS_`country'_R`round'.csv", replace 


*****F.2. Export indicator estimate data to chartbook AND dashboard

use summary_CEHS_`country'_R`round'.dta, clear

	gen updatedate = "$date"

	local time=c(current_time)
	gen updatetime=""
	replace updatetime="`time'"
	
export excel using "$chartbookdir\WHO_CEHS_Chartbook.xlsx", sheet("Indicator estimate data") sheetreplace firstrow(variables) nolabel keepcellfmt
*export excel using "$chartbookdir\CEHS_Chartbook_slides.xlsx", sheet("Indicator estimate data") sheetreplace firstrow(variables) nolabel keepcellfmt

erase temp.dta

END OF DATA CLEANING AND MANAGEMENT 

