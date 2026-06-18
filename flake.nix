# 9499764299738338
{
	inputs = { } ;
	outputs =
		{ self } :
		    {
		        lib =
		            {
		                buildFHSUserEnv ,
		                coreutils ,
		                jq ,
		                visitor ,
		                writeShellApplication
                    } :
                        let
                            implementation =
                                {
                                    resources-directory
                                } :
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
                                                                                            "--bind" "$INPUT_FILE" "/input"
                                                                                            "--bind" "$OUTPUT_FILE" "/output"
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
                                                                                                                let
                                                                                                                    init_ =
                                                                                                                        visitor
                                                                                                                            {
                                                                                                                                lambda = path : value : value null ;
                                                                                                                                null = path : value : null ;
                                                                                                                            }
                                                                                                                            init ;
                                                                                                                    in
                                                                                                                        [
                                                                                                                            (
                                                                                                                                pkgs.writeShellApplication
                                                                                                                                    {
                                                                                                                                        name = "resource-hash" ;
                                                                                                                                        runtimeInputs = [ pkgs.coreutils ] ;
                                                                                                                                        text =
                                                                                                                                            let
                                                                                                                                                in
                                                                                                                                                    ''
                                                                                                                                                        hash512sum /input | cut --characters 1-128
                                                                                                                                                    '' ;
                                                                                                                                    }
                                                                                                                            )
                                                                                                                        ] ;
                                                                                                            text =
                                                                                                                ''
                                                                                                                    cleanup( ) {
                                                                                                                        echo "$?" > /output
                                                                                                                    }
                                                                                                                    trap cleanup EXIT
                                                                                                                    RESOURCE_HASH="$( resource-hash )" || exit 163
                                                                                                                    echo "$RESOURCE_HASH"
                                                                                                                '' ;
                                                                                                        }
                                                                                                )
                                                                                            ] ;
                                                                                }
                                                                        )
                                                                        coreutils
                                                                        jq
                                                                    ] ;
                                                                text =
                                                                    ''
                                                                        mkdir --parents ${ resources-directory }/locks
                                                                        exec 178> ${ resources-directory }/locks/resource
                                                                        flock -x 178
                                                                        mkdir --parents "${ resources-directory }/temporary
                                                                        INPUT_FILE="$( mktemp "${ resources-directory }/temporary/XXXXXXXX" )" || exit 161
                                                                        export INPUT_FILE
                                                                        ARGUMENTS_JSON="$( printf '%s\n' "$@" | jq --raw-input . | jq --slurp . )" || exit 179
                                                                        OUTPUT_FILE="$( mktemp "${ resources-directory }/temporary/XXXXXXXX" )" || exit 163
                                                                        cleanup( ) {
                                                                            OUTPUT_VALUE="$( cat "$OUTPUT_FILE" )" || exit 164
                                                                            rm "$INPUT_FILE" "$OUTPUT_FILE"
                                                                            exit "$OUTPUT_VALUE"
                                                                        }
                                                                        trap cleanup EXIT
                                                                        if [[ -t 0 ]]
                                                                        then
                                                                            jq --null-input --argjson ARGUMENTS "$ARGUMENTS_JSON" '{ "arguments" : $ARGUMENTS }' > "$INPUT_FILE"
                                                                        else
                                                                            jq --argjson ARGUMENTS "$ARGUMENTS_JSON" '{ "arguments" : $ARGUMENTS , "standard-input" : . }' > "$INPUT_FILE"
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
