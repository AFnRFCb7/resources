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
                                                                                            runScript = "resource" ;
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
                                                                                                                            jq --null-input '{ "output" : "WTF" , "status" : 9 }' > /output
                                                                                                                            HASH="$( jq "{ arguments , inputs }" /input | sha512sum | cut --characters 1-126 )" || exit 142
                                                                                                                            ORIGINATOR_PID="$( jq --raw-output '.["originator-pid"]' /input )" || exit 126
                                                                                                                            if [[ -L "${ resources-directory }/canonical/$HASH" ]]
                                                                                                                            then
                                                                                                                                LINK="$( readlink --canonicalize "${ resources-directory }/canonical/$HASH" )" || exit 108
                                                                                                                                echo "$ORIGINATOR_PID" > "${ resources-directory }/pids/$INDEX/$ORIGINATOR_PID"
                                                                                                                                jq --null-input --arg OUTPUT "$LINK" '{ "output" : $OUTPUT , "status" : 0 }' > /output
                                                                                                                            else
                                                                                                                                SEQUENCE="$( sequential )" || exit 165
                                                                                                                                printf -v INDEX "%016d" "$SEQUENCE"
                                                                                                                                LINK="${ resources-directory }/mounts/$INDEX"
                                                                                                                                mkdir --parents "$LINK"
                                                                                                                                ln --symbolic "$LINK" "${ resources-directory }/canonical/$HASH"
                                                                                                                                mkdir --parents "${ resources-directory }/pid/$INDEX"
                                                                                                                                echo "$ORIGINATOR_PID" > "${ resources-directory }/pid/$INDEX/$ORIGINATOR_PID"
                                                                                                                                jq --null-input --arg OUTPUT "$LINK" '{ "output" : $OUTPUT , "status" : 0 }' > /output
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
                                                                                resource
                                                                                OUTPUT="$( jq --raw-output ".output" "$OUTPUT_FILE" )" || exit 114
                                                                                echo "$OUTPUT"
                                                                                STATUS="$( jq --raw-output ".status" "$OUTPUT_FILE" )" || exit 142
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
                                    check =
                                        {
                                            actions ,
                                            pkgs ,
                                            private ,
                                            resources-directory ,
                                            user
                                        } :
                                            pkgs.nixosTest
                                                {
                                                    name = "check" ;
                                                    nodes.machine = { ... } : { imports = private ; } ;
                                                    testScript =
                                                        let
                                                            test =
                                                                let
                                                                    application =
                                                                        pkgs.writeShellApplication
                                                                            {
                                                                                name = "test" ;
                                                                                runtimeInputs =
                                                                                    [
                                                                                        (
                                                                                            pkgs.writeShellApplication
                                                                                                {
                                                                                                    name = "is-subscribed" ;
                                                                                                    runtimeInputs = [ pkgs.coreutils pkgs.redis ] ;
                                                                                                    text =
                                                                                                        ''
                                                                                                            EXPECTED_TYPE="subscribe"
                                                                                                            EXPECTED_CHANNEL="$1"
                                                                                                            EXPECTED_PAYLOAD="$2"
                                                                                                            read -t 1 -r OBSERVED_TYPE <&189 || exit 124
                                                                                                            read -t 1 -r OBSERVED_CHANNEL <&189 || exit 154
                                                                                                            read -t 1 -r OBSERVED_PAYLOAD <&189 || exit 160
                                                                                                            if [[ "$EXPECTED_TYPE" != "$OBSERVED_TYPE" ]]
                                                                                                            then
                                                                                                                echo "OBSERVED_TYPE=$OBSERVED_TYPE" >&2
                                                                                                                exit 136
                                                                                                            fi
                                                                                                            if [[ "$EXPECTED_CHANNEL" != "$OBSERVED_CHANNEL" ]]
                                                                                                            then
                                                                                                                echo "OBSERVED_CHANNEL=$OBSERVED_CHANNEL" >&2
                                                                                                                exit 123
                                                                                                            fi
                                                                                                            if [[ "$EXPECTED_PAYLOAD" != "$OBSERVED_PAYLOAD" ]]
                                                                                                            then
                                                                                                                echo "OBSERVED_PAYLOAD=$OBSERVED_PAYLOAD" >&2
                                                                                                                exit 162
                                                                                                            fi
                                                                                                        '' ;
                                                                                                }
                                                                                        )
                                                                                        pkgs.coreutils
                                                                                        pkgs.redis
                                                                                    ] ;
                                                                                text =
                                                                                    let
                                                                                        _actions =
                                                                                            let
                                                                                                generator =
                                                                                                    index :
                                                                                                        let
                                                                                                            defaults =
                                                                                                                {
                                                                                                                    expected-standard-output = "" ;
                                                                                                                    expected-status = 0 ;
                                                                                                                    index = index ;
                                                                                                                    process = "main" ;
                                                                                                                    timeout = 60 ;
                                                                                                                } ;
                                                                                                            main =  builtins.elemAt list index ;
                                                                                                            in defaults // main ;
                                                                                                list =
                                                                                                    builtins.concatLists
                                                                                                        [
                                                                                                            [ { text = "is-blocked 1 2745375537866399" ; } ]
                                                                                                            # [ { text = "file-integrity-check 7486299242617446" ; } ]
                                                                                                            actions
                                                                                                            [ { text = "is-blocked 1 5572814436683922" ; } ]
                                                                                                        ] ;
                                                                                                in builtins.genList generator ( builtins.length list ) ;
                                                                                        commands =
                                                                                            let
                                                                                                generator =
                                                                                                    index :
                                                                                                        let
                                                                                                            action = builtins.elemAt _actions index ;
                                                                                                            command =
                                                                                                                let
                                                                                                                    application =
                                                                                                                        pkgs.writeShellApplication
                                                                                                                            {
                                                                                                                                name = "command" ;
                                                                                                                                runtimeInputs =
                                                                                                                                    [
                                                                                                                                        (
                                                                                                                                            pkgs.writeShellApplication
                                                                                                                                                {
                                                                                                                                                    name = "file-integrity-check" ;
                                                                                                                                                    runtimeInputs = [ pkgs.coreutils pkgs.findutils ] ;
                                                                                                                                                    text =
                                                                                                                                                        ''
                                                                                                                                                            EXPECTED_HASH="$1"
                                                                                                                                                            NAMES="$( find ${ resources-directory } -exec sha512 {} \; | sha512sum | cut --characters 1-128 )" || exit 191
                                                                                                                                                            CONTENT="$( find ${ resources-directory } -type f -exec cat {} \; | sha512sum | cut --characters 1-128 )" || exit 163
                                                                                                                                                            OBSERVED_HASH="$( echo "$NAMES" "$CONTENT" | sha512sum | cut --characters 1-128 )" || exit 171
                                                                                                                                                            if [[ "$EXPECTED_HASH" != "$OBSERVED_HASH" ]]
                                                                                                                                                            then
                                                                                                                                                                echo "OBSERVED_HASH=$OBSERVED_HASH" >&2
                                                                                                                                                                exit 174
                                                                                                                                                            fi
                                                                                                                                                        '' ;
                                                                                                                                                }
                                                                                                                                        )
                                                                                                                                        (
                                                                                                                                            pkgs.writeShellApplication
                                                                                                                                                {
                                                                                                                                                    name = "is-blocked" ;
                                                                                                                                                    runtimeInputs = [ pkgs.coreutils ] ;
                                                                                                                                                    text =
                                                                                                                                                        ''
                                                                                                                                                            TIMEOUT="$1"
                                                                                                                                                            UUID="$2"
                                                                                                                                                            if read -t "$TIMEOUT" -r VALUE <&189
                                                                                                                                                            then
                                                                                                                                                                echo "$UUID $VALUE" >&2
                                                                                                                                                                exit 160
                                                                                                                                                            fi
                                                                                                                                                        '' ;
                                                                                                                                                }
                                                                                                                                        )
                                                                                                                                        (
                                                                                                                                            pkgs.writeShellApplication
                                                                                                                                                {
                                                                                                                                                    name = "verify-executable" ;
                                                                                                                                                    runtimeInputs = [ ] ;
                                                                                                                                                    text =
                                                                                                                                                        ''
                                                                                                                                                            EXECUTABLE="$1"
                                                                                                                                                            if [[ ! -x "$EXECUTABLE" ]]
                                                                                                                                                            then
                                                                                                                                                                echo "$EXECUTABLE" >&2
                                                                                                                                                                exit 137
                                                                                                                                                            fi
                                                                                                                                                        '' ;
                                                                                                                                                }
                                                                                                                                        )
                                                                                                                                        (
                                                                                                                                            pkgs.writeShellApplication
                                                                                                                                                {
                                                                                                                                                    name = "is-subscribed" ;
                                                                                                                                                    runtimeInputs = [ pkgs.coreutils pkgs.redis ] ;
                                                                                                                                                    text =
                                                                                                                                                        ''
                                                                                                                                                        '' ;
                                                                                                                                                }
                                                                                                                                        )
                                                                                                                                    ] ;
                                                                                                                                text =
                                                                                                                                    ''
                                                                                                                                        seq 0 ${ builtins.toString ( index - 1 ) } | while read -r INDEX
                                                                                                                                        do
                                                                                                                                            while [[ -f "$COMMANDS/$INDEX" ]]
                                                                                                                                            do
                                                                                                                                                sleep 1
                                                                                                                                            done
                                                                                                                                        done
                                                                                                                                        STANDARD_ERROR_FILE="$( mktemp )" || exit 154
                                                                                                                                        STANDARD_OUTPUT_FILE="$( mktemp )" || exit 130
                                                                                                                                        date
                                                                                                                                        echo PROCESS
                                                                                                                                        cat ${ builtins.toFile "process" ( builtins.toString action.process ) }
                                                                                                                                        echo
                                                                                                                                        echo TIMEOUT
                                                                                                                                        cat ${ builtins.toFile "timeout" ( builtins.toString action.timeout ) }
                                                                                                                                        echo
                                                                                                                                        echo TEXT
                                                                                                                                        cat ${ builtins.toFile "text" ( builtins.toString action.text ) }
                                                                                                                                        echo
                                                                                                                                        if time timeout ${ builtins.toString action.timeout }s ${ builtins.toString action.text } > "$STANDARD_OUTPUT_FILE" 2> "$STANDARD_ERROR_FILE" <&189
                                                                                                                                        then
                                                                                                                                            OBSERVED_STATUS="$?"
                                                                                                                                        else
                                                                                                                                            OBSERVED_STATUS="$?"
                                                                                                                                        fi
                                                                                                                                        rm "$COMMANDS/${ builtins.toString index }"
                                                                                                                                        date
                                                                                                                                        OBSERVED_STANDARD_ERROR="$( cat "$STANDARD_ERROR_FILE" )" || exit 134
                                                                                                                                        OBSERVED_STANDARD_OUTPUT="$( cat "$STANDARD_OUTPUT_FILE" )" || exit 120
                                                                                                                                        if [[ -n "$OBSERVED_STANDARD_ERROR" ]]
                                                                                                                                        then
                                                                                                                                            echo "OBSERVED_STANDARD_ERROR=$OBSERVED_STANDARD_ERROR" >&2
                                                                                                                                            exit 102
                                                                                                                                        fi
                                                                                                                                        OBSERVED_STANDARD_OUTPUT="$( cat "$STANDARD_OUTPUT_FILE" )" || exit 120
                                                                                                                                        if [[ '${ builtins.toString action.expected-standard-output }' != "$OBSERVED_STANDARD_OUTPUT" ]]
                                                                                                                                        then
                                                                                                                                            echo "OBSERVED_STANDARD_OUTPUT=$OBSERVED_STANDARD_OUTPUT" >&2
                                                                                                                                            exit 178
                                                                                                                                        fi
                                                                                                                                        if [[ '${ builtins.toString action.expected-status }' != "$OBSERVED_STATUS" ]]
                                                                                                                                        then
                                                                                                                                            echo "OBSERVED_STATUS=$OBSERVED_STATUS" >&2
                                                                                                                                            exit 132
                                                                                                                                        fi
                                                                                                                                    '' ;
                                                                                                                            } ;
                                                                                                                    in "${ application }/bin/command" ;
                                                                                                            in ''ln --symbolic ${ command } "$COMMANDS/${ builtins.toString index }"'' ;
                                                                                                in builtins.genList generator ( builtins.length _actions ) ;
                                                                                        processes =
                                                                                            let
                                                                                                grouper = action : action.process ;
                                                                                                mapper =
                                                                                                    name : value :
                                                                                                        let
                                                                                                            mapper = { expected-standard-output , expected-status , index , process , text , timeout } : ''"$COMMANDS/${ builtins.toString index }"'' ;
                                                                                                            in
                                                                                                                ''
                                                                                                                    (
                                                                                                                        true ${ name }
                                                                                                                        ${ builtins.concatStringsSep "\n\t" ( builtins.map mapper value ) }
                                                                                                                    )
                                                                                                                '' ;
                                                                                                in builtins.attrValues ( builtins.mapAttrs mapper ( builtins.groupBy grouper _actions ) ) ;
                                                                                        in
                                                                                            ''
                                                                                                COMMANDS="$( mktemp --directory )" || exit 119
                                                                                                export COMMANDS
                                                                                                exec 189< <( redis-cli SUBSCRIBE valid-init valid-release invalid-init invalid-release )
                                                                                                is-subscribed valid-init 1 <&189
                                                                                                is-subscribed valid-release 2 <&189
                                                                                                is-subscribed invalid-init 3 <&189
                                                                                                is-subscribed invalid-release 4 <&189
                                                                                                ${ builtins.concatStringsSep "\n" commands }
                                                                                                ${ builtins.concatStringsSep "\n" processes }
                                                                                            '' ;
                                                                            } ;
                                                                        in "${ application }/bin/test" ;
                                                            in
                                                                ''
                                                                    machine.wait_for_unit("multi-user.target")
                                                                    machine.wait_for_unit("network-online.target")
                                                                    machine.succeed("runuser --login ${ user } -- ${ test }")
                                                                '' ;
                                                } ;
                                    implementation = implementation ;
                                } ;
            } ;
}
