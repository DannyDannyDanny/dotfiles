# Plane — self-hosted project tracker (Linear-alike) at
# https://plane.dannydannydanny.me. Public traffic: vps-relay Caddy →
# ZeroTier → here :8094 (see vps-relay.nix).
#
# Upstream ships docker-compose only (deployments/cli/community/
# docker-compose.yml in makeplane/plane); no nixpkgs module exists, so
# this mirrors that stack 1:1 as rootful podman containers on a private
# `plane` network. Plane's bundled proxy (Caddy) is kept — it
# path-routes web/space/admin/live/api/minio on one port — but serves
# plain HTTP (SITE_ADDRESS=:80); TLS terminates at vps-relay like every
# other public service.
#
# Sizing: first start pulls ~2 GB of images from Docker Hub; the stack
# idles around 2–2.5 GB RAM (Postgres, Valkey, RabbitMQ, MinIO, three
# Django processes, three Next.js servers, one node live-collab
# server). Data under /var/lib/plane, images under /var/lib/containers.
#
# Secrets: the `plane` clan vars generator at the bottom writes one env
# file (Django SECRET_KEY, DB/MQ/MinIO credentials and the URLs that
# embed them) deployed to /run/secrets/vars/plane/plane.env. Every
# container loads it; each image picks the keys it knows. Bootstrap
# order matters:
#   1. clan vars generate phantom-ship   (on the mac, writes encrypted
#      vars into the repo — commit them)
#   2. push, rebuild phantom-ship (dm-pull-deploy or clan machines update)
# A rebuild before step 1 fails ("no value set" for plane.env).
#
# After first deploy: sign up at https://plane.dannydannydanny.me — the
# first account becomes instance admin — then immediately disable public
# sign-ups under /god-mode → Authentication (the domain is public).
#
# Version bumps: change `version` below; releases at
# https://github.com/makeplane/plane/releases. The migrator container
# runs Django migrations on every boot, so the DB schema follows along.
{ config, lib, pkgs, ... }:

let
  version = "v1.3.1";
  domain = "plane.dannydannydanny.me";
  dataDir = "/var/lib/plane";

  # Secret-bearing env (SECRET_KEY, LIVE_SERVER_SECRET_KEY,
  # POSTGRES_PASSWORD, DATABASE_URL, RABBITMQ_DEFAULT_PASS, AMQP_URL,
  # MINIO_ROOT_USER/PASSWORD, AWS_ACCESS_KEY_ID/SECRET_ACCESS_KEY) —
  # see the generator at the bottom of this file.
  secretEnv = config.clan.core.vars.generators.plane.files."plane.env".path;

  # Compose's x-*-env anchors, minus every secret-bearing key (those
  # live in plane.env). Hostnames are container names / network aliases
  # on the `plane` podman network (aardvark-dns resolves both).
  dbEnv = {
    PGHOST = "plane-db";
    PGDATABASE = "plane";
    POSTGRES_USER = "plane";
    POSTGRES_DB = "plane";
    POSTGRES_PORT = "5432";
    PGDATA = "/var/lib/postgresql/data";
  };
  redisEnv = {
    REDIS_HOST = "plane-redis";
    REDIS_PORT = "6379";
    REDIS_URL = "redis://plane-redis:6379/";
  };
  s3Env = {
    AWS_REGION = "";
    AWS_S3_ENDPOINT_URL = "http://plane-minio:9000";
    AWS_S3_BUCKET_NAME = "uploads";
  };
  mqEnv = {
    RABBITMQ_HOST = "plane-mq";
    RABBITMQ_PORT = "5672";
    RABBITMQ_DEFAULT_USER = "plane";
    RABBITMQ_DEFAULT_VHOST = "plane";
    RABBITMQ_VHOST = "plane";
  };
  proxyEnv = {
    APP_DOMAIN = domain;
    FILE_SIZE_LIMIT = "5242880"; # 5 MiB upload cap (Plane default)
    BUCKET_NAME = "uploads";
    SITE_ADDRESS = ":80"; # plain HTTP; TLS terminates at vps-relay
  };
  appEnv = {
    WEB_URL = "https://${domain}";
    DEBUG = "0";
    CORS_ALLOWED_ORIGINS = "https://${domain}";
    GUNICORN_WORKERS = "1";
    USE_MINIO = "1";
    API_KEY_RATE_LIMIT = "60/minute";
    MINIO_ENDPOINT_SSL = "0";
    WEBHOOK_ALLOWED_IPS = "";
    WEBHOOK_ALLOWED_HOSTS = "";
  } // dbEnv // redisEnv // s3Env // mqEnv // proxyEnv;

  # Join the `plane` network; the alias is the compose service name the
  # other containers (and the proxy's Caddyfile) dial.
  onPlaneNet = alias:
    [ "--network=plane" ] ++ lib.optional (alias != null) "--network-alias=${alias}";

  # api / worker / beat / migrator share image and env; only the
  # entrypoint differs.
  backend = entrypoint: {
    image = "docker.io/makeplane/plane-backend:${version}";
    cmd = [ "./bin/docker-entrypoint-${entrypoint}.sh" ];
    environment = appEnv;
    environmentFiles = [ secretEnv ];
    volumes = [ "${dataDir}/logs/${entrypoint}:/code/plane/logs" ];
    extraOptions = onPlaneNet null;
    dependsOn = [ "plane-db" "plane-redis" "plane-mq" ];
  };

  containers = {
    plane-web = {
      image = "docker.io/makeplane/plane-frontend:${version}";
      extraOptions = onPlaneNet "web";
      dependsOn = [ "plane-api" "plane-worker" ];
    };
    plane-space = {
      image = "docker.io/makeplane/plane-space:${version}";
      extraOptions = onPlaneNet "space";
      dependsOn = [ "plane-api" "plane-worker" "plane-web" ];
    };
    plane-admin = {
      image = "docker.io/makeplane/plane-admin:${version}";
      extraOptions = onPlaneNet "admin";
      dependsOn = [ "plane-api" "plane-web" ];
    };
    plane-live = {
      image = "docker.io/makeplane/plane-live:${version}";
      environment = { API_BASE_URL = "http://api:8000"; } // redisEnv;
      environmentFiles = [ secretEnv ]; # LIVE_SERVER_SECRET_KEY
      extraOptions = onPlaneNet "live";
      dependsOn = [ "plane-api" "plane-web" ];
    };

    plane-api = backend "api" // { extraOptions = onPlaneNet "api"; };
    plane-worker = backend "worker" // {
      dependsOn = [ "plane-api" "plane-db" "plane-redis" "plane-mq" ];
    };
    plane-beat-worker = backend "beat" // {
      dependsOn = [ "plane-api" "plane-db" "plane-redis" "plane-mq" ];
    };
    # One-shot: runs Django migrations and exits 0. The api/worker
    # entrypoints block on wait_for_migrations, so ordering self-heals.
    plane-migrator = backend "migrator";

    plane-db = {
      image = "docker.io/library/postgres:15.7-alpine";
      cmd = [ "postgres" "-c" "max_connections=1000" ];
      environment = dbEnv;
      environmentFiles = [ secretEnv ]; # POSTGRES_PASSWORD
      volumes = [ "${dataDir}/pgdata:/var/lib/postgresql/data" ];
      extraOptions = onPlaneNet null;
    };
    plane-redis = {
      image = "docker.io/valkey/valkey:7.2.11-alpine";
      volumes = [ "${dataDir}/redis:/data" ];
      extraOptions = onPlaneNet null;
    };
    plane-mq = {
      image = "docker.io/library/rabbitmq:3.13.6-management-alpine";
      environment = mqEnv;
      environmentFiles = [ secretEnv ]; # RABBITMQ_DEFAULT_PASS
      volumes = [ "${dataDir}/rabbitmq:/var/lib/rabbitmq" ];
      extraOptions = onPlaneNet null;
    };
    plane-minio = {
      # Upstream compose pins `latest` too; uploads survive upgrades on
      # the bind mount below.
      image = "docker.io/minio/minio:latest";
      cmd = [ "server" "/export" "--console-address" ":9090" ];
      environmentFiles = [ secretEnv ]; # MINIO_ROOT_USER/PASSWORD
      volumes = [ "${dataDir}/minio:/export" ];
      extraOptions = onPlaneNet null;
    };

    plane-proxy = {
      image = "docker.io/makeplane/plane-proxy:${version}";
      environment = proxyEnv;
      # Publish on v4 and v6 — the vps-relay Caddy dials our ZeroTier
      # IPv6. Note podman DNATs published ports ahead of the NixOS
      # firewall input chain, so the zt+ rule in phantom-ship.nix is
      # documentation; actual exposure is every interface, same risk
      # profile as the other :: -bound services behind the home NAT.
      ports = [ "8094:80" "[::]:8094:80" ];
      extraOptions = onPlaneNet null;
      dependsOn = [ "plane-web" "plane-api" "plane-space" "plane-admin" "plane-live" ];
    };
  };
in
{
  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers = containers;

  # Routed v6 from the ZT interface into the podman bridge needs global
  # v6 forwarding; the NixOS NAT module (rusty-anchor subnet) only flips
  # the v4 sysctl.
  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = lib.mkDefault true;

  # All images start their entrypoint as root and chown their own data
  # dirs, so plain root-owned mounts are fine.
  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 root root - -"
    "d ${dataDir}/pgdata 0750 root root - -"
    "d ${dataDir}/redis 0750 root root - -"
    "d ${dataDir}/rabbitmq 0750 root root - -"
    "d ${dataDir}/minio 0750 root root - -"
    "d ${dataDir}/logs 0750 root root - -"
    "d ${dataDir}/logs/api 0750 root root - -"
    "d ${dataDir}/logs/worker 0750 root root - -"
    "d ${dataDir}/logs/beat 0750 root root - -"
    "d ${dataDir}/logs/migrator 0750 root root - -"
  ];

  systemd.services = lib.mkMerge [
    {
      init-plane-network = {
        description = "Create the dual-stack podman network for Plane";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        # --ipv6: netavark cannot DNAT a v6 host port into a v4-only
        # network, and the vps-relay Caddy reaches us over ZeroTier v6.
        script = ''
          ${pkgs.podman}/bin/podman network exists plane || \
            ${pkgs.podman}/bin/podman network create --ipv6 plane
        '';
      };
    }
    (lib.genAttrs (map (name: "podman-${name}") (lib.attrNames containers)) (_: {
      after = [ "init-plane-network.service" ];
      requires = [ "init-plane-network.service" ];
    }))
    {
      # The oci-containers module defaults Restart=always, which would
      # rerun the finished migrator in a loop forever. on-failure still
      # retries while postgres is warming up on first boot.
      podman-plane-migrator.serviceConfig.Restart = lib.mkForce "on-failure";
      podman-plane-migrator.serviceConfig.RestartSec = lib.mkForce "10s";
    }
  ];

  clan.core.vars.generators.plane = {
    files."plane.env" = { };
    runtimeInputs = [ pkgs.coreutils ];
    script = ''
      gen() { head -c 64 /dev/urandom | base64 | tr -d '+/=\n' | head -c "$1"; }
      pg_pw=$(gen 24)
      mq_pw=$(gen 24)
      minio_user=$(gen 16)
      minio_pw=$(gen 32)
      cat > "$out"/plane.env <<EOF
      SECRET_KEY=$(gen 50)
      LIVE_SERVER_SECRET_KEY=$(gen 32)
      POSTGRES_PASSWORD=$pg_pw
      DATABASE_URL=postgresql://plane:$pg_pw@plane-db/plane
      RABBITMQ_DEFAULT_PASS=$mq_pw
      AMQP_URL=amqp://plane:$mq_pw@plane-mq:5672/plane
      AWS_ACCESS_KEY_ID=$minio_user
      AWS_SECRET_ACCESS_KEY=$minio_pw
      MINIO_ROOT_USER=$minio_user
      MINIO_ROOT_PASSWORD=$minio_pw
      EOF
    '';
  };
}
