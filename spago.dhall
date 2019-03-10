{-
Welcome to a Spago project!
You can edit this file as you like.
-}
{ name =
    "my-project"
, dependencies =
    [ "bouzuya-template-string"
    , "console"
    , "effect"
    , "node-fs"
    , "node-process"
    , "psci-support"
    , "test-unit"
    ]
, packages =
    ./packages.dhall
}
