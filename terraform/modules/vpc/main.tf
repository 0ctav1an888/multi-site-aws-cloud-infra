locals {
  public_map  = { for idx, cidr in var.public_subnets : tostring(idx) => cidr }
  private_map = { for idx, cidr in var.private_subnets : tostring(idx) => cidr }
  az_count    = length(var.azs)
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = var.name })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-igw" })
}

# Public Subnet
resource "aws_subnet" "public" {
  for_each                = local.public_map
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = var.azs[tonumber(each.key) % local.az_count]
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { Name = "${var.name}-public-${each.key}" })
}

# Private Subnet
resource "aws_subnet" "private" {
  for_each          = local.private_map
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = var.azs[tonumber(each.key) % local.az_count]
  tags              = merge(var.tags, { Name = "${var.name}-private-${each.key}" })
}

# Management Subnet
resource "aws_subnet" "management" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.management_subnet
  availability_zone = var.azs[0]
  tags              = merge(var.tags, { Name = "${var.name}-management" })
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-rt-public" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Create one NAT gateway per availability zone for high availability
resource "aws_eip" "nat" {
  count  = var.enable_nat ? length(var.azs) : 0
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.name}-nat-eip-${var.azs[count.index]}" })
}

resource "aws_nat_gateway" "main" {
  count         = var.enable_nat ? length(var.azs) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[tostring(count.index)].id
  tags          = merge(var.tags, { Name = "${var.name}-nat-${var.azs[count.index]}" })
  depends_on    = [aws_internet_gateway.this]
}

# Create separate route table for each private subnet (one per AZ)
resource "aws_route_table" "private" {
  count  = length(var.azs)
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-private-rt-${var.azs[count.index]}" })
}

resource "aws_route" "private_nat" {
  count                  = var.enable_nat ? length(var.azs) : 0
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}

resource "aws_route_table_association" "private_assoc" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[tostring(count.index)].id
  route_table_id = aws_route_table.private[count.index % length(var.azs)].id
}

resource "aws_route_table" "management" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-rt-management" })
}

resource "aws_route_table_association" "management_assoc" {
  subnet_id      = aws_subnet.management.id
  route_table_id = aws_route_table.management.id
}

# Guest Wi-Fi Subnet
resource "aws_subnet" "guest" {
  count             = var.guest_subnet != "" ? 1 : 0
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.guest_subnet
  availability_zone = var.azs[0]
  tags              = merge(var.tags, { Name = "${var.name}-guest" })
}

resource "aws_route_table" "guest" {
  count  = var.guest_subnet != "" ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-rt-guest" })
}

resource "aws_route" "guest_internet" {
  count                  = var.guest_subnet != "" ? 1 : 0
  route_table_id         = aws_route_table.guest[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "guest_assoc" {
  count          = var.guest_subnet != "" ? 1 : 0
  subnet_id      = aws_subnet.guest[0].id
  route_table_id = aws_route_table.guest[0].id
}

# VPC Flow Logs
# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "flow_logs" {
  count             = var.enable_flow_logs ? 1 : 0
  name              = "/aws/vpc/flowlogs/${var.name}"
  retention_in_days = var.flow_logs_retention_days
  tags              = merge(var.tags, { Name = "${var.name}-flow-logs" })
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "flow_logs" {
  count              = var.enable_flow_logs ? 1 : 0
  name               = "${var.name}-flow-logs-role"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume_role[0].json
  tags               = var.tags
}

data "aws_iam_policy_document" "flow_logs_assume_role" {
  count = var.enable_flow_logs ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# IAM Policy for Flow Logs to write to CloudWatch
resource "aws_iam_role_policy" "flow_logs" {
  count  = var.enable_flow_logs ? 1 : 0
  name   = "${var.name}-flow-logs-policy"
  role   = aws_iam_role.flow_logs[0].id
  policy = data.aws_iam_policy_document.flow_logs_policy[0].json
}

data "aws_iam_policy_document" "flow_logs_policy" {
  count = var.enable_flow_logs ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["${aws_cloudwatch_log_group.flow_logs[0].arn}:*"]
  }
}

# VPC Flow Log
resource "aws_flow_log" "main" {
  count                    = var.enable_flow_logs ? 1 : 0
  iam_role_arn             = aws_iam_role.flow_logs[0].arn
  log_destination          = aws_cloudwatch_log_group.flow_logs[0].arn
  traffic_type             = var.flow_logs_traffic_type
  vpc_id                   = aws_vpc.this.id
  max_aggregation_interval = var.flow_logs_max_aggregation_interval

  tags = merge(var.tags, { Name = "${var.name}-flow-log" })
}