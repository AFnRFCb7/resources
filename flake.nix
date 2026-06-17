# 28600
{
	inputs = { } ;
	outputs =
		{ self } :
		    {
		        lib =
		            { buildFHSUserEnv , visitor , writeShellApplication } :
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
                                                                                        "--bind" "$SIGNAL_FILE" "/signal"
                                                                                    ] ;
                                                                                name = "resource" ;
                                                                                runScript =
                                                                                    ''
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
                                                                                                                    let
                                                                                                                        init_ =
                                                                                                                            visitor
                                                                                                                                {
                                                                                                                                    lambda = path : value : value null ;
                                                                                                                                    null = path : value : null ;
                                                                                                                                }
                                                                                                                                init ;
                                                                                                                        in
                                                                                                                            pkgs.writeShellApplication
                                                                                                                                {
                                                                                                                                    name = "hash" ;
                                                                                                                                    runtimeInputs = [ pkgs.coreutils ] ;
                                                                                                                                    text =
                                                                                                                                        let
                                                                                                                                            in
                                                                                                                                                ''
                                                                                                                                                    echo "$HAS_STANDARD_INPUT" "$STANDARD_INPUT" | sha512sum | cut --characters 1-128
                                                                                                                                                '' ;
                                                                                                                                }
                                                                                                                )
                                                                                                            ] ;
                                                                                                        text =
                                                                                                            ''
                                                                                                                cleanup( ) {
                                                                                                                    echo "$?" > /signal
                                                                                                                }
                                                                                                                trap cleanup EXIT
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
                                                                    SIGNAL_FILE="$( mktemp )" || exit 163
                                                                    export SIGNAL_FILE
                                                                    cleanup( ) {
                                                                        SIGNAL_VALUE="$( cat "$SIGNAL_FILE" )" || exit 164
                                                                        rm "$SIGNAL_FILE"
                                                                        exit "$SIGNAL_VALUE"
                                                                    }
                                                                    trap cleanup EXIT
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
