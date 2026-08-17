builtins.toFile
    "answer.nix"
    (
        builtins.concatStringsSep
            "\n"
            (
                builtins.concatLists
                    [
                        [ "[" ]
                        (
                            builtins.map
                                (
                                    actions :
                                        (
                                            builtins.concatStringsSep
                                                "\n"
                                                (
                                                    builtins.concatLists
                                                        [
                                                            [ "\t{" ]
                                                            [
                                                                (
                                                                    builtins.concatStringsSep
                                                                        "\n"
                                                                        (
                                                                            builtins.attrValues
                                                                                (
                                                                                    builtins.mapAttrs
                                                                                        (
                                                                                            name : parameter : "\t\t${ builtins.toJSON name } = ${ builtins.toJSON parameter } ;"
                                                                                        )
                                                                                        actions
                                                                                )
                                                                        )
                                                                )
                                                            ]
                                                            [ "\t}"]
                                                        ]
                                                )
                                        )
                                )
                                (
                                    builtins.fromJSON
                                        (
                                            builtins.readFile
                                                /tmp/scratch/outputs.json
                                        )
                                )
                        )
                        [ "]" ]
                    ]
            )
    )

