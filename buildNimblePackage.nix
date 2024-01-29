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
  postInstall ? '''',
}:
pkgs.buildNimPackage {
  inherit name src nativeBuildInputs nimFlags nimRelease nimDefines postInstall;
  buildInputs =
    buildInputs
    ++ (pkgs.lib.mapAttrsToList
      (name: src:
        pkgs.fetchgit {
          inherit (src) url rev sha256 fetchSubmodules;
        }) (pkgs.lib.importJSON deps));
}
