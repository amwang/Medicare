/***

Chris Afendulis
Last modified 3 Nov 2009

This program processes the MedPAR data into five separate categories: PPS hospital, SNF, rehab hospital, LTC hospital and other hospital.  It also calculates the payment for each stay, and codes the 30 Elixhauser variables and the six other diagnosis variables for readmission from a SNF.

input datasets:
	/disk/agedisk2/medicare/nberwest/tape100/mp100_&year..sas7bdat.gz
	(1996-2000)

output datasets:
	/disk/agebulk1/medicare.work/kessler-DUA16444/cafendul/hosp_integration/summer09/
	pps_hosp_9600.sas7bdat.gz
	snf_9600.sas7bdat.gz
	ltc_hosp_9600.sas7bdat.gz
	rehab_hosp_9600.sas7bdat.gz
	other_hosp_9600.sas7bdat.gz

***/

libname tmp "/space/cafendul/";

%macro medpar(firstyear,lastyear);
options mprint;

%do year=&firstyear. %to &lastyear.;

* Copy base year file over to tmp directory;
x "cd /disk/agedisk2/medicare/nberwest/tape100/";
x "cp -f mp100_&year..sas7bdat.gz /space/cafendul";

x "cd /space/cafendul/";
x "chmod 700 mp100_&year..sas7bdat.gz";
x "gunzip -f mp100_&year..sas7bdat.gz";

* Keep only the variables you need;
data medpar_&year. (keep=hicbic admdate disdate medpar_exp type mpcode mdiag1-mdiag10 mdrg mprovno mcovdays mlos);
%if &year.<=1997 %then %do;
	set tmp.mp100_&year. (keep=hicbic madmdte mdisdte mdrgpric moutamt mperdiem mprovno mpcode mdiag1-mdiag10 mdrg mcovdays mlos);
	%end;
%else %do;
	set tmp.mp100_&year. (keep=hicbic madmdte mdisdte mdrgpric moutamt mperdiem mprovno mfaclty mdiag1-mdiag10 mdrg mcovdays mlos rename=(mfaclty=mpcode));
	%end;

	* Calculate payment variable;
	length medpar_exp 5;
	medpar_exp=sum(mdrgpric,moutamt,mperdiem);

	* Change format of date variables;
	length admdate 5;
	admdate=madmdte;
	attrib admdate format=mmddyy10.;

	length disdate 5;
	disdate=mdisdte;
	attrib disdate format=mmddyy10.;

	* Classify each stay;
	mprovno3_6=substr(mprovno,3,4);
	if substr(mprovno,6,1)='E' then delete;

	length type 3;
	type=.;

	if mprovno3_6 >=0000 and mprovno3_6<=0879 and mpcode notin ('M', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z') then type=1;
	if mprovno3_6 >=5000 and mprovno3_6<=6499 and mpcode notin ('M', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z') then type=2; 
	if mprovno3_6 >=2000 and mprovno3_6<=2299 and mpcode notin ('M', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z') then type=3;
	if (mprovno3_6 >=3025 and mprovno3_6<=3099) or mpcode in ('R', 'T') and mpcode notin ('M', 'S', 'U', 'V', 'W', 'Y', 'Z') then type=4;
	if (mprovno3_6 >0879 and mprovno3_6<2000) or (mprovno3_6 >2299 and mprovno3_6<3025) or (mprovno3_6 >3099 and mprovno3_6<5000) or (mprovno3_6>6499) 
		or mpcode in ('M', 'S', 'U', 'V', 'W', 'Y', 'Z')  and mpcode notin ('R', 'T') then type=5;

run;

* Get rid of temporary file;
x "cd /space/cafendul/";
x "rm -f mp100_&year..sas7bdat";

* Check type variable;
proc freq;
	tables type*mpcode /missing;
run;

* Use code from Bruce to calculate Elixhauser variables;
****************************************************************;
* USING SECONDARY DX CODES AND DRG CODES                    *; 
* THE ORIGINAL ELIXHAUSER SCORE IS NUMBER 4.                   *;
****************************************************************;

data medpar_&year.(keep=hicbic admdate disdate medpar_exp type mdiag1-mdiag10 mprovno mcovdays mlos cond01-cond30);
	set medpar_&year.(drop=mpcode rename=(mdrg=drg_code));

ARRAY DIAG $ mdiag2-mdiag10; 

LENGTH COND01-COND30 3;                  

ARRAY COND COND01-COND30; 

DO I=1 TO 30;                    
   COND(I)=0;               
END; 

**************************************************************;
* FLAG SECONDARY DIAGNOSIS CODES                             *;
**************************************************************;

DO J=1 TO 9;         
   IF DIAG(J) IN ('39891','40211','40291','40411','40413','40491','40493') OR
      '4280 '<=DIAG(J)<='42899' THEN COND01=1;
   
   IF DIAG(J) IN ('42610','42611','42613','42731','42760') OR
      '4262 '<=DIAG(J)<='42653' OR '4266 '<=DIAG(J)<='42689' OR 
      SUBSTR(DIAG(J),1,4) IN ('4270','4272','4279','7850','V450','V533') THEN COND02=1;

   IF '09320'<=DIAG(J)<='09324' OR '3940 '<=DIAG(J)<='39719' OR '4240 '<=DIAG(J)<='42491' OR
      '7463 '<=DIAG(J)<='74669' OR 'V422 '<=DIAG(J)<='V4229' OR 'V433 '<=DIAG(J)<='V4339'
      THEN COND03=1;

   IF '4160 '<=DIAG(J)<='41699' OR '4179 '<=DIAG(J)<='41799' THEN COND04=1;

   IF '4400 '<=DIAG(J)<='44099' OR SUBSTR(DIAG(J),1,4) IN ('4412','4414','4417','4419','4471','5571','5579','V434') OR
      '4431 '<=DIAG(J)<='44399' THEN COND05=1;

   IF SUBSTR(DIAG(J),1,4) IN ('4011','4019') OR DIAG(J) IN ('40210','40290','40410','40490','40511','40519','40591','40599')
      THEN COND06=1;

   IF '3420 '<=DIAG(J)<='34212' OR '3429 '<=DIAG(J)<='34499' THEN COND07=1;

   IF SUBSTR(DIAG(J),1,4) IN ('3319','3320','3334','3335','3481','3483','7803','7843') OR
      '3340 '<=DIAG(J)<='33599' OR '340  '<=DIAG(J)<='34099' OR '3411 '<=DIAG(J)<='34199' OR 
      '34500'<=DIAG(J)<='34511' OR '34540'<=DIAG(J)<='34551' OR '34580'<=DIAG(J)<='34591' THEN COND08=1;

   IF '490  '<=DIAG(J)<='49289' OR '49300'<=DIAG(J)<='49391' OR '494  '<=DIAG(J)<='49499' OR 
      '4950 '<=DIAG(J)<='50599' OR '5064 '<=DIAG(J)<='50649' THEN COND09=1;

   IF '25000'<=DIAG(J)<='25033' THEN COND10=1;

   IF '25040'<=DIAG(J)<='25073' OR '25090'<=DIAG(J)<='25093' THEN COND11=1;

   IF '243  '<=DIAG(J)<='24429' OR '2448 '<=DIAG(J)<='24489' OR '2449 '<=DIAG(J)<='24499' THEN COND12=1;

   IF DIAG(J) IN ('40311','40391','40412','40492') OR SUBSTR(DIAG(J),1,3) IN ('585','586') OR
      SUBSTR(DIAG(J),1,4) IN ('V420','V451','V560','V568') THEN COND13=1;

   IF DIAG(J) IN ('07032','07033','07054','45620','45621') OR 
      SUBSTR(DIAG(J),1,4) IN ('4560','4561','5710','5712','5713','5715','5716','5718','5719','5723','5728','V427') OR
      '57140'<=DIAG(J)<='57149' THEN COND14=1;

   IF DIAG(J) IN ('53170','53190','53270','53290','53370','53390','53470','53490','V1271') THEN COND15=1;

   IF '042  '<=DIAG(J)<='04499' THEN COND16=1;

   IF '20000'<=DIAG(J)<='20238' OR '20250'<=DIAG(J)<='20301' OR '2038 '<=DIAG(J)<='20381' OR
      SUBSTR(DIAG(J),1,4) IN ('2386','2733') OR DIAG(J) IN ('V1071','V1072','V1079') THEN COND17=1;

   IF '1960 '<=DIAG(J)<='19919' THEN COND18=1;

   IF '1400 '<=DIAG(J)<='17299' OR '1740 '<=DIAG(J)<='17599' OR '179  '<=DIAG(J)<='19589' OR 'V1000'<=DIAG(J)<='V1099' THEN COND19=1;

   IF '7010 '<=DIAG(J)<='70109' OR '7100 '<=DIAG(J)<='71099' OR '7140 '<=DIAG(J)<='71499' OR '7200 '<=DIAG(J)<='72099' OR
      SUBSTR(DIAG(J),1,3)='725' THEN COND20=1;

   IF '2860 '<=DIAG(J)<='28699' OR SUBSTR(DIAG(J),1,4) IN ('2871','2873','2874','2875') THEN COND21=1;

   IF SUBSTR(DIAG(J),1,4)='2780' THEN COND22=1;

   IF '260  '<=DIAG(J)<='26399' THEN COND23=1;

   IF '2760 '<=DIAG(J)<='27699' THEN COND24=1;

   IF '2800 '<=DIAG(J)<='28009' THEN COND25=1;

   IF '2801 '<=DIAG(J)<='28199' OR '2859 '<=DIAG(J)<='28599' THEN COND26=1;

   IF SUBSTR(DIAG(J),1,4) IN ('2911','2912','2915','2918','2919','V113') OR
      '30390'<=DIAG(J)<='30393' OR '30500'<=DIAG(J)<='30503' THEN COND27=1;

   IF SUBSTR(DIAG(J),1,4) IN ('2920','2929') OR '29282'<=DIAG(J)<='29289' OR '30400'<=DIAG(J)<='30493' OR
      '30520'<=DIAG(J)<='30593' THEN COND28=1;

   IF '29500'<=DIAG(J)<='29899' OR '29910'<=DIAG(J)<='29911' THEN COND29=1;

   IF SUBSTR(DIAG(J),1,4) IN ('3004','3090','3091') OR SUBSTR(DIAG(J),1,3)='311' OR DIAG(J)='30112' THEN COND30=1;

END;     

**************************************************************;
* FLAG DRG CODES                                             *;
**************************************************************;
IF 103<=DRG_CODE<=108 OR 110<=DRG_CODE<=112 OR 115<=DRG_CODE<=118 OR 120<=DRG_CODE<=127 OR DRG_CODE=129 OR
   132<=DRG_CODE<=133 OR 135<=DRG_CODE<=143 THEN CARDIACDRG=1; ELSE CARDIACDRG=0;

IF DRG_CODE=88 THEN COPDDRG=1; ELSE COPDDRG=0;

IF 130<=DRG_CODE<=131 THEN PVDDRG=1; ELSE PVDDRG=0;

IF DRG_CODE=134 THEN HYPERDRG=1; ELSE HYPERDRG=0;

IF 302<=DRG_CODE<=305 OR 315<=DRG_CODE<=333 THEN RENALDRG=1; ELSE RENALDRG=0;

IF 199<=DRG_CODE<=202 OR 205<=DRG_CODE<=208 THEN LIVERDRG=1; ELSE LIVERDRG=0;

IF 400<=DRG_CODE<=414 OR DRG_CODE=473 OR DRG_CODE=492 THEN LEUKDRG=1; ELSE LEUKDRG=0;

IF DRG_CODE IN (10,11,64,82,172,173,199,203,239,257,258,259,260,274,275,303,318,319,338,344,346,347,354,355,357,363,366,367) OR
   406<=DRG_CODE<=414 THEN CANCERDRG=1; ELSE CANCERDRG=0;

IF DRG_CODE=5 OR 14<=DRG_CODE<=17 THEN CEREBDRG=1; ELSE CEREBDRG=0;

IF 1<=DRG_CODE<=35 THEN NERVDRG=1; ELSE NERVDRG=0;

IF 96<=DRG_CODE<=98 THEN ASTHMADRG=1; ELSE ASTHMADRG=0;

IF 294<=DRG_CODE<=295 THEN DIABDRG=1; ELSE DIABDRG=0;

IF DRG_CODE=290 THEN THYROIDDRG=1; ELSE THYROIDDRG=0;

IF 300<=DRG_CODE<=301 THEN ENDODRG=1; ELSE ENDODRG=0;

IF DRG_CODE=302 THEN KIDNEYDRG=1; ELSE KIDNEYDRG=0;

IF 316<=DRG_CODE<=317 THEN RENALFAILDRG=1; ELSE RENALFAILDRG=0;

IF 174<=DRG_CODE<=178 THEN GIDRG=1; ELSE GIDRG=0;

IF 488<=DRG_CODE<=490 THEN HIVDRG=1; ELSE HIVDRG=0;

IF 240<=DRG_CODE<=241 THEN CONNDRG=1; ELSE CONNDRG=0;

IF DRG_CODE=397 THEN COAGDRG=1; ELSE COAGDRG=0;

IF DRG_CODE=288 THEN OBESITYDRG=1; ELSE OBESITYDRG=0;

IF 296<=DRG_CODE<=298 THEN NUTRDRG=1; ELSE NUTRDRG=0;

IF 395<=DRG_CODE<=396 THEN ANEMIADRG=1; ELSE ANEMIADRG=0;

IF 433<=DRG_CODE<=437 THEN ALCDRUGDRG=1; ELSE ALCDRUGDRG=0;

IF DRG_CODE=430 THEN PSYCHODRG=1; ELSE PSYCHODRG=0;

IF DRG_CODE=426 THEN DEPRESSDRG=1; ELSE DEPRESSDRG=0;

********************************************************************;
* COMBINE CONDITION AND DRG                                        *;
********************************************************************;
IF COND01=1 AND CARDIACDRG=0 THEN CONDNODRG01=1; ELSE CONDNODRG01=0;
IF COND02=1 AND CARDIACDRG=0 THEN CONDNODRG02=1; ELSE CONDNODRG02=0;
IF COND03=1 AND CARDIACDRG=0 THEN CONDNODRG03=1; ELSE CONDNODRG03=0;
IF COND04=1 AND CARDIACDRG=0 AND COPDDRG=0 THEN CONDNODRG04=1; ELSE CONDNODRG04=0;
IF COND05=1 AND PVDDRG    =0 THEN CONDNODRG05=1; ELSE CONDNODRG05=0;
IF COND06=1 AND HYPERDRG  =0 AND CARDIACDRG=0 AND RENALDRG=0 THEN CONDNODRG06=1; ELSE CONDNODRG06=0;
IF COND07=1 AND CEREBDRG  =0 THEN CONDNODRG07=1; ELSE CONDNODRG07=0;
IF COND08=1 AND NERVDRG   =0 THEN CONDNODRG08=1; ELSE CONDNODRG08=0;
IF COND09=1 AND COPDDRG   =0 AND ASTHMADRG=0 THEN CONDNODRG09=1; ELSE CONDNODRG09=0;
IF COND10=1 AND DIABDRG   =0 THEN CONDNODRG10=1; ELSE CONDNODRG10=0;
IF COND11=1 AND DIABDRG   =0 THEN CONDNODRG11=1; ELSE CONDNODRG11=0;
IF COND12=1 AND THYROIDDRG=0 AND ENDODRG=0 THEN CONDNODRG12=1; ELSE CONDNODRG12=0;
IF COND13=1 AND KIDNEYDRG =0 AND RENALFAILDRG=0 THEN CONDNODRG13=1; ELSE CONDNODRG13=0;
IF COND14=1 AND LIVERDRG  =0 THEN CONDNODRG14=1; ELSE CONDNODRG14=0;
IF COND15=1 AND GIDRG     =0 THEN CONDNODRG15=1; ELSE CONDNODRG15=0;
IF COND16=1 AND HIVDRG    =0 THEN CONDNODRG16=1; ELSE CONDNODRG16=0;
IF COND17=1 AND LEUKDRG   =0 THEN CONDNODRG17=1; ELSE CONDNODRG17=0;
IF COND18=1 AND CANCERDRG =0 THEN CONDNODRG18=1; ELSE CONDNODRG18=0;
IF COND19=1 AND CANCERDRG =0 THEN CONDNODRG19=1; ELSE CONDNODRG19=0;
IF COND20=1 AND CONNDRG   =0 THEN CONDNODRG20=1; ELSE CONDNODRG20=0;
IF COND21=1 AND COAGDRG   =0 THEN CONDNODRG21=1; ELSE CONDNODRG21=0;
IF COND22=1 AND OBESITYDRG=0 AND NUTRDRG=0 THEN CONDNODRG22=1; ELSE CONDNODRG22=0;
IF COND23=1 AND NUTRDRG   =0 THEN CONDNODRG23=1; ELSE CONDNODRG23=0;
IF COND24=1 AND NUTRDRG   =0 THEN CONDNODRG24=1; ELSE CONDNODRG24=0;
IF COND25=1 AND ANEMIADRG =0 THEN CONDNODRG25=1; ELSE CONDNODRG25=0;
IF COND26=1 AND ANEMIADRG =0 THEN CONDNODRG26=1; ELSE CONDNODRG26=0;
IF COND27=1 AND ALCDRUGDRG=0 THEN CONDNODRG27=1; ELSE CONDNODRG27=0;
IF COND28=1 AND ALCDRUGDRG=0 THEN CONDNODRG28=1; ELSE CONDNODRG28=0;
IF COND29=1 AND PSYCHODRG =0 THEN CONDNODRG29=1; ELSE CONDNODRG29=0;
IF COND30=1 AND DEPRESSDRG=0 THEN CONDNODRG30=1; ELSE CONDNODRG30=0;  

LABEL CONDNODRG01='CONGESTIVE HEART FAILURE, NO DRG'
      CONDNODRG02='CARDIAC ARRHYTHMIAS, NO DRG'
      CONDNODRG03='VALVULAR DISEASE, NO DRG'
      CONDNODRG04='PULMONARY CIRCULATION DISORDERS, NO DRG'
      CONDNODRG05='PERIPHERAL VASCULAR DISORDERS, NO DRG'
      CONDNODRG06='HYPERTENSION, NO DRG'
      CONDNODRG07='PARALYSIS, NO DRG'
      CONDNODRG08='OTHER NEUROLOGICAL DISORDERS, NO DRG'
      CONDNODRG09='CHRONIC PULMONARY DISEASE, NO DRG'
      CONDNODRG10='DIABETES, UNCOMPLICATED, NO DRG'
      CONDNODRG11='DIABETES, COMPLICATED, NO DRG'
      CONDNODRG12='HYPOTHYOIDISM, NO DRG'
      CONDNODRG13='RENAL FAILURE, NO DRG'
      CONDNODRG14='LIVER DISEASE, NO DRG'
      CONDNODRG15='PEPTIC ULCER DISEASE EXCLUDING BLEEDING, NO DRG'
      CONDNODRG16='AIDS, NO DRG'
      CONDNODRG17='LYMPHOMA, NO DRG'
      CONDNODRG18='METASTATIC CANCER, NO DRG'
      CONDNODRG19='SOLID TUMOR WITHOUT METASTASIS, NO DRG'
      CONDNODRG20='RHEUMATOID ARTHRITIS / COLLAGEN VASCULAR DISEASES, NO DRG'
      CONDNODRG21='COAGULOPATHY, NO DRG'
      CONDNODRG22='OBESITY, NO DRG'
      CONDNODRG23='WEIGHT LOSS, NO DRG'
      CONDNODRG24='FLUID AND ELECTROLYTE DISORDERS, NO DRG'
      CONDNODRG25='BLOOD LOSS ANEMIA, NO DRG'
      CONDNODRG26='DEFICIENCY ANEMIAS, NO DRG'
      CONDNODRG27='ALCOHOL ABUSE, NO DRG'
      CONDNODRG28='DRUG ABUSE, NO DRG'
      CONDNODRG29='PSYCHOSES, NO DRG'
      CONDNODRG30='DEPRESSION, NO DRG'

********************************************************************************;
* IF FLAGGED AS SEVERE AND MILD, JUST KEEP SEVERE                              *;
********************************************************************************;
IF CONDNODRG10=1 AND CONDNODRG11=1 THEN CONDNODRG10=0;
IF CONDNODRG18=1 AND CONDNODRG19=1 THEN CONDNODRG19=0;

run;

* Code the six readmission variables, using PPS hospital stays only.  Use both the principal diagnosis code field and the secondary diagnosis code fields to do this;
data medpar_&year.(keep=hicbic admdate disdate medpar_exp type mpcode mprovno mcovdays mlos cond01-cond30 anemia chf ei ri sepsis uti);
	set medpar_&year.;

	length anemia chf ei ri sepsis uti 3;
	anemia=0;
	chf=0;
	ei=0;
	ri=0;
	sepsis=0;
	uti=0;

	if type=1 then do;;
		array read $ mdiag1-mdiag10;
		do K=1 to 10;
			if substr(read(K),1,3) in('280', '281') OR substr(read(K),1,4) ='2851' OR substr(read(K),1,5)= '28529' then anemia=1;
			if read(K)='39891' OR substr(read(K),1,3) ='428' then chf=1;
			if substr(read(K),1,3) ='276' then ei=1;
			if substr(read(K),1,4) IN ('4660', '5070') OR substr(read(K),1,3) IN ('480','487') then ri=1;
			if substr(read(K),1,3)='038' then sepsis=1;;
			if substr(read(K),1,3) in ('590','601') OR substr(read(K),1,4) in ('5950', '5951', '5952', '5954',  '5959', '5970', '5980', '5990') OR substr(read(K),1,5) ='59589' then uti=1;;
			end;
 		label
			anemia='anemia'
			chf='congestive hearth failure'
			ei='electroyte imbalance'
			ri='respiratory infection'
			sepsis='sepsis'
			uti='urinary tract infection'
			;
		end;

run;

* Append years;
data medpar_9600;
%if &year.=&firstyear. %then %do;
	set medpar_&year.;
%end;
%else %do;
	set medpar_9600 medpar_&year.;
%end;
run;

* Remove temporary dataset;
proc datasets;
	delete medpar_&year.;
run;

%end;

%mend medpar;

%medpar(1996,2000);

* Break into separate files;
data tmp.pps_hosp_9600 (drop=type rename=(medpar_exp=pps_hosp_exp));
	set medpar_9600;
	if type=1;
run;

proc sort;
	by hicbic;
run;

proc means;
run;

proc contents;
run;

data tmp.snf_9600 (drop=type chf ei ri sepsis uti anemia rename=(medpar_exp=snf_exp));
	set medpar_9600;
	if type=2;
run;

proc sort;
	by hicbic;
run;

proc means;
run;

proc contents;
run;

data tmp.ltc_hosp_9600 (drop=type chf ei ri sepsis uti anemia rename=(medpar_exp=ltc_hosp_exp));
	set medpar_9600;
	if type=3;
run;

proc sort;
	by hicbic;
run;

proc means;
run;

proc contents;
run;

data tmp.rehab_hosp_9600 (drop=type chf ei ri sepsis uti anemia rename=(medpar_exp=rehab_hosp_exp));
	set medpar_9600;
	if type=4;
run;

proc sort;
	by hicbic;
run;

proc means;
run;

proc contents;
run;

data tmp.other_hosp_9600 (drop=type chf ei ri sepsis uti anemia rename=(medpar_exp=other_hosp_exp));
	set medpar_9600;
	if type=5;
run;

proc sort;
	by hicbic;
run;

proc means;
run;

proc contents;
run;

* Get rid of temporary dataset;
proc datasets;
	delete medpar_9600;
run;

* Zip files and move to permanent location;
x "cd /space/cafendul/";

x "gzip -f pps_hosp_9600.sas7bdat";
x "gzip -f snf_9600.sas7bdat";
x "gzip -f ltc_hosp_9600.sas7bdat";
x "gzip -f rehab_hosp_9600.sas7bdat";
x "gzip -f other_hosp_9600.sas7bdat";

x "chmod 750 pps_hosp_9600.sas7bdat.gz";
x "chmod 750 -f snf_9600.sas7bdat.gz";
x "chmod 750 ltc_hosp_9600.sas7bdat.gz";
x "chmod 750 rehab_hosp_9600.sas7bdat.gz";
x "chmod 750 other_hosp_9600.sas7bdat.gz";

x "mv -f pps_hosp_9600.sas7bdat.gz /disk/agebulk1/medicare.work/kessler-DUA16444/cafendul/hosp_integration/summer09/";
x "mv -f snf_9600.sas7bdat.gz /disk/agebulk1/medicare.work/kessler-DUA16444/cafendul/hosp_integration/summer09/";
x "mv -f ltc_hosp_9600.sas7bdat.gz /disk/agebulk1/medicare.work/kessler-DUA16444/cafendul/hosp_integration/summer09/";
x "mv -f rehab_hosp_9600.sas7bdat.gz /disk/agebulk1/medicare.work/kessler-DUA16444/cafendul/hosp_integration/summer09/";
x "mv -f other_hosp_9600.sas7bdat.gz /disk/agebulk1/medicare.work/kessler-DUA16444/cafendul/hosp_integration/summer09/";
