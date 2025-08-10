{
	inputs = { } ;
	outputs =
		{ self } :
			{
				lib.implementation =
					{
					    buildFHSUserEnv ,
					    coreutils ,
					    echo-error ? 102 ,
						error ? 64 ,
						exit-error ? 121 ,
						findutils ,
						flock ,
						gnutar ,
						hidden-error ? 249 ,
						init ? null ,
						initialization-error ? 175 ,
						jq ,
						inotify-tools ,
						length ? 64 ,
						path ? null ,
						release ? null ,
						resources-directory ,
						resource-error ? 251 ,
						seed ? null ,
						self ? "SELF" ,
						standard-error-error ? 253 ,
						standard-input-error ? 115 ,
						standard-output-error ? 197 ,
                        target-error ? 106 ,
						targets ? [ ] ,
						visitor ,
						writeShellApplication ,
						yq-go ,
						zstd
					} @primary :
						let
                            bad =
                                writeShellApplication
                                    {
                                        name = "bad" ;
                                        runtimeInputs = [ coreutils gnutar log zstd ] ;
                                        text =
                                            ''
                                                CREATION_TIME="$( stat --format "%W" "${ resources-directory }/mounts/$HASH" )" || exit ${ builtins.toString hidden-error }
                                                flock -u 202
                                                exec 202>&-
                                                HASH="$1"
                                                ORIGINATOR_PID="$2"
                                                STATUS="$3"
                                                STANDARD_OUTPUT="$4"
                                                STANDARD_ERROR="$5"
                                                GARBAGE="$( mktemp --dry-run --suffix ".tar.zst" )" || exit ${ builtins.toString hidden-error }
                                                nohup \
                                                    log \
                                                    "setup" \
                                                    "bad" \
                                                    "$HASH" \
                                                    "$ORIGINATOR_PID" \
                                                    "$STATUS" \
                                                    "$STANDARD_OUTPUT" \
                                                    "$STANDARD_ERROR" \
                                                    "$CREATION_TIME" \
                                                    "$GARBAGE" > /dev/null 2>&1 &
                                                tar --create --file - "${ resources-directory }/controls/$HASH" "${ resources-directory }/mounts/$HASH" | zstd -T1 -19 > "$GARBAGE"
                                                rm --recursive --force "${ resources-directory }/controls/$HASH" "${ resources-directory }/links/$HASH" "${ resources-directory }/mounts/$HASH"
                                            '' ;
                                    } ;
                            good =
                                writeShellApplication
                                    {
                                        name = "good" ;
                                        runtimeInputs = [ coreutils findutils flock inotify-tools log wait ] ;
                                        text =
                                            ''
                                                CREATION_TIME="$( stat --format "%W" "${ resources-directory }/mounts/$HASH" )" || exit ${ builtins.toString hidden-error }
                                                flock -u 202
                                                exec 202>&-
                                                HASH="$1"
                                                ORIGINATOR_PID="$2"
                                                STATUS="$3"
                                                STANDARD_OUTPUT="$4"
                                                STANDARD_ERROR="$5"
                                                nohup \
                                                    log \
                                                    "setup" \
                                                    "good" \
                                                    "$HASH" \
                                                    "$ORIGINATOR_PID" \
                                                    "$STATUS" \
                                                    "$STANDARD_OUTPUT" \
                                                    "$STANDARD_ERROR" \
                                                    "$CREATION_TIME" \
                                                    "" > /dev/null 2>&1 &
                                                wait "$ORIGINATOR_PID" "$HASH" "$CREATION_TIME"
                                            '' ;
                                    } ;
                            hash =
                                let
                                    seed =
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
                                    in builtins.hashString "sha512" ( builtins.toJSON seed ) ;
                            init-application =
                                if builtins.typeOf init == "null" then null
                                else
                                    buildFHSUserEnv
                                        {
                                            extraBwrapArgs =
                                                [
                                                    "--bind ${ resources-directory }/mounts/$HASH /mount"
                                                    "--bind ${ resources-directory }/links/$HASH /links"
                                                    "--ro-bind ${ resources-directory }/mounts ${ resources-directory }/mount"
                                                    "--tmpfs /scratch"
                                                ] ;
                                            name = "init-application" ;
                                            runScript = init ;
                                        } ;
                            log =
                                writeShellApplication
                                    {
                                        name = "log" ;
                                        runtimeInputs = [ coreutils flock jq yq-go ] ;
                                        text =
                                            ''
                                                flock -u 201
                                                exec 201>&-
                                                MODE="$1"
                                                TYPE="$2"
                                                HASH="$3"
                                                ORIGINATOR_PID="$4"
                                                STATUS="$5"
                                                STANDARD_OUTPUT_FILE="$6"
                                                STANDARD_ERROR_FILE="$7"
                                                CREATION_TIME="$8"
                                                GARBAGE="$9"
                                                TIMESTAMP="$( date +%s )"
                                                if [[ -z "$STANDARD_OUTPUT_FILE" ]]
                                                then
                                                    STANDARD_OUTPUT=""
                                                else
                                                    STANDARD_OUTPUT="$( cat "$STANDARD_OUTPUT_FILE" )"
                                                    rm "$STANDARD_OUTPUT_FILE"
                                                fi
                                                if [[ -z "$STANDARD_ERROR_FILE" ]]
                                                then
                                                    STANDARD_ERROR=""
                                                else
                                                    STANDARD_ERROR="$( cat "$STANDARD_ERROR_FILE" )"
                                                    rm "$STANDARD_ERROR_FILE"
                                                fi
                                                TEMP_FILE="$( mktemp )" || exit ${ builtins.toString hidden-error }
                                                jq \
                                                    --null-input \
                                                    --arg CREATION_TIME "$CREATION_TIME" \
                                                    --arg HASH "$HASH" \
                                                    --arg INIT_APPLICATION ${ if builtins.typeOf init-application == "null" then "null" else init-application } \
                                                    --arg GARBAGE "$GARBAGE" \
                                                    --arg MODE "$MODE" \
                                                    --arg ORIGINATOR_PID "$ORIGINATOR_PID" \
                                                    --arg RELEASE_APPLICATION ${ if builtins.typeOf release-application == "null" then "null" else release-application } \
                                                    --arg STANDARD_ERROR "$STANDARD_ERROR" \
                                                    --arg STANDARD_OUTPUT "$STANDARD_OUTPUT" \
                                                    --arg STATUS "$STATUS" \
                                                    --arg TIMESTAMP "$TIMESTAMP" \
                                                    --arg TYPE "$TYPE" \
                                                    '{ "creation-time" : $CREATION_TIME , "hash" : $HASH , "init-application" : $INIT_APPLICATION , "mode" : $MODE , "garbage": $GARBAGE , "originator-pid" : $ORIGINATOR_PID , path : ${ builtins.toJSON path } , "release-application" : $RELEASE_APPLICATION "standard-error" : $STANDARD_ERROR , "standard-output" : $STANDARD_OUTPUT , "status" : $STATUS , "timestamp" : $TIMESTAMP , "type" : $TYPE  }' | yq --prettyPrint "[.]" > "$TEMP_FILE"
                                                mkdir --parents "${ resources-directory }/logs"
                                                exec 203> "${ resources-directory }/logs/lock"
                                                flock -x 203
                                                cat "$TEMP_FILE" >> "${ resources-directory }/logs/log.yaml"
                                                flock -u 203
                                                exec 203>&-
                                                rm "$TEMP_FILE"
                                            '' ;
                                    } ;
                            no-init =
                                writeShellApplication
                                    {
                                        name = "null" ;
                                        runtimeInputs = [ coreutils flock log wait ] ;
                                        text =
                                            ''
                                                CREATION_TIME="$( stat --format "%W" "${ resources-directory }/$HASH/mount" )" || exit ${ builtins.toString hidden-error }
                                                flock -u 202
                                                exec 202>&-
                                                HASH="$1"
                                                ORIGINATOR_PID="$2"
                                                STATUS="$3"
                                                nohup \
                                                    log \
                                                    "setup" \
                                                    "null" \
                                                    "$HASH" \
                                                    "$ORIGINATOR_PID" \
                                                    "" \
                                                    "" \
                                                    "" )" \
                                                    "" \
                                                    "$CREATION_TIME" > /dev/null 2>&1 &
                                                wait "$ORIGINATOR_PID" "$HASH" "$CREATION_TIME"
                                            '' ;
                                    } ;
                            release-application =
                                if builtins.typeOf release == "null" then null
                                else
                                    buildFHSUserEnv
                                        {
                                            extraBwrapArgs =
                                                [
                                                    "--ro-bind ${ resources-directory }/mounts/$HASH /mount"
                                                    "--ro-bind ${ resources-directory }/mounts ${ resources-directory }/mounts"
                                                    "--tmpfs /scratch"
                                                ] ;
                                            name = "release-application" ;
                                            runScript = release ;
                                        } ;
                            setup =
                                writeShellApplication
                                    {
                                        name = "setup" ;
                                        runtimeInputs = [ bad coreutils findutils flock good init-application stale ] ;
                                        text =
                                            if builtins.typeOf init == "null" then
                                                ''
                                                    PARENT_0_PID="$$"
                                                    PARENT_1_PID=$( ps -p "$PARENT_0_PID" -o ppid= | xargs )
                                                    PARENT_2_PID=$( ps -p "$PARENT_1_PID" -o ppid= | xargs )
                                                    PARENT_3_PID=$( ps -p "$PARENT_2_PID" -o ppid= | xargs )
                                                    STANDARD_INPUT="$( mktemp )" || exit ${ builtins.toString standard-input-error }
                                                    if read -t 0
                                                    then
                                                        HAS_STANDARD_INPUT=true
                                                        timeout 1m cat > "$STANDARD_INPUT"
                                                        ORIGINATOR_PID="$PARENT_3_PID"
                                                    else
                                                        HAS_STANDARD_INPUT=false
                                                        ORIGINATOR_PID="$PARENT_2_PID"
                                                    fi
                                                    HASH="$( echo "${ hash } ${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[*]" "}" ] } $( cat "$STANDARD_INPUT" ) $HAS_STANDARD_INPUT" | sha512sum | cut --bytes -${ builtins.toString length } )" || exit ${ builtins.toString exit-error }
                                                    rm "$STANDARD_INPUT"
                                                    mkdir --parents "${ resources-directory }/controls/$HASH"
                                                    exec 201> "${ resources-directory }/controls/$HASH/teardown.lock"
                                                    flock -s 201
                                                    exec 202> "${ resources-directory }/controls/$HASH/setup.lock"
                                                    flock -x 202
                                                    if [[ -d "${ resources-directory }/mounts/$HASH" ]]
                                                    then
                                                        nohup stale "$HASH" "$ORIGINATOR_PID" > /dev/null 2>&1 &
                                                        flock -u 202
                                                        exec 202>&-
                                                        flock -u 201
                                                        exec 201>&-
                                                        echo -n "${ resources-directory }/mounts/$HASH"
                                                        exit 0
                                                    else
                                                        mkdir --parents "${ resources-directory }/mounts/$HASH
                                                        nohup no-init "$HASH" "$ORIGINATOR_PID" > /dev/null 2>&1 &
                                                        flock -u 202
                                                        exec 202>&-
                                                        flock -u 201
                                                        exec 201>&-
                                                        echo -n "${ resources-directory }/mount/$HASH"
                                                        exit 0
                                                    fi
                                                ''
                                            else
                                                ''
                                                    PARENT_0_PID="$$"
                                                    PARENT_1_PID=$( ps -p "$PARENT_0_PID" -o ppid= | xargs )
                                                    PARENT_2_PID=$( ps -p "$PARENT_1_PID" -o ppid= | xargs )
                                                    PARENT_3_PID=$( ps -p "$PARENT_2_PID" -o ppid= | xargs )
                                                    STANDARD_INPUT="$( mktemp )" || exit ${ builtins.toString standard-input-error }
                                                    if read -t 0
                                                    then
                                                        HAS_STANDARD_INPUT=true
                                                        timeout 1m cat > "$STANDARD_INPUT"
                                                        ORIGINATOR_PID="$PARENT_3_PID"
                                                    else
                                                        HAS_STANDARD_INPUT=false
                                                        ORIGINATOR_PID="$PARENT_2_PID"
                                                    fi
                                                    ARGUMENTS=( "$@" )
                                                    HASH="$( echo "${ hash } ${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[*]" "}" ] } $( cat "$STANDARD_INPUT" ) $HAS_STANDARD_INPUT" | sha512sum | cut --bytes -${ builtins.toString length } )" || exit ${ builtins.toString echo-error }
                                                    export HASH
                                                    mkdir --parents "${ resources-directory }/control/$HASH"
                                                    exec 201> "${ resources-directory }/control/$HASH/teardown.lock"
                                                    flock -s 201
                                                    exec 202> "${ resources-directory }/control/$HASH/setup.lock"
                                                    flock -x 202
                                                    if [[ -d "${ resources-directory }/mounts/$HASH" ]]
                                                    then
                                                        nohup stale "$HASH" "$ORIGINATOR_PID" > /dev/null 2>&1 &
                                                        flock -u 202
                                                        exec 202>&-
                                                        flock -u 201
                                                        exec 201>&-
                                                        rm "$STANDARD_INPUT"
                                                        echo -n "${ resources-directory }/mounts/$HASH"
                                                        exit 0
                                                    else
                                                        mkdir --parents "${ resources-directory }/mounts/$HASH"
                                                        mkdir --parents "${ resources-directory }/links/$HASH"
                                                        STANDARD_ERROR="$( mktemp )" || exit ${ builtins.toString standard-error-error }
                                                        STANDARD_OUTPUT="$( mktemp )" || exit ${ builtins.toString standard-output-error }
                                                    if "$HAS_STANDARD_INPUT"
                                                        then
                                                            if init-application "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" < "$STANDARD_INPUT" > "$STANDARD_OUTPUT" 2> "$STANDARD_ERROR"
                                                            then
                                                                STATUS="$?"
                                                                if [[ "$( find "${ resources-directory }/mounts/$HASH" -mindepth 1 -maxdepth 1 -exec basename {} \; | sort | sha512sum | cut --bytes -128 )" == ${ builtins.hashString "sha512" ( builtins.concatStringsSep "\n" ( builtins.sort builtins.naturalSort targets ) ) } ]]
                                                                then
                                                                    nohup good "$HASH" "$ORIGINATOR_PID" "$STATUS" "$STANDARD_OUTPUT" "$STANDARD_ERROR" > /dev/null 2>&1 &
                                                                    flock -u 202
                                                                    exec 202>&-
                                                                    flock -u 201
                                                                    exec 201>&-
                                                                    rm "$STANDARD_INPUT"
                                                                    echo -n "${ resources-directory }/$HASH/mount"
                                                                    exit 0
                                                                else
                                                                    nohup bad "$HASH" "$ORIGINATOR_PID" "$STATUS" "$STANDARD_OUTPUT" "$STANDARD_ERROR" > /dev/null 2>&1 &
                                                                    flock -u 202
                                                                    exec 202>&-
                                                                    flock -u 201
                                                                    exec 201>&-
                                                                    rm "$STANDARD_INPUT"
                                                                    exit ${ builtins.toString target-error }
                                                                fi
                                                            else
                                                                nohup bad "$HASH" "$ORIGINATOR_PID" "$?" "$STANDARD_OUTPUT" "$STANDARD_ERROR" > /dev/null 2>&1 &
                                                                flock -u 202
                                                                exec 202>&-
                                                                flock -u 201
                                                                exec 201>&-
                                                                rm "$STANDARD_INPUT"
                                                                exit ${ builtins.toString initialization-error }
                                                            fi
                                                        else
                                                            if init-application "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" > "$STANDARD_OUTPUT" 2> "$STANDARD_ERROR"
                                                            then
                                                                STATUS="$?"
                                                                if [[ "$( find "${ resources-directory }/mounts/$HASH" -mindepth 1 -maxdepth 1 -exec basename {} \; | sort | sha512sum | cut --bytes -128 )" == ${ builtins.hashString "sha512" ( builtins.concatStringsSep "\n" ( builtins.sort builtins.naturalSort targets ) ) } ]]
                                                                then
                                                                    nohup good "$HASH" "$ORIGINATOR_PID" "$STATUS" "$STANDARD_OUTPUT" "$STANDARD_ERROR" > /dev/null 2>&1 &
                                                                    flock -u 202
                                                                    exec 202>&-
                                                                    flock -u 201
                                                                    exec 201>&-
                                                                    rm "$STANDARD_INPUT"
                                                                    echo -n "${ resources-directory }/mounts/$HASH"
                                                                    exit 0
                                                                else
                                                                    nohup bad "$HASH" "$ORIGINATOR_PID" "$STATUS" "$STANDARD_OUTPUT" "$STANDARD_ERROR" > /dev/null 2>&1 &
                                                                    flock -u 202
                                                                    exec 202>&-
                                                                    flock -u 201
                                                                    exec 201>&-
                                                                    rm "$STANDARD_INPUT"
                                                                    exit ${ builtins.toString target-error }
                                                                fi
                                                            else
                                                                nohup bad "$HASH" "$ORIGINATOR_PID" "$?" "$STANDARD_OUTPUT" "$STANDARD_ERROR" > /dev/null 2>&1 &
                                                                flock -u 202
                                                                exec 202>&-
                                                                flock -u 201
                                                                exec 201>&-
                                                                rm "$STANDARD_INPUT"
                                                                exit ${ builtins.toString initialization-error }
                                                            fi
                                                        fi
                                                    fi
                                                '' ;
                                    } ;
                            stale =
                                writeShellApplication
                                    {
                                        name = "stale" ;
                                        runtimeInputs = [ coreutils flock log wait ] ;
                                        text =
                                            ''
                                                CREATION_TIME="$( stat --format "%W" "${ resources-directory }/$HASH/mount" )" || exit ${ builtins.toString hidden-error }
                                                flock -u 202
                                                exec 202>&-
                                                HASH="$1"
                                                ORIGINATOR_PID="$2"
                                                log \
                                                    "setup" \
                                                    "stale" \
                                                    "$HASH" \
                                                    "$ORIGINATOR_PID" \
                                                    "" \
                                                    "" \
                                                    "" \
                                                    "$CREATION_TIME" \
                                                    "" &
                                                wait "$ORIGINATOR_PID" "$HASH" "$CREATION_TIME"
                                            '' ;
                                    } ;
                            teardown =
                                writeShellApplication
                                    {
                                        name = "teardown" ;
                                        runtimeInputs = [ coreutils flock gnutar log zstd ] ;
                                        text =
                                            if builtins.typeOf release == "null" then
                                                ''
                                                    HASH="$1"
                                                    ORIGINATOR_PID="$2"
                                                    CREATION_TIME="$3"
                                                    if [[ ! -d "${ resources-directory }/$HASH/mount" ]] || [[ "$( stat --format "%W" "${ resources-directory }/$HASH/mount" )" != "$CREATION_TIME" ]]
                                                    then
                                                        log \
                                                            "teardown" \
                                                            "aborted" \
                                                            "$HASH" \
                                                            "$ORIGINATOR_PID" \
                                                            "" \
                                                            "" \
                                                            "" \
                                                            "$CREATION_TIME" \
                                                            "" &
                                                    else
                                                        exec 201> "${ resources-directory }/$HASH/teardown.lock"
                                                        flock -x 201
                                                        exec 202> "${ resources-directory }/$HASH/setup.lock"
                                                        flock -x 202
                                                        GARBAGE="$( mktemp --dry-run --suffix ".tar.zst" )"
                                                        tar --create --file - -C "${ resources-directory }" "control/$HASH" "mounts/$HASH" | zstd -T1 -19 > "$GARBAGE"
                                                        rm --recursive --force "${ resources-directory }/control/$HASH" "${ resources-directory }/links/$HASH" "${ resources-directory }/mounts/$HASH"
                                                        flock -u 202
                                                        exec 202>&-
                                                        flock -u 201
                                                        exec 201>&-
                                                        log \
                                                            "teardown" \
                                                            "active" \
                                                            "$HASH" \
                                                            "$ORIGINATOR_PID" \
                                                            "" \
                                                            "" \
                                                            "" \
                                                            "$CREATION_TIME" \
                                                            "$GARBAGE"
                                                    fi
                                                ''
                                            else
                                                ''
                                                    HASH="$1"
                                                    ORIGINATOR_PID="$2"
                                                    CREATION_TIME="$3"
                                                    if [[ ! -d "${ resources-directory }/$HASH/mount" ]] || [[ "$( stat --format "%W" "${ resources-directory }/$HASH/mount" )" != "$CREATION_TIME" ]]
                                                    then
                                                        log \
                                                            "teardown" \
                                                            "aborted" \
                                                            "$HASH" \
                                                            "$ORIGINATOR_PID" \
                                                            "" \
                                                            "" \
                                                            "$CREATION_TIME" \
                                                            ""
                                                    else
                                                        exec 201> "${ resources-directory }/$HASH/teardown.lock"
                                                        flock -x 201
                                                        exec 202> "${ resources-directory }/$HASH/setup.lock"
                                                        flock -x 202
                                                        export HASH
                                                        GARBAGE="$( mktemp --dry-run --suffix ".tar.zst" )"
                                                        STANDARD_INPUT="$( mktemp )" || exit ${ builtins.hidden-error }
                                                        STANDARD_ERROR="$( mktemp )" || exit ${ builtins.hidden-error }
                                                        if ${ release-application }/bin/release > "$STANDARD_OUTPUT" 2> "$STANDARD_ERROR"
                                                        then
                                                            STATUS="$?"
                                                        else
                                                            STATUS="$?"
                                                        fi
                                                        nohup \
                                                            log \
                                                            "teardown" \
                                                            "null" \
                                                            "$HASH" \
                                                            "$ORIGINATOR_PID" \
                                                            "" \
                                                            "$STANDARD_OUTPUT" \
                                                            "$STANDARD_ERROR" \
                                                            "$CREATION_TIME"
                                                            "$GARBAGE" > /dev/null 2>&1 &
                                                        tar --create --file - -C "${ resources-directory }" "$HASH" | zstd -T1 -19 > "$GARBAGE"
                                                        rm --recursive --force "${ resources-directory }/$HASH"
                                                        flock -u 202
                                                        exec 202>&-
                                                        flock -u 201
                                                        exec 201>&-
                                                    fi
                                                '' ;
                                    } ;
                            wait =
                                writeShellApplication
                                    {
                                        name = "wait" ;
                                        runtimeInputs = [ coreutils inotify-tools teardown ] ;
                                        text =
                                            ''
                                                ORIGINATOR_PID="$1"
                                                HASH="$2"
                                                CREATION_TIME="$3"
                                                tail --follow /dev/null --pid "$ORIGINATOR_PID"
                                                SYMLINK=-1
                                                while [[ -n "$SYMLINK" ]]
                                                do
                                                    SYMLINK="$( find ${ resources-directory }/links -type l 2>/dev/null | while read -r CANDIDATE
                                                        do
                                                            RESOLVED="$( readlink --canonicalize "$CANDIDATE" 2>/dev/null )"
                                                            TARGET="${resources-directory}/mounts/$HASH"
                                                            if [[ "$RESOLVED" == "$TARGET" ]]
                                                            then
                                                                echo "$CANDIDATE"
                                                            fi
                                                        done | head --lines 1 )"
                                                    if [[ -n "$SYMLINK" ]]
                                                    then
                                                        inotifywait --event delete_self "$SYMLINK" --quiet || true
                                                    fi
                                                done
                                                teardown "$HASH" "$ORIGINATOR_PID" "$CREATION_TIME"
                                            '' ;
                                    } ;
                            in setup ;
			} ;
}
