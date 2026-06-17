# 28600
{
	inputs = { } ;
	outputs =
		{ self } :
		    {
		        lib =
		            { visitor , writeShellApplication } :
                        let
                            implementation =
                                {
                                    user =
                                        {
                                            init
                                        } :
                                            let
                                                application =
                                                    writeShellApplication
                                                        {
                                                            name = "resource" ;
                                                            runtimeInputs =
                                                                [
                                                                    (
                                                                        buildFHSUserEnv
                                                                            {
                                                                                extraBwrapArgs =
                                                                                    [
                                                                                    ] ;
                                                                                name = "resource" ;
                                                                                runScript =
                                                                                    ''
                                                                                        cleanup ( ) {
                                                                                            echo "$?" > /signal
                                                                                        }
                                                                                        trap cleanup EXIT
                                                                                        resource
                                                                                    '' ;
                                                                                targetPkgs =
                                                                                    pkgs :
                                                                                        [
                                                                                            (
                                                                                                pkgs.writeShellApplication
                                                                                                    {
                                                                                                        name = "resource" ;
                                                                                                        runtimeInputs =
                                                                                                            [
                                                                                                                (
                                                                                                                    pkgs.writeShellApplication
                                                                                                                        {
                                                                                                                            name = "hash" ;
                                                                                                                            runtimeInputs = [ pkgs.coreutils ] ;
                                                                                                                            text =
                                                                                                                                let
                                                                                                                                    pre-hash = null ;
                                                                                                                                    in
                                                                                                                                        ''
                                                                                                                                            echo ${ pre-hash } "$HAS_STANDARD_INPUT" "$STANDARD_INPUT" | sha512sum | cut --characters 1-128
                                                                                                                                        '' ;
                                                                                                                        }
                                                                                                                )
                                                                                                            ] ;
                                                                                                        text =
                                                                                                            ''
                                                                                                                HASH="$( hash )"
                                                                                                                echo "$HASH"
                                                                                                            '' ;
                                                                                                    }
                                                                                            )
                                                                                        ] ;
                                                                            }
                                                                    )
                                                                ] ;
                                                            text =
                                                                ''
                                                                    if [[ -t 0 ]]
                                                                    then
                                                                        export HAS_STANDARD_INPUT=false
                                                                        export STANDARD_INPUT=
                                                                    else
                                                                        export HAS_STANDARD_INPUT=true
                                                                        STANDARD_INPUT="$( cat )" || exit 131
                                                                        export STANDARD_INPUT
                                                                    fi
                                                                    resource
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
