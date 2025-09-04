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
                                    delay ? 1 ,
                                    diffutils ,
                                    fresh ,
                                    label ,
                                    mount ,
                                    order ,
                                    post ,
                                    stale ,
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
                                                                    ''
                                                                        EXPECTED="$1"
                                                                        OBSERVED="$2"
                                                                        CHECKPOINTS="$3"
                                                                        INDEX="$4"
                                                                        mkdir --parents "$CHECKPOINTS/$INDEX"
                                                                        yq eval "$OBSERVED" > "$CHECKPOINTS/$INDEX/log.observed.yaml"
                                                                        yq eval 'sort_by(.hash, .type)' < "$EXPECTED" > "$CHECKPOINTS/$INDEX/events.expected.yaml"
                                                                        yq eval 'sort_by(.hash, .type)' < "$OBSERVED" > "$CHECKPOINTS/$INDEX/events.expected.yaml"
                                                                        if ! diff --unified "$CHECKPOINTS/$INDEX/events.expected.yaml" "$CHECKPOINTS/$INDEX/events.expected.yaml"
                                                                        then
                                                                            echo "We expected the events of the $INDEX generation to be identical to $CHECKPOINTS/$INDEX/events.expected.yaml but we got $CHECKPOINTS/$INDEX/events.expected.yaml" >&2
                                                                            echo >&2
                                                                            echo "$OUT/bin/fix $CHECKPOINTS/$INDEX/log.observed.yaml expected/${ label }/0/log.expected.yaml" >&2
                                                                            echo >&2
                                                                            ${ failures_ "9c47c5a4" }
                                                                        fi
                                                                        if ! ${ order } "$OBSERVED"
                                                                        then
                                                                            echo "We expected the $INDEX log to be well ordered but it was not" >&2
                                                                            ${ failures_ "1d338e3a" }
                                                                        fi
                                                                    '' ;
                                                            } ;
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
                                                                        export GIT_DIR="$FIX_GIT_DIR"
                                                                        export GIT_WORK_TREE="$FIX_GIT_WORK_TREE"
                                                                        OUTPUT_ABSOLUTE="$GIT_WORK_TREE/$OUTPUT_RELATIVE"
                                                                        if [[ -e "$OUTPUT_ABSOLUTE" ]]
                                                                        then
                                                                            "$GIT" rm "$OUTPUT_RELATIVE"
                                                                        fi
                                                                        OUTPUT_DIRECTORY="$( dirname "$OUTPUT_ABSOLUTE" )" || ${ failures_ "4bd0bc32" }
                                                                        mkdir --parents "$OUTPUT_DIRECTORY"
                                                                        cp "$INPUT_ABSOLUTE" "$OUTPUT_DIRECTORY"
                                                                        "$GIT" add "$OUTPUT_RELATIVE"
                                                                        "$GIT" commit -am "" --allow-empty --allow-empty-message
                                                                    '' ;
                                                            } ;
                                                    invoke-resource =
                                                        writeShellApplication
                                                            {
                                                                name = "invoke-resource" ;
                                                                runtimeInputs = [ assert-validity coreutils diffutils yq-go ] ;
                                                                text =
                                                                    ''
                                                                        STANDARD_ERROR=$OUT/standard-error
                                                                        mkdir --parents "$STANDARD_ERROR"
                                                                        if RESOURCE_1="$( ${ implementation } ${ builtins.concatStringsSep " " arguments } ${ if builtins.typeOf standard-input == "string" then "< ${ builtins.toFile "standard-input" standard-input }" else "" } 2> "$STANDARD_ERROR/1" )"
                                                                        then
                                                                            STATUS_1="$?"
                                                                        else
                                                                            STATUS_1="$?"
                                                                        fi
                                                                        if [[ "${ mount }" != "$RESOURCE_1" ]]
                                                                        then
                                                                            echo "We expected the result of resource invocation to be ${ mount } but it was $RESOURCE_1" >&2
                                                                            ${ failures_ "d84d4b61" }
                                                                        fi
                                                                        echo "$RESOURCE_1" > "$OUT/resource"
                                                                        echo "$STATUS_1" > "$OUT/status"
                                                                        if [[ -s "$STANDARD_ERROR/1" ]]
                                                                        then
                                                                            STANDARD_ERROR="$( < "$STANDARD_ERROR/1" )" || ${ failures_ "09e5d318" }
                                                                            echo "We expected STANDARD_ERROR=$STANDARD_ERROR to be blank" >&2
                                                                            ${ failures_ "ff88af1a" }
                                                                        fi
                                                                        if [[ "${ builtins.toString status }" != "$STATUS_1" ]]
                                                                        then
                                                                            echo "We expected the status to be ${ builtins.toString status } but it was $STATUS_1" >&2
                                                                            ${ failures_ "ce28a4e9" }
                                                                        fi
                                                                        sleep ${ builtins.toString delay }
                                                                        assert-validity ${ fresh } ${ resources-directory }/logs/log.yaml "$OUT/checkpoints" 0
                                                                        rm ${ resources-directory }/logs/log.yaml
                                                                    '' ;
                                                            } ;
                                                    root =
                                                        writeShellApplication
                                                            {
                                                                name = "root" ;
                                                                runtimeInputs = [ bash coreutils invoke-resource ] ;
                                                                text =
                                                                    ''
                                                                        echo "The check derivation is $OUT"
                                                                        if [[ -e ${ resources-directory } ]]
                                                                        then
                                                                            echo "${ label } : We were expecting the resources directory ${ resources-directory } to be initially non-existant" >&2
                                                                            ${ failures_ "a29ee37a" }
                                                                        fi
                                                                        bash invoke-resource
                                                                    '' ;
                                                            } ;
                                                    in
                                                        ''
                                                            mkdir --parents $out/bin
                                                            makeWrapper ${ fix }/bin/fix "$out/bin/fix" --set OUT $out
                                                            makeWrapper ${ invoke-resource }/bin/invoke-resource $out/bin/invoke-resource --set OUT $out
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
                                                                        flock -s 211
                                                                        HEAD="$( stall-for-cleanup-head | tr --delete '[:space:]' )" || ${ failures_ "f9b0e418" }
                                                                        TYPE="$( basename "$0" )" || ${ failures_ "e4782f79" }
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
                                                                        NOHUP="$( temporary )" || ${ failures_ "c9e6586c" }
                                                                        if [[ -n "$HEAD" ]]
                                                                        then
                                                                            inotifywait --event move_self "$HEAD" --quiet
                                                                            nohup stall-for-cleanup > "$NOHUP" 2>&1 &
                                                                        else
                                                                            nohup teardown > "$NOHUP" 2>&1 &
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
                                                                        if [[ -L "${ resources-directory }/canonical/$HASH" ]]
                                                                        then
                                                                            CANDIDATE="$( readlink "${ resources-directory }/canonical/$HASH" )" || ${ failures_ "cfb26c78" }
                                                                            NOHUP="$( temporary )" || ${ failures_ "0d5ebafc" }
                                                                            if [[ "$MOUNT" == "$CANDIDATE" ]]
                                                                            then
                                                                                rm "${ resources-directory }/canonical/$HASH"
                                                                                nohup teardown-completed > "$NOHUP" 2>&1 &
                                                                            else
                                                                                nohup teardown-aborted > "$NOHUP" 2>&1 &
                                                                            fi
                                                                        else
                                                                            teardown-aborted
                                                                        fi
                                                                    '' ;
                                                                teardown-aborted =
                                                                    ''
                                                                        flock -s 211
                                                                        TYPE="$( basename "$0" )" || ${ failures_ "f75c4adf" }
                                                                        jq \
                                                                            --null-input \
                                                                            --arg HASH "$HASH" \
                                                                            --arg TYPE "$TYPE" \
                                                                            '{
                                                                                "hash" : $HASH ,
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
