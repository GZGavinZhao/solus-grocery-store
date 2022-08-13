terraform {
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
    }
  }
}

# https://stackoverflow.com/questions/59789730/how-can-i-read-environment-variables-from-a-env-file-into-a-terraform-script
# 
# Put your credentials in a .env file like this:
# ```
# ALICLOUD_ACCESS_KEY="XXX"
# ALICLOUD_SECRET_KEY="ABC"
# ALICLOUD_REGION="us-west-1"
# ```
# Then on Mac/Linux, run `. .env` to make them available to your current shell.
# On Windows, you have to use `set ALICLOUD_ACCESS_KEY="XXX"` individually for each field. Sorry for that.
provider "alicloud" {}
