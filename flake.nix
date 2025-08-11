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
                                                echo ff8980e6-b7cd-41c5-8772-abcc32f5e9a2 >> /tmp/DEBUG
                                                CREATION_TIME="$( stat --format "%W" "${ resources-directory }/mounts/$HASH" )" || exit ${ builtins.toString hidden-error }
                                                flock -u 202
                                                exec 202>&-
                                                HASH="$1"
                                                ORIGINATOR_PID="$2"
                                                STATUS="$3"
                                                STANDARD_OUTPUT="$4"
                                                STANDARD_ERROR="$5"
                                                echo fcd674a5-4a72-42ce-a13b-5d763eeab762 >> /tmp/DEBUG
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
                                                echo 3ae8c6f9-a688-4ba4-a028-126fa822c1cf >> /tmp/DEBUG
                                                stall "$ORIGINATOR_PID" "$HASH" "$CREATION_TIME"
                                                echo a7ea43ca-170d-4025-8516-4f963c8ada00 >> /tmp/DEBUG
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
                                                    "--ro-bind ${ resources-directory }/mounts ${ resources-directory }/mounts"
                                                    "--tmpfs /scratch"
                                                ] ;
                                            name = "init-application" ;
                                            runScript = init ;
                                        } ;
                            log =
                                writeShellApplication
                                    {
                                        name = "log" ;
                                        runtimeInputs = [ coreutils flock jq temporary yq-go ] ;
                                        text =
                                            ''
                                                echo 950fa7ce-5211-4144-8e83-7fce60ae4f90 >> /tmp/DEBUG
                                                MODE="$1"
                                                echo 21791125-8826-4365-ab1f-3ed35f1ee148 >> /tmp/DEBUG
                                                TYPE="$2"
                                                echo 65b94787-8e74-4e62-9abe-6a87eef7274d >> /tmp/DEBUG
                                                HASH="$3"
                                                echo 4c4466f1-17c6-4aaf-b80e-370337efa778 >> /tmp/DEBUG
                                                ORIGINATOR_PID="$4"
                                                echo 983c5643-705d-4ef9-8ed0-c9ed3d9cf019 >> /tmp/DEBUG
                                                STATUS="$5"
                                                echo 02f1f597-7fd4-430c-af44-82c5afea701b >> /tmp/DEBUG
                                                STANDARD_OUTPUT_FILE="$6"
                                                echo 380072ed-dc8b-497c-a3b2-5d35f80611e8 >> /tmp/DEBUG
                                                STANDARD_ERROR_FILE="$7"
                                                echo 5e496ea3-889e-4513-b0f3-5b9ca719b623 >> /tmp/DEBUG
                                                CREATION_TIME="$8"
                                                echo 28bc61a5-f0c8-429e-852a-ceb6550e45d2 >> /tmp/DEBUG
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
                                                echo "9e28ef2b-31cb-4171-ab16-57d065646ea2 $0" >> /tmp/DEBUG
                                                TEMP_FILE="$( temporary )" || exit ${ builtins.toString hidden-error }
                                                echo 36404b2c-56c0-4d62-8d60-ba74c86bc396 >> /tmp/DEBUG
                                                jq \
                                                    --null-input \
                                                    --arg CREATION_TIME "$CREATION_TIME" \
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
                                                    '{ "creation-time" : $CREATION_TIME , "hash" : $HASH , "init-application" : $INIT_APPLICATION , "mode" : $MODE , "originator-pid" : $ORIGINATOR_PID , "release-application" : $RELEASE_APPLICATION , "standard-error" : $STANDARD_ERROR , "standard-output" : $STANDARD_OUTPUT , "status" : $STATUS , "timestamp" : $TIMESTAMP , "type" : $TYPE  }' | yq --prettyPrint "[.]" > "$TEMP_FILE"
                                                mkdir --parents "${ resources-directory }/logs"
                                                echo b922e964-e899-4edb-9db5-fec62bb04c7d >> /tmp/DEBUG
                                                exec 203> "${ resources-directory }/logs/lock"
                                                echo 58234b72-98a7-48bd-ad87-ecf605ea825b >> /tmp/DEBUG
                                                flock -x 203
                                                echo 7f7af101-db4c-43bd-95e0-f4bc413ddd60 e4881399-6527-4e3b-8d17-330a4a4e7e1a >> /tmp/DEBUG
                                                cat "$TEMP_FILE" >> "${ resources-directory }/logs/log.yaml"
                                                echo c0ffe312-1ce0-498c-9093-6576d15b61e6 >> /tmp/DEBUG
                                                flock -u 203
                                                echo b7036d1e-e731-48d2-841b-00d7d2af1ae5 >> /tmp/DEBUG
                                                exec 203>&-
                                                echo f9433353-eddc-4b8f-8f45-9a5dbf5839af >> /tmp/DEBUG
                                                rm "$TEMP_FILE"
                                                echo 2b88979d-139e-45d9-b60d-8f6e81bb37c9 >> /tmp/DEBUG
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
                                                        mkdir --parents "${ resources-directory }/mounts/$HASH
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
                                                    echo c8c66c79-384d-4bb1-aba4-d7b774bf0617 >> /tmp/DEBUG
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
                                                    HASH="$( echo "${ hash } ${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[*]" "}" ] } $STANDARD_INPUT $HAS_STANDARD_INPUT" | sha512sum | cut --bytes -${ builtins.toString length } )" || exit ${ builtins.toString hash-error }
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
                                                                if [[ "$( find "${ resources-directory }/mounts/$HASH" -mindepth 1 -maxdepth 1 -exec basename {} \; | LC_ALL=C sort | tr --delete "\n" | sha512sum | cut --bytes -128 )" == ${ builtins.hashString "sha512" ( builtins.concatStringsSep "" ( builtins.sort builtins.lessThan targets ) ) } ]]
                                                                then
                                                                    nohup good "$HASH" "$ORIGINATOR_PID" "$STATUS" "$STANDARD_OUTPUT" "$STANDARD_ERROR" > /dev/null 2>&1 &
                                                                    flock -u 202
                                                                    exec 202>&-
                                                                    flock -u 201
                                                                    exec 201>&-
                                                                    echo -n "${ resources-directory }/$HASH/mounts"
                                                                    exit 0
                                                                else
                                                                    echo 4a1fa095-a9b8-4573-9b33-eedac63a03d8 >> /tmp/DEBUG
                                                                    nohup bad "$HASH" "$ORIGINATOR_PID" "$STATUS" "$STANDARD_OUTPUT" "$STANDARD_ERROR" > /dev/null 2>&1 &
                                                                    flock -u 202
                                                                    exec 202>&-
                                                                    flock -u 201
                                                                    exec 201>&-
                                                                    exit ${ builtins.toString target-error }
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
                                                                if [[ "$( find "${ resources-directory }/mounts/$HASH" -mindepth 1 -maxdepth 1 -exec basename {} \; | LC_ALL=C sort | tr --delete "\n" | sha512sum | cut --bytes -128 )" == ${ builtins.hashString "sha512" ( builtins.concatStringsSep "" ( builtins.sort builtins.lessThan targets ) ) } ]]
                                                                then
                                                                    echo d8382b1e-7ee4-4514-9c91-9ddd78c71dbd >> /tmp/DEBUG
                                                                    nohup good "$HASH" "$ORIGINATOR_PID" "$STATUS" "$STANDARD_OUTPUT" "$STANDARD_ERROR" > /dev/null 2>&1 &
                                                                    echo 2b94d977-718a-47dc-8a89-17037a294298 >> /tmp/DEBUG
                                                                    flock -u 202
                                                                    exec 202>&-
                                                                    flock -u 201
                                                                    exec 201>&-
                                                                    echo -n "${ resources-directory }/mounts/$HASH"
                                                                    exit 0
                                                                else
                                                                    echo ab4f151b-5923-426e-833e-2b69cbfcef77 >> /tmp/DEBUG
                                                                    nohup bad "$HASH" "$ORIGINATOR_PID" "$STATUS" "$STANDARD_OUTPUT" "$STANDARD_ERROR" > /dev/null 2>&1 &
                                                                    flock -u 202
                                                                    exec 202>&-
                                                                    flock -u 201
                                                                    exec 201>&-
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
                                                    echo 935c5f66-af2e-4e43-a116-df3fa96a15b1 >> /tmp/DEBUG
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
                                                        echo 680b0487-ab88-4535-961a-644a7e5b5f62 17309d8c-7e9c-4853-b9ca-1ebed6967fc1 >> /tmp/DEBUG
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
                                                        if ${ release-application }/bin/release > "$STANDARD_OUTPUT" 2> "$STANDARD_ERROR"
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
                            stall =
                                writeShellApplication
                                    {
                                        name = "stall" ;
                                        runtimeInputs = [ coreutils inotify-tools teardown ] ;
                                        text =
                                            ''
                                                echo a2515a22-281c-4470-95d1-900e9bac8604 >> /tmp/DEBUG
                                                ORIGINATOR_PID="$1"
                                                HASH="$2"
                                                CREATION_TIME="$3"
                                                echo 54e89396-3112-49bc-b023-8b8f1e3428a2 >> /tmp/DEBUG
                                                tail --follow /dev/null --pid "$ORIGINATOR_PID"
                                                echo 28d181a5-0874-4271-b467-749c54af5756 >> /tmp/DEBUG
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
                                                echo 95323eab-79cd-436b-b64d-ea24db8266ad >> /tmp/DEBUG
                                                teardown "$HASH" "$ORIGINATOR_PID" "$CREATION_TIME"
                                                echo bc959380-4f0b-4183-af99-8cc578f6bf58 >> /tmp/DEBUG
                                            '' ;
                                    } ;
                            in "${ setup }/bin/setup" ;
			} ;
}
