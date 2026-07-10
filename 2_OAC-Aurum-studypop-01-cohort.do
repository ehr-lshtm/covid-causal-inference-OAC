/*=========================================================================
DO FILE NAME:			2_OAC-Aurum-studypop-01-cohort

AUTHOR:					Angel Wong	
						
VERSION:				v1

DATE VERSION CREATED: 	2025-Jul-19
					
DATABASE:				CPRD Dec 2024 build
	
DESCRIPTION OF FILE:	identify the study population

MORE INFORMATION:	
-no uts in newer build Aurum

Steps:
1. Identify AF diagnoses in CPRD & HES
2. Identify study cohort during study period - DOAC group
3. Add the subsequent switching dose date for edoxaban low/high group
4. Identify study cohort during study period - warfarin group
*=========================================================================*/
*capture log close
log using "${pathLogs}/2_OAC-Aurum-studypop-01-cohort-af-dx", text replace
*********************************************************************
/************************************************************************
*************************************************************************
1. Identify AF diagnoses in CPRD & HES
************************************************************************
*************************************************************************/
*AF
forval num = 1/116 {
	use patid obsdate medcodeid using ///
	"$pathRaw/extract/Stata/Observation/Observation_`num'.dta", clear
	merge m:1 medcodeid using "$pathCodelists/aurum_codelist_af", keep(match) nogen
	save "Obs_af_`num'", replace
}

*appending files
use "Obs_af_1", clear
forval i=2/116 {
append using "Obs_af_`i'"
}
gen obsdate2=date(obsdate, "DMY")
format obsdate2 %td
drop obsdate
rename obsdate2 eventdate
save "Obs_af_all", replace

*erase files
forval i=1/116 {
erase "Obs_af_`i'.dta"
}

/*HES*/
use "$pathAulink\hes_diagnosis_epi_25_005220_DM", clear
merge m:1 icd using "$pathCodelists/codelist_af_hes", keep(match) nogen
gen eventdate=date(epistart, "YMD")
format eventdate %td
save "hes_af_all", replace

capture log close
log using "${pathLogs}/2_OAC-Aurum-studypop-01-cohort", text replace
/************************************************************************
*************************************************************************
2. Identify the first AF diagnosis
************************************************************************
*************************************************************************/
use "Obs_af_all", clear
append using "hes_af_all"
sort patid eventdate
cou if eventdate==.
bysort patid: keep if _n==1
keep patid eventdate
rename eventdate eventdate_af
save "$pathOutOAC/af_first_dx", replace

/************************************************************************
*************************************************************************
3. Identify study cohort during study period - DOAC group not edoxaban
* in AF patients on/before their OAC prescription
* No OAC prescription 12 months before cohort entry
************************************************************************
*************************************************************************/
foreach drug in warfarin rivaroxaban apixaban {
	
use "accept_`drug'_define", clear
duplicates drop patid rxst, force

*First OAC prescription (not the first ever) as indexdate
drop if year(rxst) < 2012
di "Number of `drug' users prescribed after 2012"
unique patid

bysort patid: egen min_rxst = min(rxst)
format min_rxst %td
rename min_rxst indexdate
rename rxst `drug'_rxst

*identify the first AF diagnosis before/on the first OAC prescription after 2012
merge m:1 patid using "$pathOutOAC/af_first_dx", keepusing(eventdate_af) keep(match) nogen
keep if eventdate_af!=. & eventdate_af <= indexdate

di "Number of `drug' users with an AF diagnosis prior or on the first prescription since 2012"
unique patid

*Include those aged 18 years or older
*merge the mob yob from denominator file
merge m:1 patid using "$pathRaw/extract/Stata/Patient_all.dta", keep(master match) keepusing(pracid yob mob regstartdate cprd_ddate regenddate) nogen

gen regstd=date(regstartdate, "DMY")
gen regend=date(regenddate, "DMY")
format regstd regend %td
drop regstartdate regenddate
rename regstd regstartdate
rename regend regenddate

*Generating date of birth*
destring mob, replace
destring yob, replace
gen day_birth=1  // Setting birth day to the first when missing
replace mob=7 if mob==0 | mob==. // Setting birth month to July when missing
gen dob=mdy(mob, day_birth, yob)
format dob %td
drop day_birth mob yob
label var dob DOB

*Generate variable of age at index date
gen age_index=(indexdate-dob)/365.25
label var age "Age at time of first prescription"
keep if age_index>=18
di "Number of `drug' users >=18 years at cohort entry"
unique patid

duplicates drop patid, force

*find those with other OAC prescription within 360 days prior to/on the first prescription
preserve
	merge 1:m patid using "accept_`drug'_otheroac", keep(master match) keepusing(rxst) nogen
	keep if rxst!=. & indexdate-360<=rxst & rxst<=indexdate
	keep patid
	duplicates drop patid, force 
	di "Number of people in remove_`drug'_otheroac"
	unique patid
	save "remove_`drug'_otheroac", replace
restore

*remove those who had these other OAC prescription 360 days prior to/on the first prescription
merge 1:1 patid using "remove_`drug'_otheroac", keep(master) nogen
di "Number of `drug' users who had other OAC prescription 360 days prior"
unique patid

*find those with same OAC within 360 days prior to the first prescription
preserve
	merge 1:m patid using "accept_`drug'_define", keep(master match) keepusing(rxst) nogen
	keep if rxst!=. & indexdate-360<=rxst & rxst<indexdate
	keep patid
cap	duplicates drop patid, force 
	di "Number of people in remove_`drug'"
cap	unique patid
	save "remove_`drug'", replace
restore

*remove those who had the same OAC prescription 360 days prior to the first prescription
merge 1:1 patid using "remove_`drug'", keep(master) nogen
di "Number of `drug' users who had same OAC prescription 360 days prior"
unique patid

/*key practice details*/
merge m:1 pracid using "J:\EHR Share\3 Database guidelines and info\CPRD Aurum\Denominator files\2024_12\202412_CPRDAurum_Practices.dta", keepusing(lcd) keep(master match) nogen

gen lcd2=date(lcd, "DMY")
format lcd2 %td
drop lcd
rename lcd2 lcd

/*key date of death from ONS (more accurate than CPRD)*/
merge 1:1 patid using "$pathOutOAC/ons_death_date.dta", keep(master match) keepusing(dod) nogen

*find the subsequent another anticoagulant prescription after the first prescription
preserve
merge 1:m patid using "accept_`drug'_otheroac", keep(master match) keepusing(rxst) nogen
drop if rxst!=. & rxst<=indexdate
bysort patid: egen txswitch=min(rxst)
format txswitch %td
duplicates drop patid, force
keep patid txswitch
keep if txswitch !=.
save "`drug'_cohort_txswitch", replace
restore

*key the treatment switching date to the cohort
merge m:1 patid using "`drug'_cohort_txswitch", keep(master match) keepusing(txswitch) nogen

* find the discontinuation date (at 30 days after the expected end date of any prescription, where the gap between the expected prescription end date and the start date of any subsequent prescription was >30 days)
merge 1:m patid using "`drug'_Rx_calc_dur_final", keep(master match) keepusing(rxen) nogen
replace rxen = . if rxen<indexdate
bysort patid: egen min_rxen = min(rxen)
format min_rxen %td
sort patid indexdate
bysort patid: keep if _n==1
gen discontinue_date= min_rxen + 30
format discontinue_date %td

drop rxen min_rxen

*set up study start and end date for each patient
gen startdate=max(st_st, regstartdate+365)
gen enddate=min(st_en, lcd, dod, regenddate, txswitch-1, discontinue_date)
format startdate enddate %td
label var enddate "date of end of follow-up"

*remove those study end date occurred before study start date
drop if enddate<startdate 
unique patid
drop if indexdate<startdate 
unique patid
drop if indexdate>enddate

di "Number of `drug' users in final cohort"
unique patid
 
keep patid indexdate eventdate_af regstartdate regenddate age_index lcd dod txswitch discontinue_date startdate enddate

save "$pathOutOAC/`drug'_study_cohort", replace
}
/************************************************************************
*************************************************************************
4. Identify study cohort during study period - edoxaban only
* in AF patients on/before their OAC prescription
* No OAC prescription 12 months before cohort entry
* considering removing other doses 360 days prior
************************************************************************
*************************************************************************/
foreach drug in edoxaban_low edoxaban_high {
	
use "accept_`drug'_define", clear
duplicates drop patid rxst, force

*First OAC prescription (not the first ever) as indexdate
drop if year(rxst) < 2012
di "Number of `drug' users prescribed after 2012"
unique patid

bysort patid: egen min_rxst = min(rxst)
format min_rxst %td
rename min_rxst indexdate
rename rxst `drug'_rxst

*identify the first AF diagnosis before/on the first OAC prescription after 2012
merge m:1 patid using "$pathOutOAC/af_first_dx", keepusing(eventdate_af) keep(match) nogen
keep if eventdate_af!=. & eventdate_af <= indexdate

di "Number of `drug' users with an AF diagnosis prior or on the first prescription since 2012"
unique patid

*Include those aged 18 years or older
*merge the mob yob from denominator file
merge m:1 patid using "$pathRaw/extract/Stata/Patient_all.dta", keep(master match) keepusing(pracid yob mob regstartdate cprd_ddate regenddate) nogen

gen regstd=date(regstartdate, "DMY")
gen regend=date(regenddate, "DMY")
format regstd regend %td
drop regstartdate regenddate
rename regstd regstartdate
rename regend regenddate

*Generating date of birth*
destring mob, replace
destring yob, replace
gen day_birth=1  // Setting birth day to the first when missing
replace mob=7 if mob==0 | mob==. // Setting birth month to July when missing
gen dob=mdy(mob, day_birth, yob)
format dob %td
drop day_birth mob yob
label var dob DOB

*Generate variable of age at index date
gen age_index=(indexdate-dob)/365.25
label var age "Age at time of first prescription"
keep if age_index>=18
di "Number of `drug' users >=18 years at cohort entry"
unique patid

duplicates drop patid, force

*find those with other OAC prescription within 360 days prior to/on the first prescription
preserve
	merge 1:m patid using "accept_`drug'_otheroac", keep(master match) keepusing(rxst) nogen
	keep if rxst!=. & indexdate-360<=rxst & rxst<=indexdate
	keep patid
	duplicates drop patid, force 
	di "Number of people in remove_`drug'_otheroac"
	unique patid
	save "remove_`drug'_otheroac", replace
restore

*remove those who had these other OAC prescription 360 days prior to/on the first prescription
merge 1:1 patid using "remove_`drug'_otheroac", keep(master) nogen
di "Number of `drug' users who had other OAC prescription 360 days prior"
unique patid

*find those with same OAC within 360 days prior to the first prescription
preserve
	merge 1:m patid using "accept_`drug'_define", keep(master match) keepusing(rxst) nogen
	keep if rxst!=. & indexdate-360<=rxst & rxst<indexdate
	keep patid
cap	duplicates drop patid, force 
	di "Number of people in remove_`drug'"
cap	unique patid
	save "remove_`drug'", replace
restore

*remove those who had the same OAC prescription 360 days prior to the first prescription
merge 1:1 patid using "remove_`drug'", keep(master) nogen
di "Number of `drug' users who had same OAC prescription 360 days prior"
unique patid

*find those with same edoxaban but other doses within 360 days prior to the first prescription
preserve
	merge 1:m patid using "accept_`drug'_otherdose", keep(master match) keepusing(rxst) nogen
	keep if rxst!=. & indexdate-360<=rxst & rxst<indexdate
	keep patid
cap	duplicates drop patid, force 
	di "Number of people in remove_`drug'_otherdose"
cap	unique patid
	save "remove_`drug'_otherdose", replace
restore

*remove those same edoxaban but other doses 360 days prior to the first prescription
merge 1:1 patid using "remove_`drug'_otherdose", keep(master) nogen
di "Number of `drug' users who had edoxaban other doses 360 days prior"
unique patid

/*key practice details*/
merge m:1 pracid using "J:\EHR Share\3 Database guidelines and info\CPRD Aurum\Denominator files\2024_12\202412_CPRDAurum_Practices.dta", keepusing(lcd) keep(master match) nogen

gen lcd2=date(lcd, "DMY")
format lcd2 %td
drop lcd
rename lcd2 lcd

/*key date of death from ONS (more accurate than CPRD)*/
merge 1:1 patid using "$pathOutOAC/ons_death_date.dta", keep(master match) keepusing(dod) nogen

*find the subsequent another anticoagulant prescription after the first prescription
preserve
merge 1:m patid using "accept_`drug'_otheroac", keep(master match) keepusing(rxst) nogen
drop if rxst!=. & rxst<=indexdate
bysort patid: egen txswitch=min(rxst)
format txswitch %td
duplicates drop patid, force
keep patid txswitch
keep if txswitch !=.
save "`drug'_cohort_txswitch", replace
restore

*key the treatment switching date to the cohort
merge m:1 patid using "`drug'_cohort_txswitch", keep(master match) keepusing(txswitch) nogen

* find the discontinuation date (at 30 days after the expected end date of any prescription, where the gap between the expected prescription end date and the start date of any subsequent prescription was >30 days)
merge 1:m patid using "`drug'_Rx_calc_dur_final", keep(master match) keepusing(rxen) nogen
replace rxen = . if rxen<indexdate
bysort patid: egen min_rxen = min(rxen)
format min_rxen %td
sort patid indexdate
bysort patid: keep if _n==1
gen discontinue_date= min_rxen + 30
format discontinue_date %td

drop rxen min_rxen

*set up study start and end date for each patient
gen startdate=max(st_st, regstartdate+365)
gen enddate=min(st_en, lcd, dod, regenddate, txswitch-1, discontinue_date)
format startdate enddate %td
label var enddate "date of end of follow-up"

*remove those study end date occurred before study start date
drop if enddate<startdate 
unique patid
drop if indexdate<startdate 
unique patid
drop if indexdate>enddate

di "Number of `drug' users in final cohort"
unique patid
 
keep patid indexdate eventdate_af regstartdate regenddate age_index lcd dod txswitch discontinue_date startdate enddate

save "$pathOutOAC/`drug'_study_cohort", replace
}

***************************************************
*5. Remove those who had same date of low/high dose in the low dose group (assuming they have high dose instead)
***************************************************
use "$pathOutOAC/edoxaban_low_study_cohort", clear
rename indexdate indexdate_low
unique patid
merge 1:1 patid using "$pathOutOAC/edoxaban_high_study_cohort", keepusing(indexdate) keep(master match) nogen
drop if indexdate_low == indexdate

di "Number of edoxaban_low users in final cohort after removing having same index date with high dose group"
unique patid
drop indexdate
rename indexdate_low indexdate
save "$pathOutOAC/edoxaban_low_study_cohort", replace

***************************************************
*6. Add switching to low/high/switching dose date in edoxaban group
***************************************************
foreach drug in edoxaban_low edoxaban_high {
	use "$pathOutOAC/`drug'_study_cohort", clear
	
	di "Number of `drug' users before considering switching dose"
	unique patid
	
	*key other doses dataset to this
	preserve
	merge 1:m patid using "accept_`drug'_otherdose", keepusing(rxst other_doselvl) keep(master match) nogen
	drop if rxst!=. & rxst<indexdate
	drop if rxst == .
	bysort patid: egen doseswitch=min(rxst)
	format doseswitch %td
	keep if doseswitch == rxst
	gsort patid rxst -other_doselvl
	di "Check below if any `drug' users who had multiple doses on the same doseswitch date" in red
	unique patid
	bysort patid: keep if _n==1
	keep patid doseswitch
	keep if doseswitch !=.
	save  "`drug'_cohort_doseswitch", replace
	restore

*key the treatment switching date to the cohort
merge m:1 patid using "`drug'_cohort_doseswitch", keep(master match) keepusing(doseswitch) nogen
	
*add new study end date for each patient
gen enddate_new=min(enddate, doseswitch)
format enddate_new %td
label var enddate_new "final date of end of follow-up"

*remove those study end date occurred before study start date
drop if enddate_new<startdate 
unique patid
drop if indexdate<startdate 
unique patid
drop if indexdate>enddate_new

di "Number of `drug' users in final cohort after considering switching dose"
unique patid
 
keep patid indexdate eventdate_af regstartdate regenddate age_index lcd dod txswitch discontinue_date startdate enddate enddate_new doseswitch

save "$pathOutOAC/`drug'_study_cohort_dose", replace
}

log close
