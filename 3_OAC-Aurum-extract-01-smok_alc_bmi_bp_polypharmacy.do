/*=========================================================================
DO FILE NAME:			3_OAC-Aurum-extract-01-smok_alc_bmi_bp_polypharmacy

AUTHOR:					Angel Wong
						
DATE VERSION CREATED:   2025-Aug-7
					
DATABASE:				CPRD Dec 2024 build
												
DESCRIPTION OF FILE:

Aim to identify covariates (comorbidities/co-medication):
1. Smoking
2. Alcohol
3. BMI
4. BP
5. Polypharmacy
	
DO FILES NEEDED:	MRC_FQ_Aurum-codelist01-Dec2024build
					
*=========================================================================*/
/*******************************************************************************
Set memory and run programs
*******************************************************************************/
clear all

set max_memory 130g

capture log close 
log using "${pathLogs}/3_OAC-Aurum-extract-01-smoking", text replace
set max_memory 130g
/*******************************************************************************
#1. Extract all relevant files for identifying smoking status
and identify the smoking status at the index date
*******************************************************************************/
*Get all records from Observation file
forval num = 1/116 {
	use patid obsdate numunitid value medcodeid using ///
	"$pathRaw/extract/Stata/Observation/Observation_`num'.dta", clear
	merge m:1 medcodeid using "$pathCodelists/codelist_smoking_codes_aurum", keep(match) keepusing(smokstatus) nogen
	save "Obs_smoke_`num'", replace
}


*appending files
use "Obs_smoke_1", clear
forval i=2/116 {
append using "Obs_smoke_`i'"
}
gen obsdate2=date(obsdate, "DMY")
format obsdate2 %td
drop obsdate
rename obsdate2 obsdate
save "Obs_smoking_all", replace

*erase files
forval i=1/116 {
erase "Obs_smoke_`i'.dta"
}

* Smoking cessation from drug files
forval num = 1/98 {
use patid issuedate prodcodeid using "$pathRaw/extract/Stata/DrugIssue/DrugIssue_`num'.dta", clear
merge m:1 prodcodeid using "$pathCodelists/nicotine_replacement_codes_aurum", keep(match) keepusing(prodcodeid smokstatus) nogen
save "aurum_nicotine_`num'", replace
}

*appending files
use "aurum_nicotine_1", clear
forval num=2/98 {
append using "aurum_nicotine_`num'"
}
gen issuedate2=date(issuedate, "DMY")
format issuedate2 %td
drop issuedate
rename issuedate2 issuedate
save "aurum_Nicotine_replacement_all", replace

*erase files
forval num=1/98 {
erase "aurum_nicotine_`num'.dta"
}

*Get all records in HES indicating smoking status
use "$pathAulink/hes_diagnosis_epi_25_005220_DM", clear
merge m:1 icd using "$pathCodelists/Smoking_ICD", keep(match) nogen
gen eventdate=date(epistart, "YMD")
format eventdate %td
save "hes_ICD_Smoking_Aurum.dta", replace

run "$pathPrograms/pr_getsmokingstatus_Aurum.do"

foreach drug in warfarin rivaroxaban apixaban edoxaban_low edoxaban_high {
 use "$pathOutOAC/`drug'_study_cohort", clear
 keep patid indexdate
 noi pr_getsmokingstatus_Aurum, obsfile("Obs_smoking_all") ///
 icdfile("hes_ICD_Smoking_Aurum.dta") therapyfile("aurum_Nicotine_replacement_all") ///
 smokingstatusvar(smokstatus) index(indexdate) ///
 savefile("$pathOutOAC/aurum_`drug'_smoke")
}

capture log close 
log using "${pathLogs}/3_OAC-Aurum-extract-01-alcohol", text replace

/*******************************************************************************
#2. Extract all relevant files for identifying alcohol consumption
and identify the alcohol consumption status at the index date
*******************************************************************************/
*Get all records from Observation file
forval num = 1/116 {
	use patid obsdate medcodeid numunitid value using ///
	"$pathRaw/extract/Stata/Observation/Observation_`num'.dta", clear
	merge m:1 medcodeid using "$pathCodelists/codelist_alcohol_cprd_aurum", keep(match) nogen
	save "Obs_alc_`num'", replace
}

*appending files
use "Obs_alc_1", clear
forval i=2/116 {
append using "Obs_alc_`i'"
}
gen obsdate2=date(obsdate, "DMY")
format obsdate2 %td
drop obsdate
rename obsdate2 obsdate
save "Obs_alc_all", replace

*erase files
forval i=1/116 {
erase "Obs_alc_`i'.dta"
}

/*Get all records in HES indicating alcohol status*/
use "$pathAulink/hes_diagnosis_epi_25_005220_DM", clear
merge m:1 icd using "$pathCodelists/Alcohol_ICD", keep(match) nogen
gen eventdate=date(epistart, "YMD")
format eventdate %td
drop epistart
rename eventdate epistart
save "hes_ICD_Alcohol_Aurum.dta", replace

/*Get all records in CPRD Aurum indicating antabuse treatment*/
forval num = 1/98 {
use patid issuedate prodcodeid using "$pathRaw/extract/Stata/DrugIssue/DrugIssue_`num'.dta", clear
merge m:1 prodcodeid using "$pathCodelists/antabuse_codes_aurum.dta", keep(match) keepusing(alcstatus alclevel) nogen
save "aurum_antabase_`num'", replace
}

*appending files
use "aurum_antabase_1", clear
forval num=2/98 {
append using "aurum_antabase_`num'"
}
gen issuedate2=date(issuedate, "DMY")
format issuedate2 %td
drop issuedate
rename issuedate2 issuedate
save "aurum_Antabuse_all", replace

*erase files
forval num=1/98 {
erase "aurum_antabase_`num'.dta"
}

foreach drug in warfarin rivaroxaban apixaban edoxaban_low edoxaban_high {
 use "$pathOutOAC/`drug'_study_cohort", clear
 keep patid indexdate
 run "$pathPrograms/pr_getalcoholstatus_Aurum"
 noi pr_getalcoholstatus, obsfile("Obs_alc_all") ///
 numunitfile("$pathCodelists/alcohol_level_aurum")  ///
 icdfile("hes_ICD_Alcohol_Aurum") therapyfile("aurum_Antabuse_all") ///
 alcoholstatusvar(alcstatus) alcohollevelvar(alclevel) ///
 unit_time(unit_time) index(indexdate)
 save "$pathOutOAC/aurum_`drug'_alc", replace
}

capture log close 
log using "${pathLogs}/3_OAC-Aurum-extract-01-bmi", text replace

/*******************************************************************************
#3. Extract all relevant files for identifying body mass index & body weight
and identify the BMI status and weight at the index date
*******************************************************************************/
*Get all records from Observation file
forval num = 1/116 {
	use patid medcodeid value obsdate numunitid using ///
	"$pathRaw/extract/Stata/Observation/Observation_`num'.dta", clear
	merge m:1 medcodeid using "$pathCodelists/bmi_codes_aurum", keep(match) nogen
	save "Obs_bmi_`num'", replace
}

*appending files
use "Obs_bmi_1", clear
forval i=2/116 {
append using "Obs_bmi_`i'"
}
gen obsdate2=date(obsdate, "DMY")
format obsdate2 %td
drop obsdate
rename obsdate2 obsdate
save "Obs_bmi_all", replace

*erase files
forval i=1/116 {
erase "Obs_bmi_`i'.dta"
}

/**************
* BMI status
*****************/
run "$pathPrograms/pr_getallbmirecords_Aurum.do"
run "$pathPrograms/pr_getbmistatus_Aurum.do"

foreach drug in warfarin rivaroxaban apixaban edoxaban_low edoxaban_high {
 use "$pathOutOAC/`drug'_study_cohort", clear
 keep patid indexdate
 noi pr_getbmistatus_Aurum, obsfile("Obs_bmi_all") ///
 patientfile("$pathOut\202412_CPRDAurum_AllPats.dta") ///
 numunitfile("$pathOut\NumUnit") index(indexdate)
 save "$pathOutOAC/aurum_`drug'_bmi", replace
}

log close

capture log close 
log using "${pathLogs}/3_OAC-Aurum-extract-01-bp", text replace

/*******************************************************************************
#4. Extract all relevant files for identifying blood pressure
*******************************************************************************/
run "$pathPrograms/pr_getbloodpressure_Aurum.do"

pr_getbloodpressure_Aurum, ///
 obsfile("$pathRaw/extract/Stata/Observation/Observation") ///
 obsfilesnum(116)  ///
 bp_codelist("$pathCodelists/bp_codes_aurum") ///
 savefile("Aurum_bp_all_update")

foreach drug in warfarin rivaroxaban apixaban edoxaban_low edoxaban_high {
 use "$pathOutOAC/`drug'_study_cohort", clear
 keep patid indexdate
 merge 1:m patid using "Aurum_bp_all_update", keep(master match) nogen
 keep if eventdate!=. & indexdate-365<=eventdate & eventdate<=indexdate
 gsort patid -eventdate
 by patid: keep if _n==1 
 save "$pathOutOAC/aurum_`drug'_bp_1y", replace
}

capture log close 
log using "${pathLogs}/3_OAC-Aurum-extract-01-polypharmacy", text replace

/*******************************************************************************
#5. Extract all relevant files for identifying polypharmacy
*******************************************************************************/
run "$pathPrograms/pr_getpolypharmacy_records_Aurum.do"

foreach drug in warfarin rivaroxaban apixaban edoxaban_low edoxaban_high {
noi pr_getpolypharmacy_records_Aurum, drugdictionary("$pathBrowsers/CPRDAurumProduct.txt") ///
 cohortfile("$pathOutOAC/`drug'_study_cohort") ///
 drugfile("DrugIssue") ///
 drugfilepart("$pathRaw/extract/Stata/DrugIssue") ///
 drugfilesnum(98) lookbackwindow(90) savefile("$pathOutOAC/aurum_`drug'_polypharmacy_record") ///
 index(indexdate)
}

run "$pathPrograms/pr_getpolypharmacy_status_Aurum"

foreach drug in warfarin rivaroxaban apixaban edoxaban_low edoxaban_high {
   	use "$pathOutOAC/aurum_`drug'_polypharmacy_record", clear
noi pr_getpolypharmacy_status_Aurum, cohortfile("$pathOutOAC/`drug'_study_cohort") ///
 savefile("$pathOutOAC/aurum_`drug'_polypharmacy") 
}
   
*delete records   
foreach drug in warfarin rivaroxaban apixaban edoxaban_low edoxaban_high {
erase "$pathOutOAC/aurum_`drug'_polypharmacy_record.dta"
 }

 log close
 
erase Obs_smoking_all.dta
erase aurum_Nicotine_replacement_all.dta 
erase Obs_alc_all.dta
erase aurum_Antabuse_all.dta
erase Obs_bmi_all.dta
erase Aurum_bp_all_update.dta