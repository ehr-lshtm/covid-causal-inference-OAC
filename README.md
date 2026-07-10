These are the Stata analytical codes to conduct the case study of effect of direct oral anticoaglants on thrombotic events and major bleeding versus warfarin
Please note 14_OAC-Aurum-univariable-PS-model-03-time-varying.do which contains codes to generate time-varying period covariates
We recommend future causal inference studies to report 
1) incidence of diagnoses for study population and outcome over time by exposure group - see do file: 10_OAC-Aurum-descriptive-02-af-outcome-trend.do
2) baseline characteristics pre-pandemic, during pandemic and post-pandemic - see do file: 8_OAC-Aurum-baseline-01.do
3) Different approaches for generating propensity score model - see do files: 
	i) 14ab_OAC-Aurum-PS-model-01-time-vary-program-byperiod-addional adjust.do or 14b_OAC-Aurum-PS-model-01-time-vary-program-byperiod.do (propensity score trimming separately in different periods)
	ii) 14ac_OAC-Aurum-PS-model-01-time-vary-program-byperiod-trim-additional adjust.do or 14c_OAC-Aurum-PS-model-01-time-vary-program-byperiod-trim.do (without propensity score trimming separately in different periods)
	iii) 14_OAC-Aurum-PS-model-01-time-vary-program.do (without fitting propensity scocre separately by period)
