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
		                flock ,
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
                                                    resource =
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
                                                                                                    "--ro-bind" "$INPUT_FILE" "/input"
                                                                                                    "--bind" "${ resources-directory }/canonical" "${ resources-directory }/canonical"
                                                                                                    "--bind" "${ resources-directory }/pids" "${ resources-directory }/pids"
                                                                                                    "--bind" "$OUTPUT_FILE" "/output"
                                                                                                ] ;
                                                                                            name = "resource" ;
                                                                                            runtimeScript = "resource" ;
                                                                                            targetPkgs =
                                                                                                pkgs :
                                                                                                    [
                                                                                                        (
                                                                                                            pkgs.writeShellApplication
                                                                                                                {
                                                                                                                    name = "resource" ;
                                                                                                                    runtimeInputs = [ pkgs.coreutils pkgs.jq sequential ] ;
                                                                                                                    text =
                                                                                                                        ''
                                                                                                                            HASH="$( jq "{ arguments , inputs }" /input | sha512sum | cut --characters 1-126 )" || exit 142
                                                                                                                            if [[ -L "${ resources-directory }/canonical/$HASH" ]]
                                                                                                                            then
                                                                                                                                LINK="$( readlink --canonicalize "${ resources-directory }/canonical/$HASH" )" || exit 108
                                                                                                                                ORIGINATOR_PID="$( jq --raw-output ".originator-pid" /input )" || exit 126
                                                                                                                                echo "$ORIGINATOR_PID" > "${ resources-directory }/pids/$INDEX/$ORIGINATOR_PID"
                                                                                                                                jq --null-input --arg OUTPUT "$LINK" '{ "output" : $OUTPUT , "status" : 0 }' > /output
                                                                                                                            else
                                                                                                                                jq --null-input '{ "output" : "WTF" , "status" : 0 }' > /output
#                                                                                                                                SEQUENCE="$( sequential )" || exit 165
#                                                                                                                                printf -v INDEX "%016s" "$SEQUENCE"
#                                                                                                                                LINK="${ resources-directory }/mounts/$INDEX"
#                                                                                                                                mkdir --parents "$LINK"
#                                                                                                                                ln --symbolic "$LINK" "${ resources-directory }/canonical/$HASH"
#                                                                                                                                echo "$ORIGINATOR_PID" > "${ resources-directory }/pid/$INDEX/$ORIGINATOR_PID"
#                                                                                                                                jq --null-input --arg OUTPUT "$LINK" '{ "output" : $OUTPUT , "status" : 0 }' > /output
                                                                                                                            fi
                                                                                                                        '' ;
                                                                                                                }
                                                                                                        )
                                                                                                    ] ;
                                                                                        }
                                                                                )
                                                                                coreutils
                                                                                flock
                                                                                jq
                                                                            ] ;
                                                                        text =
                                                                            ''
                                                                                mkdir --parents ${ resources-directory }/locks
                                                                                exec 155> ${ resources-directory }/locks/temporary
                                                                                flock -s 155
                                                                                mkdir --parents ${ resources-directory }/temporary
                                                                                INPUT_FILE="$( mktemp ${ resources-directory }/temporary/XXXXXXXX )" || exit 150
                                                                                export INPUT_FILE
                                                                                mkdir --parents ${ resources-directory }/canonical
                                                                                mkdir --parents ${ resources-directory }/mounts
                                                                                mkdir --parents ${ resources-directory }/pids
                                                                                OUTPUT_FILE="$( mktemp ${ resources-directory }/temporary/XXXXXXXX )" || exit 108
                                                                                export OUTPUT_FILE
                                                                                ARGUMENTS_JSON="$( printf '%s\n' "$@" | jq --raw-input . | jq --slurp . )" || exit 119
                                                                                if [[ -t 0 ]]
                                                                                then
                                                                                    ULTIMATE_PID="$( ps -o ppid= -p "$PPID" | tr -d '[:space:]' )" || exit 126
                                                                                    jq --null-input --argjson ARGUMENTS "$ARGUMENTS_JSON" --argjson ORIGINATOR_PID "$ULTIMATE_PID" '{ "arguments" : $ARGUMENTS , "inputs" : { } , "originator-pid" : $ORIGINATOR_PID }' > "$INPUT_FILE"
                                                                                else
                                                                                    PENULTIMATE_PID="$( ps -o ppid= -p "$PPID" | tr -d '[:space:]' )" || exit 133
                                                                                    PENULTIMATE_PID="$( ps -o ppid= -p "$PENULTIMATE_PID" | tr -d '[:space:]' )" || exit 141
                                                                                    jq --argjson ARGUMENTS "$ARGUMENTS_JSON" --argjson ORIGINATOR_PID "$ULTIMATE_PID" '{ "arguments" : $ARGUMENTS , "inputs" : { "standard" : "." } , "originator-pid" : $ORIGINATOR_PID }' > "$INPUT_FILE"
                                                                                fi
                                                                                echo 3761666247598712
                                                                                resource
                                                                                echo 8193592676166459
                                                                                OUTPUT="$( jq --raw-output ".output" "$OUTPUT" )" || exit 114
                                                                                echo "$OUTPUT"
                                                                                STATUS="$( jq --raw-output ".status" "$OUTPUT" )" || exit 142
                                                                                echo 9254446777424771
                                                                                exit "$STATUS"
                                                                            '' ;
                                                                    } ;
                                                            in "${ application }/bin/resource" ;
                                                    sequential =
                                                        writeShellApplication
                                                            {
                                                                name = "sequential" ;
                                                                runtimeInputs =
                                                                    [
                                                                        (
                                                                            buildFHSUserEnv
                                                                                {
                                                                                    extraBwrapArgs =
                                                                                        [
                                                                                            "--bind" "${ resources-directory }/sequential" "${ resources-directory }/sequential"
                                                                                            "--bind" "$OUTPUT_FILE" "/output"
                                                                                        ] ;
                                                                                    name = "sequential" ;
                                                                                    runScript =
                                                                                        ''
                                                                                            sequential
                                                                                        '' ;
                                                                                    targetPkgs =
                                                                                        pkgs :
                                                                                            [
                                                                                                (
                                                                                                    pkgs.writeShellApplication
                                                                                                        {
                                                                                                            name = "sequential" ;
                                                                                                            runtimeInputs = [ ] ;
                                                                                                            text =
                                                                                                                ''
                                                                                                                    CURRENT="$( cat ${ resources-directory }/sequential )" || exit 121
                                                                                                                    NEXT=$(( CURRENT + 1 ))
                                                                                                                    echo "$NEXT" > ${ resources-directory }/sequential
                                                                                                                    echo "$CURRENT" > /output
                                                                                                                '' ;
                                                                                                        }
                                                                                                )
                                                                                            ] ;
                                                                                }
                                                                        )
                                                                        coreutils
                                                                        flock
                                                                    ] ;
                                                                text =
                                                                    ''
                                                                        mkdir --parents ${ resources-directory }/locks
                                                                        exec 159> ${ resources-directory }/locks/temporary
                                                                        flock -s 159
                                                                        OUTPUT_FILE="$( mktemp ${ resources-directory }/temporary/XXXXXXXX )" || exit 179
                                                                        export OUTPUT_FILE
                                                                        exec 167> ${ resources-directory }/locks/sequential
                                                                        flock -x 167
                                                                        if [[ ! -f ${ resources-directory }/sequential ]]
                                                                        then
                                                                            echo 0 > ${ resources-directory }/sequential
                                                                        fi
                                                                        sequential "$INPUT_FILE" "$OUTPUT_FILE"
                                                                        SEQUENCE="$( cat "$OUTPUT_FILE" )" || exit 176
                                                                        echo "$SEQUENCE"
                                                                    '' ;
                                                            } ;
                                                    in resource ;
                                    } ;
                            in
                                {
                                    check = null ;
                                    implementation = implementation ;
                                } ;
            } ;
}
