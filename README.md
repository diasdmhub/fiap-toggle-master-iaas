# Tech Challenge Fase 3 - IaaS "ToggleMaster"

> Análise geral e implementação do "desafio" da Fase 3 do curso DevOps e Arquitetura Cloud da FIAP.

Nesta fase, o projeto propõe a criação **automática** de um ambiente distribuído em "cloud", focado na AWS, para a execução dos microserviços do sistema ToggleMaster ([o mesmo da Fase 2][fase2]).

<BR>

## 📋 Prerequisitos

- Faça um **"_fork_" deste repositório** a fim de executar o CI workflow. Ele é utilizado para enviar as imagens dos microserviços ao AWS ECR.
- Copie o código-fonte do repositório. Recomenda-se **clonar este repositório com o Git**:
    - `git clone https://github.com/diasdmhub/fiap-toggle-master-iaas.git && cd fiap-toggle-master-iaas`
- O terminal local deve estar **autenticado na AWS** com o [AWS CLI][awscli].
- É necessário **[instalar o Terraform][terraform]** para implementar os serviços da AWS que serão utilizados pelo sistema ToggleMaster.
- O `kubectl` é necessário para gerenciar o cluster Kubernetes e seus recursos. Recomenda-se instalá-lo utilizando o [repositório oficial do Kubernetes][kuberepo].

<BR>

## 🛠️ Roteiro de Implementação

[fase2]: https://github.com/diasdmhub/fiap-toggle-master-microservices
[awscli]: https://aws.amazon.com/cli/
[terraform]: https://developer.hashicorp.com/terraform/install
[kuberepo]: https://kubernetes.io/docs/tasks/tools/