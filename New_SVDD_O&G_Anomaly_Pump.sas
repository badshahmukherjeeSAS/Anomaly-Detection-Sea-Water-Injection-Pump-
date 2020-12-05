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

data casuser.Pump_Master_H (Keep = F1 B40TI5205A_PV B40PDI96QQ15_PV
		B40PI5100_PV
		B40PI5003_PV
		B40FI5000A_PV
		B40PDI96QQ25_PV
		B40LPSPEED5_PV) ;
	SET public.Pump_Master ;
	IF B40LPSPEED5_PV LT 4455 THEN DELETE ;
run;

/*Renaming Variables*/
data casuser.Pump_Master_H (Keep = F1 GEARBOX_JRNL_BRG_TEMP Lube_Oil_Filter_1_Diff_Pressure Lube_Oil_Supply_Pressure
Suction_Pressure  Pump_Discharge_Flow Lube_Oil_Filter_2_Diff_Pressure Pump_HP_Speed) ;
	SET casuser.Pump_Master_H ;
/* 		Date_Time = F1; */
		GEARBOX_JRNL_BRG_TEMP = B40TI5205A_PV; 
		Lube_Oil_Filter_1_Diff_Pressure = B40PDI96QQ15_PV;
		Lube_Oil_Supply_Pressure = B40PI5100_PV;
		Suction_Pressure = B40PI5003_PV;
		Pump_Discharge_Flow = B40FI5000A_PV ;
		Lube_Oil_Filter_2_Diff_Pressure = B40PDI96QQ25_PV;
		Pump_HP_Speed = B40LPSPEED5_PV;

run;

/*Create a Target Variable Based on GearBox General Bearing Temp between 183-181*/
data casuser.Pump_Master_SVDD;
set casuser.Pump_Master_H;
 IF  183 >= GEARBOX_JRNL_BRG_TEMP >= 181 THEN Target = 0 ; else Target = 1;
run;

data casuser.Pump_Master_SVDD_Train;
 set casuser.Pump_Master_SVDD;
if Target = 1 then delete ;
run;

/* Construct SVDD Anomaly Detection Model on Train */
proc svdd data=casuser.Pump_Master_SVDD_Train outlier_fraction=0.0001 nthreads=4;
	input Lube_Oil_Filter_1_Diff_Pressure
		Lube_Oil_Supply_Pressure
		Suction_Pressure
		Pump_Discharge_Flow
		Lube_Oil_Filter_2_Diff_Pressure
		Pump_HP_Speed/ level=interval;
	kernel rbf / bw=mean;
	solver stochs /;
	savestate rstore=casuser.injection_pump_svdd; 
run;

/* Capture Threshold R^2 Value from SVDD results for outlier/anomaly _SVDDDISTANCE_ cutoff */
%let threshold=0.9300;

/* Score SVDD Anomaly Detection Model on Steady State data */
proc astore;
	score data=casuser.Pump_Master_H
	out=casuser.Pump_Master_H_svdd_score
	rstore=casuser.injection_pump_svdd
	copyvars=(_all_);
quit;

/* Create table for visualization */
data casuser.Pump_Master_H_svdd_plot;
	set casuser.Pump_Master_H_svdd_score;
	format svddflag $7.;
	if _SVDDSCORE_ = 1 then svddflag="Anomaly";
	else svddflag = "Normal";
    if MONTH(DATEPART(F1)) in (6,7) and year(DATEPART(F1))=2020;
run;

proc sort data=casuser.PUMP_MASTER_H_SVDD_PLOT out=_SeriesPlotTaskData;
	by F1;
run;
/*Put a Threhold Reference Line*/
proc sgplot data=_SeriesPlotTaskData;
	series x=F1 y=_SVDDDISTANCE_ ;
	xaxis grid;
	yaxis grid;
refline 0.9300 / axis=y lineattrs=(thickness=3 color=darkred pattern=dash);
run; 

