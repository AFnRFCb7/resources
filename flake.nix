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
                                                                                            "--bind" "${ resources-directory }/canonical" "/canonical"
                                                                                            "--bind" "$INPUT_FILE" "/input"
                                                                                            "--bind" "${ resources-directory }/locks" "/locks"
                                                                                            "--bind" "${ resources-directory }/mounts" "/mounts"
                                                                                            "--bind" "$OUTPUT_FILE" "/output"
                                                                                            "--bind" "${ resources-directory }/sequential" "/sequential"
                                                                                        ] ;
                                                                                    name = "resource" ;
                                                                                    runScript =
                                                                                        ''
                                                                                            resource
                                                                                        '' ;
                                                                                    targetPkgs =
                                                                                        pkgs :
                                                                                            let
                                                                                                sequential =
                                                                                                    pkgs.writeShellApplication
                                                                                                        {
                                                                                                            name = "sequential" ;
                                                                                                            runtimeInputs = [ ] ;
                                                                                                            text =
                                                                                                                ''
                                                                                                                    exec 190> ${ resources-directory }/locks/sequential
                                                                                                                    flock -x 190
                                                                                                                    CURRENT="$( cat ${ resources-directory }/sequential )" || exit 193
                                                                                                                    NEXT=$(( ( CURRENT + 1 ) % 10000000000000000 ))
                                                                                                                    echo "$NEXT" >> ${ resources-directory }/sequential
                                                                                                                    echo "$CURRENT"
                                                                                                                '' ;
                                                                                                        } ;
                                                                                                in
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
                                                                                                                                    pkgs.coreutils
                                                                                                                                    pkgs.jq
                                                                                                                                    sequential
                                                                                                                                ] ;
                                                                                                                    text =
                                                                                                                        ''
                                                                                                                            cleanup( ) {
                                                                                                                                jq --null-input --arg INDEX "$INDEX" --argjson STATUS "$?" '{ "index" : $INDEX , "status" : $STATUS }' > /output
                                                                                                                            }
                                                                                                                            trap cleanup EXIT
                                                                                                                            RESOURCE_HASH="$( jq ".stable" /input | sha512sum | cut --characters 1-128 )" || exit 163
                                                                                                                            if [[ -L "${ resources-directory }/canonical/$RESOURCE_HASH" ]]
                                                                                                                            then
                                                                                                                                LINK="$( readlink --canonicalize "${ resources-directory }/canonical/$RESOURCE_HASH" )" || exit 148
                                                                                                                                INDEX="$( basename "$LINK" )" || exit 158
                                                                                                                            else
                                                                                                                                INDEX_UNFORMATTED="$( sequential )" || exit 168
                                                                                                                                printf -v INDEX "%016d" "$INDEX_UNFORMATTED"
                                                                                                                            fi
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
                                                                            INDEX="$( jq --raw-output ".index" "$OUTPUT_FILE" )" || exit 142
                                                                            STATUS="$( jq --raw-output ".status" "$OUTPUT_FILE" )" || exit 102
                                                                            rm "$INPUT_FILE" "$OUTPUT_FILE"
                                                                            echo "${ resources-directory }/mounts/$INDEX"
                                                                            exit "$STATUS"
                                                                        }
                                                                        trap cleanup EXIT
                                                                        ARGUMENTS_JSON="$( printf '%s\n' "$@" | jq --raw-input . | jq --slurp . )" || exit 179
                                                                        mkdir --parents ${ resources-directory }/canonical
                                                                        mkdir --parents ${ resources-directory }/mounts
                                                                        if [[ ! -f ${ resources-directory }/sequential ]]
                                                                        then
                                                                            echo 0 > ${ resources-directory }/sequential
                                                                        fi
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
