/*=========================================================================
Program for running the PS model for doac vs warfarin study
need to specify global option for
$analysis
$interactionavailable (only for analysis 3)
*=============================================================================*/
logistic exposure $psvarlist, base
predict pscore, pr

* Identify the max and min pscore by exposure for trimming
bysort exposure: su pscore, detail
bysort exposure: egen min_pscore = min(pscore)
bysort exposure: egen max_pscore = max(pscore)

* Trim the tails
egen ps_lower_tail =  max(min_pscore)
egen ps_upper_tail =  min(max_pscore)
drop if pscore < ps_lower_tail
drop if pscore > ps_upper_tail

noi tab exposure $outcome, m

* Create ATE weights 
gen ipw = 1/pscore if exposure == 1 
replace ipw = 1/(1-pscore) if exposure == 0 

summarize ipw, d

gen ipw_f = round(ipw*100) 

local lab0: label exposure 0
local lab1: label exposure 1

drop min_pscore max_pscore ps_lower_tail ps_upper_tail

* Estimate the effect with PS weighting
stset stime_$outcome [pweight = ipw], id(groupid) fail($outcome) enter(indexdate) origin(indexdate)	

cap file close tablecontent
file open tablecontent using "$result_txt", write text replace

file write tablecontent ("DOAC vs warfarin") _n 
file write tablecontent ("HR") _tab ("95% CI") _n				

file write tablecontent _n

* Row headings 
local lab0: label exposure 0
local lab1: label exposure 1

stcox i.exposure $addition_covariate, vce(robust)
lincom 1.exposure, eform

file write tablecontent %4.2f (r(estimate)) _tab %4.2f (r(lb)) (" - ") %4.2f (r(ub)) _n

	if $interactionavailable == 1 {
		
stcox i.exposure##i.period $addition_covariate, vce(robust)

lincom 1.exposure#1.period, eform 
file write tablecontent ("interaction") _tab %4.2f (r(estimate)) _tab %4.2f (r(lb)) (" - ") %4.2f (r(ub)) _n

foreach i in 0 1 {
lincom 1.exposure + `i'.period#1.exposure, eform 

file write tablecontent ("period") _tab (`i') _tab %4.2f (r(estimate)) _tab %4.2f (r(lb)) (" - ") %4.2f (r(ub)) _n
}

foreach i in 0 1 {
lincom 1.period + 1.period#`i'.exposure, eform 

file write tablecontent ("exposure") _tab (`i') _tab %4.2f (r(estimate)) _tab %4.2f (r(lb)) (" - ") %4.2f (r(ub)) _n
}

file write tablecontent _n
file close tablecontent
	}		
	
	else if $interactionavailable == 0 {
		
file write tablecontent _n
file close tablecontent
	}
