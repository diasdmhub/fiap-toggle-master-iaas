# Tech Challenge Fase 3 - IaaS "ToggleMaster"

> Análise geral e implementação do "desafio" da Fase 3 do curso DevOps e Arquitetura Cloud da FIAP.

Nesta fase, o projeto propõe a criação **automática** de um ambiente distribuído em "cloud", focado na AWS, para a execução dos microserviços do sistema ToggleMaster ([o mesmo da Fase 2][fase2]).

<BR>

## 🔑 Prerequisitos

- Faça um **"_fork_" deste repositório** a fim de executar o CI workflow. Ele é utilizado principalmente para enviar as imagens dos microserviços ao AWS ECR;
- O serviço de **"_Actions_" precisa estar habilitado** no repositório;
- Copie o código-fonte do repositório. Recomenda-se **clonar o repositório com o Git**:
    - `git clone https://github.com/SUA_CONTA/FORK_DO_REPO.git && cd FORK_DO_REPO`;
- O terminal local deve estar **autenticado na AWS** com o [**AWS CLI**][awscli];
- É necessário [**instalar o Terraform**][terraform] para implementar os serviços da AWS que serão utilizados pelo sistema ToggleMaster;
- O **`kubectl`** é necessário para gerenciar o cluster Kubernetes e seus recursos. Recomenda-se instalá-lo utilizando o [**repositório oficial do Kubernetes**][kuberepo];

<BR>

## 🛠️ Roteiro de Implementação

### 1. Configurações

Para a implementação inicial, alguns dados precisam ser configurados para permitir que o ambiente seja criado de forma consistente e atendendo às características do ambiente.

#### 1.1 Variáveis

O arquivo `terraform.tfvars` deve ser definido com as principais variáveis do Terraform. Já existem alguns valores pré-definidos, mas é **altamente recomendado que as variáveis abaixo sejam definidas ou alteradas**:

- `name_prefix` - Prefixo do nome dos recursos _(default "fiap-toggle")
- `aws_region` - Regiao da AWS _(default "us-east-1")_
- `subnet_prefix` - Os 2 primeiros octetos do CIDR da VPC _(default "10.12")_
- `db_name` - Nome do banco de dados inicial no RDS _(vazio por padrão)_
- `db_username` - Usuário master do PostgreSQL _(vazio por padrão)_
- `db_password` - Senha do usuário master _(vazio por padrão)_
- `git_org` - Domínio provedor Git _(vazio por padrão)_
- `git_repo` - Repositório do provedor Git _(vazio por padrão)_

Copie o arquivo de exemplo e edite ele com os valores do seu ambiente.

```
cp terraform.tfvars.example terraform.tfvars
```

### 2. Inicialização

Para a estruturação do ambiente AWS, é utilizado o **Terraform**. Ele faz a configuração de todos os recursos utilizados pela ToggleMaster, como o EKS, Elasticache, DynamoDB, etc. Além de implementar os serviços, ele também utiliza a AWS para a persistência do estado da infraestrutura e configuração criada. O S3 Bucket é utilizado para armazenar o arquivo `terraform.tfstate` que "mapeia" a configuração com o recursos criados no _Cloud Provider_. O Terraform também utiliza o DynamoDB para armazenar a "state lock" e evitar modificações concorrentes.

Esses serviços "extras" precisam ser configurados antes da inicialização do Terraform, de modo a permitir que ele crie a persistência do estado da configuração. Portanto, foi criado o script [`init.sh`][init] para configurar o ambiente antes de inicializar o Terraform. Ele deve ser executado na raiz do repositório.

```bash
./init.sh
``` 

Após a inicialização do ambiente, o Terraform estará preparado para aplicar as configurações na AWS. Para isso, basta executar o "Plan" e "Apply" do Terraform.

```
terraform plan
terraform apply
```

<BR>

## 📝 Observações

- A depender da instância utilizada na criação do CI workflow, podem haver diferenças ou limitações nas ações. No entanto, o workflow possui muita flexibilidade para diferentes cenários.
- A autenticação na AWS pode ser realizada com o OIDC. No entanto, devido à relação de certificados e restrições em portas de serviços, o uso de secrets pode ser necessário para ambientes de CI fora do GitHub, como ambientes self-hosted.
- O AWS CLI foi utilizado em alguns passos para:
    - Evita variáveis e suposições específicas do GitHub em ações pré-definidas;
    - Funcionar de forma consistênte no GitHub, Gitea e outro runners self-hosted.
- A verificação de vulnerabilidades da imagem pode ser realiza na AWS, no entanto, podem haver custos implícitos.

[fase2]: https://github.com/diasdmhub/fiap-toggle-master-microservices
[awscli]: https://aws.amazon.com/cli/
[terraform]: https://developer.hashicorp.com/terraform/install
[kuberepo]: https://kubernetes.io/docs/tasks/tools/
[init]: ./init.sh