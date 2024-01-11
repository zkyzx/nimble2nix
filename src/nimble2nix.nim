import std/[json, os, osproc, strformat, strutils, tables, re]

when isMainModule:
  let
    args = commandLineParams()
    path =
      if args.len() == 0:
        "."
      else:
        args[0]

  setCurrentDir(path)

  let isLocal = if dirExists "nimbledeps": true else: false
  let code = execCmd "nimble install --depsOnly --localdeps --accept"
  let semvarRegex = r"\d|[1-9]\d*)\.(\d|[1-9]\d*)\.(\d|[1-9]\d*"

  var nimbleMinorVersion: int

  try:
    nimbleMinorVersion =
      parseInt execCmdEx("nimble --version")[0].findAll(re(fmt"({semvarRegex})"))[0].split(".")[1]
  except:
    echo "Unable to parse nimble version."
    quit(1)

  if code != 0:
    if not isLocal:
      removeDir "nimbledeps"
    quit(code)

  var packages: Table[string, JsonNode]
  let pkgsDir = (if nimbleMinorVersion >= 14: "pkgs2" else: "pkgs")

  for package in walkDir "nimbledeps/" & pkgsDir:
    var name = package.path
    name.removePrefix("nimbledeps/" & pkgsDir)
    name = name.findAll(re fmt"(\w+\-{semvarRegex})")[0]

    echo &"Prefetching {name}..."

    let
      json = parseJson readFile(package.path & "/nimblemeta.json")
      url = (
        if nimbleMinorVersion >= 14: json["metaData"]["url"].getStr()
        else: json["url"].getStr()
      )
      rev = (
        if nimbleMinorVersion >= 14: json["metaData"]["vcsRevision"].getStr()
        else: json{"vcsRevision"}.getStr()
      )
      prefetch =
        execCmdEx(
          &"nix-prefetch-git --fetch-submodules --url {url}" & (
            if rev != "": &" --rev {rev}" else: ""
          ),
          options = {poUsePath},
        )

    packages[name] = %parseJson(prefetch.output)

  echo "Writing result..."
  writeFile("nimble2nix.json", pretty(%packages))

  if not isLocal:
    removeDir "nimbledeps"
