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
		                mkDerivation ,
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
                                                                                                                    redis-cli PUBLISH "$CHANNEL" "$JSON" > /output 2> /private/standard-error
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
                                                                        echo 'echo 1723258852938545 1369941427493491 9243859694285328 >&2' >> /tmp/DEBUG
                                                                        mkdir --parents ${ resources-directory }/locks
                                                                        exec 143> ${ resources-directory }/locks/log
                                                                        flock -x 143
                                                                        mkdir --parents ${ resources-directory }/log.yaml
                                                                        echo 'echo 1723258852938545 1369941427493491 6923885942444861 >&2' >> /tmp/DEBUG
                                                                        log
                                                                        echo "echo 1723258852938545 1369941427493491 1444874378897782 2761697721844579 SUBSCRIBERS=$( cat "$OUTPUT" ) >&2" >> /tmp/DEBUG
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
                                        release =
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
                                                                                                                    echo 1723258852938545 5652429811295145 _ >> /tmp/DEBUG
                                                                                                                    read -r TYPE || break
                                                                                                                    echo 1723258852938545 5669691277932618 "$TYPE" _ >> /tmp/DEBUG
                                                                                                                    read -r CHANNEL || break
                                                                                                                    read -r PAYLOAD || break
                                                                                                                    if [[ "$TYPE" == "message" ]] && [[ "${ root-parameters.valid-init-channel }" == "$CHANNEL" ]]
                                                                                                                    then
                                                                                                                        INDEX="$( jq --raw-output ".index" <<< "$PAYLOAD" )" || break
                                                                                                                        if [[ -L "/release/$INDEX" ]]
                                                                                                                        then
                                                                                                                            "/release/$INDEX" &
                                                                                                                        fi
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
                                                                    mkdir --parents ${ resources-directory }/release
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
                                                                        mkdir --parents ${ resources-directory }/locks
                                                                        exec 157> ${ resources-directory }/locks/clean
                                                                        flock -s 157
                                                                        INPUT_FILE="$( mktemp --suffix ".json" )" || exit 199
                                                                        export INPUT_FILE
                                                                        export TEMPORARY=${ builtins.toJSON resource-parameters.temporary }
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
                                                                        OUTPUT_FILE="$( mktemp --suffix ".json" )" || exit 101
                                                                        export OUTPUT_FILE
                                                                        mkdir --parents ${ gc-roots-directory }
                                                                        mkdir --parents ${ resources-directory }
                                                                        init
                                                                        CHANNEL="$( jq --raw-output ".channel" "$OUTPUT_FILE" )" || exit 181
                                                                        export CHANNEL
                                                                        INDEX="$( jq --raw-output ".index" "$OUTPUT_FILE" )" || exit 198
                                                                        EVALUATION="$( jq --raw-output ".evaluation" "$OUTPUT_FILE" )" || exit 183
                                                                        STANDARD_ERROR="$( jq --raw-output '.["standard-error"]' "$OUTPUT_FILE" )" || exit 126
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
                                                                                }' \
                                                                                "$OUTPUT_FILE" | log
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
                                                                                                                                                        EXPECTED_TARGETS="$( jq --null-input '${ builtins.toJSON resource-parameters.targets }' )" || exit 167
                                                                                                                                                        OBSERVED_TARGETS="$( LC_ALL=C find /mount -mindepth 1 -maxdepth 1 -exec basename {} \; | sort | jq -R "." | jq -s "." )" || exit 111
                                                                                                                                                        ORIGINATOR_PID="$( jq --raw-output '.["originator-pid"]' /input )" || exit 156
                                                                                                                                                        if [[ 0 == "$STATUS" ]] && [[ ! -s /private/standard-error ]] && [[ "$EXPECTED_TARGETS" == "$OBSERVED_TARGETS" ]]
                                                                                                                                                        then
                                                                                                                                                            echo "$ORIGINATOR_PID" > "/pid/$ORIGINATOR_PID"
                                                                                                                                                            jq \
                                                                                                                                                                --arg CHANNEL ${ resource-parameters.init.valid-channel } \
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
                                                                                                                                                                    "evaluation" : 0 ,
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
                                                                                                                                                                }' \
                                                                                                                                                                "$INPUT_FILE" > "$OUTPUT_FILE"
                                                                                                                                                        else
                                                                                                                                                            jq \
                                                                                                                                                                --arg INDEX "$INDEX" \
                                                                                                                                                                --arg CHANNEL ${ resource-parameters.init.invalid-channel } \
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
                                                                                                                                                                    "evaluation" : ${ resource-parameters.error } ,
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
                                                                                                                                                                echo 'echo 1723258852938545 1369941427493491 6544957497586942 >&2' >> /tmp/DEBUG
                                                                                                                                                                INDEX="$( jq --raw-output ".index" /input )" || exit 109
                                                                                                                                                                find /gc-roots -mindepth 1 -maxdepth 1 -name "$INDEX" -print0 | tar --null --files-from - --create --file /temporary/gc-roots.tar.xz --xz
                                                                                                                                                                find /resources -mindepth 2 -maxdepth 2 -name "$INDEX" -print0 -exec rm --recursive --force {} \;
                                                                                                                                                                find /gc-roots -mindepth 1 -maxdepth 1 -name "$INDEX" -print0 | tar --null --files-from - --create --file /temporary/gc-roots.tar.xz --xz
                                                                                                                                                                find /resources -mindepth 2 -maxdepth 2 -name "$INDEX" -print0 -exec rm --recursive --force {} \;
                                                                                                                                                                CHANNEL="$( jq --raw-output ".channel" /input )" || exit 134
                                                                                                                                                                export CHANNEL
                                                                                                                                                                STANDARD_ERROR="$( jq --raw-output '.["standard-error"]' /input )" || exit 192
                                                                                                                                                                STATUS="$( jq --raw-output ".status" /input )" || exit 112
                                                                                                                                                                echo 'echo 1723258852938545 1369941427493491 6718441988739488 >&2' >> /tmp/DEBUG
                                                                                                                                                                if [[ "$STATUS" == 0 ]] && [[ -z "$STANDARD_ERROR" ]]
                                                                                                                                                                then
                                                                                                                                                                    export CHANNEL=${ resource-parameters.release.valid-channel }
                                                                                                                                                                    echo 'echo 1723258852938545 1369941427493491 1146455332163843 >&2' >> /tmp/DEBUG
                                                                                                                                                                    jq \
                                                                                                                                                                        '{
                                                                                                                                                                            "standard-output" : .["standard-output"] ,
                                                                                                                                                                            "status" : .status
                                                                                                                                                                        }' \
                                                                                                                                                                        /input | log
                                                                                                                                                                echo 'echo 1723258852938545 1369941427493491 2798863357385983 >&2' >> /tmp/DEBUG
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
                                                                                                                        echo 'echo 1723258852938545 1369941427493491 1674717918388568 > &2' >> /tmp/DEBUG
                                                                                                                        tail --follow /dev/null --pid "$PID"
                                                                                                                        echo 'echo 1723258852938545 1369941427493491 7919596753232553 > &2' >> /tmp/DEBUG
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
                                                                                            mkdir --parents "$OUT"
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
                                            invalid-init-channel = to-string invalid-init-channel ;
                                            invalid-release-channel = to-string invalid-release-channel ;
                                            valid-init-channel = to-string valid-init-channel ;
                                            valid-release-channel = to-string valid-release-channel ;
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
                                    check =
                                        {
                                            actions ,
                                            gc-roots-directory ,
                                            pkgs ,
                                            private ,
                                            resources-directory ,
                                            user
                                        } :
                                            pkgs.nixosTest
                                                {
                                                    name = "check" ;
                                                    nodes.machine = { ... } : { imports = private ; } ;
                                                    testScript =
                                                        let
                                                            test =
                                                                let
                                                                    application =
                                                                        pkgs.writeShellApplication
                                                                            {
                                                                                name = "test" ;
                                                                                runtimeInputs =
                                                                                    [
                                                                                        (
                                                                                            pkgs.writeShellApplication
                                                                                                {
                                                                                                    name = "is-subscribed" ;
                                                                                                    runtimeInputs = [ pkgs.coreutils pkgs.redis ] ;
                                                                                                    text =
                                                                                                        ''
                                                                                                            EXPECTED_TYPE="subscribe"
                                                                                                            EXPECTED_CHANNEL="$1"
                                                                                                            EXPECTED_PAYLOAD="$2"
                                                                                                            read -t 1 -r OBSERVED_TYPE <&189 || exit 142
                                                                                                            read -t 1 -r OBSERVED_CHANNEL <&189 || exit 154
                                                                                                            read -t 1 -r OBSERVED_PAYLOAD <&189 || exit 164
                                                                                                            if [[ "$EXPECTED_TYPE" != "$OBSERVED_TYPE" ]]
                                                                                                            then
                                                                                                                echo "OBSERVED_TYPE=$OBSERVED_TYPE" >&2
                                                                                                                exit 136
                                                                                                            fi
                                                                                                            if [[ "$EXPECTED_CHANNEL" != "$OBSERVED_CHANNEL" ]]
                                                                                                            then
                                                                                                                echo "OBSERVED_CHANNEL=$OBSERVED_CHANNEL" >&2
                                                                                                                exit 123
                                                                                                            fi
                                                                                                            if [[ "$EXPECTED_PAYLOAD" != "$OBSERVED_PAYLOAD" ]]
                                                                                                            then
                                                                                                                echo "OBSERVED_PAYLOAD=$OBSERVED_PAYLOAD" >&2
                                                                                                                exit 162
                                                                                                            fi
                                                                                                        '' ;
                                                                                                }
                                                                                        )
                                                                                        pkgs.coreutils
                                                                                        pkgs.jq
                                                                                        pkgs.redis
                                                                                        pkgs.yq-go
                                                                                    ] ;
                                                                                text =
                                                                                    let
                                                                                        _actions =
                                                                                            let
                                                                                                generator =
                                                                                                    index :
                                                                                                        let
                                                                                                            defaults =
                                                                                                                {
                                                                                                                    accepts-redirect = true ;
                                                                                                                    expected-standard-output = "" ;
                                                                                                                    expected-status = 0 ;
                                                                                                                    index = index ;
                                                                                                                    process = "main" ;
                                                                                                                    timeout = 60 ;
                                                                                                                } ;
                                                                                                            main =  builtins.elemAt list index ;
                                                                                                            in defaults // main ;
                                                                                                list =
                                                                                                    builtins.concatLists
                                                                                                        [
                                                                                                            [
                                                                                                                { text = "check-is-blocked 1 2745375537866399" ; }
                                                                                                                { text = "check-file-integrity 9287791874713682 cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e" ; }
                                                                                                            ]
                                                                                                            actions
                                                                                                            [
                                                                                                                { text = "check-is-blocked 1 5572814436683922" ; }
                                                                                                                { text = "check-file-integrity 8592338626733518 cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e" ; }
                                                                                                            ]
                                                                                                        ] ;
                                                                                                in builtins.genList generator ( builtins.length list ) ;
                                                                                        commands =
                                                                                            let
                                                                                                generator =
                                                                                                    index :
                                                                                                        let
                                                                                                            action = builtins.elemAt _actions index ;
                                                                                                            command =
                                                                                                                let
                                                                                                                    application =
                                                                                                                        pkgs.writeShellApplication
                                                                                                                            {
                                                                                                                                name = "command" ;
                                                                                                                                runtimeInputs =
                                                                                                                                    [
                                                                                                                                        jq
                                                                                                                                        (
                                                                                                                                            pkgs.writeShellApplication
                                                                                                                                                {
                                                                                                                                                    name = "check-redis-valid-init" ;
                                                                                                                                                    runtimeInputs = [ pkgs.coreutils pkgs.diffutils pkgs.jq ] ;
                                                                                                                                                    text =
                                                                                                                                                        ''
                                                                                                                                                            while [[ "$#" -gt 0 ]]
                                                                                                                                                            do
                                                                                                                                                                case "$1" in
                                                                                                                                                                    --uuid)
                                                                                                                                                                        shift 2
                                                                                                                                                                        ;;
                                                                                                                                                                    *)
                                                                                                                                                                        exit 129
                                                                                                                                                                        ;;
                                                                                                                                                                esac
                                                                                                                                                            done
                                                                                                                                                            read -r -u 189 TYPE
                                                                                                                                                            read -r -u 189 CHANNEL
                                                                                                                                                            read -r -u 189 PAYLOAD
                                                                                                                                                            if [[ "message" != "$TYPE" ]]
                                                                                                                                                            then
                                                                                                                                                                exit 102
                                                                                                                                                            fi
                                                                                                                                                            if [[ "valid-init" != "$CHANNEL" ]]
                                                                                                                                                            then
                                                                                                                                                                exit 173
                                                                                                                                                            fi
                                                                                                                                                            EXPECTED_PAYLOAD="$( jq --compact-output '.' )" || exit 186
                                                                                                                                                            OBSERVED_PAYLOAD="$( jq --compact-output 'del(.["originator-pid"])' <<< "$PAYLOAD" )" || exit 127
                                                                                                                                                            if [[ "$EXPECTED_PAYLOAD" != "$OBSERVED_PAYLOAD" ]]
                                                                                                                                                            then
                                                                                                                                                                cat >> "$COMMANDS/FLAG" <<EOF
                                                                                                                                                                DIFF:
                                                                                                                                                                $( diff --unified <( yq eval --prettyPrint "." <<< "$EXPECTED_PAYLOAD" ) <( yq eval --prettyPrint "." <<< "$OBSERVED_PAYLOAD" ) || true )


                                                                                                                                                                EXPECTED:
                                                                                                                                                                $( yq eval --prettyPrint "." <<< "$EXPECTED_PAYLOAD" )


                                                                                                                                                                OBSERVED:
                                                                                                                                                                $( yq eval --prettyPrint "." <<< "$OBSERVED_PAYLOAD" )
                                                                                                                                                            EOF
                                                                                                                                                                exit 172
                                                                                                                                                            fi
                                                                                                                                                        '' ;
                                                                                                                                                }
                                                                                                                                        )
                                                                                                                                        (
                                                                                                                                            pkgs.writeShellApplication
                                                                                                                                                {
                                                                                                                                                    name = "check-file-integrity" ;
                                                                                                                                                    runtimeInputs = [ pkgs.coreutils pkgs.findutils pkgs.jq pkgs.yq-go ] ;
                                                                                                                                                    text =
                                                                                                                                                        ''
                                                                                                                                                            UUID="$1"
                                                                                                                                                            EXPECTED_HASH="$2"
                                                                                                                                                            ROOT="$( mktemp --directory )" || exit 128
                                                                                                                                                            if [[ -d ${ resources-directory } ]]
                                                                                                                                                            then
                                                                                                                                                                cp --recursive ${ resources-directory } "$ROOT/resources"
                                                                                                                                                            fi
                                                                                                                                                            if [[ -d ${ gc-roots-directory } ]]
                                                                                                                                                            then
                                                                                                                                                                cp --recursive ${ gc-roots-directory } "$ROOT/roots"
                                                                                                                                                            fi
                                                                                                                                                            YAML_FILE="$( mktemp )" || exit 167
                                                                                                                                                            cd "$ROOT"
                                                                                                                                                            find . \( -path './resources/pids' -o -path './resources/temporary' \) -prune -o -type f -print | sort | while IFS= read -r FILE
                                                                                                                                                            do
                                                                                                                                                                jq \
                                                                                                                                                                    --null-input \
                                                                                                                                                                    --arg NAME "$FILE" \
                                                                                                                                                                    --rawfile CONTENTS "$FILE" \
                                                                                                                                                                    '{
                                                                                                                                                                        "name": $NAME ,
                                                                                                                                                                        "contents": $CONTENTS
                                                                                                                                                                    }' | yq eval --prettyPrint '[.]'
                                                                                                                                                            done >> "$YAML_FILE"
                                                                                                                                                            OBSERVED_HASH="$( sha512sum "$YAML_FILE" | cut --characters 1-128 )" || exit 176
                                                                                                                                                            if [[ "$EXPECTED_HASH" != "$OBSERVED_HASH" ]]
                                                                                                                                                            then
                                                                                                                                                                jq \
                                                                                                                                                                    --null-input \
                                                                                                                                                                    --arg EXPECTED_HASH "$EXPECTED_HASH" \
                                                                                                                                                                    --arg OBSERVED_HASH "$OBSERVED_HASH" \
                                                                                                                                                                    --arg UUID "$UUID" \
                                                                                                                                                                    --rawfile YAML "$YAML_FILE" \
                                                                                                                                                                    '{
                                                                                                                                                                        "hash" :
                                                                                                                                                                            {
                                                                                                                                                                                "expected" : $EXPECTED_HASH ,
                                                                                                                                                                                "observed" : $OBSERVED_HASH
                                                                                                                                                                            } ,
                                                                                                                                                                        "uuid" : $UUID ,
                                                                                                                                                                        "yaml" : $YAML
                                                                                                                                                                    }' | yq eval --prettyPrint "[.]" >> "$COMMANDS/FLAG"
                                                                                                                                                                exit 101
                                                                                                                                                            fi
                                                                                                                                                        '' ;
                                                                                                                                                }
                                                                                                                                        )
                                                                                                                                        (
                                                                                                                                            pkgs.writeShellApplication
                                                                                                                                                {
                                                                                                                                                    name = "check-is-blocked" ;
                                                                                                                                                    runtimeInputs = [ pkgs.coreutils ] ;
                                                                                                                                                    text =
                                                                                                                                                        ''
                                                                                                                                                            TIMEOUT="$1"
                                                                                                                                                            UUID="$2"
                                                                                                                                                            if read -t "$TIMEOUT" -r TYPE <&189
                                                                                                                                                            then
                                                                                                                                                                read -t "$TIMEOUT" -r CHANNEL <&189
                                                                                                                                                                read -t "$TIMEOUT" -r PAYLOAD <&189
                                                                                                                                                                echo "$UUID" >&2
                                                                                                                                                                echo "$TYPE" >&2
                                                                                                                                                                echo "$CHANNEL" >&2
                                                                                                                                                                echo "$PAYLOAD" >&2
                                                                                                                                                                exit 179
                                                                                                                                                            fi
                                                                                                                                                        '' ;
                                                                                                                                                }
                                                                                                                                        )
                                                                                                                                        (
                                                                                                                                            pkgs.writeShellApplication
                                                                                                                                                {
                                                                                                                                                    name = "check-verify-executable" ;
                                                                                                                                                    runtimeInputs = [ ] ;
                                                                                                                                                    text =
                                                                                                                                                        ''
                                                                                                                                                            EXECUTABLE="$1"
                                                                                                                                                            UUID="$2"
                                                                                                                                                            if [[ ! -x "$EXECUTABLE" ]]
                                                                                                                                                            then
                                                                                                                                                                echo "UUID=$UUID" "EXECUTABLE=$EXECUTABLE" >&2
                                                                                                                                                                exit 137
                                                                                                                                                            fi
                                                                                                                                                        '' ;
                                                                                                                                                }
                                                                                                                                        )
                                                                                                                                        (
                                                                                                                                            pkgs.writeShellApplication
                                                                                                                                                {
                                                                                                                                                    name = "is-subscribed" ;
                                                                                                                                                    runtimeInputs = [ pkgs.coreutils pkgs.redis ] ;
                                                                                                                                                    text =
                                                                                                                                                        ''
                                                                                                                                                        '' ;
                                                                                                                                                }
                                                                                                                                        )
                                                                                                                                    ] ;
                                                                                                                                text =
                                                                                                                                    ''
                                                                                                                                        export COMMAND_PID="$$"
                                                                                                                                        seq 0 ${ builtins.toString ( index - 1 ) } | while read -r INDEX
                                                                                                                                        do
                                                                                                                                            while [[ ! -f "$COMMANDS/$INDEX.json" ]]
                                                                                                                                            do
                                                                                                                                                sleep 1
                                                                                                                                            done
                                                                                                                                            FLAG="$( jq --raw-output ".flag" "$COMMANDS/$INDEX.json" )" || exit 182
                                                                                                                                            if "$FLAG"
                                                                                                                                            then
                                                                                                                                                jq "." "$COMMANDS/$INDEX.json" >&2
                                                                                                                                            fi
                                                                                                                                        done
                                                                                                                                        if [[ ! -f "$COMMANDS/FLAG" ]]
                                                                                                                                        then
                                                                                                                                            BEFORE="$( date )" || exit 137
                                                                                                                                            ACCEPTS_REDIRECT="${ builtins.toJSON action.accepts-redirect }"
                                                                                                                                            STANDARD_ERROR_FILE="$( mktemp )" || exit 154
                                                                                                                                            STANDARD_OUTPUT_FILE="$( mktemp )" || exit 130
                                                                                                                                            if "$ACCEPTS_REDIRECT"
                                                                                                                                            then
                                                                                                                                                if time timeout ${ builtins.toString action.timeout }s ${ pkgs.writeShellApplication { name = "text" ; text = builtins.toString action.text ; } }/bin/text > "$STANDARD_OUTPUT_FILE" 2> "$STANDARD_ERROR_FILE"
                                                                                                                                                then
                                                                                                                                                    OBSERVED_STATUS="$?"
                                                                                                                                                else
                                                                                                                                                    OBSERVED_STATUS="$?"
                                                                                                                                                fi
                                                                                                                                            else
                                                                                                                                                if time timeout ${ builtins.toString action.timeout }s ${ pkgs.writeShellApplication { name = "text" ; text = builtins.toString action.text ; } }/bin/text > "$STANDARD_OUTPUT_FILE" 2> "$STANDARD_ERROR_FILE"
                                                                                                                                                then
                                                                                                                                                    OBSERVED_STATUS="$?"
                                                                                                                                                else
                                                                                                                                                    OBSERVED_STATUS="$?"
                                                                                                                                                fi
                                                                                                                                            fi
                                                                                                                                            rm "$COMMANDS/${ builtins.toString index }"
                                                                                                                                            FLAG=false
                                                                                                                                            FLAG_STANDARD_ERROR=false
                                                                                                                                            if [[ -s "$STANDARD_ERROR_FILE" ]]
                                                                                                                                            then
                                                                                                                                                FLAG=true
                                                                                                                                                FLAG_STANDARD_ERROR=true
                                                                                                                                            fi
                                                                                                                                            FLAG_STANDARD_OUTPUT=false
                                                                                                                                            OBSERVED_STANDARD_OUTPUT="$( cat "$STANDARD_OUTPUT_FILE" )" || exit 120
                                                                                                                                            if [[ '${ builtins.toString action.expected-standard-output }' != "$OBSERVED_STANDARD_OUTPUT" ]]
                                                                                                                                            then
                                                                                                                                                FLAG=true
                                                                                                                                                FLAG_STANDARD_OUTPUT=true
                                                                                                                                            fi
                                                                                                                                            FLAG_STATUS=false
                                                                                                                                            if [[ "$OBSERVED_STATUS" == 124 ]]
                                                                                                                                            then
                                                                                                                                                FLAG=true
                                                                                                                                                FLAG_STATUS=true
                                                                                                                                            elif [[ '${ builtins.toString action.expected-status }' != "$OBSERVED_STATUS" ]]
                                                                                                                                            then
                                                                                                                                                FLAG=true
                                                                                                                                                FLAG_STATUS=true
                                                                                                                                            fi
                                                                                                                                            AFTER="$( date )" || exit 110
                                                                                                                                            if [[ "$FLAG" == "true" ]]
                                                                                                                                            then
                                                                                                                                            jq \
                                                                                                                                                --null-input \
                                                                                                                                                --argjson ACCEPTS_REDIRECT "$ACCEPTS_REDIRECT" \
                                                                                                                                                --arg AFTER "$AFTER" \
                                                                                                                                                --arg BEFORE "$BEFORE" \
                                                                                                                                                --arg EXPECTED_STANDARD_ERROR "" \
                                                                                                                                                --rawfile EXPECTED_STANDARD_OUTPUT '${ builtins.toFile "standard-output" ( builtins.toString action.expected-standard-output ) }' \
                                                                                                                                                --argjson EXPECTED_STATUS ${ builtins.toString action.expected-status } \
                                                                                                                                                --arg FLAG "$FLAG" \
                                                                                                                                                --argjson FLAG_STANDARD_ERROR "$FLAG_STANDARD_ERROR" \
                                                                                                                                                --argjson FLAG_STANDARD_OUTPUT "$FLAG_STANDARD_OUTPUT" \
                                                                                                                                                --argjson FLAG_STATUS "$FLAG_STATUS" \
                                                                                                                                                --rawfile PROCESS ${ builtins.toFile "process" ( builtins.toString action.process ) } \
                                                                                                                                                --rawfile OBSERVED_STANDARD_ERROR "$STANDARD_ERROR_FILE" \
                                                                                                                                                --rawfile OBSERVED_STANDARD_OUTPUT "$STANDARD_OUTPUT_FILE" \
                                                                                                                                                --argjson OBSERVED_STATUS "$OBSERVED_STATUS" \
                                                                                                                                                --rawfile TEXT ${ builtins.toFile "text" ( builtins.toString action.text ) } \
                                                                                                                                                --argjson TIMEOUT ${ builtins.toString action.timeout } \
                                                                                                                                                '{
                                                                                                                                                    "accepts-redirect" : $ACCEPTS_REDIRECT ,
                                                                                                                                                    "flag" : $FLAG ,
                                                                                                                                                    "process" : $PROCESS ,
                                                                                                                                                    "stamps" :
                                                                                                                                                        {
                                                                                                                                                            "after" : $AFTER ,
                                                                                                                                                            "before" : $BEFORE
                                                                                                                                                        } ,
                                                                                                                                                    "standard-error" :
                                                                                                                                                        {
                                                                                                                                                            "expected" : $EXPECTED_STANDARD_ERROR ,
                                                                                                                                                            "flag": $FLAG_STANDARD_ERROR ,
                                                                                                                                                            "observed" : $OBSERVED_STANDARD_ERROR
                                                                                                                                                        } ,
                                                                                                                                                    "standard-output" :
                                                                                                                                                        {
                                                                                                                                                            "expected" : $EXPECTED_STANDARD_OUTPUT ,
                                                                                                                                                            "flag" : $FLAG_STANDARD_OUTPUT ,
                                                                                                                                                            "observed" : $OBSERVED_STANDARD_OUTPUT
                                                                                                                                                        } ,
                                                                                                                                                    "status" :
                                                                                                                                                        {
                                                                                                                                                            "expected" : $EXPECTED_STATUS ,
                                                                                                                                                            "flag" : $FLAG_STATUS ,
                                                                                                                                                            "observed" : $OBSERVED_STATUS
                                                                                                                                                        } ,
                                                                                                                                                    "text" : $TEXT ,
                                                                                                                                                    "timeout" : $TIMEOUT
                                                                                                                                                }' >> "$COMMANDS/FLAG"
                                                                                                                                            fi
                                                                                                                                            jq \
                                                                                                                                                --null-input \
                                                                                                                                                --argjson ACCEPTS_REDIRECT "$ACCEPTS_REDIRECT" \
                                                                                                                                                --arg AFTER "$AFTER" \
                                                                                                                                                --arg BEFORE "$BEFORE" \
                                                                                                                                                --arg EXPECTED_STANDARD_ERROR "" \
                                                                                                                                                --rawfile EXPECTED_STANDARD_OUTPUT '${ builtins.toFile "standard-output" ( builtins.toString action.expected-standard-output ) }' \
                                                                                                                                                --argjson EXPECTED_STATUS ${ builtins.toString action.expected-status } \
                                                                                                                                                --arg FLAG "$FLAG" \
                                                                                                                                                --argjson FLAG_STANDARD_ERROR "$FLAG_STANDARD_ERROR" \
                                                                                                                                                --argjson FLAG_STANDARD_OUTPUT "$FLAG_STANDARD_OUTPUT" \
                                                                                                                                                --argjson FLAG_STATUS "$FLAG_STATUS" \
                                                                                                                                                --rawfile PROCESS ${ builtins.toFile "process" ( builtins.toString action.process ) } \
                                                                                                                                                --rawfile OBSERVED_STANDARD_ERROR "$STANDARD_ERROR_FILE" \
                                                                                                                                                --rawfile OBSERVED_STANDARD_OUTPUT "$STANDARD_OUTPUT_FILE" \
                                                                                                                                                --argjson OBSERVED_STATUS "$OBSERVED_STATUS" \
                                                                                                                                                --rawfile TEXT ${ builtins.toFile "text" ( builtins.toString action.text ) } \
                                                                                                                                                --argjson TIMEOUT ${ builtins.toString action.timeout } \
                                                                                                                                                '{
                                                                                                                                                    "accepts-redirect" : $ACCEPTS_REDIRECT ,
                                                                                                                                                    "flag" : $FLAG ,
                                                                                                                                                    "process" : $PROCESS ,
                                                                                                                                                    "stamps" :
                                                                                                                                                        {
                                                                                                                                                            "after" : $AFTER ,
                                                                                                                                                            "before" : $BEFORE
                                                                                                                                                        } ,
                                                                                                                                                    "standard-error" :
                                                                                                                                                        {
                                                                                                                                                            "expected" : $EXPECTED_STANDARD_ERROR ,
                                                                                                                                                            "flag": $FLAG_STANDARD_ERROR ,
                                                                                                                                                            "observed" : $OBSERVED_STANDARD_ERROR
                                                                                                                                                        } ,
                                                                                                                                                    "standard-output" :
                                                                                                                                                        {
                                                                                                                                                            "expected" : $EXPECTED_STANDARD_OUTPUT ,
                                                                                                                                                            "flag" : $FLAG_STANDARD_OUTPUT ,
                                                                                                                                                            "observed" : $OBSERVED_STANDARD_OUTPUT
                                                                                                                                                        } ,
                                                                                                                                                    "status" :
                                                                                                                                                        {
                                                                                                                                                            "expected" : $EXPECTED_STATUS ,
                                                                                                                                                            "flag" : $FLAG_STATUS ,
                                                                                                                                                            "observed" : $OBSERVED_STATUS
                                                                                                                                                        } ,
                                                                                                                                                    "text" : $TEXT ,
                                                                                                                                                    "timeout" : $TIMEOUT
                                                                                                                                                }' > "$COMMANDS/${ builtins.toString index }.json"
                                                                                                                                        else
                                                                                                                                            jq \
                                                                                                                                                --null-input \
                                                                                                                                                --argjson FLAG true \
                                                                                                                                                '{
                                                                                                                                                    "flag" : $FLAG
                                                                                                                                                }' > "$COMMANDS/${ builtins.toString index }.json"
                                                                                                                                        fi
                                                                                                                                    '' ;
                                                                                                                            } ;
                                                                                                                    in "${ application }/bin/command" ;
                                                                                                            in ''ln --symbolic ${ command } "$COMMANDS/${ builtins.toString index }"'' ;
                                                                                                in builtins.genList generator ( builtins.length _actions ) ;
                                                                                        processes =
                                                                                            let
                                                                                                grouper = action : action.process ;
                                                                                                mapper =
                                                                                                    name : value :
                                                                                                        let
                                                                                                            mapper = { accepts-redirect , expected-standard-output , expected-status , index , process , text , timeout } : ''"$COMMANDS/${ builtins.toString index }"'' ;
                                                                                                            in
                                                                                                                ''
                                                                                                                    (
                                                                                                                        true ${ name }
                                                                                                                        # shellcheck disable=SC2030,SC2031
                                                                                                                        export PROCESS_PID="$$"
                                                                                                                        ${ builtins.concatStringsSep "\n\t" ( builtins.map mapper value ) }
                                                                                                                    ) &
                                                                                                                '' ;
                                                                                                in builtins.attrValues ( builtins.mapAttrs mapper ( builtins.groupBy grouper _actions ) ) ;
                                                                                        in
                                                                                            ''
                                                                                                COMMANDS="$( mktemp --directory )" || exit 188
                                                                                                export COMMANDS
                                                                                                exec 189< <( redis-cli SUBSCRIBE valid-init valid-release invalid-init invalid-release )
                                                                                                is-subscribed valid-init 1 <&189
                                                                                                is-subscribed valid-release 2 <&189
                                                                                                is-subscribed invalid-init 3 <&189
                                                                                                is-subscribed invalid-release 4 <&189
                                                                                                ${ builtins.concatStringsSep "\n" commands }
                                                                                                ${ builtins.concatStringsSep "\n" processes }
                                                                                                while [[ ! -f "$COMMANDS/${ builtins.toString ( ( builtins.length _actions ) - 1 ) }.json" ]]
                                                                                                do
                                                                                                    sleep 1
                                                                                                done
                                                                                                if [[ -f "$COMMANDS/FLAG" ]]
                                                                                                then
                                                                                                    echo FLAG >&2
                                                                                                    cat "$COMMANDS/FLAG" >&2
#                                                                                                    find "$COMMANDS" -type f -name "*.json" | sort | while read -r FILE
#                                                                                                    do
#                                                                                                        echo >&2
#                                                                                                        echo "FLAG:  $FILE" >&2
#                                                                                                        cat "$FILE" >&2
#                                                                                                    done
                                                                                                    exit 107
                                                                                                fi
                                                                                            '' ;
                                                                            } ;
                                                                        in "${ application }/bin/test" ;
                                                            in
                                                                ''
                                                                    machine.wait_for_unit("multi-user.target")
                                                                    machine.wait_for_unit("network-online.target")
                                                                    machine.succeed("runuser --login ${ user } -- ${ test }")
                                                                '' ;
                                                } ;
                                    implementation = implementation ;
                                } ;
            } ;
}
