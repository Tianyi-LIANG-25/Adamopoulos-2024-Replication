/* This is the code that cleans the original data files from RCRE.

Used in "Land Security and Mobility Barriers," 
for publication at the Quarterly Journal of Economics.

by Tasso Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, Xiaoyun Wei. 
*/



********************************************************************************
// Data cleaning process
// 1. Preparations 
/*
(1) you need to download the raw data of individuals, households, and villages in 2004-2018 from the data system and import them in stata. 
(2) rename the variable names in the same format. For example, nh1a_1, nh2_10. 
(3) create a root file that contains four subfiles: Dofiles, Results, Temp-data, and Working-data. And then follow the steps below:
*/
********************************************************************************
clear all
set more off

global root         = "~" 
global dofiles      = "$root/Dofiles"
global temp-data    = "$root/Temp-data"
global working-data = "$root/Working-data"
global raw-data     = "~"
global results      = "$root/Results"

********************************************************************************
// 2. Generate the variable of suburb at village level.
// ! first, you need to combine village data in 2004-2018 
//  and save as "$working-data/village0418.dta"
********************************************************************************

use "$working-data/village0418.dta",clear 

gen double village = sm*10^3 + cm 
replace village = scode*10^3 + cm if village == .

tostring regionid,format(%100.0g) replace 
gen sm2 = substr(regionid,1,2)
gen cm2 = substr(regionid,5,2)

destring regionid sm2 cm2,replace 
order regionid sm2 cm2 

replace village = sm2*10^3 + cm2 if village == .

gen suburb = nc1_5

duplicates list village year
tsset village year
replace suburb = L.suburb if suburb > 2

replace suburb = 0 if suburb == 2

keep year village suburb 
save "$temp-data/village-suburb.dta",replace 

********************************************************************************
// 3. Clean individual data
// ! first, you need to append the individual data in 2004-2018
// and save as "$working-data/individual0418.dta"
********************************************************************************

use "$working-data/individual0418.dta",clear 

**** hhid

cap drop prov
cap drop village
cap drop hhid

**** 44 广东 47 广州
replace sm = 44 if sm == 47
replace scode = 44 if scode == 47

gen double hhid = sm*10^7 + cm*10^4 + hm if year <= 2008
replace hhid = scode*10^7 + cuncode*10^4 + hucode if hhid == . & year >= 2009

format %30.0g hhid

cap drop hhid_str
tostring hhid,gen(hhid_str) force usedisplayformat

cap drop prov
gen prov = substr(hhid_str,1,2)
destring prov,replace

cap drop village
gen village = substr(hhid_str,1,5)
destring village,replace

sort hhid year

rename nh1b_1 relation
rename nh1b_2 gender
rename nh1b_3 age

gen education = nh1b_7 if year <= 2017
replace education = nh1b_8 if year == 2018 

bys hhid year: gen indid = _n

replace gender = 0 if gender == 2 


/* Section 1: clean for potential hhid errors */


/* Section 1.1  Error adjustments for hh head */

preserve 

/* Generate household statistics */

gen eduHead = education if relation == 1
bys hhid year: egen temp = mean(eduHead)
replace eduHead = temp
drop temp

gen ageHead = age if relation == 1
bys hhid year: egen temp = mean(ageHead)
replace ageHead = temp
drop temp

gen ageHeadBase = age if relation == 1 & year == 2004
bys hhid: egen temp = mean(ageHeadBase)
replace ageHeadBase = temp
drop temp

gen genderHead = gender if relation == 1
bys hhid year: egen temp = mean(genderHead)
replace genderHead = temp
drop temp


collapse (mean) eduHead ageHead ageHeadBase genderHead prov, by(hhid year)
sort hhid year

/* Type 1: sandwich adjustment of an age mistake */

/* 1.1 age equals to its adjacent year level */
replace ageHead = ageHead[_n-1] + 1 if hhid[_n] == hhid[_n-1] & hhid[_n] == hhid[_n+1] & ///
	ageHead[_n] == ageHead[_n-1] & ageHead[_n+1] == ageHead[_n-1]+2 & ///
	(eduHead[_n] == eduHead[_n-1] & eduHead[_n] == eduHead[_n+1] | ///
	genderHead[_n] == genderHead[_n-1] & genderHead[_n] == genderHead[_n+1])
			
replace ageHead = ageHead[_n-1] + 1 if hhid[_n] == hhid[_n-1] & hhid[_n] == hhid[_n+1] & ///
	ageHead[_n] == ageHead[_n+1] & ageHead[_n+1] == ageHead[_n-1]+2 & ///
	(eduHead[_n] == eduHead[_n-1] & eduHead[_n] == eduHead[_n+1] | ///
	genderHead[_n] == genderHead[_n-1] & genderHead[_n] == genderHead[_n+1])

/* 1.2 One wrong age within two correct ones */
replace ageHead = ageHead[_n-1] + 1 if hhid[_n] == hhid[_n-1] & hhid[_n] == hhid[_n+1] & ///
	hhid[_n] == hhid[_n-2] & hhid[_n] == hhid[_n+2] & ageHead[_n-1] == ageHead[_n-2]+1 & ///
	ageHead[_n+2] == ageHead[_n+1]+1 & ageHead[_n+1] == ageHead[_n-1]+2 & ///
	(eduHead[_n] == eduHead[_n-1] & eduHead[_n] == eduHead[_n+1] | ///
	genderHead[_n] == genderHead[_n-1] & genderHead[_n] == genderHead[_n+1])
	
replace ageHead = ageHead[_n-1] + 1 if hhid[_n] == hhid[_n-1] & hhid[_n] == hhid[_n+1] & ///
	ageHead[_n+1] == ageHead[_n-1]+2 & ///
	(eduHead[_n] == eduHead[_n-1] & eduHead[_n] == eduHead[_n+1] | ///
	genderHead[_n] == genderHead[_n-1] & genderHead[_n] == genderHead[_n+1])
	
/* Type 2: adjustment of nominal/real age */

/* 2.1: sequences such as 61, 62, 63, 63, 64, 65 */

gen flag_nominal = 0
replace flag_nominal = 1 if ageHead == ageHead[_n-1] & hhid[_n] == hhid[_n-1] & ///
	hhid[_n] == hhid[_n-2] & hhid[_n] == hhid[_n+1] & hhid[_n] == hhid[_n+2] & ///
	ageHead[_n-1] == ageHead[_n-2]+1 & ageHead[_n+1] == ageHead[_n]+1 & ///
	ageHead[_n+2] == ageHead[_n+1]+1
replace flag_nominal = 1 if ageHead == ageHead[_n-1]+1 & hhid[_n] == hhid[_n-1] & ///
	flag_nominal[_n-1] == 1	
replace ageHead = ageHead + 1 if flag_nominal == 1
drop flag_nominal

gen flag_nominal = 0
replace flag_nominal = 1 if ageHead == ageHead[_n-1] & hhid[_n] == hhid[_n-1] & ///
	year == 2004 & hhid[_n] == hhid[_n+1] & hhid[_n] == hhid[_n+2] & hhid[_n] == hhid[_n+3] & ///
	ageHead[_n+1] == ageHead[_n]+1 & ageHead[_n+2] == ageHead[_n+1]+1 & ///
	ageHead[_n+3] == ageHead[_n+2]+1
replace flag_nominal = 1 if ageHead == ageHead[_n-1]+1 & hhid[_n] == hhid[_n-1] & ///
	flag_nominal[_n-1] == 1	
replace ageHead = ageHead + 1 if flag_nominal == 1
drop flag_nominal

gen flag_nominal = 0
replace flag_nominal = 1 if ageHead == ageHead[_n-1] & hhid[_n] == hhid[_n-1] & ///
	year == 2017 & hhid[_n] == hhid[_n+1] & hhid[_n] == hhid[_n-2] & hhid[_n] == hhid[_n-3] & ///
	ageHead[_n+1] == ageHead[_n]+1 & ageHead[_n-1] == ageHead[_n-2]+1 & ///
	ageHead[_n-2] == ageHead[_n-3]+1
replace flag_nominal = 1 if ageHead == ageHead[_n-1]+1 & hhid[_n] == hhid[_n-1] & ///
	flag_nominal[_n-1] == 1	
replace ageHead = ageHead + 1 if flag_nominal == 1
drop flag_nominal

gen flag_nominal = 0
replace flag_nominal = 1 if ageHead == ageHead[_n-1] & hhid[_n] == hhid[_n-1] & ///
	year == 2018 & hhid[_n] == hhid[_n-2] & hhid[_n] == hhid[_n-3] & ///
	ageHead[_n-1] == ageHead[_n-2]+1 & ageHead[_n-2] == ageHead[_n-3]+1 & ///
	genderHead == genderHead[_n-1]
replace ageHead = ageHead + 1 if flag_nominal == 1
drop flag_nominal

/* 2.2: sequences such as 61, 62, 63, 65, 66, 67 */

gen flag_nominal = 0
replace flag_nominal = 1 if ageHead == ageHead[_n-1]+2 & hhid[_n] == hhid[_n-1] & ///
	hhid[_n] == hhid[_n-2] & hhid[_n] == hhid[_n+1] & hhid[_n] == hhid[_n+2] & ///
	ageHead[_n-1] == ageHead[_n-2]+1 & ageHead[_n+1] == ageHead[_n]+1 & ///
	ageHead[_n+2] == ageHead[_n+1]+1
replace flag_nominal = 1 if ageHead == ageHead[_n-1]+1 & hhid[_n] == hhid[_n-1] & ///
	flag_nominal[_n-1] == 1	
replace ageHead = ageHead - 1 if flag_nominal == 1
drop flag_nominal

gen flag_nominal = 0
replace flag_nominal = 1 if ageHead == ageHead[_n-1]+2 & hhid[_n] == hhid[_n-1] & ///
	year == 2004 & hhid[_n] == hhid[_n+1] & hhid[_n] == hhid[_n+2] & hhid[_n] == hhid[_n+3] & ///
	ageHead[_n+1] == ageHead[_n]+1 & ageHead[_n+2] == ageHead[_n+1]+1 & ///
	ageHead[_n+3] == ageHead[_n+2]+1
replace flag_nominal = 1 if ageHead == ageHead[_n-1]+1 & hhid[_n] == hhid[_n-1] & ///
	flag_nominal[_n-1] == 1	
replace ageHead = ageHead - 1 if flag_nominal == 1
drop flag_nominal

gen flag_nominal = 0
replace flag_nominal = 1 if ageHead == ageHead[_n-1]+2 & hhid[_n] == hhid[_n-1] & ///
	year == 2017 & hhid[_n] == hhid[_n+1] & hhid[_n] == hhid[_n-2] & hhid[_n] == hhid[_n-3] & ///
	ageHead[_n+1] == ageHead[_n]+1 & ageHead[_n-1] == ageHead[_n-2]+1 & ///
	ageHead[_n-2] == ageHead[_n-3]+1
replace flag_nominal = 1 if ageHead == ageHead[_n-1]+1 & hhid[_n] == hhid[_n-1] & ///
	flag_nominal[_n-1] == 1	
replace ageHead = ageHead - 1 if flag_nominal == 1
drop flag_nominal

gen flag_nominal = 0
replace flag_nominal = 1 if ageHead == ageHead[_n-1]+2 & hhid[_n] == hhid[_n-1] & ///
	year == 2018 & hhid[_n] == hhid[_n-2] & hhid[_n] == hhid[_n-3] & ///
	ageHead[_n-1] == ageHead[_n-2]+1 & ageHead[_n-2] == ageHead[_n-3]+1 & ///
	genderHead == genderHead[_n-1]	
replace ageHead = ageHead - 1 if flag_nominal == 1
drop flag_nominal



/* Type 3: Gender adjustment */

gen flag_gender = 0
replace flag_gender = 1 if genderHead ~= genderHead[_n-1] & genderHead ~= genderHead[_n+1] & ///
	genderHead[_n+1] == genderHead[_n-1] & hhid == hhid[_n-1] & hhid == hhid[_n+1] & ///
	ageHead == ageHead[_n-1]+1 & ageHead == ageHead[_n+1]-1
replace genderHead = genderHead[_n-1] if flag_gender == 1
drop flag_gender



/* Generate HH flag based on age and gender */

gen flag_hhid = 0
replace flag_hhid = 1 if hhid == hhid[_n-1] & ///
	(ageHead ~= ageHead[_n-1]+1 | genderHead ~= genderHead[_n-1])
replace flag_hhid = 0 if hhid == hhid[_n-1] & ///
	(ageHead >= ageHead[_n-1]-1 & ageHead <= ageHead[_n-1]+3 ) & genderHead == genderHead[_n-1]

sort hhid year
save "$temp-data/ageHeadFixed.dta", replace


restore

sort hhid year
merge m:1 hhid year using "$temp-data/ageHeadFixed.dta"
drop _merge

replace age = ageHead if relation == 1

sort hhid year	



/* Section 1.2  Error adjustments for hh spouse */

preserve 

/* Generate household statistics */

gen eduSpouse = education if relation == 2
bys hhid year: egen temp = mean(eduSpouse)
replace eduSpouse = temp
drop temp

gen ageSpouse = age if relation == 2
bys hhid year: egen temp = mean(ageSpouse)
replace ageSpouse = temp
drop temp

gen ageSpouseBase = age if relation == 2 & year == 2004
bys hhid: egen temp = mean(ageSpouseBase)
replace ageSpouseBase = temp
drop temp

gen genderSpouse = gender if relation == 2
bys hhid year: egen temp = mean(genderSpouse)
replace genderSpouse = temp
drop temp


collapse (mean) eduSpouse ageSpouse ageSpouseBase genderSpouse prov flag_hhid, by(hhid year)
sort hhid year

/* Type 1: sandwich adjustment of an age mistake */

/* 1.1 age equals to its adjacent year level */
replace ageSpouse = ageSpouse[_n-1] + 1 if hhid[_n] == hhid[_n-1] & hhid[_n] == hhid[_n+1] & ///
	ageSpouse[_n] == ageSpouse[_n-1] & ageSpouse[_n+1] == ageSpouse[_n-1]+2 & ///
	(eduSpouse[_n] == eduSpouse[_n-1] & eduSpouse[_n] == eduSpouse[_n+1] | ///
	genderSpouse[_n] == genderSpouse[_n-1] & genderSpouse[_n] == genderSpouse[_n+1]) & ///
	flag_hhid[_n] == 0
			
replace ageSpouse = ageSpouse[_n-1] + 1 if hhid[_n] == hhid[_n-1] & hhid[_n] == hhid[_n+1] & ///
	ageSpouse[_n] == ageSpouse[_n+1] & ageSpouse[_n+1] == ageSpouse[_n-1]+2 & ///
	(eduSpouse[_n] == eduSpouse[_n-1] & eduSpouse[_n] == eduSpouse[_n+1] | ///
	genderSpouse[_n] == genderSpouse[_n-1] & genderSpouse[_n] == genderSpouse[_n+1]) & ///
	flag_hhid[_n+1] == 0

/* 1.2 One wrong age within two correct ones */
replace ageSpouse = ageSpouse[_n-1] + 1 if hhid[_n] == hhid[_n-1] & hhid[_n] == hhid[_n+1] & ///
	hhid[_n] == hhid[_n-2] & hhid[_n] == hhid[_n+2] & ageSpouse[_n-1] == ageSpouse[_n-2]+1 & ///
	ageSpouse[_n+2] == ageSpouse[_n+1]+1 & ageSpouse[_n+1] == ageSpouse[_n-1]+2 & ///
	(eduSpouse[_n] == eduSpouse[_n-1] & eduSpouse[_n] == eduSpouse[_n+1] | ///
	genderSpouse[_n] == genderSpouse[_n-1] & genderSpouse[_n] == genderSpouse[_n+1]) & ///
	flag_hhid[_n] == 0 & flag_hhid[_n-1] == 0 & flag_hhid[_n+1] == 0
	
replace ageSpouse = ageSpouse[_n-1] + 1 if hhid[_n] == hhid[_n-1] & hhid[_n] == hhid[_n+1] & ///
	ageSpouse[_n+1] == ageSpouse[_n-1]+2 & ///
	(eduSpouse[_n] == eduSpouse[_n-1] & eduSpouse[_n] == eduSpouse[_n+1] | ///
	genderSpouse[_n] == genderSpouse[_n-1] & genderSpouse[_n] == genderSpouse[_n+1]) & ///
	flag_hhid[_n] == 0 & flag_hhid[_n-1] == 0 & flag_hhid[_n+1] == 0
	
/* Type 2: adjustment of nominal/real age */

/* 2.1: sequences such as 61, 62, 63, 63, 64, 65 */

gen flag_nominal = 0
replace flag_nominal = 1 if ageSpouse == ageSpouse[_n-1] & hhid[_n] == hhid[_n-1] & ///
	hhid[_n] == hhid[_n-2] & hhid[_n] == hhid[_n+1] & hhid[_n] == hhid[_n+2] & ///
	ageSpouse[_n-1] == ageSpouse[_n-2]+1 & ageSpouse[_n+1] == ageSpouse[_n]+1 & ///
	ageSpouse[_n+2] == ageSpouse[_n+1]+1  & ///
	flag_hhid[_n] == 0 & flag_hhid[_n-1] == 0 & flag_hhid[_n+1] == 0
replace flag_nominal = 1 if ageSpouse == ageSpouse[_n-1]+1 & hhid[_n] == hhid[_n-1] & ///
	flag_nominal[_n-1] == 1	
replace ageSpouse = ageSpouse + 1 if flag_nominal == 1
drop flag_nominal

gen flag_nominal = 0
replace flag_nominal = 1 if ageSpouse == ageSpouse[_n-1] & hhid[_n] == hhid[_n-1] & ///
	year == 2004 & hhid[_n] == hhid[_n+1] & hhid[_n] == hhid[_n+2] & hhid[_n] == hhid[_n+3] & ///
	ageSpouse[_n+1] == ageSpouse[_n]+1 & ageSpouse[_n+2] == ageSpouse[_n+1]+1 & ///
	ageSpouse[_n+3] == ageSpouse[_n+2]+1  & ///
	flag_hhid[_n] == 0 & flag_hhid[_n-1] == 0 & flag_hhid[_n+1] == 0
replace flag_nominal = 1 if ageSpouse == ageSpouse[_n-1]+1 & hhid[_n] == hhid[_n-1] & ///
	flag_nominal[_n-1] == 1	
replace ageSpouse = ageSpouse + 1 if flag_nominal == 1
drop flag_nominal

gen flag_nominal = 0
replace flag_nominal = 1 if ageSpouse == ageSpouse[_n-1] & hhid[_n] == hhid[_n-1] & ///
	year == 2017 & hhid[_n] == hhid[_n+1] & hhid[_n] == hhid[_n-2] & hhid[_n] == hhid[_n-3] & ///
	ageSpouse[_n+1] == ageSpouse[_n]+1 & ageSpouse[_n-1] == ageSpouse[_n-2]+1 & ///
	ageSpouse[_n-2] == ageSpouse[_n-3]+1  & ///
	flag_hhid[_n] == 0 & flag_hhid[_n-1] == 0 & flag_hhid[_n+1] == 0
replace flag_nominal = 1 if ageSpouse == ageSpouse[_n-1]+1 & hhid[_n] == hhid[_n-1] & ///
	flag_nominal[_n-1] == 1	
replace ageSpouse = ageSpouse + 1 if flag_nominal == 1
drop flag_nominal

gen flag_nominal = 0
replace flag_nominal = 1 if ageSpouse == ageSpouse[_n-1] & hhid[_n] == hhid[_n-1] & ///
	year == 2018 & hhid[_n] == hhid[_n-2] & hhid[_n] == hhid[_n-3] & ///
	ageSpouse[_n-1] == ageSpouse[_n-2]+1 & ageSpouse[_n-2] == ageSpouse[_n-3]+1 & ///
	genderSpouse == genderSpouse[_n-1]  & ///
	flag_hhid[_n] == 0 & flag_hhid[_n-1] == 0
replace ageSpouse = ageSpouse + 1 if flag_nominal == 1
drop flag_nominal

/* 2.2: sequences such as 61, 62, 63, 65, 66, 67 */

gen flag_nominal = 0
replace flag_nominal = 1 if ageSpouse == ageSpouse[_n-1]+2 & hhid[_n] == hhid[_n-1] & ///
	hhid[_n] == hhid[_n-2] & hhid[_n] == hhid[_n+1] & hhid[_n] == hhid[_n+2] & ///
	ageSpouse[_n-1] == ageSpouse[_n-2]+1 & ageSpouse[_n+1] == ageSpouse[_n]+1 & ///
	ageSpouse[_n+2] == ageSpouse[_n+1]+1  & ///
	flag_hhid[_n] == 0 & flag_hhid[_n-1] == 0 & flag_hhid[_n+1] == 0
replace flag_nominal = 1 if ageSpouse == ageSpouse[_n-1]+1 & hhid[_n] == hhid[_n-1] & ///
	flag_nominal[_n-1] == 1	
replace ageSpouse = ageSpouse - 1 if flag_nominal == 1
drop flag_nominal

gen flag_nominal = 0
replace flag_nominal = 1 if ageSpouse == ageSpouse[_n-1]+2 & hhid[_n] == hhid[_n-1] & ///
	year == 2004 & hhid[_n] == hhid[_n+1] & hhid[_n] == hhid[_n+2] & hhid[_n] == hhid[_n+3] & ///
	ageSpouse[_n+1] == ageSpouse[_n]+1 & ageSpouse[_n+2] == ageSpouse[_n+1]+1 & ///
	ageSpouse[_n+3] == ageSpouse[_n+2]+1  & ///
	flag_hhid[_n] == 0 & flag_hhid[_n-1] == 0 & flag_hhid[_n+1] == 0
replace flag_nominal = 1 if ageSpouse == ageSpouse[_n-1]+1 & hhid[_n] == hhid[_n-1] & ///
	flag_nominal[_n-1] == 1	
replace ageSpouse = ageSpouse - 1 if flag_nominal == 1
drop flag_nominal

gen flag_nominal = 0
replace flag_nominal = 1 if ageSpouse == ageSpouse[_n-1]+2 & hhid[_n] == hhid[_n-1] & ///
	year == 2017 & hhid[_n] == hhid[_n+1] & hhid[_n] == hhid[_n-2] & hhid[_n] == hhid[_n-3] & ///
	ageSpouse[_n+1] == ageSpouse[_n]+1 & ageSpouse[_n-1] == ageSpouse[_n-2]+1 & ///
	ageSpouse[_n-2] == ageSpouse[_n-3]+1  & ///
	flag_hhid[_n] == 0 & flag_hhid[_n-1] == 0 & flag_hhid[_n+1] == 0
replace flag_nominal = 1 if ageSpouse == ageSpouse[_n-1]+1 & hhid[_n] == hhid[_n-1] & ///
	flag_nominal[_n-1] == 1	
replace ageSpouse = ageSpouse - 1 if flag_nominal == 1
drop flag_nominal

gen flag_nominal = 0
replace flag_nominal = 1 if ageSpouse == ageSpouse[_n-1]+2 & hhid[_n] == hhid[_n-1] & ///
	year == 2018 & hhid[_n] == hhid[_n-2] & hhid[_n] == hhid[_n-3] & ///
	ageSpouse[_n-1] == ageSpouse[_n-2]+1 & ageSpouse[_n-2] == ageSpouse[_n-3]+1 & ///
	genderSpouse == genderSpouse[_n-1] & ///
	flag_hhid[_n] == 0 & flag_hhid[_n-1] == 0 
replace ageSpouse = ageSpouse - 1 if flag_nominal == 1
drop flag_nominal



/* Type 3: Gender adjustment */

gen flag_gender = 0
replace flag_gender = 1 if genderSpouse ~= genderSpouse[_n-1] & genderSpouse ~= genderSpouse[_n+1] & ///
	genderSpouse[_n+1] == genderSpouse[_n-1] & hhid == hhid[_n-1] & hhid == hhid[_n+1] & ///
	ageSpouse == ageSpouse[_n-1]+1 & ageSpouse == ageSpouse[_n+1]-1  & ///
	flag_hhid[_n] == 0 & flag_hhid[_n-1] == 0 & flag_hhid[_n+1] == 0
replace genderSpouse = genderSpouse[_n-1] if flag_gender == 1
drop flag_gender



sort hhid year
save "$temp-data/ageSpouseFixed.dta", replace

restore


sort hhid year
merge m:1 hhid year using "$temp-data/ageSpouseFixed.dta"
drop _merge

replace age = ageSpouse if relation == 2

sort hhid year		



/* Section 2: link individuals over time */



/* If everyone has a distinct age and gender, then we just proceed with age and gender. */

gen age_unique = 0
gen ageedu_unique = 0

bys hhid age gender year: replace age_unique = _N == 1
bys hhid age gender year education: replace ageedu_unique = _N == 1
	

gen indid2 = .
gen ite = .


gen double hhid_4d = (hhid - mod(hhid,10))/10

levelsof hhid_4d, local(local_speedup)

preserve

foreach hhid_4d_loop of local local_speedup {

	qui keep if hhid_4d == `hhid_4d_loop'
	
	//tab year
	
	qui levelsof hhid_str, local(local_hhid_part) 
	display(`hhid_4d_loop')
	foreach lyear of numlist 2004/2018 {
		
		foreach x of local local_hhid_part {
		//display("`x'")
			foreach y of numlist 1/11 {
			    //count if hhid_str == "`x'"
				qui sum indid2 if hhid_str == "`x'"
				qui gen temp = r(max)
				qui replace temp = 0 if temp == .
				qui replace temp = temp + 1
				qui replace indid2 = temp  if indid == `y' & hhid_str == "`x'" & year == `lyear' ///
					& age_unique == 1 & indid2 == .
			
				qui sum age if indid == `y' & hhid_str == "`x'" & year == `lyear' & age_unique == 1
				qui gen age_temp = r(mean) 
			
				qui sum gender if indid == `y' & hhid_str == "`x'" & year == `lyear' & age_unique == 1
				qui gen gender_temp = r(mean) 
			
				qui sum education if indid == `y' & hhid_str == `"x"' & year == `lyear' & age_unique == 1
				qui gen education_temp = r(mean) 
			
				foreach z of numlist `lyear'/2017 {
					qui replace indid2 = temp  if hhid_str == "`x'" & year == `z' + 1 & age_unique == 1 & ///
						age == age_temp + (`z'-`lyear'+1) & gender == gender_temp  & indid2 == .
					qui replace indid2 = temp  if hhid_str == "`x'" & year == `z' + 1 & age_unique == 0 & ///
						age == age_temp + (`z'-`lyear'+1) & gender == gender_temp  & indid2 == . & ///
						education == education_temp & ageedu_unique == 1
				}
				qui drop temp age_temp gender_temp education_temp
			}
		}
	}
	
	qui save "$temp-data/temp-part-`hhid_4d_loop'.dta", replace	
	
	restore, preserve


}
restore

clear
fs temp_part_*
foreach f in `r(files)' {
	append using `f'
	erase `f'
}



/* Section 3: re-assign HHID */

/* If hhid flag == 1: replace it to 0 if the new hh head is also in the original hh
and at least one other member is consistent. */

gen newHeadId = indid2 if flag_hhid == 1 & relation == 1
bys hhid year: gen obs_hh = _N
levelsof hhid_4d, local(local_speedup)

preserve
foreach hhid_4d_loop of local local_speedup {
	display(`hhid_4d_loop')
	qui keep if hhid_4d == `hhid_4d_loop'
	qui levelsof hhid_str, local(local_hhid_part) 
	
	foreach lyear of numlist 2004/2018 {
		foreach x of local local_hhid_part {
			qui sum indid2 if year == `lyear'-1 & hhid_str == "`x'"
			qui gen maxIdPrev = r(max) if year == `lyear' & hhid_str == "`x'"
			qui count if indid2 <= maxIdPrev & year == `lyear' & hhid_str == "`x'"
			qui gen obsIdBelow = r(N) if year == `lyear' & hhid_str == "`x'"
			qui sum newHeadId if year == `lyear' & hhid_str == "`x'"
			qui replace newHeadId = r(mean) if year == `lyear' & hhid_str == "`x'"
			qui replace flag_hhid = 0 if ((newHeadId < maxIdPrev & obsIdBelow >= 2) | ///
				(obsIdBelow >= 3) | (obsIdBelow >= round(obs_hh/2)+1 ) ) & ///
				year == `lyear' & hhid_str == "`x'"
			qui drop maxIdPrev obsIdBelow
		
		}
	}
	qui save "$temp-data/temp-part-`hhid_4d_loop'.dta", replace
	restore, preserve
}
restore



clear
qui fs temp_part_*
foreach f in `r(files)' {
	append using `f'
	erase `f'
}

	
			
sort hhid year indid2
drop ite


save "$temp-data/part3-preserved.dta", replace




collapse flag_hhid hhid_4d prov, by(hhid year)

format %30.0g hhid
cap drop hhid_str
tostring hhid,gen(hhid_str) force usedisplayformat

gen double hhid2 = hhid


levelsof hhid_4d, local(local_speedup)

preserve
foreach hhid_4d_loop of local local_speedup {
	display(`hhid_4d_loop')
	qui keep if hhid_4d == `hhid_4d_loop'
	qui levelsof hhid_str, local(local_hhid_part) 
	
	foreach x of local local_hhid_part {
		foreach lyear of numlist 2004/2018 {
		
			foreach y of numlist `lyear'/2018 {
				qui gen flag_hhid_`y' = 1 if hhid_str == "`x'" & year == `lyear' & flag_hhid == 1
			}
			foreach y of numlist `lyear'/2018 {
				qui sum flag_hhid_`y' if hhid_str == "`x'" 
				qui replace flag_hhid_`y' = r(mean) if hhid_str == "`x'"
			}
			foreach y of numlist `lyear'/2018 {
				qui replace hhid2 = hhid2 + 1000000000 if flag_hhid_`y' == 1 & year == `y'
			}
			qui drop flag_hhid_*
		}
	}
	qui save "$temp-data/temp-part-`hhid_4d_loop'.dta", replace
	restore, preserve
}
restore


 
clear
qui fs temp_part_*
foreach f in `r(files)' {
	append using `f'
	erase `f'
}	

drop hhid_4d	
	
keep hhid hhid2 year
sort hhid year
save "$temp-data/hhidFixed.dta", replace




use "$temp-data/part3-preserved.dta", clear
sort hhid year
merge m:1 hhid year using "$temp-data/hhidFixed.dta"
drop _merge
drop hhid_4d

replace hhid = hhid2



/* Section 4: For thouse households whose ID's are re-assigned, we regenerate
the individual ID's. */

replace indid2 = . if hhid >= 1000000000

drop age_unique ageedu_unique

gen age_unique = 0
gen ageedu_unique = 0

bys hhid age gender year: replace age_unique = _N == 1
bys hhid age gender year education: replace ageedu_unique = _N == 1
	

gen ite = .


replace hhid2 = . if hhid2 < 1000000000

gen hhid_4d = (hhid - mod(hhid,10))/10

levelsof hhid_4d, local(local_speedup)

preserve
foreach hhid_4d_loop of local local_speedup {
	display(`hhid_4d_loop'*10)

	qui keep if hhid_4d == `hhid_4d_loop'
	
	qui levelsof hhid, local(local_hhid) 


	foreach lyear of numlist 2004/2018 {
		foreach x of local local_hhid {
			foreach y of numlist 1/14 {
				qui sum indid2 if hhid_str == "`x'" 
				qui gen temp = r(max)
				qui replace temp = 0 if temp == .
				qui replace temp = temp + 1
				qui replace indid2 = temp  if indid == `y' & hhid_str == "`x'" & year == `lyear' ///
					& age_unique == 1 & indid2 == .
			
				qui sum age if indid == `y' & hhid_str == "`x'" & year == `lyear' & age_unique == 1
				qui gen age_temp = r(mean) 
			
				qui sum gender if indid == `y' & hhid_str == "`x'" & year == `lyear' & age_unique == 1
				qui gen gender_temp = r(mean)
			
				qui sum education if indid == `y' & hhid_str == "`x'" & year == `lyear' & age_unique == 1
				qui gen education_temp = r(mean)
			
				foreach z of numlist `lyear'/2017 {
					qui replace indid2 = temp  if hhid_str == "`x'" & year == `z' + 1 & age_unique == 1 & ///
						age == age_temp + (`z'-`lyear'+1) & gender == gender_temp  & indid2 == .
					qui replace indid2 = temp  if hhid_str == "`x'" & year == `z' + 1 & age_unique == 0 & ///
						age == age_temp + (`z'-`lyear'+1) & gender == gender_temp  & indid2 == . & ///
						education == education_temp & ageedu_unique == 1
				}
				qui drop temp age_temp gender_temp education_temp
			}
		}
	}

	qui save "temp-part-`hhid_4d_loop'.dta", replace
	restore, preserve
}
restore

clear
qui fs temp_part_*.dta
foreach f in `r(files)' {
	append using `f'
	erase `f'
}
drop hhid_4d

/* Section 5:  Final cleaning */

replace indid = indid2
drop hhid2 age_unique ageedu_unique newHeadId flag_hhid genderHead ageHeadBase ///
	ageHead eduHead eduSpouse ageSpouse ageSpouseBase ite genderSpouse indid2


label var indid "linked individual ID"
label var obs_hh "number of individuals within a HH"

sort hhid year indid

save "$temp-data/individualLinked-fast.dta", replace

/* Section 6: checks for errors in the household ID.  */


use "$temp-data/individualLinked-fast.dta", clear

gen ageHead = age       if relation == 1
bys hhid year: egen temp = mean(ageHead)
replace ageHead = temp
drop temp

gen genderHead = gender if relation == 1
bys hhid year: egen temp = mean(genderHead)
replace genderHead = temp
drop temp

gen eduHead = education if relation == 1
bys hhid year: egen temp = mean(eduHead)
replace eduHead = temp
drop temp

bys hhid year: gen numIndhh = _N

collapse(mean) prov eduHead genderHead ageHead numIndhh, by(hhid year)

gen double hhid2 = .
replace hhid2 = mod(hhid,1000000000)

/* switch hhid and hhid2 */
/* note that after switch, hhid is the original hhid, while hhid2 is our updated hhid */

gen double temp = hhid2
replace hhid2 = hhid
replace hhid = temp
drop temp

bys hhid2: gen obshh = _N

sort hhid year

//gen double village = (hhid-mod(hhid,10000))/10000


/* step 1: identify sandwich households */

gen flag_sandwich = 0
replace flag_sandwich = 1 if hhid[_n-1] == hhid & hhid[_n+1] == hhid & ///
	(hhid[_n-2] == hhid | hhid[_n+2] == hhid) & ///
	hhid2[_n-1] ~= hhid2 & hhid2[_n+1] ~= hhid2 & ///
	(hhid2[_n-2] == hhid2[_n-1] & hhid2[_n+2] == hhid2[_n+1] | ///
	hhid2[_n-2] == hhid2[_n-1] & year == 2017 | hhid2[_n+1] == hhid2[_n+2] & year == 2004)

	
gen flag_lag = 0
replace flag_lag = 1 if flag_sandwich == 0 & flag_sandwich[_n+1] == 1 & hhid == hhid[_n+1]
	
gen flag_lead = 0
replace flag_lead = 1 if flag_sandwich == 0 & flag_sandwich[_n-1] == 1 & hhid == hhid[_n-1]

sort hhid year

save "$temp-data/further-correction-temp.dta", replace

keep if flag_sandwich == 1
bys village: gen obs_flag = _n if flag_sandwich == 1

keep hhid hhid2 year obs_flag
merge 1:1 hhid2 year using "$temp-data/further-correction-temp.dta"
drop _merge

erase "$temp-data/further-correction-temp.dta"




/* Step 2: match within villages */

sort hhid year

gen double hhid3 = .

replace hhid3 = hhid2

levelsof village, local(local_village)

preserve
foreach lvillage of local local_village {
	display(`lvillage')
	qui keep if village == `lvillage'
	qui egen max_obs_flag = max(obs_flag)
	qui replace max_obs_flag = 0 if max_obs_flag == .
	local x = 1
	while `x' <= max_obs_flag {
		qui gen lagYear = year-1 if obs_flag == `x'
		qui sum lagYear
		qui replace lagYear = r(mean)
		
		qui gen lagAgeHead = ageHead[_n-1] if obs_flag == `x'
		qui sum lagAgeHead
		qui replace lagAgeHead = r(mean)
		
		qui gen lagGenderHead = genderHead[_n-1] if obs_flag == `x'
		qui sum lagGenderHead
		qui replace lagGenderHead = r(mean)
		
		qui gen lagEduHead = eduHead[_n-1] if obs_flag == `x'
		qui sum lagEduHead
		qui replace lagEduHead = r(mean)
		
		qui gen laghhid = hhid2[_n-1] if obs_flag == `x' 
		qui sum laghhid
		qui replace laghhid = r(mean)
		
		
		qui gen leadYear = year+1 if obs_flag == `x'
		qui sum leadYear
		qui replace leadYear = r(mean)
		
		qui gen leadAgeHead = ageHead[_n+1] if obs_flag == `x'
		qui sum leadAgeHead
		qui replace leadAgeHead = r(mean)
		
		qui gen leadGenderHead = genderHead[_n+1] if obs_flag == `x'
		qui sum leadGenderHead
		qui replace leadGenderHead = r(mean)
		
		qui gen leadEduHead = eduHead[_n+1] if obs_flag == `x'
		qui sum leadEduHead
		qui replace leadEduHead = r(mean)
		
		qui gen leadhhid = hhid2[_n+1] if obs_flag == `x' 
		qui sum leadhhid
		qui replace leadhhid = r(mean)
		
		qui gen criterion = 1 if year == lagYear+1 & flag_sandwich == 1 & ///
			(ageHead == lagAgeHead + 1 & genderHead == lagGenderHead | ///
			ageHead >= lagAgeHead & ageHead <= lagAgeHead + 2 & ///
			genderHead == lagGenderHead & eduHead == lagEduHead) & ///
			(ageHead == leadAgeHead - 1 & genderHead == leadGenderHead | ///
			ageHead <= leadAgeHead & ageHead >= leadAgeHead - 2 & ///
			genderHead == leadGenderHead & eduHead == leadEduHead) & ///
			ageHead ~= . & hhid2 ~= laghhid+1000000000 & hhid2 ~= leadhhid-1000000000 & ///
			year >= 2004 & year <= 2017
		qui gen flag_match = 1 if criterion == 1
		
		qui levelsof hhid, local(hhid_temp)
		foreach z of local hhid_temp {
			qui sum flag_match if hhid == `z', de
			qui replace flag_match = r(max) if hhid == `z'
		}
		

		qui sum hhid2 if flag_match == 1 & year == lagYear+1
		qui gen temp = r(mean)
		qui replace hhid3 = laghhid if hhid2 == temp & year == lagYear+1 
		qui replace hhid3 = hhid3 - 2000000000 if hhid2 == temp+1000000000 & year > lagYear+1
		drop temp
		
		qui replace obs_flag = 0 if criterion == 1
		
		
		qui drop lagAgeHead lagGenderHead lagEduHead lagYear laghhid ///
			leadAgeHead leadGenderHead leadEduHead leadYear leadhhid flag_match
		
		qui gen lagYear = year-1 if criterion == 1
		qui sum lagYear
		qui replace lagYear = r(mean)
		
		qui gen lagAgeHead = ageHead[_n-1] if criterion == 1
		qui sum lagAgeHead
		qui replace lagAgeHead = r(mean)
		
		qui gen lagGenderHead = genderHead[_n-1] if criterion == 1
		qui sum lagGenderHead
		qui replace lagGenderHead = r(mean)
		
		qui gen lagEduHead = eduHead[_n-1] if criterion == 1
		qui sum lagEduHead
		qui replace lagEduHead = r(mean)
		
		qui gen laghhid = hhid2[_n-1] if criterion == 1
		qui sum laghhid
		qui replace laghhid = r(mean)
		
		
		qui gen leadYear = year+1 if criterion == 1
		qui sum leadYear
		qui replace leadYear = r(mean)
		
		qui gen leadAgeHead = ageHead[_n+1] if criterion == 1
		qui sum leadAgeHead
		qui replace leadAgeHead = r(mean)
		
		qui gen leadGenderHead = genderHead[_n+1] if criterion == 1
		qui sum leadGenderHead
		qui replace leadGenderHead = r(mean)
		
		qui gen leadEduHead = eduHead[_n+1] if criterion == 1
		qui sum leadEduHead
		qui replace leadEduHead = r(mean)
		
		qui gen leadhhid = hhid2[_n+1] if criterion == 1
		qui sum leadhhid
		qui replace leadhhid = r(mean)
		
		qui gen criterion_backward = 1 if year == lagYear+1 & flag_sandwich == 1 & ///
			(ageHead == lagAgeHead + 1 & genderHead == lagGenderHead | ///
			ageHead >= lagAgeHead & ageHead <= lagAgeHead + 2 & ///
			genderHead == lagGenderHead & eduHead == lagEduHead) & ///
			(ageHead == leadAgeHead - 1 & genderHead == leadGenderHead | ///
			ageHead <= leadAgeHead & ageHead >= leadAgeHead - 2 & ///
			genderHead == leadGenderHead & eduHead == leadEduHead) & ///
			ageHead ~= . & hhid2 ~= laghhid & hhid2 ~= leadhhid & ///
			year >= 2004 & year <= 2017
		
		qui gen flag_match = 1 if criterion_backward == 1
		
		qui levelsof hhid, local(hhid_temp)
		foreach z of local hhid_temp {
			qui sum flag_match if hhid == `z', de
			qui replace flag_match = r(max) if hhid == `z'
		}
		
		qui sum hhid2 if flag_match == 1 & year == lagYear+1
		qui gen temp = r(mean)
		qui replace hhid3 = laghhid if hhid2 == temp & year == lagYear+1 
		qui replace hhid3 = hhid3 - 2000000000 if hhid2 == temp+1000000000 & year > lagYear+1
		qui drop temp
		
		qui replace obs_flag = 0 if criterion_backward == 1
		
		qui drop lagAgeHead lagGenderHead lagEduHead lagYear laghhid ///
			leadAgeHead leadGenderHead leadEduHead leadYear leadhhid flag_match
			
		qui drop criterion criterion_backward
		
		
		
		local x = `x' + 1
		
	}
	qui save "temp-village-`lvillage'.dta", replace
	restore, preserve
}
restore

clear
qui fs temp_village_*
foreach f in `r(files)' {
	append using `f'
	erase `f'
}
	
/* Step 3: give same household ID to AAABAAA rather than AAABCCC */
sort hhid year

gen criterion = 0
replace criterion = 1 if flag_sandwich == 1 & hhid[_n-1] == hhid[_n+1] & ///
	(hhid[_n-2] == hhid[_n-1] | hhid[_n+2] == hhid[_n+1]) & ///
	(ageHead[_n+1] == ageHead[_n-1]+2 & genderHead[_n+1] == genderHead[_n-1] | ///
	ageHead[_n+1] >= ageHead[_n-1] & ageHead[_n+1] <= ageHead[_n-1]+3 & ///
	genderHead[_n+1] == genderHead[_n-1] & eduHead[_n+1] == eduHead[_n-1]) & ///
	year >= 2004 & year <= 2017

gen yearCriterion = year if criterion == 1
by hhid: egen temp = mean(yearCriterion)
replace yearCriterion = temp
drop temp

gen hhid3Criterion = hhid3 if criterion == 1
by hhid: egen temp = mean(hhid3Criterion)
replace hhid3Criterion = temp
drop temp

replace hhid3 = hhid3 - 2000000000 if hhid3 == hhid3Criterion+1000000000 & year > yearCriterion


sort hhid year

gen temp = hhid
replace hhid = hhid2

save "$temp-data/hhid-corrected.dta", replace


use "$temp-data/individualLinked-fast.dta", clear

cap drop prov
gen double prov = floor(hhid/10000000)


sort hhid year
merge m:1 hhid year using "$temp-data/hhid-corrected.dta"

replace hhid=temp
drop temp

replace hhid = hhid3 /* correct for the wrong hhid */
drop flag_* hhid3 obshh criterion max_obs_flag hhid3* _merge ageHead numIndhh hhid2 ///
	eduHead genderHead obs_flag obs_hh yearCriterion


gen double hhid_original = mod(hhid,1000000000)

label var hhid "Household ID, after reassignment"
label var hhid_original "Original household id, before reassignment"

sort hhid year
save "$temp-data/ready-for-analysis-individual.dta", replace

********************************************************************************
// 4. Clean household data.
// 4.1 First, grab household variables for each year and append them
********************************************************************************
*********** variables **************************

// nh1a*
// nh2* 
// nh4*
// nh5*
// nh6* 
// nh7*


************* 2004-2008 *************************

forvalues t = 2004(1)2008{
	
	use "$raw-data/~`t'~.dta",clear    // use household raw data in year t
	
	gen double hhid_original = sm * 10^7 + cm * 10^4 + hm

	keep year hhid_original nh1a* nh2* nh4* nh5* nh6* nh7*

	save "$temp-data/hhvar-`t'.dta",replace 
}

************* 2009-2018**************************

forvalues t = 2009(1)2018{
	
	use "$raw-data/~`t'~.dta",clear    // use household raw data in year t
	
	gen double hhid_original = scode * 10^7 + cuncode * 10^4 + hucode

	keep year hhid_original nh1a* nh2* nh4* nh5* nh6* nh7*

	save "$temp-data/hhvar-`t'.dta",replace 
}

********************************************************************************
// 4.2 Second, generate useful variables and clean the household data.
*********************************************************************************

use "$temp-data/hhvar-2004.dta",clear 
forvalues t = 2005(1)2018{
	append using "$temp-data/hhvar-`t'.dta",force 
}
save "$temp-data/hhvar-0418.dta",replace 

tostring hhid_original,replace 
gen prov = substr(hhid_original,1,2)
gen village = substr(hhid_original,1,5)

destring prov village hhid_original,replace 

replace prov=44 if prov==47  

drop if hhid_original < 1000000   
drop if hhid_original > 9999999  

duplicates drop hhid_original year,force 
tab year

gen double villageyear=village*10000+year

/* Sample Size */
gen  dummy = 1
bysort hhid_original: egen numobs=total(dummy)
drop dummy
lab var numobs "Years observed"

gen balancepanel = 0
replace balancepanel = 1 if numobs == 15 
lab var balancepanel "Number of Observations of the Balanced Panel"


******************************************************************************************
/* 
Step 1: generate measures of labor input 

Important: in these newer waves, we can observe the hired labor among farmers.
*/
******************************************************************************************

/* 1.1  Total labor in agriculture */                                           

egen temp17 = rowtotal(nh4a*_17 nh4b*_17) 
egen temp18 = rowtotal(nh4a*_18 nh4b*_18) 
egen temp22 = rowtotal(nh4a*_22 nh4b*_22) 

gen labor_agr_total = 0

replace labor_agr_total = temp18 if year >= 2004 & year <= 2008 ///
	| year >= 2011 & year <= 2018
replace labor_agr_total = temp17 if year >= 2009 & year <= 2010

drop temp18 temp17 temp22


/* 1.2  Hired labor in agriculture */

egen temp18 = rowtotal(nh4a*_18 nh4b*_18)
egen temp19 = rowtotal(nh4a*_19 nh4b*_19)
egen temp20 = rowtotal(nh4a*_20 nh4b*_20)

gen labor_agr_hired = 0
replace labor_agr_hired = temp19 if year >= 2004 & year <= 2008 ///
	| year >= 2011 & year <= 2018
replace labor_agr_hired = temp18 if year >= 2009 & year <= 2010

lab var labor_agr_total "Agricultural labor (days), total"
lab var labor_agr_hired "Agricultural labor (days), hired"

gen labor_agr_hired_cost = 0
replace labor_agr_hired_cost = temp20 if year >= 2004 & year <= 2008 ///
	| year >= 2011 & year <= 2018
replace labor_agr_hired_cost = temp19 if year >= 2009 & year <= 2010

label var labor_agr_hired_cost "Agricultural labor cost, hired"

drop temp*



/* 1.3  Side labor in agriculture, own and hired */

egen temp11 = rowtotal(nh4c*_11)
egen temp13 = rowtotal(nh4c*_13)
egen temp14 = rowtotal(nh4c*_14)
egen temp15 = rowtotal(nh4c*_15)
egen temp16 = rowtotal(nh4c*_16)
egen temp17 = rowtotal(nh4c*_17)
egen temp18 = rowtotal(nh4c*_18)

gen labor_side_total = 0
egen temp = rowtotal(nh4d1_3 nh4d1_4)

replace labor_side_total = temp13 + temp if year >= 2004 & year <= 2008
replace labor_side_total = temp14 + temp if year >= 2009 & year <= 2010
replace labor_side_total = temp16 + temp if year >= 2011 & year <= 2018
drop temp

gen labor_side_hired = 0
egen temp = rowtotal(nh4d1_4)

replace labor_side_hired = temp14 + temp if year >= 2004 & year <= 2008
replace labor_side_hired = temp15 + temp if year >= 2009 & year <= 2010
replace labor_side_hired = temp17 + temp if year >= 2011 & year <= 2018
drop temp

gen labor_side_hired_cost = 0
egen temp = rowtotal(nh4d1_5)

replace labor_side_hired_cost = temp11 + temp if year >= 2004 & year <= 2008
replace labor_side_hired_cost = temp16 + temp if year >= 2009 & year <= 2010
replace labor_side_hired_cost = temp18 + temp if year >= 2011 & year <= 2018
drop temp

drop temp*



/* 1.4  Labor in non-agriculture */

egen labor_nonagr_total = rowtotal(nh4d2_3 nh4d4_3 nh4d5_3 nh4d6_3 nh4d7_3 nh4d8_3 ///
	nh4d9_3 nh4d2_4 nh4d4_4 nh4d5_4 nh4d6_4 nh4d7_4 nh4d8_4 nh4d9_4)
egen labor_nonagr_hired = rowtotal(nh4d2_4 nh4d4_4 nh4d5_4 nh4d6_4 nh4d7_4 nh4d8_4 ///
	nh4d9_4)

lab var labor_side_total   "Labor in agricultural sidelines (days), total"
lab var labor_side_hired   "Labor in agricultural sidelines (days), hired"
lab var labor_side_hired_cost   "Labor cost in agricultural sidelines, hired"
lab var labor_nonagr_total "Non-agricultural labor (days), total"
lab var labor_nonagr_hired "Non-agricultural labor (days), hired"



/* 1.5  Total labor */

egen labor_total       = rowtotal(labor_agr_total labor_side_total labor_nonagr_total)
egen labor_hired_total = rowtotal(labor_agr_hired labor_side_hired labor_nonagr_hired)

gen labor_agr_frac     = (labor_agr_total-labor_agr_hired) / (labor_total - labor_hired_total)
replace labor_agr_frac = 1 if labor_agr_frac == .                                

label var labor_total    	"Total agricultural labor (days)"
label var labor_hired_total "Total hired labor (days)"
label var labor_agr_frac    "Fraction of labor supplied to family production"


 ********************************************************
/* Step 2: generate measures of land allocation */

/* Land owned, cultivated area and sown area */
********************************************************

/* 2.1  Cultivated area */

egen temp9_21  = rowtotal(nh2_9 nh2_21)
egen temp15_28 = rowtotal(nh2_15 nh2_28)

gen cultivatedarea = .
replace cultivatedarea = temp9_21  if year >= 2004 & year <= 2008   
replace cultivatedarea = temp15_28 if year >= 2009 & year <= 2018

drop temp*

replace cultivatedarea = 0 if cultivatedarea < 0
label var cultivatedarea "Area cultivated in orchards and crops, in mu"

sort hhid year
foreach x of varlist cultivatedarea {
gen `x'_lag=`x'[_n-1] if hhid==hhid[_n-1]
}
egen ma = rowmean(cultivatedarea cultivatedarea_lag)


/* 2.2  Sownarea */

gen sownarea_wheat     = nh4a1_1 
gen sownarea_rice      = nh4a2_1 
gen sownarea_corn      = nh4a3_1 
gen sownarea_soy       = nh4a4_1 
gen sownarea_potato    = nh4a5_1 
gen sownarea_otherfood = nh4a6_1 


gen sownarea_cotton = .
replace sownarea_cotton = nh4b7_1 if year >= 2004 & year <= 2008
replace sownarea_cotton = nh4b1_1 if year >= 2009 & year <= 2018


gen sownarea_rapeseed = .
replace sownarea_rapeseed = nh4b8_1 if year >= 2004 & year <= 2008
replace sownarea_rapeseed = nh4b2_1 if year >= 2009 & year <= 2018

gen sownarea_sugar = .
replace sownarea_sugar = nh4b9_1 if year >= 2004 & year <= 2008
replace sownarea_sugar = nh4b3_1 if year >= 2009 & year <= 2018

gen sownarea_fiber = .
replace sownarea_fiber = nh4b10_1 if year >= 2004 & year <= 2008
replace sownarea_fiber = nh4b4_1  if year >= 2009 & year <= 2018

gen sownarea_tobacco = .
replace sownarea_tobacco = nh4b11_1 if year >= 2004 & year <= 2008
replace sownarea_tobacco = nh4b5_1  if year >= 2009 & year <= 2018

gen sownarea_silk = .
replace sownarea_silk = nh4b12_1 if year >= 2004 & year <= 2008
replace sownarea_silk = nh4b6_1  if year >= 2009 & year <= 2018

gen sownarea_veg = .
replace sownarea_veg = nh4b13_1 if year >= 2004 & year <= 2008
replace sownarea_veg = nh4b7_1  if year >= 2009 & year <= 2018

gen sownarea_othercash = .
replace sownarea_othercash = nh4b14_1 if year >= 2004 & year <= 2008
replace sownarea_othercash = nh4b8_1  if year >= 2009 & year <= 2018

gen sownarea_fruit = .
replace sownarea_fruit = nh4b15_1 if year >= 2004 & year <= 2008
replace sownarea_fruit = nh4b9_1  if year >= 2009 & year <= 2018

gen sownarea_otherorchard = .
replace sownarea_otherorchard = nh4b16_1 if year >= 2004 & year <= 2008
replace sownarea_otherorchard = nh4b10_1 if year >= 2009 & year <= 2018

foreach x of varlist sownarea_* {
	replace `x' = 0 if `x' == .
}


egen sownarea = rowtotal(sownarea_*)
label var sownarea "Area sown in orchards and crops, in mu"



/* 2.3  Identifying non-agricultural households based on sownarea */


gen nonagricategory = 0
replace nonagricategory = 1 if nh1a_7 > 4 | nh1a_7 == .
lab var nonagricategory "Non-agricultural based on household reports"

gen nonagri_reportedarea = 0
replace nonagri_reportedarea = 1 if sownarea == 0 | sownarea == .
lab var nonagri_reportedarea "Non-agricultural based on no sown area"

bysort hhid: egen totagriyears_cat    = total(nonagricategory)
bysort hhid: egen totagriyears_report = total(nonagri_reportedarea)

replace totagriyears_cat    = 1 if totagriyears_cat    > 0  
replace totagriyears_report = 1 if totagriyears_report > 0  



/* 2.4  Statistics on rent-in and rent-out */


gen leasedin      = .
replace leasedin  = nh2_5 if year >= 2004  & year <= 2008
replace leasedin  = nh2_7 if year >= 2009  & year <= 2018

gen leasedout     = .
replace leasedout = nh2_7 if year >= 2004  & year <= 2008
replace leasedout = nh2_10 if year >= 2009 & year <= 2018
gen leased_to_firm = .
replace leased_to_firm = nh2_11 if year >= 2009 & year <= 2018

gen leased_to_othervillage = .
replace leased_to_othervillage = nh2_14 if year >= 2009 & year <= 2018

label var leasedin  "The amount of land leased in, household"
label var leasedout "The amount of land leased out, household"

label var leased_to_firm "The amount of land leased to firms, household"
label var leased_to_othervillage "The amount of land leased to agents from other villages"

gen fracleasedin  = leasedin /cultivatedarea
gen fracleasedout = leasedout/cultivatedarea

lab var fracleasedin  "Fraction of land leased in"
lab var fracleasedout "Fraction of land leased out"

gen leasedindummy  = leasedin  > 0 & leasedin  ~= .                        
gen leasedoutdummy = leasedout > 0 & leasedout ~= .                      

label var leasedindummy  "Household dummy for land leased in"
label var leasedoutdummy "Household dummy for land leased our"

bysort villageyear: egen villagefracleasedin  = mean(fracleasedin)
bysort villageyear: egen villagefracleasedout = mean(fracleasedout)
bysort villageyear: egen villfrachhleasein    = mean(leasedindummy)
bysort villageyear: egen villfrachhleaseout   = mean(leasedoutdummy)

label var villagefracleasedin  "Fraction of land leased in, village level"
label var villagefracleasedout "Fraction of land leased out, village level"
label var villfrachhleasein    "Fraction of household who lease in land, village level"
label var villfrachhleaseout   "Fraction of household who lease out land, village level"




/* 2.5  Correcting for likely errors following Adamopoulos et al (2017) */



foreach x of varlist cultivatedarea sownarea sownarea_* {
gen error1_`x'=0
}


/* Error type 1: Correct an odd observation in an otherwise consistent series of
	at least 4 other identical observations */
	
foreach x of varlist cultivatedarea sownarea sownarea_* {
sort hhid year
replace error1_`x'=1 if `x'!=`x'[_n-1] & `x'!=`x'[_n+1] & ///
	`x'[_n-1]==`x'[_n+1] & `x'[_n-2]==`x'[_n+2] & `x'[_n-1]!=. & ///
	hhid==hhid[_n-1] & hhid==hhid[_n+1] & hhid==hhid[_n-2] & hhid==hhid[_n+2]
	
replace `x'=`x'[_n-1] if error1_`x'==1
}


/* Error type 2: Correct a zero sandwiched by two positive and equal, 
	or nearly equal, observations */
foreach x of varlist cultivatedarea sownarea sownarea_* {
gen error2_`x'=0
qui sum `x'
gen cutoff_`x'=r(mean)/50
sort hhid year
replace error2_`x'=1 if `x'==0 & `x'[_n-1]!=0 & `x'[_n-1]-`x'[_n+1]<cutoff_`x' & ///
hhid==hhid[_n-1] & hhid==hhid[_n+1]
replace `x'=`x'[_n-1] if error2_`x'==1
drop cutoff*
}


/* Error type 3: Correct any observation that represents an increase relative to
	the previous AND subsequent year of more than 10 times (i.e., more than a 900 percent increase) */
	
foreach x of varlist cultivatedarea sownarea sownarea_* {
gen error3_`x'=0
sort hhid year
replace error3_`x'=1 if `x'/`x'[_n-1]>10 & `x'/`x'[_n+1]>10 & ///
	`x'!=. & `x'[_n-1]!=. & `x'[_n+1]!=. & `x'[_n-1]!=0 & `x'[_n+1]!=0 & `x'!=0 & ///
	hhid==hhid[_n-1] & hhid==hhid[_n+1]
replace `x'=`x'[_n-1] if error3_`x'==1
}

/* Error type 4: Correct any observation that represents an increase relative to
	the previous year of more than 50 times */
foreach x of varlist cultivatedarea sownarea sownarea_* {
gen error4_`x'=0
sort hhid year
replace error4_`x'=1 if `x'/`x'[_n-1]>50 &`x'!=. & `x'[_n-1]!=. & `x'[_n+1]!=. & ///
	`x'[_n-1]!=0 & `x'[_n+1]!=0 & `x'!=0 & hhid==hhid[_n-1] & hhid==hhid[_n+1]
replace `x'=`x'[_n-1] if error4_`x'==1
}

/* Sum up all the errors */
foreach x of varlist cultivatedarea sownarea sownarea_* {
egen totalerror_`x'=rsum(error1_`x' error2_`x' error3_`x' error4_`x')
}




********************************************************
/* Step 3: Prices by crops */
********************************************************


/* 3.1: price of economic crops */


* Quantity
gen sell_q_cotton    = nh5_15 
gen sell_q_rapeseed  = nh5_17 
gen sell_q_sugar     = nh5_19 
gen sell_q_fiber     = nh5_21 
gen sell_q_tobacco   = nh5_23 
gen sell_q_fruit     = nh5_25 
gen sell_q_silk      = nh5_27 
gen sell_q_tea       = nh5_29 
gen sell_q_drug      = nh5_31 
gen sell_q_veg       = nh5_33 


foreach x of varlist sell_q_* {
	replace `x' = 0 if `x' == .
	label var `x' "The quantity of this crop being sold"
}

* Value
gen sell_v_cotton    = nh5_16 
gen sell_v_rapeseed  = nh5_18 
gen sell_v_sugar     = nh5_20 
gen sell_v_fiber     = nh5_22 
gen sell_v_tobacco   = nh5_24 
gen sell_v_fruit     = nh5_26 
gen sell_v_silk      = nh5_28 
gen sell_v_tea       = nh5_30 
gen sell_v_drug      = nh5_32 
gen sell_v_veg       = nh5_34 


foreach x of varlist sell_v_* {
	replace `x' = 0 if `x' == .
	label var `x' "The value of this crop being sold"
}

* Price
gen price_cotton    = sell_v_cotton    /sell_q_cotton
gen price_rapeseed  = sell_v_rapeseed  /sell_q_rapeseed
gen price_sugar     = sell_v_sugar     /sell_q_sugar
gen price_fiber     = sell_v_fiber     /sell_q_fiber
gen price_tobacco   = sell_v_tobacco   /sell_q_tobacco
gen price_fruit     = sell_v_fruit     /sell_q_fruit
gen price_silk      = sell_v_silk      /sell_q_silk
gen price_tea       = sell_v_tea       /sell_q_tea
gen price_drug      = sell_v_drug      /sell_q_drug
gen price_veg       = sell_v_veg       /sell_q_veg

foreach x of varlist price_* {
	label var `x' "The price of this crop"
}



/* 3.2: price of food crops, which is affected by quota */

egen sownarea_crop = rowtotal(nh4a1_1 nh4a2_1 nh4a3_1 nh4a4_1 nh4a5_1 nh4a6_1) 
gen crop_dummy = (sownarea == sownarea_crop)
label var crop_dummy "Dummy: if a household only cultivate crops"

* Quantity

gen sell_q_total  = nh5_1 
gen sell_q_wheat  = nh5_5 
gen sell_q_rice   = nh5_7 
gen sell_q_corn   = nh5_9 
gen sell_q_soy    = nh5_11 
gen sell_q_potato = nh5_13 


foreach x of varlist sell_q_total sell_q_wheat sell_q_rice sell_q_corn sell_q_soy sell_q_potato {
	replace `x' = 0 if `x' == .
	label var `x' "The quantity of this crop being sold"
}

gen sell_q_otherfood = sell_q_total - sell_q_wheat - sell_q_rice - sell_q_corn - ///
	sell_q_soy - sell_q_potato
replace sell_q_otherfood = 0 if sell_q_otherfood == .

* Value

gen sell_v_total  = nh5_2 
gen sell_v_wheat  = nh5_6 
gen sell_v_rice   = nh5_8 
gen sell_v_corn   = nh5_10 
gen sell_v_soy    = nh5_12 
gen sell_v_potato = nh5_14 


foreach x of varlist sell_v_total sell_v_wheat sell_v_rice sell_v_corn sell_v_soy sell_v_potato {
	replace `x' = 0 if `x' == .
	label var `x' "The value of this crop being sold"
}

gen sell_v_otherfood = sell_v_total - sell_v_wheat - sell_v_rice - sell_v_corn - ///
	sell_v_soy - sell_v_potato
replace sell_v_otherfood = 0 if sell_v_otherfood == .


* Price

gen sell_q_quota = nh5_3 
gen sell_v_quota = nh5_4 
gen noquota = sell_q_quota == 0 & sell_q_total > 0                      
replace noquota = . if sell_q_quota == .                                        

/* For those farmers who have no quota, we directly take their prices. */
gen price_wheat    = sell_v_wheat  / sell_q_wheat  if noquota==1
gen price_rice     = sell_v_rice   / sell_q_rice   if noquota==1
gen price_corn     = sell_v_corn   / sell_q_corn   if noquota==1
gen price_soy      = sell_v_soy    / sell_q_soy    if noquota==1
gen price_potato   = sell_v_potato / sell_q_potato if noquota==1



/* If a farmer has quota on rice only, then we take the price for other crops. Same 
for wheat, corn, soy, and potato quota. */

gen wheatequal  = (sell_q_wheat  == sell_q_quota) & (sell_v_wheat  == sell_v_quota) ///
	& sell_q_quota != 0 & sell_v_quota != . & sell_q_quota != .
gen riceequal   = (sell_q_rice   == sell_q_quota) & (sell_v_rice   == sell_v_quota) ///
	& sell_q_quota != 0 & sell_v_quota != . & sell_q_quota != .
gen cornequal   = (sell_q_corn   == sell_q_quota) & (sell_v_corn   == sell_v_quota) ///
	& sell_q_quota != 0 & sell_v_quota != . & sell_q_quota != .
gen soyequal    = (sell_q_soy    == sell_q_quota) & (sell_v_soy    == sell_v_quota) ///
	& sell_q_quota != 0 & sell_v_quota != . & sell_q_quota != .
gen potatoequal = (sell_q_potato == sell_q_quota) & (sell_v_potato == sell_v_quota) ///
	& sell_q_quota != 0 & sell_v_quota != . & sell_q_quota != .
	
replace price_rice     = sell_v_rice   / sell_q_rice   if wheatequal==1
replace price_corn     = sell_v_corn   / sell_q_corn   if wheatequal==1
replace price_soy      = sell_v_soy    / sell_q_soy    if wheatequal==1
replace price_potato   = sell_v_potato / sell_q_potato if wheatequal==1

replace price_wheat    = sell_v_wheat  / sell_q_wheat  if riceequal==1
replace price_corn     = sell_v_corn   / sell_q_corn   if riceequal==1
replace price_soy      = sell_v_soy    / sell_q_soy    if riceequal==1
replace price_potato   = sell_v_potato / sell_q_potato if riceequal==1

replace price_wheat    = sell_v_wheat  / sell_q_wheat  if cornequal==1
replace price_rice     = sell_v_rice   / sell_q_rice   if cornequal==1
replace price_soy      = sell_v_soy    / sell_q_soy    if cornequal==1
replace price_potato   = sell_v_potato / sell_q_potato if cornequal==1

replace price_wheat    = sell_v_wheat  / sell_q_wheat  if soyequal==1
replace price_rice     = sell_v_rice   / sell_q_rice   if soyequal==1
replace price_corn     = sell_v_corn   / sell_q_corn   if soyequal==1
replace price_potato   = sell_v_potato / sell_q_potato if soyequal==1

replace price_wheat    = sell_v_wheat  / sell_q_wheat  if potatoequal==1
replace price_rice     = sell_v_rice   / sell_q_rice   if potatoequal==1
replace price_corn     = sell_v_corn   / sell_q_corn   if potatoequal==1
replace price_soy      = sell_v_soy    / sell_q_soy    if potatoequal==1


/* For those farmers who only sell one food crop: we take the price for the part
of the crop that is not for quota purposes. */

gen wheatonly  = sell_q_wheat >  0 & sell_q_rice == 0 & sell_q_corn == 0 & ///
	sell_q_soy == 0 & sell_q_potato == 0
gen riceonly   = sell_q_wheat == 0 & sell_q_rice >  0 & sell_q_corn == 0 & ///
	sell_q_soy == 0 & sell_q_potato == 0
gen cornonly   = sell_q_wheat == 0 & sell_q_rice == 0 & sell_q_corn >  0 & ///
	sell_q_soy == 0 & sell_q_potato == 0
gen soyonly    = sell_q_wheat == 0 & sell_q_rice == 0 & sell_q_corn == 0 & ///
	sell_q_soy >  0 & sell_q_potato == 0
gen potatoonly = sell_q_wheat == 0 & sell_q_rice == 0 & sell_q_corn == 0 & ///
	sell_q_soy == 0 & sell_q_potato >  0

egen graindummytotal = rsum(wheatonly riceonly cornonly soyonly potatoonly)

replace price_wheat  = (sell_v_wheat  - sell_v_quota)/(sell_q_wheat  - sell_q_quota) ///
	if wheatonly  == 1 
replace price_rice   = (sell_v_rice   - sell_v_quota)/(sell_q_rice   - sell_q_quota) ///
	if riceonly   == 1 
replace price_corn   = (sell_v_corn   - sell_v_quota)/(sell_q_corn   - sell_q_quota) ///
	if cornonly   == 1 
replace price_soy    = (sell_v_soy    - sell_v_quota)/(sell_q_soy    - sell_q_quota) ///
	if soyonly    == 1 
replace price_potato = (sell_v_potato - sell_v_quota)/(sell_q_potato - sell_q_quota) ///
	if potatoonly == 1 

gen price_otherfood = sell_v_otherfood / sell_q_otherfood


/* Change zeros to missing */
foreach x of varlist price_*  {
	replace `x'=. if `x'==0
	label var `x' "The price of this crop, individual-year level"                //household-year level
}

/* Generate the price: median of each village, then median of the province,
then the median again. */

gen double provyear = prov*10000+year
foreach x of varlist price_* {
	bysort villageyear: egen `x'_vyear = median(`x')
	label var `x'_vyear "The price of this crop, village-year level"
	bysort provyear:    egen `x'_pyear = median(`x')
	label var `x'_pyear "The price of this crop, prov-year level"
	bysort year:        egen `x'_year  = median(`x')
	label var `x'_year "The price of this crop, aggregate-year level"
	
	
	/* If we do not observe the common price, replace it with that of the previous year */
	foreach lyear of numlist 2004/2018 {
		qui sum `x'_year if year == `lyear'-1
		qui gen temp = r(mean)
		qui replace `x'_year = temp if `x'_year == . & year == `lyear'
		qui drop temp
	}
	
}



/* If we do not observe the price at individual-year level, we replace it with 
common price */                                                                 

foreach x of varlist price_wheat price_rice price_corn price_soy price_potato ///
	price_otherfood price_cotton price_rapeseed price_sugar price_fiber price_tobacco ///
	price_fruit price_silk price_tea price_drug price_veg {
	replace `x'_pyear = `x'_year if `x'_pyear == .
	replace `x'_vyear=`x'_pyear if `x'_vyear==.   
	replace `x'=`x'_vyear if `x'==.                                             
}


local crop_name       "wheat rice corn soy potato otherfood cotton rapeseed sugar fiber tobacco silk veg othercash fruit otherorchard"
local crop_name_short "wheat rice corn soy potato otherfood cotton rapeseed sugar fiber tobacco silk veg fruit"



/* 3.3: Generating price indices */

/* Output */

gen output_q_wheat     = nh4a1_3 
gen output_q_rice      = nh4a2_3 
gen output_q_corn      = nh4a3_3 
gen output_q_soy       = nh4a4_3 
gen output_q_potato    = nh4a5_3 
gen output_q_otherfood = nh4a6_3 


gen output_q_cotton = .
replace output_q_cotton = nh4b7_3 if year >=  2004 & year <= 2008
replace output_q_cotton = nh4b1_3 if year >=  2009 & year <= 2018

gen output_q_rapeseed = .
replace output_q_rapeseed = nh4b8_3 if year >=  2004 & year <= 2008
replace output_q_rapeseed = nh4b2_3 if year >=  2009 & year <= 2018

gen output_q_sugar = .
replace output_q_sugar = nh4b9_3 if year >=  2004 & year <= 2008
replace output_q_sugar = nh4b3_3 if year >=  2009 & year <= 2018

gen output_q_fiber = .
replace output_q_fiber = nh4b10_3 if year >=  2004 & year <= 2008
replace output_q_fiber = nh4b4_3  if year >=  2009 & year <= 2018

gen output_q_tobacco = .
replace output_q_tobacco = nh4b11_3 if year >=  2004 & year <= 2008
replace output_q_tobacco = nh4b5_3  if year >=  2009 & year <= 2018

gen output_q_silk = .
replace output_q_silk = nh4b12_3 if year >=  2004 & year <= 2008
replace output_q_silk = nh4b6_3  if year >=  2009 & year <= 2018

gen output_q_veg = .
replace output_q_veg = nh4b13_3 if year >=  2004 & year <= 2008
replace output_q_veg = nh4b7_3  if year >=  2009 & year <= 2018

gen output_q_fruit = .
replace output_q_fruit = nh4b15_3 if year >=  2004 & year <= 2008
replace output_q_fruit = nh4b9_3  if year >=  2009 & year <= 2018

gen output_q_othercash = .
replace output_q_othercash = nh4b14_3 if year >=  2004 & year <= 2008
replace output_q_othercash = nh4b8_3  if year >=  2009 & year <= 2018

gen output_q_otherorchard = .
replace output_q_otherorchard = nh4b16_3 if year >=  2004 & year <= 2008
replace output_q_otherorchard = nh4b10_3 if year >=  2009 & year <= 2018

foreach x of varlist output_q_* {
	replace `x' = 0 if `x' == .
	label var `x' "Farmer's output of this crop, kilogram"
}

/* The portion of output that is sold */
gen sellfrac_wheat     = sell_q_wheat     / output_q_wheat
gen sellfrac_rice      = sell_q_rice      / output_q_rice
gen sellfrac_corn      = sell_q_corn      / output_q_corn
gen sellfrac_soy       = sell_q_soy       / output_q_soy
gen sellfrac_potato    = sell_q_potato    / output_q_potato
gen sellfrac_otherfood = sell_q_otherfood / output_q_otherfood
gen sellfrac_cotton    = sell_q_cotton    / output_q_cotton
gen sellfrac_rapeseed  = sell_q_rapeseed  / output_q_rapeseed
gen sellfrac_sugar     = sell_q_sugar     / output_q_sugar
gen sellfrac_fiber     = sell_q_fiber     / output_q_fiber
gen sellfrac_tobacco   = sell_q_tobacco   / output_q_tobacco
gen sellfrac_fruit     = sell_q_fruit     / output_q_fruit
gen sellfrac_veg       = sell_q_veg       / output_q_veg

local type wheat rice corn soy potato otherfood cotton rapeseed sugar fiber tobacco fruit veg 
foreach x of local type {
	replace sellfrac_`x' = 0 if sellfrac_`x' == .&output_q_`x'~=0
	label var sellfrac_`x' "Farmer's portion of output that is sold"                     
}





/* Laspeyres Price Index */

local var wheat rice corn soy potato otherfood cotton rapeseed sugar fiber tobacco fruit veg
foreach i of local var{
	egen output_`i'_base      = total(output_q_`i')     if year == 2004
}


foreach x of varlist output_wheat_base output_rice_base output_corn_base output_soy_base output_potato_base ///
	output_otherfood_base output_cotton_base output_rapeseed_base output_sugar_base output_fiber_base ///
	output_tobacco_base output_fruit_base output_veg_base {
	qui sum `x'
	replace `x' = r(mean) if `x' == .                                            
}


local var wheat rice corn soy potato otherfood cotton rapeseed sugar fiber tobacco fruit veg
foreach i of local var{
	gen Las_`i'     = output_`i'_base     * price_`i'_year 
}


egen Laspeyres_1 = rowtotal(Las_*) /* Omit the missing values */
 gen Laspeyres_2 = 0 /* Requiring no missing values */
foreach x of varlist Las_* {
	replace Laspeyres_2 = Laspeyres_2 + `x'
}

gen Laspeyres = Laspeyres_1

gen base = Laspeyres if year == 2004
qui sum base, de
local mean=r(mean)
replace base = `mean' if base == .
replace Laspeyres = Laspeyres/base*100

label var Laspeyres "Laspeyres price index, 2004 = 100"

/* Note: Laspeyres index does not consist of silk as it is not recorded in 2004 */
/* Note: there are a lot of missing values in the prices so far, so the Laspeyres price index 
is still missing at this moment. */

/* Paasche Price Index */

/* 
Change the terminal year here!
*/

local var wheat rice corn soy potato otherfood cotton rapeseed sugar fiber tobacco silk fruit veg
foreach i of local var{
	egen output_`i'_end      = total(output_q_`i')     if year == 2018
}


foreach x of varlist output_wheat_end output_rice_end output_corn_end output_soy_end ///
	output_potato_end output_otherfood_end output_cotton_end output_rapeseed_end output_sugar_end ///
	output_fiber_end output_tobacco_end output_silk_end output_fruit_end output_veg_end {
	qui sum `x'
	replace `x' = r(mean) if `x' == .
}

local var wheat rice corn soy potato otherfood cotton rapeseed sugar fiber tobacco silk fruit veg
foreach i of local var{

gen Pas_`i'     = output_`i'_end     * price_`i'_year 
}

egen Paasche_1 = rowtotal(Pas_*) /* Omit the missing values */
 gen Paasche_2 = 0 
 /* Requiring no missing values */
foreach x of varlist Pas_* {
	replace Paasche_2 = Paasche_2 + `x'
}

gen Paasche = Paasche_1

gen end = Paasche if year == 2018
qui sum end, de
local mean=r(mean)
replace end = `mean' if end == .
replace Paasche = Paasche/end*100

label var Paasche "Paasche price index, 2018 = 100"

drop Las_* Pas_*
drop output_*_base output_*_end
drop *equal *only



/************************************
* Step 4: Yield and total output 
*************************************/



/* 4.1  Harvest area */

gen harvestarea_wheat     = nh4a1_2  
gen harvestarea_rice      = nh4a2_2 
gen harvestarea_corn      = nh4a3_2
gen harvestarea_soy       = nh4a4_2 
gen harvestarea_potato    = nh4a5_2 
gen harvestarea_otherfood = nh4a6_2 


gen harvestarea_cotton = .
replace harvestarea_cotton = nh4b7_2 if year >= 2004 & year <= 2008
replace harvestarea_cotton = nh4b1_2 if year >= 2009 & year <= 2018

gen harvestarea_rapeseed = .
replace harvestarea_rapeseed = nh4b8_2 if year >= 2004 & year <= 2008
replace harvestarea_rapeseed = nh4b2_2 if year >= 2009 & year <= 2018

gen harvestarea_sugar = .
replace harvestarea_sugar = nh4b9_2 if year >= 2004 & year <= 2008
replace harvestarea_sugar = nh4b3_2 if year >= 2009 & year <= 2018

gen harvestarea_fiber = .
replace harvestarea_fiber = nh4b10_2 if year >= 2004 & year <= 2008
replace harvestarea_fiber = nh4b4_2  if year >= 2009 & year <= 2018

gen harvestarea_tobacco = .
replace harvestarea_tobacco = nh4b11_2 if year >= 2004 & year <= 2008
replace harvestarea_tobacco = nh4b5_2  if year >= 2009 & year <= 2018

gen harvestarea_silk = .
replace harvestarea_silk = nh4b12_2 if year >= 2004 & year <= 2008
replace harvestarea_silk = nh4b6_2  if year >= 2009 & year <= 2018

gen harvestarea_veg = .
replace harvestarea_veg = nh4b13_2 if year >= 2004 & year <= 2008
replace harvestarea_veg = nh4b7_2  if year >= 2009 & year <= 2018

gen harvestarea_othercash = .
replace harvestarea_othercash = nh4b14_2 if year >= 2004 & year <= 2008
replace harvestarea_othercash = nh4b8_2  if year >= 2009 & year <= 2018

gen harvestarea_fruit = .
replace harvestarea_fruit = nh4b15_2 if year >= 2004 & year <= 2008
replace harvestarea_fruit = nh4b9_2  if year >= 2009 & year <= 2018


gen harvestarea_otherorchard = .
replace harvestarea_otherorchard = nh4b16_2 if year >= 2004 & year <= 2008
replace harvestarea_otherorchard = nh4b10_2 if year >= 2009 & year <= 2018

foreach x of varlist harvestarea_* {
	replace `x' = 0 if `x' == .
	label var `x' "Harvested area of this crop, mu"
}


/* If a farmer reports zero output but positive harvest area, then we replace his output
with his sales. */

replace output_q_wheat    = sell_q_wheat      if output_q_wheat     == 0 & ///
	harvestarea_wheat     != 0 & harvestarea_wheat     != .
replace output_q_rice     = sell_q_rice       if output_q_rice      == 0 & ///
	harvestarea_rice      != 0 & harvestarea_rice      != .
replace output_q_corn     = sell_q_corn       if output_q_corn      == 0 & ///
	harvestarea_corn      != 0 & harvestarea_corn      != .
replace output_q_soy      = sell_q_soy        if output_q_soy       == 0 & ///
	harvestarea_soy       != 0 & harvestarea_soy       != .	
replace output_q_potato   = sell_q_potato     if output_q_potato    == 0 & ///
	harvestarea_potato    != 0 & harvestarea_potato    != .	
replace output_q_otherfood = sell_q_otherfood if output_q_otherfood == 0 & ///
	harvestarea_otherfood != 0 & harvestarea_otherfood != .	
replace output_q_cotton    = sell_q_cotton    if output_q_cotton    == 0 & ///
	harvestarea_cotton    != 0 & harvestarea_cotton    != .	
replace output_q_rapeseed  = sell_q_rapeseed  if output_q_rapeseed  == 0 & ///
	harvestarea_rapeseed  != 0 & harvestarea_rapeseed  != .	
replace output_q_sugar     = sell_q_sugar     if output_q_sugar     == 0 & ///
	harvestarea_sugar     != 0 & harvestarea_sugar     != .	
replace output_q_fiber     = sell_q_fiber     if output_q_fiber     == 0 & ///
	harvestarea_fiber     != 0 & harvestarea_fiber     != .	
replace output_q_tobacco   = sell_q_tobacco   if output_q_tobacco   == 0 & ///
	harvestarea_tobacco   != 0 & harvestarea_tobacco   != .	
replace output_q_silk      = sell_q_silk      if output_q_silk      == 0 & ///
	harvestarea_silk      != 0 & harvestarea_silk      != .	
replace output_q_veg       = sell_q_veg       if output_q_veg       == 0 & ///   
	harvestarea_veg       != 0 & harvestarea_veg       != .	


/* Yield */

local crop_name       "wheat rice corn soy potato otherfood cotton rapeseed sugar fiber tobacco silk veg othercash fruit otherorchard"
foreach x of local crop_name {
	gen yield_`x' = output_q_`x' / sownarea_`x'
	
	/* If no output, then we change the sown area and harvest area to zero ???????????
	JL did this in her original code */
	replace sownarea_`x'    = 0 if yield_`x' == 0
	replace harvestarea_`x' = 0 if yield_`x' == 0
	replace yield_`x'       = . if yield_`x' == 0
}


/* Trimming based on yield */


foreach x of varlist yield_* {

	   egen `x'_mean       = mean(`x')
    qui sum `x', de
	*qui sum `x' if `x'>r(p1) & `x'<r(p99)
        gen `x'_dev        = r(sd) 
	    gen `x'_error      = 0 if `x' != .
		gen `x'_largeerror = 0 if `x' != .
	replace `x'_error      = 1 if `x' > `x'_mean + 3*`x'_dev  & `x'!=.
	replace `x'_error      = 1 if `x' < `x'_mean - 3*`x'_dev  & `x'!=.
	replace `x'_largeerror = 1 if `x' > `x'_mean + 10*`x'_dev & `x'!=.
	replace `x'_largeerror = 1 if `x' < `x'_mean - 10*`x'_dev & `x'!=.
}


local crop_name       "wheat rice corn soy potato otherfood cotton rapeseed sugar fiber tobacco silk veg othercash fruit otherorchard"
foreach x of local crop_name {
	qui bysort hhid: egen yield_`x'_hh    = mean(yield_`x'_error)                 
	qui bysort hhid:  gen yield_`x'_dummy = yield_`x'_hh > .5 & yield_`x'_hh != . 
	/* If this hh consistently report higher yield, it could be that he is 
	just more productive. */
	replace yield_`x'_error = 0 if yield_`x'_dummy == 1 & yield_`x'_largeerror != 1 
	drop yield_`x'_dummy yield_`x'_hh
}


/* Adjust for output and yield after trimming */

local crop_name       "wheat rice corn soy potato otherfood cotton rapeseed sugar fiber tobacco silk veg othercash fruit otherorchard"

foreach x of local crop_name {
	replace output_q_`x' = sownarea_`x' * yield_`x'_mean if yield_`x'_error == 1  
	replace yield_`x' = output_q_`x' / sownarea_`x'      if yield_`x'_error == 1       
}



/* Recover sownarea for those with zero values */

local crop_name       "wheat rice corn soy potato otherfood cotton rapeseed sugar fiber tobacco silk veg othercash fruit otherorchard"

foreach x of local crop_name {
	replace sownarea_`x' = output_q_`x' / yield_`x'_mean ///
	if (sownarea_`x' == 0 | sownarea_`x' == .) & output_q_`x' ~= . & output_q_`x' ~= 0 ///
	& yield_`x'_mean ~= 0 & yield_`x'_mean ~= .
}

foreach x of varlist sownarea_* {
	replace `x' = 0 if `x' == .
}



/* Value output, common price */
local crop_name_short "wheat rice corn soy potato otherfood cotton rapeseed sugar fiber tobacco silk veg fruit"

foreach x of local crop_name_short {
	gen output_vc_`x'   = output_q_`x' * price_`x'_pyear
	replace output_vc_`x' = 0 if output_vc_`x' == .
	label var output_vc_`x' "Value of output of this crop, measured in common provincial price of the year"
}



/***************************************
* Step 5: Intermediate Inputs 
***************************************/


/* 5.1  Fertilizer */
 
/* Note: Jessica does not distinguish different types of fertilizers; she use the
same price for all fertilizers. */


gen intermediate_q_fert_total = nh6_3 
gen intermediate_q_fert_UREA  = nh6_5 
gen intermediate_q_fert_DAP   = nh6_7 
gen intermediate_q_fert_AmBic = nh6_9 
gen intermediate_q_fert_SSP   = nh6_11 
gen intermediate_q_fert_K     = nh6_13
gen intermediate_q_fert_comp  = nh6_15 
gen intermediate_q_fert_other = nh6_17 


gen intermediate_v_fert_total = nh6_4 
gen intermediate_v_fert_UREA  = nh6_6 
gen intermediate_v_fert_DAP   = nh6_8 
gen intermediate_v_fert_AmBic = nh6_10 
gen intermediate_v_fert_SSP   = nh6_12 
gen intermediate_v_fert_K     = nh6_14 
gen intermediate_v_fert_comp  = nh6_16 
gen intermediate_v_fert_other = nh6_18 


gen price_fert_total = intermediate_v_fert_total / intermediate_q_fert_total
gen price_fert_UREA  = intermediate_v_fert_UREA  / intermediate_q_fert_UREA
gen price_fert_DAP   = intermediate_v_fert_DAP   / intermediate_q_fert_UREA
gen price_fert_AmBic = intermediate_v_fert_AmBic / intermediate_q_fert_AmBic
gen price_fert_SSP   = intermediate_v_fert_SSP   / intermediate_q_fert_SSP
gen price_fert_K     = intermediate_v_fert_K     / intermediate_q_fert_K
gen price_fert_comp  = intermediate_v_fert_comp  / intermediate_q_fert_comp
gen price_fert_other = intermediate_v_fert_other / intermediate_q_fert_other

/* Here we calculate the price for each type of fertilizers. For those we do not
have price data, we assign the price to be the average price of fertilizers. */
foreach x of varlist price_fert_* {
	bysort year: egen `x'_year=mean(`x')
	replace `x'_year = price_fert_total_year if `x'_year == .
	replace `x' = `x'_year if `x' == . 
}
	
/* 5.2  Diesel oil */


gen intermediate_q_oil = nh6_19 
gen intermediate_v_oil = nh6_20 

gen price_oil          = intermediate_v_oil/intermediate_q_oil
	
bys year: egen price_oil_year = mean(price_oil)
replace price_oil = price_oil_year if price_oil == . 
	
/* 5.3  Plastics */

gen intermediate_q_plastic = nh6_21 

gen intermediate_v_plastic = nh6_22 

gen price_plastic          = intermediate_v_plastic/intermediate_q_plastic
	
bys year: egen price_plastic_year = mean(price_plastic)
replace price_plastic = price_plastic_year if price_plastic == . 


/* 5.4  Pesticides */

gen intermediate_q_pesticide = nh6_23 

gen intermediate_v_pesticide = nh6_24 

gen price_pesticide          = intermediate_v_pesticide/intermediate_q_pesticide
	
bys year: egen price_pesticide_year = mean(price_pesticide)
replace price_pesticide = price_pesticide_year if price_pesticide == . 


/* 4.5  Constant Prices */

local crop_name_short "wheat rice corn soy potato otherfood cotton rapeseed sugar fiber tobacco silk veg fruit"

foreach x of local crop_name_short {
	qui sum price_`x'_year if year >= 2004
	gen price_`x'_constant = r(mean)
	label var price_`x'_constant "Constant price over all years" 
	
	gen output_vcc_`x' = price_`x'_constant * output_q_`x'
	label var output_vcc_`x' ///
		"Value of output of this crop, measured in commmon and constant price of all years"
}

egen output_vcc_total = rowtotal(output_vcc_*)
label var output_vcc_total "Total output of crops, measured in common and constant price"
replace output_vcc_total = 0 if output_vcc_total == .

local intermediate_name ///
	"fert_total fert_UREA fert_DAP fert_AmBic fert_SSP fert_K fert_comp fert_other oil plastic pesticide"

foreach x of local intermediate_name {
	qui sum price_`x'_year if year >= 2004
	gen price_`x'_constant = r(mean)
	label var price_`x'_constant "Constant price over all years"
	
	gen intermediate_vcc_`x' = intermediate_q_`x' * price_`x'_constant
	label var intermediate_vcc_`x' ///
		"Value of this intermediate input, measured in common and constant price of all years"
}


egen intermediate_vcc_total = rowtotal(intermediate_vcc_*)
label var intermediate_vcc_total ///
	"Total value of intermediate input, measured in common and constant price"
replace intermediate_vcc_total = 0 if intermediate_vcc_total == .
	
gen valueadded_vcc_total = output_vcc_total - intermediate_vcc_total
label var valueadded_vcc_total "Value added, measured in common and constant price"
replace valueadded_vcc_total = 0 if valueadded_vcc_total == .

/* Correct for some likely errors: zero cultivated area with positive output */

* Method one: replace it with year-start cultivatedarea
gen error_cultivatedarea = 0 if cultivatedarea != .
replace error_cultivatedarea = 1 if output_vcc_total > 0 & output_vcc_total ~= . ///
	& cultivatedarea == 0                                                          
replace cultivatedarea = nh2_1 if error_cultivatedarea == 1 & year >= 2004 & year <= 2008  
replace cultivatedarea = nh2_2 if error_cultivatedarea == 1 & year >= 2009 & year <= 2018   

drop error_cultivatedarea

* Method two: for the remaining, replace it with hh average
gen error_cultivatedarea = 0 if cultivatedarea != .
replace error_cultivatedarea = 1 if output_vcc_total > 0 & output_vcc_total ~= . ///
	& cultivatedarea == 0                                                           
bysort hhid: egen meancult = mean(cultivatedarea) if output_vcc_total > 0 & output_vcc_total != .   
replace cultivatedarea = meancult if error_cultivatedarea == 1                     
drop error_cultivatedarea meancult

* Delete the remaining 
gen error_cultivatedarea = 0 if cultivatedarea != .
replace error_cultivatedarea = 1 if output_vcc_total > 0 & output_vcc_total ~= . ///
	& cultivatedarea == 0                                                        
drop if error_cultivatedarea == 1
drop error_cultivatedarea

/* Correct for some likely errors: zero sownarea area with positive output */

* Method: replace it with hh average
gen error_sownarea = 0 if sownarea != .
replace error_sownarea = 1 if output_vcc_total > 0 & output_vcc_total ~= . ///
	& sownarea == 0                                                               
bysort hhid: egen meansown = mean(sownarea) if output_vcc_total > 0 & output_vcc_total != .
replace sownarea = meansown if error_sownarea == 1                                 
drop error_sownarea meansown

* Delete the remaining 
gen error_sownarea = 0 if sownarea != .
replace error_sownarea = 1 if output_vcc_total > 0 & output_vcc_total ~= . ///
	& sownarea == 0                                                                
drop if error_sownarea == 1
drop error_sownarea



save "$working-data/basic-cleaning-done.dta", replace

