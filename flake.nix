# 28600
{
	inputs = { } ;
	outputs =
		{ self } :
		    {
		        lib =
		            { pkgs  } :
                        let
                            implementation =
                                {
                                    user =
                                        let
                                            application =
                                                pkgs.writeShellApplication
                                                    {
                                                        name = "resource" ;
                                                        runtimeInputs = [ ] ;
                                                        text =
                                                            ''
                                                            '' ;
                                                    } ;
                                            in "${ application }/bin/resource" ;
                                } ;
                            in
                                {
                                    check = null ;
                                    implementation = implementation ;
                                } ;
            } ;
}
