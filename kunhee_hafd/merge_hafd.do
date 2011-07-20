"""
	 Merge the two data, medicare ID and revenue-charage ratio, for each hospital in CA
	 based on the fac_no variable.   
	  
	  Date: 07/11/2011
	  Author: Kunhee Kim  kunhee.kim@stanford.edu

	  input: hafd_ID_final.csv
	  		 oshpd-hafd2009-rev-charge-ratio-7-11-11.csv
	  output: merge_hafd.dta
"""


cd "/Users/kunheekim/Documents/kessler/medicare/HAFD data"

insheet using hafd_ID_final.csv, clear
gen med_id = string(mcar_pro_rev)
replace med_id = "0"+med_id if med_id !="."
drop mcar_pro_rev
sort fac_no
save hafd_id, replace

insheet using oshpd-hafd2009-rev-charge-ratio-7-11-11.csv, clear
sort fac_no
merge fac_no using hafd_id
save merge_hafd, replace
