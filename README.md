# Upload de Currículos Phoenix LiveView

Aplicação Phoenix LiveView para upload de currículos com interface retro Windows 96/Linux e armazenamento seguro no Backblaze B2.

## Tecnologias

- **Framework**: Phoenix 1.8+ com LiveView
- **Storage**: Backblaze B2 (arquivos PDF/DOCX)
- **Deploy**: Fly.io

## Funcionalidades

- ✅ Formulário completo com validações
- ✅ Upload de currículos (PDF/DOCX até 10MB)
- ✅ Estética retro Windows 96/Linux
- ✅ Armazenamento seguro na nuvem (Backblaze B2)
- ✅ Salvamento local de dados (JSON)
- ✅ Interface responsiva para mobile/desktop

## Campos do Formulário

**Obrigatórios:**
- Nome, Email, Telefone, CEP
- Habilidades, Carta de Apresentação, Formação
- Anexo do Currículo (PDF/DOCX)

**Opcionais:**
- GitHub, LinkedIn

## Armazenamento de Dados

### Arquivos JSON (Dados do Formulário)
**Local:** `applications/[timestamp]_[email].json`
**Conteúdo:** Todos os dados do formulário + metadados
**Formato:** JSON estruturado e legível

### Arquivos na Nuvem (Currículos)
**Serviço:** Backblaze B2
**Local:** https://f002.backblazeb2.com/file/[bucket]/[arquivo]
**Acesso:** Público via URL

## Configuração e Setup

### 1. Pré-requisitos

- Elixir 1.17+
- Erlang 27+
- Node.js 18+
- Conta Fly.io
- Conta Backblaze B2

### 2. Configuração do Backblaze B2

1. Acesse [Backblaze B2](https://www.backblaze.com/b2/)
2. Crie um novo bucket (deixe público)
3. Vá em "App Keys" e crie uma nova chave
4. Anote:
   - `keyID` (BACKBLAZE_KEY_ID)
   - `applicationKey` (BACKBLAZE_APP_KEY)
   - Nome do bucket (BACKBLAZE_BUCKET)

### 3. Configuração do Fly.io

1. Instale o Fly CLI:
   ```bash
   curl -L https://fly.io/install.sh | sh
   ```

2. Faça login:
   ```bash
   fly auth login
   ```

### 4. Deploy

1. Clone e configure o projeto:
   ```bash
   git clone <your-repo>
   cd phoenix-live
   mix deps.get
   mix compile
   ```

2. Configure as secrets no Fly.io:
   ```bash
   fly secrets set SECRET_KEY_BASE="$(mix phx.gen.secret)"
   fly secrets set BACKBLAZE_KEY_ID="your-key-id"
   fly secrets set BACKBLAZE_APP_KEY="your-app-key"
   fly secrets set BACKBLAZE_BUCKET="your-bucket-name"
   ```

3. Deploy:
   ```bash
   fly launch
   fly deploy
   ```

## Desenvolvimento Local

1. Instale dependências:
   ```bash
   mix setup
   ```

2. Configure variáveis de ambiente:
   ```bash
   export BACKBLAZE_KEY_ID="your-key-id"
   export BACKBLAZE_APP_KEY="your-app-key"
   export BACKBLAZE_BUCKET="your-bucket"
   ```

3. Inicie o servidor:
   ```bash
   mix phx.server
   ```

4. Acesse [http://localhost:4000](http://localhost:4000)

## Estrutura do Projeto

```
lib/phoenix_live/
└── storage/              # Integração Backblaze B2

lib/phoenix_live_web/
├── live/                 # LiveViews
└── components/           # Componentes Phoenix

assets/css/
└── app.css              # Estilo Windows 96
```

## Informações da Vaga

**Cargo:** Desenvolvedor Fullstack
**Localização:** São Paulo - SP, Pinheiros
**Regime:** Segunda a Sexta (presencial)

### Sobre a Vaga
Buscamos um(a) Desenvolvedor(a) Fullstack experiente para integrar nossa equipe de desenvolvimento. A posição envolve trabalhar tanto no frontend quanto no backend, integrando ambas as partes e desenvolvendo aplicações web completas do início ao fim, desde a concepção até a implantação em produção.

A vaga é para atuação presencial em São Paulo, no bairro de Pinheiros, com horário comercial de segunda a sexta-feira. Valorizamos profissionais que tenham bom convívio social, espírito colaborativo e capacidade de trabalhar em equipe dinâmica.

### Requisitos Obrigatórios
- **Frontend:** Experiência sólida em HTML, CSS, JavaScript
- **Backend:** Conhecimentos em Node.js, Python, Java, ou tecnologias similares
- **APIs:** Experiência com integração de APIs RESTful e GraphQL
- **Linguagens Básicas:** Domínio de JavaScript, Python, SQL
- **Fullstack:** Capacidade de criar aplicações completas end-to-end
- **Soft Skills:** Bom convívio social e trabalho em equipe
- **Controle de Versão:** Conhecimentos em Git
- **Metodologias:** Experiência com metodologias ágeis

### Diferenciais
- **Certificações:** AWS, Google Cloud, Microsoft, ou similares
- **Containerização:** Docker avançado
- **Orquestração:** Kubernetes e containers
- **Sistema Operacional:** Domínio do Linux
- **Bancos de Dados:** NoSQL (MongoDB, Redis)
- **DevOps:** CI/CD e automação
- **UI/UX:** Senso estético para interfaces
- **Testes:** Experiência com testes automatizados

## Suporte

Para dúvidas ou problemas, consulte a documentação do Phoenix ou abra uma issue no repositório.

---

Feito com ❤️ usando Phoenix LiveView
# phoenix_lixir
# glowing-elixir
