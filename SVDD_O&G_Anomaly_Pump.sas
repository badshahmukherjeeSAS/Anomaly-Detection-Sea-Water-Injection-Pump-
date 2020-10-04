/******************************************************************/
/*Anomaly Detection  on Sea Water Injection Pump Data (O&G Major)*/
/******************************************************************/
cas mySession sessopts=(caslib=casuser timeout=1800 locale="en_US");
/*****************************************************************************/
/*  Create a default CAS session and create SAS librefs for existing caslibs */
/*  so that they are visible in the SAS Studio Libraries tree.               */
/*****************************************************************************/
cas;  
caslib _all_ assign;
/*Create SVDD model on Pump Master*/
/*Normal Operating Condition of Steady State  Pump Speed */
data public.Pump_Master_H (Keep = F1 B40TI5205A_PV B40PDI96QQ15_PV
		B40PI5100_PV
		B40PI5003_PV
		B40FI5000A_PV
		B40PDI96QQ25_PV
		B40LPSPEED5_PV) ;
	SET public.Pump_Master ;
	IF B40LPSPEED5_PV LT 4455 THEN DELETE ;
run;
/*Create a Target Variable Based on GearBox General Bearing Temp between 183-181*/
data public.Pump_Master_SVDD;
set public.Pump_Master_H;
 IF  183 >= B40TI5205A_PV >= 181 THEN Target = 0 ; else Target = 1;
run;

data public.Pump_Master_SVDD_Train;
 set public.Pump_Master_SVDD;
if Target = 1 then delete ;
run;

/* Construct SVDD Anomaly Detection Model on Train */
proc svdd data=public.Pump_Master_SVDD_Train outlier_fraction=0.0001 nthreads=4;
	input B40PDI96QQ15_PV
		B40PI5100_PV
		B40PI5003_PV
		B40FI5000A_PV
		B40PDI96QQ25_PV
		B40LPSPEED5_PV/ level=interval;
	kernel rbf / bw=mean;
	solver stochs /;
	savestate rstore=public.injection_pump_svdd; 
run;

/* Capture Threshold R^2 Value from SVDD results for outlier/anomaly _SVDDDISTANCE_ cutoff */
%let threshold=0.9300;

/* Score SVDD Anomaly Detection Model on Steady State data */
proc astore;
	score data=public.Pump_Master_H
	out=public.Pump_Master_H_svdd_score
	rstore=public.injection_pump_svdd
	copyvars=(_all_);
quit;

/* Create table for visualization */
data public.Pump_Master_H_svdd_plot;
	set public.Pump_Master_H_svdd_score;
	format svddflag $7.;
	if _SVDDSCORE_ = 1 then svddflag="Anomaly";
	else svddflag = "Normal";
    if MONTH(DATEPART(F1)) in (6,7) and year(DATEPART(F1))=2020;
run;

proc sort data=PUBLIC.PUMP_MASTER_H_SVDD_PLOT out=_SeriesPlotTaskData;
	by F1;
run;
/*Put a Threhold Reference Line*/
proc sgplot data=_SeriesPlotTaskData;
	series x=F1 y=_SVDDDISTANCE_ ;
	xaxis grid;
	yaxis grid;
refline 0.9300 / axis=y lineattrs=(thickness=3 color=darkred pattern=dash);
run;