if $analysis_num == 3 {
*for period 0
preserve
keep if indexdate < mdy(03,16,2020)
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

save period_0, replace
restore

*for period 1
keep if indexdate >= mdy(03,16,2020)
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

save period_1, replace

use period_1, clear
append using period_0
}

else if $analysis_num == 1 | $analysis_num == 2 | $analysis_num == 4 {
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
}

stset stime_$outcome [pweight = ipw], id(groupid) fail($outcome) enter(indexdate) origin(indexdate)	

gen ln_pt = ln(_t)

if $adjustavailable == 0 {
	
poisson _d i.exposure [pw = ipw], offset(ln_pt) vce(robust)

margins i.exposure, predict(ir) 

di "$doac vs warfarin PS weighted rate difference Analysis $analysis_num"
margins i.exposure, predict(ir) contrast(effects) saving($doac_$outcome_$analysis_num, replace)

use $doac_$outcome_$analysis_num, clear

gen rd_1000 = _margin *1000 * 365.25
gen lower_ci_1000 = _ci_lb *1000 * 365.25
gen upper_ci_1000 = _ci_ub *1000 * 365.25

keep rd_1000 lower_ci_1000 upper_ci_1000

export delimited using $output, delimiter(tab) replace

erase $doac_$outcome_$analysis_num.dta

}

else if $adjustavailable == 1 {
	
	poisson _d i.exposure $addition_covariate [pw = ipw], offset(ln_pt) vce(robust)

margins i.exposure, predict(ir) 

di "$doac vs warfarin PS weighted rate difference Analysis $analysis_num"
margins i.exposure, predict(ir) contrast(effects) saving($doac_$outcome_$analysis_num, replace)

use $doac_$outcome_$analysis_num, clear

gen rd_1000 = _margin *1000 * 365.25
gen lower_ci_1000 = _ci_lb *1000 * 365.25
gen upper_ci_1000 = _ci_ub *1000 * 365.25

keep rd_1000 lower_ci_1000 upper_ci_1000

export delimited using $output, delimiter(tab) replace

erase $doac_$outcome_$analysis_num.dta

}