{
	inputs = { } ;
	outputs =
		{ self } :
		    {
		        lib =
		            let
		                failure =
                            coreutils : jq : writeShellApplication : yq-go : compile-time-arguments :
                                writeShellApplication
                                    {
                                        name = "failure" ;
                                        runtimeInputs = [ coreutils jq yq-go ] ;
                                        text =
                                            ''
                                                RUNTIME_ARGUMENTS_JSON="$( printf '%s\n' "$@" | jq -R . | jq -s . )" || exit 65
                                                export RUNTIME_ARGUMENTS_JSON
                                                yq --null-input --prettyPrint '{ "compile-time-arguments" : ${ builtins.toJSON compile-time-arguments } }' >&2
                                                exit 64
                                            '' ;
                                    } ;
                        setup =
                            {
                                buildFHSUserEnv ,
                                channel ? "resource" ,
                                coreutils ,
                                error ? 177 ,
                                findutils ,
                                flock ,
                                init ? null ,
                                jq ,
                                makeBinPath ,
                                makeWrapper ,
                                mkDerivation ,
                                ps ,
                                redis ,
                                resources-directory ,
                                seed ? null ,
                                targets ? [ ] ,
                                transient ? false ,
                                visitor ,
                                writeShellApplication ,
                                yq-go
                            } @primary :
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
                                    implementation =
                                        let
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
                                                            runScript = init "${ resources-directory }/mounts/$INDEX" ;
                                                        } ;
                                            publish =
                                                writeShellApplication
                                                    {
                                                        name = "publish" ;
                                                        runtimeInputs = [ coreutils jq redis ] ;
                                                        text =
                                                            ''
                                                                JSON="$( cat | jq --compact-output '. + { "description" : ${ builtins.toJSON description } }' )" || ${ failure coreutils jq writeShellApplication yq-go "7b8f1293" }
                                                                redis-cli PUBLISH "${ channel }" "$JSON" > /dev/null 2>&1 || true
                                                            '' ;
                                                    } ;
                                            setup =
                                                if builtins.typeOf init == "null" then
                                                    writeShellApplication
                                                        {
                                                            name = "setup" ;
                                                            runtimeInputs = [ coreutils flock jq ps publish sequential yq-go ] ;
                                                            text =
                                                                ''
                                                                    if [[ -t 0 ]]
                                                                    then
                                                                        HAS_STANDARD_INPUT=false
                                                                        STANDARD_INPUT=
                                                                        STANDARD_INPUT_FILE="$( mktemp )" || ${ failure coreutils jq writeShellApplication yq-go "7f77cdad" }
                                                                    else
                                                                        HAS_STANDARD_INPUT=true
                                                                        cat <&0 > "$STANDARD_INPUT_FILE"
                                                                        STANDARD_INPUT="$( cat "$STANDARD_INPUT_FILE" )" || ${ failure coreutils jq writeShellApplication yq-go "fbb0e2f8" }
                                                                    fi
                                                                    TRANSIENT=${ transient_ }
                                                                    ORIGINATOR_PID="$( ps -o ppid= -p "$PPID" )" || ${ failure coreutils jq writeShellApplication yq-go "833fbd3f" }
                                                                    HASH="$( echo "${ pre-hash } ${ builtins.concatStringsSep "" [ "$TRANSIENT" "$" "{" "ARGUMENTS[*]" "}" ] } $STANDARD_INPUT $HAS_STANDARD_INPUT" | sha512sum | cut --characters 1-128 )" || ${ failure coreutils jq writeShellApplication yq-go "bc3e1b88" }
                                                                    mkdir --parents "${ resources-directory }/locks"
                                                                    ARGUMENTS_YAML="$( printf '%s\n' "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" | jq -R . | jq -s . | yq -P )" || ${ failure coreutils jq writeShellApplication yq-go "fc776602" }
                                                                    export ARGUMENTS_YAML
                                                                    export HAS_STANDARD_INPUT
                                                                    export HASH
                                                                    export STANDARD_INPUT
                                                                    export ORIGINATOR_PID
                                                                    export TRANSIENT
                                                                    exec 210> "${ resources-directory }/locks/$HASH/teardown.lock"
                                                                    flock -s 210
                                                                    if [[ -L "${ resources-directory }/canonical/$HASH" ]]
                                                                    then
                                                                        MOUNT="$( readlink "${ resources-directory }/canonical/$HASH" )" || ${ failure coreutils jq writeShellApplication yq-go "bf282501" }
                                                                        export MOUNT
                                                                        INDEX="$( basename "$MOUNT" )" || ${ failure coreutils jq writeShellApplication yq-go "26213048" }
                                                                        export INDEX
                                                                        export PROVENENCE=cached
                                                                        mkdir --parents "${ resources-directory }/locks/$INDEX"
                                                                        exec 211> "${ resources-directory }/locks/$INDEX/setup.lock"
                                                                        flock -s 211
                                                                        jq \
                                                                            --null-input \
                                                                            --arg HAS_STANDARD_INPUT "$HAS_STANDARD_INPUT" \
                                                                            '{
                                                                                "has-standard-input" : $HAS_STANDARD_INPUT }
                                                                            }' | publish
                                                                        ln --symbolic "$MOUNT" "${ resources-directory }/canonical/$HASH"
                                                                        echo -n "$MOUNT"
                                                                    else
                                                                        INDEX="$( sequential )" || ${ failure coreutils jq writeShellApplication yq-go "d162db9f" }
                                                                        export INDEX
                                                                        export PROVENANCE=new
                                                                        mkdir --parents "${ resources-directory }/locks/$INDEX"
                                                                        exec 211> "${ resources-directory }/locks/$INDEX/setup.lock"
                                                                        flock -s 211
                                                                        MOUNT="${ resources-directory }/mounts/$INDEX"
                                                                        mkdir --parents "$MOUNT"
                                                                        mkdir --parents ${ resources-directory }/canonical
                                                                        jq \
                                                                            --null-input \
                                                                            --arg HAS_STANDARD_INPUT "$HAS_STANDARD_INPUT" \
                                                                            '{
                                                                                "has-standard-input" : $HAS_STANDARD_INPUT }
                                                                            }' | publish
                                                                        mkdir --parents ${ resources-directory }/canonical
                                                                        ln --symbolic "$MOUNT" "${ resources-directory }/canonical/$HASH"
                                                                        echo -n "$MOUNT"
                                                                    fi
                                                                '' ;
                                                        }
                                                else
                                                    writeShellApplication
                                                        {
                                                            name = "setup" ;
                                                            runtimeInputs = [ coreutils flock jq ps publish redis sequential yq-go ] ;
                                                            text =
                                                                ''
                                                                    if [[ -t 0 ]]
                                                                    then
                                                                        HAS_STANDARD_INPUT=false
                                                                        STANDARD_INPUT=
                                                                    else
                                                                        STANDARD_INPUT_FILE="$( mktemp )" || ${ failure coreutils jq writeShellApplication yq-go "f66f966d" }
                                                                        export STANDARD_INPUT_FILE
                                                                        HAS_STANDARD_INPUT=true
                                                                        cat <&0 > "$STANDARD_INPUT_FILE"
                                                                        STANDARD_INPUT="$( cat "$STANDARD_INPUT_FILE" )" || ${ failure coreutils jq writeShellApplication yq-go "ffff1b30" }
                                                                    fi
                                                                    mkdir --parents ${ resources-directory }
                                                                    ARGUMENTS=( "$@" )
                                                                    ARGUMENTS_JSON="$( printf '%s\n' "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" | jq -R . | jq -s . )"
                                                                    TRANSIENT=${ transient_ }
                                                                    ORIGINATOR_PID="$(ps -o ppid= -p "$PPID" | tr -d '[:space:]')" || ${ failure coreutils jq writeShellApplication yq-go "833fbd3f" }
                                                                    export ORIGINATOR_PID
                                                                    HASH="$( echo "${ pre-hash } ${ builtins.concatStringsSep "" [ "$TRANSIENT" "$" "{" "ARGUMENTS[*]" "}" ] } $STANDARD_INPUT $HAS_STANDARD_INPUT" | sha512sum | cut --characters 1-128 )" || ${ failure coreutils jq writeShellApplication yq-go "7849a979" }
                                                                    export HASH
                                                                    mkdir --parents "${ resources-directory }/locks"
                                                                    export HAS_STANDARD_INPUT
                                                                    export HASH
                                                                    export STANDARD_INPUT
                                                                    export ORIGINATOR_PID
                                                                    export TRANSIENT
                                                                    exec 210> "${ resources-directory }/locks/$HASH"
                                                                    flock -s 210
                                                                    if [[ -L "${ resources-directory }/canonical/$HASH" ]]
                                                                    then
                                                                        MOUNT="$( readlink "${ resources-directory }/canonical/$HASH" )" || ${ failure coreutils jq writeShellApplication yq-go "ae2d1658" }
                                                                        export MOUNT
                                                                        INDEX="$( basename "$MOUNT" )" || ${ failure coreutils jq writeShellApplication yq-go"277afc07" }
                                                                        export INDEX
                                                                        export PROVENANCE=cached
                                                                        DEPENDENCIES="$( find "${ resources-directory }/links/$INDEX" -mindepth 1 -maxdepth 1 -exec basename {} \; | jq -R . | jq -s . )" || ${ failure coreutils jq writeShellApplication yq-go "54d472fb" }
                                                                        TARGETS="$( find "${ resources-directory }/mounts/$INDEX" -mindepth 1 -maxdepth 1 -exec basename {} \; | jq -R . | jq -s . )" || ${ failure coreutils jq writeShellApplication yq-go "54d472fb" }
                                                                        mkdir --parents "${ resources-directory }/locks/$INDEX"
                                                                            # shellcheck disable=SC2016
                                                                            jq \
                                                                                --null-input \
                                                                                --argjson ARGUMENTS "$ARGUMENTS_JSON" \
                                                                                --argjson DEPENDENCIES "$DEPENDENCIES" \
                                                                                --arg HASH "$HASH" \
                                                                                --arg INDEX "$INDEX" \
                                                                                --arg HAS_STANDARD_INPUT "$HAS_STANDARD_INPUT" \
                                                                                --arg ORIGINATOR_PID "$ORIGINATOR_PID" \
                                                                                --arg PROVENANCE "$PROVENANCE" \
                                                                                --arg TRANSIENT "$TRANSIENT" \
                                                                                --arg STANDARD_INPUT "$STANDARD_INPUT" \
                                                                                --argjson TARGETS "$TARGETS" \
                                                                                --arg TRANSIENT "$TRANSIENT" \
                                                                                '{
                                                                                    "arguments" : $ARGUMENTS ,
                                                                                    "dependencies" : $DEPENDENCIES ,
                                                                                    "hash" : $HASH ,
                                                                                    "index" : $INDEX ,
                                                                                    "has-standard-input" : $HAS_STANDARD_INPUT ,
                                                                                    "originator-pid" : $ORIGINATOR_PID ,
                                                                                    "provenance" : $PROVENANCE ,
                                                                                    "standard-input" : $STANDARD_INPUT ,
                                                                                    "targets" : $TARGETS ,
                                                                                    "transient" : $TRANSIENT
                                                                                }' | publish > /dev/null 2>&1
                                                                        echo -n "$MOUNT"
                                                                    else
                                                                        INDEX="$( sequential )" || ${ failure coreutils jq writeShellApplication yq-go "cab66847" }
                                                                        export INDEX
                                                                        export PROVENANCE=new
                                                                        mkdir --parents "${ resources-directory }/locks/$INDEX"
                                                                        exec 211> "${ resources-directory }/locks/$INDEX/setup.lock"
                                                                        flock -s 211
                                                                        LINK="${ resources-directory }/links/$INDEX"
                                                                        export LINK
                                                                        mkdir --parents "$LINK"
                                                                        MOUNT="${ resources-directory }/mounts/$INDEX"
                                                                        mkdir --parents "$MOUNT"
                                                                        export MOUNT
                                                                        mkdir --parents "$MOUNT"
                                                                        STANDARD_ERROR_FILE="$( mktemp )" || ${ failure coreutils jq writeShellApplication yq-go "b07f7374" }
                                                                        export STANDARD_ERROR_FILE
                                                                        STANDARD_OUTPUT_FILE="$( mktemp )" || ${ failure coreutils jq writeShellApplication yq-go "29c19af1" }
                                                                        export STANDARD_OUTPUT_FILE
                                                                        if [[ "$HAS_STANDARD_INPUT" == "true" ]]
                                                                        then
                                                                            if ${ init-application }/bin/init-application "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" < "$STANDARD_INPUT_FILE" > "$STANDARD_OUTPUT_FILE" 2> "$STANDARD_ERROR_FILE"
                                                                            then
                                                                                STATUS="$?"
                                                                            else
                                                                                STATUS="$?"
                                                                            fi
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
                                                                        TARGET_HASH_OBSERVED="$( find "$MOUNT" -mindepth 1 -maxdepth 1 -exec basename {} \; | LC_ALL=C sort | tr --delete "\n" | sha512sum | cut --characters 1-128 )" || ${ failure coreutils jq writeShellApplication yq-go "db2517b1" }
                                                                        STANDARD_ERROR="$( < "$STANDARD_ERROR_FILE" )" || ${ failure coreutils jq writeShellApplication yq-go "260fbb3c" }
                                                                        export STANDARD_ERROR
                                                                        STANDARD_OUTPUT="$( < "$STANDARD_OUTPUT_FILE" )" || ${ failure coreutils jq writeShellApplication yq-go "d1b1f5be" }
                                                                        export STANDARD_OUTPUT
                                                                        DEPENDENCIES="$( find "${ resources-directory }/links/$INDEX" -mindepth 1 -maxdepth 1 -exec basename {} \; | jq -R . | jq -s . )" || ${ failure coreutils jq writeShellApplication yq-go "54d472fb" }
                                                                        TARGETS="$( find "${ resources-directory }/mounts/$INDEX" -mindepth 1 -maxdepth 1 -exec basename {} \; | jq -R . | jq -s . )" || ${ failure coreutils jq writeShellApplication yq-go "54d472fb" }
                                                                        if [[ "$STATUS" == 0 ]] && [[ ! -s "$STANDARD_ERROR_FILE" ]] && [[ "$TARGET_HASH_EXPECTED" == "$TARGET_HASH_OBSERVED" ]]
                                                                        then
                                                                            # shellcheck disable=SC2016
                                                                            jq \
                                                                                --null-input \
                                                                                --argjson ARGUMENTS "$ARGUMENTS_JSON" \
                                                                                --argjson DEPENDENCIES "$DEPENDENCIES" \
                                                                                --arg HASH "$HASH" \
                                                                                --arg INDEX "$INDEX" \
                                                                                --arg HAS_STANDARD_INPUT "$HAS_STANDARD_INPUT" \
                                                                                --arg ORIGINATOR_PID "$ORIGINATOR_PID" \
                                                                                --arg PROVENANCE "$PROVENANCE" \
                                                                                --arg TRANSIENT "$TRANSIENT" \
                                                                                --arg STANDARD_ERROR "$STANDARD_ERROR" \
                                                                                --arg STANDARD_INPUT "$STANDARD_INPUT" \
                                                                                --arg STANDARD_OUTPUT "$STANDARD_OUTPUT" \
                                                                                --arg STATUS "$STATUS" \
                                                                                --argjson TARGETS "$TARGETS" \
                                                                                --arg TRANSIENT "$TRANSIENT" \
                                                                                '{
                                                                                    "arguments" : $ARGUMENTS ,
                                                                                    "dependencies" : $DEPENDENCIES ,
                                                                                    "hash" : $HASH ,
                                                                                    "index" : $INDEX ,
                                                                                    "has-standard-input" : $HAS_STANDARD_INPUT ,
                                                                                    "originator-pid" : $ORIGINATOR_PID ,
                                                                                    "provenance" : $PROVENANCE ,
                                                                                    "standard-error" : $STANDARD_ERROR ,
                                                                                    "standard-input" : $STANDARD_INPUT ,
                                                                                    "standard-output" : $STANDARD_OUTPUT ,
                                                                                    "status" : $STATUS ,
                                                                                    "targets" : $TARGETS ,
                                                                                    "transient" : $TRANSIENT
                                                                                }' | publish > /dev/null 2>&1
                                                                            mkdir --parents ${ resources-directory }/canonical
                                                                            ln --symbolic "$MOUNT" "${ resources-directory }/canonical/$HASH"
                                                                            echo -n "$MOUNT"
                                                                        else
                                                                            # shellcheck disable=SC2016
                                                                            jq \
                                                                                --null-input \
                                                                                --argjson ARGUMENTS "$ARGUMENTS_JSON" \
                                                                                --argjson DEPENDENCIES "$DEPENDENCIES" \
                                                                                --arg HASH "$HASH" \
                                                                                --arg INDEX "$INDEX" \
                                                                                --arg HAS_STANDARD_INPUT "$HAS_STANDARD_INPUT" \
                                                                                --arg ORIGINATOR_PID "$ORIGINATOR_PID" \
                                                                                --arg PROVENANCE "$PROVENANCE" \
                                                                                --arg TRANSIENT "$TRANSIENT" \
                                                                                --arg STANDARD_ERROR "$STANDARD_ERROR" \
                                                                                --arg STANDARD_INPUT "$STANDARD_INPUT" \
                                                                                --arg STANDARD_OUTPUT "$STANDARD_OUTPUT" \
                                                                                --arg STATUS "$STATUS" \
                                                                                --argjson TARGETS "$TARGETS" \
                                                                                --arg TRANSIENT "$TRANSIENT" \
                                                                                '{
                                                                                    "arguments" : $ARGUMENTS ,
                                                                                    "dependencies" : $DEPENDENCIES ,
                                                                                    "hash" : $HASH ,
                                                                                    "index" : $INDEX ,
                                                                                    "has-standard-input" : $HAS_STANDARD_INPUT ,
                                                                                    "originator-pid" : $ORIGINATOR_PID ,
                                                                                    "provenance" : $PROVENANCE ,
                                                                                    "standard-error" : $STANDARD_ERROR ,
                                                                                    "standard-input" : $STANDARD_INPUT ,
                                                                                    "standard-output" : $STANDARD_OUTPUT ,
                                                                                    "status" : $STATUS ,
                                                                                    "targets" : $TARGETS ,
                                                                                    "transient" : $TRANSIENT
                                                                                }' | publish
                                                                            exit ${ builtins.toString error }
                                                                        fi
                                                                    fi
                                                                '' ;
                                                        } ;
                                            sequential =
                                                writeShellApplication
                                                    {
                                                        name = "sequential" ;
                                                        runtimeInputs = [ coreutils flock ] ;
                                                        text =
                                                            ''
                                                                mkdir --parents ${ resources-directory }/sequential
                                                                exec 220> ${ resources-directory }/sequential/sequential.lock
                                                                flock -x 220
                                                                if [[ -s ${ resources-directory }/sequential/sequential.counter ]]
                                                                then
                                                                    CURRENT="$( < ${ resources-directory }/sequential/sequential.counter )" || ${ failure coreutils jq writeShellApplication yq-go "c9a94abb" }
                                                                else
                                                                    CURRENT=0
                                                                fi
                                                                NEXT=$(( ( CURRENT + 1 ) % 10000000000000000 ))
                                                                echo "$NEXT" > ${ resources-directory }/sequential/sequential.counter
                                                                printf "%016d\n" "$CURRENT"
                                                            '' ;
                                                    } ;
                                                transient_ =
                                                    visitor.lib.implementation
                                                        {
                                                            bool = path : value : if value then "$( sequential ) || ${ failure coreutils jq writeShellApplication yq-go "808f8e2c" }" else "-1" ;
                                                        }
                                                        transient ;
                                            in "${ setup }/bin/setup" ;
                                    pre-hash = builtins.hashString "sha512" ( builtins.toJSON description ) ;
                                in implementation ;
		                in
                            {
                                factories =
                                    {
                                        generic =
                                            {
                                                buildFHSUserEnv ,
                                                channel ? "resource" ,
                                                coreutils ,
                                                error ? 177 ,
                                                findutils ,
                                                flock ,
                                                init ? null ,
                                                jq ,
                                                makeBinPath ,
                                                makeWrapper ,
                                                mkDerivation ,
                                                ps ,
                                                redis ,
                                                resources-directory ,
                                                seed ? null ,
                                                targets ? [ ] ,
                                                transient ? false ,
                                                visitor ,
                                                writeShellApplication ,
                                                yq-go
                                            } @primary :
                                                let
                                                    check =
                                                        {
                                                            arguments ? [ ] ,
                                                            expected-dependencies ,
                                                            expected-index ,
                                                            expected-originator-pid ,
                                                            expected-provenance ,
                                                            expected-standard-error ,
                                                            expected-standard-output ,
                                                            expected-status ,
                                                            expected-targets ,
                                                            expected-transient ,
                                                            resources-directory-fixture ? null ,
                                                            standard-input ? null ,
                                                            standard-output ,
                                                            status ? 0
                                                        } :
                                                            mkDerivation
                                                                {
                                                                    installPhase =
                                                                        let
                                                                            fixture =
                                                                                writeShellApplication
                                                                                    {
                                                                                        name = "fixture" ;
                                                                                        runtimeInputs = [ coreutils ] ;
                                                                                        text = if builtins.typeOf resources-directory-fixture == "null" then "" else resources-directory-fixture resources-directory ;
                                                                                    } ;
                                                                            subscribe =
                                                                                writeShellApplication
                                                                                    {
                                                                                        name = "subscribe" ;
                                                                                        runtimeInputs = [ coreutils redis ] ;
                                                                                        text =
                                                                                            ''
                                                                                                redis-cli --raw SUBSCRIBE "${ channel }" | {
                                                                                                    read -r _     # skip "subscribe"
                                                                                                    read -r _     # skip channel name
                                                                                                    read -r _     # skip
                                                                                                    read -r _     # skip
                                                                                                    read -r _
                                                                                                    read -r PAYLOAD
                                                                                                    echo "$PAYLOAD" > /build/payload
                                                                                                }
                                                                                            '' ;
                                                                                    } ;
                                                                            test =
                                                                                writeShellApplication
                                                                                    {
                                                                                        name = "test" ;
                                                                                        runtimeInputs = [ coreutils fixture jq redis subscribe ] ;
                                                                                        text =
                                                                                            ''
                                                                                                OUT="$1"
                                                                                                touch "$OUT"
                                                                                                mkdir --parents /build/redis
                                                                                                redis-server --dir /build/redis --daemonize yes
                                                                                                fixture
                                                                                                while ! redis-cli ping
                                                                                                do
                                                                                                    sleep 0
                                                                                                done
                                                                                                subscribe &
                                                                                                cat >&2 <<EOF
                                                                                                if RESOURCE="\$( ${ implementation } ${ builtins.concatStringsSep " " arguments }${ if builtins.typeOf standard-input == "null" then " " else " < ${ builtins.toFile "standard-input" standard-input } " }2> /build/standard-error )"
                                                                                                EOF
                                                                                                if RESOURCE="$( ${ implementation } ${ builtins.concatStringsSep " " arguments }${ if builtins.typeOf standard-input == "null" then " " else " < ${ builtins.toFile "standard-input" standard-input } " }2> /build/standard-error )"
                                                                                                then
                                                                                                    STATUS="$?"
                                                                                                else
                                                                                                    STATUS="$?"
                                                                                                fi
                                                                                                if [[ "${ standard-output }" != "$RESOURCE" ]]
                                                                                                then
                                                                                                    echo "We expected the standard output to be ${ standard-output } but it was $RESOURCE" >&2
                                                                                                    ${ failure coreutils jq writeShellApplication yq-go "c727ba4d" }
                                                                                                fi
                                                                                                if [[ "${ builtins.toString status }" != "$STATUS" ]]
                                                                                                then
                                                                                                    echo "We expected the status to be ${ builtins.toString status } but it was $STATUS" >&2
                                                                                                    ${ failure coreutils jq writeShellApplication yq-go "57cd83f9" }
                                                                                                fi
                                                                                                if [[ ! -f /build/standard-error ]]
                                                                                                then
                                                                                                    echo "We expected the standard error file to exist" >&2
                                                                                                    ${ failure coreutils jq writeShellApplication yq-go "da8b2593" }
                                                                                                fi
                                                                                                if [[ -s /build/standard-error ]]
                                                                                                then
                                                                                                    STANDARD_ERROR="$( < /build/standard-error )" || ${ failure coreutils jq writeShellApplication yq-go "1c4d6ced" }
                                                                                                    echo "We expected the standard error file to be empty but it was $STANDARD_ERROR" >&2
                                                                                                    ${ failure coreutils jq writeShellApplication yq-go "a6d0f7ed" }
                                                                                                fi
                                                                                                while [[ ! -f /build/payload ]]
                                                                                                do
                                                                                                    redis-cli PUBLISH ${ channel } '{"test" : true}'
                                                                                                done
                                                                                                EXPECTED_ARGUMENTS="$( jq --null-input '${ builtins.toJSON arguments }' )" || ${ failure coreutils jq writeShellApplication yq-go "c0a73187" }
                                                                                                OBSERVED_ARGUMENTS="$( jq ".arguments" /build/payload )" || ${ failure coreutils jq writeShellApplication yq-go "44440f2d" }
                                                                                                if [[ "$EXPECTED_ARGUMENTS" != "$OBSERVED_ARGUMENTS" ]]
                                                                                                then
                                                                                                    echo "We expected the payload arguments to be $EXPECTED_ARGUMENTS but it was $OBSERVED_ARGUMENTS" >&2
                                                                                                    ${ failure coreutils jq writeShellApplication yq-go "d3fb3e9b" }
                                                                                                fi
                                                                                                EXPECTED_DEPENDENCIES="$( jq --null-input '${ builtins.toJSON expected-dependencies }' )" || ${ failure coreutils jq writeShellApplication yq-go "2c5c7ae4" }
                                                                                                OBSERVED_DEPENDENCIES="$( jq ".dependencies" /build/payload )" || ${ failure coreutils jq writeShellApplication yq-go "8d52f2db" }
                                                                                                if [[ "$EXPECTED_DEPENDENCIES" != "$OBSERVED_DEPENDENCIES" ]]
                                                                                                then
                                                                                                    echo "We expected the payload dependencies to be $EXPECTED_DEPENDENCIES but it was $OBSERVED_DEPENDENCIES" >&2
                                                                                                    ${ failure coreutils jq writeShellApplication yq-go "12073df9" }
                                                                                                fi
                                                                                                EXPECTED_DESCRIPTION="$( echo '${ builtins.toJSON description }' | jq '.' )" || ${ failure coreutils jq writeShellApplication yq-go "f7b03966" }
                                                                                                OBSERVED_DESCRIPTION="$( jq ".description" /build/payload )" || ${ failure coreutils jq writeShellApplication yq-go "4f4a2232" }
                                                                                                if [[ "$EXPECTED_DESCRIPTION" != "$OBSERVED_DESCRIPTION" ]]
                                                                                                then
                                                                                                    echo "We expected the payload description to be $EXPECTED_DESCRIPTION but it was $OBSERVED_DESCRIPTION" >&2
                                                                                                    ${ failure coreutils jq writeShellApplication yq-go "4656e7d5" }
                                                                                                fi
                                                                                                EXPECTED_INDEX="${ expected-index }"
                                                                                                OBSERVED_INDEX="$( jq --raw-output ".index" /build/payload )" || ${ failure coreutils jq writeShellApplication yq-go "abdf3e25" }
                                                                                                if [[ "$EXPECTED_INDEX" != "$OBSERVED_INDEX" ]]
                                                                                                then
                                                                                                    echo "We expected the payload index to be $EXPECTED_INDEX but it was $OBSERVED_INDEX" >&2
                                                                                                    ${ failure coreutils jq writeShellApplication yq-go "7a3de836" }
                                                                                                fi
                                                                                                EXPECTED_HAS_STANDARD_INPUT="${ if builtins.typeOf standard-input == "null" then "false" else "true" }"
                                                                                                OBSERVED_HAS_STANDARD_INPUT="$( jq --raw-output '."has-standard-input"' /build/payload )" || ${ failure coreutils jq writeShellApplication yq-go "1de78471" }
                                                                                                if [[ "$EXPECTED_HAS_STANDARD_INPUT" != "$OBSERVED_HAS_STANDARD_INPUT" ]]
                                                                                                then
                                                                                                    cat /build/payload >&2
                                                                                                    echo "We expected the payload has-standard-input to be $EXPECTED_HAS_STANDARD_INPUT but it was $OBSERVED_HAS_STANDARD_INPUT" >&2
                                                                                                    ${ failure coreutils jq writeShellApplication yq-go "89b51e3a" }
                                                                                                fi
                                                                                                EXPECTED_ORIGINATOR_PID="${ builtins.toString expected-originator-pid }"
                                                                                                OBSERVED_ORIGINATOR_PID="$( jq --raw-output '."originator-pid"' /build/payload )" || ${ failure coreutils jq writeShellApplication yq-go "26e0cb2b" }
                                                                                                if [[ "$EXPECTED_ORIGINATOR_PID" != "$OBSERVED_ORIGINATOR_PID" ]]
                                                                                                then
                                                                                                    echo "We expected the payload originator-pid to be $EXPECTED_ORIGINATOR_PID but it was $OBSERVED_ORIGINATOR_PID" >&2
                                                                                                    ${ failure coreutils jq writeShellApplication yq-go "db64a1c9" }
                                                                                                fi
                                                                                                EXPECTED_PROVENANCE="${ expected-provenance }"
                                                                                                OBSERVED_PROVENANCE="$( jq --raw-output ".provenance" /build/payload )" || ${ failure coreutils jq writeShellApplication yq-go "26e0cb2b" }
                                                                                                if [[ "$EXPECTED_PROVENANCE" != "$OBSERVED_PROVENANCE" ]]
                                                                                                then
                                                                                                    echo "We expected the payload provenance to be $EXPECTED_PROVENANCE but it was $OBSERVED_PROVENANCE" >&2
                                                                                                    ${ failure coreutils jq writeShellApplication yq-go "c07c110c" }
                                                                                                fi
                                                                                                EXPECTED_TARGETS="$( jq --null-input '${ builtins.toJSON expected-targets }' )" || ${ failure coreutils jq writeShellApplication yq-go "e9fa75bf" }
                                                                                                OBSERVED_TARGETS="$( jq ".targets" /build/payload )" || ${ failure coreutils jq writeShellApplication yq-go "ad928300" }
                                                                                                if [[ "$EXPECTED_TARGETS" != "$OBSERVED_TARGETS" ]]
                                                                                                then
                                                                                                    echo "We expected the payload targets to be $EXPECTED_TARGETS but it was $OBSERVED_TARGETS" >&2
                                                                                                    ${ failure coreutils jq writeShellApplication yq-go "85ad88e4" }
                                                                                                fi
                                                                                                EXPECTED_STANDARD_ERROR="${ expected-standard-error }"
                                                                                                OBSERVED_STANDARD_ERROR="$( jq --raw-output '."standard-error"' /build/payload )" || ${ failure coreutils jq writeShellApplication yq-go "714592cd" }
                                                                                                if [[ "$EXPECTED_STANDARD_ERROR" != "$OBSERVED_STANDARD_ERROR" ]]
                                                                                                then
                                                                                                    echo "We expected the payload standard-error to be $EXPECTED_STANDARD_ERROR but it was $OBSERVED_STANDARD_ERROR" >&2
                                                                                                    ${ failure coreutils jq writeShellApplication yq-go "dcea8e50" }
                                                                                                fi
                                                                                                EXPECTED_STANDARD_INPUT="${ if builtins.typeOf standard-input == "null" then "" else standard-input }"
                                                                                                OBSERVED_STANDARD_INPUT="$( jq --raw-output '."standard-input"' /build/payload )" || ${ failure coreutils jq writeShellApplication yq-go "714592cd" }
                                                                                                if [[ "$EXPECTED_STANDARD_INPUT" != "$OBSERVED_STANDARD_INPUT" ]]
                                                                                                then
                                                                                                    echo "We expected the payload standard-input to be $EXPECTED_STANDARD_INPUT but it was $OBSERVED_STANDARD_INPUT" >&2
                                                                                                    ${ failure coreutils jq writeShellApplication yq-go "11e3a4aa" }
                                                                                                fi
                                                                                                EXPECTED_STANDARD_OUTPUT="${ expected-standard-output }"
                                                                                                OBSERVED_STANDARD_OUTPUT="$( jq --raw-output '."standard-output"' /build/payload )" || ${ failure coreutils jq writeShellApplication yq-go "714592cd" }
                                                                                                if [[ "$EXPECTED_STANDARD_OUTPUT" != "$OBSERVED_STANDARD_OUTPUT" ]]
                                                                                                then
                                                                                                    echo "We expected the payload standard-output to be $EXPECTED_STANDARD_OUTPUT but it was $OBSERVED_STANDARD_OUTPUT" >&2
                                                                                                    ${ failure coreutils jq writeShellApplication yq-go "d1054818" }
                                                                                                fi
                                                                                                EXPECTED_STATUS="${ builtins.toString expected-status }"
                                                                                                OBSERVED_STATUS="$( jq --raw-output ".status" /build/payload )" || ${ failure coreutils jq writeShellApplication yq-go "714592cd" }
                                                                                                if [[ "$EXPECTED_STATUS" != "$OBSERVED_STATUS" ]]
                                                                                                then
                                                                                                    echo "We expected the payload status to be $EXPECTED_STATUS but it was $OBSERVED_STATUS" >&2
                                                                                                    ${ failure coreutils jq writeShellApplication yq-go "d1054818" }
                                                                                                fi
                                                                                                EXPECTED_TRANSIENT="${ builtins.toString expected-transient }"
                                                                                                OBSERVED_TRANSIENT="$( jq --raw-output ".transient" /build/payload )" || ${ failure coreutils jq writeShellApplication yq-go "85ad88e4" }
                                                                                                if [[ "$EXPECTED_TRANSIENT" != "$OBSERVED_TRANSIENT" ]]
                                                                                                then
                                                                                                    echo "We expected the payload transient to be $EXPECTED_TRANSIENT but it was $OBSERVED_TRANSIENT" >&2
                                                                                                    ${ failure coreutils jq writeShellApplication yq-go "e6815070" }
                                                                                                fi
                                                                                                PRE_HASH="${ pre-hash }"
                                                                                                FORMATTED_ARGUMENTS="${ builtins.concatStringsSep " " arguments }"
                                                                                                EXPECTED_HASH="$( echo "$PRE_HASH $EXPECTED_TRANSIENT$FORMATTED_ARGUMENTS $EXPECTED_STANDARD_INPUT $EXPECTED_HAS_STANDARD_INPUT" | sha512sum | cut --characters 1-128 )" || ${ failure coreutils jq writeShellApplication yq-go "e5f7b54d" }
                                                                                                OBSERVED_HASH="$( jq --raw-output ".hash" /build/payload )" || ${ failure coreutils jq writeShellApplication yq-go "a3fb933c" }
                                                                                                if [[ "$EXPECTED_HASH" != "$OBSERVED_HASH" ]]
                                                                                                then
                                                                                                    echo "We expected the payload hash to be $EXPECTED_HASH but it was $OBSERVED_HASH" >&2
                                                                                                    ${ failure coreutils jq writeShellApplication yq-go "9c498620" }
                                                                                                fi
                                                                                                EXPECTED_KEYS="$( echo '${ builtins.toJSON [ "arguments" "dependencies" "description" "has-standard-input" "hash" "index" "originator-pid" "provenance" "standard-error" "standard-input" "standard-output" "status" "targets" "transient" ] }' | jq --raw-output "." )" || ${ failure coreutils jq writeShellApplication yq-go "ecaa9ff9" }
                                                                                                OBSERVED_KEYS="$( jq --raw-output "[keys[]]" /build/payload )" || ${ failure coreutils jq writeShellApplication yq-go "04699ea8" }
                                                                                                if [[ "$EXPECTED_KEYS" != "$OBSERVED_KEYS" ]]
                                                                                                then
                                                                                                    echo "We expected the payload keys to be $EXPECTED_KEYS but it was $OBSERVED_KEYS" >&2
                                                                                                    ${ failure coreutils jq writeShellApplication yq-go "d68a978e" }
                                                                                                fi
                                                                                            '' ;
                                                                                    } ;
                                                                                in "${ test }/bin/test $out" ;
                                                                    name = "check" ;
                                                                    src = ./. ;
                                                                } ;
                                                    in
                                                        {
                                                            check = check ;
                                                            implementation = primary ;
                                                        } ;
                                    } ;
                                listeners =
                                    {
                                        log-event-listener =
                                            {
                                                channel ? "resource" ,
                                                coreutils ,
                                                flock ,
                                                redis ,
                                                resources-directory ,
                                                writeShellApplication ,
                                                yq-go
                                            } :
                                                let
                                                    implementation =
                                                        writeShellApplication
                                                            {
                                                                name = "log-event-listener" ;
                                                                runtimeInputs = [ coreutils redis yq-go ] ;
                                                                text =
                                                                    let
                                                                        append =
                                                                            writeShellApplication
                                                                                {
                                                                                    name = "append" ;
                                                                                    runtimeInputs = [ coreutils flock yq-go ] ;
                                                                                    text =
                                                                                        ''
                                                                                            mkdir --parents ${ resources-directory }/logs
                                                                                            exec 203> ${ resources-directory }/logs/lock
                                                                                            flock -x 203
                                                                                            cat | yq --prettyPrint '[.]' >> ${ resources-directory }/logs/log.yaml
                                                                                        '' ;
                                                                                } ;
                                                                        in
                                                                            ''
                                                                                redis-cli --raw SUBSCRIBE "resource" | while read -r TYPE && read -r CHANNEL && read -r PAYLOAD
                                                                                do
                                                                                    if [[ "$TYPE" == "message" ]] && [[ "$CHANNEL" == "${ channel }" ]]
                                                                                    then
                                                                                        echo "$PAYLOAD" | ${ append }/bin/append
                                                                                    fi
                                                                                done
                                                                            '' ;
                                                            } ;
                                                    in
                                                        {
                                                            check =
                                                                {
                                                                    jq ,
                                                                    log-file ,
                                                                    message ,
                                                                    mkDerivation
                                                                } :
                                                                    mkDerivation
                                                                        {
                                                                            installPhase =
                                                                                let
                                                                                    test2 =
                                                                                        writeShellApplication
                                                                                            {
                                                                                                name = "test" ;
                                                                                                runtimeInputs = [ coreutils flock redis yq-go ] ;
                                                                                                text =
                                                                                                    ''
                                                                                                        OUT="$1"
                                                                                                        touch "$OUT"
                                                                                                        mkdir --parents /build/redis
                                                                                                        redis-server --dir /build/redis --daemonize yes
                                                                                                        while ! redis-cli ping
                                                                                                        do
                                                                                                            sleep 0
                                                                                                        done
                                                                                                        mkdir --parents ${ resources-directory }/logs
                                                                                                        yq --prettyPrint < ${ builtins.toFile "log.json" ( builtins.toJSON log-file ) } > ${ resources-directory }/logs/log.yaml
                                                                                                        mkdir --parents /build/test
                                                                                                        yq --prettyPrint < ${ builtins.toFile "expected.json" ( builtins.toJSON ( builtins.concatLists [ log-file [ message ] ] ) ) } > /build/test/expected
                                                                                                        ${ implementation }/bin/log-event-listener > /build/test/standard-output 2> /build/test/standard-error &
                                                                                                        sleep 10
                                                                                                        redis-cli PUBLISH ${ channel } ${ builtins.toJSON message }
                                                                                                        sleep 10
                                                                                                        exec 203> ${ resources-directory }/logs/lock
                                                                                                        flock -x 203
                                                                                                        if [[ ! -f /build/test/standard-output ]]
                                                                                                        then
                                                                                                            echo We expected a standard output file >&2
                                                                                                            ${ failure coreutils jq writeShellApplication yq-go "27f87ad2" }
                                                                                                        elif [[ -s /build/test/standard-output ]]
                                                                                                        then
                                                                                                            echo We expected a BLANK standard output >&2
                                                                                                            ${ failure coreutils jq writeShellApplication yq-go "9325dc3d" }
                                                                                                        fi
                                                                                                        if [[ ! -f /build/test/standard-error ]]
                                                                                                        then
                                                                                                            echo We expected a standard error file >&2
                                                                                                            ${ failure coreutils jq writeShellApplication yq-go "57209bb9" }
                                                                                                        elif [[ -s /build/test/standard-error ]]
                                                                                                        then
                                                                                                            echo We expected a BLANK standard error >&2
                                                                                                            ${ failure coreutils jq writeShellApplication yq-go "a9b43301" }
                                                                                                        fi
                                                                                                        EXPECTED="$( < /build/test/expected )" || ${ failure coreutils jq writeShellApplication yq-go "" }
                                                                                                        OBSERVED="$( < ${ resources-directory }/logs/log.yaml )" || ${ failure coreutils jq writeShellApplication yq-go "" }
                                                                                                        if [[ "$EXPECTED" != "$OBSERVED" ]]
                                                                                                        then
                                                                                                            echo "${ implementation }/bin/implementation" >&2
                                                                                                            echo We expected the log file to be >&2
                                                                                                            cat /build/test/expected >&2
                                                                                                            echo but it was
                                                                                                            cat ${ resources-directory }/logs/log.yaml >&2
                                                                                                            ${ failure coreutils jq writeShellApplication yq-go "3142578a" }
                                                                                                        fi
                                                                                                '' ;
                                                                                            } ;
                                                                                    in
                                                                                        ''
                                                                                            ${ test2 }/bin/test $out
                                                                                        '' ;
                                                                            name = "check" ;
                                                                            src = ./. ;
                                                                        } ;
                                                            implementation = implementation ;
                                                        } ;
                                    } ;
                                util =
                                    {
                                        failure =
                                            {
                                                coreutils ,
                                                jq ,
                                                mkDerivation ,
                                                writeShellApplication ,
                                                yq-go
                                            } :
                                                let
                                                    implementation = failure coreutils jq writeShellApplication yq-go ;
                                                    in
                                                        {
                                                            check =
                                                                {
                                                                    compile-time-arguments ,
                                                                    run-time-arguments ,
                                                                } :
                                                                    mkDerivation
                                                                        {
                                                                            installPhase =
                                                                                let
                                                                                    test =
                                                                                        writeShellApplication
                                                                                            {
                                                                                                name = "test" ;
                                                                                                runtimeInputs = [ coreutils yq-go ( implementation compile-time-arguments ) ] ;
                                                                                                text =
                                                                                                    ''
                                                                                                        OUT="$1"
                                                                                                        touch "$OUT"
                                                                                                        mkdir --parents /build/test
                                                                                                        if failure ${ builtins.concatStringsSep " " run-time-arguments } > /build/test/standard-output 2> /build/test/standard-error
                                                                                                        then
                                                                                                            STATUS="$?"
                                                                                                        else
                                                                                                            STATUS="$?"
                                                                                                        fi
                                                                                                        STANDARD_OUTPUT="$( < /build/test/standard-output )" || ${ failure coreutils jq writeShellApplication yq-go "" }
                                                                                                        if [[ -n "$STANDARD_OUTPUT" ]]
                                                                                                        then
                                                                                                            echo "We expected no standard output but we got $STANDARD_OUTPUT" >&2
                                                                                                            ${ failure coreutils jq writeShellApplication yq-go "" }
                                                                                                        fi
                                                                                                        EXPECTED_STANDARD_ERROR="$( yq --null-input --prettyPrint '{ "compile-time-arguments" : ${ builtins.toJSON compile-time-arguments } }' )" || ${ failure coreutils jq writeShellApplication yq-go "" }
                                                                                                        OBSERVED_STANDARD_ERROR="$( < /build/test/standard-error )" || ${ failure coreutils jq writeShellApplication yq-go "" }
                                                                                                        if [[ "$EXPECTED_STANDARD_ERROR" != "$OBSERVED_STANDARD_ERROR" ]]
                                                                                                        then
                                                                                                            echo "We expected standard error to be $EXPECTED_STANDARD_ERROR but it was $OBSERVED_STANDARD_ERROR" >&2
                                                                                                            ${ failure coreutils jq writeShellApplication yq-go "" }
                                                                                                        fi
                                                                                                        if [[ "$STATUS" != "64" ]]
                                                                                                        then
                                                                                                            echo "We expected the status to be 64 but we got $STATUS" >&2
                                                                                                            ${ failure coreutils jq writeShellApplication yq-go "" }
                                                                                                        fi
                                                                                                    '' ;
                                                                                            } ;
                                                                                    in
                                                                                        ''
                                                                                            ${ test }/bin/test "$out"
                                                                                        '' ;
                                                                            name = "check" ;
                                                                            src = ./. ;
                                                                        } ;
                                                            implementation = implementation ;
                                                        } ;
                                    } ;
                            } ;
                    } ;
}
