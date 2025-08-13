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
						remediation-bad-error ? 194 ,
						remediation-create-time-error ? 254 ,
						remediation-good-error ? 101 ,
						remediation-hash-error ? 112 ,
						remediation-resolution-error ? 242 ,
						remediation-timestamp-error ? 179 ,
						remediation-type-error ? 253 ,
						remediation-temporary-error ? 166 ,
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
                                        runtimeInputs = [ coreutils findutils jq log temporary yq-go ] ;
                                        text =
                                            let
                                                logs =
                                                    writeShellApplication
                                                        {
                                                            name = "logs" ;
                                                            runtimeInputs = [ coreutils flock yq-go ] ;
                                                            text =
                                                                ''
                                                                    BAD="$( dirname "$0" )" || exit ${ builtins.toString remediation-bad-error }
                                                                    CREATION_TIME="$( < "$BAD/creation-time.asc" )" || exit ${ builtins.toString remediation-create-time-error }
                                                                    export CREATION_TIME
                                                                    export DESCRIPTION="${ description_ }"
                                                                    HASH="$( < "$BAD/hash.asc" )" || exit ${ builtins.toString remediation-hash-error }
                                                                    export HASH
                                                                    mkdir --parents ${ resources-directory }/logs
                                                                    exec 203> ${ resources-directory }/logs/lock
                                                                    flock -s 203
                                                                    yq eval '{
                                                                      "expected": {
                                                                        "creation-time" : strenv(CREATION_TIME) ,
                                                                        "description" : strenv(DESCRIPTION) ,
                                                                        "hash" : strenv(HASH) ,
                                                                        "seed" : ${ builtins.toJSON seed } ,
                                                                        "targets": ${ builtins.toJSON targets }
                                                                      },
                                                                      "observed": [
                                                                        .[] | select(.["creation-time"] == strenv(CREATION_TIME) and .hash == strenv(HASH))
                                                                      ]
                                                                    }' "${resources-directory}/logs/log.yaml" | yq eval '.expected.targets |= to_entries | .expected.targets[] |= .value'

                                                                '' ;
                                                        } ;
                                                resolve =
                                                    writeShellApplication
                                                        {
                                                            name = "resolve" ;
                                                            runtimeInputs = [ coreutils jq log temporary yq-go ] ;
                                                            text =
                                                                ''
                                                                    BAD="$( dirname "$0" )" || exit ${ builtins.toString remediation-bad-error }
                                                                    CREATION_TIME="$( < "$BAD/creation-time.asc" )" || exit ${ builtins.toString remediation-create-time-error }
                                                                    HASH="$( < "$BAD/hash.asc" )" || exit ${ builtins.toString remediation-hash-error }
                                                                    GOOD="$( temporary )" || exit ${ builtins.toString remediation-good-error }
                                                                    mv "$BAD" "$GOOD"
                                                                    if read -t 0
                                                                    then
                                                                        RESOLUTION="$( cat )" || exit ${ builtins.toString remediation-resolution-error }
                                                                    else
                                                                        RESOLUTION="${ builtins.concatStringsSep "" [ "$" "{" "*" "}" ] }"
                                                                    fi
                                                                    TIMESTAMP="$( date +%s )" || exit ${ builtins.toString remediation-timestamp-error }
                                                                    TYPE="$( basename "$0" )" || exit ${ builtins.toString remediation-type-error }
                                                                    TEMPORARY_LOG="$( temporary )" || exit ${ builtins.toString remediation-temporary-error }
                                                                    jq \
                                                                        --null-input \
                                                                        --arg BAD "$BAD" \
                                                                        --arg CREATION_TIME "$CREATION_TIME" \
                                                                        --arg GOOD "$GOOD" \
                                                                        --arg HASH "$HASH" \
                                                                        --arg RESOLUTION "$RESOLUTION" \
                                                                        --arg TIMESTAMP "$TIMESTAMP" \
                                                                        --arg TYPE "$TYPE" \
                                                                        '{ "bad" : $BAD , "creation-time" : $CREATION_TIME , "good" : $GOOD , "hash" : $HASH , "resolution" : $RESOLUTION , "timestamp" : $TIMESTAMP , "type" : $TYPE }' | yq --prettyPrint "[.]" > "$TEMPORARY_LOG"
                                                                    log "$TEMPORARY_LOG"
                                                                '' ;
                                                        } ;
                                                in
                                                    ''
                                                        HASH="$1"
                                                        STATUS="$2"
                                                        STANDARD_OUTPUT_FILE="$3"
                                                        STANDARD_ERROR_FILE="$4"
                                                        HAS_STANDARD_INPUT="$5"
                                                        STANDARD_INPUT="$6"
                                                        shift 6
                                                        ARGUMENTS="$( printf '%s\n' "$@" | jq --raw-input --slurp 'split("\n")[:-1]' )" || exit ${ builtins.toString hidden-error }
                                                        CREATION_TIME="$( stat --format "%W" "${ resources-directory }/mounts/$HASH" )" || exit ${ builtins.toString hidden-error }
                                                        find "${ resources-directory }/links/$HASH" -mindepth 1 -maxdepth 1 -type l -exec basename {} \; | jq --raw-input --slurp | yq --prettyPrint >> /tmp/DEBUG4 2>&1
                                                        LINKS=${ if builtins.typeOf init == "null" then "" else ''"$( find "${ resources-directory }/links/$HASH" -mindepth 1 -maxdepth 1 -type l -exec basename {} \; | jq --raw-input --slurp )" || exit ${ builtins.toString hidden-error }'' }
                                                        TARGETS="$( find "${ resources-directory }/mounts/$HASH" -mindepth 1 -maxdepth 1 -exec basename {} \; | jq --raw-input --slurp )" || exit ${ builtins.toString hidden-error }
                                                        TIMESTAMP="$( date +%s )" || exit ${ builtins.toString hidden-error }
                                                        mkdir --parents ${ resources-directory }/bad
                                                        BAD="$( mktemp --directory ${ resources-directory }/bad/XXXXXXXX )" || exit ${ builtins.toString hidden-error }
                                                        ${ if builtins.typeOf init == "null" then "#" else ''cp --recursive "${ resources-directory }/links/$HASH" "$BAD/links"'' }
                                                        rm --recursive --force "${ resources-directory }/locks/$HASH"
                                                        mv "${ resources-directory }/mounts/$HASH" "$BAD/mounts"
                                                        echo "$CREATION_TIME" > "$BAD/creation-time.asc"
                                                        echo "$HASH" > "$BAD/hash.asc"
                                                        ln --symbolic ${ logs }/bin/logs "$BAD/logs.sh"
                                                        ln --symbolic ${ resolve }/bin/resolve "$BAD/resolve.sh"
                                                        ${ if builtins.typeOf init == "null" then "#" else ''rm --recursive --force "${ resources-directory }/links/$HASH"'' }
                                                        flock -u 202
                                                        exec 202>&-
                                                        STANDARD_ERROR="$( cat "$STANDARD_ERROR_FILE" )" || exit ${ builtins.toString hidden-error }
                                                        STANDARD_OUTPUT="$( cat "$STANDARD_OUTPUT_FILE" )" || exit ${ builtins.toString hidden-error }
                                                        rm --force "$STANDARD_ERROR_FILE" "$STANDARD_OUTPUT_FILE"
                                                        TYPE="$( basename "$0" )" || exit ${ builtins.toString hidden-error }
                                                        TEMPORARY_LOG=$( temporary )
                                                        jq \
                                                            --null-input \
                                                            --argjson ARGUMENTS "$ARGUMENTS" \
                                                            --arg BAD "$BAD" \
                                                            --arg CREATION_TIME "$CREATION_TIME" \
                                                            --arg HASH "$HASH" \
                                                            --arg HAS_STANDARD_INPUT "$HAS_STANDARD_INPUT" \
                                                            --arg INIT_APPLICATION ${ if builtins.typeOf init-application == "null" then "null" else "${ init-application }/bin/init-application" } \
                                                            --argjson LINKS "$LINKS" \
                                                            --arg RELEASE_APPLICATION ${ if builtins.typeOf release-application == "null" then "null" else "${ release-application }/bin/release-application" } \
                                                            --arg STANDARD_ERROR "$STANDARD_ERROR" \
                                                            --arg STANDARD_INPUT "$STANDARD_INPUT" \
                                                            --arg STANDARD_OUTPUT "$STANDARD_OUTPUT" \
                                                            --arg STATUS "$STATUS" \
                                                            --argjson TARGETS "$TARGETS" \
                                                            --arg TIMESTAMP "$TIMESTAMP" \
                                                            --arg TYPE "$TYPE" \
                                                            '{
                                                                "arguments" : $ARGUMENTS ,
                                                                "bad" : $BAD ,
                                                                "creation-time" : $CREATION_TIME ,
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
                                                                "timestamp" : $TIMESTAMP ,
                                                                "type" : $TYPE
                                                            }' | yq --prettyPrint "[.]" > "$TEMPORARY_LOG"
                                                        NOHUP="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                        nohup log "$TEMPORARY_LOG" > "$NOHUP" 2>&1 &
                                                    '' ;
                                    } ;
                            description_ =
                                visitor.lib.implementation
                                    {
                                        lambda = path : value : value seed ;
                                        null = path : value : "" ;
                                        string = path : value : value ;
                                    }
                                    description ;
                            good =
                                writeShellApplication
                                    {
                                        name = "good" ;
                                        runtimeInputs = [ coreutils findutils jq log stall-for-process temporary yq-go ] ;
                                        text =
                                            ''
                                                HASH="$1"
                                                ORIGINATOR_PID="$2"
                                                STATUS="$3"
                                                STANDARD_OUTPUT_FILE="$4"
                                                STANDARD_ERROR_FILE="$5"
                                                HAS_STANDARD_INPUT="$6"
                                                STANDARD_INPUT="$7"
                                                shift 7
                                                ARGUMENTS="$( printf '%s\n' "$@" | jq --raw-input --slurp 'split("\n")[:-1]' )" || exit ${ builtins.toString hidden-error }
                                                CREATION_TIME="$( stat --format "%W" "${ resources-directory }/mounts/$HASH" )" || exit ${ builtins.toString hidden-error }
                                                LINKS=${ if builtins.typeOf init == "null" then "" else ''"$( find "${ resources-directory }/links/$HASH" -mindepth 1 -maxdepth 1 -type l -exec basename {} \; | jq --raw-input --slurp )" || exit ${ builtins.toString hidden-error }'' }
                                                STANDARD_ERROR="$( cat "$STANDARD_ERROR_FILE" )" || exit ${ builtins.toString hidden-error }
                                                STANDARD_OUTPUT="$( cat "$STANDARD_OUTPUT_FILE" )" || exit ${ builtins.toString hidden-error }
                                                echo "6c4d51c3-7b22-432d-9504-757d059bf865 2a06fb3a-e79c-4600-ac5c-1cf9e0aaacd0" >> /tmp/DEBUG
                                                rm --force "$STANDARD_ERROR_FILE" "$STANDARD_OUTPUT_FILE"
                                                echo "404604d1-a56f-4ee3-9e64-cd1b09e52663 2a06fb3a-e79c-4600-ac5c-1cf9e0aaacd0" >> /tmp/DEBUG
                                                TIMESTAMP="$( date +%s )" || exit ${ builtins.toString hidden-error }
                                                TYPE="$( basename "$0" )" || exit ${ builtins.toString hidden-error }
                                                flock -u 202
                                                exec 202>&-
                                                TEMPORARY_LOG=$( temporary )
                                                echo 0aa8d318-1f68-418e-a87d-d779b68735b5 >> /tmp/DEBUG
                                                jq \
                                                    --null-input \
                                                    --argjson ARGUMENTS "$ARGUMENTS" \
                                                    --arg CREATION_TIME "$CREATION_TIME" \
                                                    --arg DESCRIPTION "${ description_ }" \
                                                    --arg HASH "$HASH" \
                                                    --arg HAS_STANDARD_INPUT "$HAS_STANDARD_INPUT" \
                                                    --arg INIT_APPLICATION ${ if builtins.typeOf init-application == "null" then "null" else "${ init-application }/bin/init-application" } \
                                                    --argjson LINKS "$LINKS" \
                                                    --arg RELEASE_APPLICATION ${ if builtins.typeOf release-application == "null" then "null" else "${ release-application }/bin/release-application" } \
                                                    --arg STANDARD_ERROR "$STANDARD_ERROR" \
                                                    --arg STANDARD_INPUT "$STANDARD_INPUT" \
                                                    --arg STANDARD_OUTPUT "$STANDARD_OUTPUT" \
                                                    --arg STATUS "$STATUS" \
                                                    --arg TIMESTAMP "$TIMESTAMP" \
                                                    --arg TYPE "$TYPE" \
                                                    '{ "creation-time" : $CREATION_TIME  , "description" : $DESCRIPTION , "hash" : $HASH , "has-standard-input" : $HAS_STANDARD_INPUT , "init-application" : $INIT_APPLICATION , "links" : $LINKS , "release-application" : $RELEASE_APPLICATION , "standard-error" : $STANDARD_ERROR , "standard-input" : $STANDARD_INPUT , "standard-output" : $STANDARD_OUTPUT , "status" : $STATUS , "timestamp" : $TIMESTAMP , "type" : $TYPE }' | yq --prettyPrint "[.]" > "$TEMPORARY_LOG"
                                                echo f5c19c31-0252-475e-abb4-f2aa7a487f6e >> /tmp/DEBUG
                                                NOHUP="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                nohup log "$TEMPORARY_LOG" > "$NOHUP" 2>&1 &
                                                stall-for-process "$ORIGINATOR_PID" "$HASH" "$CREATION_TIME"
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
                                        runtimeInputs = [ coreutils flock ] ;
                                        text =
                                            ''
                                                echo ed16ab29-b9a0-4f48-aa80-65d79b312e2e >> /tmp/DEBUG
                                                TEMPORARY_LOG="$1"
                                                mkdir --parents ${ resources-directory }/logs
                                                echo "01829c7e-22cf-44fe-a1f5-e6dbb00fd2b3 TEMPORARY_LOG=$TEMPORARY_LOG" >> /tmp/DEBUG
                                                exec 203> ${ resources-directory }/logs/lock
                                                echo 1723b723-9da3-46e3-bde8-b5d68295e41f >> /tmp/DEBUG
                                                flock -x 203
                                                echo 2c302511-7bed-4070-9c65-0739917341ef >> /tmp/DEBUG
                                                cat "$TEMPORARY_LOG" >> ${ resources-directory }/logs/log.yaml
                                                echo 1f1ee4d2-fad5-4aae-b225-69d4176aff6b >> /tmp/DEBUG
                                                flock -u 203
                                                exec 203>&-
                                                echo "2a2a5cec-da6d-4d22-bc1f-4607f750903f 2a06fb3a-e79c-4600-ac5c-1cf9e0aaacd0" >> /tmp/DEBUG
                                                rm --force "$TEMPORARY_LOG"
                                                echo "ef337b6a-4507-485f-841e-3b291d9e8f5f 2a06fb3a-e79c-4600-ac5c-1cf9e0aaacd0" >> /tmp/DEBUG
                                            '' ;
                                    } ;
                            no-init =
                                writeShellApplication
                                    {
                                        name = "no-init" ;
                                        runtimeInputs = [ coreutils flock log stall-for-process temporary ] ;
                                        text =
                                            ''
                                                echo ea79d12b-d78d-4803-b7d8-632dbefa8d1a >> /tmp/DEBUG
                                                HASH="$1"
                                                ORIGINATOR_PID="$2"
                                                CREATION_TIME="$( stat --format "%W" "${ resources-directory }/mounts/$HASH" )" || exit ${ builtins.toString hidden-error }
                                                TIMESTAMP="$( date +%s )" || exit ${ builtins.toString hidden-error }
                                                TYPE="$( basename "$0" )" || exit ${ builtins.toString hidden-error }
                                                flock -u 202
                                                echo 7f098d90-d2b4-4b43-927a-5ad6f98cc313 >> /tmp/DEBUG
                                                exec 202>&-
                                                echo ae90ed32-4252-41cf-ae19-297b8cff9605 >> /tmp/DEBUG
                                                TEMPORARY_LOG=$( temporary )
                                                jq \
                                                    --arg CREATION_TIME "$CREATION_TIME" \
                                                    --arg DESCRIPTION "${ description }" \
                                                    --arg HASH "$HASH" \
                                                    --arg ORIGINATOR_PID "$ORIGINATOR_PID" \
                                                    --arg TIMESTAMP "$TIMESTAMP" \
                                                    --arg TYPE "$TYPE" \
                                                    --null-input \
                                                    '{ "creation-time" : $CREATION_TIME  , "description" : $DESCRIPTION "hash" : $HASH , "originator-pid" : $ORIGINATOR_PID , "timestamp" : $TIMESTAMP , "type" : $TYPE }' | yq --prettyPrint "[.]" > "$TEMPORARY_LOG"
                                                NOHUP="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                echo 1ba7fbc5-d3a0-4493-b747-0513d03d57b3 >> /tmp/DEBUG
                                                nohup log "$TEMPORARY_LOG" > "$NOHUP" 2>&1 &
                                                stall-for-process "$ORIGINATOR_PID" "$HASH" "$CREATION_TIME"
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
                                                    mkdir --parents "${ resources-directory }/locks/$HASH"
                                                    exec 201> "${ resources-directory }/locks/$HASH/teardown.lock"
                                                    flock -s 201
                                                    exec 202> "${ resources-directory }/locks/$HASH/setup.lock"
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
                                                        ORIGINATOR_PID="$PARENT_3_PID"
                                                    else
                                                        HAS_STANDARD_INPUT=false
                                                        STANDARD_INPUT=
                                                        ORIGINATOR_PID="$PARENT_2_PID"
                                                    fi
                                                    ARGUMENTS=( "$@" )
                                                    HASH="$( echo "${ hash } ${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[*]" "}" ] } $STANDARD_INPUT $HAS_STANDARD_INPUT" | sha512sum | cut --bytes -${ builtins.toString length } )" || exit ${ builtins.toString hash-error }
                                                    export HASH
                                                    mkdir --parents "${ resources-directory }/locks/$HASH"
                                                    exec 201> "${ resources-directory }/locks/$HASH/teardown.lock"
                                                    flock -s 201
                                                    exec 202> "${ resources-directory }/locks/$HASH/setup.lock"
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
                                                            if init-application "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" < "$STANDARD_INPUT_FILE" > "$STANDARD_OUTPUT" 2> "$STANDARD_ERROR"
                                                            then
                                                                STATUS="$?"
                                                            else
                                                                STATUS="$?"
                                                            fi
                                                            rm --force "$STANDARD_INPUT_FILE"
                                                            if [[ "$STATUS" == 0 ]] && [[ ! -s "$STANDARD_ERROR" ]] && [[ "$( find "${ resources-directory }/mounts/$HASH" -mindepth 1 -maxdepth 1 -exec basename {} \; | LC_ALL=C sort | tr --delete "\n" | sha512sum | cut --bytes -128 )" == ${ builtins.hashString "sha512" ( builtins.concatStringsSep "" ( builtins.sort builtins.lessThan targets ) ) } ]]
                                                            then
                                                                nohup good "$HASH" "$ORIGINATOR_PID" "$STATUS" "$STANDARD_OUTPUT" "$STANDARD_ERROR" "$HAS_STANDARD_INPUT" "$STANDARD_INPUT" "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" > /dev/null 2>&1 &
                                                                echo -n "${ resources-directory }/$HASH/mounts"
                                                            else
                                                                nohup bad "$HASH" "$STATUS" "$STANDARD_OUTPUT" "$STANDARD_ERROR" "$HAS_STANDARD_INPUT" "$STANDARD_INPUT" "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" > /dev/null 2>&1 &
                                                                exit ${ builtins.toString initialization-error }
                                                            fi
                                                        else
                                                            if init-application "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" > "$STANDARD_OUTPUT" 2> "$STANDARD_ERROR"
                                                            then
                                                                STATUS="$?"
                                                            else
                                                                STATUS="$?"
                                                            fi
                                                            if [[ "$STATUS" == 0 ]] && [[ ! -s "$STANDARD_ERROR" ]] && [[ "$( find "${ resources-directory }/mounts/$HASH" -mindepth 1 -maxdepth 1 -exec basename {} \; | LC_ALL=C sort | tr --delete "\n" | sha512sum | cut --bytes -128 )" == ${ builtins.hashString "sha512" ( builtins.concatStringsSep "" ( builtins.sort builtins.lessThan targets ) ) } ]]
                                                            then
                                                                nohup good "$HASH" "$ORIGINATOR_PID" "$STATUS" "$STANDARD_OUTPUT" "$STANDARD_ERROR" "$HAS_STANDARD_INPUT" "$STANDARD_INPUT" "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" > /dev/null 2>&1 &
                                                                echo -n "${ resources-directory }/mounts/$HASH"
                                                            else
                                                                nohup bad "$HASH" "$STATUS" "$STANDARD_OUTPUT" "$STANDARD_ERROR" "$HAS_STANDARD_INPUT" "$STANDARD_INPUT" "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" > /dev/null 2>&1 &
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
                                        runtimeInputs = [ coreutils flock log stall-for-process temporary ] ;
                                        text =
                                            ''
                                                CREATION_TIME="$( stat --format "%W" "${ resources-directory }/mounts/$HASH" )" || exit ${ builtins.toString hidden-error }
                                                flock -u 202
                                                exec 202>&-
                                                HASH="$1"
                                                ORIGINATOR_PID="$2"
                                                TIMESTAMP="$( date +%s )" || exit ${ builtins.toString hidden-error }
                                                TYPE="$( basename "$0" )" || exit ${ builtins.toString hidden-error }
                                                TEMPORARY_LOG="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                jq \
                                                    --null-input \
                                                    --arg CREATION_TIME "$CREATION_TIME" \
                                                    --arg DESCRIPTION "${ description_ }" \
                                                    --arg HASH "$HASH" \
                                                    --arg TIMESTAMP "$TIMESTAMP" \
                                                    --arg TYPE "$TYPE" \
                                                     '{ "creation-time" : $CREATION_TIME  , "description" : $DESCRIPTION , "hash" : $HASH , "timestamp" , $TIMESTAMP , "type" : $TYPE}' | yq --prettyPrint "[.]" > "$TEMPORARY_LOG"
                                                NOHUP="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                nohup log "$TEMPORARY_LOG" > "$NOHUP" 2>&1 &
                                                stall-for-process "$ORIGINATOR_PID" "$HASH" "$CREATION_TIME"
                                            '' ;
                                    } ;
                            stall-for-cleanup =
                                writeShellApplication
                                    {
                                        name = "stall-for-cleanup" ;
                                        runtimeInputs = [ coreutils log stall-for-cleanup-head stall-for-symlink teardown temporary ] ;
                                        text =
                                            ''
                                                echo a102cef2-41a7-4228-8d93-df1e0445a827 >> /tmp/DEBUG
                                                HASH="$1"
                                                echo 2d0307b2-7740-4947-9729-7036b0a9bd0a >> /tmp/DEBUG
                                                CREATION_TIME="$2"
                                                echo e91fb532-872f-4da8-a327-14284814d70b >> /tmp/DEBUG
                                                HEAD="$( stall-for-cleanup-head )" || exit ${ builtins.toString hidden-error }
                                                echo eb65232f-e191-498f-844c-b8f897d271a6 >> /tmp/DEBUG
                                                TIMESTAMP="$( date +%s )" || exit ${ builtins.toString hidden-error }
                                                echo 28dc7e64-9808-461b-b372-70f27affae1d >> /tmp/DEBUG
                                                TYPE="$( basename "$0" )" || exit ${ builtins.toString hidden-error }
                                                echo 7b83bbd1-6dd4-4e2c-b073-f4ad8ac07b4b >> /tmp/DEBUG
                                                TEMPORARY_LOG="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                echo 2d614e0d-e687-4aad-a5e8-c3a12af02eb4  >> /tmp/DEBUG
                                                jq \
                                                    --null-input \
                                                    --arg CREATION_TIME "$CREATION_TIME" \
                                                    --arg DESCRIPTION "${ description_ }" \
                                                    --arg HASH "$HASH" \
                                                    --arg HEAD "$HEAD" \
                                                    --arg TIMESTAMP "$TIMESTAMP" \
                                                    --arg TYPE "$TYPE" \
                                                     '{ "creation-time" : $CREATION_TIME , "description" : $DESCRIPTION , "hash" : $HASH , "head" : $HEAD , "timestamp" : $TIMESTAMP , "type" : $TYPE }' | yq --prettyPrint "[.]" > "$TEMPORARY_LOG"
                                                echo 6f5d91a7-d5b3-4d6a-a6d7-a78ccad6cbf2 >> /tmp/DEBUG
                                                NOHUP="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                echo 90f1bc19-1422-425b-a498-74321a3be25d >> /tmp/DEBUG
                                                cat "$TEMPORARY_LOG" >> /tmp/DEBUG
                                                nohup log "$TEMPORARY_LOG" > "$NOHUP" 2>&1 &
                                                echo "9edbd24d-6375-4b32-bc23-a25a6ee30d6b b1fb1129-39c6-4a9f-9f1e-c96b88f559c4 DESCRIPTION=${ description_ }" >> /tmp/DEBUG
                                                mkdir --parents ${ resources-directory }/links ${ resources-directory }/bad
                                                echo 6316ff11-f0b7-4088-94f0-616718e6f325 >> /tmp/DEBUG
                                                if [[ -n "$HEAD" ]]
                                                then
                                                    echo 637851b3-d51b-4297-8178-93bd64e19856 >> /tmp/DEBUG
                                                    inotifywait --event move_self "$HEAD" --quiet
                                                    stall-for-cleanup
                                                else
                                                    echo e5ce1a5c-7f11-4692-bf53-12a777ab625e >> /tmp/DEBUG
                                                    teardown "$HASH" "$CREATION_TIME"
                                                fi
                                            '' ;
                                    } ;
                            stall-for-cleanup-head =
                                writeShellApplication
                                    {
                                        name = "stall-for-cleanup-head" ;
                                        runtimeInputs = [ coreutils findutils ] ;
                                        text =
                                            ''
                                                mkdir --parents ${ resources-directory }/links ${ resources-directory }/bad
                                                find ${ resources-directory }/links ${ resources-directory }/bad -type l 2>/dev/null | while read -r CANDIDATE
                                                do
                                                    RESOLVED="$( readlink --canonicalize "$CANDIDATE" 2>/dev/null )"
                                                    TARGET="${resources-directory}/mounts/$HASH"
                                                    if [[ "$RESOLVED" == "$TARGET" ]]
                                                    then
                                                        echo "$CANDIDATE"
                                                        exit 0
                                                    fi
                                                done | head --lines 1
                                            '' ;
                                    } ;
                            stall-for-process =
                                writeShellApplication
                                    {
                                        name = "stall-for-process" ;
                                        runtimeInputs = [ coreutils log stall-for-cleanup temporary ] ;
                                        text =
                                            ''
                                                ORIGINATOR_PID="$1"
                                                HASH="$2"
                                                CREATION_TIME="$3"
                                                TIMESTAMP="$( date +%s )" || exit ${ builtins.toString hidden-error }
                                                TYPE="$( basename "$0" )" || exit ${ builtins.toString hidden-error }
                                                TEMPORARY_LOG="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                jq \
                                                    --null-input \
                                                    --arg CREATION_TIME "$CREATION_TIME" \
                                                    --arg DESCRIPTION "${ description_ }" \
                                                    --arg HASH "$HASH" \
                                                    --arg ORIGINATOR_PID "$ORIGINATOR_PID" \
                                                    --arg TIMESTAMP "$TIMESTAMP" \
                                                    --arg TYPE "$TYPE" \
                                                     '{ "creation-time" : $CREATION_TIME , "description" : $DESCRIPTION , "hash" : $HASH , "originator-pid" : $ORIGINATOR_PID , "timestamp" : $TIMESTAMP , "type" : $TYPE }' | yq --prettyPrint "[.]" > "$TEMPORARY_LOG"
                                                NOHUP="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                nohup log "$TEMPORARY_LOG" > "$NOHUP" 2>&1 &
                                                echo b11e5eeb-daa7-40cc-8d61-e4f3fe693c8f tail --follow /dev/null --pid "$ORIGINATOR_PID" >> /tmp/DEBUG
                                                tail --follow /dev/null --pid "$ORIGINATOR_PID"
                                                echo 92b24483-bb6f-4bdb-81fa-18a4d5a4d60d stall-for-cleanup "$HASH" "$CREATION_TIME" >> /tmp/DEBUG
                                                stall-for-cleanup "$HASH" "$CREATION_TIME"
                                                echo 777348a6-e476-4622-bbc3-342d46d1735c >> /tmp/DEBUG
                                            '' ;
                                    } ;
                            stall-for-symlink =
                                writeShellApplication
                                    {
                                        name = "stall-for-symlink" ;
                                        runtimeInputs = [ ] ;
                                        text =
                                            ''
                                                echo 48be45dd-e0ad-429d-bd14-d4d161f11620 >> /tmp/DEBUG
                                                SYMLINK="$1"
                                                TIMESTAMP="$( date +%s )" || exit ${ builtins.toString hidden-error }
                                                TYPE="$( basename "$0" )" || exit ${ builtins.toString hidden-error }
                                                TEMPORARY_LOG="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                echo 037c17f0-a989-4e11-9dc0-8324db8b372c >> /tmp/DEBUG
                                                jq \
                                                    --null-input \
                                                    --arg DESCRIPTION "${ description_ }" \
                                                    --arg SYMLINK "$SYMLINK" \
                                                    --arg TIMESTAMP "$TIMESTAMP" \
                                                    --arg TYPE "$TYPE" \
                                                     '{ "description" : $DESCRIPTION , "symlink" : $SYMLINK , "timestamp" : $TIMESTAMP , "type" : $TYPE }' | yq --prettyPrint "[.]" > "$TEMPORARY_LOG"
                                                echo 8bb68cba-99f7-459a-9f54-34035ca39636 >> /tmp/DEBUG
                                                NOHUP="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                nohup log "$TEMPORARY_LOG" > "$NOHUP" 2>&1 &
                                                echo "ead4dfc3-fb0f-4eb2-9f30-59c7ad66efd5 fbb055a7-80bc-40be-838d-ef0b76aff45b SYMLINK=$SYMLINK" >> /tmp/DEBUG
                                                if [[ -e "$SYMLINK" ]]
                                                then
                                                    echo 0066242f-bf73-423d-93e8-8123344da1db >> /tmp/DEBUG
                                                else
                                                    echo fc841087-0aea-441f-bd6d-913f28ecb5b9 >> /tmp/DEBUG
                                                fi
                                                inotifywait --event move_self "$SYMLINK" --quiet
                                                if [[ -e "$SYMLINK" ]]
                                                then
                                                    echo 72223bdc-8803-4d93-aaee-384480a41e52 >> /tmp/DEBUG
                                                else
                                                    echo c30680a2-f6ff-44e5-b181-65633db13c40 >> /tmp/DEBUG
                                                fi
                                                echo 9c581956-c409-4c42-a7cd-c6029c146468 >> /tmp/DEBUG
                                            '' ;
                                    } ;
                            teardown =
                                writeShellApplication
                                    {
                                        name = "teardown" ;
                                        runtimeInputs = [ coreutils flock jq log teardown-aborted teardown-completed temporary yq-go ] ;
                                        text =
                                            if builtins.typeOf release == "null" then
                                                ''
                                                    echo ac9f8eda-c00b-454d-a237-a155eac36a59 >> /tmp/DEBUG
                                                    HASH="$1"
                                                    CREATION_TIME="$2"
                                                    if [[ ! -d "${ resources-directory }/mounts/$HASH" ]] || [[ "$( stat --format "%W" "${ resources-directory }/mounts/$HASH" )" != "$CREATION_TIME" ]]
                                                    then
                                                        teardown-aborted "$HASH" "$CREATION_TIME"
                                                    else
                                                        teardown-completed "$HASH" "CREATION_TIME"
                                                    fi
                                                    echo 8d3b5949-4f10-47e6-87ea-46475a079c98 >> /tmp/DEBUG
                                                ''
                                            else
                                                ''
                                                    HASH="$1"
                                                    ORIGINATOR_PID="$2"
                                                    CREATION_TIME="$3"
                                                    if [[ ! -d "${ resources-directory }/mounts/$HASH" ]] || [[ "$( stat --format "%W" "${ resources-directory }/mounts/$HASH" )" != "$CREATION_TIME" ]]
                                                    then
                                                        teardown-aborted "$HASH" "$CREATION_TIME"
                                                    else
                                                        exec 201> "${ resources-directory }/$HASH/teardown.lock"
                                                        flock -x 201
                                                        exec 202> "${ resources-directory }/$HASH/setup.lock"
                                                        flock -x 202
                                                        export HASH
                                                        STANDARD_INPUT="$( temporary )" || exit ${ builtins.hidden-error }
                                                        STANDARD_ERROR="$( temporary )" || exit ${ builtins.hidden-error }
                                                        if ${ release-application }/bin/release > "$STANDARD_OUTPUT" 2> "$STANDARD_ERROR" && STATUS="$?" && [[ ! -s "$STANDARD_ERROR" ]]
                                                        then
                                                            teardown-completed "$HASH" "$CREATION_TIME"
                                                        else
                                                            nohup bad "$HASH" "$STATUS" "$STANDARD_OUTPUT" "$STANDARD_ERROR" > /dev/null 2>&1 &
                                                        fi
                                                    fi
                                                '' ;
                                    } ;
                            teardown-aborted =
                                writeShellApplication
                                    {
                                        name = "teardown-aborted" ;
                                        runtimeInputs = [ ] ;
                                        text =
                                            ''
                                                HASH="$1"
                                                CREATION_TIME="$2"
                                                TIMESTAMP="$( date +%s )" || exit ${ builtins.toString hidden-error }
                                                TYPE="$( basename "$0" )" || exit ${ builtins.toString hidden-error }
                                                TEMPORARY_LOG="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                jq \
                                                    --null-input \
                                                    --arg CREATION_TIME "$CREATION_TIME" \
                                                    --arg DESCRIPTION "${ description_ }" \
                                                    --arg HASH "$HASH" \
                                                    --arg TIMESTAMP "$TIMESTAMP" \
                                                    --arg TYPE "$TYPE" \
                                                    '{ "creation-time" : $CREATION_TIME , "description" : $DESCRIPTION , "hash" : $HASH , "timestamp" : $TIMESTAMP , "type" : $TYPE }' | yq --prettyPrint "[.]" > "$TEMPORARY_LOG"
                                                flock -u 202
                                                exec 202>&-
                                                flock -u 201
                                                exec 201>&-
                                                log "$TEMPORARY_LOG"
                                            '' ;
                                    } ;
                            teardown-completed =
                                writeShellApplication
                                    {
                                        name = "teardown-completed" ;
                                        runtimeInputs = [ ] ;
                                        text =
                                            ''
                                                echo ea074cfd-79bb-40b0-bdd7-64db25105ee8 >> /tmp/DEBUG
                                                HASH="$1"
                                                echo e8080aac-908a-406b-9938-488c8c86d0f2 >> /tmp/DEBUG
                                                CREATION_TIME="$2"
                                                TIMESTAMP="$( date +%s )" || exit ${ builtins.toString hidden-error }
                                                echo e21fc937-8b79-4f0a-9fb9-3899260e4a15 >> /tmp/DEBUG
                                                TYPE="$( basename "$0" )" || exit ${ builtins.toString hidden-error }
                                                echo 17cfd1f8-e9f4-4aa4-b079-f98af640a6e6 >> /tmp/DEBUG
                                                TEMPORARY_LOG="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                echo 266e8b8b-a520-4789-a9d3-e8267c4d6142 >> /tmp/DEBUG
                                                GOOD="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                echo 4ca8601e-5101-43cd-8718-a89bfba8cc39 >> /tmp/DEBUG
                                                mkdir --parents "$GOOD"
                                                echo c359cf4f-b8a5-4dfe-9e2a-12ac473917f7 >> /tmp/DEBUG
                                                ${ if builtins.typeOf init == "null" then "#" else ''mv "${ resources-directory }/links/$HASH" "$GOOD/links"'' }
                                                echo 58471533-8b35-42aa-9890-b2f709f4ee5e >> /tmp/DEBUG
                                                mv "${ resources-directory }/mounts/$HASH" "$GOOD/mounts"
                                                echo "40b5f296-aada-416f-b021-c2561d57ad29 2a06fb3a-e79c-4600-ac5c-1cf9e0aaacd0" >> /tmp/DEBUG
                                                rm --recursive "${ resources-directory }/locks/$HASH"
                                                echo "3eb57a7e-9b1f-4d1c-a263-458c34f1c227 2a06fb3a-e79c-4600-ac5c-1cf9e0aaacd0" >> /tmp/DEBUG
                                                TEMPORARY_LOG="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                jq \
                                                    --null-input \
                                                    --arg CREATION_TIME "$CREATION_TIME" \
                                                    --arg DESCRIPTION "${ description_ }" \
                                                    --arg GOOD "$GOOD" \
                                                    --arg HASH "$HASH" \
                                                    --arg TIMESTAMP "$TIMESTAMP" \
                                                    --arg TYPE "$TYPE" \
                                                    '{ "creation-time" : $CREATION_TIME , "description" : $DESCRIPTION , "good" : $GOOD , "hash" : $HASH , "timestamp" : $TIMESTAMP , "type" : $TYPE }' | yq --prettyPrint "[.]" > "$TEMPORARY_LOG"
                                                echo c944a6e3-1243-49cc-a9cf-a5387dc29e8d >> /tmp/DEBUG
                                                log "$TEMPORARY_LOG"
                                                echo 7ad54e01-f17b-44cf-ad20-91f690e29a9f >> /tmp/DEBUG
                                            '' ;
                                    } ;
                            teardown-process =
                                writeShellApplication
                                    {
                                        name = "teardown-process" ;
                                        runtimeImports = [ ] ;
                                        text =
                                            ''
                                                HASH="$1"
                                                CREATION_TIME="$2"

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
