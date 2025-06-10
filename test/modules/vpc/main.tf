resource "aws_vpc" "my_vpc" {
  cidr_block = var.cidr
  tags = merge(
    var.tags,
    {
        Name = "chatapp-vpc"
    }
  )
}

resource "aws_subnet" "pub_sub" {
  vpc_id                  = aws_vpc.my_vpc.id
  count                   = length(var.pub_sub)
  cidr_block              = var.pub_sub[count.index]
  availability_zone       = "${var.region}${var.az[count.index]}"
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
        Name = "chatapp-public-3${var.az[count.index]}"
    }
  )
}

resource "aws_subnet" "pvt_sub" {
  vpc_id            = aws_vpc.my_vpc.id
  count             = length(var.pvt_sub)
  cidr_block        = var.pvt_sub[count.index]
  availability_zone = "eu-west-3${var.az[count.index]}"

  tags = merge(
    var.tags,
    {
        Name = "chatapp-pvt-3${var.az[count.index]}"
    }
  )
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = merge(
    var.tags,
    {
        Name = "chatapp-internet-gw"
    }
  )
}

resource "aws_eip" "my_eip" {
  domain = "vpc"
  depends_on = [
    aws_internet_gateway.igw
  ]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.my_eip.id
  subnet_id     = aws_subnet.pub_sub[0].id

  depends_on = [
    aws_internet_gateway.igw
  ]

  tags = merge(
    var.tags,
    {
        Name = "chatapp-nat-gw"
    }
  )
}

resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    var.tags,
    {
        Name = "chatapp-pub-rt"
    }
  )
}

resource "aws_route_table" "pvt_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(
    var.tags,
    {
        Name = "chatapp-pvt-rt"
    }
  )
}

resource "aws_route_table_association" "pub_a" {
  count          = length(var.pub_sub)
  route_table_id = aws_route_table.pub_rt.id
  subnet_id      = aws_subnet.pub_sub[count.index].id
}

resource "aws_route_table_association" "pvt_a" {
  count          = length(var.pvt_sub)
  route_table_id = aws_route_table.pvt_rt.id
  subnet_id      = aws_subnet.pvt_sub[count.index].id
}