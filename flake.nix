{
	inputs = { } ;
	outputs =
		{ self } :
			{
				lib.implementation =
					{
						current-time ? 0 ,
						error ? 64 ,
						init-inputs ? [ ] ,
						init-text ? null ,
						length ? 64 ,
						lease ? 0 ,
						log-directory ? "/tmp/log" ,
						nixpkgs ,
						path ? null ,
						release-inputs ? [ ] ,
						release-text ? null ,
						secret-directory ? "/tmp/secrets" ,
						seed ? null ,
						self ? "SELF" ,
						system
					} @primary :
						let
							application =
								pkgs.writeShellScriptBin "application"
                                (
                                    let
                                        bad =
                                            pkgs.writeShellApplication
                                                {
                                                    name = "bad" ;
                                                    runtimeInputs = [ pkgs.coreutils ] ;
                                                    text =
                                                        ''
                                                            HASH="$1"
                                                            ORIGINATOR_PID="$2"
                                                            STATUS="$3"
                                                            STANDARD_OUTPUT="$4"
                                                            STANDARD_ERROR="$5"
                                                            GARBAGE="$( mktemp --dry-run --suffix ".tar.zst" )"
                                                            CREATION_TIME="$( stat --format "%W" "${ secret-directory }/$HASH/mount" )"
                                                            ${ log }/bin/log \
                                                                "setup" \
                                                                "bad" \
                                                                "$HASH" \
                                                                "$ORIGINATOR_PID" \
                                                                "$STATUS" \
                                                                "$STANDARD_OUTPUT" \
                                                                "$STANDARD_ERROR" \
                                                                "$CREATION_TIME" \
                                                                "$GARBAGE"
                                                            tar --create --file - "${ secret-directory }/$HASH" | zstd -T1 -19 > "$GARBAGE"
                                                            rm --recursive --force "${ secret-directory }/$HASH"
                                                        '' ;
                                                } ;
                                        good =
                                            pkgs.writeShellApplication
                                                {
                                                    name = "good" ;
                                                    runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.yq ] ;
                                                    text =
                                                        ''
                                                            CREATION_TIME="$( stat --format "%W" "${ secret-directory }/$HASH/mount" )"
                                                            flock -u 202
                                                            exec 201>&-
                                                            flock -u 202
                                                            exec 202>&-
                                                            HASH="$1"
                                                            ORIGINATOR_PID="$2"
                                                            STATUS="$3"
                                                            STANDARD_OUTPUT="$4"
                                                            STANDARD_ERROR="$5"
                                                            nohup \
                                                                ${ log }/bin/log \
                                                                "setup" \
                                                                "good" \
                                                                "$HASH" \
                                                                "$ORIGINATOR_PID" \
                                                                "$STATUS" \
                                                                "$STANDARD_OUTPUT" \
                                                                "$STANDARD_ERROR" \
                                                                "$CREATION_TIME" \
                                                                "" &
                                                            sleep ${ builtins.toString lease }
                                                            tail --follow /dev/null --pid "$ORIGINATOR_PID"
                                                            SYMLINK=-1
                                                            echo "SYMLINK=$SYMLINK HASH=$HASH" > /tmp/DEBUG
                                                            while [[ -n "$SYMLINK" ]]
                                                            do
                                                                SYMLINK="$( find ${ secret-directory } -type l 2>/dev/null | while read -r CANDIDATE
                                                                do
                                                                    RESOLVED="$( readlink --canonical "$CANDIDATE" 2>/dev/null )"
                                                                    if [[ "$RESOLVED" == "${ secret-directory }/$HASH/mount" ]]
                                                                    then
                                                                        echo "$CANDIDATE"
                                                                        break
                                                                    fi
                                                                done )"
                                                                echo "SYMLINK=$SYMLINK HASH=$HASH" >> /tmp/DEBUG
                                                                if [[ -n "$SYMLINK" ]]
                                                                then
                                                                    inotifywait --event delete_self "$SYMLINK" --quiet || true
                                                                fi
                                                            done
                                                            ${ teardown }/bin/teardown "$HASH" "$ORIGINATOR_PID" "$CREATION_TIME"
                                                        '' ;
                                                } ;
                                        hash = builtins.hashString "sha512" ( builtins.toJSON primary ) ;
                                        init-application =
                                            pkgs.writeShellApplication
                                                {
                                                    name = "init-application" ;
                                                    runtimeInputs = init-inputs ;
                                                    text = init-text ;
                                                } ;
                                        log =
                                            pkgs.writeShellApplication
                                                {
                                                    name = "log" ;
                                                    runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.yq-go ] ;
                                                    text =
                                                        ''
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
                                                            CURRENT_TIME=${ builtins.toString current-time }
#																	CREATION_TIME="$( stat --format "%W" "${ secret-directory }/$HASH/mount" )"
                                                            TEMP_FILE="$( mktemp )"
                                                            jq \
                                                                --null-input \
                                                                --arg CREATION_TIME "$CREATION_TIME" \
                                                                --arg CURRENT_TIME "$CURRENT_TIME" \
                                                                --arg HASH "$HASH" \
                                                                --arg INIT_APPLICATION "$INIT_APPLICATION" \
                                                                --arg INIT_TEXT '${ init-text }' \
                                                                --arg GARBAGE "$GARBAGE" \
                                                                --arg MODE "$MODE" \
                                                                --arg ORIGINATOR_PID "$ORIGINATOR_PID" \
                                                                --arg STANDARD_ERROR "$STANDARD_ERROR" \
                                                                --arg STANDARD_OUTPUT "$STANDARD_OUTPUT" \
                                                                --arg STATUS "$STATUS" \
                                                                --arg TIMESTAMP "$TIMESTAMP" \
                                                                --arg TYPE "$TYPE" \
                                                                '{ "creation-time" : $CREATION_TIME , "current-time" : $CURRENT_TIME , "hash" : $HASH , "init-application" : $INIT_APPLICATION , "init-text" : $INIT_TEXT , "mode" : $MODE , "garbage": $GARBAGE , "originator-pid" : $ORIGINATOR_PID , path : ${ builtins.toJSON path } , "standard-error" : $STANDARD_ERROR , "standard-output" : $STANDARD_OUTPUT , "status" : $STATUS , "timestamp" : $TIMESTAMP , "type" : $TYPE  }' | yq --prettyPrint "[.]" > "$TEMP_FILE"
                                                            mkdir --parents "${ log-directory }"
                                                            exec 203> "${ log-directory }/log.lock"
                                                            flock -x 203
                                                            cat "$TEMP_FILE" >> "${ log-directory }/log.yaml"
                                                            flock -u 203
                                                            exec 203>&-
                                                            rm "$TEMP_FILE"
                                                        '' ;
                                                } ;
                                        null =
                                            pkgs.writeShellApplication
                                                {
                                                    name = "null" ;
                                                    runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.yq ] ;
                                                    text =
                                                        ''
                                                            CREATION_TIME="$( stat --format "%W" "${ secret-directory }/$HASH/mount" )"
                                                            flock -u 202
                                                            exec 201>&-
                                                            flock -u 202
                                                            exec 202>&-
                                                            HASH="$1"
                                                            ORIGINATOR_PID="$2"
                                                            STATUS="$3"
                                                            nohup \
                                                                ${ log }/bin/log \
                                                                "setup" \
                                                                "null" \
                                                                "$HASH" \
                                                                "$ORIGINATOR_PID" \
                                                                "" \
                                                                "" \
                                                                "" )" \
                                                                "" \
                                                                "$CREATION_TIME" &
                                                            sleep ${ builtins.toString lease }
                                                            tail --follow /dev/null --pid "$ORIGINATOR_PID"
                                                            ${ teardown }/bin/teardown "$HASH" "$ORIGINATOR_PID" "" "$CREATION_TIME"
                                                        '' ;
                                                } ;

                                        stale =
                                            pkgs.writeShellApplication
                                                {
                                                    name = "stale" ;
                                                    runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.yq ] ;
                                                    text =
                                                        ''
                                                            CREATION_TIME="$( stat --format "%W" "${ secret-directory }/$HASH/mount" )"
                                                            flock -u 202
                                                            exec 201>&-
                                                            flock -u 202
                                                            exec 202>&-
                                                            HASH="$1"
                                                            ORIGINATOR_PID="$2"
                                                            ${ log }/bin/log \
                                                                "setup" \
                                                                "stale" \
                                                                "$HASH" \
                                                                "$ORIGINATOR_PID" \
                                                                "" \
                                                                "" \
                                                                "" \
                                                                "$CREATION_TIME" \
                                                                "" &
                                                            tail --follow /dev/null --pid "$ORIGINATOR_PID"
                                                            ${ teardown }/bin/teardown "$HASH"
                                                        '' ;
                                                } ;
                                        teardown =
                                            pkgs.writeShellApplication
                                                {
                                                    name = "teardown" ;
                                                    runtimeInputs = [ pkgs.coreutils pkgs.flock pkgs.gnutar pkgs.nix pkgs.zstd ] ;
                                                    text =
                                                        let
                                                            release-application =
                                                                pkgs.buildFHSUserEnv
                                                                    {
                                                                        extraBwrapArgs =
                                                                            [
                                                                                "--bind ${ secret-directory }/$HASH/mount /mount"
                                                                                "--bind ${ log-directory } ${ log-directory }"
                                                                                "--bind ${ secret-directory } ${ secret-directory }"
                                                                                "--tmpfs /work"
                                                                            ] ;
                                                                        name = "release-application" ;
                                                                        runScript =
                                                                            let
                                                                                script =
                                                                                    pkgs.writeShellApplication
                                                                                        {
                                                                                            name = "script" ;
                                                                                            runtimeInputs = release-inputs ;
                                                                                            text = release-text ;
                                                                                        } ;
                                                                                in "${ script }/bin/script" ;
                                                                    } ;
                                                            in
                                                                if builtins.typeOf release-text == "null" then
                                                                    ''
                                                                        HASH="$1"
                                                                        ORIGINATOR_PID="$2"
                                                                        CREATION_TIME="$3"
                                                                        if [[ ! -d "${ secret-directory }/$HASH/mount" ]] || [[ "$( stat --format "%W" "${ secret-directory }/$HASH/mount" )" != "$CREATION_TIME" ]]
                                                                        then
                                                                            ${ log }/bin/log \
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
                                                                            exec 201> "${ secret-directory }/$HASH/teardown.lock"
                                                                            flock -x 201
                                                                            exec 202> "${ secret-directory }/$HASH/setup.lock"
                                                                            flock -x 202
                                                                            GARBAGE="$( mktemp --dry-run --suffix ".tar.zst" )"
                                                                            tar --create --file - -C "${ secret-directory }" "$HASH" | zstd -T1 -19 > "$GARBAGE"
                                                                            rm --recursive --force "${ secret-directory }/$HASH"
                                                                            flock -u 202
                                                                            exec 202>&-
                                                                            flock -u 201
                                                                            exec 201>&-
                                                                            ${ log }/bin/log \
                                                                                "teardown" \
                                                                                "active" \
                                                                                "$HASH" \
                                                                                "$ORIGINATOR_PID" \
                                                                                "" \
                                                                                "" \
                                                                                "" \
                                                                                "$CREATION_TIME" \
                                                                                "$GARBAGE"
                                                                            exec 204> ${ secret-directory }/collect-garbage.lock
                                                                            flock -x 204
                                                                            nix-collect-garbage
                                                                            flock -u 204
                                                                            exec 204>&-
                                                                        fi
                                                                    ''
                                                                else
                                                                    ''
                                                                        HASH="$1"
                                                                        ORIGINATOR_PID="$2"
                                                                        CREATION_TIME="$3"
                                                                        if [[ ! -d "${ secret-directory }/$HASH/mount" ]] || [[ "$( stat --format "%W" "${ secret-directory }/$HASH/mount" )" != "$CREATION_TIME" ]]
                                                                        then
                                                                            ${ log }/bin/log \
                                                                                "teardown" \
                                                                                "aborted" \
                                                                                "$HASH" \
                                                                                "$ORIGINATOR_PID" \
                                                                                "" \
                                                                                "" \
                                                                                "$CREATION_TIME" \
                                                                                ""
                                                                        else
                                                                            exec 201> "${ secret-directory }/$HASH/teardown.lock"
                                                                            flock -x 201
                                                                            exec 202> "${ secret-directory }/$HASH/setup.lock"
                                                                            flock -x 202
                                                                            export HASH
                                                                            GARBAGE="$( mktemp --dry-run --suffix ".tar.zst" )"
                                                                            STANDARD_INPUT="$( mktemp )"
                                                                            STANDARD_ERROR="$( mktemp )"
                                                                            if ${ release-application }/bin/release > "$STANDARD_OUTPUT" 2> "$STANDARD_ERROR"
                                                                            then
                                                                                STATUS="$?"
                                                                            else
                                                                                STATUS="$?"
                                                                            fi
                                                                            nohup \
                                                                                ${ log }/bin/log \
                                                                                "teardown" \
                                                                                "null" \
                                                                                "$HASH" \
                                                                                "$ORIGINATOR_PID" \
                                                                                "" \
                                                                                "$STANDARD_OUTPUT" \
                                                                                "$STANDARD_ERROR" \
                                                                                "$CREATION_TIME"
                                                                                "$GARBAGE" &
                                                                            tar --create --file - -C "${ secret-directory }" "$HASH" | zstd -T1 -19 > "$GARBAGE"
                                                                            rm --recursive --force "${ secret-directory }/$HASH"
                                                                            flock -u 202
                                                                            exec 202>&-
                                                                            flock -u 201
                                                                            exec 201>&-
                                                                            exec 204> ${ secret-directory }/collect-garbage.lock
                                                                            flock -x 204
                                                                            nix-collect-garbage
                                                                            flock -u 204
                                                                            exec 204>&-
                                                                        fi
                                                                    '' ;
                                                } ;
                                        in
                                            if builtins.typeOf init-text == "null" then
                                                ''
                                                    PARENT_0_PID="$$"
                                                    PARENT_1_PID=$( ps -p "$PARENT_0_PID" -o ppid= | xargs )
                                                    PARENT_2_PID=$( ps -p "$PARENT_1_PID" -o ppid= | xargs )
                                                    PARENT_3_PID=$( ps -p "$PARENT_2_PID" -o ppid= | xargs )
                                                    STANDARD_INPUT="$( mktemp )"
                                                    if read -t 0
                                                    then
                                                        HAS_STANDARD_INPUT=true
                                                        timeout 1m cat > "$STANDARD_INPUT"
                                                        ORIGINATOR_PID="$PARENT_3_PID"
                                                    else
                                                        HAS_STANDARD_INPUT=false
                                                        ORIGINATOR_PID="$PARENT_2_PID"
                                                    fi
                                                    HASH="$( echo "${ hash } ${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[*]" "}" ] } $( cat "$STANDARD_INPUT" ) $HAS_STANDARD_INPUT" | sha512sum | cut --bytes -${ builtins.toString length } )"
                                                    rm "$STANDARD_INPUT"
                                                    mkdir --parents "${ secret-directory }/$HASH"
                                                    exec 201> "${ secret-directory }/$HASH/teardown.lock"
                                                    flock -s 201
                                                    exec 202> "${ secret-directory }/$HASH/setup.lock"
                                                    flock -x 202
                                                    if [[ -d "${ secret-directory }/$HASH/mount" ]]
                                                    then
                                                        nohup ${ stale }/bin/stale "$HASH" "$ORIGINATOR_PID" > /dev/null 2>&1 &
                                                        flock -u 202
                                                        exec 202>&-
                                                        flock -u 201
                                                        exec 201>&-
                                                        echo -n "${ secret-directory }/$HASH/mount"
                                                        exit 0
                                                    else
                                                        mkdir "${ secret-directory }/$HASH/mount
                                                        nohup ${ null }/bin/null "$HASH" "$ORIGINATOR_PID" > /dev/null 2>&1 &
                                                        flock -u 202
                                                        exec 202>&-
                                                        flock -u 201
                                                        exec 201>&-
                                                        echo -n "${ secret-directory }/$HASH/mount"
                                                        exit 0
                                                    fi
                                                ''
                                            else
                                                ''
                                                    PARENT_0_PID="$$"
                                                    PARENT_1_PID=$( ps -p "$PARENT_0_PID" -o ppid= | xargs )
                                                    PARENT_2_PID=$( ps -p "$PARENT_1_PID" -o ppid= | xargs )
                                                    PARENT_3_PID=$( ps -p "$PARENT_2_PID" -o ppid= | xargs )
                                                    STANDARD_INPUT="$( mktemp )"
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
                                                    HASH="$( echo "${ hash } ${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[*]" "}" ] } $( cat "$STANDARD_INPUT" ) $HAS_STANDARD_INPUT" | sha512sum | cut --bytes -${ builtins.toString length } )"
                                                    export HASH
                                                    ${ self }="${ secret-directory }/$HASH/mount"
                                                    export ${ self }
                                                    mkdir --parents "${ secret-directory }/$HASH"
                                                    exec 201> "${ secret-directory }/$HASH/teardown.lock"
                                                    flock -s 201
                                                    exec 202> "${ secret-directory }/$HASH/setup.lock"
                                                    flock -x 202
                                                    if [[ -d "${ secret-directory }/$HASH/mount" ]]
                                                    then
                                                        nohup ${ stale }/bin/stale "$HASH" "$ORIGINATOR_PID" > /dev/null 2>&1 &
                                                        flock -u 202
                                                        exec 202>&-
                                                        flock -u 201
                                                        exec 201>&-
                                                        rm "$STANDARD_INPUT"
                                                        echo -n "${ secret-directory }/$HASH/mount"
                                                        exit 0
                                                    else
                                                        mkdir "${ secret-directory }/$HASH/mount"
                                                        STANDARD_ERROR="$( mktemp )"
                                                        STANDARD_OUTPUT="$( mktemp )"
                                                    if "$HAS_STANDARD_INPUT"
                                                        then
                                                            if ${ init-application }/bin/init-application "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" < "$STANDARD_INPUT" > "$STANDARD_OUTPUT" 2> "$STANDARD_ERROR"
                                                            then
                                                                nohup ${ good }/bin/good "$HASH" "$ORIGINATOR_PID" "$?" "$STANDARD_OUTPUT" "$STANDARD_ERROR" > /dev/null 2>&1 &
                                                                flock -u 202
                                                                exec 202>&-
                                                                flock -u 201
                                                                exec 201>&-
                                                                rm "$STANDARD_INPUT"
                                                                echo -n "${ secret-directory }/$HASH/mount"
                                                                exit 0
                                                            else
                                                                nohup ${ bad }/bin/bad "$HASH" "$ORIGINATOR_PID" "$?" "$STANDARD_OUTPUT" "$STANDARD_ERROR" > /dev/null 2>&1 &
                                                                flock -u 202
                                                                exec 202>&-
                                                                flock -u 201
                                                                exec 201>&-
                                                                rm "$STANDARD_INPUT"
                                                                exit ${ builtins.toString error }
                                                            fi
                                                        else
                                                            if ${ init-application }/bin/init-application "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" > "$STANDARD_OUTPUT" 2> "$STANDARD_ERROR"
                                                            then
                                                                nohup ${ good }/bin/good "$HASH" "$ORIGINATOR_PID" "$?" "$STANDARD_OUTPUT" "$STANDARD_ERROR" > /dev/null 2>&1 &
                                                                flock -u 202
                                                                exec 202>&-
                                                                flock -u 201
                                                                exec 201>&-
                                                                rm "$STANDARD_INPUT"
                                                                echo -n "${ secret-directory }/$HASH/mount"
                                                                exit 0
                                                            else
                                                                nohup ${ bad }/bin/bad "$HASH" "$ORIGINATOR_PID" "$?" "$STANDARD_OUTPUT" "$STANDARD_ERROR" > /dev/null 2>&1 &
                                                                flock -u 202
                                                                exec 202>&-
                                                                flock -u 201
                                                                exec 201>&-
                                                                rm "$STANDARD_INPUT"
                                                                exit ${ builtins.toString error }
                                                            fi
                                                        fi
                                                    fi
                                                ''
                                ) ;
							pkgs = builtins.getAttr system nixpkgs.legacyPackages ;
							in "${ application }/bin/application" ;
			} ;
}
