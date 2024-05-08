{ pkgs }:
{
  pname,
  version,
  name ? "${pname}-${version}",
  src,
  deps ? src + "/nimble2nix.json",
  buildInputs ? [ ],
  nativeBuildInputs ? [ ],
  nimFlags ? [ ],
  nimRelease ? true,
  nimDefines ? [ ],
  postInstall ? '''',
  postBuild ? '''',
  meta ? { },
}:
pkgs.buildNimPackage {
  inherit
    name
    src
    nativeBuildInputs
    nimFlags
    nimRelease
    nimDefines
    postInstall
    postBuild
    meta
    ;
  buildInputs =
    buildInputs
    ++ (pkgs.lib.mapAttrsToList (
      _: src:
      pkgs.fetchgit {
        inherit (src) url rev sha256 fetchSubmodules;
      }
    ) (pkgs.lib.importJSON deps));
}
