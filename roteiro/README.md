# 🛠️ Roteiro de Implementação

Para a implementação inicial, alguns dados precisam ser configurados para permitir que o ambiente seja criado de forma consistente e atendendo às características do ambiente.

<BR>

## 1 Variáveis Terraform

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

#### MasterKey do microserviço Auth

É necessário definir uma chave "mestre" para o microserviço de autenticação Auth.

> **Altere o valor de exemplo _`admin123`_ para algo mais complexo e seguro.**

```bash
aws secretsmanager create-secret \
    --name "$(grep '^name_prefix' terraform.tfvars | cut -d '"' -f 2)/master_key" \
    --description "Chave mestre para o microserviço de autenticação Auth" \
    --secret-string '{"password": "admin123"}'
```

#### Token do microserviço Evaluation

É necessário definir um _token_ para o microserviço Evaluation. No entanto, só é possível gerar essa chave após a inicialização do microserviço Auth. Neste primeiro momento basta criar o secret com um valor aleatório. Isso é necesário para evitar falha na inicialização dos microserviços.

> **Este _secret_ será atualizado mais adiante.**

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

Com o _Git actions_ ativo no repositório, **basta submeter um novo "_push_" ou "_pull request_" em qualquer arquivo dentro do diretório `build`**, que o workflow é disparado. Alternativamente, principalmente para o primeiro build, **também é possível [acionar o workflow manualmente][runflow]**.

<BR>

## 4. Configuração ArgoCD

Esta implementação utiliza o ArgoCD para que a ToggleMaster seja atualizada dinamicamente no cluster EKS. O plano do Terraform já está preparado para instalar o ArgoCD, ficando acessível ao cluster. Entretanto, podem ser necessários alguns ajustes após a disponibilização da aplicação.

<BR>

### 4.1 (_Opcional_) Interface do ArgoCD

O ArgoCD é configurado por padrão para criar um serviço do tipo "_`ClusterIP`_" no K8s, a fim de evitar exposições desnecessárias e custos extras. No entanto, é possível alterar essa configuração no arquivo de [variáveis do Terraform][tfvars] (_`terraform.tfvars`_). Basta alterar de _`ClusterIP`_ para _`LoadBalancer`_.

#### ClusterIP

Com o serviço do tipo `ClusterIP`, pode-se acessar a interface do ArgoCD utilizando o `port-forward` do Kubernetes, como no exemplo abaixo. Depois, a interface estará acessível no navegador com o endpoint do ambiente local e na porta encaminhada (`8080`).

```bash
kubectl port-forward service/argocd-server -n argocd --address 0.0.0.0 8080:443
```

#### LoadBalancer

Caso tenha configurado o serviço como `LoadBalancer`, o _cloud provider_ disponibilizará um _endpoint_ público para acesso à interface. Pode-se obter o _endpoint_ com o comando abaixo. Depois, a interface estará acessível no navegador com o endpoint público da AWS.

```bash
kubectl get svc argocd-server -n argocd -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

<BR>

### 4.2 Senha inicial do ArgoCD

O usuário padrão do ArgoCD é `admin`, mas a senha é aleatória. A senha inicial do ArgoCD é gerada automaticamente e salva no _secret_ do K8s chamado `argocd-initial-admin-secret`. O comando abaixo utiliza o `kubectl` para mostrar a senha em texto-claro.

```bash
kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

> ⚠️ **Não esqueça de alterar a senha após o primeiro login.**

<BR>

### 4.3 (_Opcional_) Registrar o cluster

As credenciais do cluster K8s devem ser registradas no ArgoCD e isso **só é necessário ao utilizar o ArgoCD em um cluster externo.** Se necessário, siga os passos oficiais da [documentação do ArgoCD][argodoc] para registrar o cluster.

<BR>

## 5. Configuração ToggleMaster

Com os serviços da AWS criados, o Terraform disponibilizará _outputs_ com algumas configurações que serão utilizadas pelo sistema ToggleMaster. É necessário definir essas configurações como variáveis para a ToggleMaster, sendo URLs de repositórios ECR, Elasticache Valkey, RDS e SQS.

<BR>

### 5.1 Aplicação personalizada no ArgoCD

Esses valores podem ser aplicados na definição do ArgoCD que aplicará a ToggleMaster no cluster EKS. Para isso, é disponibilizado o arquivo `argo_deploy.yaml.example` no diretório `argo` deste repositório. Nele devem ser incluídos os valores corretos que serão aplicados no ambiente, conforme os outputs gerados pelo Terraform.

O script `argo_update.sh` está disponível no mesmo diretório. Ele facilita o preenchimento dos valores corretos fazendo uma cópia do exemplo já com os valores preenchidos. _Também é possível editar manualmente o arquivo de exemplo, caso prefira._

```bash
./argo/argo_update.sh
```

<BR>

### 5.2 Inicialização da ToggleMaster com o ArgoCD

> **É possível incluir a aplicação ToggleMaster diretamente pela interface do ArgoCD. Para isso, é necessário acessar a interface conforme descrito acima.**

Se optar por utilizar o manifesto `argo_deploy.yaml`, ele será responsável por definir a aplicação personalizada no ArgoCD e a sincronização do repositório com o Kubernetes. Ele deve ser aplicado com o `kubectl` conforme abaixo.

```bash
kubectl apply -f argo/argo_deploy.yaml
```

> **Esse arquivo é ignorado no Git e não deve ser publicado.**

<BR>

## 6. Validação

Nesta etapa, o sistema ToggleMaster deve estar ativo e pronto para receber mensagens. Para validar seu funcionamento, é necessário criar uma chave de autenticação com o microserviço `auth-service`, uma "feature flag" com o microserviço `flag-service` e uma regra de segmentação com o microserviço `targeting-service`.

<BR>

#### 4.1 Consulte os IPs dos serviços no cluster com o `kubectl`, conforme indicado abaixo. O resultado deve ser algo similar a seguir.

```bash
$ kubectl get service -n toggle
NAME         TYPE           CLUSTER-IP       EXTERNAL-IP                               PORT(S)          AGE
analytics    ClusterIP      172.20.201.49    <none>                                    8005/TCP         86m
auth         ClusterIP      172.20.90.88     <none>                                    8001/TCP         86m
evaluation   LoadBalancer   172.20.86.71     abc614f-123.us-east-1.elb.amazonaws.com   8004:30891/TCP   86m
flag         ClusterIP      172.20.114.165   <none>                                    8002/TCP         86m
targeting    ClusterIP      172.20.93.183    <none>                                    8003/TCP         86m
```

#### 4.2 Crie uma flag e sua regra de segmentação com os comandos a seguir.

O script abaixo demonstra a criação da feature-flag interna e a definição de uma regra de segmentação para a flag. **Pode-se executar o bloco de comandos diretamente no terminal.**

> ⚠️ **Para criar um token, a flag e a segmentação, é necessário acessar os microserviços internos. Pode ser utilizado o _port-fowarding_ para isso.**

```bash
# Master key do microserviço de autenticação
NAME_PREFIX="$(grep '^name_prefix' terraform.tfvars | cut -d '"' -f 2)"
AWS_REGION="$(aws configure get region)"
MASTER_KEY=$(aws secretsmanager get-secret-value \
    --secret-id "$NAME_PREFIX/master_key" \
    --region "$AWS_REGION" \
    --query 'SecretString' \
    --output text 2>&1 | jq -r '.password' 2>&1)
if [ $? -ne 0 ]; then
    echo "⚠ Erro ao recuperar o secret"
    exit 1
fi

# Port-fowarding dos microserviços internos
kubectl port-forward service/auth -n toggle --address 0.0.0.0 8001:8001 &
kubectl port-forward service/flag -n toggle --address 0.0.0.0 8002:8002 &
kubectl port-forward service/targeting -n toggle --address 0.0.0.0 8003:8003 &
sleep 5

# Criar chave de autenticação
FLAG_TOKEN=$(curl -X POST http://localhost:8001/admin/keys \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $MASTER_KEY" \
    -d '{"name": "toggle-flag"}' | sed -n 's/.*"key":"\([^"]*\)".*/\1/p')

# Atualizar o secret com o novo token
aws secretsmanager update-secret \
    --secret-id "$NAME_PREFIX/service_api_key" \
    --secret-string "{\"api_key\": \"$FLAG_TOKEN\"}" \
    --region "$AWS_REGION"

# Atualizar o secret no Kubernetes
kubectl annotate externalsecret evaluation-secrets \
    force-sync=$(date +%s) \
    --overwrite -n toggle
kubectl get externalsecret evaluation-secrets -n toggle
kubectl rollout restart deployment/evaluation-service -n toggle
sleep 5

# Criar feature flag com a chave 
curl -X POST http://localhost:8002/flags \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $FLAG_TOKEN" \
    -d '{
            "name": "enable-feature",
            "description": "Ativa o novo recurso para os usuários",
            "is_enabled": true
        }'

# Criar uma regra de segmentação
curl -X POST http://localhost:8003/rules \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $FLAG_TOKEN" \
    -d '{
            "flag_name": "enable-feature",
            "is_enabled": true,
            "rules": {
                "type": "PERCENTAGE",
                "value": 50
            }
        }'

# Finalizar os jobs em background
kill $(jobs -p)
```

#### **4.2** Envie mensagens para o ToggleMaster.

Neste teste, são enviadas algumas mensagens, as quais são enfileiradas no SQS. O `analytics-service` processa as mensagens e as envia para a tabela do DynamoDB. Nesse momento, é possível observar tanto o enfileiramento de mensagens no SQS quanto sua gravação no DynamoDB. Utilize o console da AWS para observar isso.

Na interface do ArgoCD também é possível observar o escalonamento de pods do `analytics-service` à medida que novas mensagens são enfileiradas.

    > ⚠️ **Este teste envia muitas mensagens ao ToggleMaster e pode levar um tempo, pois o serviço precisa se comunicar com a AWS. Se preferir, basta reduzir o número de mensagens enviadas para acelerar o processo.**

```bash
for i in $(seq 1000); do { curl "http://abc614f-123.us-east-1.elb.amazonaws.com:8004/evaluate?user_id=teste-$i&flag_name=enable-feature" ; } done
```

- Opcionalmente, é possível observar as mensagens sendo processadas no log do `analytics-service`.

[init]: ./init.sh
[helm]: https://helm.sh/docs/intro/install
[argocdcli]: https://argo-cd.readthedocs.io/en/stable/cli_installation/
[tfvars]: #11-vari%C3%A1veis-terraform
[gitaction]: https://docs.github.com/en/actions/get-started/quickstart
[runflow]: https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow
[argodoc]: https://argo-cd.readthedocs.io/en/stable/getting_started/