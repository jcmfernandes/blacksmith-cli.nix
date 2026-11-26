{
  lib,
  stdenvNoCC,
  fetchurl,
  makeBinaryWrapper,
  installShellFiles,
  versionCheckHook,
  rsync,
  openssh,
}: let
  version = "0.7.26";

  # Upstream publishes one static binary per platform, plus a .sha256
  # beside it; the hashes below are those files, converted to SRI.
  platforms = {
    x86_64-linux = {
      path = "linux/amd64";
      hash = "sha256-ipRepLYctwhmYeJW4RgkU+1B4x6SXSgaeAzEMQT2fRg=";
    };
    aarch64-linux = {
      path = "linux/arm64";
      hash = "sha256-Ee9M8UdfLh2BA5gnAzQQXoNaiCRlMju+dxnP+cbsK5w=";
    };
    aarch64-darwin = {
      path = "darwin/arm64";
      hash = "sha256-AlyUONez9U/5A6ajAnadJqCkOQ6AhfAY3FMOlPfjTIk=";
    };
  };

  inherit (stdenvNoCC.hostPlatform) system;
  platform = platforms.${system} or (throw "blacksmith-cli: unsupported system ${system}");
in
  stdenvNoCC.mkDerivation {
    pname = "blacksmith-cli";
    inherit version;

    # The install script fetches .../cli/latest/...; the versioned path
    # is the same layout, pinned.
    src = fetchurl {
      url = "https://clireleases.blacksmith.sh/cli/v${version}/${platform.path}/blacksmith";
      inherit (platform) hash;
    };

    dontUnpack = true;

    nativeBuildInputs = [makeBinaryWrapper installShellFiles];

    # The CLI replaces itself on every run unless told not to; the store
    # is read-only.  testbox shells out to rsync (over ssh); --suffix lets
    # the user's own copies win.
    installPhase = ''
      runHook preInstall
      install -Dm755 $src $out/bin/blacksmith
      wrapProgram $out/bin/blacksmith \
        --set BLACKSMITH_DISABLE_AUTO_UPDATE 1 \
        --suffix PATH : ${lib.makeBinPath [rsync openssh]}
      runHook postInstall
    '';

    postInstall = lib.optionalString (stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform) ''
      export HOME=$TMPDIR
      installShellCompletion --cmd blacksmith \
        --bash <($out/bin/blacksmith completion bash) \
        --zsh <($out/bin/blacksmith completion zsh) \
        --fish <($out/bin/blacksmith completion fish)
    '';

    doInstallCheck = true;
    nativeInstallCheckInputs = [versionCheckHook];

    meta = {
      description = "Blacksmith CLI: CI logs, job metrics, caches, sticky disks, testboxes";
      homepage = "https://docs.blacksmith.sh/blacksmith-cli/overview";
      license = lib.licenses.unfree;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      platforms = builtins.attrNames platforms;
      mainProgram = "blacksmith";
    };
  }
