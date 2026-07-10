/*=========================================================================
DO FILE NAME:			1_OAC-Aurum-studypop-01-exposure

AUTHOR:					Angel Wong	
						
VERSION:				v1

DATE VERSION CREATED: 	2025-Jul-19
					
DATABASE:				CPRD Dec 2024 build
	
DESCRIPTION OF FILE:	identify the DOAC exposure and deal with doses & duration

MORE INFORMATION:	
-no uts in newer build Aurum

Steps:
1. To identify all prescriptions using define files
2. Identify acceptable patients during study period
3. Check edoxaban doses
4. deal with duration and discontinuous treatment dates
*=========================================================================*/
capture log close
log using "${pathLogs}/1_OAC-Aurum-studypop-01-cohort-extract_individual_doac", text replace
*********************************************************************

set max_memory 150g
*********************************************************************
*1. To identify all prescriptions using define files
*********************************************************************
*for warfarin
*combine define files in CPRD Aurum
	use patid issuedate prodcodeid dosageid quantity quantunitid duration using "$pathRaw/define/oac_define_1.dta", clear
	cou
	forval num=2/16 {
		append using "$pathRaw/define/oac_define_`num'.dta"
		keep patid issuedate prodcodeid dosageid quantity quantunitid duration
	merge m:1 prodcodeid using "$pathCodelists/oac_codes_aurum.dta", keepusing(drug) keep(match) nogen
	keep if drug==1
	cou
	}
	save "$pathOutOAC/warfarin_define_all", replace
	
*for rivaroxaban
*combine define files in CPRD Aurum
	use patid issuedate prodcodeid dosageid quantity quantunitid duration using "$pathRaw/define/oac_define_1.dta", clear
	cou
	forval num=2/16 {
		append using "$pathRaw/define/oac_define_`num'.dta"
		keep patid issuedate prodcodeid dosageid quantity quantunitid duration
	merge m:1 prodcodeid using "$pathCodelists/oac_codes_aurum.dta", keepusing(drug) keep(match) nogen
	keep if drug==3
	cou
	}
	save "$pathOutOAC/rivaroxaban_define_all", replace

*for apixaban
*combine define files in CPRD Aurum
	use patid issuedate prodcodeid dosageid quantity quantunitid duration using "$pathRaw/define/oac_define_1.dta", clear
	cou
	forval num=2/16 {
		append using "$pathRaw/define/oac_define_`num'.dta"
		keep patid issuedate prodcodeid dosageid quantity quantunitid duration
	merge m:1 prodcodeid using "$pathCodelists/oac_codes_aurum.dta", keepusing(drug) keep(match) nogen
	keep if drug==4
	cou
	}
	save "$pathOutOAC/apixaban_define_all", replace

*for edoxaban - need doses
*combine define files in CPRD Aurum
	use patid issuedate prodcodeid dosageid quantity quantunitid duration using "$pathRaw/define/oac_define_1.dta", clear
	cou
	forval num=2/16 {
		append using "$pathRaw/define/oac_define_`num'.dta"
		keep patid issuedate prodcodeid dosageid quantity quantunitid duration
	merge m:1 prodcodeid using "$pathCodelists/oac_codes_aurum.dta", keepusing(drug) keep(match) nogen
	keep if drug==5
	cou
	}
	save "$pathOutOAC/edoxaban_define_all", replace
	
cap log close

capture log close
log using "${pathLogs}/1_OAC-Aurum-studypop-01-extract-dabigatran", text replace

foreach drug in dabigatran {

forval num = 1/98 {
use patid issuedate prodcodeid dosageid using "$pathRaw/extract/Stata/DrugIssue/DrugIssue_`num'.dta", clear
merge m:1 prodcodeid using "$pathCodelists/`drug'_codes_aurum", keep(match) keepusing(prodcodeid) nogen
save "aurum_`drug'_`num'", replace
}
}

foreach drug in dabigatran {
*appending files
use "aurum_`drug'_1", clear
forval num=2/98 {
append using "aurum_`drug'_`num'"
}
save "$pathOutOAC/`drug'_define_all", replace
 }
 
foreach drug in dabigatran {
*erase files
forval num=1/98 {
erase "aurum_`drug'_`num'.dta"
}
 }
*/
capture log close

log using "${pathLogs}/1_OAC-Aurum-studypop-01-exposure", text replace
/*********************************************************************
*2. For edoxaban - identify the level of doses
checked: 
1. for ONE TO BE TAKEN EVERY OTHER DAY 
(only 2 patients and from their pattern of other prescriptions: looks like once daily)
2. use proxy for strength if frequency is missing
3. remove those who had a 15mg switching dose before first ever high/low dose edoxaban prescription
*********************************************************************/
*edoxaban
use "$pathOutOAC/edoxaban_define_all", clear
merge m:1 dosageid using "$pathOutOAC/common_dosages.dta", keep(master match) nogen
merge m:1 prodcodeid using "$pathCodelists/oac_codes_aurum.dta", keepusing(substancestrength) keep(master match) nogen
gen strength = substr(substancestrength,1,2)
destring strength, replace
drop substancestrength
destring dose_number,replace
destring daily_dose,replace
tab dosage_text,m

*how many missing daily dose information from dosageid
cou 
cou if missing(daily_dose) 
cou if missing(daily_dose) & (strength == 15 | strength == 30) 
cou if daily_dose!=dose_number & (strength == 15 | strength == 30)

*assign the level of dose group
/* 
1. Use both strength and frequency to determine the dose
-if it's 60mg, unless it's half tablet, it is high dose
-if it's 30mg, twice daily is high dose, once daily is low dose
-if it's 30mg and missing frequency, use strength as proxy so it's low dose
*/
drop if dosage_text == "* NOT ISSUED *" | dosage_text == "DO NOT PRESCRIBE" 
gen doselevel = 2 if strength == 60
replace doselevel = 1 if strength == 60 & substr(dosage_text,1,4) == "HALF" 
replace doselevel = 2 if strength == 30 & dose_number == 2
replace doselevel = 2 if strength == 30 & daily_dose == 2
replace doselevel = 1 if strength == 30 & daily_dose == 1 & dose_number == 0
replace doselevel = 1 if strength == 30 & daily_dose == 0 & dose_number == 1
replace doselevel = 1 if strength == 30 & dose_number == 1 & daily_dose == 1
replace doselevel = 1 if strength == 15 & dose_number == 2 & daily_dose == 2
replace doselevel = 1 if substr(dosage_text,1,4) == "30MG" 
replace doselevel = 2 if substr(dosage_text,1,4) == "60MG" 
replace doselevel = 1 if substr(dosage_text,1,24) == "ONE TO BE TAKEN EACH DAY" & strength == 30
replace doselevel = 1 if substr(dosage_text,1,6) == "ONE BD" & strength == 15
replace doselevel = 1 if substr(dosage_text,1,27) == "ONE TO BE TAKEN TWICE A DAY" & strength == 15
replace doselevel = 1 if substr(dosage_text,1,11) == "TWICE A DAY" & strength == 15
replace doselevel = 1 if substr(dosage_text,1,32) == "TWO TO BE TAKEN AS A SINGLE DOSE" & strength == 15
replace doselevel = 0 if doselevel == . & daily_dose!=. & strength == 15
replace doselevel = 0 if strength == 30 & substr(dosage_text,1,4) == "HALF"
replace doselevel = 0 if strength == 30 & substr(dosage_text,1,9) == "TAKE HALF"
replace doselevel = 9 if daily_dose==. & doselevel==.
replace doselevel = 1 if doselevel ==. & strength == 30 // use strength as proxy if no further information and 2 patients has once every other day but looks like once daily
replace doselevel = 1 if doselevel == 9 & strength == 30 // use strength as proxy if no further information
replace doselevel = 0 if doselevel == 9 & strength == 15 // use strength as proxy if no further information

tab doselevel, m 
tab doselevel strength,m col
/*
preserve
keep if strength == 60
tab dosage_text,m
restore
preserve
keep if doselevel==. & dose_number!=. & strength == 30
tab dosage_text,m
restore
preserve
keep if doselevel==. & dose_number!=. & strength == 15
tab dosage_text,m
restore
preserve
keep if doselevel==.
tab dosage_text,m
tab strength,m
restore

*/
label define level 0 "15mg/switching dose" 1 "30mg/low dose" 2 "60mg/high dose" 9 "unkonwn", replace
label values doselevel level

save "$pathOutOAC/edoxaban_dose_define_all", replace

use "$pathOutOAC/edoxaban_dose_define_all", clear
keep if doselevel == 1
keep patid prodcodeid issuedate duration quantity dosageid
save "$pathOutOAC/edoxaban_low_define_all", replace

use "$pathOutOAC/edoxaban_dose_define_all", clear
keep if doselevel == 2
keep patid prodcodeid issuedate duration quantity dosageid
save "$pathOutOAC/edoxaban_high_define_all", replace

use "$pathOutOAC/edoxaban_dose_define_all", clear
keep if doselevel == 0 | doselevel == 9 
keep patid prodcodeid issuedate duration quantity dosageid
save "$pathOutOAC/edoxaban_other_define_all", replace

/************************************************************************
*************************************************************************
3. Identify acceptable patients 
************************************************************************
*************************************************************************/

foreach drug in warfarin rivaroxaban apixaban edoxaban_low edoxaban_high edoxaban_other dabigatran {
	use "$pathOutOAC/`drug'_define_all", clear
	
	di "Number of people had a record of `drug' prescription"
	unique patid
	
	merge m:1 dosageid using "$pathOutOAC/common_dosages.dta", keep(match) keepusing(dosage_text) nogen
	drop if dosage_text == "* NOT ISSUED *" | dosage_text == "DO NOT PRESCRIBE" 
	drop dosage_text

	di "Number of people prescribed `drug' prescription"
	unique patid
	
	merge m:1 patid using "$pathRaw/extract/Stata/Patient_all.dta", keep(master match) keepusing(acceptable) nogen
	keep if acceptable == "1"
	
	gen rxst=date(issuedate, "DMY")
	format rxst %td
	drop issuedate
	
*hes_apc	01/04/1997	31/03/2023 (in coverage Nov 2024)
*ons_death	02/01/1998	03/04/2024 (in coverage Nov 2024)
	gen st_st=mdy(01,01,2012) // study start date
	gen st_en=mdy(03,31,2023) // study end date
	format st_st st_en %td
	
	di "Number of acceptable people prescribed `drug'"
	unique patid
	
	*linked eligibility with HES/ONS 
	merge m:1 patid using "J:\EHR Share\3 Database guidelines and info\CPRD Linkage Source Data Files\Version23\set_23_Source_Aurum\Aurum_enhanced_eligibility_November_2024.dta", ////
	keepusing(hes_apc_e ons_death_e) keep(master match) nogen

tab ons_death_e, miss
tab hes_apc_e, miss
tab ons_death_e hes_apc_e,m
keep if hes_apc_e=="1" | ons_death_e=="1"
	
di "Number of people linked to HES/ONS prescribed `drug'"
unique patid
	
	save "accept_`drug'_define", replace
}	

/************************************************************************
*************************************************************************
4. Generate other OAC datasets for easy data management below
************************************************************************
*************************************************************************/
*for warfarin group
use "accept_dabigatran_define", clear
append using "accept_rivaroxaban_define"
append using "accept_apixaban_define"
append using "accept_edoxaban_low_define"
append using "accept_edoxaban_high_define"
append using "accept_edoxaban_other_define"
keep patid rxst
cou if rxst==.
save "accept_warfarin_otheroac", replace

*for rivaroxaban group
use "accept_dabigatran_define", clear
append using "accept_warfarin_define"
append using "accept_apixaban_define"
append using "accept_edoxaban_low_define"
append using "accept_edoxaban_high_define"
append using "accept_edoxaban_other_define"
keep patid rxst
cou if rxst==.
save "accept_rivaroxaban_otheroac", replace

*for apixaban group
use "accept_dabigatran_define", clear
append using "accept_warfarin_define"
append using "accept_rivaroxaban_define"
append using "accept_edoxaban_low_define"
append using "accept_edoxaban_high_define"
append using "accept_edoxaban_other_define"
keep patid rxst
cou if rxst==.
save "accept_apixaban_otheroac", replace

*for edoxaban low dose group (for other doses would be dealt with later)
use "accept_dabigatran_define", clear
append using "accept_warfarin_define"
append using "accept_rivaroxaban_define"
append using "accept_apixaban_define"
keep patid rxst
cou if rxst==.
save "accept_edoxaban_low_otheroac", replace

*for edoxaban high dose group (for other doses would be dealt with later)
use "accept_dabigatran_define", clear
append using "accept_warfarin_define"
append using "accept_rivaroxaban_define"
append using "accept_apixaban_define"
keep patid rxst
cou if rxst==.
save "accept_edoxaban_high_otheroac", replace

*for edoxaban low dose group (for other doses)
use "accept_edoxaban_high_define", clear
gen other_doselvl = 2
append using "accept_edoxaban_other_define"
replace other_doselvl = 0 if other_doselvl == .
label var other_doselvl "level of dose"
label define level 0 "15mg/switching dose" 1 "30mg/low dose" 2 "60mg/high dose", replace
label values other_doselvl level
keep patid rxst other_doselvl
cou if rxst==.
duplicates drop patid rxst other_doselvl, force
save "accept_edoxaban_low_otherdose", replace

*for edoxaban high dose group (for other doses)
use "accept_edoxaban_low_define", clear
gen other_doselvl = 1
append using "accept_edoxaban_other_define"
replace other_doselvl = 0 if other_doselvl == .
label var other_doselvl "level of dose"
label values other_doselvl level
keep patid rxst other_doselvl
cou if rxst==.
duplicates drop patid rxst other_doselvl, force
save "accept_edoxaban_high_otherdose", replace

/************************************************************************
*************************************************************************
5. Find discontinued treatment day for each exposure group
************************************************************************
5a Calculate prescription end date for all drugs of interest
see further information above

i. numdays
ii. qty and daily dose
iii. impute a median duration to missing and extreme values
*********************************************************************/
*Only calculate those with oral/injection routes (they are the only ones for inclusion)

foreach drug in warfarin rivaroxaban apixaban edoxaban_low edoxaban_high {
use  "accept_`drug'_define", clear
gen drugname="`drug'"
merge m:1 dosageid using "$pathOutOAC/common_dosages.dta", keep(master match) nogen
drop dosageid
count
destring quantity, replace
destring duration, replace
destring daily_dose, replace
replace quantity=. if quantity<0   //some quantity are negative values


if drugname=="warfarin" {
gen rx_dur=duration if duration>=1 & duration<=90 //preferred numdays than calculation
}

else if drugname=="rivaroxaban" | drugname=="apixaban"| ///
 drugname=="edoxaban_low" | drugname=="edoxaban_high" {
gen rx_dur=duration if duration>=7 & duration<=90 //preferred numdays than calculation
}

di in yellow "distribution of `i' rx duration after considering numdays only"
su rx_dur, detail


*Calculate duration using quantity/daily dose
replace rx_dur=quantity/daily_dose if rx_dur==. 


*Impute median to missing value
if drugname=="warfarin" {
preserve
drop if rx_dur==. 
keep if rx_dur>=1 & rx_dur<=90
su rx_dur, detail
return list
restore
replace rx_dur=r(p50) if rx_dur==. | rx_dur<1 | rx_dur>90
}

else if drugname=="rivaroxaban" | drugname=="apixaban"| ///
 drugname=="edoxaban_low" | drugname=="edoxaban_high" {
preserve
drop if rx_dur==. 
keep if rx_dur>=7 & rx_dur<=90
su rx_dur, detail
return list
restore
replace rx_dur=r(p50) if rx_dur==. | rx_dur<7 | rx_dur>90
}

di in yellow "Any missing value for rx_dur" 
count if rx_dur==.

gen rx_dur2=ceil(rx_dur)
di in green "finalised `i' prescription duration distribution"
su rx_dur2, detail
gen rxen=rxst+rx_dur2-1
format rxen %td

count if rxen<rxst

keep patid rxst rxen

save "$pathOutOAC/`drug'_Rx_dur", replace
}

/*********************************************************************************
5b. Handle overlapping prescriptions
*********************************************************************************/
foreach drug in warfarin rivaroxaban apixaban edoxaban_low edoxaban_high {
use "$pathOutOAC/`drug'_Rx_dur", clear
sort patid rxst rxen
keep patid rxst rxen
by patid: gen episode=_n

rename rxst timerxst
rename rxen timerxen

/************************************************************************
**************************************************************************
Start the steps of handling overlapping by reshaping the data
************************************************************************
*************************************************************************/
reshape long time, i(patid episode) j(start_end) string

*Encode the start and end for ranking the order for "rxst" first
gen start_end2= 0 if start_end=="rxst"
replace start_end2=1 if start_end=="rxen"

by patid (time start_end2), sort: gen int in_proc = sum(start_end == "rxst") - sum(start_end == "rxen")
replace in_proc = 1 if in_proc > 1
by patid (time): gen block_num = 1 if in_proc == 1 & in_proc[_n-1] != 1
by patid (time): replace block_num = sum(block_num)

by patid block_num (time), sort: assert start_end == "rxst" if _n == 1
by patid block_num (time): assert start_end == "rxen" if _n == _N
by patid block_num (time): keep if _n == 1 | _n == _N

drop episode in_proc start_end2
reshape wide time, i(patid block_num) j(start_end) string
rename time* *
order rxst, before(rxen)

by patid: gen episode=_n
keep patid episode rxst rxen

rename rxst timerxst
rename rxen timerxen

reshape long time, i(patid episode) j(start_end) string

gen start_end2= 0 if start_end=="rxst"
replace start_end2=1 if start_end=="rxen"

by patid (time start_end2), sort: gen gap_num = 1 if start_end == "rxst" & (time- time[_n-1]<=30) //change the number of days here
replace gap_num = 1 if start_end == "rxen" & gap_num[_n+1] == 1
egen gap_num_max=max(gap_num), by (patid episode)

keep if (gap_num_max==1 & gap_num==.) | (gap_num==. & gap_num_max ==.)

drop gap_num gap_num_max episode start_end2

*change the episode no as rx for reshaping the wide form
egen rx =seq(), f(1) b(2)
reshape wide time, i(patid rx) j(start_end) string
rename time* *
order rxst, before(rxen)

count 

keep patid rxst rxen

save "`drug'_Rx_calc_dur_final", replace
}

log close
