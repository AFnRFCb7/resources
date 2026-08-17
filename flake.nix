#  5426754136875314
{
	inputs = { } ;
	outputs =
		{ self } :
		    {
		        lib =
		            {
		                buildFHSUserEnv ,
		                coreutils ,
		                findutils ,
		                flock ,
		                gnused ,
		                invalid-init-channel ,
		                invalid-release-channel ,
		                jq ,
		                log-channel ,
		                mkDerivation ,
		                redis ,
		                valid-init-channel ,
		                valid-release-channel ,
		                visitor ,
		                writeShellApplication
                    } :
                        let
                            implementation =
                                {
                                    gc-roots-directory ,
                                    resources-directory
                                } :
                                    let
                                        log =
                                            writeShellApplication
                                                {
                                                    name = "log" ;
                                                    runtimeInputs = [ coreutils jq redis ] ;
                                                    text =
                                                        ''
                                                            : "${ builtins.concatStringsSep "" [ "$" "{" "CHANNEL:?must be exported" "}" ] }"
                                                            JSON="$( jq --compact-output "." )" || exit 108
                                                            redis-cli PUBLISH "$CHANNEL" "$JSON" >> /tmp/DEBUG 2>&1
                                                        '' ;
                                                } ;
                                                    log2 =
                                                        writeShellApplication
                                                            {
                                                                name = "log" ;
                                                                runtimeInputs =
                                                                    [
                                                                        coreutils
                                                                        (
                                                                            buildFHSUserEnv
                                                                                {
                                                                                    extraBwrapArgs =
                                                                                        [
                                                                                            "--ro-bind" "$INPUT" "/input"
                                                                                            "--tmpfs" "/private"
                                                                                            "--bind" "$OUTPUT" "/output"
                                                                                        ] ;
                                                                                    name = "log" ;
                                                                                    runScript = "log" ;
                                                                                    targetPkgs =
                                                                                        pkgs :
                                                                                            [
                                                                                                (
                                                                                                    pkgs.writeShellApplication
                                                                                                        {
                                                                                                            name = "log" ;
                                                                                                            runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.redis ] ;
                                                                                                            text =
                                                                                                                ''
                                                                                                                    : "${ builtins.concatStringsSep "" [ "$" "{" "CHANNEL:?must be exported" "}" ] }"
                                                                                                                    : "${ builtins.concatStringsSep "" [ "$" "{" "CHANNEL:?must be exported" "}" ] }"
                                                                                                                    JSON="$( jq --compact-output "." /input )" || exit 129
                                                                                                                    if redis-cli PUBLISH "$CHANNEL" "$JSON" > /private/standard-output 2> /private/standard-error
                                                                                                                    then
                                                                                                                        jq \
                                                                                                                            --null-input \
                                                                                                                            --arg STATUS "$?" \
                                                                                                                            --rawfile STANDARD_OUTPUT /private/standard-output \
                                                                                                                            --rawfile STANDARD_ERROR /private/standard-error \
                                                                                                                            '{
                                                                                                                                "status" : $STATUS ,
                                                                                                                                "standard-error" : $STANDARD_ERROR ,
                                                                                                                                "standard-output" : $STANDARD_OUTPUT
                                                                                                                            }' > /output
                                                                                                                    else
                                                                                                                        jq \
                                                                                                                            --null-input \
                                                                                                                            --arg STATUS "$?" \
                                                                                                                            --rawfile STANDARD_OUTPUT /private/standard-output \
                                                                                                                            --rawfile STANDARD_ERROR /private/standard-error \
                                                                                                                            '{
                                                                                                                                "status" : $STATUS ,
                                                                                                                                "standard-error" : $STANDARD_ERROR ,
                                                                                                                                "standard-output" : $STANDARD_OUTPUT
                                                                                                                            }' > /output
                                                                                                                    fi
                                                                                                                '' ;
                                                                                                        }
                                                                                                )
                                                                                            ] ;
                                                                                }
                                                                        )
                                                                    ] ;
                                                                text =
                                                                    ''
                                                                        mkdir --parents ${ resources-directory }
                                                                        exec 135> ${ resources-directory }/clean.lock
                                                                        flock -s 135
                                                                        mkdir --parents ${ resources-directory }/temporary
                                                                        INPUT="$( mktemp --suffix ".json" ${ resources-directory }/temporary/XXXXXXXX )" || exit 173
                                                                        export INPUT
                                                                        jq --compact-output "." > "$INPUT"
                                                                        OUTPUT="$( mktemp --suffix ".json" ${ resources-directory }/temporary/XXXXXXXX )" || exit 176
                                                                        export OUTPUT
                                                                        mkdir --parents ${ resources-directory }
                                                                        exec 143> ${ resources-directory }/log.lock
                                                                        flock -x 143
                                                                        mkdir --parents ${ resources-directory }/log.yaml
                                                                        log
                                                                        STATUS="$( jq --raw-output ".status" "$OUTPUT" )" || exit 123
                                                                        exit "$STATUS"
                                                                    '' ;
                                                            } ;
                                        in
                                    {
                                        clean =
                                            let
                                                application =
                                                    writeShellApplication
                                                        {
                                                            name = "clean" ;
                                                            runtimeInputs =
                                                                [
                                                                    (
                                                                        buildFHSUserEnv
                                                                            {
                                                                                extraBwrapArgs =
                                                                                    [
                                                                                        "--bind" gc-roots-directory "/gc-roots"
                                                                                        "--bind" resources-directory "/resources"
                                                                                        "--tmpfs" "/private"
                                                                                        "--bind" "$TEMPORARY" "/temporary"
                                                                                    ] ;
                                                                                name = "clean" ;
                                                                                runScript = "clean" ;
                                                                                targetPkgs =
                                                                                    pkgs :
                                                                                        [
                                                                                            (
                                                                                                pkgs.writeShellApplication
                                                                                                    {
                                                                                                        name = "clean" ;
                                                                                                        runtimeInputs = [ pkgs.findutils pkgs.gnutar pkgs.jq pkgs.xz log ] ;
                                                                                                        text =
                                                                                                            ''
                                                                                                                cleanup ( ) {
                                                                                                                    echo "$?" > /temporary/status
                                                                                                                }
                                                                                                                trap cleanup EXIT
                                                                                                                mkdir --parents /resources/release
                                                                                                                find /resources/release -mindepth 1 -maxdepth 1 -type f -exec {} \;
                                                                                                                mkdir --parents /resources/release
                                                                                                                mkdir --parents /resources/invalid-init
                                                                                                                mkdir --parents /resources/invalid-release
                                                                                                                if find /resources/release /resources/invalid-init /resources/invalid-release -mindepth 1 -type f | grep --quiet "."
                                                                                                                then
                                                                                                                    find /resources/release /resources/invalid-init /resources/invalid-release -mindepth 1 -type f >&2
                                                                                                                    exit 164
                                                                                                                fi
                                                                                                                tar --create --xz --file /temporary/archive.tar.gz /gc-roots /resources 2> /private/tar
                                                                                                                rm --recursive --force /gc-locks/* /resources/*
                                                                                                            '' ;
                                                                                                    }
                                                                                            )
                                                                                        ] ;
                                                                            }
                                                                    )
                                                                ] ;
                                                            text =
                                                                ''
                                                                    mkdir --parents ${ resources-directory }
                                                                    exec 198> ${ resources-directory }/check.lock
                                                                    flock -s 198
                                                                    exec 131> ${ resources-directory }/clean.lock
                                                                    flock -x 131
                                                                    mkdir --parents ${ gc-roots-directory }
                                                                    TEMPORARY="$( mktemp --directory )" || exit 113
                                                                    export TEMPORARY
                                                                    clean
                                                                    STATUS="$( cat "$TEMPORARY/status" )" || exit 158
                                                                    exit "$STATUS"
                                                                '' ;
                                                        } ;
                                                in "${ application }/bin/clean" ;
                                        log =
                                            let
                                                application =
                                                    writeShellApplication
                                                        {
                                                            name = "log" ;
                                                            runtimeInputs =
                                                                [
                                                                    (
                                                                        buildFHSUserEnv
                                                                            {
                                                                                extraBwrapArgs = [ "--bind" "${ resources-directory }/log.yaml" "/log" ] ;
                                                                                name = "log" ;
                                                                                runScript = "log" ;
                                                                                targetPkgs =
                                                                                    pkgs :
                                                                                        [
                                                                                            (
                                                                                                pkgs.writeShellApplication
                                                                                                    {
                                                                                                        name = "log" ;
                                                                                                        runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.redis pkgs.yq-go ] ;
                                                                                                        text =
                                                                                                            ''
                                                                                                                exec 170< <( redis-cli SUBSCRIBE ${ root-parameters.invalid-init-channel } ${ root-parameters.invalid-release-channel } ${ root-parameters.valid-init-channel } ${ root-parameters.valid-release-channel } )
                                                                                                                while true
                                                                                                                do
                                                                                                                    TIMESTAMP="$( date +%s)" || exit 164
                                                                                                                    read -r -u 170 TYPE || break
                                                                                                                    read -r -u 170 CHANNEL || break
                                                                                                                    read -r -u 170 PAYLOAD || break
                                                                                                                    if [[ "$TYPE" == "message" ]]
                                                                                                                    then
                                                                                                                        jq \
                                                                                                                            --null-input \
                                                                                                                            --arg CHANNEL "$CHANNEL" \
                                                                                                                            --argjson PAYLOAD "$PAYLOAD" \
                                                                                                                            --argjson TIMESTAMP "$TIMESTAMP" \
                                                                                                                            --arg TYPE "$TYPE" \
                                                                                                                            '{
                                                                                                                                "channel" : $CHANNEL ,
                                                                                                                                "payload" : $PAYLOAD ,
                                                                                                                                "timestamp" : $TIMESTAMP ,
                                                                                                                                "type" : $TYPE
                                                                                                                            }' | yq eval --prettyPrint '[.]' >> /log
                                                                                                                    fi
                                                                                                                done
                                                                                                            '' ;
                                                                                                    }
                                                                                            )
                                                                                        ] ;
                                                                            }
                                                                    )
                                                                ] ;
                                                            text =
                                                                ''
                                                                    mkdir --parents ${ resources-directory }
                                                                    touch ${ resources-directory }/log.yaml
                                                                    log
                                                                '' ;
                                                        } ;
                                                in "${ application }/bin/log" ;
                                        release =
                                            let
                                                application =
                                                    writeShellApplication
                                                        {
                                                            name = "release" ;
                                                            runtimeInputs =
                                                                [
                                                                    coreutils
                                                                    findutils
                                                                    jq
                                                                    redis
                                                                ] ;
                                                            text =
                                                                ''
                                                                    stdbuf -oL redis-cli --raw SUBSCRIBE ${ root-parameters.valid-init-channel } | while true
                                                                    do
                                                                        read -r TYPE || { echo "TYPE _EOF" >&2 ; break; }
                                                                        read -r CHANNEL || { echo "CHANNEL _EOF" >&2 ; break; }
                                                                        read -r PAYLOAD || { echo "PAYLOAD _EOF" >&2 ; break; }
                                                                        if [[ "$TYPE" == "message" ]] && [[ "${ root-parameters.valid-init-channel }" == "$CHANNEL" ]]
                                                                        then
                                                                            INDEX="$( jq --raw-output ".index" <<< "$PAYLOAD" )" || break
                                                                            echo ABOUT TO RELEASE "$INDEX"
                                                                            nohup "${ resources-directory }/release/$INDEX" > "/tmp/$INDEX.out" &
                                                                        fi
                                                                    done
                                                                '' ;
                                                        } ;
                                                    in "${ application }/bin/release" ;
                                        resource =
                                            {
                                                error ,
                                                init ,
                                                release ,
                                                resources ,
                                                seed ,
                                                targets ,
                                                temporary
                                            } :
                                                let
                                                    resource =
                                                        writeShellApplication
                                                            {
                                                                name = "resource" ;
                                                                runtimeInputs = [ coreutils findutils flock gnused jq log resource-parameters.init.action.script ] ;
                                                                text =
                                                                    ''
                                                                        mkdir --parents ${ resources-directory }
                                                                        exec 168> ${ resources-directory }/check.lock
                                                                        flock -s 168
                                                                        mkdir --parents ${ gc-roots-directory }
                                                                        exec 157> ${ resources-directory }/clean.lock
                                                                        flock -s 157
                                                                        INPUT_FILE="$( mktemp --suffix ".json" )" || exit 199
                                                                        export INPUT_FILE
                                                                        export TEMPORARY=${ builtins.toJSON resource-parameters.temporary }
                                                                        if [[ "$IS_NIX_FLAKE_CHECK" == "true" ]]
                                                                        then
                                                                            if [[ -t 0 ]]
                                                                            # if [[ -p /dev/stdin || -f /dev/stdin ]]
                                                                            then
                                                                                STANDARD_INPUT="$( cat )" || exit 103
                                                                                ORIGINATOR_PID="$( ps -o ppid= -p "$PPID" | tr -d '[:space:]' )" || exit 184
                                                                                jq \
                                                                                    --null-input \
                                                                                    --argjson ORIGINATOR_PID "$ORIGINATOR_PID" \
                                                                                    --arg STANDARD_INPUT "$STANDARD_INPUT" \
                                                                                    --argjson TEMPORARY "$TEMPORARY" \
                                                                                    --args \
                                                                                    '{
                                                                                        "WTF" : "2128979479613286" ,
                                                                                        "arguments" : $ARGS.positional ,
                                                                                        "inputs" :
                                                                                            {
                                                                                                "standard" : $STANDARD_INPUT
                                                                                            } ,
                                                                                        "originator-pid" : $ORIGINATOR_PID ,
                                                                                        "temporary" : $TEMPORARY
                                                                                    }' -- "$@" > "$INPUT_FILE"
                                                                            else
                                                                                # if true ; then exit 0 ; fi
                                                                                # ORIGINATOR_PID="$( ps -o ppid= -p "$$" | tr -d '[:space:]' )" || exit 187
                                                                                PENULTIMATE_PID="$( ps -o ppid= -p "$PPID" | tr -d '[:space:]' )" || exit 192
                                                                                ULTIMATE_PID="$( ps -o ppid= -p "$PENULTIMATE_PID" | tr -d '[:space:]' )" || exit 125
                                                                                ORIGINATOR_PID="$( ps -o ppid= -p "$ULTIMATE_PID" | tr -d '[:space:]' )" || exit 125
                                                                                # ORIGINATOR_PID="$( ps -o ppid= -p "$$" | tr -d '[:space:]' )" || exit 173
                                                                                # if true ; then exit 0 ; fi
                                                                                # if true ; then exit 0 ; fi
                                                                                jq \
                                                                                    --null-input \
                                                                                    --argjson ORIGINATOR_PID "$ORIGINATOR_PID" \
                                                                                    --argjson TEMPORARY "$TEMPORARY" \
                                                                                    --args \
                                                                                    '{
                                                                                        "arguments" : $ARGS.positional ,
                                                                                        "inputs" : { } ,
                                                                                        "originator-pid" : $ORIGINATOR_PID ,
                                                                                        "temporary" : $TEMPORARY
                                                                                    }' -- "$@" > "$INPUT_FILE"
                                                                                # if true ; then exit 0 ; fi
                                                                            fi
                                                                        else
                                                                            # if [[ -t 0 ]]
                                                                            if [[ -p /dev/stdin || -f /dev/stdin ]]
                                                                            then
                                                                                STANDARD_INPUT="$( cat )" || exit 103
                                                                                ORIGINATOR_PID="$( ps -o ppid= -p "$PPID" | tr -d '[:space:]' )" || exit 184
                                                                                jq \
                                                                                    --null-input \
                                                                                    --argjson ORIGINATOR_PID "$ORIGINATOR_PID" \
                                                                                    --arg STANDARD_INPUT "$STANDARD_INPUT" \
                                                                                    --argjson TEMPORARY "$TEMPORARY" \
                                                                                    --args \
                                                                                    '{
                                                                                        "WTF" : "2128979479613286" ,
                                                                                        "arguments" : $ARGS.positional ,
                                                                                        "inputs" :
                                                                                            {
                                                                                                "standard" : $STANDARD_INPUT
                                                                                            } ,
                                                                                        "originator-pid" : $ORIGINATOR_PID ,
                                                                                        "temporary" : $TEMPORARY
                                                                                    }' -- "$@" > "$INPUT_FILE"
                                                                            else
                                                                                ORIGINATOR_PID="$( ps -o ppid= -p "$$" | tr -d '[:space:]' )" || exit 112
                                                                                # PENULTIMATE_PID="$( ps -o ppid= -p "$PPID" | tr -d '[:space:]' )" || exit 192
                                                                                # ULTIMATE_PID="$( ps -o ppid= -p "$PENULTIMATE_PID" | tr -d '[:space:]' )" || exit 125
                                                                                # ORIGINATOR_PID="$( ps -o ppid= -p "$ULTIMATE_PID" | tr -d '[:space:]' )" || exit 125
                                                                                jq \
                                                                                    --null-input \
                                                                                    --argjson ORIGINATOR_PID "$ORIGINATOR_PID" \
                                                                                    --argjson TEMPORARY "$TEMPORARY" \
                                                                                    --args \
                                                                                    '{
                                                                                        "WTF" : "5482197652155478" ,
                                                                                        "arguments" : $ARGS.positional ,
                                                                                        "inputs" : { } ,
                                                                                        "originator-pid" : $ORIGINATOR_PID ,
                                                                                        "temporary" : $TEMPORARY
                                                                                    }' -- "$@" > "$INPUT_FILE"
                                                                            fi
                                                                        fi
                                                                        HASH_FILE="$( mktemp --suffix ".json" )" || exit 178
                                                                        jq 'del(.["originator-pid"]) + { "pre-hash" : "${ builtins.hashString "sha512" ( builtins.toJSON resource-parameters.seed ) }" }' "$INPUT_FILE" > "$HASH_FILE"
                                                                        HASH="$( sha512sum "$HASH_FILE" | cut --characters 1-128 )" || exit 172
                                                                        if [[ -L "${ resources-directory }/canonical/$HASH" ]]
                                                                        then
                                                                            FILE="$( readlink --canonicalize "${ resources-directory }/canonical/$HASH" )" || echo 182
                                                                            INDEX="$( basename "$FILE" )" || exit 130
                                                                            echo "$ORIGINATOR_PID" > "${ resources-directory }/pids/$INDEX/$ORIGINATOR_PID"
                                                                            echo "$FILE"
                                                                        else
                                                                            mkdir --parents ${ resources-directory }/canonical
                                                                            OUTPUT_FILE="$( mktemp --suffix ".json" )" || exit 101
                                                                            export OUTPUT_FILE
                                                                            mkdir --parents ${ gc-roots-directory }
                                                                            mkdir --parents ${ resources-directory }
                                                                            init
                                                                            CHANNEL="$( jq --raw-output ".channel" "$OUTPUT_FILE" )" || exit 181
                                                                            export CHANNEL
                                                                            INDEX="$( jq --raw-output ".index" "$OUTPUT_FILE" )" || exit 198
                                                                            EVALUATION="$( jq --raw-output ".evaluation" "$OUTPUT_FILE" )" || exit 176
                                                                            STANDARD_ERROR="$( jq --raw-output '.["standard-error"]' "$OUTPUT_FILE" )" || exit 146
                                                                            STATUS="$( jq --raw-output ".status" "$OUTPUT_FILE" )" || exit 173
                                                                            echo -en "${ resources-directory }/mounts/$INDEX"
                                                                            if [[ 0 == "$STATUS" ]] && [[ -z "$STANDARD_ERROR" ]]
                                                                            then
                                                                                ln --symbolic "${ resources-directory }/mounts/$INDEX" "${ resources-directory }/canonical/$HASH"
                                                                                mkdir --parents ${ resources-directory }/release
                                                                                ln --symbolic ${ resource-parameters.release.action.script } "${ resources-directory }/release/$INDEX"
                                                                                jq \
                                                                                    '{
                                                                                        "arguments" : .arguments ,
                                                                                        "index" : .index ,
                                                                                        "inputs" : .inputs ,
                                                                                        "originator-pid" : .["originator-pid"] ,
                                                                                        "seed" : .seed ,
                                                                                        "standard-output" : .["standard-output"] ,
                                                                                        "targets" : .targets ,
                                                                                        "text" : .text ,
                                                                                        "temporary" : .temporary
                                                                                    }' "$OUTPUT_FILE" | log
                                                                                if [[ -n "$EXPERIMENTAL" ]] ; then true ; fi
                                                                            elif [[ 0 != "$STATUS" ]] && [[ -z "$STANDARD_ERROR" ]]
                                                                            then
                                                                                jq \
                                                                                    '{
                                                                                        "WTF" : "6586389267536849" ,
                                                                                        "arguments" : .arguments ,
                                                                                        "index" : .index ,
                                                                                        "inputs" : .inputs ,
                                                                                        "originator-pid" : .["originator-pid"] ,
                                                                                        "seed" : .seed ,
                                                                                        "standard-output" : .["standard-output"] ,
                                                                                        "status" : .status ,
                                                                                        "targets" : .targets ,
                                                                                        "text" : .text ,
                                                                                        "temporary" : .temporary
                                                                                    }' "$OUTPUT_FILE" | log
                                                                            elif [[ 0 == "$STATUS" ]] && [[ -n "$STANDARD_ERROR" ]]
                                                                            then
                                                                                if true ; then exit 193 ; fi
                                                                                jq \
                                                                                    '{
                                                                                        "WTF" : "2437324934873537" ,
                                                                                        "arguments" : .arguments ,
                                                                                        "index" : .index ,
                                                                                        "inputs" : .inputs ,
                                                                                        "originator-pid" : .["originator-pid"] ,
                                                                                        "seed" : .seed ,
                                                                                        "standard-error" : .["standard-error"] ,
                                                                                        "standard-output" : .["standard-error"] ,
                                                                                        "status" : ./status ,
                                                                                        "targets" : .targets ,
                                                                                        "text" : .text ,
                                                                                        "temporary" : .temporary
                                                                                    }' "$OUTPUT_FILE" | log
                                                                            elif [[ 0 != "$STATUS" ]] && [[ -n "$STANDARD_ERROR" ]]
                                                                            then
                                                                                if true ; then exit 194 ; fi
                                                                                jq \
                                                                                    '{
                                                                                        "WTF" : "9976979456295116" ,
                                                                                        "arguments" : .arguments ,
                                                                                        "index" : .index ,
                                                                                        "inputs" : .inputs ,
                                                                                        "originator-pid" : .["originator-pid"] ,
                                                                                        "seed" : .seed ,
                                                                                        "standard-error" : .["standard-error"] ,
                                                                                        "standard-output" : .["standard-output"] ,
                                                                                        "status" : .status ,
                                                                                        "targets" : .targets ,
                                                                                        "text" : .text ,
                                                                                        "temporary" : .temporary
                                                                                    }' "$OUTPUT_FILE" | log
                                                                            fi
                                                                            # if [[ "$EXPERIMENTAL" == true ]] ; then exit 190 ; fi
                                                                            rm "$INPUT_FILE" "$OUTPUT_FILE"
                                                                            exit "$EVALUATION"
                                                                        fi
                                                                    '' ;
                                                            } ;
                                                        resource-parameters =
                                                            {
                                                                error =
                                                                    visitor
                                                                        {
                                                                            int = path : value : builtins.toString value ;
                                                                        }
                                                                        error ;
                                                                init =
                                                                    {
                                                                        action =
                                                                            let
                                                                                action = visitor { lambda = path : value : value null ; } resource-parameters.init.init.action ;
                                                                                in
                                                                                    {
                                                                                        script =
                                                                                            writeShellApplication
                                                                                                {
                                                                                                    name = "init" ;
                                                                                                    runtimeInputs =
                                                                                                        [
                                                                                                            coreutils
                                                                                                            sequential
                                                                                                            (
                                                                                                                buildFHSUserEnv
                                                                                                                    {
                                                                                                                        extraBwrapArgs =
                                                                                                                            [
                                                                                                                                "--ro-bind" "$INPUT_FILE" "/input"
                                                                                                                                "--bind" "${ gc-roots-directory }/$INDEX" "/gc-root"
                                                                                                                                "--bind" "${ resources-directory }/mounts/$INDEX" "/mount"
                                                                                                                                "--bind" "${ resources-directory }/pids/$INDEX" "/pid"
                                                                                                                                "--bind" "${ resources-directory }/release" "/release"
                                                                                                                                "--bind" "$OUTPUT_FILE" "/output"
                                                                                                                                "--tmpfs" "/private"
                                                                                                                                "--tmpfs" "/tmp/scratch"
                                                                                                                            ] ;
                                                                                                                        name = "init" ;
                                                                                                                        runScript = "init" ;
                                                                                                                        targetPkgs =
                                                                                                                            pkgs :
                                                                                                                                [
                                                                                                                                    (
                                                                                                                                        pkgs.writeShellApplication
                                                                                                                                            {
                                                                                                                                                name = "init" ;
                                                                                                                                                runtimeInputs =
                                                                                                                                                    [
                                                                                                                                                        pkgs.jq
                                                                                                                                                        (
                                                                                                                                                            pkgs.writeShellApplication
                                                                                                                                                                {
                                                                                                                                                                    name = "init" ;
                                                                                                                                                                    runtimeInputs = resource-parameters.init.action.targetPkgs { gc-roots-directory = gc-roots-directory ; pkgs =pkgs ; resources = resources ; };
                                                                                                                                                                    text = resource-parameters.init.action.text ;
                                                                                                                                                                }
                                                                                                                                                        )
                                                                                                                                                    ] ;
                                                                                                                                                text =
                                                                                                                                                    ''
                                                                                                                                                        jq --raw-output '.arguments[]' /input > /private/jq
                                                                                                                                                        mapfile -t ARGUMENTS < <( jq -r '.arguments[]' /input )
                                                                                                                                                        cd /mount
                                                                                                                                                        if jq -e '.inputs | has("standard")' /input > /private/jq
                                                                                                                                                        then
                                                                                                                                                            if jq '.inputs.standard' /input | init "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" > /private/standard-output 2> /private/standard-error
                                                                                                                                                            then
                                                                                                                                                                STATUS="$?"
                                                                                                                                                            else
                                                                                                                                                                STATUS="$?"
                                                                                                                                                            fi
                                                                                                                                                        else
                                                                                                                                                            if init "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" > /private/standard-output 2> /private/standard-error
                                                                                                                                                            then
                                                                                                                                                                STATUS="$?"
                                                                                                                                                            else
                                                                                                                                                                STATUS="$?"
                                                                                                                                                            fi
                                                                                                                                                        fi
                                                                                                                                                        EXPECTED_TARGETS="$( jq --null-input '${ builtins.toJSON resource-parameters.targets }' )" || exit 136
                                                                                                                                                        OBSERVED_TARGETS="$( find /mount -mindepth 1 -maxdepth 1 -exec basename {} \; | LC_ALL=C sort | jq -R "." | jq -s "." )" || exit 111
                                                                                                                                                        ORIGINATOR_PID="$( jq --raw-output '.["originator-pid"]' /input )" || exit 156
                                                                                                                                                        if [[ 0 == "$STATUS" ]] && [[ ! -s /private/standard-error ]] && [[ "$EXPECTED_TARGETS" == "$OBSERVED_TARGETS" ]]
                                                                                                                                                        then
                                                                                                                                                            echo "$ORIGINATOR_PID" > "/pid/$ORIGINATOR_PID"
                                                                                                                                                            jq \
                                                                                                                                                                --arg CHANNEL ${ resource-parameters.init.valid-channel } \
                                                                                                                                                                --argjson EVALUATION 0 \
                                                                                                                                                                --argjson EXPECTED_TARGETS "$EXPECTED_TARGETS" \
                                                                                                                                                                --arg INDEX "$INDEX" \
                                                                                                                                                                --argjson SEED '${ builtins.toJSON resource-parameters.seed }' \
                                                                                                                                                                --rawfile STANDARD_ERROR /private/standard-error \
                                                                                                                                                                --rawfile STANDARD_OUTPUT /private/standard-output \
                                                                                                                                                                --argjson STATUS "$STATUS" \
                                                                                                                                                                --rawfile TEXT ${ builtins.toFile "file" resource-parameters.init.action.text } \
                                                                                                                                                                --argjson TEMPORARY '${ builtins.toJSON resource-parameters.temporary }' \
                                                                                                                                                                '{
                                                                                                                                                                    "WTF" : .WTF ,
                                                                                                                                                                    "WTF2" : "5541229353485882" ,
                                                                                                                                                                    "arguments" : .arguments ,
                                                                                                                                                                    "channel" : $CHANNEL ,
                                                                                                                                                                    "evaluation" : $EVALUATION ,
                                                                                                                                                                    "index" : $INDEX ,
                                                                                                                                                                    "inputs" : .inputs ,
                                                                                                                                                                    "originator-pid" : .["originator-pid"] ,
                                                                                                                                                                    "seed" : $SEED ,
                                                                                                                                                                    "standard-error" : $STANDARD_ERROR ,
                                                                                                                                                                    "standard-output" : $STANDARD_OUTPUT ,
                                                                                                                                                                    "status" : $STATUS ,
                                                                                                                                                                    "targets" : $EXPECTED_TARGETS ,
                                                                                                                                                                    "text" : $TEXT ,
                                                                                                                                                                    "temporary" : .temporary
                                                                                                                                                                }' "$INPUT_FILE" > "$OUTPUT_FILE"
                                                                                                                                                        else
                                                                                                                                                            jq \
                                                                                                                                                                --arg INDEX "$INDEX" \
                                                                                                                                                                --arg CHANNEL ${ resource-parameters.init.invalid-channel } \
                                                                                                                                                                --argjson EVALUATION ${ resource-parameters.error } \
                                                                                                                                                                --argjson EXPECTED_TARGETS "$EXPECTED_TARGETS" \
                                                                                                                                                                --argjson OBSERVED_TARGETS "$OBSERVED_TARGETS" \
                                                                                                                                                                --argjson SEED '${ builtins.toJSON resource-parameters.seed }' \
                                                                                                                                                                --rawfile STANDARD_ERROR /private/standard-error \
                                                                                                                                                                --rawfile STANDARD_OUTPUT /private/standard-output \
                                                                                                                                                                --argjson STATUS "$STATUS" \
                                                                                                                                                                --rawfile TEXT ${ builtins.toFile "file" resource-parameters.init.action.text } \
                                                                                                                                                                '{
                                                                                                                                                                    "arguments" : .arguments ,
                                                                                                                                                                    "channel" : $CHANNEL ,
                                                                                                                                                                    "evaluation" : $EVALUATION ,
                                                                                                                                                                    "index" : $INDEX ,
                                                                                                                                                                    "inputs" : .inputs ,
                                                                                                                                                                    "seed" : $SEED ,
                                                                                                                                                                    "standard-error" : $STANDARD_ERROR ,
                                                                                                                                                                    "standard-output" : $STANDARD_OUTPUT ,
                                                                                                                                                                    "status" : $STATUS ,
                                                                                                                                                                    "targets" :
                                                                                                                                                                        {
                                                                                                                                                                            "expected" : $EXPECTED_TARGETS ,
                                                                                                                                                                            "observed" : $OBSERVED_TARGETS
                                                                                                                                                                        } ,
                                                                                                                                                                    "text" : $TEXT
                                                                                                                                                                }' "$INPUT_FILE" > "$OUTPUT_FILE"
                                                                                                                                                        fi
                                                                                                                                                    '' ;
                                                                                                                                            }
                                                                                                                                    )
                                                                                                                                ] ;
                                                                                                                    }
                                                                                                            )
                                                                                                        ] ;
                                                                                                    text =
                                                                                                        ''
                                                                                                            : "${ builtins.concatStringsSep "" [ "$" "{" "INPUT_FILE:?must be exported" "}" ] }"
                                                                                                            : "${ builtins.concatStringsSep "" [ "$" "{" "OUTPUT_FILE:?must be exported" "}" ] }"
                                                                                                            SEQUENCE="$( sequential )" || exit 137
                                                                                                            printf -v INDEX "%016d" "$SEQUENCE"
                                                                                                            export INDEX
                                                                                                            mkdir --parents "${ gc-roots-directory }/$INDEX"
                                                                                                            mkdir --parents ${ resources-directory }/flags
                                                                                                            touch "${ resources-directory }/flags/$INDEX"
                                                                                                            mkdir --parents "${ resources-directory }/mounts/$INDEX"
                                                                                                            mkdir --parents "${ resources-directory }/pids/$INDEX"
                                                                                                            mkdir --parents ${ resources-directory }/release
                                                                                                            init
                                                                                                        '' ;
                                                                                                } ;
                                                                                        text = visitor { string = path : value : value ; } action.text ;
                                                                                        targetPkgs = visitor { lambda = path : value : value ; } action.targetPkgs ;
                                                                                    } ;
                                                                        init = visitor { lambda = path : value : value null ; } init ;
                                                                        invalid-channel = root-parameters.invalid-init-channel ;
                                                                        recovery = null ;
                                                                        valid-channel = root-parameters.valid-init-channel ;
                                                                    } ;
                                                                release =
                                                                    {
                                                                        action =
                                                                            let
                                                                                action = visitor { lambda = path : value : value null ; } resource-parameters.release.release.action ;
                                                                                in
                                                                                    {
                                                                                        script =
                                                                                            let
                                                                                                application =
                                                                                                    writeShellApplication
                                                                                                        {
                                                                                                            name = "release" ;
                                                                                                            runtimeInputs =
                                                                                                                [
                                                                                                                    coreutils
                                                                                                                    flock
                                                                                                                    log
                                                                                                                    (
                                                                                                                        buildFHSUserEnv
                                                                                                                            {
                                                                                                                                extraBwrapArgs =
                                                                                                                                    [
                                                                                                                                        "--ro-bind" "$INPUT_FILE" "/input"
                                                                                                                                        "--ro-bind" gc-roots-directory "/gc-roots"
                                                                                                                                        "--bind" "${ resources-directory }/mounts/$INDEX" "/mount"
                                                                                                                                        "--bind" "$OUTPUT_FILE" "/output"
                                                                                                                                        "--tmpfs" "/private"
                                                                                                                                    ] ;
                                                                                                                                name = "is-releasable" ;
                                                                                                                                runScript = "is-releasable" ;
                                                                                                                                targetPkgs =
                                                                                                                                    pkgs :
                                                                                                                                        [
                                                                                                                                            (
                                                                                                                                                pkgs.writeShellApplication
                                                                                                                                                    {
                                                                                                                                                        name = "is-releasable" ;
                                                                                                                                                        runtimeInputs =
                                                                                                                                                            [
                                                                                                                                                                pkgs.findutils
                                                                                                                                                                pkgs.inotify-tools
                                                                                                                                                                pkgs.jq
                                                                                                                                                                (
                                                                                                                                                                    pkgs.writeShellApplication
                                                                                                                                                                        {
                                                                                                                                                                            name = "release" ;
                                                                                                                                                                            runtimeInputs = resource-parameters.release.action.targetPkgs pkgs ;
                                                                                                                                                                            text = resource-parameters.release.action.text ;
                                                                                                                                                                        }
                                                                                                                                                                )
                                                                                                                                                            ] ;
                                                                                                                                                        text =
                                                                                                                                                            ''
                                                                                                                                                                cd /mount
                                                                                                                                                                INDEX="$( jq --raw-output ".index" /input )" || exit 176
                                                                                                                                                                if release "$INDEX" > /private/standard-output 2> /private/standard-error
                                                                                                                                                                then
                                                                                                                                                                    STATUS="$?"
                                                                                                                                                                else
                                                                                                                                                                    STATUS="$?"
                                                                                                                                                                fi
                                                                                                                                                                jq \
                                                                                                                                                                    --rawfile STANDARD_ERROR /private/standard-error \
                                                                                                                                                                    --rawfile STANDARD_OUTPUT /private/standard-output \
                                                                                                                                                                    --arg STATUS "$STATUS" \
                                                                                                                                                                    '{
                                                                                                                                                                        "index" : .index ,
                                                                                                                                                                        "standard-error" : $STANDARD_ERROR ,
                                                                                                                                                                        "standard-output" : $STANDARD_OUTPUT ,
                                                                                                                                                                        "status" : $STATUS
                                                                                                                                                                    }' /input > /output
                                                                                                                                                            '' ;
                                                                                                                                                    }
                                                                                                                                            )
                                                                                                                                        ] ;
                                                                                                                            }
                                                                                                                    )
                                                                                                                    (
                                                                                                                        buildFHSUserEnv
                                                                                                                            {
                                                                                                                                extraBwrapArgs =
                                                                                                                                    [
                                                                                                                                        "--ro-bind" "$OUTPUT_FILE" "/input"
                                                                                                                                        "--bind" gc-roots-directory "/gc-roots"
                                                                                                                                        "--bind" resources-directory "/resources"
                                                                                                                                        "--bind" "$TEMPORARY" "/temporary"
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
                                                                                                                                                        runtimeInputs = [ pkgs.findutils pkgs.gnutar pkgs.jq pkgs.xz log ] ;
                                                                                                                                                        text =
                                                                                                                                                            ''
                                                                                                                                                                INDEX="$( jq --raw-output ".index" /input )" || exit 109
                                                                                                                                                                rm --recursive --force "/gc-roots/$INDEX"
                                                                                                                                                                find /resources -mindepth 2 -maxdepth 2 -name "$INDEX" -print0 | tar --null --files-from - --create --file /temporary/resources.tar.xz
                                                                                                                                                                find /resources -mindepth 2 -maxdepth 2 -name "$INDEX" -print0 -exec rm --recursive --force {} \;
                                                                                                                                                                CHANNEL="$( jq --raw-output ".channel" /input )" || exit 134
                                                                                                                                                                export CHANNEL
                                                                                                                                                                STANDARD_ERROR="$( jq --raw-output '.["standard-error"]' /input )" || exit 192
                                                                                                                                                                STATUS="$( jq --raw-output ".status" /input )" || exit 112
                                                                                                                                                                if [[ "$STATUS" == 0 ]] && [[ -z "$STANDARD_ERROR" ]]
                                                                                                                                                                then
                                                                                                                                                                    export CHANNEL=${ resource-parameters.release.valid-channel }
                                                                                                                                                                    jq \
                                                                                                                                                                        '{
                                                                                                                                                                            "index" : .index ,
                                                                                                                                                                            "standard-output" : .["standard-output"] ,
                                                                                                                                                                            "status" : .status
                                                                                                                                                                        }' /input | log
                                                                                                                                                                elif [[ "$STATUS" != 0 ]] && [[ -z "$STANDARD_ERROR" ]]
                                                                                                                                                                then
                                                                                                                                                                    mkdir --parents ${ resources-directory }/invalid-release
                                                                                                                                                                    export CHANNEL=${ resource-parameters.release.invalid-channel }
                                                                                                                                                                    jq \
                                                                                                                                                                        '{
                                                                                                                                                                            "index" : .index ,
                                                                                                                                                                            "standard-output" : .["standard-output"] ,
                                                                                                                                                                            "status" : .status
                                                                                                                                                                        }' /input | log
                                                                                                                                                                    exit ${ resource-parameters.error }
                                                                                                                                                                elif [[ "$STATUS" == 0 ]] && [[ -n "$STANDARD_ERROR" ]]
                                                                                                                                                                then
                                                                                                                                                                    mkdir --parents ${ resources-directory }/invalid-release
                                                                                                                                                                    export CHANNEL=${ resource-parameters.release.invalid-channel }
                                                                                                                                                                    jq \
                                                                                                                                                                        '{
                                                                                                                                                                            "index" : .index ,
                                                                                                                                                                            "standard-output" : .["standard-output"] ,
                                                                                                                                                                            "standard-error" : .["standard-error"]
                                                                                                                                                                        }' /input | log
                                                                                                                                                                    exit ${ resource-parameters.error }
                                                                                                                                                                elif [[ "$STATUS" != 0 ]] && [[ -n "$STANDARD_ERROR" ]]
                                                                                                                                                                then
                                                                                                                                                                    mkdir --parents ${ resources-directory }/invalid-release
                                                                                                                                                                    export CHANNEL=${ resource-parameters.release.invalid-channel }
                                                                                                                                                                    jq \
                                                                                                                                                                        '{
                                                                                                                                                                            "index" : .index ,
                                                                                                                                                                            "standard-output" : .["standard-output"] ,
                                                                                                                                                                            "standard-error" : .["standard-error"] ,
                                                                                                                                                                            "status" : .status
                                                                                                                                                                        }' /input | log
                                                                                                                                                                    exit ${ resource-parameters.error }
                                                                                                                                                                fi
                                                                                                                                                            '' ;
                                                                                                                                                    }
                                                                                                                                            )
                                                                                                                                        ] ;
                                                                                                                            }
                                                                                                                    )
                                                                                                                ] ;
                                                                                                            text =
                                                                                                                ''
                                                                                                                    # 2863426286352491 use this one
                                                                                                                    INDEX="$( basename "$0" )" || exit 101
                                                                                                                    export INDEX
                                                                                                                    cleanup () {
                                                                                                                        STATUS="$?"
                                                                                                                        exit "$STATUS"
                                                                                                                    }
                                                                                                                    trap cleanup EXIT
                                                                                                                    if [[ -e "${ resources-directory }/mounts/$INDEX" ]]
                                                                                                                    then
                                                                                                                        mkdir --parents ${ resources-directory }
                                                                                                                        exec 182> ${ resources-directory }/clean.lock
                                                                                                                        flock -s 182
                                                                                                                        rm --force "${ resources-directory }/flags/$INDEX"
                                                                                                                        find "${ resources-directory }/pids/$INDEX" -mindepth 1 -maxdepth 1 -type f | sort | while read -r PID_FILE
                                                                                                                        do
                                                                                                                            PID="$( basename "$PID_FILE" )" || exit 169
                                                                                                                            tail --follow /dev/null --pid "$PID"
                                                                                                                            rm --force "$PID_FILE"
                                                                                                                        done
                                                                                                                        mkdir --parents ${ gc-roots-directory }
                                                                                                                        EXPECTED="${ resources-directory }/mounts/$INDEX"
                                                                                                                        find ${ gc-roots-directory } -mindepth 1 -type l | sort | while read -r LINK
                                                                                                                        do
                                                                                                                            if OBSERVED="$( readlink --canonicalize "$LINK" )" && [[ "$EXPECTED" == "$OBSERVED" ]]
                                                                                                                            then
                                                                                                                                while [[ -L "$LINK" ]]
                                                                                                                                do
                                                                                                                                    sleep 1s
                                                                                                                                done
                                                                                                                            fi
                                                                                                                        done
                                                                                                                        export TEMPORARY=${ resources-directory }/temporary
                                                                                                                        mkdir --parents "$TEMPORARY"
                                                                                                                        INPUT_FILE="$( mktemp --suffix ".json" "$TEMPORARY/XXXXXXXX" )" || exit 114
                                                                                                                        export INPUT_FILE
                                                                                                                        jq --null-input --arg INDEX "$INDEX" '{ "index" : $INDEX }' > "$INPUT_FILE"
                                                                                                                        OUTPUT_FILE="$( mktemp --suffix ".json" "$TEMPORARY/XXXXXXXX" )" || exit 153
                                                                                                                        export OUTPUT_FILE
                                                                                                                        is-releasable
                                                                                                                        exec 162> "${ resources-directory }/$INDEX.lock"
                                                                                                                        flock -x 162
                                                                                                                        if [[ -f "${ resources-directory }/flags/$INDEX" ]]
                                                                                                                        then
                                                                                                                            flock -u 162
                                                                                                                            "$0"
                                                                                                                            exit 0
                                                                                                                        else
                                                                                                                            release
                                                                                                                        fi
                                                                                                                    fi
                                                                                                                '' ;
                                                                                                        } ;
                                                                                                in "${ application }/bin/release" ;
                                                                                        text = visitor { string = path : value : value ; } action.text ;
                                                                                        targetPkgs = visitor { lambda = path : value : value ; } action.targetPkgs ;
                                                                                    } ;
                                                                        invalid-channel = root-parameters.invalid-release-channel ;
                                                                        release = visitor { lambda = path : value : value null ; } release ;
                                                                        recovery =
                                                                            visitor
                                                                                {

                                                                                } ;
                                                                        valid-channel = root-parameters.valid-release-channel ;
                                                                    } ;
                                                                seed =
                                                                    visitor
                                                                        {
                                                                            bool = stringify ;
                                                                            float = stringify ;
                                                                            int = stringify ;
                                                                            lambda = stringify ;
                                                                            list = stringify ;
                                                                            null = stringify ;
                                                                            path = stringify ;
                                                                            set = stringify ;
                                                                            string = stringify ;
                                                                        }
                                                                        seed ;
                                                                targets =
                                                                    visitor
                                                                        {
                                                                            list = path : value : builtins.sort builtins.lessThan value ;
                                                                            string = path : value : value ;
                                                                        }
                                                                        targets ;
                                                                temporary = visitor { bool = path : value : value ; } temporary ;
                                                            } ;
                                                    sequential =
                                                        writeShellApplication
                                                            {
                                                                name = "sequential" ;
                                                                runtimeInputs =
                                                                    [
                                                                        coreutils
                                                                        flock
                                                                        (
                                                                            buildFHSUserEnv
                                                                                {
                                                                                    extraBwrapArgs = [ "--bind" "${ resources-directory }/sequential" "/sequential" ] ;
                                                                                    name = "sequential" ;
                                                                                    runScript = "sequential" ;
                                                                                    targetPkgs =
                                                                                        pkgs :
                                                                                            [
                                                                                                (
                                                                                                    pkgs.writeShellApplication
                                                                                                        {
                                                                                                            name = "sequential" ;
                                                                                                            runtimeInputs = [ pkgs.coreutils ] ;
                                                                                                            text =
                                                                                                                ''
                                                                                                                    CURRENT="$( cat /sequential )" || exit 109
                                                                                                                    NEXT=$(( CURRENT + 1 ))
                                                                                                                    echo "$NEXT" > /sequential
                                                                                                                    echo "$CURRENT"
                                                                                                                '' ;
                                                                                                        }
                                                                                                )
                                                                                            ] ;
                                                                                }
                                                                        )
                                                                    ] ;
                                                                text =
                                                                    ''
                                                                        mkdir --parents ${ resources-directory }
                                                                        exec 113> ${ resources-directory }/clean.lock
                                                                        flock -s 113
                                                                        if [[ ! -f ${ resources-directory }/sequential ]]
                                                                        then
                                                                            echo 0 > ${ resources-directory }/sequential
                                                                        fi
                                                                        sequential
                                                                    '' ;
                                                            } ;
                                                    store =
                                                        mkDerivation
                                                            {
                                                                installPhase = ''install "$out"'' ;
                                                                name = "resource" ;
                                                                nativeBuildInputs =
                                                                    [
                                                                        (
                                                                            writeShellApplication
                                                                                {
                                                                                    name = "install" ;
                                                                                    runtimeInputs = [ coreutils ] ;
                                                                                    text =
                                                                                        ''
                                                                                            OUT="$1"
                                                                                            mkdir --parents "$OUT/init"
                                                                                            ln --symbolic ${ resource-parameters.init.action.script } "$OUT/init/action"
                                                                                            mkdir --parents "$OUT/release"
                                                                                            ln --symbolic '${ builtins.toFile "error.json" ( builtins.toJSON resource-parameters.error ) }' "$OUT/error.json"
                                                                                            ln --symbolic '${ builtins.toFile "seed.json" ( builtins.toJSON ( visitor { bool = stringify ; float = stringify ; int = stringify ; lambda = stringify ; list = stringify ; null = stringify ; path = stringify ; set = stringify ; string = stringify ; } resource-parameters seed ) ) }' "$OUT/seed.json"
                                                                                            ln --symbolic '${ builtins.toFile "targets.json" ( builtins.toJSON resource-parameters.targets ) }' "$OUT/targets.json"
                                                                                            ln --symbolic '${ builtins.toFile "temporary.json" ( builtins.toJSON resource-parameters.temporary ) }' "$OUT/temporary.json"
                                                                                        '' ;
                                                                                }
                                                                        )
                                                                    ] ;
                                                                src = ./. ;
                                                            } ;
                                                    in "${ resource }/bin/resource" ;
                                    } ;
                            root-parameters =
                                let
                                    to-string =
                                        visitor
                                            {
                                                string = path : value : value ;
                                            } ;
                                    in
                                        {
                                            coreutils = visitor { string = path : value : value ;} coreutils ;
                                            invalid-init-channel = to-string invalid-init-channel ;
                                            invalid-release-channel = to-string invalid-release-channel ;
                                            mkDerivation = visitor { lambda = path : value : value ; } mkDerivation ;
                                            valid-init-channel = to-string valid-init-channel ;
                                            valid-release-channel = to-string valid-release-channel ;
                                            writeShellApplication = visitor { lambda = path : value : value ; } writeShellApplication ;
                                        } ;
                            stringify =
                                path : value :
                                    let
                                        type = builtins.typeOf value ;
                                        in
                                            {
                                                path = path ;
                                                type = type ;
                                                value = if type == "lambda" then null else value ;
                                            } ;
                            in
                                {
                                    check2 =
                                        {
                                            inputs ,
                                            name ,
                                            nodes ,
                                            gc-roots-directory ,
                                            pkgs ,
                                            resources-directory ,
                                            tests
                                        } :
                                            let
                                                action-derivation =
                                                    pkgs.stdenv.mkDerivation
                                                        {
                                                            installPhase = ''install "$out"'' ;
                                                            name = "check-derivation" ;
                                                            nativeBuildInputs =
                                                                [
                                                                    (
                                                                        writeShellApplication
                                                                            {
                                                                                name = "install" ;
                                                                                runtimeInputs =
                                                                                    [
                                                                                        pkgs.coreutils
                                                                                    ] ;
                                                                                text =
                                                                                    let
                                                                                        commands =
                                                                                            let
                                                                                                mapper =
                                                                                                    {
                                                                                                        command-index ,
                                                                                                        kludge ,
                                                                                                        process ,
                                                                                                        reads ,
                                                                                                        standard-error ,
                                                                                                        standard-output ,
                                                                                                        status ,
                                                                                                        text ,
                                                                                                        timeout
                                                                                                    } :
                                                                                                        let
                                                                                                            file-name = ''"$OUT/commands/${ command-index }"'' ;
                                                                                                            in
                                                                                                                {
                                                                                                                    file-name = file-name ;
                                                                                                                    link =
                                                                                                                        let
                                                                                                                            application =
                                                                                                                                pkgs.writeShellApplication
                                                                                                                                    {
                                                                                                                                        name = "link" ;
                                                                                                                                        runtimeInputs = [ pkgs.coreutils ] ;
                                                                                                                                        text =
                                                                                                                                            ''
                                                                                                                                                OUT="$1"
                                                                                                                                                mkdir --parents "$OUT/commands"
                                                                                                                                                ln --symbolic ${ file } ${ file-name }
                                                                                                                                            '' ;
                                                                                                                                    } ;
                                                                                                                            command =
                                                                                                                                let
                                                                                                                                    application =
                                                                                                                                        pkgs.writeShellApplication
                                                                                                                                            {
                                                                                                                                                name = "command" ;
                                                                                                                                                runtimeInputs =
                                                                                                                                                    [
                                                                                                                                                        (
                                                                                                                                                            pkgs.writeShellApplication
                                                                                                                                                                {
                                                                                                                                                                    name = "check-files" ;
                                                                                                                                                                    runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.findutils pkgs.yq-go ] ;
                                                                                                                                                                    text =
                                                                                                                                                                        ''
                                                                                                                                                                            EXCLUSIONS=( "-path" "${ resources-directory }/pids" "-o" "-path" "${ resources-directory }/temporary" )
                                                                                                                                                                            UUID=()
                                                                                                                                                                            while [[ "$#" -gt 0 ]]
                                                                                                                                                                            do
                                                                                                                                                                                case "$1" in
                                                                                                                                                                                    --exclusion)
                                                                                                                                                                                        EXCLUSIONS+=("-o" "-path" "${ resources-directory }/$2" )
                                                                                                                                                                                        shift 2
                                                                                                                                                                                        ;;
                                                                                                                                                                                    --uuid)
                                                                                                                                                                                        UUID+=( "$2" )
                                                                                                                                                                                        shift 2
                                                                                                                                                                                        ;;
                                                                                                                                                                                    *)
                                                                                                                                                                                        echo "$@"
                                                                                                                                                                                        exit 148
                                                                                                                                                                                        ;;
                                                                                                                                                                                esac
                                                                                                                                                                            done
                                                                                                                                                                            TARGETS=()
                                                                                                                                                                            if [[ -d ${ gc-roots-directory } ]]
                                                                                                                                                                            then
                                                                                                                                                                                TARGETS+=( "${ gc-roots-directory }" )
                                                                                                                                                                            fi
                                                                                                                                                                            if [[ -d ${ resources-directory } ]]
                                                                                                                                                                            then
                                                                                                                                                                                TARGETS=( "${ resources-directory }" )
                                                                                                                                                                            fi
                                                                                                                                                                            find "${ builtins.concatStringsSep "" [ "$" "{" "TARGETS[@]" "}" ] }" \( "${ builtins.concatStringsSep "" [ "$" "{" "EXCLUSIONS[@]" "}" ] }" \) -prune -o -type f -print | sort | while read -r NAME
                                                                                                                                                                            do
                                                                                                                                                                                STAT="$( stat --printf %A "$NAME" )" || exit 122
                                                                                                                                                                                if [[ -d "$NAME" ]]
                                                                                                                                                                                then
                                                                                                                                                                                    jq \
                                                                                                                                                                                        --null-input \
                                                                                                                                                                                        --arg NAME "$NAME" \
                                                                                                                                                                                        --arg STAT "$STAT" \
                                                                                                                                                                                        --arg TYPE "directory" \
                                                                                                                                                                                        '{
                                                                                                                                                                                            "name" : $NAME ,
                                                                                                                                                                                            "stat" : $STAT ,
                                                                                                                                                                                            "type" : $TYPE
                                                                                                                                                                                        }'
                                                                                                                                                                                elif [[ -L "$NAME" ]]
                                                                                                                                                                                then
                                                                                                                                                                                    jq \
                                                                                                                                                                                        --null-input \
                                                                                                                                                                                        --arg NAME "$NAME" \
                                                                                                                                                                                        --arg STAT "$STAT" \
                                                                                                                                                                                        --arg TYPE "symbolic link" \
                                                                                                                                                                                        '{
                                                                                                                                                                                            "name" : $NAME ,
                                                                                                                                                                                            "stat" : $STAT ,
                                                                                                                                                                                            "type" : $TYPE
                                                                                                                                                                                        }'
                                                                                                                                                                                elif [[ -f "$NAME" ]]
                                                                                                                                                                                then
                                                                                                                                                                                    if [[ "$NAME" == "${ resources-directory }/log.yaml" ]]
                                                                                                                                                                                    then
                                                                                                                                                                                        CAT="$( yq eval --prettyPrint 'map(del(.timestamp))' "${ resources-directory }/log.yaml" )" || exit 115
                                                                                                                                                                                    else
                                                                                                                                                                                        CAT="$( cat "$NAME" )" || exit 111
                                                                                                                                                                                    fi
                                                                                                                                                                                    jq \
                                                                                                                                                                                        --null-input \
                                                                                                                                                                                        --arg CAT "$CAT" \
                                                                                                                                                                                        --arg NAME "$NAME" \
                                                                                                                                                                                        --arg STAT "$STAT" \
                                                                                                                                                                                        --arg TYPE "directory" \
                                                                                                                                                                                        '{
                                                                                                                                                                                            "cat" : $CAT ,
                                                                                                                                                                                            "name" : $NAME ,
                                                                                                                                                                                            "stat" : $STAT ,
                                                                                                                                                                                            "type" : $TYPE
                                                                                                                                                                                        }'
                                                                                                                                                                                else
                                                                                                                                                                                    exit 138
                                                                                                                                                                                fi
                                                                                                                                                                            done
                                                                                                                                                                            echo "${ builtins.concatStringsSep "" [ "$" "{" "UUID[@]" "}" ] }" >&2
                                                                                                                                                                        '' ;
                                                                                                                                                                }
                                                                                                                                                        )
                                                                                                                                                        (
                                                                                                                                                            pkgs.writeShellApplication
                                                                                                                                                                {
                                                                                                                                                                    name = "check-redis" ;
                                                                                                                                                                    runtimeInputs = [ pkgs.coreutils ] ;
                                                                                                                                                                    text =
                                                                                                                                                                        ''
                                                                                                                                                                            UUID=()
                                                                                                                                                                            while [[ "$#" -gt 0 ]]
                                                                                                                                                                            do
                                                                                                                                                                                case "$1" in
                                                                                                                                                                                    --uuid)
                                                                                                                                                                                        UUID+=( "$2" )
                                                                                                                                                                                        shift 2
                                                                                                                                                                                        ;;
                                                                                                                                                                                    *)
                                                                                                                                                                                        exit 144
                                                                                                                                                                                        ;;
                                                                                                                                                                                esac
                                                                                                                                                                            done
                                                                                                                                                                            cleanup ( )
                                                                                                                                                                            {
                                                                                                                                                                                STATUS="$?"
                                                                                                                                                                                if [[ "$STATUS" != 0 ]]
                                                                                                                                                                                then
                                                                                                                                                                                    echo "$STATUS"
                                                                                                                                                                                fi
                                                                                                                                                                                exit 0
                                                                                                                                                                            }
                                                                                                                                                                            trap cleanup EXIT
                                                                                                                                                                            read -r -t 1 -u 189 TYPE <&189 || exit 183
                                                                                                                                                                            read -r -t 1 -u 189 CHANNEL <&189 || exit 104
                                                                                                                                                                            read -r -t 1 -u 189 PAYLOAD <&189 || exit 125
                                                                                                                                                                            mkdir --parents ${ resources-directory }
                                                                                                                                                                            exec 196> ${ resources-directory }/check.lock
                                                                                                                                                                            # shellcheck disable=SC2208,SC2016
                                                                                                                                                                            jq \
                                                                                                                                                                                --null-input \
                                                                                                                                                                                --arg TYPE "$TYPE" \
                                                                                                                                                                                --arg CHANNEL "$CHANNEL" \
                                                                                                                                                                                --argjson PAYLOAD "$PAYLOAD" \
                                                                                                                                                                                --arg TYPE "TYPE" \
                                                                                                                                                                                '{
                                                                                                                                                                                    "type" : $TYPE ,
                                                                                                                                                                                    "channel" : $CHANNEL ,
                                                                                                                                                                                    "payload" : $PAYLOAD"
                                                                                                                                                                                }'
                                                                                                                                                                            echo "${ builtins.concatStringsSep "" [ "$" "{" "UUID[@]" "}"] }" >&2
                                                                                                                                                                        '' ;
                                                                                                                                                                }
                                                                                                                                                        )
                                                                                                                                                    ] ;
                                                                                                                                                text = text ;
                                                                                                                                            } ;
                                                                                                                                    in "${ application }/bin/command" ;
                                                                                                                            file =
                                                                                                                                let
                                                                                                                                    application =
                                                                                                                                        pkgs.writeShellApplication
                                                                                                                                            {
                                                                                                                                                name = "file" ;
                                                                                                                                                runtimeInputs = [ pkgs.bash pkgs.coreutils pkgs.diffutils ] ;
                                                                                                                                                text =
                                                                                                                                                    ''
                                                                                                                                                        export COMMAND_INDEX=${ command-index }
                                                                                                                                                        mkdir --parents /tmp/scratch/commands/${ command-index }/expected
                                                                                                                                                        ln --symbolic ${ standard-error } /tmp/scratch/commands/${ command-index }/expected/standard-error
                                                                                                                                                        ln --symbolic ${ standard-output } /tmp/scratch/commands/${ command-index }/expected/standard-output
                                                                                                                                                        echo -n ${ status } > /tmp/scratch/commands/${ command-index }/expected/status
                                                                                                                                                        echo -n ${ kludge } > /tmp/scratch/commands/${ command-index }/kludge
                                                                                                                                                        ln --symbolic ${ process.path } /tmp/scratch/commands/${ command-index }/process
                                                                                                                                                        echo -n ${ builtins.toJSON reads } > /tmp/scratch/commands/${ command-index }/reads
                                                                                                                                                        cat ${ builtins.toFile "text" text } > /tmp/scratch/commands/${ command-index }/text
                                                                                                                                                        echo -n ${ timeout } > /tmp/scratch/commands/${ command-index }/timeout
                                                                                                                                                        mkdir --parents /tmp/scratch/commands/${ command-index }/observed
                                                                                                                                                        seq 0 $(( ${ command-index } - 1 )) | while read -r I
                                                                                                                                                        do
                                                                                                                                                            while [[ ! -f "/tmp/scratch/commands/$I/flag" ]]
                                                                                                                                                            do
                                                                                                                                                                sleep 1s
                                                                                                                                                            done
                                                                                                                                                        done
                                                                                                                                                        if timeout ${ timeout }s ${ command } > /tmp/scratch/commands/${ command-index }/observed/standard-output 2> /tmp/scratch/commands/${ command-index }/observed/standard-error ${ if reads then "<&189" else "" }
                                                                                                                                                        then
                                                                                                                                                            echo -n "$?" > "/tmp/scratch/commands/${ command-index }/observed/status"
                                                                                                                                                        else
                                                                                                                                                            echo -n "$?" > "/tmp/scratch/commands/${ command-index }/observed/status"
                                                                                                                                                        fi
                                                                                                                                                        touch "/tmp/scratch/commands/${ command-index }/flag"
                                                                                                                                                        if ! diff --recursive --report-identical-files "/tmp/scratch/commands/${ command-index }/expected" "/tmp/scratch/commands/${ command-index }/observed" > /dev/null >&1
                                                                                                                                                        then
                                                                                                                                                            echo true > "/tmp/scratch/failure"
                                                                                                                                                            echo true > "/tmp/scratch/commands/${ command-index }/failure"
                                                                                                                                                        else
                                                                                                                                                            echo false > "/tmp/scratch/commands/${ command-index }/failure"
                                                                                                                                                        fi
                                                                                                                                                    '' ;
                                                                                                                                            } ;
                                                                                                                                in "${ application }/bin/file" ;
                                                                                                                            in ''${ application }/bin/link "$OUT"'' ;
                                                                                                                    process = process ;
                                                                                                                } ;
                                                                                                in builtins.map mapper parameters ;
                                                                                        execute =
                                                                                            let
                                                                                                application =
                                                                                                    pkgs.writeShellApplication
                                                                                                        {
                                                                                                            name = "execute" ;
                                                                                                            runtimeInputs = [ pkgs.coreutils pkgs.gnused ] ;
                                                                                                            text =
                                                                                                                let
                                                                                                                    file =
                                                                                                                        let
                                                                                                                            application =
                                                                                                                                pkgs.writeShellApplication
                                                                                                                                    {
                                                                                                                                        name = "file" ;
                                                                                                                                        runtimeInputs = [ pkgs.coreutils pkgs.diffutils pkgs.findutils pkgs.flock pkgs.jq pkgs.redis pkgs.yq-go ] ;
                                                                                                                                        text =
                                                                                                                                            ''
                                                                                                                                                mkdir --parents ${ resources-directory }
                                                                                                                                                exec 142> ${ resources-directory }/check.lock
                                                                                                                                                flock -x 142
                                                                                                                                                mkdir --parents "/tmp/scratch"
                                                                                                                                                echo false > "/tmp/scratch/failure"
                                                                                                                                                export IS_NIX_FLAKE_CHECK=true
                                                                                                                                                exec 189< <( redis-cli SUBSCRIBE ${ invalid-init-channel } ${ invalid-release-channel } ${ valid-init-channel } ${ valid-release-channel } )
                                                                                                                                                ${ builtins.concatStringsSep "\n" ( builtins.map ( process : "( ${ process.file-name } <&189 & )" ) processes ) }
                                                                                                                                                seq 0 ${ builtins.toString ( ( builtins.length commands ) - 1 ) } | while read -r I
                                                                                                                                                do
                                                                                                                                                    while [[ ! -f "/tmp/scratch/commands/$I/flag" ]]
                                                                                                                                                    do
                                                                                                                                                        sleep 1s
                                                                                                                                                    done
                                                                                                                                                    KLUDGE="$( cat "/tmp/scratch/commands/$I/kludge" )" || exit 137
                                                                                                                                                    READS="$( cat "/tmp/scratch/commands/$I/reads" )" || exit 186
                                                                                                                                                    STATUS="$( cat "/tmp/scratch/commands/$I/observed/status" )" || exit 147
                                                                                                                                                    TIMEOUT="$( cat "/tmp/scratch/commands/$I/timeout" )" || exit 133
                                                                                                                                                    jq \
                                                                                                                                                        --null-input \
                                                                                                                                                        --argjson KLUDGE  "$KLUDGE" \
                                                                                                                                                        --rawfile PROCESS "/tmp/scratch/commands/$I/process" \
                                                                                                                                                        --argjson READS "$READS" \
                                                                                                                                                        --rawfile STANDARD_ERROR "/tmp/scratch/commands/$I/observed/standard-error" \
                                                                                                                                                        --rawfile STANDARD_OUTPUT "/tmp/scratch/commands/$I/observed/standard-output" \
                                                                                                                                                        --argjson STATUS "$STATUS" \
                                                                                                                                                        --rawfile TEXT "/tmp/scratch/commands/$I/text" \
                                                                                                                                                        --argjson TIMEOUT "$TIMEOUT" \
                                                                                                                                                        '{
                                                                                                                                                            "kludge" : $KLUDGE ,
                                                                                                                                                            "process" : $PROCESS ,
                                                                                                                                                            "reads" : $READS ,
                                                                                                                                                            "standard-error" : $STANDARD_ERROR ,
                                                                                                                                                            "standard-output" : $STANDARD_OUTPUT ,
                                                                                                                                                            "status" : $STATUS ,
                                                                                                                                                            "text" : $TEXT ,
                                                                                                                                                            "timeout" : $TIMEOUT
                                                                                                                                                        }' | yq eval --prettyPrint "[.]" >> /tmp/scratch/outputs.yaml
                                                                                                                                                done
                                                                                                                                                yq eval --output-format json --prettyPrint "." /tmp/scratch/outputs.yaml > /tmp/scratch/outputs.json
                                                                                                                                                cd /tmp/scratch
                                                                                                                                                nix eval --expr 'builtins.fromJSON ( builtins.readFile ./outputs.json )' --impure > /tmp/scratch/outputs.nix
                                                                                                                                                mkdir --parents /tmp/scratch/link
                                                                                                                                                TARGET="$( echo "$OUT" | sha512sum  | cut --characters 1-128 )" || exit 190
                                                                                                                                                echo "$TARGET" > /tmp/scratch/link/name
                                                                                                                                                touch "/tmp/scratch/link/$TARGET"
                                                                                                                                            '' ;
                                                                                                                                    } ;
                                                                                                                            in "${ application }/bin/file" ;
                                                                                                                    in
                                                                                                                        ''
                                                                                                                            : "${ builtins.concatStringsSep "" [ "$" "{" "OUT:?must be exported" "}" ] }"
                                                                                                                            mkdir --parent "$OUT"
                                                                                                                            sed -e "s#\$OUT#$OUT#" -e "w$OUT/execute" ${ file }
                                                                                                                            chmod a+rx "$OUT/execute"
                                                                                                                        '' ;
                                                                                                        } ;
                                                                                                in "${ application }/bin/execute" ;
                                                                                        parameters =
                                                                                            let
                                                                                                generator =
                                                                                                    index :
                                                                                                        let
                                                                                                            input = builtins.elemAt inputs_ index ;
                                                                                                            identity =
                                                                                                                {
                                                                                                                    kludge ? false ,
                                                                                                                    process ? "" ,
                                                                                                                    reads ? true ,
                                                                                                                    standard-error ? "" ,
                                                                                                                    standard-output ? "" ,
                                                                                                                    status ? 0 ,
                                                                                                                    text ,
                                                                                                                    timeout ? 60
                                                                                                                } :
                                                                                                                    {
                                                                                                                        command-index = builtins.toString index ;
                                                                                                                        kludge = visitor { bool = path : value : builtins.toJSON value ; } kludge ;
                                                                                                                        process =
                                                                                                                            let
                                                                                                                                path =
                                                                                                                                    visitor
                                                                                                                                        {
                                                                                                                                            string = path : value : builtins.toFile "process" value ;
                                                                                                                                            path = path : value : value ;
                                                                                                                                        }
                                                                                                                                        process ;
                                                                                                                                string = toString path ;
                                                                                                                                in
                                                                                                                                    {
                                                                                                                                        path = path ;
                                                                                                                                        string = string ;
                                                                                                                                    } ;
                                                                                                                        reads = visitor { bool = path : value : value ; } reads ;
                                                                                                                        standard-error =
                                                                                                                            visitor
                                                                                                                                {
                                                                                                                                    string = path : value : builtins.toFile "process" value ;
                                                                                                                                    path = path : value : value ;
                                                                                                                                }
                                                                                                                                standard-error ;
                                                                                                                        standard-output =
                                                                                                                            visitor
                                                                                                                                {
                                                                                                                                    string = path : value : builtins.toFile "process" value ;
                                                                                                                                    path = path : value : value ;
                                                                                                                                }
                                                                                                                                standard-output ;
                                                                                                                        status = visitor { int = path : value : builtins.toString value ; } status ;
                                                                                                                        text = visitor { string = path : value : value ; } text ;
                                                                                                                        timeout = visitor { int = path : value : builtins.toString value ; } timeout ;
                                                                                                                    } ;
                                                                                                            in identity input ;
                                                                                                inputs_ = builtins.fromJSON inputs ;
                                                                                                in builtins.genList generator ( builtins.length inputs_ ) ;
                                                                                        processes =
                                                                                            let
                                                                                                generator =
                                                                                                    index :
                                                                                                        let
                                                                                                            file-name = ''"$OUT/processes/${ builtins.toString index }"'' ;
                                                                                                            process = builtins.elemAt list index ;
                                                                                                            in
                                                                                                                {
                                                                                                                    file-name = file-name ;
                                                                                                                    link =
                                                                                                                        let
                                                                                                                            application =
                                                                                                                                pkgs.writeShellApplication
                                                                                                                                    {
                                                                                                                                        name = "link" ;
                                                                                                                                        runtimeInputs = [ pkgs.coreutils pkgs.gnused ] ;
                                                                                                                                        text =
                                                                                                                                            let
                                                                                                                                                file =
                                                                                                                                                    let
                                                                                                                                                        application =
                                                                                                                                                            pkgs.writeShellApplication
                                                                                                                                                                {
                                                                                                                                                                    name = "file" ;
                                                                                                                                                                    text =
                                                                                                                                                                        ''
                                                                                                                                                                            export PROCESS_INDEX=${ builtins.toString index }
                                                                                                                                                                            PROCESS_NAME=${ process.name }
                                                                                                                                                                            export PROCESS_NAME
                                                                                                                                                                            echo PROCESS ${ builtins.toString index } "$$" >&2
                                                                                                                                                                            ${ process.value.commands }
                                                                                                                                                                        '' ;
                                                                                                                                                                } ;
                                                                                                                                                    in "${ application }/bin/file" ;
                                                                                                                                                in
                                                                                                                                                    ''
                                                                                                                                                        OUT="$1"
                                                                                                                                                        sed -e "s#\$OUT#$OUT#" -e w${ file-name } ${ file }
                                                                                                                                                        chmod a+rx ${ file-name }
                                                                                                                                                    '' ;
                                                                                                                                    } ;
                                                                                                                            in ''${ application }/bin/link "$OUT"'' ;
                                                                                                                } ;
                                                                                                grouper = command : builtins.readFile ( command.process.string ) ;
                                                                                                list = builtins.attrValues ( builtins.mapAttrs mapper ( builtins.groupBy grouper commands ) ) ;
                                                                                                mapper =
                                                                                                    name : value :
                                                                                                        {
                                                                                                            name = name ;
                                                                                                            value =
                                                                                                                {
                                                                                                                    commands =
                                                                                                                        let
                                                                                                                            mapper = command : "${ command.file-name } <&189" ;
                                                                                                                            in builtins.concatStringsSep "\n" ( builtins.map mapper value ) ;
                                                                                                                    delays =
                                                                                                                        let
                                                                                                                            mapper = command : command.delay ;
                                                                                                                            in builtins.concatStringsSep "\n" ( builtins.map mapper value ) ;
                                                                                                                } ;
                                                                                                        } ;
                                                                                                in builtins.genList generator ( builtins.length list ) ;
                                                                                        test =
                                                                                            let
                                                                                                application =
                                                                                                    pkgs.writeShellApplication
                                                                                                        {
                                                                                                            name = "test" ;
                                                                                                            runtimeInputs = [ pkgs.coreutils pkgs.pstree ] ;
                                                                                                            text =
                                                                                                                ''
                                                                                                                    FAILURE="$( cat /tmp/scratch/failure )" || exit 124
                                                                                                                    if [[ "true" == "$FAILURE" ]]
                                                                                                                    then
                                                                                                                        TARGET="$( cat /tmp/scratch/link/name )" || exit 192
                                                                                                                        echo find /nix/store -type f -name "$TARGET" -exec echo {} \; -quit >&2
                                                                                                                        cat ${ builtins.toFile "name" name } >&2
                                                                                                                        exit 181
                                                                                                                    fi
                                                                                                                '' ;
                                                                                                        } ;
                                                                                                in "${ application }/bin/test" ;
                                                                                        in
                                                                                            ''
                                                                                                export OUT="$1"
                                                                                                mkdir --parents "$OUT/commands"
                                                                                                ${ builtins.concatStringsSep "\n" ( builtins.map (command : command.link ) commands ) }
                                                                                                mkdir --parent "$OUT/processes"
                                                                                                ${ builtins.concatStringsSep "\n" ( builtins.map ( process : process.link ) processes ) }
                                                                                                ${ execute }
                                                                                                NIXOS_TEST=1
                                                                                                sed -e "s#\$NIXOS_TEST#$NIXOS_TEST#" -e "w$OUT/test" ${ test }
                                                                                                chmod a+rx "$OUT/test"
                                                                                            '' ;
                                                                            }
                                                                    )
                                                                ] ;
                                                            src = ./. ;
                                                        } ;
                                                nixos-test =
                                                    pkgs.nixosTest
                                                        {
                                                            name = "resource-check" ;
                                                            nodes = nodes ;
                                                            testScript = builtins.concatStringsSep "\n" ( tests action-derivation ) ;
                                                        } ;
                                                in
                                                    {
                                                        name = name ;
                                                        value = nixos-test ;
                                                    } ;
                                    implementation = implementation ;
                                } ;
            } ;
}
