# 28600
{
	inputs = { } ;
	outputs =
		{ self } :
		    {
		        lib =
                    {
                        buildFHSUserEnv ,
                        coreutils ,
                        flock ,
                        gc-root-directory ,
                        invalid-init-channel ,
                        invalid-release-channel ,
                        jq ,
                        procps ,
                        redis ,
                        resources ,
                        resources-directory ,
                        stale-init-channel ,
                        valid-init-channel ,
                        valid-release-channel ,
                        visitor ,
                        writeShellApplication
                    } @primary :
                        let
                            implementation =
                                {
                                    depth ,
                                    init ,
                                    init-resolutions ,
                                    release ,
                                    release-resolutions ,
                                    seed ,
                                    targets ,
                                    transient
                                } @secondary :
                                    let
                                        arguments =
                                            {
                                                init =
                                                    pkgs :
                                                        {
                                                            failure = failure ;
                                                            gc-root = gc-root ;
                                                            pkgs = pkgs ;
                                                            resources = resources ;
                                                            seed = seed ;
                                                            sequential = sequential ;
                                                            trace = trace ;
                                                            wrap = wrap ;
                                                        } ;
                                                release =
                                                    pkgs :
                                                        {
                                                            failure = failure ;
                                                            pkgs = pkgs ;
                                                            resources = resources ;
                                                            seed = seed ;
                                                            sequential = sequential ;
                                                            trace = trace ;
                                                        } ;
                                                resolve =
                                                    pkgs : resolve-path : direction :
                                                        {
                                                            direction = direction ;
                                                            failure = failure ;
                                                            pkgs = pkgs ;
                                                            resolve-path = resolve-path ;
                                                            resources = resources ;
                                                            seed = seed ;
                                                            sequential = sequential ;
                                                            trace = trace ;
                                                        } ;
                                            } ;
                                        create =
                                            buildFHSUserEnv
                                                {
                                                    name = "create" ;
                                                    runScript =
                                                        ''
                                                            bash -c '
                                                                if "$HAS_STANDARD_INPUT"
                                                                then
                                                                    create ${ builtins.concatStringsSep "" [ "$" "{" "@:-" "}" ] }
                                                                else
                                                                    create ${ builtins.concatStringsSep "" [ "$" "{" "@:-" "}" ] } < "$STANDARD_INPUT_FILE"
                                                                fi
                                                            ' "$0" "$@"
                                                        '' ;
                                                    targetPkgs =
                                                        pkgs :
                                                            [
                                                                trace
                                                                (
                                                                    let
                                                                        applications =
                                                                            {
                                                                                init =
                                                                                    visitor
                                                                                        {
                                                                                            lambda =
                                                                                                path : value :
                                                                                                    buildFHSUserEnv
                                                                                                        {
                                                                                                            extraBwrapArgs =
                                                                                                                [
                                                                                                                    "--bind ${ resources-directory }/mounts/$INDEX /mount"
                                                                                                                    ''--bind "$SIGNAL" /signal''
                                                                                                                    "--tmpfs /scratch"
                                                                                                                ] ;
                                                                                                            name = "init" ;
                                                                                                            runScript =
                                                                                                                ''
                                                                                                                    bash -c '
                                                                                                                        if "$HAS_STANDARD_INPUT"
                                                                                                                        then
                                                                                                                            if init "$@"
                                                                                                                            then
                                                                                                                                echo "$?" > /signal/signal
                                                                                                                            else
                                                                                                                                echo "$?" > /signal/signal
                                                                                                                            fi
                                                                                                                        else
                                                                                                                            if init "$@" < "$STANDARD_INPUT_FILE"
                                                                                                                            then
                                                                                                                                echo "$?" > /signal/signal
                                                                                                                            else
                                                                                                                                echo "$?" > /signal/signal
                                                                                                                            fi
                                                                                                                        fi
                                                                                                                    ' "$0" "$@"
                                                                                                                '' ;
                                                                                                            targetPkgs =
                                                                                                                pkgs :
                                                                                                                    [
                                                                                                                        (
                                                                                                                            pkgs.writeShellApplication
                                                                                                                                {
                                                                                                                                    name = "init" ;
                                                                                                                                    text =
                                                                                                                                        let
                                                                                                                                            a = arguments.init pkgs ;
                                                                                                                                            in value a ;
                                                                                                                                }
                                                                                                                        )
                                                                                                                    ] ;
                                                                                                        } ;
                                                                                            null = path : value : null ;
                                                                                        }
                                                                                        init ;
                                                                                release =
                                                                                    visitor
                                                                                        {
                                                                                            lambda =
                                                                                                path : value :
                                                                                                    buildFHSUserEnv
                                                                                                        {
                                                                                                            extraBwrapArgs =
                                                                                                                [
                                                                                                                    ''--bind "${ resources-directory }/mounts/$INDEX" /mount''
                                                                                                                    ''--tmpfs /scratch''
                                                                                                                ] ;
                                                                                                            name = "release" ;
                                                                                                            runScript = "release" ;
                                                                                                            targetPkgs =
                                                                                                                 pkgs :
                                                                                                                    [
                                                                                                                        (
                                                                                                                            pkgs.writeShellApplication
                                                                                                                                {
                                                                                                                                    name = "release" ;
                                                                                                                                    text =
                                                                                                                                        let
                                                                                                                                            a = arguments.release pkgs ;
                                                                                                                                            in value a ;
                                                                                                                                }
                                                                                                                        )
                                                                                                                    ] ;
                                                                                                        } ;
                                                                                            null = path : value : null ;
                                                                                        }
                                                                                        release ;
                                                                            } ;
                                                                        destroy =
                                                                            writeShellApplication
                                                                                {
                                                                                    name = "destroy" ;
                                                                                    runtimeInputs =
                                                                                        [
                                                                                            (
                                                                                                writeShellApplication
                                                                                                    {
                                                                                                        name = "destroy" ;
                                                                                                        runtimeInputs = [ applications.release failure log pkgs.coreutils pkgs.findutils pkgs.flock pkgs.inotify-tools pkgs.zstd sequential trace ] ;
                                                                                                        text =
                                                                                                            visitor
                                                                                                                {
                                                                                                                    lambda =
                                                                                                                        path : value :
                                                                                                                            let
                                                                                                                                a = arguments.release pkgs ;
                                                                                                                                release-resolutions =
                                                                                                                                    let
                                                                                                                                        lambda =
                                                                                                                                            path : value :
                                                                                                                                                let
                                                                                                                                                    application =
                                                                                                                                                        pkgs.writeShellApplication
                                                                                                                                                            {
                                                                                                                                                                name = "resolve" ;
                                                                                                                                                                runtimeInputs = [ pkgs.coreutils ] ;
                                                                                                                                                                text =
                                                                                                                                                                    let
                                                                                                                                                                        resolve =
                                                                                                                                                                            let
                                                                                                                                                                                application =
                                                                                                                                                                                    pkgs.writeShellApplication
                                                                                                                                                                                        {
                                                                                                                                                                                            name = "resolve" ;
                                                                                                                                                                                            runtimeInputs = [ ] ;
                                                                                                                                                                                            text =
                                                                                                                                                                                                ''
                                                                                                                                                                                                    echo 18510
                                                                                                                                                                                                '' ;
                                                                                                                                                                                        } ;
                                                                                                                                                                                in "${ application }/bin/resolve" ;
                                                                                                                                                                        in
                                                                                                                                                                            ''
                                                                                                                                                                                INDEX="$1"
                                                                                                                                                                                mkdir --parents ${ resources-directory }/invalid-resolve/$INDEX/${ builtins.concatStringsSep "/" ( builtins.map builtins.toJSON path ) }
                                                                                                                                                                                sed -e "s###" -e "w${ resources-directory }/invalid-resolve/$INDEX/${ builtins.concatStringsSep "/" ( builtins.map builtins.toJSON path ) }/resolve.sh" ${ resolve }
                                                                                                                                                                                chmod 0500 "${ resources-directory }/invalid-resolve/$INDEX/${ builtins.concatStringsSep "/" ( builtins.map builtins.toJSON path ) }/resolve.sh"
                                                                                                                                                                            '' ;
                                                                                                                                                            } ;
                                                                                                                                                    in ''${ application }/bin/resolve "$INDEX"'' ;
                                                                                                                                        null =
                                                                                                                                            path : value :
                                                                                                                                                let
                                                                                                                                                    application =
                                                                                                                                                        pkgs.writeShellApplication
                                                                                                                                                            {
                                                                                                                                                                name = "resolve" ;
                                                                                                                                                                runtimeInputs = [ pkgs.coreutils ] ;
                                                                                                                                                                text =
                                                                                                                                                                    let
                                                                                                                                                                        resolve =
                                                                                                                                                                            let
                                                                                                                                                                                application =
                                                                                                                                                                                    pkgs.writeShellApplication
                                                                                                                                                                                        {
                                                                                                                                                                                            name = "resolve" ;
                                                                                                                                                                                            runtimeInputs = [ ] ;
                                                                                                                                                                                            text =
                                                                                                                                                                                                ''
                                                                                                                                                                                                    echo 23416
                                                                                                                                                                                                '' ;
                                                                                                                                                                                        } ;
                                                                                                                                                                                in ''${ application }/bin/resolve "$INDEX"'' ;
                                                                                                                                                                        in
                                                                                                                                                                            ''
                                                                                                                                                                                HASH="$1"
                                                                                                                                                                                INDEX="$2"
                                                                                                                                                                                mkdir --parents ${ resources-directory }/invalid-resolve/$INDEX/${ builtins.concatStringsSep "/" ( builtins.map builtins.toString path ) }
                                                                                                                                                                                sed -e "s#\$HASH#$HASH#" -e "s#\$INDEX#$INDEX#" -e "w${ resources-directory }/invalid-resolve/$INDEX/${ builtins.concatStringsSep "/" ( builtins.map builtins.toString path ) }/resolve.sh" ${ resolve }
                                                                                                                                                                                chmod 0500 "${ resources-directory }/invalid-resolve/$INDEX/${ builtins.concatStringsSep "/" ( builtins.map builtins.toString path ) }/resolve.sh"
                                                                                                                                                                            '' ;
                                                                                                                                                            } ;
                                                                                                                                                    in "${ application }/bin/resolve" ;
                                                                                                                                        release-resolutions =
                                                                                                                                            visitor
                                                                                                                                                {
                                                                                                                                                    lambda = lambda ;
                                                                                                                                                    null = null ;
                                                                                                                                                    list = path : list : builtins.concatLists list ;
                                                                                                                                                    set = path : set : builtins.concatLists ( builtins.attrValues set ) ;
                                                                                                                                                }
                                                                                                                                                { resolve = release-resolutions ; } ;
                                                                                                                                        in
                                                                                                                                            builtins.concatLists
                                                                                                                                                [
                                                                                                                                                ] ;
                                                                                                                                in
                                                                                                                                    ''
                                                                                                                                        rm "${ resources-directory }/release/$INDEX"
                                                                                                                                        # shellcheck disable=SC2153
                                                                                                                                        INDEX="$_INDEX"
                                                                                                                                        rm --force "${ resources-directory }/marks/$INDEX"
                                                                                                                                        if [[ -d "${ resources-directory }/pids/$INDEX" ]]
                                                                                                                                        then
                                                                                                                                            find "${ resources-directory }/pids/$INDEX" -mindepth 1 -maxdepth 1 -type f -exec basename {} \; | while read -r PID
                                                                                                                                            do
                                                                                                                                                trace "1179 PID $PID"
                                                                                                                                                tail --follow /dev/null --pid "$PID"
                                                                                                                                                trace "27859 PID $PID"
                                                                                                                                            done
                                                                                                                                        fi
                                                                                                                                        trace 14764
                                                                                                                                        mkdir --parents "${ gc-root-directory }"
                                                                                                                                        find ${ gc-root-directory } -mindepth 1 -type l | while read -r LINK
                                                                                                                                        do
                                                                                                                                            FILE="$( readlink --canonicalize "$LINK" )" || failure 15150
                                                                                                                                            if [[ "${ resources-directory }/mounts/$INDEX" == "$FILE" ]]
                                                                                                                                            then
                                                                                                                                                echo 7010 "LINK=$LINK" "FILE=$FILE" "TARGET=${ resources-directory }/mounts/$INDEX"
                                                                                                                                                inotifywait --event delete_self "$LINK"
                                                                                                                                            fi
                                                                                                                                        done
                                                                                                                                        exec 203> "${ resources-directory }/locks/$HASH"
                                                                                                                                        flock -x 203
                                                                                                                                        exec 204> "${ resources-directory }/locks/$INDEX"
                                                                                                                                        flock -x 204
                                                                                                                                        if [[ -e "${ resources-directory }/marks/$INDEX" ]]
                                                                                                                                        then
                                                                                                                                            flock -u 203
                                                                                                                                            flock -u 204
                                                                                                                                            nohup "$0" &
                                                                                                                                        else
                                                                                                                                            rm --force "${ resources-directory }/canonical/$HASH"
                                                                                                                                            flock -u 203 echo 10200
                                                                                                                                            mkdir --parents ${ resources-directory }/logs
                                                                                                                                            SCRIPT_FILE="$( ${ script-file release a } )" || failure 17419
                                                                                                                                            SEED='${ builtins.toJSON seed }'
                                                                                                                                            STANDARD_ERROR_SEQUENCE="$( sequential )" || failure 16457
                                                                                                                                            STANDARD_ERROR_FILE="${ resources-directory }/logs/$STANDARD_ERROR_SEQUENCE"
                                                                                                                                            STANDARD_OUTPUT_SEQUENCE="$( sequential )" || failure 27852
                                                                                                                                            STANDARD_OUTPUT_FILE="${ resources-directory }/logs/$STANDARD_OUTPUT_SEQUENCE"
                                                                                                                                            if release > "$STANDARD_OUTPUT_FILE" 2> "$STANDARD_ERROR_FILE"
                                                                                                                                            then
                                                                                                                                                STATUS="$?"
                                                                                                                                            else
                                                                                                                                                STATUS="$?"
                                                                                                                                            fi
                                                                                                                                            chmod 0400 "$STANDARD_ERROR_FILE" "$STANDARD_OUTPUT_FILE"
                                                                                                                                            if [[ "$STATUS" == 0 ]] && [[ ! -s "$STANDARD_ERROR_FILE" ]]
                                                                                                                                            then
                                                                                                                                                ARCHIVE="$( mktemp --dry-run --suffix ".tar.xz" )" || failure 7546
                                                                                                                                                mkdir --parents "${ gc-root-directory }/$INDEX" "${ resources-directory }/mounts/$INDEX" "${ resources-directory }/pids/$INDEX"
                                                                                                                                                touch "${ resources-directory }/release/$INDEX"
                                                                                                                                                tar --create --xz --file "$ARCHIVE" "${ gc-root-directory }/$INDEX" "${ resources-directory }/mounts/$INDEX" "${ resources-directory }/pids/$INDEX" "${ resources-directory }/release/$INDEX"
                                                                                                                                                rm --recursive --force "${ gc-root-directory }/$INDEX" "${ resources-directory }/mounts/$INDEX" "${ resources-directory }/pids/$INDEX" "${ resources-directory }/release/$INDEX"
                                                                                                                                                trace 6738
                                                                                                                                                jq \
                                                                                                                                                    --compact-output \
                                                                                                                                                    --null-input \
                                                                                                                                                    --arg INDEX "$INDEX" \
                                                                                                                                                    --rawfile SCRIPT "$SCRIPT_FILE" \
                                                                                                                                                    --argjson SEED "$SEED" \
                                                                                                                                                    --rawfile STANDARD_OUTPUT "$STANDARD_OUTPUT_FILE" \
                                                                                                                                                    --argjson STATUS "$STATUS" \
                                                                                                                                                    '{
                                                                                                                                                        "WTF" : 1 ,
                                                                                                                                                        "index" : $INDEX ,
                                                                                                                                                        "script" : $SCRIPT ,
                                                                                                                                                        "seed" : $SEED ,
                                                                                                                                                        "standard-output" : $STANDARD_OUTPUT
                                                                                                                                                    }' | log ${ valid-release-channel }
                                                                                                                                            else
                                                                                                                                                jq \
                                                                                                                                                    --compact-output \
                                                                                                                                                    --null-input \
                                                                                                                                                    --arg INDEX "$INDEX" \
                                                                                                                                                    --rawfile SCRIPT "$SCRIPT_FILE" \
                                                                                                                                                    --argjson SEED "$SEED" \
                                                                                                                                                    --rawfile STANDARD_ERROR "$STANDARD_ERROR_FILE" \
                                                                                                                                                    --rawfile STANDARD_OUTPUT "$STANDARD_OUTPUT_FILE" \
                                                                                                                                                    --argjson STATUS "$STATUS" \
                                                                                                                                                    '{
                                                                                                                                                        "WTF" : 2 ,
                                                                                                                                                        "index" : $INDEX ,
                                                                                                                                                        "script" : $SCRIPT ,
                                                                                                                                                        "seed" : $SEED ,
                                                                                                                                                        "standard-error": $STANDARD_ERROR ,
                                                                                                                                                        "standard-output" : $STANDARD_OUTPUT ,
                                                                                                                                                        "status" : $STATUS
                                                                                                                                                    }' | log ${ invalid-release-channel }
                                                                                                                                            fi
                                                                                                                                        fi
                                                                                                                                    '' ;
                                                                                                                    null =
                                                                                                                        path : value :
                                                                                                                            ''
                                                                                                                                echo 1111927120 "INDEX=$INDEX"
                                                                                                                                rm --force "${ resources-directory }/marks/$INDEX"
                                                                                                                                mkdir --parents "${ resources-directory }/pids/$INDEX"
                                                                                                                                find "${ resources-directory }/pids/$INDEX" -mindepth 1 -maxdepth 1 -type f -exec basename {} \; | while read -r PID
                                                                                                                                do
                                                                                                                                    tail --follow /dev/null --pid "$PID"
                                                                                                                                done
                                                                                                                                mkdir --parents "${ gc-root-directory }"
                                                                                                                                echo 30425 find "${ gc-root-directory }" -mindepth 1 -type l
                                                                                                                                find "${ gc-root-directory }" -mindepth 1 -type l
                                                                                                                                find "${ gc-root-directory }" -mindepth 1 -type l | while read -r LINK
                                                                                                                                do
                                                                                                                                    FILE="$( readlink --canonicalize "$LINK" )" || failure 15150
                                                                                                                                    echo 1656 "LINK=$LINK" "FILE=$FILE" "TARGET=${ resources-directory }/mounts/$INDEX"
                                                                                                                                    if [[ "${ resources-directory }/mounts/$INDEX" == "$FILE" ]]
                                                                                                                                    then
                                                                                                                                        echo 9337 "LINK=$LINK" "FILE=$FILE" "TARGET=${ resources-directory }/mounts/$INDEX"
                                                                                                                                        inotifywait --event delete_self "$LINK"
                                                                                                                                        echo 5614 "LINK=$LINK" "FILE=$FILE" "TARGET=${ resources-directory }/mounts/$INDEX"
                                                                                                                                    fi
                                                                                                                                done
                                                                                                                                echo 4351
                                                                                                                                exec 203> "${ resources-directory }/locks/$HASH"
                                                                                                                                flock -x 203
                                                                                                                                exec 204> "${ resources-directory }/locks/$INDEX"
                                                                                                                                flock -x 204
                                                                                                                                if [[ -e "${ resources-directory }/marks/$INDEX" ]]
                                                                                                                                then
                                                                                                                                    flock -u 203
                                                                                                                                    flock -u 204
                                                                                                                                    nohup "$0" &
                                                                                                                                else
                                                                                                                                    echo 13649
                                                                                                                                    rm "${ resources-directory }/canonical/$HASH"
                                                                                                                                    echo  9251
                                                                                                                                    flock -u 203
                                                                                                                                    SEED='${ builtins.toJSON seed }'
                                                                                                                                    ARCHIVE="$( mktemp --dry-run --suffix ".tar.xz" )" || failure 7546
                                                                                                                                    mkdir --parents "${ gc-root-directory }/$INDEX"
                                                                                                                                    tar --create --xz --file "$ARCHIVE" "${ gc-root-directory }/$INDEX" "${ resources-directory }/mounts/$INDEX" "${ resources-directory }/pids/$INDEX" "${ resources-directory }/release/$INDEX"
                                                                                                                                    echo 763
                                                                                                                                    rm --recursive --force "${ gc-root-directory }/$INDEX" "${ resources-directory }/mounts/$INDEX" "${ resources-directory }/pids/$INDEX" "${ resources-directory }/release/$INDEX"
                                                                                                                                    JSON_SEQUENCE="$( sequential )" || failure 32030
                                                                                                                                    JSON_FILE="${ resources-directory }/logs/$JSON_SEQUENCE"
                                                                                                                                    jq \
                                                                                                                                        --compact-output \
                                                                                                                                        --null-input \
                                                                                                                                        --arg HASH "$HASH" \
                                                                                                                                        --arg INDEX "$INDEX" \
                                                                                                                                        --argjson SEED "$SEED" \
                                                                                                                                        '{
                                                                                                                                            "hash" : $HASH ,
                                                                                                                                            "index" : $INDEX ,
                                                                                                                                            "seed" : $SEED
                                                                                                                                        }' > "$JSON_FILE"
                                                                                                                                    redis-cli PUBLISH ${ valid-release-channel } "$JSON_FILE"
                                                                                                                                fi
                                                                                                                            '' ;
                                                                                                                }
                                                                                                                release ;
                                                                                                    }
                                                                                            )
                                                                                        ] ;
                                                                                    text =
                                                                                        ''
                                                                                            # shellcheck disable=SC2269
                                                                                            export _HASH="$_HASH"
                                                                                            # shellcheck disable=SC2269
                                                                                            export _INDEX="$_INDEX"
                                                                                            # shellcheck disable=SC2153
                                                                                            export INDEX=$_INDEX
                                                                                            mkdir --parents "${ gc-root-directory }/$INDEX"
                                                                                            # shellcheck disable=SC2153
                                                                                            export HASH=$_HASH
                                                                                            destroy
                                                                                        '' ;
                                                                                } ;
                                                                        destroy2 =
                                                                            writeShellApplication
                                                                                {
                                                                                    name = "destroy" ;
                                                                                    runtimeInputs =
                                                                                        [
                                                                                            trace
                                                                                            (
                                                                                                buildFHSUserEnv
                                                                                                    {
                                                                                                        extraBwrapArgs =
                                                                                                            [
                                                                                                                "--bind ${ gc-root-directory } ${ gc-root-directory }"
                                                                                                                "--bind ${ resources-directory} ${ resources-directory }"
                                                                                                            ] ;
                                                                                                        name = "destroy" ;
                                                                                                        runScript = "destroy" ;
                                                                                                        targetPkgs =
                                                                                                            pkgs :
                                                                                                                [
                                                                                                                    (
                                                                                                                        pkgs.writeShellApplication
                                                                                                                            {
                                                                                                                                name = "destroy" ;
                                                                                                                                runtimeInputs = [ applications.release failure log pkgs.coreutils pkgs.findutils pkgs.flock pkgs.inotify-tools pkgs.zstd sequential trace ] ;
                                                                                                                                text =
                                                                                                                                    visitor
                                                                                                                                        {
                                                                                                                                            lambda =
                                                                                                                                                path : value :
                                                                                                                                                    let
                                                                                                                                                        a = arguments.release pkgs ;
                                                                                                                                                        release-resolutions =
                                                                                                                                                            let
                                                                                                                                                                lambda =
                                                                                                                                                                    path : value :
                                                                                                                                                                        let
                                                                                                                                                                            application =
                                                                                                                                                                                pkgs.writeShellApplication
                                                                                                                                                                                    {
                                                                                                                                                                                        name = "resolve" ;
                                                                                                                                                                                        runtimeInputs = [ pkgs.coreutils ] ;
                                                                                                                                                                                        text =
                                                                                                                                                                                            let
                                                                                                                                                                                                resolve =
                                                                                                                                                                                                    let
                                                                                                                                                                                                        application =
                                                                                                                                                                                                            pkgs.writeShellApplication
                                                                                                                                                                                                                {
                                                                                                                                                                                                                    name = "resolve" ;
                                                                                                                                                                                                                    runtimeInputs = [ ] ;
                                                                                                                                                                                                                    text =
                                                                                                                                                                                                                        ''
                                                                                                                                                                                                                            echo 18510
                                                                                                                                                                                                                        '' ;
                                                                                                                                                                                                                } ;
                                                                                                                                                                                                        in "${ application }/bin/resolve" ;
                                                                                                                                                                                                in
                                                                                                                                                                                                    ''
                                                                                                                                                                                                        INDEX="$1"
                                                                                                                                                                                                        mkdir --parents ${ resources-directory }/invalid-resolve/$INDEX/${ builtins.concatStringsSep "/" ( builtins.map builtins.toJSON path ) }
                                                                                                                                                                                                        sed -e "s###" -e "w${ resources-directory }/invalid-resolve/$INDEX/${ builtins.concatStringsSep "/" ( builtins.map builtins.toJSON path ) }/resolve.sh" ${ resolve }
                                                                                                                                                                                                        chmod 0500 "${ resources-directory }/invalid-resolve/$INDEX/${ builtins.concatStringsSep "/" ( builtins.map builtins.toJSON path ) }/resolve.sh"
                                                                                                                                                                                                    '' ;
                                                                                                                                                                                    } ;
                                                                                                                                                                            in ''${ application }/bin/resolve "$INDEX"'' ;
                                                                                                                                                                null =
                                                                                                                                                                    path : value :
                                                                                                                                                                        let
                                                                                                                                                                            application =
                                                                                                                                                                                pkgs.writeShellApplication
                                                                                                                                                                                    {
                                                                                                                                                                                        name = "resolve" ;
                                                                                                                                                                                        runtimeInputs = [ pkgs.coreutils ] ;
                                                                                                                                                                                        text =
                                                                                                                                                                                            let
                                                                                                                                                                                                resolve =
                                                                                                                                                                                                    let
                                                                                                                                                                                                        application =
                                                                                                                                                                                                            pkgs.writeShellApplication
                                                                                                                                                                                                                {
                                                                                                                                                                                                                    name = "resolve" ;
                                                                                                                                                                                                                    runtimeInputs = [ ] ;
                                                                                                                                                                                                                    text =
                                                                                                                                                                                                                        ''
                                                                                                                                                                                                                            echo 23416
                                                                                                                                                                                                                        '' ;
                                                                                                                                                                                                                } ;
                                                                                                                                                                                                        in ''${ application }/bin/resolve "$INDEX"'' ;
                                                                                                                                                                                                in
                                                                                                                                                                                                    ''
                                                                                                                                                                                                        HASH="$1"
                                                                                                                                                                                                        INDEX="$2"
                                                                                                                                                                                                        mkdir --parents ${ resources-directory }/invalid-resolve/$INDEX/${ builtins.concatStringsSep "/" ( builtins.map builtins.toString path ) }
                                                                                                                                                                                                        sed -e "s#\$HASH#$HASH#" -e "s#\$INDEX#$INDEX#" -e "w${ resources-directory }/invalid-resolve/$INDEX/${ builtins.concatStringsSep "/" ( builtins.map builtins.toString path ) }/resolve.sh" ${ resolve }
                                                                                                                                                                                                        chmod 0500 "${ resources-directory }/invalid-resolve/$INDEX/${ builtins.concatStringsSep "/" ( builtins.map builtins.toString path ) }/resolve.sh"
                                                                                                                                                                                                    '' ;
                                                                                                                                                                                    } ;
                                                                                                                                                                            in "${ application }/bin/resolve" ;
                                                                                                                                                                release-resolutions =
                                                                                                                                                                    visitor
                                                                                                                                                                        {
                                                                                                                                                                            lambda = lambda ;
                                                                                                                                                                            null = null ;
                                                                                                                                                                            list = path : list : builtins.concatLists list ;
                                                                                                                                                                            set = path : set : builtins.concatLists ( builtins.attrValues set ) ;
                                                                                                                                                                        }
                                                                                                                                                                        { resolve = release-resolutions ; } ;
                                                                                                                                                                in
                                                                                                                                                                    builtins.concatLists
                                                                                                                                                                        [
                                                                                                                                                                        ] ;
                                                                                                                                                        in
                                                                                                                                                            ''
                                                                                                                                                                rm "${ resources-directory }/release/$INDEX"
                                                                                                                                                                # shellcheck disable=SC2153
                                                                                                                                                                INDEX="$_INDEX"
                                                                                                                                                                rm --force "${ resources-directory }/marks/$INDEX"
                                                                                                                                                                trace 17040
                                                                                                                                                                if [[ -d "${ resources-directory }/pids/$INDEX" ]]
                                                                                                                                                                then
                                                                                                                                                                    find "${ resources-directory }/pids/$INDEX" -mindepth 1 -maxdepth 1 -type f -exec basename {} \; | while read -r PID
                                                                                                                                                                    do
                                                                                                                                                                        trace "8565 PID $PID"
                                                                                                                                                                        tail --follow /dev/null --pid "$PID"
                                                                                                                                                                        trace "26485 PID $PID"
                                                                                                                                                                    done
                                                                                                                                                                fi
                                                                                                                                                                trace 14764
                                                                                                                                                                mkdir --parents "${ gc-root-directory }"
                                                                                                                                                                find ${ gc-root-directory } -mindepth 1 -type l | while read -r LINK
                                                                                                                                                                do
                                                                                                                                                                    FILE="$( readlink --canonicalize "$LINK" )" || failure 15150
                                                                                                                                                                    if [[ "${ resources-directory }/mounts/$INDEX" == "$FILE" ]]
                                                                                                                                                                    then
                                                                                                                                                                        echo 7010 "LINK=$LINK" "FILE=$FILE" "TARGET=${ resources-directory }/mounts/$INDEX"
                                                                                                                                                                        inotifywait --event delete_self "$LINK"
                                                                                                                                                                    fi
                                                                                                                                                                done
                                                                                                                                                                exec 203> "${ resources-directory }/locks/$HASH"
                                                                                                                                                                flock -x 203
                                                                                                                                                                exec 204> "${ resources-directory }/locks/$INDEX"
                                                                                                                                                                flock -x 204
                                                                                                                                                                if [[ -e "${ resources-directory }/marks/$INDEX" ]]
                                                                                                                                                                then
                                                                                                                                                                    flock -u 203
                                                                                                                                                                    flock -u 204
                                                                                                                                                                    nohup "$0" &
                                                                                                                                                                else
                                                                                                                                                                    rm --force "${ resources-directory }/canonical/$HASH"
                                                                                                                                                                    flock -u 203 echo 10200
                                                                                                                                                                    mkdir --parents ${ resources-directory }/logs
                                                                                                                                                                    SCRIPT_FILE="$( ${ script-file release a } )" || failure 17419
                                                                                                                                                                    SEED='${ builtins.toJSON seed }'
                                                                                                                                                                    STANDARD_ERROR_SEQUENCE="$( sequential )" || failure 16457
                                                                                                                                                                    STANDARD_ERROR_FILE="${ resources-directory }/logs/$STANDARD_ERROR_SEQUENCE"
                                                                                                                                                                    STANDARD_OUTPUT_SEQUENCE="$( sequential )" || failure 27852
                                                                                                                                                                    STANDARD_OUTPUT_FILE="${ resources-directory }/logs/$STANDARD_OUTPUT_SEQUENCE"
                                                                                                                                                                    if release > "$STANDARD_OUTPUT_FILE" 2> "$STANDARD_ERROR_FILE"
                                                                                                                                                                    then
                                                                                                                                                                        STATUS="$?"
                                                                                                                                                                    else
                                                                                                                                                                        STATUS="$?"
                                                                                                                                                                    fi
                                                                                                                                                                    chmod 0400 "$STANDARD_ERROR_FILE" "$STANDARD_OUTPUT_FILE"
                                                                                                                                                                    if [[ "$STATUS" == 0 ]] && [[ ! -s "$STANDARD_ERROR_FILE" ]]
                                                                                                                                                                    then
                                                                                                                                                                        ARCHIVE="$( mktemp --dry-run --suffix ".tar.xz" )" || failure 7546
                                                                                                                                                                        mkdir --parents "${ gc-root-directory }/$INDEX" "${ resources-directory }/mounts/$INDEX" "${ resources-directory }/pids/$INDEX"
                                                                                                                                                                        touch "${ resources-directory }/release/$INDEX"
                                                                                                                                                                        tar --create --xz --file "$ARCHIVE" "${ gc-root-directory }/$INDEX" "${ resources-directory }/mounts/$INDEX" "${ resources-directory }/pids/$INDEX" "${ resources-directory }/release/$INDEX"
                                                                                                                                                                        rm --recursive --force "${ gc-root-directory }/$INDEX" "${ resources-directory }/mounts/$INDEX" "${ resources-directory }/pids/$INDEX" "${ resources-directory }/release/$INDEX"
                                                                                                                                                                        trace 6738
                                                                                                                                                                        jq \
                                                                                                                                                                            --compact-output \
                                                                                                                                                                            --null-input \
                                                                                                                                                                            --arg INDEX "$INDEX" \
                                                                                                                                                                            --rawfile SCRIPT "$SCRIPT_FILE" \
                                                                                                                                                                            --argjson SEED "$SEED" \
                                                                                                                                                                            --rawfile STANDARD_OUTPUT "$STANDARD_OUTPUT_FILE" \
                                                                                                                                                                            --argjson STATUS "$STATUS" \
                                                                                                                                                                            '{
                                                                                                                                                                                "WTF" : 1 ,
                                                                                                                                                                                "index" : $INDEX ,
                                                                                                                                                                                "script" : $SCRIPT ,
                                                                                                                                                                                "seed" : $SEED ,
                                                                                                                                                                                "standard-output" : $STANDARD_OUTPUT
                                                                                                                                                                            }' | log ${ valid-release-channel }
                                                                                                                                                                    else
                                                                                                                                                                        jq \
                                                                                                                                                                            --compact-output \
                                                                                                                                                                            --null-input \
                                                                                                                                                                            --arg INDEX "$INDEX" \
                                                                                                                                                                            --rawfile SCRIPT "$SCRIPT_FILE" \
                                                                                                                                                                            --argjson SEED "$SEED" \
                                                                                                                                                                            --rawfile STANDARD_ERROR "$STANDARD_ERROR_FILE" \
                                                                                                                                                                            --rawfile STANDARD_OUTPUT "$STANDARD_OUTPUT_FILE" \
                                                                                                                                                                            --argjson STATUS "$STATUS" \
                                                                                                                                                                            '{
                                                                                                                                                                                "WTF" : 2 ,
                                                                                                                                                                                "index" : $INDEX ,
                                                                                                                                                                                "script" : $SCRIPT ,
                                                                                                                                                                                "seed" : $SEED ,
                                                                                                                                                                                "standard-error": $STANDARD_ERROR ,
                                                                                                                                                                                "standard-output" : $STANDARD_OUTPUT ,
                                                                                                                                                                                "status" : $STATUS
                                                                                                                                                                            }' | log ${ invalid-release-channel }
                                                                                                                                                                    fi
                                                                                                                                                                fi
                                                                                                                                                            '' ;
                                                                                                                                            null =
                                                                                                                                                path : value :
                                                                                                                                                    ''
                                                                                                                                                        echo 1111927120 "INDEX=$INDEX"
                                                                                                                                                        rm --force "${ resources-directory }/marks/$INDEX"
                                                                                                                                                        mkdir --parents "${ resources-directory }/pids/$INDEX"
                                                                                                                                                        find "${ resources-directory }/pids/$INDEX" -mindepth 1 -maxdepth 1 -type f -exec basename {} \; | while read -r PID
                                                                                                                                                        do
                                                                                                                                                            tail --follow /dev/null --pid "$PID"
                                                                                                                                                        done
                                                                                                                                                        mkdir --parents "${ gc-root-directory }"
                                                                                                                                                        echo 30425 find "${ gc-root-directory }" -mindepth 1 -type l
                                                                                                                                                        find "${ gc-root-directory }" -mindepth 1 -type l
                                                                                                                                                        find "${ gc-root-directory }" -mindepth 1 -type l | while read -r LINK
                                                                                                                                                        do
                                                                                                                                                            FILE="$( readlink --canonicalize "$LINK" )" || failure 15150
                                                                                                                                                            echo 1656 "LINK=$LINK" "FILE=$FILE" "TARGET=${ resources-directory }/mounts/$INDEX"
                                                                                                                                                            if [[ "${ resources-directory }/mounts/$INDEX" == "$FILE" ]]
                                                                                                                                                            then
                                                                                                                                                                echo 9337 "LINK=$LINK" "FILE=$FILE" "TARGET=${ resources-directory }/mounts/$INDEX"
                                                                                                                                                                inotifywait --event delete_self "$LINK"
                                                                                                                                                                echo 5614 "LINK=$LINK" "FILE=$FILE" "TARGET=${ resources-directory }/mounts/$INDEX"
                                                                                                                                                            fi
                                                                                                                                                        done
                                                                                                                                                        echo 4351
                                                                                                                                                        exec 203> "${ resources-directory }/locks/$HASH"
                                                                                                                                                        flock -x 203
                                                                                                                                                        exec 204> "${ resources-directory }/locks/$INDEX"
                                                                                                                                                        flock -x 204
                                                                                                                                                        if [[ -e "${ resources-directory }/marks/$INDEX" ]]
                                                                                                                                                        then
                                                                                                                                                            flock -u 203
                                                                                                                                                            flock -u 204
                                                                                                                                                            nohup "$0" &
                                                                                                                                                        else
                                                                                                                                                            echo 13649
                                                                                                                                                            rm "${ resources-directory }/canonical/$HASH"
                                                                                                                                                            echo  9251
                                                                                                                                                            flock -u 203
                                                                                                                                                            SEED='${ builtins.toJSON seed }'
                                                                                                                                                            ARCHIVE="$( mktemp --dry-run --suffix ".tar.xz" )" || failure 7546
                                                                                                                                                            mkdir --parents "${ gc-root-directory }/$INDEX"
                                                                                                                                                            tar --create --xz --file "$ARCHIVE" "${ gc-root-directory }/$INDEX" "${ resources-directory }/mounts/$INDEX" "${ resources-directory }/pids/$INDEX" "${ resources-directory }/release/$INDEX"
                                                                                                                                                            echo 763
                                                                                                                                                            rm --recursive --force "${ gc-root-directory }/$INDEX" "${ resources-directory }/mounts/$INDEX" "${ resources-directory }/pids/$INDEX" "${ resources-directory }/release/$INDEX"
                                                                                                                                                            JSON_SEQUENCE="$( sequential )" || failure 32030
                                                                                                                                                            JSON_FILE="${ resources-directory }/logs/$JSON_SEQUENCE"
                                                                                                                                                            jq \
                                                                                                                                                                --compact-output \
                                                                                                                                                                --null-input \
                                                                                                                                                                --arg HASH "$HASH" \
                                                                                                                                                                --arg INDEX "$INDEX" \
                                                                                                                                                                --argjson SEED "$SEED" \
                                                                                                                                                                '{
                                                                                                                                                                    "hash" : $HASH ,
                                                                                                                                                                    "index" : $INDEX ,
                                                                                                                                                                    "seed" : $SEED
                                                                                                                                                                }' > "$JSON_FILE"
                                                                                                                                                            redis-cli PUBLISH ${ valid-release-channel } "$JSON_FILE"
                                                                                                                                                        fi
                                                                                                                                                    '' ;
                                                                                                                                        }
                                                                                                                                        release ;
                                                                                                                            }
                                                                                                                    )
                                                                                                                ] ;
                                                                                                    }
                                                                                            )
                                                                                        ] ;
                                                                                    text =
                                                                                        ''
                                                                                            # shellcheck disable=SC2269
                                                                                            export _HASH="$_HASH"
                                                                                            # shellcheck disable=SC2269
                                                                                            export _INDEX="$_INDEX"
                                                                                            # shellcheck disable=SC2153
                                                                                            export INDEX=$_INDEX
                                                                                            mkdir --parents "${ gc-root-directory }/$INDEX"
                                                                                            # shellcheck disable=SC2153
                                                                                            export HASH=$_HASH
                                                                                            destroy
                                                                                        '' ;
                                                                                } ;
                                                                        resolutions =
                                                                            direction :
                                                                                let
                                                                                    channel =
                                                                                        visitor
                                                                                            {
                                                                                                bool = path : value : if value then valid-init-channel else valid-release-channel ;
                                                                                            }
                                                                                            direction ;
                                                                                    directory =
                                                                                        visitor
                                                                                            {
                                                                                                bool =
                                                                                                    path : value :
                                                                                                        if value then
                                                                                                            ''
                                                                                                                ${ resources-directory }/invalid-init/$INDEX''
                                                                                                        else
                                                                                                            ''
                                                                                                                ${ resources-directory }/invalid-release/$INDEX'' ;
                                                                                            }
                                                                                            direction ;
                                                                                    resolutions =
                                                                                        visitor
                                                                                            {
                                                                                                lambda =
                                                                                                    path : value :
                                                                                                        let
                                                                                                            a = arguments.resolve pkgs path direction ;
                                                                                                            b = value a ;
                                                                                                            in
                                                                                                                [
                                                                                                                    ''
                                                                                                                        mkdir --parents "${ directory }/resolve/${ builtins.concatStringsSep "/" ( builtins.map builtins.toString path ) }"
                                                                                                                    ''
                                                                                                                    ''
                                                                                                                        sed -e "s#\$_HASH#$HASH#" -e "s#\$_INDEX#$INDEX#" -e "s#\$_SCRIPT_FILE#${ b }#" -e "w${ directory }/resolve/${ builtins.concatStringsSep "/" ( builtins.map builtins.toString path ) }/resolve.sh" ${ resolve.lambda path } > /dev/null 2>&1
                                                                                                                    ''
                                                                                                                    ''
                                                                                                                        chmod 0500 "${ directory }/resolve/${ builtins.concatStringsSep "/" ( builtins.map builtins.toString path ) }/resolve.sh"
                                                                                                                    ''
                                                                                                                ] ;
                                                                                                list = path : list : builtins.concatLists list ;
                                                                                                null =
                                                                                                    path : value :
                                                                                                        [
                                                                                                            ''
                                                                                                                mkdir --parents "${ directory }/resolve/${ builtins.concatStringsSep "/" ( builtins.map builtins.toString path ) }"
                                                                                                            ''
                                                                                                            ''
                                                                                                                RESOLUTION_PATH='${ builtins.toJSON path }'
                                                                                                            ''
                                                                                                            ''
                                                                                                                sed -e "s#\HAS_SCRIPT#false#" -e "s#\$HASH#$HASH#" -e "s#\$_HASH#$HASH#" -e "s#\$_INDEX#$INDEX" -e "s#\$INDEX#$INDEX#" -e "s#\$RELEASE_FILE#${ resources-directory }/release/$INDEX#" -e "s#\$RESOLUTION_PATH#$RESOLUTION_PATH#" -e "s#\$SCRIPT_FILE##" -e "w${ directory }/resolve/${ builtins.concatStringsSep "/" ( builtins.map builtins.toString path ) }/resolve.sh" ${ resolve.null } > /dev/null 2>&1
                                                                                                            ''
                                                                                                            ''
                                                                                                                chmod 0500 "${ directory }/resolve/${ builtins.concatStringsSep "/" ( builtins.map builtins.toString path ) }/resolve.sh"
                                                                                                            ''
                                                                                                        ] ;
                                                                                                set = path : set : builtins.concatLists ( builtins.attrValues set ) ;
                                                                                            }
                                                                                            source-resolutions ;
                                                                                    resolve =
                                                                                        {
                                                                                            lambda =
                                                                                                path :
                                                                                                    let
                                                                                                        application =
                                                                                                            pkgs.writeShellApplication
                                                                                                                {
                                                                                                                    name = "resolve" ;
                                                                                                                    runtimeInputs = [ failure log pkgs.coreutils pkgs.gnused pkgs.jq pkgs.redis sequential ] ;
                                                                                                                    text =
                                                                                                                        ''
                                                                                                                            # shellcheck disable=SC2153
                                                                                                                            HASH="$_HASH"
                                                                                                                            # shellcheck disable=SC2153
                                                                                                                            INDEX="$_INDEX"
                                                                                                                            # shellcheck disable=SC2269
                                                                                                                            _HASH="$_HASH"
                                                                                                                            # shellcheck disable=SC2269
                                                                                                                            _INDEX="$_INDEX"
                                                                                                                            # shellcheck disable=SC2153
                                                                                                                            SCRIPT_FILE="$_SCRIPT_FILE"
                                                                                                                            STANDARD_ERROR_SEQUENCE="$( sequential )" || failure 9691798625321771
                                                                                                                            STANDARD_ERROR_FILE="${ resources-directory }/logs/$STANDARD_ERROR_SEQUENCE"
                                                                                                                            STANDARD_OUTPUT_SEQUENCE="$( sequential )" || failure 2986933649455245
                                                                                                                            STANDARD_OUTPUT_FILE="${ resources-directory }/logs/$STANDARD_OUTPUT_SEQUENCE"
                                                                                                                            if [[ "$#" -gt 0 ]]
                                                                                                                            then
                                                                                                                                ARGUMENTS="$( printf '%s\n' "$@" | jq --raw-input . | jq --slurp . )" || failure 8734692413302431
                                                                                                                            else
                                                                                                                                ARGUMENTS="[]"
                                                                                                                            fi
                                                                                                                            if [[ -t 0 ]]
                                                                                                                            then
                                                                                                                                HAS_STANDARD_INPUT=false
                                                                                                                                STANDARD_INPUT=
                                                                                                                                if "$SCRIPT_FILE" "${ builtins.concatStringsSep "" [ "$" "{" "@:-" "}" ] }" > "$STANDARD_OUTPUT_FILE" 2> "$STANDARD_ERROR_FILE"
                                                                                                                                then
                                                                                                                                    STATUS="$?"
                                                                                                                                else
                                                                                                                                    STATUS="$?"
                                                                                                                                fi
                                                                                                                            else
                                                                                                                                HAS_STANDARD_INPUT=true
                                                                                                                                STANDARD_INPUT="$( cat )" || failure 5689582774767916
                                                                                                                                if "$SCRIPT_FILE" "${ builtins.concatStringsSep "" [ "$" "{" "@:-" "}" ] }" <<< "$STANDARD_INPUT" > "$STANDARD_OUTPUT_FILE" 2> "$STANDARD_ERROR_FILE"
                                                                                                                                then
                                                                                                                                    STATUS="$?"
                                                                                                                                else
                                                                                                                                    STATUS="$?"
                                                                                                                                fi
                                                                                                                            fi
                                                                                                                            if [[ "$STATUS" -eq 0 ]] && [[ ! -s "$STANDARD_ERROR_FILE" ]]
                                                                                                                            then
                                                                                                                                jq \
                                                                                                                                    --null-input \
                                                                                                                                    --compact-output \
                                                                                                                                    --argjson ARGUMENTS "$ARGUMENTS" \
                                                                                                                                    --argjson HAS_STANDARD_INPUT "$HAS_STANDARD_INPUT" \
                                                                                                                                    --arg INDEX "$INDEX" \
                                                                                                                                    --argjson RESOLVE_PATH '${ builtins.toJSON path }' \
                                                                                                                                    --rawfile SCRIPT "$SCRIPT_FILE" \
                                                                                                                                    --arg STANDARD_INPUT "$STANDARD_INPUT" \
                                                                                                                                    --rawfile STANDARD_OUTPUT "$STANDARD_OUTPUT_FILE" \
                                                                                                                                    '{
                                                                                                                                        "WTF" : 3 ,
                                                                                                                                        "arguments" : $ARGUMENTS ,
                                                                                                                                        "has-standard-input" : $HAS_STANDARD_INPUT ,
                                                                                                                                        "index" : $INDEX ,
                                                                                                                                        "resolve-path" : $RESOLVE_PATH ,
                                                                                                                                        "script" : $SCRIPT  ,
                                                                                                                                        "standard-input" : $STANDARD_INPUT ,
                                                                                                                                        "standard-output" : $STANDARD_OUTPUT
                                                                                                                                    }' | log ${ valid-init-channel }
                                                                                                                                RELEASE_FILE="${ resources-directory }/release/$_INDEX"
                                                                                                                                # shellcheck disable=SC2016,SC2086
                                                                                                                                trace 29404
                                                                                                                                sed -e s#'$'_HASH#$HASH# -e s#'$'_INDEX#$INDEX# -e "w$RELEASE_FILE" ${ destroy }/bin/destroy > /dev/null 2>&1
                                                                                                                                trace 118644
                                                                                                                                chmod 0500 "$RELEASE_FILE"
                                                                                                                                rm --recursive --force "${ directory }"
                                                                                                                            else
                                                                                                                                # shellcheck disable=SC2016
                                                                                                                                jq \
                                                                                                                                    --null-input \
                                                                                                                                    --compact-output \
                                                                                                                                    --argjson ARGUMENTS "$ARGUMENTS" \
                                                                                                                                    --argjson HAS_STANDARD_INPUT "$HAS_STANDARD_INPUT" \
                                                                                                                                    --arg INDEX "$INDEX" \
                                                                                                                                    --argjson RESOLVE_PATH '${ builtins.toJSON path }' \
                                                                                                                                    --rawfile SCRIPT "$SCRIPT_FILE" \
                                                                                                                                    --rawfile STANDARD_ERROR "$STANDARD_ERROR_FILE" \
                                                                                                                                    --arg STANDARD_INPUT "$STANDARD_INPUT" \
                                                                                                                                    --rawfile STANDARD_OUTPUT "$STANDARD_OUTPUT_FILE" \
                                                                                                                                    --argjson STATUS "$STATUS" \
                                                                                                                                    '{
                                                                                                                                        "WTF" : 4 ,
                                                                                                                                        "arguments" : $ARGUMENTS ,
                                                                                                                                        "has-standard-input" : $HAS_STANDARD_INPUT ,
                                                                                                                                        "index" : $INDEX ,
                                                                                                                                        "resolve-path" : $RESOLVE_PATH ,
                                                                                                                                        "script" : $SCRIPT ,
                                                                                                                                        "standard-error" : $STANDARD_ERROR ,
                                                                                                                                        "standard-input" : $STANDARD_INPUT ,
                                                                                                                                        "standard-output" : $STANDARD_OUTPUT ,
                                                                                                                                        "status" : $STATUS
                                                                                                                                    }' | log ${ invalid-init-channel }
                                                                                                                                exit 64
                                                                                                                            fi
                                                                                                                        '' ;
                                                                                                                } ;
                                                                                                        in "${ application }/bin/resolve" ;
                                                                                            null =
                                                                                                let
                                                                                                    application =
                                                                                                        pkgs.writeShellApplication
                                                                                                            {
                                                                                                                name = "resolve" ;
                                                                                                                runtimeInputs = [ failure pkgs.coreutils pkgs.jq pkgs.redis sequential ] ;
                                                                                                                text =
                                                                                                                    ''
                                                                                                                        # shellcheck disable=SC2153,SC2016
                                                                                                                        _RELEASE_FILE="$RELEASE_FILE"
                                                                                                                        STATUS=0
                                                                                                                        STANDARD_ERROR_SEQUENCE="$( sequential )" || failure 9691798625321771
                                                                                                                        STANDARD_ERROR_FILE="${ resources-directory }/logs/$STANDARD_ERROR_SEQUENCE"
                                                                                                                        STANDARD_INPUT_SEQUENCE="$( sequential )" || failure 8384911191384463
                                                                                                                        STANDARD_INPUT_FILE="${ resources-directory }/logs/$STANDARD_INPUT_SEQUENCE"
                                                                                                                        STANDARD_OUTPUT_SEQUENCE="$( sequential )" || failure 2986933649455245
                                                                                                                        STANDARD_OUTPUT_FILE="${ resources-directory }/logs/$STANDARD_OUTPUT_SEQUENCE"
                                                                                                                        ARGUMENTS="$( printf '%s\n' "$@" | jq --raw-input . | jq --slurp . )" || failure 8734692413302431
                                                                                                                        # shellcheck disable=SC2153
                                                                                                                        _HAS_SCRIPT="$HAS_SCRIPT"
                                                                                                                        # shellcheck disable=SC2153
                                                                                                                        _SCRIPT_FILE="$SCRIPT_FILE"
                                                                                                                        if [[ -t 0 ]]
                                                                                                                        then
                                                                                                                            HAS_STANDARD_INPUT=false
                                                                                                                            if "$_HAS_SCRIPT"
                                                                                                                            then
                                                                                                                                if "$_SCRIPT_FILE" "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[*]" "}" ] }" > "$STANDARD_OUTPUT_FILE" 2> "$STANDARD_ERROR_FILE"
                                                                                                                                then
                                                                                                                                    STATUS="$?"
                                                                                                                                else
                                                                                                                                    STATUS="$?"
                                                                                                                                fi
                                                                                                                            fi
                                                                                                                        else
                                                                                                                            HAS_STANDARD_INPUT=true
                                                                                                                            cat "$STANDARD_INPUT_FILE"
                                                                                                                            if "$_HAS_SCRIPT"
                                                                                                                            then
                                                                                                                                if "$_SCRIPT_FILE" "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" <<< "$STANDARD_INPUT" > "$STANDARD_OUTPUT_FILE" 2> "$STANDARD_ERROR_FILE"
                                                                                                                                then
                                                                                                                                    STATUS="$?"
                                                                                                                                else
                                                                                                                                    STATUS="$?"
                                                                                                                                fi
                                                                                                                            fi
                                                                                                                        fi
                                                                                                                        JSON_SEQUENCE="$( sequential )" || failure 8452556526050122
                                                                                                                        JSON_FILE="${ resources-directory }/logs/$JSON_SEQUENCE"
                                                                                                                        # shellcheck disable=SC2153
                                                                                                                        _HASH="$HASH"
                                                                                                                        # shellcheck disable=SC2153
                                                                                                                        _INDEX="$INDEX"
                                                                                                                        RELEASE_FILE="${ resources-directory }/release/$INDEX"
                                                                                                                        if [[ -e "$RELEASE_FILE" ]]
                                                                                                                        then
                                                                                                                            failure 9339682764537318
                                                                                                                        fi
                                                                                                                        sed -e "s#\$_HASH#$HASH#" -e "s#\$_INDEX#$INDEX#" -e "w$RELEASE_FILE" ${ destroy }/bin/destroy > /dev/null 2>&1
                                                                                                                        echo "# 6848967577446656" >> "$RELEASE_FILE"
                                                                                                                        chmod 0500 "$RELEASE_FILE"
                                                                                                                        jq \
                                                                                                                            --null-input \
                                                                                                                            --compact-output \
                                                                                                                            --argjson ARGUMENTS "$ARGUMENTS" \
                                                                                                                            --arg _HAS_SCRIPT "$_HAS_SCRIPT" \
                                                                                                                            --argjson HAS_STANDARD_INPUT "$HAS_STANDARD_INPUT" \
                                                                                                                            --arg HASH "$HASH" \
                                                                                                                            --arg INDEX "$INDEX" \
                                                                                                                            --arg _RELEASE_FILE "$_RELEASE_FILE" \
                                                                                                                            --argjson _RESOLUTION_PATH "$_RESOLUTION_PATH" \
                                                                                                                            --arg _SCRIPT_FILE "$_SCRIPT_FILE" \
                                                                                                                            --arg STANDARD_ERROR_FILE "$STANDARD_ERROR_FILE" \
                                                                                                                            --arg STANDARD_INPUT_FILE "$STANDARD_INPUT_FILE" \
                                                                                                                            --arg STANDARD_OUTPUT_FILE "$STANDARD_OUTPUT_FILE" \
                                                                                                                            --argjson STATUS "$STATUS" \
                                                                                                                            '{
                                                                                                                                "WTF" : 5 ,
                                                                                                                                "arguments" : $ARGUMENTS ,
                                                                                                                                "has-script" : $_HAS_SCRIPT ,
                                                                                                                                "has-standard-input" : $HAS_STANDARD_INPUT ,
                                                                                                                                "hash" : $_HASH ,
                                                                                                                                "index" : $_INDEX ,
                                                                                                                                "release-file" : $_RELEASE_FILE ,
                                                                                                                                "resolution-path" : $_RESOLUTION_PATH ,
                                                                                                                                "script-file" : $_SCRIPT_FILE ,
                                                                                                                                "standard-error-file" : $STANDARD_ERROR_FILE ,
                                                                                                                                "standard-input-file" : $STANDARD_INPUT_FILE ,
                                                                                                                                "standard-output-file" : $STANDARD_OUTPUT_FILE ,
                                                                                                                                "status" : $STATUS
                                                                                                                            }' > "$JSON_FILE"
                                                                                                                        if [[ "$STATUS" -eq 0 ]]
                                                                                                                        then
                                                                                                                            rm --recursive --force "${ directory }"
                                                                                                                            redis-cli PUBLISH valid-init "$JSON_FILE"
                                                                                                                        else
                                                                                                                            redis-cli PUBLISH invalid-init "$JSON_FILE"
                                                                                                                        fi
                                                                                                                        exit "$STATUS"
                                                                                                                    '' ;
                                                                                                            } ;
                                                                                                    in "${ application }/bin/resolve" ;
                                                                                        } ;
                                                                                    source-resolutions =
                                                                                        visitor
                                                                                            {
                                                                                                bool = path : value : if value then init-resolutions else release-resolutions ;
                                                                                            }
                                                                                            direction ;
                                                                                    in
                                                                                        builtins.concatLists
                                                                                            [
                                                                                                [
                                                                                                    ''
                                                                                                        mkdir --parents "${ directory }"
                                                                                                    ''
                                                                                                    ''
                                                                                                        sed -e "s#\$HAS_SCRIPT#false#" -e "s#\$HASH#$HASH#" -e "s#\$INDEX#$INDEX#" -e "s#\$RELEASE_FILE#${ resources-directory }/release/$INDEX#" -e "s#\$SCRIPT_FILE##" -e "w${ directory }/resolve.sh" ${ resolve.null } > /dev/null 2>&1
                                                                                                    ''
                                                                                                    ''
                                                                                                        chmod 0500 "${ directory }/resolve.sh"
                                                                                                    ''
                                                                                                ]
                                                                                                resolutions
                                                                                            ] ;
                                                                        in
                                                                            pkgs.writeShellApplication
                                                                                {
                                                                                    name = "create" ;
                                                                                    runtimeInputs = [ applications.init failure log pid pkgs.coreutils pkgs.flock pkgs.gnused pkgs.jq sequential trace ] ;
                                                                                    text =
                                                                                        visitor
                                                                                            {
                                                                                                lambda =
                                                                                                    path : value :
                                                                                                        let
                                                                                                            a = arguments.init pkgs ;
                                                                                                            resolutions =
                                                                                                                visitor
                                                                                                                    {
                                                                                                                        lambda =
                                                                                                                            path : value :
                                                                                                                                let
                                                                                                                                    application =
                                                                                                                                        pkgs.writeShellApplication
                                                                                                                                            {
                                                                                                                                                name = "resolve" ;
                                                                                                                                                runtimeInputs = [ pkgs.coreutils ] ;
                                                                                                                                                text =
                                                                                                                                                    let
                                                                                                                                                        a = arguments.resolve pkgs [ ] false ;
                                                                                                                                                        resolve =
                                                                                                                                                            let
                                                                                                                                                                application =
                                                                                                                                                                    pkgs.writeShellApplication
                                                                                                                                                                        {
                                                                                                                                                                            name = "resolve" ;
                                                                                                                                                                            runtimeInputs = [ failure sequential pkgs.coreutils ] ;
                                                                                                                                                                            text = "$SCRIPT_FILE" ;
                                                                                                                                                                        } ;
                                                                                                                                                                in "${ application }/bin/resolve" ;
                                                                                                                                                        in
                                                                                                                                                            ''
                                                                                                                                                                HASH="$1"
                                                                                                                                                                INDEX="$2"
                                                                                                                                                                SCRIPT_FILE='${ script-file value a }'
                                                                                                                                                                OUTPUT_SEQUENCE="$( sequential )" || failure 5243846297643168
                                                                                                                                                                ERROR_SEQUENCE="$( sequential )" || failure 4614838668989285
                                                                                                                                                                mkdir --parents "${ resources-directory }/invalid-init/$INDEX/${ builtins.concatStringsSep "/" ( builtins.map builtins.toString path ) }"
                                                                                                                                                                mkdir --parents ${ resources-directory }/logs
                                                                                                                                                                sed -e "s#\$HASH#$HASH#" -e "s#\$INDEX#$INDEX#" -e "s#\$SCRIPT_FILE#$SCRIPT_FILE#" -e "w${ resources-directory }/invalid-init/$INDEX/${ builtins.concatStringsSep "/" ( builtins.map builtins.toString path ) }/resolve.sh" ${ resolve } > "${ resources-directory }/logs/$OUTPUT_SEQUENCE" 2> "${ resources-directory }/logs/$ERROR_SEQUENCE"
                                                                                                                                                                chmod 0500 "${ resources-directory }/invalid-init/$INDEX/${ builtins.concatStringsSep "/" ( builtins.map builtins.toString path ) }/resolve.sh"
                                                                                                                                                            '' ;
                                                                                                                                            } ;
                                                                                                                                    in [ ''${ application }/bin/resolve "$HASH" "$INDEX"'' ] ;
                                                                                                                        null =
                                                                                                                            path : value :
                                                                                                                                let
                                                                                                                                    application =
                                                                                                                                        pkgs.writeShellApplication
                                                                                                                                            {
                                                                                                                                                name = "resolve" ;
                                                                                                                                                runtimeInputs = [ pkgs.coreutils ] ;
                                                                                                                                                text =
                                                                                                                                                    let
                                                                                                                                                        resolve =
                                                                                                                                                            let
                                                                                                                                                                application =
                                                                                                                                                                    pkgs.writeShellApplication
                                                                                                                                                                        {
                                                                                                                                                                            name = "resolve" ;
                                                                                                                                                                            runtimeInputs = [ failure sequential pkgs.coreutils ] ;
                                                                                                                                                                            text =
                                                                                                                                                                                ''
                                                                                                                                                                                    echo 17333
                                                                                                                                                                                    echo "$HASH"
                                                                                                                                                                                    echo "$INDEX"
                                                                                                                                                                                '' ;
                                                                                                                                                                        } ;
                                                                                                                                                                in "${ application }/bin/resolve" ;
                                                                                                                                                        in
                                                                                                                                                            ''
                                                                                                                                                                HASH="$1"
                                                                                                                                                                INDEX="$2"
                                                                                                                                                                OUTPUT_SEQUENCE="$( sequential )" || failure 5243846297643168
                                                                                                                                                                ERROR_SEQUENCE="$( sequential )" || failure 4614838668989285
                                                                                                                                                                mkdir --parents "${ resources-directory }/invalid-init/$INDEX/${ builtins.concatStringsSep "/" ( builtins.map builtins.toString path ) }"
                                                                                                                                                                mkdir --parents ${ resources-directory }/logs
                                                                                                                                                                sed -e "s#\$HASH#$HASH#" -e "s#\$INDEX#$INDEX#" -e "w${ resources-directory }/invalid-init/$INDEX/${ builtins.concatStringsSep "/" ( builtins.map builtins.toString path ) }/resolve.sh" ${ resolve } > "${ resources-directory }/logs/$OUTPUT_SEQUENCE" 2> "${ resources-directory }/logs/$ERROR_SEQUENCE"
                                                                                                                                                                chmod 0500 "${ resources-directory }/invalid-init/$INDEX/${ builtins.concatStringsSep "/" ( builtins.map builtins.toString path ) }/resolve.sh"
                                                                                                                                                            '' ;
                                                                                                                                            } ;
                                                                                                                                    in [ ''${ application }/bin/resolve "$HASH" "$INDEX"'' ] ;
                                                                                                                        list = path : list : builtins.concatLists list ;
                                                                                                                        set = path : set : builtins.concatLists ( builtins.attrValues set ) ;
                                                                                                                    }
                                                                                                                    { default = null ; resolutions = init-resolutions ; } ;
                                                                                                            in
                                                                                                                ''
                                                                                                                    echo 6986572542557694 > /tmp/DEBUG
                                                                                                                    mkdir --parents ${ resources-directory }/logs
                                                                                                                    echo 3654834852556233 >> /tmp/DEBUG
                                                                                                                    INDEX="$( sequential )" || failure 5607
                                                                                                                    echo 2919585643294958 >> /tmp/DEBUG
                                                                                                                    export INDEX
                                                                                                                    exec 204> "${ resources-directory }/locks/$INDEX"
                                                                                                                    flock -x 204
                                                                                                                    mkdir --parents ${ resources-directory }/marks
                                                                                                                    touch "${ resources-directory }/marks/$INDEX"
                                                                                                                    mkdir --parents "${ resources-directory }/mounts/$INDEX"
                                                                                                                    mkdir --parents "${ resources-directory }/release"
                                                                                                                    if [[ "$#" == 0 ]]
                                                                                                                    then
                                                                                                                        ARGUMENTS=[]
                                                                                                                    else
                                                                                                                        ARGUMENTS="$( printf '%s\n' "$@" | jq --raw-input . | jq --slurp . )" || failure 8826156374172617
                                                                                                                    fi
                                                                                                                    # shellcheck disable=SC2016
                                                                                                                    SCRIPT_FILE="$( ${ script-file init a } )"
                                                                                                                    SEED='${ builtins.toJSON seed }'
                                                                                                                    STANDARD_ERROR_SEQUENCE="$( sequential )" || failure 7574
                                                                                                                    STANDARD_ERROR_FILE="${ resources-directory }/logs/$STANDARD_ERROR_SEQUENCE"
                                                                                                                    STANDARD_OUTPUT_SEQUENCE="$( sequential )" || failure 21462
                                                                                                                    STANDARD_OUTPUT_FILE="${ resources-directory }/logs/$STANDARD_OUTPUT_SEQUENCE"
                                                                                                                    echo 9625214521458483 >> /tmp/DEBUG
                                                                                                                    init "$@" > "$STANDARD_OUTPUT_FILE" 2> "$STANDARD_ERROR_FILE"
                                                                                                                    echo 2727691298113249 >> /tmp/DEBUG
                                                                                                                    TARGETS_OBSERVED="$( find "${resources-directory}/mounts/$INDEX" -mindepth 1 -maxdepth 1 -exec basename {} \; | LC_ALL=C sort | jq --raw-input . | jq --compact-output --slurp . )" || failure 28445
                                                                                                                    if [[ "$TRANSIENT" == -1 ]]
                                                                                                                    then
                                                                                                                        TRANSIENT_JSON=false
                                                                                                                    else
                                                                                                                        TRANSIENT_JSON=true
                                                                                                                    fi
                                                                                                                    while [[ ! -e "$SIGNAL/signal" ]]
                                                                                                                    do
                                                                                                                        sleep 0
                                                                                                                    done
                                                                                                                    STATUS="$( cat "$SIGNAL/signal" )" || failure 11902
                                                                                                                    chmod 0400 "$STANDARD_OUTPUT_FILE" "$STANDARD_ERROR_FILE"
                                                                                                                    echo 1839454585667768 >> /tmp/DEBUG
                                                                                                                    if [[ "$STATUS" == 0 ]] && [[ ! -s "$STANDARD_ERROR_FILE" ]] && [[ "$TARGETS_EXPECTED" == "$TARGETS_OBSERVED" ]]
                                                                                                                    then
                                                                                                                        echo 5219365285757541 >> /tmp/DEBUG
                                                                                                                        pid "$ULTIMATE_PID" ${ builtins.toString depth } "$INDEX"
                                                                                                                        echo 7118546882223467 >> /tmp/DEBUG
                                                                                                                        RELEASE_FILE="${ resources-directory }/release/$INDEX"
                                                                                                                        echo 1495191433138176 >> /tmp/DEBUG
                                                                                                                        if [[ -e "$RELEASE_FILE" ]]
                                                                                                                        then
                                                                                                                            echo 6392986933177972 >> /tmp/DEBUG
                                                                                                                            failure 16697
                                                                                                                        fi
                                                                                                                        # shellcheck disable=SC2129
                                                                                                                        echo 1742328312635292 >> /tmp/DEBUG
                                                                                                                        # shellcheck disable=SC2129
                                                                                                                        sed -e "s#\$_HASH#$HASH#" -e "s#\$_INDEX#$INDEX#" -e "s#\$HASH#$HASH#" -e "s#\$INDEX#$INDEX#" -e "w$RELEASE_FILE" ${ destroy }/bin/destroy >> /tmp/DEBUG 2>&1
                                                                                                                        echo 4915227719246627 >> /tmp/DEBUG
                                                                                                                        echo "# 1593884543916188" >> "$RELEASE_FILE"
                                                                                                                        echo 1114471876255727 >> /tmp/DEBUG
                                                                                                                        chmod 0500 "$RELEASE_FILE"
                                                                                                                        echo 4298255823544273 >> /tmp/DEBUG
                                                                                                                        if [[ "$HAS_STANDARD_INPUT" == "true" ]]
                                                                                                                        then
                                                                                                                            jq \
                                                                                                                                --compact-output \
                                                                                                                                --null-input \
                                                                                                                                --argjson ARGUMENTS "$ARGUMENTS" \
                                                                                                                                --arg INDEX "$INDEX" \
                                                                                                                                --arg RELEASE_FILE "$RELEASE_FILE" \
                                                                                                                                --rawfile SCRIPT "$SCRIPT_FILE" \
                                                                                                                                --argjson SEED "$SEED" \
                                                                                                                                --rawfile STANDARD_ERROR "$STANDARD_ERROR_FILE" \
                                                                                                                                --rawfile STANDARD_OUTPUT "$STANDARD_OUTPUT_FILE" \
                                                                                                                                --rawfile STANDARD_INPUT "$STANDARD_INPUT_FILE" \
                                                                                                                                --argjson TARGETS_EXPECTED "$TARGETS_EXPECTED" \
                                                                                                                                --argjson TRANSIENT "$TRANSIENT_JSON" \
                                                                                                                                '{
                                                                                                                                    "arguments" : $ARGUMENTS ,
                                                                                                                                    "index" : $INDEX ,
                                                                                                                                    "script" : $SCRIPT ,
                                                                                                                                    "seed" : $SEED ,
                                                                                                                                    "standard-output" : $STANDARD_OUTPUT ,
                                                                                                                                    "targets" : $TARGETS_EXPECTED ,
                                                                                                                                    "transient" : $TRANSIENT
                                                                                                                                }' | log ${ valid-init-channel }
                                                                                                                        else
                                                                                                                            jq \
                                                                                                                                --compact-output \
                                                                                                                                --null-input \
                                                                                                                                --argjson ARGUMENTS "$ARGUMENTS" \
                                                                                                                                --arg INDEX "$INDEX" \
                                                                                                                                --arg RELEASE_FILE "$RELEASE_FILE" \
                                                                                                                                --rawfile SCRIPT "$SCRIPT_FILE" \
                                                                                                                                --argjson SEED "$SEED" \
                                                                                                                                --rawfile STANDARD_ERROR "$STANDARD_ERROR_FILE" \
                                                                                                                                --rawfile STANDARD_OUTPUT "$STANDARD_OUTPUT_FILE" \
                                                                                                                                --argjson TARGETS_EXPECTED "$TARGETS_EXPECTED" \
                                                                                                                                --argjson TRANSIENT "$TRANSIENT_JSON" \
                                                                                                                                '{
                                                                                                                                    "arguments" : $ARGUMENTS ,
                                                                                                                                    "index" : $INDEX ,
                                                                                                                                    "script" : $SCRIPT ,
                                                                                                                                    "seed" : $SEED ,
                                                                                                                                    "standard-output" : $STANDARD_OUTPUT ,
                                                                                                                                    "targets" : $TARGETS_EXPECTED ,
                                                                                                                                    "transient" : $TRANSIENT
                                                                                                                                }' | log ${ valid-init-channel }
                                                                                                                        fi
                                                                                                                        mkdir --parents ${ resources-directory }/canonical
                                                                                                                        ln --symbolic "${ resources-directory }/mounts/$INDEX" "${ resources-directory }/canonical/$HASH"
                                                                                                                        echo "${ resources-directory }/mounts/$INDEX"
                                                                                                                        echo 2179917276469149 >> /tmp/DEBUG
                                                                                                                    else
                                                                                                                        echo 8519152656595598 >> /tmp/DEBUG
                                                                                                                        if [[ "$HAS_STANDARD_INPUT" == true ]]
                                                                                                                        then
                                                                                                                            jq \
                                                                                                                                --compact-output \
                                                                                                                                --null-input \
                                                                                                                                --argjson ARGUMENTS "$ARGUMENTS" \
                                                                                                                                --arg INDEX "$INDEX" \
                                                                                                                                --rawfile SCRIPT "$SCRIPT_FILE" \
                                                                                                                                --argjson SEED "$SEED" \
                                                                                                                                --rawfile STANDARD_ERROR "$STANDARD_ERROR_FILE" \
                                                                                                                                --rawfile STANDARD_INPUT "$STANDARD_INPUT_FILE" \
                                                                                                                                --rawfile STANDARD_OUTPUT "$STANDARD_OUTPUT_FILE" \
                                                                                                                                --argjson STATUS "$STATUS" \
                                                                                                                                --argjson TARGETS_EXPECTED "$TARGETS_EXPECTED" \
                                                                                                                                --argjson TARGETS_OBSERVED "$TARGETS_OBSERVED" \
                                                                                                                                --argjson TRANSIENT "$TRANSIENT_JSON" \
                                                                                                                                '{
                                                                                                                                    "arguments" : $ARGUMENTS ,
                                                                                                                                    "index" : $INDEX ,
                                                                                                                                    "script" : $SCRIPT ,
                                                                                                                                    "seed" : $SEED ,
                                                                                                                                    "standard-error" : $STANDARD_ERROR ,
                                                                                                                                    "standard-input" : $STANDARD_INPUT ,
                                                                                                                                    "standard-output" : $STANDARD_OUTPUT ,
                                                                                                                                    "status" : $STATUS ,
                                                                                                                                    "targets" : { "expected" : $TARGETS_EXPECTED , "observed" : $TARGETS_OBSERVED } ,
                                                                                                                                    "transient" : $TRANSIENT
                                                                                                                                }' | log ${ invalid-init-channel }
                                                                                                                        else
                                                                                                                            jq \
                                                                                                                                --compact-output \
                                                                                                                                --null-input \
                                                                                                                                --argjson ARGUMENTS "$ARGUMENTS" \
                                                                                                                                --arg INDEX "$INDEX" \
                                                                                                                                --rawfile SCRIPT "$SCRIPT_FILE" \
                                                                                                                                --argjson SEED "$SEED" \
                                                                                                                                --rawfile STANDARD_ERROR "$STANDARD_ERROR_FILE" \
                                                                                                                                --rawfile STANDARD_OUTPUT "$STANDARD_OUTPUT_FILE" \
                                                                                                                                --argjson STATUS "$STATUS" \
                                                                                                                                --argjson TARGETS_EXPECTED "$TARGETS_EXPECTED" \
                                                                                                                                --argjson TARGETS_OBSERVED "$TARGETS_OBSERVED" \
                                                                                                                                --argjson TRANSIENT "$TRANSIENT_JSON" \
                                                                                                                                '{
                                                                                                                                    "arguments" : $ARGUMENTS ,
                                                                                                                                    "index" : $INDEX ,
                                                                                                                                    "script" : $SCRIPT ,
                                                                                                                                    "seed" : $SEED ,
                                                                                                                                    "standard-error" : $STANDARD_ERROR ,
                                                                                                                                    "standard-output" : $STANDARD_OUTPUT ,
                                                                                                                                    "status" : $STATUS ,
                                                                                                                                    "targets" : { "expected" : $TARGETS_EXPECTED , "observed" : $TARGETS_OBSERVED } ,
                                                                                                                                    "transient" : $TRANSIENT
                                                                                                                                }' | log ${ invalid-init-channel }
                                                                                                                        fi
                                                                                                                        ${ builtins.concatStringsSep "\n" resolutions }
                                                                                                                        echo "${ resources-directory }/mounts/$INDEX"
                                                                                                                        failure 3247386799252451 "INDEX=$INDEX" "STATUS=$STATUS" "STANDARD_ERROR_FILE=$STANDARD_ERROR_FILE" "TARGETS_EXPECTED=$TARGETS_EXPECTED" "TARGETS_OBSERVED=$TARGETS_OBSERVED"
                                                                                                                    fi
                                                                                                                    echo 1625986342496743 >> /tmp/DEBUG
                                                                                                                '' ;
                                                                                                null =
                                                                                                    path : value :
                                                                                                        ''
                                                                                                            INDEX="$( sequential )" || failure 5607
                                                                                                            export INDEX
                                                                                                            mkdir --parents ${ resources-directory }/marks
                                                                                                            touch "${ resources-directory }/marks/$INDEX"
                                                                                                            mkdir --parents "${ resources-directory }/mounts/$INDEX"
                                                                                                            ARGUMENTS="$( printf '%s\n' "$@" | jq --raw-input . | jq --slurp . )" || failure 14587
                                                                                                            mkdir --parents ${ resources-directory }/release
                                                                                                            trace 28886
                                                                                                            RELEASE_FILE="${ resources-directory }/release/$INDEX"
                                                                                                            trace 32610 "$RELEASE_FILE"
                                                                                                            if [[ -e "$RELEASE_FILE" ]]
                                                                                                            then
                                                                                                                failure 15975
                                                                                                            fi
                                                                                                            trace 17843
                                                                                                            sed -e "s#\$_HASH#$HASH#" -e "s#\$_INDEX#$INDEX#" "s#\$HASH#$HASH#" -e "s#\$INDEX#$INDEX#" -e "w$RELEASE_FILE" ${ destroy }/bin/destroy > /dev/null 2>&1
                                                                                                            trace 28617
                                                                                                            echo "# 3421794956336178" >> "$RELEASE_FILE"
                                                                                                            chmod 0500 "$RELEASE_FILE"
                                                                                                            SEED='${ builtins.toJSON seed }'
                                                                                                            JSON_SEQUENCE="$( sequential )" || failure 32761
                                                                                                            JSON_FILE="${ resources-directory }/logs/$JSON_SEQUENCE"
                                                                                                            jq \
                                                                                                                --compact-output \
                                                                                                                --null-input \
                                                                                                                --argjson ARGUMENTS "$ARGUMENTS" \
                                                                                                                --argjson HAS_STANDARD_INPUT "$HAS_STANDARD_INPUT" \
                                                                                                                --arg INDEX "$INDEX" \
                                                                                                                --arg RELEASE_FILE "$RELEASE_FILE" \
                                                                                                                --arg SEED "$SEED" \
                                                                                                                --arg STANDARD_INPUT_FILE "$STANDARD_INPUT_FILE" \
                                                                                                                --argjson STATUS "$STATUS" \
                                                                                                                --argjson TRANSIENT "$TRANSIENT" \
                                                                                                                '{
                                                                                                                    "arguments" : $ARGUMENTS ,
                                                                                                                    "has-standard-input" : $HAS_STANDARD_INPUT ,
                                                                                                                    "index" : $INDEX ,
                                                                                                                    "seed" : $SEED ,
                                                                                                                    "standard-input-file" : $STANDARD_INPUT_FILE ,
                                                                                                                    "transient" : $TRANSIENT
                                                                                                                }' > "$JSON_FILE"
                                                                                                            chmod 0400 "$JSON_FILE"
                                                                                                            ln --symbolic "${ resources-directory }/mounts/$INDEX" "/canonical/$HASH"
                                                                                                            redis-cli PUBLISH ${ valid-init-channel } "$JSON_FILE" > /dev/null 2>&1 || true
                                                                                                            echo "${ resources-directory }/mounts/$INDEX"
                                                                                                        '' ;
                                                                                            }
                                                                                            init ;
                                                                                }
                                                                )
                                                            ] ;
                                            } ;
                                        failure =
                                            buildFHSUserEnv
                                                {
                                                    name = "failure" ;
                                                    runScript =
                                                        ''
                                                            bash -c '
                                                                if [[ -t 0 ]]
                                                                then
                                                                    failure "${ builtins.concatStringsSep "" [ "$" "{" "@:-" "}" ] }"
                                                                else
                                                                    failure "${ builtins.concatStringsSep "" [ "$" "{" "@:-" "}" ] }" <&0
                                                                fi
                                                            ' "$0" "$@"
                                                        '' ;
                                                    targetPkgs =
                                                        pkgs :
                                                            [
                                                                (
                                                                    pkgs.writeShellApplication
                                                                        {
                                                                            name = "failure" ;
                                                                            runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.yq-go ] ;
                                                                            text =
                                                                                ''
                                                                                    ARGUMENTS="$( printf '%s\n' "$@" | jq --raw-input . | jq --slurp . )" || exit 74
                                                                                    if [[ -t 0 ]]
                                                                                    then
                                                                                        # shellcheck disable=SC2016
                                                                                        jq \
                                                                                            --null-input \
                                                                                            --argjson ARGUMENTS "$ARGUMENTS" \
                                                                                            '{ "arguments" : $ARGUMENTS }' >&2
                                                                                    else
                                                                                        STANDARD_INPUT="$( cat )" || exit 65
                                                                                        # shellcheck disable=SC2016
                                                                                        jq \
                                                                                            --null-input \
                                                                                            --argjson ARGUMENTS "$ARGUMENTS" \
                                                                                            --arg STANDARD_INPUT "$STANDARD_INPUT" \
                                                                                            '{ "arguments" : $ARGUMENTS , "standard-input" : $STANDARD_INPUT }' >&2
                                                                                    fi
                                                                                    exit 66
                                                                                '' ;
                                                                        }
                                                                )
                                                            ] ;
                                                } ;
                                        gc-root =
                                            buildFHSUserEnv
                                                {
                                                    name = "gc-root" ;
                                                    runScript =
                                                        ''
                                                            bash -c '
                                                                if [[ -t 0 ]]
                                                                then
                                                                    gc-root "${ builtins.concatStringsSep "" [ "$" "{" "@:-" "}" ] }"
                                                                else
                                                                    gc-root "${ builtins.concatStringsSep "" [ "$" "{" "@:-" "}" ] }" <&0
                                                                fi
                                                            ' "$0" "$@"
                                                        '' ;
                                                    targetPkgs =
                                                        pkgs :
                                                            [
                                                                (
                                                                    pkgs.writeShellApplication
                                                                        {
                                                                            name = "gc-root" ;
                                                                            runtimeInputs = [ pkgs.coreutils sequential trace ] ;
                                                                            text =
                                                                                ''
                                                                                    TARGET="$1"
                                                                                    DIRECTORY="$( dirname "$TARGET" )" || failure 30095
                                                                                    SEQUENCE="$( sequential )" || failure 18737
                                                                                    ln --symbolic "$TARGET" "${ gc-root-directory }/$INDEX/$SEQUENCE$DIRECTORY"
                                                                                    echo Rooted "TARGET=$TARGET" at "DESTINATION=${ gc-root-directory }/$INDEX/$SEQUENCE$DIRECTORY"
                                                                                '' ;
                                                                        }
                                                                )
                                                            ] ;
                                                } ;
                                        log =
                                            buildFHSUserEnv
                                                {
                                                    name = "log" ;
                                                    runScript =
                                                        ''
                                                            bash -c '
                                                                if [[ -t 0 ]]
                                                                then
                                                                    log "${ builtins.concatStringsSep "" [ "$" "{" "@:-" "}" ] }"
                                                                else
                                                                    log "${ builtins.concatStringsSep "" [ "$" "{" "@:-" "}" ] }" <&0
                                                                fi
                                                            ' "$0" "$@"
                                                        '' ;
                                                    targetPkgs =
                                                        pkgs :
                                                            [
                                                                (
                                                                    pkgs.writeShellApplication
                                                                        {
                                                                            name = "log" ;
                                                                            runtimeInputs = [ failure pkgs.jq pkgs.redis sequential ] ;
                                                                            text =
                                                                                ''
                                                                                    CHANNEL="$1"
                                                                                    JSON="$( jq --compact-output "." )" || failure 7456186835451742
                                                                                    STANDARD_OUTPUT_SEQUENCE="$( sequential )" || failure 7956485765567239
                                                                                    STANDARD_ERROR_SEQUENCE="$( sequential )" || failure 9116318311428797
                                                                                    redis-cli PUBLISH "$CHANNEL" "$JSON" > "${ resources-directory }/logs/$STANDARD_OUTPUT_SEQUENCE" 2> "${ resources-directory }/logs/$STANDARD_ERROR_SEQUENCE" || true
                                                                                '' ;
                                                                        }
                                                                )
                                                            ] ;
                                                } ;
                                        pid =
                                            buildFHSUserEnv
                                                {
                                                    name = "pid" ;
                                                    runScript =
                                                        ''
                                                            bash -c '
                                                                if [[ -t 0 ]]
                                                                then
                                                                    pid "${ builtins.concatStringsSep "" [ "$" "{" "@:-" "}" ] }"
                                                                else
                                                                    pid "${ builtins.concatStringsSep "" [ "$" "{" "@:-" "}" ] }" <&0
                                                                fi
                                                            ' "$0" "$@"
                                                        '' ;
                                                    targetPkgs =
                                                        pkgs :
                                                            [
                                                                (
                                                                    pkgs.writeShellApplication
                                                                        {
                                                                            name = "pid" ;
                                                                            runtimeInputs = [ coreutils failure procps ] ;
                                                                            text =
                                                                                ''
                                                                                    CHILD="$1"
                                                                                    DEPTH="$2"
                                                                                    INDEX="$3"
                                                                                    mkdir --parents "${ resources-directory }/pids/$INDEX"
                                                                                    touch "${ resources-directory }/pids/$INDEX/$CHILD"
                                                                                    chmod 0400 "${ resources-directory }/pids/$INDEX/$CHILD"
                                                                                    if [[ "$DEPTH" -gt "0" ]] && [[ "$CHILD" -gt "1" ]]
                                                                                    then
                                                                                        PARENT="$( ps -o ppid= -p "$CHILD" | tr -d '[:space:]' )" || failure 7862
                                                                                        NEXT=$(( DEPTH - 1 ))
                                                                                        "$0" "$PARENT" "$NEXT" "$INDEX"
                                                                                    fi
                                                                                '' ;
                                                                        }
                                                                    )
                                                                ] ;
                                                } ;
                                        script-file =
                                            script : arguments :
                                                let
                                                    application =
                                                        buildFHSUserEnv
                                                            {
                                                                name = "script" ;
                                                                runScript = "script" ;
                                                                targetPkgs =
                                                                    pkgs :
                                                                        [
                                                                            (
                                                                                pkgs.writeShellApplication
                                                                                    {
                                                                                        name = "script" ;
                                                                                        runtimeInputs = [ failure pkgs.coreutils sequential ] ;
                                                                                        text =
                                                                                            let
                                                                                                application =
                                                                                                    let
                                                                                                        application =
                                                                                                            pkgs.writeShellApplication
                                                                                                                {
                                                                                                                    name = "application" ;
                                                                                                                    text = script arguments ;
                                                                                                                } ;
                                                                                                            in "${ application }/bin/application" ;
                                                                                                in
                                                                                                    ''
                                                                                                        SEQUENCE="$( sequential )" || failure 18903
                                                                                                        FILE="${ resources-directory }/logs/$SEQUENCE"
                                                                                                        ln --symbolic ${ application } "$FILE"
                                                                                                        echo "$FILE"
                                                                                                    '' ;
                                                                                    }
                                                                            )
                                                                        ] ;
                                                            } ;
                                                    in "${ application }/bin/script" ;
                                        scripts-hash =
                                            buildFHSUserEnv
                                                {
                                                    name = "scripts-hash" ;
                                                    runScript = "scripts-hash" ;
                                                    targetPkgs =
                                                        pkgs :
                                                            [
                                                                (
                                                                    pkgs.writeShellApplication
                                                                        {
                                                                            name = "scripts-hash" ;
                                                                            text =
                                                                                let
                                                                                    scripts-hash =
                                                                                        visitor
                                                                                            {
                                                                                                lambda =
                                                                                                    path : value :
                                                                                                        pkgs.writeShellApplication
                                                                                                            {
                                                                                                                name = "script" ;
                                                                                                                runtimeInputs = [ pkgs.coreutils ] ;
                                                                                                                text =
                                                                                                                    let
                                                                                                                        a =
                                                                                                                            if builtins.typeOf path == "list" && builtins.length path == 1 && builtins.typeOf ( builtins.elemAt path 0 ) == "string" && builtins.elemAt path 0 == "init" then arguments.init pkgs
                                                                                                                            else if builtins.typeOf path == "list" && builtins.length path == 1 && builtins.typeOf ( builtins.elemAt path 0 ) == "string" && builtins.elemAt path 0 == "release" then arguments.release pkgs
                                                                                                                            else arguments.resolve pkgs path ( builtins.elemAt path 1 == "init-resolutions" ) ;
                                                                                                                        in builtins.hashString "sha512" ( builtins.concatStringsSep "" ( builtins.concatLists [ path [ ( builtins.toString ( value a ) ) ] ] ) ) ;
                                                                                                            } ;
                                                                                                list = path : list : builtins.hashString "sha512" ( builtins.toJSON [ path list ] ) ;
                                                                                                null = path : value : builtins.hashString "sha512" ( builtins.concatStringsSep "" path ) ;
                                                                                                set = path : set : builtins.hashString "sha512" ( builtins.toJSON [ path set ] ) ;
                                                                                            }
                                                                                            {
                                                                                                init = init ;
                                                                                                init-resolutions = init-resolutions ;
                                                                                                release = release ;
                                                                                                release-resolutions = release-resolutions ;
                                                                                            } ;
                                                                                    in
                                                                                        ''
                                                                                            echo ${ scripts-hash }
                                                                                        '' ;
                                                                        }
                                                                )
                                                            ] ;
                                                } ;
                                        sequential =
                                            buildFHSUserEnv
                                                {
                                                    name = "sequential" ;
                                                    runScript = "sequential" ;
                                                    targetPkgs =
                                                        pkgs :
                                                            [
                                                                (
                                                                    pkgs.writeShellApplication
                                                                        {
                                                                            name = "sequential" ;
                                                                            runtimeInputs = [ failure pkgs.coreutils pkgs.flock ] ;
                                                                            text =
                                                                                ''
                                                                                    mkdir --parents ${ resources-directory }/sequential
                                                                                    mkdir --parents ${ resources-directory }/locks
                                                                                    exec 203> ${ resources-directory }/locks/sequential
                                                                                    flock -x 203
                                                                                    if [[ -s ${ resources-directory }/sequential/sequential.counter ]]
                                                                                    then
                                                                                        CURRENT="$( cat ${ resources-directory }/sequential/sequential.counter )" || failure 5766
                                                                                    else
                                                                                        CURRENT=0
                                                                                    fi
                                                                                    NEXT=$(( ( CURRENT + 1 ) % 10000000000000000 ))
                                                                                    echo "$NEXT" > ${ resources-directory }/sequential/sequential.counter
                                                                                    printf "%016d\n" "$CURRENT"
                                                                                    rm ${ resources-directory }/locks/sequential
                                                                                '' ;
                                                                        }
                                                                )
                                                            ] ;
                                                text =
                                                    ''
                                                        if [[ -s /sequential/sequential.counter ]]
                                                        then
                                                            CURRENT="$( cat /sequential/sequential.counter )" || failure 5766
                                                        else
                                                            CURRENT=0
                                                        fi
                                                        NEXT=$(( ( CURRENT + 1 ) % 10000000000000000 ))
                                                        echo "$NEXT" > /sequential/sequential.counter
                                                        printf "%016d\n" "$CURRENT"
                                                    '' ;
                                            } ;
                                        trace =
                                            buildFHSUserEnv
                                                {
                                                    name = "trace" ;
                                                    runScript =
                                                        ''
                                                            bash -c '
                                                                trace "${ builtins.concatStringsSep "" [ "$" "{" "@:-" "}" ] }" <&0
                                                            ' "$0" "$@"
                                                        '' ;
                                                    targetPkgs =
                                                        pkgs :
                                                            [
                                                                (
                                                                    pkgs.writeShellApplication
                                                                        {
                                                                            name = "trace" ;
                                                                            runtimeInputs = [ pkgs.jq pkgs.yq-go ] ;
                                                                            text =
                                                                                ''
                                                                                    ARGUMENTS="$( printf '%s\n' "$@" | jq --raw-input . | jq --slurp . )" || failure 22397
                                                                                    # shellcheck disable=SC2016
                                                                                    jq \
                                                                                        --compact-output \
                                                                                        --null-input \
                                                                                        --argjson ARGUMENTS "$ARGUMENTS" \
                                                                                        '$ARGUMENTS' | yq eval --prettyPrint "[.]" \
                                                                                        >> ${ resources-directory }/logs/trace.log.yaml
                                                                                '' ;
                                                                        }
                                                                )
                                                            ] ;
                                                } ;
                                        wrap =
                                            buildFHSUserEnv
                                                {
                                                    name = "wrap" ;
                                                    runScript =
                                                        ''
                                                            bash -c '
                                                                if [[ -t 0 ]]
                                                                then
                                                                    wrap "${ builtins.concatStringsSep "" [ "$" "{" "@:-" "}" ] }"
                                                                else
                                                                    wrap "${ builtins.concatStringsSep "" [ "$" "{" "@:-" "}" ] }" <&0
                                                                fi
                                                            ' "$0" "$@"
                                                        '' ;
                                                    targetPkgs =
                                                        pkgs :
                                                            [
                                                                (
                                                                    pkgs.writeShellApplication
                                                                        {
                                                                            name = "wrap" ;
                                                                            runtimeInputs = [ failure pkgs.coreutils pkgs.gnugrep pkgs.gnused ] ;
                                                                            text =
                                                                                ''
                                                                                    if [[ 3 -gt "$#" ]]
                                                                                    then
                                                                                        failure 4721 "We were expecting input output permissions but we observed $# arguments:" "$*"
                                                                                    fi
                                                                                    INPUT="$1"
                                                                                    if [[ ! -f "$INPUT" ]]
                                                                                    then
                                                                                        failure 14159 "We were expecting the first argument $INPUT to be a file but we observed $*"
                                                                                    fi
                                                                                    UUID=""
                                                                                    shift
                                                                                    OUTPUT="$1"
                                                                                    if [[ -e "/mount/$OUTPUT" ]]
                                                                                    then
                                                                                        failure 3790 "We were expecting the second argument $OUTPUT to not (yet) exist but we observed $*"
                                                                                    fi
                                                                                    OUTPUT_DIRECTORY="$( dirname "/mount/$OUTPUT" )" || failure 20962
                                                                                    mkdir --parents "$OUTPUT_DIRECTORY"
                                                                                    shift
                                                                                    PERMISSIONS="$1"
                                                                                    if [[ ! $PERMISSIONS =~ ^-?[0-9]+$ ]]
                                                                                    then
                                                                                        failure 18129 "We were expecting the third argument to be an integer but we observed $*"
                                                                                    fi
                                                                                    ALLOWED_PLACEHOLDERS=()
                                                                                    COMMANDS=()
                                                                                    shift
                                                                                    while [[ "$#" -gt 0 ]]
                                                                                    do
                                                                                        case "$1" in
                                                                                            --inherit)
                                                                                                if [[ "$#" -lt 3 ]]
                                                                                                then
                                                                                                    failure 22854 "We were expecting --inherit STYLE VARIABLE but we observed $*"
                                                                                                fi
                                                                                                STYLE="$2"
                                                                                                VARIABLE="$3"
                                                                                                if [[ -z "${ builtins.concatStringsSep "" [ "$" "{" "!VARIABLE+x" "}" ] }" ]]
                                                                                                then
                                                                                                    failure 26274 "The environment variable '$VARIABLE' is not set, but it is required for --inherit." "$*"
                                                                                                fi
                                                                                                VALUE="${ builtins.concatStringsSep "" [ "$" "{" "!VARIABLE" "}" ] }"
                                                                                                if [[ "$STYLE" == "brace" ]]
                                                                                                then
                                                                                                    BRACED="${ builtins.concatStringsSep "" [ "\\" "$" "{" "$VARIABLE" "}" ] }"
                                                                                                elif [[ "$STYLE" == "plain" ]]
                                                                                                then
                                                                                                    BRACED="\$$VARIABLE"
                                                                                                else
                                                                                                    failure 32719 "We were expecting brace or plain but we got $STYLE" "$*"
                                                                                                fi
                                                                                                if [[ -z "${ builtins.concatStringsSep "" [ "$" "{" "VARIABLE+x" "}" ] }" ]]
                                                                                                then
                                                                                                    failure 11096 "We were expecting $VARIABLE to be in the environment but it is not" "$*"
                                                                                                fi
                                                                                                if ! grep --fixed-string "$BRACED" "$INPUT"
                                                                                                then
                                                                                                    failure 28342 "We were expecting inherit $BRACED to be in the input file $INPUT but it was not" "$*"
                                                                                                fi
                                                                                                ALLOWED_PLACEHOLDERS+=( "$BRACED" )
                                                                                                COMMANDS+=( -e "s#$BRACED#$VALUE#g" )
                                                                                                shift 3
                                                                                                ;;
                                                                                            --literal)
                                                                                                if [[ "$#" -lt 3 ]]
                                                                                                then
                                                                                                    failure 11868 "We were expecting --literal STYLE VARIABLE but we observed $*"
                                                                                                fi
                                                                                                STYLE="$2"
                                                                                                VARIABLE="$3"
                                                                                                if [[ "$STYLE" == "brace" ]]
                                                                                                then
                                                                                                    BRACED="${ builtins.concatStringsSep "" [ "\\" "$" "{" "$VARIABLE" "}" ] }"
                                                                                                elif [[ "$STYLE" == "plain" ]]
                                                                                                then
                                                                                                    BRACED="\$$VARIABLE"
                                                                                                else
                                                                                                    failure 21548 "We were expecting brace or plain but we got $STYLE" "$*"
                                                                                                fi
                                                                                                if ! grep --fixed-string "$BRACED" "$INPUT"
                                                                                                then
                                                                                                    failure 9160 "We were expecting literal $BRACED to be in the input file $INPUT but it was not" "$*"
                                                                                                fi
                                                                                                ALLOWED_PLACEHOLDERS+=( "$BRACED" )
                                                                                                # With sed we do not need to do anything for literal-brace
                                                                                                shift 3
                                                                                                ;;
                                                                                            --set)
                                                                                                if [[ "$#" -lt 4 ]]
                                                                                                then
                                                                                                    failure 25685 "We were expecting --set STYLE VARIABLE VALUE but we observed $*"
                                                                                                fi
                                                                                                STYLE="$2"
                                                                                                VARIABLE="$3"
                                                                                                VALUE="$4"
                                                                                                if [[ "$STYLE" == "brace" ]]
                                                                                                then
                                                                                                    BRACED="${ builtins.concatStringsSep "" [ "\\" "$" "{" "$VARIABLE" "}" ] }"
                                                                                                elif [[ "$STYLE" == "plain" ]]
                                                                                                then
                                                                                                    BRACED="\$$VARIABLE"
                                                                                                else
                                                                                                    failure 5029 "We were expecting brace or plain but we got $STYLE" "$*"
                                                                                                fi
                                                                                                if ! grep -F --quiet "$BRACED" "$INPUT"
                                                                                                then
                                                                                                    failure 19050 "We were expecting set $BRACED to be in the input file but it was not" "$*"
                                                                                                fi
                                                                                                ALLOWED_PLACEHOLDERS+=( "$BRACED" )
                                                                                                COMMANDS+=( -e "s#$BRACED#$VALUE#g" )
                                                                                                shift 4
                                                                                                ;;
                                                                                            --uuid)
                                                                                                UUID="$2"
                                                                                                shift 2
                                                                                                ;;
                                                                                            *)
                                                                                                failure 15883 "We were expecting --inherit, --literal, --set, or --uuid but we observed $*"
                                                                                        esac
                                                                                    done
                                                                                    mapfile -t FOUND_PLACEHOLDERS < <(
                                                                                        grep --only-matching --extended-regexp '\$\{[A-Za-z_][A-Za-z0-9_]*\}|\$[A-Za-z_][A-Za-z0-9_]*' "$INPUT" | sort --unique
                                                                                    )
                                                                                    UNRESOLVED=()
                                                                                    for PLACE_HOLDER in "${ builtins.concatStringsSep "" [ "$" "{" "FOUND_PLACEHOLDERS[@]" "}" ] }"
                                                                                    do
                                                                                        FOUND=false
                                                                                        for ALLOWED in "${ builtins.concatStringsSep "" [ "$" "{" "ALLOWED_PLACEHOLDERS[@]" "}" ] }"
                                                                                        do
                                                                                            if [[ "$PLACE_HOLDER" == "$ALLOWED" ]]
                                                                                            then
                                                                                                FOUND=true
                                                                                                break
                                                                                            fi
                                                                                        done
                                                                                        if ! $FOUND
                                                                                        then
                                                                                            UNRESOLVED+=( "$PLACE_HOLDER" )
                                                                                        fi
                                                                                    done
                                                                                    if [[ "${ builtins.concatStringsSep "" [ "$" "{" "#UNRESOLVED[@]" "}" ] }" -ne 0 ]]
                                                                                    then
                                                                                        failure 31558 "Unresolved placeholders in input file: ${ builtins.concatStringsSep "" [ "$" "{" "UNRESOLVED[*]" "}" ] }" "INPUT=$INPUT" "OUTPUT=$OUTPUT" "ALLOWED_PLACEHOLDERS=${ builtins.concatStringsSep "" [ "$" "{" "ALLOWED_PLACEHOLDERS[*]" "}" ] }" "UUID=$UUID"
                                                                                    fi
                                                                                    sed "${ builtins.concatStringsSep "" [ "$" "{" "COMMANDS[@]" "}" ] }" -e "w/mount/$OUTPUT" "$INPUT"
                                                                                    chmod "$PERMISSIONS" "/mount/$OUTPUT"
                                                                                '' ;
                                                                        }
                                                                )
                                                            ] ;
                                                } ;
                                        in
                                            let
                                                application =
                                                    writeShellApplication
                                                        {
                                                            name = "setup" ;
                                                            runtimeInputs = [ coreutils create failure flock jq pid procps scripts-hash sequential trace ] ;
                                                            text =
                                                                let
                                                                    stringable =
                                                                        let
                                                                            breaker =
                                                                                let
                                                                                    mapper =
                                                                                        name : value :
                                                                                            if name == "resources" then
                                                                                                {
                                                                                                    resources = true ;
                                                                                                    value = null ;
                                                                                                }
                                                                                            else
                                                                                                {
                                                                                                    resources = false ;
                                                                                                    value = value ;
                                                                                                } ;
                                                                                    in builtins.mapAttrs mapper primary ;
                                                                            stringable =
                                                                                path : value :
                                                                                    let
                                                                                        resources = if value == resources then true else false ;
                                                                                        type = builtins.typeOf value ;
                                                                                        in
                                                                                            {
                                                                                                path = path ;
                                                                                                type = type ;
                                                                                                value = if type == "lambda" then null else value ;
                                                                                            } ;
                                                                        in
                                                                            visitor
                                                                                {
                                                                                    bool = stringable ;
                                                                                    int = stringable ;
                                                                                    float = stringable ;
                                                                                    lambda = path : value : { path = path ; type = "lambda" ; value = null ; } ;
                                                                                    null = stringable ;
                                                                                    path = stringable ;
                                                                                    string = stringable ;
                                                                                }
                                                                                [ breaker secondary ] ;
                                                                    transient_ =
                                                                        visitor
                                                                            {
                                                                                bool =
                                                                                    path : value :
                                                                                        if value then "$( sequential ) || failure 13613"
                                                                                        else "-1" ;
                                                                            }
                                                                            transient ;
                                                                    in
                                                                        ''
                                                                            STANDARD_INPUT_SEQUENCE="$( sequential )" || failure 27125
                                                                            mkdir --parents "${ resources-directory }/logs"
                                                                            STANDARD_INPUT_FILE="${ resources-directory }/logs/$STANDARD_INPUT_SEQUENCE"
                                                                            # KLUDGE.
                                                                            # WE NOTICED THAT THE STANDARD INPUT CODE SOMETIMES MAL FUNCTIONED
                                                                            # AND WE WERE NOT USING STANDARD INPUT
                                                                            # SO THE EASIEST THING TO DO IS DISABLE IT
                                                                            HAS_STANDARD_INPUT=false
                                                                            touch "$STANDARD_INPUT_FILE"
                                                                            chmod 0400 "$STANDARD_INPUT_FILE"
                                                                            ULTIMATE_PID="$( ps -o ppid= -p "$PPID" | tr -d '[:space:]' )" || failure 22859
#                                                                           if [[ -t 0 ]]
#                                                                           then
#                                                                                HAS_STANDARD_INPUT=false
#                                                                                touch "$STANDARD_INPUT_FILE"
#                                                                                chmod 0400 "$STANDARD_INPUT_FILE"
#                                                                                ULTIMATE_PID="$( ps -o ppid= -p "$PPID" | tr -d '[:space:]' )" || failure 28567
#                                                                            else
#                                                                                STANDARD_INPUT_FILE="$( mktemp )" || failure 29248
#                                                                                export STANDARD_INPUT_FILE
#                                                                                HAS_STANDARD_INPUT=true
#                                                                                cat > "$STANDARD_INPUT_FILE"
#                                                                                chmod 0400 "$STANDARD_INPUT_FILE"
#                                                                                PENULTIMATE_PID="$( ps -o ppid= -p "$PPID" | tr -d '[:space:]' )" || failure 27339
#                                                                                ULTIMATE_PID="$( ps -o ppid= -p "$PENULTIMATE_PID" | tr -d '[:space:]' )" || failure 17331
#                                                                            fi
                                                                            if [[ "$#" -eq 0 ]]
                                                                            then
                                                                                ARGUMENTS='[]'
                                                                            else
                                                                                ARGUMENTS="$( jq --null-input '$ARGS.positional' --args "$@" )" || failure 9695442699954655
                                                                            fi
                                                                            PRE_HASH='${ builtins.hashString "sha512" ( builtins.toJSON stringable ) }'
                                                                            SCRIPTS_HASH="$( scripts-hash )" || failure 15672
                                                                            STANDARD_INPUT_HASH="$( sha512sum "$STANDARD_INPUT_FILE" | cut --characters -128 )" || failure 12800
                                                                            # shellcheck disable=SC2089
                                                                            TARGETS_EXPECTED='${ builtins.toJSON ( builtins.sort ( a : b : a < b ) targets ) }'
                                                                            TRANSIENT=${ transient_ }
                                                                            export TRANSIENT
                                                                            HASH="$( echo "$ARGUMENTS" "$HAS_STANDARD_INPUT" "$PRE_HASH" "$SCRIPTS_HASH" "$STANDARD_INPUT_HASH" "$TRANSIENT" | sha512sum | cut --characters 1-128 )" || failure 21086
                                                                            mkdir --parents "${ resources-directory }/locks"
                                                                            exec 203> "${ resources-directory }/locks/$HASH"
                                                                            flock -x 203
                                                                            if [[ -L "${ resources-directory }/canonical/$HASH" ]]
                                                                            then
                                                                                LINK="$( readlink --canonicalize "${ resources-directory }/canonical/$HASH" )" || failure 6882155195748272
                                                                                INDEX="$( basename "$LINK" )" || failure 5382672217914679
                                                                                exec 204> "${ resources-directory }/locks/$INDEX"
                                                                                flock -s 204
                                                                                mkdir --parents ${ resources-directory }/marks
                                                                                touch "${ resources-directory }/marks/$INDEX"
                                                                                mkdir --parents "${ resources-directory }/pids/$INDEX"
                                                                                pid "$ULTIMATE_PID" ${ builtins.toString depth } "$INDEX"
                                                                                echo "${ resources-directory }/mounts/$INDEX"
                                                                            else
                                                                                export HAS_STANDARD_INPUT
                                                                                export HASH
                                                                                export SCRIPTS_HASH
                                                                                export STANDARD_INPUT_FILE
                                                                                # shellcheck disable=SC2090
                                                                                export TARGETS_EXPECTED
                                                                                export ULTIMATE_PID
                                                                                SIGNAL_SEQUENCE="$( sequential )" || failure 28752
                                                                                export SIGNAL="${ resources-directory }/logs/$SIGNAL_SEQUENCE"
                                                                                mkdir --parents "$SIGNAL"
                                                                                create "$@"
                                                                                STATUS="$( cat "$SIGNAL/signal" )" || failure 13801
                                                                                exit "$STATUS"
                                                                            fi
                                                                        '' ;
                                                        } ;
                                                in "${ application }/bin/setup" ;
                            in
                                {
                                    check =
                                        {
                                            depth ? 0 ,
                                            expected ? "" ,
                                            init ? null ,
                                            init-resolutions ? null ,
                                            mkDerivation ,
                                            release ? null ,
                                            release-resolutions ? null ,
                                            resources ? null ,
                                            seed ? 17507 ,
                                            setup ? setup : setup ,
                                            targets ? [ ] ,
                                            transient ? false ,
                                        } :
                                            mkDerivation
                                                {
                                                    installPhase = "check" ;
                                                    name = "check" ;
                                                    nativeBuildInputs =
                                                        [
                                                            (
                                                                writeShellApplication
                                                                    {
                                                                        name = "check" ;
                                                                        runtimeInputs = [ coreutils ] ;
                                                                        text =
                                                                            let
                                                                                observed =
                                                                                    implementation
                                                                                        {
                                                                                            depth = depth ;
                                                                                            init = init ;
                                                                                            init-resolutions = init-resolutions ;
                                                                                            release = release ;
                                                                                            release-resolutions = release-resolutions ;
                                                                                            seed = seed ;
                                                                                            targets = targets ;
                                                                                            transient = transient ;
                                                                                        } ;
                                                                                in
                                                                                    if expected == observed then
                                                                                        ''
                                                                                            : "${ builtins.concatStringsSep "" [ "$" "{" "out:?must be exported" "}" ] }"
                                                                                            touch "$out"
                                                                                        ''
                                                                                    else
                                                                                        ''
                                                                                            : "${ builtins.concatStringsSep "" [ "$" "{" "out:?must be exported" "}" ] }"
                                                                                            echo "We were expecting" >&2
                                                                                            echo >&2
                                                                                            echo '${ expected }' >&2
                                                                                            echo "but we observed " >&2
                                                                                            echo >&2
                                                                                            echo '${ observed }' > "$out"
                                                                                            cat "$out" >&2
                                                                                            exit 64
                                                                                        '' ;
                                                                    }
                                                            )
                                                        ] ;
                                                    src = ./. ;
                                                } ;
                                    implementation = implementation ;
                                } ;
            } ;
}
