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

*AT MINIMUM, FOUR parts must be updated per country-specific adaptation. See "MUST BE ADAPTED" below 

/* TABLE OF CONTENTS*/

* A. SETTING <<<<<<<<<<========== MUST BE ADAPTED: 1. directories and local
* B. Import and drop duplicate cases
*****B.1. Import raw data from LimeSurvey 
*****B.2. Export/save the data daily in CSV form with date 
*****B.3. Export the data to chartbook  
*****B.4. Drop duplicate cases 
* C. Cleaning - variables 
*****C.1. Change var names to lowercase	
*****C.2. Change var names to make then coding friendly 
*****C.3. Find non-numeric variables and desting 
*****C.4. Recode yes/no & yes/no/NA
*****C.5. Label values 
* D. Create field check tables 
* E. Create analytical variables 
*****E.1. Country speciic code local <<<<<<<<<<========== MUST BE ADAPTED: 2. local per survey implementation and section 1 
*****E.2. Construct analysis variables <<<<<<<<<<========== MUST BE ADAPTED: 3. country specific staffing - section 2 
*****E.3. Merge with sampling weight <<<<<<<<<<========== MUST BE ADAPTED: 4. weight depending on sample design 
*****E.4. Export clean Respondent-level data to chart book 
* F. Create and export indicator estimate data 
*****F.1. Calculate estimates 
*****F.2. Export indicator estimate data to chart book and dashboard

**************************************************************
* A. SETTING 
**************************************************************

*** Directory for this do file 
*cd "C:\Users\ctaylor\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards\"
cd "C:\Users\YoonJoung Choi\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards\"

*** Directory for downloaded CSV data, if different from the main directory
*global downloadcsvdir "C:\Users\ctaylor\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards\DownloadedCSV\"
global downloadcsvdir "C:\Users\YoonJoung Choi\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards\DownloadedCSV\"

*** Define a directory for the chartbook, if different from the main directory 
*global chartbookdir "C:\Users\ctaylor\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards\"
global chartbookdir "C:\Users\YoonJoung Choi\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards\"

*** Define local macro for the survey 
local country	 		 COUNTRYNAME /*country name*/	
local round 			 1 /*round*/		
local year 			 	 2020 /*year of the mid point in data collection*/	
local month 			 12 /*month of the mid point in data collection*/		

local surveyid 			 769747 /*LimeSurvey survey ID*/		

*** local macro for analysis: no change needed  
local today=c(current_date)
local c_today= "`today'"
global date=subinstr("`c_today'", " ", "",.)

**************************************************************
* B. Import and drop duplicate cases
**************************************************************

*****B.1. Import raw data from LimeSurvey 
import delimited using "https://who.my-survey.host/index.php/plugins/direct?plugin=CountryOverview&docType=1&sid=`surveyid'&language=en&function=createExport", case(preserve) clear

*****B.2. Export/save the data daily in CSV form with date 	
export delimited using "$downloadcsvdir/LimeSurvey_CEHS_`country'_R`round'_$date.csv", replace 

*****B.3. Export the data to chartbook  	
import delimited "$downloadcsvdir/LimeSurvey_CEHS_EXAMPLE_R1.csv", case(preserve) clear  /*THIS LINE ONLY FOR PRACTICE*/

	codebook token Q101
	list Q1* if Q101==. | token=="" 
	*****CHECK: this is an empty row. There should be none	

	****MASK idenitifiable information*/
	foreach var of varlist Q1BSQ001comment Q102 Q103 Q108 Q109 Q1102 Q1103 {
		replace `var'=""
		}	
		
export excel using "$chartbookdir\WHO_CEHS_Chartbook.xlsx", sheet("Facility-level raw data") sheetreplace firstrow(variables) nolabel

*****B.4. Drop duplicate cases 

	lookfor id
	rename *id id
	codebook id 
	*****CHECK HERE: this is an ID variable generated by LimeSurvey, not facility ID. still there should be no missing*/	

	*****identify duplicate cases, based on facility code*/
	duplicates tag Q101, gen(duplicate) 
				
		rename submitdate submitdate_string			
	gen double submitdate = clock(submitdate_string, "MDY hm")
		format submitdate %tc
	
	list Q101 Q102 Q104 Q105 submitdate* startdate datestamp if duplicate==1 
	*****CHECK HERE: In the model data, there is one duplicate for practice purpose. 
	
	*****drop duplicates before the latest submission */
	egen double submitdatelatest = max(submitdate) if duplicate==1
						
		format %tcnn/dd/ccYY_hh:MM submitdatelatest
		
		list Q101 Q102 Q104 Q105 submitdate* if duplicate==1	
	
	drop if duplicate==1 & submitdate!=submitdatelatest 
	
	*****confirm there's no duplicate cases, based on facility code*/
	duplicates report Q101,
	*****CHECK HERE: Now there should be no duplicate 

	drop duplicate submitdatelatest

**************************************************************
* C. Data cleaning - variables
**************************************************************

*****C.1. Change var names to lowercase
 
	rename *, lower

*****C.1.a. Assess timestamp data 
	
	***** drop detailed timstamp data but keep interviewtime (interview length in seconds)
	drop q*time 
	drop grouptime* 
	codebook interviewtime 
	gen long interviewlength=round(interviewtime/60, 1) 
		lab var interviewlength "interview length in minutes"
		sum interviewlength
		
*****C.2. Change var names to drop odd elements "y" "sq" - because of Lime survey's naming convention 
	
	d *sq*
	d *y*
		
	rename (*ysq*) (*_*) /*when y is in the middle */
	rename (*sqsq*) (*_*) /*when sq is repeated - no need to */
	rename (*sq) (*) /*when ending with sq - no need to */

	rename (*_sq*) (*_*) /*replace sq with _*/
	rename (*sq*) (*_*) /*replace sq with _*/
	
	rename (q409b_*) (q409_*)
	
	rename (q201_*_a1) (q201_*_001)
	rename (q201_*_a2) (q201_*_002)
	
	lookfor sq
	lookfor y
	
	d *t
	capture drop *t

*****C.3. Find non-numeric variables and desting 
	
	*****************************
	* Section 1
	*****************************
	sum q1*
	codebook q104 q105 q106 q114*
		
	foreach var of varlist q104 q105 q106 q114*{	
		replace `var' = usubinstr(`var', "A", "", 1) 
		replace `var' = "88" if `var'=="-oth-"
		destring `var', replace 
		}
		
	sum q1*			
	
	*****************************	
	* Section 2
	*****************************
	sum q2*
	codebook q204 q205* q207* q208
		
	foreach var of varlist q204 q205* q207*  {	
		replace `var' = usubinstr(`var', "A", "", 1) 
		replace `var' = "88" if `var'=="-oth-"
		destring `var', replace 
		}	
		
	sum q2*		
		
	*****************************	
	* Section 3
	*****************************
	sum q3*
	codebook q302 q309 q311
		
	foreach var of varlist q302 q309  {	
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}		
		
	sum q3*
	
	*****************************	
	* Section 4
	*****************************
	sum q4*
	codebook q406* q409* q410* q411* q412* q414 q415 q417* q420* q421* 
		
	*foreach var of varlist q406* q409* q410* q411* q412* q414 q415 q417* q420* q421*   {		
	foreach var of varlist q406* q409* q412* q414 q415 q417* q420* q421*   {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}			
		
	rename q410_other q410other  
	gen q410_007=.
		replace q410_007 = 1 if q410other!=""
		replace q410_007 = 0 if q410other==""
		replace q410_007 = . if q410_001==.
		
	rename q411_other q411other 
	gen q411_012=.
		replace q411_012 = 1 if q411other!=""
		replace q411_012 = 0 if q411other==""
		replace q411_012 = . if q411_001==.
		
	sum q4*

	*****************************
	* Section 5
	*****************************
	sum q5*	
	codebook q503* q505* q507*
	sum q503* q505* q507*
	
	foreach var of varlist q503_001 - q503_011 q505* q507*  {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	
		
	sum q5*	

	*****************************	
	* Section 6		
	*****************************	
	sum q6*	
	codebook q604 q607* q608*
	
	foreach var of varlist q604 q607* q608_* {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}				
		
	sum q6*		
	
	*****************************
	* Section 7
	*****************************
	sum q7*
		
	foreach var of varlist q701* q702* q703* {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	
		
	sum q7*	
	
	*****************************	
	* Section 8
	*****************************
	sum q8*
	codebook q802_* q803_* q804* q805*
	
	foreach var of varlist q802_* q803_* q805_* 	{		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}			
		
	sum q8*

	*****************************		
	* Section 9
	*****************************
	sum q9*
	codebook q907 q910 q911
		
	foreach var of varlist q907 q910 q911 {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}		
		
	sum q9*

	*****************************			
	* Section 11: interview results
	*****************************
	sum q110*
	codebook q1101 q1104
	
	foreach var of varlist q1101 q1104 {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}			
	
	sum q110*
								
*****C.4. Recode yes/no 

	#delimit;
	sum
		q202  q205_* q206   q207* 
		q301  q304   q306_* q307  q308  q310
		q402 - q405  q406_* q407  q408  q410_* q411_* q416 q418 q419 
		q501  q502  q503_* q504  q505_* q506
		q601  q602  q603  q605  q606 q609  q610 q614-q615
		q701_* q702_* q703_* q704
		q801 q804 
		q901 q902  q905 q908 q912 q913 q914
		; 
		#delimit cr
	
	#delimit;
	foreach var of varlist 
		q202  q205_* q206   q207* 
		q301  q304   q306_* q307  q308  q310
		q402 - q405  q406_* q407  q408  q410_* q411_* q416 q418 q419 
		q501  q502  q503_* q504  q505_* q506
		q601  q602  q603  q605  q606 q609  q610 q614-q615
		q701_* q702_* q703_* q704
		q801 q804 
		q901 q902  q905 q908 q912 q913 q914
		{; 
		#delimit cr		
		recode `var' 2=0 /*no*/
		}
				
*****C.5. Label values 

	#delimit;	
	
	lab define q104 
		1"1.Urban" 
		2"2.Rural";  
	lab values q104 q104; 
	
	lab define q105 
		1"1.Level2: Dispensary"
		2"2.Level3: Health Centre"
		3"3.Level4: Primary Hospital"
		4"4.Level5: Secondary level hospital and above"
		5"5.Level6: Tertiary level" ; 
	lab values q105 q105; /*corresponding to the model example context*/
	
	lab define q106 
		1"1.Government"
		2"2.Private"
		3"3.NGO"
		4"4.FBO"
		5"5.Other"; 
	lab values q106 q106; /*corresponding to the model example context*/
	
	lab define q302
		1"1. Yes – user fees exempted only for COVID-19 services"
		2"2. Yes – user fees exempted only for other health services"
		3"3. Yes – user fees exempted for both COVID-19 and other health services"
		4"4. No"; 
	lab values q302 q302; 
		
	lab define q305
		1"1. Yes – for COVID-19 case management services"
		2"2. Yes – for other essential health services"
		3"3. Yes – for both COVID-19 and other services"
		4"4. No"
		5"5. Do not know"; 
	lab values q305 q305; 
		
	lab define change   /*KECT - q409a is weird (asks if all increased, all decreased, no changes, mixed), so it cannot be included here, changed from q409* to q409_* to address this issue*/
		1"1.Yes, increased"
		2"2.Yes, decreased"
		3"3.No" 
		4"4.N/A";  
	foreach var of varlist q409_* q412* q414 q415 q417* q420*{;
	lab values `var' change;	
	};
	
	lab define q409a   
		1"1.Yes, increased in all areas"
		2"2.Yes, decreased in all areas"
		3"3.Yes, increased in some but decreased in some" 
		4"4.No changes in any";  
	foreach var of varlist q409a {;
	lab values `var' q409a;	
	};
	
	lab define q417
		1"1.Yes, less frequent"
		2"2.Yes, suspended"
		3"3.No change" 
		4"4.yes, increased" 
		5"5.N/A";  
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
	
	lab define q421
		1"1.Not at all"	
		2"2.Slightly" 	
		3"3.Moderately" 	
		4"4.Quite a lot"	
		5"5.A great deal";  
	foreach var of varlist q421* {;
	lab values `var' q421;	
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
		3"2.Yes, PCR & RDT"
		4"5.No";
	lab values q604 q604;		

	lab define availfunc 
		1"1.Available, functional"
		2"2.Available, but not functional"
		3"3.Not available";
	foreach var of varlist q802_* q803_* q805_* q903 q904  {;
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
		3"3.None-no functional freezer" ;
	lab values q911 icepackfreeze ;	
	
	lab define yesno 1"1.Yes" 0"0.No"; 	
	foreach var of varlist 
		q202  q205_* q206   q207* 
		q301  q304   q306_* q307  q308  q310
		q402 - q405  q406_* q407  q408  q410_* q411_* q416 q418 q419 
		q501  q502  q503_* q504  q505_* q506
		q601  q602  q603  q605  q606 q609  q610 q614-q615
		q701_* q702_* q703_* q704
		q801 q804 
		q901 q902  q905 q908 q912 q913 q914
		{;		
	labe values `var' yesno; 
	};	

	lab define yesnona 
		1"1.Yes" 
		2"2.No" 
		3"3.N/A"; 	
	foreach var of varlist q204 q309 {;		
	labe values `var' yesnona; 
	};	
	
	lab define alwayssometimesnever 
		1"1.Always" 
		2"2.Sometimes" 
		3"3.Never"; 
	foreach var of varlist q607_* q608_* {;		
	labe values `var' alwayssometimesnever; 
	};	
		
	#delimit cr

**************************************************************
* D. Create field check tables for data quality check  
**************************************************************

* generates daily field check tables in excel

preserve

	gen updatedate = "$date"
	
	tabout updatedate using "$chartbookdir\FieldCheckTable_CEHS_`country'_R`round'_$date.xls", replace ///
		cells(freq col) h2("Date of field check table update") f(0 1) clab(n %)

			split submitdate_string, p(" ")
			gen date=date(submitdate_string1, "MDY") 
			format date %td
						
	tabout submitdate_string1 using "$chartbookdir\FieldCheckTable_CEHS_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Date of interviews (submission date, final)") f(0 1) clab(n %)
			
			gen xresult=q1104==1
			
			gen byte responserate= xresult==1
			label define responselist 0 "Not complete" 1 "Complete"
			label val responserate responselist

	tabout responserate using "$chartbookdir\FieldCheckTable_CEHS_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Interview response rate") f(0 1) clab(n %)
	
	tabout q104 using "$chartbookdir\FieldCheckTable_CEHS_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Number of completed interviews by area") f(0 1) clab(n %)
		
	tabout q105 using "$chartbookdir\FieldCheckTable_CEHS_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Number of completed interviews by hospital type") f(0 1) clab(n %)		

			bysort xresult: sum interviewlength
			egen time_complete = mean(interviewlength) if xresult==1
			egen time_incomplete = mean(interviewlength) if xresult==0
				replace time_complete = round(time_complete, 1)
				replace time_incomplete = round(time_incomplete, 1)

	tabout time_complete using "$chartbookdir\FieldCheckTable_CEHS_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Average interview length (minutes), among completed interviews") f(0 1) clab(n %)		
	tabout time_incomplete using "$chartbookdir\FieldCheckTable_CEHS_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Average interview length (minutes), among incomplete interviews") f(0 1) clab(n %)	

* Missing responses 

			capture drop missing
			gen missing=0
			foreach var of varlist q1104 {	
				replace missing=1 if `var'==.				
				}		
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_CEHS_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("0. Missing survery results (among all interviews)") f(0 1) clab(n %)									

keep if xresult==1 /*the following calcualtes % missing in select questions among completed interviews*/		
			
			capture drop missing
			gen missing=0
			foreach var of varlist q112 q113 {	
				replace missing=1 if `var'==.
				replace missing=. if q111!=1
				}		
			lab values missing yesno
			
	tabout missing using "$chartbookdir\FieldCheckTable_CEHS_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("1. Missing number of beds when facility provides inpatient services (among completed interviews)") f(0 1) clab(n %)					

			capture drop missing
			gen missing=0
			foreach var of varlist q201_002_001 q201_002_002 {	
				replace missing=1 if `var'==.
				}		
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_CEHS_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("2. Missing number of nurses (either the total number or the number who have been infected) (among completed interviews)") f(0 1) clab(n %)					

			capture drop missing
			gen missing=0
			foreach var of varlist q307 q308 {	
				replace missing=1 if `var'==.
				}
				
				replace missing=1 if q308==1 & q309==. 
				
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_CEHS_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("3. Missing salary payment ontime (among completed interviews)") f(0 1) clab(n %)					
		
			capture drop missing
			gen missing=0
			foreach var of varlist q406_* {	
				replace missing=1 if `var'==.
				}		
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_CEHS_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("4. Missing service strategy change (among completed interviews)") f(0 1) clab(n %)							
		
			capture drop missing
			gen missing=0
			foreach var of varlist q409_* {	
				replace missing=1 if `var'==.
				}		
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_CEHS_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("5. Missing OPT service volume change (among completed interviews)") f(0 1) clab(n %)							
		
			capture drop missing
			gen missing=0
			foreach var of varlist q420_* {	
				replace missing=1 if `var'==.
				}		
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_CEHS_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("6. Missing catch-up/restroation (among completed interviews)") f(0 1) clab(n %)							
			
			capture drop missing
			gen missing=0
			foreach var of varlist q507_* {	
				replace missing=1 if `var'==.
				}		
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_CEHS_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("7. Missing PPE availability (among completed interviews)") f(0 1) clab(n %)							
			
			capture drop missing
			gen missing=0
			foreach var of varlist q605 {	
				replace missing=1 if `var'==. & q604==4
				replace missing=. if q604!=4 				
				}		
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_CEHS_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("8. Missing specimen transportation time (among completed interviews)") f(0 1) clab(n %)							
		
			capture drop missing
			gen missing=0
			foreach var of varlist q701_* {	
				replace missing=1 if `var'==.
				}		
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_CEHS_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("9. Missing tracer medicine availability (among completed interviews)") f(0 1) clab(n %)							
	
restore
**************************************************************
* E. Create analytical variables 
**************************************************************

*****E.1. Country speciic code local 
	
	***** MUST REVIEW CODING FOR THE FOLLOWING FOUR GROUPS OF VARIABLES */
		/*
		zurban
		zlevel*
		zpub
		staff* 
		*/
	
	***** DEFINE LOCAL FOR THE FOLLOWING*/ 

		local urbanmin			 1 	
		local urbanmax			 1
		
		local minlow		 	 1 /*lowest code for lower-level facilities in Q105*/
		local maxlow		 	 2 /*highest code for lower-level facilities in Q105*/
		local minhigh		 	 3 /*lowest code for hospital/high-level facilities in Q105*/
		local maxhigh			 5 /*highest code for hospital/high-level facilities in Q105*/
		local primaryhospital    3 /*district hospital or equivalent */	
		
		local pubmin			 1
		local pubmax			 1
			
		local maxtraining	     5 /*total number of training items asked in q207*/
		local maxtrainingsupport 9 /*total number of training/support items asked in q207*/

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
	
	gen long facilitycode=q101

	gen month	=`month'
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

	egen staff_num_total_othclinical=rowtotal(q201_003_001 q201_004_001 q201_005_001 q201_006_001 q201_007_001  )
	egen staff_num_covid_othclinical=rowtotal(q201_003_002 q201_004_002 q201_005_002 q201_006_002 q201_007_002  )
	
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
	global itemlist "001 002 003 004 005 006 007 008 009"
	foreach item in $itemlist{	
		gen byte xtraining__`item' = q207_`item' ==1
		}		
		
		gen max=`maxtraining'
		egen temp=rowtotal(xtraining__001 xtraining__002 xtraining__003 xtraining__004 xtraining__005)
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

	gen xaddfund = q305==1 | q305==2 | q305==3
	gen xaddfund_gov 			= q306_001==1 
 	gen xaddfund_other 			= q306_002==1 | q306_003==1 | q306_004==1 | q306_005==1 
			
	gen xfinance_salaryontime 	= q307==1
	gen xfinance_ot 			= q308==1 
	gen xfinance_otontime 		= q309==1 | q309==3
		replace xfinance_otontime = . if xfinance_ot==0
		
	gen xfinance_ontime = xfinance_salaryontime ==1 & (xfinance_otontime==1 | xfinance_otontime==.)
			
	gen xfinance_PBF = q310==1
	
	sum xuserfee xexempt* xfee* xfinance*

	*****************************
	* Section 4: service delivery & utlization  
	*****************************
	
	***** guidelines about EHS: before & during COVID 
	gen xguideline_EHS		=q404==1
	gen xguideline_EHScovid	=q405==1 /*update chelsea about this change*/
	
	***** strategy change
		egen temp=rowtotal(q402 q403 q406*)
	gen xstrategy= temp>=1
		drop temp	
	
	gen xstrategy_reduce= 			q402==1  | q403==1  | q406_001==1 | q406_002==1 | q406_003==1 | q406_004==1 | q406_005==1
	gen xstrategy_reduce_closure= 	q402==1  
	gen xstrategy_reduce_hrchange= 	q403==1  | q406_001==1 | q406_002==1 | q406_003==1 | q406_004==1 | q406_005==1
	gen xstrategy_reduce_reduce= 	q406_001==1 | q406_002==1 | q406_003==1
	gen xstrategy_reduce_redirect= 	q406_004==1
	gen xstrategy_reduce_priority= 	q406_005==1
	gen xstrategy_reduce_combine= 	q406_006==1
	gen xstrategy_self= 			q406_007==1
	gen xstrategy_home= 			q406_008==1
	gen xstrategy_remote= 			q406_009==1 
	gen xstrategy_prescription= 	q406_010==1 | q406_011==1 | q406_012==1 
	
	***** Referral/transportation for COVID patients 
	
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
	/*
	*** Chelsea and YJ to discuss further 
		
		tab xopt_increase xopt_decrease, m
		
		codebook q409a
		tab q409a xopt_increase, m 
		tab q409a xopt_decrease, m
		
		tab q409a xopt_change, m
	*/
	
	***** REASONS for OPT volume changes
					
	global itemlist "001 002 003 004 005 006 007"
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
		gen `var'_reason_covidnow 	= `var'==1 & (`var'_reason__001==1 | `var'_reason__002==1  )
		gen `var'_reason_covidafter = `var'==1 & (`var'_reason__003==1 | `var'_reason__004==1 | `var'_reason__005==1 )
		gen `var'_reason_gbv	    = `var'==1 & (`var'_reason__006==1 ) 
		}		
		
	global varlist "xopt_decrease"
	foreach var in $varlist {
		gen `var'_reason_comdemand  = `var'==1 & (`var'_reason__001==1 | `var'_reason__002==1  | `var'_reason__005==1  ) //* KEYC edit*//
		gen `var'_reason_enviro 	= `var'==1 & (`var'_reason__003==1 | `var'_reason__004==1 )
		gen `var'_reason_intention	= `var'==1 & (`var'_reason__007==1 | `var'_reason__008==1 | `var'_reason__009==1 | `var'_reason__010==1  )
		gen `var'_reason_disruption = `var'==1 & (`var'_reason__011==1 | `var'_reason__012==1 )
		}
		
	***** ER
	
	gen xer = q114_001==1

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
	
	gen xipt = q111==1
	
	gen xbed = q112
	gen xbedrate = round(100*(q413/q112), 1)
	sum xbedrate
	
	gen xipt_increase = q414==1
	gen xipt_decrease = q414==2
	gen xipt_nochange = q414==3

		foreach var of varlist xbed* xipt_*{
			replace `var'=. if xipt==0
			}
		
	***** Pre hospital ER
	
	gen xpreer = q415<=3
	
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
	gen xresto_imp_preg 		= q420_001==1 
	gen xresto_imp_immunization = q420_002==1 
	gen xresto_imp_chronic 		= q420_003==1 
	gen xresto_imp_tb 			= q420_004==1 
	gen xresto_imp_hiv 			= q420_005==1 
	
	gen xresto_imppln_preg 			= q420_001==1 | q420_001==2
	gen xresto_imppln_immunization 	= q420_002==1 | q420_002==2
	gen xresto_imppln_chronic 		= q420_003==1 | q420_003==2 	
	gen xresto_imppln_tb 			= q420_004==1 | q420_004==2 	
	gen xresto_imppln_hiv 			= q420_005==1 | q420_005==2 	
	
		foreach item in preg{
			replace xresto_imp_`item' 	 =. if q420_001>=4
			replace xresto_imppln_`item' =. if q420_001>=4
			}	
		foreach item in immunization{
			replace xresto_imp_`item' 	 =. if q420_002>=4
			replace xresto_imppln_`item' =. if q420_002>=4
			}	
		foreach item in chronic{
			replace xresto_imp_`item' 	 =. if q420_003>=4
			replace xresto_imppln_`item' =. if q420_003>=4
			}		
		foreach item in tb{
			replace xresto_imp_`item' 	 =. if q420_004>=4
			replace xresto_imppln_`item' =. if q420_004>=4
			}					
		foreach item in hiv{
			replace xresto_imp_`item' 	 =. if q420_005>=4
			replace xresto_imppln_`item' =. if q420_005>=4
			}						
	
	global itemlist "001 002 003 004"
	foreach item in $itemlist{	
		gen xdisrupt__`item' = q421_`item'>=4 & q421_`item'<=5
		}
		
		rename xdisrupt__001 xdisrupt__hr
		rename xdisrupt__002 xdisrupt__finance
		rename xdisrupt__003 xdisrupt__ipc
		rename xdisrupt__004 xdisrupt__medsupp
				
	sum xstrategy* 
	sum xopt_increase xopt_increase_* xopt_increase_reason_* 
	sum xopt_decrease xopt_decrease_* xopt_decrease_reason_*
	sum xer xer_increase_* xer_increase xer_decrease_* xer_decrease
	sum xipt* xpreer*
	sum xout* xresto* 
	sum xdisrupt*

	*****************************
	* Section 5: IPC 
	*****************************
	
	gen xipcpp= q501==1
	
	gen xsafe= q502==1
	global itemlist "001 002 003 004 005 006 007 008 009 010 011" 
	foreach item in $itemlist{	
		gen xsafe__`item' = q503_`item' ==1
		}		
	
		gen max=11
		egen temp = rowtotal(xsafe__*)
	gen xsafe_score	=100*(temp/max)
	gen xsafe_100 	=xsafe_score>=100
	gen xsafe_50 	=xsafe_score>=50
		drop max temp
			
	gen xguideline= q504
	global itemlist "001 002 003 004 005 006" 
	foreach item in $itemlist{	
		gen xguideline__`item' = q505_`item' ==1
		}		
		
		gen max=6
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

	gen xppedispose = q508==1 
	
	sum xipc* xsafe* xguideline* xppe*

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
		gen xcvd_pt__`item' 	= xcvd_pt==1 & q607_`item'==1 /* ALWAYS - TBC*/
		}	
		
		gen max=7							
		egen temp=rowtotal(xcvd_pt__*)    
	gen xcvd_pt_score	=100*(temp/max)
	gen xcvd_pt_100 	=xcvd_pt_score>=100
	gen xcvd_pt_50 		=xcvd_pt_score>=50
		drop max temp		

		foreach var of varlist xcvd_pt_score xcvd_pt_100 xcvd_pt_50 xcvd_pt__*{
			replace `var'=. if xcvd_pt==0
			}
		
	gen xcvd_pthbsi = q607_006==1 | q607_006==2	/* ALWAYS or SOMETIMES*/
	
	global itemlist "001 002 003 004 005 006"   
	foreach item in $itemlist{	
		gen xcvd_pthbsi__`item' 	= xcvd_pthbsi==1 & q608_`item'==1 /* ALWAYS - TBC*/
		}	

		/*
		foreach var of varlist xcvd_pthbsi_*{
			replace `var'=. if xcvd_pthbsi==0
			}		
		*/ 
	
	gen xcvd_guide_casemanage	= q609==1				
		
	gen xcvd_info = q610==1	

	gen xcvd_info_moh 		= q610==1	& q611_001==1
	gen xcvd_info_localgov	= q610==1	& q611_002==1
	gen xcvd_info_who 		= q610==1	& q611_003==1
	gen xcvd_info_prof 		= q610==1	& q611_004==1
	gen xcvd_info_other		= q610==1	& q611_005==1
	
	sum xcvd_*
	
	*****************************
	* Section 7: Therapeutics
	*****************************

	global itemlist "001 002 003 004 005 006 007 008 009 010 011 012 013 014 015 016 017" 
	foreach item in $itemlist{	
		gen xdrug__`item' = q701_`item' ==1 
		}		
			
		gen max=`maxdrug'
		egen temp=rowtotal(xdrug__* )
	gen xdrug_score	=100*(temp/max)
	gen xdrug_100 	=xdrug_score>=100
	gen xdrug_50 	=xdrug_score>=50
		drop max temp

	global itemlist "001 002 003" 
	foreach item in $itemlist{	
		gen xsupply__`item' = q702_`item' ==1 
		}	
		
		gen max=3
		egen temp=rowtotal(xsupply__*)
	gen xsupp_score	=100*(temp/max)
	gen xsupp_100 	=xsupp_score>=100
	gen xsupp_50 	=xsupp_score>=50
		drop max temp

	gen xvaccine_child=q409_005>=1 & q409_005<=3	
		
	global itemlist "001 002 003 004 005"
	foreach item in $itemlist{	
		gen xvaccine__`item' = q703_`item' ==1
		}	
	
		gen max=5
		egen temp=rowtotal(xvaccine__* )
	gen xvac_score	=100*(temp/max)
	gen xvac_100 	=xvac_score>=100
	gen xvac_50 	=xvac_score>=50
		drop max temp
			
	foreach var of varlist xvaccine__* xvac_*  {	
		replace `var'	=. if xvaccine_child!=1 
		}		
		
	gen byte xdisrupt_supply = q704==1
		
	*****************************
	* Section 8: 
	*****************************
		
	gen xdiag=q801==1
	gen ximage=q804==1
	
	global itemlist "001 002 003 004 005" 
	foreach item in $itemlist{	
		gen xdiag_av_a`item' 	= q802_`item'<=2 
		}	
		
	global itemlist "001 002 003 004 005" 
	foreach item in $itemlist{	
		gen xdiag_avfun_a`item' = q802_`item'<=1
		}			
		
	global itemlist "001 002 003 004 005"
	foreach item in $itemlist{	
		gen xdiag_av_h`item' 	= q803_`item'<=2
		replace xdiag_av_h`item' 	= . if zlevel_hospital!=1  
		}		
		
	global itemlist "001 002 003 004 005"
	foreach item in $itemlist{	
		gen xdiag_avfun_h`item' = q803_`item'<=1
		replace xdiag_avfun_h`item' 	= . if zlevel_hospital!=1  
		}		
						
		gen max=5
		egen tempbasic=rowtotal(xdiag_avfun_a*)
	gen xdiagbasic_score	=100*(tempbasic/max)
	gen xdiagbasic_100 	=xdiagbasic_score>=100
	gen xdiagbasic_50 	=xdiagbasic_score>=50
		*drop max temp
		drop max 
		
		gen max=.
			replace max=5  if zlevel_hospital!=1 
			replace max=10 if zlevel_hospital==1 
		egen temphosp=rowtotal(xdiag_avfun_h*)
		gen temprelevant=.
			replace temprelevant=tempbasic if zlevel_hospital!=1 
			replace temprelevant=tempbasic + temphosp if zlevel_hospital==1 
	gen xdiag_score	=100*(temprelevant/max)
	gen xdiag_100 	=xdiag_score>=100
	gen xdiag_50 	=xdiag_score>=50
		*drop max temp
		drop max 			
		
	global itemlist "001 002 003 004" 
	foreach item in $itemlist{	
		gen ximage_av_`item' 	= q805_`item'<=2
		replace ximage_av_`item'	=. if zlevel_hospital!=1  
		}

	global itemlist "001 002 003 004" 
	foreach item in $itemlist{	
		gen ximage_avfun_`item' = q805_`item'<=1  
		replace ximage_avfun_`item' =. if zlevel_hospital!=1  
		}		
	
		gen max=4  /* CHECK kenya code, it should be 4 there*/
		egen tempimage=rowtotal(ximage_avfun_*)
	gen ximage_score	=100*(tempimage/max)
	gen ximage_100 	=ximage_score>=100
	gen ximage_50 	=ximage_score>=50
		*drop max temp
		drop max 	
	
	foreach var of varlist ximage*{	
		replace `var' =. if zlevel_hospital!=1  
		}	
	
	*****************************
	* Section 9: vaccine
	*****************************
	
	gen xvac= q901==1 | q902==1
	
	gen xvac_av_fridge 		= q903==1 | q903==2
	gen xvac_avfun_fridge 	= q903==1 
	gen xvac_avfun_fridgetemp 	= q903==1 & q904==1
	
	gen xvac_av_coldbox	= q905==1
	
	gen xvac_avfun_coldbox_all		= q905==1 & (q906>=1 & q906!=.) & q907==1
	gen xvac_avfun_coldbox_all_full	= q905==1 & (q906>=1 & q906!=.) & q907==1 & q911==1
	
	gen yvac_avfun_coldbox_all		= q906 if xvac_avfun_coldbox_all==1
	gen yvac_avfun_coldbox_all_full	= q906 if xvac_avfun_coldbox_all==1 & q911==1
	
	gen xvac_av_carrier	= q908==1
	
	gen xvac_avfun_carrier_all		= q908==1 & (q909>=1 & q909!=.) & q910==1	
	gen xvac_avfun_carrier_all_full	= q908==1 & (q909>=1 & q909!=.) & q910==1 & q911==1	
	
	gen yvac_avfun_carrier_all		= q909 if xvac_avfun_carrier_all==1
	gen yvac_avfun_carrier_all_full	= q909 if xvac_avfun_carrier_all==1 & q911==1

	gen xvac_av_outreach 			 = xvac_av_coldbox ==1 | xvac_av_carrier ==1  
	gen xvac_avfun_outreach_all_full = xvac_avfun_coldbox_all_full ==1 | xvac_avfun_carrier_all_full==1  
		
	gen xvac_sharp = q912==1
	
	gen xvac_aefikit = q913==1
	gen xvac_aefireport = q914==1
	
	foreach var of varlist xvac_av* yvac_av* xvac_sharp xvac_aefi*{
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
***** MUST select/run Chunk A or B, depending on the sample design 
/*RUN this chunk A if there is samplingb weight*/
*CHUNK A BEGINS  

import excel "$chartbookdir\WHO_CEHS_Chartbook.xlsx", sheet("Weight") firstrow clear
	rename *, lower
		
	sort facilitycode
	merge facilitycode using CEHS_`country'_R`round'.dta, 
	
		tab _merge
		*****CHECK HERE: all should be 3 (i.e., match) by the end of the data collection*/
		drop _merge*
		
	sort id /*this is generated from Lime survey*/
	save CEHS_`country'_R`round'.dta, replace 		
	
*CHUNK A ENDS

/*RUN this chunk B if there is NO samplingb weight
*CHUNK B BEGINS  	

	gen weight=1 

*CHUNK B BEGINS  
*/	
	
*****E.4. Export clean facility-level data to chart book 
	
	save CEHS_`country'_R`round'.dta, replace 	
	
	export delimited using CEHS_`country'_R`round'.csv, replace 

	export excel using "$chartbookdir\WHO_CEHS_Chartbook.xlsx", sheet("Facility-level cleaned data") sheetreplace firstrow(variables) nolabel
			
**************************************************************
* F. Create indicator estimate data 
**************************************************************
use CEHS_`country'_R`round'.dta, clear
	
	***** To get the total number of observations per relevant part 
	
	gen obs=1 	
	gen obs_userfee=1 	if xuserfee==1
	gen obs_ipt=1 		if xipt==1
	gen obs_er=1 		if xer==1
	gen obs_vac=1 		if xvac==1
	gen obs_primary=1 	if zlevel_low==1 /*COUNTRY SPECIFIC*/
		
	global itemlist "opt ipt del dpt"
	foreach item in $itemlist{	
		capture drop temp
		egen temp	= rowtotal(vol_`item'_*)
		gen obshmis_`item' =1 if (temp>0 & temp!=.)
		}			
	
	gen xresult=q1104==1
	
	save temp.dta, replace 
	
*****F.1. Calculate estimates 

	use temp.dta, clear
	collapse (count) obs obs_* (mean) x* interviewlength (sum) staff_num* yvac* vol* (count) obshmis* [iweight=weight], by(country round month year  )
		gen group="All"
		gen grouplabel="All"
		keep obs* country round month year  group* x* interviewlength staff* yvac* vol*
		save summary_CEHS_`country'_R`round'.dta, replace 
		
	use temp.dta, clear
	collapse (count) obs obs_* (mean) x* interviewlength (sum) staff_num* yvac* vol* (count) obshmis* [iweight=weight], by(country round month year   zurban)
		gen group="Location"
		gen grouplabel=""
			replace grouplabel="Rural" if zurban==0
			replace grouplabel="Urban" if zurban==1
		keep obs* country round month year  group* x* interviewlength staff* yvac* vol*
		
		append using summary_CEHS_`country'_R`round'.dta, force
		save summary_CEHS_`country'_R`round'.dta, replace 

	use temp.dta, clear
	collapse (count) obs obs_* (mean) x* interviewlength (sum) staff_num* yvac* vol* (count) obshmis* [iweight=weight], by(country round month year   zlevel_hospital)
		gen group="Level"
		gen grouplabel=""
			replace grouplabel="Primary" if zlevel_hospital==0
			replace grouplabel="Secondary" if zlevel_hospital==1
		keep obs* country round month year  group* x* interviewlength staff* yvac* vol*
			
		append using summary_CEHS_`country'_R`round'.dta
		save summary_CEHS_`country'_R`round'.dta, replace 
		
	use temp.dta, clear
	collapse (count) obs obs_* (mean) x* interviewlength (sum) staff_num* yvac* vol* (count) obshmis* [iweight=weight], by(country round month year   zpub)
		gen group="Sector"
		gen grouplabel=""
			replace grouplabel="Non-public" if zpub==0
			replace grouplabel="Public" if zpub==1
		keep obs* country round month year  group* x* interviewlength staff* yvac* vol*
		
		append using summary_CEHS_`country'_R`round'.dta		
		save summary_CEHS_`country'_R`round'.dta, replace 
	
	
	***** convert proportion to %
	foreach var of varlist x*{
		replace `var'=round(`var'*100, 1)	
		}
	
			* But, convert back variables that were incorrectly converted (e.g., occupancy rates, score)
			foreach var of varlist xbedrate	*_score *_num {
				replace `var'=round(`var'/100, 1)
				}
			
			* Drop categorial variables 
			drop xopt_change 
			
			* Drop survey variables 
			drop xresult interviewlength
	
	***** generate staff infection rates useing the pooled data	
	global itemlist "md nr othclinical clinical nonclinical all" 
	foreach item in $itemlist{	
		gen staff_pct_covid_`item' = round(100* (staff_num_covid_`item' / staff_num_total_`item' ), 0.1)
		}	
	
	tab group round, m
	
	rename xsafe__004 xsafe__triage
	rename xsafe__005 xsafe__isolation
	
	***** organize order of the variables by section in the questionnaire  
	order country round year month group grouplabel obs obs_* obshmis* staff_num* staff_pct* 
		
	sort country round grouplabel
	
save summary_CEHS_`country'_R`round'.dta, replace 

export delimited using summary_CEHS_`country'_R`round'.csv, replace 

*****F.2. Export indicator estimate data to chartbook AND dashboard

use summary_CEHS_`country'_R`round'.dta, clear

	gen updatedate = "$date"

	local time=c(current_time)
	gen updatetime=""
	replace updatetime="`time'"
	
export excel using "$chartbookdir\WHO_CEHS_Chartbook.xlsx", sheet("Indicator estimate data") sheetreplace firstrow(variables) nolabel keepcellfmt

* For YJ's shiny app and cross check against results from R
export delimited using "C:\Users\YoonJoung Choi\Dropbox\0 iSquared\iSquared_WHO\ACTA\4.ShinyApp\0_Model\summary_CEHS_`country'_R`round'.csv", replace 
export delimited using "C:\Users\YoonJoung Choi\Dropbox\0 iSquared\iSquared_WHO\ACTA\3.AnalysisPlan\summary_CEHS_`country'_R`round'_Stata.csv", replace 

erase temp.dta

END OF DATA CLEANING AND MANAGEMENT 

