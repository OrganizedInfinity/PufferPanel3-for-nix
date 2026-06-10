{
  lib,
  fetchFromGitHub,
  buildGoModule,
  makeWrapper,
  go-swag,
  #nixosTests,
  #testers,
  #pufferpanel,
  nodejs,
  yarn,
  importNpmLock,
  makeSetupHook,
  srcOnly
}:

buildGoModule rec {
  pname = "pufferpanel";
  version = "3.0.8";

  src = fetchFromGitHub {
    owner = "PufferPanel";
    repo = "PufferPanel";
    tag = "v${version}";
    hash = "sha256-uLDoJ5fgyLRyc+NSJl5GcKth7naELByYN3JC+PXeBgw=";
  };

  patches = [
    # The git tree of pufferpanel uses @description.markdown but it doesnt give it its required argument
    # Building the api docs will fail without this patch
    ./swagger-markdown.patch
  ];

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/pufferpanel/pufferpanel/v2.Hash=none"
    "-X=github.com/pufferpanel/pufferpanel/v2.Version=${version}-nixpkgs"
  ];

  # WHY TF WAS THIS EVER BEING BUILT LIKE THIS
  #frontend = buildNpmPackage {
  #  pname = "pufferpanel-frontend";
  #  inherit version;
  #
  #  src = "${src}/client";
  #
  #  npmDepsHash = "sha256-591GTQ9UulTRkHazpagrbd+QtmS0iqdsayDvjEHI25Q=";
  #
  #  NODE_OPTIONS = "--openssl-legacy-provider";
  #  installPhase = ''
  #    runHook preInstall
  #    
  #    cp -r ./frontend/dist $out
  #
  #    runHook postInstall
  #  '';
  #
  #  nativeBuildInputs = [ yarn ];
  #};

  npmDeps = importNpmLock {
    npmRoot = "${src}/client";
  };

  nativeBuildInputs = 
    let 
      nodeHook = makeSetupHook {
        name = "npm-config-hook";
        substitutions = {
          nodeSrc = srcOnly nodejs;
          nodeGyp = "${nodejs}/lib/node_modules/npm/node_modules/node-gyp/bin/node-gyp.js";
          canonicalizeSymlinksScript = ./canonicalize-symlinks.js;
          storePrefix = builtins.storeDir;
	  workingDirectory = "./client";
	  inherit npmDeps;
        };
        meta.license = lib.licenses.mit;
      } ./npm-config-hook.sh;
    in [
    nodeHook
    makeWrapper
    go-swag
    nodejs
    yarn
  ];

  preBuild = ''
    
    cd client
    npm run build
    cd ..

    # Generate code for Swagger documentation endpoints (see web/swagger/docs.go).
    # Note that GOROOT embedded in go-swag is empty by default since it is built
    # with -trimpath (see https://go.dev/cl/399214). It looks like go-swag skips
    # file paths that start with $GOROOT, thus all files when it is empty.
    swag init --output web/swagger --generalInfo web/loader.go --parseDependency --parseInternal

  '';

  vendorHash = "sha256-2XR6YJjYwlCRcCi2Eb0GmnneMaxqcek71BNL3Qg444o=";
  proxyVendor = true;

  installPhase = ''
    runHook preInstall

    # Set up directory structure similar to the official PufferPanel releases.
    #mkdir -p $out/share/pufferpanel
    #cp "$GOPATH"/bin/cmd $out/share/pufferpanel/pufferpanel
    #cp -r $frontend $out/share/pufferpanel/www
    #cp -r $src/assets/email $out/share/pufferpanel/email
    #cp web/swagger/swagger.{json,yaml} $out/share/pufferpanel

    # Wrap the binary with the path to the external files, but allow setting
    # custom paths if needed.
    #makeWrapper $out/share/pufferpanel/pufferpanel $out/bin/pufferpanel \
    #  --set-default GIN_MODE release \
    #  --set-default PUFFER_PANEL_EMAIL_TEMPLATES $out/share/pufferpanel/email/emails.json \
    #  --set-default PUFFER_PANEL_WEB_FILES $out/share/pufferpanel/www

    # new shit here
    mkdir -p $out/bin
    cp "$GOPATH"/bin/cmd $out/bin/pufferpanel

    runHook postInstall
  '';

  doCheck = false;
  
  # TODO: fix tests
  #passthru.tests = {
  #  inherit (nixosTests) pufferpanel;
  #  version = testers.testVersion {
  #    package = pufferpanel;
  #    command = "${pname} version";
  #  };
  #};

  meta = {
    description = "Free, open source game management panel";
    homepage = "https://www.pufferpanel.com/";
    license = with lib.licenses; [ asl20 ];
    maintainers = with lib.maintainers; [ tie ];
    mainProgram = "pufferpanel";
  };
}
