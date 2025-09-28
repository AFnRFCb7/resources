{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    let
                        implementation =
                            {
                                bool ? builtins.null ,
                                default ? path : value : builtins.throw "The definition at ${ builtins.concatStringsSep " / " ( builtins.concatLists [ [ "*ROOT*" ] ( builtins.map builtins.toJSON path ) ] ) } is invalid.  It is of type ${ builtins.typeOf value }.  It is ${ if builtins.any ( t : t == builtins.typeOf value ) [ "bool" "float" "int" "null" "path" "string" ] then  builtins.toJSON value else "unstringable" }." ,
                                float ? builtins.null ,
                                int ? builtins.null ,
                                lambda ? builtins.null ,
                                list ? path : list : list ,
                                null ? builtins.null ,
                                path ? builtins.null ,
                                set ? path : set : set ,
                                string ? builtins.null
                            } : value :
                                    let
                                        elem =
                                            path : value :
                                                let
                                                    visitor =
                                                        let
                                                            visitor =
                                                                let
                                                                    filtered-visitors =
                                                                        let
                                                                            all-visitors =
                                                                                let
                                                                                    list-visitor =
                                                                                        if builtins.typeOf list == "lambda" then
                                                                                            {
                                                                                                name = "list" ;
                                                                                                value = path : value : list path ( builtins.genList ( index : elem ( builtins.concatLists [ path [ index ] ] ) ( builtins.elemAt value index ) ) ( builtins.length value ) ) ;
                                                                                            }
                                                                                        else builtins.throw "The complex list aggregator is not lambda but ${ builtins.typeOf list }." ;
                                                                                    set-visitor =
                                                                                        if builtins.typeOf set == "lambda" then
                                                                                            {
                                                                                                name = "set" ;
                                                                                                value = path : value : set path ( builtins.mapAttrs ( name : value : elem ( builtins.concatLists [ path [ name ] ] ) value ) value ) ;
                                                                                            }
                                                                                        else builtins.throw "The complex set aggregator is not lambda but ${ builtins.typeOf set }." ;
                                                                                    simple-visitors =
                                                                                        let
                                                                                            simple-visitors =
                                                                                                let
                                                                                                    identity =
                                                                                                        {
                                                                                                            bool ? builtins.null ,
                                                                                                            float ? builtins.null ,
                                                                                                            int ? builtins.null ,
                                                                                                            lambda ? builtins.null ,
                                                                                                            null ? builtins.null ,
                                                                                                            path ? builtins.null ,
                                                                                                            string ? builtins.null
                                                                                                        } :
                                                                                                            {
                                                                                                                bool = bool ;
                                                                                                                float = float ;
                                                                                                                int = int ;
                                                                                                                lambda = lambda ;
                                                                                                                null = null ;
                                                                                                                path = path ;
                                                                                                                string = string ;
                                                                                                            } ;
                                                                                                    mapper =
                                                                                                        name : value :
                                                                                                            {
                                                                                                                name = name ;
                                                                                                                value =
                                                                                                                    if builtins.typeOf value == "lambda" then value
                                                                                                                    else if builtins.typeOf value == "null" && builtins.typeOf default == "lambda" then default
                                                                                                                    else if builtins.typeOf value == "null" then builtins.throw "The simple ${ name } visitor is not lambda, null (and the default simple visitor is not lambda) but ${ builtins.typeOf value }."
                                                                                                                    else builtins.throw "The simple ${ name } visitor is not lambda, null but ${ builtins.typeOf value }." ;
                                                                                                            } ;
                                                                                                    in builtins.mapAttrs mapper ( identity ( simple ) ) ;
                                                                                            in builtins.attrValues simple-visitors ;
                                                                                    in builtins.concatLists [ simple-visitors [ list-visitor set-visitor ] ] ;
                                                                            predicate = visitor : visitor.name == builtins.typeOf value ;
                                                                            in builtins.filter predicate all-visitors ;
                                                                    in builtins.head filtered-visitors ;
                                                            in visitor.value ;
                                                    in visitor path value ;
                                        simple =
                                            {
                                                bool = bool ;
                                                float = float ;
                                                int = int ;
                                                lambda = lambda ;
                                                null = null ;
                                                path = path ;
                                                string = string ;
                                            } ;
                                        in elem [ ] value ;
                        in
                            {
                                implementation = implementation ;
                                test =
                                   pkgs : expected : success : visitors : value :
                                        let
                                            eval = builtins.tryEval ( implementation visitors value ) ;
                                            status = { success = success ; value = expected ; } == eval ;
                                            in
                                                pkgs.stdenv.mkDerivation
                                                    {
                                                        installPhase =
                                                            if status then
                                                                ''
                                                                    touch $out
                                                                    echo SUCCESS
                                                                    exit 0
                                                                ''
                                                            else
                                                                ''
                                                                    touch $out
                                                                    echo '${ builtins.toJSON { expected = { success = success ; value = expected ; } ; observed = eval ; } }' | yq --yaml-output "." >&2
                                                                    exit 64
                                                                '' ;
                                                        name = "test-visitor" ;
                                                        nativeBuildInputs = [ pkgs.coreutils pkgs.yq ] ;
                                                        src = ./. ;
                                                    } ;
                            } ;
            } ;
}