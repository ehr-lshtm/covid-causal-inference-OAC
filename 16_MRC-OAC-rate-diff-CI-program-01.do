/*=========================================================================
DO FILE NAME:			16_MRC-OAC-rate-diff-CI-program-01

AUTHOR:					Angel Wong
VERSION:				v1
DATE VERSION CREATED:	3 Feb 2026
					
DATABASE:				
						CPRD Aurum Dec 2024 build

Aim:
program to find the CI for each crude rate and crude rate difference
*=============================================================================*/

/**********************************************************************
*1. Rate in each group
***********************************************************************/
stset stime_$outcome, id(groupid) fail($outcome) enter(indexdate) origin(indexdate)

cap file close tablecontent
file open tablecontent using "$stptime_name", write text replace

file write tablecontent ("no_of_outcome") _tab ("exposure") _tab ("time_in_years") _n	

preserve
keep if exposure == 0
stptime, per(365250) //per 1000 person-year
return list
restore

scalar time_yr = r(ptime) / 365.25 

file write tablecontent (r(failures)) _tab ("0") _tab (time_yr) _tab %4.2f (r(rate)) _tab %4.2f (r(lb)) _tab %4.2f (r(ub)) _n

preserve
keep if exposure == 1
stptime, per(365250) //per 1000 person-year
return list
restore

scalar time_yr = r(ptime) / 365.25 

file write tablecontent (r(failures)) _tab ("1") _tab (time_yr) _tab %4.2f (r(rate)) _tab %4.2f (r(lb)) _tab %4.2f (r(ub)) _n

file write tablecontent _n
file close tablecontent

/**********************************************************************
*2. Calculate the rate difference 
***********************************************************************/
import delimited using "$stptime_name", clear 

gen time_yr_1000 = time_in_years / 1000

ir no_of_outcome exposure time_yr_1000

cap file close tablecontent
file open tablecontent using "$ratediff_name", write text replace

file write tablecontent ("rate_difference") _tab ("95%CI") _n	

file write tablecontent %4.2f (r(ird)) _tab %4.2f (r(lb_ird)) (" - ") %4.2f (r(ub_ird)) _n

file write tablecontent _n
file close tablecontent