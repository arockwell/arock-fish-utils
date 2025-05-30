# Defined via `source`
function find-interactive-functions
	for func in (functions)
    		set -l f_details $(functions --details $func | rg -v "fish") 
    		if string match -q "stdin" $f_details 
	    		echo $func 
        	end
    	end
end
