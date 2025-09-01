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
                        testing-locks ? false ,
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
                                    checkpoint-pre ,
                                    checkpoint-post ,
                                    commands ,
                                    diffutils ,
                                    label ,
                                    mount ,
                                    standard-input  ,
                                    status
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
                                                                                    j = builtins.toString ( index + 1 ) ;
                                                                                    in
                                                                                        ''
                                                                                            OUT="$1"
                                                                                            mkdir --parents "$OUT/${ j }"
                                                                                            echo ${ command.command } > "$OUT/${ j }/command"
                                                                                            ${ command.command }
                                                                                            cp --recursive ${ resources-directory } "$OUT/${ j }/checkpoint"
                                                                                            find "$OUT/${ j }/checkpoint" -type d -exec touch {}/.gitkeep \;
                                                                                            if ! diff --recursive ${ command.checkpoint } "$OUT/${ j }/checkpoint"
                                                                                            then
                                                                                                echo "${ label } We expected the result of the ${ j }-th command ${ command.command } to be ${ resources-directory } but it was $OUT/${ j }/checkpoint" >&2
                                                                                                echo >&2
                                                                                                echo "$OUT/bin/func /home/emory/resources/d6aa3612e1f5bb476970d9ef9bcdb2b2dfa34054d7dfb3771b4093984eb7d7a8/mount/git /home/emory/resources/d6aa3612e1f5bb476970d9ef9bcdb2b2dfa34054d7dfb3771b4093984eb7d7a8/mount/work-tree $OUT/${ j }/checkpoint expected/${ label }/${ j }/checkpoint /home/emory/resources/d6aa3612e1f5bb476970d9ef9bcdb2b2dfa34054d7dfb3771b4093984eb7d7a8/mount/work-tree/expected/${ label }/${ j }/checkpoint"
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
                                                                        echo "$$" >> "$OUT/0/pid"
                                                                        if MOUNT_1="$( ${ implementation } ${ builtins.concatStringsSep " " arguments } ${ if builtins.typeOf standard-input == "string" then "< ${ builtins.toFile "standard-input" standard-input }" else "" } 2> "$OUT/test/standard-error" )"
                                                                        then
                                                                            if [[ ! -d "$MOUNT_1" ]]
                                                                            then
                                                                                echo "${ label } command ${ implementation } succeeded but MOUNT_1 $MOUNT is not a directory" >&2
                                                                                ${ failures_ "e551352c" }
                                                                            elif [[ "$MOUNT_1" != "${ mount }" ]]
                                                                            then
                                                                                echo "${ label } command ${ implementation } succeeded but MOUNT_1 $MOUNT_1 is not the expected directory ${ mount }" >&2
                                                                                ${ failures_ "e484b646" }
                                                                            fi
                                                                            if [[ -s ${ resources-directory }/test/standard-error ]]
                                                                            then
                                                                                echo "${ label } command ${ implementation } succeeded but it generated standard-error" >&2
                                                                                ${ failures_ "eede733e" }
                                                                            fi
                                                                            MOUNT_2="$( ${ implementation } ${ builtins.concatStringsSep " " arguments } ${ if builtins.typeOf standard-input == "string" then "< ${ builtins.toFile "standard-input" standard-input }" else "" } 2> "$OUT/test/standard-error" )"
                                                                            if [[ "$MOUNT_1" ${ if transient then "==" else "!=" } "$MOUNT_2" ]]
                                                                            then
                                                                                echo "${ label } the second invocation ${ if transient then "should" else "should not" } generate the same result as the first invocation" >&2
                                                                                ${ failures_ "9167f049" }
                                                                            fi
                                                                            ${ if status != 0 then ''exit 148'' else "# " }
                                                                        else
                                                                            STATUS="$?"
                                                                            if [[ "$STATUS" != "${ builtins.toString status }" ]]
                                                                            then
                                                                                echo "${ label } command ${ implementation } failed but we expected the status to be ${ builtins.toString status } and we observed $STATUS" >&2
                                                                                ${ failures_ "e3be9f66" }
                                                                            fi
                                                                            if [[ -s ${ resources-directory }/test/standard-output ]]
                                                                            then
                                                                                echo "${ label } command failed but it generated standard-output" >&2
                                                                                ${ failures_ "c4cb3838" }
                                                                            fi
                                                                            if [[ -s ${ resources-directory }/test/standard-error ]]
                                                                            then
                                                                                echo "${ label } command ${ implementation } failed but it generated standard-error"
                                                                                ${ failures_ "dde5524a" }
                                                                            fi
                                                                            MOUNT_2="$( ${ implementation } ${ builtins.concatStringsSep " " arguments } ${ if builtins.typeOf standard-input == "string" then "< ${ builtins.toFile "standard-input" standard-input }" else "" } 2> "$OUT/test/standard-error" )"
                                                                            if [[ -n "$MOUNT_2" ]]
                                                                            then
                                                                                echo "${ label } the first invocation generated an empty result and the second generation generated $MOUNT_2" >&2
                                                                                ${ failures_ "5f8b5de3" }
                                                                            fi
                                                                        fi
                                                                        cp --recursive ${ resources-directory } "$OUT/0/checkpoint-pre"
                                                                        find "$OUT/0/checkpoint-pre" -type d -exec touch {}/.gitkeep \;
                                                                        if ! diff --recursive ${ checkpoint-pre } "$OUT/0/checkpoint-pre"
                                                                        then
                                                                            echo "${ label } We expected the resources-directory pre initial clean to exactly match ${ checkpoint-pre } but it was $OUT/0/checkpoint-pre" >&2
                                                                            echo >&2
                                                                            echo "$OUT/bin/func /home/emory/resources/d6aa3612e1f5bb476970d9ef9bcdb2b2dfa34054d7dfb3771b4093984eb7d7a8/mount/git /home/emory/resources/d6aa3612e1f5bb476970d9ef9bcdb2b2dfa34054d7dfb3771b4093984eb7d7a8/mount/work-tree $OUT/0/checkpoint-pre expected/${ label }/0/checkpoint-pre /home/emory/resources/d6aa3612e1f5bb476970d9ef9bcdb2b2dfa34054d7dfb3771b4093984eb7d7a8/mount/work-tree/expected/${ label }/0/checkpoint-pre"
                                                                            ${ failures_ "a6f0de4f" }
                                                                        fi
                                                                    '' ;
                                                            } ;
                                                    root =
                                                        writeShellApplication
                                                            {
                                                                name = "root" ;
                                                                runtimeInputs = [ coreutils diffutils findutils flock invoke-resource setup ] ;
                                                                text =
                                                                    ''
                                                                        echo "The derivation for this check is $OUT"
                                                                        bash setup
                                                                        ${ builtins.concatStringsSep "\n" ( builtins.genList ( index : let c = command index ; in ''${ c }/bin/command "$OUT"'' ) ( builtins.length commands ) ) }
                                                                        if [[ -e ${ resources-directory }/debug ]]
                                                                        then
                                                                            echo ${ label } We expected the debug to be non-existant >&2
                                                                            cat ${ resources-directory }/debug
                                                                            ${ failures_ "bf77ed8c" }
                                                                        fi
                                                                        if [[ -n "$( find ${ resources-directory }/mounts -mindepth 1 -maxdepth 1 )" ]]
                                                                        then
                                                                            echo ${ label } We expected ${ resources-directory }/mounts to be an empty directory >&2
                                                                            ${ failures_ "65eb34ce" }
                                                                        fi
                                                                        if [[ -n "$( find ${ resources-directory }/canonical -mindepth 1 -maxdepth 1 )" ]]
                                                                        then
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
                                                    func =
                                                        writeShellApplication
                                                            {
                                                                name = "func" ;
                                                                text =
                                                                    ''
                                                                        export GIT_DIR="$1"
                                                                        export GIT_WORK_TREE="$2"
                                                                        INPUT="$3"
                                                                        OUTPUT_RELATIVE="$4"
                                                                        OUTPUT_ABSOLUTE="$5"
                                                                        if [[ -e "$OUTPUT_ABSOLUTE" ]]
                                                                        then
                                                                            git rm -r "$OUTPUT_RELATIVE"
                                                                        fi
                                                                        mkdir --parents "$( dirname "$OUTPUT_ABSOLUTE" )"
                                                                        cp --recursive "$INPUT" "$OUTPUT_ABSOLUTE"
                                                                        git add "$OUTPUT_RELATIVE"
                                                                        git commit -am "" --allow-empty --allow-empty-message
                                                                    '' ;
                                                            } ;
                                                    setup =
                                                        writeShellApplication
                                                            {
                                                                name = "setup" ;
                                                                runtimeInputs = [ bash coreutils diffutils flock invoke-resource ] ;
                                                                text =
                                                                    ''
                                                                        if [[ -e ${ resources-directory } ]]
                                                                        then
                                                                            echo ${ label } We expected the resources directory to not initially exist >&2
                                                                            ${ failures_ "a6e628b6" }
                                                                        fi
                                                                        mkdir "$OUT/test"
                                                                        bash invoke-resource
                                                                        exec 200> ${ resources-directory }/locks/test.setup.lock
                                                                        flock -x 200
                                                                        exec 201> ${ resources-directory }/locks/test.stall-for-process.lock
                                                                        flock -x 201
                                                                        exec 202> ${ resources-directory }/locks/test.stall-for-cleanup.lock
                                                                        flock -x 202
                                                                        exec 203> ${ resources-directory }/locks/test.teardown.lock
                                                                        flock -x 203
                                                                        cp --recursive ${ resources-directory } "$OUT/0/checkpoint-post"
                                                                        find "$OUT/0/checkpoint-post" -type d -exec touch {}/.gitkeep \;
                                                                        if ! diff --recursive ${ checkpoint-post } "$OUT/0/checkpoint-post"
                                                                        then
                                                                            echo ${ label } We expected the resources-directory post initial clean to exactly match ${ checkpoint-post } but it was "$OUT/0/checkpoint-post" >&2
                                                                            echo >&2
                                                                            echo "$OUT/bin/func /home/emory/resources/d6aa3612e1f5bb476970d9ef9bcdb2b2dfa34054d7dfb3771b4093984eb7d7a8/mount/git /home/emory/resources/d6aa3612e1f5bb476970d9ef9bcdb2b2dfa34054d7dfb3771b4093984eb7d7a8/mount/work-tree $OUT/0/checkpoint-post expected/${ label }/0/checkpoint-post /home/emory/resources/d6aa3612e1f5bb476970d9ef9bcdb2b2dfa34054d7dfb3771b4093984eb7d7a8/mount/work-tree/expected/${ label }/0/checkpoint-post"
                                                                            ${ failures_ "b42acd0d" }
                                                                        fi
                                                                    '' ;
                                                            } ;
                                                    in
                                                        ''
                                                            mkdir --parents $out/bin
                                                            makeWrapper ${ invoke-resource }/bin/invoke-resource $out/bin/invoke-resource --set OUT $out
                                                            makeWrapper ${ root }/bin/root $out/bin/root --set OUT $out
                                                            makeWrapper ${ setup }/bin/setup $out/bin/setup
                                                            makeWrapper ${ stall }/bin/stall $out/bin/stall
                                                            makeWrapper ${ func }/bin/func $out/bin/func
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
                                                                        ${ if testing-locks_ then "flock -s 200" else "#" }
                                                                        LINK=${ builtins.concatStringsSep "" [ "$" "{" "LINK:?LINK must be set" "}" ] }
                                                                        ARGUMENTS="$( printf '%s\n' "$@" | jq --raw-input --slurp 'split("\n") | map(select(length>0))' )" || ${ failures_ "a1b19aa5" }
                                                                        DESCRIPTION='${ builtins.toJSON description }'
                                                                        LINKS_TEMPORARY="$( temporary )" || ${ failures_ "cabcc321" }
                                                                        ${ if builtins.typeOf init == "null" then "#" else ''find "$LINK" -mindepth 1 -maxdepth 1 -type l > "$LINKS_TEMPORARY"'' }
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
                                                                        rm --force "$STANDARD_ERROR_FILE" "$STANDARD_OUTPUT_FILE"
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
                                                                            --arg MOUNT_INDEX "$MOUNT_INDEX" \
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
                                                                                "mount-index" : $MOUNT_INDEX ,
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
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 200" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 201" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 202" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 203" else "#" }
                                                                        flock -s 211
                                                                        ARGUMENTS="$( printf '%s\n' "$@" | jq --raw-input --slurp 'split("\n")[:-1]' )" || ${ failures_ "ea11161a" }
                                                                        DESCRIPTION='${ builtins.toJSON description }'
                                                                        LINKS=${ if builtins.typeOf init == "null" then "" else ''"$( find "${ resources-directory }/links/$MOUNT_INDEX" -mindepth 1 -maxdepth 1 -type l | jq --raw-input --slurp )" || ${ failures_ "a7486bbb" }'' }
                                                                        STANDARD_ERROR="$( cat "$STANDARD_ERROR_FILE" )" || ${ failures_ "a69f5bc2" }
                                                                        STANDARD_OUTPUT="$( cat "$STANDARD_OUTPUT_FILE" )" || ${ failures_ "dc662c73" }
                                                                        rm --force "$STANDARD_ERROR_FILE" "$STANDARD_OUTPUT_FILE"
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
                                                                            --arg MOUNT "$MOUNT" \
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
                                                                                "mount" : $MOUNT ,
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
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 200" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 202" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 203" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 204" else "#" }
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
                                                                        ${ if testing-locks_ then "exec 200> ${ resources-directory }/locks/test.setup.lock" else "#" }
                                                                        ${ if testing-locks_ then "flock -s 200" else "#" }
                                                                        ${ if testing-locks_ then "exec 201> ${ resources-directory }/locks/test.stall-for-process.lock" else "#" }
                                                                        ${ if testing-locks_ then "flock -s 201" else "#" }
                                                                        ${ if testing-locks_ then "exec 202> ${ resources-directory }/locks/test.stall-for-cleanup.lock" else "#" }
                                                                        ${ if testing-locks_ then "flock -s 202" else "#" }
                                                                        ${ if testing-locks_ then "exec 203> ${ resources-directory }/locks/test.teardown.lock" else "#" }
                                                                        ${ if testing-locks_ then "flock -s 203" else "#" }
                                                                        GOOD="$( temporary )" || ${ failures_ "f696cd77" }
                                                                        mkdir --parents ${ resources-directory }/temporary
                                                                        rm --recursive --force "${ resources-directory }/links/$MOUNT_INDEX"
                                                                        mv "${ resources-directory }/mounts/$MOUNT_INDEX" "$GOOD"
                                                                        rm --recursive --force "${ resources-directory }/recovery/$MOUNT_INDEX"
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
                                                                            --arg MOUNT_INDEX "$MOUNT_INDEX" \
                                                                            --arg STANDARD_INPUT "$STANDARD_INPUT" \
                                                                            --arg TYPE "$TYPE" \
                                                                            '{
                                                                                "arguments" : $ARGUMENTS ,
                                                                                "has-standard-input" : $HAS_STANDARD_INPUT ,
                                                                                "hash" : $HASH ,
                                                                                "mount-index" : $MOUNT_INDEX ,
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
                                                                            mkdir --parents ${ resources-directory }/locks
                                                                            ${ if testing-locks_ then "exec 200> ${ resources-directory }/locks/test.setup.lock" else "#" }
                                                                            ${ if testing-locks_ then "flock -s 200" else "#" }
                                                                            ${ if testing-locks_ then "exec 201> ${ resources-directory }/locks/test.stall-for-process.lock" else "#" }
                                                                            ${ if testing-locks_ then "flock -s 201" else "#" }
                                                                            ${ if testing-locks_ then "exec 202> ${ resources-directory }/locks/test.stall-for-cleanup.lock" else "#" }
                                                                            ${ if testing-locks_ then "flock -s 202" else "#" }
                                                                            ${ if testing-locks_ then "exec 203> ${ resources-directory }/locks/test.teardown.lock" else "#" }
                                                                            ${ if testing-locks_ then "flock -s 203" else "#" }
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
                                                                            ORIGINATOR_PID="$( ps -o ppid= -p "$PPID" )" || ${ failures_ "833fbd3f" }
                                                                            export ORIGINATOR_PID
                                                                            HASH="$( echo "${ pre-hash } ${ builtins.concatStringsSep "" [ "$TRANSIENT" "$" "{" "ARGUMENTS[*]" "}" ] } $STANDARD_INPUT $HAS_STANDARD_INPUT" | sha512sum | cut --characters 1-128 )" || ${ failures_ "bc3e1b88" }
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
                                                                            mkdir --parents ${ resources-directory }
                                                                            mkdir --parents "${ resources-directory }/locks"
                                                                            ${ if testing-locks_ then "exec 200> ${ resources-directory }/locks/test.setup.lock" else "#" }
                                                                            ${ if testing-locks_ && testing-locks then "flock -s 200" else "#" }
                                                                            ${ if testing-locks_ then "exec 201> ${ resources-directory }/locks/test.stall-for-process.lock" else "#" }
                                                                            ${ if testing-locks_ then "flock -s 201" else "#" }
                                                                            ${ if testing-locks_ then "exec 202> ${ resources-directory }/locks/test.stall-for-cleanup.lock" else "#" }
                                                                            ${ if testing-locks_ then "flock -s 202" else "#" }
                                                                            ${ if testing-locks_ then "exec 203> ${ resources-directory }/locks/test.teardown.lock" else "#" }
                                                                            ${ if testing-locks_ then "flock -s 203" else "#" }
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
                                                                            }' | log
                                                                        NOHUP="$( temporary )" || ${ failures_ "290a9299" }
                                                                        nohup stall-for-process > "$NOHUP" 2>&1 &
                                                                    '' ;
                                                                stall-for-cleanup =
                                                                    ''
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 202" else "#" }
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 203" else "#" }
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
                                                                                }' | log
                                                                        tail --follow /dev/null --pid "$ORIGINATOR_PID"
                                                                        NOHUP1="$( temporary )" || ${ failures_ "ee645658" }
                                                                        nohup stall-for-cleanup > "$NOHUP1" 2>&1 &
                                                                        NOHUP2="$( temporary )" || ${ failures_ "59978ab6" }
                                                                        nohup teardown > "$NOHUP2" 2>&1 &
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
                                                                            }' | log
                                                                        inotifywait --event move_self "$SYMLINK" --quiet
                                                                    '' ;
                                                                teardown =
                                                                    ''
                                                                        ${ if builtins.typeOf testing-locks == "bool" && testing-locks then "flock -s 203" else "#" }
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
                                                                            }' | log
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
                                                                        export HAS_STANDARD_INPUT=false
                                                                        export STANDARD_INPUT=
                                                                        rm --recursive --force "$LINK" # KLUDGE
                                                                        # ${ if builtins.typeOf init == "null" then "#" else ''rm --recursive --force "$LINK"'' }
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
                                    testing-locks_ =
                                        visitor.lib.implementation
                                            {
                                                bool = path : value : value ;
                                            }
                                            testing-locks ;
                                    transient_ =
                                        visitor.lib.implementation
                                            {
                                                bool = path : value : if value then ''"$( sequential )" || ${ failures_ "ea21ca9e" }"'' else "" ;
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
