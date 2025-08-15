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
						makeBinPath ,
						makeWrapper ,
						mkDerivation ,
						ps ,
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
						transient ? false ,
						uuid-error ? 112 ,
						visitor ,
						yq-go ,
						which ,
						writeShellApplication
					} @primary :
						let
						    derivation =
						        mkDerivation
						            {
						                installPhase =
						                    let
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
                                                scripts =
                                                    {
                                                        bad =
                                                            ''
                                                                echo "f283c432-25be-495b-a497-9f462d1b2e05" >> /tmp/DEBUG
                                                                HASH="$1"
                                                                STATUS="$2"
                                                                STANDARD_OUTPUT_FILE="$3"
                                                                STANDARD_ERROR_FILE="$4"
                                                                HAS_STANDARD_INPUT="$5"
                                                                STANDARD_INPUT="$6"
                                                                shift 6
                                                                ARGUMENTS="$( printf '%s\n' "$@" | jq --raw-input --slurp 'split("\n")[:-1]' )" || exit ${ builtins.toString hidden-error }
                                                                echo "bfb9a6a8-886e-4024-9ad3-1a631afcbaf1" >> /tmp/DEBUG
                                                                CREATION_TIME="$( stat --format "%W" "${ resources-directory }/mounts/$HASH" )" || exit ${ builtins.toString hidden-error }
                                                                LINKS=${ if builtins.typeOf init == "null" then "" else ''"$( find "${ resources-directory }/links/$HASH" -mindepth 1 -maxdepth 1 -type l -exec basename {} \; | jq --raw-input --slurp )" || exit ${ builtins.toString hidden-error }'' }
                                                                TARGETS="$( find "${ resources-directory }/mounts/$HASH" -mindepth 1 -maxdepth 1 -exec basename {} \; | jq --raw-input --slurp )" || exit ${ builtins.toString hidden-error }
                                                                TIMESTAMP="$( date +%s )" || exit ${ builtins.toString hidden-error }
                                                                mkdir --parents ${ resources-directory }/bad
                                                                BAD="$( mktemp --directory ${ resources-directory }/bad/XXXXXXXX )" || exit ${ builtins.toString hidden-error }
                                                                ${ if builtins.typeOf init == "null" then "#" else ''cp --recursive "${ resources-directory }/links/$HASH" "$BAD/links"'' }
                                                                rm --recursive --force "${ resources-directory }/locks/$HASH"
                                                                mv "${ resources-directory }/mounts/$HASH" "$BAD/mounts"
                                                                echo "b01fb612-087e-4881-8738-5e832d1fd729" >> /tmp/DEBUG
                                                                flock -u 201
                                                                echo "f5c4fddf-a955-4a36-b77b-fb8170dda17f" >> /tmp/DEBUG
                                                                exec 201>&-
                                                                echo "6ed065f7-1b7a-4ace-bc84-a943198973cf" >> /tmp/DEBUG
                                                                echo "$CREATION_TIME" > "$BAD/creation-time.asc"
                                                                echo "$HASH" > "$BAD/hash.asc"
                                                                RESOLVE="$( which resolve )" || exit ${ builtins.toString hidden-error }
                                                                ln --symbolic "$RESOLVE" "$BAD/resolve.sh"
                                                                ${ if builtins.typeOf init == "null" then "#" else ''rm --recursive --force "${ resources-directory }/links/$HASH"'' }
                                                                # echo "4f0fc092-5794-40b0-9dfb-0d226fd2ff4e" >> /tmp/DEBUG
                                                                # flock -u 202
                                                                # echo "dcff554e-62b6-442a-8656-84d41e0c3209" >> /tmp/DEBUG
                                                                # exec 202>&-
                                                                # echo "f6be374d-7472-4e9f-802f-0cfd4bf56e5e" >> /tmp/DEBUG
                                                                # flock -u 201
                                                                # echo "13d083e0-dd7d-4898-b604-21d13ff368f5" >> /tmp/DEBUG
                                                                # exec 201>&-
                                                                echo "d1f547f2-cd3e-423b-9b7a-18a19ab522a9" >> /tmp/DEBUG
                                                                STANDARD_ERROR="$( < "$STANDARD_ERROR_FILE" )" || exit ${ builtins.toString hidden-error }
                                                                STANDARD_OUTPUT="$( < "$STANDARD_OUTPUT_FILE" )" || exit ${ builtins.toString hidden-error }
                                                                rm --force "$STANDARD_ERROR_FILE" "$STANDARD_OUTPUT_FILE"
                                                                TYPE="$( basename "$0" )" || exit ${ builtins.toString hidden-error }
                                                                TEMPORARY_LOG="$( temporary )" || exit ${ builtins.toString hidden-error }
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
                                                                nohup log-bad "$BAD" "$CREATION_TIME" "$HASH" "$TEMPORARY_LOG" > "$NOHUP" 2>&1 &
                                                            '' ;
                                                        good =
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
                                                                rm --force "$STANDARD_ERROR_FILE" "$STANDARD_OUTPUT_FILE"
                                                                TIMESTAMP="$( date +%s )" || exit ${ builtins.toString hidden-error }
                                                                TYPE="$( basename "$0" )" || exit ${ builtins.toString hidden-error }
                                                                TEMPORARY_LOG=$( temporary )
                                                                jq \
                                                                    --null-input \
                                                                    --argjson ARGUMENTS "$ARGUMENTS" \
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
                                                                    --arg TIMESTAMP "$TIMESTAMP" \
                                                                    --arg TYPE "$TYPE" \
                                                                    '{
                                                                        "creation-time" : $CREATION_TIME  ,
                                                                        "hash" : $HASH ,
                                                                        "has-standard-input" : $HAS_STANDARD_INPUT ,
                                                                        "init-application" : $INIT_APPLICATION ,
                                                                        "links" : $LINKS ,
                                                                        "release-application" : $RELEASE_APPLICATION ,
                                                                        "standard-error" : $STANDARD_ERROR ,
                                                                        "standard-input" : $STANDARD_INPUT ,
                                                                        "standard-output" : $STANDARD_OUTPUT ,
                                                                        "status" : $STATUS ,
                                                                        "timestamp" : $TIMESTAMP ,
                                                                        "type" : $TYPE
                                                                    }' | yq --prettyPrint "[.]" > "$TEMPORARY_LOG"
                                                                NOHUP="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                                nohup log "$TEMPORARY_LOG" > "$NOHUP" 2>&1 &
                                                                stall-for-process "$ORIGINATOR_PID" "$HASH" "$CREATION_TIME"
                                                            '' ;
                                                        log =
                                                            ''
                                                                TEMPORARY_LOG="$1"
                                                                mkdir --parents ${ resources-directory }/logs
                                                                exec 203> ${ resources-directory }/logs/lock
                                                                flock -x 203
                                                                cat "$TEMPORARY_LOG" >> ${ resources-directory }/logs/log.yaml
                                                                flock -u 203
                                                                exec 203>&-
                                                                rm --force "$TEMPORARY_LOG"
                                                            '' ;
                                                        log-bad =
                                                            ''
                                                                BAD="$1"
                                                                export CREATION_TIME="$2"
                                                                export HASH="$3"
                                                                export TEMPORARY_LOG="$4"
                                                                yq --null-input eval '
                                                                    {
                                                                        "expected" :
                                                                            {
                                                                                "creation-time" : strenv(CREATION_TIME) ,
                                                                                "hash" : strenv(HASH) ,
                                                                                "seed" : ${ builtins.toJSON seed } ,
                                                                                "targets": ${ builtins.toJSON targets }
                                                                            } ,
                                                                      "observed" : load(strenv(TEMPORARY_LOG))
                                                                    }' | yq eval '.expected.targets |= to_entries | .expected.targets[] |= .value' > "$BAD/log.yaml"
                                                                log "$TEMPORARY_LOG"
                                                            '' ;
                                                        no-init =
                                                            ''
                                                                HASH="$1"
                                                                ORIGINATOR_PID="$2"
                                                                CREATION_TIME="$( stat --format "%W" "${ resources-directory }/mounts/$HASH" )" || exit ${ builtins.toString hidden-error }
                                                                TIMESTAMP="$( date +%s )" || exit ${ builtins.toString hidden-error }
                                                                TYPE="$( basename "$0" )" || exit ${ builtins.toString hidden-error }
                                                                TEMPORARY_LOG=$( temporary )
                                                                jq \
                                                                    --arg CREATION_TIME "$CREATION_TIME" \
                                                                    --arg HASH "$HASH" \
                                                                    --arg ORIGINATOR_PID "$ORIGINATOR_PID" \
                                                                    --arg TIMESTAMP "$TIMESTAMP" \
                                                                    --arg TYPE "$TYPE" \
                                                                    --null-input \
                                                                    '{
                                                                        "creation-time" : $CREATION_TIME ,
                                                                        "hash" : $HASH ,
                                                                        "originator-pid" : $ORIGINATOR_PID ,
                                                                        "timestamp" : $TIMESTAMP ,
                                                                        "type" : $TYPE
                                                                    }' | yq --prettyPrint "[.]" > "$TEMPORARY_LOG"
                                                                NOHUP="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                                nohup log "$TEMPORARY_LOG" > "$NOHUP" 2>&1 &
                                                                stall-for-process "$ORIGINATOR_PID" "$HASH" "$CREATION_TIME"
                                                            '' ;
                                                        resolve =
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
                                                                    '{
                                                                        "bad" : $BAD ,
                                                                        "creation-time" : $CREATION_TIME ,
                                                                        "good" : $GOOD ,
                                                                        "hash" : $HASH ,
                                                                        "resolution" : $RESOLUTION ,
                                                                        "timestamp" : $TIMESTAMP ,
                                                                        "type" : $TYPE
                                                                    }' | yq --prettyPrint "[.]" > "$TEMPORARY_LOG"
                                                                log "$TEMPORARY_LOG"
                                                            '' ;
                                                        setup =
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
                                                                    ${ if builtins.typeOf transient == "bool" && transient then ''UUID="$( uuidgen )" || exit ${ builtins.toString uuid-error }"'' else "#" }
                                                                    HASH="$( echo "${ hash } ${ builtins.concatStringsSep "" [ ( if builtins.typeOf transient == "bool" && transient then "$UUID" else "" ) "$" "{" "ARGUMENTS[*]" "}" ] } $STANDARD_INPUT $HAS_STANDARD_INPUT" | sha512sum | cut --bytes -${ builtins.toString length } )" || exit ${ builtins.toString hash-error }
                                                                    mkdir --parents "${ resources-directory }/locks/$HASH"
                                                                    exec 201> "${ resources-directory }/locks/$HASH/teardown.lock"
                                                                    flock -s 201
                                                                    exec 202> "${ resources-directory }/locks/$HASH/setup.lock"
                                                                    flock -x 202
                                                                    if [[ -d "${ resources-directory }/mounts/$HASH" ]]
                                                                    then
                                                                        flock -u 202
                                                                        exec 202>&-
                                                                        nohup stale "$HASH" "$ORIGINATOR_PID" > /dev/null 2>&1 &
                                                                        echo -n "${ resources-directory }/mounts/$HASH"
                                                                    else
                                                                        mkdir --parents "${ resources-directory }/mounts/$HASH"
                                                                        flock -u 202
                                                                        exec 202>&-
                                                                        nohup no-init "$HASH" "$ORIGINATOR_PID" > /dev/null 2>&1 &
                                                                        echo -n "${ resources-directory }/mounts/$HASH"
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
                                                                    ${ if builtins.typeOf transient == "bool" && transient then ''UUID="$( uuidgen )" || exit ${ builtins.toString uuid-error }"'' else "#" }
                                                                    HASH="$( echo "${ hash } ${ builtins.concatStringsSep "" [ ( if builtins.typeOf transient == "bool" && transient then "$UUID" else "" ) "$" "{" "ARGUMENTS[*]" "}" ] } $STANDARD_INPUT $HAS_STANDARD_INPUT" | sha512sum | cut --bytes -${ builtins.toString length } )" || exit ${ builtins.toString hash-error }
                                                                    export HASH
                                                                    mkdir --parents "${ resources-directory }/locks/$HASH"
                                                                    exec 201> "${ resources-directory }/locks/$HASH/teardown.lock"
                                                                    flock -s 201
                                                                    exec 202> "${ resources-directory }/locks/$HASH/setup.lock"
                                                                    flock -x 202
                                                                    if [[ -d "${ resources-directory }/mounts/$HASH" ]]
                                                                    then
                                                                        flock -u 202
                                                                        exec 202>&-
                                                                        nohup stale "$HASH" "$ORIGINATOR_PID" > /dev/null 2>&1 &
                                                                        echo -n "${ resources-directory }/mounts/$HASH"
                                                                    else
                                                                        mkdir --parents "${ resources-directory }/mounts/$HASH"
                                                                        mkdir --parents "${ resources-directory }/links/$HASH"
                                                                        STANDARD_ERROR="$( temporary )" || exit ${ builtins.toString standard-error-error }
                                                                        STANDARD_OUTPUT="$( temporary )" || exit ${ builtins.toString standard-output-error }
                                                                        if "$HAS_STANDARD_INPUT"
                                                                        then
                                                                            if ${ init-application }/bin/init-application "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" < "$STANDARD_INPUT_FILE" > "$STANDARD_OUTPUT" 2> "$STANDARD_ERROR"
                                                                            then
                                                                                STATUS="$?"
                                                                            else
                                                                                STATUS="$?"
                                                                            fi
                                                                            flock -u 202
                                                                            exec 202>&-
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
                                                                            if ${ init-application }/bin/init-application "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" > "$STANDARD_OUTPUT" 2> "$STANDARD_ERROR"
                                                                            then
                                                                                STATUS="$?"
                                                                            else
                                                                                STATUS="$?"
                                                                            fi
                                                                            flock -u 202
                                                                            exec 202>&-
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
                                                        stale =
                                                            ''
                                                                CREATION_TIME="$( stat --format "%W" "${ resources-directory }/mounts/$HASH" )" || exit ${ builtins.toString hidden-error }
                                                                HASH="$1"
                                                                ORIGINATOR_PID="$2"
                                                                TIMESTAMP="$( date +%s )" || exit ${ builtins.toString hidden-error }
                                                                TYPE="$( basename "$0" )" || exit ${ builtins.toString hidden-error }
                                                                TEMPORARY_LOG="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                                jq \
                                                                    --null-input \
                                                                    --arg CREATION_TIME "$CREATION_TIME" \
                                                                    --arg HASH "$HASH" \
                                                                    --arg TIMESTAMP "$TIMESTAMP" \
                                                                    --arg TYPE "$TYPE" \
                                                                    '{
                                                                        "creation-time" : $CREATION_TIME  ,
                                                                        "description" : $DESCRIPTION ,
                                                                        "hash" : $HASH ,
                                                                        "timestamp" , $TIMESTAMP ,
                                                                        "type" : $TYPE
                                                                    }' | yq --prettyPrint "[.]" > "$TEMPORARY_LOG"
                                                                NOHUP="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                                nohup log "$TEMPORARY_LOG" > "$NOHUP" 2>&1 &
                                                                stall-for-process "$ORIGINATOR_PID" "$HASH" "$CREATION_TIME"
                                                            '' ;
                                                        stall-for-cleanup =
                                                            ''
                                                                HASH="$1"
                                                                CREATION_TIME="$2"
                                                                HEAD="$( stall-for-cleanup-head | tr --delete '[:space:]' )" || exit ${ builtins.toString hidden-error }
                                                                TIMESTAMP="$( date +%s )" || exit ${ builtins.toString hidden-error }
                                                                TYPE="$( basename "$0" )" || exit ${ builtins.toString hidden-error }
                                                                TEMPORARY_LOG="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                                jq \
                                                                    --null-input \
                                                                    --arg CREATION_TIME "$CREATION_TIME" \
                                                                    --arg HASH "$HASH" \
                                                                    --arg HEAD "$HEAD" \
                                                                    --arg TIMESTAMP "$TIMESTAMP" \
                                                                    --arg TYPE "$TYPE" \
                                                                        '{
                                                                            "creation-time" : $CREATION_TIME ,
                                                                            "hash" : $HASH ,
                                                                            "head" : $HEAD ,
                                                                            "timestamp" : $TIMESTAMP ,
                                                                            "type" : $TYPE
                                                                        }' | yq --prettyPrint "[.]" > "$TEMPORARY_LOG"
                                                                NOHUP="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                                nohup log "$TEMPORARY_LOG" > "$NOHUP" 2>&1 &
                                                                mkdir --parents ${ resources-directory }/links ${ resources-directory }/bad
                                                                if [[ -n "$HEAD" ]]
                                                                then
                                                                    inotifywait --event move_self "$HEAD" --quiet
                                                                    stall-for-cleanup
                                                                else
                                                                    teardown "$HASH" "$CREATION_TIME"
                                                                fi
                                                            '' ;
                                                        stall-for-cleanup-head =
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
                                                                done | head --lines 1 | tr --delete '[:space:]'
                                                            '' ;
                                                        stall-for-process =
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
                                                                    --arg HASH "$HASH" \
                                                                    --arg ORIGINATOR_PID "$ORIGINATOR_PID" \
                                                                    --arg TIMESTAMP "$TIMESTAMP" \
                                                                    --arg TYPE "$TYPE" \
                                                                        '{
                                                                            "creation-time" : $CREATION_TIME ,
                                                                            "hash" : $HASH ,
                                                                            "originator-pid" : $ORIGINATOR_PID ,
                                                                            "timestamp" : $TIMESTAMP ,
                                                                            "type" : $TYPE
                                                                        }' | yq --prettyPrint "[.]" > "$TEMPORARY_LOG"
                                                                NOHUP="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                                nohup log "$TEMPORARY_LOG" > "$NOHUP" 2>&1 &
                                                                tail --follow /dev/null --pid "$ORIGINATOR_PID"
                                                                stall-for-cleanup "$HASH" "$CREATION_TIME"
                                                            '' ;
                                                        stall-for-symlink =
                                                            ''
                                                                SYMLINK="$1"
                                                                TIMESTAMP="$( date +%s )" || exit ${ builtins.toString hidden-error }
                                                                TYPE="$( basename "$0" )" || exit ${ builtins.toString hidden-error }
                                                                TEMPORARY_LOG="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                                jq \
                                                                    --null-input \
                                                                    --arg SYMLINK "$SYMLINK" \
                                                                    --arg TIMESTAMP "$TIMESTAMP" \
                                                                    --arg TYPE "$TYPE" \
                                                                    '{
                                                                        "symlink" : $SYMLINK ,
                                                                        "timestamp" : $TIMESTAMP ,
                                                                        "type" : $TYPE
                                                                    }' | yq --prettyPrint "[.]" > "$TEMPORARY_LOG"
                                                                NOHUP="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                                nohup log "$TEMPORARY_LOG" > "$NOHUP" 2>&1 &
                                                                inotifywait --event move_self "$SYMLINK" --quiet
                                                            '' ;
                                                        teardown =
                                                            ''
                                                                HASH="$1"
                                                                CREATION_TIME="$2"
                                                                flock -u 201
                                                                exec 201>&-
                                                                exec 201> ${ resources-directory }/locks/teardown.lock
                                                                echo "9058f107-e00f-4ef2-9342-40a213f43f26" >> /tmp/DEBUG
                                                                flock -x 201
                                                                echo "b6c84f97-6b5a-4318-b42e-1cec229c6a99" >> /tmp/DEBUG
                                                                exec 202> ${ resources-directory }/locks/setup.lock
                                                                echo "f61dcf3c-38e7-4331-a9b6-8653fda02c89" >> /tmp/DEBUG
                                                                flock -x 202
                                                                echo "2c28511c-af4f-4e7c-9a98-01db7f750950" >> /tmp/DEBUG
                                                                if [[ ! -d "${ resources-directory }/mounts/$HASH" ]] || [[ "$( stat --format "%W" "${ resources-directory }/mounts/$HASH" )" != "$CREATION_TIME" ]]
                                                                then
                                                                    echo "4489ba95-211f-4963-be37-5bd2bfa0955b" >> /tmp/DEBUG
                                                                    teardown-aborted "$HASH" "$CREATION_TIME"
                                                                else
                                                                    echo "51c2a72f-2f49-4224-83a1-335c351b1972" >> /tmp/DEBUG
                                                                    teardown-completed "$HASH" "$CREATION_TIME"
                                                                fi
                                                                echo "2823f6b5-b006-405f-a684-b814870f7b2c" >> /tmp/DEBUG
                                                            '' ;
                                                        teardown-aborted =
                                                            ''
                                                                HASH="$1"
                                                                CREATION_TIME="$2"
                                                                TIMESTAMP="$( date +%s )" || exit ${ builtins.toString hidden-error }
                                                                TYPE="$( basename "$0" )" || exit ${ builtins.toString hidden-error }
                                                                TEMPORARY_LOG="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                                jq \
                                                                    --null-input \
                                                                    --arg CREATION_TIME "$CREATION_TIME" \
                                                                    --arg HASH "$HASH" \
                                                                    --arg TIMESTAMP "$TIMESTAMP" \
                                                                    --arg TYPE "$TYPE" \
                                                                    '{
                                                                        "creation-time" : $CREATION_TIME ,
                                                                        "hash" : $HASH ,
                                                                        "timestamp" : $TIMESTAMP ,
                                                                        "type" : $TYPE
                                                                    }' | yq --prettyPrint "[.]" > "$TEMPORARY_LOG"
                                                                log "$TEMPORARY_LOG"
                                                            '' ;
                                                        teardown-completed =
                                                                if builtins.typeOf release == "null" then
                                                                    ''
                                                                        HASH="$1"
                                                                        CREATION_TIME="$2"
                                                                        teardown-final "$HASH" "$CREATION_TIME"
                                                                    ''
                                                                else
                                                                    ''
                                                                        echo "ebe4993e-3414-4671-ae78-506369fca9d6" >> /tmp/DEBUG
                                                                        HASH="$1"
                                                                        echo "2d8b1aa4-72c1-49e4-a2d2-a7bf3f681ae8" >> /tmp/DEBUG
                                                                        CREATION_TIME="$2"
                                                                        echo "59af58c0-aef8-4938-939b-70abd13e5157" >> /tmp/DEBUG
                                                                        STANDARD_OUTPUT="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                                        echo "519d2bb0-6341-40ee-9a34-ebf616d72a4d" >> /tmp/DEBUG
                                                                        STANDARD_ERROR="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                                        echo "24946981-8fd8-4bc6-be46-d74461d2c613" >> /tmp/DEBUG
                                                                        if ${ release-application }/bin/release-application > "$STANDARD_OUTPUT" 2> "$STANDARD_ERROR"
                                                                        then
                                                                            STATUS="$?"
                                                                        else
                                                                            STATUS="$?"
                                                                        fi
                                                                        flock -u 202
                                                                        exec 202>&-
                                                                        echo "dc95cee1-f935-450d-94a1-4989bfe31893 STATUS=$STATUS STANDARD_ERROR=$STANDARD_ERROR" >> /tmp/DEBUG
                                                                        if [[ "$STATUS" == "0" ]] && [[ ! -s "$STANDARD_ERROR" ]]
                                                                        then
                                                                            echo "5ef8aeaf-5977-4439-86c3-bfb83f6b0c49" >> /tmp/DEBUG
                                                                            teardown-final "$HASH" "$CREATION_TIME"
                                                                        else
                                                                            echo "805ffcbf-1b7a-4ed3-9277-be18925462ef" >> /tmp/DEBUG
                                                                            bad "$HASH" "$STATUS" "$STANDARD_OUTPUT" "$STANDARD_ERROR" false ""
                                                                            echo "13ada047-be29-497f-8d02-ef1abdcfc80d" >> /tmp/DEBUG
                                                                        fi
                                                                        echo "5dff7637-081d-4335-8748-871fccfab11d" >> /tmp/DEBUG
                                                                    '' ;
                                                        teardown-final =
                                                            ''
                                                                HASH="$1"
                                                                CREATION_TIME="$2"
                                                                TIMESTAMP="$( date +%s )" || exit ${ builtins.toString hidden-error }
                                                                TYPE="$( basename "$0" )" || exit ${ builtins.toString hidden-error }
                                                                TEMPORARY_LOG="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                                GOOD="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                                mkdir --parents "$GOOD"
                                                                ${ if builtins.typeOf init == "null" then "#" else ''mv "${ resources-directory }/links/$HASH" "$GOOD/links"'' }
                                                                mv "${ resources-directory }/mounts/$HASH" "$GOOD/mounts"
                                                                rm --recursive "${ resources-directory }/locks/$HASH"
                                                                TEMPORARY_LOG="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                                jq \
                                                                    --null-input \
                                                                    --arg CREATION_TIME "$CREATION_TIME" \
                                                                    --arg GOOD "$GOOD" \
                                                                    --arg HASH "$HASH" \
                                                                    --arg TIMESTAMP "$TIMESTAMP" \
                                                                    --arg TYPE "$TYPE" \
                                                                    '{
                                                                        "creation-time" : $CREATION_TIME ,
                                                                        "good" : $GOOD ,
                                                                        "hash" : $HASH ,
                                                                        "timestamp" : $TIMESTAMP ,
                                                                        "type" : $TYPE
                                                                    }' | yq --prettyPrint "[.]" > "$TEMPORARY_LOG"
                                                                log "$TEMPORARY_LOG"
                                                            '' ;
                                                        temporary =
                                                            ''
                                                                mkdir --parents ${ resources-directory }/temporary
                                                                mktemp --dry-run ${ resources-directory }/temporary/XXXXXXXX
                                                            '' ;
                                                    } ;
						                        in
						                            ''
						                                mkdir --parents $out/scripts
                                                        ${ builtins.concatStringsSep "\n" ( builtins.attrValues ( builtins.mapAttrs ( name : value : "makeWrapper ${ writeShellApplication { name = name ; text = value ; } }/bin/${ name } $out/bin/${ name } --set PATH $out/bin:${ makeBinPath [ coreutils findutils flock jq ps which yq-go ] }" ) scripts ) ) }
						                            '' ;
						                name = "derivation" ;
						                nativeBuildInputs = [ coreutils makeWrapper ] ;
						                src = ./. ;
						            } ;
                            in "${ derivation }/bin/setup" ;
			} ;
}
