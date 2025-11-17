# Projeto SCOM/LCON I (Equipe 2) - Guia Rápido

Este repositório armazena a API (`.php`) e o Banco de Dados (`.sql`) para coletar dados do ESP32.

## 1. O que é Necessário para o Servidor

Você precisa de um PC com XAMPP para atuar como servidor.

1.  **Clone este Repositório:** Coloque os arquivos deste projeto dentro da pasta `C:\xampp\htdocs\`.
2.  **Inicie o XAMPP:** Abra o Painel de Controle do XAMPP e inicie os serviços **Apache** e **MySQL**.
3.  **Importe o Banco de Dados:**
    * Abra `http://localhost/phpmyadmin` no navegador.
    * Clique em "Novo" (New), crie um banco de dados chamado `projetointegrador`.
    * Clique no banco `projetointegrador` (na esquerda), vá na aba "Importar".
    * Escolha o arquivo `projetointegrador.sql` (deste repositório) e clique em "Executar".

**Seu servidor está pronto.**

## 2. O que é Necessário para Coletar Dados (ESP32)

Para o ESP32 enviar dados, ele precisa "saber" o IP do seu servidor.

1.  **Descubra o IP do seu PC:**
    * Abra o **CMD** (Prompt de Comando).
    * Digite `ipconfig`.
    * Anote o **Endereço IPv4** da sua rede Wi-Fi (ex: `192.168.1.10`).

2.  **Configure o Código do ESP32 (.ino):**
    * Abra o código-fonte do ESP32.
    * Modifique estas 4 variáveis no topo do código:
    ```cpp
    const char* ssid = "NOME_DA_SUA_REDE_WIFI";
    const char* password = "SENHA_DA_SUA_REDE_WIFI";
    const char* serverIp = "192.168.1.10"; // <-- SEU IP AQUI
    const int MINHA_MALHA_ID = 1;          // 1 para Tanque 1, 2 para Tanque 2
    ```

3.  **Faça o Upload:** Envie o código para o ESP32.

## 3. Como Visualizar os Dados

1.  Com o ESP32 rodando, abra o **Serial Monitor** (115200 baud) para ver os logs de "POST".
2.  No seu PC, abra o **phpMyAdmin** no navegador: `http://localhost/phpmyadmin`
3.  A tabela contendo os dados da ESP32 se chama `historicodados`.
4.  Atualize a página (F5). **Você verá os dados aparecendo em tempo real.**

---

## 4. Fluxo Node-RED (funcionamento)

O fluxo `Projeto integrador` faz duas tarefas principais: **(A) gerar/receber valores e escrever em variáveis globais** e **(B) aplicar esses valores no banco de dados**.

### A) Geração/Recepção e globais
- **Inject (a cada 3 s)** → dispara a Function que monta um `msg.payload` com:
  ```json
  { "valor1": <0..100>, "valor2": <0..50>, "ativo": true|false }
  ```
- **Switch + Change/Function**:
  - `valor1` → grava em `global.tanque1`
  - `valor2` → grava em `global.tanque2`
  - `ativo`  → grava em `global.ModoOp` (pode ser 0/1, ou true/false conforme seu uso)

> Se em produção os dados vierem do ESP32, substitua a Function geradora por um **nó HTTP In** ou **MQTT In**, e **converta** o payload com o nó **JSON** antes do Switch.

### B) Atualização no Banco de Dados
- **Inject manual** → dispara a Function **“Atualiza malhasdecontrole”**, que:
  - Lê `global.tanque1`, `global.tanque2`, `global.ModoOp`.
  - Executa **um único UPDATE** com placeholders `?` na tabela `malhasdecontrole`:
    - `setpoint = ModoOp` **para “Tanque 1” e “Tanque 2”**.
    - `saida_manual_percent` de **“Tanque 1”** recebe `global.tanque1`.
    - `saida_manual_percent` de **“Tanque 2”** recebe `global.tanque2`.

SQL executado (forma resumida):
```sql
UPDATE malhasdecontrole
SET
  setpoint = ?,
  saida_manual_percent = CASE nome_malha
    WHEN 'Tanque 1' THEN ?
    WHEN 'Tanque 2' THEN ?
    ELSE saida_manual_percent
  END,
  ultima_modificacao = CURRENT_TIMESTAMP
WHERE nome_malha IN ('Tanque 1','Tanque 2');
-- parâmetros na ordem: [ModoOp, tanque1, tanque2]
```

- **MySQL node**: recebe `msg.topic` (SQL) e `msg.payload` (parâmetros) e executa no banco `projetointegrador`.
- **Debug**: exibe o resultado da operação (para INSERT/UPDATE não retorna linhas, apenas status).

> As variáveis globais podem ser definidas/ajustadas por **nós Change** ou via **contexto** do Node-RED (`global.set('tanque1', 42)`, etc.).

---

## 5. Credenciais do Banco de Dados (para o Node-RED)

Use estas credenciais no nó **MySQL** do Node-RED:

- **Host**: `localhost` (ou `127.0.0.1`)
- **Port**: `3306`
- **Database**: `projetointegrador`
- **User**: `PIntegrador`
- **Password**: `BancoDados`
- **Timezone**: `-03:00` (opcional)
- **Charset**: `UTF8MB4` (ou deixe em branco)

> Caso apareça “Access denied”, confirme que o usuário existe para `localhost` **e** `127.0.0.1` e que tem permissões no DB.

---

## 6. Teste rápido do fluxo

1. No Node-RED, clique no **Deploy**.
2. Clique no **Inject** de geração a cada 3 s (ou aguarde ele disparar sozinho).
3. Clique no **Inject** de atualização do BD (o que liga na Function de UPDATE).
4. Abra o phpMyAdmin e confira a tabela `malhasdecontrole`:
   - `setpoint` = valor de `global.ModoOp`
   - `saida_manual_percent` do “Tanque 1” = `global.tanque1`
   - `saida_manual_percent` do “Tanque 2” = `global.tanque2`

Pronto! O fluxo está integrando Node-RED ↔ MySQL conforme o esperado.


## 7. Fluxo "ProjetoIntegradorV2.json" 
Páginas web
1. /login: página com abas “Entrar” e “Criar conta”. No cadastro, o front envia POST /auth/register com username e password (com validações) e, se der certo, redireciona para /operador.
2. /operador (protegida): rota verifica cookie token; se não houver, responde 302 → /login.
A página exibe KP/KI/KD e KPIs (Tanque1, Tanque2, Vazão) e tem JS para: carregar sessão com /auth/me, fazer logout com POST /auth/logout, ler/salvar PID via /api/pid e fazer polling de 1s em /api/monitor/latest.
3. Autenticação & sessão
4. As rotas protegidas extraem o JWT do cookie token e validam com o jwt verify usando JWT_SECRET.
5. O front trata /auth/me (redireciona se 401) e logout (limpa sessão e volta ao /login).
6. APIs do operador
7. GET /api/monitor/latest: exige cookie (função requireAuth), verifica JWT e responde JSON com tanque1, tanque2, vazao e ts (503 se variáveis globais indisponíveis).
8. GET /api/pid: protegido; lê KP/KI/KD das globais e retorna JSON. POST /api/pid: protegido; valida numéricos, aplica limites, grava nas globais e retorna ok.
9. Simulação de processo (dados de entrada)
10. Um function 37 gera a cada 3s (inject) um objeto { valor1, valor2, ativo }. Um switch separa as chaves e nós change+function gravam nas globais tanque1, tanque2 e ModoOp.
11. A vazão é simulada em SIM: atualiza global.vazao como combinação linear de valor1/valor2, gravando em global.vazao.

Há debug úteis (ex.: “debug HTTP Request”) para ver payloads durante chamadas HTTP.


## 8. Sistema de Logs e Coleta de Dados

Para atender aos requisitos de registro de interações e recebimento de dados, o sistema agora inclui duas rotas principais de coleta e uma nova tabela de logs.

### A. Coleta de Dados do ESP32 (Tabela `historicodados`)

O Node-RED agora expõe um *endpoint* dedicado para o ESP32 enviar os dados dos sensores. Os dados recebidos são registrados na tabela `historicodados`.

* **Endpoint:** `POST /api/esp32/data`
* **Formato Esperado:** JSON

O ESP32 deve enviar um JSON contendo os seguintes campos. O único campo obrigatório é `malha_id` (1 ou 2). Os outros podem ser enviados ou omitidos (serão gravados como `NULL`).

**Exemplo de JSON que o ESP32 deve enviar:**
```json
{
  "malha_id": 1,
  "nivel_sensor_medido": 12.3,
  "saida_atuador_calculada": 45.0,
  "setpoint_no_momento": 15.0
}

```
## 9. Controle de Acesso e Administração

O sistema agora possui segurança baseada em cargos (RBAC) e registro de atividades.

### Níveis de Permissão
* **Visualizador (Padrão):** Apenas monitora os dados dos sensores. Não pode alterar configurações.
* **Editor (Operador):** Além de monitorar, tem permissão para alterar os parâmetros de controle (PID).
* **Admin:** Acesso total. Pode gerenciar outros usuários e auditar o sistema.

### Painel do Administrador (`/admin`)
Acessível via botão exclusivo no dashboard principal. Permite:
* **Gerenciar Usuários:** Alterar o nível de acesso (promover/rebaixar) ou excluir contas.
* **Logs de Auditoria:** Visualizar o histórico de ações críticas (ex: quem alterou um PID ou quem excluiu um usuário).

IMPORTANTE: Foi criado para implementação dessas funções um fluxo secundário, separado do fluxo principal (chamado Funções Admin ou só Admin), lá estão os blocos que criam esses níveis de acesso.
