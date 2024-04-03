{ stdenv, lib, pkgs, fetchFromGitHub, pkg-config, autoPatchelfHook
, installShellFiles, scons, vulkan-loader, libGL, libX11, libXcursor
, libXinerama, libXext, libXrandr, libXrender, libXi, libXfixes, libxkbcommon
, alsa-lib, libpulseaudio, dbus, speechd, fontconfig, udev
, withPlatform ? "linux", withTarget ? "template_release"
, withPrecision ? "single", withPulseaudio ? true, withDbus ? true
, withSpeechd ? true, withFontconfig ? true, withUdev ? true, withTouch ? true
}:

assert lib.asserts.assertOneOf "withPrecision" withPrecision [
  "single"
  "double"
];

let
  mkSconsFlagsFromAttrSet = lib.mapAttrsToList (k: v:
    if builtins.isString v then "${k}=${v}" else "${k}=${builtins.toJSON v}");
in stdenv.mkDerivation rec {
  pname = "gd_cubism";
  version = "f43a20c36e1879b037070cc9a989f8c92ab055e4";
  #  commitHash = "3f5c23d474da8702f4a1627e96e29066b0e3e475";
  #  commitHash = "b09f793f564a6c95dc76acc654b390e68441bd01";
  src = ./.;
  #  src = fetchFromGitHub {
  #    owner = "godotengine";
  #    repo = "godot";
  #    rev = commitHash;
  #    hash = "sha256-Q6Og1H4H2ygOryMPyjm6kzUB6Su6T9mJIp0alNAxvjQ=";
  #  };

  nativeBuildInputs = [
    pkg-config
    #    autoPatchelfHook
    #    installShellFiles
    (pkgs.clang-tools.override { llvmPackages = pkgs.llvmPackages_18; })
    pkgs.llvmPackages_18.bintools

  ];

  buildInputs = [
    scons
    #    (pkgs.llvmPackages_18.libcxx.override { enableShared = false; })
    #    pkgs.llvmPackages_18.libraries.libcxx
    pkgs.llvmPackages_18.compiler-rt
  ];

  runtimeDependencies = [

    vulkan-loader
    libGL
    libX11
    libXcursor
    libXinerama
    libXext
    libXrandr
    libXrender
    libXi
    libXfixes
    libxkbcommon
    alsa-lib
  ] ++ lib.optional withPulseaudio libpulseaudio ++ lib.optional withDbus dbus
    ++ lib.optional withDbus dbus.lib ++ lib.optional withSpeechd speechd
    ++ lib.optional withFontconfig fontconfig
    ++ lib.optional withFontconfig fontconfig.lib ++ lib.optional withUdev udev;

  enableParallelBuilding = true;

  # Set the build name which is part of the version. In official downloads, this
  # is set to 'official'. When not specified explicitly, it is set to
  # 'custom_build'. Other platforms packaging Godot (Gentoo, Arch, Flatpack
  # etc.) usually set this to their name as well.
  #
  # See also 'methods.py' in the Godot repo and 'build' in
  # https://docs.godotengine.org/en/stable/classes/class_engine.html#class-engine-method-get-version-info
  BUILD_NAME = "nixpkgs";

  # Required for the commit hash to be included in the version number.
  #
  # `methods.py` reads the commit hash from `.git/HEAD` and manually follows
  # refs. Since we just write the hash directly, there is no need to emulate any
  # other parts of the .git directory.
  #
  # See also 'hash' in
  # https://docs.godotengine.org/en/stable/classes/class_engine.html#class-engine-method-get-version-info
  #  preConfigure = ''
  #    mkdir -p .git
  #    echo ${commitHash} > .git/HEAD
  #  '';

  sconsFlags = mkSconsFlagsFromAttrSet {
    # Options from 'SConstruct'
    platform = withPlatform;
    target = withTarget;

    use_llvm = true;
    linker = "lld";
    #    LINK = "ld.lld";
    #    use_static_cpp = true;
  };

  #  outputs = [ "out" "man" ];

  meta = with lib; {
    homepage = "https://godotengine.org";
    description = "Free and Open Source 2D and 3D game engine";
    license = licenses.mit;
    platforms = [ "i686-linux" "x86_64-linux" "aarch64-linux" ];
    maintainers = with maintainers; [ shiryel ];
    mainProgram = "godot4";
  };
}
