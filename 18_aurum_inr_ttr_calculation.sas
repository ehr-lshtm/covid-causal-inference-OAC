/*from Emma:
I used Rosendaal’s  method to calculate TTR (to match method used in my target trial).
After cleaning the INR data and making sure only 1 INR obs per day (if there were multiple plausible on 1 day I took the mean value for that day) I used linear interpolation.
This link shows an easy example that makes it clear how calculation should work
https://www.inrpro.com/rosendaal.asp
*/
libname inr_cprd "J:\EHR-Working\Angel\Covid_recording\datafiles\OAC";
%macro import_inr;

    %let meds = rivaroxaban apixaban dose_edoxaban_low dose_edoxaban_high;
    %let analyses = analysis1 analysis2 analysis3 analysis4 analysis5;

    %do i = 1 %to %sysfunc(countw(&meds));
        %let med = %scan(&meds, &i);

        %do j = 1 %to %sysfunc(countw(&analyses));
            %let analysis = %scan(&analyses, &j);

            data inr_cprd.raw_&med._&analysis;

                infile "J:\EHR-Working\Angel\Covid_recording\datafiles\OAC\&med._inr_bleed_&analysis..txt"
                delimiter=',' MISSOVER DSD lrecl=32767 firstobs=2;

                informat patid            $50. ;
                informat indexdate        date9. ;
                informat heart_valve_base best5. ;
                informat enddate          date9. ;
                informat obsdate          date9. ;
                informat INR              best5. ;

                format patid              $50. ;
                format indexdate          date9. ;
                format heart_valve_base   best5. ;
                format enddate            date9. ;
                format obsdate            date9. ;
                format INR               best5. ;

                input
                    patid $
                    indexdate
                    heart_valve_base 
                    enddate
                    obsdate
                    INR
                ;

            run;

            %put NOTE: Imported &med &analysis;

        %end;
    %end;

%mend;

%import_inr;
/*this data only have 1 INR record per person per day, if one day has multiple INR value, calculated mean in STATA already*/

%macro short_name;
    %let analyses = analysis1 analysis2 analysis3 analysis4 analysis5;
        %do j = 1 %to %sysfunc(countw(&analyses));
            %let analysis = %scan(&analyses, &j);

            data inr_cprd.raw_edolow_&analysis;
			set inr_cprd.raw_dose_edoxaban_low_&analysis;

        %end;
%mend;
%short_name;


%macro short_name;
    %let analyses = analysis1 analysis2 analysis3 analysis4 analysis5;
        %do j = 1 %to %sysfunc(countw(&analyses));
            %let analysis = %scan(&analyses, &j);

            data inr_cprd.raw_edohigh_&analysis;
			set inr_cprd.raw_dose_edoxaban_high_&analysis;

        %end;
%mend;
%short_name;

/*investigate data for heart valve base = 1 */
%macro process_inr(meds=, analyses=);
  /* Loop over each medication */
  %let i = 1;
  %do %while (%scan(&meds, &i) ne );
    %let med = %scan(&meds, &i);

    /* Loop over each analysis for the current medication */
    %let j = 1;
    %do %while (%scan(&analyses, &j) ne );
      %let analysis = %scan(&analyses, &j);

      %put Processing &med - &analysis...;

 data inr_cprd.inr1_&med._&analysis;
        set inr_cprd.Raw_&med._&analysis;
	if heart_valve_base = 1;
Year=Year(obsdate);run;

proc sort data = inr_cprd.inr1_&med._&analysis;
by Year;
run;
proc sort data = inr_cprd.inr1_&med._&analysis;
by patid obsdate;
run;

data inr_cprd.inr2_&med._&analysis;
set inr_cprd.inr1_&med._&analysis;
by patid;
tmp=lag(obsdate);
if ^first.patid then Before_date = tmp;
format Before_date date9.;
drop tmp;
run;

proc sort data=inr_cprd.inr2_&med._&analysis;
by patid obsdate Before_Date;
run;
data inr_cprd.inr3_&med._&analysis;
set inr_cprd.inr2_&med._&analysis;
if Before_date>0 then dayssince=intck('day',Before_date,obsdate, 'continuous');
run;

data inr_cprd.inr3_&med._&analysis;
set inr_cprd.inr3_&med._&analysis;
by patid;
tmp=lag(INR);
if ^first.patid then Before_inr = tmp;
drop tmp;
run;
data inr_cprd.inr3_&med._&analysis;
set inr_cprd.inr3_&med._&analysis;
if Before_inr>0 then INRdiff=INR-Before_inr;
run;

data inr_cprd.inr3_&med._&analysis;
set inr_cprd.inr3_&med._&analysis;
rename Before_inr=lastINR;
rename Before_date=lastINRdt;
run;

data inr_cprd.ttr_&med._&analysis;
  set inr_cprd.inr3_&med._&analysis;
  by patid;
  length /*lastINR lastINRdt dayssince INRdiff */ INRdiff_outrange prop_inrange daysinrange 8.;
  call missing(/*lastINR,lastINRdt,dayssince,INRdiff,*/INRdiff_outrange,prop_inrange,daysinrange);
  /*lastINR=lag(INR);*/
  /*lastINRdt=lag(obsdt);*/
  /*dayssince=obsdt-lastINRdt;
  INRdiff=abs(INR-lastINR);*/
  if first.patid then do;
    lastINR=.;
    lastINRdt=.;
    dayssince=0;
    INRdiff=.;
    INRdiff_outrange=.;
    prop_inrange=.;
    daysinrange=0;
  end;
    *if current measure and last measure in target range then 100% daysinrange;
  if (INR ge 2.5 and INR le 3.5) and (lastINR ge 2.5 and lastINR le 3.5) then do;
    INRdiff_outrange=0;
    prop_inrange=1;
    daysinrange=dayssince;
  end;
  if (INR < 2.5 or INR > 3.5) or (lastINR < 2.5 or lastINR > 3.5) then do;
    if (INR>3.5 and lastINR>3.5) or (INR <2.5 and lastINR<2.5) then do;
        INRdiff_outrange=INRdiff;
        prop_inrange=0;
        daysinrange=0;
    end;
    if (INR>3.5 and lastINR le 3.5) then do;
        INRdiff_outrange=INR-3.5;
        prop_inrange=(abs(INRdiff)-INRdiff_outrange)/abs(INRdiff);
        daysinrange=prop_inrange*dayssince;
    end;
    if (INR le 3.5 and lastINR > 3.5) then do;
        INRdiff_outrange=lastINR-3.5;
        prop_inrange=(abs(INRdiff)-INRdiff_outrange)/abs(INRdiff);
        daysinrange=prop_inrange*dayssince;
    end;
    if (INR<2.5 and lastINR ge 2.5) then do;
        INRdiff_outrange=2.5-INR;
        prop_inrange=(abs(INRdiff)-INRdiff_outrange)/abs(INRdiff);
        daysinrange=prop_inrange*dayssince;
    end;
    if (INR ge 2.5 and lastINR < 2.5) then do;
        INRdiff_outrange=2.5-lastINR;
        prop_inrange=(abs(INRdiff)-INRdiff_outrange)/abs(INRdiff);
        daysinrange=prop_inrange*dayssince;
    end;
  end;
  format lastINRdt date9.;
run;


*Want to keep last obs before index dt then calculate TTR from indexdt up to censoring date;
data inr_cprd.ttr2_&med._&analysis;
set inr_cprd.ttr_&med._&analysis;
by patid obsdate indexdate;
where obsdate ge indexdate and obsdate le enddate;
run;

proc sql;
  *sum(daysinrange)/sum(dayssince);
  create table inr_cprd.ttrf1_&med._&analysis as
    select distinct patid, 
           sum(daysinrange) as total_daysinrange,
           sum(dayssince) as total_dayssince, 
           freq(patid) as num_inr_vals,
           median(dayssince) as median_dayssince
    from inr_cprd.ttr2_&med._&analysis
    group by patid, indexdate;
quit;
data inr_cprd.ttrf1_&med._&analysis;
  set inr_cprd.ttrf1_&med._&analysis;
  length ttr 8.;
  call missing(ttr);
  if total_dayssince>0 then  ttr=total_daysinrange/total_dayssince;
run;

      %let j = %eval(&j + 1);
    %end; /* end analysis loop */

    %let i = %eval(&i + 1);
  %end; /* end medication loop */

%mend process_inr;

/* Example usage: */
%process_inr(meds=rivaroxaban apixaban edohigh edolow, analyses=analysis1 analysis2 analysis3 analysis4 analysis5);

/*investigate data for heart valve base = 0 */
%macro process_inr(meds=, analyses=);
  /* Loop over each medication */
  %let i = 1;
  %do %while (%scan(&meds, &i) ne );
    %let med = %scan(&meds, &i);

    /* Loop over each analysis for the current medication */
    %let j = 1;
    %do %while (%scan(&analyses, &j) ne );
      %let analysis = %scan(&analyses, &j);

      %put Processing &med - &analysis...;

 data inr_cprd.inr1_&med._&analysis;
        set inr_cprd.Raw_&med._&analysis;
	if heart_valve_base = 0;
Year=Year(obsdate);run;

proc sort data = inr_cprd.inr1_&med._&analysis;
by Year;
run;
proc sort data = inr_cprd.inr1_&med._&analysis;
by patid obsdate;
run;

data inr_cprd.inr2_&med._&analysis;
set inr_cprd.inr1_&med._&analysis;
by patid;
tmp=lag(obsdate);
if ^first.patid then Before_date = tmp;
format Before_date date9.;
drop tmp;
run;

proc sort data=inr_cprd.inr2_&med._&analysis;
by patid obsdate Before_Date;
run;
data inr_cprd.inr3_&med._&analysis;
set inr_cprd.inr2_&med._&analysis;
if Before_date>0 then dayssince=intck('day',Before_date,obsdate, 'continuous');
run;

data inr_cprd.inr3_&med._&analysis;
set inr_cprd.inr3_&med._&analysis;
by patid;
tmp=lag(INR);
if ^first.patid then Before_inr = tmp;
drop tmp;
run;
data inr_cprd.inr3_&med._&analysis;
set inr_cprd.inr3_&med._&analysis;
if Before_inr>0 then INRdiff=INR-Before_inr;
run;

data inr_cprd.inr3_&med._&analysis;
set inr_cprd.inr3_&med._&analysis;
rename Before_inr=lastINR;
rename Before_date=lastINRdt;
run;

data inr_cprd.ttr_&med._&analysis;
  set inr_cprd.inr3_&med._&analysis;
  by patid;
  length /*lastINR lastINRdt dayssince INRdiff */ INRdiff_outrange prop_inrange daysinrange 8.;
  call missing(/*lastINR,lastINRdt,dayssince,INRdiff,*/INRdiff_outrange,prop_inrange,daysinrange);
  /*lastINR=lag(INR);*/
  /*lastINRdt=lag(obsdt);*/
  /*dayssince=obsdt-lastINRdt;
  INRdiff=abs(INR-lastINR);*/
  if first.patid then do;
    lastINR=.;
    lastINRdt=.;
    dayssince=0;
    INRdiff=.;
    INRdiff_outrange=.;
    prop_inrange=.;
    daysinrange=0;
  end;
    *if current measure and last measure in target range then 100% daysinrange;
  if (INR ge 2 and INR le 3) and (lastINR ge 2 and lastINR le 3) then do;
    INRdiff_outrange=0;
    prop_inrange=1;
    daysinrange=dayssince;
  end;
  if (INR < 2 or INR > 3) or (lastINR < 2 or lastINR > 3) then do;
    if (INR>3 and lastINR>3) or (INR <2 and lastINR<2) then do;
        INRdiff_outrange=INRdiff;
        prop_inrange=0;
        daysinrange=0;
    end;
    if (INR>3 and lastINR le 3) then do;
        INRdiff_outrange=INR-3;
        prop_inrange=(abs(INRdiff)-INRdiff_outrange)/abs(INRdiff);
        daysinrange=prop_inrange*dayssince;
    end;
    if (INR le 3 and lastINR > 3) then do;
        INRdiff_outrange=lastINR-3;
        prop_inrange=(abs(INRdiff)-INRdiff_outrange)/abs(INRdiff);
        daysinrange=prop_inrange*dayssince;
    end;
    if (INR<2 and lastINR ge 2) then do;
        INRdiff_outrange=2-INR;
        prop_inrange=(abs(INRdiff)-INRdiff_outrange)/abs(INRdiff);
        daysinrange=prop_inrange*dayssince;
    end;
    if (INR ge 2 and lastINR < 2) then do;
        INRdiff_outrange=2-lastINR;
        prop_inrange=(abs(INRdiff)-INRdiff_outrange)/abs(INRdiff);
        daysinrange=prop_inrange*dayssince;
    end;
  end;
  format lastINRdt date9.;
run;


*Want to keep last obs before index dt then calculate TTR from indexdt up to censoring date;
data inr_cprd.ttr2_&med._&analysis;
set inr_cprd.ttr_&med._&analysis;
by patid obsdate indexdate;
where obsdate ge indexdate and obsdate le enddate;
run;

proc sql;
  *sum(daysinrange)/sum(dayssince);
  create table inr_cprd.ttrf0_&med._&analysis as
    select distinct patid, 
           sum(daysinrange) as total_daysinrange,
           sum(dayssince) as total_dayssince, 
           freq(patid) as num_inr_vals,
           median(dayssince) as median_dayssince
    from inr_cprd.ttr2_&med._&analysis
    group by patid, indexdate;
quit;
data inr_cprd.ttrf0_&med._&analysis;
  set inr_cprd.ttrf0_&med._&analysis;
  length ttr 8.;
  call missing(ttr);
  if total_dayssince>0 then  ttr=total_daysinrange/total_dayssince;
run;

      %let j = %eval(&j + 1);
    %end; /* end analysis loop */

    %let i = %eval(&i + 1);
  %end; /* end medication loop */

%mend process_inr;

/* Example usage: */
%process_inr(meds=rivaroxaban apixaban edohigh edolow, analyses=analysis1 analysis2 analysis3 analysis4 analysis5);

/*export and import back to STATA*/
%macro export_stata0;
    %let meds = rivaroxaban apixaban edohigh edolow;
    %let analyses = analysis1 analysis2 analysis3 analysis4 analysis5;

    %do i = 1 %to %sysfunc(countw(&meds));
        %let med = %scan(&meds, &i);

        %do j = 1 %to %sysfunc(countw(&analyses));
            %let analysis = %scan(&analyses, &j);

      proc export data=inr_cprd.ttrf0_&med._&analysis
      outfile="J:\EHR-Working\Angel\Covid_recording\datafiles\OAC\ttrf0_&med._&analysis..txt"
      dbms=dlm
      replace;
      delimiter=','; 
    run;
        %end;
		%end;
%mend;
%export_stata0;

%macro export_stata1;
    %let meds = rivaroxaban apixaban edohigh edolow;
    %let analyses = analysis1 analysis2 analysis3 analysis4 analysis5;

    %do i = 1 %to %sysfunc(countw(&meds));
        %let med = %scan(&meds, &i);

        %do j = 1 %to %sysfunc(countw(&analyses));
            %let analysis = %scan(&analyses, &j);

      proc export data=inr_cprd.ttrf1_&med._&analysis
      outfile="J:\EHR-Working\Angel\Covid_recording\datafiles\OAC\ttrf1_&med._&analysis..txt"
      dbms=dlm
      replace;
      delimiter=','; 
    run;
        %end;
		%end;
%mend;
%export_stata1;



