locals {
    public_map = { for idx, cidr in var.var.public_subnets : tostring(idx) => cidr}
    private_map = { for idx, cidr in var.private_subnets : tostring(idx) => cidr}
    az_count = length(var.azs)
}

resource "aws_vpc" "this" {
    cidr_block = var.cidr
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = merge(var.tags, { Name = var.name })
}

resource "aws_internet_gateway" "this" {
    vpc_id = aws_vpc.this.id
    tags = merge(var.tags, { Name = "${var.name}-igw" })
}

# Public Subnet
resource "aws_subnet" "public" {
    for_each = local.public_map
    vpc_id = aws_vpc.this.id
    cidr_block = each.value
    availability_zone = var.azs[tonumber(each.key) % local.az_count]
    map_public_ip_on_launch = true
    tags = merge(var.tags, { Name = "${var.name}-public-${each.key}" })
}

# Private Subnet
resource "aws_subnet" "private" {
    for_each = local.private_map
    vpc_id = aws_vpc.this.id
    cidr_block = each.value
    availability_zone = var.azs[tonumber(each.key) % local.az_count]
    tags = merge(var.tags, { Name = "${var.name}-private-${each.key}" })
}

# Management Subnet
resource "aws_subnet" "management" {
    vpc_id = aws_vpc.this.id
    cidr_block = var.management_subnet
    availability_zone = var.asz[0]
    tags = merge(var.tags, { Name = "${var.name}-management" })
}

# Public Route Table
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.this.id
    tags = merge(var.tags, { Name = "${var.name}-rt-public" })
}

resource "aws_route" "public_internet" {
    route_table_id = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public_assoc" {
    for_each = aws_subnet.public
    subnet_id = each.value.id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.this.id
    tags = merge(var.tags, { Name = "${var.name}-rt-private" })
}

resource "aws_eip" "nat" {
    count = var.enable_nat ? 1 : 0
    depends_on = [ aws_internet_gateway.this ]
    tags = merge(var.tags, { Name = "${var.name}-nat-eip" })
}

locals {
    public_subnet_ids = [
        for s in aws_subnet.public : s.id
    ]
}

resource "aws_nat_gateway" "nat" {
    count = var.enable_nat ? 1 : 0
    subnet_id = aws_eip.nat[0].id
    tags = merge(var.tags, { Name = "${var.name}-nat" })
    depends_on = [ aws_internet_gateway.this ]
}

resource "aws_route" "private_nat" {
    count = var.enable_nat ? 1 : 0
    route_table_id = aws_route_table.private.id
    destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "management" {
    vpc_id = aws_vpc.this.id
    tags = merge(var.tags, { Name = "${var.name}-rt-management" })
}

resource "aws_route_table_association" "management_assoc" {
    subnet_id = aws_subnet.management.id
    route_table_id = aws_route_table.management.id
}