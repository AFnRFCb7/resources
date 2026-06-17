{
    inputs =
        {
            nixpkgs.url = "github:Nixos/nixpkgs/nixos-24.11" ;
            visitor.url = "github:AFnRFCb7/visitor" ;
        } ;
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
                                        user = null ;
                                        hooks =
                                            {

                                            } ;
                                    } ;
                            in
                                {
                                    checks = null ;
                                    implementation = implementation ;
                                } ;
            } ;
}