module "eks" {
  source              = "terraform-aws-modules/eks/aws"
  version             = "20.0"
  cluster_name        = "eks-cluster"
  cluster_version     = "1.24"
  cluster_endpoint_public_access = true
  vpc_id              = module.my-vpc.vpc_id
  subnet_ids          = module.my-vpc.private_subnets
  tags = {
    environment = "development"
    application = "digidine"
  }

  eks_managed_node_groups = {
    dev = {
      min_size     = 1
      max_size     = 3
      desired_size = 2
      instance_types = ["t2.small"]
    }
  }
}


resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  for_each = toset([
    "AmazonEKSWorkerNodePolicy",
    "AmazonEC2ContainerRegistryReadOnly",
    "AmazonEKS_CNI_Policy"
  ])

  policy_arn = "arn:aws:iam::aws:policy/${each.key}"
  role       = aws_iam_role.eks_role.name
}

resource "aws_security_group" "eks_lb_sg" {
  name        = "eks-lb-sg"
  description = "Security group for the EKS Load Balancer"
  vpc_id      = module.my-vpc.vpc_id  # Garantir que o VPC correto seja referenciado

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]  # Permite tráfego de qualquer lugar, pode ajustar conforme necessário
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]  # Permite tráfego de qualquer lugar, pode ajustar conforme necessário
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]  # Permite tráfego de qualquer lugar, pode ajustar conforme necessário
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
  }
}

# Atualizando o Load Balancer para usar o Security Group correto
resource "aws_lb" "eks_lb" {
  name               = "eks-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.eks_lb_sg.id]
  subnets            = module.my-vpc.public_subnets

  enable_deletion_protection = false
}



# Recurso Null para aplicar manifests Kubernetes
resource "null_resource" "apply_k8s" {
  provisioner "local-exec" {
    command = <<EOT
      # Gera o arquivo de kubeconfig
      cat <<EOF > kubeconfig
      apiVersion: v1
      clusters:
      - cluster:
          server: ${module.eks.cluster_endpoint}
        name: ${module.eks.cluster_name}
      contexts:
      - context:
          cluster: ${module.eks.cluster_name}
          user: ${module.eks.cluster_name}
        name: ${module.eks.cluster_name}
      current-context: ${module.eks.cluster_name}
      kind: Config
      preferences: {}
      users:
      - name: ${module.eks.cluster_name}
      EOF

      # Debug: Verifica o conteúdo do kubeconfig
      echo "Conteúdo do kubeconfig:"
      cat kubeconfig

      # Aplica os manifests do Kubernetes
      kubectl apply -f ../k8s-manifests/ --kubeconfig=kubeconfig

      # Debug: Verifica o status dos nós
      kubectl get nodes --kubeconfig=kubeconfig
    EOT
  }
}

resource "aws_subnet" "private" {
  vpc_id            = module.my-vpc.vpc_id  
  cidr_block        = "10.0.1.0/24"            
  availability_zone = "us-east-2a"             
  
}


resource "aws_kms_key" "eks_cluster_key" {
  description             = "eks-cluster cluster encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Environment = "production"
    Application = "eks-cluster"
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/eks/eks-cluster/cluster"
  retention_in_days = 90

  tags = {
    Environment = "production"
    Application = "eks-cluster"
  }
}

resource "aws_security_group" "eks_lb_sg" {
  name        = "eks-lb-sg"                       # Nome do SG
  description = "Security group for the EKS Load Balancer"
  vpc_id      = "vpc-014eb1b4108e08384"           # ID do VPC associado

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-lb-sg"
  }
}

