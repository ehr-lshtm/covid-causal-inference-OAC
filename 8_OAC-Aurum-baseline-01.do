/*==============================================================================
DO FILE NAME:			8_OAC-Aurum-baseline-01.do

AUTHOR:					Angel Wong
VERSION:				v1
DATE VERSION CREATED:	2025-Aug-13
					
DATABASE:				CPRD Dec 2024 build

DESCRIPTION OF FILE:	Exposure groups 
						(DOAC vs warfarin)
						Produce a table of baseline characteristics, by exposure
						Generalised to produce same columns as levels of exposure
						Output to a textfile for further formatting in different analyses

==============================================================================*/

* Open a log file
capture log close

/*******************************************************************************
Identify file locations
*******************************************************************************/
* create a filename global that can be used throughout the file
global filename "8_OAC-Aurum-baseline-01"

* open log file - no need as fast tool will create log files
log using "${pathLogs}/${filename}", text replace

/*==============================================================================*/
	
/* PROGRAMS TO AUTOMATE TABULATIONS===========================================*/ 

********************************************************************************
* All below code from K Baskharan 
* Generic code to output one row of table

cap prog drop generaterow
program define generaterow
syntax, variable(varname) condition(string) 
	
	qui count
	local overalldenom=r(N)
	    
	qui sum `variable' if `variable' `condition'
	file write tablecontent (r(max)) _tab
	
	qui cou if `variable' `condition'
	local rowdenom = r(N)
	local colpct = 100*(r(N)/`overalldenom')
	file write tablecontent %9.0gc (`rowdenom')  (" (") %3.1f (`colpct') (")") _tab
	
	qui cou if exposure == 0
	local rowdenom = r(N)
	qui cou if exposure == 0 & `variable' `condition'
	local pct = 100*(r(N)/`rowdenom')
	file write tablecontent %9.0gc (r(N)) (" (") %3.1f  (`pct') (")") _tab
	
	qui cou if exposure == 1 
	local rowdenom = r(N)
	qui cou if exposure == 1 & `variable' `condition'
	local pct = 100*(r(N)/`rowdenom')
	file write tablecontent %9.0gc (r(N)) (" (") %3.1f  (`pct') (")") _n
	
end
/* Explanatory Notes 

defines a program (SAS macro/R function equivalent), generate row
the syntax row specifies two inputs for the program: 

	a VARNAME which is your variable 
	a CONDITION which is a string of some condition you impose 
	
the program counts if variable and condition and returns the counts
column percentages are then automatically generated
this is then written to the text file 'tablecontent' 
the number followed by space, brackets, formatted pct, end bracket and then tab

the format %3.1f specifies length of 3, followed by 1 dp. 

*/ 

********************************************************************************
* Generic code to output one section (varible) within table (calls above)

cap prog drop tabulatevariable
prog define tabulatevariable
syntax, variable(varname) min(real) max(real) [missing]

	local lab: variable label `variable'
	file write tablecontent ("`lab'") _n 

	forvalues varlevel = `min'/`max'{ 
		generaterow, variable(`variable') condition("==`varlevel'")
	}
	
	if "`missing'"!="" generaterow, variable(`variable') condition(">=.")

end

********************************************************************************

/* Explanatory Notes 

defines program tabulate variable 
syntax is : 

	- a VARNAME which you stick in variable 
	- a numeric minimum 
	- a numeric maximum 
	- optional missing option, default value is . 

forvalues lowest to highest of the variable, manually set for each var
run the generate row program for the level of the variable 
if there is a missing specified, then run the generate row for missing vals

*/ 

********************************************************************************
* Generic code to summarise a continuous variable 

cap prog drop summarizevariable 
prog define summarizevariable
syntax, variable(varname) 

	local lab: variable label `variable'
	file write tablecontent ("`lab'") _n 
	
	qui summarize `variable', d
	file write tablecontent ("Median (IQR)") _tab 
	file write tablecontent (r(p50)) (" (") (r(p25)) ("-") (r(p75)) (")") _tab
							
	qui summarize `variable' if exposure == 0, d
	file write tablecontent (r(p50)) (" (") (r(p25)) ("-") (r(p75)) (")") _tab
	
    qui summarize `variable' if exposure == 1, d
	file write tablecontent (r(p50)) (" (") (r(p25)) ("-") (r(p75)) (")") _n
	
	qui summarize `variable', d
	file write tablecontent ("Min, Max") _tab 
	file write tablecontent (r(min)) (", ") (r(max)) ("") _tab
							
	qui summarize `variable' if exposure == 0, d
	file write tablecontent (r(min)) (", ") (r(max)) ("") _tab
	
	qui summarize `variable' if exposure == 1, d
	file write tablecontent (r(min)) (", ") (r(max)) ("") _n
	
end

*combine all DOACs into one group for main table


foreach i in 1 2 3 4 {
	
use "$pathOutOAC/aurum_rivaroxaban_major_bleed_analysis`i'", clear
foreach doac in apixaban edoxaban_low edoxaban_high {
append using "$pathOutOAC/aurum_`doac'_major_bleed_analysis`i'"
}

preserve
keep if exposure == 1
sort patid indexdate
bysort patid: keep if _n == 1
tempfile doac
save `doac'
restore

keep if exposure == 0
sort patid indexdate
bysort patid: keep if _n == 1
append using `doac'
save "$pathOutOAC/aurum_doac_major_bleed_analysis`i'", replace
}

foreach i in 1 2 3 4 {
	
foreach doac in rivaroxaban apixaban edoxaban_low edoxaban_high doac {
	
* Input the file into Stata

	use "$pathOutOAC/aurum_`doac'_major_bleed_analysis`i'", clear
	
	xtile sys_bp_quartile=systolic_bp,n(4)
	
/* INVOKE PROGRAMS FOR TABLE 1================================================*/ 

*Set up output file
cap file close tablecontent
file open tablecontent using "$pathResults/OAC/`doac'_analysis`i'_baseline.txt", write text replace

file write tablecontent ("Table 1: Demographic and Clinical Characteristics") _n

* Exposure labelled columns

local lab0: label exposure 0
local lab1: label exposure 1
local lab2: label exposure 2

file write tablecontent _tab ("Total")				  			  _tab ///
							 ("`lab0'")			 			      _tab ///
							 ("`lab1'")			 			      _n

* DEMOGRAPHICS

gen byte cons=1
tabulatevariable, variable(cons) min(1) max(1) 
file write tablecontent _n 

tabulatevariable, variable(agegroup) min(1) max(6) 
file write tablecontent _n 

tabulatevariable, variable(male) min(0) max(1) 
file write tablecontent _n 

tabulatevariable, variable(eth5) min(0) max(5) missing 
file write tablecontent _n 

tabulatevariable, variable(imd) min(1) max(5) missing
file write tablecontent _n 

tabulatevariable, variable(region) min(1) max(9) missing
file write tablecontent _n 

tabulatevariable, variable(calendar_year) min(2012) max(2023) 
file write tablecontent _n 

tabulatevariable, variable(smokstatus) min(0) max(2) missing 
file write tablecontent _n 

tabulatevariable, variable(alcohol) min(0) max(6) missing
file write tablecontent _n 

tabulatevariable, variable(bmicat) min(0) max(3) missing
file write tablecontent _n 

tabulatevariable, variable(gpvisit_cat) min(0) max(2) missing
file write tablecontent _n 

tabulatevariable, variable(sys_bp_quartile) min(1) max(4) missing
file write tablecontent _n 

tabulatevariable, variable(ckd) min(0) max(5) missing
file write tablecontent _n 

foreach var in 		hypertension ///			
					copd ///
					liver_pancreatitis ///
					bleeding_disorder ///
					previous_bleed ///
					oesophageal_varices ///
					peptic_ulcer ///
					common_cancer  ///
					hf ///
					ihd ///
					pad ///
					dm ///
					stroke ///
					vte ///
					heart_valve_disease ///
					fracture ///
					ppi ///
					corticosteroid ///
					macrolide ///
					antiplatelet ///
					ssri_snri ///
					anticonvulsant_bleed ///
					diazepam ///
					nsaid ///
					amiodarone ///
					acei ///
					arb ///
					betablocker ///
					ccb ///
					statin ///
					oestrogen_like ///
					polypharmacy_main {
			   	
tabulatevariable, variable(`var') min(0) max(1) 
file write tablecontent _n 
}

file write tablecontent _n _n

* Other covariates (continuous)

summarizevariable, variable(age_index)
summarizevariable, variable(gpvisit_num)

file close tablecontent

}
}

*After COVID-19 hits
use "$pathOutOAC/aurum_rivaroxaban_covariate_major_bleed", clear
foreach doac in apixaban edoxaban_low edoxaban_high {
append using "$pathOutOAC/aurum_`doac'_covariate_major_bleed"
}

gen pandemic_start = mdy(03,16,2020)
keep if indexdate>=pandemic_start
	
preserve
keep if exposure == 1
sort patid indexdate
bysort patid: keep if _n == 1
tempfile doac
save `doac'
restore

keep if exposure == 0
sort patid indexdate
bysort patid: keep if _n == 1
append using `doac'

drop pandemic_start 
save "$pathOutOAC/aurum_doac_covariate_major_bleed", replace


foreach doac in rivaroxaban apixaban edoxaban_low edoxaban_high doac {
	
* Input the file into Stata

	use "$pathOutOAC/aurum_`doac'_covariate_major_bleed", clear
	
gen pandemic_start = mdy(03,16,2020)
keep if indexdate>=pandemic_start
	
	xtile sys_bp_quartile=systolic_bp,n(4)
	destring region, replace
	
/* INVOKE PROGRAMS FOR TABLE 1================================================*/ 

*Set up output file
cap file close tablecontent
file open tablecontent using "$pathResults/OAC/`doac'_duringaftercovid_baseline.txt", write text replace

file write tablecontent ("Table 1: Demographic and Clinical Characteristics") _n

* Exposure labelled columns

local lab0: label exposure 0
local lab1: label exposure 1
local lab2: label exposure 2

file write tablecontent _tab ("Total")				  			  _tab ///
							 ("`lab0'")			 			      _tab ///
							 ("`lab1'")			 			      _n

* DEMOGRAPHICS

gen byte cons=1
tabulatevariable, variable(cons) min(1) max(1) 
file write tablecontent _n 

tabulatevariable, variable(agegroup) min(1) max(6) 
file write tablecontent _n 

tabulatevariable, variable(male) min(0) max(1) 
file write tablecontent _n 

tabulatevariable, variable(eth5) min(0) max(5) missing 
file write tablecontent _n 

tabulatevariable, variable(imd) min(1) max(5) missing
file write tablecontent _n 

tabulatevariable, variable(region) min(1) max(9) missing
file write tablecontent _n 

tabulatevariable, variable(calendar_year) min(2012) max(2023) 
file write tablecontent _n 

tabulatevariable, variable(smokstatus) min(0) max(2) missing 
file write tablecontent _n 

tabulatevariable, variable(alcohol) min(0) max(6) missing
file write tablecontent _n 

tabulatevariable, variable(bmicat) min(0) max(3) missing
file write tablecontent _n 

tabulatevariable, variable(gpvisit_cat) min(0) max(2) missing
file write tablecontent _n 

tabulatevariable, variable(sys_bp_quartile) min(1) max(4) missing
file write tablecontent _n 

tabulatevariable, variable(ckd) min(0) max(5) missing
file write tablecontent _n 

foreach var in 		hypertension ///			
					copd ///
					liver_pancreatitis ///
					bleeding_disorder ///
					previous_bleed ///
					oesophageal_varices ///
					peptic_ulcer ///
					common_cancer  ///
					hf ///
					ihd ///
					pad ///
					dm ///
					stroke ///
					vte ///
					heart_valve_disease ///
					fracture ///
					ppi ///
					corticosteroid ///
					macrolide ///
					antiplatelet ///
					ssri_snri ///
					anticonvulsant_bleed ///
					diazepam ///
					nsaid ///
					amiodarone ///
					acei ///
					arb ///
					betablocker ///
					ccb ///
					statin ///
					oestrogen_like ///
					polypharmacy_main {
			   	
tabulatevariable, variable(`var') min(0) max(1) 
file write tablecontent _n 
}

file write tablecontent _n _n

* Other covariates (continuous)

summarizevariable, variable(age_index)
summarizevariable, variable(gpvisit_num)

file close tablecontent

}


* Close log file 
log close

