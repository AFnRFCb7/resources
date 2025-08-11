{
	inputs = { } ;
	outputs =
		{ self } :
			{
				lib.implementation =
					{
					    buildFHSUserEnv ,
					    description ? null ,
					    coreutils ,
					    echo-error ? 102 ,
						exit-error ? 121 ,
						findutils ,
						flock ,
						hash-error ? 172 ,
						hidden-error ? 249 ,
						init ? null ,
						initialization-error ? 175 ,
						jq ,
						inotify-tools ,
						length ? 64 ,
						release ? null ,
						resources-directory ,
						resource-error ? 251 ,
						seed ? null ,
						self ? "SELF" ,
						standard-error-error ? 253 ,
						standard-error-not-empty-error ? 132 ,
						standard-input-cat-error ? 115 ,
						standard-input-temporary-error ? 123 ,
						standard-output-error ? 197 ,
                        target-error ? 106 ,
						targets ? [ ] ,
						timestamp-error ? 139 ,
						visitor ,
						writeShellApplication ,
						yq-go
					} @primary :
						let
                            bad =
                                writeShellApplication
                                    {
                                        name = "bad" ;
                                        runtimeInputs = [ coreutils log temporary ] ;
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
                                                NOHUP="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                nohup \
                                                    log \
                                                    "setup" \
                                                    "bad" \
                                                    "$HASH" \
                                                    "$ORIGINATOR_PID" \
                                                    "$STATUS" \
                                                    "$STANDARD_OUTPUT" \
                                                    "$STANDARD_ERROR" \
                                                    "$CREATION_TIME" > "$NOHUP" 2>&1 &
                                                mkdir --parents ${ resources-directory }/bad
                                                BAD="$( mktemp --directory ${ resources-directory }/bad/XXXXXXXX )" || exit ${ builtins.toString hidden-error }
                                                if [[ -d "${ resources-directory }/links/$HASH" ]]
                                                then
                                                    cp --recursive "${ resources-directory }/links/$HASH" "$BAD/links"
                                                fi
                                                mv "${ resources-directory }/controls/$HASH" "$BAD/controls"
                                                if [[ -e "${ resources-directory }/mounts/$HASH" ]]
                                                then
                                                    mv "${ resources-directory }/mounts/$HASH" "$BAD/mounts"
                                                fi
                                                rm --recursive --force "${ resources-directory }/links/$HASH"
                                            '' ;
                                    } ;
                            good =
                                writeShellApplication
                                    {
                                        name = "good" ;
                                        runtimeInputs = [ coreutils findutils flock inotify-tools log stall ] ;
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
                                                NOHUP="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                nohup \
                                                    log \
                                                    "setup" \
                                                    "good" \
                                                    "$HASH" \
                                                    "$ORIGINATOR_PID" \
                                                    "$STATUS" \
                                                    "$STANDARD_OUTPUT" \
                                                    "$STANDARD_ERROR" \
                                                    "$CREATION_TIME" > "$NOHUP" 2>&1 &
                                                stall "$ORIGINATOR_PID" "$HASH" "$CREATION_TIME"
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
                                                    "--tmpfs /scratch"
                                                ] ;
                                            name = "init-application" ;
                                            runScript = init "${ resources-directory }/mounts/$HASH" ;
                                        } ;
                            log =
                                writeShellApplication
                                    {
                                        name = "log" ;
                                        runtimeInputs = [ coreutils flock jq temporary yq-go ] ;
                                        text =
                                            let
                                                description_ =
                                                    visitor.lib.implementation
                                                        {
                                                            lambda = path : value : value seed ;
                                                            null = path : value : "" ;
                                                            string = path : value : value ;
                                                        }
                                                        description ;
                                                in
                                                    ''
                                                        MODE="$1"
                                                        TYPE="$2"
                                                        HASH="$3"
                                                        ORIGINATOR_PID="$4"
                                                        STATUS="$5"
                                                        STANDARD_OUTPUT_FILE="$6"
                                                        STANDARD_ERROR_FILE="$7"
                                                        CREATION_TIME="$8"
                                                        TIMESTAMP="$( date +%s )" || exit ${ builtins.toString timestamp-error }
                                                        if [[ -n "$STANDARD_OUTPUT_FILE" ]] && [[ -f "$STANDARD_OUTPUT_FILE" ]]
                                                        then
                                                            STANDARD_OUTPUT="$( cat "$STANDARD_OUTPUT_FILE" )" || exit ${ builtins.toString hidden-error }
                                                            rm "$STANDARD_OUTPUT_FILE"
                                                        else
                                                            STANDARD_OUTPUT=""
                                                        fi
                                                        if [[ -n "$STANDARD_ERROR_FILE" ]] && [[ -f "$STANDARD_ERROR_FILE" ]]
                                                        then
                                                            STANDARD_ERROR="$( cat "$STANDARD_ERROR_FILE" )" || exit ${ builtins.toString hidden-error }
                                                            rm "$STANDARD_ERROR_FILE"
                                                        else
                                                            STANDARD_ERROR=""
                                                        fi
                                                        TEMP_FILE="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                        jq \
                                                            --null-input \
                                                            --arg CREATION_TIME "$CREATION_TIME" \
                                                            --arg DESCRIPTION "${ description_ }" \
                                                            --arg HASH "$HASH" \
                                                            --arg INIT_APPLICATION ${ if builtins.typeOf init-application == "null" then "null" else init-application } \
                                                            --arg MODE "$MODE" \
                                                            --arg ORIGINATOR_PID "$ORIGINATOR_PID" \
                                                            --arg RELEASE_APPLICATION ${ if builtins.typeOf release-application == "null" then "null" else release-application } \
                                                            --arg STANDARD_ERROR "$STANDARD_ERROR" \
                                                            --arg STANDARD_OUTPUT "$STANDARD_OUTPUT" \
                                                            --arg STATUS "$STATUS" \
                                                            --arg TIMESTAMP "$TIMESTAMP" \
                                                            --arg TYPE "$TYPE" \
                                                            '{ "creation-time" : $CREATION_TIME , "description" : $DESCRIPTION , "hash" : $HASH , "init-application" : $INIT_APPLICATION , "mode" : $MODE , "originator-pid" : $ORIGINATOR_PID , "release-application" : $RELEASE_APPLICATION , "standard-error" : $STANDARD_ERROR , "standard-output" : $STANDARD_OUTPUT , "status" : $STATUS , "timestamp" : $TIMESTAMP , "type" : $TYPE  }' | yq --prettyPrint "[.]" > "$TEMP_FILE"
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
                                        runtimeInputs = [ coreutils flock log stall ] ;
                                        text =
                                            ''
                                                CREATION_TIME="$( stat --format "%W" "${ resources-directory }/mounts/$HASH" )" || exit ${ builtins.toString hidden-error }
                                                flock -u 202
                                                exec 202>&-
                                                HASH="$1"
                                                ORIGINATOR_PID="$2"
                                                STATUS="$3"
                                                NOHUP="$( temporary )" || exit ${ builtins.toString hidden-error }
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
                                                    "$CREATION_TIME" > "$NOHUP" 2>&1 &
                                                stall "$ORIGINATOR_PID" "$HASH" "$CREATION_TIME"
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
                                        runtimeInputs = [ bad coreutils findutils flock good init-application stale temporary ] ;
                                        text =
                                            if builtins.typeOf init == "null" then
                                                ''
                                                    PARENT_0_PID="$$"
                                                    PARENT_1_PID=$( ps -p "$PARENT_0_PID" -o ppid= | xargs )
                                                    PARENT_2_PID=$( ps -p "$PARENT_1_PID" -o ppid= | xargs )
                                                    PARENT_3_PID=$( ps -p "$PARENT_2_PID" -o ppid= | xargs )
                                                    if read -t 0
                                                    then
                                                        STANDARD_INPUT_FILE="$( temporary )" || exit ${ builtins.toString standard-input-temporary-error }
                                                        HAS_STANDARD_INPUT=true
                                                        timeout 1m cat > "$STANDARD_INPUT_FILE"
                                                        STANDARD_INPUT="$( cat "$STANDARD_INPUT_FILE" )" || exit ${ builtins.toString standard-input-cat-error }
                                                        rm "$STANDARD_INPUT_FILE"
                                                        ORIGINATOR_PID="$PARENT_3_PID"
                                                    else
                                                        HAS_STANDARD_INPUT=false
                                                        STANDARD_INPUT=
                                                        ORIGINATOR_PID="$PARENT_2_PID"
                                                    fi
                                                    HASH="$( echo "${ hash } ${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[*]" "}" ] } $STANDARD_INPUT $HAS_STANDARD_INPUT" | sha512sum | cut --bytes -${ builtins.toString length } )" || exit ${ builtins.toString hash-error }
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
                                                        mkdir --parents "${ resources-directory }/mounts/$HASH"
                                                        nohup no-init "$HASH" "$ORIGINATOR_PID" > /dev/null 2>&1 &
                                                        flock -u 202
                                                        exec 202>&-
                                                        flock -u 201
                                                        exec 201>&-
                                                        echo -n "${ resources-directory }/mounts/$HASH"
                                                        exit 0
                                                    fi
                                                ''
                                            else
                                                ''
                                                    PARENT_0_PID="$$"
                                                    PARENT_1_PID=$( ps -p "$PARENT_0_PID" -o ppid= | xargs )
                                                    PARENT_2_PID=$( ps -p "$PARENT_1_PID" -o ppid= | xargs )
                                                    PARENT_3_PID=$( ps -p "$PARENT_2_PID" -o ppid= | xargs )
                                                    if read -t 0
                                                    then
                                                        STANDARD_INPUT_FILE="$( temporary )" || exit ${ builtins.toString standard-input-temporary-error }
                                                        HAS_STANDARD_INPUT=true
                                                        timeout 1m cat > "$STANDARD_INPUT_FILE"
                                                        STANDARD_INPUT="$( cat "$STANDARD_INPUT_FILE" )" || exit ${ builtins.toString standard-input-cat-error }
                                                        rm "$STANDARD_INPUT_FILE"
                                                        ORIGINATOR_PID="$PARENT_3_PID"
                                                    else
                                                        HAS_STANDARD_INPUT=false
                                                        STANDARD_INPUT=
                                                        ORIGINATOR_PID="$PARENT_2_PID"
                                                    fi
                                                    ARGUMENTS=( "$@" )
                                                    HASH="$( echo "${ hash } ${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[*]" "}" ] } $STANDARD_INPUT $HAS_STANDARD_INPUT" | sha512sum | cut --bytes -${ builtins.trace ( builtins.toString length ) ( builtins.toString length ) } )" || exit ${ builtins.toString hash-error }
                                                    export HASH
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
                                                        mkdir --parents "${ resources-directory }/mounts/$HASH"
                                                        mkdir --parents "${ resources-directory }/links/$HASH"
                                                        STANDARD_ERROR="$( temporary )" || exit ${ builtins.toString standard-error-error }
                                                        STANDARD_OUTPUT="$( temporary )" || exit ${ builtins.toString standard-output-error }
                                                        if "$HAS_STANDARD_INPUT"
                                                        then
                                                            if init-application "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" < "$STANDARD_INPUT" > "$STANDARD_OUTPUT" 2> "$STANDARD_ERROR"
                                                            then
                                                                STATUS="$?"
                                                                if [[ "$( find "${ resources-directory }/mounts/$HASH" -mindepth 1 -maxdepth 1 -exec basename {} \; | LC_ALL=C sort | tr --delete "\n" | sha512sum | cut --bytes -128 )" != ${ builtins.hashString "sha512" ( builtins.concatStringsSep "" ( builtins.sort builtins.lessThan targets ) ) } ]]
                                                                then
                                                                    nohup bad "$HASH" "$ORIGINATOR_PID" "$STATUS" "$STANDARD_OUTPUT" "$STANDARD_ERROR" > /dev/null 2>&1 &
                                                                    flock -u 202
                                                                    exec 202>&-
                                                                    flock -u 201
                                                                    exec 201>&-
                                                                    exit ${ builtins.toString target-error }
                                                                elif [[ -s "$STANDARD_ERROR" ]]
                                                                then
                                                                    nohup bad "$HASH" "$ORIGINATOR_PID" "$STATUS" "$STANDARD_OUTPUT" "$STANDARD_ERROR" > /dev/null 2>&1 &
                                                                    flock -u 202
                                                                    exec 202>&-
                                                                    flock -u 201
                                                                    exec 201>&-
                                                                    exit ${ builtins.toString standard-error-not-empty-error }
                                                                else
                                                                    nohup good "$HASH" "$ORIGINATOR_PID" "$STATUS" "$STANDARD_OUTPUT" "$STANDARD_ERROR" > /dev/null 2>&1 &
                                                                    flock -u 202
                                                                    exec 202>&-
                                                                    flock -u 201
                                                                    exec 201>&-
                                                                    echo -n "${ resources-directory }/$HASH/mounts"
                                                                    exit 0
                                                                fi
                                                            else
                                                                nohup bad "$HASH" "$ORIGINATOR_PID" "$?" "$STANDARD_OUTPUT" "$STANDARD_ERROR" > /dev/null 2>&1 &
                                                                flock -u 202
                                                                exec 202>&-
                                                                flock -u 201
                                                                exec 201>&-
                                                                exit ${ builtins.toString initialization-error }
                                                            fi
                                                        else
                                                            if init-application "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" > "$STANDARD_OUTPUT" 2> "$STANDARD_ERROR"
                                                            then
                                                                STATUS="$?"
                                                                if [[ "$( find "${ resources-directory }/mounts/$HASH" -mindepth 1 -maxdepth 1 -exec basename {} \; | LC_ALL=C sort | tr --delete "\n" | sha512sum | cut --bytes -128 )" != ${ builtins.hashString "sha512" ( builtins.concatStringsSep "" ( builtins.sort builtins.lessThan targets ) ) } ]]
                                                                then
                                                                    nohup bad "$HASH" "$ORIGINATOR_PID" "$STATUS" "$STANDARD_OUTPUT" "$STANDARD_ERROR" > /dev/null 2>&1 &
                                                                    flock -u 202
                                                                    exec 202>&-
                                                                    flock -u 201
                                                                    exec 201>&-
                                                                    exit ${ builtins.toString target-error }
                                                                elif [[ -s "$STANDARD_ERROR" ]]
                                                                then
                                                                    nohup bad "$HASH" "$ORIGINATOR_PID" "$STATUS" "$STANDARD_OUTPUT" "$STANDARD_ERROR" > /dev/null 2>&1 &
                                                                    flock -u 202
                                                                    exec 202>&-
                                                                    flock -u 201
                                                                    exec 201>&-
                                                                    exit ${ builtins.toString standard-error-not-empty-error }
                                                                else
                                                                    nohup good "$HASH" "$ORIGINATOR_PID" "$STATUS" "$STANDARD_OUTPUT" "$STANDARD_ERROR" > /dev/null 2>&1 &
                                                                    flock -u 202
                                                                    exec 202>&-
                                                                    flock -u 201
                                                                    exec 201>&-
                                                                    echo -n "${ resources-directory }/mounts/$HASH"
                                                                    exit 0
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
                                        runtimeInputs = [ coreutils flock log stall ] ;
                                        text =
                                            ''
                                                CREATION_TIME="$( stat --format "%W" "${ resources-directory }/mounts/$HASH" )" || exit ${ builtins.toString hidden-error }
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
                                                    "$CREATION_TIME" &
                                                stall "$ORIGINATOR_PID" "$HASH" "$CREATION_TIME"
                                            '' ;
                                    } ;
                            teardown =
                                writeShellApplication
                                    {
                                        name = "teardown" ;
                                        runtimeInputs = [ coreutils flock log temporary ] ;
                                        text =
                                            if builtins.typeOf release == "null" then
                                                ''
                                                    HASH="$1"
                                                    ORIGINATOR_PID="$2"
                                                    CREATION_TIME="$3"
                                                    if [[ ! -d "${ resources-directory }/mounts/$HASH" ]] || [[ "$( stat --format "%W" "${ resources-directory }/mounts/$HASH" )" != "$CREATION_TIME" ]]
                                                    then
                                                        log \
                                                            "teardown" \
                                                            "aborted" \
                                                            "$HASH" \
                                                            "$ORIGINATOR_PID" \
                                                            "" \
                                                            "" \
                                                            "" \
                                                            "$CREATION_TIME" &
                                                    else
                                                        exec 201> "${ resources-directory }/controls/$HASH/teardown.lock"
                                                        flock -x 201
                                                        exec 202> "${ resources-directory }/controls/$HASH/setup.lock"
                                                        flock -x 202
                                                        GARBAGE="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                        mkdir --parents "$GARBAGE"
                                                        mv "${ resources-directory }/controls/$HASH" "$GARBAGE/controls"
                                                        if [[ -e "${ resources-directory }/links/$HASH" ]]
                                                        then
                                                            mv "${ resources-directory }/links/$HASH" "$GARBAGE/links"
                                                        fi
                                                        if [[ -e "${ resources-directory }/mounts/$HASH" ]]
                                                        then
                                                            mv "${ resources-directory }/mounts/$HASH" "$GARBAGE/mounts"
                                                        fi
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
                                                            "$CREATION_TIME"
                                                    fi
                                                ''
                                            else
                                                ''
                                                    HASH="$1"
                                                    ORIGINATOR_PID="$2"
                                                    CREATION_TIME="$3"
                                                    if [[ ! -d "${ resources-directory }/mounts/$HASH" ]] || [[ "$( stat --format "%W" "${ resources-directory }/mounts/$HASH" )" != "$CREATION_TIME" ]]
                                                    then
                                                        log \
                                                            "teardown" \
                                                            "aborted" \
                                                            "$HASH" \
                                                            "$ORIGINATOR_PID" \
                                                            "" \
                                                            "" \
                                                            "$CREATION_TIME"
                                                    else
                                                        exec 201> "${ resources-directory }/$HASH/teardown.lock"
                                                        flock -x 201
                                                        exec 202> "${ resources-directory }/$HASH/setup.lock"
                                                        flock -x 202
                                                        export HASH
                                                        STANDARD_INPUT="$( temporary )" || exit ${ builtins.hidden-error }
                                                        STANDARD_ERROR="$( temporary )" || exit ${ builtins.hidden-error }
                                                        if ${ release-application }/bin/release > "$STANDARD_OUTPUT" 2> "$STANDARD_ERROR" && [[ ! -s "$STANDARD_ERROR" ]]
                                                        then
                                                            GOOD="$( temporary )" || exit ${ builtins.hidden-error }
                                                            mkdir --parents "$GOOD"
                                                            mv "${ resources-directory }/controls/$HASH" "$GOOD/controls"
                                                            if [[ -e "${ resources-directory }/links/$HASH" ]]
                                                            then
                                                                mv "${ resources-directory }/links/$HASH" "$GOOD/links"
                                                            fi
                                                            if [[ -e "${ resources-directory }/mounts/$HASH" ]]
                                                            then
                                                                mv "${ resources-directory }/mounts/$HASH" "$GOOD/mounts"
                                                            fi
                                                            log \
                                                                "teardown" \
                                                                "aborted" \
                                                                "$HASH" \
                                                                "$ORIGINATOR_PID" \
                                                                "" \
                                                                "" \
                                                                "$CREATION_TIME"
                                                        else
                                                            nohup bad "$HASH" "$ORIGINATOR_PID" "$?" "$STANDARD_OUTPUT" "$STANDARD_ERROR" > /dev/null 2>&1 &
                                                            flock -u 202
                                                            exec 202>&-
                                                            flock -u 201
                                                            exec 201>&-
                                                        fi
                                                    fi
                                                '' ;
                                    } ;
                            stall =
                                writeShellApplication
                                    {
                                        name = "stall" ;
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
                                                    SYMLINK="$( find ${ resources-directory }/links ${ resources-directory }/bad/*/links -mindepth 1 -maxdepth 1 -type l 2>/dev/null | while read -r CANDIDATE
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
                            temporary =
                                writeShellApplication
                                    {
                                        name = "temporary" ;
                                        runtimeInputs = [ coreutils ] ;
                                        text =
                                            ''
                                                mkdir --parents ${ resources-directory }/temporary
                                                mktemp --dry-run ${ resources-directory }/temporary/XXXXXXXX
                                            '' ;
                                    } ;
                            in "${ setup }/bin/setup" ;
			} ;
}
