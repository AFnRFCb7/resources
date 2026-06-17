# 9499764299738338
{
	inputs = { } ;
	outputs =
		{ self } :
		    {
		        lib =
		            { buildFHSUserEnv , resources-directory , visitor , writeShellApplication } :
                        let
                            implementation =
                                {
                                    user =
                                        {
                                            init
                                        } :
                                            let
                                                application =
                                                    writeShellApplication
                                                        {
                                                            name = "resource" ;
                                                            runtimeInputs =
                                                                [
                                                                    (
                                                                        buildFHSUserEnv
                                                                            {
                                                                                extraBwrapArgs =
                                                                                    [
                                                                                        "--bind" "$SIGNAL_FILE" "/signal"
                                                                                    ] ;
                                                                                name = "resource" ;
                                                                                runScript =
                                                                                    ''
                                                                                        resource
                                                                                    '' ;
                                                                                targetPkgs =
                                                                                    pkgs :
                                                                                        [
                                                                                            (
                                                                                                pkgs.writeShellApplication
                                                                                                    {
                                                                                                        name = "resource" ;
                                                                                                        runtimeInputs =
                                                                                                            let
                                                                                                                init_ =
                                                                                                                    visitor
                                                                                                                        {
                                                                                                                            lambda = path : value : value null ;
                                                                                                                            null = path : value : null ;
                                                                                                                        }
                                                                                                                        init ;
                                                                                                                in
                                                                                                                    [
                                                                                                                        (
                                                                                                                            pkgs.writeShellApplication
                                                                                                                                {
                                                                                                                                    name = "resource-hash" ;
                                                                                                                                    runtimeInputs = [ pkgs.coreutils ] ;
                                                                                                                                    text =
                                                                                                                                        let
                                                                                                                                            in
                                                                                                                                                ''
                                                                                                                                                    echo -en "4496715738691135 HAS_STANDARD_INPUT=$HAS_STANDARD_INPUT STANDARD_INPUT=$STANDARD_INPUT" | sha512sum | cut --characters 1-128
                                                                                                                                                '' ;
                                                                                                                                }
                                                                                                                        )
                                                                                                                    ] ;
                                                                                                        text =
                                                                                                            ''
                                                                                                                cleanup( ) {
                                                                                                                    echo "$?" > /signal
                                                                                                                }
                                                                                                                trap cleanup EXIT
                                                                                                                RESOURCE_HASH="$( resource-hash )" || exit 163
                                                                                                                echo "$RESOURCE_HASH"
                                                                                                            '' ;
                                                                                                    }
                                                                                            )
                                                                                        ] ;
                                                                            }
                                                                    )
                                                                ] ;
                                                            text =
                                                                ''
                                                                    mkdir --parents "${ resources-directory }/temporary"
                                                                    JSON_FILE=$( mktemp "${ resources-directory }/temporary/XXXXXXXX" )" || exit 161
                                                                    ARGUMENTS_JSON="$( printf '%s\n' "$@" | jq --raw-input . | jq --slurp . )" || exit 179
                                                                    SIGNAL_FILE="$( mktemp "${ resources-directory }/temporary/XXXXXXXX" )" || exit 163
                                                                    export SIGNAL_FILE
                                                                    cleanup( ) {
                                                                        SIGNAL_VALUE="$( cat "$SIGNAL_FILE" )" || exit 164
                                                                        rm "$JSON_FILE" "$SIGNAL_FILE"
                                                                        exit "$SIGNAL_VALUE"
                                                                    }
                                                                    trap cleanup EXIT
                                                                    if [[ -t 0 ]]
                                                                    then
                                                                        jq --null-input --argjson ARGUMENTS "$ARGUMENTS_JSON" '{ "arguments" : $ARGUMENTS }' > "$JSON_FILE"
                                                                    else
                                                                        jq --argjson ARGUMENTS "$ARGUMENTS_JSON" '{ "arguments" : $ARGUMENTS , "standard-input" : . }' > "$JSON_FILE"
                                                                    fi
                                                                    resource
                                                                '' ;
                                                        } ;
                                                in "${ application }/bin/resource" ;
                                } ;
                            in
                                {
                                    check = null ;
                                    implementation = implementation ;
                                } ;
            } ;
}
