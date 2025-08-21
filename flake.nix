{
	inputs = { } ;
	outputs =
		{ self } :
		    {
		        lib =
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
                        standard-status-error ? 108 ,
                        target-error ? 106 ,
                        targets ? [ ] ,
                        timestamp-error ? 139 ,
                        transient ? false ,
                        uuidlib ,
                        uuid-error ? 112 ,
                        visitor ,
                        yq-go ,
                        which ,
                        writeShellApplication
                    } @primary :
                        let
                            check =
                                {
                                    arguments ,
                                    commands ,
                                    label ,
                                    mount ,
                                    standard-input  ,
                                    status ,
                                    test-directory
                                } :
                                    mkDerivation
                                        {
                                            installPhase = "root $out" ;
                                            name = "test" ;
                                            nativeBuildInputs =
                                                let
                                                    invoke-resource =
                                                        writeShellApplication
                                                            {
                                                                name = "invoke-resource" ;
                                                                runtimeInputs = [ coreutils ] ;
                                                                text =
                                                                    ''
                                                                        mkdir --parents ${ test-directory }
                                                                        if ${ implementation } ${ builtins.concatStringsSep " " arguments } ${ if builtins.typeOf standard-input == "string" then "< ${ builtins.toFile "standard-input" standard-input }" else "" } > ${ test-directory }/standard-output 2> ${ test-directory }/standard-error
                                                                        then
                                                                            MOUNT="$( < ${ test-directory }/standard-output )" || exit ${ builtins.toString hidden-error }
                                                                            if [[ ! -d "$MOUNT" ]]
                                                                            then
                                                                                echo "${ label } command succeeded but mount $MOUNT is not a directory" >&2
                                                                                exit 216
                                                                            elif [[ "$MOUNT" != "${ mount }" ]]
                                                                            then
                                                                                echo "${ label } command succeeded but mount $MOUNT is not the expected directory ${ mount }" >&2
                                                                                exit 102
                                                                            fi
                                                                            if [[ -s ${ test-directory }/standard-error ]]
                                                                            then
                                                                                echo "${ label } command succeeded but it generated standard-error" >&2
                                                                                exit 133
                                                                            fi
                                                                            ${ if status != 0 then ''exit 148'' else "# " }
                                                                        else
                                                                            STATUS="$?"
                                                                            if [[ "$STATUS" != "${ builtins.toString status }" ]]
                                                                            then
                                                                                echo "${ label } command failed but we expected the status to be ${ builtins.toString status } and we observed $STATUS" >&2
                                                                                exit 249
                                                                            fi
                                                                            if [[ -s ${ test-directory }/standard-output ]]
                                                                            then
                                                                                echo "${ label } command failed but it generated standard-output"
                                                                                exit 113
                                                                            fi
                                                                            if [[ -s ${ test-directory }/standard-error ]]
                                                                            then
                                                                                cat ${ test-directory }/standard-error
                                                                                echo "${ label } command failed but it generated standard-error"
                                                                                exit 163
                                                                            fi
                                                                        fi
                                                                        # exit 185
                                                                    '' ;
                                                            } ;
                                                    root =
                                                        writeShellApplication
                                                            {
                                                                name = "root" ;
                                                                runtimeInputs = [ coreutils invoke-resource findutils ] ;
                                                                text =
                                                                    ''
                                                                        OUT="$1"
                                                                        touch "$OUT"
                                                                        if [[ -e ${ resources-directory } ]]
                                                                        then
                                                                            echo ${ label } We expected the resources directory to not initially exist >&2
                                                                            exit 179
                                                                        fi
                                                                        if [[ -e ${ test-directory } ]]
                                                                        then
                                                                            echo ${ label } We expected the test directory to not initially exit >&2
                                                                            exit 135
                                                                        fi
                                                                        invoke-resource
                                                                        sleep 10s
                                                                        find ${ resources-directory } >&2
                                                                        if [[ ! -d ${ resources-directory }/bad ]]
                                                                        then
                                                                            cat ${ resources-directory }/logs/log.yaml
                                                                            echo ${ label } We expected ${ resources-directory }/bad to be an existing directory >&2
                                                                            exit 226
                                                                        fi
                                                                        # if [[ -n "$( find ${ resources-directory }/bad -mindepth 1 -maxdepth 1 )" ]]
                                                                        # then
                                                                        #     echo ${ label } We expected the ${ resources-directory }/bad to be an empty directory >&2
                                                                        #     exit 192
                                                                        # fi
                                                                    '' ;
                                                            } ;
                                                    in
                                                        [ root ] ;
                                            src = ./. ;
                                        } ;
                            implementation =
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
                                                                        HASH="$1"
                                                                        TRANSIENT="$2"
                                                                        STATUS="$3"
                                                                        STANDARD_OUTPUT_FILE="$4"
                                                                        STANDARD_ERROR_FILE="$5"
                                                                        HAS_STANDARD_INPUT="$6"
                                                                        STANDARD_INPUT="$7"
                                                                        shift 7
                                                                        ARGUMENTS="$( printf '%s\n' "$@" | jq --raw-input --slurp 'split("\n")[:-1]' )" || exit ${ builtins.toString hidden-error }
                                                                        CREATION_TIME="$( stat --format "%W" "${ resources-directory }/mounts/$HASH" )" || exit ${ builtins.toString hidden-error }
                                                                        LINKS=${ if builtins.typeOf init == "null" then "" else ''"$( find "${ resources-directory }/links/$HASH" -mindepth 1 -maxdepth 1 -type l -exec basename {} \; | jq --raw-input --slurp )" || exit ${ builtins.toString hidden-error }'' }
                                                                        TARGETS="$( find "${ resources-directory }/mounts/$HASH" -mindepth 1 -maxdepth 1 -exec basename {} \; | jq --raw-input --slurp )" || exit ${ builtins.toString hidden-error }
                                                                        TIMESTAMP="$( date +%s )" || exit ${ builtins.toString hidden-error }
                                                                        mkdir --parents ${ resources-directory }/bad
                                                                        SEQUENCE="$( sequential )" || exit ${ builtins.toString hidden-error }
                                                                        BAD="${ resources-directory }/bad/$SEQUENCE"
                                                                        mkdir --parents "$BAD"
                                                                        ${ if builtins.typeOf init == "null" then "#" else ''cp --recursive "${ resources-directory }/links/$HASH" "$BAD/links"'' }
                                                                        rm --recursive --force "${ resources-directory }/locks/$HASH"
                                                                        mv "${ resources-directory }/mounts/$HASH" "$BAD/mounts"
                                                                        flock -u 201
                                                                        exec 201>&-
                                                                        RESOLVE="$( which resolve )" || exit ${ builtins.toString hidden-error }
                                                                        # shellcheck source=/dev/null
                                                                        source "$MAKE_WRAPPER/nix-support/setup-hook"
                                                                        makeWrapper "$RESOLVE" "$BAD/settle" --set BAD "$BAD" --set CREATION_TIME "$CREATION_TIME" --set HASH "$HASH" --set ACTION settle
                                                                        makeWrapper "$RESOLVE" "$BAD/repair" --set BAD "$BAD" --set CREATION_TIME "$CREATION_TIME" --set HASH "$HASH" --set ACTION repair
                                                                        ln --symbolic "$RESOLVE" "$BAD/resolve.sh"
                                                                        ${ if builtins.typeOf init == "null" then "#" else ''rm --recursive --force "${ resources-directory }/links/$HASH"'' }
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
                                                                            --arg TRANSIENT "$TRANSIENT" \
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
                                                                                "transient" : $TRANSIENT ,
                                                                                "type" : $TYPE
                                                                            }' | yq --prettyPrint "[.]" > "$TEMPORARY_LOG"
                                                                        NOHUP="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                                        nohup log-bad "$BAD" "$CREATION_TIME" "$HASH" "$TEMPORARY_LOG" > "$NOHUP" 2>&1 &
                                                                    '' ;
                                                                good =
                                                                    ''
                                                                        HASH="$1"
                                                                        ORIGINATOR_PID="$2"
                                                                        TRANSIENT="$3"
                                                                        STATUS="$4"
                                                                        STANDARD_OUTPUT_FILE="$5"
                                                                        STANDARD_ERROR_FILE="$6"
                                                                        HAS_STANDARD_INPUT="$7"
                                                                        STANDARD_INPUT="$8"
                                                                        shift 8
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
                                                                            --arg TRANSIENT "$TRANSIENT" \
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
                                                                                "transient" : $TRANSIENT ,
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
                                                                            --arg TRANSIENT "$TRANSIENT" \
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
                                                                            --arg ACTION "$ACTION" \
                                                                            --arg BAD "$BAD" \
                                                                            --arg CREATION_TIME "$CREATION_TIME" \
                                                                            --arg GOOD "$GOOD" \
                                                                            --arg HASH "$HASH" \
                                                                            --arg RESOLUTION "$RESOLUTION" \
                                                                            --arg TIMESTAMP "$TIMESTAMP" \
                                                                            --arg TYPE "$TYPE" \
                                                                            '{
                                                                                "action" : $ACTION ,
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
                                                                sequential =
                                                                    ''
                                                                        mkdir --parents ${ resources-directory }
                                                                        exec 205> ${ resources-directory }/counter.lock
                                                                        flock -x 205
                                                                        if [[ -s ${ resources-directory }/counter.increment ]]
                                                                        then
                                                                            OLD="$( < ${ resources-directory }/counter.increment )" || exit ${ builtins.toString hidden-error }
                                                                        else
                                                                            OLD="0"
                                                                        fi
                                                                        NEW=$(( OLD + 1 ))
                                                                        echo "$NEW" > ${ resources-directory }/counter.increment
                                                                        chmod 0600 ${ resources-directory }/counter.increment
                                                                        printf "%08d\n" "$NEW"
                                                                    '' ;
                                                                setup =
                                                                    if builtins.typeOf init == "null" then
                                                                        ''
                                                                            if [[ -t 0 ]]
                                                                            then
                                                                                HAS_STANDARD_INPUT=false
                                                                                STANDARD_INPUT=
                                                                                STANDARD_INPUT_FILE="$( temporary )" || exit ${ builtins.toString standard-input-temporary-error }
                                                                            else
                                                                                HAS_STANDARD_INPUT=true
                                                                                timeout 1m cat > "$STANDARD_INPUT_FILE"
                                                                                STANDARD_INPUT="$( cat "$STANDARD_INPUT_FILE" )" || exit ${ builtins.toString standard-input-cat-error }
                                                                                rm "$STANDARD_INPUT_FILE"
                                                                            fi
                                                                            TRANSIENT=${ transient_ }
                                                                            ORIGINATOR_PID="$PPID"
                                                                            HASH="$( echo "${ hash } ${ builtins.concatStringsSep "" [ "$TRANSIENT" "$" "{" "ARGUMENTS[*]" "}" ] } $STANDARD_INPUT $HAS_STANDARD_INPUT" | sha512sum | cut --bytes -${ builtins.toString length } )" || exit ${ builtins.toString hash-error }
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
                                                                            if [[ -t 0 ]]
                                                                            then
                                                                                HAS_STANDARD_INPUT=false
                                                                                STANDARD_INPUT=
                                                                            else
                                                                                STANDARD_INPUT_FILE="$( temporary )" || exit ${ builtins.toString standard-input-temporary-error }
                                                                                export STANDARD_INPUT_FILE
                                                                                HAS_STANDARD_INPUT=true
                                                                                cat > "$STANDARD_INPUT_FILE"
                                                                                STANDARD_INPUT="$( cat "$STANDARD_INPUT_FILE" )" || exit ${ builtins.toString standard-input-cat-error }
                                                                            fi
                                                                            ARGUMENTS=( "$@" )
                                                                            TRANSIENT=${ transient_ }
                                                                            ORIGINATOR_PID=$PPID
                                                                            HASH="$( echo "${ hash } ${ builtins.concatStringsSep "" [ "$TRANSIENT" "$" "{" "ARGUMENTS[*]" "}" ] } $STANDARD_INPUT $HAS_STANDARD_INPUT" | sha512sum | cut --bytes -${ builtins.toString length } )" || exit ${ builtins.toString hash-error }
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
                                                                                STANDARD_ERROR_FILE="$( temporary )" || exit ${ builtins.toString standard-error-error }
                                                                                STANDARD_OUTPUT_FILE="$( temporary )" || exit ${ builtins.toString standard-output-error }
                                                                                if [[ "$HAS_STANDARD_INPUT" == "true" ]]
                                                                                then
                                                                                    if ${ init-application }/bin/init-application "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" < "$STANDARD_INPUT_FILE" > "$STANDARD_OUTPUT_FILE" 2> "$STANDARD_ERROR_FILE"
                                                                                    then
                                                                                        STATUS="$?"
                                                                                    else
                                                                                        STATUS="$?"
                                                                                    fi
                                                                                    rm "$STANDARD_INPUT_FILE"
                                                                                else
                                                                                    if ${ init-application }/bin/init-application "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" > "$STANDARD_OUTPUT_FILE" 2> "$STANDARD_ERROR_FILE"
                                                                                    then
                                                                                        STATUS="$?"
                                                                                    else
                                                                                        STATUS="$?"
                                                                                    fi
                                                                                fi
                                                                                flock -u 202
                                                                                exec 202>&-
                                                                                if [[ "$STATUS" == 0 ]] && [[ ! -s "$STANDARD_ERROR_FILE" ]] && [[ "$( find "${ resources-directory }/mounts/$HASH" -mindepth 1 -maxdepth 1 -exec basename {} \; | LC_ALL=C sort | tr --delete "\n" | sha512sum | cut --bytes -128 )" == ${ builtins.hashString "sha512" ( builtins.concatStringsSep "" ( builtins.sort builtins.lessThan targets ) ) } ]]
                                                                                then
                                                                                    nohup good "$HASH" "$ORIGINATOR_PID" "$TRANSIENT" "$STATUS" "$STANDARD_OUTPUT_FILE" "$STANDARD_ERROR_FILE" "$HAS_STANDARD_INPUT" "$STANDARD_INPUT" "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" > /dev/null 2>&1 &
                                                                                    echo -n "${ resources-directory }/mounts/$HASH"
                                                                                else
                                                                                    nohup bad "$HASH" "$TRANSIENT" "$STATUS" "$STANDARD_OUTPUT_FILE" "$STANDARD_ERROR_FILE" "$HAS_STANDARD_INPUT" "$STANDARD_INPUT" "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" > /dev/null 2>&1 &
                                                                                    exit ${ builtins.toString initialization-error }
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
                                                                            --arg TRANSIENT "$TRANSIENT" \
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
                                                                        flock -x 201
                                                                        exec 202> ${ resources-directory }/locks/setup.lock
                                                                        flock -x 202
                                                                        if [[ ! -d "${ resources-directory }/mounts/$HASH" ]] || [[ "$( stat --format "%W" "${ resources-directory }/mounts/$HASH" )" != "$CREATION_TIME" ]]
                                                                        then
                                                                            teardown-aborted "$HASH" "$CREATION_TIME"
                                                                        else
                                                                            teardown-completed "$HASH" "$CREATION_TIME"
                                                                        fi
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
                                                                                HASH="$1"
                                                                                CREATION_TIME="$2"
                                                                                STANDARD_OUTPUT="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                                                STANDARD_ERROR="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                                                if ${ release-application }/bin/release-application > "$STANDARD_OUTPUT" 2> "$STANDARD_ERROR"
                                                                                then
                                                                                    STATUS="$?"
                                                                                else
                                                                                    STATUS="$?"
                                                                                fi
                                                                                flock -u 202
                                                                                exec 202>&-
                                                                                if [[ "$STATUS" == "0" ]] && [[ ! -s "$STANDARD_ERROR" ]]
                                                                                then
                                                                                    teardown-final "$HASH" "$CREATION_TIME"
                                                                                else
                                                                                    bad "$HASH" "$STATUS" "$STANDARD_OUTPUT" "$STANDARD_ERROR" false ""
                                                                                fi
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
                                                                        SEQUENCE="$( sequential )" || exit ${ builtins.toString hidden-error }
                                                                        echo "${ resources-directory }/temporary/$SEQUENCE"
                                                                    '' ;
                                                            } ;
                                                        in
                                                            ''
                                                                mkdir --parents $out/scripts
                                                                ${ builtins.concatStringsSep "\n" ( builtins.attrValues ( builtins.mapAttrs ( name : value : "makeWrapper ${ writeShellApplication { name = name ; text = value ; } }/bin/${ name } $out/bin/${ name } --set PATH $out/bin:${ makeBinPath [ coreutils findutils flock jq ps uuidlib which yq-go ] } --set MAKE_WRAPPER ${ makeWrapper }" ) scripts ) ) }
                                                            '' ;
                                                name = "derivation" ;
                                                nativeBuildInputs = [ coreutils makeWrapper ] ;
                                                src = ./. ;
                                            } ;
                                    transient_ =
                                        visitor.lib.implementation
                                            {
                                                bool = path : value : if value then ''"$( uuidgen )" || exit ${ builtins.toString uuid-error }'' else "" ;
                                                int = path : value : if value > 0 then ''"$(( $( date ) / ${ builtins.toString value } ))" || exit ${ builtins.toString uuid-error }'' else builtins.throw "non-positive time does not make sense" ;
                                                null = path : value : "" ;
                                                string = path : value : ''"$( ${ value } )" || exit ${ builtins.toString uuid-error }'' ;
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
