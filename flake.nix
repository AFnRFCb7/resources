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
                        description ? null ,
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
                                    payload ,
                                    redacted ? "1f41874b0cedd39ac838e4ef32976598e2bec5b858e6c1400390821c99948e9e205cff9e245bc6a42d273742bb2c48b9338e7d7e0d38c09a9f3335412b97f02f" ,
                                    standard-input ? null ,
                                    standard-output ,
                                    status ? 0
                                } :
                                    mkDerivation
                                        {
                                            installPhase =
                                                let
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
                                                                runtimeInputs = [ coreutils redis subscribe ] ;
                                                                text =
                                                                    let
                                                                        standard-input_ =
                                                                            visitor.lib.implementation
                                                                                {
                                                                                    null = path : value : "" ;
                                                                                    string = path : value : "< ${ builtins.toFile "standard-input" value }" ;
                                                                                }
                                                                                standard-input ;
                                                                        in
                                                                            ''
                                                                                OUT="$1"
                                                                                touch "$OUT"
                                                                                mkdir --parents /build/redis
                                                                                redis-server --dir /build/redis --daemonize yes
                                                                                while ! redis-cli ping
                                                                                do
                                                                                    sleep 1
                                                                                done
                                                                                subscribe &
                                                                                sleep 1m
                                                                                if RESOURCE="$( ${ implementation } ${ builtins.concatStringsSep " " arguments } ${ standard-input_ } > /build/standard-error )"
                                                                                then
                                                                                    STATUS="$?"
                                                                                else
                                                                                    STATUS="$?"
                                                                                fi
                                                                                if [[ "${ standard-output }" != "$RESOURCE" ]]
                                                                                then
                                                                                    echo "We expected the standard output to be ${ standard-output } but it was $RESOURCE" >&2
                                                                                    ${ failures_ "c727ba4d" }
                                                                                fi
                                                                                if [[ "${ builtins.toString status }" != "$STATUS" ]]
                                                                                then
                                                                                    echo ${ implementation }
                                                                                    cat ${ resources-directory }/debug
                                                                                    echo "We expected the status to be ${ builtins.toString status } but it was $STATUS" >&2
                                                                                    ${ failures_ "57cd83f9" }
                                                                                fi
                                                                                if [[ ! -f /build/standard-error ]]
                                                                                then
                                                                                    echo "We expected the standard error file to exist" >&2
                                                                                    ${ failures_ "da8b2593" }
                                                                                fi
                                                                                if [[ ! -s /build/standard-error ]]
                                                                                then
                                                                                    STANDARD_ERROR="$( < /build/standard-error )" || ${ failures_ "1c4d6ced" }
                                                                                    echo "We expected the standard error file to be empty but it was $STANDARD_ERROR" >&2
                                                                                    ${ failures_ "a6d0f7ed" }
                                                                                fi
                                                                                while [[ ! -f /build/payload ]]
                                                                                do
                                                                                    redis-cli PUBLISH ${ channel } '{"test" : true}'
                                                                                done
                                                                                PAYLOAD="$( < /build/payload )" || ${ failures_ "a94f732b" }
                                                                                if [[ "${ builtins.toJSON payload }" != "$PAYLOAD" ]]
                                                                                then
                                                                                    echo "We expected the payload to be ${ builtins.toJSON payload } but it was $PAYLOAD"
                                                                                    cat ${ resources-directory }/debug
                                                                                    ${ failures_ "2ce1635f" }
                                                                                fi
                                                                            '' ;
                                                            } ;
                                                        in "${ test }/bin/test $out" ;
                                            name = "check" ;
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
                                    publish =
                                        writeShellApplication
                                            {
                                                name = "publish" ;
                                                runtimeInputs = [ coreutils jq redis ] ;
                                                text =
                                                    ''
                                                        echo "22b880d3-4d59-4763-936e-e6bec70cf03d" >> ${ resources-directory }/debug
                                                        # redis-cli PUBLISH "${ channel }" '{ "test" : "no standard-input" }'
                                                        JSON="$( jq --null-input '{ "description" : "description" }' )" || ${ failures_ "7b8f1293" }
                                                        redis-cli PUBLISH "${ channel }" "$JSON"
                                                        # cat | jq '. + { description : ${ builtins.toJSON description } }' | redis-cli PUBLISH "${ channel }"
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
                                                                STANDARD_INPUT_FILE="$( mktemp )" || ${ failures_ "7f77cdad" }
                                                            else
                                                                HAS_STANDARD_INPUT=true
                                                                timeout 1m cat > "$STANDARD_INPUT_FILE"
                                                                STANDARD_INPUT="$( cat "$STANDARD_INPUT_FILE" )" || ${ failures_ "fbb0e2f8" }
                                                            fi
                                                            TRANSIENT=${ transient_ }
                                                            ORIGINATOR_PID="$( ps -o ppid= -p "$PPID" )" || ${ failures_ "833fbd3f" }
                                                            HASH="$( echo "${ pre-hash } ${ builtins.concatStringsSep "" [ "$TRANSIENT" "$" "{" "ARGUMENTS[*]" "}" ] } $STANDARD_INPUT $HAS_STANDARD_INPUT" | sha512sum | cut --characters 1-128 )" || ${ failures_ "bc3e1b88" }
                                                            mkdir --parents "${ resources-directory }/locks"
                                                            ARGUMENTS_YAML="$( printf '%s\n' "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" | jq -R . | jq -s . | yq -P )" || ${ failures_ "fc776602" }
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
                                                                MOUNT="$( readlink "${ resources-directory }/canonical/$HASH" )" || ${ failures_ "bf282501" }
                                                                export MOUNT
                                                                INDEX="$( basename "$MOUNT" )" || ${ failures_ "26213048" }
                                                                export INDEX
                                                                export PROVENENCE=cached
                                                                mkdir --parents "${ resources-directory }/locks/$INDEX"
                                                                exec 211> "${ resources-directory }/locks/$INDEX/setup.lock"
                                                                flock -s 211
                                                                jq \
                                                                    --null-input \
                                                                    --arg HAS_STANDARD_INPUT "$HAS_STANDARD_INPUT" \
                                                                    '{
                                                                        "has-standard-input : $HAS_STANDARD_INPUT }"
                                                                    }' | publish
                                                                ln --symbolic "$MOUNT" "${ resources-directory }/canonical/$HASH"
                                                                echo -n "$MOUNT"
                                                            else
                                                                INDEX="$( sequential )" || ${ failures_ "d162db9f" }
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
                                                                        "has-standard-input : $HAS_STANDARD_INPUT }"
                                                                    }' | publish
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
                                                                STANDARD_INPUT_FILE="$( mktemp )" || ${ failures_ "f66f966d" }
                                                                export STANDARD_INPUT_FILE
                                                                HAS_STANDARD_INPUT=true
                                                                cat > "$STANDARD_INPUT_FILE"
                                                                STANDARD_INPUT="$( cat "$STANDARD_INPUT_FILE" )" || ${ failures_ "ffff1b30" }
                                                            fi
                                                            mkdir --parents ${ resources-directory }
                                                            ARGUMENTS=( "$@" )
                                                            TRANSIENT=${ transient_ }
                                                            ORIGINATOR_PID="$( ps -o ppid= -p "$PPID" | awk '{print $1}' )" || ${ failures_ "833fbd3f" }
                                                            export ORIGINATOR_PID
                                                            HASH="$( echo "${ pre-hash } ${ builtins.concatStringsSep "" [ "$TRANSIENT" "$" "{" "ARGUMENTS[*]" "}" ] } $STANDARD_INPUT $HAS_STANDARD_INPUT" | sha512sum | cut --characters 1-128 )" || ${ failures_ "7849a979" }
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
                                                                MOUNT="$( readlink "${ resources-directory }/canonical/$HASH" )" || ${ failures_ "ae2d1658" }
                                                                export MOUNT
                                                                INDEX="$( basename "$MOUNT" )" || ${ failures_ "277afc07" }
                                                                export INDEX
                                                                export PROVENANCE=cached
                                                                mkdir --parents "${ resources-directory }/locks/$INDEX"
                                                                jq \
                                                                    --null-input \
                                                                    --arg HAS_STANDARD_INPUT "$HAS_STANDARD_INPUT" \
                                                                    '{
                                                                        "has-standard-input : $HAS_STANDARD_INPUT }"
                                                                    }' | publish
                                                                echo -n "$MOUNT"
                                                            else
                                                                INDEX="$( sequential )" || ${ failures_ "cab66847" }
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
                                                                STANDARD_ERROR_FILE="$( mktemp )" || ${ failures_ "b07f7374" }
                                                                export STANDARD_ERROR_FILE
                                                                STANDARD_OUTPUT_FILE="$( mktemp )" || ${ failures_ "29c19af1" }
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
                                                                TARGET_HASH_OBSERVED="$( find "$MOUNT" -mindepth 1 -maxdepth 1 -exec basename {} \; | LC_ALL=C sort | tr --delete "\n" | sha512sum | cut --characters 1-128 )" || ${ failures_ "db2517b1" }
                                                                STANDARD_ERROR="$( < "$STANDARD_ERROR_FILE" )" || ${ failures_ "260fbb3c" }
                                                                export STANDARD_ERROR
                                                                STANDARD_OUTPUT="$( < "$STANDARD_OUTPUT_FILE" )" || ${ failures_ "d1b1f5be" }
                                                                export STANDARD_OUTPUT
                                                                if [[ "$STATUS" == 0 ]] && [[ ! -s "$STANDARD_ERROR_FILE" ]] && [[ "$TARGET_HASH_EXPECTED" == "$TARGET_HASH_OBSERVED" ]]
                                                                then
                                                                    # shellcheck disable=SC2016
                                                                    jq \
                                                                        --null-input \
                                                                        --arg HAS_STANDARD_INPUT "$HAS_STANDARD_INPUT" \
                                                                        '{
                                                                            "has-standard-input : $HAS_STANDARD_INPUT }"
                                                                        }' | publish
                                                                    echo -n "$MOUNT"
                                                                else
                                                                    jq \
                                                                        --null-input \
                                                                        --arg HAS_STANDARD_INPUT "$HAS_STANDARD_INPUT" \
                                                                        '{
                                                                            "has-standard-input : $HAS_STANDARD_INPUT }"
                                                                        }' | publish
                                                                    ${ failures_ "b385d889" }
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
                                                            CURRENT="$( < ${ resources-directory }/sequential/sequential.counter )" || ${ failures_ "c9a94abb" }
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
                                                    bool = path : value : if value then "$( sequential ) || ${ failures_ "808f8e2c" }" else "" ;
                                                }
                                                transient ;
                                    in "${ setup }/bin/setup" ;
                            in
                                {
                                    check = check ;
                                    implementation = implementation ;
                                } ;
			} ;
}
