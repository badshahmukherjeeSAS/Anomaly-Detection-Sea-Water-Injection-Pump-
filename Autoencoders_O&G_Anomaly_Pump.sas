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

/*Step1 - Autoencoder*/;
/*Create autoencoder model on Pump Master*/
/*Normal Operating Condition of Speed Pump Data*/
data public.Pump_Master_H (Keep = F1 B40TI5205A_PV B40PDI96QQ15_PV
		B40PI5100_PV
		B40PI5003_PV
		B40FI5000A_PV
		B40PDI96QQ25_PV
		B40LPSPEED5_PV) ;
	SET public.Pump_Master ;
	IF B40LPSPEED5_PV LT 4455 THEN DELETE ;
run;
/*Create autoencoder model on Pump Master*/
%let Hidden_Nodes = 4;
proc nnet data=public.Pump_Master_H  standardize=STD  missing=mean;
	input  
		B40PDI96QQ15_PV
		B40PI5100_PV
		B40PI5003_PV
		B40FI5000A_PV
		B40PDI96QQ25_PV
		B40LPSPEED5_PV
		/ level=interval;
   hidden &Hidden_Nodes ;
      train outmodel=public.pumpmasternet_H;
/*    optimization ALGORITHM=SGD REGL1=10 REGL2=0.00664137; */
   optimization ;
/* autotune objective=MSE searchmethod=GA maxtime =200; */
  score out=public.autoencoderscore_H copyvars=(_all_);; 
run;

proc contents data = public.autoencoderscore_H;run;

/* Identify 'anomalies' based on abnormal obs (beyond 3 sigma variation) of score */

proc means data=public.autoencoderscore_H std;
var _Node_0 - _Node_3;
output out=public.aestd_H;
run;

proc sql;
	select _Node_0, _Node_1, _Node_2, _Node_3
	into :SX0, :SX1, :SX2, :SX3 
	from public.aestd_H
	where _STAT_='STD';
quit;
/* %put &SX0 &SX1 &SX2 &SX3 */

%let set=3;
data public.aeanomalies;
	set public.autoencoderscore_H;
	format nnetflag $7.;
	if _Node_0 > &set*&SX0 or _Node_0 < -&set*&SX0 then nnetflag = "Anomaly";
	else if _Node_1 > &set*&SX1 or _Node_1 < -&set*&SX1 then nnetflag = "Anomaly";
	else if _Node_2 > &set*&SX2 or _Node_2 < -&set*&SX2 then nnetflag = "Anomaly";
	else if _Node_3 > &set*&SX3 or _Node_3 < -&set*&SX3 then nnetflag = "Anomaly";
	else nnetflag= "Normal";
run;
proc contents data = public.aeanomalies;
run;
proc print data = public.aeanomalies (obs =10);
	var F1 nnetflag ;
run;


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

/*Step1 - Autoencoder*/;
/*Create autoencoder model on Pump Master*/
/*Normal Operating Condition of Speed Pump Data*/
data public.Pump_Master_H (Keep = F1 B40TI5205A_PV B40PDI96QQ15_PV
		B40PI5100_PV
		B40PI5003_PV
		B40FI5000A_PV
		B40PDI96QQ25_PV
		B40LPSPEED5_PV) ;
	SET public.Pump_Master ;
	IF B40LPSPEED5_PV LT 4455 THEN DELETE ;
run;
/*Create autoencoder model on Pump Master*/
%let Hidden_Nodes = 4;
proc nnet data=public.Pump_Master_H  standardize=STD  missing=mean;
	input  
		B40PDI96QQ15_PV
		B40PI5100_PV
		B40PI5003_PV
		B40FI5000A_PV
		B40PDI96QQ25_PV
		B40LPSPEED5_PV
		/ level=interval;
   hidden &Hidden_Nodes ;
      train outmodel=public.pumpmasternet_H;
/*    optimization ALGORITHM=SGD REGL1=10 REGL2=0.00664137; */
   optimization ;
/* autotune objective=MSE searchmethod=GA maxtime =200; */
  score out=public.autoencoderscore_H copyvars=(_all_);; 
run;

proc contents data = public.autoencoderscore_H;run;

/* Identify 'anomalies' based on abnormal obs (beyond 3 sigma variation) of score */

proc means data=public.autoencoderscore_H std;
var _Node_0 - _Node_3;
output out=public.aestd_H;
run;

proc sql;
	select _Node_0, _Node_1, _Node_2, _Node_3
	into :SX0, :SX1, :SX2, :SX3 
	from public.aestd_H
	where _STAT_='STD';
quit;
/* %put &SX0 &SX1 &SX2 &SX3 */

%let set=3;
data public.aeanomalies;
	set public.autoencoderscore_H;
	format nnetflag $7.;
	if _Node_0 > &set*&SX0 or _Node_0 < -&set*&SX0 then nnetflag = "Anomaly";
	else if _Node_1 > &set*&SX1 or _Node_1 < -&set*&SX1 then nnetflag = "Anomaly";
	else if _Node_2 > &set*&SX2 or _Node_2 < -&set*&SX2 then nnetflag = "Anomaly";
	else if _Node_3 > &set*&SX3 or _Node_3 < -&set*&SX3 then nnetflag = "Anomaly";
	else nnetflag= "Normal";
run;
proc contents data = public.aeanomalies;
run;

