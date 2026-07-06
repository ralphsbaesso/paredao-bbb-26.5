# Desafio Técnico - Desenvolvedor FullStack

## Sumário

1. [O problema](#1-o-problema)
   1. [Regras](#11-regras)
2. [Publique o projeto no Github e documente em um README.md os itens abaixo](#2-publique-o-projeto-no-github-e-documente-em-um-readmemd-os-itens-abaixo)
3. [Itens que serão avaliados](#3-itens-que-serão-avaliados)
4. [Diferenciais](#4-diferenciais)

## 1. O problema

Você deve desenvolver um sistema de votação para o paredão do BBB, em versão Web com HTML/CSS/Javascript e uma API REST como backend utilizando qualquer linguagem de programação (Java, Python, Go, Ruby, etc...).

O paredão do BBB consiste em uma votação que confronta dois integrantes do programa BBB. A votação é apresentada em uma interface acessível pela Web, onde os usuários optam por votar em um dos integrantes apresentados. Uma vez realizado o voto, o usuário recebe uma tela com a confirmação do sucesso de seu voto e um panorama percentual dos votos por candidato até aquele momento.

Além do frontend deve existir uma api onde serão computados os votos.

### 1.1. Regras

- Os usuários podem votar quantas vezes quiserem independente da opção escolhida, entretanto, a produção do programa não gostaria de receber votos oriundos de uma máquina e sim votos de pessoas.
- A votação é chamada em horário nobre, com isso, é esperado um volume elevado de votos. Para exemplificar, vamos trabalhar com 1000 votos/segundo.
- A produção do programa gostaria de consultar em uma URL, o total geral de votos, o total por participante e o total de votos por hora.
- Você apresentará o desafio para o time de avaliadores.

## 2. Publique o projeto no Github e documente em um README.md os itens abaixo

- Documentação do projeto
- Documentação das APIs
- Documentação de arquitetura
- Documentação de como podemos subir uma cópia deste ambiente localmente

## 3. Itens que serão avaliados

- Aplicação rodando
- API
- Frontend
- Instrumentação API
- Facilidade de deploy
- Monitoração da API
- Dashboard da monitoração
- Itens extras listados abaixo

## 4. Diferenciais

- Idealmente, a aplicação deve ser conteinerizada, com pelo menos a API e o Frontend em microservices diferentes. Exemplos de ambientes que suportam aplicações conteinerizadas:
  - Docker compose / Swarm
  - Kubernetes Local / Minikube
  - Kubernetes Cloud
    - GKE
    - EKS
    - AKS
    - Outras clouds
  - outros...
- Testes de carga / performance
- Infrastructure as a code
- CI/CD - automação do processo de deploy com pipelines
- Definir um SLO
- Calcular um SLI
  - Mostrar num Dashboard
- Extra 1: A aplicação deverá gerar logs tipo Warning, Erro, Debug e Info e é importante ter ao menos uma situação de execução com erro no log.
- Extra 2: Utilizando uma ferramenta de métricas (exemplos: Prometheus, Zabbix, cloudwatch ou similar), crie 3 dashboards que mostre em tempo real as métricas que foram instrumentadas para a aplicação

