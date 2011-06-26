/***
zip_to_region.do

create zip-to-region xwalk

author: Angela Wang amwang@stanford.edu

input: iv_rcc.dta
		
output: iv_rcc.ster

***/

cd "[directory]"

insheet using "hrr_to_zip.txt", tab clear
drop hsanum hsacity hsastate hrrcity hrrstate
rename zipcode07 zip5
rename hrrnum hrr
sort hrr
save hrr_to_zip, replace

insheet using "hrr_to_region.txt", clear
drop hrrcity hrrstate
rename hrrnum hrr
sort hrr
save hrr_to_region, replace

merge hrr using hrr_to_zip
tab _merge
drop _merge
gen szip = string(zip5, "%05.0f")
drop zip5
rename szip zip5
save zip_to_region, replace

fdasave "zip_to_region", rename vallabfile(none) replace
