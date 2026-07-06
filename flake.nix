# 4234654894679556
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
                                                                                                        runtimeInputs = [ pkgs.findutils pkgs.gnutar pkgs.xz ] ;
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
                                                                                                                PROBLEMS="$( find /resources/release /resources/invalid-init /resources/invalid-release )" || exit 127
                                                                                                                if [[ -z "$PROBLEMS" ]]
                                                                                                                then
                                                                                                                    tar --create --xz --file /temporary/archive.tar.gz /gc-roots /resources
                                                                                                                    rm --recursive --force /gc-roots /resources
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
                                                                    mkdir --parents ${ gc-roots-directory }
                                                                    mkdir --parents ${ resources-directory }/locks
                                                                    exec 149> ${ resources-directory }/locks/clean
                                                                    flock -x 149
                                                                    TEMPORARY="$( mktemp --directory )" || exit 113
                                                                    export TEMPORARY
                                                                    clean
                                                                    STATUS="$( cat "$TEMPORARY/status" )" || exit 158
                                                                    exit "$STATUS"
                                                                '' ;
                                                        } ;
                                                in "${ application }/bin/clean" ;
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
                                                    store =
                                                        mkDerivation
                                                            {
                                                                installPhase = ''resource "$error" "$init" "$release" "$seed" "$targets" "$temporary'' ;
                                                                name = "alpha" ;
                                                                nativeBuildInputs =
                                                                    [
                                                                        (
                                                                            writeShellApplication
                                                                                {
                                                                                    name = "resource" ;
                                                                                    runtimeInputs = [ ] ;
                                                                                    text =
                                                                                        let
                                                                                            resource-parameters =
                                                                                                {
                                                                                                    error =
                                                                                                        visitor
                                                                                                            {
                                                                                                                int = path : value : builtins.builtins.toString value ;
                                                                                                            }
                                                                                                            error ;
                                                                                                    init =
                                                                                                        {
                                                                                                            action =
                                                                                                                let
                                                                                                                    action = visitor { lambda = path : value : value null ; } resource-parameters.init.init ;
                                                                                                                    in
                                                                                                                        {
                                                                                                                            script =
                                                                                                                                writeShellApplication
                                                                                                                                    {
                                                                                                                                        name = "init" ;
                                                                                                                                        runtimeInputs =
                                                                                                                                            [
                                                                                                                                                (
                                                                                                                                                    buildFHSUserEnv
                                                                                                                                                        {
                                                                                                                                                            extraBwrapArgs =
                                                                                                                                                                [
                                                                                                                                                                    "--ro-bind" "$INPUT_FILE" "/input"
                                                                                                                                                                    "--bind" "$OUTPUT_FILE" "/output"
                                                                                                                                                                    "--bind" "${ resources-directory }/mounts/$INDEX" "/mount"
                                                                                                                                                                    "--bind" "${ resources-directory }/pids/$INDEX" "/pid"
                                                                                                                                                                    "--bind" "${ resources-directory }/release/$INDEX" "/release"
                                                                                                                                                                    "--tmpfs" "/private"
                                                                                                                                                                    "--tmpfs" "/scratch"
                                                                                                                                                                ] ;
                                                                                                                                                            name = "init" ;
                                                                                                                                                            runScript = "" ;
                                                                                                                                                            targetPkgs =
                                                                                                                                                                pkgs :
                                                                                                                                                                    [
                                                                                                                                                                        (
                                                                                                                                                                            pkgs.writeShellApplication
                                                                                                                                                                                {
                                                                                                                                                                                    name = "init" ;
                                                                                                                                                                                    runtimeInputs = [ pkgs.jq ] ;
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
                                                                                                                                                                                                mkdir --parents "/pid/$INDEX"
                                                                                                                                                                                                echo "$ORIGINATOR_PID" > "/pid/$INDEX/$ORIGINATOR_PID"
                                                                                                                                                                                                ### FIXME
                                                                                                                                                                                                jq \
                                                                                                                                                                                                    --arg CHANNEL ${ resource-parameters.init.valid-channel } \
                                                                                                                                                                                                    --argjson EXPECTED_TARGETS "$EXPECTED_TARGETS" \
                                                                                                                                                                                                    --arg INDEX "$INDEX" \
                                                                                                                                                                                                    --argjson SEED '${ builtins.toJSON resource-parameters.seed }' \
                                                                                                                                                                                                    --rawfile STANDARD_ERROR /private/standard-error \
                                                                                                                                                                                                    --rawfile STANDARD_OUTPUT /private/standard-output \
                                                                                                                                                                                                    --argjson STATUS "$STATUS" \
                                                                                                                                                                                                    --rawfile TEXT ${ builtins.toFile "file" resource-parameters.init.text } \
                                                                                                                                                                                                    --argjson TEMPORARY '${ builtins.toJSON resource-parameters.temporary }' \
                                                                                                                                                                                                    '{
                                                                                                                                                                                                        "arguments" : .arguments ,
                                                                                                                                                                                                        "channel" : $CHANNEL ,
                                                                                                                                                                                                        "evaluation" : 0 ,
                                                                                                                                                                                                        "index" : $INDEX ,
                                                                                                                                                                                                        "inputs" : .inputs ,
                                                                                                                                                                                                        "seed" : $SEED ,
                                                                                                                                                                                                        "standard-error" : $STANDARD_ERROR ,
                                                                                                                                                                                                        "standard-output" : $STANDARD_OUTPUT ,
                                                                                                                                                                                                        "status" : $STATUS ,
                                                                                                                                                                                                        "targets" : $EXPECTED_TARGETS ,
                                                                                                                                                                                                        "text" : $TEXT
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
                                                                                                                                                                                                    --rawfile TEXT ${ builtins.toFile "file" resource-parameters.init.text } \
                                                                                                                                                                                                    '{
                                                                                                                                                                                                        "arguments" : .arguments ,
                                                                                                                                                                                                        "channel" : $CHANNEL
                                                                                                                                                                                                        "evalutation" : ${ resource-parameters.error } ,
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
                                                                                                                                                                                        '' ;
                                                                                                                                                                                }
                                                                                                                                                                        )
                                                                                                                                                                    ] ;
                                                                                                                                                        }
                                                                                                                                                )
                                                                                                                                            ] ;
                                                                                                                                        text =
                                                                                                                                            ''

                                                                                                                                            '' ;
                                                                                                                                    } ;
                                                                                                                            text = visitor { string = path : value : value ; } action.text ;
                                                                                                                            targetPkgs = visitor { lambda = path : value : value ; } action.targetPkgs ;
                                                                                                                        } ;
                                                                                                            init = visitor { lambda = path : value : value null ; } init ;
                                                                                                            recovery = null ;
                                                                                                        } ;
                                                                                                    release = null ;
                                                                                                    seed =
                                                                                                        let
                                                                                                            to-string =
                                                                                                                path : value :
                                                                                                                    let
                                                                                                                        type = builtins.typeOf value ;
                                                                                                                        in
                                                                                                                            [
                                                                                                                                {
                                                                                                                                    path = path ;
                                                                                                                                    type = type ;
                                                                                                                                    value = if type == "lambda" then null else value ;
                                                                                                                                }
                                                                                                                            ] ;
                                                                                                            in
                                                                                                                visitor
                                                                                                                    {
                                                                                                                        bool = to-string ;
                                                                                                                        float = to-string ;
                                                                                                                        int = to-string ;
                                                                                                                        lambda = to-string ;
                                                                                                                        list = path : value : builtins.concatLists value ;
                                                                                                                        path = to-string ;
                                                                                                                        set = path : value : builtins.concatLists ( builtins.attrValue value ) ;
                                                                                                                        string = to-string ;
                                                                                                                    }
                                                                                                                    seed ;
                                                                                                    targets =
                                                                                                        visitor
                                                                                                            {
                                                                                                                list = path : value : builtins.sort builtins.lessThan value ;
                                                                                                                string = path : value : value ;
                                                                                                            }
                                                                                                            targets ;
                                                                                                    temporary =
                                                                                                        visitor
                                                                                                            {
                                                                                                                bool = path : value : value ;
                                                                                                            }
                                                                                                            temporary ;
                                                                                                } ;
                                                                                            in
                                                                                                ''
                                                                                                    ERROR="$1"
                                                                                                    INIT="$2"
                                                                                                    INIT_RECOVERY="$3"
                                                                                                    RELEASE="$4"
                                                                                                    SEED="$6"
                                                                                                    TARGETS="$7"
                                                                                                    TEMPORARY="$8"
                                                                                                    jq "." ${ builtins.toFile "error.json" ( builtins.toJSON resource-parameters.error ) } > "$ERROR"

                                                                                                    jq "." ${ builtins.toFile "seed.json" ( builtins.toJSON resource-parameters.seed ) } > "$SEED"
                                                                                                    jq "." ${ builtins.toFile "targets.json" ( builtins.toJSON resource-parameters.targets ) } > "$TARGETS"
                                                                                                    jq "." ${ builtins.toFile "temporary.json" ( builtins.toJSON resource-parameters.temporary ) } > "$TEMPORARY"
                                                                                                '' ;
                                                                                }
                                                                        )
                                                                    ] ;
                                                                out = [ "error" "init" "init-recovery" "release" "release-recovery" "seed" "targets" "temporary" ] ;
                                                                src = ./. ;
                                                            } ;
                                                    resource =
                                                        writeShellApplication
                                                            {
                                                                name = "resource" ;
                                                                runtimeInputs = [ coreutils findutils log store ] ;
                                                                text =
                                                                    ''
                                                                        mkdir --parents ${ gc-roots-directory }
                                                                        mkdir --parents ${ resources-directory }/locks
                                                                        exec 157> ${ resources-directory }/locks/clean
                                                                        flock -s 157
                                                                        INPUT_FILE="$( mktemp --suffix ".json" )" || exit 199
                                                                        export INPUT_FILE
                                                                        if [[ -t 0 ]]
                                                                        then
                                                                            ULTIMATE_PID="$( ps -o ppid= -p "$PPID" | tr -d '[:space:]' )" || exit 127
                                                                            jq \
                                                                                --null-input \
                                                                                --arg ORIGINATOR_PID "$ULTIMATE_PID" \
                                                                                --args \
                                                                                '{
                                                                                    "arguments" : $ARGS.positional ,
                                                                                    "inputs" : { } ,
                                                                                    "originator-pid" : $ORIGINATOR_PID
                                                                                }' \
                                                                                -- "$@" > "$INPUT_FILE"
                                                                        else
                                                                            PENULTIMATE_PID="$( ps -o ppid= -p "$PPID" | tr -d '[:space:]' )" || exit 146
                                                                            STANDARD_INPUT="$( cat )" || exit 103
                                                                            ULTIMATE_PID="$( ps -o ppid= -p "$PENULTIMATE_PID" | tr -d '[:space:]' )" || exit 184
                                                                            jq \
                                                                                --null-input \
                                                                                --arg ORIGINATOR_PID "$ULTIMATE_PID" \
                                                                                --arg STANDARD_INPUT "$STANDARD_INPUT" \
                                                                                --args \
                                                                                '{
                                                                                    "arguments" : $ARGS.positional ,
                                                                                    "inputs" :
                                                                                        {
                                                                                            "standard" : $STANDARD_INPUT
                                                                                        } ,
                                                                                    "originator-pid" : $ORIGINATOR_PID
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
                                                                        STATUS="$( jq --raw-output ".status" "$OUTPUT_FILE" )" || exit 179
                                                                        echo -en "${ resources-directory }/mounts/$INDEX"
                                                                        if [[ 0 == "$STATUS" ]] && [[ -z "$STANDARD_ERROR" ]]
                                                                        then
                                                                            export CHANNEL=valid-init
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
                                                                            exit "$EVALUATION"
                                                                        elif [[ 0 != "$STATUS" ]] && [[ -z "$STANDARD_ERROR" ]]
                                                                        then
                                                                            export CHANNEL=invalid-init
                                                                            jq \
                                                                                '{
                                                                                    "arguments" : .arguments ,
                                                                                    "index" : .index ,
                                                                                    "inputs" : .inputs ,
                                                                                    "originator-pid" : .["originator-pid"] , ,
                                                                                    "seed" : .seed ,
                                                                                    "standard-output" : .["standard-output"] ,
                                                                                    "status" : .status ,
                                                                                    "targets" : .targets ,
                                                                                    "text" : .text ,
                                                                                    "temporary" : .temporary
                                                                                }' \
                                                                                "$OUTPUT_FILE" | log
                                                                            exit "$EVALUATION"
                                                                        elif [[ 0 == "$STATUS" ]] && [[ -n "$STANDARD_ERROR" ]]
                                                                        then
                                                                            export CHANNEL=invalid-init
                                                                            jq \
                                                                                '{
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
                                                                            exit "$EVALUATION"
                                                                        elif [[ 0 != "$STATUS" ]] && [[ -n "$STANDARD_ERROR" ]]
                                                                        then
                                                                            export CHANNEL=invalid-init
                                                                            jq \
                                                                                '{
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
                                                                            exit "$EVALUATION"
                                                                        fi
                                                                        rm "$INPUT_FILE" "$OUTPUT_FILE"
                                                                    '' ;
                                                            } ;
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
                                                                                        extraBwrapArgs = [ "--tmpfs" "/private" ] ;
                                                                                        name = "log" ;
                                                                                        runScript = "log" ;
                                                                                        targetPkgs =
                                                                                            pkgs :
                                                                                                [
                                                                                                    (
                                                                                                        pkgs.writeShellApplication
                                                                                                            {
                                                                                                                name = "log" ;
                                                                                                                runtimeInputs = [ pkgs.coreutils pkgs.redis ] ;
                                                                                                                text =
                                                                                                                    ''
                                                                                                                        : "${ builtins.concatStringsSep "" [ "$" "{" "CHANNEL:?must be exported" "}" ] }"
                                                                                                                        : "${ builtins.concatStringsSep "" [ "$" "{" "CHANNEL:?must be exported" "}" ] }"
                                                                                                                        JSON="$( cat )" || exit 129
                                                                                                                        redis-cli PUBLISH "$CHANNEL" "$JSON" > /private/standard-error 2> /private/standard-error
                                                                                                                        echo "$JSON"
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
                                                                            exec 174> ${ resources-directory }/locks/clean
                                                                            flock -s 174
                                                                            exec 143> ${ resources-directory }/locks/log
                                                                            flock -x 143
                                                                            mkdir --parents ${ resources-directory }/log.yaml
                                                                            log
                                                                        '' ;
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
                                                                                                                        CURRENT="$( cat /sequential )" || exit 166
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
                                                                                                            read -t 1 -r OBSERVED_PAYLOAD <&189 || exit 160
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
                                                                                        pkgs.redis
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
                                                                                                                                                            YAML_FILE="$( mktemp )" || exit 139
                                                                                                                                                            cd "$ROOT"
                                                                                                                                                            find . \( -path './resources/pids' -o -path './resources/temporary' \) -prune -o -type f -print | sort | while IFS= read -r FILE
                                                                                                                                                            do
                                                                                                                                                                jq --null-input --arg NAME "$FILE" --rawfile CONTENTS "$FILE" '{ "name": $NAME, "contents": $CONTENTS }' | yq eval --prettyPrint '[.]'
                                                                                                                                                            done >> "$YAML_FILE"
                                                                                                                                                            OBSERVED_HASH="$( sha512sum "$YAML_FILE" | cut --characters 1-128 )" || exit 176
                                                                                                                                                            if [[ "$EXPECTED_HASH" != "$OBSERVED_HASH" ]]
                                                                                                                                                            then
                                                                                                                                                                echo "UUID=$UUID" >&2
                                                                                                                                                                echo "YAML_FILE" >&2
                                                                                                                                                                yq eval --prettyPrint "." "$YAML_FILE" >&2
                                                                                                                                                                echo "OBSERVED_HASH=$OBSERVED_HASH" >&2
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
                                                                                                                                                            if read -t "$TIMEOUT" -r VALUE <&189
                                                                                                                                                            then
                                                                                                                                                                echo "$UUID $VALUE" >&2
                                                                                                                                                                exit 160
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
                                                                                                                                        seq 0 ${ builtins.toString ( index - 1 ) } | while read -r INDEX
                                                                                                                                        do
                                                                                                                                            while [[ -f "$COMMANDS/$INDEX" ]]
                                                                                                                                            do
                                                                                                                                                sleep 1
                                                                                                                                            done
                                                                                                                                        done
                                                                                                                                        STANDARD_ERROR_FILE="$( mktemp )" || exit 154
                                                                                                                                        STANDARD_OUTPUT_FILE="$( mktemp )" || exit 130
                                                                                                                                        date
                                                                                                                                        echo PROCESS
                                                                                                                                        cat ${ builtins.toFile "process" ( builtins.toString action.process ) }
                                                                                                                                        echo
                                                                                                                                        echo TIMEOUT
                                                                                                                                        cat ${ builtins.toFile "timeout" ( builtins.toString action.timeout ) }
                                                                                                                                        echo
                                                                                                                                        echo TEXT
                                                                                                                                        cat ${ builtins.toFile "text" ( builtins.toString action.text ) }
                                                                                                                                        echo
                                                                                                                                        if time timeout ${ builtins.toString action.timeout }s ${ builtins.toString action.text } > "$STANDARD_OUTPUT_FILE" 2> "$STANDARD_ERROR_FILE" <&189
                                                                                                                                        then
                                                                                                                                            OBSERVED_STATUS="$?"
                                                                                                                                        else
                                                                                                                                            OBSERVED_STATUS="$?"
                                                                                                                                        fi
                                                                                                                                        rm "$COMMANDS/${ builtins.toString index }"
                                                                                                                                        date
                                                                                                                                        OBSERVED_STANDARD_ERROR="$( cat "$STANDARD_ERROR_FILE" )" || exit 134
                                                                                                                                        OBSERVED_STANDARD_OUTPUT="$( cat "$STANDARD_OUTPUT_FILE" )" || exit 120
                                                                                                                                        if [[ -n "$OBSERVED_STANDARD_ERROR" ]]
                                                                                                                                        then
                                                                                                                                            echo "OBSERVED_STANDARD_ERROR=$OBSERVED_STANDARD_ERROR" >&2
                                                                                                                                            exit 188
                                                                                                                                        fi
                                                                                                                                        OBSERVED_STANDARD_OUTPUT="$( cat "$STANDARD_OUTPUT_FILE" )" || exit 120
                                                                                                                                        if [[ '${ builtins.toString action.expected-standard-output }' != "$OBSERVED_STANDARD_OUTPUT" ]]
                                                                                                                                        then
                                                                                                                                            echo "OBSERVED_STANDARD_OUTPUT=$OBSERVED_STANDARD_OUTPUT" >&2
                                                                                                                                            exit 178
                                                                                                                                        fi
                                                                                                                                        if [[ "$OBSERVED_STATUS" == 124 ]]
                                                                                                                                        then
                                                                                                                                            echo time timeout ${ builtins.toString action.timeout }s ${ builtins.toString action.text } >&2
                                                                                                                                            echo >&2
                                                                                                                                            cat ${ builtins.toString action.text } >&2
                                                                                                                                            echo "RESOURCES=$RESOURCES" >&2
                                                                                                                                            cat "$RESOURCES/[\"checks\",\"true\",\"true\"]/resource" >&2
                                                                                                                                            exit 183
                                                                                                                                        fi
                                                                                                                                        if [[ '${ builtins.toString action.expected-status }' != "$OBSERVED_STATUS" ]]
                                                                                                                                        then
                                                                                                                                            echo "OBSERVED_STATUS=$OBSERVED_STATUS" >&2
                                                                                                                                            exit 132
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
                                                                                                            mapper = { expected-standard-output , expected-status , index , process , text , timeout } : ''"$COMMANDS/${ builtins.toString index }"'' ;
                                                                                                            in
                                                                                                                ''
                                                                                                                    (
                                                                                                                        true ${ name }
                                                                                                                        ${ builtins.concatStringsSep "\n\t" ( builtins.map mapper value ) }
                                                                                                                    ) &
                                                                                                                '' ;
                                                                                                in builtins.attrValues ( builtins.mapAttrs mapper ( builtins.groupBy grouper _actions ) ) ;
                                                                                        in
                                                                                            ''
                                                                                                COMMANDS="$( mktemp --directory )" || exit 119
                                                                                                export COMMANDS
                                                                                                exec 189< <( redis-cli SUBSCRIBE valid-init valid-release invalid-init invalid-release )
                                                                                                is-subscribed valid-init 1 <&189
                                                                                                is-subscribed valid-release 2 <&189
                                                                                                is-subscribed invalid-init 3 <&189
                                                                                                is-subscribed invalid-release 4 <&189
                                                                                                ${ builtins.concatStringsSep "\n" commands }
                                                                                                ${ builtins.concatStringsSep "\n" processes }
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
