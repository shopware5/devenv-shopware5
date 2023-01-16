{ pkgs, lib, config, inputs, ... }:

{
  languages.javascript.enable = true;
  languages.javascript.package = lib.mkDefault pkgs.nodejs-18_x;

  languages.php.enable = true;
  languages.php.package = lib.mkDefault (inputs.phps.packages.${builtins.currentSystem}.php81.buildEnv {
    extensions = { all, enabled }: with all; enabled ++ [ redis ];
    extraConfig = ''
      memory_limit = 2G
      pdo_mysql.default_socket=''${MYSQL_UNIX_PORT}
      mysqli.default_socket=''${MYSQL_UNIX_PORT}
      blackfire.agent_socket = "${config.services.blackfire.socket}";
      realpath_cache_ttl=3600
      session.gc_probability=0
      session.save_handler = redis
      session.save_path = "tcp://127.0.0.1:6379/0"
      display_errors = On
      error_reporting = E_ALL
      assert.active=0
      opcache.memory_consumption=256M
      opcache.interned_strings_buffer=20
      zend.assertions = 0
      short_open_tag = 0
      zend.detect_unicode=0
      realpath_cache_ttl=3600
    '';
  });

  languages.php.fpm.pools.web = {
    settings = {
      "clear_env" = "no";
      "pm" = "dynamic";
      "pm.max_children" = 10;
      "pm.start_servers" = 2;
      "pm.min_spare_servers" = 1;
      "pm.max_spare_servers" = 10;
    };
  };

  services.caddy.enable = lib.mkDefault true;
  services.caddy.virtualHosts."http://localhost:8000" = {
    extraConfig = ''
      root * .
      php_fastcgi unix/${config.languages.php.fpm.pools.web.socket} {
        index shopware.php
      }
      file_server
    '';
  };

  services.mysql.enable = lib.mkDefault true;
  services.mysql.initialDatabases = [
    { name = "shopware"; }
  ];
  services.mysql.ensureUsers = [
    {
      name = "shopware";
      password = "shopware";
      ensurePermissions = {
        "shopware.*" = "ALL PRIVILEGES";
      };
    }
  ];

  services.redis.enable = lib.mkDefault true;
  services.adminer.enable = lib.mkDefault true;
  services.adminer.listen = lib.mkDefault "127.0.0.1:9080";
  services.mailhog.enable = lib.mkDefault true;
}
