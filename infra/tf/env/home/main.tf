terraform {
  backend "local" {
    path = "terraform.tfstate"
  }

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1.1"
    }
    argocd = {
      source  = "argoproj-labs/argocd"
      version = "7.13.0"
    }
  }
}

provider "argocd" {
#  server_addr = "argo.kwkc.home:80"
  server_addr = "localhost:8088"
  username    = "admin"
  password    = var.argocd-pw
  insecure    = true
  plain_text  = true
}

variable "argocd-pw" {
  sensitive = true
}

variable "github-key" {
  sensitive = true
}

resource "argocd_project" "default" {
  metadata {
    name      = "default"
    namespace = "argocd"
  }

  spec {
    # description  = "Default ArgoCD project"
    source_repos = ["*"]

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "default"
    }

    cluster_resource_whitelist {
      group = "*"
      kind  = "*"
    }
  }
}

resource "argocd_repository" "n8n_repo" {
  repo            = "git@github.com:kklein90/n8n.git"
  name            = "n8n"
  type            = "git"
  ssh_private_key = var.github-key
  project         = "default"

  depends_on = [argocd_project.default]
}

resource "argocd_application" "n8n" {
  metadata {
    name      = "n8n"
    namespace = "argocd"
  }

  spec {
    project = "default"

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "default"
      #   name      = "n8n" # conflicts with server param
    }

    source {
      repo_url        = "git@github.com:kklein90/n8n.git"
      path            = "infra/kubernetes/overlays/home"
      target_revision = "main"
    }

    sync_policy {
      automated {
        prune       = true
        self_heal   = true
        allow_empty = true
      }
      sync_options = ["Validate=false"]
      retry {
        limit = "5"
        backoff {
          duration     = "30s"
          max_duration = "2m"
          factor       = "2"
        }
      }
    }
  }

  depends_on = [argocd_project.default, argocd_repository.n8n_repo]
}
