

SAS® Studio - Develop SAS Code









Git Repositories



Current Repository
ARAMCO_Anomaly_Pump
master (1)











	select B40PDI96QQ15_PV , B40PI5100_PV , B40PI5003_PV, B40FI5000A_PV, B40PDI96QQ25_PV,B40LPSPEED5_PV  
	into :B40PDI96QQ15_PV, :B40PI5100_PV , :B40PI5003_PV, :B40FI5000A_PV, :B40PDI96QQ25_PV,:B40LPSPEED5_PV 
	from work.std 
	where _STAT_='STD'; 
quit; 
 
%let set=3; 
data public.rpcaanomalies; 
	set public.sparse; 
	format rpcaflag $7.; 
	if (B40PDI96QQ15_PV > &set*&B40PDI96QQ15_PV or B40PDI96QQ15_PV < -&set*&B40PDI96QQ15_PV) then rpcaflag = "Anomaly"; 
	else if (B40PI5100_PV > &set*&B40PI5100_PV or B40PI5100_PV < -&set*&B40PI5100_PV) then rpcaflag = "Anomaly"; 
	else if (B40PI5003_PV > &set*&B40PI5003_PV or B40PI5003_PV < -&set*&B40PI5003_PV) then rpcaflag = "Anomaly"; 
	else if (B40FI5000A_PV > &set*&B40FI5000A_PV or B40FI5000A_PV < -&set*&B40FI5000A_PV) then rpcaflag = "Anomaly"; 
	else if (B40PDI96QQ25_PV > &set*&B40PDI96QQ25_PV or B40PDI96QQ25_PV < -&set*&B40PDI96QQ25_PV) then rpcaflag = "Anomaly"; 
    else if (B40LPSPEED5_PV > &set*&B40LPSPEED5_PV or B40LPSPEED5_PV < -&set*&B40LPSPEED5_PV) then rpcaflag = "Anomaly"; 
	else rpcaflag= "Noise"; 
run; 
 
/* Get a small sample of resulting data for plotting purposes */ 
proc partition data=public.rpcaanomalies samppct=100 seed=123; 
	output out=public.rpcaanomalies_sample; 
run; 
 
/* Plot RPCA Anomaly Detection results */ 
 
ods graphics / reset width=6.4in height=4.8in imagemap; 
 
proc sgplot data=public.rpcaanomalies_sample; 
	scatter x=B40LPSPEED5_PV y=B40PDI96QQ15_PV / group= rpcaflag; 
	xaxis grid; 
	yaxis grid; 
    xaxis label="Pump Speed"; 
	yaxis label="L.O. Filter  #1  Diff  Pressure"; 
run; 
 
ods graphics / reset; 
 






















