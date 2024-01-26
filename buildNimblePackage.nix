{pkgs}: {
  pname,
  version,
  name ? "${pname}-${version}",
  src,
  deps ? src + "/nimble2nix.json",
  buildInputs ? [],
  nativeBuildInputs ? [],
  nimFlags ? [],
  nimRelease ? true,
  nimDefines ? [],
}:
pkgs.buildNimPackage {
  inherit name src nativeBuildInputs nimFlags nimRelease nimDefines;
  buildInputs =
    buildInputs
    ++ (pkgs.lib.mapAttrsToList
      (name: src:
        pkgs.fetchgit {
          inherit (src) url rev sha256 fetchSubmodules;
        }) (pkgs.lib.importJSON deps));
}
