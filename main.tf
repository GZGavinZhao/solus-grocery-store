# Specify them in the .env file. See `version.tf` for more info.
variable "REGION" {
  description = "Region to deploy to."
}
variable "ACCOUNT_ID" {
  description = "The MASTER account ID."
}

variable "repo_name" {
  type     = string
  default  = "grocery"
  nullable = false
}

locals {
  # "pisces" will become "Pisces". It just looks a bit better (强迫症狂喜).
  repoName = title(var.repo_name)
  # We need to make sure that there's no space in the front.
  sls_token = ", '\";=()[]{}?@&<>/:\n\t\r"
}

# ========== Resource group for better management ==========

resource "alicloud_resource_manager_resource_group" "repo" {
  resource_group_name = "${var.repo_name}-rg"
  display_name        = "${local.repoName} Repo Resource Group"
}

# ========== OSS bucket of the repo for users to download ==========

resource "alicloud_oss_bucket" "repo" {
  bucket = "solus-grocery-store-oss"
  acl    = "public-read"
}

# ========== Create VPC to connect FC and NAS ==========

resource "alicloud_vpc" "repo" {
  vpc_name          = "${var.repo_name}-repo-vpc"
  cidr_block        = "172.16.0.0/12"
  resource_group_id = alicloud_resource_manager_resource_group.repo.id
}

resource "alicloud_vswitch" "repo" {
  vswitch_name = "${var.repo_name}-repo-vswitch"
  vpc_id       = alicloud_vpc.repo.id
  cidr_block   = "172.16.0.0/21"
  # Who the heck decided to name things like this?!
  # `cn-beijing-a` is equivalent to `cn-beijinga`, but `us-east-1-a` is NOT
  # equal to `us-east-1a`
  zone_id = "${var.REGION}a"
}

resource "alicloud_security_group" "repo" {
  name                = "${var.repo_name}-repo-sg"
  description         = "Security group for the ${local.repoName} repository, mainly for NAS"
  resource_group_id   = alicloud_resource_manager_resource_group.repo.id
  vpc_id              = alicloud_vpc.repo.id
  security_group_type = "normal"
}

resource "alicloud_security_group_rule" "repo-allow-433-tcp" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "443/443"
  priority          = 1
  security_group_id = alicloud_security_group.repo.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "repo-allow-all-icmp" {
  type              = "ingress"
  ip_protocol       = "icmp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  priority          = 1
  security_group_id = alicloud_security_group.repo.id
  cidr_ip           = "0.0.0.0/0"
}

# ========== Create a NAS to mount in FC ==========

resource "alicloud_nas_file_system" "repo" {
  file_system_type = "standard"
  protocol_type    = "NFS"
  storage_type     = "Performance"
  # Illegal characters... What?!? No spaces???
  # description      = lower("NAS for ${local.repoName} repo since OSS sucks in performance")
  description = "nas4repofc"
  zone_id     = "${var.REGION}a"
  vpc_id      = alicloud_vpc.repo.id
  vswitch_id  = alicloud_vswitch.repo.id
}

resource "alicloud_nas_access_group" "repo" {
  access_group_name = "${var.repo_name}-repo-ag"
  access_group_type = "Vpc"
  description       = "ag4repofc"
  file_system_type  = "standard"
}

resource "alicloud_nas_access_rule" "repo-fc" {
  access_group_name = alicloud_nas_access_group.repo.access_group_name
  source_cidr_ip    = alicloud_vpc.repo.cidr_block
  rw_access_type    = "RDWR"
  user_access_type  = "root_squash"
  priority          = 100
}

resource "alicloud_nas_mount_target" "repo-fc" {
  file_system_id    = alicloud_nas_file_system.repo.id
  access_group_name = alicloud_nas_access_group.repo.access_group_name
  vswitch_id        = alicloud_vswitch.repo.id
  security_group_id = alicloud_resource_manager_resource_group.repo.id
}

# ========== Create a RAM user/role for the repos ==========

resource "alicloud_ram_user" "repo-manager" {
  name         = "${var.repo_name}-manager"
  display_name = "${local.repoName} RAM user ${local.repoName}RAM用户"
  # If I put them on a new line using EOT, terraform or Aliyun will always
  # detect changes, which is not desirable. This doesn't occur on resources.
  # Weird!
  comments = "RAM user for managing the ${local.repoName} repo(s).\n用于管理${local.repoName}仓库的RAM用户。"
  force    = true
}

resource "alicloud_ram_role" "repo-fc" {
  name        = "${local.repoName}RepoFCRole"
  document    = <<EOT
  {
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
          "Service": [
            "fc.aliyuncs.com",
            "oss.aliyuncs.com"
          ]
        }
      }
    ],
    "Version": "1"
  }
  EOT
  description = <<EOT
  RAM role for FC for ${local.repoName} repo.
  用于管理${local.repoName}仓库的FC的RAM角色。
  EOT
  force       = true
}

# ========== Grant necessary permissions to the RAM user/role to use in FC ==========

# Allow managing the repo bucket. 允许管理repo bucket。
# r: read; w: write; d: delete.
resource "alicloud_ram_policy" "repo-bucket-rw" {
  policy_name     = "${local.repoName}RepoBucketNoDeleteAccess"
  policy_document = <<EOT
  {
      "Version": "1",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": "oss:*",
              "Resource": [
                  "acs:oss:*:*:${alicloud_oss_bucket.repo.id}",
                  "acs:oss:*:*:${alicloud_oss_bucket.repo.id}/*"
              ]
          },
          {
              "Effect": "Deny",
              "Action": "oss:DeleteBucket",
              "Resource": "acs:oss:*:*:${alicloud_oss_bucket.repo.id}"
          },
          {
              "Effect": "Deny",
              "Action": "oss:DeleteObject",
              "Resource": "acs:oss:*:*:${alicloud_oss_bucket.repo.id}/*"
          }
      ]
  }
  EOT
  description     = <<EOT
  Allow read, writing, but not deleting objects in the ${local.repoName} repo bucket.
  允许在${local.repoName}仓库的Bucket中读、写对象，但不能删除对象。
  EOT
  force           = true
}

# Allow basic permissions in FC (VPC, LogStore, etc.).
# FC中的一些默认权限，如VPC、日志存储等。
resource "alicloud_ram_policy" "repo-fc" {
  policy_name     = "${local.repoName}RepoFCPolicy"
  policy_document = <<EOT
  {
    "Version": "1",
    "Statement": [
        {
            "Action": [
                "vpc:DescribeVSwitchAttributes",
                "vpc:DescribeVpcAttribute"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "ecs:CreateNetworkInterface",
                "ecs:DeleteNetworkInterface",
                "ecs:DescribeNetworkInterfaces",
                "ecs:CreateNetworkInterfacePermission",
                "ecs:DescribeNetworkInterfacePermissions",
                "ecs:DeleteNetworkInterfacePermission"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": "log:PostLogStoreLogs",
            "Resource": "*",
            "Effect": "Allow"
        },
    {
            "Action": [
                "fc:InvokeFunction",
                "mns:SendMessage",
                "mns:PublishMessage",
                "eventbridge:PutEvents",
                "mq:PUB",
                "mq:OnsInstanceBaseInfo"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
  }
  EOT
  description     = <<EOT
  The default roles/permissions to use in FC.
  在FC中的默认权限。
  EOT
  force           = true
}

resource "alicloud_ram_user_policy_attachment" "repo-oss" {
  user_name   = alicloud_ram_user.repo-manager.name
  policy_name = alicloud_ram_policy.repo-bucket-rw.name
  policy_type = alicloud_ram_policy.repo-bucket-rw.type
}

resource "alicloud_ram_user_policy_attachment" "repo-fc" {
  user_name   = alicloud_ram_user.repo-manager.name
  policy_name = alicloud_ram_policy.repo-fc.name
  policy_type = alicloud_ram_policy.repo-fc.type
}

resource "alicloud_ram_role_policy_attachment" "repo-oss" {
  role_name   = alicloud_ram_role.repo-fc.name
  policy_name = alicloud_ram_policy.repo-bucket-rw.name
  policy_type = alicloud_ram_policy.repo-bucket-rw.type
}

resource "alicloud_ram_role_policy_attachment" "repo-fc" {
  role_name   = alicloud_ram_role.repo-fc.name
  policy_name = alicloud_ram_policy.repo-fc.name
  policy_type = alicloud_ram_policy.repo-fc.type
}

# ========== Setup Log Service ==========

resource "alicloud_log_project" "repo" {
  name        = "${var.repo_name}-repo"
  description = <<EOT
  Log Project for storing logs of the ${local.repoName} repo.
  用以存储${local.repoName}仓库的Log Project。
  EOT
}

resource "alicloud_log_store" "repo-fc" {
  project          = alicloud_log_project.repo.name
  name             = "${var.repo_name}-fc"
  retention_period = 14
  shard_count      = 1
}

resource "alicloud_log_store_index" "repo" {
  project  = alicloud_log_project.repo.name
  logstore = alicloud_log_store.repo-fc.name
  full_text {
    # I don't know why we need another chomp even though we're not using EOT...
    token = local.sls_token
  }

  # Required for accurate log querying.
  field_search {
    name             = "aggPeriodSeconds"
    type             = "long"
    enable_analytics = true
  }
  field_search {
    name             = "concurrentRequests"
    type             = "long"
    enable_analytics = true
  }
  field_search {
    name             = "cpuPercent"
    type             = "double"
    enable_analytics = true
  }
  field_search {
    name             = "cpuQuotaPercent"
    type             = "double"
    enable_analytics = true
  }
  field_search {
    name             = "errorType"
    type             = "text"
    enable_analytics = true
    token            = local.sls_token
  }
  field_search {
    name             = "functionName"
    type             = "text"
    case_sensitive   = true
    token            = local.sls_token
    enable_analytics = true
  }
  field_search {
    name             = "hasFunctionError"
    type             = "text"
    token            = local.sls_token
    enable_analytics = true
  }
  field_search {
    name             = "hostname"
    type             = "text"
    token            = local.sls_token
    enable_analytics = true
  }
  field_search {
    name             = "instanceID"
    type             = "text"
    token            = local.sls_token
    enable_analytics = true
  }
  field_search {
    name             = "ipAddress"
    type             = "text"
    token            = local.sls_token
    enable_analytics = true
  }
  field_search {
    name             = "isColdStart"
    type             = "text"
    token            = local.sls_token
    enable_analytics = true
  }
  field_search {
    name             = "memoryLimitMB"
    type             = "double"
    enable_analytics = true
  }
  field_search {
    name             = "memoryUsageMB"
    type             = "double"
    enable_analytics = true
  }
  field_search {
    name             = "memoryUsagePercent"
    type             = "double"
    enable_analytics = true
  }
  field_search {
    name             = "operation"
    type             = "text"
    token            = local.sls_token
    enable_analytics = true
  }
  field_search {
    name             = "qualifier"
    type             = "text"
    case_sensitive   = true
    token            = local.sls_token
    enable_analytics = true
  }
  field_search {
    name             = "rxBytes"
    type             = "long"
    enable_analytics = true
  }
  field_search {
    name             = "rxTotalBytes"
    type             = "long"
    enable_analytics = true
  }
  field_search {
    name             = "serviceName"
    type             = "text"
    case_sensitive   = true
    token            = local.sls_token
    enable_analytics = true
  }
  field_search {
    name             = "txBytes"
    type             = "long"
    enable_analytics = true
  }
  field_search {
    name             = "txTotalBytes"
    type             = "long"
    enable_analytics = true
  }
  field_search {
    name             = "versionId"
    type             = "text"
    token            = local.sls_token
    enable_analytics = true
  }
}

# ========== Setup FC ==========

resource "alicloud_fc_service" "repo" {
  name            = "${var.repo_name}-repo"
  description     = <<EOT
  ${local.repoName} repo indexing service.
  ${local.repoName}仓库搭建服务。
  EOT
  internet_access = false
  log_config {
    project  = alicloud_log_project.repo.name
    logstore = alicloud_log_store.repo-fc.name
  }
  vpc_config {
    vswitch_ids       = [alicloud_vswitch.repo.id]
    security_group_id = alicloud_security_group.repo.id
  }
  nas_config {
    user_id  = 0
    group_id = 0
    # What if I want two mount points?
    mount_points {
      server_addr = "${alicloud_nas_mount_target.repo-fc.mount_target_domain}:/"
      mount_dir   = "/mnt/repo"
    }
  }
  role = alicloud_ram_role.repo-fc.arn
  depends_on = [
    alicloud_ram_role_policy_attachment.repo-oss,
    alicloud_ram_role_policy_attachment.repo-fc,
  ]
}

data "alicloud_file_crc64_checksum" "indexer" {
  filename = "indexer.zip"
}

resource "alicloud_fc_function" "indexer" {
  service       = alicloud_fc_service.repo.name
  name          = "${var.repo_name}-repo-solus-indexer"
  description   = <<EOT
  ${local.repoName} Solus repo auto indexer.
  ${local.repoName}Solus仓库的自动indexer。
  EOT
  handler       = "main"
  memory_size   = "512"
  runtime       = "go1"
  filename      = "indexer.zip"
  code_checksum = data.alicloud_file_crc64_checksum.indexer.checksum
  environment_variables = {
    "BUCKET" : alicloud_oss_bucket.repo.id,
  }
}

resource "alicloud_fc_trigger" "solus-repo-trigger" {
  service    = alicloud_fc_service.repo.name
  function   = alicloud_fc_function.indexer.name
  name       = "repo-oss-trigger"
  role       = alicloud_ram_role.repo-fc.arn
  source_arn = "acs:oss:${var.REGION}:${var.ACCOUNT_ID}:${alicloud_oss_bucket.repo.id}"
  type       = "oss"
  config     = <<EOT
  {
    "events": [
      "oss:ObjectCreated:PostObject",
      "oss:ObjectCreated:PutObject",
      "oss:ObjectRemoved:DeleteObject",
      "oss:ObjectRemoved:DeleteObjects"
    ],
    "filter": {
      "key": {
        "prefix": "",
        "suffix": ".eopkg"
      }
    }
  }
  EOT
}
