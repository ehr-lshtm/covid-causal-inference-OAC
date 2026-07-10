/*=========================================================================
DO FILE NAME:			4_OAC-Aurum-extract-01-comorbidities-medications

AUTHOR:					Angel Wong
						
DATE VERSION CREATED:   2025-Jul-30
					
DATABASE:				CPRD Dec 2024 build
												
DESCRIPTION OF FILE:

Aim to identify covariates (comorbidities/co-medication) in Aurum only:
1. comorbidities
2. medications
	
DO FILES NEEDED:	MRC_FQ_Aurum-codelist01-Dec2024build
					
*=========================================================================*/

/*******************************************************************************
>> HOUSEKEEPING
*******************************************************************************/
/*******************************************************************************
Set memory and run programs
*******************************************************************************/
clear all

set max_memory 130g

capture log close 
log using "${pathLogs}/3_OAC-Aurum-extract-01-cprd-outcome", text replace

/*******************************************************************************
#1a. Extract all relevant files for identifying thromboembolic outcomes in CPRD
*******************************************************************************/
*ischaemic stroke, myocardial infarction and venous throboembolism

foreach dx in stroke vte mi {
forval num = 1/116 {
	use patid obsdate medcodeid using ///
	"$pathRaw/extract/Stata/Observation/Observation_`num'.dta", clear
	merge m:1 medcodeid using "$pathCodelists/aurum_codelist_`dx'_final", keep(match) keepusing(incident) nogen
	save "Obs_`dx'_`num'", replace
}
}

*appending files
foreach dx in stroke vte mi {
use "Obs_`dx'_1", clear
forval i=2/116 {
append using "Obs_`dx'_`i'"
}
gen obsdate2=date(obsdate, "DMY")
format obsdate2 %td
drop obsdate
rename obsdate2 obsdate
save "Obs_`dx'_all", replace
}

*key type of stroke (ischaemic/TIA/unspecific)
use "Obs_stroke_all", clear
merge m:1 medcodeid using "$pathCodelists/aurum_codelist_stroke_final", keep(match) keepusing(type) nogen
	save "Obs_stroke_all", replace

*erase files
foreach dx in stroke vte mi {
forval i=1/116 {
erase "Obs_`dx'_`i'.dta"
}
}

log close
*/
capture log close 
log using "${pathLogs}/3_OAC-Aurum-extract-01-HES-ONS-outcome", text replace

/*******************************************************************************
#1b. Extract all relevant files for identifying all outcomes in HES
*In Vinogradova appendix, there are R31X, I64x and I81X in the icd-10 codes
I checked ICD-10 dictionary in J-dive and the HES data for this study
-> no these X codes specified so excluded them from the codelists
*******************************************************************************/
//all the code after 1 d.p. would be included so can simply use icd rather than icdx
*the codelist contain 1 d.p. and all their corresponding 2 d.p. codes
*ischaemic stroke
use "$pathAulink/hes_diagnosis_epi_25_005220_DM", clear
merge m:1 icd using "$pathCodelists/ischaemic_stroke_icd10code", keep(match) nogen
gen eventdate=date(epistart, "YMD")
format eventdate %td
save "$pathOutOAC/hes_ischaemic_stroke_dx.dta", replace

*myocardial infarction
use "$pathAulink/hes_diagnosis_epi_25_005220_DM", clear
merge m:1 icd using "$pathCodelists/codelist_MI_hes", keep(match) keepusing(icd mi_cat) nogen
gen eventdate=date(epistart, "YMD")
format eventdate %td
sort patid eventdate
gen incident = 1 if mi_cat == 3
replace incident = 0 if mi_cat == 1
keep patid eventdate icd incident
save "$pathOutOAC/hes_MI_dx", replace

*VTE
use "$pathAulink/hes_diagnosis_epi_25_005220_DM", clear
merge m:1 icd using "$pathCodelists/vte_icd10code", keep(match) nogen
gen eventdate=date(epistart, "YMD")
format eventdate %td
save "$pathOutOAC/hes_vte_dx.dta", replace

*major bleeding
use "$pathAulink/hes_diagnosis_epi_25_005220_DM", clear
merge m:1 icd using "$pathCodelists/major_bleed_icd10code", keep(match) nogen
gen eventdate=date(epistart, "YMD")
format eventdate %td
save "$pathOutOAC/hes_major_bleed_hx.dta", replace

/*******************************************************************************
#1c. Extract all relevant files for identifying all outcomes in ONS
extract both 1) all COD and 2) underlying COD only
*******************************************************************************/
*Data cleaning for ONS death dataset in MRC_OAC-import01-Aurum.do:
*(Check the earliest date and use that as cause of death
*For those with same death date but different causes of death, keep both)

*stroke, vte, major bleeding
foreach outcome in ischaemic_stroke vte major_bleed {
	use "$pathOutOAC\oac_cod_all.dta", clear
	gen event = 0
forval num = 1/16 {
	rename s_cod_code_`num' alt_code
	merge m:1 alt_code using "$pathCodelists/`outcome'_icd10code", keep(master match) keepusing(alt_code)
	replace event = 1 if _merge == 3
	drop _merge
	rename alt_code s_cod_code_`num'
}
keep if event == 1
drop event
duplicates drop patid, force
save "$pathOutOAC/ons_`outcome'_dx.dta", replace
}


*myocardial infarction
use "$pathOutOAC\oac_cod_all.dta", clear
gen event = 0
forval num = 1/16 {
	rename s_cod_code_`num' alt_code
	merge m:1 alt_code using "$pathCodelists/codelist_MI_hes", keep(master match) keepusing(alt_code)
	replace event = 1 if _merge == 3
	drop _merge
	rename alt_code s_cod_code_`num'
}
keep if event == 1
drop event
duplicates drop patid, force
save "$pathOutOAC/ons_MI_dx", replace


*Underlying cause of death only
*stroke, vte, major bleeding
foreach outcome in ischaemic_stroke vte major_bleed {
	use "$pathOutOAC\oac_cod_all.dta", clear
	rename s_cod_code_16 alt_code //s_cod_code_16 is the underlying COD
	merge m:1 alt_code using "$pathCodelists/`outcome'_icd10code", keep(match) keepusing(alt_code)
duplicates drop patid, force
save "$pathOutOAC/ons_`outcome'_underlyingdx.dta", replace
}


*myocardial infarction
use "$pathOutOAC\oac_cod_all.dta", clear
	rename s_cod_code_16 alt_code //s_cod_code_16 is the underlying COD
	merge m:1 alt_code using "$pathCodelists/codelist_MI_hes", keep(match) keepusing(alt_code)
duplicates drop patid, force
save "$pathOutOAC/ons_MI_underlyingdx", replace

capture log close 
log using "${pathLogs}/4_OAC-Aurum-extract-01-comorbidities", text replace
/*******************************************************************************
#1d. Extract all relevant files for identifying covariates in CPRD
*******************************************************************************/
foreach dx in copd pancreatitis bleeding_disorder oesophageal_varices ///
common_cancer hip_fracture previous_bleed hf ihd peptic_ulcer ///
chronic_liver pad dm hypertension heart_valve_disease {
forval num = 1/116 {
	use patid obsdate medcodeid using ///
	"$pathRaw/extract/Stata/Observation/Observation_`num'.dta", clear
	merge m:1 medcodeid using "$pathCodelists/`dx'_codes_aurum", keep(match) keepusing(medcodeid) nogen
	save "Obs_`dx'_`num'", replace
}
}
foreach dx in falls {
forval num = 1/116 {
	use patid obsdate medcodeid value using ///
	"$pathRaw/extract/Stata/Observation/Observation_`num'.dta", clear
	merge m:1 medcodeid using "$pathCodelists/`dx'_codes_aurum", keep(match) keepusing(medcodeid frequency) nogen
	destring value, replace
	drop if value!=. & value == 0 & frequency == 1 
	drop if value ==. & frequency == 1 
	save "Obs_`dx'_`num'", replace
}
}
foreach dx in esrd_unknownstage {
forval num = 1/116 {
	use patid obsdate medcodeid value using ///
	"$pathRaw/extract/Stata/Observation/Observation_`num'.dta", clear
	merge m:1 medcodeid using "$pathCodelists/`dx'_codes_aurum", keep(match) keepusing(medcodeid ckd) nogen
	destring value, replace
	drop if value!=. & value < 5 & ckd == 9 
	drop if value == . & ckd == 9
	save "Obs_`dx'_`num'", replace
}
}
foreach dx in copd pancreatitis bleeding_disorder oesophageal_varices ///
common_cancer hip_fracture previous_bleed hf ihd peptic_ulcer ///
chronic_liver pad dm hypertension esrd_unknownstage heart_valve_disease falls {
*appending files
use "Obs_`dx'_1", clear
forval i=2/116 {
append using "Obs_`dx'_`i'"
}
gen obsdate2=date(obsdate, "DMY")
format obsdate2 %td
drop obsdate
rename obsdate2 eventdate
save "$pathOutOAC/Obs_`dx'_all", replace
}
*erase files
foreach dx in copd pancreatitis bleeding_disorder oesophageal_varices ///
common_cancer hip_fracture previous_bleed hf ihd peptic_ulcer ///
chronic_liver pad dm hypertension esrd_unknownstage heart_valve_disease falls {
forval i=1/116 {
erase "Obs_`dx'_`i'.dta"
}
}

/*******************************************************************************
#1e. Extract all relevant files for identifying covariates in CPRD/HES
*******************************************************************************/
/*******************************************************************************
Extract CKD codes and creatinine
*******************************************************************************/ 
* Find serum creatinine measures
forval num = 1/116 {
	use patid obsdate value medcodeid numunitid numrangelow numrangehigh using ///
	"$pathRaw/extract/Stata/Observation/Observation_`num'.dta", clear
	merge m:1 medcodeid using "$pathCodelists/SCr_codes_aurum", keep(match) keepusing(medcodeid) nogen
	save "Obs_creatinine_`num'", replace
}

*appending files
use "Obs_creatinine_1", clear
forval i=2/116 {
append using "Obs_creatinine_`i'"
}
gen obsdate2=date(obsdate, "DMY")
format obsdate2 %td
drop obsdate
rename obsdate2 obsdate
save "$pathOutOAC/Obs_creatinine_all", replace

*erase files
forval i=1/116 {
erase "Obs_creatinine_`i'.dta"
}

run "J:\EHR-Working\Angel\Covid_recording\dofiles\OAC\pr_getSCr_Aurum.do"
run "$pathPrograms/prog_getCovariate_HES.do"
run "$pathPrograms/prog_getCovariate_OPCS.do"
run "$pathPrograms/prog_getminESRD_Aurum.do"

* from CPRD serum creatinine & eGFR calculation
noi pr_getSCr_Aurum, ///
	obs_SCrfile("$pathOutOAC/Obs_creatinine_all") ///
	savefile("$pathOutOAC/SCr_eGFR_result") ///
	patientfile("$pathOut/202412_CPRDAurum_AllPats.dta")
	
* from HES diagnoses (icd-10 codes)
prog_getCovariate_HES, ///
	extractfile("$pathAulink/hes_diagnosis_epi_25_005220_DM") ///
	codelist("$pathCodelists/icd10codes-ESRD-aki2") ///
	comorbidity("ESRD") ///
	savefile("$pathOutOAC/ESRD_hes_dx")
	
	use "$pathOutOAC/ESRD_hes_dx", clear
	gen eventdate = date(epistart, "YMD")
	format eventdate %td
	drop epistart	
save "$pathOutOAC/ESRD_hes_dx", replace

* from HES procedures (OPCS codes) 
prog_getCovariate_OPCS, ///
	extractfile("$pathAulink/hes_procedures_epi_25_005220_DM") ///
	codelist("$pathCodelists/opcscodes-ESRD-aki2") ///
	comorbidity("ESRD") ///
	savefile("$pathOutOAC/ESRD_operation")
	
	use "$pathOutOAC/ESRD_operation", clear
	gen eventdate = date(epistart, "YMD")
	format eventdate %td
	drop epistart	
save "$pathOutOAC/ESRD_operation", replace

use "$pathOutOAC/Obs_esrd_unknownstage_all", clear
rename eventdate obsdate
save "$pathOutOAC/Obs_esrd_unknownstage_all", replace
 
*find the earliest ESRD
prog_getminESRD_Aurum, ///
	cprdfile("$pathOutOAC/Obs_esrd_unknownstage_all") ///
	hesfile("$pathOutOAC/ESRD_hes_dx") ///
	opcsfile("$pathOutOAC/ESRD_operation") ///
	egfrfile("$pathOutOAC/SCr_eGFR_result") ///
	savefile("ESRD_all_update") ///
	savefileminESRD("$pathOutOAC/ESRD_min")
	
* No need to identify outcome for this study - erase dataset
erase "ESRD_all_update.dta"

/*******************************************************************************
Identify the latest record of eGFR within 1 year before index date
*******************************************************************************/
foreach drug in warfarin rivaroxaban apixaban edoxaban_low edoxaban_high {
 use "$pathOutOAC/`drug'_study_cohort", clear
 keep patid indexdate
 merge 1:m patid using "$pathOutOAC/SCr_eGFR_result", ///
 keepusing(obsdate SCr SCr_adj egfr ckd) keep(master match) nogen
 keep if obsdate!=. & indexdate-365<=obsdate & obsdate<=indexdate
 gsort patid -obsdate SCr
 by patid: keep if _n==1 
 keep patid obsdate egfr ckd SCr_adj
 save "$pathOutOAC/aurum_`drug'_eGFR_1y", replace
}

/*******************************************************************************
Extract knee and hip operations from opcs
*******************************************************************************/
prog_getCovariate_OPCS, ///
	extractfile("$pathAulink/hes_procedures_epi_25_005220_DM") ///
	codelist("$pathCodelists/hip_knee_codes_opcs") ///
	comorbidity("hipknee_operation") ///
	savefile("$pathOutOAC/hipknee_operation")

use "$pathOutOAC/hipknee_operation", clear
	gen eventdate = date(epistart, "YMD")
	format eventdate %td
	drop epistart	
save "$pathOutOAC/hipknee_operation", replace

*combine all data relevant to falls/hip fractures and hip/knee replacement operations
use "$pathOutOAC/hipknee_operation", clear
append using "$pathOutOAC/Obs_falls_all"
append using "$pathOutOAC/Obs_hip_fracture_all"
cou if eventdate==.
save "$pathOutOAC/hipknee_falls_all", replace

foreach drug in warfarin rivaroxaban apixaban edoxaban_low edoxaban_high {
 use "$pathOutOAC/`drug'_study_cohort", clear
 keep patid indexdate
 merge 1:m patid using "$pathOutOAC/hipknee_falls_all", keep(master match) nogen
 keep if eventdate!=. & indexdate-180<=eventdate & eventdate<=indexdate
 gsort patid -eventdate
 bysort patid: keep if _n==1 
 keep patid eventdate
 save "$pathOutOAC/aurum_`drug'_fallfracture_6m", replace
}

erase "$pathOutOAC/hipknee_falls_all.dta"

capture log close 
log using "${pathLogs}/4_OAC-Aurum-extract-01-medications", text replace

/*******************************************************************************
#2. Extract all relevant files for medications
*******************************************************************************/
foreach drug in ppi corticosteroid macrolide antiplatelet ssri_snri anticonvulsant_bleed ///
 diazepam nsaid amiodarone acei arb betablocker ccb statin oestrogen_like {

forval num = 1/98 {
use patid issuedate prodcodeid using "$pathRaw/extract/Stata/DrugIssue/DrugIssue_`num'.dta", clear
merge m:1 prodcodeid using "$pathCodelists/`drug'_codes_aurum", keep(match) keepusing(prodcodeid) nogen
save "aurum_`drug'_`num'", replace
}
}

foreach drug in ppi corticosteroid macrolide antiplatelet ssri_snri anticonvulsant_bleed ///
 diazepam nsaid amiodarone acei arb betablocker ccb statin oestrogen_like {
*appending files
use "aurum_`drug'_1", clear
forval num=2/98 {
append using "aurum_`drug'_`num'"
}
gen issuedate2=date(issuedate, "DMY")
format issuedate2 %td
drop issuedate
rename issuedate2 issuedate
save "$pathOutOAC/aurum_`drug'_all", replace
 }
 
foreach drug in ppi corticosteroid macrolide antiplatelet ssri_snri anticonvulsant_bleed ///
 diazepam nsaid amiodarone acei arb betablocker ccb statin oestrogen_like {
*erase files
forval num=1/98 {
erase "aurum_`drug'_`num'.dta"
}
 }

capture log close 
log using "${pathLogs}/4_OAC-Aurum-extract-01-GPvisit", text replace
/*******************************************************************************
#3. Extract number of GP visits
*******************************************************************************/
forval num = 1/22 {
	use patid consdate conssourceid using ///
	"$pathRaw/extract/Stata/Consultation/Consultation_`num'.dta", clear
	merge m:1 conssourceid using "$pathCodelists/GPvisits_codes_aurum", keep(match) nogen
	save "Consult_`num'", replace
}
*appending files
use "Consult_1", clear
forval i=2/22 {
append using "Consult_`i'"
}
gen consdate2=date(consdate, "DMY")
format consdate2 %td
drop consdate
rename consdate2 consdate
save "$pathOutOAC/GP_consult_all", replace

*erase files
forval i=1/22 {
erase "Consult_`i'.dta"
}


/*identify GP date 1 year before prescription to minimise data size*/
foreach drug in warfarin rivaroxaban apixaban edoxaban_low edoxaban_high {
use patid consdate using "$pathOutOAC/GP_consult_all", clear
merge m:1 patid using "$pathOutOAC/`drug'_study_cohort", keepusing(indexdate) keep(match) nogen
keep if consdate!=. & indexdate-365<=consdate & consdate<indexdate 
keep patid consdate
save "`drug'_GP_consult_1y", replace
}

cap log close

log using "${pathLogs}/4_OAC-Aurum-extract-01-ethnicity", text replace

/*******************************************************************************
#4. Extract ethincity codes
*******************************************************************************/
* from CPRD Aurum Observation files
foreach dx in ethnicity {
forval num = 1/116 {
	use "$pathRaw/extract/Stata/Observation/Observation_`num'.dta", clear
	merge m:1 medcodeid using "$pathCodelists/`dx'_codes_aurum", keep(match) nogen
	save "Obs_`dx'_`num'", replace
}

*appending files
use "Obs_`dx'_1", clear
forval i=2/116 {
append using "Obs_`dx'_`i'"
}
gen obsdate2=date(obsdate, "DMY")
format obsdate2 %td
drop obsdate
rename obsdate2 obsdate
}
save "$pathOutOAC/Obs_ethnicity_all", replace

run "$pathPrograms/pr_getethnicitystatus_001_aurum"
noi pr_getethnicitystatus_001_aurum, ///
hesfile("$pathAulink/hes_patient_25_005220_DM") savehesfile("$pathOutOAC/hes_ethnicity")

run "J:\EHR-Working\Angel\Covid_recording\dofiles\OAC\pr_getethnicity_002_aurum.do" // use obsdate as enterdate
noi pr_getethnicity_002_aurum, ///
obsfile("$pathOutOAC/Obs_ethnicity_all") ///
 patientfile("$pathRaw/extract/Stata/Patient_all.dta") ///
 hesavailable("1") savecprdfile("$pathOutOAC/aurum_ethnicity")

run "$pathPrograms/pr_getethnicitystatus_003_aurum"
noi pr_getethnicitystatus_003_aurum, savecprdfile("$pathOutOAC/aurum_ethnicity") ///
 savehesfile("$pathOutOAC/hes_ethnicity") savefinalfile("$pathOutOAC/ethnicity_final")

cap log close

use "$pathOutOAC/Obs_chronic_liver_all", clear
append using "$pathOutOAC/Obs_pancreatitis_all"
save "$pathOutOAC/Obs_liver_pancreatitis_all", replace


capture log close 
log using "${pathLogs}/4_OAC-Aurum-extract-01-INR-TTR", text replace
set max_memory 130g
/*******************************************************************************
#1. Extract all relevant files for identifying INR
*******************************************************************************/
*Get all records from Observation file
forval num = 1/116 {
	use patid obsdate numunitid value medcodeid using ///
	"$pathRaw/extract/Stata/Observation/Observation_`num'.dta", clear
	merge m:1 medcodeid using "$pathCodelists/inr_ttr_codes_aurum", keep(match) nogen
	save "Obs_inr_`num'", replace
}


*appending files
use "Obs_inr_1", clear
forval i=2/116 {
append using "Obs_inr_`i'"
}
gen obsdate2=date(obsdate, "DMY")
format obsdate2 %td
drop obsdate
rename obsdate2 obsdate
save "Obs_inr_all", replace

*erase files
forval i=1/116 {
erase "Obs_inr_`i'.dta"
}


capture log close 