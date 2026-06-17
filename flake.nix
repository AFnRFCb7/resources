# 28600
{
	inputs = { } ;
	outputs =
		{ self } :
		    {
		        lib =
                    {
                        pkgs
                    } :
                        let
                            implementation =
                                pkgs.writeShellApplication
                                    {
                                        name = "resource" ;
                                        runtimeInputs = [ ] ;
                                        text =
                                            ''
                                            '' ;
                                    } ;
                            in
                                {
                                    check = null ;
                                    implementation = implementation ;
                                } ;
            } ;
}
