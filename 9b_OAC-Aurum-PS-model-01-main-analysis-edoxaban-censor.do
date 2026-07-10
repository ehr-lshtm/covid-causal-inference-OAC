/*=========================================================================
DO FILE NAME:			9b_OAC-Aurum-PS-model-01-main-analysis-edoxaban_censor

AUTHOR:					Angel Wong
VERSION:				v1
DATE VERSION CREATED:	12 Aug 2025
					
DATABASE:				
						CPRD Aurum Dec 2024 build

Aim:
To run PS model 
*=============================================================================*/

capture log close

/*******************************************************************************
Identify file locations
*******************************************************************************/
* open log file - no need as fast tool will create log files
log using "${pathLogs}/9b_OAC-Aurum-PS-model-01-main-analysis-edoxaban_censor", text replace

/*very low in age group in edoxaban low so collapse the first age group together for edoxaban low group*/
foreach doac in edoxaban_low  {
		foreach outcome in major_bleed ischaemic_stroke MI vte {
			foreach num in 1 2 3 4 {
use "$pathOutOAC/aurum_dose_`doac'_`outcome'_analysis`num'", clear
replace agegroup = 1 if agegroup == 2
save "$pathOutOAC/aurum_dose_`doac'_`outcome'_analysis`num'", replace
			}
		}
}

/*very low/no one in ethnicity - non white/GP category in all warfarin group so collapse category for analysis 4*/
foreach doac in edoxaban_low edoxaban_high {
		foreach outcome in major_bleed ischaemic_stroke MI vte {
use "$pathOutOAC/aurum_dose_`doac'_`outcome'_analysis4", clear
replace eth5 = 1 if eth5!=. & eth5 >1
replace gpvisit_cat = 1 if gpvisit_cat == 2
save "$pathOutOAC/aurum_dose_`doac'_`outcome'_analysis4", replace
			}
		}

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

foreach doac in edoxaban_low edoxaban_high {
		foreach outcome in major_bleed {
/**********************************************************************
* Analysis 1: data from pre-pandemic 
***********************************************************************/
use "$pathOutOAC/aurum_dose_`doac'_`outcome'_analysis1", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis1
global interactionavailable 0
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_dose_`doac'_`outcome'_analysis1.txt"
global graphbeforeps "$pathResults/OAC/beforeps_dose_`doac'_`outcome'_analysis1.svg"
global graphafterps "$pathResults/OAC/afterps_dose_`doac'_`outcome'_analysis1.svg"
global stddiff "$pathResults/OAC/stddiff_dose_`doac'_`outcome'_analysis1.txt"

do "$pathDofiles/9_OAC-Aurum-PS-model-01-program.do"

/**********************************************************************
* Analysis 2: study population from pre-pandemic and lengthening the follow-up to post-pandemic
***********************************************************************/
use "$pathOutOAC/aurum_dose_`doac'_`outcome'_analysis2", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis2
global interactionavailable 0
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_dose_`doac'_`outcome'_analysis2.txt"
global graphbeforeps "$pathResults/OAC/beforeps_dose_`doac'_`outcome'_analysis2.svg"
global graphafterps "$pathResults/OAC/afterps_dose_`doac'_`outcome'_analysis2.svg"
global stddiff "$pathResults/OAC/stddiff_dose_`doac'_`outcome'_analysis2.txt"

do "$pathDofiles/9_OAC-Aurum-PS-model-01-program.do"

/**********************************************************************
* Analysis 3: Using all data for study population and identify outcome
***********************************************************************/
use "$pathOutOAC/aurum_dose_`doac'_`outcome'_analysis3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_dose_`doac'_`outcome'_analysis3.txt"
global graphbeforeps "$pathResults/OAC/beforeps_dose_`doac'_`outcome'_analysis3.svg"
global graphafterps "$pathResults/OAC/afterps_dose_`doac'_`outcome'_analysis3.svg"
global stddiff "$pathResults/OAC/stddiff_dose_`doac'_`outcome'_analysis3.txt"

do "$pathDofiles/9_OAC-Aurum-PS-model-01-program.do"

/**********************************************************************
* Analysis 4: Using data from post-pandemic only
***********************************************************************/
use "$pathOutOAC/aurum_dose_`doac'_`outcome'_analysis4", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis4
global interactionavailable 0
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_dose_`doac'_`outcome'_analysis4.txt"
global graphbeforeps "$pathResults/OAC/beforeps_dose_`doac'_`outcome'_analysis4.svg"
global graphafterps "$pathResults/OAC/afterps_dose_`doac'_`outcome'_analysis4.svg"
global stddiff "$pathResults/OAC/stddiff_dose_`doac'_`outcome'_analysis4.txt"

do "$pathDofiles/9_OAC-Aurum-PS-model-01-program.do"

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
	
foreach doac in edoxaban_low edoxaban_high {
		foreach outcome in ischaemic_stroke {
/**********************************************************************
* Analysis 1: data from pre-pandemic 
***********************************************************************/
use "$pathOutOAC/aurum_dose_`doac'_`outcome'_analysis1", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis1
global interactionavailable 0
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_dose_`doac'_`outcome'_analysis1.txt"
global graphbeforeps "$pathResults/OAC/beforeps_dose_`doac'_`outcome'_analysis1.svg"
global graphafterps "$pathResults/OAC/afterps_dose_`doac'_`outcome'_analysis1.svg"
global stddiff "$pathResults/OAC/stddiff_dose_`doac'_`outcome'_analysis1.txt"

do "$pathDofiles/9_OAC-Aurum-PS-model-01-program.do"

/**********************************************************************
* Analysis 2: study population from pre-pandemic and lengthening the follow-up to post-pandemic
***********************************************************************/
use "$pathOutOAC/aurum_dose_`doac'_`outcome'_analysis2", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis2
global interactionavailable 0
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_dose_`doac'_`outcome'_analysis2.txt"
global graphbeforeps "$pathResults/OAC/beforeps_dose_`doac'_`outcome'_analysis2.svg"
global graphafterps "$pathResults/OAC/afterps_dose_`doac'_`outcome'_analysis2.svg"
global stddiff "$pathResults/OAC/stddiff_dose_`doac'_`outcome'_analysis2.txt"

do "$pathDofiles/9_OAC-Aurum-PS-model-01-program.do"

/**********************************************************************
* Analysis 3: Using all data for study population and identify outcome
***********************************************************************/
use "$pathOutOAC/aurum_dose_`doac'_`outcome'_analysis3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_dose_`doac'_`outcome'_analysis3.txt"
global graphbeforeps "$pathResults/OAC/beforeps_dose_`doac'_`outcome'_analysis3.svg"
global graphafterps "$pathResults/OAC/afterps_dose_`doac'_`outcome'_analysis3.svg"
global stddiff "$pathResults/OAC/stddiff_dose_`doac'_`outcome'_analysis3.txt"

do "$pathDofiles/9_OAC-Aurum-PS-model-01-program.do"

/**********************************************************************
* Analysis 4: Using data from post-pandemic only
***********************************************************************/
use "$pathOutOAC/aurum_dose_`doac'_`outcome'_analysis4", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis4
global interactionavailable 0
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_dose_`doac'_`outcome'_analysis4.txt"
global graphbeforeps "$pathResults/OAC/beforeps_dose_`doac'_`outcome'_analysis4.svg"
global graphafterps "$pathResults/OAC/afterps_dose_`doac'_`outcome'_analysis4.svg"
global stddiff "$pathResults/OAC/stddiff_dose_`doac'_`outcome'_analysis4.txt"

do "$pathDofiles/9_OAC-Aurum-PS-model-01-program.do"
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
	
foreach doac in edoxaban_low edoxaban_high {
		foreach outcome in MI {
/**********************************************************************
* Analysis 1: data from pre-pandemic 
***********************************************************************/
use "$pathOutOAC/aurum_dose_`doac'_`outcome'_analysis1", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis1
global interactionavailable 0
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_dose_`doac'_`outcome'_analysis1.txt"
global graphbeforeps "$pathResults/OAC/beforeps_dose_`doac'_`outcome'_analysis1.svg"
global graphafterps "$pathResults/OAC/afterps_dose_`doac'_`outcome'_analysis1.svg"
global stddiff "$pathResults/OAC/stddiff_dose_`doac'_`outcome'_analysis1.txt"

do "$pathDofiles/9_OAC-Aurum-PS-model-01-program.do"

/**********************************************************************
* Analysis 2: study population from pre-pandemic and lengthening the follow-up to post-pandemic
***********************************************************************/
use "$pathOutOAC/aurum_dose_`doac'_`outcome'_analysis2", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis2
global interactionavailable 0
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_dose_`doac'_`outcome'_analysis2.txt"
global graphbeforeps "$pathResults/OAC/beforeps_dose_`doac'_`outcome'_analysis2.svg"
global graphafterps "$pathResults/OAC/afterps_dose_`doac'_`outcome'_analysis2.svg"
global stddiff "$pathResults/OAC/stddiff_dose_`doac'_`outcome'_analysis2.txt"

do "$pathDofiles/9_OAC-Aurum-PS-model-01-program.do"

/**********************************************************************
* Analysis 3: Using all data for study population and identify outcome
***********************************************************************/
use "$pathOutOAC/aurum_dose_`doac'_`outcome'_analysis3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_dose_`doac'_`outcome'_analysis3.txt"
global graphbeforeps "$pathResults/OAC/beforeps_dose_`doac'_`outcome'_analysis3.svg"
global graphafterps "$pathResults/OAC/afterps_dose_`doac'_`outcome'_analysis3.svg"
global stddiff "$pathResults/OAC/stddiff_dose_`doac'_`outcome'_analysis3.txt"

do "$pathDofiles/9_OAC-Aurum-PS-model-01-program.do"

/**********************************************************************
* Analysis 4: Using data from post-pandemic only
***********************************************************************/
use "$pathOutOAC/aurum_dose_`doac'_`outcome'_analysis4", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis4
global interactionavailable 0
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_dose_`doac'_`outcome'_analysis4.txt"
global graphbeforeps "$pathResults/OAC/beforeps_dose_`doac'_`outcome'_analysis4.svg"
global graphafterps "$pathResults/OAC/afterps_dose_`doac'_`outcome'_analysis4.svg"
global stddiff "$pathResults/OAC/stddiff_dose_`doac'_`outcome'_analysis4.txt"

do "$pathDofiles/9_OAC-Aurum-PS-model-01-program.do"

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
	
foreach doac in edoxaban_low edoxaban_high {
		foreach outcome in vte {
/**********************************************************************
* Analysis 1: data from pre-pandemic 
***********************************************************************/
use "$pathOutOAC/aurum_dose_`doac'_`outcome'_analysis1", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis1
global interactionavailable 0
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_dose_`doac'_`outcome'_analysis1.txt"
global graphbeforeps "$pathResults/OAC/beforeps_dose_`doac'_`outcome'_analysis1.svg"
global graphafterps "$pathResults/OAC/afterps_dose_`doac'_`outcome'_analysis1.svg"
global stddiff "$pathResults/OAC/stddiff_dose_`doac'_`outcome'_analysis1.txt"

do "$pathDofiles/9_OAC-Aurum-PS-model-01-program.do"

/**********************************************************************
* Analysis 2: study population from pre-pandemic and lengthening the follow-up to post-pandemic
***********************************************************************/
use "$pathOutOAC/aurum_dose_`doac'_`outcome'_analysis2", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis2
global interactionavailable 0
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_dose_`doac'_`outcome'_analysis2.txt"
global graphbeforeps "$pathResults/OAC/beforeps_dose_`doac'_`outcome'_analysis2.svg"
global graphafterps "$pathResults/OAC/afterps_dose_`doac'_`outcome'_analysis2.svg"
global stddiff "$pathResults/OAC/stddiff_dose_`doac'_`outcome'_analysis2.txt"

do "$pathDofiles/9_OAC-Aurum-PS-model-01-program.do"

/**********************************************************************
* Analysis 3: Using all data for study population and identify outcome
***********************************************************************/
use "$pathOutOAC/aurum_dose_`doac'_`outcome'_analysis3", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis3
global interactionavailable 1
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_dose_`doac'_`outcome'_analysis3.txt"
global graphbeforeps "$pathResults/OAC/beforeps_dose_`doac'_`outcome'_analysis3.svg"
global graphafterps "$pathResults/OAC/afterps_dose_`doac'_`outcome'_analysis3.svg"
global stddiff "$pathResults/OAC/stddiff_dose_`doac'_`outcome'_analysis3.txt"

do "$pathDofiles/9_OAC-Aurum-PS-model-01-program.do"

/**********************************************************************
* Analysis 4: Using data from post-pandemic only
***********************************************************************/
use "$pathOutOAC/aurum_dose_`doac'_`outcome'_analysis4", clear
xtile sys_bp_quartile=systolic_bp,n(4)

global sample_size = _N
global analysis analysis4
global interactionavailable 0
global outcome `outcome'
global result_txt "$pathResults/OAC/PS_dose_`doac'_`outcome'_analysis4.txt"
global graphbeforeps "$pathResults/OAC/beforeps_dose_`doac'_`outcome'_analysis4.svg"
global graphafterps "$pathResults/OAC/afterps_dose_`doac'_`outcome'_analysis4.svg"
global stddiff "$pathResults/OAC/stddiff_dose_`doac'_`outcome'_analysis4.txt"

do "$pathDofiles/9_OAC-Aurum-PS-model-01-program.do"

		}
}


log close
