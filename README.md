# Gestor PRO+ - Sistema de Gestão para Estética Automotiva

![Gestor PRO+](https://img.shields.io/badge/version-2.0.0-blue.svg)
![PWA](https://img.shields.io/badge/PWA-enabled-green.svg)
![Offline First](https://img.shields.io/badge/offline-first-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

Sistema completo de gestão para empresas de estética automotiva, desenvolvido com **Clean Architecture**, **PWA offline-first** e **sincronização em tempo real**.

## 🚀 Funcionalidades

### ✅ Gestão Completa
- **Dashboard** com estatísticas em tempo real
- **Clientes** - Cadastro, edição e histórico completo
- **Serviços** - Catálogo com preços e categorias
- **Orçamentos** - Criação, aprovação e controle de status
- **Histórico** - Relatórios e análises detalhadas

### ✅ Tecnologia Avançada
- **PWA** - Funciona offline como app nativo
- **Sincronização automática** quando voltar online
- **Autenticação segura** com Supabase Auth
- **Multi-tenant** com isolamento de dados por usuário
- **Responsivo** - Funciona em desktop, tablet e mobile

### ✅ Integrações
- **WhatsApp** - Envio de orçamentos direto
- **PDF** - Geração de recibos e orçamentos
- **Backup automático** na nuvem
- **Exportação CSV** para análises

## 🛠️ Tecnologias Utilizadas

### Frontend
- **Vite** - Build tool moderna e rápida
- **Vanilla JavaScript** - ES6+ com módulos
- **CSS3** - Custom properties e Grid/Flexbox
- **PWA** - Service Workers e offline-first

### Backend
- **Supabase** - Database as a Service
- **PostgreSQL** - Banco de dados relacional
- **Row Level Security** - Segurança por usuário
- **Edge Functions** - Serverless functions

### Arquitetura
- **Clean Architecture** - Separação de responsabilidades
- **Domain-Driven Design** - Foco no domínio do negócio
- **SOLID Principles** - Código limpo e maintível
- **Offline-First** - Funciona sem internet

### Bibliotecas
- **Zustand** - Gerenciamento de estado
- **Dexie** - IndexedDB wrapper
- **Chart.js** - Gráficos e visualizações
- **jsPDF** - Geração de PDFs
- **date-fns** - Manipulação de datas

## 📦 Instalação

### Pré-requisitos
- Node.js 18+
- npm 9+
- Conta no Supabase

### 1. Clone o repositório
```bash
git clone https://github.com/seu-usuario/gestor-proplus.git
cd gestor-proplus
```

### 2. Instale as dependências
```bash
npm install
```

### 3. Configure as variáveis de ambiente
```bash
cp .env.example .env
```

Edite o arquivo `.env` com suas credenciais do Supabase:
```env
SUPABASE_URL=https://uymunsavnpfcsuznrugi.supabase.co
SUPABASE_PUBLISHABLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV5bXVuc2F2bnBmY3N1em5ydWdpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA3ODU3ODgsImV4cCI6MjA2NjM2MTc4OH0.Kz__-jB9SsD-w7SuwlYCWPuEOcOX9epRE9CB5jd4eFY
```

### 4. Configure o banco de dados
Execute o script SQL no **SQL Editor** do Supabase:
```sql
-- O arquivo está em: sql/schema.sql
```

### 5. Inicie o servidor de desenvolvimento
```bash
npm run dev
```

A aplicação estará disponível em `http://localhost:5173`

## 🚀 Deploy

### Build para produção
```bash
npm run build
```

### Visualizar build
```bash
npm run preview
```

### Deploy no Vercel
```bash
npm install -g vercel
vercel --prod
```

### Deploy no Netlify
```bash
npm run build
# Faça upload da pasta dist/
```

## 📱 PWA - Instalação no Dispositivo

### Desktop
1. Acesse a aplicação no navegador
2. Clique no ícone de "Instalar" na barra de endereços
3. Confirme a instalação

### Mobile
1. Acesse via navegador mobile
2. Toque no menu do navegador
3. Selecione "Adicionar à tela inicial"

## 🗂️ Estrutura do Projeto

```
gestor-proplus/
├── src/
│   ├── core/                 # Regras de negócio
│   │   ├── domain/           # Entidades e Value Objects
│   │   └── application/      # Casos de uso
│   ├── infra/               # Infraestrutura
│   │   ├── repositories/    # Acesso a dados
│   │   └── services/        # Serviços externos
│   └── ui/                  # Interface do usuário
│       ├── components/      # Componentes reutilizáveis
│       ├── pages/          # Páginas da aplicação
│       └── styles/         # Estilos CSS
├── public/                 # Arquivos estáticos
├── sql/                   # Scripts do banco de dados
└── service-worker.js      # Service Worker para PWA
```

## 🔧 Scripts Disponíveis

```bash
# Desenvolvimento
npm run dev              # Servidor de desenvolvimento
npm run build           # Build para produção
npm run preview         # Visualizar build

# Qualidade de código
npm run lint            # Verificar código
npm run format          # Formatar código

# Testes
npm run test            # Executar testes
npm run test:ui         # Interface de testes
```

## 🔐 Segurança

### Implementadas
- ✅ Row Level Security (RLS)
- ✅ Autenticação JWT
- ✅ Validação de entrada
- ✅ Sanitização de dados
- ✅ HTTPS obrigatório

### Recomendações
- 🔄 Rotação regular de chaves
- 🔄 Auditoria de logs
- 🔄 Backup automático
- 🔄 Monitoramento de performance

## 🎯 Roadmap

### Versão 2.1 (Q2 2025)
- [ ] Relatórios financeiros avançados
- [ ] Integração com gateways de pagamento
- [ ] Notificações push
- [ ] Modo escuro/claro

### Versão 2.2 (Q3 2025)
- [ ] App mobile nativo
- [ ] Integração com ERPs
- [ ] Automação de workflows
- [ ] BI self-service

### Versão 3.0 (Q4 2025)
- [ ] Marketplace de oficinas
- [ ] Inteligência artificial
- [ ] Multi-idioma
- [ ] Franquia/multi-empresa

## 🤝 Contribuindo

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🆘 Suporte

- 📧 Email: contato@rmestecautomotiva.com.br
- 📱 WhatsApp: (11) 99999-9999
- 🌐 Site: https://rmestecautomotiva.com.br

---

**Desenvolvido com ❤️ por R.M. Estética Automotiva**

*Sistema profissional para gestão de estética automotiva*