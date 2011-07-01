/***
HCC_byhicbic.sas

sas file for recoding ICD-9 (int'l classification of disease codes) from MedPAR to HCC (hazard characteristic code) dummies

last updated: 16May2011
author: Angela Wang amwang@stanford.edu

input: 	2007_HCC.txt
		medpar100.sas7bdat
		
output: medpar_hcc_byhicbic.sas7bdat

***/

options nocenter pagesize=max;
%let size=100;
%let d1=1; /*dgnsc 1*/
%let d2=10; /*dgnsc 2*/

libname tmp "/space/wanga/test/&size.";
x "cd /space/wanga/test/&size.";

*import ICD-9 HCC file;
data tmp.hcc;
%let _EFIERR_ = 0; 
*set the ERROR detection macro variable;
infile '2007_HCC.txt' delimiter='09'x MISSOVER DSD lrecl=32767 firstobs=2 ;
informat ICD9 $6. ;
informat HCC 3. ;
format ICD9 $6. ;
format HCC 3. ;
input ICD9 $
HCC
;
if _ERROR_ then call symputx('_EFIERR_',1); 
*set ERROR detection macro variable;
run;

*create working medpar;
proc sort data = tmp.medpar&size. out=medpar;
	by hicbic;
run;

*create id for ease of merging;
data medpar (keep=hicbic id dschrgdt mprovno dgnscd1-dgnscd10);
	set medpar;
	id = _N_;
run;

proc datasets nolist;
	delete dgnscd;
run;

*loop through dgnscds and match to hcc;
%macro hcc();
%do num=&d1. %to &d2.;
*create table with id, dgnscd, and hcc;
	proc sql;
		create table medpar&num. as
		select id, dgnscd&num., hcc as hcc&num.
		from medpar a left join tmp.hcc b on a.DGNSCD&num.=b.ICD9;
	quit;

	%if &num.=1 %then %do;
		data medpar_hcc;
		set medpar&num.;
		run;
	%end;
	%else %do;
		proc sql;
		create table medpar_hcc as
		select a.*, dgnscd&num., hcc&num.
		from medpar_hcc a left join medpar&num. b
		on a.id=b.id;
		quit;
	%end;
	run;

	proc datasets nolist;
		delete medpar&num.;
	run;

%end;
%mend;
%hcc();

proc datasets nolist;
	delete med_hcc;
run;

*create primary hcc dummies and label;
data hcc (keep = id p1 p2 p5 p7 p8 p9 p10 p15 p16 p17 p18 p19 p21 p25 p26 p27 p31 p32 p33 p37 p38 p44 p45 p51 p52 p54 p55 p67 p68 p69 p70 p71 p72 p73 p74 p75 p77 p78 p79 p80 p81 p82 p83 p92 p95 p96 p100 p101 p104 p105 p107 p108 p111 p112 p119 p130 p131 p132 p148 p149 p150 p154 p155 p157 p158 p161 p164 p174 p176 p177);
	set medpar_hcc;

	*loop to form a set of 70 hcc dummies;
	array P {*} 3. p1-p177;
	do i=1 to 177;
		P(i) = ((hcc1=i)or(hcc2=i)or(hcc3=i)or(hcc3=i)or(hcc4=i)or(hcc5=i)or(hcc6=i)or(hcc7=i)or(hcc8=i)or(hcc9=i)or(hcc10=i));
	end;

label 
	p1="HIV/AIDS Infection"
	p2="Septicemia/Shock Infection"
	p5="Opportunistic Infections Infection"
	p7="Metastatic Cancer and Acute Leukemia Neoplasm"
	p8="Lung, Upper Digestive Tract, and Other Severe Cancers Neoplasm"
	p9="Lymphatic, Head and Neck, Brain, and Other Major Cancers Neoplasm"
	p10="Breast, Prostate, Colorectal and Other Cancers and Tumors Neoplasm"
	p15="Diabetes with Renal or Peripheral Circulatory Manifestation Diabetes"
	p16="Diabetes with Neurologic or Other Specified Manifestation Diabetes"
	p17="Diabetes with Acute Complications Diabetes"
	p18="Diabetes with Ophthalmologic or Unspecified Manifestation Diabetes"
	p19="Diabetes without Complication Diabetes"
	p21="Protein-Calorie Malnutrition Metabolic"
	p25="End-Stage Liver Disease Liver"
	p26="Cirrhosis of Liver Liver"
	p27="Chronic Hepatitis Liver"
	p31="Intestinal Obstruction/Perforation Gastrointestinal"
	p32="Pancreatic Disease Gastrointestinal"
	p33="Inflammatory Bowel Disease Gastrointestinal"
	p37="Bone/Joint/Muscle Infections/Necrosis Musculoskeletal"
	p38="Rheumatoid Arthritis and Inflammatory Connective Tissue Disease Musculoskeletal"
	p44="Severe Hematological Disorders Blood"
	p45="Disorders of Immunity Blood"
	p51="Drug/Alcohol Psychosis Substance"
	p52="Drug/Alcohol Dependence Substance"
	p54="Schizophrenia Psych"
	p55="Major Depressive, Bipolar, and Paranoid Disorders Psych"
	p67="Quadriplegia, Other Extensive Paralysis Spinal"
	p68="Paraplegia Spinal"
	p69="Spinal Cord Disorders/Injuries Spinal"
	p70="Muscular Dystrophy Neuro"
	p71="Polyneuropathy Neuro"
	p72="Multiple Sclerosis Neuro"
	p73="Parkinson's and Huntington's Diseases Neuro"
	p74="Seizure Disorders and Convulsions Neuro"
	p75="Coma, Brain Compression/Anoxic Damage Neuro"
	p77="Respirator Dependence/Tracheostomy Status Arrest"
	p78="Respiratory Arrest Arrest"
	p79="Cardio-Respiratory Failure and Shock Arrest"
	p80="Congestive Heart Failure Heart"
	p81="Acute Myocardial Infarction Heart"
	p82="Unstable Angina and Other Acute Ischemic Heart Disease Heart"
	p83="Angina Pectoris/Old Myocardial Infarction Heart"
	p92="Specified Heart Arrhythmias Heart"
	p95="Cerebral Hemorrhage CVD"
	p96="Ischemic or Unspecified Stroke CVD"
	p100="Hemiplegia/Hemiparesis CVD"
	p101="Cerebral Palsy and Other Paralytic Syndromes CVD"
	p104="Vascular Disease with Complications Vascular"
	p105="Vascular Disease Vascular"
	p107="Cystic Fibrosis Lung"
	p108="Chronic Obstructive Pulmonary Disease Lung"
	p111="Aspiration and Specified Bacterial Pneumonias Lung"
	p112="Pneumococcal Pneumonia, Emphysema, Lung Abscess Lung"
	p119="Proliferative Diabetic Retinopathy and Vitreous Hemorrhage Eye"
	p130="Dialysis Status Urinary"
	p131="Renal Failure Urinary"
	p132="Nephritis Urinary"
	p148="Decubitus Ulcer of Skin Skin"
	p149="Chronic Ulcer of Skin, Except Decubitus Skin"
	p150="Extensive Third-Degree Burns Skin"
	p154="Severe Head Injury Injury"
	p155="Major Head Injury Injury"
	p157="Vertebral Fractures without Spinal Cord Injury Injury"
	p158="Hip Fracture/Dislocation Injury"
	p161="Traumatic Amputation Injury"
	p164="Major Complications of Medical Care and Trauma Complications"
	p174="Major Organ Transplant Status Transplant"
	p176="Artificial Openings for Feeding or Elimination Openings"
	p177="Amputation Status, Lower Limb/Amputation Complications"
run;

*merge hcc dummies to medpar using id;
proc sql;
	create table medpar_hcc_id as
	select a.*, b.*
	from medpar a, hcc b
	where a.id=b.id;
quit;

*collapse to form beneficiary level file;
proc means data=medpar_hcc_id noprint;
	by hicbic;
	var p1--p177 medpar_payment;
	output out=tmp.medpar_hcc_byhicbic
	max(p1--p177) = /autoname;
run;

proc datasets nolist;
	delete hcc medpar_hcc_id medpar_hcc;
run;

*stat-transfer;
x "st medpar_hcc_byhicbic.sas7bdat medpar_hcc_byhicbic.dta";

*cleanup;
x "mv 2007_HCC.txt /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv medpar100.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv medpar_hcc_byhicbic.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv medpar_hcc_byhicbic.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/analysis_stata/100/statanew";