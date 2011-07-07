all: test

#test
test:
	echo "hi"
	
#return all variables in all files
return_variables:
	cd /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata
	sasage3 contents.sas
	cat contents.lst
	
#c