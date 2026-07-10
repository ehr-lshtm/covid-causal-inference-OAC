/*=========================================================================
DO FILE NAME:			6_OAC-Aurum-outcome-01

AUTHOR:					Angel Wong
VERSION:				v1
DATE VERSION CREATED:	12 Aug 2025
					
DATABASE:				CPRD Dec 2024 build

Aim:
key all history and incident outcome to all datasets
Revised: use all FQ events instead of first FQ events
*=============================================================================*/

/*******************************************************************************
>> HOUSEKEEPING
*******************************************************************************/
capture log close

/*******************************************************************************
Identify file locations
*******************************************************************************/
* create a filename global that can be used throughout the file
global filename "6_OAC-Aurum-outcome-01"

* open log file - no need as fast tool will create log files
log using "${pathLogs}/${filename}", text replace

/****************************************************************************
* Combine outcomes identified from HES & ONS for major bleeding
*****************************************************************************/
use "$pathOutOAC/hes_major_bleed_hx.dta", clear
gen source = 1
gen incident = "1"
append using "$pathOutOAC/ons_major_bleed_dx.dta"
replace incident = "1" if missing(incident)
replace source = 2 if source == .
cou if eventdate==. 
cou 
drop if eventdate==.
keep patid source eventdate incident
save "$pathOutOAC/major_bleed_all.dta", replace

/****************************************************************************
* Combine outcomes identified from CPRD, HES & ONS for CVD outcomes
*****************************************************************************/
*ischamiec stroke
use "Obs_stroke_all", clear //the replicated study include TIA/unspecified stroke
gen source = 0
rename obsdate eventdate
append using "$pathOutOAC/hes_ischaemic_stroke_dx.dta"
replace incident = "1" if missing(incident)
replace source = 1 if source == .
append using "$pathOutOAC/ons_ischaemic_stroke_dx.dta"
replace incident = "1" if missing(incident)
replace source = 2 if source == . 
cou if eventdate==. 
cou 
drop if eventdate==.
keep patid source eventdate incident
save "$pathOutOAC/ischaemic_stroke_all.dta", replace

*MI
use "Obs_mi_all", clear
gen source = 0
rename obsdate eventdate
destring incident, replace
append using "$pathOutOAC/hes_MI_dx.dta"
replace source = 1 if source == .
append using "$pathOutOAC/ons_MI_dx.dta"
replace incident = 1 if incident==.
replace source = 2 if source == . 
cou if eventdate==. 
tab incident,m
cou 
drop if eventdate==.
tostring incident, replace
keep patid source eventdate incident
save "$pathOutOAC/MI_all.dta", replace

*vte
use "Obs_vte_all", clear
gen source = 0
rename obsdate eventdate
append using "$pathOutOAC/hes_vte_dx.dta"
replace incident = "1" if missing(incident)
replace source = 1 if source == .
append using "$pathOutOAC/ons_vte_dx.dta"
replace incident = "1" if missing(incident)
replace source = 2 if source == . 
cou if eventdate==. 
cou 
drop if eventdate==.
keep patid source eventdate incident
save "$pathOutOAC/vte_all.dta", replace

*first recorded of CV outcomes
	foreach outcome in ischaemic_stroke MI vte {
use "$pathOutOAC/`outcome'_all.dta", clear
sort patid eventdate
bysort patid: keep if _n==1
save "$pathOutOAC/`outcome'_first.dta", replace
	}

/**************************************************************************** 
* Identify the first recorded major bleeding after cohort entry as the outcome occurence
*****************************************************************************/
foreach doac in rivaroxaban apixaban edoxaban_low edoxaban_high {
use "$pathOutOAC/aurum_`doac'_covariate_final", clear

tab exposure,m

joinby patid using "$pathOutOAC/major_bleed_all.dta", unmatched(master)
						
gen major_bleed = 1 if eventdate != . & ///
					eventdate > indexdate & eventdate <= enddate
					
replace eventdate = . if major_bleed != 1				
replace major_bleed = 0 if major_bleed == .
gen stime_major_bleed = min(enddate, eventdate)
format stime_major_bleed %td

bysort patid exposure: egen max_MB = max(major_bleed)

sort patid exposure stime_major_bleed
bysort patid exposure: keep if _n==1
drop major_bleed eventdate

rename max_MB major_bleed

tab exposure major_bleed,m
drop _merge source incident

save "$pathOutOAC/aurum_`doac'_covariate_major_bleed", replace	
}

/**************************************************************************** 
* Identify the first recorded CVD event after cohort entry as the outcome occurence
* Remove people who had a history of outcome
*****************************************************************************/
foreach doac in rivaroxaban apixaban edoxaban_low edoxaban_high {
	foreach outcome in ischaemic_stroke MI vte {

use "$pathOutOAC/aurum_`doac'_covariate_final", clear

tab exposure,m

joinby patid using "$pathOutOAC/`outcome'_all.dta", unmatched(master)
						
gen `outcome' = 1 if eventdate != . &  incident == "1" & ///
					eventdate > indexdate & eventdate <= enddate

replace eventdate = . if `outcome' != 1
replace `outcome' = 0 if `outcome' == .	

gen stime_`outcome' = min(enddate, eventdate)
format stime_`outcome' %td

bysort patid exposure: egen max_`outcome' = max(`outcome')

sort patid exposure stime_`outcome'
bysort patid exposure: keep if _n==1
drop `outcome' eventdate incident _merge source

rename max_`outcome' `outcome'

merge m:1 patid using "$pathOutOAC/`outcome'_first.dta", keepusing(eventdate) keep(master match) nogen
gen hist_ever_`outcome' = 1 if eventdate != . & eventdate <= indexdate  
replace hist_ever_`outcome' = 0 if hist_ever_`outcome' == .

tab exposure `outcome',m
tab exposure hist_ever_`outcome',m

drop if hist_ever_`outcome' == 1

tab exposure `outcome',m

drop eventdate hist_ever_`outcome'

save "$pathOutOAC/aurum_`doac'_covariate_`outcome'", replace	
	}
}

log close					
