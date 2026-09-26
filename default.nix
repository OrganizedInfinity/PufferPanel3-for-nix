{
  lib,
  fetchFromGitHub,
  buildGoModule,
  makeWrapper,
  go-swag,
  nodejs,
  yarn,
  importNpmLock,
  makeSetupHook,
  srcOnly
}:

buildGoModule rec {
  pname = "pufferpanel";
  version = "3.0.9";

  src = fetchFromGitHub {
    owner = "PufferPanel";
    repo = "PufferPanel";
    tag = "v${version}";
    hash = "sha256-Qn/Z/yuJR8/1cNzEc6kVXlokewtDdraSPpjs7Lsce10=";
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
    swag init --output web/swagger --generalInfo web/loader.go --parseDependency --parseInternal
  '';

  vendorHash = "sha256-2XR6YJjYwlCRcCi2Eb0GmnneMaxqcek71BNL3Qg444o=";
  proxyVendor = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp "$GOPATH"/bin/cmd $out/bin/pufferpanel

    runHook postInstall
  '';
  doCheck = false;
  
  meta = {
    description = "Free, open source game management panel";
    homepage = "https://www.pufferpanel.com/";
    license = with lib.licenses; [ asl20 ];
    maintainers = [];
    mainProgram = "pufferpanel";
  };
}
