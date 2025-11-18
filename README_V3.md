# Projeto SCOM/LCON I (Equipe 2) - README V3 (Atualizado)

Este repositório armazena os fluxos Node-RED (`.json`) e o Banco de Dados (`.sql`) para o Projeto Integrador SCOM/LCON.

## 1. O que é Necessário para o Servidor (XAMPP)

Você precisa de um PC com XAMPP para atuar como servidor.

1.  **Clone este Repositório:** Coloque os arquivos deste projeto em uma pasta de sua preferência.
2.  **Inicie o XAMPP:** Abra o Painel de Controle do XAMPP e inicie os serviços **Apache** e **MySQL**.
3.  **Importe o Banco de Dados (MUITO IMPORTANTE):**
    * Abra `http://localhost/phpmyadmin` no navegador.
    * Clique em "Novo" (New), crie um banco de dados chamado `projetointegrador`.
    * Clique no banco `projetointegrador` (na esquerda), vá na aba "Importar".
    * Escolha o arquivo `projetointegrador.sql` **deste repositório**. A versão mais recente é essencial, pois contém as tabelas `commands`, `logs` e as colunas `_crip` em `historicodados`.
    * Clique em "Executar".

**Seu servidor de banco de dados está pronto.**

## 2. O que é Necessário para o Back-end (Node-RED)

O back-end (API, dashboard, lógica) é inteiramente controlado pelo Node-RED.

1.  **Navegue até o Diretório do Node-RED:**
    * Abra um terminal (PowerShell).
    * Navegue até o diretório de usuário do Node-RED (onde ficam as instalações):
        ```powershell
        cd C:\Users\seu_usuario\.node-red
        ```
2.  **Instale as Dependências (se for a primeira vez):**
    * O fluxo do projeto precisa de pacotes adicionais para funcionar. Instale-os:
        ```powershell
        npm install node-red-contrib-mysql
        npm install node-red-dashboard
        npm install bcrypt
        npm install jsonwebtoken
        ```
3.  **Inicie o Node-RED:**
    * No mesmo terminal, inicie o servidor:
        ```powershell
        node-red
        ```
4.  **Importe o Fluxo:**
    * Abra o Node-RED no seu navegador (geralmente `http://localhost:1880`).
    * Clique no menu "hambúrguer" (☰) no canto superior direito $\rightarrow$ **Importar**.
    * Clique em "Selecionar um arquivo para importar" e escolha o arquivo `.json` mais recente deste repositório (ex: `ProjetoIntegradorV2.json`).
    * Clique em **Importar**.
5.  **Configure as Credenciais do Banco (Seção 5):**
    * No Node-RED, encontre qualquer nó MySQL (laranja, ex: `[Gravar em 'commands']`).
    * Clique duas vezes nele e depois no ícone de lápis ✏️ para editar a conexão.
    * Verifique se as credenciais estão corretas (conforme Seção 5 abaixo).
6.  **DEPLOY:** Clique no botão vermelho **"Deploy"** no canto superior direito para iniciar todos os fluxos.

**Seu sistema está no ar.**

## 3. Credenciais do Banco de Dados (para o Node-RED)

Use estas credenciais nos nós **MySQL** do Node-RED:

* **Host**: `localhost` (ou `127.0.0.1`)
* **Port**: `3306`
* **Database**: `projetointegrador`
* **User**: `PIntegrador`
* **Password**: `BancoDados`
* **Timezone**: `-03:00` (opcional)
* **Charset**: `UTF8MB4` (ou deixe em branco)

> Caso apareça “Access denied”, confirme que o usuário existe para `localhost` **e** `127.0.0.1` e que tem permissões no DB.

---

## 4. Como Testar o Sistema V2 Completo (End-to-End)

Siga estes passos para validar a comunicação bidirecional simulada.

### 4.1. Teste (ESP32 Simulado $\rightarrow$ Servidor)

Este teste valida o recebimento e armazenamento seguro dos dados dos sensores.

1.  **Ação:** Nenhuma. O fluxo "Simulação entrada de dados" (que você pode ver no Node-RED) é iniciado automaticamente a cada 3 segundos após o "Deploy".
2.  **O que está acontecendo:**
    * Este fluxo gera dados simulados (nível e vazão).
    * Ele **salva nas globais** (para o dashboard ler).
    * Ele **atua como um ESP32**, formatando um JSON e fazendo um `POST` para o endpoint `POST /api/esp32/data`.
    * O endpoint `/api/esp32/data` recebe os dados, executa a codificação Base64 e os salva no banco.
3.  **Verificação (phpMyAdmin):**
    * Abra `http://localhost/phpmyadmin`.
    * Abra a tabela `historicodados`.
    * Você verá novas linhas sendo adicionadas a cada 3 segundos, com **ambas** as colunas preenchidas:
        * `nivel_sensor_medido` (com o valor numérico, ex: `54.13`)
        * `nivel_sensor_medido_crip` (com o valor em Base64, ex: `NTQuMTM=`)

### 4.2. Teste (Site $\rightarrow$ Servidor)

Este teste valida o envio de comandos do operador para o banco de dados.

1.  **Ação (Login):**
    * Abra o site: `http://localhost:1880/auth/login`
    * Crie uma conta ou entre com um usuário existente.
    * Você será redirecionado para o dashboard `/operador`.
2.  **Ação (Envio de Comando):**
    * No dashboard, encontre o formulário "Parâmetros PID".
    * Digite novos valores (ex: Kp=5, Ki=10, Kd=2) e clique em "Salvar".
3.  **Verificação 1 (Logs):**
    * Vá ao **phpMyAdmin** e abra a tabela `logs`.
    * Você verá um novo registro com `evento: 'pid_update'` e `detalhes: 'PID atualizado por [seu_usuario]: Kp=5, Ki=10, Kd=2'`.
4.  **Verificação 2 (Commands):**
    * Vá ao **phpMyAdmin** e abra a tabela `commands`.
    * Você verá uma nova linha que representa o seu comando, com:
        * `status: 'pendente'`
        * `value: '{"Kp":5,"Ki":10,"Kd":2}'`

**Se ambas as verificações funcionarem, o fluxo bidirecional de back-end está 100% funcional.**

---

## 5. Referência: Detalhes do Fluxo "ProjetoIntegradorV2.json"

Esta seção detalha o funcionamento interno dos fluxos.

### 5.1. Páginas web e Autenticação (Antiga Seção 7)
1.  **/login:** página com abas “Entrar” e “Criar conta”. No cadastro, o front envia POST /auth/register com username e password (com validações) e, se der certo, redireciona para /operador.
2.  **/operador (protegida):** rota verifica cookie token; se não houver, responde 302 $\rightarrow$ /login.
3.  **Dashboard:** A página exibe KP/KI/KD e KPIs (Tanque1, Tanque2, Vazão) e tem JS para: carregar sessão com /auth/me, fazer logout com POST /auth/logout, ler/salvar PID via /api/pid e fazer polling de 1s em /api/monitor/latest.
4.  **Autenticação & sessão:** As rotas protegidas extraem o JWT do cookie token e validam com o jwt verify usando JWT_SECRET.
5.  **APIs do operador:**
    * `GET /api/monitor/latest`: exige cookie (função requireAuth), verifica JWT e responde JSON com tanque1, tanque2, vazao e ts (503 se variáveis globais indisponíveis).
    * `GET /api/pid`: protegido; lê KP/KI/KD das globais e retorna JSON.
    * `POST /api/pid`: (Ver Seção 5.3 abaixo).
6.  **Simulação de processo (dados de entrada):**
    * Um function 37 gera a cada 3s (inject) um objeto { valor1, valor2, ativo }. Um switch separa as chaves e nós change+function gravam nas globais tanque1, tanque2 e ModoOp.
    * A vazão é simulada em SIM: atualiza global.vazao como combinação linear de valor1/valor2, gravando em global.vazao.

### 5.2. Sistema de Logs e Coleta de Dados (Antiga Seção 8 - ATUALIZADA)

O sistema inclui rotas de coleta e tabelas de log.

**A. Coleta de Dados do ESP32 (Tabela `historicodados`)**
* **Endpoint:** `POST /api/esp32/data`
* **Lógica:** Recebe um JSON do ESP32 (ou do simulador). O nó `[Validar e Montar SQL ESP32]` executa:
    1.  Validação dos dados numéricos.
    2.  Codificação Base64 (usando `Buffer.from().toString('base64')`) dos valores.
    3.  Um `INSERT` na tabela `historicodados` que salva *ambos* os valores: o numérico (ex: `nivel_sensor_medido`) e o codificado (ex: `nivel_sensor_medido_crip`).
* **Formato Esperado (JSON):**
    ```json
    {
      "malha_id": 1,
      "nivel_sensor_medido": 12.3,
      "saida_atuador_calculada": 45.0,
      "setpoint_no_momento": 15.0
    }
    ```

**B. Registro de Logs de Atividade (Tabela `logs`)**
* Um subfluxo centralizado ("Gravar Log") é usado para registrar eventos discretos (login, erros, comandos) na tabela `logs`.
* O fluxo `POST /api/pid` chama este log, salvando os `detalhes` do PID que foi alterado.

**C. Registro de Comandos (Tabela `commands`)**
* **Endpoint:** `POST /api/pid`
* **Lógica:** Além de salvar nas globais e nos logs, este fluxo agora insere uma nova linha na tabela `commands` com `status: 'pendente'`. Isso armazena o comando para que o ESP32 possa lê-lo.

### 5.3. Controle de Acesso e Administração (Antiga Seção 9)
* **Níveis de Permissão:** Visualizador (padrão), Editor (Operador) e Admin.
* **Editor (Operador):** Pode alterar os parâmetros de controle (PID).
* **Admin:** Acesso total, incluindo gerenciamento de usuários e visualização de logs de auditoria.

---

## 6. Para um ESP32 Real (Próximos Passos)

Quando for usar um ESP32 real, a configuração é esta:

1.  **Descubra o IP do seu PC:**
    * Abra o **CMD** e digite `ipconfig`.
    * Anote o **Endereço IPv4** (ex: `192.168.1.10`).
2.  **Configure o Código do ESP32 (.ino):**
    * Modifique estas variáveis no código do ESP32:
        ```cpp
        const char* ssid = "NOME_DA_SUA_REDE_WIFI";
        const char* password = "SENHA_DA_SUA_REDE_WIFI";
        // O IP deve ser o do PC que está rodando o Node-RED
        const char* serverIp = "192.168.1.10"; 
        ```
3.  **Lógica do ESP32:**
    * **Envio de Dados:** O ESP32 deve fazer `POST` para `http://[serverIp]:1880/api/esp32/data` com o JSON (ex: `{ "malha_id": 1, "nivel_sensor_medido": 12.3 }`).
    * **Recebimento de Comandos:** O ESP32 deve fazer `GET` periodicamente para `http://[serverIp]:1880/api/commands` para verificar se há novos PIDs para aplicar. (Este endpoint `GET` é a única parte que falta implementar no Node-RED).
