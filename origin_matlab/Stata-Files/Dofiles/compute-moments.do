/* This is the code that computes data moments used in calibration.

Used in "Land Security and Mobility Barriers," 
for publication at the Quarterly Journal of Economics.

by Tasso Adamopoulos, Loren Brandt, Chaoran Chen, Diego Restuccia, Xiaoyun Wei. 
*/


********************************************************************************
// Data cleaning process
********************************************************************************
clear all
set more off

global root         = "~" 
global dofiles      = "$root/Dofiles"
global temp-data    = "$root/Temp-data"
global working-data = "$root/Working-data"
global results      = "$root/Results"

********************************************************************************
// Estimate moments
********************************************************************************

/* Step 1: collect information from the household data */

use "$working-data/basic-cleaning-done.dta", clear


/* Generate moments on tau_y */

gen p_theta = 0.533
gen p_gamma = 0.75
gen output = valueadded_vcc_total
gen labor  = labor_agr_total
gen land   = cultivatedarea

gen s    = (output/(labor^(1-p_theta)*land^p_theta)^p_gamma)^(1/(1-p_gamma))
gen TFPR = output/(labor^(1-p_theta)*land^p_theta)
gen TFPQ = s^(1-p_gamma)

label var TFPR "Farm TFPR"
label var TFPQ "Farm TFPQ"

/* Generate nominal wage rate in agriculture */

* We do not drop wage rate of zero here since in agr there is indeed free labor
gen wage_rate_agr = (labor_agr_hired_cost + labor_side_hired_cost)/(labor_agr_hired + labor_side_hired)

replace wage_rate_agr = wage_rate_agr*0.75*5/7
/* 0.75 is to adjust for peak/nonpeak season following Xiaobo Zhang's statistics 
	5/7 is to adjust for the counting issue: counting working days without breaks */
	
gen wage_rate_agr_het = wage_rate_agr

gen temp = .
foreach x of numlist 2004/2018 {
	qui sum wage_rate_agr if year == `x', de
	qui sum wage_rate_agr if year == `x' & wage_rate_agr < r(p99), de
	replace temp = r(mean) if year == `x'
	
}

replace wage_rate_agr = temp
drop temp



/* Generate nominal income of farming households */


gen hh_inc_farming = .
label var hh_inc_farming "Household income from operating the farm"


/* 2004 - 2008 */

egen temp1 = rowtotal(nh4a*_5 nh4a*_6 nh4a*_8 nh4a*_9 nh4a*_10 nh4a*_11 ///
	 nh4a*_12 nh4a*_13 nh4a*_14 nh4a*_15 nh4a*_16 nh4a*_17 ///
	 nh4b*_5 nh4b*_6 nh4b*_8 nh4b*_9 nh4b*_10 nh4b*_11 ///
	 nh4b*_12 nh4b*_13 nh4b*_14 nh4b*_15 nh4b*_16 nh4b*_17)
egen temp2 = rowtotal(nh4a*_4 nh4a*_21 nh4b*_4 nh4b*_21)
replace hh_inc_farming = temp2 - temp1 if year >= 2004 & year <= 2008
drop temp1 temp2

/* 2009 and 2010 */

egen temp1 = rowtotal(nh4a*_5 nh4a*_7 nh4a*_8 nh4a*_9 nh4a*_10 nh4a*_11 ///
	 nh4a*_12 nh4a*_13 nh4a*_14 nh4a*_16 ///
	 nh4b*_5 nh4b*_7 nh4b*_8 nh4b*_9 nh4b*_10 nh4b*_11 ///
	 nh4b*_12 nh4b*_13 nh4b*_14 nh4b*_16)
egen temp2 = rowtotal(nh4a*_4 nh4a*_20 nh4b*_4 nh4b*_20)
replace hh_inc_farming = temp2 - temp1 if year >= 2009 & year <= 2010
drop temp1 temp2

/* 2011 -2018 */

egen temp1 = rowtotal(nh4a*_6 nh4a*_8 nh4a*_9 nh4a*_10 nh4a*_11 nh4a*_12 nh4a*_13 ///
	nh4a*_14 nh4a*_15 nh4a*_17 ///
	nh4b*_6 nh4b*_8 nh4b*_9 nh4b*_10 nh4b*_11 nh4b*_12 nh4b*_13 ///
	nh4b*_14 nh4b*_15 nh4b*_17)
egen temp2 = rowtotal(nh4a*_4 nh4a*_21 nh4b*_4 nh4b*_21)
replace hh_inc_farming = temp2 - temp1 if year >= 2011 & year <= 2018
drop temp1 temp2


/* income from livestocks */

egen temp1 = rowtotal(nh4c*_1) 
egen temp2 = rowtotal(nh4c*_6) 
egen temp3 = rowtotal(nh4c*_7) 
egen temp4 = rowtotal(nh4c*_8)  
egen temp5 = rowtotal(nh4c*_10)  
egen temp6 = rowtotal(nh4c*_11) 
egen temp7 = rowtotal(nh4c*_16) 
egen temp8 = rowtotal(nh4c*_18) 

replace hh_inc_livestock = temp1 - temp3 + temp6 if year >= 2004 & year <= 2008
replace hh_inc_livestock = temp1 - temp4 + temp7 if year >= 2009 & year <= 2010
replace hh_inc_livestock = temp1 - temp5 + temp8 if year >= 2011 & year <= 2018

label var hh_inc_livestock "Household net income from livestocks"
drop temp*

/* income from others */

egen temp1 = rowtotal(nh4d*_1)
egen temp2 = rowtotal(nh4d*_2)
egen temp3 = rowtotal(nh4d*_5)

gen temp4 = nh4d3_1
replace temp4 = 0 if temp4 == .

gen temp5 = nh4d3_2
replace temp5 = 0 if temp5 == .

gen temp6 = nh4d3_5
replace temp6 = 0 if temp6 == .

gen hh_inc_other = temp1 - temp2 + temp3 - (temp4 - temp5 + temp6) /* double counting */

label var hh_inc_other "Household net income from others including forestry"

gen temp7 = nh4d1_1
replace temp7 = 0 if temp7 == .

gen temp8 = nh4d1_2
replace temp8 = 0 if temp8 == .

gen temp9 = nh4d1_5
replace temp9 = 0 if temp9 == .

gen hh_inc_nonagr_business = hh_inc_other - (temp7 - temp8 + temp9) if year <= 2018 
label var hh_inc_nonagr_business "Household net income from non-farm business"

drop temp*

/* income from labor supply to nonagr */


egen temp = rowtotal(nh7_7 nh7_8 nh7_13)
replace hh_inc_nonagr = temp if year >= 2004 & year <= 2008
drop temp


egen hh_inc_nonagr_rural = rowtotal(nh7_4 nh7_5) if year >= 2009 & year <= 2018

gen hh_inc_nonagr_urban = nh7_6 if year >= 2009 & year <= 2017
replace hh_inc_nonagr_urban = nh7_7 if year == 2018

egen temp = rowtotal(hh_inc_nonagr_rural hh_inc_nonagr_urban)
replace hh_inc_nonagr = temp if year >= 2009 & year <= 2018
drop temp


label var hh_inc_nonagr "Household income from labor supply to the non-agricultural sector"
label var hh_inc_nonagr_rural "Household income from labor supply to rural non-agricultural sector"
label var hh_inc_nonagr_urban "Household income from labor supply to urban non-agricultural sector"

keep hhid hh_inc_farming hh_inc_livestock hh_inc_nonagr_business hh_inc_nonagr ///
	hh_inc_nonagr_rural hh_inc_nonagr_urban year wage_rate_agr ///
	TFPR TFPQ s output labor land p_gamma p_theta wage_rate_agr_het ///
	labor_agr_total labor_agr_hired labor_side_total labor_side_hired hh_inc_other ///
	leasedin leasedout sownarea output_vcc_total intermediate_vcc_total
	
sort hhid year

rename hhid hhid_original

/* Calculate the cumulative lease-out land */

xtset hhid year

replace leasedin  = 0 if leasedin  == .
replace leasedout = 0 if leasedout == .

gen cumu_leasedout = leasedout if year == 2004

foreach x of numlist 2005/2018 {
	replace cumu_leasedout = L.cumu_leasedout + leasedout - leasedin if year == `x'
}


/* generate a permanent component of productivity and reconstruct output */


gen logs = log(s)
areg logs i.year, absorb(hhid)
predict logs_hat, d

sum logs_hat, de
gen s_hat = exp(logs_hat)
gen y_hat = s_hat^(1-p_gamma)*(labor^(1-p_theta)*land^p_theta)^p_gamma


gen TFPR_hat = y_hat/(labor^(1-p_theta)*land^p_theta)
gen TFPQ_hat = s_hat^(1-p_gamma)



save "$temp-data/household-inc-cleaned.dta", replace




/* Step 2: collect information from the individual data */

use "$temp-data/ready-for-analysis-individual", clear

bys year hhid: gen hhsize = _N 

gen dummy_student = 1 if nh1b_5 == 2 & year <= 2017
replace dummy_student = 1 if nh1b_6 == 2 & year == 2018

replace dummy_student = 0 if dummy_student == .
replace dummy_student = 0 if dummy_student == 2


gen health = nh1b_11 if year <= 2008
replace health = nh1b_13 if year >= 2009 & year <= 2017
replace health = nh1b_23 if year == 2018
 
 
bys year hhid: gen hhsize = _N // household size 


* # of old  
gen old_dummy = 1 if age > 65
bys year hhid: egen old_num = total(old_dummy)

* # of children under 7 years old 
gen child7_dummy = 1 if age < 7
bys year hhid: egen child7_num = total(child7_dummy)

* # of children under 12 years old 
gen child12_dummy = 1 if age <= 12
bys year hhid: egen child12_num = total(child12_dummy)

* share of old and children under 7 years old 
gen old_child7_share = (old_num + child7_num)/hhsize 

* share of old and children under 12 years old 
gen old_child12_share = (old_num + child12_num)/hhsize 

* # of labor 
gen labor_dummy = 1 if age >= 16 & age <= 65 & dummy_student == 0 & health ~= 5 
bys year hhid: egen labor_num = total(labor_dummy)

* # of sibling 
gen temp1 = 1 if relation == 7
bys year hhid: egen temp1_num = total(temp1)
gen temp2 = 1 if relation == 3
bys year hhid: egen temp2_num = total(temp2)
gen temp3 = 1 if relation == 4
bys year hhid: egen temp3_num = total(temp3)
gen sibling_num = .
replace sibling_num = temp1_num - 1 if relation == 1 | relation == 2
replace sibling_num = temp2_num - 1 if relation == 3
replace sibling_num = temp3_num - 1 if relation == 4
drop temp*

replace sibling_num = 0 if sibling_num == -1 



recast double indid 

replace indid = hhid*100 + indid

keep if age >= 16 & age <= 65
drop if indid == .

/* Labor supply in agriculture */


gen LS_agr = .
replace LS_agr = nh1b_15 if year <= 2008
replace LS_agr = nh1b_17 if year >= 2009 & year <= 2017
replace LS_agr = nh1b_27 if year == 2018
replace LS_agr = 0 if LS_agr == .
replace LS_agr = 365 if LS_agr >= 365 

/* Labor supply in local nonagriculture */

gen LS_nonagr_rural = .
egen temp = rowtotal(nh1b_16 nh1b_17)
replace LS_nonagr_rural = temp if year <= 2008 & nh1b_20 <= 2                   
replace LS_nonagr_rural = nh1b_16 if year <= 2008 & nh1b_20 >= 3                 
drop temp

egen temp = rowtotal(nh1b_18 nh1b_19)
replace LS_nonagr_rural = temp if (year >= 2009 & year <= 2017) & nh1b_22 == 1                           
replace LS_nonagr_rural = nh1b_18 if (year >= 2009 & year <= 2017) & nh1b_22 >= 2  
drop temp

egen temp = rowtotal(nh1b_30 nh1b_32)
replace LS_nonagr_rural = temp if year == 2018 & nh1b_35 == 1
replace LS_nonagr_rural = nh1b_30 if year == 2018 & nh1b_35 >= 2
drop temp

              
replace LS_nonagr_rural = 0 if LS_nonagr_rural == . 
replace LS_nonagr_rural = 365 if LS_nonagr_rural > 365

/* 
Note that for local nonagr labor supply, only a part of it has a record of income.
Hence we need to separate that component. */

gen LS_nonagr_rural2 = .
replace LS_nonagr_rural2 = nh1b_17 if year <= 2008 & nh1b_20 <= 2               
replace LS_nonagr_rural2 = nh1b_19 if (year >= 2009 & year <= 2017) & nh1b_22 == 1   
replace LS_nonagr_rural2 = nh1b_32 if year == 2018 & nh1b_35 == 1
replace LS_nonagr_rural2 = 0 if LS_nonagr_rural2 == . 
replace LS_nonagr_rural2 = 365 if LS_nonagr_rural2 > 365



/* Labor supply in urban nonagriculture */

gen LS_nonagr_urban = .

replace LS_nonagr_urban = nh1b_17 if year <= 2008 & nh1b_20 >= 3
replace LS_nonagr_urban = nh1b_19 if (year >= 2009 & year <= 2017) & nh1b_22 >= 2
replace LS_nonagr_urban = nh1b_32 if year == 2018 & nh1b_35 >= 2
replace LS_nonagr_urban = 0 if LS_nonagr_urban == . 
replace LS_nonagr_urban = 365 if LS_nonagr_urban >= 365


label var LS_agr "Labor supply to agriculture, days"
label var LS_nonagr_rural "Labor supply to local nonagr, days"
label var LS_nonagr_urban "Labor supply to urban nonagr, days"

egen LS_nonagr = rowtotal(LS_nonagr_rural LS_nonagr_urban)
label var LS_nonagr "Labor supply to nonagr, both local and urban"





/* Merge it with the household information */
cap drop _merge 
sort hhid_original year
merge m:1 hhid_original year using "$temp-data/household-inc-cleaned.dta"

drop if _merge == 1 
drop if _merge == 2

gen dummy_LS_nonagr_rural = 1 if LS_nonagr_rural > 0 & LS_nonagr_rural ~= .
bys hhid year: egen sole_nonagr_rural = total(dummy_LS_nonagr_rural)
replace sole_nonagr_rural = 2 if sole_nonagr_rural > 1

gen dummy_LS_nonagr_urban = 1 if LS_nonagr_urban > 0 & LS_nonagr_urban ~= .
bys hhid year: egen sole_nonagr_urban = total(dummy_LS_nonagr_urban)
replace sole_nonagr_urban = 2 if sole_nonagr_urban > 1


/* Labor income */

gen inc_nonagr_rural = .
replace inc_nonagr_rural = nh1b_18 if year <= 2008 & nh1b_20 <= 2               
replace inc_nonagr_rural = nh1b_20 if (year >= 2009 & year <= 2017) & nh1b_22 == 1
replace inc_nonagr_rural = nh1b_33 if year == 2018 & nh1b_35 == 1
replace inc_nonagr_rural = 0 if inc_nonagr_rural == .

replace inc_nonagr_rural = hh_inc_nonagr if year <= 2008 & nh1b_20 <= 2 & ///
	sole_nonagr_rural == 1 & hh_inc_nonagr ~= . & sole_nonagr_urban == 0 & inc_nonagr_rural == 0
replace inc_nonagr_rural = hh_inc_nonagr_rural if (year >= 2009 & year <= 2017) & nh1b_22 == 1 & /// 
	sole_nonagr_rural == 1 & hh_inc_nonagr_rural ~= . & inc_nonagr_rural == 0
replace inc_nonagr_rural = hh_inc_nonagr_rural if year == 2018 & nh1b_35 == 1 & /// 
	sole_nonagr_rural == 1 & hh_inc_nonagr_rural ~= . & inc_nonagr_rural == 0


gen wage_rate_nonagr_rural = inc_nonagr_rural / LS_nonagr_rural2
replace wage_rate_nonagr_rural = . if wage_rate_nonagr_rural == 0

gen inc_nonagr_urban = .                                                        
replace inc_nonagr_urban = nh1b_18 if year <= 2008 & nh1b_20 >= 3
replace inc_nonagr_urban = nh1b_20 if (year >= 2009 & year <= 2017) & nh1b_22 >= 2
replace inc_nonagr_urban = nh1b_33 if year == 2018 & nh1b_35 >= 2
replace inc_nonagr_urban = 0 if inc_nonagr_urban == .

gen wage_rate_nonagr_urban = inc_nonagr_urban / LS_nonagr_urban
replace wage_rate_nonagr_urban = . if wage_rate_nonagr_urban == 0

label var inc_nonagr_rural "Total income, rural nonagr (outside own town)"
label var inc_nonagr_urban "Total income, urban nonagr"
label var wage_rate_nonagr_rural "Wage rate, rural nonagr (outside own town)"
label var wage_rate_nonagr_urban "Wage rate, urban nonagr"




/* Step 3: Define Farm operator */

replace LS_agr = 0 if LS_agr == .

gen dummy_operator = 0
replace dummy_operator = 1 if nh1b_12 == 1 & year <= 2008                       
replace dummy_operator = 1 if nh1b_14 == 1 & (year >= 2009 & year <= 2017)
replace dummy_operator = 1 if nh1b_24 == 1 & year == 2018
replace dummy_operator = 0 if LS_agr < 60

label var dummy_operator "Household farm operator"

bys year: egen threshold = median(output_vcc_total)


/* For those without operator: choose the person with the highest agr labor supply */

bys hhid year: egen total_operator = total(dummy_operator)


bys hhid year: egen max_LS_agr = max(LS_agr)
gen dummy_operator2 = 0
replace dummy_operator2 = 1 if LS_agr == max_LS_agr & LS_agr >= 60 
drop max_LS_agr
replace dummy_operator = dummy_operator2 if total_operator == 0 


/* For those with more than one operators: choose the person with the highest
labor supply in agr (within them), then choose the person with the lowest labor 
supply in nonagriculture */

drop total_operator
bys hhid year: egen total_operator = total(dummy_operator)

bys hhid year dummy_operator: egen max_LS_agr = max(LS_agr)
replace dummy_operator = 0 if LS_agr < max_LS_agr & total_operator >= 2
drop max_LS_agr

drop total_operator
bys hhid year: egen total_operator = total(dummy_operator)

bys hhid year dummy_operator: egen min_LS_nonagr = min(LS_nonagr)
replace dummy_operator = 0 if LS_nonagr > min_LS_nonagr & total_operator >= 2
drop min_LS_nonagr

/* still more than one operator: choose relation == 1 and then male and then age */

drop total_operator
bys hhid year: egen total_operator = total(dummy_operator)

gen dummy_operator_temp = dummy_operator
replace dummy_operator = 0 if relation ~= 1 & total_operator >= 2 

drop total_operator
bys hhid year: egen total_operator = total(dummy_operator)

replace dummy_operator = dummy_operator_temp if total_operator == 0
drop dummy_operator_temp





drop total_operator
bys hhid year: egen total_operator = total(dummy_operator)

gen dummy_operator_temp = dummy_operator
replace dummy_operator = 0 if gender == 2 & total_operator >= 2

drop total_operator
bys hhid year: egen total_operator = total(dummy_operator)

replace dummy_operator = dummy_operator_temp if total_operator == 0
drop dummy_operator_temp



drop total_operator
bys hhid year: egen total_operator = total(dummy_operator)

gen dummy_operator_temp = dummy_operator
replace dummy_operator = 0 if gender == 2 & total_operator >= 2

drop total_operator
bys hhid year: egen total_operator = total(dummy_operator)

replace dummy_operator = dummy_operator_temp if total_operator == 0
drop dummy_operator_temp




drop total_operator
bys hhid year: egen total_operator = total(dummy_operator)

gen dummy_operator_temp = dummy_operator

drop total_operator
bys hhid year: egen total_operator = total(dummy_operator)
bys hhid year dummy_operator: egen max_age = max(age)
replace dummy_operator = 0 if age < max_age & total_operator >= 2
drop max_age

drop total_operator
bys hhid year: egen total_operator = total(dummy_operator)

replace dummy_operator = dummy_operator_temp if total_operator == 0
drop dummy_operator_temp


drop total_operator
bys hhid year: egen total_operator = total(dummy_operator)

tab total_operator





gen inc_farming = hh_inc_farming + hh_inc_livestock + hh_inc_other - hh_inc_nonagr_business ///
	if dummy_operator == 1


gen wage_rate_farming = inc_farming / 365


* Compare the households with and without operators

preserve

bys hhid year: egen hh_LS_agr = total(LS_agr)
bys total_operator: sum hh_LS_agr

restore


/* Step 4: define employment and age status */



gen dummy_1 = 0

replace dummy_1 = 1 if dummy_student == 1

label var dummy_1 "Indicator variable for schooling "


replace LS_agr = 0 if LS_agr == .
replace LS_nonagr_rural = 0 if LS_nonagr_rural == .
replace LS_nonagr_urban = 0 if LS_nonagr_urban == .

gen LS_threshold = 10




gen dummy_2 = 0
replace dummy_2 = 1 if LS_agr > LS_threshold & LS_nonagr_rural <= LS_threshold ///
	& LS_nonagr_urban <= LS_threshold & dummy_1 == 0 & dummy_operator == 0
label var dummy_2 "Indicator variable: fulltime agr"

gen dummy_3 = 0
replace dummy_3 = 1 if LS_nonagr_rural > LS_threshold & ///
	LS_nonagr_urban <= LS_threshold & LS_agr <= LS_threshold & dummy_1 == 0 & dummy_operator == 0
label var dummy_3 "Indicator variable: fulltime rural nonagr"

gen dummy_4 = 0
replace dummy_4 = 1 if LS_nonagr_urban > LS_threshold & ///
	LS_nonagr_rural <= LS_threshold & LS_agr <= LS_threshold & dummy_1 == 0 & dummy_operator == 0
label var dummy_4 "Indicator variable: fulltime urban nonagr"

gen dummy_5 = 0
replace dummy_5 = 1 if LS_agr > LS_threshold & LS_nonagr_rural > LS_threshold & ///
	LS_nonagr_urban <= LS_threshold & dummy_1 == 0  & dummy_operator == 0
label var dummy_5 "Indicator variable: parttime agr and rural nonagr"
	
gen dummy_6 = 0
replace dummy_6 = 1 if LS_agr > LS_threshold & LS_nonagr_urban > LS_threshold & ///
	LS_nonagr_rural <= LS_threshold & dummy_1 == 0  & dummy_operator == 0
label var dummy_6 "Indicator variable: parttime agr and urban nonagr"
	
gen dummy_7 = 0
replace dummy_7 = 1 if LS_nonagr_urban > LS_threshold & LS_nonagr_rural > LS_threshold & ///
	LS_agr <= LS_threshold & dummy_1 == 0 & dummy_operator == 0
label var dummy_7 "Indicator variable: parttime rural and urban nonagr"
	
gen dummy_8 = 0
replace dummy_8 = 1 if LS_nonagr_urban > LS_threshold & LS_nonagr_rural > LS_threshold & ///
	LS_agr > LS_threshold & dummy_1 == 0  & dummy_operator == 0
label var dummy_8 "Indicator variable: parttime agr, rural and urban nonagr"

gen dummy_9 = 0
replace dummy_9 = 1 if LS_agr <= LS_threshold & LS_nonagr_rural <= LS_threshold & ///
	LS_nonagr_urban <= LS_threshold & dummy_1 == 0 & dummy_operator == 0
label var dummy_9 "Indicator variable: not working"



/* clean up income statistics */

replace wage_rate_nonagr_rural = . if dummy_operator == 1
replace wage_rate_nonagr_urban = . if dummy_operator == 1
replace wage_rate_agr          = . if dummy_operator == 1


replace wage_rate_farming      = . if dummy_2 == 1
replace wage_rate_nonagr_rural = . if dummy_2 == 1
replace wage_rate_nonagr_urban = . if dummy_2 == 1

replace wage_rate_farming      = . if dummy_3 == 1
replace wage_rate_agr          = . if dummy_3 == 1
replace wage_rate_nonagr_urban = . if dummy_3 == 1

replace wage_rate_farming      = . if dummy_4 == 1
replace wage_rate_nonagr_rural = . if dummy_4 == 1
replace wage_rate_agr          = . if dummy_4 == 1

replace wage_rate_farming      = . if dummy_5 == 1
replace wage_rate_nonagr_urban = . if dummy_5 == 1

replace wage_rate_farming      = . if dummy_6 == 1
replace wage_rate_nonagr_rural = . if dummy_6 == 1


gen logwage_rural = log(wage_rate_nonagr_rural)
gen logwage_urban = log(wage_rate_nonagr_urban)
gen logwage_agr   = log(wage_rate_agr) 
gen logwage_farming = log(wage_rate_farming)

gen VOI = .

egen indid_year = group(indid year)
egen hhid_year  = group(hhid  year)

gen dummy_old = 0
replace dummy_old = 1 if age >= 45
label var dummy_old "Old individuals"

save "$temp-data/ready-for-moments.dta", replace




use "$temp-data/ready-for-moments.dta", clear


/*

//coastal area

gen coastal = 0
replace coastal = 1 if prov == 12 | prov == 31 | prov == 32 | prov == 33 | prov == 35 | ///
prov == 37 | prov == 44 | prov == 46 | prov == 21 | prov == 13

keep if coastal == 0
//keep if coastal == 1

*/



/*
//suburb
cap drop _merge 
merge m:1 year village using "$temp-data/village_suburb.dta"

drop if _merge < 3  
drop _merge

keep if suburb == 0
//keep if suburb == 1

*/



drop if dummy_1 == 1 | dummy_9 == 1 /* drop those who do not work */

tab dummy_old






/* =================================*/
*Step 5: Calculate employment statistics
/* =================================*/


preserve

* Experiment with part-time workers to identify the dispersion in labor mobility barriers

gen wage_rate_nonagr = .
replace wage_rate_nonagr = wage_rate_nonagr_rural if wage_rate_nonagr_rural ~= .
replace wage_rate_nonagr = wage_rate_nonagr_urban if wage_rate_nonagr_urban ~= .

cap drop temp1 
egen temp1 = rowtotal(LS_agr LS_nonagr_rural LS_nonagr_urban)
gen LS_agr_frac = LS_agr/temp1
drop temp1
 
spearman LS_agr_frac wage_rate_nonagr if year == 2004 & LS_agr_frac ~= 0 & LS_agr_frac ~= 1


gen inc_nonagr = .
replace inc_nonagr = inc_nonagr_rural if inc_nonagr_rural ~= . & inc_nonagr_rural ~= 0
replace inc_nonagr = inc_nonagr_urban if inc_nonagr_urban ~= . & inc_nonagr_urban ~= 0
gen LS_nonagr_frac = 1-LS_agr_frac


gen corr_LS_wage_2035    = .
gen corr_LS_wage_2035_se = .
gen corr_LS_wage_1020    = .
gen corr_LS_wage_1020_se = .
label var corr_LS_wage_2035 "Rank correlation of labor supply and hours, hours 0.20-0.35"
label var corr_LS_wage_1020 "Rank correlation of labor supply and hours, hours 0.10-0.20"


foreach x of numlist 2004/2018 {

bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
	spearman LS_nonagr inc_nonagr if year == `x' & LS_agr_frac >= 0.20 & LS_agr_frac <= 0.35
qui replace corr_LS_wage_2035    = _b[_bs_1]  if year == `x'
qui replace corr_LS_wage_2035_se = _se[_bs_1] if year == `x'

bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
	spearman LS_nonagr inc_nonagr if year == `x' & LS_agr_frac >= 0.10 & LS_agr_frac <= 0.20
qui replace corr_LS_wage_1020    = _b[_bs_1]  if year == `x'
qui replace corr_LS_wage_1020_se = _se[_bs_1] if year == `x'
}

collapse (mean) corr_LS_wage_*, by(year)
export excel corr_LS_wage_1020 corr_LS_wage_1020_se corr_LS_wage_2035 corr_LS_wage_2035_se ///
	using "$results/estimation-Calibration.xlsx", sheet("Part-time LS",   modify) cell(C4)
sleep 100
	
restore




preserve


gen ope_share   = .
gen agr_share   = .
gen rural_share = .
gen urban_share = .
gen ar_share    = .
gen an_share    = .

gen ope_share_se   = .
gen agr_share_se   = .
gen rural_share_se = .
gen urban_share_se = .
gen ar_share_se    = .
gen an_share_se    = .

label var ope_share   "Employment share, operators"
label var agr_share   "Employment share, full-time agricultural workers"
label var rural_share "Employment share, full-time rural non-agr workers"
label var urban_share "Employment share, full-time urban non-agr workers"
label var ar_share    "Employment share, part-time agr and rural nonagr"
label var an_share    "Employment share, part-time agr and urban nonagr"



gen LS_agr_pt_frac = LS_agr/(LS_agr + LS_nonagr)
label var LS_agr_pt_frac "Fraction of labor supply to agr among part-time workers"

gen LS_agr_pt_rural = .
gen LS_agr_pt_urban = .
gen LS_agr_pt_both  = .

gen LS_agr_pt_rural_se = .
gen LS_agr_pt_urban_se = .
gen LS_agr_pt_both_se  = .

label var LS_agr_pt_rural ///
	"Fraction of labor supply to agr--part-time workers with rural nonagr"
label var LS_agr_pt_urban ///
	"Fraction of labor supply to agr--part-time workers with urban nonagr"
label var LS_agr_pt_both  ///
	"Fraction of labor supply to agr--part-time workers with rural or urban nonagr"

	
gen LS_agr_pt_rural_med = .
gen LS_agr_pt_urban_med = .
gen LS_agr_pt_both_med  = .

gen LS_agr_pt_rural_med_se = .
gen LS_agr_pt_urban_med_se = .
gen LS_agr_pt_both_med_se  = .

label var LS_agr_pt_rural_med ///
	"Fraction of labor supply to agr--part-time workers with rural nonagr, median"
label var LS_agr_pt_urban_med ///
	"Fraction of labor supply to agr--part-time workers with urban nonagr, median"
label var LS_agr_pt_both_med  ///
	"Fraction of labor supply to agr--part-time workers with rural or urban nonagr, median"
	
	
gen LS_agr_pt_rural_sd = .
gen LS_agr_pt_urban_sd = .
gen LS_agr_pt_both_sd  = .

label var LS_agr_pt_rural_med ///
	"Fraction of labor supply to agr--part-time workers with rural nonagr, sd"
label var LS_agr_pt_urban_med ///
	"Fraction of labor supply to agr--part-time workers with urban nonagr, sd"
label var LS_agr_pt_both_med  ///
	"Fraction of labor supply to agr--part-time workers with rural or urban nonagr, sd"
	
gen LS_agr_pt_rural_ir = .
gen LS_agr_pt_urban_ir = .
gen LS_agr_pt_both_ir  = .


label var LS_agr_pt_rural_med ///
	"Fraction of labor supply to agr--part-time workers with rural nonagr, inter range"
label var LS_agr_pt_urban_med ///
	"Fraction of labor supply to agr--part-time workers with urban nonagr, inter range"
label var LS_agr_pt_both_med  ///
	"Fraction of labor supply to agr--part-time workers with rural or urban nonagr, inter range"

	
/* Not many individuals in bin 7 and 8; use an_share to absorb */
//replace dummy_6 = 1 if dummy_7 == 1 | dummy_8 == 1

** changes in July 15th, 2023: if an individual does parttime in rural nonagr and urban nonagr, we put him in the group of urban non agr.

replace dummy_4 = 1 if dummy_7 == 1
replace dummy_6 = 1 if dummy_8 == 1


foreach x of numlist 2004/2018 {
display(`x')
	
	

	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_operator if year == `x'
	qui replace ope_share    = _b[_bs_1]  if year == `x'
	qui replace ope_share_se = _se[_bs_1] if year == `x'

	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_2 if year == `x'
	qui replace agr_share    = _b[_bs_1]  if year == `x'
	qui replace agr_share_se = _se[_bs_1] if year == `x'

	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_3 if year == `x'
	qui replace rural_share    = _b[_bs_1]  if year == `x'
	qui replace rural_share_se = _se[_bs_1] if year == `x'

	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_4 if year == `x'
	qui replace urban_share    = _b[_bs_1]  if year == `x'
	qui replace urban_share_se = _se[_bs_1] if year == `x'

	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_5 if year == `x'
	qui replace ar_share    = _b[_bs_1]  if year == `x'
	qui replace ar_share_se = _se[_bs_1] if year == `x'

	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_6 if year == `x'
	qui replace an_share    = _b[_bs_1]  if year == `x'
	qui replace an_share_se = _se[_bs_1] if year == `x'


	bootstrap r(p50), rep(100) notable nolegend noheader nowarn nodots: ///
		sum LS_agr_pt_frac if year == `x' & dummy_5 > 0, de
	qui replace LS_agr_pt_rural_med    = _b[_bs_1]  if year == `x'
	qui replace LS_agr_pt_rural_med_se = _se[_bs_1] if year == `x'
	
	bootstrap r(p50), rep(100) notable nolegend noheader nowarn nodots: ///
		sum LS_agr_pt_frac if year == `x' & dummy_6 > 0, de
	qui replace LS_agr_pt_urban_med    = _b[_bs_1]  if year == `x'
	qui replace LS_agr_pt_urban_med_se = _se[_bs_1] if year == `x'
	
	bootstrap r(p50), rep(100) notable nolegend noheader nowarn nodots: ///
		sum LS_agr_pt_frac if year == `x' & (dummy_5 > 0 | dummy_6 > 0), de
	qui replace LS_agr_pt_both_med    = _b[_bs_1]  if year == `x'
	qui replace LS_agr_pt_both_med_se = _se[_bs_1] if year == `x'
	
	
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum LS_agr_pt_frac if year == `x' & dummy_5 > 0, de
	qui replace LS_agr_pt_rural    = _b[_bs_1]  if year == `x'
	qui replace LS_agr_pt_rural_se = _se[_bs_1] if year == `x'
	
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum LS_agr_pt_frac if year == `x' & dummy_6 > 0, de
	qui replace LS_agr_pt_urban    = _b[_bs_1]  if year == `x'
	qui replace LS_agr_pt_urban_se = _se[_bs_1] if year == `x'
	
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum LS_agr_pt_frac if year == `x' & (dummy_5 > 0 | dummy_6 > 0), de
	qui replace LS_agr_pt_both    = _b[_bs_1]  if year == `x'
	qui replace LS_agr_pt_both_se = _se[_bs_1] if year == `x'
	
	
	qui sum LS_agr_pt_frac if year == `x' & dummy_5 > 0, de
	qui replace LS_agr_pt_rural_sd    = r(sd)  if year == `x'
	qui replace LS_agr_pt_rural_ir    = r(p75)-r(p25) if year == `x'
	
	qui sum LS_agr_pt_frac if year == `x' & dummy_6 > 0, de
	qui replace LS_agr_pt_urban_sd    = r(sd)  if year == `x'
	qui replace LS_agr_pt_urban_ir    = r(p75)-r(p25) if year == `x'
	
	qui sum LS_agr_pt_frac if year == `x' & (dummy_5 > 0 | dummy_6 > 0), de
	qui replace LS_agr_pt_both_sd     = r(sd)  if year == `x'
	qui replace LS_agr_pt_both_ir     = r(p75)-r(p25) if year == `x'
	
	
	

}


collapse (mean) *_share *_share_se LS_agr_pt*, by(year)
export excel ope_share ope_share_se agr_share agr_share_se rural_share rural_share_se ///
	urban_share urban_share_se ar_share ar_share_se an_share an_share_se ///
	using "$results/estimation-Calibration.xlsx", sheet("Employment Share",modify) cell(B4)
sleep 100

export excel LS_agr_pt_rural LS_agr_pt_rural_se LS_agr_pt_rural_med LS_agr_pt_rural_med_se ///
	LS_agr_pt_rural_sd LS_agr_pt_rural_ir ///
	LS_agr_pt_urban LS_agr_pt_urban_se LS_agr_pt_urban_med LS_agr_pt_urban_med_se ///
	LS_agr_pt_urban_sd LS_agr_pt_urban_ir ///
	LS_agr_pt_both LS_agr_pt_both_se LS_agr_pt_both_med LS_agr_pt_both_med_se ///
	LS_agr_pt_both_sd LS_agr_pt_both_ir ///
	using "$results/estimation-Calibration.xlsx", sheet("Employment Share",modify) cell(O4)
sleep 100

restore        

     
/* Age distribution by employment status */


preserve



gen ope_old_share   = .
gen agr_old_share   = .
gen rural_old_share = .
gen urban_old_share = .
gen ar_old_share    = .
gen an_old_share    = .

gen ope_old_share_se   = .
gen agr_old_share_se   = .
gen rural_old_share_se = .
gen urban_old_share_se = .
gen ar_old_share_se    = .
gen an_old_share_se    = .

label var ope_old_share   "Fraction of old among operators"
label var agr_old_share   "Fraction of old among full-time agr workers"
label var rural_old_share "Fraction of old among full-time rural nonagr workers"
label var urban_old_share "Fraction of old among full-time urban nonagr workers"
label var ar_old_share    "Fraction of old among part-time workers with rural nonagr"
label var an_old_share    "Fraction of old among part-time workers with urban nonagr"




gen somerural_old_share = .
gen someurban_old_share = .
gen agrope_old_share    = .

gen somerural_old_share_se = .
gen someurban_old_share_se = .
gen agrope_old_share_se    = .

label var somerural_old_share "Fraction of old among individuals with rural nonagr"
label var someurban_old_share "Fraction of old among individuals with urban nonagr"
label var agrope_old_share    "Fraction of old, operator or fulltime agr workers"



gen pop_old_share = .

gen pop_old_share_se = .

label var pop_old_share "Fraction of old, population"


foreach x of numlist 2004/2018 {
display(`x')
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_old if year == `x'
	qui replace pop_old_share    = _b[_bs_1]  if year == `x'
	qui replace pop_old_share_se = _se[_bs_1] if year == `x'

	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_old if dummy_operator == 1 & year == `x'
	qui replace ope_old_share    = _b[_bs_1]  if year == `x'
	qui replace ope_old_share_se = _se[_bs_1] if year == `x'
	
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_old if dummy_2 == 1 & year == `x'
	qui replace agr_old_share    = _b[_bs_1]  if year == `x'
	qui replace agr_old_share_se = _se[_bs_1] if year == `x'

	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_old if dummy_3 == 1 & year == `x'
	qui replace rural_old_share    = _b[_bs_1]  if year == `x'
	qui replace rural_old_share_se = _se[_bs_1] if year == `x'

	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_old if dummy_4 == 1 & year == `x'
	qui replace urban_old_share    = _b[_bs_1]  if year == `x'
	qui replace urban_old_share_se = _se[_bs_1] if year == `x'

	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_old if dummy_5 == 1 & year == `x'
	qui replace ar_old_share    = _b[_bs_1]  if year == `x'
	qui replace ar_old_share_se = _se[_bs_1] if year == `x'

/*
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_old if dummy_6 + dummy_7 + dummy_8 == 1 & year == `x'
*/
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_old if dummy_6 + dummy_8 == 1 & year == `x'
	qui replace an_old_share    = _b[_bs_1]  if year == `x'
	qui replace an_old_share_se = _se[_bs_1] if year == `x'
	
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_old if dummy_3 + dummy_5 == 1 & year == `x'
	qui replace somerural_old_share    = _b[_bs_1]  if year == `x'
	qui replace somerural_old_share_se = _se[_bs_1] if year == `x'
	
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_old if dummy_4 + dummy_6 + dummy_7 + dummy_8 == 1 & year == `x'
	qui replace someurban_old_share    = _b[_bs_1]  if year == `x'
	qui replace someurban_old_share_se = _se[_bs_1] if year == `x'
	
	
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_old if dummy_operator + dummy_2 == 1 & year == `x'
	qui replace agrope_old_share    = _b[_bs_1]  if year == `x'
	qui replace agrope_old_share_se = _se[_bs_1] if year == `x'
	
}

collapse (mean) *old_share *old_share_se, by(year)
export excel ope_old_share ope_old_share_se agr_old_share agr_old_share_se ///
	rural_old_share rural_old_share_se urban_old_share urban_old_share_se ///
	ar_old_share ar_old_share_se an_old_share an_old_share_se ///
	somerural_old_share somerural_old_share_se someurban_old_share someurban_old_share_se ///
	agrope_old_share agrope_old_share_se pop_old_share pop_old_share_se ///
	using "$results/estimation-Calibration.xlsx", firstrow(variables) sheet("Old Share by Employment",modify) cell(B3)
sleep 100

restore



/* Employment Status by Age */


preserve


gen ope_old_share   = .
gen agr_old_share   = .
gen rural_old_share = .
gen urban_old_share = .
gen ar_old_share    = .
gen an_old_share    = .

gen ope_old_share_se   = .
gen agr_old_share_se   = .
gen rural_old_share_se = .
gen urban_old_share_se = .
gen ar_old_share_se    = .
gen an_old_share_se    = .

label var ope_old_share   "Among old: employment share of operators"
label var agr_old_share   "Among old: employment share of fulltime agr workers"
label var rural_old_share "Among old: employment share of fulltime rural nonagr"
label var urban_old_share "Among old: employment share of fulltime urban nonagr"
label var ar_old_share    "Among old: employment share of parttime workers with rural nonagr"
label var an_old_share    "Among old: employment share of parttime workers with urban nonagr"



gen somerural_old_share = .
gen someurban_old_share = .
gen agrope_old_share    = .

gen somerural_old_share_se = .
gen someurban_old_share_se = .
gen agrope_old_share_se    = .

label var somerural_old_share "Among old: share of workers with rural nonagr days"
label var someurban_old_share "Among old: share of workers with urban nonagr days"
label var agrope_old_share    "Among old: share of farm operators and fulltime agr workers"



gen pop_old_share = .

gen pop_old_share_se = .

label var pop_old_share "Old population share"



foreach x of numlist 2004/2018 {
display(`x')
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_old if year == `x'
	qui replace pop_old_share    = _b[_bs_1]  if year == `x'
	qui replace pop_old_share_se = _se[_bs_1] if year == `x'

	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_operator if dummy_old == 1 & year == `x'
	qui replace ope_old_share   = _b[_bs_1]  if year == `x'
	qui replace ope_old_share_se = _se[_bs_1] if year == `x'
	
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_2 if dummy_old == 1 & year == `x'
	qui replace agr_old_share   = _b[_bs_1]  if year == `x'
	qui replace agr_old_share_se = _se[_bs_1] if year == `x'

	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_3 if dummy_old == 1 & year == `x'
	qui replace rural_old_share    = _b[_bs_1]  if year == `x'
	qui replace rural_old_share_se = _se[_bs_1] if year == `x'

	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_4 if dummy_old == 1 & year == `x'
	qui replace urban_old_share    = _b[_bs_1]  if year == `x'
	qui replace urban_old_share_se = _se[_bs_1] if year == `x'

	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_5 if dummy_old == 1 & year == `x'
	qui replace ar_old_share    = _b[_bs_1]  if year == `x'
	qui replace ar_old_share_se = _se[_bs_1] if year == `x'

/*
	qui gen dummy_temp = dummy_6 + dummy_7 + dummy_8
*/
	qui gen dummy_temp = dummy_6 + dummy_8
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_temp if dummy_old == 1 & year == `x'
	qui replace an_old_share    = _b[_bs_1]  if year == `x'
	qui replace an_old_share_se = _se[_bs_1] if year == `x'
	drop dummy_temp
	
	qui gen dummy_temp = dummy_3 + dummy_5
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_temp if dummy_old == 1 & year == `x'
	qui replace somerural_old_share    = _b[_bs_1]  if year == `x'
	qui replace somerural_old_share_se = _se[_bs_1] if year == `x'
	drop dummy_temp
	
	qui gen dummy_temp = dummy_4 + dummy_6 + dummy_7 + dummy_8
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_temp if dummy_old == 1 & year == `x'
	qui replace someurban_old_share    = _b[_bs_1]  if year == `x'
	qui replace someurban_old_share_se = _se[_bs_1] if year == `x'
	drop dummy_temp
	
	qui gen dummy_temp = dummy_operator + dummy_2
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_temp if dummy_old == 1 & year == `x'
	qui replace agrope_old_share    = _b[_bs_1]  if year == `x'
	qui replace agrope_old_share_se = _se[_bs_1] if year == `x'
	drop dummy_temp
	
}

collapse (mean) *old_share *old_share_se, by(year)
export excel ope_old_share ope_old_share_se agr_old_share agr_old_share_se ///
	rural_old_share rural_old_share_se urban_old_share urban_old_share_se ///
	ar_old_share agr_old_share_se an_old_share an_old_share_se ///
	somerural_old_share somerural_old_share_se someurban_old_share someurban_old_share_se ///
	agrope_old_share agrope_old_share_se pop_old_share pop_old_share_se ///
	using "$results/estimation-Calibration.xlsx", firstrow(variables) sheet("Employment Old",modify) cell(B3)
sleep 100

restore



preserve
 
     
gen ope_young_share   = .
gen agr_young_share   = .
gen rural_young_share = .
gen urban_young_share = .
gen ar_young_share    = .
gen an_young_share    = .

gen ope_young_share_se   = .
gen agr_young_share_se   = .
gen rural_young_share_se = .
gen urban_young_share_se = .
gen ar_young_share_se    = .
gen an_young_share_se    = .

label var ope_young_share   "Among young: employment share of operators"
label var agr_young_share   "Among young: employment share of fulltime agr workers"
label var rural_young_share "Among young: employment share of fulltime rural nonagr"
label var urban_young_share "Among young: employment share of fulltime urban nonagr"
label var ar_young_share    "Among young: employment share of parttime workers with rural nonagr"
label var an_young_share    "Among young: employment share of parttime workers with urban nonagr"



gen somerural_young_share = .
gen someurban_young_share = .
gen agrope_young_share    = .

gen somerural_young_share_se = .
gen someurban_young_share_se = .
gen agrope_young_share_se    = .

label var somerural_young_share "Among young: share of workers with rural nonagr days"
label var someurban_young_share "Among young: share of workers with urban nonagr days"
label var agrope_young_share    "Among young: share of farm operators and fulltime agr workers"



gen pop_young_share = .

gen pop_young_share_se = .

label var pop_young_share "Population share of young individuals"

gen dummy_young = 1 - dummy_old

foreach x of numlist 2004/2018 {
display(`x')
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_young if year == `x'
	qui replace pop_young_share    = _b[_bs_1]  if year == `x'
	qui replace pop_young_share_se = _se[_bs_1] if year == `x'

	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_operator if dummy_young == 1 & year == `x'
	qui replace ope_young_share   = _b[_bs_1]  if year == `x'
	qui replace ope_young_share_se = _se[_bs_1] if year == `x'
	
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_2 if dummy_young == 1 & year == `x'
	qui replace agr_young_share   = _b[_bs_1]  if year == `x'
	qui replace agr_young_share_se = _se[_bs_1] if year == `x'

	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_3 if dummy_young == 1 & year == `x'
	qui replace rural_young_share    = _b[_bs_1]  if year == `x'
	qui replace rural_young_share_se = _se[_bs_1] if year == `x'

	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_4 if dummy_young == 1 & year == `x'
	qui replace urban_young_share    = _b[_bs_1]  if year == `x'
	qui replace urban_young_share_se = _se[_bs_1] if year == `x'

	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_5 if dummy_young == 1 & year == `x'
	qui replace ar_young_share    = _b[_bs_1]  if year == `x'
	qui replace ar_young_share_se = _se[_bs_1] if year == `x'

/*
	qui gen dummy_temp = dummy_6 + dummy_7 + dummy_8
*/
	qui gen dummy_temp = dummy_6 + dummy_8
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_temp if dummy_young == 1 & year == `x'
	qui replace an_young_share    = _b[_bs_1]  if year == `x'
	qui replace an_young_share_se = _se[_bs_1] if year == `x'
	drop dummy_temp
	
	qui gen dummy_temp = dummy_3 + dummy_5
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_temp if dummy_young == 1 & year == `x'
	qui replace somerural_young_share    = _b[_bs_1]  if year == `x'
	qui replace somerural_young_share_se = _se[_bs_1] if year == `x'
	drop dummy_temp
	
	qui gen dummy_temp = dummy_4 + dummy_6 + dummy_7 + dummy_8
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_temp if dummy_young == 1 & year == `x'
	qui replace someurban_young_share    = _b[_bs_1]  if year == `x'
	qui replace someurban_young_share_se = _se[_bs_1] if year == `x'
	drop dummy_temp
	
	qui gen dummy_temp = dummy_operator + dummy_2
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_temp if dummy_young == 1 & year == `x'
	qui replace agrope_young_share    = _b[_bs_1]  if year == `x'
	qui replace agrope_young_share_se = _se[_bs_1] if year == `x'
	drop dummy_temp
	
}

collapse (mean) *young_share *young_share_se, by(year)
export excel ope_young_share ope_young_share_se agr_young_share agr_young_share_se ///
	rural_young_share rural_young_share_se urban_young_share urban_young_share_se ///
	ar_young_share ar_young_share_se an_young_share an_young_share_se ///
	somerural_young_share somerural_young_share_se someurban_young_share someurban_young_share_se ///
	agrope_young_share agrope_young_share_se pop_young_share pop_young_share_se ///
	using "$results/estimation-Calibration.xlsx", sheet("Employment Young",modify) cell(B3)
sleep 100

restore




  
/* =================================*/
/* Step 6: calculate income moments */
/* =================================*/

* 6.1 Clean up income statistics---put in earlier section of this code


/* 6.2 Dispersion and within household correlation */

* 6.2.1 Rural nonagr
cap drop temp* 

preserve

qui gen disp1    = .
qui gen disp1_se = .
qui replace VOI = logwage_rural
foreach x of numlist 2004/2018 {
	qui sum VOI if year == `x', de
	qui gen temp1 = r(p1)
	qui gen temp2 = r(p99)
	bootstrap r(sd), rep(100) notable nolegend noheader nowarn nodots: ///
		sum VOI if VOI >= temp1 & VOI <= temp2 & year == `x'
	qui replace disp1    = _b[_bs_1]  if year == `x'
	qui replace disp1_se = _se[_bs_1] if year == `x'
	drop temp1 temp2
}
label var disp1 "Dispersion of rural nonagr wage rate"

/* Calculate the correlation of rural nonagr wage if a household happens to have 
exactly two individuals with rural nonagr wage rate reported. */

bys hhid year: egen obs = total((dummy_3+dummy_5)*(logwage_rural~=.)*(logwage_rural~=0))
keep if obs == 2
keep if (dummy_3+dummy_5)*(logwage_rural~=.)*(logwage_rural~=0) == 1

drop obs

sort hhid year indid

bys hhid year: gen obs = _n
gen logwage_1 = logwage_rural if obs == 1
gen logwage_2 = logwage_rural if obs == 2

collapse(mean) logwage_1 logwage_2 disp1 disp1_se, by(hhid year)

gen corr_rural_hh_1 = .
gen corr_rural_hh_2 = .

gen corr_rural_hh_1_se = .
gen corr_rural_hh_2_se = .

label var corr_rural_hh_1 "Linear correlation, rural nonagr wage rate within household"
label var corr_rural_hh_2 "Spearman correlation, rural nonagr wage rate within household"

foreach x of numlist 2004/2018 {
	display(`x')
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		spearman logwage_1 logwage_2 if year == `x'
	qui replace corr_rural_hh_2    = _b[_bs_1]  if year == `x'
	qui replace corr_rural_hh_2_se = _se[_bs_1] if year == `x'
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		corr logwage_1 logwage_2 if year == `x'
	qui replace corr_rural_hh_1    = _b[_bs_1]  if year == `x'
	qui replace corr_rural_hh_1_se = _se[_bs_1] if year == `x'
}



collapse (mean) disp1 disp1_se corr_rural_hh_1 corr_rural_hh_1_se ///
	corr_rural_hh_2 corr_rural_hh_2_se, by(year)
export excel disp1 disp1_se corr_rural_hh_1 corr_rural_hh_1_se ///
	corr_rural_hh_2 corr_rural_hh_2_se using "$results/estimation-Calibration.xlsx", ///
	sheet("Income Moments",modify) cell(C3)
sleep 100

restore

* 6.2.2 Urban nonagr

preserve

qui gen disp1    = .
qui gen disp1_se = .
qui replace VOI = logwage_urban
foreach x of numlist 2004/2018 {
	qui sum VOI if year == `x', de
	qui gen temp1 = r(p1)
	qui gen temp2 = r(p99)
	bootstrap r(sd), rep(100) notable nolegend noheader nowarn nodots: ///
		sum VOI if VOI >= temp1 & VOI <= temp2 & year == `x'
	qui replace disp1    = _b[_bs_1]  if year == `x'
	qui replace disp1_se = _se[_bs_1] if year == `x'
	drop temp1 temp2
}

label var disp1 "Dispersion of urban nonagr wage rate"

/* Calculate the correlation of urban nonagr wage if a household happens to have 
exactly two individuals with urban nonagr wage rate reported. */

replace dummy_4 = 1 if dummy_7 == 1
replace dummy_6 = 1 if dummy_8 == 1

bys hhid year: egen obs = total((dummy_4+dummy_6)*(logwage_urban~=.)*(logwage_urban~=0))
keep if obs == 2
keep if (dummy_4+dummy_6)*(logwage_urban~=.)*(logwage_urban~=0) == 1

drop obs

sort hhid year indid

bys hhid year: gen obs = _n
gen logwage_1 = logwage_urban if obs == 1
gen logwage_2 = logwage_urban if obs == 2

collapse(mean) logwage_1 logwage_2 disp1 disp1_se, by(hhid year)

gen corr_urban_hh_1 = .
gen corr_urban_hh_2 = .

gen corr_urban_hh_1_se = .
gen corr_urban_hh_2_se = .

label var corr_urban_hh_1 "Linear correlation, urban nonagr wage rate within household"
label var corr_urban_hh_2 "Spearman correlation, urban nonagr wage rate within household"

foreach x of numlist 2004/2018 {
	display(`x')
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		spearman logwage_1 logwage_2 if year == `x'
	qui replace corr_urban_hh_2    = _b[_bs_1]  if year == `x'
	qui replace corr_urban_hh_2_se = _se[_bs_1] if year == `x'
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		corr logwage_1 logwage_2 if year == `x'
	qui replace corr_urban_hh_1    = _b[_bs_1]  if year == `x'
	qui replace corr_urban_hh_1_se = _se[_bs_1] if year == `x'
}


collapse (mean) disp1 disp1_se corr_urban_hh_1 corr_urban_hh_1_se ///
	corr_urban_hh_2 corr_urban_hh_2_se, by(year)
export excel disp1 disp1_se corr_urban_hh_1 corr_urban_hh_1_se ///
	corr_urban_hh_2 corr_urban_hh_2_se using "$results/estimation-Calibration.xlsx", ///
	sheet("Income Moments",modify) cell(J3)
sleep 100

restore

* 6.2.3 Nonagr, either or both



preserve


qui gen disp1 = .
qui gen disp1_se = .

count if logwage_rural ~= . & logwage_urban ~= . /* have to be zero */
egen logwage_nonagr = rowtotal(logwage_rural logwage_urban)

drop if logwage_rural == . & logwage_urban == .

qui replace VOI = logwage_nonagr
foreach x of numlist 2004/2018 {
	qui sum VOI if year == `x', de
	qui gen temp1 = r(p1)
	qui gen temp2 = r(p99)
	bootstrap r(sd), rep(100) notable nolegend noheader nowarn nodots: ///
		sum VOI if VOI >= temp1 & VOI <= temp2 & year == `x'
	qui replace disp1    = _b[_bs_1]  if year == `x'
	qui replace disp1_se = _se[_bs_1] if year == `x'
	drop temp1 temp2
}

label var disp1 "Dispersion of nonagr wage rate"

/* Calculate the correlation of urban nonagr wage if a household happens to have 
exactly two individuals with rural or urban nonagr wage rate reported. */

replace dummy_4 = 1 if dummy_7 == 1
replace dummy_6 = 1 if dummy_8 == 1

bys hhid year: egen obs = total((dummy_3+dummy_4+dummy_5+dummy_6)* ///
	(logwage_nonagr~=.)*(logwage_nonagr~=0))
keep if obs == 2
keep if (dummy_3+dummy_4+dummy_5+dummy_6)*(logwage_nonagr~=.)*(logwage_nonagr~=0) == 1

drop obs

sort hhid year indid

bys hhid year: gen obs = _n
gen logwage_1 = logwage_nonagr if obs == 1
gen logwage_2 = logwage_nonagr if obs == 2


collapse(mean) logwage_1 logwage_2 disp1 disp1_se, by(hhid year)

gen corr_nonagr_hh_1 = .
gen corr_nonagr_hh_2 = .

gen corr_nonagr_hh_1_se = .
gen corr_nonagr_hh_2_se = .

label var corr_nonagr_hh_1 "Linear correlation, nonagr wage rate within household"
label var corr_nonagr_hh_2 "Spearman correlation, nonagr wage rate within household"

foreach x of numlist 2004/2018 {
	display(`x')
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		spearman logwage_1 logwage_2 if year == `x'
	qui replace corr_nonagr_hh_2    = _b[_bs_1]  if year == `x'
	qui replace corr_nonagr_hh_2_se = _se[_bs_1] if year == `x'
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		corr logwage_1 logwage_2 if year == `x'
	qui replace corr_nonagr_hh_1    = _b[_bs_1]  if year == `x'
	qui replace corr_nonagr_hh_1_se = _se[_bs_1] if year == `x'
}



collapse (mean) disp1 disp1_se corr_nonagr_hh_1 corr_nonagr_hh_1_se ///
	corr_nonagr_hh_2 corr_nonagr_hh_2_se, by(year)
export excel disp1 disp1_se corr_nonagr_hh_1 corr_nonagr_hh_1_se ///
	corr_nonagr_hh_2 corr_nonagr_hh_2_se using "$results/estimation-Calibration.xlsx", ///
	sheet("Income Moments",modify) cell(Q3)
sleep 100

restore


/* 6.3 Within household correlation across occupations */


* 6.3.1 Rural nonagr versus urban nonagr

/* Calculate the correlation of these two if a household happens to have 
exactly one rural nonagr and one urban nonagr. */

preserve

bys hhid year: egen obs_r = total((dummy_3+dummy_5)*(logwage_rural~=.)*(logwage_rural~=0))
bys hhid year: egen obs_u = total((dummy_4+dummy_6)*(logwage_urban~=.)*(logwage_urban~=0))

keep if obs_r == 1 & obs_u == 1

replace dummy_4 = 1 if dummy_7 == 1
replace dummy_6 = 1 if dummy_8 == 1

keep if ((dummy_3+dummy_5)*(logwage_rural~=.)*(logwage_rural~=0) == 1) ///
	| ((dummy_4+dummy_6)*(logwage_urban~=.)*(logwage_urban~=0) == 1)

bys hhid year: egen logwage_rural_hh = mean(logwage_rural)
bys hhid year: egen logwage_urban_hh = mean(logwage_urban)

collapse(mean) logwage_rural_hh logwage_urban_hh, by(hhid year)

gen corr_rural_urban_hh_1 = .
gen corr_rural_urban_hh_2 = .

gen corr_rural_urban_hh_1_se = .
gen corr_rural_urban_hh_2_se = .

label var corr_rural_urban_hh_1 "Within household linear correlation, rural vs urban nonagr"
label var corr_rural_urban_hh_2 "Within household rank correlation, rural vs urban nonagr"

foreach x of numlist 2004/2018 {
	display(`x')
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		spearman logwage_rural_hh logwage_urban_hh if year == `x'
	qui replace corr_rural_urban_hh_2    = _b[_bs_1]  if year == `x'
	qui replace corr_rural_urban_hh_2_se = _se[_bs_1] if year == `x'
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		corr logwage_rural_hh logwage_urban_hh if year == `x'
	qui replace corr_rural_urban_hh_1    = _b[_bs_1]  if year == `x'
	qui replace corr_rural_urban_hh_1_se = _se[_bs_1] if year == `x'
}


collapse (mean) corr_rural_urban_hh_*, by(year)
export excel corr_rural_urban_hh_1 corr_rural_urban_hh_1_se ///
	corr_rural_urban_hh_2 corr_rural_urban_hh_2_se ///
	using "$results/estimation-Calibration.xlsx", sheet("Income Moments",modify) cell(AF3)
sleep 100
restore

* 6.3.2 Farming profit and rural nonagr

/* Calculate the correlation of these two if a household happens to have 
exactly one operator and one rural nonagr. */

preserve


bys hhid year: egen obs = total((dummy_3+dummy_5)*(logwage_rural~=.)*(logwage_rural~=0))
keep if obs == 1 
drop obs
bys hhid year: egen obs = total((dummy_operator)*(logwage_farming~=.)*(logwage_farming~=0))
keep if obs == 1
drop obs 

keep if (dummy_3+dummy_5)*(logwage_rural~=.)*(logwage_rural~=0) == 1 ///
	| (dummy_operator)*(logwage_farming~=.)*(logwage_farming~=0) == 1
sort hhid year indid

bys hhid year: gen obs = _n
gen logwage_1 = logwage_rural 
gen logwage_2 = logwage_farming 

collapse(mean) logwage_1 logwage_2, by(hhid year)

gen corr_farming_rural_1 = .
gen corr_farming_rural_2 = .

gen corr_farming_rural_1_se = .
gen corr_farming_rural_2_se = .

label var corr_farming_rural_1 "Linear correlation, rural nonagr versus farming, within hh"
label var corr_farming_rural_2 "Spearman correlation, rural nonagr versus farming, within hh"

foreach x of numlist 2004/2018 {
	display(`x')
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		spearman logwage_1 logwage_2 if year == `x'
	qui replace corr_farming_rural_2    = _b[_bs_1]  if year == `x'
	qui replace corr_farming_rural_2_se = _se[_bs_1] if year == `x'
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		corr logwage_1 logwage_2 if year == `x'
	qui replace corr_farming_rural_1    = _b[_bs_1]  if year == `x'
	qui replace corr_farming_rural_1_se = _se[_bs_1] if year == `x'
}


collapse (mean) corr_farming_rural_1 corr_farming_rural_1_se ///
	corr_farming_rural_2 corr_farming_rural_2_se, by(year)
export excel corr_farming_rural_1 corr_farming_rural_1_se ///
	corr_farming_rural_2 corr_farming_rural_2_se using "$results/estimation-Calibration.xlsx", ///
	sheet("Income Moments",modify) cell(AK3)
sleep 100

restore


* 6.3.3 Farming profit and rural/urban nonagr

/* Calculate the correlation of these two if a household happens to have 
exactly one operator and one rural/urban nonagr. */


preserve

count if logwage_rural ~= . & logwage_urban ~= . /* have to be zero */
egen logwage_nonagr = rowtotal(logwage_rural logwage_urban) ///
	if logwage_rural ~= . | logwage_urban ~= .

replace dummy_4 = 1 if dummy_7 == 1
replace dummy_6 = 1 if dummy_8 == 1

bys hhid year: egen obs = total((dummy_3+dummy_4+dummy_5+dummy_6)*(logwage_nonagr~=.)* ///
	(logwage_nonagr~=0))
keep if obs == 1 
drop obs
bys hhid year: egen obs = total((dummy_operator)*(logwage_farming~=.)*(logwage_farming~=0))
keep if obs == 1
drop obs

keep if (dummy_3+dummy_4+dummy_5+dummy_6)*(logwage_nonagr~=.)*(logwage_nonagr~=0) == 1 ///
	| (dummy_operator)*(logwage_farming~=.)*(logwage_farming~=0) == 1
sort hhid year indid

bys hhid year: gen obs = _n
gen logwage_1 = logwage_nonagr 
gen logwage_2 = logwage_farming 

collapse(mean) logwage_1 logwage_2, by(hhid year)

gen corr_farming_nonagr_1 = .
gen corr_farming_nonagr_2 = .

gen corr_farming_nonagr_1_se = .
gen corr_farming_nonagr_2_se = .

label var corr_farming_nonagr_1 "Linear correlation, nonagr versus farming, within hh"
label var corr_farming_nonagr_2 "Spearman correlation, nonagr versus farming, within hh"

foreach x of numlist 2004/2018 {
	display(`x')
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		spearman logwage_1 logwage_2 if year == `x'
	qui replace corr_farming_nonagr_2    = _b[_bs_1]  if year == `x'
	qui replace corr_farming_nonagr_2_se = _se[_bs_1] if year == `x'
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		corr logwage_1 logwage_2 if year == `x'
	qui replace corr_farming_nonagr_1    = _b[_bs_1]  if year == `x'
	qui replace corr_farming_nonagr_1_se = _se[_bs_1] if year == `x'
}


collapse (mean) corr_farming_nonagr_*, by(year)
export excel corr_farming_nonagr_1 corr_farming_nonagr_1_se ///
	corr_farming_nonagr_2 corr_farming_nonagr_2_se using "$results/estimation-Calibration.xlsx", ///
	sheet("Income Moments",modify) cell(AP3)
sleep 100

restore





/* 6.4 Compare the average nonagr wage rate between households who have operators 
versus those who do not have operators. */


preserve

count if logwage_rural ~= . & logwage_urban ~= . /* have to be zero */
egen logwage_nonagr = rowtotal(logwage_rural logwage_urban) ///
	if logwage_rural ~= . | logwage_urban ~= .
	
* Average nonagr wage rate within household
bys hhid year: egen logwage_nonagr_hh = mean(logwage_nonagr)


collapse(mean) logwage_nonagr_hh dummy_operator, by(hhid year)

* As long as dummy_operator > 0, someone works as an operator
replace dummy_operator = 1 if dummy_operator > 0 


gen wage_diff_migration_nonagr_1 = .
gen wage_diff_migration_nonagr_2 = .
gen wage_diff_migration_nonagr_1_se = .
gen wage_diff_migration_nonagr_2_se = .
label var wage_diff_migration_nonagr_1 ///
	"Nonagr wage difference (median), hh with or without operators"
label var wage_diff_migration_nonagr_2 ///
	"Nonagr wage difference (mean), hh with or without operators"
	
winsor2 logwage_nonagr_hh, cuts(1 99) trim by(dummy_operator year) replace

foreach x of numlist 2004/2018 {
	display(`x')
	
	bootstrap _b[dummy_operator], rep(100) notable nolegend noheader nowarn nodots: ///
		reg logwage_nonagr_hh dummy_operator if year == `x'
	qui replace wage_diff_migration_nonagr_2    = _b[_bs_1]  if year == `x'
	qui replace wage_diff_migration_nonagr_2_se = _se[_bs_1] if year == `x'
	
	bootstrap _b[dummy_operator], rep(100) notable nolegend noheader nowarn nodots: ///
		qreg logwage_nonagr_hh dummy_operator if year == `x'
	qui replace wage_diff_migration_nonagr_1    = _b[_bs_1]  if year == `x'
	qui replace wage_diff_migration_nonagr_1_se = _se[_bs_1] if year == `x'
}


collapse (mean) wage_diff_migration_nonagr*, by(year)
export excel wage_diff_migration_nonagr_1 wage_diff_migration_nonagr_1_se ///
	wage_diff_migration_nonagr_2 wage_diff_migration_nonagr_2_se ///
	using "$results/estimation-Calibration.xlsx", sheet("Income Moments",modify) cell(AU3)
sleep 100

restore




/* 6.6 Sectoral wage differentials */

* 6.6.1 Baseline wage differentials

preserve

gen mean_rural   = .
gen mean_urban   = .
bys year: gen mean_agr     = log(wage_rate_agr) 
gen mean_farming = .

keep if logwage_rural ~= . | logwage_urban ~= . | logwage_farming ~= .

/* should be zero: individuals with multiple wage rates */
count if logwage_rural ~= . & logwage_urban ~= . & logwage_farming ~= .
	
gen logwage        = .
gen dummy_category = .
gen dummy_rural    = 0
gen dummy_urban    = 0
gen dummy_farming  = 0

replace logwage = logwage_rural if logwage_rural ~= .
replace dummy_rural = 1         if logwage_rural ~= .
replace dummy_category = 1      if logwage_rural ~= .

replace logwage = logwage_urban if logwage_urban ~= .
replace dummy_urban = 1         if logwage_urban ~= .
replace dummy_category = 2      if logwage_urban ~= .

replace logwage = logwage_farming if logwage_farming ~= .
replace dummy_farming = 1         if logwage_farming ~= .
replace dummy_category = 3        if logwage_farming ~= .

winsor2 logwage, by(dummy_category year) trim cuts(1 99) replace

gen wage_diff_rural_urban   = .
gen wage_diff_rural_agr     = .
gen wage_diff_rural_farming = .

gen wage_diff_rural_urban_se   = .
gen wage_diff_rural_agr_se     = .
gen wage_diff_rural_farming_se = .

foreach x of numlist 2004/2018 {
display(`x')
	bootstrap _b[dummy_urban], rep(100) notable nolegend noheader nowarn nodots: ///
		reg logwage dummy_urban if year == `x' & dummy_farming ~= 1
	qui replace wage_diff_rural_urban    = _b[_bs_1]  if year == `x'
	qui replace wage_diff_rural_urban_se = _se[_bs_1] if year == `x'
	
	
	bootstrap _b[dummy_rural], rep(100) notable nolegend noheader nowarn nodots: ///
		reg logwage dummy_rural if year == `x' & dummy_urban ~= 1
	qui replace wage_diff_rural_farming    = _b[_bs_1]  if year == `x'
	qui replace wage_diff_rural_farming_se = _se[_bs_1] if year == `x'
	
	
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum logwage if year == `x' & dummy_rural == 1
	qui replace wage_diff_rural_agr    = _b[_bs_1]  - mean_agr  if year == `x'
	qui replace wage_diff_rural_agr_se = _se[_bs_1]             if year == `x'

}


collapse (mean) wage_diff_*, by(year)
export excel wage_diff_rural_urban wage_diff_rural_urban_se ///
	wage_diff_rural_agr wage_diff_rural_agr_se wage_diff_rural_farming wage_diff_rural_farming_se ///
	using "$results/estimation-Calibration.xlsx", sheet("Income Moments",modify) cell(Y3)
sleep 100

restore



preserve

gen mean_nonagr  = .
bys year: gen mean_agr     = log(wage_rate_agr) 
gen mean_farming = .

keep if logwage_rural ~= . | logwage_urban ~= . | logwage_farming ~= .

/* should be zero: individuals with multiple wage rates */
count if logwage_rural ~= . & logwage_urban ~= . & logwage_farming ~= .

count if logwage_rural ~= . & logwage_urban ~= . /* have to be zero */

egen logwage_nonagr = rowtotal(logwage_rural logwage_urban) ///
 if logwage_rural ~= . | logwage_urban ~= .
 
gen logwage        = .
gen dummy_category = .
gen dummy_nonagr   = 0
gen dummy_farming  = 0

replace logwage = logwage_nonagr if logwage_nonagr ~= .
replace dummy_nonagr = 1         if logwage_nonagr ~= .
replace dummy_category = 1       if logwage_nonagr ~= .


replace logwage = logwage_farming if logwage_farming ~= .
replace dummy_farming = 1         if logwage_farming ~= .
replace dummy_category = 2        if logwage_farming ~= .

winsor2 logwage, by(dummy_category year) trim cuts(1 99) replace

gen wage_diff_nonagr_agr     = .
gen wage_diff_nonagr_farming = .

gen wage_diff_nonagr_agr_se     = .
gen wage_diff_nonagr_farming_se = .

foreach x of numlist 2004/2018 {
display(`x')
 
 
 bootstrap _b[dummy_nonagr], rep(100) notable nolegend noheader nowarn nodots: ///
  reg logwage dummy_nonagr if year == `x'
 qui replace wage_diff_nonagr_farming    = _b[_bs_1]  if year == `x'
 qui replace wage_diff_nonagr_farming_se = _se[_bs_1] if year == `x'
 
 
 bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
  sum logwage if year == `x' & dummy_nonagr == 1
 qui replace wage_diff_nonagr_agr    = _b[_bs_1]  - mean_agr  if year == `x'
 qui replace wage_diff_nonagr_agr_se = _se[_bs_1]             if year == `x'

}


collapse (mean) wage_diff_*, by(year)
export excel wage_diff_nonagr_agr wage_diff_nonagr_agr_se ///
 wage_diff_nonagr_farming wage_diff_nonagr_farming_se ///
 using "$results/estimation-Calibration.xlsx", sheet("Income Moments",modify) cell(AZ3)
sleep 100

restore


* 6.6.2 Wage differential by age

preserve

bys year: gen mean_agr     = log(wage_rate_agr)
count if logwage_rural ~= . & logwage_urban ~= . /* have to be zero */
egen logwage_nonagr = rowtotal(logwage_rural logwage_urban) ///
	if logwage_rural ~= . | logwage_urban ~= .


winsor2 logwage_rural,   by(dummy_old year) trim cuts(1 99) replace
winsor2 logwage_urban,   by(dummy_old year) trim cuts(1 99) replace
winsor2 logwage_nonagr,  by(dummy_old year) trim cuts(1 99) replace
winsor2 logwage_farming, by(dummy_old year) trim cuts(1 99) replace


gen wage_diff_urban_yo   = .
gen wage_diff_rural_yo   = .
gen wage_diff_nonagr_yo  = .
gen wage_diff_farming_yo = .

gen wage_diff_urban_yo_se   = .
gen wage_diff_rural_yo_se   = .
gen wage_diff_nonagr_yo_se  = .
gen wage_diff_farming_yo_se = .

label var wage_diff_urban_yo   "Wage difference, young - old, among urban nonagr"
label var wage_diff_rural_yo   "Wage difference, young - old, among rural nonagr"
label var wage_diff_nonagr_yo  "Wage difference, young - old, among nonagr"
label var wage_diff_farming_yo "Wage difference, young - old, among farming"




foreach x of numlist 2004/2018 {
display(`x')

	bootstrap _b[dummy_old], rep(100) notable nolegend noheader nowarn nodots: ///
		reg logwage_rural dummy_old if year == `x'
	qui replace wage_diff_rural_yo    = -_b[_bs_1] if year == `x'
	qui replace wage_diff_rural_yo_se = _se[_bs_1] if year == `x'
	
	bootstrap _b[dummy_old], rep(100) notable nolegend noheader nowarn nodots: ///
		reg logwage_urban dummy_old if year == `x'
	qui replace wage_diff_urban_yo    = -_b[_bs_1] if year == `x'
	qui replace wage_diff_urban_yo_se = _se[_bs_1] if year == `x'
	
	bootstrap _b[dummy_old], rep(100) notable nolegend noheader nowarn nodots: ///
		reg logwage_nonagr dummy_old if year == `x'
	qui replace wage_diff_nonagr_yo    = -_b[_bs_1] if year == `x'
	qui replace wage_diff_nonagr_yo_se = _se[_bs_1] if year == `x'
	
	bootstrap _b[dummy_old], rep(100) notable nolegend noheader nowarn nodots: ///
		reg logwage_farming dummy_old if year == `x'
	qui replace wage_diff_farming_yo    = -_b[_bs_1] if year == `x'
	qui replace wage_diff_farming_yo_se = _se[_bs_1] if year == `x'

}


count if logwage_rural ~= . & logwage_urban ~= . & logwage_farming ~= . /* have to be zero */

gen logwage        = .
gen dummy_category = .
gen dummy_rural    = 0
gen dummy_urban    = 0
gen dummy_farming  = 0

replace logwage = logwage_rural if logwage_rural ~= 0 & logwage_rural ~= .
replace dummy_rural = 1         if logwage_rural ~= 0 & logwage_rural ~= .
replace dummy_category = 1      if logwage_rural ~= 0 & logwage_rural ~= .

replace logwage = logwage_urban if logwage_urban ~= 0 & logwage_urban ~= .
replace dummy_urban = 1         if logwage_urban ~= 0 & logwage_urban ~= .
replace dummy_category = 2      if logwage_urban ~= 0 & logwage_urban ~= .

replace logwage = logwage_farming if logwage_farming ~= 0 & logwage_farming ~= .
replace dummy_farming = 1         if logwage_farming ~= 0 & logwage_farming ~= .
replace dummy_category = 3        if logwage_farming ~= 0 & logwage_farming ~= .



gen wage_diff_rural_urban_y = .
gen wage_diff_rural_urban_o = .

gen wage_diff_rural_urban_y_se = .
gen wage_diff_rural_urban_o_se = .

label var wage_diff_rural_urban_y "Wage difference, urban - rural, among young"
label var wage_diff_rural_urban_o "Wage difference, urban - rural, among old"


gen wage_diff_rural_farming_y = .
gen wage_diff_rural_farming_o = .

gen wage_diff_rural_farming_y_se = .
gen wage_diff_rural_farming_o_se = .

label var wage_diff_rural_farming_y "Wage difference, rural - farming, among young"
label var wage_diff_rural_farming_o "Wage difference, rural - farming, among old"


gen wage_diff_rural_agr_y = .
gen wage_diff_rural_agr_o = .

gen wage_diff_rural_agr_y_se = .
gen wage_diff_rural_agr_o_se = .

label var wage_diff_rural_agr_y "Wage difference, rural young - agr"
label var wage_diff_rural_agr_o "Wage difference, rural old - agr"

foreach x of numlist 2004/2018 {
display(`x')

	bootstrap _b[dummy_urban], rep(100) notable nolegend noheader nowarn nodots: ///
		reg logwage dummy_urban if year == `x' & dummy_farming ~= 1 & dummy_old == 0
	qui replace wage_diff_rural_urban_y    = _b[_bs_1]  if year == `x'
	qui replace wage_diff_rural_urban_y_se = _se[_bs_1] if year == `x'
	
	bootstrap _b[dummy_urban], rep(100) notable nolegend noheader nowarn nodots: ///
		reg logwage dummy_urban if year == `x' & dummy_farming ~= 1 & dummy_old == 1
	qui replace wage_diff_rural_urban_o    = _b[_bs_1]  if year == `x'
	qui replace wage_diff_rural_urban_o_se = _se[_bs_1] if year == `x'
	
	bootstrap _b[dummy_rural], rep(100) notable nolegend noheader nowarn nodots: ///
		reg logwage dummy_rural if year == `x' & dummy_urban ~= 1 & dummy_old == 0
	qui replace wage_diff_rural_farming_y    = _b[_bs_1]  if year == `x'
	qui replace wage_diff_rural_farming_y_se = _se[_bs_1] if year == `x'
	
	bootstrap _b[dummy_rural], rep(100) notable nolegend noheader nowarn nodots: ///
		reg logwage dummy_rural if year == `x' & dummy_urban ~= 1 & dummy_old == 1
	qui replace wage_diff_rural_farming_o    = _b[_bs_1]  if year == `x'
	qui replace wage_diff_rural_farming_o_se = _se[_bs_1] if year == `x'
	
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum logwage if year == `x' & dummy_rural == 1 & dummy_old == 1
	qui replace wage_diff_rural_agr_o    = _b[_bs_1] - mean_agr if year == `x'
	qui replace wage_diff_rural_agr_o_se = _se[_bs_1]           if year == `x'
	
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum logwage if year == `x' & dummy_rural == 1 & dummy_old == 0
	qui replace wage_diff_rural_agr_y    = _b[_bs_1] - mean_agr  if year == `x'
	qui replace wage_diff_rural_agr_y_se = _se[_bs_1]            if year == `x'

}








collapse (mean) wage_diff_* dummy_old, by(year)
export excel wage_diff_urban_yo wage_diff_urban_yo_se wage_diff_rural_yo wage_diff_rural_yo_se ///
	wage_diff_nonagr_yo wage_diff_nonagr_yo_se wage_diff_farming_yo wage_diff_farming_yo_se ///
	wage_diff_rural_urban_y wage_diff_rural_urban_y_se ///
	wage_diff_rural_urban_o wage_diff_rural_urban_o_se ///
	wage_diff_rural_agr_y wage_diff_rural_agr_y_se ///
	wage_diff_rural_agr_o wage_diff_rural_agr_o_se ///
	wage_diff_rural_farming_y wage_diff_rural_farming_y_se ///
	wage_diff_rural_farming_o wage_diff_rural_farming_o_se ///
	using "$results/estimation-Calibration.xlsx", sheet("Income Moments YO",modify) cell(B3)
sleep 100
restore






/* Step 7: Calculate farm IO statistics */




/* 7.1 Raw statistics */


preserve

gen dummy_rentin  = (leasedin >0) & (leasedin ~=.)

collapse(mean) TFPR TFPQ land dummy_operator dummy_rentin, by(hhid year)

replace dummy_operator = 1 if dummy_operator > 0
keep if dummy_operator == 1

replace dummy_rentin   = 1 if dummy_rentin   > 0

gen logTFPR = log(TFPR)
gen logTFPQ = log(TFPQ)
gen logland = log(land)

gen disp_TFPR    = .
gen disp_TFPR_se = .
gen disp_TFPQ    = .
gen disp_TFPQ_se = .
gen disp_land    = .
gen disp_land_se = .

gen corr_TFPR_TFPQ_1    = .
gen corr_TFPR_TFPQ_2    = .
gen corr_TFPR_TFPQ_1_se = .
gen corr_TFPR_TFPQ_2_se = .

gen corr_TFPQ_land_1    = .
gen corr_TFPQ_land_2    = .
gen corr_TFPQ_land_1_se = .
gen corr_TFPQ_land_2_se = .

label var disp_TFPR "Dispersion of log TFPR after trimming 1% tails"
label var disp_TFPQ "Dispersion of log TFPQ after trimming 1% tails"
label var corr_TFPR_TFPQ_1 "Linear correlation between log TFPR and log TFPQ"
label var corr_TFPR_TFPQ_2 "Rank correlation between log TFPR and log TFPQ"
label var disp_land "Dispersion of farm size after trimming 1% tails"
label var corr_TFPQ_land_1 "Linear correlation between log TFPQ and log farm size"
label var corr_TFPQ_land_2 "Rank correlation between log TFPQ and log farm size"


gen disp_TFPR_top    = .
gen disp_TFPR_top_se = .
gen disp_TFPQ_top    = .
gen disp_TFPQ_top_se = .
gen disp_land_top    = .
gen disp_land_top_se = .

gen corr_TFPR_TFPQ_top_1    = .
gen corr_TFPR_TFPQ_top_2    = .
gen corr_TFPR_TFPQ_top_1_se = .
gen corr_TFPR_TFPQ_top_2_se = .

gen corr_TFPQ_land_top_1    = .
gen corr_TFPQ_land_top_2    = .
gen corr_TFPQ_land_top_1_se = .
gen corr_TFPQ_land_top_2_se = .

label var disp_TFPR_top "Dispersion of log TFPR among top"
label var disp_TFPQ_top "Dispersion of log TFPQ among top"
label var disp_land_top "Dispersion of log land among top"

label var corr_TFPR_TFPQ_top_1 "Linear correlation between log TFPR and log TFPQ among top"
label var corr_TFPR_TFPQ_top_2 "Rank correlation between log TFPR and log TFPQ among top"
label var corr_TFPQ_land_top_1 "Linear correlation between log TFPQ and log farm size among top"
label var corr_TFPQ_land_top_2 "Rank correlation between log TFPQ and log farm size among top"


gen disp_TFPR_rental    = .
gen disp_TFPR_rental_se = .
gen disp_TFPQ_rental    = .
gen disp_TFPQ_rental_se = .
gen disp_land_rental    = .
gen disp_land_rental_se = .

gen corr_TFPR_TFPQ_rental_1    = .
gen corr_TFPR_TFPQ_rental_2    = .
gen corr_TFPR_TFPQ_rental_1_se = .
gen corr_TFPR_TFPQ_rental_2_se = .

gen corr_TFPQ_land_rental_1    = .
gen corr_TFPQ_land_rental_2    = .
gen corr_TFPQ_land_rental_1_se = .
gen corr_TFPQ_land_rental_2_se = .

label var disp_TFPR_rental "Dispersion of log TFPR among rental"
label var disp_TFPQ_rental "Dispersion of log TFPQ among rental"
label var disp_land_rental "Dispersion of log land among rental"

label var corr_TFPR_TFPQ_rental_1 "Linear correlation between log TFPR and log TFPQ among rental"
label var corr_TFPR_TFPQ_rental_2 "Rank correlation between log TFPR and log TFPQ among rental"
label var corr_TFPQ_land_rental_1 "Linear correlation between log TFPQ and log farm size among rental"
label var corr_TFPQ_land_rental_2 "Rank correlation between log TFPQ and log farm size among rental"

gen VOI  = .
gen flag = .

foreach x of numlist 2004/2018 {
	display(`x')
	
	qui replace VOI = logTFPR
	
	qui sum VOI if year == `x', de
	qui gen temp1 = r(p1)
	qui gen temp2 = r(p99)
	bootstrap r(sd), rep(100) notable nolegend noheader nowarn nodots: ///
		sum VOI if year == `x' & VOI > temp1 & VOI < temp2, de
	qui replace disp_TFPR    = _b[_bs_1]  if year == `x'
	qui replace disp_TFPR_se = _se[_bs_1] if year == `x'
	drop temp1 temp2
	
	
	qui replace VOI = logTFPQ
	
	qui sum VOI if year == `x', de
	qui gen temp1 = r(p1)
	qui gen temp2 = r(p99)
	bootstrap r(sd), rep(100) notable nolegend noheader nowarn nodots: ///
		sum VOI if year == `x' & VOI > temp1 & VOI < temp2, de
	qui replace disp_TFPQ    = _b[_bs_1]  if year == `x'
	qui replace disp_TFPQ_se = _se[_bs_1] if year == `x'
	drop temp1 temp2
	
	
	qui replace VOI = logland
	
	qui sum VOI if year == `x', de
	qui gen temp1 = r(p1)
	qui gen temp2 = r(p99)
	bootstrap r(sd), rep(100) notable nolegend noheader nowarn nodots: ///
		sum VOI if year == `x' & VOI > temp1 & VOI < temp2, de
	qui replace disp_land    = _b[_bs_1]  if year == `x'
	qui replace disp_land_se = _se[_bs_1] if year == `x'
	drop temp1 temp2
	
	
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		spearman logTFPQ logTFPR if year == `x'
	qui replace corr_TFPR_TFPQ_2    = _b[_bs_1]  if year == `x'
	qui replace corr_TFPR_TFPQ_2_se = _se[_bs_1] if year == `x'
	
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		corr logTFPQ logTFPR if year == `x'
	qui replace corr_TFPR_TFPQ_1    = _b[_bs_1]  if year == `x'
	qui replace corr_TFPR_TFPQ_1_se = _se[_bs_1] if year == `x'
	
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		corr logTFPQ logland if year == `x'
	qui replace corr_TFPQ_land_1    = _b[_bs_1]  if year == `x'
	qui replace corr_TFPQ_land_1_se = _se[_bs_1] if year == `x'
	
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		spearman logTFPQ logland if year == `x'
	qui replace corr_TFPQ_land_2    = _b[_bs_1]  if year == `x'
	qui replace corr_TFPQ_land_2_se = _se[_bs_1] if year == `x'
	
	
	* Statistics among the top 
	
	qui sum logTFPQ if year == `x', de
	qui replace flag = 1 if year == `x' & logTFPQ > r(p75) & logTFPQ < r(p99)
	
	
	qui replace VOI = logTFPR
	qui sum VOI if year == `x', de
	qui gen temp1 = r(p1)
	qui gen temp2 = r(p99)
	bootstrap r(sd), rep(100) notable nolegend noheader nowarn nodots: ///
		sum VOI if year == `x' & VOI > temp1 & VOI < temp2 & flag == 1, de
	qui replace disp_TFPR_top    = _b[_bs_1]  if year == `x'
	qui replace disp_TFPR_top_se = _se[_bs_1] if year == `x'
	drop temp1 temp2
	
	qui replace VOI = logTFPQ
	qui sum VOI if year == `x', de
	qui gen temp1 = r(p1)
	qui gen temp2 = r(p99)
	bootstrap r(sd), rep(100) notable nolegend noheader nowarn nodots: ///
		sum VOI if year == `x' & VOI > temp1 & VOI < temp2 & flag == 1, de
	qui replace disp_TFPQ_top    = _b[_bs_1]  if year == `x'
	qui replace disp_TFPQ_top_se = _se[_bs_1] if year == `x'
	drop temp1 temp2
	
	qui replace VOI = logland
	qui sum VOI if year == `x', de
	qui gen temp1 = r(p1)
	qui gen temp2 = r(p99)
	bootstrap r(sd), rep(100) notable nolegend noheader nowarn nodots: ///
		sum VOI if year == `x' & VOI > temp1 & VOI < temp2 & flag == 1, de
	qui replace disp_land_top    = _b[_bs_1]  if year == `x'
	qui replace disp_land_top_se = _se[_bs_1] if year == `x'
	drop temp1 temp2
	
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		spearman logTFPQ logTFPR if year == `x' & flag == 1
	qui replace corr_TFPR_TFPQ_top_2    = _b[_bs_1]  if year == `x'
	qui replace corr_TFPR_TFPQ_top_2_se = _se[_bs_1] if year == `x'
	
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		corr logTFPQ logTFPR if year == `x' & flag == 1
	qui replace corr_TFPR_TFPQ_top_1    = _b[_bs_1]  if year == `x'
	qui replace corr_TFPR_TFPQ_top_1_se = _se[_bs_1] if year == `x'
	
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		corr logTFPQ logland if year == `x' & flag == 1
	qui replace corr_TFPQ_land_top_1    = _b[_bs_1]  if year == `x'
	qui replace corr_TFPQ_land_top_1_se = _se[_bs_1] if year == `x'
	
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		spearman logTFPQ logland if year == `x' & flag == 1
	qui replace corr_TFPQ_land_top_2    = _b[_bs_1]  if year == `x'
	qui replace corr_TFPQ_land_top_2_se = _se[_bs_1] if year == `x'
	
	* Statistics among those who rent in 
	
	qui replace VOI = logTFPR
	qui sum VOI if year == `x', de
	qui gen temp1 = r(p1)
	qui gen temp2 = r(p99)
	bootstrap r(sd), rep(100) notable nolegend noheader nowarn nodots: ///
		sum VOI if year == `x' & VOI > temp1 & VOI < temp2 & dummy_rentin == 1, de
	qui replace disp_TFPR_rental    = _b[_bs_1]  if year == `x'
	qui replace disp_TFPR_rental_se = _se[_bs_1] if year == `x'
	drop temp1 temp2
	
	qui replace VOI = logTFPQ
	qui sum VOI if year == `x', de
	qui gen temp1 = r(p1)
	qui gen temp2 = r(p99)
	bootstrap r(sd), rep(100) notable nolegend noheader nowarn nodots: ///
		sum VOI if year == `x' & VOI > temp1 & VOI < temp2 & dummy_rentin == 1, de
	qui replace disp_TFPQ_rental    = _b[_bs_1]  if year == `x'
	qui replace disp_TFPQ_rental_se = _se[_bs_1] if year == `x'
	drop temp1 temp2
	
	qui replace VOI = logland
	qui sum VOI if year == `x', de
	qui gen temp1 = r(p1)
	qui gen temp2 = r(p99)
	bootstrap r(sd), rep(100) notable nolegend noheader nowarn nodots: ///
		sum VOI if year == `x' & VOI > temp1 & VOI < temp2 & dummy_rentin == 1, de
	qui replace disp_land_rental    = _b[_bs_1]  if year == `x'
	qui replace disp_land_rental_se = _se[_bs_1] if year == `x'
	drop temp1 temp2
	
	
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		spearman logTFPQ logTFPR if year == `x' & dummy_rentin == 1
	qui replace corr_TFPR_TFPQ_rental_2    = _b[_bs_1]  if year == `x'
	qui replace corr_TFPR_TFPQ_rental_2_se = _se[_bs_1] if year == `x'
	
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		corr logTFPQ logTFPR if year == `x' & dummy_rentin == 1
	qui replace corr_TFPR_TFPQ_rental_1    = _b[_bs_1]  if year == `x'
	qui replace corr_TFPR_TFPQ_rental_1_se = _se[_bs_1] if year == `x'
	
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		corr logTFPQ logland if year == `x' & dummy_rentin == 1
	qui replace corr_TFPQ_land_rental_1    = _b[_bs_1]  if year == `x'
	qui replace corr_TFPQ_land_rental_1_se = _se[_bs_1] if year == `x'
	
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		spearman logTFPQ logland if year == `x' & dummy_rentin == 1
	qui replace corr_TFPQ_land_rental_2    = _b[_bs_1]  if year == `x'
	qui replace corr_TFPQ_land_rental_2_se = _se[_bs_1] if year == `x'
}

collapse (mean) disp_TFPR* disp_TFPQ* disp_land* corr_TFPR_TFPQ_* corr_TFPQ_land_*, by(year)

export excel disp_TFPR disp_TFPR_se disp_TFPQ disp_TFPQ_se disp_land disp_land_se ///
	using "$results/estimation-Calibration.xlsx", sheet("Agr Moments Raw",modify) cell(C4)
sleep 100
export excel corr_TFPR_TFPQ_1 corr_TFPR_TFPQ_1_se corr_TFPR_TFPQ_2 corr_TFPR_TFPQ_2_se ///
	corr_TFPQ_land_1 corr_TFPQ_land_1_se corr_TFPQ_land_2 corr_TFPQ_land_2_se ///
	using "$results/estimation-Calibration.xlsx", sheet("Agr Moments Raw",modify) cell(I4)
sleep 100

export excel disp_TFPR_top disp_TFPR_top_se disp_TFPQ_top disp_TFPQ_top_se disp_land_top  ///
	disp_land_top_se using "$results/estimation-Calibration.xlsx", sheet("Agr Moments Raw",modify) cell(R4)
sleep 100
export excel corr_TFPR_TFPQ_top_1 corr_TFPR_TFPQ_top_1_se corr_TFPR_TFPQ_top_2 ///
	corr_TFPR_TFPQ_top_2_se corr_TFPQ_land_top_1 corr_TFPQ_land_top_1_se ///
	corr_TFPQ_land_top_2 corr_TFPQ_land_top_2_se ///
	using "$results/estimation-Calibration.xlsx", sheet("Agr Moments Raw",modify) cell(X4)
sleep 100


export excel disp_TFPR_rental disp_TFPR_rental_se disp_TFPQ_rental disp_TFPQ_rental_se ///
	disp_land_rental disp_land_rental_se ///
	using "$results/estimation-Calibration.xlsx", sheet("Agr Moments Raw",modify) cell(AG4)
sleep 100
export excel corr_TFPR_TFPQ_rental_1 corr_TFPR_TFPQ_rental_1_se corr_TFPR_TFPQ_rental_2 ///
	corr_TFPR_TFPQ_rental_2_se corr_TFPQ_land_rental_1 corr_TFPQ_land_rental_1_se ///
	corr_TFPQ_land_rental_2 corr_TFPQ_land_rental_2_se ///
	using "$results/estimation-Calibration.xlsx", sheet("Agr Moments Raw",modify) cell(AM4)
sleep 100

 
restore
 



/* 7.2 Statistics using the permanent component */




preserve


replace TFPR = TFPR_hat
replace TFPQ = TFPQ_hat


gen dummy_rentin  = (leasedin >0) & (leasedin ~=.)

collapse(mean) TFPR TFPQ land dummy_operator dummy_rentin, by(hhid year)

replace dummy_operator = 1 if dummy_operator > 0
keep if dummy_operator == 1

replace dummy_rentin   = 1 if dummy_rentin   > 0

gen logTFPR = log(TFPR)
gen logTFPQ = log(TFPQ)
gen logland = log(land)

gen disp_TFPR    = .
gen disp_TFPR_se = .
gen disp_TFPQ    = .
gen disp_TFPQ_se = .
gen disp_land    = .
gen disp_land_se = .

gen corr_TFPR_TFPQ_1    = .
gen corr_TFPR_TFPQ_2    = .
gen corr_TFPR_TFPQ_1_se = .
gen corr_TFPR_TFPQ_2_se = .

gen corr_TFPQ_land_1    = .
gen corr_TFPQ_land_2    = .
gen corr_TFPQ_land_1_se = .
gen corr_TFPQ_land_2_se = .

label var disp_TFPR "Dispersion of log TFPR after trimming 1% tails"
label var disp_TFPQ "Dispersion of log TFPQ after trimming 1% tails"
label var corr_TFPR_TFPQ_1 "Linear correlation between log TFPR and log TFPQ"
label var corr_TFPR_TFPQ_2 "Rank correlation between log TFPR and log TFPQ"
label var disp_land "Dispersion of farm size after trimming 1% tails"
label var corr_TFPQ_land_1 "Linear correlation between log TFPQ and log farm size"
label var corr_TFPQ_land_2 "Rank correlation between log TFPQ and log farm size"


gen disp_TFPR_top    = .
gen disp_TFPR_top_se = .
gen disp_TFPQ_top    = .
gen disp_TFPQ_top_se = .
gen disp_land_top    = .
gen disp_land_top_se = .

gen corr_TFPR_TFPQ_top_1    = .
gen corr_TFPR_TFPQ_top_2    = .
gen corr_TFPR_TFPQ_top_1_se = .
gen corr_TFPR_TFPQ_top_2_se = .

gen corr_TFPQ_land_top_1    = .
gen corr_TFPQ_land_top_2    = .
gen corr_TFPQ_land_top_1_se = .
gen corr_TFPQ_land_top_2_se = .

label var disp_TFPR_top "Dispersion of log TFPR among top"
label var disp_TFPQ_top "Dispersion of log TFPQ among top"
label var disp_land_top "Dispersion of log land among top"

label var corr_TFPR_TFPQ_top_1 "Linear correlation between log TFPR and log TFPQ among top"
label var corr_TFPR_TFPQ_top_2 "Rank correlation between log TFPR and log TFPQ among top"
label var corr_TFPQ_land_top_1 "Linear correlation between log TFPQ and log farm size among top"
label var corr_TFPQ_land_top_2 "Rank correlation between log TFPQ and log farm size among top"


gen disp_TFPR_rental    = .
gen disp_TFPR_rental_se = .
gen disp_TFPQ_rental    = .
gen disp_TFPQ_rental_se = .
gen disp_land_rental    = .
gen disp_land_rental_se = .

gen corr_TFPR_TFPQ_rental_1    = .
gen corr_TFPR_TFPQ_rental_2    = .
gen corr_TFPR_TFPQ_rental_1_se = .
gen corr_TFPR_TFPQ_rental_2_se = .

gen corr_TFPQ_land_rental_1    = .
gen corr_TFPQ_land_rental_2    = .
gen corr_TFPQ_land_rental_1_se = .
gen corr_TFPQ_land_rental_2_se = .

label var disp_TFPR_rental "Dispersion of log TFPR among rental"
label var disp_TFPQ_rental "Dispersion of log TFPQ among rental"
label var disp_land_rental "Dispersion of log land among rental"

label var corr_TFPR_TFPQ_rental_1 "Linear correlation between log TFPR and log TFPQ among rental"
label var corr_TFPR_TFPQ_rental_2 "Rank correlation between log TFPR and log TFPQ among rental"
label var corr_TFPQ_land_rental_1 "Linear correlation between log TFPQ and log farm size among rental"
label var corr_TFPQ_land_rental_2 "Rank correlation between log TFPQ and log farm size among rental"

gen VOI  = .
gen flag = .

foreach x of numlist 2004/2018 {
	display(`x')
	
	qui replace VOI = logTFPR
	
	qui sum VOI if year == `x', de
	qui gen temp1 = r(p1)
	qui gen temp2 = r(p99)
	bootstrap r(sd), rep(100) notable nolegend noheader nowarn nodots: ///
		sum VOI if year == `x' & VOI > temp1 & VOI < temp2, de
	qui replace disp_TFPR    = _b[_bs_1]  if year == `x'
	qui replace disp_TFPR_se = _se[_bs_1] if year == `x'
	drop temp1 temp2
	
	
	qui replace VOI = logTFPQ
	
	qui sum VOI if year == `x', de
	qui gen temp1 = r(p1)
	qui gen temp2 = r(p99)
	bootstrap r(sd), rep(100) notable nolegend noheader nowarn nodots: ///
		sum VOI if year == `x' & VOI > temp1 & VOI < temp2, de
	qui replace disp_TFPQ    = _b[_bs_1]  if year == `x'
	qui replace disp_TFPQ_se = _se[_bs_1] if year == `x'
	drop temp1 temp2
	
	
	qui replace VOI = logland
	
	qui sum VOI if year == `x', de
	qui gen temp1 = r(p1)
	qui gen temp2 = r(p99)
	bootstrap r(sd), rep(100) notable nolegend noheader nowarn nodots: ///
		sum VOI if year == `x' & VOI > temp1 & VOI < temp2, de
	qui replace disp_land    = _b[_bs_1]  if year == `x'
	qui replace disp_land_se = _se[_bs_1] if year == `x'
	drop temp1 temp2
	
	
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		spearman logTFPQ logTFPR if year == `x'
	qui replace corr_TFPR_TFPQ_2    = _b[_bs_1]  if year == `x'
	qui replace corr_TFPR_TFPQ_2_se = _se[_bs_1] if year == `x'
	
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		corr logTFPQ logTFPR if year == `x'
	qui replace corr_TFPR_TFPQ_1    = _b[_bs_1]  if year == `x'
	qui replace corr_TFPR_TFPQ_1_se = _se[_bs_1] if year == `x'
	
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		corr logTFPQ logland if year == `x'
	qui replace corr_TFPQ_land_1    = _b[_bs_1]  if year == `x'
	qui replace corr_TFPQ_land_1_se = _se[_bs_1] if year == `x'
	
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		spearman logTFPQ logland if year == `x'
	qui replace corr_TFPQ_land_2    = _b[_bs_1]  if year == `x'
	qui replace corr_TFPQ_land_2_se = _se[_bs_1] if year == `x'
	
	
	* Statistics among the top 
	
	qui sum logTFPQ if year == `x', de
	qui replace flag = 1 if year == `x' & logTFPQ > r(p75) & logTFPQ < r(p99)
	
	
	qui replace VOI = logTFPR
	qui sum VOI if year == `x', de
	qui gen temp1 = r(p1)
	qui gen temp2 = r(p99)
	bootstrap r(sd), rep(100) notable nolegend noheader nowarn nodots: ///
		sum VOI if year == `x' & VOI > temp1 & VOI < temp2 & flag == 1, de
	qui replace disp_TFPR_top    = _b[_bs_1]  if year == `x'
	qui replace disp_TFPR_top_se = _se[_bs_1] if year == `x'
	drop temp1 temp2
	
	qui replace VOI = logTFPQ
	qui sum VOI if year == `x', de
	qui gen temp1 = r(p1)
	qui gen temp2 = r(p99)
	bootstrap r(sd), rep(100) notable nolegend noheader nowarn nodots: ///
		sum VOI if year == `x' & VOI > temp1 & VOI < temp2 & flag == 1, de
	qui replace disp_TFPQ_top    = _b[_bs_1]  if year == `x'
	qui replace disp_TFPQ_top_se = _se[_bs_1] if year == `x'
	drop temp1 temp2
	
	qui replace VOI = logland
	qui sum VOI if year == `x', de
	qui gen temp1 = r(p1)
	qui gen temp2 = r(p99)
	bootstrap r(sd), rep(100) notable nolegend noheader nowarn nodots: ///
		sum VOI if year == `x' & VOI > temp1 & VOI < temp2 & flag == 1, de
	qui replace disp_land_top    = _b[_bs_1]  if year == `x'
	qui replace disp_land_top_se = _se[_bs_1] if year == `x'
	drop temp1 temp2
	
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		spearman logTFPQ logTFPR if year == `x' & flag == 1
	qui replace corr_TFPR_TFPQ_top_2    = _b[_bs_1]  if year == `x'
	qui replace corr_TFPR_TFPQ_top_2_se = _se[_bs_1] if year == `x'
	
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		corr logTFPQ logTFPR if year == `x' & flag == 1
	qui replace corr_TFPR_TFPQ_top_1    = _b[_bs_1]  if year == `x'
	qui replace corr_TFPR_TFPQ_top_1_se = _se[_bs_1] if year == `x'
	
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		corr logTFPQ logland if year == `x' & flag == 1
	qui replace corr_TFPQ_land_top_1    = _b[_bs_1]  if year == `x'
	qui replace corr_TFPQ_land_top_1_se = _se[_bs_1] if year == `x'
	
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		spearman logTFPQ logland if year == `x' & flag == 1
	qui replace corr_TFPQ_land_top_2    = _b[_bs_1]  if year == `x'
	qui replace corr_TFPQ_land_top_2_se = _se[_bs_1] if year == `x'
	
	* Statistics among those who rent in 
	
	qui replace VOI = logTFPR
	qui sum VOI if year == `x', de
	qui gen temp1 = r(p1)
	qui gen temp2 = r(p99)
	bootstrap r(sd), rep(100) notable nolegend noheader nowarn nodots: ///
		sum VOI if year == `x' & VOI > temp1 & VOI < temp2 & dummy_rentin == 1, de
	qui replace disp_TFPR_rental    = _b[_bs_1]  if year == `x'
	qui replace disp_TFPR_rental_se = _se[_bs_1] if year == `x'
	drop temp1 temp2
	
	qui replace VOI = logTFPQ
	qui sum VOI if year == `x', de
	qui gen temp1 = r(p1)
	qui gen temp2 = r(p99)
	bootstrap r(sd), rep(100) notable nolegend noheader nowarn nodots: ///
		sum VOI if year == `x' & VOI > temp1 & VOI < temp2 & dummy_rentin == 1, de
	qui replace disp_TFPQ_rental    = _b[_bs_1]  if year == `x'
	qui replace disp_TFPQ_rental_se = _se[_bs_1] if year == `x'
	drop temp1 temp2
	
	qui replace VOI = logland
	qui sum VOI if year == `x', de
	qui gen temp1 = r(p1)
	qui gen temp2 = r(p99)
	bootstrap r(sd), rep(100) notable nolegend noheader nowarn nodots: ///
		sum VOI if year == `x' & VOI > temp1 & VOI < temp2 & dummy_rentin == 1, de
	qui replace disp_land_rental    = _b[_bs_1]  if year == `x'
	qui replace disp_land_rental_se = _se[_bs_1] if year == `x'
	drop temp1 temp2
	
	
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		spearman logTFPQ logTFPR if year == `x' & dummy_rentin == 1
	qui replace corr_TFPR_TFPQ_rental_2    = _b[_bs_1]  if year == `x'
	qui replace corr_TFPR_TFPQ_rental_2_se = _se[_bs_1] if year == `x'
	
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		corr logTFPQ logTFPR if year == `x' & dummy_rentin == 1
	qui replace corr_TFPR_TFPQ_rental_1    = _b[_bs_1]  if year == `x'
	qui replace corr_TFPR_TFPQ_rental_1_se = _se[_bs_1] if year == `x'
	
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		corr logTFPQ logland if year == `x' & dummy_rentin == 1
	qui replace corr_TFPQ_land_rental_1    = _b[_bs_1]  if year == `x'
	qui replace corr_TFPQ_land_rental_1_se = _se[_bs_1] if year == `x'
	
	bootstrap r(rho), rep(100) notable nolegend noheader nowarn nodots: ///
		spearman logTFPQ logland if year == `x' & dummy_rentin == 1
	qui replace corr_TFPQ_land_rental_2    = _b[_bs_1]  if year == `x'
	qui replace corr_TFPQ_land_rental_2_se = _se[_bs_1] if year == `x'
}

collapse (mean) disp_TFPR* disp_TFPQ* disp_land* corr_TFPR_TFPQ_* corr_TFPQ_land_*, by(year)

export excel disp_TFPR disp_TFPR_se disp_TFPQ disp_TFPQ_se disp_land disp_land_se ///
	using "$results/estimation-Calibration.xlsx", sheet("Agr Moments Permanent",modify) cell(C4)
sleep 100
export excel corr_TFPR_TFPQ_1 corr_TFPR_TFPQ_1_se corr_TFPR_TFPQ_2 corr_TFPR_TFPQ_2_se ///
	corr_TFPQ_land_1 corr_TFPQ_land_1_se corr_TFPQ_land_2 corr_TFPQ_land_2_se ///
	using "$results/estimation-Calibration.xlsx", sheet("Agr Moments Permanent",modify) cell(I4)
sleep 100

export excel disp_TFPR_top disp_TFPR_top_se disp_TFPQ_top disp_TFPQ_top_se disp_land_top  ///
	disp_land_top_se using "$results/estimation-Calibration.xlsx", sheet("Agr Moments Permanent",modify) cell(R4)
sleep 100
export excel corr_TFPR_TFPQ_top_1 corr_TFPR_TFPQ_top_1_se corr_TFPR_TFPQ_top_2 ///
	corr_TFPR_TFPQ_top_2_se corr_TFPQ_land_top_1 corr_TFPQ_land_top_1_se ///
	corr_TFPQ_land_top_2 corr_TFPQ_land_top_2_se ///
	using "$results/estimation-Calibration.xlsx", sheet("Agr Moments Permanent",modify) cell(X4)
sleep 100


export excel disp_TFPR_rental disp_TFPR_rental_se disp_TFPQ_rental disp_TFPQ_rental_se ///
	disp_land_rental disp_land_rental_se ///
	using "$results/estimation-Calibration.xlsx", sheet("Agr Moments Permanent",modify) cell(AG4)
sleep 100
export excel corr_TFPR_TFPQ_rental_1 corr_TFPR_TFPQ_rental_1_se corr_TFPR_TFPQ_rental_2 ///
	corr_TFPR_TFPQ_rental_2_se corr_TFPQ_land_rental_1 corr_TFPQ_land_rental_1_se ///
	corr_TFPQ_land_rental_2 corr_TFPQ_land_rental_2_se ///
	using "$results/estimation-Calibration.xlsx", sheet("Agr Moments Permanent",modify) cell(AM4)
sleep 100
 

restore



/* 7.3 Percentage of families with operators */

preserve

drop if dummy_operator == . /* zero dropped */

collapse (mean) dummy_*, by(hhid year)

replace dummy_operator = 1 if dummy_operator > 0

gen share_operator    = .
gen share_operator_se = .
label var share_operator    "Fraction of families with operators"

foreach x of numlist 2004/2018 {
	display(`x')
	
	bootstrap r(mean), rep(100) notable nolegend noheader nowarn nodots: ///
		sum dummy_operator if year == `x'
	qui replace share_operator    = _b[_bs_1]  if year == `x'
	qui replace share_operator_se = _se[_bs_1] if year == `x'
}
	
collapse (mean) share_operator share_operator_se, by(year)
export excel share_operator share_operator_se using "$results/estimation-Calibration.xlsx", ///
	sheet("Agr Moments Other",modify) cell(C4)
sleep 100

restore	
	
	
/* 7.4 Average farm size */

preserve

collapse(mean) land dummy_operator, by(hhid year)

replace dummy_operator = 1 if dummy_operator > 0
keep if dummy_operator == 1

gen AFS    = .
gen AFS_75 = .
gen AFS_50 = .
gen AFS_25 = .

gen AFS_se    = .
gen AFS_75_se = .
gen AFS_50_se = .
gen AFS_25_se = .

gen AFS_sd = .
gen AFS_sd_se = .

winsor2 land, cuts(1 99) replace trim by(year)

foreach x of numlist 2004/2018 {

	bootstrap r(mean) r(p75) r(p50) r(p25), rep(100) notable nolegend noheader nowarn nodots: ///
		sum land if year == `x', de
		

		
	qui replace AFS       = _b[_bs_1]  if year == `x'
	qui replace AFS_se    = _se[_bs_1] if year == `x'
	
	qui replace AFS_75    = _b[_bs_2]  if year == `x'
	qui replace AFS_75_se = _se[_bs_2] if year == `x'
	
	qui replace AFS_50    = _b[_bs_3]  if year == `x'
	qui replace AFS_50_se = _se[_bs_3] if year == `x'
	
	qui replace AFS_25    = _b[_bs_4]  if year == `x'
	qui replace AFS_25_se = _se[_bs_4] if year == `x'

	
}

gen logland = log(land)
foreach x of numlist 2004/2018 {

	bootstrap r(sd), rep(100) notable nolegend noheader nowarn nodots: ///
		sum logland if year == `x', de
		
	
	qui replace AFS_sd    = _b[_bs_1]  if year == `x'
	qui replace AFS_sd_se = _se[_bs_1] if year == `x'
	
}
collapse (mean) AFS*, by(year)
export excel AFS AFS_se AFS_25 AFS_25_se AFS_50 AFS_50_se AFS_75 AFS_75_se ///
	AFS_sd AFS_sd_se using "$results/estimation-Calibration.xlsx", sheet("Agr Moments Other",modify) cell(F4)
sleep 100

restore
	
	
	
	
/* 7.5 Sideline Agriculture */

preserve



gen frac_sideline = .
label var frac_sideline "Employment of sideline agr labor as % of total agr labor"

gen labor_side_hh = labor_side_total - labor_side_hired
gen labor_agr_hh  = labor_agr_total  - labor_agr_hired

collapse (mean) frac_sideline labor_side_hh labor_side_total labor_side_hired ///
	labor_agr_hh labor_agr_total labor_agr_hired, by(hhid year)
foreach x of numlist 2004/2018 {
	qui sum labor_side_total if year == `x', de
	qui sum labor_side_total if year == `x' & labor_side_total < r(p99), de
	qui gen temp1 = r(mean) if year == `x'
	qui sum labor_agr_total if year == `x', de
	qui sum labor_agr_total if year == `x' & labor_agr_total < r(p99), de
	qui gen temp2 = r(mean) if year == `x'
	qui replace frac_sideline = temp1 / (temp1+temp2) if year == `x'
	drop temp1 temp2
}
collapse (mean) frac_sideline, by(year)
export excel frac_sideline using "$results/estimation-Calibration.xlsx", ///
	sheet("Agr Moments Other",modify) cell(Q4)
sleep 100

restore

/* 7.6 Agricultural labor */

preserve


collapse (mean) labor_agr_total labor_agr_hired, by(hhid year)

gen frac_hh_labor = .
label var frac_hh_labor "hh labor as % of total labor, aggregate per year"


foreach x of numlist 2004/2018 {
	qui sum labor_agr_total if year == `x', de
	qui sum labor_agr_total if year == `x' & labor_agr_total < r(p99), de
	qui gen temp1 = r(mean) if year == `x'
	qui sum labor_agr_hired if year == `x', de
	qui sum labor_agr_hired if year == `x' & labor_agr_hired < r(p99), de
	qui gen temp2 = r(mean) if year == `x'
	qui replace frac_hh_labor = temp1 / (temp1+temp2) if year == `x'
	drop temp1 temp2
}
collapse (mean) frac_hh_labor, by(year)
export excel frac_hh_labor using "$results/estimation-Calibration.xlsx", ///
	sheet("Agr Moments Other",modify) cell(S4)
sleep 100

restore

/* 7.7 Non-agr days */

preserve

drop if dummy_1 + dummy_9 == 1

gen dummy_nonagr = 0
replace dummy_nonagr = 1 if dummy_3 + dummy_4 + dummy_5 + dummy_6 + dummy_7 + dummy_8 > 0
keep if dummy_nonagr == 1

egen LS = rowtotal(LS_agr LS_nonagr)

replace LS = . if LS == 0

collapse (mean) LS, by(year)

export excel LS using "$results/estimation-Calibration.xlsx", sheet("Agr Moments Other",modify) cell(U4)
sleep 100

restore

/* 7.8 Rentals */


preserve

replace TFPQ = TFPQ_hat


gen dummy_rentin  = (leasedin >0) & (leasedin ~=.)
gen dummy_rentout = (leasedout>0) & (leasedout~=.)

gen dummy_fallow  = ((output==0) | (labor==0)) & (land>leasedout)

collapse(mean) leasedin leasedout land dummy_rentin dummy_rentout dummy_operator ///
	dummy_fallow TFPQ, by(hhid year)

replace dummy_operator = 1 if dummy_operator > 0 & dummy_operator ~= .
replace dummy_fallow   = 1 if dummy_fallow   > 0 & dummy_fallow   ~= .


bys year: egen rentin_hh_frac     = mean(dummy_rentin) if dummy_operator == 1
bys year: egen inactive_hh_frac   = mean((1-dummy_rentin)*(1-dummy_rentout)) if dummy_operator == 1
bys year: egen rentout_hh_frac    = mean(dummy_rentout) if dummy_operator == 1

label var rentin_hh_frac   "Among farms with operators: pct of rent in households"
label var rentout_hh_frac  "Among farms with operators: pct of rent out households"
label var inactive_hh_frac "Among farms with operators: pct of households not rent in/out"


bys year: egen land_size_total    = total(land)        if dummy_operator == 1
bys year: egen rentin_size_total  = total(leasedin)    if dummy_operator == 1
bys year: egen rentout_size_total = total(leasedout)   if dummy_operator == 1

foreach x of numlist 2004/2018 {
	qui sum land_size_total if year == `x'
	replace land_size_total = r(mean) if year == `x'
}


gen rentin_size_mean_perHH    = .
label var rentin_size_mean_perHH   "Average amount of rent in land per household"
gen rentin_size_median_perHH  = .
label var rentin_size_median_perHH "Median amount of rent in land per household"

foreach x of numlist 2004/2018{
	qui sum leasedin if leasedin > 0 & leasedin ~= . & dummy_operator == 1 & year == `x', de
	qui replace rentin_size_mean_perHH   = r(mean) if year == `x'
	qui replace rentin_size_median_perHH = r(p50)  if year == `x'
}

gen rentin_size_frac   = rentin_size_total /land_size_total
gen rentout_size_frac  = rentout_size_total/land_size_total

label var rentin_size_frac  "Among farms with operators: pct of land rent in"
label var rentout_size_frac "Among farms with operators: pct of land rent out"


bys year: egen rentout_hh_frac_2   = mean(dummy_rentout)
label var rentout_hh_frac_2  "Among all households: pct of rent out households"

bys year: egen rentout_size_total_2 = total(leasedout)

bys year: egen fallow_size_total   = total(land-leasedout) if dummy_fallow == 1 
bys year: egen fallow_hh_frac      = mean(dummy_fallow)    
label var fallow_hh_frac  "Among all households: pct of fallowed households"

gen rentout_size_frac_2 = rentout_size_total_2/land_size_total
label var rentout_size_frac_2 "Total land rent out as pct of land used by operators"

gen fallow_size_frac    = fallow_size_total /land_size_total
label var fallow_size_frac "Total fallow land as pct of land used by operators"

bys year: egen land_noope_frac     = total(land) if dummy_operator == 0
replace  land_noope_frac = land_noope_frac/land_size_total
label var land_noope_frac "Total land by farms without operators as pct of land used by operators"

gen corr_rental_TFP_1 = . /* linear corr intensive margin */
gen corr_rental_TFP_2 = . /* rank corr intensive margin */
gen corr_rental_TFP_3 = . /* linear corr extensive margin */
gen corr_rental_TFP_4 = . /* rank corr extensive margin */
gen corr_rental_TFP_5 = . /* rank corr both margins */

gen logTFPQ = log(TFPQ)
gen logleasedin = log(leasedin)

foreach x of numlist 2004/2018 {
	
	qui corr logleasedin logTFPQ if year == `x' & dummy_operator == 1 & dummy_rentin == 1
	qui replace corr_rental_TFP_1 = r(rho)      if year == `x'
	
	qui spearman leasedin TFPQ   if year == `x' & dummy_operator == 1 & dummy_rentin == 1
	qui replace corr_rental_TFP_2 = r(rho)      if year == `x'
	
	qui corr dummy_rentin logTFPQ if year == `x' & dummy_operator == 1
	qui replace corr_rental_TFP_3 = r(rho) if year == `x'
	
	qui spearman dummy_rentin logTFPQ if year == `x' & dummy_operator == 1
	qui replace corr_rental_TFP_4 = r(rho) if year == `x'
	
	qui spearman leasedin TFPQ   if year == `x' & dummy_operator == 1
	qui replace corr_rental_TFP_5 = r(rho)      if year == `x'
}



collapse (mean) rentin_hh_frac rentout_hh_frac inactive_hh_frac rentin_size_mean_perHH ///
	rentin_size_median_perHH rentin_size_frac rentout_size_frac rentout_hh_frac_2 ///
	rentout_size_frac_2 fallow_hh_frac fallow_size_frac land_noope_frac ///
	corr_rental_TFP_*, by(year)

export excel rentin_hh_frac rentout_hh_frac inactive_hh_frac rentin_size_frac ///
	rentout_size_frac rentin_size_mean_perHH rentin_size_median_perHH ///
	rentout_hh_frac_2 rentout_size_frac_2 fallow_hh_frac fallow_size_frac ///
	land_noope_frac corr_rental_TFP_1 corr_rental_TFP_2 ///
	corr_rental_TFP_3 corr_rental_TFP_4 corr_rental_TFP_5 ///
	using "$results/estimation-Calibration.xlsx", sheet("Agr Moments Other",modify) cell(W4)
	

restore

*******************************************************************************
// Complement 1: estimate the correlation between the choice of off-farm employment and the household characteristics
*******************************************************************************

use "$temp-data/ready-for-moments.dta", clear

/*
//coastal area

gen coastal = 0
replace coastal = 1 if prov == 12 | prov == 31 | prov == 32 | prov == 33 | prov == 35 | ///
prov == 37 | prov == 44 | prov == 46 | prov == 21 | prov == 13

keep if coastal == 0
*/


/*
//suburb
cap drop _merge 
merge m:1 year village using "$temp-data/village_suburb.dta"

drop if _merge < 3  
drop _merge

keep if suburb == 0
//keep if suburb == 1

*/

preserve

bys hhid year: gen obs_hh = _N
gen logobs = log(obs_hh)


* dummy of working labor size 
gen bin_hhsize = .
replace bin_hhsize = 1 if obs_hh <= 3
replace bin_hhsize = 2 if obs_hh >= 4 & obs_hh <= 6
replace bin_hhsize = 3 if obs_hh > 6


drop if dummy_1 + dummy_9 == 1

gen logland = log(land)
gen logland_capita = log(land/hhsize)

gen dummy_nonagr = 0
replace dummy_nonagr = 1 if dummy_3 + dummy_4 + dummy_5 + dummy_6 + dummy_7 + dummy_8 > 0

replace gender = . if gender ~= 1 & gender ~= 2
replace gender = 0 if gender == 2
tab year 

gen bin_edu = 1 if education <= 6
replace bin_edu = 2 if education > 6 & education <= 9
replace bin_edu = 3 if education > 9 & education <= 12
replace bin_edu = 4 if education > 12

gen logage = log(age)
gen age2 = age*age


probit dummy_nonagr obs_hh i.gender i.bin_edu logage age age2 i.year i.village,cluster(prov) 
est store probitobs_hh1 
eststo:estpost margins, dydx(obs_hh)

probit dummy_nonagr obs_hh i.gender i.bin_edu logage age age2 logland i.year i.village,cluster(prov) 
est store probitobs_hh2 
eststo:estpost margins, dydx(obs_hh)

probit dummy_nonagr obs_hh i.gender i.bin_edu logage age age2 logland_capita i.year i.village,cluster(prov) 
est store probitobs_hh3 
eststo:estpost margins, dydx(obs_hh)

reghdfe dummy_nonagr obs_hh i.gender i.bin_edu logage age age2 i.year i.village, absorb(village year) cluster(prov)
est store regobs_hh1

reghdfe dummy_nonagr obs_hh i.gender i.bin_edu logage age age2 logland i.year i.village, absorb(village year) cluster(prov)
est store regobs_hh1

reghdfe dummy_nonagr obs_hh i.gender i.bin_edu logage age age2 logland_capita i.year i.village, absorb(village year) cluster(prov)
est store regobs_hh2



local var hhsize labor_num old_child7_share old_child12_share old_child_share sibling_num
foreach i of local var{
	
	probit dummy_nonagr `i' i.gender i.bin_edu logage age age2 i.year i.village,cluster(prov) 
	est store probit`i'1
	eststo:estpost margins, dydx(`i')

	probit dummy_nonagr `i' i.gender i.bin_edu logage age age2 logland_capita i.year i.village,cluster(prov) 
	est store probit`i'2
	eststo:estpost margins, dydx(`i')
	
	reghdfe dummy_nonagr `i' i.gender i.bin_edu logage age age2 logland_capita i.year i.village, absorb(village year) cluster(prov)
	est store reg`i'


}

esttab probitobs_hh1 probitobs_hh2 probitobs_hh3 probithhsize1 probithhsize2 probitlabor_num1 probitlabor_num2 probitold_child7_share1 probitold_child7_share2 probitold_child12_share1 probitold_child12_share2 probitold_child_share1 probitold_child_share2 probitsibling_num1 probitsibling_num2 regobs_hh1 regobs_hh2 reghhsize reglabor_num regold_child7_share regold_child12_share regold_child_share regsibling_num using $results/dummy_nonagr.csv,  ///
mtitle(probitobs_hh1 probitobs_hh2 probitobs_hh3 probithhsize1 probithhsize2 probitlabor_num1 probitlabor_num2 probitold_child7_share1 probitold_child7_share2 probitold_child12_share1 probitold_child12_share2 probitold_child_share1 probitold_child_share2 probitsibling_num1 probitsibling_num2 regobs_hh1 regobs_hh2 reghhsize reglabor_num regold_child7_share regold_child12_share regold_child_share regsibling_num)   ///
b(%12.3f) se(%12.3f) nogap compress s(N r2 r2_p) star(* 0.10 ** 0.05 *** 0.01) ///
drop(*.village *.year) 
                                      
esttab est1 est2 est3 est4 est5 est6 est7 est8 est9 est10 est11 est12 est13 est14 est15 using $results/Marginal.csv, cell("b(star fmt(3))") pr2 ///
replace compress nogap star( * 0.10 ** 0.05 *** 0.01 ) title("Marginal Effect")

                                      
restore 

********************************************************************************
// Complement 2. collect information on the generation change of farm operators
********************************************************************************

use "$temp-data/ready-for-moments.dta", clear

/*
//coastal area

gen coastal = 0
replace coastal = 1 if prov == 12 | prov == 31 | prov == 32 | prov == 33 | prov == 35 | ///
prov == 37 | prov == 44 | prov == 46 | prov == 21 | prov == 13

keep if coastal == 0
*/


/*
//suburb
cap drop _merge 
merge m:1 year village using "$temp-data/village_suburb.dta"

drop if _merge < 3  
drop _merge

keep if suburb == 0
//keep if suburb == 1

*/

drop if dummy_1 == 1 /* drop those who are in school */


* 1. households quiting farm 

bys year hhid: egen hh_operator = total(dummy_operator)
drop if hh_operator > 1 

preserve 

duplicates drop year hhid,force 

keep year hhid hh_operator 
tsset hhid year 
sort hhid year 
gen dummy_quitfarm = 1 if (hh_operator - L.hh_operator == -1)

save "$temp-data/dummy-quitfarm.dta",replace 

restore 

drop _merge 
merge m:1 year hhid using "$temp-data/dummy-quitfarm.dta",force 
drop if _merge < 3 
drop _merge 



* 2. households changing operators 

preserve 

keep if dummy_operator == 1
duplicates drop year hhid,force 

gen dummy_oy_operator = 0
label var dummy_oy_operator "generation change of farm operator, old to young"

tsset hhid year
sort hhid year 
replace dummy_oy_operator = 1 if (L.relation == 1 | L.relation == 2) & (relation == 3 | relation == 4)
replace dummy_oy_operator = 1 if (L.relation == 5 | L.relation == 6) & (relation == 1 | relation == 2 | relation == 3 | relation == 4)

replace dummy_oy_operator = 1 if (L.age - age >= 18) & (L.age - age ~= .)

keep year hhid dummy_oy_operator 
save "$temp-data/dummy-oy-operator.dta",replace 

restore 

preserve 

keep if dummy_operator == 1
duplicates drop year hhid,force 

gen dummy_yo_operator = 0
label var dummy_yo_operator "generation change of farm operator, young to old"

tsset hhid year
sort hhid year 
replace dummy_yo_operator = 1 if (L.relation == 3 | L.relation == 4) & (relation == 1 | relation == 2)
replace dummy_yo_operator = 1 if (L.relation == 1 | L.relation == 2  | relation == 3 | relation == 4 ) & (relation == 5 | relation == 6)

replace dummy_yo_operator = 1 if (L.age - age <= -18) & (L.age - age ~= .)

keep year hhid dummy_yo_operator 
save "$temp-data/dummy-yo-operator.dta",replace 

restore 


merge m:1 year hhid using "$temp-data/dummy-yo-operator.dta",force 
drop _merge 

merge m:1 year hhid using "$temp-data/dummy-oy-operator.dta",force 
drop _merge 

drop if indid == .

* 3. A description of the previous operators 

gen dummy_prev_operator = 0
tsset indid year 
sort indid year 
replace dummy_prev_operator = 1 if dummy_quitfarm == 1 & L.dummy_operator == 1
replace dummy_prev_operator = 1 if dummy_oy_operator == 1 & L.dummy_operator == 1 
replace dummy_prev_operator = 1 if dummy_yo_operator == 1 & L.dummy_operator == 1 

sum age if dummy_prev_operator == 1 & (dummy_quitfarm == 1| dummy_oy_operator == 1),d 


* 4. subsample: operators quit beause of the age or health problem

preserve 

keep if dummy_prev_operator == 1
gen old_quit_operator = 0
replace old_quit_operator = 1 if dummy_oy_operator == 1 & (health >= 4 | age >= 50)
replace old_quit_operator = 1 if dummy_quitfarm == 1 & (health >= 4 | age >= 50)

keep if old_quit_operator == 1
bys year: egen Nold_quit_operator = total(old_quit_operator)
bys year: egen Noy_operator = total(dummy_oy_operator)
bys year: egen Nquitfarm = total(dummy_quitfarm)

gen share_oy = Noy_operator / Nold_quit_operator
gen share_quit = Nquitfarm / Nold_quit_operator

duplicates drop year,force 
keep year share_oy share_quit

export excel year share_oy share_quit ///
	using "$results/operator.xlsx", firstrow(variables) sheet("share1",modify) cell(C3)

restore 

* old - young operator, whether the young operator participates farm works

preserve 

drop if dummy_1 == 1 

replace dummy_4 = 1 if dummy_7 == 1
replace dummy_6 = 1 if dummy_8 == 1

tsset indid year
sort indid year 
drop if dummy_oy_operator == 1 & dummy_operator == 1 & L.dummy_2 == . & L.dummy_3 == . & L.dummy_4 == . & L.dummy_5 == . & L.dummy_6 == . & year > 2004

gen Dfull_agr = 1 if L.dummy_2 == 1 & dummy_oy_operator == 1 & dummy_operator == 1
gen Dpart_agr = 1 if (L.dummy_5 == 1 | L.dummy_6 == 1) & dummy_oy_operator == 1 & dummy_operator == 1
gen Dfull_nonagr = 1 if (L.dummy_3 == 1 | L.dummy_4 == 1) & dummy_oy_operator == 1 & dummy_operator == 1

gen temp0 = 1 if dummy_oy_operator == 1 & dummy_operator == 1
gen temp9 = 1 if temp0 == 1 &  Dfull_agr == . & Dpart_agr == . & Dfull_nonagr == .
drop if temp9 == 1

bys year: egen Nfull_agr = total(Dfull_agr)   
bys year: egen Npart_agr = total(Dpart_agr)
bys year: egen Nfull_nonagr = total(Dfull_nonagr)

bys year: egen Noy_operator = total(temp0) 

gen share_fullagr = Nfull_agr / Noy_operator 
gen share_partagr = Npart_agr / Noy_operator 
gen share_fullnonagr = Nfull_nonagr / Noy_operator 

duplicates drop year,force 

keep year share_fullagr share_partagr share_fullnonagr
export excel year share_fullagr share_partagr share_fullnonagr ///
	using "$results/operator.xlsx", firstrow(variables) sheet("share2",modify) cell(C3)

restore 

* land transfers for households giving up agricultrue

preserve 

duplicates drop hhid year,force 

tsset hhid year
sort hhid year
gen share_leasedout = leasedout / L.land 
keep if dummy_quitfarm == 1 & (health >= 4 | age >= 50)
bys year: egen Sshare_leasedout = mean(share_leasedout)

duplicates drop year,force 

keep year Sshare_leasedout
export excel year Sshare_leasedout ///
	using "$results/operator.xlsx", firstrow(variables) sheet("share3",modify) cell(C3)

restore 

