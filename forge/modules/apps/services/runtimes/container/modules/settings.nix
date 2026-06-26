{
  app,

  service,
  serviceName,
  runtimeConfig ? {
    setup = "";
    packages = [ ];
  },
  pkgs,
  lib,
  ...
}:
{
  binName = "${app.name}-service";

  container = {
    copyToRoot =
      let
        uid = "1001";
        gid = "1001";
        etcFiles = pkgs.runCommand "etc-${serviceName}" { } ''
          mkdir -p $out/etc
          echo 'root:x:0:0:root:/root:/bin/sh' > $out/etc/passwd
          echo '${serviceName}:x:${uid}:${gid}:${serviceName}:${service.stateDir}:/sbin/nologin' >> $out/etc/passwd
          echo 'root:x:0:' > $out/etc/group
          echo '${serviceName}:x:${gid}:' >> $out/etc/group
          echo 'root:!:0::::::' > $out/etc/shadow
          echo '${serviceName}:!:1::::::' >> $out/etc/shadow
          echo 'hosts: files dns' > $out/etc/nsswitch.conf
        '';
      in
      pkgs.buildEnv {
        name = "runtime-bins";
        paths = service.packages ++ runtimeConfig.packages ++ [ etcFiles ];
        pathsToLink = [
          "/bin"
          "/etc"
        ];
      };

    imageConfig = {
      WorkingDir = service.stateDir;
      User = if service.user == "root" then "root" else serviceName;
      Volumes = {
        "${service.stateDir}" = { };
      };
      Env =
        let
          envAttrsToList = attrs: lib.mapAttrsToList (n: v: "${n}=${v}") attrs;
        in
        envAttrsToList service.environment;
    };
  };

  startup.runOnStartup = lib.mkIf (runtimeConfig.setup != "") (
    pkgs.writeShellScript "container-setup" runtimeConfig.setup
  );
}
