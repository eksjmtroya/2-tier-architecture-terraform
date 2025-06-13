# ┌──────────────────────┬─────────────────────────────────────────────┬────────────────────────────────────────────────────────────────────────────┐
# │ Security Group       │ ¿Dónde se aplica?                           │ ¿Qué tráfico permite y por qué?                                             │
# ├──────────────────────┼─────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────┤
# │ alb_sg               │ Application Load Balancer (ALB)             │ - Entrada en puerto 80 (HTTP) y 443 (HTTPS)                                 │
# │                      │                                             │   desde cualquier IP pública, porque se usa "0.0.0.0/0",                    │
# │                      │                                             │   que significa "todas las direcciones IPv4".                               │
# │                      │                                             │ - Salida abierta a cualquier destino (egress a 0.0.0.0/0)                   │
# │                      │                                             │   para permitir respuestas o peticiones hacia fuera.                        │
# ├──────────────────────┼─────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────┤
# │ client_sg            │ EC2 de backend / capa aplicación            │ - Entrada en puerto 80 (HTTP) solo desde el security group "alb_sg".       │
# │                      │                                             │   No se permite el acceso desde fuera directamente, solo desde el ALB.     │
# │                      │                                             │ - Salida abierta a cualquier IP (0.0.0.0/0),                                │
# │                      │                                             │   útil para que el backend pueda llamar a APIs externas, repos, etc.       │
# ├──────────────────────┼─────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────┤
# │ db_sg                │ Base de datos (MySQL, por ejemplo en RDS)   │ - Entrada en puerto 3306 (MySQL) solo desde el security group "client_sg", │
# │                      │                                             │   es decir, **solo las instancias backend pueden conectar** al DB.         │
# │                      │                                             │ - Salida abierta (0.0.0.0/0), por si el DB necesita conectarse a algo más. │
# └──────────────────────┴─────────────────────────────────────────────┴────────────────────────────────────────────────────────────────────────────┘



resource "aws_security_group" "alb_sg" {
  name        = "alb security group"
  description = "enable http/https access on port 80/443"
  vpc_id      = var.vpc_id

  ingress {
    description = "http access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "https access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb_sg"
  }
}

# create security group for the Client
resource "aws_security_group" "client_sg" {
  name        = "client_sg"
  description = "enable http/https access on port 80 for elb sg"
  vpc_id      = var.vpc_id

  ingress {
    description     = "http access"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Client_sg"
  }
}

# create security group for the Database
resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  description = "enable mysql access on port 3305 from client-sg"
  vpc_id      = var.vpc_id

  ingress {
    description     = "mysql access"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.client_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "database_sg"
  }
}