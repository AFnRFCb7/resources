{
	inputs = { } ;
	outputs =
		{ self } :
		    {
		        lib =
                    {
                        buildFHSUserEnv ,
                        creation-time-error ? 153 ,
                        description ? null ,
                        coreutils ,
                        echo-error ? 102 ,
                        errors ? { } ,
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
                        transient ? false ,
                        uuidlib ,
                        uuid-error ? 112 ,
                        visitor ,
                        yq-go ,
                        writeShellApplication
                    } @primary :
                        let
                            check =
                                {
                                    arguments ,
                                    checkpoint-pre ,
                                    checkpoint-post ,
                                    commands ,
                                    diffutils ,
                                    label ,
                                    mount ,
                                    standard-input  ,
                                    status ,
                                    test-directory
                                } :
                                    mkDerivation
                                        {
                                            installPhase = "root $out" ;
                                            name = "test-expected" ;
                                            nativeBuildInputs =
                                                let
                                                    command =
                                                        index :
                                                            let
                                                                command =
                                                                    writeShellApplication
                                                                        {
                                                                            name = "command" ;
                                                                            runtimeInputs = [ diffutils ] ;
                                                                            text =
                                                                                let
                                                                                    command = builtins.elemAt commands index ;
                                                                                    in
                                                                                        ''
                                                                                            OUT="$1"
                                                                                            echo ${ command.command } > "$OUT/${ builtins.toString index }/command"
                                                                                            ${ command.command }
                                                                                            cp --recursive ${ resources-directory } "$OUT/${ builtins.toString index }/checkpoint"
                                                                                            touch "$OUT/${ builtins.toString index }/${ builtins.toString index }/checkpoint/.gitkeep"
                                                                                            if ! diff --recursive ${ command.checkpoint } ${ resources-directory }
                                                                                            then
                                                                                                echo We expected the result of the ${ builtins.toString index }th command ${ command.command } to be ${ command.checkpoint } but it was ${ resources-directory } >&2
                                                                                                exit 148
                                                                                            fi
                                                                                        '' ;
                                                                        } ;
                                                                    in "${ command }" ;
                                                    invoke-resource =
                                                        writeShellApplication
                                                            {
                                                                name = "invoke-resource" ;
                                                                runtimeInputs = [ coreutils ] ;
                                                                text =
                                                                    ''
                                                                        OUT="$1"
                                                                        mkdir --parents "$OUT/0"
                                                                        mkdir --parents ${ test-directory }
                                                                        echo "${ implementation } ${ builtins.concatStringsSep " " arguments } ${ if builtins.typeOf standard-input == "string" then "< ${ builtins.toFile "standard-input" standard-input }" else "" } > ${ test-directory }/standard-output 2> ${ test-directory }/standard-error" > "$OUT/0/command.sh"
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
                                                                        find ${ resources-directory }/links ${ resources-directory }/locks ${ resources-directory }/mounts -maxdepth 2 -type d -exec touch {}/.gitkeep \;
                                                                        cp --recursive ${ resources-directory } "$OUT/0/checkpoint-pre"
                                                                        if ! diff --recursive ${ checkpoint-pre } "$OUT/0/checkpoint-pre"
                                                                        then
                                                                            echo ${ label } We expected the resources-directory pre initial clean to exactly match ${ checkpoint-pre } >&2
                                                                            exit 144
                                                                        fi
                                                                        # exit 185
                                                                    '' ;
                                                            } ;
                                                    root =
                                                        writeShellApplication
                                                            {
                                                                name = "root" ;
                                                                runtimeInputs = [ coreutils diffutils findutils invoke-resource stall ] ;
                                                                text =
                                                                    ''
                                                                        OUT="$1"
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
                                                                        invoke-resource "$OUT"
                                                                        stall
                                                                        find ${ resources-directory }/links ${ resources-directory }/bad ${ resources-directory }/locks ${ resources-directory }/mounts -maxdepth 1 -type d -exec touch {}/.gitkeep \;
                                                                        cp --recursive ${ resources-directory } "$OUT/0/checkpoint-post"
                                                                        if ! diff --recursive ${ checkpoint-post } "$OUT/0/checkpoint-post"
                                                                        then
                                                                            echo ${ label } We expected the resources-directory post initial clean to exactly match ${ checkpoint-post } >&2
                                                                            exit 184
                                                                        fi
                                                                        # ${ builtins.concatStringsSep "\n" ( builtins.genList ( index : let c = command index ; in ''${ c }/bin/command "$OUT"'' ) ( builtins.length commands ) ) }
                                                                        # if [[ -n "$( find ${ resources-directory }/bad -mindepth 1 -maxdepth 1 ! -name .gitkeep )" ]]
                                                                        # then
                                                                        #     echo ${ label } We expected ${ resources-directory }/bad to be an empty directory >&2
                                                                        #     exit 192
                                                                        # fi
                                                                    '' ;
                                                            } ;
                                                    stall =
                                                        writeShellApplication
                                                            {
                                                                name = "stall" ;
                                                                runtimeInputs = [ inotify-tools ] ;
                                                                text =
                                                                    if status == 0 then
                                                                        ''
                                                                            inotifywait --quiet --timeout 60 --event create ${ resources-directory }
                                                                            if [[ ! -d ${ resources-directory }/logs ]]
                                                                            then
                                                                                echo ${ label } We expected ${ resources-directory }/logs to be created >&2
                                                                                exit 246
                                                                            fi
                                                                            inotifywait --quiet --timeout 60 --event create ${ resources-directory }
                                                                            if [[ ! -d ${ resources-directory }/bad ]]
                                                                            then
                                                                                echo ${ label } We expected ${ resources-directory }/bad to be created >&2
                                                                                exit 226
                                                                            fi
                                                                        ''
                                                                    else
                                                                        ''
                                                                            inotifywait --quiet --timeout 60 --event create ${ resources-directory }
                                                                            if [[ ! -d ${ resources-directory }/bad ]]
                                                                            then
                                                                                echo ${ label } We expected ${ resources-directory }/bad to be created >&2
                                                                                exit 226
                                                                            fi
                                                                            inotifywait --quiet --timeout 60 --event create ${ resources-directory }
                                                                            if [[ ! -d ${ resources-directory }/logs ]]
                                                                            then
                                                                                echo ${ label } We expected ${ resources-directory }/logs to be created >&2
                                                                                exit 246
                                                                            fi
                                                                            sleep 10s
                                                                        '' ;
                                                            } ;
                                                    in
                                                        [ root ] ;
                                            src = ./. ;
                                        } ;
                            errors_ =
                                let
                                    defaults =
                                        let
                                            list =
                                                [
                                                    "a0721efc"
                                                    "a69f5bc2"
                                                    "a7486bbb"
                                                    "ae2d1658"
                                                    "aee914c6"
                                                    "a1b19aa5"
                                                    "a32a15dc"
                                                    "a3bc4273"
                                                    "a3c6c75b"
                                                    "b63481a0"
                                                    "bf282501"
                                                    "b07f7374"
                                                    "b385d889"
                                                    "b82279bb"
                                                    "bf995f33"
                                                    "cab66847"
                                                    "cd255035"
                                                    "c141fe3b"
                                                    "cfb26c78"
                                                    "d162db9f"
                                                    "d2cc81ec"
                                                    "dc662c73"
                                                    "df0ddf7b"
                                                    "d6df365c"
                                                    "d8a96cd7"
                                                    "e1892647"
                                                    "e4782f79"
                                                    "e139686a"
                                                    "e5fa2135"
                                                    "e9c39c16"
                                                    "ea11161a"
                                                    "f2f6f4e4"
                                                    "fb67f7f4"
                                                    "f3ead1ff"
                                                    "f66f966d"
                                                    "f696cd77"
                                                    "ffff1b30"
                                                    "f13f84ae"
                                                    "f2409776"
                                                    "f78116ae"
                                                    "f86a3eb9"
                                                    "f91c57c2"
                                                    "faa95dc4"
                                                    "f9b0e418"
                                                ] ;
                                            in builtins.genList ( index : { name = builtins.elemAt list index ; value = index + 100 ; } ) ( builtins.length list ) ;
                                    integers = defaults // errors ;
                                    in builtins.mapAttrs ( name : value : "exit ${ builtins.toString value }" ) integers ;
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
                                                                                "--bind $LINK /link"
                                                                                "--bind $MOUNT /mount"
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
                                                                        ARGUMENTS="$( printf '%s\n' "$@" | jq --raw-input --slurp 'split("\n")[:-1]' )" || ${ errors_.a1b19aa5 }
                                                                        LINKS=${ if builtins.typeOf init == "null" then "" else ''"$( find "$LINK" -mindepth 1 -maxdepth 1 -type l -exec basename {} \; | jq --raw-input --slurp )" || ${ errors_.bf995f33 }'' }
                                                                        TARGETS="$( find "$MOUNT" -mindepth 1 -maxdepth 1 -exec basename {} \; | jq --raw-input --slurp )" || ${ errors_.f3ead1ff }
                                                                        rm "${ resources-directory }/canonical/$HASH"
                                                                        flock -u 201
                                                                        exec 201>&-
                                                                        RECOVERY="${ resources-directory }/recovery/$MOUNT_INDEX"
                                                                        mkdir --parents "$RECOVERY"
                                                                        RECOVERY_BIN="$OUT/bin/recovery"
                                                                        # shellcheck source=/dev/null
                                                                        source "$MAKE_WRAPPER/nix-support/setup-hook"
                                                                        makeWrapper "$RECOVERY_BIN" "$RECOVERY/settle" --set ACTION settle --set HASH "$HASH" --set MOUNT_INDEX "$MOUNT_INDEX"
                                                                        makeWrapper "$RECOVERY_BIN" "$RECOVERY/repair" --set ACTION settle --set HASH "$HASH" --set MOUNT_INDEX "$MOUNT_INDEX"
                                                                        STANDARD_ERROR="$( < "$STANDARD_ERROR_FILE" )" || ${ errors_.c141fe3b }
                                                                        STANDARD_OUTPUT="$( < "$STANDARD_OUTPUT_FILE" )" || ${ errors_.f13f84ae }
                                                                        rm --force "$STANDARD_ERROR_FILE" "$STANDARD_OUTPUT_FILE"
                                                                        TYPE="$( basename "$0" )" || ${ errors_.e5fa2135 }
                                                                        NOHUP="$( temporary )" || ${ errors_.fb67f7f4 }
                                                                        jq \
                                                                            --null-input \
                                                                            --argjson ARGUMENTS "$ARGUMENTS" \
                                                                            --arg HASH "$HASH" \
                                                                            --arg HAS_STANDARD_INPUT "$HAS_STANDARD_INPUT" \
                                                                            --arg INIT_APPLICATION ${ if builtins.typeOf init-application == "null" then "null" else "${ init-application }/bin/init-application" } \
                                                                            --argjson LINKS "$LINKS" \
                                                                            --arg MOUNT_INDEX "$MOUNT_INDEX" \
                                                                            --arg RELEASE_APPLICATION ${ if builtins.typeOf release-application == "null" then "null" else "${ release-application }/bin/release-application" } \
                                                                            --arg STANDARD_ERROR "$STANDARD_ERROR" \
                                                                            --arg STANDARD_INPUT "$STANDARD_INPUT" \
                                                                            --arg STANDARD_OUTPUT "$STANDARD_OUTPUT" \
                                                                            --arg STATUS "$STATUS" \
                                                                            --argjson TARGETS "$TARGETS" \
                                                                            --arg TRANSIENT "$TRANSIENT" \
                                                                            --arg TYPE "$TYPE" \
                                                                            '{
                                                                                "arguments" : $ARGUMENTS ,
                                                                                "hash" : $HASH ,
                                                                                "has-standard-input" : $HAS_STANDARD_INPUT ,
                                                                                "init-application" : $INIT_APPLICATION ,
                                                                                "links" : $LINKS ,
                                                                                "mount-indexs" : $MOUNT_INDEX
                                                                                "release-application" : $RELEASE_APPLICATION ,
                                                                                "standard-error" : $STANDARD_ERROR ,
                                                                                "standard-input" : $STANDARD_INPUT ,
                                                                                "standard-output" : $STANDARD_OUTPUT ,
                                                                                "status" : $STATUS ,
                                                                                "targets" : $TARGETS ,
                                                                                "transient" : $TRANSIENT ,
                                                                                "type" : $TYPE
                                                                            }' | yq --prettyPrint "[.]" | nohup log-bad $HASH" > "$NOHUP" 2>&1 &
                                                                    '' ;
                                                                good =
                                                                    ''
                                                                        ARGUMENTS="$( printf '%s\n' "$@" | jq --raw-input --slurp 'split("\n")[:-1]' )" || ${ errors_.ea11161a }
                                                                        LINKS=${ if builtins.typeOf init == "null" then "" else ''"$( find "${ resource-directory }/links/$MOUNT_INDEX" -mindepth 1 -maxdepth 1 -type l -exec basename {} \; | jq --raw-input --slurp )" || ${ errors_.a7486bbb }
                                                                        STANDARD_ERROR="$( cat "$STANDARD_ERROR_FILE" )" || ${ errors_.a69f5bc2 }
                                                                        STANDARD_OUTPUT="$( cat "$STANDARD_OUTPUT_FILE" )" || ${ errors_.dc662c73 }
                                                                        rm --force "$STANDARD_ERROR_FILE" "$STANDARD_OUTPUT_FILE"
                                                                        TYPE="$( basename "$0" )" || ${ errors_.cd255035 }
                                                                        NOHUP="$( temporary )" || ${ errors_.f86a3eb9 }
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
                                                                                "transient" : $TRANSIENT ,
                                                                                "type" : $TYPE
                                                                            }' | yq --prettyPrint "[.]" | nohup log "$TEMPORARY_LOG" > "$NOHUP" 2>&1 &
                                                                        stall-for-process
                                                                    '' ;
                                                                log =
                                                                    ''
                                                                        mkdir --parents ${ resources-directory }/logs
                                                                        exec 203> ${ resources-directory }/logs/lock
                                                                        flock -x 203
                                                                        cat >> ${ resources-directory }/logs/log.yaml
                                                                    '' ;
                                                                log-bad =
                                                                    ''
                                                                        export HASH="$1"
                                                                        export TEMPORARY_LOG="$2"
                                                                        yq --null-input eval '
                                                                            {
                                                                                "expected" :
                                                                                    {
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
                                                                        TYPE="$( basename "$0" )" || ${ errors_.a32a15dc }
                                                                        NOHUP="$( temporary )" || ${ errors_.e139686a }
                                                                        jq \
                                                                            --arg CREATION_TIME "$CREATION_TIME" \
                                                                            --arg HASH "$HASH" \
                                                                            --arg ORIGINATOR_PID "$ORIGINATOR_PID" \
                                                                            --arg TRANSIENT "$TRANSIENT" \
                                                                            --arg TYPE "$TYPE" \
                                                                            --null-input \
                                                                            '{
                                                                                "creation-time" : $CREATION_TIME ,
                                                                                "hash" : $HASH ,
                                                                                "originator-pid" : $ORIGINATOR_PID ,
                                                                                "type" : $TYPE
                                                                            }' | yq --prettyPrint "[.]" | nohup log "$TEMPORARY_LOG" > "$NOHUP" 2>&1 &
                                                                        stall-for-process
                                                                    '' ;
                                                                recovery =
                                                                    ''
                                                                        GOOD="$( sequential )" || ${ errors_.f696cd77 }
                                                                        mkdir --parents ${ resources-directory }/temporary
                                                                        rm --recursive --force "$LINK"
                                                                        mv "$MOUNT" "${ resources-directory }/temporary/$GOOD"
                                                                        rm --recusive --force "$RECOVERY"
                                                                        if read -t 0
                                                                        then
                                                                            RESOLUTION="$( cat )" || ${ errors_.d8a96cd7 }
                                                                        else
                                                                            RESOLUTION="${ builtins.concatStringsSep "" [ "$" "{" "*" "}" ] }"
                                                                        fi
                                                                        TYPE="$( basename "$0" )" || exit ${ builtins.toString remediation-type-error }
                                                                        TEMPORARY_LOG="$( temporary )" || exit ${ builtins.toString remediation-temporary-error }
                                                                        jq \
                                                                            --null-input \
                                                                            --arg ACTION "$ACTION" \
                                                                            --arg HASH "$HASH" \
                                                                            --arg MOUNT_INDEX "$MOUNT_INDEX" \
                                                                            --arg RESOLUTION "$RESOLUTION" \
                                                                            --arg TYPE "$TYPE" \
                                                                            '{
                                                                                "action" : $ACTION ,
                                                                                "hash" : $HASH ,
                                                                                "mount-index" : $MOUNT_INDEX ,
                                                                                "resolution" : $RESOLUTION ,
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
                                                                        chmod 0644 ${ resources-directory }/counter.increment
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
                                                                            export ORIGINATOR_PID="$PPID"
                                                                            HASH="$( echo "${ hash } ${ builtins.concatStringsSep "" [ "$TRANSIENT" "$" "{" "ARGUMENTS[*]" "}" ] } $STANDARD_INPUT $HAS_STANDARD_INPUT" | sha512sum | cut --bytes -${ builtins.toString length } )" || exit ${ builtins.toString hash-error }
                                                                            export HASH
                                                                            mkdir --parents "${ resources-directory }/locks/$HASH"
                                                                            exec 201> "${ resources-directory }/locks/$HASH/teardown.lock"
                                                                            flock -s 201
                                                                            exec 202> "${ resources-directory }/locks/$HASH/setup.lock"
                                                                            flock -x 202
                                                                            if [[ -L "${ resources-directory }/canonical/$HASH" ]]
                                                                            then
                                                                                flock -u 202
                                                                                exec 202>&-
                                                                                MOUNT="$( readlink "${ resources-directory }/canonical/$HASH" )" || ${ errors_.bf282501 }
                                                                                export MOUNT
                                                                                NOHUP="$( temporary )" || ${ errors_.b63481a0 }
                                                                                nohup stale > "$NOHUP" 2>&1 &
                                                                                echo -n "$MOUNT"
                                                                            else
                                                                                MOUNT_INDEX="$( sequential )" || ${ errors_.d162db9f }
                                                                                MOUNT="${ resources-directory }/mounts/$MOUNT_INDEX"
                                                                                mkdir --parents "$MOUNT"
                                                                                ln --symbolic "$MOUNT" "${ resources-directory }/canonical/$HASH"
                                                                                flock -u 202
                                                                                exec 202>&-
                                                                                NOHUP="$( temporary )" || ${ errors_.f91c57c2 }
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
                                                                                STANDARD_INPUT_FILE="$( temporary )" || ${ errors_.f66f966d }
                                                                                export STANDARD_INPUT_FILE
                                                                                HAS_STANDARD_INPUT=true
                                                                                cat > "$STANDARD_INPUT_FILE"
                                                                                STANDARD_INPUT="$( cat "$STANDARD_INPUT_FILE" )" || ${ errors_.ffff1b30 }
                                                                            fi
                                                                            export HAS_STANDARD_INPUT
                                                                            export STANDARD_INPUT
                                                                            ARGUMENTS=( "$@" )
                                                                            TRANSIENT=${ transient_ }
                                                                            export TRANSIENT
                                                                            ORIGINATOR_PID=$PPID
                                                                            HASH="$( echo "${ hash } ${ builtins.concatStringsSep "" [ "$TRANSIENT" "$" "{" "ARGUMENTS[*]" "}" ] } $STANDARD_INPUT $HAS_STANDARD_INPUT" | sha512sum | cut --bytes -${ builtins.toString length } )" || exit ${ builtins.toString hash-error }
                                                                            export HASH
                                                                            mkdir --parents "${ resources-directory }/locks/$HASH"
                                                                            exec 201> "${ resources-directory }/locks/$HASH/teardown.lock"
                                                                            flock -s 201
                                                                            exec 202> "${ resources-directory }/locks/$HASH/setup.lock"
                                                                            flock -x 202
                                                                            if [[ -L "${ resources-directory }/canonical/$HASH" ]]
                                                                            then
                                                                                MOUNT="$( readlink ${ resources-directory }/canonical/$HASH }" || ${ errors_.ae2d1658 }
                                                                                export MOUNT
                                                                                flock -u 202
                                                                                exec 202>&-
                                                                                NOHUP="$( temporary )" || ${ errors_.f2f6f4e4 }
                                                                                nohup stale > "$NOHUP" 2>&1 &
                                                                                echo -n "$MOUNT"
                                                                            else
                                                                                MOUNT_INDEX="$( sequential )" || ${ errors_.cab66847 }
                                                                                LINK="${ resources-directory }/links/$MOUNT_INDEX"
                                                                                export LINK
                                                                                mkdir --parents "$LINK"
                                                                                MOUNT="${ resources-directory }/mounts/$MOUNT_INDEX"
                                                                                export MOUNT
                                                                                mkdir --parents "$MOUNT"
                                                                                STANDARD_ERROR_FILE="$( temporary )" || ${ errors_.b07f7374 }
                                                                                export STANDARD_ERROR_FILE
                                                                                STANDARD_OUTPUT_FILE="$( temporary )" || exit ${ builtins.toString standard-output-error }
                                                                                export STANDARD_OUTPUT_FILE
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
                                                                                export STATUS
                                                                                flock -u 202
                                                                                exec 202>&-
                                                                                if [[ "$STATUS" == 0 ]] && [[ ! -s "$STANDARD_ERROR_FILE" ]] && [[ "$( find "${ resources-directory }/mounts/$HASH" -mindepth 1 -maxdepth 1 -exec basename {} \; | LC_ALL=C sort | tr --delete "\n" | sha512sum | cut --bytes -128 )" == ${ builtins.hashString "sha512" ( builtins.concatStringsSep "" ( builtins.sort builtins.lessThan targets ) ) } ]]
                                                                                then
                                                                                    NOHUP="$( temporary )" || ${ errors.faa95dc4 }
                                                                                    nohup good "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" > "$NOHUP" 2>&1 &
                                                                                    echo -n "$MOUNT"
                                                                                else
                                                                                    NOHUP="$( temporary )" || ${ errors.aee914c6 }
                                                                                    nohup bad "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" > "$NOHUP" 2>&1 &
                                                                                    ${ errors_.b385d889 }
                                                                                fi
                                                                            fi
                                                                        '' ;
                                                                stale =
                                                                    ''
                                                                        MOUNT_INDEX="$( basename "$MOUNT" )" || ${ errors_.d6df365c }
                                                                        TYPE="$( basename "$0" )" || ${ errors_.d2cc81ec }
                                                                        NOHUP="$( temporary )" || ${ errors_.a3c6c75b }
                                                                        jq \
                                                                            --null-input \
                                                                            --arg HASH "$HASH" \
                                                                            --arg MOUNT_INDEX "$MOUNT_INDEX"
                                                                            --arg TRANSIENT "$TRANSIENT" \
                                                                            --arg TYPE "$TYPE" \
                                                                            '{
                                                                                "hash" : $HASH ,
                                                                                "mount-index" : $MOUNT_INDEX ,
                                                                                "type" : $TYPE
                                                                            }' | yq --prettyPrint "[.]" | nohup log > "$NOHUP" 2>&1 &
                                                                        stall-for-process
                                                                    '' ;
                                                                stall-for-cleanup =
                                                                    ''
                                                                        HEAD="$( stall-for-cleanup-head | tr --delete '[:space:]' )" || ${ errors_.f9b0e418 }
                                                                        TYPE="$( basename "$0" )" || ${ errors_.e4782f79 }
                                                                        NOHUP="$( temporary )" || ${ errors_.df0ddf7b }
                                                                        jq \
                                                                            --null-input \
                                                                            --arg CREATION_TIME "$CREATION_TIME" \
                                                                            --arg HASH "$HASH" \
                                                                            --arg HEAD "$HEAD" \
                                                                            --arg TYPE "$TYPE" \
                                                                                '{
                                                                                    "hash" : $HASH ,
                                                                                    "head" : $HEAD ,
                                                                                    "type" : $TYPE
                                                                                }' | yq --prettyPrint "[.]" | nohup log > "$NOHUP" 2>&1 &
                                                                        mkdir --parents ${ resources-directory }/links ${ resources-directory }/bad
                                                                        if [[ -n "$HEAD" ]]
                                                                        then
                                                                            inotifywait --event move_self "$HEAD" --quiet
                                                                            stall-for-cleanup
                                                                        else
                                                                            teardown
                                                                        fi
                                                                    '' ;
                                                                stall-for-cleanup-head =
                                                                    ''
                                                                        mkdir --parents ${ resources-directory }/links
                                                                        find ${ resources-directory }/links -mindepth 2 -maxdepth 2 -type l | while read -r CANDIDATE
                                                                        do
                                                                            RESOLVED="$( readlink --canonicalize "$CANDIDATE" )" || ${ errors_1.e9c39c16 }
                                                                            if [[ "$RESOLVED" == "$MOUNT" ]]
                                                                            then
                                                                                echo "$CANDIDATE"
                                                                                exit 0
                                                                            fi
                                                                        done | head --lines 1 | tr --delete '[:space:]'
                                                                    '' ;
                                                                stall-for-process =
                                                                    ''
                                                                        TYPE="$( basename "$0" )" || ${ errors_.a3bc4273 }
                                                                        NOHUP="$( temporary )" || ${ errors_.e1892647 }
                                                                        jq \
                                                                            --null-input \
                                                                            --arg CREATION_TIME "$CREATION_TIME" \
                                                                            --arg HASH "$HASH" \
                                                                            --arg ORIGINATOR_PID "$ORIGINATOR_PID" \
                                                                            --arg TYPE "$TYPE" \
                                                                                '{
                                                                                    "hash" : $HASH ,
                                                                                    "originator-pid" : $ORIGINATOR_PID ,
                                                                                    "type" : $TYPE
                                                                                }' | yq --prettyPrint "[.]" | nohup log > "$NOHUP" 2>&1 &
                                                                        tail --follow /dev/null --pid "$ORIGINATOR_PID"
                                                                        stall-for-cleanup
                                                                    '' ;
                                                                stall-for-symlink =
                                                                    ''
                                                                        SYMLINK="$1"
                                                                        TYPE="$( basename "$0" )" || exit ${ builtins.toString hidden-error }
                                                                        TEMPORARY_LOG="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                                        jq \
                                                                            --null-input \
                                                                            --arg SYMLINK "$SYMLINK" \
                                                                            --arg TYPE "$TYPE" \
                                                                            '{
                                                                                "symlink" : $SYMLINK ,
                                                                                "type" : $TYPE
                                                                            }' | yq --prettyPrint "[.]" > "$TEMPORARY_LOG"
                                                                        NOHUP="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                                        nohup log "$TEMPORARY_LOG" > "$NOHUP" 2>&1 &
                                                                        inotifywait --event move_self "$SYMLINK" --quiet
                                                                    '' ;
                                                                teardown =
                                                                    ''
                                                                        flock -u 201
                                                                        exec 201>&-
                                                                        exec 201> ${ resources-directory }/locks/teardown.lock
                                                                        flock -x 201
                                                                        exec 202> ${ resources-directory }/locks/setup.lock
                                                                        flock -x 202
                                                                        if [[ -L "${ resources-directory }/canonical/$HASH" ]]
                                                                        then
                                                                            CANDIDATE="$( readlink "${ resources-directory }/canonical/$HASH" )" || ${ errors_.cfb26c78 }
                                                                            if [[ "$MOUNT" == "$CANDIDATE" ]]
                                                                            then
                                                                                teardown-completed
                                                                            else
                                                                                teardown-aborted
                                                                        else
                                                                            teardown-aborted
                                                                        fi
                                                                    '' ;
                                                                teardown-aborted =
                                                                    ''
                                                                        HASH="$1"
                                                                        TYPE="$( basename "$0" )" || ${ errors_.f75c4adf }
                                                                        jq \
                                                                            --null-input \
                                                                            --arg CREATION_TIME "$CREATION_TIME" \
                                                                            --arg HASH "$HASH" \
                                                                            --arg TYPE "$TYPE" \
                                                                            '{
                                                                                "creation-time" : $CREATION_TIME ,
                                                                                "hash" : $HASH ,
                                                                                "type" : $TYPE
                                                                            }' | yq --prettyPrint "[.]" | log
                                                                    '' ;
                                                                teardown-completed =
                                                                    if builtins.typeOf release == "null" then
                                                                        ''
                                                                            teardown-final
                                                                        ''
                                                                    else
                                                                        ''
                                                                            STANDARD_OUTPUT_FILE="$( temporary )" || ${ errors_.a0721efc }
                                                                            export STANDARD_OUTPUT_FILE
                                                                            STANDARD_ERROR_FILE="$( temporary )" || ${ errors_.f78116ae }
                                                                            export STANDARD_ERROR_FILE
                                                                            if ${ release-application }/bin/release-application > "$STANDARD_OUTPUT_FILE" 2> "$STANDARD_ERROR_FILE"
                                                                            then
                                                                                STATUS="$?"
                                                                            else
                                                                                STATUS="$?"
                                                                            fi
                                                                            flock -u 202
                                                                            exec 202>&-
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
                                                                        TYPE="$( basename "$0" )" || ${ errors_.f2409776 }
                                                                        GOOD="$( temporary )" || ${ errors_.b82279bb }
                                                                        mkdir --parents "$GOOD"
                                                                        ${ if builtins.typeOf init == "null" then "#" else ''rm --recursive --force "$LINK"'' }
                                                                        mv "$MOUNT" "$GOOD"
                                                                        jq \
                                                                            --null-input \
                                                                            --arg CREATION_TIME "$CREATION_TIME" \
                                                                            --arg GOOD "$GOOD" \
                                                                            --arg HASH "$HASH" \
                                                                            --arg TYPE "$TYPE" \
                                                                            '{
                                                                                "creation-time" : $CREATION_TIME ,
                                                                                "good" : $GOOD ,
                                                                                "hash" : $HASH ,
                                                                                "type" : $TYPE
                                                                            }' | yq --prettyPrint "[.]" | log
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
                                                                ${ builtins.concatStringsSep "\n" ( builtins.attrValues ( builtins.mapAttrs ( name : value : "makeWrapper ${ writeShellApplication { name = name ; text = value ; } }/bin/${ name } $out/bin/${ name } --set MAKE_WRAPPER ${ makeWrapper } set OUT $out --set PATH $out/bin:${ makeBinPath [ coreutils findutils flock jq ps uuidlib yq-go ] }" ) scripts ) ) }
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
