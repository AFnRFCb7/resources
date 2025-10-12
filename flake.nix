{
	inputs = { } ;
	outputs =
		{ self } :
		    {
		        lib =
		            {
		                event-listener =
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
		                                        name = "event-listener" ;
                                                runtimeInputs = [ coreutils redis yq-go ] ;
                                                text =
                                                    ''
                                                        redis-cli --raw SUBSCRIBE "${ channel }" | {
                                                            read -r _     # skip "subscribe"
                                                            read -r _     # skip channel name
                                                            read -r _     # skip
                                                            read -r _     # skip
                                                            read -r _
                                                            read -r PAYLOAD
                                                            mkdir --parents ${ resources-directory }/log
                                                            exec 203> ${ resources-directory }/logs/lock
                                                            flock -x 203
                                                            echo "$PAYLOAD" | yq --prettyPrint "[.]" >> ${ resources-directory }/log.yaml
                                                        }
                                                    '' ;
		                                    } ;
                                    in
                                        {
                                            check =
                                                {
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
                                                                                        redis-cli PUBLISH ${ channel } ${ builtins.toJSON message }
                                                                                        mkdir --parents /build/test
                                                                                        yq --prettyPrint < ${ builtins.toFile "expected.json" ( builtins.toJSON ( builtins.concatLists [ log-file [ message ] ] ) ) } > /build/test/expected
                                                                                        ${ implementation }/bin/event-listener > /build/test/standard-output 2> /build/test/standard-error &
                                                                                        sleep 10
                                                                                        exec 203> ${ resources-directory }/logs/lock
                                                                                        flock -x 203
                                                                                        if [[ ! -f /build/test/standard-output ]]
                                                                                        then
                                                                                            echo We expected a standard output file >&2
                                                                                            exit 64
                                                                                        elif [[ -s /build/test/standard-output ]]
                                                                                        then
                                                                                            echo We expected a BLANK standard output >&2
                                                                                            exit 64
                                                                                        fi
                                                                                        if [[ ! -f /build/test/standard-error ]]
                                                                                        then
                                                                                            echo We expected a standard error file >&2
                                                                                            exit 64
                                                                                        elif [[ -s /build/test/standard-error ]]
                                                                                        then
                                                                                            echo We expected a BLANK standard error >&2
                                                                                            exit 64
                                                                                        fi
                                                                                        EXPECTED="$( < /build/test/expected )" || exit 64
                                                                                        OBSERVED="$( < ${ resources-directory }/logs/log.yaml )" || exit 64
                                                                                        if [[ "$EXPECTED" != "$OBSERVED" ]]
                                                                                        then
                                                                                            echo We expected the log file to be >&2
                                                                                            cat /build/test/expected >&2
                                                                                            echo but it was
                                                                                            cat ${ resources-directory }/logs/log.yaml >&2
                                                                                            ls -lah ${ implementation }
                                                                                            ls -lah ${ implementation }/bin
                                                                                            ls -lah ${ implementation }/bin/event-listener
                                                                                            cat ${ implementation }/bin/event-listener
                                                                                            exit 64
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
                                                                                        fixture
                                                                                        while ! redis-cli ping
                                                                                        do
                                                                                            sleep 0
                                                                                        done
                                                                                        subscribe &
                                                                                        if RESOURCE="$( ${ implementation } ${ builtins.concatStringsSep " " arguments } ${ standard-input_ } 2> /build/standard-error )"
                                                                                        then
                                                                                            STATUS="$?"
                                                                                        else
                                                                                            STATUS="$?"
                                                                                        fi
                                                                                        if [[ "${ standard-output }" != "$RESOURCE" ]]
                                                                                        then
                                                                                            echo "We expected the standard output to be ${ standard-output } but it was $RESOURCE" >&2
                                                                                            cat ${ resources-directory }/debug >&2
                                                                                            ${ failures_ "c727ba4d" }
                                                                                        fi
                                                                                        if [[ "${ builtins.toString status }" != "$STATUS" ]]
                                                                                        then
                                                                                            echo "We expected the status to be ${ builtins.toString status } but it was $STATUS" >&2
                                                                                            ${ failures_ "57cd83f9" }
                                                                                        fi
                                                                                        if [[ ! -f /build/standard-error ]]
                                                                                        then
                                                                                            echo "We expected the standard error file to exist" >&2
                                                                                            ${ failures_ "da8b2593" }
                                                                                        fi
                                                                                        if [[ -s /build/standard-error ]]
                                                                                        then
                                                                                            STANDARD_ERROR="$( < /build/standard-error )" || ${ failures_ "1c4d6ced" }
                                                                                            echo "We expected the standard error file to be empty but it was $STANDARD_ERROR" >&2
                                                                                            ${ failures_ "a6d0f7ed" }
                                                                                        fi
                                                                                        while [[ ! -f /build/payload ]]
                                                                                        do
                                                                                            redis-cli PUBLISH ${ channel } '{"test" : true}'
                                                                                        done
                                                                                        EXPECTED_ARGUMENTS="$( jq --null-input '${ builtins.toJSON arguments }' )" || ${ failures_ "c0a73187" }
                                                                                        OBSERVED_ARGUMENTS="$( jq ".arguments" /build/payload )" || ${ failures_ "44440f2d" }
                                                                                        if [[ "$EXPECTED_ARGUMENTS" != "$OBSERVED_ARGUMENTS" ]]
                                                                                        then
                                                                                            echo "We expected the payload arguments to be $EXPECTED_ARGUMENTS but it was $OBSERVED_ARGUMENTS" >&2
                                                                                            ${ failures_ "d3fb3e9b" }
                                                                                        fi
                                                                                        EXPECTED_DEPENDENCIES="$( jq --null-input '${ builtins.toJSON expected-dependencies }' )" || ${ failures_ "2c5c7ae4" }
                                                                                        OBSERVED_DEPENDENCIES="$( jq ".dependencies" /build/payload )" || ${ failures_ "8d52f2db" }
                                                                                        if [[ "$EXPECTED_DEPENDENCIES" != "$OBSERVED_DEPENDENCIES" ]]
                                                                                        then
                                                                                            echo "We expected the payload dependencies to be $EXPECTED_DEPENDENCIES but it was $OBSERVED_DEPENDENCIES" >&2
                                                                                            ${ failures_ "12073df9" }
                                                                                        fi
                                                                                        EXPECTED_DESCRIPTION="$( echo '${ builtins.toJSON description }' | jq '.' )" || ${ failures_ "f7b03966" }
                                                                                        OBSERVED_DESCRIPTION="$( jq ".description" /build/payload )" || ${ failures_ "4f4a2232" }
                                                                                        if [[ "$EXPECTED_DESCRIPTION" != "$OBSERVED_DESCRIPTION" ]]
                                                                                        then
                                                                                            echo "We expected the payload description to be $EXPECTED_DESCRIPTION but it was $OBSERVED_DESCRIPTION" >&2
                                                                                            ${ failures_ "4656e7d5" }
                                                                                        fi
                                                                                        EXPECTED_INDEX="${ expected-index }"
                                                                                        OBSERVED_INDEX="$( jq --raw-output ".index" /build/payload )" || ${ failures_ "abdf3e25" }
                                                                                        if [[ "$EXPECTED_INDEX" != "$OBSERVED_INDEX" ]]
                                                                                        then
                                                                                            echo "We expected the payload index to be $EXPECTED_INDEX but it was $OBSERVED_INDEX" >&2
                                                                                            ${ failures_ "7a3de836" }
                                                                                        fi
                                                                                        EXPECTED_HAS_STANDARD_INPUT="${ if builtins.typeOf standard-input == "null" then "false" else "true" }"
                                                                                        OBSERVED_HAS_STANDARD_INPUT="$( jq --raw-output '."has-standard-input"' /build/payload )" || ${ failures_ "1de78471" }
                                                                                        if [[ "$EXPECTED_HAS_STANDARD_INPUT" != "$OBSERVED_HAS_STANDARD_INPUT" ]]
                                                                                        then
                                                                                            echo "We expected the payload has-standard-input to be $EXPECTED_STANDARD_INPUT but it was $OBSERVED_STANDARD_INPUT" >&2
                                                                                            ${ failures_ "89b51e3a" }
                                                                                        fi
                                                                                        EXPECTED_ORIGINATOR_PID="${ builtins.toString expected-originator-pid }"
                                                                                        OBSERVED_ORIGINATOR_PID="$( jq --raw-output '."originator-pid"' /build/payload )" || ${ failures_ "26e0cb2b" }
                                                                                        if [[ "$EXPECTED_ORIGINATOR_PID" != "$OBSERVED_ORIGINATOR_PID" ]]
                                                                                        then
                                                                                            echo "We expected the payload originator-pid to be $EXPECTED_ORIGINATOR_PID but it was $OBSERVED_ORIGINATOR_PID" >&2
                                                                                            ${ failures_ "db64a1c9" }
                                                                                        fi
                                                                                        EXPECTED_PROVENANCE="${ expected-provenance }"
                                                                                        OBSERVED_PROVENANCE="$( jq --raw-output ".provenance" /build/payload )" || ${ failures_ "26e0cb2b" }
                                                                                        if [[ "$EXPECTED_PROVENANCE" != "$OBSERVED_PROVENANCE" ]]
                                                                                        then
                                                                                            echo "We expected the payload provenance to be $EXPECTED_PROVENANCE but it was $OBSERVED_PROVENANCE" >&2
                                                                                            ${ failures_ "c07c110c" }
                                                                                        fi
                                                                                        EXPECTED_TARGETS="$( jq --null-input '${ builtins.toJSON expected-targets }' )" || ${ failures_ "e9fa75bf" }
                                                                                        OBSERVED_TARGETS="$( jq ".targets" /build/payload )" || ${ failures_ "ad928300" }
                                                                                        if [[ "$EXPECTED_TARGETS" != "$OBSERVED_TARGETS" ]]
                                                                                        then
                                                                                            echo "We expected the payload targets to be $EXPECTED_TARGETS but it was $OBSERVED_TARGETS" >&2
                                                                                            ${ failures_ "85ad88e4" }
                                                                                        fi
                                                                                        EXPECTED_STANDARD_ERROR="${ expected-standard-error }"
                                                                                        OBSERVED_STANDARD_ERROR="$( jq --raw-output '."standard-error"' /build/payload )" || ${ failures_ "714592cd" }
                                                                                        if [[ "$EXPECTED_STANDARD_ERROR" != "$OBSERVED_STANDARD_ERROR" ]]
                                                                                        then
                                                                                            echo "We expected the payload standard-error to be $EXPECTED_STANDARD_ERROR but it was $OBSERVED_STANDARD_ERROR" >&2
                                                                                            ${ failures_ "dcea8e50" }
                                                                                        fi
                                                                                        EXPECTED_STANDARD_INPUT="${ if builtins.typeOf standard-input == "null" then "" else standard-input }"
                                                                                        OBSERVED_STANDARD_INPUT="$( jq --raw-output '."standard-input"' /build/payload )" || ${ failures_ "714592cd" }
                                                                                        if [[ "$EXPECTED_STANDARD_INPUT" != "$OBSERVED_STANDARD_INPUT" ]]
                                                                                        then
                                                                                            echo "We expected the payload standard-input to be $EXPECTED_STANDARD_INPUT but it was $OBSERVED_STANDARD_INPUT" >&2
                                                                                            ${ failures_ "11e3a4aa" }
                                                                                        fi
                                                                                        EXPECTED_STANDARD_OUTPUT="${ expected-standard-output }"
                                                                                        OBSERVED_STANDARD_OUTPUT="$( jq --raw-output '."standard-output"' /build/payload )" || ${ failures_ "714592cd" }
                                                                                        if [[ "$EXPECTED_STANDARD_OUTPUT" != "$OBSERVED_STANDARD_OUTPUT" ]]
                                                                                        then
                                                                                            echo "We expected the payload standard-output to be $EXPECTED_STANDARD_OUTPUT but it was $OBSERVED_STANDARD_OUTPUT" >&2
                                                                                            ${ failures_ "d1054818" }
                                                                                        fi
                                                                                        EXPECTED_STATUS="${ builtins.toString expected-status }"
                                                                                        OBSERVED_STATUS="$( jq --raw-output ".status" /build/payload )" || ${ failures_ "714592cd" }
                                                                                        if [[ "$EXPECTED_STATUS" != "$OBSERVED_STATUS" ]]
                                                                                        then
                                                                                            echo "We expected the payload status to be $EXPECTED_STATUS but it was $OBSERVED_STATUS" >&2
                                                                                            ${ failures_ "d1054818" }
                                                                                        fi
                                                                                        EXPECTED_TRANSIENT="${ builtins.toString expected-transient }"
                                                                                        OBSERVED_TRANSIENT="$( jq --raw-output ".transient" /build/payload )" || ${ failures_ "85ad88e4" }
                                                                                        if [[ "$EXPECTED_TRANSIENT" != "$OBSERVED_TRANSIENT" ]]
                                                                                        then
                                                                                            echo "We expected the payload transient to be $EXPECTED_TRANSIENT but it was $OBSERVED_TRANSIENT" >&2
                                                                                            ${ failures_ "e6815070" }
                                                                                        fi
                                                                                        PRE_HASH="${ pre-hash }"
                                                                                        FORMATTED_ARGUMENTS="${ builtins.concatStringsSep " " arguments }"
                                                                                        EXPECTED_HASH="$( echo "$PRE_HASH $EXPECTED_TRANSIENT$FORMATTED_ARGUMENTS $EXPECTED_STANDARD_INPUT $EXPECTED_HAS_STANDARD_INPUT" | sha512sum | cut --characters 1-128 )" || ${ failures_ "e5f7b54d" }
                                                                                        OBSERVED_HASH="$( jq --raw-output ".hash" /build/payload )" || ${ failures_ "a3fb933c" }
                                                                                        if [[ "$EXPECTED_HASH" != "$OBSERVED_HASH" ]]
                                                                                        then
                                                                                            echo "We expected the payload hash to be $EXPECTED_HASH but it was $OBSERVED_HASH" >&2
                                                                                            ${ failures_ "9c498620" }
                                                                                        fi
                                                                                        EXPECTED_KEYS="$( echo '${ builtins.toJSON [ "arguments" "dependencies" "description" "has-standard-input" "hash" "index" "originator-pid" "provenance" "standard-error" "standard-input" "standard-output" "status" "targets" "transient" ] }' | jq --raw-output "." )" || ${ failures_ "ecaa9ff9" }
                                                                                        OBSERVED_KEYS="$( jq --raw-output "[keys[]]" /build/payload )" || ${ failures_ "04699ea8" }
                                                                                        if [[ "$EXPECTED_KEYS" != "$OBSERVED_KEYS" ]]
                                                                                        then
                                                                                            echo "We expected the payload keys to be $EXPECTED_KEYS but it was $OBSERVED_KEYS" >&2
                                                                                            ${ failures_ "d68a978e" }
                                                                                        fi
                                                                                    '' ;
                                                                    } ;
                                                                in "${ test }/bin/test $out" ;
                                                    name = "check" ;
                                                    src = ./. ;
                                                } ;
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
                                                                JSON="$( cat | jq --compact-output '. + { "description" : ${ builtins.toJSON description } }' )" || ${ failures_ "7b8f1293" }
                                                                redis-cli PUBLISH "${ channel }" "$JSON" 2> /dev/null || true
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
                                                                        cat <&0 > "$STANDARD_INPUT_FILE"
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
                                                                                "has-standard-input" : $HAS_STANDARD_INPUT }
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
                                                                        STANDARD_INPUT_FILE="$( mktemp )" || ${ failures_ "f66f966d" }
                                                                        export STANDARD_INPUT_FILE
                                                                        HAS_STANDARD_INPUT=true
                                                                        cat <&0 > "$STANDARD_INPUT_FILE"
                                                                        STANDARD_INPUT="$( cat "$STANDARD_INPUT_FILE" )" || ${ failures_ "ffff1b30" }
                                                                    fi
                                                                    mkdir --parents ${ resources-directory }
                                                                    ARGUMENTS=( "$@" )
                                                                    ARGUMENTS_JSON="$( printf '%s\n' "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" | jq -R . | jq -s . )"
                                                                    TRANSIENT=${ transient_ }
                                                                    ORIGINATOR_PID="$(ps -o ppid= -p "$PPID" | tr -d '[:space:]')" || ${ failures_ "833fbd3f" }
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
                                                                        DEPENDENCIES="$( find "${ resources-directory }/links/$INDEX" -mindepth 1 -maxdepth 1 -exec basename {} \; | jq -R . | jq -s . )" || ${ failures_ "54d472fb" }
                                                                        TARGETS="$( find "${ resources-directory }/mounts/$INDEX" -mindepth 1 -maxdepth 1 -exec basename {} \; | jq -R . | jq -s . )" || ${ failures_ "54d472fb" }
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
                                                                        DEPENDENCIES="$( find "${ resources-directory }/links/$INDEX" -mindepth 1 -maxdepth 1 -exec basename {} \; | jq -R . | jq -s . )" || ${ failures_ "54d472fb" }
                                                                        TARGETS="$( find "${ resources-directory }/mounts/$INDEX" -mindepth 1 -maxdepth 1 -exec basename {} \; | jq -R . | jq -s . )" || ${ failures_ "54d472fb" }
                                                                        if [[ "$STATUS" == 0 ]] && [[ ! -s "$STANDARD_ERROR_FILE" ]] && [[ "$TARGET_HASH_EXPECTED" == "$TARGET_HASH_OBSERVED" ]]
                                                                        then
                                                                            echo "ba5bfd7d-d507-4c8d-a18c-79d22d6e5dfd MOUNT=$MOUNT" >> ${ resources-directory }/debug
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
                                                                            echo "aafcf4c2-2303-41ad-a3df-ee3daded2553 MOUNT=$MOUNT" >> ${ resources-directory }/debug
                                                                            mkdir --parents ${ resources-directory }/canonical
                                                                            ln --symbolic "$MOUNT" "${ resources-directory }/canonical/$HASH"
                                                                            echo -n "$MOUNT"
                                                                            echo "aa84788f-590a-4251-9c4f-ad68148a7f5b MOUNT=$MOUNT" >> ${ resources-directory }/debug
                                                                        else
                                                                            # COVERAGE cc71c31856d494c0fa6298238c3a88465a027005abb5a35f1adf0d1f5f70bd127dd0fc8c7f3143403fe2707aec2aa596424388676d733a8999ed14274bbb7257 when the targets do not match
                                                                            # COVERAGE b6685e582f11196ead4fa3459fd16d9111f0fbba91c26c7e8d72357d1a363e9cb2a8f5b002ca50b0a6227082922c66bebbc0baf07bb8abec3bc72e4faed24410 when there is standard error
                                                                            # COVERAGE 18bcee8bb15fcb7bc19928b5f59f311c3892ed31c6941b94bb7f2193020730889c79d0ab473c680630bcb96ed3c900ef7c67583682dbdbed6044f046c725e0a9 when there is a non-zero status
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
                                                            bool = path : value : if value then "$( sequential ) || ${ failures_ "808f8e2c" }" else "-1" ;
                                                        }
                                                        transient ;
                                            in "${ setup }/bin/setup" ;
                                    pre-hash = builtins.hashString "sha512" ( builtins.toJSON description ) ;
                                    in
                                        {
                                            check = check ;
                                            implementation = implementation ;
                                        } ;

                            } ;
			} ;
}
