/*=========================================================================
DO FILE NAME:			14_OAC-Aurum-univariable-PS-model-03-time-varying

AUTHOR:					Angel Wong
VERSION:				v1
DATE VERSION CREATED:	6 Oct 2025
					
DATABASE:				
						CPRD Aurum Dec 2024 build

Aim:
To run unadjusted model only
Update: use distinct id rather than patid

only analysis 3 for time-varying analyses

*Revised version: to run the PS model considering the PS covariates between periods too
*Second revised version: adding adjusted variables CKD for low dose edoxaban for all outcomes as it was not balanced using PS
*=============================================================================*/

capture log close

/*******************************************************************************
Identify file locations
*******************************************************************************/
* open log file - no need as fast tool will create log files
log using "${pathLogs}/14_OAC-Aurum-univariable-PS-model-02-time-varying", text replace

/**********************************************************************
* Analysis 3: Using all data for study population and identify outcome
***********************************************************************/
di "Analysis 3 crude: `doac' `outcome'"

use "$pathOutOAC/aurum_`doac'_covariate_`outcome'", clear
drop if indexdate == stime_`outcome'

tab exposure `outcome', m row

egen groupid = group(patid exposure)
global sample_size = _N

destring region, replace

*remove those who initiated antibiotics when pandemic started
gen pandemic_start = mdy(03,16,2020)
gen pandemic_end = mdy(04,17,2022)
format pandemic_start pandemic_end stime_`outcome' %td

gen period = 1 if indexdate>=pandemic_start
replace period = 0 if period == .

gen time_enter = 0
gen time_enter_2 = indexdate
gen startd = indexdate
format startd %td

*set the second period for time-varying
preserve
keep if stime_`outcome' > pandemic_start & indexdate<pandemic_start
expand 2, generate(newv)
sort patid newv
replace `outcome' = 0 if newv == 0 //955 when newv  == 0 means pre-pandemic period
*replace enddate for pre-pandemic period as pandemic start date
replace stime_`outcome' = pandemic_start if newv == 0

replace startd = indexdate if newv == 0
replace startd = pandemic_start if newv == 1

replace period = 0 if newv == 0
replace period = 1 if newv == 1

*set up time-enter date
replace time_enter = pandemic_start - indexdate if newv == 1
replace time_enter_2 = mdy(03,16,2020) if newv == 1

save "`doac'_`outcome'_timevary3", replace
restore

drop if stime_`outcome' > pandemic_start & indexdate<pandemic_start
append using "`doac'_`outcome'_timevary3"

su stime_`outcome', format

tab exposure `outcome', m row
format time_enter_2 %td

save "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", replace

stset stime_`outcome', id(groupid) fail(`outcome') enter(time_enter_2) origin(indexdate)	

cap file close tablecontent
file open tablecontent using "$pathResults/OAC/crude_`doac'_`outcome'_timevary3.txt", write text replace

file write tablecontent ("DOAC vs warfarin") _tab ("HR") _tab ("95% CI") _n				

file write tablecontent _n

di "Analysis 3 crude: `doac' `outcome'"

stcox i.exposure, vce(robust)
lincom 1.exposure, eform 

file write tablecontent %4.2f (r(estimate)) _tab %4.2f (r(lb)) (" - ") %4.2f (r(ub)) _n 

di "Analysis 3 crude: `doac' `outcome' with interaction"

stcox i.exposure##i.period, vce(robust)

lincom 1.exposure#1.period, eform 
file write tablecontent ("interaction") _tab %4.2f (r(estimate)) _tab %4.2f (r(lb)) (" - ") %4.2f (r(ub)) _n

foreach i in 0 1 {
lincom 1.exposure + `i'.period#1.exposure, eform 
file write tablecontent ("period") _tab (`i') _tab %4.2f (r(estimate)) _tab %4.2f (r(lb)) (" - ") %4.2f (r(ub)) _n

}

file write tablecontent _n
file close tablecontent

		}
}

log close

/*******************************************************************************
Identify file locations
*******************************************************************************/
* open log file - no need as fast tool will create log files
cap log using "${pathLogs}/14_OAC-Aurum-PS-model-01-time-varying", text replace

/**********************************************************************
* Specify PS covariates
***********************************************************************/
*major bleeding
global psvarlist i.agegroup /// 
					i.male  ///
					i.gpvisit_cat ///
					i.bmicat ///
					i.smokstatus ///
					i.alcohol ///		
					i.sys_bp_quartile ///
					i.ckd ///
					i.copd ///
					i.liver_pancreatitis ///
					i.bleeding_disorder ///
					i.oesophageal_varices ///
					i.common_cancer  ///
					i.previous_bleed ///
					i.hf ///
					i.ihd ///
					i.peptic_ulcer ///
					i.pad ///
					i.dm ///
					i.stroke ///
					i.vte ///
					i.hypertension ///
					i.heart_valve_disease ///
					i.fracture ///
					i.ppi ///
					i.corticosteroid ///
					i.macrolide ///
					i.antiplatelet ///
					i.ssri_snri ///
					i.anticonvulsant_bleed ///
					i.nsaid ///
					i.acei ///
					i.imd    ///
					i.region ///
					i.polypharmacy_main ///
					i.eth5 

foreach doac in rivaroxaban apixaban edoxaban_low edoxaban_high dose_edoxaban_low dose_edoxaban_high {
		foreach outcome in major_bleed {

/**********************************************************************
* Analysis 3: Using all data for study population and identify outcome
***********************************************************************/
di "Analysis 3 PS: `doac' `outcome' approach 1"

use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_`doac'_`outcome'_timevary3.txt"
global stddiff "$pathResults/OAC/stddiff_`doac'_`outcome'_timevary3.txt"

do "$pathDofiles/14_OAC-Aurum-PS-model-01-time-vary-program.do"

*generate PS by period, trimming in different initiation period
di "Analysis 3 PS: `doac' `outcome' approach 2"

use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_`doac'_`outcome'_timevary3byp.txt"
global stddiff "$pathResults/OAC/stddiff_`doac'_`outcome'_timevary3byp.txt"

do "$pathDofiles/14b_OAC-Aurum-PS-model-01-time-vary-program-byperiod.do"
	
*generate PS by period trimming regardless of initiation period
di "Analysis 3 PS: `doac' `outcome' approach 3"

use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_`doac'_`outcome'_timevary3bypt.txt"
global stddiff "$pathResults/OAC/stddiff_`doac'_`outcome'_timevary3bypt.txt"

do "$pathDofiles/14c_OAC-Aurum-PS-model-01-time-vary-program-byperiod-trim.do"
		}
}
*stroke (remove i.stroke from the list)				
global psvarlist 	i.agegroup /// 
					i.male  ///
					i.gpvisit_cat ///
					i.bmicat ///
					i.smokstatus ///
					i.alcohol ///		
					i.sys_bp_quartile ///
					i.ckd ///
					i.copd ///
					i.liver_pancreatitis ///
					i.oesophageal_varices ///
					i.common_cancer  ///
					i.hf ///
					i.ihd ///
					i.pad ///
					i.dm ///
					i.vte ///
					i.hypertension ///
					i.heart_valve_disease ///
					i.fracture ///
					i.macrolide ///
					i.antiplatelet ///
					i.diazepam ///
					i.nsaid ///
					i.amiodarone ///
					i.acei ///
					i.arb ///
					i.betablocker ///
					i.ccb ///
					i.statin ///
					i.imd    ///
					i.region ///
					i.polypharmacy_main ///
					i.eth5 
	
foreach doac in rivaroxaban apixaban edoxaban_low edoxaban_high dose_edoxaban_low dose_edoxaban_high {
		foreach outcome in ischaemic_stroke {

/**********************************************************************
* Analysis 3: Using all data for study population and identify outcome
***********************************************************************/
di "Analysis 3 PS: `doac' `outcome' approach 1"

use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_`doac'_`outcome'_timevary3.txt"
global stddiff "$pathResults/OAC/stddiff_`doac'_`outcome'_timevary3.txt"

do "$pathDofiles/14_OAC-Aurum-PS-model-01-time-vary-program.do"

*generate PS by period, trimming in different initiation period
di "Analysis 3 PS: `doac' `outcome' approach 2"

use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_`doac'_`outcome'_timevary3byp.txt"
global stddiff "$pathResults/OAC/stddiff_`doac'_`outcome'_timevary3byp.txt"

do "$pathDofiles/14b_OAC-Aurum-PS-model-01-time-vary-program-byperiod.do"
	
*generate PS by period trimming regardless of initiation period
di "Analysis 3 PS: `doac' `outcome' approach 3"

use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_`doac'_`outcome'_timevary3bypt.txt"
global stddiff "$pathResults/OAC/stddiff_`doac'_`outcome'_timevary3bypt.txt"

do "$pathDofiles/14c_OAC-Aurum-PS-model-01-time-vary-program-byperiod-trim.do"
		}
}
*MI				
global psvarlist 	i.agegroup /// 
					i.male  ///
					i.gpvisit_cat ///
					i.bmicat ///
					i.smokstatus ///
					i.alcohol ///		
					i.sys_bp_quartile ///
					i.ckd ///
					i.copd ///
					i.liver_pancreatitis ///
					i.oesophageal_varices ///
					i.common_cancer  ///
					i.hf ///
					i.ihd ///
					i.pad ///
					i.dm ///
					i.stroke ///
					i.vte ///
					i.hypertension ///
					i.heart_valve_disease ///
					i.fracture ///
					i.macrolide ///
					i.antiplatelet ///
					i.diazepam ///
					i.nsaid ///
					i.amiodarone ///
					i.acei ///
					i.arb ///
					i.betablocker ///
					i.ccb ///
					i.statin ///
					i.imd    ///
					i.region ///
					i.polypharmacy_main ///
					i.eth5 
	
foreach doac in rivaroxaban apixaban edoxaban_low edoxaban_high dose_edoxaban_low dose_edoxaban_high {
		foreach outcome in MI {

/**********************************************************************
* Analysis 3: Using all data for study population and identify outcome
***********************************************************************/
di "Analysis 3 PS: `doac' `outcome' approach 1"

use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_`doac'_`outcome'_timevary3.txt"
global stddiff "$pathResults/OAC/stddiff_`doac'_`outcome'_timevary3.txt"

do "$pathDofiles/14_OAC-Aurum-PS-model-01-time-vary-program.do"

*generate PS by period, trimming in different initiation period
di "Analysis 3 PS: `doac' `outcome' approach 2"

use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_`doac'_`outcome'_timevary3byp.txt"
global stddiff "$pathResults/OAC/stddiff_`doac'_`outcome'_timevary3byp.txt"

do "$pathDofiles/14b_OAC-Aurum-PS-model-01-time-vary-program-byperiod.do"
	
*generate PS by period trimming regardless of initiation period
di "Analysis 3 PS: `doac' `outcome' approach 3"

use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_`doac'_`outcome'_timevary3bypt.txt"
global stddiff "$pathResults/OAC/stddiff_`doac'_`outcome'_timevary3bypt.txt"

do "$pathDofiles/14c_OAC-Aurum-PS-model-01-time-vary-program-byperiod-trim.do"

		}
}


*VTE (include oestrogen too, remove i.vte from the list)
global psvarlist 	i.agegroup /// 
					i.male  ///
					i.gpvisit_cat ///
					i.bmicat ///
					i.smokstatus ///
					i.alcohol ///		
					i.sys_bp_quartile ///
					i.ckd ///
					i.copd ///
					i.liver_pancreatitis ///
					i.oesophageal_varices ///
					i.common_cancer  ///
					i.hf ///
					i.ihd ///
					i.pad ///
					i.dm ///
					i.stroke ///
					i.hypertension ///
					i.heart_valve_disease ///
					i.fracture ///
					i.macrolide ///
					i.antiplatelet ///
					i.diazepam ///
					i.nsaid ///
					i.amiodarone ///
					i.acei ///
					i.arb ///
					i.betablocker ///
					i.ccb ///
					i.statin ///
					i.imd    ///
					i.region ///
					i.polypharmacy_main ///
					i.eth5 ///
					i.oestrogen_like 
	
foreach doac in rivaroxaban apixaban edoxaban_low edoxaban_high dose_edoxaban_low dose_edoxaban_high {
		foreach outcome in vte {
/**********************************************************************
* Analysis 3: Using all data for study population and identify outcome
***********************************************************************/
di "Analysis 3 PS: `doac' `outcome' approach 1"

use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_`doac'_`outcome'_timevary3.txt"
global stddiff "$pathResults/OAC/stddiff_`doac'_`outcome'_timevary3.txt"

do "$pathDofiles/14_OAC-Aurum-PS-model-01-time-vary-program.do"

*generate PS by period, trimming in different initiation period
di "Analysis 3 PS: `doac' `outcome' approach 2"

use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_`doac'_`outcome'_timevary3byp.txt"
global stddiff "$pathResults/OAC/stddiff_`doac'_`outcome'_timevary3byp.txt"

do "$pathDofiles/14b_OAC-Aurum-PS-model-01-time-vary-program-byperiod.do"
	
*generate PS by period trimming regardless of initiation period
di "Analysis 3 PS: `doac' `outcome' approach 3"

use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_`doac'_`outcome'_timevary3bypt.txt"
global stddiff "$pathResults/OAC/stddiff_`doac'_`outcome'_timevary3bypt.txt"

do "$pathDofiles/14c_OAC-Aurum-PS-model-01-time-vary-program-byperiod-trim.do"
		}
}

log close

cap log close
/*******************************************************************************
Identify file locations
*******************************************************************************/
* open log file - no need as fast tool will create log files
log using "${pathLogs}/14_OAC-Aurum-PS-model-01-time-varying-additional adjust", text replace

/**********************************************************************
* Specify PS covariates
***********************************************************************/
*major bleeding
global psvarlist i.agegroup /// 
					i.male  ///
					i.gpvisit_cat ///
					i.bmicat ///
					i.smokstatus ///
					i.alcohol ///		
					i.sys_bp_quartile ///
					i.ckd ///
					i.copd ///
					i.liver_pancreatitis ///
					i.bleeding_disorder ///
					i.oesophageal_varices ///
					i.common_cancer  ///
					i.previous_bleed ///
					i.hf ///
					i.ihd ///
					i.peptic_ulcer ///
					i.pad ///
					i.dm ///
					i.stroke ///
					i.vte ///
					i.hypertension ///
					i.heart_valve_disease ///
					i.fracture ///
					i.ppi ///
					i.corticosteroid ///
					i.macrolide ///
					i.antiplatelet ///
					i.ssri_snri ///
					i.anticonvulsant_bleed ///
					i.nsaid ///
					i.acei ///
					i.imd    ///
					i.region ///
					i.polypharmacy_main ///
					i.eth5 

foreach doac in dose_edoxaban_low {
		foreach outcome in major_bleed {

/**********************************************************************
* Analysis 3: Using all data for study population and identify outcome
***********************************************************************/
di "Analysis 3 PS: `doac' `outcome' approach 1"

use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global addition_covariate i.ckd
global result_txt "$pathResults/OAC/PSadj_`doac'_`outcome'_timevary3.txt"

do "$pathDofiles/14a_OAC-Aurum-PS-model-01-time-vary-program-additional adjust.do"

*generate PS by period, trimming in different initiation period
di "Analysis 3 PS: `doac' `outcome' approach 2"

use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global addition_covariate i.ckd
global result_txt "$pathResults/OAC/PSadj_`doac'_`outcome'_timevary3byp.txt"

do "$pathDofiles/14ab_OAC-Aurum-PS-model-01-time-vary-program-byperiod-addional adjust.do"
	
*generate PS by period trimming regardless of initiation period
di "Analysis 3 PS: `doac' `outcome' approach 3"

use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global addition_covariate i.ckd
global result_txt "$pathResults/OAC/PSadj_`doac'_`outcome'_timevary3bypt.txt"

do "$pathDofiles/14ac_OAC-Aurum-PS-model-01-time-vary-program-byperiod-trim-additional adjust.do"
		}
}
*stroke (remove i.stroke from the list)				
global psvarlist 	i.agegroup /// 
					i.male  ///
					i.gpvisit_cat ///
					i.bmicat ///
					i.smokstatus ///
					i.alcohol ///		
					i.sys_bp_quartile ///
					i.ckd ///
					i.copd ///
					i.liver_pancreatitis ///
					i.oesophageal_varices ///
					i.common_cancer  ///
					i.hf ///
					i.ihd ///
					i.pad ///
					i.dm ///
					i.vte ///
					i.hypertension ///
					i.heart_valve_disease ///
					i.fracture ///
					i.macrolide ///
					i.antiplatelet ///
					i.diazepam ///
					i.nsaid ///
					i.amiodarone ///
					i.acei ///
					i.arb ///
					i.betablocker ///
					i.ccb ///
					i.statin ///
					i.imd    ///
					i.region ///
					i.polypharmacy_main ///
					i.eth5 
	
foreach doac in dose_edoxaban_low {
		foreach outcome in ischaemic_stroke {

/**********************************************************************
* Analysis 3: Using all data for study population and identify outcome
***********************************************************************/
di "Analysis 3 PS: `doac' `outcome' approach 1"

use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global addition_covariate i.ckd
global result_txt "$pathResults/OAC/PSadj_`doac'_`outcome'_timevary3.txt"

do "$pathDofiles/14a_OAC-Aurum-PS-model-01-time-vary-program-additional adjust.do"

*generate PS by period, trimming in different initiation period
di "Analysis 3 PS: `doac' `outcome' approach 2"

use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global addition_covariate i.ckd
global result_txt "$pathResults/OAC/PSadj_`doac'_`outcome'_timevary3byp.txt"

do "$pathDofiles/14ab_OAC-Aurum-PS-model-01-time-vary-program-byperiod-addional adjust.do"
	
*generate PS by period trimming regardless of initiation period
di "Analysis 3 PS: `doac' `outcome' approach 3"

use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global addition_covariate i.ckd
global result_txt "$pathResults/OAC/PSadj_`doac'_`outcome'_timevary3bypt.txt"

do "$pathDofiles/14ac_OAC-Aurum-PS-model-01-time-vary-program-byperiod-trim-additional adjust.do"
		}
}
*MI				
global psvarlist 	i.agegroup /// 
					i.male  ///
					i.gpvisit_cat ///
					i.bmicat ///
					i.smokstatus ///
					i.alcohol ///		
					i.sys_bp_quartile ///
					i.ckd ///
					i.copd ///
					i.liver_pancreatitis ///
					i.oesophageal_varices ///
					i.common_cancer  ///
					i.hf ///
					i.ihd ///
					i.pad ///
					i.dm ///
					i.stroke ///
					i.vte ///
					i.hypertension ///
					i.heart_valve_disease ///
					i.fracture ///
					i.macrolide ///
					i.antiplatelet ///
					i.diazepam ///
					i.nsaid ///
					i.amiodarone ///
					i.acei ///
					i.arb ///
					i.betablocker ///
					i.ccb ///
					i.statin ///
					i.imd    ///
					i.region ///
					i.polypharmacy_main ///
					i.eth5 
	
foreach doac in dose_edoxaban_low {
		foreach outcome in MI {

/**********************************************************************
* Analysis 3: Using all data for study population and identify outcome
***********************************************************************/
di "Analysis 3 PS: `doac' `outcome' approach 1"

use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global addition_covariate i.ckd
global result_txt "$pathResults/OAC/PSadj_`doac'_`outcome'_timevary3.txt"

do "$pathDofiles/14a_OAC-Aurum-PS-model-01-time-vary-program-additional adjust.do"

*generate PS by period, trimming in different initiation period
di "Analysis 3 PS: `doac' `outcome' approach 2"

use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global addition_covariate i.ckd
global result_txt "$pathResults/OAC/PSadj_`doac'_`outcome'_timevary3byp.txt"

do "$pathDofiles/14ab_OAC-Aurum-PS-model-01-time-vary-program-byperiod-addional adjust.do"
	
*generate PS by period trimming regardless of initiation period
di "Analysis 3 PS: `doac' `outcome' approach 3"

use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global addition_covariate i.ckd
global result_txt "$pathResults/OAC/PSadj_`doac'_`outcome'_timevary3bypt.txt"

do "$pathDofiles/14ac_OAC-Aurum-PS-model-01-time-vary-program-byperiod-trim-additional adjust.do"

		}
}


*VTE (include oestrogen too, remove i.vte from the list)
global psvarlist 	i.agegroup /// 
					i.male  ///
					i.gpvisit_cat ///
					i.bmicat ///
					i.smokstatus ///
					i.alcohol ///		
					i.sys_bp_quartile ///
					i.ckd ///
					i.copd ///
					i.liver_pancreatitis ///
					i.oesophageal_varices ///
					i.common_cancer  ///
					i.hf ///
					i.ihd ///
					i.pad ///
					i.dm ///
					i.stroke ///
					i.hypertension ///
					i.heart_valve_disease ///
					i.fracture ///
					i.macrolide ///
					i.antiplatelet ///
					i.diazepam ///
					i.nsaid ///
					i.amiodarone ///
					i.acei ///
					i.arb ///
					i.betablocker ///
					i.ccb ///
					i.statin ///
					i.imd    ///
					i.region ///
					i.polypharmacy_main ///
					i.eth5 ///
					i.oestrogen_like 
	
foreach doac in dose_edoxaban_low {
		foreach outcome in vte {

/**********************************************************************
* Analysis 3: Using all data for study population and identify outcome
***********************************************************************/
di "Analysis 3 PS: `doac' `outcome' approach 1"

use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global addition_covariate i.ckd
global result_txt "$pathResults/OAC/PSadj_`doac'_`outcome'_timevary3.txt"

do "$pathDofiles/14a_OAC-Aurum-PS-model-01-time-vary-program-additional adjust.do"

*generate PS by period, trimming in different initiation period
di "Analysis 3 PS: `doac' `outcome' approach 2"

use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global addition_covariate i.ckd
global result_txt "$pathResults/OAC/PSadj_`doac'_`outcome'_timevary3byp.txt"

do "$pathDofiles/14ab_OAC-Aurum-PS-model-01-time-vary-program-byperiod-addional adjust.do"
	
*generate PS by period trimming regardless of initiation period
di "Analysis 3 PS: `doac' `outcome' approach 3"

use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global addition_covariate i.ckd
global result_txt "$pathResults/OAC/PSadj_`doac'_`outcome'_timevary3bypt.txt"

do "$pathDofiles/14ac_OAC-Aurum-PS-model-01-time-vary-program-byperiod-trim-additional adjust.do"
		}
}

log close