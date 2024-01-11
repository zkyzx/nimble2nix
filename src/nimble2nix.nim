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

  let
    semvarRegex =
      re"(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?"

  var nimbleMinorVersion: int

  try:
    nimbleMinorVersion =
      parseInt execCmdEx("nimble --version")[0].findAll(semvarRegex)[0].split(".")[1]
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
    removePrefix(name, "nimbledeps/" & pkgsDir)

    echo &"Prefetching {name}..."
    echo name

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
