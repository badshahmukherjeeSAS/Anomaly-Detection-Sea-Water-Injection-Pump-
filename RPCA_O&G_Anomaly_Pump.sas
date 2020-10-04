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
/*Step2 - RPCA Robust PCA*/
/*Create RPCA model on Pump Master*/
/*Normal Operating Condition of Steady State Pump Speed*/
data public.Pump_Master_H (Keep = F1 B40TI5205A_PV
	    B40PDI96QQ15_PV
		B40PI5100_PV
		B40PI5003_PV
		B40FI5000A_PV
		B40PDI96QQ25_PV
		B40LPSPEED5_PV) ;
	SET public.Pump_Master ;
	IF B40LPSPEED5_PV LT 4455 THEN DELETE ;
run;
/*Principal Component Analysis*/
proc pca data=public.Pump_Master_H method=nipals plots;
var    B40PDI96QQ15_PV
		B40PI5100_PV
		B40PI5003_PV
		B40FI5000A_PV
		B40PDI96QQ25_PV
		B40LPSPEED5_PV;
output out=public.Pump_PCA_Scores copyVars= (B40LPSPEED5_PV B40PI5003_PV)  ;
run;
ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=PUBLIC.PUMP_PCA_SCORES;
	heatmap x=Score1 y=Score2 / name='HeatMap' colorresponse=B40LPSPEED5_PV 
		colorstat=mean nxbins=25 nybins=25 showybins;;
	gradlegend 'HeatMap'; 
run;

ods graphics / reset;
/*Robust Principal Component Analysis*/
proc rpca data=public.Pump_Master_H method=alm scale center  CUMEIGPCTTOL = 0.83 outsparse=public.sparse;
/* 	id F1; */
	input 
        B40PDI96QQ15_PV
		B40PI5100_PV
		B40PI5003_PV
		B40FI5000A_PV
		B40PDI96QQ25_PV
		B40LPSPEED5_PV;
/* 	svd method=eigen; */
    outdecomp svddiag=public.svddiag;
run;

/* Identify 'anomalies' based on abnormal obs (beyond 3sigma variation) of sparse */
/* proc means data=public.sparse std; */
/* var B40PDI96QQ15_PV */
/* 		B40PI5100_PV */
/* 		B40PI5003_PV */
/* 		B40FI5000A_PV */
/* 		B40PDI96QQ25_PV */
/* 		B40LPSPEED5_PV; */
/* output out=std; */
/* run; */
/*  */
/* proc sql; */
/* 	select B40PDI96QQ15_PV , B40PI5100_PV , B40PI5003_PV, B40FI5000A_PV, B40PDI96QQ25_PV,B40LPSPEED5_PV  */
/* 	into :B40PDI96QQ15_PV, :B40PI5100_PV , :B40PI5003_PV, :B40FI5000A_PV, :B40PDI96QQ25_PV,:B40LPSPEED5_PV */
/* 	from work.std */
/* 	where _STAT_='STD'; */
/* quit; */
/*  */
/* %let set=3; */
/* data public.rpcaanomalies; */
/* 	set public.sparse; */
/* 	format rpcaflag $7.; */
/* 	if (B40PDI96QQ15_PV > &set*&B40PDI96QQ15_PV or B40PDI96QQ15_PV < -&set*&B40PDI96QQ15_PV) then rpcaflag = "Anomaly"; */
/* 	else if (B40PI5100_PV > &set*&B40PI5100_PV or B40PI5100_PV < -&set*&B40PI5100_PV) then rpcaflag = "Anomaly"; */
/* 	else if (B40PI5003_PV > &set*&B40PI5003_PV or B40PI5003_PV < -&set*&B40PI5003_PV) then rpcaflag = "Anomaly"; */
/* 	else if (B40FI5000A_PV > &set*&B40FI5000A_PV or B40FI5000A_PV < -&set*&B40FI5000A_PV) then rpcaflag = "Anomaly"; */
/* 	else if (B40PDI96QQ25_PV > &set*&B40PDI96QQ25_PV or B40PDI96QQ25_PV < -&set*&B40PDI96QQ25_PV) then rpcaflag = "Anomaly"; */
/*     else if (B40LPSPEED5_PV > &set*&B40LPSPEED5_PV or B40LPSPEED5_PV < -&set*&B40LPSPEED5_PV) then rpcaflag = "Anomaly"; */
/* 	else rpcaflag= "Noise"; */
/* run; */
/*  */
/* Get a small sample of resulting data for plotting purposes */
/* proc partition data=public.rpcaanomalies samppct=100 seed=123; */
/* 	output out=public.rpcaanomalies_sample; */
/* run; */
/*  */
/* Plot RPCA Anomaly Detection results */
/*  */
/* ods graphics / reset width=6.4in height=4.8in imagemap; */
/*  */
/* proc sgplot data=public.rpcaanomalies_sample; */
/* 	scatter x=B40LPSPEED5_PV y=B40PDI96QQ15_PV / group= rpcaflag; */
/* 	xaxis grid; */
/* 	yaxis grid; */
/*     xaxis label="Pump Speed"; */
/* 	yaxis label="L.O. Filter  #1  Diff  Pressure"; */
/* run; */
/*  */
/* ods graphics / reset; */
=======