{
	inputs = { } ;
	outputs =
		{ self } :
		    {
		        lib =
                    {
                        buildFHSUserEnv ,
                        channel ? "resource" ,
                        coreutils ,
                        failure ,
                        findutils ,
                        flock ,
                        init ? null ,
                        jq ,
                        makeBinPath ,
                        makeWrapper ,
                        mkDerivation ,
                        ps ,
                        redis ,
                        resources ? null ,
                        resources-directory ,
                        seed ? null ,
                        targets ? [ ] ,
                        transient ? false ,
                        visitor ,
                        writeShellApplication ,
                        yq-go
                    } @primary :
                        let
                            _failure = failure.lib { coreutils = coreutils ; jq = jq ; mkDerivation = mkDerivation ; writeShellApplication = writeShellApplication ; visitor = visitor ; yq-go = yq-go ; } ;
                            _visitor = visitor.lib { } ;
                            description =
                                let
                                    seed = path : value : [ { path = path ; type = builtins.typeOf value ; value = if builtins.typeOf value == "lambda" then null else value ; } ] ;
                                    in
                                        _visitor.implementation
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
                            implementation2 = implementation ;
                            implementation =
                                let
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
                                                            runScript = init { resources = resources ; self = "${ resources-directory }/mounts/$INDEX" ; } ;
                                                        } ;
                                            publish =
                                                writeShellApplication
                                                    {
                                                        name = "publish" ;
                                                        runtimeInputs = [ coreutils jq redis ] ;
                                                        text =
                                                            ''
                                                                JSON="$( cat | jq --compact-output '. + { "description" : ${ builtins.toJSON description } }' )" || ${ _failure.implementation "7b8f1293" }/bin/failure
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
                                                                        STANDARD_INPUT_FILE="$( mktemp )" || ${ _failure.implementation "7f77cdad" }/bin/failure
                                                                    else
                                                                        HAS_STANDARD_INPUT=true
                                                                        cat <&0 > "$STANDARD_INPUT_FILE"
                                                                        STANDARD_INPUT="$( cat "$STANDARD_INPUT_FILE" )" || ${ _failure.implementation "fbb0e2f8" }/bin/failure
                                                                    fi
                                                                    TRANSIENT=${ transient_ }
                                                                    ORIGINATOR_PID="$( ps -o ppid= -p "$PPID" )" || ${ _failure.implementation "833fbd3f" }/bin/failure
                                                                    HASH="$( echo "${ pre-hash } ${ builtins.concatStringsSep "" [ "$TRANSIENT" "$" "{" "ARGUMENTS[*]" "}" ] } $STANDARD_INPUT $HAS_STANDARD_INPUT" | sha512sum | cut --characters 1-128 )" || ${ _failure.implementation "bc3e1b88" }/bin/failure
                                                                    mkdir --parents "${ resources-directory }/locks"
                                                                    ARGUMENTS_YAML="$( printf '%s\n' "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" | jq -R . | jq -s . | yq -P )" || ${ _failure.implementation "fc776602" }/bin/failure
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
                                                                        MOUNT="$( readlink "${ resources-directory }/canonical/$HASH" )" || ${ _failure.implementation "bf282501" }/bin/failure
                                                                        export MOUNT
                                                                        INDEX="$( basename "$MOUNT" )" || ${ _failure.implementation "26213048" }/bin/failure
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
                                                                        INDEX="$( sequential )" || ${ _failure.implementation "d162db9f" }/bin/failure
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
                                                                        STANDARD_INPUT_FILE="$( mktemp )" || ${ _failure.implementation "f66f966d" }/bin/failure
                                                                        export STANDARD_INPUT_FILE
                                                                        HAS_STANDARD_INPUT=true
                                                                        cat <&0 > "$STANDARD_INPUT_FILE"
                                                                        STANDARD_INPUT="$( cat "$STANDARD_INPUT_FILE" )" || ${ _failure.implementation "ffff1b30" }/bin/failure
                                                                    fi
                                                                    mkdir --parents ${ resources-directory }
                                                                    ARGUMENTS=( "$@" )
                                                                    ARGUMENTS_JSON="$( printf '%s\n' "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" | jq -R . | jq -s . )"
                                                                    TRANSIENT=${ transient_ }
                                                                    ORIGINATOR_PID="$(ps -o ppid= -p "$PPID" | tr -d '[:space:]')" || ${ _failure.implementation "833fbd3f" }/bin/failure
                                                                    export ORIGINATOR_PID
                                                                    HASH="$( echo "${ pre-hash } ${ builtins.concatStringsSep "" [ "$TRANSIENT" "$" "{" "ARGUMENTS[*]" "}" ] } $STANDARD_INPUT $HAS_STANDARD_INPUT" | sha512sum | cut --characters 1-128 )" || ${ _failure.implementation "7849a979" }/bin/failure
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
                                                                        MOUNT="$( readlink "${ resources-directory }/canonical/$HASH" )" || ${ _failure.implementation "ae2d1658" }
                                                                        export MOUNT
                                                                        INDEX="$( basename "$MOUNT" )" || ${ _failure.implementation "277afc07" }
                                                                        export INDEX
                                                                        export PROVENANCE=cached
                                                                        DEPENDENCIES="$( find "${ resources-directory }/links/$INDEX" -mindepth 1 -maxdepth 1 -exec basename {} \; | jq -R . | jq -s . )" || ${ _failure.implementation "54d472fb" }/bin/failure
                                                                        TARGETS="$( find "${ resources-directory }/mounts/$INDEX" -mindepth 1 -maxdepth 1 -exec basename {} \; | jq -R . | jq -s . )" || ${ _failure.implementation "54d472fb" }/bin/failure
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
                                                                        INDEX="$( sequential )" || ${ _failure.implementation "cab66847" }/bin/failure
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
                                                                        STANDARD_ERROR_FILE="$( mktemp )" || ${ _failure.implementation "b07f7374" }/bin/failure
                                                                        export STANDARD_ERROR_FILE
                                                                        STANDARD_OUTPUT_FILE="$( mktemp )" || ${ _failure.implementation "29c19af1" }/bin/failure
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
                                                                        TARGET_HASH_OBSERVED="$( find "$MOUNT" -mindepth 1 -maxdepth 1 -exec basename {} \; | LC_ALL=C sort | tr --delete "\n" | sha512sum | cut --characters 1-128 )" || ${ _failure.implementation "db2517b1" }/bin/failure
                                                                        STANDARD_ERROR="$( cat "$STANDARD_ERROR_FILE" )" || ${ _failure.implementation "260fbb3c" }/bin/failure
                                                                        export STANDARD_ERROR
                                                                        STANDARD_OUTPUT="$( cat "$STANDARD_OUTPUT_FILE" )" || ${ _failure.implementation "d1b1f5be" }/bin/failure
                                                                        export STANDARD_OUTPUT
                                                                        DEPENDENCIES="$( find "${ resources-directory }/links/$INDEX" -mindepth 1 -maxdepth 1 -exec basename {} \; | jq -R . | jq -s . )" || ${ _failure.implementation "54d472fb" }/bin/failure
                                                                        TARGETS="$( find "${ resources-directory }/mounts/$INDEX" -mindepth 1 -maxdepth 1 -exec basename {} \; | sort | jq -R . | jq -s . )" || ${ _failure.implementation "54d472fb" }/bin/failure
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
                                                                            ${ _failure.implementation "bd13c123" }/bin/failure
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
                                                                    CURRENT="$( cat ${ resources-directory }/sequential/sequential.counter )" || ${ _failure.implementation "c9a94abb" }/bin/failure
                                                                else
                                                                    CURRENT=0
                                                                fi
                                                                NEXT=$(( ( CURRENT + 1 ) % 10000000000000000 ))
                                                                echo "$NEXT" > ${ resources-directory }/sequential/sequential.counter
                                                                printf "%016d\n" "$CURRENT"
                                                            '' ;
                                                    } ;
                                                transient_ =
                                                    _visitor.implementation
                                                        {
                                                            bool = path : value : if value then "$( sequential ) || ${ _failure.implementation "808f8e2c" }/bin/failure" else "-1" ;
                                                        }
                                                        transient ;
                                            in "${ setup }/bin/setup" ;
                                    in script : ''"$( ${ script implementation } )" || ${ _failure.implementation "5b05da86" }/bin/failure'' ;
                                    # in script : ''true || ${ _failure.implementation "5b05da86" }/bin/failure'' ;
                            pre-hash = builtins.hashString "sha512" ( builtins.toJSON description ) ;
                            in
                                {
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
                                            resources-directory ? "/build/resources" ,
                                            resources-directory-fixture ? null ,
                                            self ? "self" ,
                                            standard-input ? null ,
                                            standard-error ? "" ,
                                            standard-output ? "" ,
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
                                                            mount = builtins.concatStringsSep "/" [ resources-directory "mounts" expected-index ] ;
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
                                                                            let
                                                                                resource =
                                                                                    _visitor.implementation
                                                                                        {
                                                                                            null = path : value : implementation ( implementation : "${ implementation } ${ builtins.concatStringsSep " " arguments } 2> /build/standard-error" ) ;
                                                                                            string = path : value : ( setup : "${ setup } ${ builtins.concatStringsSep " " arguments } < ${ builtins.toFile "standard-input" value } 2> /build/standard-error" null null ) ;
                                                                                            set = path : value : "fc242a830da7e1998322763f87910f3e1e093823aa0bfd26ce85abf6a08c0f9ed586c81c3915367bd59eaff00e3b9122906346f4b736fd015053271c595b4335" ;
                                                                                        }
                                                                                        standard-input ;
                                                                                in
                                                                                    ''
                                                                                        OUT="$1"
                                                                                        mkdir --parents "$OUT"
                                                                                        mkdir --parents /build/redis
                                                                                        redis-server --dir /build/redis --daemonize yes
                                                                                        fixture
                                                                                        while ! redis-cli ping
                                                                                        do
                                                                                            sleep 0
                                                                                        done
                                                                                        subscribe &
                                                                                        if RESOURCE=${ resource } 2> /build/standard-error
                                                                                        then
                                                                                            STATUS="$?"
                                                                                        else
                                                                                            STATUS="$?"
                                                                                        fi
                                                                                        while [[ ! -f /build/payload ]]
                                                                                        do
                                                                                            redis-cli PUBLISH ${ channel } '{"test" : true}'
                                                                                        done
                                                                                        EXPECTED_ARGUMENTS="$( jq --null-input '${ builtins.toJSON arguments }' )" || ${ _failure.implementation "c0a73187" }
                                                                                        OBSERVED_ARGUMENTS="$( jq ".arguments" /build/payload )" || ${ _failure.implementation "44440f2d" }
                                                                                        if [[ "$EXPECTED_ARGUMENTS" != "$OBSERVED_ARGUMENTS" ]]
                                                                                        then
                                                                                            ${ _failure.implementation "d3fb3e9b" }/bin/failure "We expected the payload arguments to be $EXPECTED_ARGUMENTS but it was $OBSERVED_ARGUMENTS"
                                                                                        fi
                                                                                        EXPECTED_DEPENDENCIES="$( jq --null-input '${ builtins.toJSON expected-dependencies }' )" || ${ _failure.implementation "2c5c7ae4" }
                                                                                        OBSERVED_DEPENDENCIES="$( jq ".dependencies" /build/payload )" || ${ _failure.implementation "8d52f2db" }
                                                                                        if [[ "$EXPECTED_DEPENDENCIES" != "$OBSERVED_DEPENDENCIES" ]]
                                                                                        then
                                                                                            ${ _failure.implementation "12073df9" }/bin/failure "We expected the payload dependencies to be $EXPECTED_DEPENDENCIES but it was $OBSERVED_DEPENDENCIES"
                                                                                        fi
                                                                                        EXPECTED_DESCRIPTION="$( echo '${ builtins.toJSON description }' | jq '.' )" || ${ _failure.implementation "f7b03966" }
                                                                                        OBSERVED_DESCRIPTION="$( jq ".description" /build/payload )" || ${ _failure.implementation "4f4a2232" }
                                                                                        if [[ "$EXPECTED_DESCRIPTION" != "$OBSERVED_DESCRIPTION" ]]
                                                                                        then
                                                                                            ${ _failure.implementation "4656e7d5" }/bin/failure "We expected the payload description to be $EXPECTED_DESCRIPTION but it was $OBSERVED_DESCRIPTION"
                                                                                        fi
                                                                                        EXPECTED_INDEX="${ expected-index }"
                                                                                        OBSERVED_INDEX="$( jq --raw-output ".index" /build/payload )" || ${ _failure.implementation "abdf3e25" }/bin/failure
                                                                                        if [[ "$EXPECTED_INDEX" != "$OBSERVED_INDEX" ]]
                                                                                        then
                                                                                            ${ _failure.implementation "7a3de836" }/bin/failure "We expected the payload index to be $EXPECTED_INDEX but it was $OBSERVED_INDEX"
                                                                                        fi
                                                                                        EXPECTED_HAS_STANDARD_INPUT="${ if builtins.typeOf standard-input == "null" then "false" else "true" }"
                                                                                        OBSERVED_HAS_STANDARD_INPUT="$( jq --raw-output '."has-standard-input"' /build/payload )" || ${ _failure.implementation "1de78471" }
                                                                                        if [[ "$EXPECTED_HAS_STANDARD_INPUT" != "$OBSERVED_HAS_STANDARD_INPUT" ]]
                                                                                        then
                                                                                            ${ _failure.implementation "89b51e3a" }/bin/failure "We expected the payload has-standard-input to be $EXPECTED_STANDARD_INPUT but it was $OBSERVED_STANDARD_INPUT"
                                                                                        fi
                                                                                        EXPECTED_ORIGINATOR_PID="${ builtins.toString expected-originator-pid }"
                                                                                        OBSERVED_ORIGINATOR_PID="$( jq --raw-output '."originator-pid"' /build/payload )" || ${ _failure.implementation "26e0cb2b" }/bin/failure
                                                                                        if [[ "$EXPECTED_ORIGINATOR_PID" != "$OBSERVED_ORIGINATOR_PID" ]]
                                                                                        then
                                                                                            ${ _failure.implementation "db64a1c9" } "We expected the payload originator-pid to be $EXPECTED_ORIGINATOR_PID but it was $OBSERVED_ORIGINATOR_PID"
                                                                                        fi
                                                                                        EXPECTED_PROVENANCE="${ expected-provenance }"
                                                                                        OBSERVED_PROVENANCE="$( jq --raw-output ".provenance" /build/payload )" || ${ _failure.implementation "26e0cb2b" }/bin/failure
                                                                                        if [[ "$EXPECTED_PROVENANCE" != "$OBSERVED_PROVENANCE" ]]
                                                                                        then
                                                                                            ${ _failure.implementation "c07c110c" }/bin/failure "We expected the payload provenance to be $EXPECTED_PROVENANCE but it was $OBSERVED_PROVENANCE"
                                                                                        fi
                                                                                        EXPECTED_TARGETS="$( jq --null-input '${ builtins.toJSON expected-targets }' )" || ${ _failure.implementation "e9fa75bf" }/bin/failure
                                                                                        OBSERVED_TARGETS="$( jq ".targets" /build/payload )" || ${ _failure.implementation "ad928300" }/bin/failure
                                                                                        if [[ "$EXPECTED_TARGETS" != "$OBSERVED_TARGETS" ]]
                                                                                        then
                                                                                            ${ _failure.implementation "85ad88e4" }/bin/failure "We expected the payload targets to be $EXPECTED_TARGETS but it was $OBSERVED_TARGETS"
                                                                                        fi
                                                                                        EXPECTED_STANDARD_ERROR="${ expected-standard-error }"
                                                                                        OBSERVED_STANDARD_ERROR="$( jq --raw-output '."standard-error"' /build/payload )" || ${ _failure.implementation "714592cd" }/bin/failure
                                                                                        if [[ "$EXPECTED_STANDARD_ERROR" != "$OBSERVED_STANDARD_ERROR" ]]
                                                                                        then
                                                                                            ${ _failure.implementation "dcea8e50" }/bin/failure "We expected the payload standard-error to be $EXPECTED_STANDARD_ERROR but it was $OBSERVED_STANDARD_ERROR"
                                                                                        fi
                                                                                        EXPECTED_STANDARD_INPUT="${ if builtins.typeOf standard-input == "null" then "" else standard-input }"
                                                                                        OBSERVED_STANDARD_INPUT="$( jq --raw-output '."standard-input"' /build/payload )" || ${ _failure.implementation "714592cd" }/bin/failure
                                                                                        if [[ "$EXPECTED_STANDARD_INPUT" != "$OBSERVED_STANDARD_INPUT" ]]
                                                                                        then
                                                                                            ${ _failure.implementation "11e3a4aa" }/bin/failure "We expected the payload standard-input to be $EXPECTED_STANDARD_INPUT but it was $OBSERVED_STANDARD_INPUT"
                                                                                        fi
                                                                                        EXPECTED_STANDARD_OUTPUT="${ expected-standard-output }"
                                                                                        OBSERVED_STANDARD_OUTPUT="$( jq --raw-output '."standard-output"' /build/payload )" || ${ _failure.implementation "714592cd" }/bin/failure
                                                                                        if [[ "$EXPECTED_STANDARD_OUTPUT" != "$OBSERVED_STANDARD_OUTPUT" ]]
                                                                                        then
                                                                                            ${ _failure.implementation "d1054818" }/bin/failure "We expected the payload standard-output to be $EXPECTED_STANDARD_OUTPUT but it was $OBSERVED_STANDARD_OUTPUT"
                                                                                        fi
                                                                                        EXPECTED_STATUS="${ builtins.toString expected-status }"
                                                                                        OBSERVED_STATUS="$( jq --raw-output ".status" /build/payload )" || ${ _failure.implementation "714592cd" }/bin/failure
                                                                                        if [[ "$EXPECTED_STATUS" != "$OBSERVED_STATUS" ]]
                                                                                        then
                                                                                            ${ _failure.implementation "d1054818" }/bin/failure "We expected the payload status to be $EXPECTED_STATUS but it was $OBSERVED_STATUS"
                                                                                        fi
                                                                                        EXPECTED_TRANSIENT="${ builtins.toString expected-transient }"
                                                                                        OBSERVED_TRANSIENT="$( jq --raw-output ".transient" /build/payload )" || ${ _failure.implementation "85ad88e4" }/bin/failure
                                                                                        if [[ "$EXPECTED_TRANSIENT" != "$OBSERVED_TRANSIENT" ]]
                                                                                        then
                                                                                            ${ _failure.implementation "e6815070" }/bin/failure "We expected the payload transient to be $EXPECTED_TRANSIENT but it was $OBSERVED_TRANSIENT"
                                                                                        fi
                                                                                        PRE_HASH="${ pre-hash }"
                                                                                        FORMATTED_ARGUMENTS="${ builtins.concatStringsSep " " arguments }"
                                                                                        EXPECTED_HASH="$( echo "$PRE_HASH $EXPECTED_TRANSIENT$FORMATTED_ARGUMENTS $EXPECTED_STANDARD_INPUT $EXPECTED_HAS_STANDARD_INPUT" | sha512sum | cut --characters 1-128 )" || ${ _failure.implementation "e5f7b54d" }/bin/failure
                                                                                        OBSERVED_HASH="$( jq --raw-output ".hash" /build/payload )" || ${ _failure.implementation "a3fb933c" }/bin/failure
                                                                                        if [[ "$EXPECTED_HASH" != "$OBSERVED_HASH" ]]
                                                                                        then
                                                                                            ${ _failure.implementation "9c498620" }/bin/failure "We expected the payload hash to be $EXPECTED_HASH but it was $OBSERVED_HASH"
                                                                                        fi
                                                                                        EXPECTED_KEYS="$( echo '${ builtins.toJSON [ "arguments" "dependencies" "description" "has-standard-input" "hash" "index" "originator-pid" "provenance" "standard-error" "standard-input" "standard-output" "status" "targets" "transient" ] }' | jq --raw-output "." )" || ${ _failure.implementation "ecaa9ff9" }/bin/failure
                                                                                        OBSERVED_KEYS="$( jq --raw-output "[keys[]]" /build/payload )" || ${ _failure.implementation "04699ea8" }/bin/failure
                                                                                        if [[ "$EXPECTED_KEYS" != "$OBSERVED_KEYS" ]]
                                                                                        then
                                                                                            ${ _failure.implementation "d68a978e" }/bin/failure "We expected the payload keys to be $EXPECTED_KEYS but it was $OBSERVED_KEYS"
                                                                                        fi
                                                                                        EXPECTED_SELF=${ mount }
                                                                                        OBSERVED_SELF="$( cat "${ mount }/${ self }" )" || ${ _failure.implementation "0f7fe006" }/bin/failure
                                                                                        if [[ "$EXPECTED_SELF" != "$OBSERVED_SELF" ]]
                                                                                        then
                                                                                            ${ _failure.implementation "0140fc7d" }/bin/failure "We expected the self to be $EXPECTED_SELF but it was $OBSERVED_SELF"
                                                                                        fi
                                                                                        if [[ "${ standard-output }" != "$RESOURCE" ]]
                                                                                        then
                                                                                            ${ _failure.implementation "043022f8" }/bin/failure "We expected the standard output to be ${ standard-output } but it was $RESOURCE"
                                                                                        fi
                                                                                        if [[ "${ builtins.toString status }" != "$STATUS" ]]
                                                                                        then
                                                                                            ${ _failure.implementation "57cd83f9" }/bin/failure "We expected the status to be ${ builtins.toString status } but it was $STATUS"
                                                                                        fi
                                                                                        cp /build/standard-error "$OUT/standard-error"
                                                                                        if ! diff --unified ${ builtins.toFile "standard-error" standard-error } /build/standard-error
                                                                                        then
                                                                                            cp /build/standard-error "$OUT/standard-error"
                                                                                            ${ _failure.implementation "a6d0f7ed" }/bin/failure "We expected the standard error file to be ${ builtins.toFile "standard-error" standard-error } but it was $OUT/standard-error"
                                                                                        fi
                                                                                    '' ;
                                                                    } ;
                                                                in "${ test }/bin/test $out" ;
                                                    name = "check" ;
                                                    src = ./. ;
                                                } ;
                                    implementation = implementation ;
                                } ;
            } ;
}
