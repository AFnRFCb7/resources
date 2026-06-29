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
                                                                        coreutils
                                                                        jq
                                                                        (
                                                                            buildFHSUserEnv
                                                                                {
                                                                                    extraBwrapArgs =
                                                                                        [
                                                                                            "--bind" "${ gc-roots-directory }" "${ gc-roots-directory }"
                                                                                            "--ro-bind" "$INPUT_FILE" "/input"
                                                                                            "--bind" "$OUTPUT_FILE" "/output"
                                                                                            "--bind" "${ resources-directory }" "${ resources-directory }"
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
                                                                                                            runtimeInputs = [ pkgs.coreutils pkgs.flock pkgs.jq ] ;
                                                                                                            text =
                                                                                                                ''
                                                                                                                    HASH="$( jq --null-input ".payload" /input | sha512sum | cut --characters 1-128 )" || exit 191
                                                                                                                    if [[ -L ${ resources-directory }/canonical ]]
                                                                                                                    then
                                                                                                                        LINK="$( readlink --canonical "${ resources-directory }/canonical/$HASH" )" || exit 197
                                                                                                                        INDEX="$( basename "$LINK" )" || exit 176
                                                                                                                        export INDEX
                                                                                                                        mkdir --parents ${ resources-directory }/flags
                                                                                                                        touch "${ resources-directory }/flags/$INDEX"
                                                                                                                        jq --null-input --arg INDEX "$INDEX" '{ "index" : $INDEX }' > /output
                                                                                                                        ORIGINATOR_PID="$( jq --null-input --raw-output ".originator-pid" /input )" || exit 192
                                                                                                                        echo "$ORIGINATOR_PID" > "${ resources-directory }/pids/$INDEX/$ORIGINATOR_PID"
                                                                                                                    else
                                                                                                                        mkdir --parents "${ resources-directory }/locks"
                                                                                                                        exec 109> "${ resources-directory }/locks/sequential"
                                                                                                                        flock -x 109
                                                                                                                        CURRENT="$( cat ${ resources-directory }/sequence )" || exit 117
                                                                                                                        NEXT=$(( CURRENT + 1 ))
                                                                                                                        echo "$NEXT" >> ${ resources-directory }/sequence
                                                                                                                        INDEX="$( printf "%016d" "$CURRENT" )" || exit 157
                                                                                                                        export INDEX
                                                                                                                        mkdir --parents ${ resources-directory }/flags
                                                                                                                        touch "${ resources-directory }/flags/$INDEX"
                                                                                                                        mkdir --parents "${ resources-directory }/scripts/$INDEX/init/action"
                                                                                                                        INIT_ACTION="$( jq --raw-output ".payload.scripts.init.action.text" /input )" || exit 124
                                                                                                                        ln --symbolic "$INIT_ACTION" "${ resources-directory }/scripts/$INDEX/init/action/text"

                                                                                                                        mkdir --parents "${ resources-directory }/mounts/$INDEX"
                                                                                                                        mkdir --parents ${ resources-directory }/canonical
                                                                                                                        ln --symbolic "${ resources-directory }/mounts/$INDEX" "${ resources-directory }/canonical/$HASH"
                                                                                                                        jq --null-input --arg INDEX "$INDEX" '{ "index" : $INDEX }' > /output
                                                                                                                    fi
                                                                                                                '' ;
                                                                                                        }
                                                                                                )
                                                                                            ] ;
                                                                                }
                                                                        )
                                                                    ] ;
                                                                text =
                                                                    ''
                                                                        mkdir --parents ${ gc-roots-directory }
                                                                        mkdir --parents ${ resources-directory }/locks
                                                                        exec 191> ${ resources-directory }/locks/temporary
                                                                        flock -s 191
                                                                        if [[ ! -f ${ resources-directory }/sequence ]]
                                                                        then
                                                                            echo 0 > ${ resources-directory }/sequence
                                                                        fi
                                                                        ARGUMENTS="$( printf '%s\n' "$@" | jq --raw-output . | jq --slurp . )" || exit 110
                                                                        mkdir --parents ${ resources-directory }/temporary
                                                                        INPUT_FILE="$( mktemp --suffix ".json" ${ resources-directory }/temporary/XXXXXXXX )" || exit 187
                                                                        export INPUT_FILE
                                                                        OUTPUT_FILE="$( mktemp --suffix ".json" ${ resources-directory }/temporary/XXXXXXXX )" || exit 164
                                                                        export OUTPUT_FILE
                                                                        if [[ -t 0 ]]
                                                                        then
                                                                            ULTIMATE_PID="$( ps -o ppid= -p "$PPID" | tr -d '[:space:]' )" || exit 185
                                                                            jq \
                                                                                --null-input \
                                                                                --argjson ARGUMENTS "$ARGUMENTS" \
                                                                                --argjson ORIGINATOR_PID "$ULTIMATE_PID" \
                                                                                --argjson PARAMETERS '${ builtins.toJSON runtime.parameters }' \
                                                                                '{
                                                                                    "originator-pid" : $ORIGINATOR_PID ,
                                                                                    "payload" :
                                                                                        {
                                                                                            "arguments" : $ARGUMENTS ,
                                                                                            "parameters" : $PARAMETERS ,
                                                                                            "inputs" : { }
                                                                                        }
                                                                                }' > "$INPUT_FILE"
                                                                        else
                                                                            PENULTIMATE_PID="$( ps -o ppid= -p "$PPID" | tr -d '[:space:]' )" || exit 172
                                                                            ULTIMATE_PID="$( ps -o ppid= -p "$PENULTIMATE_PID" | tr -d '[:space:]' )" || exit 144
                                                                            jq \
                                                                                --null-input \
                                                                                --argjson ARGUMENTS "$ARGUMENTS" \
                                                                                --argjson PARAMETERS '${ builtins.toJSON runtime.parameters }' \
                                                                                --argjson ORIGINATOR_PID "$ULTIMATE_PID" \
                                                                                '{
                                                                                    "originator-pid" : $ORIGINATOR_PID ,
                                                                                    "payload" :
                                                                                        {
                                                                                            "arguments" : $ARGUMENTS ,
                                                                                            "parameters" : $PARAMETERS ,
                                                                                            "inputs" : { "standard" : . }
                                                                                        }
                                                                                }' > "$INPUT_FILE"
                                                                        fi
                                                                        resource
                                                                        INDEX="$( jq --raw-output ".index" "$OUTPUT_FILE" )" || exit 146
                                                                        echo "${ resources-directory }/mounts/$INDEX"
                                                                        rm "$INPUT_FILE" "$OUTPUT_FILE"
                                                                    '' ;
                                                            } ;
                                                        runtime =
                                                            let
                                                                parameters =
                                                                    {
                                                                        init =
                                                                            {
                                                                                text =
                                                                                    visitor
                                                                                        {
                                                                                            lambda =
                                                                                                path : value :
                                                                                                    let
                                                                                                        init = value null ;
                                                                                                        in
                                                                                                            {
                                                                                                                action =
                                                                                                                    {
                                                                                                                        text =
                                                                                                                            visitor
                                                                                                                                {
                                                                                                                                    lambda =
                                                                                                                                        path : value :
                                                                                                                                            let
                                                                                                                                                action = value null ;
                                                                                                                                                in
                                                                                                                                                    visitor
                                                                                                                                                        {
                                                                                                                                                            lambda = path : value : builtins.toFile "text" ( value { seed = seed ; } ) ;
                                                                                                                                                        }
                                                                                                                                                        action.text ;
                                                                                                                                }
                                                                                                                                init.action ;
                                                                                                                    } ;
                                                                                                            } ;
                                                                                        }
                                                                                        init ;
                                                                            } ;
                                                                        release =
                                                                            visitor
                                                                                {
                                                                                    lambda =
                                                                                        path : value :
                                                                                            let
                                                                                                release = value null ;
                                                                                                in
                                                                                                    {
                                                                                                        action =
                                                                                                            {
                                                                                                                text =
                                                                                                                    visitor
                                                                                                                        {
                                                                                                                            lambda =
                                                                                                                                path : value :
                                                                                                                                    let
                                                                                                                                        action = value null ;
                                                                                                                                        in
                                                                                                                                            visitor
                                                                                                                                                {
                                                                                                                                                    lambda = path : value : builtins.toFile "text" ( value { seed = seed ; } ) ;
                                                                                                                                                }
                                                                                                                                                action.text ;
                                                                                                                        }
                                                                                                                        release.action ;
                                                                                                            } ;
                                                                                                    } ;
                                                                                }
                                                                                release ;
                                                                        temporary = temporary ;
                                                                    } ;
                                                                in
                                                                    {
                                                                        parameters = parameters ;
                                                                        user-environments =
                                                                            {
                                                                                init =
                                                                                    {
                                                                                        action = null ;
                                                                                        recovery = { } ;
                                                                                    } ;
                                                                                release =
                                                                                    {
                                                                                        action =
                                                                                            writeShellApplication
                                                                                                {
                                                                                                    name = "action" ;
                                                                                                    runtimeInputs =
                                                                                                        [
                                                                                                            coreutils
                                                                                                            flock
                                                                                                            (
                                                                                                                buildFHSUserEnv
                                                                                                                    {
                                                                                                                        extraBwrapArgs =
                                                                                                                            [
                                                                                                                                "--mount" "${ gc-roots-directory }" "${ gc-roots-directory }"
                                                                                                                                "--mount" "${ resources-directory }" "${ resources-directory }"
                                                                                                                                "--mount" "$OUTPUT_FILE" "/output"
                                                                                                                            ] ;
                                                                                                                        name = "garbage-collection" ;
                                                                                                                        runScript = "garbage-collection" ;
                                                                                                                        targetPkgs =
                                                                                                                            pkgs :
                                                                                                                                [
                                                                                                                                    (
                                                                                                                                        pkgs.writeShellApplication
                                                                                                                                            {
                                                                                                                                                name = "garbage-collection" ;
                                                                                                                                                runtimeInputs = [ pkgs.coreutils pkgs.flock ] ;
                                                                                                                                                text =
                                                                                                                                                    ''
                                                                                                                                                        GC_ROOT_COLLECT="$( find ${ gc-roots-directory } -mindepth 1 -maxdepth 1 -name "$INDEX" )" || exit 140
                                                                                                                                                        RESOURCES_COLLECT="$( find ${ resources-directory } -mindepth 1 -maxdepth 1 -name "INDEX" )" || exit 157
                                                                                                                                                        mkdir --parents ${ resources-directory }/temporary
                                                                                                                                                        TARGET="$( mktemp --sufix .xz.tar ${ resources-directory }/temporary/XXXXXXXX )" || exit 178
                                                                                                                                                        SOURCE="$GC_ROOT_COLLECT $RESOURCES_COLLECT"
                                                                                                                                                        tar --create --xz --file "$TARGET" "$SOURCE"
                                                                                                                                                        rm --recursive --force "$SOURCE"
                                                                                                                                                        jq --null-input --arg TARGET "$TARGET" '$TARGET' > /output
                                                                                                                                                    '' ;
                                                                                                                                            }
                                                                                                                                    )
                                                                                                                                ] ;
                                                                                                                    }
                                                                                                            )
                                                                                                            (
                                                                                                                buildFHSUserEnv
                                                                                                                    {
                                                                                                                        extraBwrapArgs =
                                                                                                                            [
                                                                                                                                "--ro-mount" "$INPUT_FILE" "/input"
                                                                                                                                "--ro-mount" "${ gc-roots-directory }" "${ gc-roots-directory }"
                                                                                                                                "--ro-mount" "${ resources-directory }" "${ resources-directory }"
                                                                                                                                "--mount" "$OUTPUT_FILE" "/output"
                                                                                                                            ] ;
                                                                                                                        name = "is-marked-for-garbage-collection" ;
                                                                                                                        runScript = "is-marked-for-garbage-collection" ;
                                                                                                                        targetPkgs =
                                                                                                                            pkgs :
                                                                                                                                [
                                                                                                                                    (
                                                                                                                                        pkgs.writeShellApplication
                                                                                                                                            {
                                                                                                                                                name = "is-marked-for-garbage-collection" ;
                                                                                                                                                runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.gnugrep pkgs.jq ] ;
                                                                                                                                                text =
                                                                                                                                                    ''
                                                                                                                                                        INDEX="$( jq --null-input --raw-output ".index" /input )" || exit 121
                                                                                                                                                        find ${ gc-roots-directory } -type L | while read -r LINK
                                                                                                                                                        do
                                                                                                                                                            if [[ ! -s /output ]]
                                                                                                                                                            then
                                                                                                                                                                OBSERVED="$( readlink --canonicalize "$LINK" )" || exit 122
                                                                                                                                                                if [[ "${ resources-directory }/mounts/$INDEX" == "$OBSERVED" ]]
                                                                                                                                                                then
                                                                                                                                                                    jq --null-input 'false' > /output
                                                                                                                                                                fi
                                                                                                                                                            fi
                                                                                                                                                        done
                                                                                                                                                        if [[ ! -s /output ]]
                                                                                                                                                        then
                                                                                                                                                            jq --null-input 'true' > /output
                                                                                                                                                        fi
                                                                                                                                                    '' ;
                                                                                                                                            }
                                                                                                                                    )
                                                                                                                                ] ;
                                                                                                                    }
                                                                                                            )
                                                                                                            (
                                                                                                                buildFHSUserEnv
                                                                                                                    {
                                                                                                                        extraBwrapArgs =
                                                                                                                            [
                                                                                                                                "--ro-bind" "${ resources-directory }" "${ resources-directory }"
                                                                                                                            ] ;
                                                                                                                        name = "release" ;
                                                                                                                        runScript = "release" ;
                                                                                                                        targetPkgs =
                                                                                                                            pkgs :
                                                                                                                                [
                                                                                                                                    (
                                                                                                                                        pkgs.writeShellApplication
                                                                                                                                            {
                                                                                                                                                name = "release" ;
                                                                                                                                                runtimeInputs = [ ] ;
                                                                                                                                                text =
                                                                                                                                            }
                                                                                                                                    )
                                                                                                                                ] ;
                                                                                                                    }
                                                                                                            )
                                                                                                        ] ;
                                                                                                    text =
                                                                                                        ''
                                                                                                            mkdir --parents ${ resources-directory }/locks
                                                                                                            exec 172> ${ resources-directory }/locks/temporary
                                                                                                            flock -s 172
                                                                                                            mkdir --parents ${ resources-directory }/temporary
                                                                                                            INPUT_FILE="$( mktemp --suffix ".json" ${ resources-directory }/temporary/XXXXXXXX )" || exit 101
                                                                                                            export INPUT_FILE
                                                                                                            OUTPUT_FILE="$( mktemp --suffix ".json" ${ resources-directory }/temporary/XXXXXXXX )" || exit 100
                                                                                                            export OUTPUT_FILE
                                                                                                            mkdir --parents ${ gc-roots-directory }
                                                                                                            mkdir --parents ${ resources-directory }
                                                                                                            exec 111> "${ resources-directory }/locks/$INDEX"
                                                                                                            flock -x 111
                                                                                                            mkdir --parents ${ resources-directory }/flags
                                                                                                            rm --force "${ resources-directory }/flags/$INDEX"
                                                                                                            mkdir --parents "${ resources-directory }/pids/$INDEX"
                                                                                                            find "${ resources-directory }/pids/$INDEX" -type f | while read PID_FILE
                                                                                                            do
                                                                                                                PID="$( basename "$PID_FILE" )" || exit 122
                                                                                                                tail --follow /dev/null --pid "$PID"
                                                                                                                rm "$PID_FILE"
                                                                                                            done
                                                                                                            is-marked-for-garbage-collection
                                                                                                            IS_MARKED_FOR_GARBAGE_COLLECTION="$( jq --null-input --raw-output "." )" || exit 143
                                                                                                            if "$IS_MARKED_FOR_GARBAGE_COLLECTION"
                                                                                                            then
                                                                                                                release
                                                                                                                IS_RELEASED="$( jq --raw-input --raw-output "." "$OUTPUT_FILE" )" || exit 4784873797123221
                                                                                                                if "$IS_RELEASED"
                                                                                                                then
                                                                                                                    garbage-collect
                                                                                                                    TARGET="$( jq --null-input "." $OUTPUT_FILE )" || exit 162
                                                                                                                    ARCHIVE="$( mktemp --suffix .xz.tar )" || exit 186
                                                                                                                    mv "$TARGET" "$ARCHIVE"
                                                                                                                fi
                                                                                                            else
                                                                                                                flock -u 111
                                                                                                                "$0"
                                                                                                            fi
                                                                                                            rm "$INPUT_FILE" "$OUTPUT_FILE"
                                                                                                        '' ;
                                                                                                } ;
                                                                                        recovery = { } ;
                                                                                    } ;
                                                                            } ;
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
                                                                                                                                                            UUID="$1"
                                                                                                                                                            EXECUTABLE="$2"
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
