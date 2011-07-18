#Readme for Medicare project
*Research question at hand: what effect does hospital concentration have on the bargaining power of MA plans?
*Prior to 2008, hospital were not required to report utilization data of their MA patients to the Medicare.
*The current project deals only with 2008 data, but the code can be modified so that subsequent years can be added. The macro %year. is used in all code.  
*Change working directories to correspond to your own.

##Piece-by-Piece: building our dataset
All dataset processing for this project is completed in SAS. All regression analysis is completed in STATA. The philosophy behind this is that SAS can handle complex data sets while STATA is much more efficient for analysis. Stat-Transfer (available on all of our servers) can be used to convert files from .sas7bdat to .dta. Elsewise, xpt files can be exported from SAS and imported into STATA.

Levels: Analysis is conducted on both the discharge/stay level as well as the beneficiary-MA status level.

This readme is organized as follows:
	1) raw files used to build our dataset
		a) description and background
		b) processing to get to base files
		c) variables
	2) derivative files
		a) description and variables
		b) processing steps
	3) analysis
		a) hospital choice regressions
		b) construction of market structure variables
		b) main MA, hospital concentration regressions

###Medicare beneficiary data: Denominator and MedPAR (unique identifier: hicbic)
One should begin by understanding the contents of the Medicare utilization and enrollment data from CMS (Center for Medicare & Medicaid Services). The [RESDAC (Research Data Assistance Center) website](http://www.resdac.org/ddvh/Index.asp) provides detailed codebook (aka data documentation, data dictionaries, record layouts, and data layouts) info regarding all the datasets that are available to researchers. The pertinent files for this project are the "Medicare Denominator File" (commonly referred to as "denom"), which is a enrollment/summary file, and the "Medicare MedPAR file" (referred to as "MedPAR"), which is the utilization file. These files are **big**. New programmers should take a look at the RESDAC documentation to get acquainted with the data and determine what variables are available and where they are located.  

-The denominator file contains all enrollees (aka beneficiary, eligible, or member) in Medicare for the calendar year and their demographic information including: date of birth, date of death, zip code of residence, sex, ethnicity, monthly indicators for hmo enrollment, monthly indicators eligibility for medicare, etc. For 2008, this file contains 46+ million observations.  

-The MedPAR File contains inpatient hospital and skilled nursing facility (SNF) final action stay records. Each MedPAR record represents a stay in an inpatient hospital or SNF. An inpatient "stay" record summarizes all services rendered to a beneficiary from the time of admission to a facility through discharge. Each MedPAR record may represent one claim or multiple claims, depending on the length of a beneficiary's stay and the amount of inpatient services used throughout the stay. For 2008, this file contains 13+ million observations.

Chris mentions the "Inpatient SAFs" (ip) in his original email. We choose to use the MedPAR files instead of the ip. The unit of analysis for the Inpatient SAFs is a claim whereas for the MedPAR it is a stay (an inpatient stay may have several claims). With (some experienced) manipulation you can transform the ip file to MedPAR form.

Our data is stored on the NBER servers. Jean Roth (jroth@nber.org), one of the two data/server managers at the NBER, processes the yearly data that comes from the CMS every year. For 2008, the denom and MedPAR files are split into 100 files that need to be appended back together to form your personal working dataset. There are several sample sizes that you can use ranging from 1% (maybe smaller available as well) to the full 100% file. Working with a smaller file will allow you to cut down on processing time during a debugging phase. Ultimately though, all analysis will be run on the 100% files.  

The directory locations for these two sets of files are here:  
/disk/agedisk1/medicare/data.NOBACKUP/u/c/100pct/denom - denominator  
/disk/agedisk1/medicare/data.NOBACKUP/u/c/100pct/medpar - medpar  

There's a subdirectory for each year of data under each of these subdirectories.  The NBER has data through 2005 currently, and we can use data as far back as 1996.  In the locations above you'll find data for 2002-2008. 

All of these files have had their HICs encrypted, using a common encryption algorithm across files and two sets of years 2002-05 and 2006-08. In the 2002-05 files, you will see a variable called ehic in each file. In the 06-08 files, you will see a variable called bene\_id. *We rename the bene\_id variable to hicbic for consistency with other sets of data.*

See "construct\_denom.sas" and "construct\_medpar.sas" for code to build these files. Liberal comments are used in the denom file. These personal CMS working files are used heavily in the construction of other intermediary datasets further on in the project. After you have these constructed to your liking, make sure you have a backup stored somewhere as this is a processing intensive step.  

Below I detail the variables that we use from these two datasets.
####Patient characteristics
#####Demographics (variables: a6569, a7074, a7579, a8089, a9099, female, black)
Age, female, black, and derivative interacted indicators can be constructed directly from the denominator file.  
For our analysis, age is always taken to be their age at January 1, 2008. There may be some consideration to recode ages for the discharge-level regressions, so that age reflects the beneficiaries age at time of discharge.  
Black is the only reliable indicator that researchers use from the race variable, so we follow suit.  
Code to implement this appears at various points throughout the project when needed (eg. "analysis\_denom.sas" lines 41-62)

#####Patient location/geocode (variables: pzip, SSA)
5-digit zip-codes are also constructed directly from 9-digit bene_zip in the denominator file. SAS has a handy zipcode-to-geocode crosswalk(sashelp.zipcode.sas7bdat) which will geocode any valid zip-code to the centroid of the zip-code and they also have some [handy documentation](http://support.sas.com/resources/papers/proceedings10/219-2010.pdf) on this process. We considered using 9-digit or 3-digit zips, but ultimately we decided that analysis on those levels would be respectively too granular or too coarse. 

We also create a complete 5-digit SSA (Social Security Administration) state-county code by concatenating the SSA state-code and SSA county-codes from the denominator so that we can later merge in our IV: the Medicare Advantage benchmark payment rate.  
Note that the SSA state-county code is different from the more commonly used FIPS (federal info processing stds) state-county codes. There are plenty of SSA-FIPS crosswalks available if any merging needs to be done. This has been unnecessary for our analysis so far.

#####Diagnosis codes (DGNSCD1-DGNSCD10)
We eventually recode ICD-9 (int'l classification of disease codes/diagnosis codes) from MedPAR to HCC (hazard characteristic code) using the CMS-HCC model that was in place in 2008, the [2007 HCC model software](https://www.cms.gov/MedicareAdvtgSpecRateStats/06a_Risk_adjustment_prior.asp). Note that the CMS-HCC scheme we use is not exhaustive, so not all of our diagnosis codes will have a matching HCC. CMS uses a modified version of the model which has 70 indicators in 2007, while the true HCC model has 180 or so. The percentage of ICD-9 codes <5% that do not have a match are not worrisome.

The HCC risk model is used to adjust Medicare capitation payments to private health care plans for the health expenditure risk of their enrollees. We are using the HCC in a different capacity: as binary controls for disease conditions. Essentially, we are binning the 6000+ different ICD-9 codes into 70 disease categories for control purposes.  

"analysis\_medpar\_HCC\_byhicbic.sas" is used to recode the 10 diagnosis codes by stay in MedPAR to 70 HCC indicators by hicbic.  
The HCC indicators for each hicbic represents a summary of all HCCs that the beneficiary was diagnosed with over the calendar year. We map the 10 diagnosis codes to their respective HCCs for each stay and then reshape to obtain 70 indicator dummies for each stay.  We then take the maximum value of each HCC indicator by hicbic to obtain the hicbic level file.  

#####MA indicator and weight (variables: MA, weight)
HMO/GHO/MCO/MA what are they and how do they differ?  
An HMO (health maintenance organization) or a GHO (group health organization) is a type of MCO (managed care organization) that provide some form of health care coverage. The terms "HMO" and "GHO" are used interchangeably to indicate a managed care plan. Medicare Advantage (MA) is the managed care plan for Medicare.  

The MedPAR file contains a variable called the MedPAR GHO Paid Code, but we choose not to use this. [ResDAC provides a nice write up on GHO/HMO encoding in MedPAR files](http://www.resdac.org/tools/TBs/TN-009_MedicareManagedCareEnrolleesandUtilFiles_508.pdf). This code indicates whether or not a GHO has paid the provider for the claim (in ip)/stay (in medpar). However, an empirical analysis conducted by ResDAC showed that the indictor was correct only 95% of the time, so they recommend that researchers use the monthly HMO indicators from the denominator data. To assign an HMO status to each stay, we first construct monthly MA indicators for each hicbic. Then we match each MedPAR stay by discharge month to its respective HMO status. This process actually turns out to be a lot more complicated than it sounds. The easiest way to understand this is to look through the sas files.

######Constructing our MA (Medicare Advantage) indicator and weights "hmo\_status\_byhicbic.sas"  
We use two sets hmo1-hmo12 and buy1-buy12 monthly indicator variables and the death date (if applicable) to construct 12 monthly MA indicators for each hicbic. A beneficiary's enrollment may not be consistent across the year, so we use the rules listed below to determine a beneficiaries eligibility to remain in our dataset and construct some weights for those enrollees who have both MA and TM enrollment in 2008. The buy-in indicator is a 0/1 dummy for whether or not the bene was eligible for 

Establish monthly eligibility for Medicare:  
1) Eligibility ends the first full month after month of death. Benes received benefits up to the date of death which implies that they are eligible for Medicare during their month of death.  
2) Buyin indicator must be 1 and you must be living/died during that month.  

Keep valid beneficiaries with valid eligibility data:  
1) Benes must have either zero or only 1 switch between MA and TM plans  
2) Benes must have continuous eligibility for the entire year (or until death if applicable)  
3) Benes must not have "aged" into Medicare: eligibility switch from noneligible-->eligible  

TM and MA weights:  
Since some proportion of benes switch plans during the year, we construct weights so that we can utilize both the TM and MA part of their data.  
1) weightMA = months MA/12 and weightTM = months TM/12; weightTM and weightMA should sum to 1 since we only keep benes who have continuous eligibility for the entire year.  
2) If bene dies in 2008, weightMA = months MA/months eligible and weightTM = months TM/ months eligible; we do this so as to prevent down-weighting benes who die.  

#####Assigning our MA indicator  
The MA indicator is assigned based on the month of discharge of a stay. "analysis\_rcc\_byhicbic.sas" 

#####Charges, Costs, and Revenue (rcc)

######Charges (totchrg)
Definition: dollar amounts asked for a service by a health care provider. This is often different from the actual payments made to providers
Other names: gross revenue
Origin: This value is taken directly from each MedPAR stay record. No processing needed! Hurray!

######Cost (cost)
Definition: Cost to the hospital for services provided
Other names: expenditures
Origin: Derived using cost reports for all stays using hospital-level cost-to-charge ratio

######Revenue (revenue)
Definition: amount that the provider (hospital) actually makes. Theoretically the identity "revenue = cost-charges" should hold true.
Other names: payment, medpar_payment, net revenue
Origin: For TM folks, 

cost=ccr*totchrg;
if MA=1 then revenue=totchrg*npr;
else revenue=medpar_payment;

###Medicare hospitals (unique identifier: mprovno)
####Hospital Location/geocode (variable: hzip)
The raw file (/disk/homes2b/nber/cafendul/hosp\_prices/Hospital\_Geocoding\_Result2.dbf) for this part of the project was obtained from Chris. We sent a file with hospitals and hospital addresses to Scott, our map library contact, who helped geocode them into latitude and longitude coordinates. This file is imported into SAS and saved as "hosp\_geocodes.sas7bdat". The cleaned version, "hosp\_geocode\_clean.sas7bdat" has a total of 3560 unique hospitals.
"clean\_hosp\_geocode.sas" is used to clean up the raw data and process it to an analysis ready file.  
Hospital data was checked against their listing on the [Medicare Data website](http://data.medicare.gov/dataset/Hospital-General-Information/v287-28n3).  
Some hospitals have miscoded zip codes. These zipcodes are corrected using the data step.
Exact duplicates are dropped, but many hospitals still contained multiple entries with conflicting geocodes.  
Hospital duplicates come in several flavors:  
- Miscoded zip codes: one entry has the wrong address/zipcode, the duplicate entry which was coded using the wrong zip was dropped  
- Conflicting address: 
	1) Hospitals that have multiple campuses but only one hospital code. We take the main campus to be the location for our geocode.  
	2) Hospitals with two addresses, we take the average of these geocodes to be our final geocode. Usually these geocodes are similar and have a difference of less than 0.01deg.

To further validate our hospital data we compare it to the geocodes provided by the AHA (American Hospital Association) hospital files. We don't use these files straight up because they only cover a portion of the hospitals we need geocodes for. That said, only 147 hospitals appear in the cost reports but not the AHA. If lat and long differ by more than 0.5deg, the lat and long were updated to what was reported in the AHA.  
Note about AHA files: You'll need to sign a consent form through NBER/Jean to work with these files.  

####Hospital characteristics (variables: hchar1-hchar7, beds)
Chris provides the hospital characteristic file. (/disk/homes2b/nber/cafendul/hosp_prices/hosp_chars.sas7bdat.gz)
The hospital characteristics include size (small, med, large) based on the number of beds, ownership (non-profit, for-profit, and teaching) and whether or not it is a teaching hospital. This dataset can be used as is.  

####CMS Cost reports
Chris provides us with CMS cost reports (/disk/homes2b/nber/cafendul/hosp_prices/hosp_chars_new.sas7bdat.gz). 
We use this data to calculate a net payment ratio (npr) and cost-to-charge ration(ccr) for each cost report. "npr_ccr_bymprovno.sas" Using these ratios, we can then impute the cost for each stay and the revenue for MA stays.

We can calculate net revenue to gross revenue ratio using data directly from the hospital cost reports.
net payment ratio  = net patient revenue/total charges
net payment ratio = [net patient revenue - Medicare net patient revenue]/[total charges - Medicare charges]

Note that these represent net and gross revenue (total charges) for all patients, for all different parts of the hospital complex.  To the extent that we can isolate those net revenues and gross revenues that do not include Medicare payments of various kinds, we can improve upon it. One thing we can definitely do is to remove Medicare inpatient net revenue from the numerator, and Medicare inpatient total charges from the denominator. Unfortunately, we don't think we can go further than this. While we can identify other pots of net revenue that are paid by Medicare (i.e., SNF, HHA), we can't find the corresponding charge figures for each of those sources.

http://www.resdac.org/tools/TBs/TN-008_UsingCCRsinResearch_508.pdf
http://www.resdac.org/Tools/TBs/TN-004_CalculatingHospitalDRG_508.pdf

##Working in the Unix environment
###If your SAS program doesn't run:
Learning to love SAS will take time. Breath.  
-Semicolon delimiter. Is it at the end of every proc/data step?  
-Make sure that you have a **libname** specified. Unlike STATA, SAS wants you to tell it exactly where it can find the datasets it will work on.  
-Single vs. double quotes matter. Check to see if you're using the right ones.  
-Commas make a big difference, check to see if you need or don't need them  
-Shell commands: cd, rm, bunzip (things that your bash terminal will understand) can be evoked.  
-Are the macro variables referenced correctly: &macro_name.?

###The power of SQL
Learn to run queries(aka chop up your dataset(s), combine, reshuffle your data) in SQL will save you tons of time and headaches in the long run. Any DATA step can pretty much be replaced with a more efficient and cleaner SQL step. The [handbook](http://support.sas.com/documentation/onlinedoc/91pdf/sasdoc_91/base_sqlproc_6992.pdf) provides lots of examples is a great go-to for any sql coding questions. The code for this project also has plenty examples.  
We also have a MySQL book floating around in the room. The syntax between proc sql and MySQL is a bit different, but the book is still very useful.

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
	>+cd ..: go up a level  
	>+cd: go to home dir  
	>+cd -: go to last dir  
- bzip, bunzip and gzip, gunzip: zip and unzip files using these two utilities  
- Most used shortcut keys:  
	>+ctrl+c: escape from current line/start a new line  
	>+ctrl+c, ctrl+x: exit out of current program  
	>+ctrl+u: delete everything ahead of the cursor on this line  
	>+up/down arrows: recall and cycle through previous commands  


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
-analysis\_medpar\_HCC\_byhicbic.sas: recode ICD-9 (int'l classification of disease codes) from MedPAR to HCC (hazard characteristic code) dummies  
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