{
    inputs = { nixpkgs.url = "github:Nixos/nixpkgs/nixos-24.11" ; visitor.url = "github:AFnRFCb7/visitor" ; } ;
    outputs =
        { nixpkgs , self , visitor } :
            {
                lib =
                    {
                        nixpkgs ? nixpkgs ,
                        system ,
                        visitor ? visitor.lib.implementation
                    } :
                        let
                            implementation =
                                {
                                    gc-root-directory ,
                                    resources ,
                                    resources-directory ,
                                    seed ,
                                    visitor ? visitor.lib { }.implementation
                                } :
                                    {
                                        user =
                                            {
                                                init
                                            } :
                                                let
                                                    setup_ =
                                                        let
                                                            application =
                                                                pkgs.writeShellApplication
                                                                    {
                                                                        name = "setup" ;
                                                                        runtimeInputs =
                                                                            [
                                                                                pkgs.coreutils
                                                                                pkgs.flock
                                                                                (
                                                                                    pkgs.buildFHSUserEnv
                                                                                        {
                                                                                            extraBwrapArgs =
                                                                                                [
                                                                                                    "--bindfs" "${ gc-root-directory }" "${ gc-root-directory }"
                                                                                                    "--bindfs" "${ resources-directory }/canonical" "${ resources-directory }/canonical"
                                                                                                    "--bindfs" "${ resources-directory }/locks" "${ resources-directory }/locks"
                                                                                                    "--bindfs" "${ resources-directory }/logs" "${resources-directory }/logs"
                                                                                                    "--bindfs" "${ resources-directory }/pids" "${ resources-directory }/pids"
                                                                                                    "--bindfs" "${ resources-directory }/sequential" "${ resources-directory }/sequential"
                                                                                                    "--bindfs" "${ resources-directory }/mounts" "${ resources-directory }/mounts"
                                                                                                    "--tmpfs" "/scratch"
                                                                                                    "--bindfs" "$SIGNAL_FILE" "/signal"
                                                                                                ] ;
                                                                                            name = "setup" ;
                                                                                            runScript =
                                                                                                ''
                                                                                                    cleanup ( ) {
                                                                                                        echo "$?" > /signal
                                                                                                    }
                                                                                                    trap cleanup EXIT
                                                                                                    if [[ -t 0 ]]
                                                                                                    then
                                                                                                        HAS_STANDARD_INPUT=false
                                                                                                        STANDARD_INPUT="$( cat )" || failure 9385732636793239
                                                                                                    else
                                                                                                        HAS_STANDARD_INPUT=true
                                                                                                        STANDARD_INPUT="$( cat )" || failure 1197218473895833
                                                                                                    fi
                                                                                                    if "$HAS_STANDARD_INPUT"
                                                                                                    then
                                                                                                        HASH="$( hash <<< "$STANDARD_INPUT" )" || failure 4679565614566485
                                                                                                    else
                                                                                                        HASH="$( hash )" || failure 3689575179341484
                                                                                                    fi
                                                                                                    if [[ ! -L "${ resources-directory }/canonical/$HASH" ]]
                                                                                                    then
                                                                                                        if "$HAS_STANDARD_INPUT"
                                                                                                        then
                                                                                                            entrypoint "$@" <<< "$STANDARD_INPUT
                                                                                                        else
                                                                                                            entrypoint "$@"
                                                                                                        fi
                                                                                                    fi
                                                                                                    echo "$ORIGINATOR_PID" > "${ resources-directory }/pids/$INDEX/$ORIGINATOR_PID"
                                                                                                '' ;
                                                                                            targetPkgs =
                                                                                                pkgs :
                                                                                                    let
                                                                                                        failure =
                                                                                                            pkgs.writeShellApplication
                                                                                                                {
                                                                                                                    name = "failure" ;
                                                                                                                    runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.yq-go ] ;
                                                                                                                    text =
                                                                                                                        ''
                                                                                                                            ARGUMENTS="$( printf '%s\n' "$@" | jq --raw-input . | jq --slurp . )" || exit 181
                                                                                                                            if [[ -t 0 ]]
                                                                                                                            then
                                                                                                                                jq --null-input --argjson ARGUMENTS "$ARGUMENTS" \'$ARGUMENTS\' | yq eval --prettyPrint
                                                                                                                                exit 122
                                                                                                                            else
                                                                                                                                STANDARD_INPUT="$( cat )" || exit 186
                                                                                                                                jq --null-input --argjson ARGUMENTS "$ARGUMENTS" --arg STANDARD_INPUT "$STANDARD_INPUT" \'{ "arguments" : $ARGUMENTS , "standard-input" : $STANDARD_INPUT }\' | yq eval --prettyPrint
                                                                                                                                exit 172
                                                                                                                            fi
                                                                                                                        '' ;
                                                                                                                } ;
                                                                                                        gc-root =
                                                                                                            pkgs.writeShellApplication
                                                                                                                {
                                                                                                                    name = "gc-root" ;
                                                                                                                    runtimeInputs = [ failure pkgs.coreutils sequential ] ;
                                                                                                                    text =
                                                                                                                        ''
                                                                                                                            "${ builtins.concatStringsSep "" [ "$" "{" "INDEX:?INDEX must be exported:  9849637684268429" "}" ] }"
                                                                                                                            DIRECTORY="$( dirname "$@" )" || failure 6519445882384145
                                                                                                                            SEQUENCE="$( sequential )" || failure 8869875554956429
                                                                                                                            mkdir --parents ${ gc-root-directory }/$INDEX/$DIRECTORY/$SEQUENCE"
                                                                                                                            ln --symbolic --force ${ gc-root-directory }/$INDEX/$DIRECTORY/$SEQUENCE"
                                                                                                                        '' ;
                                                                                                                } ;
                                                                                                        init_ =
                                                                                                            let
                                                                                                                identity =
                                                                                                                    {
                                                                                                                        entrypoint ,
                                                                                                                        recoveries ? null
                                                                                                                    } :
                                                                                                                        {
                                                                                                                            entrypoint = { failure = failure ; gc-root = gc-root ; pkgs = pkgs ; resources = resources ; seed = seed ; sequential = sequential ; trace = trace ; wrap = wrap ; } ;
                                                                                                                            recoveries =
                                                                                                                                visitor
                                                                                                                                    {

                                                                                                                                    }
                                                                                                                                    recoveries ;
                                                                                                                        } ;
                                                                                                            in identity init ;
                                                                                                        sequential =
                                                                                                            pkgs.writeShellApplication
                                                                                                                {
                                                                                                                    name = "sequential" ;
                                                                                                                    runtimeInputs = [ failure pkgs.coreutils pkgs.flock ] ;
                                                                                                                    text =
                                                                                                                        ''
                                                                                                                            exec 154> ${ resources-directory }/logs/sequential
                                                                                                                            flock 154
                                                                                                                            CURRENT="$( cat ${ resources-directory }/sequential )" || failure 4442346955934376
                                                                                                                            NEXT=$(( ( CURRENT + 1 ) % 10000000000000000 ))
                                                                                                                            echo "$NEXT" > ${ resources-directory }/sequential
                                                                                                                            echo "$CURRENT"
                                                                                                                        '' ;
                                                                                                                } ;
                                                                                                        trace =
                                                                                                            pkgs.writeShellApplication
                                                                                                                {
                                                                                                                    name = "trace" ;
                                                                                                                    runtimeInputs = [ failure pkgs.coreutils pkgs.jq pkgs.yq-go ] ;
                                                                                                                    text =
                                                                                                                        ''
                                                                                                                            exec 180> ${ resources-directory }/locks/trace
                                                                                                                            flock -x 180
                                                                                                                            ARGUMENTS="$( printf '%s\n' "$@" | jq --raw-input . | jq --slurp . )" || failure 5742523868313349
                                                                                                                            if [[ -t 0 ]]
                                                                                                                            then
                                                                                                                                jq --null-input --argjson ARGUMENTS "$ARGUMENTS" \'$ARGUMENTS\' | yq eval --prettyPrint "[.]" >> ${ resources-directory }/logs/trace.log.yaml
                                                                                                                            else
                                                                                                                                STANDARD_INPUT="$( cat )" || failure 3382282922851825
                                                                                                                                jq --null-input --argjson ARGUMENTS "$ARGUMENTS" --arg STANDARD_INPUT "$STANDARD_INPUT" \'{ "arguments" : $ARGUMENTS , "standard-input" : $STANDARD_INPUT }\' | yq eval --prettyPrint "[.]" >> ${ resources-directory }/logs/trace.log.yaml
                                                                                                                            fi
                                                                                                                        '' ;
                                                                                                                } ;
                                                                                                        wrap =
                                                                                                            pkgs.writeShellApplication
                                                                                                                {
                                                                                                                    name = "wrap" ;
                                                                                                                    runtimeInputs = [ ] ;
                                                                                                                    text =
                                                                                                                        ''

                                                                                                                        '' ;
                                                                                                                } ;
                                                                                                        in
                                                                                                            [
                                                                                                                (
                                                                                                                    pkgs.writeShellApplication
                                                                                                                        {
                                                                                                                            name = "hash" ;
                                                                                                                            runtimeInputs = [ pkgs.coreutils ] ;
                                                                                                                            text =
                                                                                                                                let
                                                                                                                                    pre-hash =
                                                                                                                                        visitor
                                                                                                                                            {
                                                                                                                                                list = path : list : builtins.hashString "sha512" ( builtins.concatStringsSep "" ( builtins.concatLists [ path list ] ) ) ;
                                                                                                                                                string = path : value : builtins.hashString "sha512" ( builtins.concatStringsSep "" ( builtins.concatLists [ path [ value ] ] ) ) ;
                                                                                                                                                set = path : set : builtins.hashString "sha512" ( builtins.concatStringsSep "" ( builtins.concatLists [ path ( builtins.attrValues set ) ] ) ) ;
                                                                                                                                            }
                                                                                                                                            {
                                                                                                                                                init = init_ ;
                                                                                                                                            } ;
                                                                                                                                    in
                                                                                                                                        ''
                                                                                                                                            HASH="$( echo ${ pre-hash } | sha512sum | cut --characters 1-128 )"
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
                                                                                exec 160> ${ resources-directory }/locks/setup
                                                                                flock 160
                                                                                mkdir --parents ${ gc-root-directory }
                                                                                mkdir --parents ${ resources-directory }/canonical
                                                                                mkdir --parents ${ resources-directory }/logs
                                                                                mkdir --parents ${ resources-directory }/pids
                                                                                if [[ ! -f ${ resources-directory }/sequential ]]
                                                                                then
                                                                                    echo 0 > ${ resources-directory }/sequential
                                                                                fi
                                                                                SIGNAL_FILE="$( mktemp )"
                                                                                export SIGNAL_FILE
                                                                                if [[ -t 0 ]]
                                                                                then
                                                                                    ORIGINATOR_PID="$( ps -o ppid= -p "$PPID" | tr -d '[:space:]' )" || failure 9886817613456157
                                                                                    export ORIGINATOR_PID
                                                                                    setup "$@"
                                                                                else
                                                                                    PENULTIMATE_ORIGINATOR_PID="$( ps -o ppid= -p "$PPID" | tr -d '[:space:]' )" || failure 3264316381735222
                                                                                    ORIGINATOR_PID="$( ps -o ppid= -p "$PENULTIMATE_ORIGINATOR_PID" | tr -d '[:space:]' )" || failure 8551739414442514
                                                                                    export ORIGINATOR_PID
                                                                                    setup "$@"
                                                                                fi
                                                                                SIGNAL_VALUE="$( cat "$SIGNAL_FILE" )"
                                                                                rm "$SIGNAL_FILE"
                                                                                exit "$SIGNAL_VALUE"
                                                                            '' ;
                                                                    } ;
                                                            in "${ application }/bin/setup" ;
                                                        pkgs = builtins.getAttr system nixpkgs.legacyPackages ;
                                                    in
                                                        {
                                                            failure ? 5265823577854516 ,
                                                            setup ? setup : setup
                                                        } :
                                                            ''${ setup setup_ } || failure ${ failure }'' ;
                                        hooks =
                                            let
                                                cleaner = null ;
                                                logger = null ;
                                                releaser = null ;
                                                in
                                                    {
                                                        scripts =
                                                            {
                                                                cleaner = cleaner ;
                                                                logger = logger ;
                                                                releaser = releaser ;
                                                            } ;
                                                    } ;
                                    } ;
                            in
                                {
                                    checks = null ;
                                    implementation = implementation ;
                                } ;
            } ;
}