BEGIN{
i = 1
FS="\""
}
{
if(NR==2)
	{
		i = 1
		x=""
		while(1) {
			if($i=="") break; 
			if($i~/shards/) {
				x=$i
				break
				}
			i++

		}
		if(x!="")gsub(x,"cts",$0)
		print $0
	}
else if($0~/CtsDeqpTestCases/)
	{
		i=1
		x=""
		while(1) {
			if($i=="") break; 
			if($i~/true/) {
				x=$i
				break
				}
			i++

		}
		if(x!="")gsub(x,"false",$0)
		print $0
	}
else print $0	
}

END{


}
