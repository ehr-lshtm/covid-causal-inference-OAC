/*=========================================================================
DO FILE NAME:			7b_OAC-Aurum-univariable-model-01-main-analysis-edoxaban

AUTHOR:					Angel Wong
VERSION:				v1
DATE VERSION CREATED:	12 Aug 2025
					
DATABASE:				
						CPRD Aurum Dec 2024 build

Aim:
To run unadjusted model only
Update: use distinct id rather than patid
*=============================================================================*/

capture log close

/*******************************************************************************
Identify file locations
*******************************************************************************/
* open log file - no need as fast tool will create log files
log using "${pathLogs}/7b_OAC-Aurum-univariable-model-01-main-analysis-edoxaban", text replace

/**********************************************************************
* Analysis 1: data from pre-pandemic 
***********************************************************************/
foreach doac in edoxaban_low edoxaban_high {
		foreach outcome in major_bleed ischaemic_stroke MI vte {
			
use "$pathOutOAC/aurum_dose_`doac'_covariate_`outcome'", clear 

//this dataset for CVD outcome already removed those with history of CVD events
egen groupid = group(patid exposure)
global sample_size = _N
destring region, replace
drop eventdate `outcome' stime_`outcome'

*remove those who initiated antibiotics when pandemic started
gen pandemic_start = mdy(03,16,2020)
gen pandemic_end = mdy(04,17,2022)
format pandemic_start pandemic_end %td

drop if indexdate>=pandemic_start

*change the end of follow-up when pandemic started
gen enddate_new = min(pandemic_start, enddate)
format enddate_new %td
su enddate_new, format

*re-generate outcome for analysis 1
joinby patid using "$pathOutOAC/`outcome'_all.dta", unmatched(master)
drop _merge source
						
gen `outcome' = 1 if eventdate != . &  incident == "1" & ///
					eventdate > indexdate & eventdate <= enddate_new
replace eventdate = . if `outcome' != 1	
replace `outcome' = 0 if `outcome' == .

gen stime_`outcome' = min(enddate_new, eventdate)
format stime_`outcome' %td

bysort patid exposure: egen max_`outcome' = max(`outcome')

sort patid exposure stime_`outcome'
bysort patid exposure: keep if _n==1
drop `outcome' eventdate incident

rename max_`outcome' `outcome'

drop if indexdate == stime_`outcome'

tab exposure `outcome', m row

save "$pathOutOAC/aurum_dose_`doac'_`outcome'_analysis1", replace

stset stime_`outcome', id(groupid) fail(`outcome') enter(indexdate) origin(indexdate)	

cap file close tablecontent
file open tablecontent using "$pathResults/OAC/crude_dose_`doac'_`outcome'_analysis1.txt", write text replace

file write tablecontent _tab ("Number of events") _tab ("Total person-year") _tab ("Rate per 1,000") _tab ("Univariable") _tab _tab _n
file write tablecontent ("DOAC vs warfarin") _tab _tab _tab _tab ("HR") _tab ("95% CI") _n				

file write tablecontent _n

* Row headings 
local lab0: label exposure 0
local lab1: label exposure 1

	di "Description of follow-up in analysis 1 `doac' `outcome'" 
	su _t, detail
	di "Description of follow-up for each exposure group in analysis 1 `doac' `outcome'" 
	bysort exposure: su _t, detail
	
* First row, exposure = 0 (reference)

	qui count if exposure == 0 & `outcome' == 1
	local event = r(N)
    bysort exposure: egen total_follow_up = total(_t)
	qui su total_follow_up if exposure == 0
	local person_year = r(mean)/365.25
	local rate = 1000*(`event'/`person_year')
	
	file write tablecontent ("`lab0'") _tab
	file write tablecontent (`event') _tab %10.0f (`person_year') _tab %3.2f (`rate') _tab
	file write tablecontent ("1.00 (ref)") _n
	
* Second row, exposure = 1 
file write tablecontent ("`lab1'") _tab  

	qui count if exposure == 1 & `outcome' == 1
	local event = r(N)
	qui su total_follow_up if exposure == 1
	local person_year = r(mean)/365.25
	local rate = 1000*(`event'/`person_year')
	file write tablecontent (`event') _tab %10.0f (`person_year') _tab %3.2f (`rate') _tab

stcox i.exposure, vce(robust)
lincom 1.exposure, eform 

file write tablecontent %4.2f (r(estimate)) _tab %4.2f (r(lb)) (" - ") %4.2f (r(ub)) _tab 

file write tablecontent _n
file close tablecontent

/**********************************************************************
* Analysis 2: study population from pre-pandemic and lengthening the follow-up to post-pandemic
***********************************************************************/
use "$pathOutOAC/aurum_dose_`doac'_covariate_`outcome'", clear

drop if indexdate == stime_`outcome'
egen groupid = group(patid exposure)
global sample_size = _N

destring region, replace

*remove those who initiated antibiotics when pandemic started
gen pandemic_start = mdy(03,16,2020)
gen pandemic_end = mdy(04,17,2022)
format pandemic_start pandemic_end stime_`outcome' %td

drop if indexdate>=pandemic_start

su stime_`outcome', format

tab exposure `outcome', m row

save "$pathOutOAC/aurum_dose_`doac'_`outcome'_analysis2", replace

stset stime_`outcome', id(groupid) fail(`outcome') enter(indexdate) origin(indexdate)	

cap file close tablecontent
file open tablecontent using "$pathResults/OAC/crude_dose_`doac'_`outcome'_analysis2.txt", write text replace

file write tablecontent _tab ("Number of events") _tab ("Total person-year") _tab ("Rate per 1,000") _tab ("Univariable") _tab _tab _n
file write tablecontent ("DOAC vs warfarin") _tab _tab _tab _tab ("HR") _tab ("95% CI") _n				

file write tablecontent _n

* Row headings 
local lab0: label exposure 0
local lab1: label exposure 1

	di "Description of follow-up in analysis 2 `doac' `outcome'" 
	su _t, detail
	di "Description of follow-up for each exposure group in analysis 2 `doac' `outcome'" 
	bysort exposure: su _t, detail	

* First row, exposure = 0 (reference)

	qui count if exposure == 0 & `outcome' == 1
	local event = r(N)
    bysort exposure: egen total_follow_up = total(_t)
	qui su total_follow_up if exposure == 0
	local person_year = r(mean)/365.25
	local rate = 1000*(`event'/`person_year')
	
	file write tablecontent ("`lab0'") _tab
	file write tablecontent (`event') _tab %10.0f (`person_year') _tab %3.2f (`rate') _tab
	file write tablecontent ("1.00 (ref)") _n
	
* Second row, exposure = 1 
file write tablecontent ("`lab1'") _tab  

	qui count if exposure == 1 & `outcome' == 1
	local event = r(N)
	qui su total_follow_up if exposure == 1
	local person_year = r(mean)/365.25
	local rate = 1000*(`event'/`person_year')
	file write tablecontent (`event') _tab %10.0f (`person_year') _tab %3.2f (`rate') _tab

stcox i.exposure, vce(robust)
lincom 1.exposure, eform 

file write tablecontent %4.2f (r(estimate)) _tab %4.2f (r(lb)) (" - ") %4.2f (r(ub)) _tab 

file write tablecontent _n
file close tablecontent

/**********************************************************************
* Analysis 3: Using all data for study population and identify outcome
***********************************************************************/
use "$pathOutOAC/aurum_dose_`doac'_covariate_`outcome'", clear

drop if indexdate == stime_`outcome'
egen groupid = group(patid exposure)
global sample_size = _N

destring region, replace
format stime_`outcome' %td

su stime_`outcome', format

tab exposure `outcome', m row

*Create a period variable
gen pandemic_start = mdy(03,16,2020)
gen pandemic_end = mdy(04,17,2022)
gen period = 1 if indexdate>=pandemic_start
replace period = 0 if period == .

save "$pathOutOAC/aurum_dose_`doac'_`outcome'_analysis3", replace

stset stime_`outcome', id(groupid) fail(`outcome') enter(indexdate) origin(indexdate)	

cap file close tablecontent
file open tablecontent using "$pathResults/OAC/crude_dose_`doac'_`outcome'_analysis3.txt", write text replace

file write tablecontent _tab ("Number of events") _tab ("Total person-year") _tab ("Rate per 1,000") _tab ("Univariable") _tab _tab _n
file write tablecontent ("DOAC vs warfarin") _tab _tab _tab _tab ("HR") _tab ("95% CI") _n				

file write tablecontent _n

* Row headings 
local lab0: label exposure 0
local lab1: label exposure 1

	di "Description of follow-up in analysis 3 `doac' `outcome'" 
	su _t, detail
	di "Description of follow-up for each exposure group in analysis 3 `doac' `outcome'" 
	bysort exposure: su _t, detail
	

* First row, exposure = 0 (reference)

	qui count if exposure == 0 & `outcome' == 1
	local event = r(N)
    bysort exposure: egen total_follow_up = total(_t)
	qui su total_follow_up if exposure == 0
	local person_year = r(mean)/365.25
	local rate = 1000*(`event'/`person_year')
	
	file write tablecontent ("`lab0'") _tab
	file write tablecontent (`event') _tab %10.0f (`person_year') _tab %3.2f (`rate') _tab
	file write tablecontent ("1.00 (ref)") _n
	
* Second row, exposure = 1 
file write tablecontent ("`lab1'") _tab  

	qui count if exposure == 1 & `outcome' == 1
	local event = r(N)
	qui su total_follow_up if exposure == 1
	local person_year = r(mean)/365.25
	local rate = 1000*(`event'/`person_year')
	file write tablecontent (`event') _tab %10.0f (`person_year') _tab %3.2f (`rate') _tab

stcox i.exposure, vce(robust)
lincom 1.exposure, eform 

file write tablecontent %4.2f (r(estimate)) _tab %4.2f (r(lb)) (" - ") %4.2f (r(ub)) _n 

stcox i.exposure##i.period, vce(robust)
foreach i in 0 1 {
lincom 1.exposure + `i'.period#1.exposure, eform 

file write tablecontent ("period") _tab (`i') _tab %4.2f (r(estimate)) _tab %4.2f (r(lb)) (" - ") %4.2f (r(ub)) _n
}

file write tablecontent _n
file close tablecontent


/**********************************************************************
* Analysis 4: Using data from post-pandemic only
***********************************************************************/
use "$pathOutOAC/aurum_dose_`doac'_covariate_`outcome'", clear

drop if indexdate == stime_`outcome'
egen groupid = group(patid exposure)
global sample_size = _N

destring region, replace
format stime_`outcome' %td

su stime_`outcome', format

tab exposure `outcome', m row

*remove those who initiated antibiotics when pandemic restrictions ended
gen pandemic_end = mdy(04,17,2022)
format pandemic_end stime_`outcome' %td

drop if indexdate<pandemic_end

su stime_`outcome', format

tab exposure `outcome', m row

save "$pathOutOAC/aurum_dose_`doac'_`outcome'_analysis4", replace

stset stime_`outcome', id(groupid) fail(`outcome') enter(indexdate) origin(indexdate)	

cap file close tablecontent
file open tablecontent using "$pathResults/OAC/crude_dose_`doac'_`outcome'_analysis4.txt", write text replace

file write tablecontent _tab ("Number of events") _tab ("Total person-year") _tab ("Rate per 1,000") _tab ("Univariable") _tab _tab _n
file write tablecontent ("DOAC vs warfarin") _tab _tab _tab _tab ("HR") _tab ("95% CI") _n				

file write tablecontent _n

* Row headings 
local lab0: label exposure 0
local lab1: label exposure 1

	di "Description of follow-up in analysis 4 `doac' `outcome'" 
	su _t, detail
	di "Description of follow-up for each exposure group in analysis 4 `doac' `outcome'" 
	bysort exposure: su _t, detail

* First row, exposure = 0 (reference)

	qui count if exposure == 0 & `outcome' == 1
	local event = r(N)
    bysort exposure: egen total_follow_up = total(_t)
	qui su total_follow_up if exposure == 0
	local person_year = r(mean)/365.25
	local rate = 1000*(`event'/`person_year')
	
	file write tablecontent ("`lab0'") _tab
	file write tablecontent (`event') _tab %10.0f (`person_year') _tab %3.2f (`rate') _tab
	file write tablecontent ("1.00 (ref)") _n
	
* Second row, exposure = 1 
file write tablecontent ("`lab1'") _tab  

	qui count if exposure == 1 & `outcome' == 1
	local event = r(N)
	qui su total_follow_up if exposure == 1
	local person_year = r(mean)/365.25
	local rate = 1000*(`event'/`person_year')
	file write tablecontent (`event') _tab %10.0f (`person_year') _tab %3.2f (`rate') _tab

stcox i.exposure, vce(robust)
lincom 1.exposure, eform 

file write tablecontent %4.2f (r(estimate)) _tab %4.2f (r(lb)) (" - ") %4.2f (r(ub)) _tab 

file write tablecontent _n
file close tablecontent
		}
}

log close
