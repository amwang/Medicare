sasdir =../sas
statadir=../statanew

sas = nohup sas -noterminal -work /space/wanga/ -memsize 0
stata = nohup statamp -b do

#type "make test"
test:
	echo "hi"
	
#build files

#BASE FILES	
#build denom file from 100-parts
build_denom:
	$(sas) construct_denom.sas
	
#build medpar file from 100-parts
build_medpar:
	$(sas) construct_medpar.sas
	
#clean hospital geocodes
build_hosp_geocode: hosp_geocodes.sas7bdat
	$(sas) clean_hosp_geocode.sas

#clean cost reports
build_hosp_geocode: hosp_chars_new.sas7bdat
	$(sas) npr_crr_bymprovno.sas

#clean benchmark payments
build_benchmark: cty_risk.txt
	$(sas) import_cty_risk.sas
	
#DERIVATIVE FILES
#build datasets for hospital choice models
construct_regions: build_denom build_medpar build_hosp_geocode hosp_char.sas7bdat 
	$(sas) construct_regions.sas

#build dataset to determine hmo status
construct_hmo_status: build_denom
	$(sas) hmo_status_byhicbic.sas

#build full denominator for analysis
analysis_denom: construct_hmo_status build benchmark
	$(sas) analysis_denom.sas
	
#build cost, charge, and price amounts
analysis_charge: construct_hmo_status build_medpar npr_crr_bymprovno
	$(sas) analysis_rcc_byhicbic.sas
	$(sas) analysis_rcc_bydischarge.sas

#build dataset for hcc indicators
analysis_hcc: build_medpar
	$(sas) analysis_HCC_byhicbic.sas

#run clogits to calculated predicted values
run_hospital_choice: construct_regions.sas
	$(stata) analysis.do
	
#construct pat-k-star variables
run_hosp_mrkt_strct: build_hospital_choice
	$(stata) hosp_mrkt_strct.do

#regressions
#construct IVs
run_zero_stage: denom.dta medpar_hcc_byhicbiuc.dta rcc_byhicbic.dta rcc_bydischarge.dta build_hosp_mrkt_strct benchmark_new.dta
	$(stata) IV0.do

#regressions
run_IV: run_zero_stage
	$(stata) IV.do