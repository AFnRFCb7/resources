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
                        self ? "SELF" ,
                        testing-locks ? false ,
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
                                            installPhase =
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
                                                                                            find "$OUT/${ builtins.toString index }/checkpoint -type d -exec touch {}/.gitkeep \;
                                                                                            if ! diff --recursive ${ command.checkpoint } "$OUT/${ builtins.toString index }/checkpoint"
                                                                                            then
                                                                                                echo We expected the result of the ${ builtins.toString index }th command ${ command.command } to be $OUT/${ builtins.toString index }/checkpoint but it was ${ resources-directory } >&2
                                                                                                ${ failures_ "df837f22" }
                                                                                            fi
                                                                                        '' ;
                                                                        } ;
                                                                    in "${ command }" ;
                                                    invoke-resource =
                                                        writeShellApplication
                                                            {
                                                                name = "invoke-resource" ;
                                                                runtimeInputs = [ coreutils flock ] ;
                                                                text =
                                                                    ''
                                                                        mkdir --parents "$OUT/0"
                                                                        echo "The test directory is $OUT"
                                                                        echo "$$" > "$OUT/0/invoke-resource.pid"
                                                                        mkdir --parents ${ test-directory }
                                                                        echo "${ implementation } ${ builtins.concatStringsSep " " arguments } ${ if builtins.typeOf standard-input == "string" then "< ${ builtins.toFile "standard-input" standard-input }" else "" } > ${ test-directory }/standard-output 2> ${ test-directory }/standard-error" > "$OUT/0/command.sh"
                                                                        if ${ implementation } ${ builtins.concatStringsSep " " arguments } ${ if builtins.typeOf standard-input == "string" then "< ${ builtins.toFile "standard-input" standard-input }" else "" } > ${ test-directory }/standard-output 2> ${ test-directory }/standard-error
                                                                        then
                                                                            MOUNT="$( < ${ test-directory }/standard-output )" || ${ failures_ "b982047f" }
                                                                            if [[ ! -d "$MOUNT" ]]
                                                                            then
                                                                                echo "${ label } command ${ implementation } succeeded but mount $MOUNT is not a directory" >&2
                                                                                ${ failures_ "e551352c" }
                                                                            elif [[ "$MOUNT" != "${ mount }" ]]
                                                                            then
                                                                                echo "${ label } command ${ implementation } succeeded but mount $MOUNT is not the expected directory ${ mount }" >&2
                                                                                ${ failures_ "e484b646" }
                                                                            fi
                                                                            if [[ -s ${ test-directory }/standard-error ]]
                                                                            then
                                                                                echo "${ label } command ${ implementation } succeeded but it generated standard-error" >&2
                                                                                ${ failures_ "eede733e" }
                                                                            fi
                                                                            ${ if status != 0 then ''exit 148'' else "# " }
                                                                        else
                                                                            STATUS="$?"
                                                                            if [[ "$STATUS" != "${ builtins.toString status }" ]]
                                                                            then
                                                                                echo "${ label } command ${ implementation } failed but we expected the status to be ${ builtins.toString status } and we observed $STATUS" >&2
                                                                                ${ failures_ "e3be9f66" }
                                                                            fi
                                                                            if [[ -s ${ test-directory }/standard-output ]]
                                                                            then
                                                                                echo "${ label } command failed but it generated standard-output" >&2
                                                                                ${ failures_ "c4cb3838" }
                                                                            fi
                                                                            if [[ -s ${ test-directory }/standard-error ]]
                                                                            then
                                                                                echo "${ label } command ${ implementation } failed but it generated standard-error"
                                                                                ${ failures_ "dde5524a" }
                                                                            fi
                                                                        fi
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "exec 200> ${ resources-directory }/test.setup.lock" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -x 200" else "#" }
                                                                        cp --recursive ${ resources-directory } "$OUT/0/checkpoint-pre"
                                                                        find "$OUT/0/checkpoint-pre" -type d -exec touch {}/.gitkeep \;
                                                                        if ! diff --recursive ${ checkpoint-pre } "$OUT/0/checkpoint-pre"
                                                                        then
                                                                            echo "${ label } We expected the resources-directory pre initial clean to exactly match ${ checkpoint-pre } but it was $OUT/0/checkpoint-pre" >&2
                                                                            ${ failures_ "a6f0de4f" }
                                                                        fi
                                                                        flock -u 200
                                                                        exec 200>&-
                                                                    '' ;
                                                            } ;
                                                    root =
                                                        writeShellApplication
                                                            {
                                                                name = "root" ;
                                                                runtimeInputs = [ coreutils diffutils findutils flock invoke-resource ] ;
                                                                text =
                                                                    ''
                                                                        if [[ -e ${ resources-directory } ]]
                                                                        then
                                                                            echo ${ label } We expected the resources directory to not initially exist >&2
                                                                            ${ failures_ "a6e628b6" }
                                                                        fi
                                                                        if [[ -e ${ test-directory } ]]
                                                                        then
                                                                            echo ${ label } We expected the test directory to not initially exit >&2
                                                                            exit 135
                                                                        fi
                                                                        invoke-resource
                                                                        echo "root $$" >> "$OUT/0/invoke-resource.pid"
                                                                        exec 200> ${ resources-directory }/test.setup.lock
                                                                        flock -x 200
                                                                        cp --recursive ${ resources-directory } "$OUT/0/checkpoint-post"
                                                                        find "$OUT/0/checkpoint-post" -type d -exec touch {}/.gitkeep \;
                                                                        if ! diff --recursive ${ checkpoint-post } "$OUT/0/checkpoint-post"
                                                                        then
                                                                            echo ${ label } We expected the resources-directory post initial clean to exactly match ${ checkpoint-post } but it was "$OUT/0/checkpoint-post" >&2
                                                                            ${ failures_ "b42acd0d" }
                                                                        fi
                                                                        echo "da4b3b6c-fe76-4be1-a335-0e3b84a5b8fc" >> /build/DEBUG
                                                                        ${ builtins.concatStringsSep "\n" ( builtins.genList ( index : let c = command index ; in ''${ c }/bin/command "$OUT"'' ) ( builtins.length commands ) ) }
                                                                        echo "801e761b-27de-47d3-b9ec-2482f5548fb6 BEFORE SLEEP" >> /build/DEBUG
                                                                        sleep 10s # KLUDGE
                                                                        echo "21293d5e-1de7-4c08-8f8f-5a244ce0cfa5 AFTER SLEEP" >> /build/DEBUG
                                                                        if [[ -n "$( find ${ resources-directory }/mounts -mindepth 1 -maxdepth 1 )" ]]
                                                                        then
                                                                            cat /build/DEBUG
                                                                            echo ${ label } We expected ${ resources-directory }/mounts to be an empty directory >&2
                                                                            find ${ resources-directory }/mounts #KLUDGE
                                                                            ${ failures_ "65eb34ce" }
                                                                        fi
                                                                        if [[ -n "$( find ${ resources-directory }/canonical -mindepth 1 -maxdepth 1 )" ]]
                                                                        then
                                                                            cat /build/DEBUG
                                                                            echo ${ label } We expected the canonical directory ${ resources-directory }/canonical to be empty >&2
                                                                            ${ failures_ "4705e39e" }
                                                                        fi
                                                                    '' ;
                                                            } ;
                                                    stall =
                                                        writeShellApplication
                                                            {
                                                                name = "stall" ;
                                                                runtimeInputs = [ flock ] ;
                                                                text =
                                                                    ''
                                                                        find ${ resources-directory }/locks -type f | while read -r LOCK
                                                                        do
                                                                            exec 210> "$LOCK"
                                                                            flock -x 210
                                                                        done
                                                                    '' ;
                                                            } ;
                                                    in
                                                        ''
                                                            mkdir --parents $out/bin
                                                            makeWrapper ${ invoke-resource }/bin/invoke-resource $out/bin/invoke-resource --set OUT $out
                                                            makeWrapper ${ root }/bin/root $out/bin/root --set OUT $out
                                                            makeWrapper ${ stall }/bin/stall $out/bin/stall
                                                            $out/bin/root
                                                        '' ;
                                            name = "test-expected" ;
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
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 200" else "#" }
                                                                        LINK=${ builtins.concatStringsSep "" [ "$" "{" "LINK:?LINK must be set" "}" ] }
                                                                        ARGUMENTS="$( printf '%s\n' "$@" | jq --raw-input --slurp 'split("\n")[:-1]' )" || ${ failures_ "a1b19aa5" }
                                                                        LINKS=${ if builtins.typeOf init == "null" then "" else ''"$( find "$LINK" -mindepth 1 -maxdepth 1 -type l -exec basename {} \; | jq --raw-input --slurp )" || ${ failures_ "bf995f33" }'' }
                                                                        TARGETS="$( find "$MOUNT" -mindepth 1 -maxdepth 1 -exec basename {} \; | jq --raw-input --slurp )" || ${ failures_ "f3ead1ff" }
                                                                        rm "${ resources-directory }/canonical/$HASH"
                                                                        RECOVERY="${ resources-directory }/recovery/$MOUNT_INDEX"
                                                                        mkdir --parents "$RECOVERY"
                                                                        RECOVERY_BIN="$OUT/bin/recovery"
                                                                        # shellcheck source=/dev/null
                                                                        source "$MAKE_WRAPPER/nix-support/setup-hook"
                                                                        makeWrapper "$RECOVERY_BIN" "$RECOVERY/repair" --set ACTION repair --set HASH "$HASH" --set MOUNT_INDEX "$MOUNT_INDEX"
                                                                        makeWrapper "$RECOVERY_BIN" "$RECOVERY/settle" --set ACTION settle --set HASH "$HASH" --set MOUNT_INDEX "$MOUNT_INDEX"
                                                                        STANDARD_ERROR="$( < "$STANDARD_ERROR_FILE" )" || ${ failures_ "c141fe3b" }
                                                                        STANDARD_OUTPUT="$( < "$STANDARD_OUTPUT_FILE" )" || ${ failures_ "f13f84ae" }
                                                                        rm --force "$STANDARD_ERROR_FILE" "$STANDARD_OUTPUT_FILE"
                                                                        TYPE="$( basename "$0" )" || ${ failures_ "e5fa2135" }
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
                                                                                "mount-index" : $MOUNT_INDEX ,
                                                                                "release-application" : $RELEASE_APPLICATION ,
                                                                                "standard-error" : $STANDARD_ERROR ,
                                                                                "standard-input" : $STANDARD_INPUT ,
                                                                                "standard-output" : $STANDARD_OUTPUT ,
                                                                                "status" : $STATUS ,
                                                                                "targets" : $TARGETS ,
                                                                                "transient" : $TRANSIENT ,
                                                                                "type" : $TYPE
                                                                            }' | yq --prettyPrint "[.]" | log-bad
                                                                    '' ;
                                                                good =
                                                                    ''
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 200" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 201" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 202" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 203" else "#" }
                                                                        flock -s 211
                                                                        ARGUMENTS="$( printf '%s\n' "$@" | jq --raw-input --slurp 'split("\n")[:-1]' )" || ${ failures_ "ea11161a" }
                                                                        LINKS=${ if builtins.typeOf init == "null" then "" else ''"$( find "${ resources-directory }/links/$MOUNT_INDEX" -mindepth 1 -maxdepth 1 -type l -exec basename {} \; | jq --raw-input --slurp )" || ${ failures_ "a7486bbb" }'' }
                                                                        STANDARD_ERROR="$( cat "$STANDARD_ERROR_FILE" )" || ${ failures_ "a69f5bc2" }
                                                                        STANDARD_OUTPUT="$( cat "$STANDARD_OUTPUT_FILE" )" || ${ failures_ "dc662c73" }
                                                                        rm --force "$STANDARD_ERROR_FILE" "$STANDARD_OUTPUT_FILE"
                                                                        TYPE="$( basename "$0" )" || ${ failures_ "cd255035" }
                                                                        jq \
                                                                            --null-input \
                                                                            --argjson ARGUMENTS "$ARGUMENTS" \
                                                                            --arg HASH "$HASH" \
                                                                            --arg HAS_STANDARD_INPUT "$HAS_STANDARD_INPUT" \
                                                                            --arg INIT_APPLICATION ${ if builtins.typeOf init-application == "null" then "null" else "${ init-application }/bin/init-application" } \
                                                                            --argjson LINKS "$LINKS" \
                                                                            --arg MOUNT "$MOUNT" \
                                                                            --arg RELEASE_APPLICATION ${ if builtins.typeOf release-application == "null" then "null" else "${ release-application }/bin/release-application" } \
                                                                            --arg STANDARD_ERROR "$STANDARD_ERROR" \
                                                                            --arg STANDARD_INPUT "$STANDARD_INPUT" \
                                                                            --arg STANDARD_OUTPUT "$STANDARD_OUTPUT" \
                                                                            --arg STATUS "$STATUS" \
                                                                            --arg TRANSIENT "$TRANSIENT" \
                                                                            --arg TYPE "$TYPE" \
                                                                            '{
                                                                                "hash" : $HASH ,
                                                                                "has-standard-input" : $HAS_STANDARD_INPUT ,
                                                                                "init-application" : $INIT_APPLICATION ,
                                                                                "links" : $LINKS ,
                                                                                "mount" : $MOUNT ,
                                                                                "release-application" : $RELEASE_APPLICATION ,
                                                                                "standard-error" : $STANDARD_ERROR ,
                                                                                "standard-input" : $STANDARD_INPUT ,
                                                                                "standard-output" : $STANDARD_OUTPUT ,
                                                                                "status" : $STATUS ,
                                                                                "transient" : $TRANSIENT ,
                                                                                "type" : $TYPE
                                                                            }' | yq --prettyPrint "[.]" | log
                                                                        NOHUP="$( temporary )" || ${ failures_ "8d2d5a45" }
                                                                        nohup stall-for-process > "$NOHUP" 2>&1 &
                                                                    '' ;
                                                                log =
                                                                    ''
                                                                        echo "61cc998a-7373-4141-ba51-5d50476c43ee IN LOG" >> /build/DEBUG
                                                                        mkdir --parents ${ resources-directory }/logs
                                                                        echo "b0a08351-7feb-4f4f-b635-dee834083b1d" >> /build/DEBUG
                                                                        exec 203> ${ resources-directory }/logs/lock
                                                                        echo "45dad86f-097f-44d4-b6fd-0b6093ed1254" >> /build/DEBUG
                                                                        flock -x 203
                                                                        echo "7d990221-085a-4446-95f2-89f505964d13" >> /build/DEBUG
                                                                        cat >> ${ resources-directory }/logs/log.yaml
                                                                        echo "334419e9-5b60-4bc6-a48f-6537ba39ccbc FINISHED LOG" >> /build/DEBUG
                                                                    '' ;
                                                                log-bad =
                                                                    ''
                                                                        TEMPORARY_LOG="$( temporary )" || ${ failures_ "cebabd7e" }
                                                                        cat > "$TEMPORARY_LOG"
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
                                                                        log < "$TEMPORARY_LOG"
                                                                        rm "$TEMPORARY_LOG"
                                                                    '' ;
                                                                no-init =
                                                                    ''
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 200" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 202" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 203" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 204" else "#" }
                                                                        flock -s 211
                                                                        TYPE="$( basename "$0" )" || ${ failures_ "a32a15dc" }
                                                                        jq \
                                                                            --arg HASH "$HASH" \
                                                                            --arg ORIGINATOR_PID "$ORIGINATOR_PID" \
                                                                            --arg TRANSIENT "$TRANSIENT" \
                                                                            --arg TYPE "$TYPE" \
                                                                            --null-input \
                                                                            '{
                                                                                "hash" : $HASH ,
                                                                                "originator-pid" : $ORIGINATOR_PID ,
                                                                                "type" : $TYPE
                                                                            }' | yq --prettyPrint "[.]"
                                                                        NOHUP="$( temporary )" || ${ failures_ "8192be99" }
                                                                        nohup stall-for-process > "$NOHUP" 2>&1 &
                                                                    '' ;
                                                                recovery =
                                                                    ''
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "exec 200> ${ resources-directory }/test.setup.lock" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 200" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "exec 201> ${ resources-directory }/test.setup.lock" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 201" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "exec 202> ${ resources-directory }/test.setup.lock" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 202" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "exec 203> ${ resources-directory }/test.setup.lock" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 203" else "#" }
                                                                        mkdir --parents "${ resources-directory }/locks/$MOUNT_INDEX"
                                                                        exec 211> "${ resources-directory }/locks/$MOUNT_INDEX/setup.lock"
                                                                        flock -x 211
                                                                        GOOD="$( sequential )" || ${ failures_ "f696cd77" }
                                                                        mkdir --parents ${ resources-directory }/temporary
                                                                        rm --recursive --force "$LINK"
                                                                        mv "$MOUNT" "${ resources-directory }/temporary/$GOOD"
                                                                        rm --recusive --force "$RECOVERY"
                                                                        if read -t 0
                                                                        then
                                                                            RESOLUTION="$( cat )" || ${ failures_ "d8a96cd7" }
                                                                        else
                                                                            RESOLUTION="${ builtins.concatStringsSep "" [ "$" "{" "*" "}" ] }"
                                                                        fi
                                                                        TYPE="$( basename "$0" )" || ${ failures_ "26030b9e" }
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
                                                                            }' | yq --prettyPrint "[.]" > log
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
                                                                        echo "$NEW" > ${ resources-directory }/counter.increment
                                                                        chmod 0644 ${ resources-directory }/counter.increment
                                                                        printf "%08d\n" "$NEW"
                                                                    '' ;
                                                                setup =
                                                                    if builtins.typeOf init == "null" then
                                                                        ''
                                                                            ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "exec 200> ${ resources-directory }/test.setup.lock" else "#" }
                                                                            ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 200" else "#" }
                                                                            ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "exec 201> ${ resources-directory }/test.stall-for-process.lock" else "#" }
                                                                            ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 201" else "#" }
                                                                            ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "exec 202> ${ resources-directory }/test.stall-for-cleanup.lock" else "#" }
                                                                            ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 202" else "#" }
                                                                            ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "exec 203> ${ resources-directory }/test.teardown.lock" else "#" }
                                                                            ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 203" else "#" }
                                                                            if [[ -t 0 ]]
                                                                            then
                                                                                HAS_STANDARD_INPUT=false
                                                                                STANDARD_INPUT=
                                                                                STANDARD_INPUT_FILE="$( temporary )" || ${ failures_ "7f77cdad" }
                                                                            else
                                                                                HAS_STANDARD_INPUT=true
                                                                                timeout 1m cat > "$STANDARD_INPUT_FILE"
                                                                                STANDARD_INPUT="$( cat "$STANDARD_INPUT_FILE" )" || ${ failures_ "fbb0e2f8" }
                                                                                rm "$STANDARD_INPUT_FILE"
                                                                            fi
                                                                            TRANSIENT=${ transient_ }
                                                                            export ORIGINATOR_PID="$PPID"
                                                                            HASH="$( echo "${ hash } ${ builtins.concatStringsSep "" [ "$TRANSIENT" "$" "{" "ARGUMENTS[*]" "}" ] } $STANDARD_INPUT $HAS_STANDARD_INPUT" | sha512sum | cut --characters 1-128 )" || ${ failures_ "bc3e1b88" }
                                                                            export HASH
                                                                            mkdir --parents "${ resources-directory }/locks/$HASH"
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
                                                                                echo -n "$MOUNT"
                                                                            else
                                                                                MOUNT_INDEX="$( sequential )" || ${ failures_ "d162db9f" }
                                                                                export MOUNT_INDEX
                                                                                mkdir --parents "${ resources-directory }/locks/$MOUNT_INDEX"
                                                                                exec 211> "${ resources-directory }/locks/$MOUNT_INDEX/setup.lock"
                                                                                flock -s 211
                                                                                MOUNT="${ resources-directory }/mounts/$MOUNT_INDEX"
                                                                                mkdir --parents "$MOUNT"
                                                                                ln --symbolic "$MOUNT" "${ resources-directory }/canonical/$HASH"
                                                                                NOHUP="$( temporary )" || ${ failures_ "f91c57c2" }
                                                                                nohup no-init > "$NOHUP" 2>&1 &
                                                                                echo -n "$MOUNT"
                                                                            fi
                                                                        ''
                                                                    else
                                                                        ''
                                                                            ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "exec 200> ${ resources-directory }/test.setup.lock" else "#" }
                                                                            ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 200" else "#" }
                                                                            ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "exec 201> ${ resources-directory }/test.stall-for-process.lock" else "#" }
                                                                            ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 201" else "#" }
                                                                            ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "exec 202> ${ resources-directory }/test.stall-for-cleanup.lock" else "#" }
                                                                            ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 202" else "#" }
                                                                            ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "exec 203> ${ resources-directory }/test.teardown.lock" else "#" }
                                                                            ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 203" else "#" }
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
                                                                            export ORIGINATOR_PID=$PPID
                                                                            HASH="$( echo "${ hash } ${ builtins.concatStringsSep "" [ "$TRANSIENT" "$" "{" "ARGUMENTS[*]" "}" ] } $STANDARD_INPUT $HAS_STANDARD_INPUT" | sha512sum | cut --characters 1-128 )" || ${ failures_ "7849a979" }
                                                                            export HASH
                                                                            mkdir --parents "${ resources-directory }/locks/$HASH"
                                                                            ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "exec 200> ${ resources-directory }/test.setup.lock" else "#" }
                                                                            ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 200" else "#" }
                                                                            ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "exec 201> ${ resources-directory }/test.teardown.lock" else "#" }
                                                                            ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 201" else "#" }
                                                                            exec 210> "${ resources-directory }/locks/$HASH/teardown.lock"
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
                                                                                export MOUNT
                                                                                mkdir --parents "$MOUNT"
                                                                                STANDARD_ERROR_FILE="$( temporary )" || ${ failures_ "b07f7374" }
                                                                                export STANDARD_ERROR_FILE
                                                                                STANDARD_OUTPUT_FILE="$( temporary )" || g${ failures_ "29c19af1" }
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
                                                                                if [[ "$STATUS" == 0 ]] && [[ ! -s "$STANDARD_ERROR_FILE" ]] && [[ "$( find "$MOUNT" -mindepth 1 -maxdepth 1 -exec basename {} \; | LC_ALL=C sort | tr --delete "\n" | sha512sum | cut --bytes -128 )" == ${ builtins.hashString "sha512" ( builtins.concatStringsSep "" ( builtins.sort builtins.lessThan targets ) ) } ]]
                                                                                then
                                                                                    NOHUP="$( temporary )" || ${ failures_ "faa95dc4" }
                                                                                    nohup good "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" > "$NOHUP" 2>&1 &
                                                                                    echo -n "$MOUNT"
                                                                                else
                                                                                    NOHUP="$( temporary )" || ${ failures_ "aee914c6" }
                                                                                    nohup bad "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" > "$NOHUP" 2>&1 &
                                                                                    ${ failures_ "b385d889" }
                                                                                fi
                                                                            fi
                                                                        '' ;
                                                                stale =
                                                                    ''
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 200" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 202" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 203" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 204" else "#" }
                                                                        flock -s 211
                                                                        MOUNT_INDEX="$( basename "$MOUNT" )" || ${ failures_ "d6df365c" }
                                                                        TYPE="$( basename "$0" )" || ${ failures_ "d2cc81ec" }
                                                                        jq \
                                                                            --null-input \
                                                                            --arg HASH "$HASH" \
                                                                            --arg MOUNT_INDEX "$MOUNT_INDEX" \
                                                                            --arg TRANSIENT "$TRANSIENT" \
                                                                            --arg TYPE "$TYPE" \
                                                                            '{
                                                                                "hash" : $HASH ,
                                                                                "mount-index" : $MOUNT_INDEX ,
                                                                                "type" : $TYPE
                                                                            }' | yq --prettyPrint "[.]" | nohup log
                                                                        NOHUP="$( temporary )" || ${ failures_ "290a9299" }
                                                                        nohup stall-for-process > "$NOHUP" 2>&1 &
                                                                    '' ;
                                                                stall-for-cleanup =
                                                                    ''
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 202" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 203" else "#" }
                                                                        flock -s 211
                                                                        echo "b39d663d-7d4e-4e75-bd7e-51cbcd5fc9d1" >> /build/DEBUG
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "exec 200> ${ resources-directory }/test.setup.lock" else "#" }
                                                                        echo "b43685d4-2c8a-4f53-8b89-46b22faa8fea" >> /build/DEBUG
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 201" else "#" }
                                                                        echo "f44227f5-c7bd-4083-bd57-6a4fcd9a4744" >> /build/DEBUG
                                                                        HEAD="$( stall-for-cleanup-head | tr --delete '[:space:]' )" || ${ failures_ "f9b0e418" }
                                                                        HEAD2="HEAD=$HEAD"
                                                                        echo "5e87057c-d3f0-4529-b6cc-b183a7d6db60" >> /build/DEBUG
                                                                        TYPE="$( basename "$0" )" || ${ failures_ "e4782f79" }
                                                                        echo "5fa7d290-52cb-46cc-9565-c235daed0e08 BEGIN LOG stall-for-cleanup" >> /build/DEBUG
                                                                        jq \
                                                                            --null-input \
                                                                            --arg HASH "$HASH" \
                                                                            --arg HEAD "$HEAD2" \
                                                                            --arg TYPE "$TYPE" \
                                                                                '{
                                                                                    "hash" : $HASH ,
                                                                                    "head" : "$HEAD" ,
                                                                                    "type" : $TYPE
                                                                                }' | yq --prettyPrint "[.]" | log
                                                                        echo "a22285b2-0ebf-4ff8-8198-17fc45968fc3 END LOG stall-for-cleanup" >> /build/DEBUG
                                                                        NOHUP="$( temporary )" || ${ failures_ "c9e6586c" }
                                                                        if [[ -n "$HEAD" ]]
                                                                        then
                                                                            echo "cd0df0d8-f830-4351-aaab-03520a291120" >> /build/DEBUG
                                                                            inotifywait --event move_self "$HEAD" --quiet
                                                                            echo "5ccbe110-6c5b-4878-b6df-fe7e1925c482" >> /build/DEBUG
                                                                            nohup stall-for-cleanup > "$NOHUP" 2>&1 &
                                                                            echo "266b98de-52e9-41a5-a0db-78bd61de6e42" >> /build/DEBUG
                                                                        else
                                                                            echo "ca583298-d738-40e9-afc8-751acd16f46f" >> /build/DEBUG
                                                                            nohup teardown > "$NOHUP" 2>&1 &
                                                                            echo "183ddaba-d4f0-4d74-8fcb-5a900e27e53c" >> /build/DEBUG
                                                                        fi
                                                                        echo "e0296274-2e60-4ad3-a407-555b021e9792" >> /build/DEBUG
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
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 201" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 202" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 203" else "#" }
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
                                                                                }' | yq --prettyPrint "[.]" | log
                                                                        echo "31e4c966-638d-42f0-9690-e9ba3a02ac77" > /build/DEBUG
                                                                        echo "f2692e9b-7652-4e83-a6f7-834412775b9d" >> /build/DEBUG
                                                                        tail --follow /dev/null --pid "$ORIGINATOR_PID"
                                                                        echo "de16c36b-a60b-4f0f-afdf-c9b8da36d523" >> /build/DEBUG
                                                                        NOHUP="$( temporary )" || ${ failures_ "ee645658" }
                                                                        nohup stall-for-cleanup > "$NOHUP" 2>&1 &
                                                                        echo "099dcc85-e24b-47d4-b59d-b1ad72339e9c" >> /build/DEBUG
                                                                    '' ;
                                                                stall-for-symlink =
                                                                    ''
                                                                        SYMLINK="$1"
                                                                        TYPE="$( basename "$0" )" || ${ failures_ "99ddfc39" }
                                                                        jq \
                                                                            --null-input \
                                                                            --arg SYMLINK "$SYMLINK" \
                                                                            --arg TYPE "$TYPE" \
                                                                            '{
                                                                                "symlink" : $SYMLINK ,
                                                                                "type" : $TYPE
                                                                            }' | yq --prettyPrint "[.]" | log
                                                                        inotifywait --event move_self "$SYMLINK" --quiet
                                                                    '' ;
                                                                teardown =
                                                                    ''
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 203" else "#" }
                                                                        exec 210> "${ resources-directory }/locks/$HASH/teardown.lock"
                                                                        echo "4c6a4df6-c320-40b0-816b-5eac11d7fab3" >> /build/DEBUG
                                                                        flock -x 210
                                                                        flock -s 211
                                                                        echo "a7c7b814-96a3-42ee-b875-b3df59aea073" >> /build/DEBUG
                                                                        if [[ -L "${ resources-directory }/canonical/$HASH" ]]
                                                                        then
                                                                            CANDIDATE="$( readlink "${ resources-directory }/canonical/$HASH" )" || ${ failures_ "cfb26c78" }
                                                                            echo "3f1c7fad-53e4-4344-95cc-5dfa983e22ba" >> /build/DEBUG
                                                                            NOHUP="$( temporary )" || ${ failures_ "0d5ebafc" }
                                                                            if [[ "$MOUNT" == "$CANDIDATE" ]]
                                                                            then
                                                                                echo "70d5fd35-a89d-48be-a31d-d6f04553a1ec" >> /build/DEBUG
                                                                                rm "${ resources-directory }/canonical/$HASH"
                                                                                nohup teardown-completed > "$NOHUP" 2>&1 &
                                                                                echo "3177bf16-a2e1-43e2-9c36-4d7bbd644b9b" >> /build/DEBUG
                                                                            else
                                                                                echo "e7372c5b-f5f7-4ace-800f-ddfc030a085e" >> /build/DEBUG
                                                                                nohup teardown-aborted > "$NOHUP" 2>&1 &
                                                                                echo "d2e9addc-5e48-4682-a438-8af8767a7959" >> /build/DEBUG
                                                                            fi
                                                                        else
                                                                            echo "54051e3c-ddce-4bd2-be8d-0ee15d0870b7" >> /build/DEBUG
                                                                            teardown-aborted
                                                                            echo "f7519e3c-bf3d-41cd-82b2-df3a83d3b240" >> /build/DEBUG
                                                                        fi
                                                                    '' ;
                                                                teardown-aborted =
                                                                    ''
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 203" else "#" }
                                                                        flock -s 211
                                                                        TYPE="$( basename "$0" )" || ${ failures_ "f75c4adf" }
                                                                        jq \
                                                                            --null-input \
                                                                            --arg HASH "$HASH" \
                                                                            --arg TYPE "$TYPE" \
                                                                            '{
                                                                                "hash" : $HASH ,
                                                                                "type" : $TYPE
                                                                            }' | yq --prettyPrint "[.]" | log
                                                                    '' ;
                                                                teardown-completed =
                                                                    if builtins.typeOf release == "null" then
                                                                        ''
                                                                            ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 203" else "#" }
                                                                            flock -s 211
                                                                            teardown-final
                                                                        ''
                                                                    else
                                                                        ''
                                                                            ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 203" else "#" }
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
                                                                        ${ if builtins.typeOf init == "null" then "#" else ''rm --recursive --force "$LINK"'' }
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
                                                                            }' | yq --prettyPrint "[.]" | log
                                                                    '' ;
                                                                temporary =
                                                                    ''
                                                                        mkdir --parents ${ resources-directory }/temporary
                                                                        SEQUENCE="$( sequential )" || ${ failures_ "09d1282d" }
                                                                        echo "${ resources-directory }/temporary/$SEQUENCE"
                                                                    '' ;
                                                            } ;
                                                        in
                                                            ''
                                                                mkdir --parents $out/scripts
                                                                ${ builtins.concatStringsSep "\n" ( builtins.attrValues ( builtins.mapAttrs ( name : value : "makeWrapper ${ writeShellApplication { name = name ; text = value ; } }/bin/${ name } $out/bin/${ name } --set MAKE_WRAPPER ${ makeWrapper } --set OUT $out --set PATH $out/bin:${ makeBinPath [ coreutils findutils flock jq ps uuidlib yq-go ] }" ) scripts ) ) }
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
