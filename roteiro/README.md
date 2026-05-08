# 🛠️ Roteiro de Implementação

Para a implementação inicial, alguns dados precisam ser configurados para permitir que o ambiente seja criado de forma consistente e atendendo às características do ambiente.

<BR>

### 1 Variáveis Terraform

O arquivo de [variáveis do Terraform][tfvars] (`terraform.tfvars`) deve ser definido com as principais variáveis do ambiente. É disponibilizado um arquivo de exemplo (`terraform.tfvars.example`) com alguns valores pré-definidos, mas é **altamente recomendado que as variáveis abaixo sejam definidas de acordo com o ambiente**.

> ⚠️ **Note que este arquivo possui dados sensíveis e deve ter seu acesso restrito.**

| Variável | Descrição | Default |
| :---: | :--- | :--- |
| `name_prefix` | Prefixo do nome dos recursos _ | _`fiap-toggle`_ |
| `aws_region` | Regiao da AWS | _`us-east-1`_ |
| `subnet_prefix` | Os 2 primeiros octetos do CIDR da VPC | _`10.12`_ |
| `db_name` | Nome do banco de dados inicial no RDS | _vazio_ |
| `db_username` | Usuário master do PostgreSQL | _vazio_ |
| `db_password` | Senha do usuário master | _vazio_ |
| `git_org` | Domínio provedor Git | _vazio_ |
| `git_repo` | Repositório do provedor Git | _vazio_ |

Copie o arquivo de exemplo e edite ele com os valores do seu ambiente.

```bash
cp terraform.tfvars.example terraform.tfvars
# [vi]/[nano] terraform.tfvars
```

<BR>

### 2. Inicialização AWS

Para a estruturação do ambiente AWS, é utilizado o **Terraform**. Ele faz a configuração de todos os recursos utilizados pela ToggleMaster, como o EKS, Elasticache, DynamoDB, etc. Além de implementar os serviços, ele também utiliza serviços extras da AWS para a persistência do estado da infraestrutura e configuração criada. O **S3 Bucket** é utilizado para armazenar o arquivo `terraform.tfstate` que "mapeia" a configuração com o recursos criados no _Cloud Provider_. O Terraform também utiliza o **DynamoDB** para armazenar o "_state lock_" e evitar modificações concorrentes.

Esses serviços "extras" precisam ser configurados antes da inicialização do Terraform para que ele crie a persistência do estado da configuração. Portanto, o script [`init.sh`][init] está disponível para configurar o ambiente na AWS e inicializar o Terraform em seguida. Ele deve ser executado na raiz do repositório.

```bash
./init.sh
``` 

Após a inicialização do ambiente, o Terraform estará preparado para aplicar as configurações na AWS. Para isso, basta executar o "Plan" e "Apply" do Terraform conforme abaixo.

```bash
terraform plan
terraform apply
```

> A criação dos recursos pode levar alguns minutos, principalmente por causa do cluster EKS e seus nodes. Ao final, será apresentada uma mensagem indicando o término da implementação seguido dos outputs gerados. Algo similar à mensagem abaixo.

> ```
> Apply complete! Resources: 77 added, 0 changed, 0 destroyed.
> ```

<BR>

### 2.1 Configuração `kubectl`

Após a criação dos recursos na AWS, o cluster EKS deve estar disponível. É necessário atualizar a configuração do `kubectl` para o acesso ao cluster. Utilize o comando abaixo para isso.

> Altere o nome do cluster caso seja diferente.

```bash
aws eks update-kubeconfig --region $(aws configure get region) --name "$(grep '^name_prefix' terraform.tfvars | cut -d '"' -f 2)-eks-cluster"
```

<BR>

### 2.2 Configuração de credenciais

Considerando a arquitetura atual do sistema ToggleMaster, algumas credenciais sensíveis só podem ser definidos após a criação da infraestrutura na AWS. Para isso, é utilizado o gerenciador de segredos da AWS (_AWS Secrets Manager_). Alguns valores são extraídos dos outputs do Terraform, outros devem ser definidos manualmente. Eles são considerados sensíveis para evitar a exposição em repositórios públicos.

⚠️ Note que os secrets criados abaixo utilizam o _namespace_ igual ao prefixo do nome dos recursos utilizados no Terraform ("_fiap-toggle_" por padrão). Altere caso utilize outro nome.

<BR>

#### MasterKey do microserviço Auth

É necessário definir uma chave "mestre" para o microserviço de autenticação Auth.

> **Altere o valor de exemplo _`admin123`_ para algo mais complexo e seguro.**

```bash
aws secretsmanager create-secret \
    --name "$(grep '^name_prefix' terraform.tfvars | cut -d '"' -f 2)/master_key" \
    --description "Chave mestre para o microserviço de autenticação Auth" \
    --secret-string '{"password": "admin123"}'
```

<BR>

#### Token do microserviço Evaluation

É necessário definir um _token_ para o microserviço Evaluation. No entanto, só é possível gerar essa chave após a inicialização do microserviço Auth.

> **Altere o valor de exemplo _`teste`_ para algo mais complexo e seguro.**

```bash
aws secretsmanager create-secret \
    --name "$(grep '^name_prefix' terraform.tfvars | cut -d '"' -f 2)/service_api_key" \
    --description "Chave de serviço para o microserviço Evaluation" \
    --secret-string '{"api_key": "teste"}'
```

<BR>

## 3. Build da ToggleMaster

Com o **ambiente AWS criado e os repositório ECR disponíveis**, os microserviços da ToggleMaster podem ser enviados ao repositório de imagens ECR. As imagens do microserviços são construídas e enviadas ao repositório de forma automática através de um [**Git actions workflow**][gitaction].

<BR>

### 3.1 Secrets para o build

**Antes de executar o workflow**, é necessário definir algumas variáveis sensíveis que serão utilizadas nos passos do workflow. Essas variáveis são exclusivas para a conexão do GitHub com a AWS. Para isso, deve-se definir os valores abaixo como "**secrets**" no repositório.

| Variável       | Descrição       |
| :------------: | :-------------- |
| `AWS_ACC_ID`   | ID da conta AWS |
| `AWS_REGION`   | Região da AWS   |
| `AWS_GIT_ROLE` | Role da AWS para o Git Actions. _Esta role é criada pelo Terraform e pode ser consultada com `terraform output oidc_outputs`_ |

<BR>

### 3.2 Push da build

Com o _Git actions_ ativo no repositório, **basta submeter um novo "_push_" ou "_pull request_" em qualquer arquivo dentro do diretório `build`**, que o workflow é disparado. Alternativamente, principalmente para o primeiro build, **também é possível acionar o workflow manualmente**.

<BR>

## 4. Configuração ArgoCD

Esta implementação utiliza o ArgoCD para que a ToggleMaster seja atualizada dinamicamente no cluster EKS. O plano do Terraform já está preparado para instalar o ArgoCD, ficando acessível ao cluster. Entretanto, podem ser necessários alguns ajustes após a disponibilização da aplicação.

<BR>

### 4.1 Interface do ArgoCD

O ArgoCD é configurado por padrão para criar um serviço do tipo "_`ClusterIP`_" no K8s, a fim de evitar exposições desnecessárias e custos extras. No entanto, é possível alterar essa configuração no arquivo de [variáveis do Terraform][tfvars] (_`terraform.tfvars`_). Basta alterar de _`ClusterIP`_ para _`LoadBalancer`_.

#### ClusterIP

Com o serviço do tipo `ClusterIP`, pode-se acessar a interface do ArgoCD utilizando o `port-forward` do Kubernetes, como no exemplo abaixo.

```bash
kubectl port-forward service/argocd-server -n argocd --address 0.0.0.0 8080:443
```

#### LoadBalancer

Caso tenha configurado o serviço como `LoadBalancer`, o _cloud provider_ disponibilizará um _endpoint_ público para acesso à interface. Pode-se obter o _endpoint_ com o comando abaixo.

```bash
kubectl get svc argocd-server -n argocd -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

<BR>

### 4.2 Senha inicial do ArgoCD

O usuário padrão do ArgoCD é `admin`, mas a senha é aleatória. A senha inicial do ArgoCD é gerada automaticamente e salva no _secret_ do K8s chamado `argocd-initial-admin-secret`. O comando abaixo utiliza o `kubectl` para moostrar a senha em texto-claro.

```bash
kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

> ⚠️ **Não esqueça de alterar a senha após o primeiro login.**

<BR>

### 4.3 Registrar o cluster

As credenciais do cluster K8s devem ser registradas no ArgoCD e isso **só é necessário ao utilizar o ArgoCD em um cluster externo.**

> **Estes passos utilizam o [_ArgoCD client_][argocdcli]. Caso esteja utilizando o serviço do tipo `ClusterIP`, é necessário fazer o _port-forward_ primeiro e utilizar o endpoint local. Se o serviço for do tipo `LoadBalancer`, utilize o _endpoint_ criado pelo _cloud provider_.**

1. Faça o login no ArgoCD pelo terminal.

```bash
argocd login [endpoint:porta]
```

2. Verifique se o ArgoCD está registrado no cluster EKS. Normalmente, essa verificação deve indicar a coluna Server como `https://kubernetes.default.svc` e a coluna Name como `in-cluster`.

```bash
argocd cluster list
```

<BR>

## 4. Configuração ToggleMaster

Após criar os recursos da AWS, o Terraform disponibilizará _outputs_ com algumas configurações que serão utilizadas pelo sistema ToggleMaster. É necessário definir essas configurações como variáveis para a ToggleMaster, como URLs de repositórios ECR, Elasticache Valkey, RDS e SQS.

<BR>

### 4.1 Aplicação personalizada no ArgoCD

Esses valores podem ser aplicados na definição do ArgoCD que aplicará a ToggleMaster no cluster EKS. Para isso, é disponibilizado o arquivo `argo_deploy.yaml.example` no diretório `argo` deste repositório. Nele devem ser incluídos os valores corretos que serão aplicados no ambiente, conforme os outputs gerados pelo Terraform. A execução do script `argo_update.sh` facilita o preenchimento dos valores corretos fazendo uma cópia do exemplo já com os valores preenchidos. _Também é possível editar manualmente o arquivo de exemplo, caso prefira._

```bash
./argo/argo_update.sh
```

<BR>

## 4.2 Inicialização da ToggleMaster com o ArgoCD

O novo arquivo `argo_deploy.yaml` será responsável por definir a aplicação personalizada no ArgoCD e a sincronização do repositório com o Kubernetes. Ele deve ser aplicado com o `kubectl` conforme abaixo.

```bash
kubectl apply -f argo/argo_deploy.yaml
```

> **Esse arquivo é ignorado no Git e não deve ser publicado.**

[init]: ./init.sh
[helm]: https://helm.sh/docs/intro/install
[argocdcli]: https://argo-cd.readthedocs.io/en/stable/cli_installation/
[tfvars]: #11-vari%C3%A1veis-terraform
[gitaction]: https://docs.github.com/en/actions/get-started/quickstart