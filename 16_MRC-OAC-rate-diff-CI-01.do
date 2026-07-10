/*=========================================================================
DO FILE NAME:			16_MRC-OAC-rate-diff-CI-01

AUTHOR:					Angel Wong
VERSION:				v1
DATE VERSION CREATED:	3 Feb 2026
					
DATABASE:				
						CPRD Aurum Dec 2024 build

Aim:
Do-file to run the program to find the CI for each crude rate and crude rate difference
*=============================================================================*/
capture log close

/*******************************************************************************
Identify file locations
*******************************************************************************/
* open log file - no need as fast tool will create log files
log using "${pathLogs}/16_MRC-OAC-rate-diff-CI-01", text replace

/**********************************************************************
*Main analysis
***********************************************************************/

foreach doac in rivaroxaban apixaban dose_edoxaban_low dose_edoxaban_high {
		foreach outcome in major_bleed ischaemic_stroke MI vte {
			
/**********************************************************************
* Analysis 1: data from pre-pandemic 
***********************************************************************/
use "$pathOutOAC/aurum_`doac'_`outcome'_analysis1", clear

global outcome `outcome'
global stptime_name "$pathResults/OAC/rate_diff/stptime_`doac'_`outcome'_analysis1.txt"
global ratediff_name "$pathResults/OAC/rate_diff/rd_`doac'_`outcome'_analysis1.txt"

do "$pathDofiles/16_MRC-OAC-rate-diff-CI-program-01.do"

/**********************************************************************
* Analysis 2: study population from pre-pandemic and lengthening the follow-up to post-pandemic
***********************************************************************/
use "$pathOutOAC/aurum_`doac'_`outcome'_analysis2", clear

global outcome `outcome'
global stptime_name "$pathResults/OAC/rate_diff/stptime_`doac'_`outcome'_analysis2.txt"
global ratediff_name "$pathResults/OAC/rate_diff/rd_`doac'_`outcome'_analysis2.txt"

do "$pathDofiles/16_MRC-OAC-rate-diff-CI-program-01.do"

/**********************************************************************
* Analysis 3: Using all data for study population and identify outcome
***********************************************************************/
use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear

global outcome `outcome'
global stptime_name "$pathResults/OAC/rate_diff/stptime_`doac'_`outcome'_analysis3.txt"
global ratediff_name "$pathResults/OAC/rate_diff/rd_`doac'_`outcome'_analysis3.txt"

do "$pathDofiles/16_MRC-OAC-rate-diff-CI-program-01.do"

/**********************************************************************
* Analysis 4: Using data from post-pandemic only
***********************************************************************/
use "$pathOutOAC/aurum_`doac'_`outcome'_analysis4", clear

global outcome `outcome'
global stptime_name "$pathResults/OAC/rate_diff/stptime_`doac'_`outcome'_analysis4.txt"
global ratediff_name "$pathResults/OAC/rate_diff/rd_`doac'_`outcome'_analysis4.txt"

do "$pathDofiles/16_MRC-OAC-rate-diff-CI-program-01.do"
		}
}

log close


* open log file - no need as fast tool will create log files
log using "${pathLogs}/16_MRC-OAC-PSweight-rate-diff-CI-01", text replace

/**********************************************************************
*PS-weighted Main analysis
***********************************************************************/
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
foreach doac in rivaroxaban apixaban dose_edoxaban_low dose_edoxaban_high {
		foreach outcome in major_bleed {
			
/**********************************************************************
* Analysis 1: data from pre-pandemic 
***********************************************************************/
use "$pathOutOAC/aurum_`doac'_`outcome'_analysis1", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global doac `doac'
global outcome `outcome'
global analysis_num 1
global output "$pathResults/OAC/rate_diff/PS_`doac'_`outcome'_analysis1.txt"

if "`doac'" == "rivaroxaban" | "`doac'" =="apixaban" | "`doac'" == "dose_edoxaban_high" {
	global adjustavailable 0
}

if "`doac'" == "dose_edoxaban_low" {
global adjustavailable 1
global addition_covariate i.ckd
}

do "$pathDofiles/16_MRC-OAC-PSweight-rate-diff-CI-program-01.do"

/**********************************************************************
* Analysis 2: study population from pre-pandemic and lengthening the follow-up to post-pandemic
***********************************************************************/
use "$pathOutOAC/aurum_`doac'_`outcome'_analysis2", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global doac `doac'
global outcome `outcome'
global analysis_num 2
global output "$pathResults/OAC/rate_diff/PS_`doac'_`outcome'_analysis2.txt"

if "`doac'" == "rivaroxaban" | "`doac'" =="apixaban" | "`doac'" == "dose_edoxaban_high" {
	global adjustavailable 0
}

if "`doac'" == "dose_edoxaban_low" {
global adjustavailable 1
global addition_covariate i.ckd
}


do "$pathDofiles/16_MRC-OAC-PSweight-rate-diff-CI-program-01.do"

/**********************************************************************
* Analysis 3: Using all data for study population and identify outcome
***********************************************************************/
use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global doac `doac'
global outcome `outcome'
global analysis_num 3
global output "$pathResults/OAC/rate_diff/PS_`doac'_`outcome'_analysis3.txt"

if "`doac'" == "rivaroxaban" | "`doac'" =="apixaban" | "`doac'" == "dose_edoxaban_high" {
	global adjustavailable 0
}

if "`doac'" == "dose_edoxaban_low" {
global adjustavailable 1
global addition_covariate i.ckd
}

do "$pathDofiles/16_MRC-OAC-PSweight-rate-diff-CI-program-01.do"

/**********************************************************************
* Analysis 4: Using data from post-pandemic only
***********************************************************************/
use "$pathOutOAC/aurum_`doac'_`outcome'_analysis4", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global doac `doac'
global outcome `outcome'
global analysis_num 4
global output "$pathResults/OAC/rate_diff/PS_`doac'_`outcome'_analysis4.txt"
global adjustavailable 1

if "`doac'" == "rivaroxaban" {
global addition_covariate i.male i.smokstatus i.common_cancer  ///
					i.previous_bleed i.pad i.fracture ///
					i.ppi i.nsaid 
}
			
if "`doac'" =="apixaban" {
global addition_covariate i.bmicat i.smokstatus i.alcohol i.ckd  ///
					i.bleeding_disorder i.previous_bleed i.peptic_ulcer i.pad i.fracture ///
					i.ppi i.region
}

if "`doac'" == "dose_edoxaban_high" {
global addition_covariate i.male i.bmicat i.smokstatus i.bleeding_disorder  ///
					i.previous_bleed i.peptic_ulcer i.pad  ///
					i.antiplatelet i.nsaid ///
					i.imd i.region 
}

if "`doac'" == "dose_edoxaban_low" {
global addition_covariate i.agegroup i.smokstatus i.alcohol ///
					i.ckd i.copd i.hf i.ihd i.pad i.dm i.hypertension i.fracture ///
					i.corticosteroid i.macrolide i.antiplatelet i.ssri_snri ///
					i.acei i.region 
}


do "$pathDofiles/16_MRC-OAC-PSweight-rate-diff-CI-program-01.do"
		}
}

//bmi was recoded for high dose edoxaban in analysis 4 as convergence is not achieved
use "$pathOutOAC/aurum_dose_edoxaban_high_major_bleed_analysis4", clear
xtile sys_bp_quartile=systolic_bp,n(4)
codebook bmi 
replace bmicat = 2 if bmicat == 3 
replace bmicat = 0 if bmicat == 1

global doac dose_edoxaban_high
global outcome major_bleed
global analysis_num 4
global output "$pathResults/OAC/rate_diff/PS_dose_edoxaban_high_major_bleed_analysis4.txt"
global adjustavailable 1
global addition_covariate i.agegroup i.bmicat i.smokstatus i.alcohol ///
					i.ckd i.copd i.hf i.ihd i.pad i.dm i.hypertension i.fracture ///
					i.corticosteroid i.macrolide i.antiplatelet i.ssri_snri ///
					i.acei i.region 
		
do "$pathDofiles/16_MRC-OAC-PSweight-rate-diff-CI-program-01.do"


//ckd was recoded for low dose edoxaban in analysis as can't fit the model
use "$pathOutOAC/aurum_dose_edoxaban_low_major_bleed_analysis4", clear
xtile sys_bp_quartile=systolic_bp,n(4)
codebook ckd
replace ckd = 4 if ckd == 5

global doac dose_edoxaban_low
global outcome major_bleed
global analysis_num 4
global output "$pathResults/OAC/rate_diff/PS_dose_edoxaban_low_major_bleed_analysis4.txt"
global adjustavailable 1
global addition_covariate i.agegroup i.smokstatus i.alcohol ///
					i.ckd i.copd i.hf i.ihd i.pad i.dm i.hypertension i.fracture ///
					i.corticosteroid i.macrolide i.antiplatelet i.ssri_snri ///
					i.acei i.region 
					
do "$pathDofiles/16_MRC-OAC-PSweight-rate-diff-CI-program-01.do"

*stroke
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
	
foreach doac in rivaroxaban apixaban dose_edoxaban_low dose_edoxaban_high {
		foreach outcome in ischaemic_stroke {
			
/**********************************************************************
* Analysis 1: data from pre-pandemic 
***********************************************************************/
use "$pathOutOAC/aurum_`doac'_`outcome'_analysis1", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global doac `doac'
global outcome `outcome'
global analysis_num 1
global output "$pathResults/OAC/rate_diff/PS_`doac'_`outcome'_analysis1.txt"

if "`doac'" == "rivaroxaban" | "`doac'" =="apixaban" | "`doac'" == "dose_edoxaban_high" {
	global adjustavailable 0
}

if "`doac'" == "dose_edoxaban_low" {
global adjustavailable 1
global addition_covariate i.ckd
}

do "$pathDofiles/16_MRC-OAC-PSweight-rate-diff-CI-program-01.do"

/**********************************************************************
* Analysis 2: study population from pre-pandemic and lengthening the follow-up to post-pandemic
***********************************************************************/
use "$pathOutOAC/aurum_`doac'_`outcome'_analysis2", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global doac `doac'
global outcome `outcome'
global analysis_num 2
global output "$pathResults/OAC/rate_diff/PS_`doac'_`outcome'_analysis2.txt"

if "`doac'" == "rivaroxaban" | "`doac'" =="apixaban" | "`doac'" == "dose_edoxaban_high" {
	global adjustavailable 0
}

if "`doac'" == "dose_edoxaban_low" {
global adjustavailable 1
global addition_covariate i.ckd
}

do "$pathDofiles/16_MRC-OAC-PSweight-rate-diff-CI-program-01.do"

/**********************************************************************
* Analysis 3: Using all data for study population and identify outcome
***********************************************************************/
use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global doac `doac'
global outcome `outcome'
global analysis_num 3
global output "$pathResults/OAC/rate_diff/PS_`doac'_`outcome'_analysis3.txt"

if "`doac'" == "rivaroxaban" | "`doac'" =="apixaban" | "`doac'" == "dose_edoxaban_high" {
	global adjustavailable 0
}

if "`doac'" == "dose_edoxaban_low" {
global adjustavailable 1
global addition_covariate i.ckd
}

do "$pathDofiles/16_MRC-OAC-PSweight-rate-diff-CI-program-01.do"

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
	
foreach doac in rivaroxaban apixaban dose_edoxaban_low dose_edoxaban_high {
		foreach outcome in MI {
/**********************************************************************
* Analysis 1: data from pre-pandemic 
***********************************************************************/
use "$pathOutOAC/aurum_`doac'_`outcome'_analysis1", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global doac `doac'
global outcome `outcome'
global analysis_num 1
global output "$pathResults/OAC/rate_diff/PS_`doac'_`outcome'_analysis1.txt"

if "`doac'" == "rivaroxaban" | "`doac'" =="apixaban" | "`doac'" == "dose_edoxaban_high" {
	global adjustavailable 0
}

if "`doac'" == "dose_edoxaban_low" {
global adjustavailable 1
global addition_covariate i.ckd
}

do "$pathDofiles/16_MRC-OAC-PSweight-rate-diff-CI-program-01.do"

/**********************************************************************
* Analysis 2: study population from pre-pandemic and lengthening the follow-up to post-pandemic
***********************************************************************/
use "$pathOutOAC/aurum_`doac'_`outcome'_analysis2", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global doac `doac'
global outcome `outcome'
global analysis_num 2
global output "$pathResults/OAC/rate_diff/PS_`doac'_`outcome'_analysis2.txt"

if "`doac'" == "rivaroxaban" | "`doac'" =="apixaban" | "`doac'" == "dose_edoxaban_high" {
	global adjustavailable 0
}

if "`doac'" == "dose_edoxaban_low" {
global adjustavailable 1
global addition_covariate i.ckd
}

do "$pathDofiles/16_MRC-OAC-PSweight-rate-diff-CI-program-01.do"

/**********************************************************************
* Analysis 3: Using all data for study population and identify outcome
***********************************************************************/
use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global doac `doac'
global outcome `outcome'
global analysis_num 3
global output "$pathResults/OAC/rate_diff/PS_`doac'_`outcome'_analysis3.txt"

if "`doac'" == "rivaroxaban" | "`doac'" =="apixaban" | "`doac'" == "dose_edoxaban_high" {
	global adjustavailable 0
}

if "`doac'" == "dose_edoxaban_low" {
global adjustavailable 1
global addition_covariate i.ckd
}

do "$pathDofiles/16_MRC-OAC-PSweight-rate-diff-CI-program-01.do"

/**********************************************************************
* Analysis 4: Using data from post-pandemic only
***********************************************************************/
* <5 events in warfarin groups so redacted
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
	
foreach doac in rivaroxaban apixaban dose_edoxaban_low dose_edoxaban_high {
		foreach outcome in vte {
/**********************************************************************
* Analysis 1: data from pre-pandemic 
***********************************************************************/
use "$pathOutOAC/aurum_`doac'_`outcome'_analysis1", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global doac `doac'
global outcome `outcome'
global analysis_num 1
global output "$pathResults/OAC/rate_diff/PS_`doac'_`outcome'_analysis1.txt"

if "`doac'" == "rivaroxaban" | "`doac'" =="apixaban" | "`doac'" == "dose_edoxaban_high" {
	global adjustavailable 0
}

if "`doac'" == "dose_edoxaban_low" {
global adjustavailable 1
global addition_covariate i.ckd
}

do "$pathDofiles/16_MRC-OAC-PSweight-rate-diff-CI-program-01.do"
		
/**********************************************************************
* Analysis 2: study population from pre-pandemic and lengthening the follow-up to post-pandemic
***********************************************************************/
use "$pathOutOAC/aurum_`doac'_`outcome'_analysis2", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global doac `doac'
global outcome `outcome'
global analysis_num 2
global output "$pathResults/OAC/rate_diff/PS_`doac'_`outcome'_analysis2.txt"

if "`doac'" == "rivaroxaban" | "`doac'" =="apixaban" | "`doac'" == "dose_edoxaban_high" {
	global adjustavailable 0
}

if "`doac'" == "dose_edoxaban_low" {
global adjustavailable 1
global addition_covariate i.ckd
}

do "$pathDofiles/16_MRC-OAC-PSweight-rate-diff-CI-program-01.do"

/**********************************************************************
* Analysis 3: Using all data for study population and identify outcome
***********************************************************************/
use "$pathOutOAC/aurum_`doac'_`outcome'_timevary3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global doac `doac'
global outcome `outcome'
global analysis_num 3
global output "$pathResults/OAC/rate_diff/PS_`doac'_`outcome'_analysis3.txt"

if "`doac'" == "rivaroxaban" | "`doac'" =="apixaban" | "`doac'" == "dose_edoxaban_high" {
	global adjustavailable 0
}

if "`doac'" == "dose_edoxaban_low" {
global adjustavailable 1
global addition_covariate i.ckd
}

do "$pathDofiles/16_MRC-OAC-PSweight-rate-diff-CI-program-01.do"

/**********************************************************************
* Analysis 4: Using data from post-pandemic only
***********************************************************************/
* <5 events in warfarin groups so redacted
		}
}

log close