/***
zip_fips.do

create zip-to-fips xwalk

author: Angela Wang amwang@stanford.edu

input: 	DMA_ZIP_2007.csv
		FIPS Coes.csv
		
output: zip_ctyfips.dta
		state_ctyfips.dta
		zip_fips.dta
		zip_fips.txt

***/

cd "[directory]"
insheet using "DMA_ZIP_2007.csv", comma clear n
keep zip v7 cty
rename v7 st
rename cty ctyfips
drop if zip==""
drop if zip=="CODE"
destring ctyfips, replace
format ctyfips %03.0f
sort st
save zip_ctyfips, replace

insheet using "FIPS Codes.csv", comma clear n
drop countyname countyansi
rename state st
rename stateansi stfips
duplicates drop
format stfips %02.0f
sort st
save state_ctyfips, replace

merge st using zip_ctyfips
tab _merge
drop if _merge~=3
drop _merge
gen str5 fips = string(stfips,"%02.0f") + string(ctyfips,"%03.0f")
drop stfips ctyfips
order st fips zip
save zip_fips, replace

outsheet using zip_fips.txt, noquote replace
