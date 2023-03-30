 clear
clear matrix
clear mata
capture log close
set more off
numlabel, add

* Date of the combined COVID-19 HFA questionniare version: 14 September, 2022
* Date of last code update: 23 September, 2022

*This code 
*1) imports and cleans dataset from Lime Survey, and 
*2) creates indicator estimate data for dashboards and chartbook. 
*		=====> First Purple Tab in Chartbook: "Indicator estimate data"
*3) creates indicator estimate data for trend analysis. 
*		=====> Second Purple Tab in Chartbook: "All round data"
*4) conducts minimum data quality check /*NEW Section G*/. 

*  DATA IN:	CSV file daily downloaded from Limesurvey 	
*  DATA OUT: 
*		1. raw data (as is, downloaded from Limesurvey) 
*			=> CSV, dta, and green tab in Chartbook  	
*		2. cleaned data with additional analytical variables in Chartbook and, for further analyses, as a datafile 
*			=> CSV, dta, and blue tab in Chartbook  	
*		3. summary estimates of indicators in Chartbook and, for dashboards, as a datafile 	
*			=> CSV, dta, and the first purple tab in Chartbook  	
*		4. ALL-ROUND summary estimates of indicators in Chartbook and, for dashboards, as a datafile 	
*			=> The second purple tab in Chartbook  	
*  NOTE OUT to log file for minimum data quality check  
*		1. DataCheck_CombinedCOVID19HFA_`country'_R`round'_$date.log

*AT MINIMUM, THREE parts must be updated per country-specific adaptation. See "MUST BE ADAPTED" below 

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
*****C.3. Find non-numeric variables and destring 
*****C.4. Recode yes/no 
*****C.5. Label values 
* D. Field check tables - dropped from the previous analysis code.  
* E. Create analytical variables 
*****E.1. Country specific code local <<<<<<<<<<========== MUST BE ADAPTED: 2. local per survey implementation and section 1 
*****E.2. Construct analysis variables 
*		In addition to creating variables based on the revised questionnaire, it also does the following: 
*		(1) Rename detailed indicators ending with sub-question numbers with more friendly/intuitive names (Previously E.2.A), and 
*		(2) Create "global indicators" that were created at the HQ level after country analyses were completed.   
*			They can be found under "ADDITIONAL FROM "GLOBAL INDICATORS"" at the end of each section. 
*****E.3. Merge with sampling weight <<<<<<<<<<========== MUST BE ADAPTED: 3. weight depending on sample design 
*****E.4. Export clean Respondent-level data to chartbook 
* F. Create and export indicator estimate data - LATEST/current round data. 
*****F.1. Calculate estimates 
*****F.2. Export indicator estimate data to chartbook and for dashboard
* G. MINIMUM data quality check 
* H. Create and export ALL-ROUND indicator estimate data
*		Import "PAST indicator estimate data" (which will be prepared for each country by HQ)
*		Append it the latest round's PAST indicator estimate data
* 		Export the all round data to chartbook

**************************************************************
* A. SETTING 
**************************************************************

*** Directory for this do file 
*cd "C:\Users\ctaylor\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards\"
*cd "C:\Users\YoonJoung Choi\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards\"
*cd "G:\My Drive\Dropbox\Office\Data Management\ODK\Projects\WHO\Round 3\Analysis\Readiness"
cd "~/Dropbox/0iSquared/iSquared_WHO/ACTA/0.Countries/0 Ghana/GH_Q20230329/"

*** Directory for downloaded CSV data, if different from the main directory
*global downloadcsvdir "C:\Users\ctaylor\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards\DownloadedCSV\"
*global downloadcsvdir "C:\Users\YoonJoung Choi\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards\DownloadedCSV\"
*global downloadcsvdir "G:\My Drive\Dropbox\Office\Data Management\ODK\Projects\WHO\Round 3\Analysis\Readiness"
global downloadcsvdir "~/Dropbox/0iSquared/iSquared_WHO/ACTA/0.Countries/0 Ghana/GH_Q20230329/"

*** Define a directory for the chartbook, if different from the main directory 
*global chartbookdir "C:\Users\ctaylor\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards\"
*global chartbookdir "C:\Users\YoonJoung Choi\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards\"
*global chartbookdir "G:\My Drive\Dropbox\Office\Data Management\ODK\Projects\WHO\Round 3\Analysis\Readiness"
global chartbookdir "~/Dropbox/0iSquared/iSquared_WHO/ACTA/0.Countries/0 Ghana/GH_Q20230329/"

*** Define local macro for the survey 
local country	 		 GHANA /*country name*/	
local round 			 3 /*round*/		
local year 			 	 2022 /*year of the mid point in data collection*/	
local month 			 11 /*month of the mid point in data collection*/				

// Ghana didnt use limesurvey
//local surveyid 			 259237 /*LimeSurvey survey ID*/

*** local macro for analysis: no change needed  
local today=c(current_date)
local c_today= "`today'"
global date=subinstr("`c_today'", " ", "",.)

**************************************************************
* B. Import and drop duplicate cases
**************************************************************

*****B.1. Import raw data from LimeSurvey 
*import delimited using "https://extranet.who.int/dataformv3/index.php/plugins/direct?plugin=CountryOverview&docType=1&sid=`surveyid'&language=en&function=createExport", case(preserve) clear

	/*
	
	NOTE
	
	For the URL, we need to use part of the country overview page for the data server. For example, suppose the overview page link looks like this for a country named YYY:
	https://extranet.who.int/dataformv3/index.php/plugins/direct?plugin=CountryOverview&country=YYY&password=XXXXXXXXX.

	Replace part of the link before plugins with the part in the country-specific link. So, the code should be: 

	import delimited using "https://extranet.who.int/dataformv3/index.php/plugins/direct?plugin=CountryOverview&docType=1&sid=`surveyid'&language=en&function=createExport", case(preserve) clear

	*/

import delimited "$downloadcsvdir/Readiness.csv", case(preserve) clear /*THIS LINE ONLY FOR PRACTICE*/

*****B.2. Export/save the data daily in CSV form with date 	
export delimited using "$downloadcsvdir/GH_CombinedCOVID19HFA_`country'_R`round'_$date.csv", replace
	
*****B.3. Export the data to chartbook  	

	/*MASK idenitifiable information for respondents.*/
	/*
	foreach var of varlist Q104 {
		replace `var'=""
		}		
	foreach var of varlist Q1002 Q1003 {
		replace `var'=.		
		}		
		*/
export excel using "$chartbookdir/GH_CombinedCOVID19HFA_Chartbook.xlsx", sheet("Facility-level raw data") sheetreplace firstrow(variables) nolabel

*****B.4. Drop duplicate cases 

	///codebook Q101
	///list Q101 - Q105 if Q101==. 
	*****CHECK HERE: 
	*		this is an empty row. There should be none	

	///lookfor id
	///rename *id id
	///codebook id 
	*****CHECK HERE: 
	*		this is an ID variable generated by LimeSurvey, not facility ID.
	*		not used for analysis 
	*		still there should be no missing	
	///drop id

	*****identify duplicate cases, based on facility code*/
	///duplicates tag Q101, gen(duplicate) 
		
		/* 
		* must check string value and update
		* 	1. "mask" in the "clock" line for submitdate
		* 	2. "format" line for the submitdatelatest		
		* REFERENCE: https://www.stata.com/manuals13/u24.pdf
		* REFERENCE: https://www.stata.com/manuals13/ddatetime.pdf#ddatetime
		*/
	///	codebook submitdate 
				
		///rename submitdate submitdate_string			
	///gen double submitdate 	= clock(submitdate_string, "YMDhms") /*"clock" line with different mask: with seconds*/
	*gen submitdate 		= clock(submitdate_string, "MD20Y hm") /*"clock" line in the standard code*/
	*gen double submitdate 	= clock(submitdate_string, "MDY hm") /*"clock" line with different mask: 4-digit year*/
	
	///	format submitdate %tc 
	///	codebook submitdate*
			
	///sort Q101 Q105 submitdate
	///list Q101 Q105 submitdate if duplicate!=0  
	*****CHECK HERE: 
	*		In the model data, there is one facility that have three data entries for practice purpose. 

	*****drop duplicates before the latest submission */
	///egen double submitdatelatest = max(submitdate) if duplicate!=0  , by(Q101) /*LATEST TIME WITHIN EACH DUPLICATE*/					
		
		*format %tcnn/dd/ccYY_hh:MM submitdatelatest /*"format line without seconds*/
		///format %tcnn/dd/ccYY_hh:MM:SS submitdatelatest /*"format line with seconds*/
		
		///sort Q101 submitdate
		///list Q101 submitdate* if duplicate!=0 	

		/*

		.                 list Q101 submitdate* if duplicate!=0   

			 +------------------------------------------------------------------------+
			 |    Q101     submitdate_string           submitdate    submitdatelatest |
			 |------------------------------------------------------------------------|
		 60. | 5023684   2022-09-16 22:59:15   16sep2022 22:59:15   9/17/2022 9:07:59 |
		 61. | 5023684   2022-09-16 23:59:15   16sep2022 23:59:15   9/17/2022 9:07:59 |
		 62. | 5023684   2022-09-17 09:07:59   17sep2022 09:07:59   9/17/2022 9:07:59 |
			 +------------------------------------------------------------------------+

		*/	
		
	///drop if duplicate!=0  & submitdate!=submitdatelatest 
	///drop if Q101==. 

	*****confirm there's no duplicate cases, based on facility code*/
	///duplicates report Q101,
	*****CHECK HERE: 
	*		Now there should be no duplicate 

	///drop duplicate submitdatelatest
	
**************************************************************
* C. Data cleaning - variables 
**************************************************************

*****C.1. Change var names to lowercase
 
	rename *, lower

*****C.1.a. Assess and drop timestamp data 

	///drop *time* 
	*interviewtime is availabl in dataset only when directly downloaded from the server, not via export plug-in used in this code
	*So, just do not deal with interview time for now. 

*****C.2. Change var names to drop odd elements "y" "sq" - because of Lime survey's naming convention 

	///rename (*sq*) (*_*) /*replace sq with _*/
		
	///rename (q201_*_a1) (q201_*_a)
	///rename (q201_*_a2) (q201_*_b)

	///rename (q501_*1) (q501_*_a)
	///rename (q501_*2) (q501_*_b)
	
	///rename (q505_*1) (q505_*_a)
	///rename (q505_*2) (q505_*_b)
	
	///rename (q503*) (q503_0*)
		
	///lookfor sq
	///lookfor a
	///lookfor b
	
	///lookfor other /* We have only two questions where text entry for other is allowed*/ 

*****C.3. Find non-numeric variables and desting 

	*****************************
	* Section 1
	*****************************
	///sum q1*
		
	foreach var of varlist q106 q107 q108 q110 {	
		//replace `var' = usubinstr(`var', "A", "", 1) 
		//replace `var' = "88" if `var'=="-oth-"
		destring `var', replace 
		}
		
	sum q1*			

	*****************************	
	* Section 2
	*****************************
	sum q2*	
		
	foreach var of varlist q208* q210*  {	
		*replace `var' = usubinstr(`var', "A", "", 1) 
		*replace `var' = "88" if `var'=="-oth-"
		destring `var', replace 
		}	
		
	sum q2*		
	
	*****************************	
	* Section 3
	*****************************
	sum q3*
		
	foreach var of varlist q302* q304* q305* q307*  {	
	//	replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}		
		
	sum q3*
	
	*****************************	
	* Section 4
	*****************************
	sum q4*
		
	foreach var of varlist q402* q415* q417*   {		
		//replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}			

	sum q4*

	*****************************
	* Section 5
	*****************************
	sum q5*	
		
	foreach var of varlist q501* q502 q505* q507*  {		
		//replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	
		
	sum q5*	

	*****************************	
	* Section 6		
	*****************************	
	sum q6*	
	
	foreach var of varlist q601* q602* q603* q604* {		
		//replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}				
		
	sum q6*		
	
	*****************************
	* Section 7
	*****************************
	sum q7*
		
	foreach var of varlist q701* q702*  {		
		//replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	
		
	sum q7*	
	
	*****************************	
	* Section 8
	*****************************
	sum q8*
		
	foreach var of varlist q804 q807* q808* 	{		
		//replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}			
		
	sum q8*

	*****************************		
	* Section 9
	*****************************
	sum q9*
			
	foreach var of varlist q904* q909* q911* {		
		//replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}		
		
	sum q9*
	
	*****************************			
	* Section 10: interview results
	*****************************
	sum q100*	
	
	foreach var of varlist q1001 q1004 {		
		//replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}			
	
	sum q100*	
	
*****C.4. Recode yes/no 

	#delimit;
	global varlistyesno "
		q109 q110
		q208* q209 q210* q211 
		q301 q302* q303 q30401 q307*
		q406 q407 q408 q409 q414 q4160* q417* q41802 
		q501* q502 q50102a q5031 q5032 q5033 q5034 q5035 q5036 
		q5037 q5038 q5039 q50310 q50311 q50312 q50313 q50314 q50315 q50316 q50317 
		 q5042 q5043 q5044 q5045 q5046 q5047 q5048 q506 q50701
		q702* q703 q704
		q801 q802 q803 q804 q805 q806 q80701
		q903 q90901 q91102 q91103 q91104 q912 q913 q914
		q1001 q1002
		"; 
		#delimit cr
	
	sum $varlistyesno

	foreach var of varlist $varlistyesno{
		recode `var' 2=0 /*no*/
		}	
		
	sum $varlistyesno
							
*****C.5. Label values 
{
	#delimit;	
	//Jane and Ben 18022023 changed 106 to 105
	lab define urbanrural
		1"1.Urban" 
		2"2.Rural";  
	lab values q105 urbanrural; 
	
	//Jane and Ben 18022023 changed 108 to 107
	lab define sector 
		1"1.Government"
		2"2.Quasi-government (e.g SSNIT, UGMC etc)"
		3"3.Private self-financed"
		4"4.Private faith-based (ie. CHAG, Amadiaya, etc)"; 
	lab values q107 sector; 
	
	lab define ipc
		1"1.Currently available for all health workers"
		2"2.Currently available only for some health workers"
		3"3.Currently unavailable for any health workers"
		4"4.Not applicable – never provided" ;
	foreach var of varlist q304* q305* {;
	lab values `var' ipc;	
	};	
	
	lab define mgmt_optcovid
		1"1.Yes, always"
		2"2.Yes, but only sometimes"
		3"3.No";
	foreach var of varlist q402* {;
	lab values `var' mgmt_optcovid;	
	};	
	
	lab define mgmt_iptcovidsevere
		1"1.Yes almost always"
		2"2.Yes but only at certain times of days"
		3"3.No, never able to provide the care"
		4"4.N/A";
		//changed 415 to 416
	foreach var of varlist q416* {;
	lab values `var' mgmt_iptcovidsevere;	
	};	
	
	lab define optchange
		1"1.Much lower"
		2"2.Lower"
		3"3.Similar"
		4"4.Higher"
		5"5.Much higher";
	foreach var of varlist q502 {;
	lab values `var' optchange;	
	};	
	
	lab define outreachchange
		1"1.Yes changed, decreased"
		2"2.Yes changed, suspended"
		3"3.No change in frequency"
		4"4.Yes changed, increased"
		5"N/A or Outreach services not offered";
	foreach var of varlist q507* {;
	lab values `var' outreachchange;	
	};			
	
	lab define availfunc 
		1"1.Yes, functional"
		2"2.Yes, but not functional"
		3"3.Unavailable";
	foreach var of varlist 
		q701* q807* q808* 
		q902 q903 {;
	lab values `var' availfunc ;	
	};	
	
	lab define pcrprocess
		1"1.Process specimens in the facility"
		2"2.Send specimens outside";
	foreach var of varlist q804 {;
	lab values `var' pcrprocess ;	
	};		

	lab define yesno 
		1"1.Yes" 
		2"2.No"; 	
	foreach var of varlist $varlistyesno {;		
	lab values `var' yesno; 
	};
	
	lab define yesnona 
		1"1.Yes" 
		2"2.No" 
		3"N/A"; 
	foreach var of varlist 
		q505*a
		q602* q603*
		{;		
	lab values `var' yesnona; 
	};
	
	lab define yesyesbutno 
		1"1.Yes, provided and available" 
		2"2.Yes, provided but unavailable" 
		3"3.Not provided"; 
	foreach var of varlist 
		q904* q909*
		{;		
	lab values `var' yesyesbutno; 
	};	
	
	/*
	*when "other" is selected, LimeSurvey treats Q1004 as string... :( 
	lab define results
		1"1.COMPLETED"
		2"2.POSTPONED"
		3"3.PARTLY COMPLETED AND POSTPONED" 
		4"4.PARTLY COMPLETED"
		5"5.REFUSED"
		6"6.OTHER"; 
	lab values q1004 results; 
	*/
	
	#delimit cr
}
**************************************************************
* E. Create analytical variables 
**************************************************************

*****E.1. Country speciic code local 
	
	***** MUST REVIEW CODING FOR THE FOLLOWING VARIABLES AT MINIMUM */
		/*
		zurban
		zlevel*
		zpub
		*/
	
	/*DEFINE LOCAL FOR THE FOLLOWING*/ 
		
		local minlow		 	1 /*lowest code for lower-level facilities in q107*/
		local maxlow		 	3 /*highest code for lower-level facilities in q107*/ 
		local minhigh		 	2 /*lowest code for hospital/high-level facilities in q107*/  
		local maxhigh			8 /*highest code for hospital/high-level facilities in q107*/ 

		local pubmin			1
		local pubmax			1
	
*****E.2. Construct analysis variables 

* give prefix z for background characteristics, which can be used as analysis strata     
* give prefix x for binary variables, which will be used to calculate percentage   
* give prefix y for integer/continuous variables, which will be used to calculate total
* give prefix staff for a number of staff integer variables, which will be used to calculate total

	*****************************
	* Section 1 
	*****************************
	
	***** basic variables
	
		gen double facilitycode = q101
		lab var facilitycode "facility ID from sample list" 
		/*this will be used to merge with sampling weight, if relevant*/	

		gen country = "`country'"
		gen round 	=`round'
		gen month	=`month'
		gen year	=`year'
		
		
		
		//Jane and Ben 18022023
		gen zurban	=q105==1
		
		gen zlevel			=""
		replace zlevel	="CHPS" if q106==1
		replace zlevel	="Clinic" if q106==2
		replace zlevel	="Health Centre" if q106==3
		replace zlevel	="Polyclinic" if q106==4
		replace zlevel	="Hospital" if q106==5
		replace zlevel	="District Hospital" if q106==6
		replace zlevel	="Regional Hospital" if q106==7
		replace zlevel	="Teaching Hospital" if q106==8

		
		*gen zlevel_hospital		=q107>=`minhigh' & q107<=`maxhigh'
		*gen zlevel_low			=q107>=`minlow'  & q107<=`maxlow'
		
		gen zlevel_low		=q106>=`minhigh' & q106<=`maxhigh'
		gen zlevel_hospital			=q106>=`minlow'  & q106<=`maxlow'
		
		tab zlevel_low
		
		gen zpub	=q107>=`pubmin' & q107<=`pubmax'
			
			
		//Jane and Ben 18022023
		gen zc19cm=q109==1 /*NEW*/
			/*
			*MOST IMPORTANT CHECK before data collection! 
			*DOUBLE CHECK q110, filter for green/blue shaded questions in the tool
			gen temp=0 
			capture confirm variable q109
				if !_rc {
				replace temp = 1 if zlevel_hospital==1 | q109==1  	
				}
				else{
					replace temp = 1 if zlevel_hospital==1 
				}			
			
			tab zc19cm temp, m 
			drop temp
			*/
				
		lab define zurban 1"Rural" 2"Urban"
		lab define zlevel_hospital 0"Primary level" 1"Secondary level" 2 "Tertiary Level"
		lab define zpub 0"Non-public" 1"Public"
		lab define zc19cm 0"NOT eligible for C19CM questions" 1"eligible for C19CM questions"	

		lab values zurban zurban
		lab values zlevel_hospital zlevel_hospital
		lab values zpub zpub
		lab values zc19cm zc19cm

	*****************************
	* Section 2: Staffing: new infections, vaccination, and training
	*****************************

	***** staff: total number and total number infected by occupation groups
	
		egen staff_num_total_md=rowtotal(q20101a)
		egen staff_num_covidwk_md=rowtotal(q20101b)
		
		
		egen staff_num_total_nr=rowtotal(q20102a)
		egen staff_num_covidwk_nr=rowtotal(q20102b)
		
		// Ghana added Midwives 
		egen staff_num_total_mw=rowtotal(q20103a)
		egen staff_num_covidwk_mw=rowtotal(q20103b)

		egen staff_num_total_othclinical=rowtotal(q20104a q20105a q20106a q20107a q20110a q20111a )
		egen staff_num_covidwk_othclinical=rowtotal(q20104b q20105b q20106b q20107b q20110b q20111b)
		
		egen staff_num_total_clinical=rowtotal(staff_num_total_md staff_num_total_nr staff_num_total_mw staff_num_total_othclinical)
		egen staff_num_covidwk_clinical=rowtotal(staff_num_covidwk_md staff_num_covidwk_nr staff_num_covidwk_mw staff_num_covidwk_othclinical)
		
		egen staff_num_total_nonclinical=rowtotal( q20108a q20109a q20112a )
		egen staff_num_covidwk_nonclinical=rowtotal( q20108b q20109b q20112b)
		
		egen staff_num_total_all=rowtotal(staff_num_total_clinical staff_num_total_nonclinical) 
		egen staff_num_covidwk_all=rowtotal(staff_num_covidwk_clinical staff_num_covidwk_nonclinical) 
	
	***** staff: covax
	
		gen staff_num_covaxany  = q202
		gen staff_num_covaxfull = q203
		gen staff_num_covaxbooster = q204 /*NEW*/
		

	***** staff: absence 
	
		gen staff_num_absensce = q205 /*NEW*/	
		gen staff_num_absensce_covid = q206 /*NEW*/	
		gen xabsence=q205>=1 & q205!=. 
		gen xabsence_covid=	q206>=1 & q206!=. /*NEW*/
		
		
		/*once adjusted for the reference period, it is SIMILAR to previous "xabsence_medical"*/
	
	***** staff: training, supportive supervision, and mental health support 
	
		gen xtraining = q207==1 | q209==1
		global itemlist "01 02 03 04 05 06 07"
		foreach item in $itemlist{	
			gen byte xtraining__`item' = q208`item' ==1 /*select subitems changed*/
			}		
		
		global itemlist "01 02"
		foreach item in $itemlist{	
			gen byte xsupport__`item' = q210`item' ==1 /*select subitems changed*/ 
			}		
			
		gen xtraining__mental = q211==1
	
			local varlist xtraining__* /*indicators for the summary metrics*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')				
		gen xtraining_score	=100*(temp/max)
		gen xtraining_100 	=xtraining_score==100
		gen xtraining_50 	=xtraining_score>=50
			drop max temp
						
			local varlist xtraining__01 - xtraining__07 xsupport__* xtraining__mental /*indicators for the summary metrics*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')				
		gen xtrainingsupport_score	=100*(temp/max)
		gen xtrainingsupport_100	=xtrainingsupport_score==100
		gen xtrainingsupport_50 	=xtrainingsupport_score>=50
			drop max temp		

	sum staff* xabsence* xtraining* xsupport* 	
	
	/***** name sub-items *****/
		rename	xtraining__01	xtraining__ppe
		rename	xtraining__02	xtraining__ipccleaning /*NEW*/ 
		rename	xtraining__03	xtraining__ipcscreening	/*NEW*/ 	
		rename	xtraining__04	xtraining__ipchand /*NEW*/ 
		rename	xtraining__05	xtraining__triage	
		rename	xtraining__06	xtraining__emerg
		rename	xtraining__07	xtraining__remote

		rename	xsupport__01	xtraining__ss_ipc
		rename	xsupport__02	xtraining__ss_c19cm		
	
	*****************************
	* Section 3: Infection prevention and control
	*****************************
	
	***** IPC measures implemented
		gen xsafe= q301==1
		global itemlist "01 02 03 04 05 06 07"
		foreach item in $itemlist{	
			gen xsafe__`item' = q302`item' ==1
			}		
						
			local varlist xsafe__* /*indicators for the summary metrics*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')	
		gen xsafe_score	=100*(temp/max)
		gen xsafe_100 	=xsafe_score==100
		gen xsafe_50 	=xsafe_score>=50
			drop max temp
	// Added 06 for Re-Useable Mask (Cloth)
	***** PPE and IPC items
		global itemlist "01 02 03 04 05 06"
		foreach item in $itemlist{	
			gen xppe_all__`item' = q304`item'==1
			}						

			local varlist xppe_all__* /*indicators for the summary metrics*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')			
		gen xppe_all_score	=100*(temp/max)
		gen xppe_all_100 		=xppe_all_score==100
		gen xppe_all_50 		=xppe_all_score>=50
			drop max temp
			
		global itemlist "01 02 03 04"	
		foreach item in $itemlist{	
			gen xipcitem__`item' = q305`item'==1
			}						

			local varlist xipcitem__* /*indicators for the summary metrics*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')			
		gen xipcitem_score	=100*(temp/max)
		gen xipcitem_100 		=xipcitem_score==100
		gen xipcitem_50 		=xipcitem_score>=50
			drop max temp	
		
	***** IPC guideliens 
	// Jane and Ben added ==1
		gen xguideline= q306 == 1
		global itemlist "01 02 03 04 05 06 07"
		foreach item in $itemlist{	
			gen xguideline__`item' = q307`item' ==1
			}		
			
			local varlist xguideline__* /*indicators for the summary metrics*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')			
		gen xguideline_score	=100*(temp/max)
		gen xguideline_100 		=xguideline_score==100
		gen xguideline_50 		=xguideline_score>=50
			drop max temp
			
	sum xsafe* xppe* xipc* xguideline*
	
	/***** name sub-items *****/
		rename	xsafe__01	xsafe__staff_entrance
		rename	xsafe__02	xsafe__entrance_screening			
		rename	xsafe__03	xsafe__screening_c19 /*NEW*/
		/* similar to previous xsafe__triage_c19, but not really...*/
		rename	xsafe__04	xsafe__distancing
		rename	xsafe__05	xsafe__hygiene_instructions
		rename	xsafe__06	xsafe__hygiene_stations
		rename	xsafe__07	xsafe__cleaning
							
		rename	xppe_all__01	xppe_all__mask
		rename	xppe_all__02	xppe_all__respirator
		rename	xppe_all__03	xppe_all__gloves
		rename	xppe_all__04	xppe_all__gown		
		rename	xppe_all__05	xppe_all__goggles
		rename	xppe_all__06	xppe_all__clothmask
				
		rename	xipcitem__01	xipcitem__soap
		rename	xipcitem__02	xipcitem__sanitizer
		rename	xipcitem__03	xipcitem__biobag
		rename	xipcitem__04	xipcitem__boxes

		rename	xguideline__01	xguideline__screening
		rename	xguideline__02	xguideline__c19 /*NEW*/
		rename	xguideline__03	xguideline__ppe
		rename	xguideline__04	xguideline__masking /*NEW*/
		rename	xguideline__05	xguideline__c19_surveillance
		rename	xguideline__06	xguideline__envcleaning /*NEW*/
		rename	xguideline__07	xguideline__waste
		
	***** ADDITIONAL FROM "GLOBAL INDICATORS"

		*recalculate PPE with only masks, gloves, and respirators
		egen xxppe_total	= rowtotal(xppe_all__mask xppe_all__gloves xppe_all__respirator)
		gen xppe_essential_all_100	= xxppe_total==3
		gen xppe_essential_all_score= xxppe_total/3
			drop xxppe_total

		*recalculate PPE with only masks and gloves
		egen xxppe_total	 	= rowtotal(xppe_all__mask xppe_all__gloves)
		gen xppe_mask_glove_all_100 	= xxppe_total==2
		gen xppe_mask_glove_all_score	= xxppe_total/2
			drop xxppe_total		
		
		*recalculate IPC items without body bags
		egen xxipcitem_total	= rowtotal(xipcitem__soap xipcitem__sanitizer xipcitem__boxes xipcitem__biobag)
		gen xipcitem_nobodybag_100	= xxipcitem_total==4 /*same with xipcitem_100 in the combined version*/
		gen xipcitem_nobodybag_score= xxipcitem_total/4	 /*same with xipcitem_score in the combined version*/
			drop xxipcitem_total		
	
	*****************************
	* Section 4: Availability of services for COVID-19 case management
	*****************************	
		
	***** PT with suspected/confirmed C19: ALL facilities - Primary or Hospitals /*NEW*/
		
		gen xopt_covid = q401==1 /*suspected and confirmed*/ 
		
		global itemlist "01 02 03 04 05 06 07"
		foreach item in $itemlist{	
			gen xopt_covid__`item' 	= xopt_covid==1 & q402`item'==1 /* ALWAYS*/
			}	
			
		global itemlist "06 07"
		foreach item in $itemlist{	
			gen xopt_covidehs__`item' 	= xopt_covid==1 & q402`item'==1 /* ALWAYS*/
			}		
		
		rename	xopt_covid__01	xopt_covid__triage 
		rename	xopt_covid__02	xopt_covid__o2_measure
		rename	xopt_covid__03	xopt_covid__progmarker 
		rename	xopt_covid__04	xopt_covid__covax 
		rename	xopt_covid__05	xopt_covid__antiviral	
		rename  xopt_covidehs__06	xopt_covidehs__home_isolate 
		rename  xopt_covidehs__07 xopt_covidehs__refer 		
				
			local varlist xopt_covid__* /*indicators for the summary metrics*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'			
			egen temp=rowtotal(`varlist')			 
		gen xopt_covid_score	=100*(temp/max)
		gen xopt_covid_100 		=xopt_covid_score==100
		gen xopt_covid_50 		=xopt_covid_score>=50
			drop max temp	
		
		bysort zc19cm: sum xopt_covid*
		
			local varlist xopt_covid__* xopt_covidehs__* /*indicators for the summary metrics - for PHC*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'			
			egen temp=rowtotal(`varlist')			 
		replace xopt_covid_score	=100*(temp/max)			if zc19cm==0
		replace xopt_covid_100 		=xopt_covid_score==100	if zc19cm==0
		replace xopt_covid_50 		=xopt_covid_score>=50	if zc19cm==0
			drop max temp	
		
		bysort zc19cm: sum xopt_covid*
		
			foreach var of varlist xopt_covid__* xopt_covidehs__* xopt_covid_score xopt_covid_100 xopt_covid_50{
				replace `var'=. if xopt_covid==0 /*missing if no C19 OPT*/
				}		
				
			foreach var of varlist xopt_covidehs__* {
				replace `var'=. if xopt_covid==0 | zc19cm==1 /*missing if no C19 OPT*/
				}		
				
		bysort zc19cm: sum xopt_covid*		

	***** ER
	
		gen xer = q404==1 
		/*NOTE: can be stricter than previous xer, since two questions are used*/

		gen xer_triage = q405==1 /*NEW*/
		
			replace xer_triage=. if xer==0 /*missing if no ER*/
	
	***** IPT: general & COVID19		

		gen byte xipt= q407==1
		
	

		lab var xipt "facilities providing IPT services"
		
		gen ybed 			= q408 ==1
		gen ybed_icu 	 	= q409 ==1
			
		gen ybed_night   = q410
		gen ybed_icu_night   = q411 ==1 /*NEW*/
		
		gen xipt_surveillance = q412 ==1  /*NEW*/
			

	
		gen byte xipt_covid= q413==1 /*NEW*/
		
	
		lab var xipt_covid "facilities providing IPT services for C19 patients"
		
		gen ybed_covid_night   = q414==1
		
			foreach var of varlist xipt* ybed*{
				replace `var'=. if zc19cm==0 /*missing if NOT C19CM facilities*/
				}
			foreach var of varlist ybed*{
				replace `var'=. if xipt==0 /*missing if no IPT*/
				}	
			foreach var of varlist ybed_covid_night {
				replace `var'=. if xipt_covid==0 /*missing if no IPT for C19 patients*/
				}					
		
	***** IPT: severe/critical C19 cases		
	
		gen xcvd_ptsevere = q415==1  /*NEW*/
		
		global itemlist "01 02 03 04 05"
		foreach item in $itemlist{	
			gen xcvd_ptsevere__`item' 	= xcvd_ptsevere==1 & q416`item'==1 /* ALWAYS*/ /*NEW*/
			}	
						
			local varlist xcvd_ptsevere__* /*indicators for the summary metrics*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')			 			
		gen xcvd_ptsevere_score	=100*(temp/max)
		gen xcvd_ptsevere_100 	=xcvd_ptsevere_score==100
		gen xcvd_ptsevere_50 	=xcvd_ptsevere_score>=50
			drop max temp		
		
		gen xcvd_ptsevere_notable = q417==1 
		
		gen xcvd_ptsevere_repurpose	= q41801==1 
		gen xcvd_ptsevere_refer		= q41802==1 

			foreach var of varlist xcvd_ptsevere*{
				replace `var'=. if zc19cm==0 /*missing if NOT C19CM facilities*/
				}
			foreach var of varlist xcvd_ptsevere_*{
				replace `var'=. if xcvd_ptsevere==0 /*missing if no patients with severe/critical C19*/
				}					
		
	/***** name sub-items *****/
		
		rename	xcvd_ptsevere__01	xcvd_ptsevere__oxygen /*NEW*/
		rename	xcvd_ptsevere__02	xcvd_ptsevere__intubation /*NEW*/
		rename	xcvd_ptsevere__03	xcvd_ptsevere__ventilation /*NEW*/
		rename	xcvd_ptsevere__04	xcvd_ptsevere__iv /*NEW*/
		rename	xcvd_ptsevere__05	xcvd_ptsevere__glucosetest /*NEW*/
	
	
	*****************************
	* Section 5: Delivery and utilization of essential health services
	*****************************
		
	***** strategy change  /*NEW - ALL in Q502*/
	
		gen xstever_reduce_reduce	= q50101a==1 | q50102a==1 | q50103a==1
		gen xstever_reduce_redirect	= q50104a==1
		gen xstever_reduce_priority	= q50105a==1
		gen xstever_reduce_combine	= q50106a==1
		
		gen xstever_self			= q50107a==1
		gen xstever_home			= q50108a==1
		gen xstever_remote			= q50109a==1 
		gen xstever_prescription	= q50110a==1 | q50111a==1 | q50112a==1 
	
		gen xstmonth_reduce_reduce	= q50101b==1 | q50102b==1 | q50103b==1
		gen xstmonth_reduce_redirect= q50104b==1
		gen xstmonth_reduce_priority= q50105b==1
		gen xstmonth_reduce_combine	= q50106b==1

		gen xstmonth_self			= q50107b==1
		gen xstmonth_home			= q50108b==1
		gen xstmonth_remote			= q50109b==1 
		gen xstmonth_prescription	= q50110b==1 | q50111b==1 | q50112b==1 	
			
		global itemlist	"reduce_reduce reduce_redirect reduce_priority reduce_combine self home remote prescription" 
		foreach item in $itemlist {
			*tab xstmonth_`item' xstever_`item', m
			replace xstmonth_`item'=. if xstever_`item'==0
			}

	***** OPT change
		gen xopt_lower 	= q502==1 | q502==2 /*NEW*/
		gen xopt_similar= q502==3  /*NEW*/
		gen xopt_higher	= q502==4 | q502==5 /*NEW*/

		global itemlist "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17"
		foreach item in $itemlist{			
			gen xopt_lower_reason__`item' = q503`item'
			}
		
		global itemlist "1 2 3 4 5 6 7 8" 	
		foreach item in $itemlist{	
			gen xopt_higher_reason__`item' = q504`item'
			}
			
		global varlist "xopt_lower"
		foreach var in $varlist {
			gen `var'_reason_epi	 	= `var'==1 & (`var'_reason__1==1 | `var'_reason__2==1 ) /*NEW*/
			gen `var'_reason_comdemand  = `var'==1 & (`var'_reason__3==1 | `var'_reason__4==1  | `var'_reason__5==1  ) 
			gen `var'_reason_enviro 	= `var'==1 & (`var'_reason__6==1 | `var'_reason__7==1 )
			gen `var'_reason_cost	 	= `var'==1 & (`var'_reason__8==1 | `var'_reason__9==1 ) /*NEW*/
			gen `var'_reason_intention	= `var'==1 & (`var'_reason__10==1 | `var'_reason__11==1 | `var'_reason__12==1 | `var'_reason__16==1 )
			gen `var'_reason_disruption = `var'==1 & (`var'_reason__13==1 | `var'_reason__14==1 | `var'_reason__15==1 ) /*REVISED CODE: 37 added*/			
			}		
			
		global varlist "xopt_higher"
		foreach var in $varlist {
			gen `var'_reason_covidnow 	= `var'==1 & (`var'_reason__1==1 | `var'_reason__4==1  )
			gen `var'_reason_seasonal	= `var'==1 & (`var'_reason__2==1 ) /*NEW*/
			gen `var'_reason_gbv	    = `var'==1 & (`var'_reason__3==1 ) 
			gen `var'_reason_covidafter = `var'==1 & (`var'_reason__5==1 | `var'_reason__6==1 | `var'_reason__7==1 )
			/*NOTE: this is kept since comp data available, but prefer below two NEW indicators*/
			gen `var'_reason_catchup = `var'==1 & (`var'_reason__5==1 | `var'_reason__6==1 ) /*NEW*/
			gen `var'_reason_genpromo = `var'==1 & (`var'_reason__7==1 ) /*NEW*/
			
			}		
		
		foreach var of varlist xopt_lower_reason*{
			replace `var'=. if xopt_lower==0
			}
			
		foreach var of varlist xopt_higher_reason*{
			replace `var'=. if xopt_higher==0
			}			
			
			rename	xopt_lower_reason__1	xopt_lower_reason__less_ari
			rename	xopt_lower_reason__2	xopt_lower_reason__seasonal
			
			rename	xopt_lower_reason__3	xopt_lower_reason__changerecs
			rename	xopt_lower_reason__4	xopt_lower_reason__fear
			rename	xopt_lower_reason__5	xopt_lower_reason__lockdown
			rename	xopt_lower_reason__6	xopt_lower_reason__transport
			rename	xopt_lower_reason__7	xopt_lower_reason__costtrans /*NEW*/
			rename	xopt_lower_reason__8	xopt_lower_reason__othercom
			
			rename	xopt_lower_reason__9	xopt_lower_reason__servreduc
			rename	xopt_lower_reason__10	xopt_lower_reason__disrupt
			rename	xopt_lower_reason__11	xopt_lower_reason__hours
			rename	xopt_lower_reason__12	xopt_lower_reason__closure
			rename	xopt_lower_reason__13	xopt_lower_reason__drugs
			rename	xopt_lower_reason__14	xopt_lower_reason__staff
			rename	xopt_lower_reason__15	xopt_lower_reason__longwait	/*NEW*/
			rename	xopt_lower_reason__16	xopt_lower_reason__costserv	/*NEW*/
			rename	xopt_lower_reason__17	xopt_lower_reason__otherfac	

			rename	xopt_higher_reason__1	xopt_higher_reason__more_ari
			rename	xopt_higher_reason__2	xopt_higher_reason__seasonal /*NEW*/
			rename	xopt_higher_reason__3	xopt_higher_reason__gbv
			rename	xopt_higher_reason__4	xopt_higher_reason__redirect
			rename	xopt_higher_reason__5	xopt_higher_reason__backlog
			rename	xopt_higher_reason__6	xopt_higher_reason__react
			rename	xopt_higher_reason__7	xopt_higher_reason__comms
			rename	xopt_higher_reason__8	xopt_higher_reason__other	
			
		
				
	***** backlog /*ALL NEW*/
	
		global itemlist "01 02 03 04"
		foreach item in $itemlist{	
			gen xbacklogever__`item' = q505`item'a==1 
			replace xbacklogever__`item' = . if q505`item'a==3 
			}
		foreach item in $itemlist{	
			gen xbacklogmonth__`item' = q505`item'b==1 
			replace xbacklogmonth__`item' = . if q505`item'b==3
			}			
		
		global itemlist	"01 02 03 04" 
		foreach item in $itemlist {
			replace xbacklogmonth__`item'=. if xbacklogever__`item'==0
			}
			
		global itemlist "xbacklogever xbacklogmonth"	
		foreach item in $itemlist{	
			egen `item'_any=rowtotal(`item'__*) 	
			replace `item'_any = 1 if `item'_any>=2 & `item'_any!=.
			}	
		
		global itemlist "xbacklogever xbacklogmonth"
		foreach item in $itemlist{
			replace `item'_any=. if  `item'__01==. & ///
								`item'__02==. & ///
								`item'__03==. & ///
								`item'__04==. /*missing if N/A for all four services*/
			}		
		
			rename xbacklogever__01  xbacklogever__routine
			rename xbacklogever__02  xbacklogever__ncd
			rename xbacklogever__03  xbacklogever__infectiou
			rename xbacklogever__04  xbacklogever__elecsurg			

			rename xbacklogmonth__01  xbacklogmonth__routine
			rename xbacklogmonth__02  xbacklogmonth__ncd
			rename xbacklogmonth__03  xbacklogmonth__infectiou
			rename xbacklogmonth__04  xbacklogmonth__elecsurg
			
	***** community outreach
	
		gen xout = q506==1
		
		global itemlist "01 02 03 04 05"
		foreach item in $itemlist{	
			gen xout_decrease__`item' = q507`item'==1 |  q507`item'==2
			}

		egen temp=rowtotal(xout_decrease__*) 
		gen xout_decrease= temp>=1	
		drop temp
		
			foreach var of varlist xout_*{
				replace `var'=. if xout==0
				}
				
			rename	xout_decrease__01	xout_decrease__immun
			rename	xout_decrease__02	xout_decrease__malaria
			rename	xout_decrease__03	xout_decrease__ntd
			rename	xout_decrease__04	xout_decrease__cbc
			rename	xout_decrease__05	xout_decrease__home 				
		
	*****************************
	* Section 6: Medicines and supplies
	*****************************
	
	* QUESTION TO CHELSEA: 
	* should use use just "xdrug" for all mediciens or different prefixes like below?? 
	* trying to see what would be helpful for comparability
	* we can have both systems. see at the end of this section. pros and cons... 
				
		global itemlist "01 02 03 04 05 06 07 08 09 10 13 14 15 16 17 18"
		foreach item in $itemlist{	
			gen xdrugc19__`item' = q601`item' ==1 /*NEW? - TBD*/
			}			

		global itemlist "01 02 03 04 05 06 07 08 09 10 11 12" 
		foreach item in $itemlist{	
			gen xdrughosp__`item' = q602`item' ==1 /*NEW? - TBD*/
			}		
			
		global itemlist "01 02 03 04 05 06 07 08 09 " 
		foreach item in $itemlist{	
			gen xdrugehs__`item' = q603`item' ==1 /*NEW? - TBD*/
			}		
			
		global itemlist "01 02 03"
		foreach item in $itemlist{	
			gen xsupphosp__`item' = q604`item' ==1
			}
					
		global itemlist "drugc19 drughosp drugehs supphosp"
		foreach item in $itemlist{				
					
				local varlist x`item'__* /*indicators for the summary metrics*/ 
					preserve
					keep `varlist'
					d, short
					restore
				gen max=`r(k)'
				egen temp=rowtotal(`varlist')					
			gen x`item'_score	=100*(temp/max)
			gen x`item'_100 	=x`item'_score==100
			gen x`item'_50 		=x`item'_score>=50
				drop max temp
			}		
			
				foreach var of varlist xdrugc19* xdrughosp* xsupphosp*{
					replace `var'=. if zc19cm==0 /*missing if NOT C19CM facilities*/
					}		
					
			rename	xdrugc19__01	xdrugc19__dexamethasone
			rename	xdrugc19__02	xdrugc19__molnupiravir /*NEW*/
			rename	xdrugc19__03	xdrugc19__baracitanib /*NEW*/
			rename	xdrugc19__04	xdrugc19__casirivimab /*NEW*/
			rename	xdrugc19__05	xdrugc19__tocilizumab /*NEW*/
			rename	xdrugc19__06	xdrugc19__heparin /*NOT new - more specific than "Heparin" but not really differen (DH 7/12/2022)*/
			
			rename	xdrughosp__01	xdrughosp__alcohol
			rename	xdrughosp__02	xdrughosp__chlorine
			rename	xdrughosp__03	xdrughosp__paracetamol
			rename	xdrughosp__04	xdrughosp__ampicillin
			rename	xdrughosp__05	xdrughosp__ceftriaxone
			rename	xdrughosp__06	xdrughosp__azithromycin
			rename	xdrughosp__07	xdrughosp__rocuronium  /*NOT new - fully comparable as both are covered by “ … other neuromuscular blocker (injectable)” (DH 7/12/2022)*/
			rename	xdrughosp__08	xdrughosp__morphine
			rename	xdrughosp__09	xdrughosp__haloperidol
			rename	xdrughosp__10	xdrughosp__epinephrine			
			rename	xdrughosp__11	xdrughosp__oxytocin			
			rename	xdrughosp__12	xdrughosp__oxygen	
			
			rename	xdrugehs__01	xdrugehs__salbutamol
			rename	xdrugehs__02	xdrugehs__metformin
			rename	xdrugehs__03	xdrugehs__hydrochlorothiazide
			rename	xdrugehs__04	xdrugehs__carbamazapine
			rename	xdrugehs__05	xdrugehs__amoxicillin_tabs		
			rename	xdrugehs__06	xdrugehs__magnesiumsulphate
			rename	xdrugehs__07	xdrugehs__artemether
			rename	xdrugehs__08	xdrugehs__efavirenz
			rename	xdrugehs__09	xdrugehs__isoniazid
					
			rename	xsupphosp__01	xsupphosp__ivsets
			rename	xsupphosp__02	xsupphosp__nasalcanulae
			rename	xsupphosp__03	xsupphosp__facemasks		
		
		* TBD: Create/Clone medicines and supply individual indicators that have prefixes same with old indicators?? 
		
		global itemlist "xdrugc19 xdrughosp xdrugehs"
		foreach item in $itemlist{				
			foreach var of varlist `item'__*{
				clonevar x`var' = `var'
			}		
		}
		
			foreach var of varlist xsupphosp__*{
				clonevar x`var' = `var'
			}		
			
			rename (xxdrugc19__*) (xdrug__*) 
			rename (xxdrughosp__*) (xdrug__*) 
			rename (xxdrugehs__*) (xdrug__*) 
			rename (xxsupphosp__*) (xsupply__*) 
			
	*****************************
	* Section 7 : Equipment for COVID-19 case management
	*****************************

	***** Equipment 
		
		global itemlist "01 02 03 04"
		foreach item in $itemlist{	
			gen xequip_anyfunction__`item' = q701`item'==1 
			}			
			
			local varlist xequip_anyfunction__* /*indicators for the summary metrics*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')						
		gen xequip_anyfunction_score	=100*(temp/max)
		gen xequip_anyfunction_100		=xequip_anyfunction_score==100
		gen xequip_anyfunction_50		=xequip_anyfunction_score>=50
			drop max temp				

			rename	xequip_anyfunction__01	xequip_anyfunction__xray
			rename	xequip_anyfunction__02	xequip_anyfunction__oximeters
			rename	xequip_anyfunction__03	xequip_anyfunction__vicu
			rename	xequip_anyfunction__04	xequip_anyfunction__vnoninv			
		
			/*NOTE: depending on sample design, 			
			"xequip_anyfunction__xray" may be same with 
			"ximage_avfun__xray" AMONG HOSPITALS in old CEHS
			*/
		
	***** Oxygen
	
		gen xoxygen_concentrator= q70201==1 
		gen xoxygen_bulk 		= q70202==1 
		gen xoxygen_cylinder	= q70203==1 
		gen xoxygen_plant 		= q70204==1   
		
			egen temp=rowtotal(xoxygen_*)
		gen xoxygensource	=temp>=1
			drop temp
		
		gen xoxygen_dist 		 = q703==1
		gen xoxygen_portcylinder = q704==1
	
			foreach var of varlist xequip* xoxygen* {
				replace `var'=. if zc19cm==0 /*missing if NOT C19CM facilities*/
				}			

	***** ADDITIONAL FROM "GLOBAL INDICATORS"
		
		*calculate cross tabs of having ventilator BY TYPE	
		gen xequip_novent_anyfunction		= xequip_anyfunction__vicu==0 & xequip_anyfunction__vnoninv==0
		gen xequip_bothvent_anyfunction		= xequip_anyfunction__vicu==1 & xequip_anyfunction__vnoninv==1
		gen xequip_onlyinvvent_anyfunction	= xequip_anyfunction__vicu==1 & xequip_anyfunction__vnoninv==0
		gen xequip_onlyninvvent_anyfunction	= xequip_anyfunction__vicu==0 & xequip_anyfunction__vnoninv==1
		gen xequip_eithervent_anyfunction	= xequip_anyfunction__vicu==1 | xequip_anyfunction__vnoninv==1

		*create index with EITHER ventilator plus oxygen and oximeters
			local varlist xoxygensource xequip_eithervent_anyfunction xequip_anyfunction__oximeters 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')						
		gen xequip_anyvent_oxy_oximtr_score	=100*(temp/max)
		gen xequip_anyvent_oxy_oximtr_100	=xequip_anyvent_oxy_oximtr_score==100
			drop max temp		
		
		*create index with BOTH ventilator plus oxygen and oximeters
			local varlist xoxygensource xequip_bothvent_anyfunction xequip_anyfunction__oximeters
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')						
		gen xequip_bothvent_oxy_oximtr_score=100*(temp/max)
		gen xequip_bothvent_oxy_oximtr_100	=xequip_bothvent_oxy_oximtr_score==100
			drop max temp	
			
			foreach var of varlist xequip* xoxygen* {
				replace `var'=. if zc19cm==0 /*missing if NOT C19CM facilities*/
				}	
				
	*****************************
	* Section 8 : Diagnostics
	*****************************

	***** COVID diagnostics 
	
		gen xspcm	= q801==1
		gen xrdt 	= q802==1	
		gen xpcr 	= q803==1 & q804==1 /*OR IS IT NEW? SHOULD WE GIVE A DIFFERENT NAME? - TBD*/ 
		gen xonsite	= xpcr==1 | xrdt==1
		
		gen xpcr_equip	= q805==1
		gen xpcr_supply	= q806==1 /*NEW*/ 
				
		foreach var of varlist xpcr_*	{
			replace `var'=. if xpcr==0 /*missing if no PCR*/
			}	

		/*NOTE: 
		Ah, we used different names for very similar indicators between CEHS and C19CM.
		Clone those vars to facilitate trend analysis, in case. 
		*/ 	
		clonevar xcvd_test_pcr = xrdt 
		clonevar xcvd_test_rdt = xpcr 

	***** EHS diagnostics 		

		global itemlist "01 02 03 04 05 06" 
		foreach item in $itemlist{	
			gen xdiag_av_b`item' 	= q807`item'<=2 
			}	
		foreach item in $itemlist{	
			gen xdiag_avfun_b`item' = q807`item'<=1
			}			
			
		global itemlist "01 02 03 04"
		foreach item in $itemlist{	
			gen xdiag_av_h`item' 	= q808`item'<=2 		
			}		
		foreach item in $itemlist{	
			gen xdiag_avfun_h`item' = q808`item'<=1		
			}					
							
			local varlist xdiag_avfun_b* /*indicators for the summary metrics*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')						
		gen xdiagbasic_score	=100*(temp/max)
		gen xdiagbasic_100 	=xdiagbasic_score==100
		gen xdiagbasic_50 	=xdiagbasic_score>=50
			drop max temp
			
			local varlist xdiag_avfun_b* /*indicators for the summary metrics: for non-hospitals*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen maxnonhospital=`r(k)'
			egen tempnonhospital=rowtotal(`varlist')	
			
			local varlist xdiag_avfun_b* xdiag_avfun_h* /*indicators for the summary metrics: for hospitals*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen maxhospital=`r(k)'
			egen temphospital=rowtotal(`varlist')	
			
			gen max=.
				replace max=maxnonhospital  if zlevel_hospital!=0 /*non-hospital*/
				replace max=maxhospital 	if zlevel_hospital==0 /*hospital*/
			gen temp=.
				replace temp=tempnonhospital if zlevel_hospital!=0 /*non-hospital*/
				replace temp=temphospital 	if zlevel_hospital==0 /*hospital*/
		gen xdiag_score	=100*(temp/max)
		gen xdiag_100 	=xdiag_score==100
		gen xdiag_50 	=xdiag_score>=50
			drop max* temp*
			
		foreach var of varlist xdiag_av_h* xdiag_avfun_h* {
			replace `var'=. if zlevel_hospital==1 /*missing if NOT hospital*/
			}				
			
			rename	xdiag_av_b01	xdiag_av__bloodglucose
			rename	xdiag_av_b02	xdiag_av__urineglucose
			rename	xdiag_av_b03	xdiag_av__urineprotein
			rename	xdiag_av_b04	xdiag_av__pregnancy
			rename	xdiag_av_b05	xdiag_av__hbg /*NEW - revised*/
			rename	xdiag_av_b06	xdiag_av__malaria
			
			rename	xdiag_av_h01	xdiag_av__h_hiv
			rename	xdiag_av_h02	xidag_av__h_tb
			rename	xdiag_av_h03	xdiag_av__h_bloodtype
			rename	xdiag_av_h04	xdiag_av__h_bloodcreatine
			
			rename	xdiag_avfun_b01	xdiag_avfun__bloodglucose
			rename	xdiag_avfun_b02	xdiag_avfun__urineglucose
			rename	xdiag_avfun_b03	xdiag_avfun__urineprotein
			rename	xdiag_avfun_b04	xdiag_avfun__pregnancy
			rename	xdiag_avfun_b05	xdiag_avfun__hbg /*NEW - revised*/
			rename	xdiag_avfun_b06	xdiag_avfun__malaria

			rename	xdiag_avfun_h01	xdiag_avfun__h_hiv
			rename	xdiag_avfun_h02	xidag_avfun__h_tb
			rename	xdiag_avfun_h03	xdiag_avfun__h_bloodtype
			rename	xdiag_avfun_h04	xdiag_avfun__h_bloodcreatine
			
	***** ADDITIONAL FROM "GLOBAL INDICATORS"
	
		*create cross-tabs of doing PCR, RDT, both, neither
		gen xcovid_diag_none		= xpcr==0 & xrdt==0
		gen xcovid_diag_pcr_only	= xpcr==1 & xrdt==0
		gen xcovid_diag_rdt_only	= xpcr==0 & xrdt==1
		gen xcovid_diag_pcr_and_rdt	= xpcr==1 & xrdt==1

		foreach var of varlist xcovid_diag_*	{
			replace `var'=. if xspcm==0 /*missing if no test at all*/
			}
			
		gen xcovid_diag_pcr_or_rdt	=xcovid_diag_none==0 /*this is same with above "xonsite" */
			
	*****************************
	* Section 9: Vaccination
	*****************************

	***** Childhood immunization 

		gen xvaccine_child=q901==1 
		gen xvac= q901==1 
		
		/*NOTE:
		Technically not same with previous "xvac", which included child AND adult vaccination. 
		But, practically, it will be close to identical - 
		since child vaccination is almost universally available - in low resource settings, at least. 
		*/
		
		gen xvac_av_fridge 			= q902==1 | q902==2
		gen xvac_avfun_fridge 		= q902==1 
		gen xvac_avfun_fridgetemp 	= q902==1 & q903==1

		global itemlist "01 02 03 04 05 06 07"
		foreach item in $itemlist{	
			gen xvaccine__`item' = q904`item' ==1
			}	
		
			local varlist xvaccine__* /*indicators for the summary metrics*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')					
		gen xvac_score	=100*(temp/max)
		gen xvac_100 	=xvac_score==100
		gen xvac_50 	=xvac_score>=50
			drop max temp

		gen xvac_syrstockout = q905==1
		
			rename	xvaccine__01	xvaccine__mcv
			rename	xvaccine__02	xvaccine__dtp
			rename	xvaccine__03	xvaccine__polio_oral /*NEW*/
			rename	xvaccine__04	xvaccine__polio_inj /*NEW*/
			rename	xvaccine__05	xvaccine__bcg
			rename	xvaccine__06	xvaccine__pneumo
			rename	xvaccine__07	xvaccine__hpv /*NEW*/
		
		foreach var of varlist xvac_* xvaccine__*  {	
			replace `var'	=. if xvaccine_child!=1 /*missing if no child vaccine services*/
			}		

	***** COVAX
	
		gen xcovax = q906==1
		/*Koforidua
		gen xcovax_av_fridge 			= q907==1 | q907==2 /*NEW*/
		gen xcovax_avfun_fridge 		= q907==1  /*NEW*/
		gen xcovax_avfun_fridgetemp 	= q907==1 & q908==1 /*NEW*/		*/
		
		*global itemlist "001 002 003 004 005 006 007"
		global itemlist "01 02 03 04 05 06 07 08"
		foreach item in $itemlist{	
			gen xcovax_offer__`item' = q909`item'==1 | q909`item'==2 
			gen xcovax_offerav__`item' = q909`item'==1 
			}
			
		gen xcovax_report = q910==1 
		
		global itemlist "01 02 03 04"
		foreach item in $itemlist{	
			gen xcovax_train__`item' = q911`item'==1
			}		
		
		gen xcovax_syrstockout	=q912==1 /*NEW*/ 

		foreach var of varlist xcovax_*{
			replace `var'=. if xcovax!=1 /*missing if no COVID-19 vaccine services*/
			}			
			
			rename	 xcovax_offer__01	xcovax_offer__pfizer
			rename	 xcovax_offerav__01	xcovax_offerav__pfizer
			rename	 xcovax_offer__02	xcovax_offer__moderna
			rename	 xcovax_offerav__02	xcovax_offerav__moderna
			rename	 xcovax_offer__03	xcovax_offer__astra
			rename	 xcovax_offerav__03	xcovax_offerav__astra
			rename	 xcovax_offer__04	xcovax_offer__jj
			rename	 xcovax_offerav__04	xcovax_offerav__jj
			rename	 xcovax_offer__05	xcovax_offer__covishiled
			rename	 xcovax_offerav__05	xcovax_offerav__covishiled
			/*
			rename	 xcovax_offer__006	xcovax_offer__sinopharm
			rename	 xcovax_offerav__006	xcovax_offerav__sinopharm	
			rename	 xcovax_offer__007	xcovax_offer__sinovac
			rename	 xcovax_offerav__007	xcovax_offerav__sinovac
			*/
			
			rename	 xcovax_train__01	xcovax_train__storage
			rename	 xcovax_train__02	xcovax_train__admin
			rename	 xcovax_train__03	xcovax_train__manage_adverse
			rename	 xcovax_train__04	xcovax_train__report_adverse			

	***** AEFI 
		
		gen xaefikit 		= q913==1 /*NEW - but this will be very similar to "xvac_aefikit"*/
		gen xaefireport 	= q914==1 /*NEW - but this will be very similar to "xvac_aefireport"*/	
		
		foreach var of varlist xaefi*{
			replace `var'=. if xvaccine_child==0 & xcovax==0 /*missing if no vaccine services*/
			}	
			
	***** ADDITIONAL FROM "GLOBAL INDICATORS"
	
		*Get information on COVAX
		egen numb_offer	 = rowtotal(xcovax_offer__*)
		gen xcovax_offer = numb_offer>=1
			drop numb_offer
			
		egen numb_avail	 = rowtotal(xcovax_offerav__*)
		gen xcovax_avail = numb_avail>=1
			drop numb_avail

		gen xcovax_offer_avail=1
			replace xcovax_offer_avail=0 if xcovax_offer==1 & xcovax_avail==0
			replace xcovax_offer_avail=. if xcovax_offer==0
			
		foreach var of varlist xcovax_avail xcovax_offer xcovax_offer_avail {
			replace `var'=. if xcovax!=1 /*missing if no COVID-19 vaccine services*/
			}			

			
	sort facilitycode
	save CombinedCOVID19HFA_`country'_R`round'.dta, replace 		
	
*****E.3. Merge with sampling weight 
***** MUST select/run Chunk A or B, depending on the sample design 
/*RUN this chunk A if there is samplingb weight*/
*CHUNK A BEGINS  
/*
import excel "$chartbookdir/GH_CombinedCOVID19HFA_Chartbook.xlsx", sheet("Weight") firstrow clear

	rename *, lower

		sum weight
		*****CHECK HERE: 
		*		check if weight distribution is normalized with mean=1 
		*		if not, we have to rescale so that the mean of sampling weight==1

		replace weight=weight / r(mean) /*if already normalized, this line does not change anything*/
			
		sum weight
	
	sort facilitycode	
	merge facilitycode using CombinedCOVID19HFA_`country'_R`round'.dta, 
	
		tab _merge
		*****CHECK HERE: 
		*		all should be 3 (i.e., match) by the end of the data collection

		drop _merge*
		
	sort facilitycode /*this is generated from Lime survey*/
	save CombinedCOVID19HFA_`country'_R`round'.dta, replace 		
*/	
*CHUNK A ENDS

/*RUN this chunk B if there is NO samplingb weight
*CHUNK B BEGINS  	

	gen weight=1 

*CHUNK B BEGINS  
*/
	
*****E.4. Export clean facility-level data to chart book 
	
	save CombinedCOVID19HFA_`country'_R`round'.dta, replace 		

	
	export delimited using CombinedCOVID19HFA_`country'_R`round'.csv, replace 

	export excel using "$chartbookdir/GH_CombinedCOVID19HFA_Chartbook.xlsx", sheet("Facility-level cleaned data") sheetreplace firstrow(variables) nolabel
	
	
	
**************************************************************
* F. Create indicator estimate data 
**************************************************************

	
use CombinedCOVID19HFA_`country'_R`round'.dta, clear

	***** To get the total number of observations per relevant part 
	
	gen obs=1 	
	//Ghana added  obs_cvd_pt 			
	gen obs_cvd_pt=1 			if q401==1
	gen obs_c19cm=1 		if zc19cm==1
		
	gen obs_opt_covid=1 	if xopt_covid==1 	/*facilities that provide OPT services for patients with suspected/confirmed C19*/
	gen obs_er=1 			if xer==1 			/*facilities that provide 24-hour staffed ER services*/
	gen obs_ipt=1 			if q407==1		/*facilities that provide IPT services*/
	
	
	tab obs_ipt
	

	
	//Jane and Ben changed xipt_covid to q413 
	gen obs_ipt_covid=1 	if q413==1 
	
	
	/*facilities that provide IPT services for patients with C19*/
	gen obs_ipt_cvdptsev=1 	if q415==1 /*facilities that provide services for patients with severe or critical C19*/

	
	
	gen obs_pcr=1 			if xpcr==1 			/*facilities that conduct PCR on site*/
	
	gen obs_vac=1 			if xvac==1
	
	gen obs_covax=1 		if xcovax==1	
	
	/*
	gen xresult=q1004==1
	tab xresult, m
	keep if xresult==1
	drop xresult	
	*/
	
			
	save temp.dta, replace 

*****F.1. Calculate estimates  

	
	use temp.dta, clear

	collapse (count) obs* (mean) x*  (sum) staff_num_* ybed*, by(country round month year  )
		gen group="All"
		gen grouplabel="All"

		keep obs* country round month year  group* x*  y* staff_num_* 
		
		save summary_CombinedCOVID19HFA_`country'_R`round'.dta, replace 
		
	use temp.dta, clear
	collapse (count) obs* (mean) x* (sum) staff_num_* ybed*, by(country round month year   zurban)
		gen group="Location"
		gen grouplabel=""
			replace grouplabel="Rural" if zurban==0
			replace grouplabel="Urban" if zurban==1
		keep obs* country round month year  group* x*  y* staff_num_* 
		
		append using summary_CombinedCOVID19HFA_`country'_R`round'.dta, force
		save summary_CombinedCOVID19HFA_`country'_R`round'.dta, replace 

	use temp.dta, clear
	collapse (count) obs* (mean) x* (sum) staff_num_* ybed*, by(country round month year   zlevel_hospital)
		gen group="Level"
		gen grouplabel=""
			replace grouplabel="Primary Facility" if zlevel_hospital==1
			replace grouplabel="Secondary Facility" if zlevel_hospital==0
			
			
			
			
		keep obs* country round month year group* x*  y* staff_num_* 
			
		append using summary_CombinedCOVID19HFA_`country'_R`round'.dta
		save summary_CombinedCOVID19HFA_`country'_R`round'.dta, replace 
		
	use temp.dta, clear
	
	collapse (count) obs* (mean) x* (sum) staff_num_* ybed*, by(country round month year   zpub)
		gen group="Sector"
		gen grouplabel=""
			replace grouplabel="Non-Government" if zpub==0
			replace grouplabel="Government" if zpub==1
		keep obs* country round month year  group* x*  y* staff_num_* 
		
		append using summary_CombinedCOVID19HFA_`country'_R`round'.dta		
		save summary_CombinedCOVID19HFA_`country'_R`round'.dta, replace 
		
	use temp.dta, clear	
	collapse (count) obs* (mean) x* (sum) staff_num_* ybed*, by(country round month year   zc19cm)
		gen group="C19CM eligibility"
		gen grouplabel=""
			replace grouplabel="non-C19CM (or CEHS) facilities" if zc19cm==0
			replace grouplabel="C19CM facilities" if zc19cm==1
		keep obs* country round month year  group* x*  y* staff_num_* 
		
		append using summary_CombinedCOVID19HFA_`country'_R`round'.dta		
		save summary_CombinedCOVID19HFA_`country'_R`round'.dta, replace 		
			

	erase temp.dta	
			
	***** convert proportion to %		
	foreach var of varlist x*{
		replace `var'=round(`var'*100, 1)	
		}
			* But, convert back variables that were incorrectly converted (e.g., score)	
			foreach var of varlist *_score {
				replace `var'=round(`var'/100, 1)	
				}		

			
	***** generate staff infection rates using the pooled data	
	global itemlist "md mw nr othclinical clinical nonclinical all" 
	foreach item in $itemlist{	
		gen xstaff_pct_covidwk_`item' = round(100* (staff_num_covidwk_`item' / staff_num_total_`item' ), 0.1)
		}	
		
	***** generate COVID-19 vaccine among staff using the pooled data	
		gen xstaff_pct_covaxany  = round(100*staff_num_covaxany  / staff_num_total_all, 1)
		gen xstaff_pct_covaxfull = round(100*staff_num_covaxfull / staff_num_total_all, 1)
		//Jane and Ben added percentage for booster
		gen xstaff_pct_booster = round(100*staff_num_covaxbooster / staff_num_total_all, 1)
	
	tab group round, m
	
	***** round the number of observations, in case sampling weight was used
	foreach var of varlist obs*{
		replace `var' = round(`var', 1)
		}	
		
	***** round the number of staff pooled from all facilities, in case sampling weight was used
	foreach var of varlist staff_num*{
		replace `var' = round(`var', 1)
		}			

	***** organize order of the variables by section in the questionnaire  
	gen module = "Combined" /*module tag for appending all summary data later*/
	
	***** order columns & sort rows
	order module country round year month group grouplabel obs* staff*
		
	sort module country round year month group grouplabel
	
save summary_CombinedCOVID19HFA_`country'_R`round'.dta, replace 

export delimited using summary_CombinedCOVID19HFA_`country'_R`round'.csv, replace 

*****F.2. Export indicator estimate data to chartbook AND dashboard

use summary_CombinedCOVID19HFA_`country'_R`round'.dta, clear

	gen updatedate = "$date"

	local time=c(current_time)
	gen updatetime=""
	replace updatetime="`time'"


export excel using "$chartbookdir/GH_CombinedCOVID19HFA_Chartbook.xlsx", sheet("Latest indicator estimate data") sheetreplace firstrow(variables) nolabel keepcellfmt


		
/* To check against R results
export delimited using "~/Dropbox/0 iSquared/iSquared_WHO/ACTA/3.AnalysisPlan/summary_CombinedCOVID19HFA_`country'_R`round'_Stata.csv", replace 
*/

**************************************************************
* G. MINIMUM data quality check 
**************************************************************

capture log close
log using DataCheck_CombinedCOVID19HFA_`country'_R`round'_$date.log, replace

*** Minimum red-flag indicators will be listed. So, the shorter log, the better.  

use summary_CombinedCOVID19HFA_`country'_R`round'.dta, clear	

	sort group grouplabel

*** 1. Estimates exceeding boundaries 
	/*
	Estimates for percent or score (0-100) that exceed boundaris.  
	For example, xdrug_100 MUST BE BETWEEN 0 and 100.  
	*/
			foreach var of varlist x* *_score{
				list group grouplabel `var' if `var'<0 | (`var'>100 & `var'!=.)
			}			

*** 2. Comparing more vs. less restrictive indicators: all vs. half of the tracer items 
	/*
	Pairs where more restrictive indicator is higher than less restrictive indicator
	For example, xdrug_100 MUST BE ALWAYS EQUAL TO OR LOWER THAN xdrug_100
	*/
	
			*d *_100 /*NOTE: get the list of variables ending with _100 and adjust itemlist as needed */
			
			#delimit;
			global itemlist "
				xtraining xtrainingsupport 
				xsafe xppe_all xipcitem xguideline 
				xopt_covid xcvd_ptsevere
				xdrugc19 xdrughosp xdrugehs xsupphosp 
				xequip_anyfunction xdiagbasic xdiag 
				xvac
				" ;
				#delimit cr
			foreach item in $itemlist{	
				list group grouplabel `item'_100 `item'_50  if `item'_100 > `item'_50
			}			   

*** 3. Comparing more vs. less restrictive indicators: more 
	/*
	Pairs where more restrictive indicator is higher than less restrictive indicator
	For example, xcovax_offerav__jj MUST BE ALWAYS EQUAL TO OR LOWER THAN xcovax_offer__jj
	*/
				
			*global itemlist "pfizer moderna astra jj covishiled sinopharm sinovac"
			global itemlist "pfizer moderna astra jj covishiled"
			foreach item in $itemlist{	
				list group grouplabel xcovax_offerav__`item' xcovax_offer__`item' ///
					if xcovax_offerav__`item' > xcovax_offer__`item' 
			}	
			
	/*
	Quiz: 
	How about this pair? 
	Is it possible that "xdiag_score" is higher than "xdiagbasic_score"??  
	*/
	
			list group grouplabel obs xdiagbasic_score xdiag_score  ///
				if xdiag_score  > xdiagbasic_score  
	
log close

**************************************************************
* H. Append with previous "indicator estimate data" 
**************************************************************

/*

* This section is to facilitate trend analysis for select key indicators. 
* WHO/HQ WILL CREATE the "lavender" tab (i.e., "Past indicator estimate data") for each country's chartbook. 
* This lavender tab includes key indicator estimates from all previous rounds. 
* Further, 
*		1. for indicators that are common in both C19CM and CEHS tools, HQ calculated the indicators using pulled facility-level data.
* 		2. for indicators that have a revised name, indicator names in the past data have been renamed. 

* The do file is: "Code to combine previous modules to all for trending with new rounds.do"
* Saved in the sharepoint folder:
* "HSA unit/4 Databases, analyses & dashboards/2 HFAs for COVID-19/2. Analysis files/STATA code/code to create global database/"
	
* The "global" dataset is: "combined_new_elements.dta"
* Saved in the sharepoint folder: 
* "HSA unit/4 Databases, analyses & dashboards/2 HFAs for COVID-19/1. Database/"
	
* WHO/HQ TO UPDATE THE FOLLOWING DIRECTORY AS NEEDED 
use "~/Dropbox/0iSquared/iSquared_WHO/ACTA/5.Dashboard/1 Database/combined_new_elements.dta", clear

	keep if country=="Ghana"
	replace country = "`country'"

	keep if module=="Combined"
	
	order module country round year month group grouplabel obs*
				
	*export excel using "$chartbookdir/CombinedCOVID19HFA_Chartbook_draft.xlsx", ///
	*	sheet("Past indicator estimate data") sheetreplace firstrow(variables) nolabel keepcellfmt
	export excel using "$chartbookdir/GH_CombinedCOVID19HFA_Chartbook.xlsx", ///
		sheet("Past indicator estimate data") sheetreplace firstrow(variables) nolabel keepcellfmt

*/

import excel "$chartbookdir/GH_CombinedCOVID19HFA_Chartbook.xlsx", sheet("Past indicator estimate data") firstrow clear
	
	save temp.dta, replace
	
import excel "$chartbookdir/GH_CombinedCOVID19HFA_Chartbook.xlsx", sheet("Latest indicator estimate data") firstrow clear
		
		d, short
		*local indicatorlist = "`r(varlist)'"
		*d `indicatorlist'
				
	append using temp.dta, force
		
		d, short
		
export excel using "$chartbookdir/GH_CombinedCOVID19HFA_Chartbook.xlsx", sheet("All round data") sheetreplace firstrow(variables) nolabel keepcellfmt		

erase temp.dta
	
*END OF DATA CLEANING AND MANAGEMENT 

**************************************************************
* I. Quick scan of trends 3/29/2023
**************************************************************

	***Keep variables that wre in multiple rounds
	
		foreach var of varlist obs* x* y* staff* {
			quietly sum `var'
 
			/* Indicators in roudns 2 and 3 */
			*if r(N)<14{ 
			/* Indicators in all three rounds */
			if r(N)!= _N{			
				drop `var'
			}					
		}		
	
		d, short	

	***Keep observations/analysis domain (aka "grouplabel") that are in all three rounds

		tab grouplabel round, m
			replace grouplabel = "Government" if grouplabel=="Public"
			replace grouplabel = "Non-Government" if grouplabel=="Non-Public"
		tab grouplabel round, m
		
		bysort grouplabel: gen temp = _N	
		drop if temp<3
	
	***Quick scan of trends	
	capture putdocx clear 
	putdocx begin
	
		foreach var of varlist xppe* xipc* xcovid_diag_pcr_or_rdt xcovax_offer*{
			
			#delimit; 
			graph bar `var', over(round)  
				by(grouplabel, 
					title(" '`var'' over the three rounds", size(medium)) note("") row(1)) 
				blabel(bar)
				ytitle("Percentage of sentinel facilities", size(small)) 
			; 
			#delimit cr
			
			graph save Graph "Figures/Trend_`var'.gph", replace
			
			graph export graph.png, replace	
		
		putdocx paragraph
		putdocx text ("`var'"), linebreak	
		putdocx image graph.png			
			
		}	
				
			#delimit; 
			graph bar 
				xcovid_diag_pcr_and_rdt
				xcovid_diag_pcr_only 
				xcovid_diag_rdt_only 
				xcovid_diag_none , over(round)  
				by(grouplabel, 
					title(" 'xcovid_diag' over the three rounds", size(medium)) note("") row(1)) 
				stack	
				bar(1, color(ebblue*2)) bar(2, color(ebblue*1))  bar(3, color(ebblue*0.5))  bar(4, color(gray*0.5))
				legend(rows(1) label(1 "PCR & RDT") label(2 "PCR") label(3 "RDT") label(4 "None"))
				ytitle("Percentage of sentinel facilities", size(small)) 
			; 
			#delimit cr
			
			graph save Graph "Figures/Diag_Trend_stackbar.gph", replace
			
			graph export graph.png, replace	
		
		putdocx paragraph
		putdocx text ("`var'"), linebreak	
		putdocx image graph.png					
		
		erase graph.png
		
	putdocx save Quick_Scan_Trends_$date.docx, replace			
	
END OF DATA CLEANING AND MANAGEMENT - CONGRATULATIONS! 	
