/*=========================================================================
DO FILE NAME:			10_OAC-Aurum-descriptive-02-af-outcome-trend

AUTHOR:					Angel Wong
VERSION:				v1
DATE VERSION CREATED:	4 Nov 2025
					
DATABASE:				CPRD Dec 2024 build

Aim:
describe the trend of study population and outcome in each DOAC vs warfarin
*=============================================================================*/

/*******************************************************************************
>> HOUSEKEEPING
*******************************************************************************/
capture log close

/*******************************************************************************
Identify file locations
*******************************************************************************/
* create a filename global that can be used throughout the file
global filename "10_OAC-Aurum-descriptive-02-af-outcome-trend"
*******************************************************************************/
* open log file - no need as fast tool will create log files
log using "${pathLogs}/${filename}", text replace
/********************************************************************/
/*******************************************************************************/
*Overall frequency 
/********************************************************************/
foreach doac in rivaroxaban apixaban dose_edoxaban_low dose_edoxaban_high {
foreach outcome in ischaemic_stroke MI vte {
use "$pathOutOAC/aurum_`doac'_`outcome'_analysis3", clear
drop eventdate
keep if `outcome' == 1
joinby patid using "$pathOutOAC/`outcome'_all.dta", unmatched(master)
keep if stime_`outcome' == eventdate
keep patid exposure eventdate source

duplicates drop patid exposure source eventdate, force

gen year_event = year(eventdate)
tab year_event,m

drop if year_event == 2023

preserve
tab year_event,m matcell(freq)
tab year_event,m matrow(year)
clear
svmat year
svmat freq
rename year1 year
rename freq total_frequency
save "fir_`outcome'_cohort_year", replace
restore

preserve
keep if source == 0
tab year_event,m matcell(freq)
tab year_event,m matrow(year)
clear
svmat year
svmat freq
rename year1 year
rename freq aurum_frequency
save "firaurum_`outcome'_cohort_year", replace
restore

preserve
keep if source == 1
tab year_event,m matcell(freq)
tab year_event,m matrow(year)
clear
svmat year
svmat freq
rename year1 year
rename freq hes_frequency
save "firhes_`outcome'_cohort_year", replace
restore

preserve
keep if source == 2
tab year_event,m matcell(freq)
tab year_event,m matrow(year)
clear
svmat year
svmat freq
rename year1 year
rename freq ons_frequency
save "firons_`outcome'_cohort_year", replace
restore

*merge by source dataset to total
use "fir_`outcome'_cohort_year", clear
merge 1:1 year using "firhes_`outcome'_cohort_year", nogen
merge 1:1 year using "firaurum_`outcome'_cohort_year", nogen
merge 1:1 year using "firons_`outcome'_cohort_year", nogen

foreach var in total_ hes_ aurum_ ons_ {
	replace `var'frequency =. if `var'frequency < 5
}

scatter total_frequency hes_frequency aurum_frequency ons_frequency year, ytick(#10) xtick(#1) xlabel(2012(1)2023) connect(l 2 3 4)

graph export "$pathResults/OAC/trend/freq_first_`outcome'_`doac'_source.svg", replace

}
}

foreach doac in rivaroxaban apixaban dose_edoxaban_low dose_edoxaban_high {
foreach outcome in major_bleed {
use "$pathOutOAC/aurum_`doac'_`outcome'_analysis3", clear
drop eventdate
keep if `outcome' == 1
joinby patid using "$pathOutOAC/`outcome'_all.dta", unmatched(master)
keep if stime_`outcome' == eventdate
keep patid exposure eventdate source

duplicates drop patid exposure source eventdate, force
gen year_event = year(eventdate)
tab year_event,m

drop if year_event == 2023

preserve
tab year_event,m matcell(freq)
tab year_event,m matrow(year)
clear
svmat year
svmat freq
rename year1 year
rename freq total_frequency
save "fir_`outcome'_cohort_year", replace
restore

preserve
keep if source == 1
tab year_event,m matcell(freq)
tab year_event,m matrow(year)
clear
svmat year
svmat freq
rename year1 year
rename freq hes_frequency
save "firhes_`outcome'_cohort_year", replace
restore

preserve
keep if source == 2
tab year_event,m matcell(freq)
tab year_event,m matrow(year)
clear
svmat year
svmat freq
rename year1 year
rename freq ons_frequency
save "firons_`outcome'_cohort_year", replace
restore

*merge by source dataset to total
use "fir_`outcome'_cohort_year", clear
merge 1:1 year using "firhes_`outcome'_cohort_year", nogen
merge 1:1 year using "firons_`outcome'_cohort_year", nogen

foreach var in total_ hes_ ons_ {
	replace `var'frequency =. if `var'frequency < 5
}

scatter total_frequency hes_frequency ons_frequency year, ytick(#10) xtick(#1) xlabel(2012(1)2022) connect(l 2 3)
graph export "$pathResults/OAC/trend/freq_first_`outcome'_`doac'_source.svg", replace

}
}

/*******************************************************************************/
*Overall incidence taking population as denominator by exposure without stratify by data source with CI 
/********************************************************************/
/*******************************************************************************/
*incidence per exposure group
/********************************************************************/
foreach doac in rivaroxaban apixaban dose_edoxaban_low dose_edoxaban_high {
foreach outcome in ischaemic_stroke MI vte major_bleed {
		foreach exp in 1 0 {
use "$pathOutOAC/aurum_`doac'_`outcome'_analysis3", clear
keep patid indexdate enddate exposure `outcome' stime_`outcome'
gen year_index = year(indexdate)
gen year_end = year(enddate)

forval num = 12/22 {
	gen year20`num' = 20`num'
	gen doacpop_20`num' = 1 if year_index <= (2000 + `num') & (2000 + `num') <= year_end
	replace doacpop_20`num' = 1 if (2000 + `num') <= year_index  & year_index  <= (2000 + `num')
	replace doacpop_20`num' = 1 if (2000 + `num') <= year_end  & year_end  <= (2000 + `num')
	replace doacpop_20`num' = 0 if doacpop_20`num' ==.
	egen denominatorall20`num' = total(doacpop_20`num')
	bysort exposure: egen denominator20`num' = total(doacpop_20`num')
}
	preserve
	keep if _n==1
	reshape long denominatorall, i(exposure) j(year)
	rename denominatorall denominator
	keep year denominator
	save "all_denominator_`outcome'_`doac'", replace
	restore
	
	preserve
	duplicates drop exposure, force
	keep if exposure == `exp'
	keep exposure denominator20*
	reshape long denominator, i(exposure) j(year)
	save "denominator`exp'_`doac'_`outcome'", replace
	restore
	
keep if `outcome' == 1

keep if exposure == `exp'

joinby patid using "$pathOutOAC/`outcome'_all.dta", unmatched(master)
keep if stime_`outcome' == eventdate
keep patid exposure eventdate source stime_`outcome'

duplicates drop patid exposure source eventdate, force

gen year_event = year(stime_`outcome')
bysort exposure: tab year_event,m

drop if year_event == 2023

preserve
tab year_event,m matcell(freq)
tab year_event,m matrow(year)
clear
svmat year
svmat freq
rename year1 year
rename freq total`exp'_frequency
merge 1:1 year using "denominator`exp'_`doac'_`outcome'", keep(master match) nogen
list total`exp'_frequency denominator
gen total`exp'_incidence = .
gen lci = .
gen uci = .

forvalues i = 1/`=_N' {
    cii proportion `=denominator[`i']' `=total`exp'_frequency[`i']'
    replace total`exp'_incidence = r(proportion) in `i'
    replace lci = r(lb) in `i'
    replace uci = r(ub) in `i'
}
gen total`exp'_incidence1000 = total`exp'_incidence * 1000
gen total`exp'_lci1000 = lci * 1000
gen total`exp'_uci1000 = uci * 1000

save "all_`doac'_`outcome'_incidence`exp'", replace
restore
		}
		
*merge by exposure dataset to total 
use "all_`doac'_`outcome'_incidence1", clear
append using "all_`doac'_`outcome'_incidence0"
save "fir_`doac'_`outcome'_all_trend_data", replace

foreach var in total1 total0  {
	replace `var'_incidence1000 =. if `var'_frequency < 5
	replace `var'_lci1000 =. if `var'_frequency < 5
	replace `var'_uci1000 =. if `var'_frequency < 5
	replace `var'_frequency =. if `var'_frequency < 5
}
 	twoway ///
    (rcap total1_lci1000 total1_uci1000 year) ///
    (line total1_incidence1000 year, msymbol(square)) ///
    , ///
	title("`doac'")  ///
    xtitle("Year", size(medium)) ///
    xlabel(2012(1)2022, labsize(medium) angle(40)) ///
    legend(off) ///
	saving(incidence_`outcome'_`doac'_total_exp1, replace)
	twoway ///
    (rcap total0_lci1000 total0_uci1000 year) ///
    (line total0_incidence1000 year, msymbol(triangle)) ///
    , ///
	title("warfarin")  ///
    xtitle("Year", size(medium)) ///
    xlabel(2012(1)2022, labsize(medium) angle(40)) ///
    legend(off) ///
	saving(incidence_`outcome'_`doac'_total_exp0, replace)
}
}
*regenerate rivaroxaban with y title
foreach outcome in ischaemic_stroke MI vte major_bleed {
use "all_rivaroxaban_`outcome'_incidence1", clear
append using "all_rivaroxaban_`outcome'_incidence0"
save "fir_rivaroxaban_`outcome'_all_trend_data", replace

foreach var in total1 total0  {
	replace `var'_incidence1000 =. if `var'_frequency < 5
	replace `var'_lci1000 =. if `var'_frequency < 5
	replace `var'_uci1000 =. if `var'_frequency < 5
	replace `var'_frequency =. if `var'_frequency < 5
}
 	twoway ///
    (rcap total1_lci1000 total1_uci1000 year) ///
    (line total1_incidence1000 year, msymbol(square)) ///
    , /// 
	title("rivaroxaban")  ///
    ytitle("Incidence per 1,000", size(verylarge)) ///
    xtitle("Year", size(medium)) ///
    xlabel(2012(1)2022, labsize(medium) angle(40)) ///
    legend(off) ///
	saving(incidence_`outcome'_rivaroxaban_total_exp1, replace)
	
	twoway ///
    (rcap total0_lci1000 total0_uci1000 year) ///
    (line total0_incidence1000 year, msymbol(triangle)) ///
    , ///
	title("warfarin")  ///
    xtitle("Year", size(medium)) ///
    xlabel(2012(1)2022, labsize(medium) angle(40)) ///
    legend(off) ///
	saving(incidence_`outcome'_rivaroxaban_total_exp0, replace)
 }	

foreach outcome in ischaemic_stroke MI vte major_bleed {
graph combine incidence_`outcome'_rivaroxaban_total_exp1.gph incidence_`outcome'_apixaban_total_exp1.gph incidence_`outcome'_dose_edoxaban_low_total_exp1.gph incidence_`outcome'_dose_edoxaban_high_total_exp1.gph incidence_`outcome'_rivaroxaban_total_exp0.gph, scale(0.6) ycommon xcommon graphregion(margin(tiny)) imargin(tiny) row(1)
graph export "$pathResults/OAC/trend/incidence_`outcome'_exp_CI.svg", replace
}

*remove datasets not needed
foreach doac in rivaroxaban apixaban dose_edoxaban_low dose_edoxaban_high {
foreach outcome in ischaemic_stroke MI vte major_bleed {
	foreach exp in 1 0 {
erase "all_`doac'_`outcome'_incidence`exp'.dta"
	}
}
}
foreach doac in rivaroxaban apixaban dose_edoxaban_low dose_edoxaban_high {
foreach outcome in ischaemic_stroke MI vte major_bleed {
erase "incidence_`outcome'_`doac'_total_exp1.gph"
erase "incidence_`outcome'_`doac'_total_exp0.gph"
}
}

*AF diagnosis trend
*incidence: taking denominator (general population in the data source) into account
use "J:\EHR Share\3 Database guidelines and info\CPRD Aurum\Denominator files\2024_12\202412_CPRDAurum_AllPats.dta", clear
keep if acceptable == "1"
unique patid

*linked to HES
merge m:1 patid using "J:\EHR Share\3 Database guidelines and info\CPRD Linkage Source Data Files\Version23\set_23_Source_Aurum\Aurum_enhanced_eligibility_November_2024.dta", ////
	keepusing(hes_apc_e ons_death_e) keep(master match) nogen
	
keep if hes_apc_e=="1" | ons_death_e=="1"

gen regstd=date(regstartdate, "DMY")
gen regend=date(regenddate, "DMY")
gen dod=date(cprd_ddate, "DMY")
gen lcd1=date(lcd, "DMY")
format regstd regend dod lcd1 %td

gen st_st=mdy(01,01,2012) // study start date
gen st_en=mdy(12,31,2022) // study end date (for the graph)

drop if dod != . & dod < st_st
drop if regend !=. & regend < st_st
drop if lcd1 < st_st
drop if regstd > st_en

gen followup_st = max(st_st, regstd)
gen followup_en = min(regend, dod, lcd1)
format st_st st_en followup_st followup_en %td
gen nid = 1

gen year_fst = year(followup_st)
gen year_fen = year(followup_en)

forval num = 12/22 {
	gen year20`num' = 20`num'
	gen pop_20`num' = 1 if year_fst <= (2000 + `num') & (2000 + `num') <= year_fen
	replace pop_20`num' = 1 if (2000 + `num') <= year_fst  & year_fst  <= (2000 + `num')
	replace pop_20`num' = 1 if (2000 + `num') <= year_fen  & year_fen  <= (2000 + `num')
	replace pop_20`num' = 0 if pop_20`num' ==.
	egen denominatorall20`num' = total(pop_20`num')
}

	keep if _n==1
	reshape long denominatorall, i(nid) j(year)
	rename denominatorall denominator
	keep year denominator
	save "all_denominator", replace
	
*all af diagnosis
use "Obs_af_all", clear
gen source = 1
append using "hes_af_all"
replace source = 2 if source ==.
save "af_all_dx", replace


use "$pathOutOAC/aurum_apixaban_major_bleed_analysis3", clear
append using "$pathOutOAC/aurum_rivaroxaban_major_bleed_analysis3"
append using "$pathOutOAC/aurum_edoxaban_low_major_bleed_analysis3"
append using "$pathOutOAC/aurum_edoxaban_high_major_bleed_analysis3"
sort patid eventdate_af
bysort patid: keep if _n==1
keep patid eventdate_af

joinby patid using "af_all_dx.dta", unmatched(master)
keep if eventdate_af == eventdate
keep patid eventdate source

duplicates drop patid source eventdate, force

gen year_event = year(eventdate)
tab year_event,m

drop if year_event == 2023

save "afdx_trend.dta", replace

preserve
tab year_event,m matcell(freq)
tab year_event,m matrow(year)
clear
svmat year
svmat freq
rename year1 year
rename freq total_frequency
save "fir_af_cohort_year", replace
restore

preserve
keep if source == 1
tab year_event,m matcell(freq)
tab year_event,m matrow(year)
clear
svmat year
svmat freq
rename year1 year
rename freq cprd_frequency
save "fircprd_af_cohort_year", replace
restore

preserve
keep if source == 2
tab year_event,m matcell(freq)
tab year_event,m matrow(year)
clear
svmat year
svmat freq
rename year1 year
rename freq hes_frequency
save "firhes_af_cohort_year", replace
restore

*merge by source dataset to total
use "fir_af_cohort_year", clear
merge 1:1 year using "firhes_af_cohort_year", nogen
merge 1:1 year using "fircprd_af_cohort_year", nogen

foreach var in total_ hes_ cprd_ {
	replace `var'frequency =. if `var'frequency < 5
}

scatter total_frequency hes_frequency cprd_frequency year, ytick(#10) xtick(#1) xlabel(2012(1)2022) connect(l 2 3) saving(freq_af_exp, replace) 

graph export "$pathResults/OAC/trend/freq_af_source.svg", replace

*drop year<2012
use "afdx_trend.dta", clear

drop if year_event < 2012

preserve
tab year_event,m matcell(freq)
tab year_event,m matrow(year)
clear
svmat year
svmat freq
rename year1 year
rename freq total_frequency
save "fir_af_cohort_year", replace
restore

preserve
keep if source == 1
tab year_event,m matcell(freq)
tab year_event,m matrow(year)
clear
svmat year
svmat freq
rename year1 year
rename freq cprd_frequency
save "fircprd_af_cohort_year", replace
restore

preserve
keep if source == 2
tab year_event,m matcell(freq)
tab year_event,m matrow(year)
clear
svmat year
svmat freq
rename year1 year
rename freq hes_frequency
save "firhes_af_cohort_year", replace
restore

*merge by source dataset to total
use "fir_af_cohort_year", clear
merge 1:1 year using "firhes_af_cohort_year", nogen
merge 1:1 year using "fircprd_af_cohort_year", nogen

merge 1:1 year using "all_denominator", nogen

gen total_incidence = total_frequency / denominator *1000
gen hes_incidence = hes_frequency / denominator *1000
gen cprd_incidence = cprd_frequency / denominator *1000

foreach var in total_ hes_ cprd_ {
	replace `var'frequency =. if `var'frequency < 5
}

scatter total_frequency hes_frequency cprd_frequency year, ytick(#10) xtick(#1) xlabel(2012(1)2022) connect(l 2 3) saving(freq_af_exp, replace) 

graph export "$pathResults/OAC/trend/freq_af_source_20122022.svg", replace

scatter total_incidence hes_incidence cprd_incidence year, ytitle("Incidence per 1000") ytick(#10) xtick(#1) xlabel(2012(1)2022) connect(l 2 3) saving(incidence_af_exp, replace) 

graph export "$pathResults/OAC/trend/incidence_af_source_20122022.svg", replace

*collapse all before year<2012 to be year of 2012
use "afdx_trend.dta", clear

replace year_event = 2012 if year_event < 2012

preserve
tab year_event,m matcell(freq)
tab year_event,m matrow(year)
clear
svmat year
svmat freq
rename year1 year
rename freq total_frequency
save "fir_af_cohort_year", replace
restore

preserve
keep if source == 1
tab year_event,m matcell(freq)
tab year_event,m matrow(year)
clear
svmat year
svmat freq
rename year1 year
rename freq cprd_frequency
save "fircprd_af_cohort_year", replace
restore

preserve
keep if source == 2
tab year_event,m matcell(freq)
tab year_event,m matrow(year)
clear
svmat year
svmat freq
rename year1 year
rename freq hes_frequency
save "firhes_af_cohort_year", replace
restore

*merge by source dataset to total
use "fir_af_cohort_year", clear
merge 1:1 year using "firhes_af_cohort_year", nogen
merge 1:1 year using "fircprd_af_cohort_year", nogen

foreach var in total_ hes_ cprd_ {
	replace `var'frequency =. if `var'frequency < 5
}

scatter total_frequency hes_frequency cprd_frequency year, ytick(#10) xtick(#1) xlabel(2012(1)2022) connect(l 2 3) saving(freq_af_exp, replace) 

graph export "$pathResults/OAC/trend/freq_af_source_collapse20122022.svg", replace

log close
