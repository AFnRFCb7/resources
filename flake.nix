# 1527183264148369
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
		                mkDerivation ,
		                visitor ,
		                writeShellApplication
                    } :
                        let
                            implementation =
                                {
                                    gc-roots-directory ,
                                    resources-directory
                                } :
                                    {
                                        clean =
                                            let
                                                application =
                                                    writeShellApplication
                                                        {
                                                            name = "clean" ;
                                                            runtimeInputs =
                                                                [
                                                                    (
                                                                        buildFHSUserEnv
                                                                            {
                                                                                extraBwrapArgs =
                                                                                    [
                                                                                    ] ;
                                                                                name = "clean" ;
                                                                                runScript = "clean" ;
                                                                                targetPkgs =
                                                                                    pkgs :
                                                                                        [
                                                                                            (
                                                                                                pkgs.writeShellApplication
                                                                                                    {
                                                                                                        name = "clean" ;
                                                                                                        runtimeInputs = [ ] ;
                                                                                                        text =
                                                                                                            ''
                                                                                                            '' ;
                                                                                                    }
                                                                                            )
                                                                                        ] ;
                                                                            }
                                                                    )
                                                                ] ;
                                                            text =
                                                                ''
                                                                    clean
                                                                '' ;
                                                        } ;
                                                in "${ application }/bin/clean" ;
                                        resource =
                                            {
                                                init ,
                                                release ,
                                                seed ,
                                                temporary
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
                                                                                            "--ro-bind" "$INPUT_FILE" "/input"
                                                                                            "--bind" gc-roots-directory gc-roots-directory
                                                                                            "--bind" resources-directory resources-directory
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
                                                                                                            runtimeInputs = [ ] ;
                                                                                                            text =
                                                                                                                let
                                                                                                                    resource =
                                                                                                                        mkDerivation
                                                                                                                            {
                                                                                                                                installPhase = ''resource "$out"'' ;
                                                                                                                                name = "resource" ;
                                                                                                                                nativeBuildInputs =
                                                                                                                                    [
                                                                                                                                    ] ;
                                                                                                                                src = ./. ;
                                                                                                                            } ;
                                                                                                                    in
                                                                                                                        ''
                                                                                                                            HASH="$( jq "[ .arguments , .inputs ]" /input | sha512sum | cut --characters 1-128 )" || exit 140
                                                                                                                            jq --null-input --arg OUTPUT "$HASH" --argjson STATUS "0" '{ "output" : $OUTPUT , "status" : $STATUS }' > /output
                                                                                                                        '' ;
                                                                                                        }
                                                                                                )
                                                                                            ] ;
                                                                                }
                                                                        )
                                                                    ] ;
                                                                text =
                                                                    let
                                                                        resource =
                                                                            mkDerivation
                                                                                {
                                                                                    installPhase = ''resource "$1"'' ;
                                                                                    name = "resource" ;
                                                                                    nativeBuildInputs = [ ] ;
                                                                                    src = ./. ;
                                                                                } ;
                                                                        in
                                                                            ''
                                                                                ARGUMENTS="$( printf '%s\n' "$@" | jq --raw-output . | jq --slurp . )"
                                                                                INPUT_FILE="$( mktemp --suffix ".json" )" || exit 199
                                                                                export INPUT_FILE
                                                                                if [[ -t 0 ]]
                                                                                then
                                                                                    ULTIMATE_PID="$( ps -o ppid= -p "$PPID" | tr -d '[:space:]' )" || exit 127
                                                                                    jq \
                                                                                        --null-input \
                                                                                        --argjson ARGUMENTS "$ARGUMENTS" \
                                                                                        --arg ORIGIN_PID "$ULTIMATE_PID" \
                                                                                        '{
                                                                                            "arguments" : $ARGUMENTS ,
                                                                                            "inputs" : { } ,
                                                                                            "origin-pid" : $ORIGIN_PID
                                                                                        }' > "$INPUT_FILE"
                                                                                else
                                                                                    PENULTIMATE_PID="$( ps -o ppid= -p "$PPID" | tr -d '[:space:]' )" || exit 146
                                                                                    ULTIMATE_PID="$( ps -o ppid= -p "$PENULTIMATE_PID" | tr -d '[:space:]' )" || exit 184
                                                                                    jq \
                                                                                        --null-input \
                                                                                        --argjson ARGUMENTS "$ARGUMENTS" \
                                                                                        --arg ORIGIN_PID "$ULTIMATE_PID" \
                                                                                        '{
                                                                                            "arguments" : $ARGUMENTS ,
                                                                                            "inputs" :
                                                                                                {
                                                                                                    "standard" : .
                                                                                                } ,
                                                                                            "origin-pid" : $ORIGIN_PID
                                                                                        }' > "$INPUT_FILE"
                                                                                fi
                                                                                OUTPUT_FILE="$( mktemp --suffix ".json" )" || exit 101
                                                                                export OUTPUT_FILE
                                                                                mkdir --parents ${ gc-roots-directory }
                                                                                mkdir --parents ${ resources-directory }
                                                                                resource
                                                                                OUTPUT="$( jq --raw-output ".output" "$OUTPUT_FILE" )" || exit 158
                                                                                STATUS="$( jq --raw-output ".status" "$OUTPUT_FILE" )" || exit 183
                                                                                echo "$OUTPUT"
                                                                                rm "$INPUT_FILE" "$OUTPUT_FILE"
                                                                                exit "$STATUS"
                                                                            '' ;
                                                            } ;
                                                    in "${ application }/bin/resource" ;
                                    } ;
                            in
                                {

                                    check =
                                        {
                                            actions ,
                                            gc-roots-directory ,
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
                                                                                                            read -t 1 -r OBSERVED_TYPE <&189 || exit 142
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
                                                                                                            [
                                                                                                                { text = "check-is-blocked 1 2745375537866399" ; }
                                                                                                                { text = "check-file-integrity 9287791874713682 cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e" ; }
                                                                                                            ]
                                                                                                            actions
                                                                                                            [
                                                                                                                { text = "check-is-blocked 1 5572814436683922" ; }
                                                                                                                { text = "check-file-integrity 8592338626733518 cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e" ; }
                                                                                                            ]
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
                                                                                                                                                    name = "check-file-integrity" ;
                                                                                                                                                    runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.jq pkgs.yq-go ] ;
                                                                                                                                                    text =
                                                                                                                                                        ''
                                                                                                                                                            UUID="$1"
                                                                                                                                                            EXPECTED_HASH="$2"
                                                                                                                                                            ROOT="$( mktemp --directory )" || exit 128
                                                                                                                                                            if [[ -d ${ resources-directory } ]]
                                                                                                                                                            then
                                                                                                                                                                cp --recursive ${ resources-directory } "$ROOT/resources"
                                                                                                                                                            fi
                                                                                                                                                            if [[ -d ${ gc-roots-directory } ]]
                                                                                                                                                            then
                                                                                                                                                                cp --recursive ${ gc-roots-directory } "$ROOT/roots"
                                                                                                                                                            fi
                                                                                                                                                            YAML_FILE="$( mktemp )" || exit 139
                                                                                                                                                            cd "$ROOT"
                                                                                                                                                            find . \( -path './resources/pids' -o -path './resources/temporary' \) -prune -o -type f -print | sort | while IFS= read -r FILE
                                                                                                                                                            do
                                                                                                                                                                jq --null-input --arg NAME "$FILE" --rawfile CONTENTS "$FILE" '{ "name": $NAME, "contents": $CONTENTS }' | yq eval --prettyPrint '[.]'
                                                                                                                                                            done >> "$YAML_FILE"
                                                                                                                                                            OBSERVED_HASH="$( sha512sum "$YAML_FILE" | cut --characters 1-128 )" || exit 176
                                                                                                                                                            if [[ "$EXPECTED_HASH" != "$OBSERVED_HASH" ]]
                                                                                                                                                            then
                                                                                                                                                                echo "UUID=$UUID" >&2
                                                                                                                                                                echo "YAML_FILE" >&2
                                                                                                                                                                yq eval --prettyPrint "." "$YAML_FILE" >&2
                                                                                                                                                                echo "OBSERVED_HASH=$OBSERVED_HASH" >&2
                                                                                                                                                                exit 101
                                                                                                                                                            fi
                                                                                                                                                        '' ;
                                                                                                                                                }
                                                                                                                                        )
                                                                                                                                        (
                                                                                                                                            pkgs.writeShellApplication
                                                                                                                                                {
                                                                                                                                                    name = "check-is-blocked" ;
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
                                                                                                                                                    name = "check-verify-executable" ;
                                                                                                                                                    runtimeInputs = [ ] ;
                                                                                                                                                    text =
                                                                                                                                                        ''
                                                                                                                                                            EXECUTABLE="$1"
                                                                                                                                                            UUID="$2"
                                                                                                                                                            if [[ ! -x "$EXECUTABLE" ]]
                                                                                                                                                            then
                                                                                                                                                                echo "UUID=$UUID" "EXECUTABLE=$EXECUTABLE" >&2
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
                                                                                                                                        if [[ "$OBSERVED_STATUS" == 124 ]]
                                                                                                                                        then
                                                                                                                                            echo 2739396698441122 >&2
                                                                                                                                            echo time timeout ${ builtins.toString action.timeout }s ${ builtins.toString action.text } >&2
                                                                                                                                            echo >&2
                                                                                                                                            cat ${ builtins.toString action.text } >&2
                                                                                                                                            echo 6953992692648714 >&2
                                                                                                                                            echo "RESOURCES=$RESOURCES" >&2
                                                                                                                                            echo 3876262385333986 >&2
                                                                                                                                            cat "$RESOURCES/[\"checks\",\"true\",\"true\"]/resource" >&2
                                                                                                                                            echo 7926178834245513 >&2
                                                                                                                                            echo >&2
                                                                                                                                            exit 183
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
                                                                                                                    ) &
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
