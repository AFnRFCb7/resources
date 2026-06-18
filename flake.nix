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
                                                                                                                                                        jq ".stable" | sha512sum | cut --characters 1-128
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
                                                                        mkdir --parents "${ resources-directory }/temporary"
                                                                        INPUT_FILE="$( mktemp "${ resources-directory }/temporary/XXXXXXXX" )" || exit 161
                                                                        export INPUT_FILE
                                                                        OUTPUT_FILE="$( mktemp "${ resources-directory }/temporary/XXXXXXXX" )" || exit 163
                                                                        export OUTPUT_FILE
                                                                        cleanup( ) {
                                                                            OUTPUT_VALUE="$( cat "$OUTPUT_FILE" )" || exit 164
                                                                            rm "$INPUT_FILE" "$OUTPUT_FILE"
                                                                            exit "$OUTPUT_VALUE"
                                                                        }
                                                                        trap cleanup EXIT
                                                                        ARGUMENTS_JSON="$( printf '%s\n' "$@" | jq --raw-input . | jq --slurp . )" || exit 179
                                                                        if [[ -t 0 ]]
                                                                        then
                                                                            ULTIMATE_PID="$( ps -o ppid= -p "$PPID" | tr -d '[:space:]' )" || failure 117
                                                                            jq --null-input --argjson ARGUMENTS "$ARGUMENTS_JSON" --argjson ULTIMATE_PID "$ULTIMATE_PID" '{ "stable" : { "arguments" : $ARGUMENTS } , "ultimate-pid" : $ULTIMATE_PID ,  }' > "$INPUT_FILE"
                                                                        else
                                                                            PENULTIMATE_PID="$( ps -o ppid= -p "$PPID" | tr -d '[:space:]' )" || failure 171
                                                                            ULTIMATE_PID="$( ps -o ppid= -p "$PENULTIMATE_PID" | tr -d '[:space:]' )" || failure 167
                                                                            jq --argjson ARGUMENTS "$ARGUMENTS_JSON" --argjson ULTIMATE_PID "$ULTIMATE_PID" '{ "stable" : { "arguments" : $ARGUMENTS , "standard-input" : "." } , "ultimate-pid" : $ULTIMATE_PID }' > "$INPUT_FILE"
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
