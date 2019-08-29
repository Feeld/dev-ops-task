terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "feeld-recruitment-daveio"
    # token in .terraformrc
    workspaces {
      prefix = "feeld-"
    }
  }
}
