#########################################
####### Experimental PgBoucner config ###
#########################################
#
# PG Bouncer can be used to provide frontend authentication to materialize
# In this scenario, PgBouncer authenticates via either users defined in an auth_file
# or via an auth_query against materialize, a 3rd party database could be used as well.
# 
# The query used can be modified to suit your needs, but initially is set to
# auth_query = SELECT username, password_md5 FROM auth_users WHERE username=$1 limit 1;
#
# To create the table, connect to the materialize instance and run:
# CREATE TABLE auth_users (username: text, password_md5: text);
# 
# To add a new user you can run
# INERST INTO auth_users VALUES ( 'hunter', '2ab96390c7dbe3439de74d0c9b0b1767');
#
# IF you want to use this module you should make sure pgbouncer or a fronting
# proxy/loadbalancer provides TLS encyprtion to ensure no passwords or password
# hashes are transmitted unencrypted. Since this uses md5 it is not considered a secure mechanism
# and thus should not be used in any production, critical, or public facing environment.


variable "namespace" {
  description = "Namespace for all resources, usually the organization or project name"
  type        = string
}

variable "name" {
  description = "name of the environment the pgbouncer is for."
  type        = string
}

variable "materialize_host" {
  description = "PostgreSQL backend hostname"
  type        = string
  default     = "mz6030f4a2hh-balancerd.materialize-environment.svc.cluster.local"
}

variable "pgbouncer_auth_users" {
  description = "Map of usernames to hashed passwords for client authentication"
  type        = map(string)
  default     = {}
}


locals {
  auth_users = length(var.pgbouncer_auth_users) > 0 ? var.pgbouncer_auth_users : { "mzadmin" : md5(random_password.database_admin_password.result) }
}

resource "random_password" "database_admin_password" {
  length  = 16
  special = false
}

resource "random_password" "pgbouncer_admin_password" {
  length  = 16
  special = false
}

resource "kubernetes_secret" "pgbouncer_user_list" {
  metadata {
    name      = "pgbouncer-userlist-${var.name}"
    namespace = var.namespace
  }
  data = {
    "userlist.txt" = join("\n", [for user, pass in local.auth_users : "\"${user}\" \"${pass}\""])
  }
}

resource "random_password" "default_admin_password" {
  length  = 16
  special = false
}

resource "helm_release" "pg_bouncer2" {
  name       = "materialize"
  namespace  = var.namespace
  chart      = "pgbouncer"
  version    = "2.5.0"
  repository = "oci://ghcr.io/icoretech/charts"

  values = [
    yamlencode({
      "service" : {
        "port" : 6875
      },
      "config" : {
        "adminPassword" : random_password.default_admin_password.result,
        "existingUserlistSecret" : "pgbouncer-userlist-${var.name}",
        "databases" : {
          "*" : {
            "host" : var.materialize_host
            "port" : 6875,
            "dbname" : "materialize",
            "auth_user" : "materialize",
          }
        }
        "pgbouncer" : {
          "auth_type" : "md5",
          "auth_query" : "SELECT username, password FROM auth_users WHERE username=$1 limit 1;",
          "pool_mode" : "session",
          "max_client_conn" : 1000
        }
      }
    })
  ]
}

