/*=========================================================================
DO FILE NAME:			11_OAC-Aurum-descriptive-02-others

AUTHOR:					Angel Wong
VERSION:				v1
DATE VERSION CREATED:	19 Aug 2025
					
DATABASE:				CPRD Dec 2024 build

Aim:
describe in each analysis
1. Proportion of days covered
2. loss to follow up due to deregistration
3. Time between AF diagnosis and initiation of first OAC
4. Drug switching/change dose
5. median follow-up between groups

PDC based on https://joppp.biomedcentral.com/articles/10.1186/s40545-021-00385-w
denominator: 180 days or other censoring date (except discontinuation)
nominator: all the prescription start and end date within 180 days
*=============================================================================*/

/*******************************************************************************
>> HOUSEKEEPING
*******************************************************************************/
capture log close

/*******************************************************************************
Identify file locations
*******************************************************************************/
* create a filename global that can be used throughout the file
global filename "11_OAC-Aurum-descriptive-02-others"

* open log file - no need as fast tool will create log files
log using "${pathLogs}/${filename}", text replace

/*******************************************************************************
*1. Proportion of days covered
*******************************************************************************/
*Analysis 1

*rivaroxaban and apixaban
foreach oac in rivaroxaban apixaban warfarin {
	use "$pathOutOAC/aurum_`oac'_covariate", clear
	gen st_en=mdy(03,31,2023) // study end date
	gen pandemic_start = mdy(03,16,2020)
	gen pandemic_end = mdy(04,17,2022)
	
	drop if indexdate>=pandemic_start // analysis 1
	unique patid
	
	*generate denominator end date
	gen denominator_end = min(pandemic_start, lcd, dod, regenddate, txswitch-1) // Censor at pandemic start date for analysis 1
	format denominator_end pandemic_end pandemic_end st_en %td
	
	*key all the DOAC prescriptions
	joinby patid using "`oac'_Rx_calc_dur_final", unmatched(master)
	
	keep patid indexdate denominator_end rxst rxen
	
	drop if denominator_end == indexdate // 8
	drop if rxen < indexdate
	drop if rxst > denominator_end
	assert rxst >= indexdate 
	gen rxen_new = denominator_end if rxen >= denominator_end
	replace rxen_new = rxen if rxen_new == .
	format rxen_new %td
	
	*calculate total days of prescription
	gen rx_dur = rxen_new - rxst + 1
	bysort patid: egen nominator = total(rx_dur)
	gen denominator = denominator_end - indexdate + 1
	cou if nominator > denominator //0
	cou if denominator > 180 //0
	cou if nominator==. //0
	cou if denominator==. //0
	
	gen pdr = nominator/denominator *100
	
	di "Analysis 1 PDR `oac'"
	duplicates drop patid, force
	su pdr, detail

*Analysis 2
	use "$pathOutOAC/aurum_`oac'_covariate", clear
	gen st_en=mdy(03,31,2023) // study end date
	gen pandemic_start = mdy(03,16,2020)
	gen pandemic_end = mdy(04,17,2022)
	
	drop if indexdate>=pandemic_start // analysis 2
	unique patid
	
	*generate denominator end date
	gen denominator_end = min(st_en, lcd, dod, regenddate, txswitch-1) //Censor at study end date for analysis 2
	format denominator_end pandemic_end pandemic_end st_en %td
	
	*key all the DOAC prescriptions
	joinby patid using "`oac'_Rx_calc_dur_final", unmatched(master)
	
	keep patid indexdate denominator_end rxst rxen
	
	drop if denominator_end == indexdate // 8
	drop if rxen < indexdate
	drop if rxst > denominator_end
	assert rxst >= indexdate 
	gen rxen_new = denominator_end if rxen >= denominator_end
	replace rxen_new = rxen if rxen_new == .
	format rxen_new %td
	
	*calculate total days of prescription
	gen rx_dur = rxen_new - rxst + 1
	bysort patid: egen nominator = total(rx_dur)
	gen denominator = denominator_end - indexdate + 1
	cou if nominator > denominator //0
	cou if denominator > 180 //0
	cou if nominator==. //0
	cou if denominator==. //0
	
	gen pdr = nominator/denominator *100
	
	di "Analysis 2 PDR `oac'"
	duplicates drop patid, force
	su pdr, detail

	
	*Analysis 3
	use "$pathOutOAC/aurum_`oac'_covariate", clear
	gen st_en=mdy(03,31,2023) // study end date
	gen pandemic_start = mdy(03,16,2020)
	gen pandemic_end = mdy(04,17,2022)
	
	*no dropping patients for analysis 3
	unique patid
	
	*generate denominator end date
	gen denominator_end = min(st_en, lcd, dod, regenddate, txswitch-1) //Censor at study end date for analysis 3
	format denominator_end pandemic_end pandemic_end st_en %td
	
	*key all the DOAC prescriptions
	joinby patid using "`oac'_Rx_calc_dur_final", unmatched(master)
	
	keep patid indexdate denominator_end rxst rxen
	
	drop if denominator_end == indexdate // 8
	drop if rxen < indexdate
	drop if rxst > denominator_end
	assert rxst >= indexdate 
	gen rxen_new = denominator_end if rxen >= denominator_end
	replace rxen_new = rxen if rxen_new == .
	format rxen_new %td
	
	*calculate total days of prescription
	gen rx_dur = rxen_new - rxst + 1
	bysort patid: egen nominator = total(rx_dur)
	gen denominator = denominator_end - indexdate + 1
	cou if nominator > denominator //0
	cou if denominator > 180 //0
	cou if nominator==. //0
	cou if denominator==. //0
	
	gen pdr = nominator/denominator *100
	
	di "Analysis 3 PDR `oac'"
	duplicates drop patid, force
	su pdr, detail
	
	*Analysis 4
	use "$pathOutOAC/aurum_`oac'_covariate", clear
	gen st_en=mdy(03,31,2023) // study end date
	gen pandemic_start = mdy(03,16,2020)
	gen pandemic_end = mdy(04,17,2022)
	
	drop if indexdate<pandemic_end //analysis 4
	unique patid
	
	*generate denominator end date
	gen denominator_end = min(st_en, lcd, dod, regenddate, txswitch-1) //Censor at study end date for analysis 4
	format denominator_end pandemic_end pandemic_end st_en %td
	
	*key all the DOAC prescriptions
	joinby patid using "`oac'_Rx_calc_dur_final", unmatched(master)
	
	keep patid indexdate denominator_end rxst rxen
	
	drop if denominator_end == indexdate // 8
	drop if rxen < indexdate
	drop if rxst > denominator_end
	assert rxst >= indexdate 
	gen rxen_new = denominator_end if rxen >= denominator_end
	replace rxen_new = rxen if rxen_new == .
	format rxen_new %td
	
	*calculate total days of prescription
	gen rx_dur = rxen_new - rxst + 1
	bysort patid: egen nominator = total(rx_dur)
	gen denominator = denominator_end - indexdate + 1
	cou if nominator > denominator //0
	cou if denominator > 180 //0
	cou if nominator==. //0
	cou if denominator==. //0
	
	gen pdr = nominator/denominator *100
	
	di "Analysis 4 PDR `oac'"
	duplicates drop patid, force
	su pdr, detail
	
}

*edoxaban; taking dose switching into acccount for demominator
foreach oac in edoxaban_low edoxaban_high {
	use "$pathOutOAC/`oac'_study_cohort_dose", clear
	gen st_en=mdy(03,31,2023) // study end date
	gen pandemic_start = mdy(03,16,2020)
	gen pandemic_end = mdy(04,17,2022)
	
	drop if indexdate>=pandemic_start // analysis 1
	unique patid
	
	*generate denominator end date
	gen denominator_end = min(pandemic_start - 1, lcd, dod, regenddate, txswitch-1, doseswitch) // Censor at pandemic start date for analysis 1
	format denominator_end pandemic_end pandemic_end st_en %td
	
	*key all the DOAC prescriptions
	joinby patid using "`oac'_Rx_calc_dur_final", unmatched(master)
	
	keep patid indexdate denominator_end rxst rxen
	
	drop if denominator_end == indexdate // 8
	drop if rxen < indexdate
	drop if rxst > denominator_end
	assert rxst >= indexdate 
	gen rxen_new = denominator_end if rxen >= denominator_end
	replace rxen_new = rxen if rxen_new == .
	format rxen_new %td
	
	*calculate total days of prescription
	gen rx_dur = rxen_new - rxst + 1
	bysort patid: egen nominator = total(rx_dur)
	gen denominator = denominator_end - indexdate + 1
	cou if nominator > denominator //0
	cou if denominator > 180 //0
	cou if nominator==. //0
	cou if denominator==. //0
	
	gen pdr = nominator/denominator *100
	
	di "Analysis 1 PDR `oac'"
	duplicates drop patid, force
	su pdr, detail

*Analysis 2
	use "$pathOutOAC/`oac'_study_cohort_dose", clear
	gen st_en=mdy(03,31,2023) // study end date
	gen pandemic_start = mdy(03,16,2020)
	gen pandemic_end = mdy(04,17,2022)
	
	drop if indexdate>=pandemic_start // analysis 2
	unique patid
	
	*generate denominator end date
	gen denominator_end = min(st_en, lcd, dod, regenddate, txswitch-1, doseswitch) //Censor at study end date for analysis 2
	format denominator_end pandemic_end pandemic_end st_en %td
	
	*key all the DOAC prescriptions
	joinby patid using "`oac'_Rx_calc_dur_final", unmatched(master)
	
	keep patid indexdate denominator_end rxst rxen
	
	drop if denominator_end == indexdate // 8
	drop if rxen < indexdate
	drop if rxst > denominator_end
	assert rxst >= indexdate 
	gen rxen_new = denominator_end if rxen >= denominator_end
	replace rxen_new = rxen if rxen_new == .
	format rxen_new %td
	
	*calculate total days of prescription
	gen rx_dur = rxen_new - rxst + 1
	bysort patid: egen nominator = total(rx_dur)
	gen denominator = denominator_end - indexdate + 1
	cou if nominator > denominator //0
	cou if denominator > 180 //0
	cou if nominator==. //0
	cou if denominator==. //0
	
	gen pdr = nominator/denominator *100
	
	di "Analysis 2 PDR `oac'"
	duplicates drop patid, force
	su pdr, detail

	
	*Analysis 3
	use "$pathOutOAC/`oac'_study_cohort_dose", clear
	gen st_en=mdy(03,31,2023) // study end date
	gen pandemic_start = mdy(03,16,2020)
	gen pandemic_end = mdy(04,17,2022)
	
	*no dropping patients for analysis 3
	unique patid
	
	*generate denominator end date
	gen denominator_end = min(st_en, lcd, dod, regenddate, txswitch-1, doseswitch) //Censor at study end date for analysis 3
	format denominator_end pandemic_end pandemic_end st_en %td
	
	*key all the DOAC prescriptions
	joinby patid using "`oac'_Rx_calc_dur_final", unmatched(master)
	
	keep patid indexdate denominator_end rxst rxen
	
	drop if denominator_end == indexdate // 8
	drop if rxen < indexdate
	drop if rxst > denominator_end
	assert rxst >= indexdate 
	gen rxen_new = denominator_end if rxen >= denominator_end
	replace rxen_new = rxen if rxen_new == .
	format rxen_new %td
	
	*calculate total days of prescription
	gen rx_dur = rxen_new - rxst + 1
	bysort patid: egen nominator = total(rx_dur)
	gen denominator = denominator_end - indexdate + 1
	cou if nominator > denominator //0
	cou if denominator > 180 //0
	cou if nominator==. //0
	cou if denominator==. //0
	
	gen pdr = nominator/denominator *100
	
	di "Analysis 3 PDR `oac'"
	duplicates drop patid, force
	su pdr, detail
	
	*Analysis 4
	use "$pathOutOAC/`oac'_study_cohort_dose", clear
	gen st_en=mdy(03,31,2023) // study end date
	gen pandemic_start = mdy(03,16,2020)
	gen pandemic_end = mdy(04,17,2022)
	
	drop if indexdate<pandemic_end //analysis 4
	unique patid
	
	*generate denominator end date
	gen denominator_end = min(st_en, lcd, dod, regenddate, txswitch-1, doseswitch) //Censor at study end date for analysis 4
	format denominator_end pandemic_end pandemic_end st_en %td
	
	*key all the DOAC prescriptions
	joinby patid using "`oac'_Rx_calc_dur_final", unmatched(master)
	
	keep patid indexdate denominator_end rxst rxen
	
	drop if denominator_end == indexdate // 8
	drop if rxen < indexdate
	drop if rxst > denominator_end
	assert rxst >= indexdate 
	gen rxen_new = denominator_end if rxen >= denominator_end
	replace rxen_new = rxen if rxen_new == .
	format rxen_new %td
	
	*calculate total days of prescription
	gen rx_dur = rxen_new - rxst + 1
	bysort patid: egen nominator = total(rx_dur)
	gen denominator = denominator_end - indexdate + 1
	cou if nominator > denominator //0
	cou if denominator > 180 //0
	cou if nominator==. //0
	cou if denominator==. //0
	
	gen pdr = nominator/denominator *100
	
	di "Analysis 4 PDR `oac'"
	duplicates drop patid, force
	su pdr, detail
	
}

/*******************************************************************************
*2. Proportion of people registered out of GP (excluding death date)
*******************************************************************************/
foreach drug in rivaroxaban apixaban {
	use "$pathOutOAC/`drug'_study_cohort", clear
gen exposure = 1
append using "$pathOutOAC/warfarin_study_cohort"
replace exposure = 0 if exposure == .
	
	*Analysis 3
	gen st_en=mdy(03,31,2023) // study end date
	gen pandemic_start = mdy(03,16,2020)
	gen pandemic_end = mdy(04,17,2022)
	format st_en pandemic_start pandemic_end %td
	gen total_end = min(st_en, lcd, dod, regenddate, txswitch-1, discontinue_date)
	format total_end %td

	gen deregister_gp = 1 if total_end == regenddate & regenddate!=. & total_end!=dod
	replace deregister_gp = 0 if deregister_gp == .
	
	di "Analysis 3 Proportion of people deregister GP `drug' (not deathdate)"
	tab deregister_gp exposure,m col
	
	gen total_duration = total_end - indexdate + 1
	bysort exposure: egen max_deregister_gp = total(deregister_gp)
	bysort exposure: egen max_total_duration = total(total_duration)
	gen rate = max_deregister_gp / (max_total_duration/365.25) *1000
	
	di "Analysis 3 Rate of people deregister GP `drug' (not deathdate)"
	bysort exposure: su rate
	
	drop total_duration max_deregister_gp max_total_duration rate
	
	*Analysis 4
	preserve
	drop if indexdate<pandemic_end
	di "Analysis 4 Proportion of people deregister GP `drug' (not deathdate)"
	tab deregister_gp exposure,m col
	
	gen total_duration = total_end - indexdate + 1
	bysort exposure: egen max_deregister_gp = total(deregister_gp)
	bysort exposure: egen max_total_duration = total(total_duration)
	gen rate = max_deregister_gp / (max_total_duration/365.25) *1000
	
	di "Analysis 4 Rate of people deregister GP `drug' (not deathdate)"
	bysort exposure: su rate
	restore
	
	*Analysis 2
	preserve
	drop if indexdate>=pandemic_start
	di "Analysis 2 Proportion of people deregister GP `drug' (not deathdate)"
	tab deregister_gp exposure,m col
	
	gen total_duration = total_end - indexdate + 1
	bysort exposure: egen max_deregister_gp = total(deregister_gp)
	bysort exposure: egen max_total_duration = total(total_duration)
	gen rate = max_deregister_gp / (max_total_duration/365.25) *1000
	
	di "Analysis 2 Rate of people deregister GP `drug' (not deathdate)"
	bysort exposure: su rate
	restore
	
	*Analysis 1
	drop total_end
	drop deregister_gp
	drop if indexdate>=pandemic_start
	gen total_end = min(pandemic_start, lcd, dod, regenddate, txswitch-1, discontinue_date)
	
	gen deregister_gp = 1 if total_end == regenddate & regenddate!=. & total_end!=dod
	replace deregister_gp = 0 if deregister_gp == .
	di "Analysis 1 Proportion of people deregister GP `drug' (not deathdate)"
	tab deregister_gp exposure,m col
	
	gen total_duration = total_end - indexdate + 1
	bysort exposure: egen max_deregister_gp = total(deregister_gp)
	bysort exposure: egen max_total_duration = total(total_duration)
	gen rate = max_deregister_gp / (max_total_duration/365.25) *1000
	
	di "Analysis 1 Rate of people deregister GP `drug' (not deathdate)"
	bysort exposure: su rate
}

foreach drug in edoxaban_low edoxaban_high {
	use "$pathOutOAC/`drug'_study_cohort_dose", clear
gen exposure = 1
append using "$pathOutOAC/warfarin_study_cohort"
replace exposure = 0 if exposure == .
	
	*Analysis 3
	gen st_en=mdy(03,31,2023) // study end date
	gen pandemic_start = mdy(03,16,2020)
	gen pandemic_end = mdy(04,17,2022)
	format st_en pandemic_start pandemic_end %td
	gen total_end = min(st_en, lcd, dod, regenddate, txswitch-1, doseswitch, discontinue_date)
	format total_end %td

	gen deregister_gp = 1 if total_end == regenddate & regenddate!=. & total_end!=dod
	replace deregister_gp = 0 if deregister_gp == .
	
	di "Analysis 3 Proportion of people deregister GP `drug' (not deathdate)"
	tab deregister_gp exposure,m col
	
	gen total_duration = total_end - indexdate + 1
	bysort exposure: egen max_deregister_gp = total(deregister_gp)
	bysort exposure: egen max_total_duration = total(total_duration)
	gen rate = max_deregister_gp / (max_total_duration/365.25) *1000
	
	di "Analysis 3 Rate of people deregister GP `drug' (not deathdate)"
	bysort exposure: su rate

	drop total_duration max_deregister_gp max_total_duration rate
	
	*Analysis 4
	preserve
	drop if indexdate<pandemic_end
	di "Analysis 4 Proportion of people deregister GP `drug' (not deathdate)"
	tab deregister_gp exposure,m col
	
	gen total_duration = total_end - indexdate + 1
	bysort exposure: egen max_deregister_gp = total(deregister_gp)
	bysort exposure: egen max_total_duration = total(total_duration)
	gen rate = max_deregister_gp / (max_total_duration/365.25) *1000
	
	di "Analysis 4 Rate of people deregister GP `drug' (not deathdate)"
	bysort exposure: su rate
	restore
	
	*Analysis 2
	preserve
	drop if indexdate>=pandemic_start
	di "Analysis 2 Proportion of people deregister GP `drug' (not deathdate)"
	tab deregister_gp exposure,m col
	
	gen total_duration = total_end - indexdate + 1
	bysort exposure: egen max_deregister_gp = total(deregister_gp)
	bysort exposure: egen max_total_duration = total(total_duration)
	gen rate = max_deregister_gp / (max_total_duration/365.25) *1000
	
	di "Analysis 2 Rate of people deregister GP `drug' (not deathdate)"
	bysort exposure: su rate
	restore
	
	*Analysis 1
	drop total_end
	drop if indexdate>=pandemic_start
	gen total_end = min(pandemic_start, lcd, dod, regenddate, txswitch-1, doseswitch, discontinue_date)
	
	drop deregister_gp
	gen deregister_gp = 1 if total_end == regenddate & regenddate!=. & total_end!=dod
	replace deregister_gp = 0 if deregister_gp == .
	di "Analysis 1 Proportion of people deregister GP `drug' (not deathdate)"
	tab deregister_gp exposure,m col
	
	gen total_duration = total_end - indexdate + 1
	bysort exposure: egen max_deregister_gp = total(deregister_gp)
	bysort exposure: egen max_total_duration = total(total_duration)
	gen rate = max_deregister_gp / (max_total_duration/365.25) *1000
	
	di "Analysis 1 Rate of people deregister GP `drug' (not deathdate)"
	bysort exposure: su rate
}

/*******************************************************************************
*3. Length between AF diagnosis and initiation of OAC
*******************************************************************************/
foreach drug in rivaroxaban apixaban edoxaban_low edoxaban_high {
	use "$pathOutOAC/`drug'_study_cohort", clear
gen exposure = 1
append using "$pathOutOAC/warfarin_study_cohort"
replace exposure = 0 if exposure == .
	
	*Analysis 3
	gen time_af_oac = indexdate - eventdate_af
	gen pandemic_start = mdy(03,16,2020)
	gen pandemic_end = mdy(04,17,2022)
	format pandemic_start pandemic_end %td
	
	di "Analysis 3 Length between AF diagnosis and initiation of OAC `drug'"
	su time_af_oac, detail
	bysort exposure: su time_af_oac, detail
	
	*Analysis 4
	preserve
	drop if indexdate<pandemic_end
	di "Analysis 4 Length between AF diagnosis and initiation of OAC `drug'"
	su time_af_oac, detail
	bysort exposure: su time_af_oac, detail
	restore
	
	*Analysis 2
	preserve
	drop if indexdate>=pandemic_start
	di "Analysis 2 Length between AF diagnosis and initiation of OAC `drug'"
	su time_af_oac, detail
	bysort exposure: su time_af_oac, detail
	restore
	
	*Analysis 1
	drop if indexdate>=pandemic_start
	
	di "Analysis 1 Length between AF diagnosis and initiation of OAC `drug'"
	su time_af_oac, detail
	bysort exposure: su time_af_oac, detail
}

/*******************************************************************************
*4. Proportion of people switching to another group (and edoxaban changing doses)
*******************************************************************************/
foreach drug in rivaroxaban apixaban {
	use "$pathOutOAC/`drug'_study_cohort", clear
gen exposure = 1
append using "$pathOutOAC/warfarin_study_cohort"
replace exposure = 0 if exposure == .
	
	*Analysis 3
	gen st_en=mdy(03,31,2023) // study end date
	gen pandemic_start = mdy(03,16,2020)
	gen pandemic_end = mdy(04,17,2022)
	format st_en pandemic_start pandemic_end %td
	gen total_end = min(st_en, lcd, dod, regenddate, txswitch-1, discontinue_date)
	format total_end %td

	gen switch_treatment = 1 if total_end == txswitch-1 & txswitch !=.
	replace switch_treatment = 0 if switch_treatment == .
	
	di "Analysis 3 Proportion of people treatment switching `drug'"
	tab switch_treatment exposure,m col
	
	*Analysis 4
	preserve
	drop if indexdate<pandemic_end
	di "Analysis 4 Proportion of people treatment switching `drug'"
	tab switch_treatment exposure,m col
	restore
	
	*Analysis 2
	preserve
	drop if indexdate>=pandemic_start
	di "Analysis 2 Proportion of people treatment switching `drug'"
	tab switch_treatment exposure,m col
	restore
	
	*Analysis 1
	drop total_end
	drop if indexdate>=pandemic_start
	gen total_end = min(pandemic_start, lcd, dod, regenddate, txswitch-1, discontinue_date)
	
	drop switch_treatment
	gen switch_treatment = 1 if total_end == txswitch-1 & txswitch !=.
	replace switch_treatment = 0 if switch_treatment == .
	
	di "Analysis 1 Proportion of people treatment switching `drug'"
	tab switch_treatment exposure,m col
}

foreach drug in edoxaban_low edoxaban_high {
	use "$pathOutOAC/`drug'_study_cohort_dose", clear
gen exposure = 1
append using "$pathOutOAC/warfarin_study_cohort"
replace exposure = 0 if exposure == .
	
	*Analysis 3
	gen st_en=mdy(03,31,2023) // study end date
	gen pandemic_start = mdy(03,16,2020)
	gen pandemic_end = mdy(04,17,2022)
	format st_en pandemic_start pandemic_end %td
	gen total_end = min(st_en, lcd, dod, regenddate, txswitch-1, doseswitch, discontinue_date)
	format total_end %td

	gen switch_treatment = 1 if total_end == txswitch-1 & txswitch !=.
	replace switch_treatment = 1 if total_end == doseswitch & doseswitch !=.
	replace switch_treatment = 0 if switch_treatment == .
	 
	di "Analysis 3 Proportion of people treatment switching `drug' & change dose"
	tab switch_treatment exposure,m col
	
	*Analysis 4
	preserve
	drop if indexdate<pandemic_end
	di "Analysis 4 Proportion of people treatment switching `drug' & change dose"
	tab switch_treatment exposure,m col
	restore
	
	*Analysis 2
	preserve
	drop if indexdate>=pandemic_start
	di "Analysis 2 Proportion of people treatment switching `drug' & change dose"
	tab switch_treatment exposure,m col
	restore
	
	*Analysis 1
	drop total_end
	drop if indexdate>=pandemic_start
	gen total_end = min(pandemic_start, lcd, dod, regenddate, txswitch-1, doseswitch, discontinue_date)
	
	drop switch_treatment
	gen switch_treatment = 1 if total_end == txswitch-1 & txswitch !=.
	replace switch_treatment = 1 if total_end == doseswitch & doseswitch !=.
	replace switch_treatment = 0 if switch_treatment == .
	
	di "Analysis 1 Proportion of people treatment switching `drug' & change dose"
	tab switch_treatment exposure,m col
}

foreach drug in edoxaban_low edoxaban_high {
	use "$pathOutOAC/`drug'_study_cohort_dose", clear
gen exposure = 1
append using "$pathOutOAC/warfarin_study_cohort"
replace exposure = 0 if exposure == .
	
	*Analysis 3
	gen st_en=mdy(03,31,2023) // study end date
	gen pandemic_start = mdy(03,16,2020)
	gen pandemic_end = mdy(04,17,2022)
	format st_en pandemic_start pandemic_end %td
	gen total_end = min(st_en, lcd, dod, regenddate, txswitch-1, doseswitch, discontinue_date)
	format total_end %td

	gen switch_treatment = 1 if total_end == txswitch-1 & txswitch !=.
	replace switch_treatment = 0 if switch_treatment == .
	
	di "Analysis 3 Proportion of people treatment switching `drug'"
	tab switch_treatment exposure,m col
	
	*Analysis 4
	preserve
	drop if indexdate<pandemic_end
	di "Analysis 4 Proportion of people treatment switching `drug'"
	tab switch_treatment exposure,m col
	restore
	
	*Analysis 2
	preserve
	drop if indexdate>=pandemic_start
	di "Analysis 2 Proportion of people treatment switching `drug'"
	tab switch_treatment exposure,m col
	restore
	
	*Analysis 1
	drop total_end
	drop if indexdate>=pandemic_start
	gen total_end = min(pandemic_start, lcd, dod, regenddate, txswitch-1, doseswitch, discontinue_date)
	
	drop switch_treatment
	gen switch_treatment = 1 if total_end == txswitch-1 & txswitch !=.
	replace switch_treatment = 0 if switch_treatment == .
	
	di "Analysis 1 Proportion of people treatment switching `drug'"
	tab switch_treatment exposure,m col
}

/*******************************************************************************
*5. Proportion of people switching to another group (and edoxaban changing doses) or discontinuation
*******************************************************************************/
foreach drug in rivaroxaban apixaban {
	use "$pathOutOAC/`drug'_study_cohort", clear
gen exposure = 1
append using "$pathOutOAC/warfarin_study_cohort"
replace exposure = 0 if exposure == .
	
	*Analysis 3
	gen st_en=mdy(03,31,2023) // study end date
	gen pandemic_start = mdy(03,16,2020)
	gen pandemic_end = mdy(04,17,2022)
	format st_en pandemic_start pandemic_end %td
	gen total_end = min(st_en, lcd, dod, regenddate, txswitch-1, discontinue_date)
	format total_end %td

	gen switch_treatment = 1 if total_end == txswitch-1 & txswitch !=.
	replace switch_treatment = 1 if total_end == discontinue_date & discontinue_date !=.
	replace switch_treatment = 0 if switch_treatment == .
	
	di "Analysis 3 Proportion of people treatment switching/discontinuation `drug'"
	tab switch_treatment exposure,m col
	
	*Analysis 4
	preserve
	drop if indexdate<pandemic_end
	di "Analysis 4 Proportion of people treatment switching/discontinuation `drug'"
	tab switch_treatment exposure,m col
	restore
	
	*Analysis 2
	preserve
	drop if indexdate>=pandemic_start
	di "Analysis 2 Proportion of people treatment switching/discontinuation `drug'"
	tab switch_treatment exposure,m col
	restore
	
	*Analysis 1
	drop total_end
	drop if indexdate>=pandemic_start
	gen total_end = min(pandemic_start, lcd, dod, regenddate, txswitch-1, discontinue_date)
	
	drop switch_treatment
	gen switch_treatment = 1 if total_end == txswitch-1 & txswitch !=.
	replace switch_treatment = 1 if total_end == discontinue_date & discontinue_date !=.
	replace switch_treatment = 0 if switch_treatment == .
	
	di "Analysis 1 Proportion of people treatment switching/discontinuation `drug'"
	tab switch_treatment exposure,m col
}

foreach drug in edoxaban_low edoxaban_high {
	use "$pathOutOAC/`drug'_study_cohort_dose", clear
gen exposure = 1
append using "$pathOutOAC/warfarin_study_cohort"
replace exposure = 0 if exposure == .
	
	*Analysis 3
	gen st_en=mdy(03,31,2023) // study end date
	gen pandemic_start = mdy(03,16,2020)
	gen pandemic_end = mdy(04,17,2022)
	format st_en pandemic_start pandemic_end %td
	gen total_end = min(st_en, lcd, dod, regenddate, txswitch-1, doseswitch, discontinue_date)
	format total_end %td

	gen switch_treatment = 1 if total_end == txswitch-1 & txswitch !=.
	replace switch_treatment = 1 if total_end == discontinue_date & discontinue_date !=.
	replace switch_treatment = 1 if total_end == doseswitch & doseswitch !=.
	replace switch_treatment = 0 if switch_treatment == .
	
	di "Analysis 3 Proportion of people treatment switching/discontinuation `drug'"
	tab switch_treatment exposure,m col
	
	*Analysis 4
	preserve
	drop if indexdate<pandemic_end
	di "Analysis 4 Proportion of people treatment switching/discontinuation `drug'"
	tab switch_treatment exposure,m col
	restore
	
	*Analysis 2
	preserve
	drop if indexdate>=pandemic_start
	di "Analysis 2 Proportion of people treatment switching/discontinuation `drug'"
	tab switch_treatment exposure,m col
	restore
	
	*Analysis 1
	drop total_end
	drop if indexdate>=pandemic_start
	gen total_end = min(pandemic_start, lcd, dod, regenddate, txswitch-1, doseswitch, discontinue_date)
	
	drop switch_treatment
	gen switch_treatment = 1 if total_end == txswitch-1 & txswitch !=.
	replace switch_treatment = 1 if total_end == discontinue_date & discontinue_date !=.
	replace switch_treatment = 1 if total_end == doseswitch & doseswitch !=.
	replace switch_treatment = 0 if switch_treatment == .
	
	di "Analysis 1 Proportion of people treatment switching/discontinuation `drug'"
	tab switch_treatment exposure,m col
}

/*******************************************************************************
*6. Median of follow-up of each group (using major bleed dataset as it's primary outcome)
*******************************************************************************/
foreach num in 1 2 3 4 {
	foreach doac in rivaroxaban apixaban dose_edoxaban_low dose_edoxaban_high {
	use "$pathOutOAC/aurum_`doac'_major_bleed_analysis`num'", clear

	gen dur = stime_major_bleed - indexdate
	di in yellow "Analysis `num'"
	bysort exposure: su dur, detail
}
}

log close