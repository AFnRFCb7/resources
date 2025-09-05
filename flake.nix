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
                        transient ? false ,
                        visitor ,
                        yq-go ,
                        writeShellApplication
                    } @primary :
                        let
                            check =
                                {
                                    arguments ,
                                    bash ,
                                    commands ,
                                    diffutils ,
                                    fresh ,
                                    label ,
                                    mount ,
                                    order ,
                                    post ,
                                    stale ,
                                    stall ,
                                    standard-input  ,
                                    status
                                } :
                                    mkDerivation
                                        {
                                            installPhase =
                                                let
                                                    assert-validity =
                                                        writeShellApplication
                                                            {
                                                                name = "assert-validity" ;
                                                                runtimeInputs = [ coreutils diffutils fix yq-go ] ;
                                                                text =
                                                                    let
                                                                        censorship-expression =
                                                                            ''
                                                                                (.[] | select(has("init-application")) | .["init-application"]) = "../bin/init-application" |
                                                                                (.[] | select(has("release-application")) | .["release-application"]) = "../bin/release-application" |
                                                                                (.[] | select(has("transient")) | .["transient"]) = ""
                                                                            '' ;
                                                                        in
                                                                            ''
                                                                                EXPECTED="$1"
                                                                                OBSERVED="$2"
                                                                                CHECKPOINTS="$3"
                                                                                INDEX="$4"
                                                                                mkdir --parents "$CHECKPOINTS/$INDEX"
                                                                                yq eval --from-file '${ builtins.toFile "censorship-expression" censorship-expression }' "$OBSERVED" > "$CHECKPOINTS/$INDEX/log.observed.yaml"
                                                                                if [[ -f "$EXPECTED" ]]
                                                                                then
                                                                                    yq eval 'sort_by(.hash, .type)' < "$EXPECTED" > "$CHECKPOINTS/$INDEX/events.expected.yaml"
                                                                                fi
                                                                                yq eval 'sort_by(.hash, .type)' "$CHECKPOINTS/$INDEX/log.observed.yaml" > "$CHECKPOINTS/$INDEX/events.observed.yaml"
                                                                                if [[ ! -f "$CHECKPOINTS/$INDEX/events.expected.yaml" ]] || ! diff --unified "$CHECKPOINTS/$INDEX/events.expected.yaml" "$CHECKPOINTS/$INDEX/events.observed.yaml"
                                                                                then
                                                                                    cat ${ resources-directory }/debug
                                                                                    echo "${ label }:  We expected the events of the $INDEX generation to be identical to $CHECKPOINTS/$INDEX/events.expected.yaml but we got $CHECKPOINTS/$INDEX/events.observed.yaml"
                                                                                    echo
                                                                                    echo "$OUT/bin/fix $CHECKPOINTS/$INDEX expected/${ label }/$INDEX events.observed.yaml log.yaml"
                                                                                    echo
                                                                                fi
                                                                                ORDER_VIOLATIONS="$( ${ order } < "$OBSERVED" )" || ${ failures_ "ceb89766" }
                                                                                if [[ "$ORDER_VIOLATIONS" != 0 ]]
                                                                                then
                                                                                    echo "${ label }:  We detected $ORDER_VIOLATIONS order violations in the $INDEX generation"
                                                                                fi
                                                                            '' ;
                                                            } ;
                                                    catch-errors =
                                                        writeShellApplication
                                                            {
                                                                name = "catch-errors" ;
                                                                runtimeInputs = [ coreutils inotify-tools ] ;
                                                                text =
                                                                    ''
                                                                        FLAG_FILE="$1"
                                                                        ASSERTIONS_FILE="$2"
                                                                        inotifywait --event delete_self "$FLAG_FILE"
                                                                        if [[ -s "$ASSERTIONS_FILE" ]]
                                                                        then
                                                                            cat "$ASSERTIONS_FILE"
                                                                            ${ failures_ "a8d09093" }
                                                                        fi
                                                                    '' ;
                                                            } ;
                                                    cmmnds =
                                                        index :
                                                            let
                                                                i = builtins.toString ( index + 3 ) ;
                                                                command = builtins.elemAt commands index ;
                                                                c =
                                                                    writeShellApplication
                                                                        {
                                                                            name = "command" ;
                                                                            runtimeInputs = [ assert-validity coreutils ] ;
                                                                            text =
                                                                                ''
                                                                                    ${ command.command }
                                                                                    ${ stall }
                                                                                    assert-validity ${ command.checkpoint } ${ resources-directory }/logs/log.yaml "$OUT/checkpoints" ${ i }
                                                                                    rm ${ resources-directory }/logs/log.yaml
                                                                                '' ;
                                                                        } ;
                                                                in "${ c }/bin/command" ;
                                                    fix =
                                                        writeShellApplication
                                                            {
                                                                name = "fix" ;
                                                                runtimeInputs = [ coreutils ] ;
                                                                text =
                                                                    ''
                                                                        : "${ builtins.concatStringsSep "" [ "$" "{" "FIX_GIT_DIR:?FIX_GIT_DIR must be set" "}" ] }"
                                                                        : "${ builtins.concatStringsSep "" [ "$" "{" "FIX_GIT_WORK_TREE:?FIX_GIT_WORK_TREE must be set" "}" ] }"
                                                                        : "${ builtins.concatStringsSep "" [ "$" "{" "GIT:?GIT must be set" "}" ] }"
                                                                        INPUT_ABSOLUTE="$1"
                                                                        OUTPUT_RELATIVE="$2"
                                                                        OBSERVED="$3"
                                                                        EXPECTED="$4"
                                                                        export GIT_DIR="$FIX_GIT_DIR"
                                                                        export GIT_WORK_TREE="$FIX_GIT_WORK_TREE"
                                                                        OUTPUT_ABSOLUTE="$GIT_WORK_TREE/$OUTPUT_RELATIVE"
                                                                        "$GIT" commit -am "" --allow-empty --allow-empty-message
                                                                        if [[ -f "$OUTPUT_ABSOLUTE/$EXPECTED" ]]
                                                                        then
                                                                            "$GIT" rm "$OUTPUT_RELATIVE/$EXPECTED"
                                                                        fi
                                                                        OBSERVED_DIRECTORY="$( dirname "$OUTPUT_ABSOLUTE/$EXPECTED" )" || ${ failures_ "534f754e" }
                                                                        mkdir --parents "$OBSERVED_DIRECTORY"
                                                                        cp "$INPUT_ABSOLUTE/$OBSERVED" "$OUTPUT_ABSOLUTE/$EXPECTED"
                                                                        "$GIT" add "$OUTPUT_RELATIVE"
                                                                        "$GIT" commit -am "" --allow-empty --allow-empty-message
                                                                    '' ;
                                                            } ;
                                                    invoke-resource-fresh =
                                                        writeShellApplication
                                                            {
                                                                name = "invoke-resource-fresh" ;
                                                                runtimeInputs = [ assert-validity coreutils diffutils inotify-tools yq-go ] ;
                                                                text =
                                                                    ''
                                                                        mkdir --parents "$OUT/standard-error"
                                                                        if RESOURCE="$( ${ implementation } ${ builtins.concatStringsSep " " arguments } ${ if builtins.typeOf standard-input == "string" then "< ${ builtins.toFile "standard-input" standard-input }" else "" } 2> "$OUT/standard-error/1" )"
                                                                        then
                                                                            STATUS="$?"
                                                                        else
                                                                            STATUS="$?"
                                                                        fi
                                                                        if [[ "${ mount }" != "$RESOURCE" ]]
                                                                        then
                                                                            echo "${ label }:  We expected the result of fresh resource invocation 1 to be ${ mount } but it was $RESOURCE" >> "$OUT/assertions/invoke-resource-fresh"
                                                                        fi
                                                                        echo "$RESOURCE" > "$OUT/resource"
                                                                        echo "$STATUS" > "$OUT/status"
                                                                        if [[ -s "$OUT/standard-error/1" ]]
                                                                        then
                                                                            STANDARD_ERROR="$( < "$OUT/standard-error/1" )" || ${ failures_ "09e5d318" }
                                                                            echo "${ label }:  We expected 0th generation STANDARD_ERROR=$STANDARD_ERROR to be blank" >> "$OUT/assertions/invoke-resource-fresh"
                                                                        fi
                                                                        if [[ "${ builtins.toString status }" != "$STATUS" ]]
                                                                        then
                                                                            echo "${ label }:  We expected the 0th generation status to be ${ builtins.toString status } but it was $STATUS" >> "$OUT/assertions/invoke-resource-fresh"
                                                                        fi
                                                                        ${ stall }
                                                                        # echo assert-validity ${ fresh } ${ resources-directory }/logs/log.yaml "$OUT/checkpoints" 0 >> "$OUT/assertions/invoke-resource-fresh"
                                                                        rm ${ resources-directory }/logs/log.yaml
                                                                        rm "$OUT/flags/invoke-resource-fresh-start"
                                                                        inotifywait --event delete_self "$OUT/flags/invoke-resource-fresh-stop"
                                                                    '' ;
                                                            } ;
                                                    root =
                                                        writeShellApplication
                                                            {
                                                                name = "root" ;
                                                                runtimeInputs = [ assert-validity bash catch-errors coreutils findutils invoke-resource-fresh ] ;
                                                                text =
                                                                    ''
                                                                        echo "The check derivation is $OUT"
                                                                        if [[ -e ${ resources-directory } ]]
                                                                        then
                                                                            echo "${ label } : We were expecting the resources directory ${ resources-directory } to be initially non-existant" >&2
                                                                            ${ failures_ "a29ee37a" }
                                                                        fi
                                                                        mkdir --parents "$OUT/flags"
                                                                        touch "$OUT/flags/invoke-resource-fresh-start"
                                                                        touch "$OUT/flags/invoke-resource-fresh-stop"
                                                                        nohup invoke-resource-fresh "$OUT/flags/invoke-resource-fresh-start" "$OUT/flags/invoke-resource-fresh-stop" "$OUT/assertions/invoke-resource-fresh" >> "$OUT/nohup" 2>&1 &
                                                                        catch-errors "$OUT/flags/invoke-resource-fresh-start" "$OUT/assertions"
                                                                        rm "$OUT/flags/invoke-resource-fresh-stop"
                                                                        # ${ stall }
                                                                        # assert-validity ${ post } ${ resources-directory }/logs/log.yaml "$OUT/checkpoints" 2
                                                                        # ${ builtins.concatStringsSep "\n" ( builtins.genList cmmnds ( builtins.length commands ) ) }
                                                                        # MOUNT="$( find ${ resources-directory }/mounts -mindepth 1 -maxdepth 1 )" || ${ failures_ "b4210f0e" }
                                                                        # if [[ -n "$MOUNT" ]]
                                                                        # then
                                                                        #     echo "${ label } : We were expecting ${ resources-directory }/mounts to be empty but $MOUNT" >&2
                                                                        #     ${ failures_ "83f8df5c" }
                                                                        # fi
                                                                        # CANONICAL="$( find ${ resources-directory }/canonical -mindepth 1 -maxdepth 1 )" || ${ failures_ "b4210f0e" }
                                                                        # if [[ -n "$CANONICAL" ]]
                                                                        # then
                                                                        #     echo "${ label } : We were expecting ${ resources-directory }/canonical to be empty but $CANONICAL" >&2
                                                                        #     ${ failures_ "2531bccc" }
                                                                        # fi
                                                                        # if [[ -e ${ resources-directory }/debug ]]
                                                                        # then
                                                                        #     echo "${ label } : We were not expecting any debug" >&2
                                                                        #     cat ${ resources-directory }/debug
                                                                        #     ${ failures_ "a60eff59" }
                                                                        # fi
                                                                    '' ;
                                                            } ;
                                                    in
                                                        ''
                                                            mkdir --parents $out/bin
                                                            makeWrapper ${ root }/bin/root $out/bin/root --set OUT $out --set PATH $out
                                                            $out/bin/root
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
                                                                        makeWrapper "$RECOVERY_BIN" "$RECOVERY/recovery.sh" --set HASH "$HASH" --set MOUNT_INDEX "$MOUNT_INDEX"
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
                                                                            --arg STATUS "$STATUS" \
                                                                            --argjson TARGETS "$TARGETS" \
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
                                                                        cat | yq --prettyPrint "[.]" >> ${ resources-directory }/logs/log.yaml
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
                                                                            --arg TRANSIENT "$TRANSIENT" \
                                                                            --arg TYPE "$TYPE" \
                                                                            --null-input \
                                                                            '{
                                                                                "description" : "$DESCRIPTION" ,
                                                                                "hash" : $HASH ,
                                                                                "originator-pid" : $ORIGINATOR_PID ,
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
                                                                            --arg TYPE "$TYPE" \
                                                                            '{
                                                                                "arguments" : $ARGUMENTS ,
                                                                                "has-standard-input" : $HAS_STANDARD_INPUT ,
                                                                                "hash" : $HASH ,
                                                                                "standard-input" : $STANDARD_INPUT ,
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
                                                                                    echo "e0df3c7b-8344-4759-a1da-d8cd61ea06b4 before $HASH" >> ${ resources-directory }/debug
                                                                                    if ${ init-application }/bin/init-application "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" < "$STANDARD_INPUT_FILE" > "$STANDARD_OUTPUT_FILE" 2> "$STANDARD_ERROR_FILE"
                                                                                    then
                                                                                        STATUS="$?"
                                                                                    else
                                                                                        STATUS="$?"
                                                                                    fi
                                                                                    echo "03287d20-d3b7-45fa-955a-d9c7366257f7 after $HASH LINK=$LINK" >> ${ resources-directory }/debug
                                                                                    find ${ resources-directory }/links >> ${ resources-directory }/debug
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
                                                                                    nohup bad "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" >> "$NOHUP" 2>&1 &
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
                                                                            --arg TYPE "$TYPE" \
                                                                            '{
                                                                                "hash" : $HASH ,
                                                                                "type" : $TYPE
                                                                            }' | log
                                                                    '' ;
                                                                stall-for-cleanup =
                                                                    ''
                                                                        echo "3c814765-85d9-43fa-9cc7-1483c852f3c5" >> ${ resources-directory }/debug
                                                                        flock -s 211
                                                                        echo "ad6adcfb-c66f-4681-9232-6ef3e542924c" >> ${ resources-directory }/debug
                                                                        HEAD="$( stall-for-cleanup-head | tr --delete '[:space:]' )" || ${ failures_ "f9b0e418" }
                                                                        echo "734c9b22-3060-481f-9dd7-0581f14eeb1f" >> ${ resources-directory }/debug
                                                                        TYPE="$( basename "$0" )" || ${ failures_ "e4782f79" }
                                                                        echo "b52e7b52-ec84-421f-9666-99d66afa691a" >> ${ resources-directory }/debug
                                                                        jq \
                                                                            --null-input \
                                                                            --arg HASH "$HASH" \
                                                                            --arg HEAD "<$HEAD>" \
                                                                            --arg TYPE "$TYPE" \
                                                                                '{
                                                                                    "hash" : $HASH ,
                                                                                    "head" : $HEAD ,
                                                                                    "type" : $TYPE
                                                                                }' | log
                                                                        echo "86fb09f4-da90-4b57-a746-848097ff86a8" >> ${ resources-directory }/debug
                                                                        NOHUP="$( temporary )" || ${ failures_ "c9e6586c" }
                                                                        echo "4fcbb116-d97c-4d00-a8f0-a8ad51d2193f" >> ${ resources-directory }/debug
                                                                        if [[ -n "$HEAD" ]]
                                                                        then
                                                                            echo "b7c90bf6-a4bf-469d-aeb6-571d6f016477" >> ${ resources-directory }/debug
                                                                            inotifywait --event move_self "$HEAD" --quiet
                                                                            echo "0abeb703-5f06-4aa1-884d-24b23a3c3000" >> ${ resources-directory }/debug
                                                                            nohup stall-for-cleanup > "$NOHUP" 2>&1 &
                                                                            echo "42565823-129f-4893-b99e-dd2011ace44a" >> ${ resources-directory }/debug
                                                                        fi
                                                                    '' ;
                                                                stall-for-cleanup-head =
                                                                    ''
                                                                        echo "0193d31b-a994-4d75-bd7c-e39efd386a71" >> ${ resources-directory }/debug
                                                                        mkdir --parents ${ resources-directory }/links
                                                                        echo "aeef499a-34ab-4ed0-a394-fb9c6be00314 BEFORE FIND" >> ${ resources-directory }/debug
                                                                        find ${ resources-directory }/links >> ${ resources-directory }/debug
                                                                        find ${ resources-directory }/links -mindepth 2 -maxdepth 2 -type l | while read -r CANDIDATE
                                                                        do
                                                                            echo "115ef482-4b52-457d-9871-a7ebc0babb80" >> ${ resources-directory }/debug
                                                                            RESOLVED="$( readlink --canonicalize "$CANDIDATE" )" || ${ failures_ "e9c39c16" }
                                                                            echo "22ecbb2e-b3b3-4cb5-8291-39657e46bf64" >> ${ resources-directory }/debug
                                                                            if [[ "$RESOLVED" == "$MOUNT" ]]
                                                                            then
                                                                                echo "9422b363-4b62-4854-ac9f-37857aa51be8" >> ${ resources-directory }/debug
                                                                                echo "$CANDIDATE"
                                                                                echo "de68760e-6f73-44b3-ab48-36a9662152f0" >> ${ resources-directory }/debug
                                                                                exit 0
                                                                            fi
                                                                        echo "d18ce51a-4912-466b-a1bc-2a6d756f9d7d" >> ${ resources-directory }/debug
                                                                        done | head --lines 1 | tr --delete '[:space:]'
                                                                        echo "1e942cd8-8dcd-4ed3-a97d-7b0ec321c354" >> ${ resources-directory }/debug
                                                                    '' ;
                                                                stall-for-process =
                                                                    ''
                                                                        flock -s 211
                                                                        TYPE="$( basename "$0" )" || ${ failures_ "a3bc4273" }
                                                                        jq \
                                                                            --null-input \
                                                                            --arg HASH "$HASH" \
                                                                            --arg ORIGINATOR_PID "$ORIGINATOR_PID" \
                                                                            --arg TYPE "$TYPE" \
                                                                                '{
                                                                                    "hash" : $HASH ,
                                                                                    "originator-pid" : $ORIGINATOR_PID ,
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
                                                                            --arg TYPE "$TYPE" \
                                                                            '{
                                                                                "hash" : $HASH ,
                                                                                "mode" : $MODE ,
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
                                                                                bad
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
                                                                            --arg TYPE "$TYPE" \
                                                                            '{
                                                                                "good" : $GOOD ,
                                                                                "hash" : $HASH ,
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
