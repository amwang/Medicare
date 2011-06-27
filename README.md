SAS files for cleaning 2008 MedPAR/denominator files and STATA files for analysis of code

SAS files:
-analysis_denom.sas: duplicate observation and collapse TM/MA weights to weight variable, add hicbic characteristics
-analysis\_rcc\_byhicbic.sas: match cost reports to medpar stays, calculating artifical costs for MA stays and revenue.
collapse to the hicbic, MA level for a regression-ready file
-bene\_per\_zip.sas: construct a dataset for beneficiaries per zip code
-clean\_hosp\_geocode.sas: clean version of hospital geocodes and zip codes
-construct_denom.sas: construct denominator from raw files
-construct_medpar.sas: construct medpar from raw files
-construct_regions.sas: create regions for hospital market structure regressions
-HCC_byhicbic.sas: recode ICD-9 (int'l classification of disease codes) from MedPAR to HCC (hazard characteristic code) dummies
-hmo\_status\_byhicbic.sas: assign TM or MA status and weights to all benes based on hmo, buy-in, and death status from denom
-import_cty_risk.sas: import the cty_risk benchmarks
-npr\_ccr\_bymprovno.sas: construct net payment ratio(npr) and cost to charge ratio(ccr) from cost reports
-tables.sas: [sample] code for creating various summary/frequency tables throughout the project

STATA files:
-analysis.do: construct and run choice regressions
-HHI\_mprovno\_sys.do: construct NEW HHI hospital market stucture variables and intermediaries that takes into account hospital systems
-hosp\_mrkt\_strct.do: do file for constructing hospital market structure variables and intermediaries: HHI\_pat\_k\_star, CAP\_pat\_k\_star, hosp\_char\_h\_pat\_k\_star
-IV.do: first-pass IVs of MA choice on hospital market structure variables
-IV0.do: merging files together for IV regressions, running 0-stage regression to calculate MA_hat for IV construction
-zip_fips.do: create zip-to-fips xwalk
-zip_to_region.do: create zip-to-region xwalk

proc contents:
lists of variables in datasets

xwalks:
various crosswalks used for regressions