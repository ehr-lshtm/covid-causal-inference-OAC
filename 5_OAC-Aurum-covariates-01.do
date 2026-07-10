/*=========================================================================
DO FILE NAME:			5_OAC-Aurum-covariates-01

AUTHOR:					Angel Wong
VERSION:				v1
DATE VERSION CREATED:	2025-Aug-12
					
DATABASE:				CPRD Aurum 2024 Dec build

DESCRIPTION OF FILE and DATASETS CREATED:

Aim:
Derive all COVARIATES:
1. Age
2. Sex
3. deprivation
4. region
5. BMI
6. Smoking
7. alcohol consumption
8. ethnicity
9. systolic BP
10. number of GP visits
11. bleeding disorders
12. cancer
13. chronic liver disease or pancreatitis
14. COPD
15. chronic renal disease
16. heart failure
17. coronary heart disease
18. peripheral arteral disease
19. diabetes
20. hypertension
21. previous ischaemic stroke or transient ischaemic attack
22. oesophageal varices
23. peptic ulcer
24. valvular heart disease
25. venous thromboembolism
26. previous bleed (including intracranial, haematuria, haemoptysis, or gastrointestinal)
27. falls/hip fractures and hip/knee replacement operations 6 months before cohort entry)
28. proton pump inhibitors
29. macrolides
30. antiplatelets
31. antidepressants
32. anticonvulsants
33. non-steroidal anti-inflammatory drugs
34. corticosteroids
35. amiodarone
36. angiotensin-converting enzyme inhibitors
37. angiotensin receptor blockers
38. beta-blockers
39. calcium channel blockers
40. statins
41. polypharmacy 
42. Oestrogens will also be included for the analysis of venous thromboembolism
*=============================================================================*/

/*******************************************************************************
>> HOUSEKEEPING
*******************************************************************************/
capture log close

/*******************************************************************************
Identify file locations
*******************************************************************************/
* create a filename global that can be used throughout the file
global filename "5_OAC-Aurum-covariates-01"

* open log file - no need as fast tool will create log files
log using "${pathLogs}/${filename}", text replace

************************************************
/*** AGE and SEX
************************************************/
foreach drug in warfarin rivaroxaban apixaban edoxaban_low edoxaban_high { 

use "$pathOutOAC/`drug'_study_cohort", clear
merge 1:1 patid using "$pathRaw/extract/Stata/Patient_all.dta", keep(match) nogen keepusing(pracid gender) 

gen male = 1 if gender == "1"
replace male = 0 if gender == "2"

drop gender

label var male "Male sex"

* Create categorised age
gen     agegroup=1 if age_index>=18 & age_index<40
replace agegroup=2 if age_index>=40 & age_index<50
replace agegroup=3 if age_index>=50 & age_index<60
replace agegroup=4 if age_index>=60 & age_index<70
replace agegroup=5 if age_index>=70 & age_index<80
replace agegroup=6 if age_index>=80
replace agegroup=. if age_index==.

label var agegroup "Age group"

label define agegroup 	1 "18-<40" ///
						2 "40-<50" ///
						3 "50-<60" ///
						4 "60-<70" ///
						5 "70-<80" ///
						6 "80+"
						
label values agegroup agegroup

/************************
*No of GP visits
*************************/
merge 1:m patid using "`drug'_GP_consult_1y", keepusing(consdate) keep(master match) nogen

* remove duplicates for same consultation date within each person
duplicates drop patid consdate, force

* mark those with consultation date within 1 year before indexdate
gen cons_1y = 1 if consdate!=. & indexdate-365<=consdate & consdate<indexdate 
replace cons_1y = 0 if cons_1y == .

bysort patid: egen gpvisit_num = total(cons_1y)
duplicates drop patid, force
drop consdate cons_1y

label var gpvisit_num "Number of GP consultation"

* Create category for GP active consultation
gen gpvisit_cat = 2 if gpvisit_num == 0 
replace gpvisit_cat = 1 if gpvisit_num > 0 & gpvisit_num <12
replace gpvisit_cat = 0 if gpvisit_num >= 12

label var gpvisit_cat "Category of GP consultation"

************************************************
*** CALENDAR PERIODS at cohort entry
************************************************
gen calendar_year=year(indexdate) 

tab calendar_year,m

label var calendar_year "Calendar year at cohort entry"

************************************************
*** MERGE IN LIFESTYLE FACTORS
************************************************
************************
*** SMOKING STATUS
************************
merge 1:1 patid using "$pathOutOAC/aurum_`drug'_smoke", keep(match master) nogen keepusing(smokstatus) 

************************
*** BMI 
************************
merge 1:1 patid using "$pathOutOAC/aurum_`drug'_bmi", keep(match master) nogen keepusing(bmicat)

label var bmicat "BMI category"

************************
*** ALCOHOL STATUS
************************
merge 1:1 patid using "$pathOutOAC/aurum_`drug'_alc", keep(match master) nogen keepusing(alcstatus alclevel)

label var alcstatus "Alcohol status"
label var alclevel "Alcohol level"

*Create a new variable to regroup alcohol
gen alcohol = 0 	if alcstatus != . & alcstatus == 0
replace alcohol = 1 if alcstatus != . & alclevel != . & alcstatus == 1 & alclevel == 1
replace alcohol = 2 if alcstatus != . & alclevel != . & alcstatus == 1 & alclevel == 2
replace alcohol = 3 if alcstatus != . & alclevel != . & alcstatus == 1 & alclevel == 3
replace alcohol = 4 if alcstatus != . & alcstatus == 1 & alclevel == .
replace alcohol = 5 if alcstatus == 2
replace alcohol = 6 if alcstatus == .

label var alcohol "Alcohol status with consumption information"
label def alcohol_lbl 0 "Non-drinker" 1 "Current low level" 2 "Current medium level" ///
						3 "Current high level" 4 "Current without consumption data" ///
						5 "Ex-drinker" 6 "Missing alcohol status"
						
label val alcohol alcohol_lbl

replace alcohol = . if alcohol == 6

************************
*** BP (choose the most recent BP measurement within 12 months before indexdate)
************************
merge 1:1 patid using "$pathOutOAC/aurum_`drug'_bp_1y", ///
keepusing(systolic_bp diastolic_bp) keep(master match) nogen

************************
*ESRD
************************
merge 1:1 patid using "$pathOutOAC/aurum_`drug'_eGFR_1y", ///
keepusing(ckd SCr) keep(master match) nogen

* ESRD
merge 1:1 patid using "$pathOutOAC/ESRD_min", keepusing(esrd) keep(match master) nogen 

rename esrd eventdate

* ESRD Baseline status at indexdate 
gen esrd_base=0
replace esrd_base = 1 if eventdate!= . & eventdate <= indexdate
label var esrd_base "ESRD prevalence at first drug initation date"
drop eventdate

* ESRD = stage 5
replace ckd = 5 if esrd_base == 1

* Generate a variable for CKD
gen ckd_base = 1 if ckd == 2 | ckd == 3 | ckd == 4 | ckd == 5
replace ckd_base = 0 if ckd_base == .

label var ckd_base "CKD prevalence at first drug initation date"

************************
*** Deprivation
************************
* Patient-level Index of Multiple Deprivation
merge 1:1 patid using "$pathAulink/patient_2019_imd_25_005220", keep(match master) keepusing(e2019_imd_5) nogen //no linkage for some people

rename e2019_imd_5 imd
destring imd, replace
count if imd == .
tab imd, m

* Practice-level Index of Multiple Deprivation
merge m:1 pracid using "$pathAulink/practice_imd_25_005220", keep(master match) keepusing(e2019_imd_5) nogen
destring e2019_imd_5, replace
replace imd = e2019_imd_5 if imd == .
tab imd, m

drop e2019_imd_5

* Index of multiple deprivation quintile
label var imd "SES quintiles based on the area of residence through linkage to the Index of Multiple Deprivation (IMD, version 2019)"
label define vSES 1 "Quintile 1 (low)" 2 "Quintile 2" 3 "Quintile 3" 4 "Quintile 4" 5 "Quintile 5 (high)"
label values imd vSES

************************************************
*** MERGE IN COMORBIDITY
************************************************
foreach comorbid in copd liver_pancreatitis bleeding_disorder oesophageal_varices ///
			common_cancer hip_fracture previous_bleed hf ihd peptic_ulcer ///
			 pad dm hypertension heart_valve_disease {
					
merge 1:m patid using "$pathOutOAC/Obs_`comorbid'_all", keepusing(eventdate) keep(match master) nogen 
gen `comorbid' = 1 if eventdate!=. & eventdate <= indexdate
bysort patid: egen `comorbid'_base = max(`comorbid')
duplicates drop patid, force
replace `comorbid'_base = 0 if `comorbid'_base == .
drop eventdate `comorbid'

label var `comorbid'_base "`comorbid' prevalence at cohort entry"
}

foreach comorbid in stroke vte {			
merge 1:m patid using "Obs_`comorbid'_all", keepusing(obsdate) keep(match master) nogen 
rename obsdate eventdate
gen `comorbid' = 1 if eventdate!=. & eventdate <= indexdate
bysort patid: egen `comorbid'_base = max(`comorbid')
duplicates drop patid, force
replace `comorbid'_base = 0 if `comorbid'_base == .
drop eventdate `comorbid'

label var `comorbid'_base "`comorbid' prevalence at cohort entry"
}

************************************************
*** MERGE IN fall/fracture in the past 6 months
************************************************
merge 1:m patid using "$pathOutOAC/aurum_`drug'_fallfracture_6m", keepusing(eventdate) keep(match master) nogen 
gen fracture_base = 1 if eventdate!=. & indexdate-180<=eventdate & eventdate<=indexdate
replace fracture_base = 0 if fracture_base == .
drop eventdate

label var fracture "fracture on or 180 days before cohort entry"

************************
*** Prescriptions ever used in past 6 months
************************
foreach comed in ppi corticosteroid macrolide antiplatelet ssri_snri anticonvulsant_bleed ///
 diazepam nsaid amiodarone acei arb betablocker ccb statin oestrogen_like {
				
merge 1:m patid using "$pathOutOAC/aurum_`comed'_all", keepusing(issuedate) keep(match master) nogen 
rename issuedate eventdate
gen `comed'_past = 1 if eventdate!=. & indexdate-180<=eventdate & eventdate<=indexdate
bysort patid: egen `comed' = max(`comed'_past)
duplicates drop patid, force
replace `comed' = 0 if `comed' == .
drop eventdate `comed'_past

label var `comed' "`comed' use at cohort entry"

}

************************
*Ethnicity
************************
merge 1:1 patid using "$pathOutOAC/ethnicity_final", keepusing(eth5) keep(master match) nogen

label var eth5 "Ethnicity"

************************
*Region
************************
merge m:1 pracid using "$pathRaw/extract/Stata/Practice_all.dta", keep(master match) nogen keepusing(region)

label var region "Region"

************************
*Polypharmacy 
************************
merge 1:1 patid using "$pathOutOAC/aurum_`drug'_polypharmacy", ///
keepusing(polypharmacy_main polypharmacy_sens polypharmacy_degree_main polypharmacy_degree_sens) keep(master match) nogen


************************
*** Save final datasets
************************
save "$pathOutOAC/aurum_`drug'_covariate", replace

}

************************
*Create files to combine all the exposure groups
************************
*rivaroxaban
	use "$pathOutOAC/aurum_warfarin_covariate", clear
	gen exposure = 0
	append using "$pathOutOAC/aurum_rivaroxaban_covariate"
	replace exposure = 1 if exposure == .
	
	label var exposure "exposure groups"
	label def exposure 0 "warfarin" 1 "rivaroxaban" 
	label val exposure exposure

	save "$pathOutOAC/aurum_rivaroxaban_covariate_final", replace
	
*apixaban
	use "$pathOutOAC/aurum_warfarin_covariate", clear
	gen exposure = 0
	append using "$pathOutOAC/aurum_apixaban_covariate"
	replace exposure = 1 if exposure == .
	
	label var exposure "exposure groups"
	label def exposure 0 "warfarin" 1 "apixaban" 
	label val exposure exposure

	save "$pathOutOAC/aurum_apixaban_covariate_final", replace
	
*edoxaban_high
	use "$pathOutOAC/aurum_warfarin_covariate", clear
	gen exposure = 0
	append using "$pathOutOAC/aurum_edoxaban_high_covariate"
	replace exposure = 1 if exposure == .
	
	label var exposure "exposure groups"
	label def exposure 0 "warfarin" 1 "high dose edoxaban" 
	label val exposure exposure

	save "$pathOutOAC/aurum_edoxaban_high_covariate_final", replace

*edoxaban_low
	use "$pathOutOAC/aurum_warfarin_covariate", clear
	gen exposure = 0
	append using "$pathOutOAC/aurum_edoxaban_low_covariate"
	replace exposure = 1 if exposure == .
	
	label var exposure "exposure groups"
	label def exposure 0 "warfarin" 1 "low dose edoxaban" 
	label val exposure exposure

	save "$pathOutOAC/aurum_edoxaban_low_covariate_final", replace

log close
