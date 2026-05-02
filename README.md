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
- O [`helm`][helm] também pode ser utilizado neste cenário ao aplicar os [ExternalSecrets (ClusterSecretStore)][extsecret].
- _(Opcional)_ O [cliente ArgoCD CLI][argocdcli] pode ser instalado para auxiliar as configurações da ToggleMaster no cluster. Abaixo são oferecidos alguns scripts que utilizam ele.

<BR>

## 🛠️ Roteiro de Implementação

### 1. Configurações

Para a implementação inicial, alguns dados precisam ser configurados para permitir que o ambiente seja criado de forma consistente e atendendo às características do ambiente.

#### 1.1 Variáveis Terraform

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

```bash
cp terraform.tfvars.example terraform.tfvars
```

<BR>

### 2. Inicialização AWS

Para a estruturação do ambiente AWS, é utilizado o **Terraform**. Ele faz a configuração de todos os recursos utilizados pela ToggleMaster, como o EKS, Elasticache, DynamoDB, etc. Além de implementar os serviços, ele também utiliza a AWS para a persistência do estado da infraestrutura e configuração criada. O S3 Bucket é utilizado para armazenar o arquivo `terraform.tfstate` que "mapeia" a configuração com o recursos criados no _Cloud Provider_. O Terraform também utiliza o DynamoDB para armazenar a "state lock" e evitar modificações concorrentes.

Esses serviços "extras" precisam ser configurados antes da inicialização do Terraform, de modo a permitir que ele crie a persistência do estado da configuração. Portanto, foi criado o script [`init.sh`][init] para configurar o ambiente antes de inicializar o Terraform. Ele deve ser executado na raiz do repositório.

```bash
./init.sh
``` 

Após a inicialização do ambiente, o Terraform estará preparado para aplicar as configurações na AWS. Para isso, basta executar o "Plan" e "Apply" do Terraform.

```bash
terraform plan
terraform apply
```

> A criação dos recursos pode levar alguns minutos, principalmente por causa do cluster EKS e seus nodes. Ao final, será apresentada uma mensagem indicando o término da implementação seguido dos outputs gerados.

> ```
> Apply complete! Resources: 49 added, 0 changed, 0 destroyed.
> ```

### 2.1 Configuração `kubectl`

Após a criação do cluster EKS, é necessário atualizar a configuração do `kubectl` para o acesso ao cluster. Utilize o comando abaixo para isso.

```bash
aws eks update-kubeconfig --region us-east-1 --name fiap-toggle-eks-cluster
```

### 2.2 Configuração Helm

O Helm é utilizado nesta implementação para facilitar a instalação de recursos acessórios ao ambiente Kubernetes. Diversas das distribuições disponibilizam pacotes de instalação do Helm por meio de seus gerenciadores de pacotes. Por exemplo:

```bash
dnf install helm
```

Também é possível instalar a versão mais recente do Helm a partir de seu repositório público.

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash
```

> O Helm não é necessário para a implementação da infraestrutura da ToggleMaster, mas é recomendado.

<BR>

### 2.3 Configuração External Secrets

Com o Helm instalado, deve-se instalar o recurso de External Secrets de modo a permitir que as variáveis sensíveis do sistema ToggleMaster sejam armazenadas em um repositório seguro. Neste caso, a instalação do External Secrets é realizada com os comandos abaixo.

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace
```

<BR>

### 2.4 Configuração Keda

Outro recurso extra da ToggleMaster, é o Keda que é utilizado para escalonar o microserviço `analytics-service`, de modo que seus pods aumentem caso o tamanho da fila SQS aumente significativamente.

Para instalar o KEDA, basta aplicar seu manifesto, conforme [indicado em sua documentação][keda].

```bash
kubectl apply --server-side -f https://github.com/kedacore/keda/releases/download/v2.19.0/keda-2.19.0.yaml
```

<BR>

## 3. Configuração ArgoCD

Para esta implementação é utlizado o ArgoCD para que a ToggleMaster seja atualizada dinamicamente no EKS. O plano do Terraform já está preparado para instalar o ArgoCD no cluster e ele deve estar acessível após essa

<BR>

## 3. Configuração ToggleMaster

Após criar os recursos da AWS, o Terraform disponibilizará _outputs_ com as configurações que serão utilizadas pelo sistema ToggleMaster. É necessário definir essas configurações como variáveis para a ToggleMaster, como URLs de repositórios ECR, Elasticache Valkey, RDS e SQS.

Esses valores podem ser aplicados na definição do ArgoCD que aplicará a ToggleMaster no cluster EKS. Para isso, é disponibilizado o arquivo `argo_deploy.yaml.example` no diretório `argo` deste repositório. O script `toggle_deploy.sh` facilita o preenchimento dos valores corretos no arquivo.

```bash
toggle_deploy.sh
```

<BR>

## 📝 Observações

- A depender da instância utilizada na criação do CI workflow, podem haver diferenças ou limitações nas ações. No entanto, o workflow possui muita flexibilidade para diferentes cenários.
- A autenticação na AWS pode ser realizada com o OIDC. No entanto, devido à relação de certificados e restrições em portas de serviços, o uso de secrets pode ser necessário para ambientes de CI fora do GitHub, como ambientes self-hosted.
- O AWS CLI foi utilizado em alguns passos para:
    - Evita variáveis e suposições específicas do GitHub em ações pré-definidas;
    - Funcionar de forma consistênte no GitHub, Gitea e outro runners self-hosted.
- A verificação de vulnerabilidades da imagem pode ser realiza na AWS, no entanto, podem haver custos implícitos.

- Considerando que o objetivo desta implementação é atualizar os microserviços automaticamente com o ArgoCD, não há necessidade de atualizar o valor da tag das imagens construídas no manifesto de deployment dos microserviços, haja vista que o ArgoCD pode detectar a tag mais recente do _registry_.
- 

[fase2]: https://github.com/diasdmhub/fiap-toggle-master-microservices
[awscli]: https://aws.amazon.com/cli/
[terraform]: https://developer.hashicorp.com/terraform/install
[kuberepo]: https://kubernetes.io/docs/tasks/tools/
[init]: ./init.sh
[helm]: https://helm.sh/docs/intro/install
[extsecret]: https://external-secrets.io/
[argocdcli]: https://argo-cd.readthedocs.io/en/stable/cli_installation/
[keda]: https://keda.sh/docs/2.19/deploy/#yaml