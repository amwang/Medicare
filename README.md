#Readme for Medicare project
*The current project deals only with 2008 data, but the code can be modified so that subsequent years can be added. The macro %year is used in all code.
*Change working directories to correspond to your own.

##Piece-by-Piece: building our dataset
###Medicare beneficiary data (unique identifier: hicbic)
One should begin by understanding the anatomy of the Medicare utilization and enrollment data from CMS (Center for Medicare & Medicaid Services). The [RESDAC (Research Data Assistance Center) website](http://www.resdac.org/ddvh/Index.asp) provides detailed codebook info regarding all the datasets that are available to researchers. The pertinent files for this project are the "Medicare Denominator File" (commonly referred to as "denom"), which is a enrollment/summary file, and the "Medicare MedPAR file" (referred to as "MedPAR"), which is the utilization file. These files are **big**. New programmers should take a look at the RESDAC documentation to get acquainted with the data and determine what variables are available and where they are located.  
-The denominator file contains all enrollees (aka beneficiary, eligible, or member) in Medicare for the calendar year and their demographic information including: date of birth, date of death, zip code of residence, sex, ethnicity, monthly indicators for hmo enrollment, monthly indicators eligibility for medicare, etc. For 2008 this file contains 45+ million observations. 
-The MedPAR File contains inpatient hospital and skilled nursing facility (SNF) final action stay records. Each MedPAR record represents a stay in an inpatient hospital or SNF. An inpatient "stay" record summarizes all services rendered to a beneficiary from the time of admission to a facility through discharge. Each MedPAR record may represent one claim or multiple claims, depending on the length of a beneficiary's stay and the amount of inpatient services used throughout the stay. For 2008, this file contains 13+ million observations.  

Our data is stored on the NBER servers. Jean Roth (jroth@nber.org), one of the two data/server managers at the NBER, processes the yearly data that comes from the government every year. For 2008, the denom and MedPAR files are split into 100 files that need to be appended back together to form your personal working dataset. There are several sample sizes that you can use ranging from 1% (maybe smaller available as well) to the full 100% file. Working with a smaller file, will allow you to cut down on processing time during a debugging phase. Ultimately though, all analysis will be run on the 100% files.  

See construct\_denom.sas and construct\_medpar.sas for code to construct these files. Liberal comments are used in the denom file. These personal CMS working files are used heavily in the construction of other intermediary datasets further on in the project. After you have these constructed to your liking, make sure you have a backup stored somewhere as this is a processing intensive step.  

###Medicare hospitals (unique identifier: mprovno)
####Hospital Location/geocode
The raw file (/disk/homes2b/nber/cafendul/hosp_prices/Hospital_Geocoding_Result2.dbf) for this part of the project was obtained from Chris. We sent a file with hospitals and hospital addresses to Scott, our map library contact, who helped geocode them into latitude and longitude coordinates. This file is imported into SAS and saved as "hosp_geocodes.sas7bdat". The cleaned version, "hosp_geocode_clean.sas7bdat" has a total of 3560 unique hospitals.
clean\_hosp\_geocode.sas is used to clean up issues with this dataset to get to the clean dataset.  
Hospital data was checked against their listing on the [Medicare Data website](http://data.medicare.gov/dataset/Hospital-General-Information/v287-28n3).  
Some hospitals have miscoded zip codes. These zipcodes are corrected using the data step.
Exact duplicates are dropped, but many hospitals still contained multiple entries with conflicting geocodes.  
Hospital duplicates come in several flavors:  
- Miscoded zip codes: one entry has the wrong address/zipcode, the duplicate entry which was coded using the wrong zip was dropped  
- Conflicting address: 
	1) Hospitals that have multiple campuses but only one hospital code. We take the main campus to be the location for our geocode. 
	2) Hospitals with two addresses, we take the average of these geocodes to be our final geocode. Usually these geocodes are similar and have a difference of less than 0.01deg.

To further validate our hospital data we compare it to the geocodes provided by the AHA (American Hospital Association) hospital files. We don't use these files straight up because they only cover a portion of the hospitals we need geocodes for. That said only 147 hospitals appear in the cost reports but not the AHA. If lat and long differ by more than 0.5deg, the lat and long were updated to what was reported in the AHA. 
Note about AHA files: You'll need to sign a consent form through NBER/Jean to work with these files.  

####Hospital characteristics
Chris provides the hospital characteristic file. (/disk/homes2b/nber/cafendul/hosp_prices/hosp_chars.sas7bdat.gz)
The hospital characteristics include size (small, med, large) based on the number of beds, ownership (non-profit, for-profit, and teaching) and whether or not it is a teaching hospital.  

####CMS Cost reports
Chris provides us with CMS cost reports (/disk/homes2b/nber/cafendul/hosp_prices/hosp_chars_new.sas7bdat.gz). We calculate net 
npr_ccr_bymprovno.sas

###Patient characteristics
####Demographics
Age, male, and black indicators can be constructed directly from the denominator file. Code to implement this appears at various points throughout the project (eg. analysis\_denom.sas line 41-62 and )

####Patient location/geocode
5-digit zip-codes are also constructed directly from bene_zip in the denominator file. SAS has a handy zipcode-to-geocode crosswalk(sashelp.zipcode.sas7bdat) which will geocode any valid zipcode to the centroid of the zipcode and some [handy documentation](http://support.sas.com/resources/papers/proceedings10/219-2010.pdf).

We also create a complete 5-digit SSA(social security administration) state-county code by concatenating the SSA state-code and SSA county-codes from the denominator so that we can later merge in our IV: the Medicare Advantage benchmark payment rate.
Note that the SSA state-county code is different from the more commonly used FIPS(federal info processing stds) state-county codes. There are plenty of crosswalks available if any merging needs to be done.

####HCC (hazard characteristic code) (variables: p1_max-p177_max)
The HCC risk model is used to adjust Medicare capitation payments to private health care plans for the health expenditure risk of their enrollees. We are using the HCC in a different capacity: as binary controls for disease conditions.  
We recode ICD-9 (int'l classification of disease codes/diagnosis codes) from MedPAR to HCC using the CMS-HCC model that was in place in 2008, the [2007 HCC model software](https://www.cms.gov/MedicareAdvtgSpecRateStats/06a_Risk_adjustment_prior.asp). Note that the HCC scheme we use is not exhaustive, so not all of our diagnosis codes will have a matching HCC. CMS uses a modified version of the model which has 70 indicators in 2007, while the true HCC model has 180 or so. The percentage of ICD-9 codes that do not have a match are not worrisome.

HCC\_byhicbic.sas is used to recode the 10 diagnosis codes by stay in MedPAR to 70 HCC indicators by hicbic.  
The HCC indicators for each hicbic represents a summary of all HCCs that the beneficiary was diagnosed with over the calendar year. We map the 10 diagnosis codes to their respective HCCs for each stay and then reshape to obtain 70 indicator dummies for each stay.  We then take the maximum value of each HCC indicator by hicbic to obtain the hicbic level file.  

####MA indicator
[ResDAC provides a nice write up on GHO/HMO encoding in MedPAR files](http://www.resdac.org/tools/TBs/TN-009_MedicareManagedCareEnrolleesandUtilFiles_508.pdf)
The MedPAR file contains a variable called the MedPAR GHO Paid Code. This code indicate whether or not a Group Health Organization (MCO) has paid the provider for the claim. However, an empirical analysis conducted by ResDAC showed that the indictor was correct over 95% of the time, so they recommend that researchers use the monthly HMO indicators from the denominator data.

So we go about constructing our own MA indicator...


##Working in the Unix environment
###If your SAS program doesn't run:
Learning to love SAS will take time. Breath.  
-Semicolon delimiter. Is it at the end of every proc/data step?  
-Make sure that you have a **libname** specified. Unlike STATA, SAS wants you to tell it exactly where it can find the datasets it will work on.  
-Single vs. double quotes matter a lot.  
-Commas make a big difference, check to see if you need or don't need them when listing variables.  
-Shell commands: cd, rm, bunzip (things that your bash terminal will understand) can be evoked.  

###The power of SQL
Learn to run queries(aka chop up your dataset(s), combine, reshuffle your data) in SQL will save you tons of time and headaches in the long run. Any DATA step can pretty much be replaced with a more efficient and cleaner SQL step. The [handbook](http://support.sas.com/documentation/onlinedoc/91pdf/sasdoc_91/base_sqlproc_6992.pdf) provides lots of examples is a great go-to for any sql coding questions. The code for this project also has plenty examples.  
We also have a MySQL book floating around in the room. The syntax between proc sql and MySQL is a bit different, but the book is still useful.

###Most used Terminal/Bash commands
If all else fails, just close the window and start up a new session. :-)  
- kill -9 PID: bring the process to the highest priority (-9) and then kill it. PID is the process number which you can look up by using 'top' or 'ps' (only if you are still in the same bash session). You can kill any process that belongs to you  
- ls -lha: show all(-a) files in long(-l), human(-h)-readable format  
- exit: exit the program or session  
- rm -rf: remove a file without prompt(-f) and all child directories (-r)  
- top: list the top process of all users that are currently running on a machine. You can also kill a process while in top by hitting 'k' and then typing the PID.  
- ps: list all of the running process for the current session  
- tail -f: monitor the tail end of an output .log. I use this _all_ the time to check how regressions are running  
- cat: open and read a document in the screen  
- pico or vim: to edit documents on the fly  
- cd: change directories  
	cd ..: go up a level  
	cd: go to home dir  
	cd -: go to last dir  
- bzip, bunzip and gzip, gunzip: zip and unzip files using these two utilities  
- Most used shortcut keys:  
	ctrl+c: escape from current line/start a new line  
	ctrl+c, ctrl+x: exit out of current program  
	ctrl+u: delete everything ahead of the cursor on this line  
	up/down arrows: recall and cycle through previous commands  


##Code contents:
###SAS files:  
-analysis\_denom.sas: duplicate observation and collapse TM/MA weights to weight variable, add hicbic characteristics  
-analysis\_rcc\_byhicbic.sas: match cost reports to medpar stays, calculating artificial costs for MA stays and revenue.  
collapse to the hicbic, MA level for a regression-ready file  
-bene\_per\_zip.sas: construct a dataset for beneficiaries per zip code  
-clean\_hosp\_geocode.sas: clean version of hospital geocodes and zip codes  
-construct\_denom.sas: construct denominator from raw files  
-construct\_medpar.sas: construct medpar from raw files  
-construct\_regions.sas: create regions for hospital market structure regressions  
-HCC\_byhicbic.sas: recode ICD-9 (int'l classification of disease codes) from MedPAR to HCC (hazard characteristic code) dummies  
-hmo\_status\_byhicbic.sas: assign TM or MA status and weights to all benes based on hmo, buy-in, and death status from denom  
-import\_cty\_risk.sas: import the cty_risk benchmarks  
-npr\_ccr\_bymprovno.sas: construct net payment ratio(npr) and cost to charge ratio(ccr) from cost reports  
-tables.sas: [sample] code for creating various summary/frequency tables throughout the project  

###STATA files:  
-analysis.do: construct and run choice regressions  
-HHI\_mprovno\_sys.do: construct NEW HHI hospital market stucture variables and intermediaries that takes into account hospital systems  
-hosp\_mrkt\_strct.do: do file for constructing hospital market structure variables and intermediaries: HHI\_pat\_k\_star, CAP\_pat\_k\_star, hosp\_char\_h\_pat\_k\_star  
-IV.do: first-pass IVs of MA choice on hospital market structure variables  
-IV0.do: merging files together for IV regressions, running 0-stage regression to calculate MA_hat for IV construction  
-zip\_fips.do: create zip-to-fips xwalk  
-zip\_to\_region.do: create zip-to-region xwalk  

###proc contents:  
lists of variables in datasets

###xwalks:  
various crosswalks used for regressions