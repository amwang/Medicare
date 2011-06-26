/***

Chris Afendulis
Last modified 28 Jan 2011

Extract mprovno, address, city, state, ZIP code for all PPS hospitals active in CY 2008.

Input data:
      http://www.cms.gov/CostReports/Downloads/HospitalFY2007.zip
      http://www.cms.gov/CostReports/Downloads/HospitalFY2008.zip
      http://www.cms.gov/CostReports/Downloads/HospitalFY2009.zip
      copies also placed in /disk/homes2b/nber/cafendul/hosp_prices

Output files:
       /disk/homes2b/nber/cafendul/hosp_prices/hosp_cr.sas7bdat

***/

libname tmp "/space/cafendul";

options mprint;

%macro costrpt(firstyear,lastyear);

%do year=&firstyear. %to &lastyear.;

* Get files;
x "cd /disk/homes2b/nber/cafendul/hosp_prices/";
x "wget -nv http://www.cms.gov/CostReports/Downloads/HospitalFY&year..zip";
x "cp HospitalFY&year..zip /space/cafendul";

* Unzip;
x "cd /space/cafendul";
x "unzip -u HospitalFY&year..zip hosp_&year._RPT.CSV hosp_&year._ALPHA.CSV";

* It is necessary to get rid of the carriage returns in each file;
x "tr -d '\r'< hosp_&year._RPT.CSV > hosp_&year._RPT.CSV.2";
x "rm -f hosp_&year._RPT.CSV";
x "mv hosp_&year._RPT.CSV.2 hosp_&year._RPT.CSV";

x "tr -d '\r'< hosp_&year._ALPHA.CSV > hosp_&year._ALPHA.CSV.2";
x "rm -f hosp_&year._ALPHA.CSV";
x "mv hosp_&year._ALPHA.CSV.2 hosp_&year._ALPHA.CSV";

* Import all files into SAS;

x "cd /space/cafendul";
filename rpt "hosp_&year._RPT.CSV";

data rpt;
    length
        report_id 5
        PRVDR_CTRL_TYPE_CD 3
        mprovno $6
        RPT_STUS_CD 3
        INITL_RPT_SW $1
        LAST_RPT_SW $1
        TRNSMTL_NUM $1
        FI_NUM $5
        ADR_VNDR_CD 3
        UTIL_CD $1
        SPEC_IND $1
        default = 4.;
    infile rpt dsd delimiter=',' lrecl=3072 missover;
    input
        report_id
        PRVDR_CTRL_TYPE_CD 
        mprovno $ 
        NPI 
        RPT_STUS_CD                       
        FY_BGN_DT : mmddyy10.                                   
        FY_END_DT : mmddyy10.                                      
        PROC_DT : mmddyy10.                
        INITL_RPT_SW $
        LAST_RPT_SW $
        TRNSMTL_NUM $                    
        FI_NUM $
        ADR_VNDR_CD                      
        FI_CREAT_DT : mmddyy10.                                   
        UTIL_CD $                          
        NPR_DT : mmddyy10.                                            
        SPEC_IND $                        
        FI_RCPT_DT : mmddyy10.
        ;
    format
        FY_BGN_DT   MMDDYYS10.
        FY_END_DT   MMDDYYS10.
        PROC_DT     MMDDYYS10.
        FI_CREAT_DT MMDDYYS10.
        NPR_DT      MMDDYYS10.
        FI_RCPT_DT  MMDDYYS10.
        ;
run;

filename alpha "hosp_&year._ALPHA.CSV";

data alphnmrc;
    length worksheet $7. row $5. col $4. element $40.;
    infile alpha dsd delimiter=',' lrecl=3072 missover;
    input
        report_id
        Worksheet $
        row $
        Col $
        element  $
        ;
run;

* Delete all files;
x "rm -f HospitalFY&year..zip";
x "rm -f hosp_&year._RPT.CSV hosp_&year._ALPHA.CSV";

* Work with the RPT file first;
* Restrict attention to hospitals from 50 states+DC;
* Drop reports that end before 1 Jan 2008 or begin after 31 Dec 2008;
* Drop reports from non-PPS hospitals;
data hospinfo_&year. (drop=state last_four);
	set rpt (keep=report_id mprovno fy_bgn_dt fy_end_dt);

	state=substr(mprovno,1,2);
	if state in ('40', '48', '64', '65', '99') then delete;

        if fy_end_dt<'01Jan2008'D then delete;
        if fy_bgn_dt>'31Dec2008'D then delete;
	if fy_bgn_dt=. then delete;

	last_four=substr(mprovno,3,4);
	if last_four>=0000 and last_four<=0879;

run;

* Get rid of duplicates by report id;
proc sort nodupkey;
    by report_id;
run;

* Create a file that contains street, city, state and ZIP;
data address (drop=worksheet row col);
	set alphnmrc;
	if (worksheet='S200000' and col='0100' and row='00100') /*street*/
	or (worksheet='S200000' and col='0100' and row='00101') /*city*/
	or (worksheet='S200000' and col='0200' and row='00101') /*state*/
	or (worksheet='S200000' and col='0300' and row='00101') /*ZIP*/;
	colrow=col||row;
run;

* Transpose data into columns;
proc transpose data=address out=newaddress;
    by report_id;
    id colrow;
    var element;
run;

* Keep only the first five digits of ZIP code, create variable names;
data newaddress (keep=report_id street city state zip);
	set newaddress;

	length street $40.;
	street=_010000100;

	length city $40.;
	city=_010000101;

	length state $40.;
	state=_020000101;

	length zip $5.;
	zip=substr(_030000101,1,5);

run;

* Get rid of duplicates;
proc sort nodupkey;
    by report_id;
run;

* Merge to earlier dataset using reportid -- drop any cases that do not match;
data hospinfo_&year.;
    merge newaddress(in=a) hospinfo_&year.(in=b);
    by report_id;
    if a=1 and b=1;
run;

* Append files together;
data tmp.hosp_cr;
	%if &year.=&firstyear. %then %do;
	set hospinfo_&year.;
		%end;
	%else %do;
	set tmp.hosp_cr hospinfo_&year.;
	%end;
run;

%end;

%mend costrpt;

%costrpt(2007,2009);

* See what the addresses, cities, states and ZIPs look like;
proc freq;
     tables street city state zip /missing;
run;

* Check to see if some hosps have multiple addresses across cost reports;
proc sort data=tmp.hosp_cr nodupkey out=test1;
	by mprovno street city state zip;
run;

* Keep one case only for each mprovno;
proc sort data=tmp.hosp_cr nodupkey out=test1;
	by mprovno;
run;

proc contents;
run;

* Zip and move files;
x "gzip -f hosp_cr.sas7bdat";
x "mv hosp_cr.sas7bdat.gz /disk/homes2b/nber/cafendul/hosp_prices/";
