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
                                                                        mkdir --parents ${ resources-directory }/locks
                                                                        exec 135> ${ resources-directory }/locks/clean
                                                                        flock -s 135
                                                                        mkdir --parents ${ resources-directory }/temporary
                                                                        INPUT="$( mktemp --suffix ".json" ${ resources-directory }/temporary/XXXXXXXX )" || exit 173
                                                                        export INPUT
                                                                        jq --compact-output "." > "$INPUT"
                                                                        OUTPUT="$( mktemp --suffix ".json" ${ resources-directory }/temporary/XXXXXXXX )" || exit 128
                                                                        export OUTPUT
                                                                        mkdir --parents ${ resources-directory }/locks
                                                                        exec 143> ${ resources-directory }/locks/log
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
                                                                    mkdir --parents ${ gc-roots-directory }
                                                                    mkdir --parents ${ resources-directory }/locks
                                                                    exec 131> ${ resources-directory }/locks/clean
                                                                    flock -x 131
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
                                                                                                                    read -r -u 170 TYPE || break
                                                                                                                    read -r -u 170 CHANNEL || break
                                                                                                                    read -r -u 170 PAYLOAD || break
                                                                                                                    jq \
                                                                                                                        --null-input \
                                                                                                                        --arg TYPE "$TYPE" \
                                                                                                                        --arg CHANNEL "$CHANNEL" \
                                                                                                                        --argjson PAYLOAD "$PAYLOAD" \
                                                                                                                        '{
                                                                                                                            "type" : $TYPE ,
                                                                                                                            "channel" : $CHANNEL ,
                                                                                                                            "payload" : $PAYLOAD
                                                                                                                        }' | yq eval --prettyPrint '[.]' >> /log
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
                                                            runtimeInputs = [ coreutils jq redis ] ;
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
                                                                            "${ resources-directory }/release/$INDEX" &
                                                                        fi
                                                                    done
                                                                '' ;
                                                        } ;
                                                    in "${ application }/bin/release" ;
                                        release2 =
                                            let
                                                application =
                                                    writeShellApplication
                                                        {
                                                            name = "release" ;
                                                            runtimeInputs =
                                                                [
                                                                    (
                                                                        buildFHSUserEnv
                                                                            {
                                                                                extraBwrapArgs =
                                                                                    [
                                                                                        "--bind" "/tmp/DEBUG" "/debug"
                                                                                        "--tmpfs" "/private"
                                                                                        "--ro-bind" "${ resources-directory }/release" "/release"
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
                                                                                                        runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.redis ] ;
                                                                                                        text =
                                                                                                            ''
                                                                                                                stdbuf -oL redis-cli --raw SUBSCRIBE ${ root-parameters.valid-init-channel } | while true
                                                                                                                do
                                                                                                                    read -r TYPE || { echo "TYPE _EOF" >> /debug ; break; }
                                                                                                                    read -r CHANNEL || { echo "CHANNEL _EOF" >> /debug ; break; }
                                                                                                                    read -r PAYLOAD || { echo "PAYLOAD _EOF" >> /debug ; break; }
                                                                                                                    if [[ "$TYPE" == "message" ]] && [[ "${ root-parameters.valid-init-channel }" == "$CHANNEL" ]]
                                                                                                                    then
                                                                                                                        INDEX="$( jq --raw-output ".index" <<< "$PAYLOAD" )" || break
                                                                                                                        "/release/$INDEX" &
                                                                                                                    else
                                                                                                                        echo "NO_CONDITION" >> /debug
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
                                                                    while [[ ! -d ${ resources-directory }/release ]]
                                                                    do
                                                                        sleep 1s
                                                                    done
                                                                    release
                                                                '' ;
                                                        } ;
                                                in "${ application }/bin/release" ;
                                        resource =
                                            {
                                                error ,
                                                init ,
                                                release ,
                                                seed ,
                                                targets ,
                                                temporary
                                            } :
                                                let
                                                    resource =
                                                        writeShellApplication
                                                            {
                                                                name = "resource" ;
                                                                runtimeInputs = [ coreutils findutils gnused log resource-parameters.init.action.script ] ;
                                                                text =
                                                                    ''
                                                                        mkdir --parents ${ gc-roots-directory }
                                                                        mkdir --parents ${ resources-directory }
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
                                                                                    }' \
                                                                                    -- "$@" > "$INPUT_FILE"
                                                                            else
                                                                                # ORIGINATOR_PID="$( ps -o ppid= -p "$$" | tr -d '[:space:]' )" || exit 186
                                                                                PENULTIMATE_PID="$( ps -o ppid= -p "$PPID" | tr -d '[:space:]' )" || exit 192
                                                                                ULTIMATE_PID="$( ps -o ppid= -p "$PENULTIMATE_PID" | tr -d '[:space:]' )" || exit 125
                                                                                ORIGINATOR_PID="$( ps -o ppid= -p "$ULTIMATE_PID" | tr -d '[:space:]' )" || exit 125
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
                                                                                    }' \
                                                                                    -- "$@" > "$INPUT_FILE"
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
                                                                                    }' \
                                                                                    -- "$@" > "$INPUT_FILE"
                                                                            else
                                                                                ORIGINATOR_PID="$( ps -o ppid= -p "$$" | tr -d '[:space:]' )" || exit 186
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
                                                                                    }' \
                                                                                    -- "$@" > "$INPUT_FILE"
                                                                            fi
                                                                        fi
                                                                        OUTPUT_FILE="$( mktemp --suffix ".json" )" || exit 101
                                                                        export OUTPUT_FILE
                                                                        mkdir --parents ${ gc-roots-directory }
                                                                        mkdir --parents ${ resources-directory }
                                                                        init
                                                                        CHANNEL="$( jq --raw-output ".channel" "$OUTPUT_FILE" )" || exit 181
                                                                        export CHANNEL
                                                                        INDEX="$( jq --raw-output ".index" "$OUTPUT_FILE" )" || exit 198
                                                                        EVALUATION="$( jq --raw-output ".evaluation" "$OUTPUT_FILE" )" || exit 183
                                                                        STANDARD_ERROR="$( jq --raw-output '.["standard-error"]' "$OUTPUT_FILE" )" || exit 146
                                                                        STATUS="$( jq --raw-output ".status" "$OUTPUT_FILE" )" || exit 128
                                                                        echo -en "${ resources-directory }/mounts/$INDEX"
                                                                        if [[ 0 == "$STATUS" ]] && [[ -z "$STANDARD_ERROR" ]]
                                                                        then
                                                                            # FINDME SUCCESS 2
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
                                                                                }' \
                                                                                "$OUTPUT_FILE" | log
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
                                                                                }' \
                                                                                "$OUTPUT_FILE" | log
                                                                        elif [[ 0 != "$STATUS" ]] && [[ -n "$STANDARD_ERROR" ]]
                                                                        then
                                                                            jq \
                                                                                '{
                                                                                    "WTF" : "9976979456295116" ,
                                                                                    "arguments" : .arguments ,
                                                                                    "index" : .index ,
                                                                                    "inputs" : .inputs ,
                                                                                    "originator-pid" : .["originator-pid"] ,
                                                                                    "seed" : .seed ,
                                                                                    "standard-error" : .["standard-error"] ,
                                                                                    "standard-output" : .["standard-ouput"] ,
                                                                                    "status" : .status ,
                                                                                    "targets" : .targets ,
                                                                                    "text" : .text ,
                                                                                    "temporary" : .temporary
                                                                                }' \
                                                                                "$OUTPUT_FILE" | log
                                                                        fi
                                                                        rm "$INPUT_FILE" "$OUTPUT_FILE"
                                                                        exit "$EVALUATION"
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
                                                                                                                                "--bind" "${ resources-directory }/mounts/$INDEX" "/mount"
                                                                                                                                "--bind" "${ resources-directory }/pids/$INDEX" "/pid"
                                                                                                                                "--bind" "${ resources-directory }/release" "/release"
                                                                                                                                "--bind" "$OUTPUT_FILE" "/output"
                                                                                                                                "--tmpfs" "/private"
                                                                                                                                "--tmpfs" "/scratch"
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
                                                                                                                                                                    runtimeInputs = resource-parameters.init.action.targetPkgs pkgs ;
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
                                                                                                                                                        OBSERVED_TARGETS="$( LC_ALL=C find /mount -mindepth 1 -maxdepth 1 -exec basename {} \; | sort | jq -R "." | jq -s "." )" || exit 111
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
                                                                                                                                                            # shellcheck disable=SC2016
                                                                                                                                                            echo jq \
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
                                                                                                                                                                    "channel" : $CHANNEL
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
                                                                                                                                                                }' >&2
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
                                                                                                                                                                    "channel" : $CHANNEL
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
                                                                                                                                                                }' \
                                                                                                                                                                "$INPUT_FILE" > "$OUTPUT_FILE"
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
                                                                                                            mkdir --parents ${ resources-directory }/flage =
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
                                                                                                                                                                INDEX="$( jq --raw-output ".index" /input )" || exit 176
                                                                                                                                                                EXPECTED="${ resources-directory }/mounts/$INDEX"
                                                                                                                                                                find /gc-roots -type l | sort | while read -r LINK
                                                                                                                                                                do
                                                                                                                                                                    OBSERVED="$( readlink --canonicalize "$LINK" )" || exit 198
                                                                                                                                                                    if [[ "$EXPECTED" == "$OBSERVED" ]]
                                                                                                                                                                    then
                                                                                                                                                                        inotifywait --event delete_self "$LINK" > /private/inotifywait
                                                                                                                                                                    fi
                                                                                                                                                                done
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
                                                                                                                                                                    }' \
                                                                                                                                                                    /input > /output
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
                                                                                                                                                                find /gc-roots -mindepth 1 -maxdepth 1 -name "$INDEX" -print0 | tar --null --files-from - --create --file /temporary/gc-roots.tar.xz --xz
                                                                                                                                                                find /resources -mindepth 2 -maxdepth 2 -name "$INDEX" -print0 -exec rm --recursive --force {} \;
                                                                                                                                                                find /gc-roots -mindepth 1 -maxdepth 1 -name "$INDEX" -print0 | tar --null --files-from - --create --file /temporary/gc-roots.tar.xz --xz
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
                                                                                                                                                                            "standard-output" : .["standard-output"] ,
                                                                                                                                                                            "status" : .status
                                                                                                                                                                        }' \
                                                                                                                                                                        /input | log
                                                                                                                                                                elif [[ "$STATUS" != 0 ]] && [[ -z "$STANDARD_ERROR" ]]
                                                                                                                                                                then
                                                                                                                                                                    export CHANNEL=${ resource-parameters.release.invalid-channel }
                                                                                                                                                                    jq \
                                                                                                                                                                        '{
                                                                                                                                                                            "standard-output" : .standard-output ,
                                                                                                                                                                            "status" : .status
                                                                                                                                                                        }' \
                                                                                                                                                                        /input | log
                                                                                                                                                                    exit ${ resource-parameters.error }
                                                                                                                                                                elif [[ "$STATUS" == 0 ]] && [[ -n "$STANDARD_ERROR" ]]
                                                                                                                                                                then
                                                                                                                                                                    jq \
                                                                                                                                                                        '{
                                                                                                                                                                            "standard-output" : .["standard-output"] ,
                                                                                                                                                                            "standard-error" : .["standard-error"]
                                                                                                                                                                        }' \
                                                                                                                                                                        /input | log
                                                                                                                                                                    exit ${ resource-parameters.error }
                                                                                                                                                                elif [[ "$STATUS" != 0 ]] && [[ -n "$STANDARD_ERROR" ]]
                                                                                                                                                                then
                                                                                                                                                                    jq \
                                                                                                                                                                        '{
                                                                                                                                                                            "standard-output" : .["standard-output"] ,
                                                                                                                                                                            "standard-error" : .["standard-error"] ,
                                                                                                                                                                            "status" : .status
                                                                                                                                                                        }' \
                                                                                                                                                                        /input | log
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
                                                                                                                    INDEX="$( basename "$0" )" || exit 101
                                                                                                                    mkdir --parents ${ resources-directory }/locks
                                                                                                                    exec 182> ${ resources-directory }/locks/clean
                                                                                                                    flock -s 182
                                                                                                                    rm --force "${ resources-directory }/flags/$INDEX"
                                                                                                                    find "${ resources-directory }/pids/$INDEX" -mindepth 1 -maxdepth 1 -type f | sort | while read -r PID_FILE
                                                                                                                    do
                                                                                                                        PID="$( basename "$PID_FILE" )" || exit 169
                                                                                                                        tail --follow /dev/null --pid "$PID"
                                                                                                                        rm "$PID_FILE"
                                                                                                                    done
                                                                                                                    mkdir --parents ${ resources-directory }/temporary
                                                                                                                    INPUT_FILE="$( mktemp --suffix ".json" ${ resources-directory }/temporary/XXXXXXXX )" || exit 128
                                                                                                                    export INPUT_FILE
                                                                                                                    jq \
                                                                                                                        --null-input \
                                                                                                                        --arg _INDEX "$INDEX"\
                                                                                                                        '{
                                                                                                                            "index" : $_INDEX
                                                                                                                        }' > "$INPUT_FILE"
                                                                                                                    OUTPUT_FILE="$( mktemp --suffix ".json" ${ resources-directory }/temporary/XXXXXXXX )" || exit 128
                                                                                                                    export OUTPUT_FILE
                                                                                                                    mkdir --parents ${ gc-roots-directory }
                                                                                                                    is-releasable
                                                                                                                    STATUS="$( jq --raw-output ".status" "$OUTPUT_FILE" )" || exit 171
                                                                                                                    STANDARD_ERROR="$( jq --raw-output '.["standard-error"]' "$OUTPUT_FILE" )" || exit 172
                                                                                                                    if [[ ! -f "${ resources-directory }/flags/$INDEX" ]] && [[ "$STATUS" == 0 ]] && [[ -z "$STANDARD_ERROR" ]]
                                                                                                                    then
                                                                                                                        exec 186> "${ resources-directory }/locks/$INDEX.lock"
                                                                                                                        flock -x 186
                                                                                                                        TEMPORARY="$( mktemp --directory )" || exit 112
                                                                                                                        export TEMPORARY
                                                                                                                        release
                                                                                                                    else
                                                                                                                        flock -u 182
                                                                                                                        "$0"
                                                                                                                    fi
                                                                                                                    rm "$INPUT_FILE" "$OUTPUT_FILE"
                                                                                                                '' ;
                                                                                                        } ;
                                                                                                in "${ application }/bin/release" ;
                                                                                        text = visitor { string = path : value : value ; } action.text ;
                                                                                        targetPkgs = visitor { lambda = path : value : value ; } action.targetPkgs ;
                                                                                    } ;
                                                                        invalid-channel = root-parameters.invalid-release-channel ;
                                                                        release = visitor { lambda = path : value : value null ; } release ;
                                                                        recovery = null ;
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
                                                                        mkdir --parents ${ resources-directory }/locks
                                                                        exec 113> ${ resources-directory }/locks/clean
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
                                            actions ,
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
                                                                                runtimeInputs = [ pkgs.coreutils ] ;
                                                                                text =
                                                                                    let
                                                                                        commands =
                                                                                            let
                                                                                                mapper =
                                                                                                    {
                                                                                                        command-index ,
                                                                                                        critical ,
                                                                                                        process ,
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
                                                                                                                    delay =
                                                                                                                        let
                                                                                                                            application =
                                                                                                                                pkgs.writeShellApplication
                                                                                                                                    {
                                                                                                                                        name = "delay" ;
                                                                                                                                        runtimeInputs = [ pkgs.coreutils pkgs.findutils ] ;
                                                                                                                                        text =
                                                                                                                                            ''
                                                                                                                                                while [[ ! -f "$SCRATCH/commands/${ command-index }/flag" ]]
                                                                                                                                                do
                                                                                                                                                    sleep 1s
                                                                                                                                                done
                                                                                                                                            '' ;
                                                                                                                                    } ;
                                                                                                                            in "${ application }/bin/delay" ;
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
                                                                                                                            file =
                                                                                                                                let
                                                                                                                                    application =
                                                                                                                                        pkgs.writeShellApplication
                                                                                                                                            {
                                                                                                                                                name = "file" ;
                                                                                                                                                runtimeInputs = [ pkgs.bash pkgs.coreutils pkgs.diffutils ] ;
                                                                                                                                                text =
                                                                                                                                                    ''
                                                                                                                                                        export DOCUMENT="$SCRATCH/commands/${ command-index }/document"
                                                                                                                                                        mkdir --parents "$SCRATCH/commands/${ command-index }/expected"
                                                                                                                                                        echo ${ critical } > "$SCRATCH/commands/${ command-index }/critical"
                                                                                                                                                        ln --symbolic ${ process.path } "$SCRATCH/commands/${ command-index }/process"
                                                                                                                                                        ln --symbolic ${ text } "$SCRATCH/commands/${ command-index }/text"
                                                                                                                                                        echo ${ timeout } > "$SCRATCH/commands/${ command-index }/timeout"
                                                                                                                                                        ln --symbolic ${ standard-error } "$SCRATCH/commands/${ command-index }/expected/standard-error"
                                                                                                                                                        ln --symbolic ${ standard-output } "$SCRATCH/commands/${ command-index }/expected/standard-output"
                                                                                                                                                        echo ${ status } > "$SCRATCH/commands/${ command-index }/expected/status"
                                                                                                                                                        mkdir --parents "$SCRATCH/commands/${ command-index }/observed"
                                                                                                                                                        seq 0 $(( ${ command-index } - 1 )) | while read -r I
                                                                                                                                                        do
                                                                                                                                                            while [[ ! -f "$SCRATCH/commands/$I/flag" ]]
                                                                                                                                                            do
                                                                                                                                                                sleep 1s
                                                                                                                                                            done
                                                                                                                                                        done
                                                                                                                                                        seq 0 $(( ${ command-index } - 1 )) | while read -r I
                                                                                                                                                        do
                                                                                                                                                            if [[ -f "$SCRATCH/command/$I/failure" ]]
                                                                                                                                                            then
                                                                                                                                                                touch "$SCRATCH/commands/${ command-index }/failure"
                                                                                                                                                            fi
                                                                                                                                                        done
                                                                                                                                                        if [[ ! -f "$SCRATCH/commands/${ command-index }/failure" ]]
                                                                                                                                                        then
                                                                                                                                                            if timeout ${ timeout }s ${ text } > "$SCRATCH/commands/${ command-index }/observed/standard-output" 2> "$SCRATCH/commands/${ command-index }/observed/standard-error" <&189
                                                                                                                                                            then
                                                                                                                                                                echo "$?" > "$SCRATCH/commands/${ command-index }/observed/status"
                                                                                                                                                            else
                                                                                                                                                                echo "$?" > "$SCRATCH/commands/${ command-index }/observed/status"
                                                                                                                                                            fi
                                                                                                                                                        fi
                                                                                                                                                        touch "$SCRATCH/commands/${ command-index }/flag"
                                                                                                                                                        if ${ critical } && ! diff --recursive --report-identical-files "$SCRATCH/commands/${ command-index }/expected" "$SCRATCH/commands/${ command-index }/observed" 2>&1
                                                                                                                                                        then
                                                                                                                                                            touch "$SCRATCH/commands/${ command-index }/failure"
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
                                                                                                            name = "application" ;
                                                                                                            runtimeInputs = [ pkgs.coreutils pkgs.gnused ] ;
                                                                                                            text =
                                                                                                                let
                                                                                                                    file =
                                                                                                                        let
                                                                                                                            application =
                                                                                                                                pkgs.writeShellApplication
                                                                                                                                    {
                                                                                                                                        name = "file" ;
                                                                                                                                        runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.redis ] ;
                                                                                                                                        text =
                                                                                                                                            ''
                                                                                                                                                SCRATCH="$( mktemp --directory )" || exit 125
                                                                                                                                                exec 189< <( redis-cli SUBSCRIBE ${ invalid-init-channel } ${ invalid-release-channel } ${ log-channel } ${ valid-init-channel } ${ valid-release-channel } )
                                                                                                                                                export SCRATCH
                                                                                                                                                ${ builtins.concatStringsSep "\n" ( builtins.map ( process : "( ${ process.file-name } <&189 & )" ) processes ) }
                                                                                                                                                ${ builtins.concatStringsSep "\n" ( builtins.map ( process : "${ process.delay }" ) processes ) }
                                                                                                                                                find "$SCRATCH/commands" -mindepth 2 -maxdepth 2 -name failure | while read -r FAILURE
                                                                                                                                                do
                                                                                                                                                    echo failure "$FAILURE" >&2
                                                                                                                                                    DIR="$( dirname "$FAILURE" )" || exit 183
                                                                                                                                                    if [[ -f "$DIR/document" ]]
                                                                                                                                                    then
                                                                                                                                                        cat "$DIR/document" >&2
                                                                                                                                                    fi
                                                                                                                                                    touch "$SCRATCH/failure"
                                                                                                                                                done
                                                                                                                                                if [[ -f "$SCRATCH/failure" ]]
                                                                                                                                                then
                                                                                                                                                    echo SCRATCH "$SCRATCH" >&2
                                                                                                                                                    exit 138
                                                                                                                                                fi
                                                                                                                                            '' ;
                                                                                                                                    } ;
                                                                                                                            in "${ application }/bin/file" ;
                                                                                                                    in
                                                                                                                        ''
                                                                                                                            OUT="$1"
                                                                                                                            mkdir --parent "$OUT"
                                                                                                                            sed -e "s#\$OUT#$OUT#" -e "w$OUT/execute" ${ file }
                                                                                                                            chmod a+rx "$OUT/execute"
                                                                                                                        '' ;
                                                                                                        } ;
                                                                                                in ''${ application }/bin/application "$OUT"'' ;
                                                                                        parameters =
                                                                                            let
                                                                                                generator =
                                                                                                    index :
                                                                                                        let
                                                                                                            action = builtins.elemAt actions index ;
                                                                                                            identity =
                                                                                                                {
                                                                                                                    critical ? true ,
                                                                                                                    process ? "" ,
                                                                                                                    standard-error ? "" ,
                                                                                                                    standard-output ? "" ,
                                                                                                                    status ? 0 ,
                                                                                                                    text ,
                                                                                                                    timeout ? 60
                                                                                                                } :
                                                                                                                    {
                                                                                                                        command-index = builtins.toString index ;
                                                                                                                        critical = visitor { bool = path : value : builtins.toJSON value ; } critical ;
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
                                                                                                                        text =
                                                                                                                            visitor
                                                                                                                                {
                                                                                                                                    string =
                                                                                                                                        path : value :
                                                                                                                                            let
                                                                                                                                                application =
                                                                                                                                                    pkgs.writeShellApplication
                                                                                                                                                        {
                                                                                                                                                            name = "text" ;
                                                                                                                                                            runtimeInputs =
                                                                                                                                                                [
                                                                                                                                                                    (
                                                                                                                                                                        pkgs.writeShellApplication
                                                                                                                                                                            {
                                                                                                                                                                                name = "check-executable" ;
                                                                                                                                                                                text =
                                                                                                                                                                                    ''
                                                                                                                                                                                        if [[ ! -x "$1" ]]
                                                                                                                                                                                        then
                                                                                                                                                                                            echo "$1 is not an executable" >&2
                                                                                                                                                                                        fi
                                                                                                                                                                                    '' ;
                                                                                                                                                                            }
                                                                                                                                                                    )
                                                                                                                                                                    (
                                                                                                                                                                        pkgs.writeShellApplication
                                                                                                                                                                            {
                                                                                                                                                                                name = "check-gc-roots-directory" ;
                                                                                                                                                                                runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.jq pkgs.yq-go ] ;
                                                                                                                                                                                text =
                                                                                                                                                                                    ''
                                                                                                                                                                                        touch "$DOCUMENT"
                                                                                                                                                                                        if [[ -e ${ gc-roots-directory } ]]
                                                                                                                                                                                        then
                                                                                                                                                                                            find ${ gc-roots-directory } -type l -print | sort | while read -r FILE
                                                                                                                                                                                            do
                                                                                                                                                                                                LINK="$( readlink --canonicalize "$FILE" )" || exit 105
                                                                                                                                                                                                jq \
                                                                                                                                                                                                    --null-input \
                                                                                                                                                                                                    --arg FILE "$FILE" \
                                                                                                                                                                                                    --arg CONTENT "$LINK" \
                                                                                                                                                                                                    '{
                                                                                                                                                                                                        "file" : $FILE ,
                                                                                                                                                                                                        "content" : $CONTENT
                                                                                                                                                                                                    }' | yq eval --prettyPrint >> "$DOCUMENT"
                                                                                                                                                                                            done
                                                                                                                                                                                        fi
                                                                                                                                                                                        sha512sum "$DOCUMENT" | cut --characters 1-128
                                                                                                                                                                                    '' ;
                                                                                                                                                                            }
                                                                                                                                                                    )
                                                                                                                                                                    (
                                                                                                                                                                        pkgs.writeShellApplication
                                                                                                                                                                            {
                                                                                                                                                                                name = "check-redis" ;
                                                                                                                                                                                runtimeInputs = [ pkgs.jq ] ;
                                                                                                                                                                                text =
                                                                                                                                                                                    ''
                                                                                                                                                                                        if [[ "$#" == 0 ]]
                                                                                                                                                                                        then
                                                                                                                                                                                            cleanup ( ) {
                                                                                                                                                                                                if [[ "$?" == 0 ]]
                                                                                                                                                                                                then
                                                                                                                                                                                                    jq \
                                                                                                                                                                                                        --null-input \
                                                                                                                                                                                                        --arg TYPE "$TYPE" \
                                                                                                                                                                                                        --arg CHANNEL "$CHANNEL" \
                                                                                                                                                                                                        --argjson PAYLOAD "$PAYLOAD" \
                                                                                                                                                                                                        '{
                                                                                                                                                                                                            "type" : $TYPE ,
                                                                                                                                                                                                            "channel" : $CHANNEL ,
                                                                                                                                                                                                            "payload" : $PAYLOAD
                                                                                                                                                                                                        }' >&2
                                                                                                                                                                                                else
                                                                                                                                                                                                    exit 0
                                                                                                                                                                                                fi
                                                                                                                                                                                            }
                                                                                                                                                                                            trap cleanup EXIT
                                                                                                                                                                                            read -r -t 1 -u 189 TYPE <&189
                                                                                                                                                                                            read -r -t 1 -u 189 CHANNEL <&189
                                                                                                                                                                                            read -r -t 1 -u 189 PAYLOAD <&189
                                                                                                                                                                                        elif [[ "$#" == 2 ]]
                                                                                                                                                                                        then
                                                                                                                                                                                            EXPECTED_TYPE="$1"
                                                                                                                                                                                            EXPECTED_CHANNEL="$2"
                                                                                                                                                                                            EXPECTED_PAYLOAD_TYPE="$3"
                                                                                                                                                                                            read -r -t 1 -u 189 OBSERVED_TYPE <&189 || exit 157
                                                                                                                                                                                            read -r -t 1 -u 189 OBSERVED_CHANNEL <&189 || exit 104
                                                                                                                                                                                            read -r -t 1 -u 189 OBSERVED_PAYLOAD_RAW <&189 || exit 125
                                                                                                                                                                                            if [[ "$EXPECTED_PAYLOAD_TYPE" == "number" ]]
                                                                                                                                                                                            then
                                                                                                                                                                                                jq '.' <<< "$OBSERVED_PAYLOAD" > "$DOCUMENT"
                                                                                                                                                                                            elif [[ "$EXPECTED_PAYLOAD_TYPE" == "set" ]]
                                                                                                                                                                                            then
                                                                                                                                                                                                jq 'del(.["originator-pid"])' <<< "$OBSERVED_PAYLOAD" > "$DOCUMENT"
                                                                                                                                                                                            else
                                                                                                                                                                                                exit 170
                                                                                                                                                                                            fi
                                                                                                                                                                                            sha512sum "$DOCUMENT" | cut --characters 1-128
                                                                                                                                                                                            if [[ "$EXPECTED_TYPE" != "$OBSERVED_TYPE" ]] || [[ "$EXPECTED_CHANNEL" != "$OBSERVED_CHANNEL" ]]
                                                                                                                                                                                            then
                                                                                                                                                                                                # shellcheck disable=SC2208,SC2016
                                                                                                                                                                                                jq \
                                                                                                                                                                                                    --null-input \
                                                                                                                                                                                                    --arg EXPECTED_CHANNEL "$EXPECTED_CHANNEL" \
                                                                                                                                                                                                    --arg EXPECTED_PAYLOAD_TYPE "$EXPECTED_PAYLOAD" \
                                                                                                                                                                                                    --arg EXPECTED_TYPE "$EXPECTED_TYPE" \
                                                                                                                                                                                                    --arg OBSERVED_CHANNEL "$OBSERVED_CHANNEL" \
                                                                                                                                                                                                    --argjson OBSERVED_PAYLOAD "$OBSERVED_PAYLOAD" \
                                                                                                                                                                                                    --arg OBSERVED_TYPE "$OBSERVED_TYPE" \
                                                                                                                                                                                                    '{
                                                                                                                                                                                                        "type" :
                                                                                                                                                                                                            {
                                                                                                                                                                                                                "expected" : $EXPECTED_TYPE ,
                                                                                                                                                                                                                "observed" : $OBSERVED_TYPE
                                                                                                                                                                                                            } ,
                                                                                                                                                                                                        "channel" :
                                                                                                                                                                                                            {
                                                                                                                                                                                                                "expected" : $EXPECTED_CHANNEL ,
                                                                                                                                                                                                                "observed" : $OBSERVED_CHANNEL
                                                                                                                                                                                                            } ,
                                                                                                                                                                                                        "payload" :
                                                                                                                                                                                                            {
                                                                                                                                                                                                                "expected-type" : $EXPECTED_PAYLOAD_TYPE ,
                                                                                                                                                                                                                "observed" : $OBSERVED_PAYLOAD
                                                                                                                                                                                                            }
                                                                                                                                                                                                    }' >&2
                                                                                                                                                                                            fi
                                                                                                                                                                                        else
                                                                                                                                                                                            echo Improper Usage >&2
                                                                                                                                                                                        fi
                                                                                                                                                                                    '' ;
                                                                                                                                                                            }
                                                                                                                                                                    )
                                                                                                                                                                    (
                                                                                                                                                                        pkgs.writeShellApplication
                                                                                                                                                                            {
                                                                                                                                                                                name = "check-resources-directory" ;
                                                                                                                                                                                runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.jq pkgs.yq-go ] ;
                                                                                                                                                                                text =
                                                                                                                                                                                    ''
                                                                                                                                                                                        touch "$DOCUMENT"
                                                                                                                                                                                        if [[ -e ${ resources-directory } ]]
                                                                                                                                                                                        then
                                                                                                                                                                                            find ${ resources-directory } \( -path '${ resources-directory }/log.yaml' -o -path '${ resources-directory }/pids' -o -path '${ resources-directory }/temporary' \) -prune -o -type f,l -print | sort | while read -r FILE
                                                                                                                                                                                            do
                                                                                                                                                                                                jq \
                                                                                                                                                                                                    --null-input \
                                                                                                                                                                                                    --arg FILE "$FILE" \
                                                                                                                                                                                                    --rawfile CONTENT "$FILE" \
                                                                                                                                                                                                    '{
                                                                                                                                                                                                        "file" : $FILE ,
                                                                                                                                                                                                        "content" : $CONTENT
                                                                                                                                                                                                    }' | yq eval --prettyPrint >> "$DOCUMENT"
                                                                                                                                                                                            done
                                                                                                                                                                                        fi
                                                                                                                                                                                        sha512sum "$DOCUMENT" | cut --characters 1-128
                                                                                                                                                                                    '' ;
                                                                                                                                                                            }
                                                                                                                                                                    )
                                                                                                                                                                ] ;
                                                                                                                                                            text = text ;
                                                                                                                                                        } ;
                                                                                                                                                in "${ application }/bin/text" ;
                                                                                                                                }
                                                                                                                                text ;
                                                                                                                        timeout = visitor { int = path : value : builtins.toString value ; } timeout ;
                                                                                                                    } ;
                                                                                                            in identity action ;
                                                                                                in builtins.genList generator ( builtins.length actions ) ;
                                                                                        processes =
                                                                                            let
                                                                                                generator =
                                                                                                    index :
                                                                                                        let
                                                                                                            file-name = ''"$OUT/processes/${ builtins.toString index }"'' ;
                                                                                                            process = builtins.elemAt list index ;
                                                                                                            in
                                                                                                                {
                                                                                                                    delay =
                                                                                                                        let
                                                                                                                            application =
                                                                                                                                pkgs.writeShellApplication
                                                                                                                                    {
                                                                                                                                        name = "delay" ;
                                                                                                                                        text = process.value.delays ;
                                                                                                                                    } ;
                                                                                                                            in "${ application }/bin/delay" ;
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
                                                                                                                                                                    text = process.value.commands ;
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
                                                                                                grouper = command : builtins.hashString "sha512" ( command.process.string ) ;
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
                                                                                        in
                                                                                            ''
                                                                                                OUT="$1"
                                                                                                mkdir --parents "$OUT/commands"
                                                                                                ${ builtins.concatStringsSep "\n" ( builtins.map (command : command.link ) commands ) }
                                                                                                mkdir --parent "$OUT/processes"
                                                                                                ${ builtins.concatStringsSep "\n" ( builtins.map ( process : process.link ) processes ) }
                                                                                                ${ execute }
                                                                                            '' ;
                                                                            }
                                                                    )
                                                                ] ;
                                                            src = ./. ;
                                                        } ;
                                                in
                                                    pkgs.nixosTest
                                                        {
                                                            name = "resource-check" ;
                                                            nodes = nodes ;
                                                            testScript = builtins.concatStringsSep "\n" ( tests action-derivation ) ;
                                                        } ;
                                    check =
                                        {
                                            actions ,
                                            gc-roots-directory ,
                                            machines ,
                                            nixosTest ,
                                            pkgs ,
                                            private ,
                                            resources-directory ,
                                            user
                                        } :
                                            let
                                                check-parameters =
                                                    {
                                                        actions =
                                                            let
                                                                _actions = builtins.concatLists [ pre-actions actions post-actions ] ;
                                                                generator =
                                                                    index :
                                                                        let
                                                                            action = builtins.elemAt _actions index ;
                                                                            identity =
                                                                                {
                                                                                    critical ? true                                                                                    ,
                                                                                    expected-standard-error ? "" ,
                                                                                    expected-standard-output ? "" ,
                                                                                    expected-status ? 0 ,
                                                                                    process ? "default" ,
                                                                                    text ,
                                                                                    timeout ? 60 ,
                                                                                    uuid ? null
                                                                                } :
                                                                                    {
                                                                                        critical = visitor { bool = path : value : builtins.toJSON value ; } critical ;
                                                                                        expected-standard-error = visitor { path = path : value : value ; string = path : value : builtins.toFile "standard-error" value ; } expected-standard-error ;
                                                                                        expected-standard-output = visitor { path = path : value : value ; string = path : value : builtins.toFile "standard-output" value ; } expected-standard-output ;
                                                                                        expected-status = visitor { int = path : value : builtins.toString value ; } expected-status ;
                                                                                        index = builtins.toString index ;
                                                                                        process = visitor { path = path : value : value ; string = path : value : builtins.toFile "process" value ; } process ;
                                                                                        text =
                                                                                            visitor
                                                                                                {
                                                                                                    path = path : value : value ;
                                                                                                    string =
                                                                                                        path : value :
                                                                                                            let
                                                                                                                application =
                                                                                                                    root-parameters.writeShellApplication
                                                                                                                        {
                                                                                                                            name = "command" ;
                                                                                                                            runtimeInputs =
                                                                                                                                [
                                                                                                                                    (
                                                                                                                                        root-parameters.writeShellApplication
                                                                                                                                            {
                                                                                                                                                name = "check-executable" ;
                                                                                                                                                text =
                                                                                                                                                    ''
                                                                                                                                                        EXECUTABLE="$1"
                                                                                                                                                        if [[ ! -x "$EXECUTABLE" ]]
                                                                                                                                                        then
                                                                                                                                                            echo NOT EXECUTABLE >&2
                                                                                                                                                        fi
                                                                                                                                                    '' ;
                                                                                                                                            }
                                                                                                                                    )
                                                                                                                                    (
                                                                                                                                        root-parameters.writeShellApplication
                                                                                                                                            {
                                                                                                                                                name = "check-file-empty" ;
                                                                                                                                                text =
                                                                                                                                                    ''
                                                                                                                                                        if [[ ! -e ${ resources-directory } ]]
                                                                                                                                                        then
                                                                                                                                                            echo Not Empty
                                                                                                                                                        fi
                                                                                                                                                    '' ;
                                                                                                                                            }
                                                                                                                                    )
                                                                                                                                    (
                                                                                                                                        root-parameters.writeShellApplication
                                                                                                                                            {
                                                                                                                                                name = "check-file" ;
                                                                                                                                                runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.jq pkgs.yq-go ] ;
                                                                                                                                                text =
                                                                                                                                                    ''
                                                                                                                                                        YAML_FILE="$1"
                                                                                                                                                        if [[ -e ${ resources-directory } ]]
                                                                                                                                                        then
                                                                                                                                                            find ${ resources-directory } \( -path '${ resources-directory }/pids' -o -path '${ resources-directory }/temporary' \) -prune -o -type f,l -print | sort | while read -r FILE
                                                                                                                                                            do
                                                                                                                                                                CONTENT="$( cat "$FILE" )" || exit 125
                                                                                                                                                                jq \
                                                                                                                                                                    null-input \
                                                                                                                                                                    --arg FILE "$FILE" \
                                                                                                                                                                    --arg CONTENT "$CONTENT" \
                                                                                                                                                                    '{
                                                                                                                                                                        "file" : $FILE ,
                                                                                                                                                                        "content" : $CONTENT
                                                                                                                                                                    }' | yq eval --prettyPrint >> "$YAML_FILE"
                                                                                                                                                            done
                                                                                                                                                        else
                                                                                                                                                            touch "$YAML_FILE"
                                                                                                                                                        fi
                                                                                                                                                        sha512sum "$YAML_FILE" | cut --characters 1-128
                                                                                                                                                    '' ;
                                                                                                                                            }
                                                                                                                                    )
                                                                                                                                    (
                                                                                                                                        root-parameters.writeShellApplication
                                                                                                                                            {
                                                                                                                                                name = "check-redis-block" ;
                                                                                                                                                runtimeInputs = [ pkgs.coreutils pkgs.jq ] ;
                                                                                                                                                text =
                                                                                                                                                    ''
                                                                                                                                                        cleanup ( ) {
                                                                                                                                                            if [[ "$?" == 0 ]]
                                                                                                                                                            then
                                                                                                                                                                jq \
                                                                                                                                                                    --null-input \
                                                                                                                                                                    --arg TYPE "$TYPE" \
                                                                                                                                                                    --arg CHANNEL "$CHANNEL" \
                                                                                                                                                                    --argjson PAYLOAD "$PAYLOAD" \
                                                                                                                                                                    '{
                                                                                                                                                                        "type" : $TYPE ,
                                                                                                                                                                        "channel" : $CHANNEL ,
                                                                                                                                                                        "payload" : $PAYLOAD
                                                                                                                                                                    }' >&2
                                                                                                                                                            else
                                                                                                                                                                exit 0
                                                                                                                                                            fi
                                                                                                                                                        }
                                                                                                                                                        trap cleanup EXIT
                                                                                                                                                        read -r -t 1 -u 189 TYPE <&189
                                                                                                                                                        read -r -t 1 -u 189 CHANNEL <&189
                                                                                                                                                        read -r -t 1 -u 189 PAYLOAD <&189
                                                                                                                                                    '' ;
                                                                                                                                            }
                                                                                                                                    )
                                                                                                                                    (
                                                                                                                                        root-parameters.writeShellApplication
                                                                                                                                            {
                                                                                                                                                name = "check-redis-message" ;
                                                                                                                                                runtimeInputs = [ pkgs.coreutils pkgs.jq ] ;
                                                                                                                                                text =
                                                                                                                                                    ''
                                                                                                                                                        EXPECTED_TYPE="$1"
                                                                                                                                                        EXPECTED_CHANNEL="$2"
                                                                                                                                                        EXPECTED_PAYLOAD_FILE="$3"
                                                                                                                                                        EXPECTED_PAYLOAD_TYPE="$4"
                                                                                                                                                        read -r -t 1 -u 189 OBSERVED_TYPE <&189 || exit 157
                                                                                                                                                        read -r -t 1 -u 189 OBSERVED_CHANNEL <&189 || exit 104
                                                                                                                                                        read -r -t 1 -u 189 OBSERVED_PAYLOAD <&189 || exit 125
                                                                                                                                                        if [[ "$EXPECTED_PAYLOAD_TYPE" == "number" ]]
                                                                                                                                                        then
                                                                                                                                                            EXPECTED_PAYLOAD="$( cat "$EXPECTED_PAYLOAD_FILE" )" || exit 120
                                                                                                                                                            if [[ "$EXPECTED_TYPE" != "$OBSERVED_TYPE" ]] || [[ "$EXPECTED_CHANNEL" != "$OBSERVED_CHANNEL" ]] || [[ "$EXPECTED_PAYLOAD" != "$OBSERVED_PAYLOAD" ]]
                                                                                                                                                            then
                                                                                                                                                                # shellcheck disable=SC2208,SC2016
                                                                                                                                                                jq \
                                                                                                                                                                    --null-input \
                                                                                                                                                                    --arg EXPECTED_CHANNEL "$EXPECTED_CHANNEL" \
                                                                                                                                                                    --argjson EXPECTED_PAYLOAD "$EXPECTED_PAYLOAD" \
                                                                                                                                                                    --arg EXPECTED_TYPE "$EXPECTED_TYPE" \
                                                                                                                                                                    --arg OBSERVED_CHANNEL "$OBSERVED_CHANNEL" \
                                                                                                                                                                    --argjson OBSERVED_PAYLOAD "$OBSERVED_PAYLOAD" \
                                                                                                                                                                    --arg OBSERVED_TYPE "$OBSERVED_TYPE" \
                                                                                                                                                                    '{
                                                                                                                                                                        "type" :
                                                                                                                                                                            {
                                                                                                                                                                                "expected" : $EXPECTED_TYPE ,
                                                                                                                                                                                "observed" : $OBSERVED_TYPE
                                                                                                                                                                            } ,
                                                                                                                                                                        "channel" :
                                                                                                                                                                            {
                                                                                                                                                                                "expected" : $EXPECTED_CHANNEL ,
                                                                                                                                                                                "observed" : $OBSERVED_CHANNEL
                                                                                                                                                                            } ,
                                                                                                                                                                        "payload" :
                                                                                                                                                                            {
                                                                                                                                                                                "expected" : $EXPECTED_PAYLOAD ,
                                                                                                                                                                                "observed" : $OBSERVED_PAYLOAD
                                                                                                                                                                            }
                                                                                                                                                                    }' >&2
                                                                                                                                                            fi
                                                                                                                                                        elif [[ "$EXPECTED_PAYLOAD_TYPE" == "object" ]]
                                                                                                                                                        then
                                                                                                                                                            EXPECTED_PAYLOAD="$( jq "." "$EXPECTED_PAYLOAD_FILE" )" || exit 121
                                                                                                                                                            STRIPPED_PAYLOAD="$( jq 'del(.["originator-pid"])' <<< "$OBSERVED_PAYLOAD" )" || exit 113
                                                                                                                                                            if [[ "$EXPECTED_TYPE" != "$OBSERVED_TYPE" ]] && [[ "$EXPECTED_CHANNEL" != "$OBSERVED_CHANNEL" ]] && [[ "EXPECTED_PAYLOAD" != "$OBSERVED_PAYLOAD" ]]
                                                                                                                                                            then
                                                                                                                                                                # shellcheck disable=SC2208,SC2016
                                                                                                                                                                echo "$EXPECTED_PAYLOAD_TYPE" jq \
                                                                                                                                                                    --null-input \
                                                                                                                                                                    --arg EXPECTED_CHANNEL "$EXPECTED_CHANNEL" \
                                                                                                                                                                    --argjson EXPECTED_PAYLOAD "$EXPECTED_PAYLOAD" \
                                                                                                                                                                    --arg EXPECTED_TYPE "$EXPECTED_TYPE" \
                                                                                                                                                                    --arg OBSERVED_CHANNEL "$OBSERVED_CHANNEL" \
                                                                                                                                                                    --argjson OBSERVED_PAYLOAD "$STRIPPED_PAYLOAD" \
                                                                                                                                                                    --arg OBSERVED_TYPE "$OBSERVED_TYPE" \
                                                                                                                                                                    '{
                                                                                                                                                                        "type" :
                                                                                                                                                                            {
                                                                                                                                                                                "expected" : $EXPECTED_TYPE ,
                                                                                                                                                                                "observed" : $OBSERVED_TYPE
                                                                                                                                                                            } ,
                                                                                                                                                                        "channel" :
                                                                                                                                                                            {
                                                                                                                                                                                "expected" : $EXPECTED_CHANNEL ,
                                                                                                                                                                                "observed" : $OBSERVED_CHANNEL
                                                                                                                                                                            } ,
                                                                                                                                                                        "payload" :
                                                                                                                                                                            {
                                                                                                                                                                                "expected" : $EXPECTED_PAYLOAD ,
                                                                                                                                                                                "observed" : $OBSERVED_PAYLOAD
                                                                                                                                                                            }
                                                                                                                                                                    }' >&2
                                                                                                                                                                # shellcheck disable=SC2208,SC2016
                                                                                                                                                                jq \
                                                                                                                                                                    --null-input \
                                                                                                                                                                    --arg EXPECTED_CHANNEL "$EXPECTED_CHANNEL" \
                                                                                                                                                                    --argjson EXPECTED_PAYLOAD "$EXPECTED_PAYLOAD" \
                                                                                                                                                                    --arg EXPECTED_TYPE "$EXPECTED_TYPE" \
                                                                                                                                                                    --arg OBSERVED_CHANNEL "$OBSERVED_CHANNEL" \
                                                                                                                                                                    --argjson OBSERVED_PAYLOAD "$STRIPPED_PAYLOAD" \
                                                                                                                                                                    --arg OBSERVED_TYPE "$OBSERVED_TYPE" \
                                                                                                                                                                    '{
                                                                                                                                                                        "type" :
                                                                                                                                                                            {
                                                                                                                                                                                "expected" : $EXPECTED_TYPE ,
                                                                                                                                                                                "observed" : $OBSERVED_TYPE
                                                                                                                                                                            } ,
                                                                                                                                                                        "channel" :
                                                                                                                                                                            {
                                                                                                                                                                                "expected" : $EXPECTED_CHANNEL ,
                                                                                                                                                                                "observed" : $OBSERVED_CHANNEL
                                                                                                                                                                            } ,
                                                                                                                                                                        "payload" :
                                                                                                                                                                            {
                                                                                                                                                                                "expected" : $EXPECTED_PAYLOAD ,
                                                                                                                                                                                "observed" : $OBSERVED_PAYLOAD
                                                                                                                                                                            }
                                                                                                                                                                    }' >&2
                                                                                                                                                            fi
                                                                                                                                                        else
                                                                                                                                                            exit 151
                                                                                                                                                        fi
                                                                                                                                                    '' ;
                                                                                                                                            }
                                                                                                                                    )
                                                                                                                                ] ;
                                                                                                                            text = value ;
                                                                                                                        } ;
                                                                                                                    in "${ application }/bin/command" ;
                                                                                                } text ;
                                                                                        timeout = visitor { int = path : value : builtins.toString value ; } timeout ;
                                                                                        uuid = visitor { null = path : value : builtins.toString index ; string = path : value : value ; } uuid ;
                                                                                    } ;
                                                                            in identity action ;
                                                                post-actions =
                                                                    [
                                                                        { text = ''check-redis-block <&189'' ; }
                                                                        { text = "check-file-empty" ; }
                                                                    ] ;
                                                                pre-actions =
                                                                    [
                                                                        { text = ''echo 1 > "$SCRATCH/invalid-init-channel.json"'' ; }
                                                                        { text = ''check-redis-message subscribe ${ root-parameters.invalid-init-channel } "$SCRATCH/invalid-init-channel.json" number <&189'' ; }
                                                                        { text = ''echo 2 > "$SCRATCH/invalid-release-channel.json"'' ; }
                                                                        { text = ''check-redis-message subscribe ${ root-parameters.invalid-release-channel } "$SCRATCH/invalid-release-channel.json" number <&189'' ; }
                                                                        { text = ''echo 3 > "$SCRATCH/valid-init-channel.json"'' ; }
                                                                        { text = ''check-redis-message subscribe ${ root-parameters.valid-init-channel } "$SCRATCH/valid-init-channel.json" number <&189'' ; }
                                                                        { text = ''echo 4 > "$SCRATCH/valid-release-channel.json"'' ; }
                                                                        { text = ''check-redis-message subscribe ${ root-parameters.valid-release-channel } "$SCRATCH/valid-release-channel.json" number <&189'' ; }
                                                                        { text = ''check-redis-block <&189'' ; uuid = "redis_blocked" ; }
                                                                        { text = "check-file-empty" ; }
                                                                    ] ;
                                                                in builtins.genList generator ( builtins.length _actions ) ;
                                                        nixosTest = visitor { lambda = path : value : value ; } nixosTest ;
                                                    } ;
                                                in
                                                    check-parameters.nixosTest
                                                        {
                                                            name = "check" ;
                                                            nodes = { machine = { ... } : { imports = private ; } ; } ;
                                                            testScript =
                                                                let
                                                                    test =
                                                                        let
                                                                            application =
                                                                                root-parameters.mkDerivation
                                                                                    {
                                                                                        installPhase = ''install "$out"'' ;
                                                                                        name = "test" ;
                                                                                        nativeBuildInputs =
                                                                                            [
                                                                                                (
                                                                                                    writeShellApplication
                                                                                                        {
                                                                                                            name = "install" ;
                                                                                                            runtimeInputs =
                                                                                                                [
                                                                                                                    pkgs.findutils
                                                                                                                    pkgs.gnused
                                                                                                                    pkgs.redis
                                                                                                                ] ;
                                                                                                            text =
                                                                                                                let
                                                                                                                    commands =
                                                                                                                        let
                                                                                                                            mapper =
                                                                                                                                { critical , expected-standard-error , expected-standard-output , expected-status , index , process , text , timeout , uuid } @ primary :
                                                                                                                                    let
                                                                                                                                        application =
                                                                                                                                            root-parameters.writeShellApplication
                                                                                                                                                {
                                                                                                                                                    name = "command" ;
                                                                                                                                                    runtimeInputs = [ root-parameters.coreutils pkgs.diffutils ] ;
                                                                                                                                                    text =
                                                                                                                                                        ''
                                                                                                                                                            export IS_NIX_FLAKE_CHECK=true
                                                                                                                                                            mkdir --parent "$SCRATCH/commands/${ index }/expected"
                                                                                                                                                            echo '${ critical }' > "$SCRATCH/commands/${ index }/critical"
                                                                                                                                                            ln --symbolic ${ expected-standard-error } "$SCRATCH/commands/${ index }/expected/standard-error"
                                                                                                                                                            ln --symbolic ${ expected-standard-output } "$SCRATCH/commands/${ index }/expected/standard-output"
                                                                                                                                                            echo '${ expected-status }' > "$SCRATCH/commands/${ index }/expected/status"
                                                                                                                                                            ln --symbolic ${ process } "$SCRATCH/commands/${ index }/process"
                                                                                                                                                            ln --symbolic ${ text } "$SCRATCH/commands/${ index }/text"
                                                                                                                                                            echo ${ timeout } > "$SCRATCH/commands/${ index }/timeout"
                                                                                                                                                            seq 0 $(( ${ index } - 1 )) | while read -r FLAG
                                                                                                                                                            do
                                                                                                                                                                while [[ ! -f "$SCRATCH/commands/$FLAG/flag" ]]
                                                                                                                                                                do
                                                                                                                                                                    sleep 1
                                                                                                                                                                done
                                                                                                                                                            done
                                                                                                                                                            mkdir --parent "$SCRATCH/commands/${ index }/observed"
                                                                                                                                                            if timeout ${ timeout }s "$SCRATCH/commands/${ index }/text" > "$SCRATCH/commands/${ index }/observed/standard-output" 2> "$SCRATCH/commands/${ index }/observed/standard-error" <&189
                                                                                                                                                            then
                                                                                                                                                                 echo "$?" > "$SCRATCH/commands/${ index }/observed/status"
                                                                                                                                                            else
                                                                                                                                                                 echo "$?" > "$SCRATCH/commands/${ index }/observed/status"
                                                                                                                                                            fi
                                                                                                                                                            touch "$SCRATCH/commands/${ index }/flag"
                                                                                                                                                            if "${ critical }" && ! diff --recursive --report-identical-files "$SCRATCH/commands/${ index }/expected" "$SCRATCH/commands/${ index }/observed"
                                                                                                                                                            then
                                                                                                                                                                echo "${ uuid }" > "$SCRATCH/commands/${ index }/failure"
                                                                                                                                                            fi
                                                                                                                                                        '' ;
                                                                                                                                                } ;
                                                                                                                                            in
                                                                                                                                                ''
                                                                                                                                                    sed -e "s#\$OUT#$OUT#" -e "w$OUT/commands/${ index }" ${ application }/bin/command
                                                                                                                                                    chmod 0555 "$OUT/commands/${ index }"
                                                                                                                                                '' ;
                                                                                                                            in builtins.map mapper check-parameters.actions ;
                                                                                                                    execute =
                                                                                                                        let
                                                                                                                            application =
                                                                                                                                let
                                                                                                                                    grouper = action : builtins.hashString "sha512" ( builtins.toString action.process.string ) ;
                                                                                                                                    mapper = name : value : ''( "$OUT/processes/${ name }" <&189 & )'' ;
                                                                                                                                    in
                                                                                                                                        root-parameters.writeShellApplication
                                                                                                                                            {
                                                                                                                                                name = "execute" ;
                                                                                                                                                runtimeInputs = [ pkgs.coreutils pkgs.redis ] ;
                                                                                                                                                text =
                                                                                                                                                    ''
                                                                                                                                                        export IS_NIX_FLAKE_CHECK=true
                                                                                                                                                        ## if true ; then echo XXXXXXXXXXXXXX && dirname "$0" && exit 10 ; fi
                                                                                                                                                        SCRATCH="$( mktemp --directory )" || exit 198
                                                                                                                                                        ## if true ; then echo XXXXXXXXXXXXXX && dirname "$0" && exit 10 ; fi
                                                                                                                                                        export SCRATCH
                                                                                                                                                        ## if true ; then echo XXXXXXXXXXXXXX && dirname "$0" && exit 10 ; fi
                                                                                                                                                        sleep 10
                                                                                                                                                        # if true ; then echo XXXXXXXXXXXXXX && dirname "$0" && exit 10 ; fi
                                                                                                                                                        # redis-server --port 14012 &
                                                                                                                                                        # if true ; then echo XXXXXXXXXXXXXX && dirname "$0" && exit 10 ; fi
                                                                                                                                                        sleep 1s
                                                                                                                                                        # if true ; then echo XXXXXXXXXXXXXX && dirname "$0" && exit 10 ; fi
                                                                                                                                                        exec 189< <( redis-cli SUBSCRIBE ${ root-parameters.invalid-init-channel } ${ root-parameters.invalid-release-channel } ${ root-parameters.valid-init-channel } ${ root-parameters.valid-release-channel } )
                                                                                                                                                        # if true ; then echo XXXXXXXXXXXXXX && dirname "$0" && exit 10 ; fi
                                                                                                                                                        ${ builtins.concatStringsSep "\n" ( builtins.attrValues ( builtins.mapAttrs mapper ( builtins.groupBy grouper check-parameters.actions ) ) ) }
                                                                                                                                                        # if true ; then echo XXXXXXXXXXXXXX && dirname "$0" && exit 10 ; fi
                                                                                                                                                        while [[ ! -f "$SCRATCH/commands/${ builtins.toString ( ( builtins.length commands ) - 1 ) }/flag" ]]
                                                                                                                                                        do
                                                                                                                                                            sleep 1s
                                                                                                                                                        done
                                                                                                                                                        # if true ; then echo XXXXXXXXXXXXXX && dirname "$0" && exit 10 ; fi
                                                                                                                                                        echo 0 > "$SCRATCH/status"
                                                                                                                                                        find "$SCRATCH/commands" -mindepth 2 -maxdepth 2 -name failure | sort | while read -r FAILURE
                                                                                                                                                        do
                                                                                                                                                            REASON="$( cat "$FAILURE" )" || exit 192
                                                                                                                                                            echo "FAILURE:  $REASON" >&2
                                                                                                                                                            echo 119 > "$SCRATCH/status"
                                                                                                                                                        done
                                                                                                                                                        # if true ; then echo XXXXXXXXXXXXXX && dirname "$0" && exit 11 ; fi
                                                                                                                                                        STATUS="$( cat "$SCRATCH/status" )" || exit 114
                                                                                                                                                        echo STATUS="$STATUS"
                                                                                                                                                        # if true ; then echo XXXXXXXXXXXXXX && dirname "$0" && exit 11 ; fi
                                                                                                                                                        echo OUT="$OUT"
                                                                                                                                                        # if true ; then echo XXXXXXXXXXXXXX && dirname "$0" && exit 11 ; fi
                                                                                                                                                        echo SCRATCH="$SCRATCH"
                                                                                                                                                        # if true ; then echo XXXXXXXXXXXXXX && dirname "$0" && exit 11 ; fi
                                                                                                                                                        exit "$STATUS"
                                                                                                                                                    '' ;
                                                                                                                                            } ;
                                                                                                                            in "${ application }/bin/execute" ;
                                                                                                                    processes =
                                                                                                                        let
                                                                                                                            grouper = action : builtins.hashString "sha512" ( builtins.toString action.proces.string  ) ;
                                                                                                                            mapper =
                                                                                                                                name : value :
                                                                                                                                    let
                                                                                                                                        application =
                                                                                                                                            root-parameters.writeShellApplication
                                                                                                                                                {
                                                                                                                                                    name = "process" ;
                                                                                                                                                    text = builtins.concatStringsSep "\n" ( builtins.map ( v : ''"$OUT/commands/${ v.index}" <&189'' ) value ) ;
                                                                                                                                                } ;
                                                                                                                                            in
                                                                                                                                                ''
                                                                                                                                                    sed -e "s#\$OUT#$OUT#" -e w$OUT/processes/${ name } ${ application }/bin/process
                                                                                                                                                    chmod 0555 "$OUT"/processes/${ name }
                                                                                                                                                '' ;
                                                                                                                            in builtins.attrValues ( builtins.mapAttrs mapper ( builtins.groupBy grouper check-parameters.actions ) ) ;
                                                                                                                    test =
                                                                                                                        let
                                                                                                                            application =
                                                                                                                                writeShellApplication
                                                                                                                                    {
                                                                                                                                        name = "test" ;
                                                                                                                                        runtimeInputs = [ root-parameters.coreutils ] ;
                                                                                                                                        text =
                                                                                                                                            ''
                                                                                                                                                DERIVATION="$( dirname "$0" )" || exit 145
                                                                                                                                                echo The test derivation is in "$DERIVATION" >&2
                                                                                                                                                STATUS="$( cat "$DERIVATION/status" )" || exit 199
                                                                                                                                                exit "$STATUS"
                                                                                                                                            '' ;
                                                                                                                                    } ;
                                                                                                                                in "${ application }/bin/test" ;
                                                                                                                    in
                                                                                                                        ''
                                                                                                                            export OUT="$1"
                                                                                                                            export SCRATCH="$OUT"
                                                                                                                            mkdir --parents "$OUT/commands"
                                                                                                                            ${ builtins.concatStringsSep "\n" commands }
                                                                                                                            sed -e "s#\$OUT#$OUT#" -e "w$OUT/execute.sh" ${ execute }
                                                                                                                            chmod 0555 "$OUT/execute.sh"
                                                                                                                            mkdir --parents "$OUT/processes"
                                                                                                                            ${ builtins.concatStringsSep "\n" processes }
                                                                                                                        '' ;
                                                                                                        }
                                                                                                )
                                                                                            ] ;
                                                                                        src = ./. ;
                                                                                    } ;
                                                                            in "${ application }/execute.sh" ;
                                                                    github =
                                                                        let
                                                                            application =
                                                                                pkgs.writeShellApplication
                                                                                    {
                                                                                        name = "github" ;
                                                                                        runtimeInputs = [ pkgs.coreutils ] ;
                                                                                        text =
                                                                                            ''
                                                                                                echo 1723258852938545 8227226241357269 >&2
                                                                                                ifconfig >&2
                                                                                                echo 1723258852938545 2599363965377888 >&2
                                                                                            '' ;
                                                                                    } ;
                                                                        in "${ application }/bin/github" ;
                                                                    in
                                                                        ''
                                                                            machine.wait_for_unit("multi-user.target")
                                                                            machine.wait_for_unit("network-online.target")
                                                                            machine.wait_for_unit("redis.service")
                                                                            machine.succeed("runuser --login ${ user } -- ${ test }")
                                                                       '' ;
                                                        } ;
                                    implementation = implementation ;
                                } ;
            } ;
}
