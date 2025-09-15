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
                                    commands ,
                                    delay ,
                                    diffutils ,
                                    golden-path ,
                                    processes ,
                                    redacted ? "1f41874b0cedd39ac838e4ef32976598e2bec5b858e6c1400390821c99948e9e205cff9e245bc6a42d273742bb2c48b9338e7d7e0d38c09a9f3335412b97f02f"
                                } :
                                    null ;
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
                                                runtimeInputs = [ coreutils redis ] ;
                                                text =
                                                    ''
                                                        TEMPORARY_FILE="$( mktemp )" || ${ failures_ "74a1c409" }
                                                        cat | yq eval "." "$CHANNEL" "$TEMPORARY_FILE"
                                                    '' ;
                                            } ;
                                    setup =
                                        if builtins.typeOf init == "null" then
                                            writeShellApplication
                                                {
                                                    name = "setup" ;
                                                    runtimeInputs = [ coreutils ps publish sequential ] ;
                                                    text =
                                                        ''
                                                            if [[ -t 0 ]]
                                                            then
                                                                HAS_STANDARD_INPUT=false
                                                                STANDARD_INPUT=
                                                                STANDARD_INPUT_FILE="$( temporary )" || ${ failures_ "7f77cdad" }
                                                            else
                                                                HAS_STANDARD_INPUT=true
                                                                timeout 1m cat > "$STANDARD_INPUT_FILE"
                                                                STANDARD_INPUT="$( cat "$STANDARD_INPUT_FILE" )" || ${ failures_ "fbb0e2f8" }
                                                            fi
                                                            TRANSIENT=${ transient_ }
                                                            ORIGINATOR_PID="$( ps -o ppid= -p "$PPID" )" || ${ failures_ "833fbd3f" }
                                                            HASH="$( echo "${ pre-hash } ${ builtins.concatStringsSep "" [ "$TRANSIENT" "$" "{" "ARGUMENTS[*]" "}" ] } $STANDARD_INPUT $HAS_STANDARD_INPUT" | sha512sum | cut --characters 1-128 )" || ${ failures_ "bc3e1b88" }
                                                            mkdir --parents "${ resources-directory }/locks"
                                                            ARGUMENTS_JSON="$( printf '%s\n' "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" | jq -R . | jq -s .)" || ${ failures_ "" }
                                                            export ARGUMENTS_JSON
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
                                                                yq eval '{ arguments : strenv(ARGUMENTS) , has-standard-input : strenv(HAS_STANDARD_INPUT) , hash : strenv(HASH) , index : strenv(INDEX) , originator-pid : strenv(ORIGINATOR_PID) , provenance : strenv(PROVENANCE) , standard-input: strenv(STANDARD_INPUT) , transient : strenv(TRANSIENT) }' | publish ${ channel }
                                                                ln --symbolic "$MOUNT" "${ resources-directory }/canonical/$HASH"
                                                                echo -n "$MOUNT"
                                                            else
                                                                MOUNT_INDEX="$( sequential )" || ${ failures_ "d162db9f" }
                                                                export MOUNT_INDEX
                                                                export PROVENANCE=new
                                                                mkdir --parents "${ resources-directory }/locks/$MOUNT_INDEX"
                                                                exec 211> "${ resources-directory }/locks/$MOUNT_INDEX/setup.lock"
                                                                flock -s 211
                                                                MOUNT="${ resources-directory }/mounts/$MOUNT_INDEX"
                                                                mkdir --parents "$MOUNT"
                                                                mkdir --parents ${ resources-directory }/canonical
                                                                yq eval '{ arguments : strenv(ARGUMENTS) , has-standard-input : strenv(HAS_STANDARD_INPUT) , hash : strenv(HASH) , index : strenv(INDEX) , originator-pid : strenv(ORIGINATOR_PID) , provenance : strenv(PROVENANCE) , standard-input: strenv(STANDARD_INPUT) , transient : strenv(TRANSIENT) }' | publish ${ channel }
                                                                ln --symbolic "$MOUNT" "${ resources-directory }/canonical/$HASH"
                                                                echo -n "$MOUNT"
                                                            fi
                                                        '' ;
                                                }
                                        else
                                            writeShellApplication
                                                {
                                                    name = "setup" ;
                                                    runtimeInputs = [ coreutils ps redis sequential ] ;
                                                    text =
                                                        ''
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
                                                            ARGUMENTS=( "$@" )
                                                            TRANSIENT=${ transient_ }
                                                            ORIGINATOR_PID="$( ps -o ppid= -p "$PPID" | awk '{print $1}' )" || ${ failures_ "833fbd3f" }
                                                            export ORIGINATOR_PID
                                                            HASH="$( echo "${ pre-hash } ${ builtins.concatStringsSep "" [ "$TRANSIENT" "$" "{" "ARGUMENTS[*]" "}" ] } $STANDARD_INPUT $HAS_STANDARD_INPUT" | sha512sum | cut --characters 1-128 )" || ${ failures_ "7849a979" }
                                                            export HASH
                                                            mkdir --parents "${ resources-directory }/locks"
                                                            ARGUMENTS_JSON="$( printf '%s\n' "${ builtins.concatStringsSep "" [ "$" "{" "ARGUMENTS[@]" "}" ] }" | jq -R . | jq -s .)" || ${ failures_ "" }
                                                            export ARGUMENTS_JSON
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
                                                                mkdir --parents "${ resources-directory }/locks/$MOUNT_INDEX"
                                                                yq eval '{ arguments : strenv(ARGUMENTS) , has-standard-input : strenv(HAS_STANDARD_INPUT) , hash : strenv(HASH) , index : strenv(INDEX) , originator-pid : strenv(ORIGINATOR_PID) , provenance : strenv(PROVENANCE) , standard-input: strenv(STANDARD_INPUT) , transient : strenv(TRANSIENT) }' | publish ${ channel }
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
                                                                MOUNT="${ resources-directory }/mounts/$MOUNT_INDEX"
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
                                                                    yq eval '{ arguments : strenv(ARGUMENTS) , has-standard-input : strenv(HAS_STANDARD_INPUT) , hash : strenv(HASH) , index : strenv(INDEX) , init-application : "${ init-application }" , originator-pid : strenv(ORIGINATOR_PID) , provenance : strenv(PROVENANCE) , standard-error: strenv(STANDARD_ERROR) , standard-input: strenv(STANDARD_INPUT) , standard-output: strenv(STANDARD_OUTPUT) , status : strenv(STATUS) , transient : strenv(TRANSIENT) }' | publish ${ channel }
                                                                    echo -n "$MOUNT"
                                                                else
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
                                                        NEXT=$(( CURRENT + 1 ))
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
