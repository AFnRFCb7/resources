{
	inputs = { } ;
	outputs =
		{ self } :
		    {
		        lib =
                    {
                        buildFHSUserEnv ,
                        coreutils ,
                        description ? null ,
                        failures ? { } ,
                        findutils ,
                        flock ,
                        gawk ,
                        init ? null ,
                        jq ,
                        inotify-tools ,
                        makeBinPath ,
                        makeWrapper ,
                        mkDerivation ,
                        ps ,
                        release ? null ,
                        resources-directory ,
                        seed ? null ,
                        targets ? [ ] ,
                        token-bad ? 0 ,
                        token-good ? 0 ,
                        token-no-init ? 0 ,
                        token-recovery-setup ? 0 ,
                        token-recovery-teardown ? 0 ,
                        token-stall-for-cleanup ? 0 ,
                        token-stall-for-process ? 0 ,
                        token-stale ? 0 ,
                        token-teardown-aborted ? 0 ,
                        token-teardown-final ? 0 ,
                        transient ? false ,
                        visitor ,
                        yq-go ,
                        writeShellApplication
                    } @primary :
                        let
                            check =
                                {
                                    commands ,
                                    delay ,
                                    diffutils ,
                                    processes ,
                                    redacted ? "1f41874b0cedd39ac838e4ef32976598e2bec5b858e6c1400390821c99948e9e205cff9e245bc6a42d273742bb2c48b9338e7d7e0d38c09a9f3335412b97f02f"
                                } :
                                    mkDerivation
                                        {
                                            installPhase =
                                                let
                                                    check =
                                                        writeShellApplication
                                                            {
                                                                name = "check" ;
                                                                runtimeInputs =
                                                                    let
                                                                        assert-empty =
                                                                            writeShellApplication
                                                                                {
                                                                                    name = "assert-empty" ;
                                                                                    runtimeInputs = [ coreutils findutils ] ;
                                                                                    text =
                                                                                        ''
                                                                                            OUT="$1"
                                                                                            DIRECTORY="$2"
                                                                                            if [[ -d "${ resources-directory }/$DIRECTORY" ]]
                                                                                            then
                                                                                                CONTENTS="$( find "${ resources-directory }/$DIRECTORY" -mindepth 1 -exec basename {} \; )" || ${ failures_ "4fcd6c4d" }
                                                                                                if [[ -n "$CONTENTS" ]]
                                                                                                then
                                                                                                    echo "We expected $DIRECTORY to be empty but found $CONTENTS OUT=$OUT" >&2
                                                                                                    ${ failures_ "ab669425" }
                                                                                                fi
                                                                                            fi
                                                                                        '' ;
                                                                                } ;
                                                                        checkpoint-post =
                                                                            writeShellApplication
                                                                                {
                                                                                    name = "checkpoint-post" ;
                                                                                    runtimeInputs = [ coreutils yq-go ] ;
                                                                                    text =
                                                                                        ''
                                                                                            NAME="$1"
                                                                                            OBSERVED="$2"
                                                                                            ORDER="$3"
                                                                                            OUT="$4"
                                                                                            while [[ ! -f "$OBSERVED/log.yaml" ]]
                                                                                            do
                                                                                                sleep 0
                                                                                            done
                                                                                            mkdir "$OUT/commands/$ORDER/observed"
                                                                                            yq --prettyPrint eval '
                                                                                                (.[] | select(has("init-application"))."init-application") = "${ redacted }" |
                                                                                                (.[] | select(has("release-application"))."release-application") = "${ redacted }" |
                                                                                                (.[] | select(has("originator-pid"))."originator-pid") = "${ redacted }"
                                                                                            ' "$OBSERVED/log.yaml" > "$OUT/commands/$ORDER/observed/log.yaml"
                                                                                            yq --prettyPrint eval 'sort_by(.hash, .type)' "$OUT/commands/$ORDER/observed/log.yaml" > "$OUT/commands/$ORDER/observed/events.yaml"
                                                                                            yq eval '[.[].token]' "$OUT/commands/$ORDER/observed/log.yaml" > "$OUT/commands/$ORDER/observed/order.yaml"
                                                                                            rm --recursive "$OBSERVED"
                                                                                            if ! diff --recursive --unified "$OUT/commands/$ORDER/expected/events.yaml" "$OUT/commands/$ORDER/observed/events.yaml"
                                                                                            then
                                                                                                echo "We expected the events of the $ORDER checkpoint to be $OUT/commands/$ORDER/expected/events.yaml but we observed $OUT/commands/$ORDER/observed/events.yaml" >&2
                                                                                                echo >&2
                                                                                                echo "${ fix }/bin/fix $OUT/commands/$ORDER/observed/log.yaml $NAME/log.yaml" >&2
                                                                                                echo >&2
                                                                                                ${ failures_ "f638de3c" }
                                                                                            fi
                                                                                            if ! diff --unified "$OUT/commands/$ORDER/expected/order.yaml" "$OUT/commands/$ORDER/observed/order.yaml"
                                                                                            then
                                                                                                echo "We expected the order of the $ORDER checkpoint to be $OUT/commands/$ORDER/expected/order.yaml but we observed $OUT/commands/$ORDER/observed/order.yaml" >&2
                                                                                                echo >&2
                                                                                                echo "${ fix }/bin/fix $OUT/commands/$ORDER/observed/log.yaml $NAME/log.yaml" >&2
                                                                                                echo >&2
                                                                                                ${ failures_ "65add455" }
                                                                                            fi
                                                                                            EVENTS="$( yq eval '.' "$OUT/commands/$ORDER/observed/events.yaml" )" || ${ failures_ "53034396" }
                                                                                            export EVENTS
                                                                                            ORDER="$( yq eval "." "$OUT/commands/$ORDER/observed/order.yaml" )" || ${ failures_ "e7c4924d" }
                                                                                            export ORDER
                                                                                            # shellcheck disable=SC2016
                                                                                            yq eval --inplace --prettyPrint '. += [ { "events" : ( strenv(EVENTS) | from_yaml ) , "order" : ( strenv(ORDER) | from_yaml ) } ]' "$OUT/log.yaml"
                                                                                        '' ;
                                                                                } ;
                                                                        checkpoint-run =
                                                                            writeShellApplication
                                                                                {
                                                                                    name = "checkpoint-run" ;
                                                                                    runtimeInputs = [ coreutils yq-go ] ;
                                                                                    text =
                                                                                        ''
                                                                                            OBSERVED="$1"
                                                                                            sleep 10s #KLUDGE
                                                                                            echo 8a6978d0
                                                                                            ls ${ resources-directory }/logs/log.yaml
                                                                                            echo acd75010
                                                                                            cat ${ resources-directory }/logs/log.yaml > "$OBSERVED/log.yaml"
                                                                                            echo 70062a4d
                                                                                            rm ${ resources-directory }/logs/log.yaml
                                                                                        '' ;
                                                                                } ;
                                                                        command-post =
                                                                            writeShellApplication
                                                                                {
                                                                                    name = "command-post" ;
                                                                                    runtimeInputs = [ coreutils diffutils yq-go ] ;
                                                                                    text =
                                                                                        ''
                                                                                            export COMMAND="$1"
                                                                                            NAME="$2"
                                                                                            OBSERVED="$3"
                                                                                            ORDER="$4"
                                                                                            OUT="$5"
                                                                                            export PROCESS="$6"
                                                                                            while [[ ! -f "$OBSERVED/standard-output" ]]
                                                                                            do
                                                                                                sleep 0
                                                                                            done
                                                                                            while [[ ! -f "$OBSERVED/standard-error" ]]
                                                                                            do
                                                                                                sleep 0
                                                                                            done
                                                                                            while [[ ! -f "$OBSERVED/status" ]]
                                                                                            do
                                                                                                sleep 0
                                                                                            done
                                                                                            mv "$OBSERVED" "$OUT/commands/$ORDER/observed"
                                                                                            if ! diff --unified "$OUT/commands/$ORDER/expected/standard-output" "$OUT/commands/$ORDER/observed/standard-output"
                                                                                            then
                                                                                                echo "We expected the standard output of the $ORDER command to be $OUT/commands/$ORDER/expected/standard-output but it was $OUT/commands/$ORDER/observed/standard-output" >&2
                                                                                                echo >&2
                                                                                                echo "${ fix }/bin/fix $OUT/commands/$ORDER/observed/standard-output $NAME/standard-output" >&2
                                                                                                echo >&2
                                                                                                ${ failures_ "ed07854e" }
                                                                                            fi
                                                                                            if [[ ! -f "$OUT/commands/$ORDER/observed/standard-error" ]]
                                                                                            then
                                                                                                echo "We expected the standard error of the $ORDER command to exist but it does not exist" >&2
                                                                                                ${ failures_ "231188dc" }
                                                                                            elif [[ -s "$OUT/commands/$ORDER/observed/standard-error" ]]
                                                                                            then
                                                                                                echo "We expected the standard error of the $ORDER command to be blank but it was not blank" >&2
                                                                                                ${ failures_ "28512133" }
                                                                                            fi
                                                                                            OBSERVED_STATUS="$( < "$OUT/commands/$ORDER/observed/status" )" || ${ failures_ "f5a2fae1" }
                                                                                            export OBSERVED_STATUS
                                                                                            if ! diff --unified "$OUT/commands/$ORDER/expected/status" "$OUT/commands/$ORDER/observed/status"
                                                                                            then
                                                                                                EXPECTED_STATUS="$( < "$OUT/commands/$ORDER/expected/status" )" || ${ failures_ "9bfd8524" }
                                                                                                echo "We expected the status of the $ORDER command to be $EXPECTED_STATUS but it was $OBSERVED_STATUS" >&2
                                                                                                echo >&2
                                                                                                echo "${ fix }/bin/fix $OUT/commands/$ORDER/observed/status $NAME/status" >&2
                                                                                                echo >&2
                                                                                                ${ failures_ "ed408cfe" }
                                                                                            fi
                                                                                            STANDARD_OUTPUT="$( < "$OUT/commands/$ORDER/observed/standard-output" )" || ${ failures_ "68f2d853" }
                                                                                            export STANDARD_OUTPUT
                                                                                            touch "$OUT/log.yaml"
                                                                                            # shellcheck disable=SC2016
                                                                                            yq eval --inplace --prettyPrint '. += [ { "command": strenv(COMMAND), "process": strenv(PROCESS), "standard-output": strenv(STANDARD_OUTPUT), "status": strenv(STATUS) } ]' "$OUT/log.yaml"
                                                                                        '' ;
                                                                                } ;
                                                                        command-run =
                                                                            writeShellApplication
                                                                                {
                                                                                    name = "command-run" ;
                                                                                    runtimeInputs = [ coreutils ] ;
                                                                                    text =
                                                                                        ''
                                                                                            COMMAND="$1"
                                                                                            OBSERVED="$2"
                                                                                            OUT="$3"
                                                                                            PROCESS="$4"
                                                                                            cat >> "$OUT/processes/$PROCESS.pipe" <<EOF
                                                                                            if RESOURCE="\$( $COMMAND 2> "$OBSERVED/standard-error" )"
                                                                                            then
                                                                                                echo "\$RESOURCE" > "$OBSERVED/standard-output"
                                                                                                echo "\$?" > "$OBSERVED/status"
                                                                                            else
                                                                                                echo "\$RESOURCE" > "$OBSERVED/standard-output"
                                                                                                echo "\$?" > "$OBSERVED/status"
                                                                                            fi
                                                                                            EOF
                                                                                        '' ;
                                                                                } ;
                                                                        exit-post =
                                                                            writeShellApplication
                                                                                {
                                                                                    name = "exit-post" ;
                                                                                    runtimeInputs = [ coreutils yq-go ] ;
                                                                                    text =
                                                                                        ''
                                                                                            OUT="$1"
                                                                                            PROCESS="$2"
                                                                                            # shellcheck disable=SC2016
                                                                                            yq --inplace --null-input --arg PROCESS "$PROCESS" --prettyPrint '. += [ { "exit" : true , "process" : $PROCESS } ]' "$OUT/log.yaml"
                                                                                        '' ;
                                                                                } ;
                                                                        exit-run =
                                                                            writeShellApplication
                                                                                {
                                                                                    name = "exit-run" ;
                                                                                    runtimeInputs = [ coreutils ] ;
                                                                                    text =
                                                                                        ''
                                                                                            OUT="$1"
                                                                                            PROCESS="$2"
                                                                                            echo "exit" >> "$OUT/processes/$PROCESS.pipe"
                                                                                        '' ;
                                                                                } ;
                                                                        fix =
                                                                            writeShellApplication
                                                                                {
                                                                                    name = "fix" ;
                                                                                    runtimeInputs = [ coreutils ] ;
                                                                                    text =
                                                                                        ''
                                                                                            : "${ builtins.concatStringsSep "" [ "$" "{" "GOLDEN" ":?GOLDEN must be set" "}" ] }"
                                                                                            INPUT="$1"
                                                                                            OUTPUT="$2"
                                                                                            cat "$INPUT" > "$GOLDEN/$OUTPUT"
                                                                                        '' ;
                                                                                } ;
                                                                        prepare-command =
                                                                            writeShellApplication
                                                                                {
                                                                                    name = "prepare-command" ;
                                                                                    runtimeInputs = [ coreutils yq-go ] ;
                                                                                    text =
                                                                                        ''
                                                                                            : "${ builtins.concatStringsSep "" [ "$" "{" "OUT:?OUT must be set" "}" ] }"
                                                                                            ORDER="$1"
                                                                                            COMMAND_DIRECTORY="$2"
                                                                                            mkdir --parents "$OUT/commands/$ORDER"
                                                                                            echo "$ORDER" > "$OUT/commands/$ORDER/order"
                                                                                            if [[ -f "$COMMAND_DIRECTORY/is-checkpoint" ]] && [[ -f "$COMMAND_DIRECTORY/log.yaml" ]]
                                                                                            then
                                                                                                NAME="$( basename "$COMMAND_DIRECTORY" )" || ${ failures_ "52791884" }
                                                                                                OBSERVED="$( mktemp --directory )" || ${ failures_ "be0e1e19" }
                                                                                                chmod 0755 "$OBSERVED"
                                                                                                mkdir --parents "$OUT/commands/$ORDER/expected"
                                                                                                yq eval --prettyPrint 'sort_by(.hash, .type)' "$COMMAND_DIRECTORY/log.yaml" > "$OUT/commands/$ORDER/expected/events.yaml"
                                                                                                yq eval --prettyPrint '[.[].token]' "$COMMAND_DIRECTORY/log.yaml" > "$OUT/commands/$ORDER/expected/order.yaml"
                                                                                                echo "checkpoint-run \"$OBSERVED\"" >> "$OUT/run"
                                                                                                echo "checkpoint-post \"$NAME\" \"$OBSERVED\" \"$ORDER\" \"$OUT\"" >> "$OUT/post"
                                                                                            elif [[ -f "$COMMAND_DIRECTORY/is-command" ]] && [[ -f "$COMMAND_DIRECTORY/command" ]] && [[ -f "$COMMAND_DIRECTORY/standard-output" ]] && [[ -f "$COMMAND_DIRECTORY/status" ]]
                                                                                            then
                                                                                                PROCESS="$( < "$COMMAND_DIRECTORY/process" )" || ${ failures_ "cf9df67c" }
                                                                                                if [[ ! -f "$OUT/processes/$PROCESS.pipe" ]] && [[ ! -f "$OUT/processes/$PROCESS.pid" ]]
                                                                                                then
                                                                                                    echo "We expected there to be a process $PROCESS but there was not OUT=$OUT" >&2
                                                                                                    ${ failures_ "2f257e3e" }
                                                                                                fi
                                                                                                OBSERVED="$( mktemp --directory )" || ${ failures_ "7006794a" }
                                                                                                chmod 0755 "$OBSERVED"
                                                                                                NAME="$( basename "$COMMAND_DIRECTORY" )" || ${ failures_ "fd6fbc4d" }
                                                                                                COMMAND_RAW="$( < "$COMMAND_DIRECTORY/command" )" || ${ failures_ "e50bd79d" }
                                                                                                COMMAND_SUBSTITUTED="${ builtins.concatStringsSep "" [ "$" "{" "COMMAND_RAW//\\\$IMPLEMENTATION/${ implementation }" "}" ] }"
                                                                                                echo "$COMMAND_SUBSTITUTED" > "$OUT/commands/$ORDER/command"
                                                                                                mkdir --parents "$OUT/commands/$ORDER/expected"
                                                                                                ln --symbolic "$COMMAND_DIRECTORY/standard-output" "$OUT/commands/$ORDER/expected"
                                                                                                ln --symbolic "$COMMAND_DIRECTORY/status" "$OUT/commands/$ORDER/expected"
                                                                                                echo "command-run \"$COMMAND_SUBSTITUTED\" \"$OBSERVED\" \"$OUT\" \"$PROCESS\"" >> "$OUT/run"
                                                                                                echo "command-post \"$COMMAND_RAW\" \"$NAME\" \"$OBSERVED\" \"$ORDER\" \"$OUT\" \"$PROCESS\"" >> "$OUT/post"
                                                                                            elif [[ -f "$COMMAND_DIRECTORY/is-exit" ]]
                                                                                            then
                                                                                                PROCESS="$( < "$COMMAND_DIRECTORY/process" )" || ${ failures_ "b9b62f51" }
                                                                                                echo "exit-run \"$OUT\" \"$PROCESS\"" >> "$OUT/run"
                                                                                                echo "exit-post \"$OUT\" \"$PROCESS\"" >> "$OUT/post"
                                                                                            else
                                                                                                echo "Unexpected Configuration OUT=$OUT" >&2
                                                                                                ${ failures_ "a1aba4ed" }
                                                                                            fi
                                                                                            echo "sleep ${ builtins.toString delay }" >> "$OUT/run"
                                                                                        '' ;
                                                                                } ;
                                                                        in [ assert-empty checkpoint-post checkpoint-run command-post command-run exit-post exit-run coreutils prepare-command ] ;
                                                                text =
                                                                    let
                                                                        command-mapper =
                                                                            { index ? 0 , order } :
                                                                                let
                                                                                    application =
                                                                                        writeShellApplication
                                                                                            {
                                                                                                name = "run-command" ;
                                                                                                runtimeInputs = [ process ] ;
                                                                                                text =
                                                                                                    ''
                                                                                                        COMMANDS="$1"
                                                                                                        mkdir --parents "$COMMANDS/${ index }"
                                                                                                        echo ${ order } > "$COMMANDS/${ index }/order"
                                                                                                    '' ;
                                                                                            } ;
                                                                                    in ''${ application }/bin/run-command "$OUT/commands"'' ;
                                                                        process =
                                                                            writeShellApplication
                                                                                {
                                                                                    name = "process" ;
                                                                                    runtimeInputs = [ coreutils inotify-tools ] ;
                                                                                    text =
                                                                                        ''
                                                                                            PIPE="$1"
                                                                                            touch "$PIPE"
                                                                                            CURRENT_LINE=0
                                                                                            inotifywait --event modify "$PIPE" | while read -r
                                                                                            do
                                                                                                NEW_LINES="$( tail --lines +"$CURRENT_LINE" "$PIPE" )" || ${ failures_ "a6f9cc4a" }
                                                                                                NUM_NEW_LINES="$( echo "$NEW_LINES" | wc --lines )" || ${ failures_ "5e1f27c6" }
                                                                                                CURRENT_LINE=$(( CURRENT_LINE + NUM_NEW_LINES ))
                                                                                                eval "$NEW_LINES"
                                                                                                sleep 1s
                                                                                            done
                                                                                        '' ;
                                                                                } ;
                                                                        process-mapper =
                                                                            name :
                                                                                let
                                                                                    application =
                                                                                        writeShellApplication
                                                                                            {
                                                                                                name = "start-process" ;
                                                                                                runtimeInputs = [ process ] ;
                                                                                                text =
                                                                                                    ''
                                                                                                        PROCESSES="$1"
                                                                                                        mkdir --parents "$PROCESSES"
                                                                                                        process "$PROCESSES/${ name }.pipe" &
                                                                                                        echo "$!" > "$PROCESSES/${ name }.pid"
                                                                                                    '' ;
                                                                                            } ;
                                                                                    in ''${ application }/bin/start-process "$OUT/processes"'' ;
                                                                        in
                                                                            ''
                                                                                ${ builtins.concatStringsSep "\n" ( builtins.map process-mapper processes ) }
                                                                                echo "OUT=$OUT $0"
                                                                                find ${ commands } -mindepth 1 -maxdepth 1 -type d | while read -r COMMAND_DIRECTORY
                                                                                do
                                                                                    ORDER="$( < "$COMMAND_DIRECTORY/order" )" || ${ failures_ "acdfc2c8" }
                                                                                    echo "$ORDER $COMMAND_DIRECTORY"
                                                                                done | sort --numeric --key 1 > "$OUT/order"
                                                                                uniq "$OUT/order" > "$OUT/uniq"
                                                                                if ! diff --unified "$OUT/order" "$OUT/uniq"
                                                                                then
                                                                                    echo "We expected the order to be unique but it was not" >&2
                                                                                    ${ failures_ "67149273" }
                                                                                fi
                                                                                while read -r ORDER COMMAND
                                                                                do
                                                                                    prepare-command "$ORDER" "$COMMAND"
                                                                                done < "$OUT/uniq"
                                                                                chmod 0500 "$OUT/run"
                                                                                "$OUT/run"
                                                                                # KLUDGE
                                                                                # find "$OUT/processes" -mindepth 1 -maxdepth 1 -type f -name "*.pid" | while read -r PROCESS
                                                                                # do
                                                                                #     PID="$( < "$PROCESS" )" || ${ failures_ "58a2f3e9" }
                                                                                #     tail --follow /dev/null --pid "$PID"
                                                                                # done
                                                                                chmod 0500 "$OUT/post"
                                                                                "$OUT/post"
                                                                                find "$OUT/processes" -mindepth 1 -maxdepth 1 -type f -name "*.pid" | while read -r PROCESS
                                                                                do
                                                                                    PID="$( < "$PROCESS" )" || ${ failures_ "c2823f07" }
                                                                                    if kill -0 "$PID"
                                                                                    then
                                                                                        BASE="$( basename "$PROCESS" )" || ${ failures_ "0ef41434" }
                                                                                        echo "We expected PROCESS $PID $BASE to be finished OUT=$OUT" >&2
                                                                                        ${ failures_ "23abd5bc" }
                                                                                    fi
                                                                                done
                                                                                assert-empty "$OUT" "mounts"
                                                                                assert-empty "$OUT" "links"
                                                                                assert-empty "$OUT" "canonical"
                                                                            '' ;
                                                            } ;
                                                in
                                                    ''
                                                        mkdir --parents $out/bin
                                                        makeWrapper ${ check }/bin/check $out/bin/check --set OUT $out
                                                        $out/bin/check
                                                    '' ;
                                            name = "test-observed" ;
                                            nativeBuildInputs = [ makeWrapper ] ;
                                            src = ./. ;
                                        } ;
                            failures_ =
                                unique :
                                    let
                                        listed = builtins.genList ( index : builtins.substring index 1 stringed ) 128 ;
                                        reduced =
                                            let
                                                reducer =
                                                    previous : current :
                                                        let
                                                            hexadecimal2decimal = hexadecimal : builtins.fromJSON ( builtins.replaceStrings [ "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "a" "b" "c" "d" "e" "f" ] [ "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "13" "14" "15" ] hexadecimal ) ;
                                                            mod = a : b : a - ( b * ( a / b ) ) ;
                                                            in mod ( previous * 16 + ( hexadecimal2decimal current ) ) 246 ;
                                                in builtins.foldl' reducer 0 listed ;
                                        stringed = builtins.hashString "sha512" ( builtins.toJSON stringable ) ;
                                        stringable =
                                            let
                                                to-stringable =
                                                    path : value :
                                                        let
                                                            type = builtins.typeOf value ;
                                                            in [ { path = path ; type = type ; value = if type == "lambda" then null else value ; } ] ;
                                                in
                                                    visitor.lib.implementation
                                                        {
                                                            bool = to-stringable ;
                                                            float = to-stringable ;
                                                            int = to-stringable ;
                                                            lambda = to-stringable ;
                                                            list = path : list : builtins.concatList list ;
                                                            null = to-stringable ;
                                                            path = to-stringable ;
                                                            set = path : set : builtins.concatLists ( builtins.attrValues set ) ;
                                                            string = to-stringable ;
                                                        }
                                                        unique ;
                                        in "exit ${ builtins.toString ( reduced + 10 ) }" ;
                            implementation =
                                let
                                    derivation =
                                        mkDerivation
                                            {
                                                installPhase =
                                                    let
                                                        description =
                                                            let
                                                                seed = path : value : [ { path = path ; type = builtins.typeOf value ; value = if builtins.typeOf value == "lambda" then null else value ; } ] ;
                                                                in
                                                                    visitor.lib.implementation
                                                                        {
                                                                            bool = seed ;
                                                                            float = seed ;
                                                                            int = seed ;
                                                                            lambda = seed ;
                                                                            list = seed ;
                                                                            null = seed ;
                                                                            path = seed ;
                                                                            set = seed ;
                                                                            string = seed ;
                                                                        }
                                                                        primary ;
                                                        init-application =
                                                            if builtins.typeOf init == "null" then null
                                                            else
                                                                buildFHSUserEnv
                                                                    {
                                                                        extraBwrapArgs =
                                                                            [
                                                                                "--bind $LINK /links"
                                                                                "--bind $MOUNT /mount"
                                                                                "--tmpfs /scratch"
                                                                            ] ;
                                                                        name = "init-application" ;
                                                                        runScript = init "${ resources-directory }/mounts/$HASH" ;
                                                                    } ;
                                                        pre-hash = builtins.hashString "sha512" ( builtins.toJSON description ) ;
                                                        release-application =
                                                            if builtins.typeOf release == "null" then null
                                                            else
                                                                buildFHSUserEnv
                                                                    {
                                                                        extraBwrapArgs =
                                                                            [
                                                                                "--ro-bind $MOUNT /mount"
                                                                                "--ro-bind ${ resources-directory } ${ resources-directory }"
                                                                                "--tmpfs /scratch"
                                                                            ] ;
                                                                        name = "release-application" ;
                                                                        runScript = release ;
                                                                    } ;
                                                        scripts =
                                                            {
                                                                bad =
                                                                    ''
                                                                        STAGE="$( cat )" || ${ failures_ "4e2a429a" }
                                                                        ARGUMENTS="$( printf '%s\n' "$@" | jq --raw-input --slurp 'split("\n") | map(select(length>0))' )" || ${ failures_ "a1b19aa5" }
                                                                        DESCRIPTION='${ builtins.toJSON description }'
                                                                        LINKS_TEMPORARY="$( temporary )" || ${ failures_ "cabcc321" }
                                                                        if [[ ! -s "$LINKS_TEMPORARY" ]]
                                                                        then
                                                                            LINKS='[]'
                                                                        else
                                                                            LINKS="$( jq --raw-input --slurp < "$LINKS_TEMPORARY" )" || ${ failures_ "bf995f33" }
                                                                        fi
                                                                        TARGET_TEMPORARY="$( temporary )" || ${ failures_ "2c083157" }
                                                                        find "$MOUNT" -mindepth 1 -maxdepth 1 -exec basename {} \; > "$TARGET_TEMPORARY"
                                                                        if [[ ! -s "$TARGET_TEMPORARY" ]]
                                                                        then
                                                                            TARGETS='[]'
                                                                        else
                                                                            TARGETS="$( jq --raw-input --slurp 'split("\n") | map(select(length>0))' < "$TARGET_TEMPORARY" )" || ${ failures_ "1623725f" }
                                                                        fi
                                                                        RECOVERY="${ resources-directory }/recovery/$MOUNT_INDEX"
                                                                        mkdir --parents "$RECOVERY"
                                                                        RECOVERY_BIN="$OUT/bin/recovery"
                                                                        # shellcheck source=/dev/null
                                                                        source "$MAKE_WRAPPER/nix-support/setup-hook"
                                                                        makeWrapper "$RECOVERY_BIN" "$RECOVERY/recovery.sh" --set HASH "$HASH" --set MOUNT_INDEX "$MOUNT_INDEX" --set STAGE "$STAGE"
                                                                        STANDARD_ERROR="$( < "$STANDARD_ERROR_FILE" )" || ${ failures_ "c141fe3b" }
                                                                        STANDARD_OUTPUT="$( < "$STANDARD_OUTPUT_FILE" )" || ${ failures_ "f13f84ae" }
                                                                        TYPE="$( basename "$0" )" || ${ failures_ "e5fa2135" }
                                                                        INIT_APPLICATION=${ if builtins.typeOf init-application == "null" then "null" else "${ init-application }/bin/init-application" }
                                                                        RELEASE_APPLICATION=${ if builtins.typeOf release-application == "null" then "null" else "${ release-application }/bin/release-application" }
                                                                        jq \
                                                                            --null-input \
                                                                            --argjson ARGUMENTS "$ARGUMENTS" \
                                                                            --argjson DESCRIPTION "$DESCRIPTION" \
                                                                            --arg HASH "$HASH" \
                                                                            --arg HAS_STANDARD_INPUT "$HAS_STANDARD_INPUT" \
                                                                            --arg INIT_APPLICATION "$INIT_APPLICATION" \
                                                                            --argjson LINKS "$LINKS" \
                                                                            --arg RELEASE_APPLICATION "$RELEASE_APPLICATION" \
                                                                            --arg STANDARD_ERROR "$STANDARD_ERROR" \
                                                                            --arg STANDARD_INPUT "$STANDARD_INPUT" \
                                                                            --arg STANDARD_OUTPUT "$STANDARD_OUTPUT" \
                                                                            --arg STAGE "$STAGE" \
                                                                            --arg STATUS "$STATUS" \
                                                                            --argjson TARGETS "$TARGETS" \
                                                                            --arg TOKEN ${ builtins.toString token-bad } \
                                                                            --arg TRANSIENT "$TRANSIENT" \
                                                                            --arg TYPE "$TYPE" \
                                                                            '{
                                                                                "arguments" : $ARGUMENTS ,
                                                                                "description" : $DESCRIPTION ,
                                                                                "hash" : $HASH ,
                                                                                "has-standard-input" : $HAS_STANDARD_INPUT ,
                                                                                "init-application" : $INIT_APPLICATION ,
                                                                                "links" : $LINKS ,
                                                                                "release-application" : $RELEASE_APPLICATION ,
                                                                                "standard-error" : $STANDARD_ERROR ,
                                                                                "standard-input" : $STANDARD_INPUT ,
                                                                                "standard-output" : $STANDARD_OUTPUT ,
                                                                                "status" : $STATUS ,
                                                                                "targets" : $TARGETS ,
                                                                                "token" : $TOKEN ,
                                                                                "transient" : $TRANSIENT ,
                                                                                "type" : $TYPE
                                                                            }' | log-bad
                                                                    '' ;
                                                                good =
                                                                    ''
                                                                        flock -s 211
                                                                        ARGUMENTS="$( printf '%s\n' "$@" | jq --raw-input --slurp 'split("\n")[:-1]' )" || ${ failures_ "ea11161a" }
                                                                        DESCRIPTION='${ builtins.toJSON description }'
                                                                        LINKS_TEMPORARY="$( temporary )" || ${ failures_ "c86d99c2" }
                                                                        if [[ ! -s "$LINKS_TEMPORARY" ]]
                                                                        then
                                                                            LINKS='[]'
                                                                        else
                                                                            LINKS="$( jq --raw-input --slurp < "$LINKS_TEMPORARY" )" || ${ failures_ "bf995f33" }
                                                                        fi
                                                                        STANDARD_ERROR="$( cat "$STANDARD_ERROR_FILE" )" || ${ failures_ "a69f5bc2" }
                                                                        STANDARD_OUTPUT="$( cat "$STANDARD_OUTPUT_FILE" )" || ${ failures_ "dc662c73" }
                                                                        TYPE="$( basename "$0" )" || ${ failures_ "cd255035" }
                                                                        INIT_APPLICATION=${ if builtins.typeOf init-application == "null" then "null" else "${ init-application }/bin/init-application" }
                                                                        RELEASE_APPLICATION=${ if builtins.typeOf release-application == "null" then "null" else "${ release-application }/bin/release-application" }
                                                                        jq \
                                                                            --null-input \
                                                                            --argjson ARGUMENTS "$ARGUMENTS" \
                                                                            --argjson DESCRIPTION "$DESCRIPTION" \
                                                                            --arg HASH "$HASH" \
                                                                            --arg HAS_STANDARD_INPUT "$HAS_STANDARD_INPUT" \
                                                                            --arg INIT_APPLICATION "$INIT_APPLICATION" \
                                                                            --argjson LINKS "$LINKS" \
                                                                            --arg RELEASE_APPLICATION "$RELEASE_APPLICATION" \
                                                                            --arg STANDARD_ERROR "$STANDARD_ERROR" \
                                                                            --arg STANDARD_INPUT "$STANDARD_INPUT" \
                                                                            --arg STANDARD_OUTPUT "$STANDARD_OUTPUT" \
                                                                            --arg STATUS "$STATUS" \
                                                                            --arg TOKEN ${ builtins.toString token-good } \
                                                                            --arg TRANSIENT "$TRANSIENT" \
                                                                            --arg TYPE "$TYPE" \
                                                                            '{
                                                                                "arguments" : $ARGUMENTS ,
                                                                                "description" : $DESCRIPTION ,
                                                                                "hash" : $HASH ,
                                                                                "has-standard-input" : $HAS_STANDARD_INPUT ,
                                                                                "init-application" : $INIT_APPLICATION ,
                                                                                "links" : $LINKS ,
                                                                                "release-application" : $RELEASE_APPLICATION ,
                                                                                "standard-error" : $STANDARD_ERROR ,
                                                                                "standard-input" : $STANDARD_INPUT ,
                                                                                "standard-output" : $STANDARD_OUTPUT ,
                                                                                "status" : $STATUS ,
                                                                                "token" : $TOKEN ,
                                                                                "transient" : $TRANSIENT ,
                                                                                "type" : $TYPE
                                                                            }' | log
                                                                        NOHUP="$( temporary )" || ${ failures_ "8d2d5a45" }
                                                                        nohup stall-for-process > "$NOHUP" 2>&1 &
                                                                    '' ;
                                                                links =
                                                                    if builtins.typeOf init == "null" then
                                                                        ''
                                                                            LINKS_TEMPORARY="$( temporary )" || ${ failures_ "f97d30fa" }
                                                                            echo "$LINKS_TEMPORARY"
                                                                        ''
                                                                    else
                                                                        ''
                                                                            LINKS_TEMPORARY="$( temporary )" || ${ failures_ "f97d30fa" }
                                                                            LINK=${ builtins.concatStringsSep "" [ "$" "{" "LINK:?LINK must be set" "}" ] }
                                                                            find "$LINK" -mindepth 1 -maxdepth 1 -type l -exec readlink {} \; | while read -r FROM_LINK
                                                                            do
                                                                                find ${ resources-directory }/canonical -mindepth 1 -maxdepth 1 -type l -exec readlink {} \; | while read -r FROM_CANONICAL
                                                                                do
                                                                                    if [[ "$FROM_LINK" == "$FROM_CANONICAL" ]]
                                                                                    then
                                                                                        echo "$FROM_LINK" >> "$LINKS_TEMPORARY"
                                                                                    fi
                                                                                done
                                                                            done
                                                                            echo "$LINKS_TEMPORARY"
                                                                        '' ;
                                                                log =
                                                                    ''
                                                                        mkdir --parents ${ resources-directory }/logs
                                                                        exec 203> ${ resources-directory }/logs/lock
                                                                        flock -x 203
                                                                        cat | yq --prettyPrint '[.]' >> ${ resources-directory }/logs/log.yaml
                                                                    '' ;
                                                                log-bad =
                                                                    ''
                                                                        TEMPORARY_LOG="$( temporary )" || ${ failures_ "cebabd7e" }
                                                                        cat > "$TEMPORARY_LOG"
                                                                        mkdir --parents "${ resources-directory }/recovery/$MOUNT_INDEX"
                                                                        OBSERVED="$( < "$TEMPORARY_LOG" )" || ${ failures_ "e9908502" }
                                                                        jq \
                                                                            --null-input \
                                                                            --arg HASH "$HASH" \
                                                                            --argjson TARGETS '${ builtins.toJSON targets }' \
                                                                            --argjson OBSERVED "$OBSERVED" \
                                                                            '{
                                                                                "expected" :
                                                                                    {
                                                                                        "hash" : $HASH ,
                                                                                        "targets": $TARGETS
                                                                                    } ,
                                                                              "observed" : $OBSERVED
                                                                            }' | yq --prettyPrint > "${ resources-directory }/recovery/$MOUNT_INDEX/log.yq"
                                                                        log < "$TEMPORARY_LOG"
                                                                    '' ;
                                                                no-init =
                                                                    ''
                                                                        flock -s 211
                                                                        DESCRIPTION='${ builtins.toJSON description }'
                                                                        TYPE="$( basename "$0" )" || ${ failures_ "a32a15dc" }
                                                                        jq \
                                                                            --argjson DESCRIPTION "$DESCRIPTION" \
                                                                            --arg HASH "$HASH" \
                                                                            --arg ORIGINATOR_PID "$ORIGINATOR_PID" \
                                                                            --arg TOKEN ${ builtins.toString token-no-init } \
                                                                            --arg TRANSIENT "$TRANSIENT" \
                                                                            --arg TYPE "$TYPE" \
                                                                            --null-input \
                                                                            '{
                                                                                "description" : "$DESCRIPTION" ,
                                                                                "hash" : $HASH ,
                                                                                "originator-pid" : $ORIGINATOR_PID ,
                                                                                "token" : $TOKEN ,
                                                                                "type" : $TYPE
                                                                            }' | log
                                                                        NOHUP="$( temporary )" || ${ failures_ "8192be99" }
                                                                        nohup stall-for-process > "$NOHUP" 2>&1 &
                                                                    '' ;
                                                                recovery =
                                                                    ''
                                                                        GOOD="$( temporary )" || ${ failures_ "f696cd77" }
                                                                        mkdir --parents ${ resources-directory }/temporary
                                                                        trash "${ resources-directory }/links/$MOUNT_INDEX"
                                                                        mv "${ resources-directory }/mounts/$MOUNT_INDEX" "$GOOD"
                                                                        trash "${ resources-directory }/recovery/$MOUNT_INDEX"
                                                                        ARGUMENTS="$( printf '%s\n' "$@" | jq --raw-input --slurp 'split("\n")[:-1]' )" || ${ failures_ "8a335213" }
                                                                        if [[ "$STAGE" == "setup" ]]
                                                                        then
                                                                            TOKEN=${ builtins.toString token-recovery-setup }
                                                                        else
                                                                            TOKEN=${ builtins.toString token-recovery-teardown }
                                                                        fi
                                                                        if read -t 0
                                                                        then
                                                                            HAS_STANDARD_INPUT=true
                                                                            STANDARD_INPUT="$( cat )" || ${ failures_ "d8a96cd7" }
                                                                        else
                                                                            HAS_STANDARD_INPUT=false
                                                                            STANDARD_INPUT=
                                                                        fi
                                                                        TYPE="$( basename "$0" )" || ${ failures_ "26030b9e" }
                                                                        jq \
                                                                            --null-input \
                                                                            --argjson ARGUMENTS "$ARGUMENTS" \
                                                                            --arg HAS_STANDARD_INPUT "$HAS_STANDARD_INPUT" \
                                                                            --arg HASH "$HASH" \
                                                                            --arg STANDARD_INPUT "$STANDARD_INPUT" \
                                                                            --arg TOKEN "$TOKEN
                                                                            " \
                                                                            --arg TYPE "$TYPE" \
                                                                            '{
                                                                                "arguments" : $ARGUMENTS ,
                                                                                "has-standard-input" : $HAS_STANDARD_INPUT ,
                                                                                "hash" : $HASH ,
                                                                                "standard-input" : $STANDARD_INPUT ,
                                                                                "token" : $TOKEN ,
                                                                                "type" : $TYPE
                                                                            }' | log
                                                                        log
                                                                    '' ;
                                                                sequential =
                                                                    ''
                                                                        mkdir --parents ${ resources-directory }
                                                                        exec 205> ${ resources-directory }/counter.lock
                                                                        flock -x 205
                                                                        if [[ -s ${ resources-directory }/counter.increment ]]
                                                                        then
                                                                            OLD="$( < ${ resources-directory }/counter.increment )" || ${ failures_ "d565ecbe" }
                                                                        else
                                                                            OLD="0"
                                                                        fi
                                                                        NEW=$(( OLD + 1 ))
                                                                        if [[ "$NEW" -eq "9999999999999999" ]]
                                                                        then
                                                                            NEW="0"
                                                                        fi
                                                                        echo "$NEW" > ${ resources-directory }/counter.increment
                                                                        chmod 0644 ${ resources-directory }/counter.increment
                                                                        printf "%016d\n" "$NEW"
                                                                    '' ;
                                                                setup =
                                                                    if builtins.typeOf init == "null" then
                                                                        ''
                                                                            if [[ -t 0 ]]
                                                                            then
                                                                                HAS_STANDARD_INPUT=false
                                                                                STANDARD_INPUT=
                                                                                STANDARD_INPUT_FILE="$( temporary )" || ${ failures_ "7f77cdad" }
                                                                            else
                                                                                HAS_STANDARD_INPUT=true
                                                                                timeout 1m cat > "$STANDARD_INPUT_FILE"
                                                                                STANDARD_INPUT="$( cat "$STANDARD_INPUT_FILE" )" || ${ failures_ "fbb0e2f8" }
                                                                            fi
                                                                            TRANSIENT=${ transient_ }
                                                                            ORIGINATOR_PID="$( ps -o ppid= -p "$PPID" )" || ${ failures_ "833fbd3f" }
                                                                            export ORIGINATOR_PID
                                                                            HASH="$( echo "${ pre-hash } ${ builtins.concatStringsSep "" [ "$TRANSIENT" "$" "{" "ARGUMENTS[*]" "}" ] } $STANDARD_INPUT $HAS_STANDARD_INPUT" | sha512sum | cut --characters 1-128 )" || ${ failures_ "bc3e1b88" }
                                                                            export HASH
                                                                            mkdir --parents "${ resources-directory }/locks"
                                                                            exec 210> "${ resources-directory }/locks/$HASH/teardown.lock"
                                                                            flock -s 210
                                                                            if [[ -L "${ resources-directory }/canonical/$HASH" ]]
                                                                            then
                                                                                MOUNT="$( readlink "${ resources-directory }/canonical/$HASH" )" || ${ failures_ "bf282501" }
                                                                                export MOUNT
                                                                                MOUNT_INDEX="$( basename "$MOUNT" )" || ${ failures_ "26213048" }
                                                                                export MOUNT_INDEX
                                                                                mkdir --parents "${ resources-directory }/locks/$MOUNT_INDEX"
                                                                                exec 211> "${ resources-directory }/locks/$MOUNT_INDEX/setup.lock"
                                                                                flock -s 211
                                                                                NOHUP="$( temporary )" || ${ failures_ "b63481a0" }
                                                                                nohup stale > "$NOHUP" 2>&1 &
                                                                                ln --symbolic "$MOUNT" "${ resources-directory }/canonical/$HASH"
                                                                                echo -n "$MOUNT"
                                                                            else
                                                                                MOUNT_INDEX="$( sequential )" || ${ failures_ "d162db9f" }
                                                                                export MOUNT_INDEX
                                                                                mkdir --parents "${ resources-directory }/locks/$MOUNT_INDEX"
                                                                                exec 211> "${ resources-directory }/locks/$MOUNT_INDEX/setup.lock"
                                                                                flock -s 211
                                                                                MOUNT="${ resources-directory }/mounts/$MOUNT_INDEX"
                                                                                mkdir --parents "$MOUNT"
                                                                                mkdir --parents ${ resources-directory }/canonical
                                                                                ln --symbolic "$MOUNT" "${ resources-directory }/canonical/$HASH"
                                                                                NOHUP="$( temporary )" || ${ failures_ "f91c57c2" }
                                                                                nohup no-init > "$NOHUP" 2>&1 &
                                                                                echo -n "$MOUNT"
                                                                            fi
                                                                        ''
                                                                    else
                                                                        ''
                                                                            if [[ -t 0 ]]
                                                                            then
                                                                                HAS_STANDARD_INPUT=false
                                                                                STANDARD_INPUT=
                                                                            else
                                                                                STANDARD_INPUT_FILE="$( temporary )" || ${ failures_ "f66f966d" }
                                                                                export STANDARD_INPUT_FILE
                                                                                HAS_STANDARD_INPUT=true
                                                                                cat > "$STANDARD_INPUT_FILE"
                                                                                STANDARD_INPUT="$( cat "$STANDARD_INPUT_FILE" )" || ${ failures_ "ffff1b30" }
                                                                            fi
                                                                            export HAS_STANDARD_INPUT
                                                                            export STANDARD_INPUT
                                                                            ARGUMENTS=( "$@" )
                                                                            TRANSIENT=${ transient_ }
                                                                            export TRANSIENT
                                                                            ORIGINATOR_PID="$( ps -o ppid= -p "$PPID" | awk '{print $1}' )" || ${ failures_ "833fbd3f" }
                                                                            export ORIGINATOR_PID
                                                                            HASH="$( echo "${ pre-hash } ${ builtins.concatStringsSep "" [ "$TRANSIENT" "$" "{" "ARGUMENTS[*]" "}" ] } $STANDARD_INPUT $HAS_STANDARD_INPUT" | sha512sum | cut --characters 1-128 )" || ${ failures_ "7849a979" }
                                                                            export HASH
                                                                            mkdir --parents "${ resources-directory }/locks"
                                                                            exec 210> "${ resources-directory }/locks/$HASH"
                                                                            flock -s 210
                                                                            if [[ -L "${ resources-directory }/canonical/$HASH" ]]
                                                                            then
                                                                                MOUNT="$( readlink "${ resources-directory }/canonical/$HASH" )" || ${ failures_ "ae2d1658" }
                                                                                export MOUNT
                                                                                MOUNT_INDEX="$( basename "$MOUNT" )" || ${ failures_ "277afc07" }
                                                                                export MOUNT_INDEX
                                                                                mkdir --parents "${ resources-directory }/locks/$MOUNT_INDEX"
                                                                                exec 211> "${ resources-directory }/locks/$MOUNT_INDEX/setup.lock"
                                                                                flock -s 211
                                                                                NOHUP="$( temporary )" || ${ failures_ "f2f6f4e4" }
                                                                                nohup stale > "$NOHUP" 2>&1 &
                                                                                echo -n "$MOUNT"
                                                                            else
                                                                                MOUNT_INDEX="$( sequential )" || ${ failures_ "cab66847" }
                                                                                export MOUNT_INDEX
                                                                                mkdir --parents "${ resources-directory }/locks/$MOUNT_INDEX"
                                                                                exec 211> "${ resources-directory }/locks/$MOUNT_INDEX/setup.lock"
                                                                                flock -s 211
                                                                                LINK="${ resources-directory }/links/$MOUNT_INDEX"
                                                                                export LINK
                                                                                mkdir --parents "$LINK"
                                                                                MOUNT="${ resources-directory }/mounts/$MOUNT_INDEX"
                                                                                mkdir --parents "$MOUNT"
                                                                                export MOUNT
                                                                                mkdir --parents "$MOUNT"
                                                                                STANDARD_ERROR_FILE="$( temporary )" || ${ failures_ "b07f7374" }
                                                                                export STANDARD_ERROR_FILE
                                                                                STANDARD_OUTPUT_FILE="$( temporary )" || ${ failures_ "29c19af1" }
                                                                                export STANDARD_OUTPUT_FILE
                                                                                if [[ "$HAS_STANDARD_INPUT" == "true" ]]
                                                                                then
                                                                                    if ${ init-application }/bin/init-application "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" < "$STANDARD_INPUT_FILE" > "$STANDARD_OUTPUT_FILE" 2> "$STANDARD_ERROR_FILE"
                                                                                    then
                                                                                        STATUS="$?"
                                                                                    else
                                                                                        STATUS="$?"
                                                                                    fi
                                                                                else
                                                                                    if ${ init-application }/bin/init-application "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" > "$STANDARD_OUTPUT_FILE" 2> "$STANDARD_ERROR_FILE"
                                                                                    then
                                                                                        STATUS="$?"
                                                                                    else
                                                                                        STATUS="$?"
                                                                                    fi
                                                                                fi
                                                                                export STATUS
                                                                                TARGET_HASH_EXPECTED=${ builtins.hashString "sha512" ( builtins.concatStringsSep "" ( builtins.sort builtins.lessThan targets ) ) }
                                                                                TARGET_HASH_OBSERVED="$( find "$MOUNT" -mindepth 1 -maxdepth 1 -exec basename {} \; | LC_ALL=C sort | tr --delete "\n" | sha512sum | cut --characters 1-128 )" || ${ failures_ "db2517b1" }
                                                                                if [[ "$STATUS" == 0 ]] && [[ ! -s "$STANDARD_ERROR_FILE" ]] && [[ "$TARGET_HASH_EXPECTED" == "$TARGET_HASH_OBSERVED" ]]
                                                                                then
                                                                                    NOHUP="$( temporary )" || ${ failures_ "605463b2" }
                                                                                    nohup good "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" > "$NOHUP" 2>&1
                                                                                    mkdir --parents ${ resources-directory }/canonical
                                                                                    ln --symbolic "$MOUNT" "${ resources-directory }/canonical/$HASH"
                                                                                    echo -n "$MOUNT"
                                                                                else
                                                                                    NOHUP="$( temporary )" || ${ failures_ "c56f63a4" }
                                                                                    echo setup | nohup bad "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" >> "$NOHUP" 2>&1 &
                                                                                    ${ failures_ "b385d889" }
                                                                                fi
                                                                            fi
                                                                        '' ;
                                                                stale =
                                                                    ''
                                                                        flock -s 211
                                                                        TYPE="$( basename "$0" )" || ${ failures_ "d2cc81ec" }
                                                                        jq \
                                                                            --null-input \
                                                                            --arg HASH "$HASH" \
                                                                            --arg TRANSIENT "$TRANSIENT" \
                                                                            --arg TOKEN ${ builtins.toString token-stale } \
                                                                            --arg TYPE "$TYPE" \
                                                                            '{
                                                                                "hash" : $HASH ,
                                                                                "token" : $TOKEN ,
                                                                                "type" : $TYPE
                                                                            }' | log
                                                                    '' ;
                                                                stall-for-cleanup =
                                                                    ''
                                                                        flock -s 211
                                                                        HEAD="$( stall-for-cleanup-head | tr --delete '[:space:]' )" || ${ failures_ "f9b0e418" }
                                                                        TYPE="$( basename "$0" )" || ${ failures_ "e4782f79" }
                                                                        jq \
                                                                            --null-input \
                                                                            --arg HASH "$HASH" \
                                                                            --arg HEAD "<$HEAD>" \
                                                                            --arg TOKEN ${ builtins.toString token-stall-for-cleanup } \
                                                                            --arg TYPE "$TYPE" \
                                                                                '{
                                                                                    "hash" : $HASH ,
                                                                                    "head" : $HEAD ,
                                                                                    "token" : $TOKEN ,
                                                                                    "type" : $TYPE
                                                                                }' | log
                                                                        NOHUP="$( temporary )" || ${ failures_ "c9e6586c" }
                                                                        if [[ -n "$HEAD" ]]
                                                                        then
                                                                            inotifywait --event move_self "$HEAD" --quiet
                                                                            nohup stall-for-cleanup > "$NOHUP" 2>&1 &
                                                                        fi
                                                                    '' ;
                                                                stall-for-cleanup-head =
                                                                    ''
                                                                        mkdir --parents ${ resources-directory }/links
                                                                        find ${ resources-directory }/links -mindepth 2 -maxdepth 2 -type l | while read -r CANDIDATE
                                                                        do
                                                                            RESOLVED="$( readlink --canonicalize "$CANDIDATE" )" || ${ failures_ "e9c39c16" }
                                                                            if [[ "$RESOLVED" == "$MOUNT" ]]
                                                                            then
                                                                                echo "$CANDIDATE"
                                                                                exit 0
                                                                            fi
                                                                        done | head --lines 1 | tr --delete '[:space:]'
                                                                    '' ;
                                                                stall-for-process =
                                                                    ''
                                                                        flock -s 211
                                                                        TYPE="$( basename "$0" )" || ${ failures_ "a3bc4273" }
                                                                        jq \
                                                                            --null-input \
                                                                            --arg HASH "$HASH" \
                                                                            --arg ORIGINATOR_PID "$ORIGINATOR_PID" \
                                                                            --arg TOKEN ${ builtins.toString token-stall-for-process } \
                                                                            --arg TYPE "$TYPE" \
                                                                                '{
                                                                                    "hash" : $HASH ,
                                                                                    "originator-pid" : $ORIGINATOR_PID ,
                                                                                    "token" : $TOKEN ,
                                                                                    "type" : $TYPE
                                                                                }' | log
                                                                        tail --follow /dev/null --pid "$ORIGINATOR_PID"
                                                                        NOHUP1="$( temporary )" || ${ failures_ "ee645658" }
                                                                        nohup stall-for-cleanup > "$NOHUP1" 2>&1 &
                                                                        NOHUP2="$( temporary )" || ${ failures_ "59978ab6" }
                                                                        nohup teardown > "$NOHUP2" 2>&1 &
                                                                    '' ;
                                                                teardown =
                                                                    ''
                                                                        exec 210> "${ resources-directory }/locks/$HASH"
                                                                        flock -x 210
                                                                        flock -s 211
                                                                        NOHUP="$( temporary )" || ${ failures_ "0d5ebafc" }
                                                                        if [[ -L "${ resources-directory }/canonical/$HASH" ]]
                                                                        then
                                                                            CANDIDATE="$( readlink "${ resources-directory }/canonical/$HASH" )" || ${ failures_ "cfb26c78" }
                                                                            if [[ "$MOUNT" == "$CANDIDATE" ]]
                                                                            then
                                                                                rm "${ resources-directory }/canonical/$HASH"
                                                                                nohup teardown-completed > "$NOHUP" 2>&1 &
                                                                            else
                                                                                export MODE="not-equals"
                                                                                nohup teardown-aborted > "$NOHUP" 2>&1 &
                                                                            fi
                                                                        else
                                                                            export MODE="no-symbolic-link"
                                                                            nohup teardown-aborted > "$NOHUP" 2>&1 &
                                                                        fi
                                                                    '' ;
                                                                teardown-aborted =
                                                                    ''
                                                                        flock -s 211
                                                                        TYPE="$( basename "$0" )" || ${ failures_ "f75c4adf" }
                                                                        jq \
                                                                            --null-input \
                                                                            --arg HASH "$HASH" \
                                                                            --arg MODE "$MODE" \
                                                                            --arg TOKEN ${ builtins.toString token-teardown-aborted } \
                                                                            --arg TYPE "$TYPE" \
                                                                            '{
                                                                                "hash" : $HASH ,
                                                                                "mode" : $MODE ,
                                                                                "token" : $TOKEN ,
                                                                                "type" : $TYPE
                                                                            }' | log
                                                                    '' ;
                                                                teardown-completed =
                                                                    if builtins.typeOf release == "null" then
                                                                        ''
                                                                            flock -s 211
                                                                            teardown-final
                                                                        ''
                                                                    else
                                                                        ''
                                                                            flock -s 211
                                                                            STANDARD_OUTPUT_FILE="$( temporary )" || ${ failures_ "a0721efc" }
                                                                            export STANDARD_OUTPUT_FILE
                                                                            STANDARD_ERROR_FILE="$( temporary )" || ${ failures_ "f78116ae" }
                                                                            export STANDARD_ERROR_FILE
                                                                            if ${ release-application }/bin/release-application > "$STANDARD_OUTPUT_FILE" 2> "$STANDARD_ERROR_FILE"
                                                                            then
                                                                                STATUS="$?"
                                                                            else
                                                                                STATUS="$?"
                                                                            fi
                                                                            export STATUS
                                                                            if [[ "$STATUS" == "0" ]] && [[ ! -s "$STANDARD_ERROR_FILE" ]]
                                                                            then
                                                                                teardown-final
                                                                            else
                                                                                echo teardown | bad
                                                                            fi
                                                                        '' ;
                                                                teardown-final =
                                                                    ''
                                                                        TYPE="$( basename "$0" )" || ${ failures_ "f2409776" }
                                                                        GOOD="$( temporary )" || ${ failures_ "b82279bb" }
                                                                        mkdir --parents "$GOOD"
                                                                        export HAS_STANDARD_INPUT=false
                                                                        export STANDARD_INPUT=
                                                                        ${ if builtins.typeOf init == "null" then "#" else ''trash "$LINK"'' }
                                                                        mv "$MOUNT" "$GOOD"
                                                                        jq \
                                                                            --null-input \
                                                                            --arg GOOD "$GOOD" \
                                                                            --arg HASH "$HASH" \
                                                                            --arg TOKEN ${ builtins.toString token-teardown-final } \
                                                                            --arg TYPE "$TYPE" \
                                                                            '{
                                                                                "good" : $GOOD ,
                                                                                "hash" : $HASH ,
                                                                                "token" : $TOKEN ,
                                                                                "type" : $TYPE
                                                                            }' | log
                                                                    '' ;
                                                                temporary =
                                                                    ''
                                                                        mkdir --parents ${ resources-directory }/temporary
                                                                        SEQUENCE="$( sequential )" || ${ failures_ "09d1282d" }
                                                                        echo "${ resources-directory }/temporary/$SEQUENCE"
                                                                    '' ;
                                                                trash =
                                                                    ''
                                                                        TRASH="$1"
                                                                        TEMPORARY="$( temporary )" || ${ failures_ "cd1cddbf" }
                                                                        mv "$TRASH" "$TEMPORARY"
                                                                    '' ;
                                                            } ;
                                                        in
                                                            ''
                                                                mkdir --parents $out/scripts
                                                                ${ builtins.concatStringsSep "\n" ( builtins.attrValues ( builtins.mapAttrs ( name : value : "makeWrapper ${ writeShellApplication { name = name ; text = value ; } }/bin/${ name } $out/bin/${ name } --set MAKE_WRAPPER ${ makeWrapper } --set OUT $out --set PATH $out/bin:${ makeBinPath [ coreutils findutils flock gawk jq ps yq-go ] }" ) scripts ) ) }
                                                            '' ;
                                                name = "derivation" ;
                                                nativeBuildInputs = [ coreutils makeWrapper ] ;
                                                src = ./. ;
                                            } ;
                                    transient_ =
                                        visitor.lib.implementation
                                            {
                                                bool = path : value : if value then ''"$( sequential )" || ${ failures_ "ea21ca9e" }'' else "" ;
                                            }
                                            transient ;
                                    in "${ derivation }/bin/setup" ;
                            in
                                {
                                    check = check ;
                                    implementation = implementation ;
                                } ;
			} ;
}
