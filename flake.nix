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
                                        {
                                            init
                                        } :
                                            let
                                                application =
                                                    pkgs.writeShellApplication
                                                        {
                                                            name = "resource" ;
                                                            runtimeInputs = [ pkgs.coreutils ] ;
                                                            text =
                                                                let
                                                                    init_ =
                                                                        visitor
                                                                            {
                                                                                lambda =
                                                                                    path : value :
                                                                                        let
                                                                                            identity =
                                                                                                {
                                                                                                    entrypoint
                                                                                                } :
                                                                                                    {
                                                                                                        entrypoint =
                                                                                                            visitor
                                                                                                                {
                                                                                                                    lambda =
                                                                                                                        path : value :
                                                                                                                            value { } ;
                                                                                                                }
                                                                                                                entrypoint ;
                                                                                                    } ;
                                                                                            in identity init ;
                                                                                null = path : value : null ;
                                                                            }
                                                                            init ;
                                                                    in
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
