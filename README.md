# House Security

---

## Sumário
* [1. Sobre o Projeto](#1-sobre-o-projeto)
* [2. ODS Escolhida](#2-ods-escolhida)
* [3. O Problema Real](#3-o-problema-real)
* [4. A Solução com Inteligência Artificial](#4-a-solução-com-inteligência-artificial)
* [5. Público Alvo](#5-público-alvo)
* [6. Modelagem de Dados (UML)](#6-modelagem-de-dados-uml)
* [7. Arquitetura do Sistema (Modelo C4)](#7-arquitetura-do-sistema-modelo-c4)

## 1. Sobre o Projeto
O **House Security** é uma evolução do projeto de segurança residencial do primeiro semestre. A aplicação móvel permite que o morador envie a **planta da sua residência** (em formato de imagem ou PDF) para que uma Inteligência Artificial realize um diagnóstico preventivo automático, identificando pontos vulneráveis e recomendando soluções técnicas integradas ao catálogo de produtos da empresa.

## 2. ODS Escolhida
**ODS 16 – Paz, Justiça e Instituições Eficazes**

Nosso time escolheu essa ODS porque a segurança residencial é um problema real de qualidade de vida na cidade e de acesso desigual à proteção. Nem todo mundo tem condições de pagar por uma consultoria de segurança particular ou instalar um sistema caro — e é aí que a House Security entra: usando IA e dados públicos, o app democratiza o acesso à prevenção de riscos, ajudando a deixar as comunidades mais seguras de um jeito acessível.

## 3. O Problema Real
Muita gente não faz ideia de onde a própria casa tá vulnerável. Coisa como iluminação fraca, acesso exposto ou falha de cobertura passa batido no dia a dia, e o morador só descobre a fragilidade depois que já aconteceu algo. Existe consultoria de segurança que faz esse diagnóstico, mas custa caro e não é opção real pra maioria das famílias. Falta um jeito barato e acessível de qualquer um entender os riscos da própria casa e saber o que fazer pra melhorar.

## 4. A Solução com Inteligência Artificial
O diferencial do House Security é usar IA pra transformar uma foto simples em diagnóstico de segurança:

- *Análise de imagem por IA:* a IA analisa a foto da planta do imóvel pra achar pontos vulneráveis — tipo iluminação fraca, acesso exposto ou falha de cobertura.
- *Geração de recomendação:* com os dados em mãos  o sistema monta um relatório automático com mapa de risco da casa e um plano de ação prático e personalizado pra melhorar a segurança.

Ou seja, a IA não é só enfeite — ela é o motor que transforma foto em diagnóstico que dá pra agir, algo que normalmente só uma consultoria especializada faria.

## 5. Público-Alvo
Moradores de casas ou apartamentos que quere entender e melhorarar a segurança do próprio lar, mas não tem orçamento pra pagarem uma consultoria especializada — principalmente gente de bairro com pouco recurso de segurança pública ou privada, que é justamente quem mais ganha com uma ferramenta acessível de diagnóstico preventivo.

## 6. Modelagem de Dados (UML)
![Diagrama de Classes](https://github.com/user-attachments/assets/cc6e83f4-b49c-4aa5-b8ba-7800c98213c3)

## 7. Arquitetura do Sistema (Modelo C4)
A arquitetura do **House Security** foi desenhada utilizando a metodologia do **C4 Model**. Essa abordagem nos permite visualizar a plataforma sob diferentes perspectivas: desde o impacto direto no usuário até a estrutura técnica que roda no servidor.

### Nível 1: Diagrama de Contexto
A aplicação funciona como uma plataforma inteligente de prevenção de riscos. O objetivo do Nível 1 é demonstrar a visão macro do produto, focando em como o sistema se conecta ao usuário e a serviços parceiros, sem se prender a detalhes internos de código.

![Diagrama de Contexto - Nível 1](https://github.com/santanasamuelsousa/House-Securityapp/blob/main/imagem_2026-09-15_225515350.png)

- *Cliente `[Pessoa]`:* O morador que envia a planta da sua residência (em foto ou PDF) para identificar pontos fracos de proteção e receber diagnósticos práticos para o dia a dia.
- *Sistema House Security `[Sistema de Software]`:* O ecossistema central da aplicação. É responsável por receber a solicitação do cliente, gerenciar o fluxo de análise e entregar o relatório final junto às soluções do catálogo. 
- *Google Gemini API `[Sistema Externo]`:* A inteligência artificial integrada que interpreta o layout visual das plantas baixas e mapeia automaticamente os pontos vulneráveis do imóvel. 

### Nível 2: Diagrama de Contêineres 
Abrindo a estrutura para entender o que acontece por baixo dos panos, dividimos o sistema em unidades independentes (contêineres). Essa separação garante que o aplicativo seja ágil, seguro e simples de manter.

![Diagrama de Contêineres - Nível 2](https://github.com/santanasamuelsousa/House-Securityapp/blob/main/imagem_2026-09-15_225858937.png)

- *Aplicativo Mobile `[Flutter / Dart]`:* A interface direto na mão do usuário. Criada para oferecer uma experiência leve e fluida no celular, a aplicação cuida do envio das fotos, da navegação no catálogo e da exibição amigável do relatório de segurança. 
- *Back-End `[Java / Spring Boot]`:* O cérebro da arquitetura. Esta API REST assume o trabalho pesado do sistema: valida as informações do app, envia os arquivos para processamento na IA, cruza os riscos encontrados com os produtos adequados e orquestra os dados. 
- *Banco de Dados `[MySQL Server]`:* A camada de armazenamento confiável. Guarda com segurança as contas dos usuários, os históricos de diagnósticos gerados e o catálogo completo de equipamentos de segurança. 
- *Serviço de IA `[Google Gemini API]`:* O motor externo é acionado pelo Back-End para realizar o processamento de visão computacional na imagem da planta e retornar o diagnóstico de riscos.
