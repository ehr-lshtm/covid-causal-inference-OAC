/*=========================================================================
DO FILE NAME:			17_OAC-Aurum-01-INR-TTR calculation

AUTHOR:					Angel Wong
						
DATE VERSION CREATED:   2026-Mar-31
					
DATABASE:				CPRD Dec 2024 build
												
DESCRIPTION OF FILE:

Aim to identify covariates (comorbidities/co-medication) in Aurum only:
1. identify frequency and median of INR test during follow-up
2. identify TTR
	
DO FILES NEEDED:	MRC_FQ_Aurum-codelist01-Dec2024build
					
*=========================================================================*/
* Open a log file
capture log close

/*******************************************************************************
Identify file locations
*******************************************************************************/
* create a filename global that can be used throughout the file
global filename "17_OAC-Aurum-01-INR-TTR calculation"

* open log file - no need as fast tool will create log files
log using "${pathLogs}/${filename}", text replace
*******************************************************************************/
use "Obs_inr_all", clear
drop if missing(value)
drop if target == 1 //they are not actual values confirmed with Charlotte
destring value, replace
drop target

preserve
keep if ttr==1
save "$pathOutOAC/Obs_ttr_all", replace
drop ttr
restore

drop if ttr==1
drop ttr
merge m:1 numunit using "$pathOut\NumUnit", keep(match) nogen //units are not very helpful
save "$pathOutOAC/Obs_inr_all", replace

su value, detail

*drop implausible values
drop if value < 0.8 | value > 20 //https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0164076
drop if missing(obsdate)

*calculate mean INR if more than one test per day per patient
bysort patid obsdate: egen mean_inr = mean(value)
duplicates drop patid obsdate, force
save "$pathOutOAC/inr_perdayperpatient", replace


//link inr with warfarin cohorts
foreach doac in rivaroxaban apixaban dose_edoxaban_low dose_edoxaban_high {
	foreach num in 1 2 3 4 {
	use "$pathOutOAC/aurum_`doac'_major_bleed_analysis`num'", clear
keep if exposure== 0 //warfarin
merge 1:m patid using "$pathOutOAC/inr_perdayperpatient", keep(master match) keepusing(obsdate mean_inr) nogen
keep if !missing(obsdate) & indexdate<=obsdate & obsdate<=stime_major_bleed
save "$pathOutOAC/`doac'_inr_bleed_analysis`num'", replace
drop enddate
rename stime_major_bleed enddate
rename mean_inr INR
unique patid
keep patid indexdate enddate obsdate INR heart_valve_disease_base

/*import in SAS and calculate using Emma's syntax*/
export delimited using "$pathOutOAC/`doac'_inr_bleed_analysis`num'.txt", replace 
	}
}

*during/after COVID only
foreach doac in rivaroxaban apixaban dose_edoxaban_low dose_edoxaban_high {
use "$pathOutOAC/aurum_`doac'_covariate_major_bleed", clear
gen pandemic_start = mdy(03,16,2020)
keep if indexdate>=pandemic_start
keep if exposure== 0 //warfarin
merge 1:m patid using "$pathOutOAC/inr_perdayperpatient", keep(master match) keepusing(obsdate mean_inr) nogen
keep if !missing(obsdate) & indexdate<=obsdate & obsdate<=stime_major_bleed
save "$pathOutOAC/`doac'_inr_bleed_analysis5", replace
drop enddate
rename stime_major_bleed enddate
rename mean_inr INR
unique patid
keep patid indexdate enddate obsdate INR heart_valve_disease_base

/*import in SAS and calculate using Emma's syntax*/
export delimited using "$pathOutOAC/`doac'_inr_bleed_analysis5.txt", replace 
	}

log close

*import back to Stata from SAS
global filename "17_OAC-Aurum-01-INR-TTR calculation_main analysis"

* open log file - no need as fast tool will create log files
log using "${pathLogs}/${filename}", text replace

*import ttr value calculated in SAS
foreach doac in rivaroxaban apixaban edohigh edolow {
	foreach num in 1 2 3 4 5 {
		foreach heartv in 1 0 {
			import delimited using "$pathOutOAC/ttrf`heartv'_`doac'_analysis`num'.txt", clear stringcols(_all) 
			destring ttr, replace
			keep patid ttr
			save "$pathOutOAC/ttrf`heartv'_`doac'_analysis`num'", replace
		}
	}
		}

*check the TTR dataset (same number of patients and same patient cohort)
foreach doac in rivaroxaban apixaban {
	foreach num in 1 2 3 4 5 {
use "$pathOutOAC/`doac'_inr_bleed_analysis`num'", clear
duplicates drop patid, force
local sample_size = _N

tempfile previous_dataset
save `previous_dataset'

use "$pathOutOAC/ttrf1_`doac'_analysis`num'", clear
append using "$pathOutOAC/ttrf0_`doac'_analysis`num'"
local sample_size_new = _N

merge 1:1 patid using `previous_dataset'

di "`doac' and analysis`num'"
assert `sample_size' == `sample_size_new'
assert _merge!=1
assert _merge!=2

	}
}

	foreach num in 1 2 3 4 5 {
use "$pathOutOAC/dose_edoxaban_low_inr_bleed_analysis`num'", clear
duplicates drop patid, force
local sample_size = _N
tempfile previous_dataset
save `previous_dataset'

use "$pathOutOAC/ttrf1_edolow_analysis`num'", clear
append using "$pathOutOAC/ttrf0_edolow_analysis`num'"
merge 1:1 patid using `previous_dataset'

local sample_size_new = _N
di "edolow and analysis`num'"
assert `sample_size' == `sample_size_new'
assert _merge!=1
assert _merge!=2
	}

	foreach num in 1 2 3 4 5 {
use "$pathOutOAC/dose_edoxaban_high_inr_bleed_analysis`num'", clear
duplicates drop patid, force
local sample_size = _N
tempfile previous_dataset
save `previous_dataset'

use "$pathOutOAC/ttrf1_edohigh_analysis`num'", clear
append using "$pathOutOAC/ttrf0_edohigh_analysis`num'"
merge 1:1 patid using `previous_dataset'

local sample_size_new = _N
di "edohigh and analysis`num'"
assert `sample_size' == `sample_size_new'
assert _merge!=1
assert _merge!=2
	}

*combine heart valve =1 and =0 datasets
*TTR values in each analyses
foreach doac in rivaroxaban apixaban edohigh edolow {
	foreach num in 1 2 3 4 5 {
		use "$pathOutOAC/ttrf1_`doac'_analysis`num'", clear
		gen heartv = 1
		append using "$pathOutOAC/ttrf0_`doac'_analysis`num'"
		replace heartv=0 if heartv != 1
		
		gen ttr_percent = ttr*100
		
		di " TTR for `doac' in analysis `num'"
		bysort heartv: su ttr_percent, detail
	}
}

foreach doac in rivaroxaban apixaban dose_edoxaban_low dose_edoxaban_high {
use "$pathOutOAC/aurum_`doac'_covariate_major_bleed", clear
gen pandemic_start = mdy(03,16,2020)
keep if indexdate>=pandemic_start
save "$pathOutOAC/aurum_`doac'_major_bleed_analysis5", replace
}
	foreach num in 1 2 3 4 5 {
use "$pathOutOAC/ttrf1_edohigh_analysis`num'", clear
save "$pathOutOAC/ttrf1_dose_edoxaban_high_analysis`num'", replace
use "$pathOutOAC/ttrf0_edohigh_analysis`num'", clear
save "$pathOutOAC/ttrf0_dose_edoxaban_high_analysis`num'", replace
use "$pathOutOAC/ttrf1_edolow_analysis`num'", clear
save "$pathOutOAC/ttrf1_dose_edoxaban_low_analysis`num'", replace
use "$pathOutOAC/ttrf0_edolow_analysis`num'", clear
save "$pathOutOAC/ttrf0_dose_edoxaban_low_analysis`num'", replace
}

*combine heart valve =1 and =0 datasets
*frequency INR tests in each analyses
foreach doac in rivaroxaban apixaban dose_edoxaban_low dose_edoxaban_high {
	foreach num in 1 2 3 4 5 {
		use "$pathOutOAC/ttrf1_`doac'_analysis`num'", clear
		gen heartv = 1
		append using "$pathOutOAC/ttrf0_`doac'_analysis`num'"
		replace heartv=0 if heartv != 1
		tempfile ttr_dataset
		save `ttr_dataset'
		
		*original dataset
		use "$pathOutOAC/aurum_`doac'_major_bleed_analysis`num'", clear
		keep if exposure == 0
		keep patid indexdate stime_major_bleed heart_valve_disease_base
			
		merge 1:1 patid using `ttr_dataset', keepusing(ttr) nogen
		merge 1:m patid using "$pathOutOAC/Obs_inr_all", keep(master match) keepusing(value obsdate)
		
		unique patid
		
		replace value = .  if !missing(obsdate) & (obsdate<indexdate | obsdate>stime_major_bleed) 
		replace _merge = 4  if !missing(obsdate) & (obsdate<indexdate | obsdate>stime_major_bleed) 
		replace obsdate = . if !missing(obsdate) & (obsdate<indexdate | obsdate>stime_major_bleed) 
		
		unique patid

		replace _merge = 4  if !missing(value) & (value < 0.8 | value > 20 )
		replace value = . if !missing(value) & (value < 0.8 | value > 20 )
		replace obsdate = . if !missing(value) & (value < 0.8 | value > 20 )
		unique patid
		gen inrtest = 1 if _merge==3
		drop _merge
		
		di " median INR for `doac' in analysis `num'"
		bysort heart_valve_disease_base: su value, detail
		
		bysort patid obsdate: egen mean_inr = mean(value)
		
		duplicates drop patid obsdate, force
		bysort patid: egen max_num_test = total(inrtest)
		
		gen duration = stime_major_bleed - indexdate + 1
		gen num_test_py = max_num_test / (duration/365.25)
		
		preserve
		sort patid obsdate
		bysort patid: keep if _n==1
		keep if max_num_test>0
		
		di "First test: median INR after taking mean for multiple tests on same day for `doac' in analysis `num'"
		bysort heart_valve_disease_base: su mean_inr, detail
		
		di " frequency of INR for `doac' in analysis `num'"
		bysort heart_valve_disease_base: su max_num_test, detail
		
		di " rate of INR tests per py for `doac' in analysis `num'"
		bysort heart_valve_disease_base: su num_test_py, detail
		
		restore
		
		duplicates drop patid, force
		
		di " Number of test for `doac' in analysis `num' among valvular patients"
		cou if heart_valve_disease_base==1
		local valve = r(N)
		
		di " Number of zero test for `doac' in analysis `num' among valvular patients"
		cou if max_num_test== 0 & heart_valve_disease_base==1 
		local valve_zero = r(N)
		
		di " Proportion of zero test for `doac' in analysis `num' among valvular patients"
		local valve_proportion = `valve_zero' / `valve' 
		di `valve_proportion'
		
		di " Number of test for `doac' in analysis `num' among non-valvular patients"
		cou if heart_valve_disease_base==0
		local non_valve = r(N)
		
		di " Number of zero test for `doac' in analysis `num' among non-valvular patients"
		cou if max_num_test== 0 & heart_valve_disease_base==0
		local non_valve_zero = r(N)
		
		di " Proportion of zero test for `doac' in analysis `num' among non-valvular patients"
		local non_valve_proportion = `non_valve_zero' / `non_valve' 
		di `non_valve_proportion'
		
		rename value inr_value
		rename obsdate inr_date
		
		*merge those recorded TTR as supplement
		merge 1:m patid using "$pathOutOAC/Obs_ttr_all", keep(master match) keepusing(value obsdate)
		
		replace value = .  if !missing(obsdate) & (obsdate<indexdate | obsdate>stime_major_bleed) 
		replace _merge = 4  if !missing(obsdate) & (obsdate<indexdate | obsdate>stime_major_bleed) 
		replace obsdate = . if !missing(obsdate) & (obsdate<indexdate | obsdate>stime_major_bleed)
		
		replace _merge = 4  if value!=. & value >100  
		replace obsdate = . if value!=. &  value >100 
		replace value = .  if value!=. & value >100 
		
		sort patid value //taking the smallest TTR as conservative estimate
		bysort patid: keep if _n==1
		
		rename value ttr_recordvalue
		rename obsdate ttr_date
		
		gen ttr_final_percent = ttr*100
		replace ttr_final_percent = ttr_recordvalue if ttr_final_percent == .
		
		di " TTR final for `doac' in analysis `num'"
		bysort heart_valve_disease_base: su ttr_final_percent, detail
		
		di " Number of zero test/TTR for `doac' in analysis `num' among valvular patients"
		cou if max_num_test== 0 & ttr_recordvalue==. & heart_valve_disease_base==1 
		local valve_none = r(N)
		
		di " Proportion of zero test/TTR for `doac' in analysis `num' among valvular patients"
		local valve_proportionnone = `valve_none' / `valve' 
		di `valve_proportionnone'
		
		di " Number of zero test/TTR for `doac' in analysis `num' among non-valvular patients"
		cou if max_num_test== 0 & ttr_recordvalue==. & heart_valve_disease_base==0
		local nonvalve_none = r(N)
		
		di " Proportion of zero test/TTR for `doac' in analysis `num' among non-valvular patients"
		local non_valve_proportionnone = `nonvalve_none' / `non_valve' 
		di `non_valve_proportionnone'
		
		
	}
}

	foreach num in 1 2 3 4 5 {
erase "$pathOutOAC/ttrf0_dose_edoxaban_high_analysis`num'.dta"
erase "$pathOutOAC/ttrf1_dose_edoxaban_high_analysis`num'.dta"
erase "$pathOutOAC/ttrf1_dose_edoxaban_low_analysis`num'.dta"
erase "$pathOutOAC/ttrf0_dose_edoxaban_low_analysis`num'.dta"
}

log close 
