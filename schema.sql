-- Gestor PRO+ - Schema do Banco de Dados
-- Versão: 2.0.0
-- Compatível com PostgreSQL 14+

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Função para obter o tenant_id do usuário atual
CREATE OR REPLACE FUNCTION auth.get_tenant_id()
RETURNS UUID AS $$
BEGIN
  RETURN COALESCE(
    (SELECT auth.uid()),
    '00000000-0000-0000-0000-000000000000'::UUID
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Limpar tabelas existentes
DROP TABLE IF EXISTS orcamento_itens CASCADE;
DROP TABLE IF EXISTS orcamentos CASCADE;
DROP TABLE IF EXISTS servicos CASCADE;
DROP TABLE IF EXISTS clientes CASCADE;
DROP TABLE IF EXISTS audit_log CASCADE;

-- Tabela de auditoria
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name VARCHAR(50) NOT NULL,
    operation VARCHAR(10) NOT NULL,
    old_data JSONB,
    new_data JSONB,
    user_id UUID REFERENCES auth.users(id),
    tenant_id UUID DEFAULT auth.get_tenant_id(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de clientes
CREATE TABLE clientes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR(255) NOT NULL,
    telefone VARCHAR(20),
    email VARCHAR(255),
    carro VARCHAR(100),
    placa VARCHAR(10),
    endereco TEXT,
    observacoes TEXT,
    tenant_id UUID DEFAULT auth.get_tenant_id(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de serviços
CREATE TABLE servicos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    descricao TEXT NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    categoria VARCHAR(50) DEFAULT 'Outros',
    tempo_estimado INTEGER DEFAULT 60, -- em minutos
    ativo BOOLEAN DEFAULT TRUE,
    tenant_id UUID DEFAULT auth.get_tenant_id(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de orçamentos
CREATE TABLE orcamentos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero_orcamento VARCHAR(20) UNIQUE NOT NULL,
    cliente_id UUID REFERENCES clientes(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'orcamento' CHECK (status IN ('orcamento', 'aprovado', 'em_andamento', 'finalizado', 'cancelado')),
    valor_total DECIMAL(10,2) DEFAULT 0,
    desconto DECIMAL(10,2) DEFAULT 0,
    valor_final DECIMAL(10,2) GENERATED ALWAYS AS (valor_total - desconto) STORED,
    formas_pagamento JSONB DEFAULT '[]',
    observacoes TEXT,
    validade_orcamento DATE DEFAULT (CURRENT_DATE + INTERVAL '30 days'),
    data_aprovacao TIMESTAMP WITH TIME ZONE,
    data_finalizacao TIMESTAMP WITH TIME ZONE,
    tenant_id UUID DEFAULT auth.get_tenant_id(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de itens do orçamento
CREATE TABLE orcamento_itens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    orcamento_id UUID REFERENCES orcamentos(id) ON DELETE CASCADE,
    servico_id UUID REFERENCES servicos(id) ON DELETE CASCADE,
    descricao TEXT NOT NULL,
    quantidade INTEGER DEFAULT 1,
    valor_unitario DECIMAL(10,2) NOT NULL,
    valor_cobrado DECIMAL(10,2) NOT NULL,
    valor_total DECIMAL(10,2) GENERATED ALWAYS AS (valor_cobrado * quantidade) STORED,
    observacoes TEXT,
    tenant_id UUID DEFAULT auth.get_tenant_id(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Função para gerar número do orçamento
CREATE OR REPLACE FUNCTION generate_orcamento_number()
RETURNS TEXT AS $$
DECLARE
    current_year INTEGER := EXTRACT(year FROM CURRENT_DATE);
    next_number INTEGER;
    formatted_number TEXT;
BEGIN
    -- Buscar o próximo número para o ano atual
    SELECT COALESCE(MAX(
        CAST(SUBSTRING(numero_orcamento FROM '\d{4}-(\d+)') AS INTEGER)
    ), 0) + 1
    INTO next_number
    FROM orcamentos
    WHERE numero_orcamento LIKE current_year || '-%'
    AND tenant_id = auth.get_tenant_id();
    
    -- Formatar como YYYY-000001
    formatted_number := current_year || '-' || LPAD(next_number::TEXT, 6, '0');
    
    RETURN formatted_number;
END;
$$ LANGUAGE plpgsql;

-- Trigger para gerar número do orçamento automaticamente
CREATE OR REPLACE FUNCTION set_orcamento_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.numero_orcamento IS NULL THEN
        NEW.numero_orcamento := generate_orcamento_number();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_orcamento_number
    BEFORE INSERT ON orcamentos
    FOR EACH ROW
    EXECUTE FUNCTION set_orcamento_number();

-- Trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_clientes_updated_at
    BEFORE UPDATE ON clientes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_servicos_updated_at
    BEFORE UPDATE ON servicos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_orcamentos_updated_at
    BEFORE UPDATE ON orcamentos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_orcamento_itens_updated_at
    BEFORE UPDATE ON orcamento_itens
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Função para auditoria
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (table_name, operation, old_data, user_id, tenant_id)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(OLD), auth.uid(), OLD.tenant_id);
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, operation, old_data, new_data, user_id, tenant_id)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(OLD), to_jsonb(NEW), auth.uid(), NEW.tenant_id);
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, operation, new_data, user_id, tenant_id)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(NEW), auth.uid(), NEW.tenant_id);
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Aplicar auditoria a todas as tabelas
CREATE TRIGGER audit_clientes
    AFTER INSERT OR UPDATE OR DELETE ON clientes
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_servicos
    AFTER INSERT OR UPDATE OR DELETE ON servicos
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_orcamentos
    AFTER INSERT OR UPDATE OR DELETE ON orcamentos
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_orcamento_itens
    AFTER INSERT OR UPDATE OR DELETE ON orcamento_itens
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- Índices para performance
CREATE INDEX idx_clientes_tenant_id ON clientes(tenant_id);
CREATE INDEX idx_clientes_nome ON clientes(nome);
CREATE INDEX idx_clientes_telefone ON clientes(telefone);
CREATE INDEX idx_clientes_placa ON clientes(placa);
CREATE INDEX idx_clientes_created_at ON clientes(created_at);

CREATE INDEX idx_servicos_tenant_id ON servicos(tenant_id);
CREATE INDEX idx_servicos_categoria ON servicos(categoria);
CREATE INDEX idx_servicos_ativo ON servicos(ativo);

CREATE INDEX idx_orcamentos_tenant_id ON orcamentos(tenant_id);
CREATE INDEX idx_orcamentos_cliente_id ON orcamentos(cliente_id);
CREATE INDEX idx_orcamentos_status ON orcamentos(status);
CREATE INDEX idx_orcamentos_numero ON orcamentos(numero_orcamento);
CREATE INDEX idx_orcamentos_created_at ON orcamentos(created_at);

CREATE INDEX idx_orcamento_itens_tenant_id ON orcamento_itens(tenant_id);
CREATE INDEX idx_orcamento_itens_orcamento_id ON orcamento_itens(orcamento_id);
CREATE INDEX idx_orcamento_itens_servico_id ON orcamento_itens(servico_id);

CREATE INDEX idx_audit_log_tenant_id ON audit_log(tenant_id);
CREATE INDEX idx_audit_log_table_name ON audit_log(table_name);
CREATE INDEX idx_audit_log_created_at ON audit_log(created_at);

-- Habilitar Row Level Security
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE servicos ENABLE ROW LEVEL SECURITY;
ALTER TABLE orcamentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE orcamento_itens ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- Políticas RLS para clientes
CREATE POLICY "clientes_policy" ON clientes
    FOR ALL USING (tenant_id = auth.uid());

-- Políticas RLS para serviços
CREATE POLICY "servicos_policy" ON servicos
    FOR ALL USING (tenant_id = auth.uid());

-- Políticas RLS para orçamentos
CREATE POLICY "orcamentos_policy" ON orcamentos
    FOR ALL USING (tenant_id = auth.uid());

-- Políticas RLS para itens do orçamento
CREATE POLICY "orcamento_itens_policy" ON orcamento_itens
    FOR ALL USING (tenant_id = auth.uid());

-- Políticas RLS para auditoria
CREATE POLICY "audit_log_policy" ON audit_log
    FOR ALL USING (tenant_id = auth.uid());

-- Inserir dados de exemplo de serviços
INSERT INTO servicos (descricao, valor, categoria, tempo_estimado) VALUES 
('Lavagem Simples', 15.00, 'Lavagem', 30),
('Lavagem Completa', 25.00, 'Lavagem', 60),
('Enceramento Simples', 40.00, 'Enceramento', 45),
('Enceramento Premium', 60.00, 'Enceramento', 90),
('Lavagem + Cera', 70.00, 'Combo', 120),
('Polimento Simples', 80.00, 'Polimento', 120),
('Polimento Técnico', 150.00, 'Polimento', 180),
('Lavagem de Motor', 30.00, 'Lavagem', 45),
('Limpeza de Bancos', 35.00, 'Detalhamento', 60),
('Detalhamento Completo', 200.00, 'Detalhamento', 240),
('Lavagem de Rodas', 20.00, 'Lavagem', 30),
('Aspiração Completa', 25.00, 'Lavagem', 45),
('Hidratação de Couro', 45.00, 'Detalhamento', 60),
('Limpeza do Ar-Condicionado', 50.00, 'Outros', 30),
('Lavagem de Chassi', 40.00, 'Lavagem', 60);

-- Criar função para estatísticas do dashboard
CREATE OR REPLACE FUNCTION get_dashboard_stats(user_id UUID)
RETURNS JSON AS $$
DECLARE
    total_orcamentos INTEGER;
    orcamentos_pendentes INTEGER;
    orcamentos_aprovados INTEGER;
    orcamentos_finalizados INTEGER;
    faturamento_mes DECIMAL(10,2);
    resultado JSON;
BEGIN
    -- Total de orçamentos
    SELECT COUNT(*) INTO total_orcamentos
    FROM orcamentos WHERE tenant_id = user_id;
    
    -- Orçamentos pendentes
    SELECT COUNT(*) INTO orcamentos_pendentes
    FROM orcamentos WHERE tenant_id = user_id AND status = 'orcamento';
    
    -- Orçamentos aprovados
    SELECT COUNT(*) INTO orcamentos_aprovados
    FROM orcamentos WHERE tenant_id = user_id AND status = 'aprovado';
    
    -- Orçamentos finalizados
    SELECT COUNT(*) INTO orcamentos_finalizados
    FROM orcamentos WHERE tenant_id = user_id AND status = 'finalizado';
    
    -- Faturamento do mês
    SELECT COALESCE(SUM(valor_final), 0) INTO faturamento_mes
    FROM orcamentos 
    WHERE tenant_id = user_id 
    AND status = 'finalizado'
    AND EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM CURRENT_DATE)
    AND EXTRACT(MONTH FROM created_at) = EXTRACT(MONTH FROM CURRENT_DATE);
    
    -- Montar resultado
    resultado := json_build_object(
        'total_orcamentos', total_orcamentos,
        'orcamentos_pendentes', orcamentos_pendentes,
        'orcamentos_aprovados', orcamentos_aprovados,
        'orcamentos_finalizados', orcamentos_finalizados,
        'faturamento_mes', faturamento_mes
    );
    
    RETURN resultado;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comentários das tabelas
COMMENT ON TABLE clientes IS 'Tabela de clientes da estética automotiva';
COMMENT ON TABLE servicos IS 'Catálogo de serviços oferecidos';
COMMENT ON TABLE orcamentos IS 'Orçamentos criados para clientes';
COMMENT ON TABLE orcamento_itens IS 'Itens individuais de cada orçamento';
COMMENT ON TABLE audit_log IS 'Log de auditoria para todas as operações';

-- Comentários das colunas principais
COMMENT ON COLUMN clientes.nome IS 'Nome completo do cliente';
COMMENT ON COLUMN clientes.telefone IS 'Telefone no formato (11) 99999-9999';
COMMENT ON COLUMN clientes.placa IS 'Placa do veículo no formato ABC-1234';
COMMENT ON COLUMN servicos.tempo_estimado IS 'Tempo estimado em minutos';
COMMENT ON COLUMN orcamentos.numero_orcamento IS 'Número único do orçamento no formato YYYY-NNNNNN';
COMMENT ON COLUMN orcamentos.valor_final IS 'Valor final calculado automaticamente (valor_total - desconto)';

-- Criar views úteis
CREATE OR REPLACE VIEW vw_orcamentos_completos AS
SELECT 
    o.id,
    o.numero_orcamento,
    o.status,
    o.valor_total,
    o.desconto,
    o.valor_final,
    o.created_at,
    c.nome as cliente_nome,
    c.telefone as cliente_telefone,
    c.carro as cliente_carro,
    c.placa as cliente_placa,
    COUNT(oi.id) as total_itens
FROM orcamentos o
JOIN clientes c ON o.cliente_id = c.id
LEFT JOIN orcamento_itens oi ON o.id = oi.orcamento_id
GROUP BY o.id, c.nome, c.telefone, c.carro, c.placa
ORDER BY o.created_at DESC;

CREATE OR REPLACE VIEW vw_clientes_resumo AS
SELECT 
    c.id,
    c.nome,
    c.telefone,
    c.carro,
    c.placa,
    c.created_at,
    COUNT(o.id) as total_orcamentos,
    COALESCE(SUM(CASE WHEN o.status = 'finalizado' THEN o.valor_final ELSE 0 END), 0) as total_gasto
FROM clientes c
LEFT JOIN orcamentos o ON c.id = o.cliente_id
GROUP BY c.id, c.nome, c.telefone, c.carro, c.placa, c.created_at
ORDER BY c.created_at DESC;