clear
clear matrix
clear mata
capture log close
set more off

*************************************************************************************************
* A SETTING 
*************************************************************************************************

cd "C:\Users\YoonJoung Choi\Dropbox\0 iSquared\iSquared_WHO\ACTA\3.AnalysisPlan\"
*dir

	clear
	set obs 100
	set seed 38
	
*************************************************************************************************
* B. Dummy data construction (n=100)
*************************************************************************************************

	gen id=_n
	
	gen submitdate ="10/12/2020 10:55"
	gen startdate ="10/12/2020 10:55"
	gen datestamp ="10/12/2020 10:55"
	
	******************** Section 1
	global numlist "101 102 103 104 105 106 107 108 109 110"
	foreach num in $numlist{	
		gen q`num' = "" 
		}
	ok
	#delimit;
	gen rannum = uniform(); egen q111 = cut(rannum), group(2); drop rannum; 
	gen q112 = runiformint(30, 50); 
	gen rannum = uniform(); egen q113 = cut(rannum), group(4); drop rannum;
	gen rannum = uniform(); egen q114 = cut(rannum), group(3); drop rannum; 
	#delimit cr

	global varlist "111 113 114"
	foreach var in $varlist{	
		replace q`var' = q`var' + 1
		}	

	******************** Section 2: Need and use 

	global numlist "001 "
	foreach num in $numlist{	
		gen rannum = uniform()
		gen q201_`num'=1
			replace q201_`num'	=2 if rannum >= .8
			replace q201_`num'	=3 if rannum >= .9
		drop rannum
		}
		
	global numlist "002 003 004 005 006"
	foreach num in $numlist{	
		gen rannum = uniform()
		gen q201_`num'=1
			replace q201_`num'	=2 if rannum >= .6
			replace q201_`num'	=3 if rannum >= .9
		drop rannum
		}
		
	global numlist "007 008 009"
	foreach num in $numlist{	
		gen rannum = uniform()
		gen q201_`num'=1
			replace q201_`num'	=2 if rannum >= .5
			replace q201_`num'	=3 if rannum >= .8
		drop rannum
		}		
		
	******************** Section 3: Barriers 
	
	global numlist "001 002"
	foreach num in $numlist{	
		gen rannum = uniform()
		egen temp = cut(rannum), group(9)
		gen q301_`num' = temp==0
		drop rannum temp
		}
		
	global numlist "003 004 005 006 007"
	foreach num in $numlist{	
		gen rannum = uniform()
		egen temp = cut(rannum), group(8)
		gen q301_`num' = temp==0
		drop rannum temp
		}
		
	global numlist "008 009 010 011 012 013 014 015 016 017"
	foreach num in $numlist{	
		gen rannum = uniform()
		egen temp = cut(rannum), group(7)
		gen q301_`num' = temp==0
		drop rannum temp
		}		
		
	global numlist "302"
	foreach num in $numlist{	
		gen rannum = uniform()
		egen q`num' = cut(rannum), group(3)
		replace q`num' = q`num' + 1
		drop rannum
		}

	global numlist "001 002 003 004 005"
	foreach num in $numlist{	
		gen rannum = uniform()
		egen temp = cut(rannum), group(4)
		gen q303_`num' = temp==0
		drop rannum temp
		}
		
	global numlist "006 007 008 009 010"
	foreach num in $numlist{	
		gen rannum = uniform()
		egen temp = cut(rannum), group(5)
		gen q303_`num' = temp==0
		drop rannum temp
		}
		
	global numlist "011 012 013 014 015"
	foreach num in $numlist{	
		gen rannum = uniform()
		egen temp = cut(rannum), group(7)
		gen q303_`num' = temp==0
		drop rannum temp
		}	
	
	foreach var of varlist q303_*{
		replace `var'=. if q302==1 /*skip pattern*/
		}
	
	global numlist "304"
	foreach num in $numlist{	
		gen rannum = uniform()
		egen q`num' = cut(rannum), group(2)
		drop rannum
		}		

	global numlist "001 002 003 004 005 006 007"
	foreach num in $numlist{	
		gen rannum = uniform()
		egen temp = cut(rannum), group(8)
		gen q305_`num' = temp==0
		replace q305_`num' =. if q304!=1 /*SKIP pattern*/
		drop rannum temp
		}
		
	global numlist "001 002 003 004 005 006 007 008 009 010 011"
	foreach num in $numlist{	
		gen rannum = uniform()
		egen temp = cut(rannum), group(7)
		gen q306_`num' = temp==0
		drop rannum temp
		}		
		
	******************** Section 4: Attitude towards COVID-19 vaccine 
	
	global numlist "401 402 403"
	foreach num in $numlist{	
		gen rannum = uniform()
		egen q`num' = cut(rannum), group(4)
		replace q`num' = q`num' + 1
		drop rannum 
		}		
		
	global numlist "001 002 003 004 005 006 007 008"
	foreach num in $numlist{	
		gen rannum = uniform()
		egen temp = cut(rannum), group(7)
		gen q404_`num' = temp==0
		replace q404_`num' =. if q402==1 & q403==1 /*SKIP pattern*/
		drop rannum temp
		}	
		
	******************** Section 5: CHW service delivery 
	
	gen q501 =uniform() < .6 /*60% yes*/
	
		gen rannum = uniform()
	egen q502 = cut(rannum), group(5)
		replace q502 = q502+1
		drop rannum 
	
	global numlist "001 002 003 004 005 006"
	foreach num in $numlist{	
		gen rannum = uniform()
		egen temp = cut(rannum), group(7)
		gen q503_`num' = temp==0
		replace q503_`num' =. if q502<=2 /*SKIP pattern*/
		drop rannum temp
		}	

	global numlist "504 505"
	foreach num in $numlist{	
		gen rannum = uniform()
		egen q`num' = cut(rannum), group(3)
		replace q`num' = q`num' + 1
		drop rannum 
		}	
		
	global numlist "001 002 003 004 005"
	foreach num in $numlist{	
		gen rannum = uniform()
		egen temp = cut(rannum), group(7)
		gen q506_`num' = temp==0
		replace q506_`num' =. if q505==1 /*SKIP pattern*/
		drop rannum temp
		}		
		
	global numlist "001 002 003"
	foreach num in $numlist{	
		gen rannum = uniform()
		gen q507_`num'=1
			replace q507_`num'	=2 if rannum >= .25
			replace q507_`num'	=3 if rannum >= .75
			replace q507_`num'	=4 if rannum >= .9
		drop rannum
		}		
		
	global numlist "004 005"
	foreach num in $numlist{	
		gen rannum = uniform()
		gen q507_`num'=1
			replace q507_`num'	=2 if rannum >= .05
			replace q507_`num'	=3 if rannum >= .4
			replace q507_`num'	=4 if rannum >= .5
		drop rannum
		}				
	
	******************** Section 5: CHW service delivery 
	
	gen q601 =uniform() < .8 /*80% yes*/
	gen q602=""
	gen q603=""

		gen rannum = uniform()
	gen q604=1
		replace q604	=4 if rannum >= .9
		replace q604	=5 if rannum >= .95
		drop rannum
		
*************************************************************************************************
* B. Export
*************************************************************************************************
	
sum 	

export delimited using ExportedCSV_FromLimeSurvey\LimeSurvey_Community_Dummy_R1.csv, replace

*END OF DO FILE
******************** END 
