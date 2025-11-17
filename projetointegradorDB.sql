-- ===========================
-- Banco de dados: projetointegrador
-- ===========================
CREATE DATABASE IF NOT EXISTS `projetointegrador`
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;

USE `projetointegrador`;

-- Evita erros de ordem ao recriar
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `historicodados`;
DROP TABLE IF EXISTS `malhasdecontrole`;
DROP TABLE IF EXISTS `usuarios`;
SET FOREIGN_KEY_CHECKS = 1;

-- ===========================
-- Tabela: usuarios
-- ===========================
CREATE TABLE `usuarios` (
  `usuario_id` INT NOT NULL AUTO_INCREMENT,
  `nome_usuario` VARCHAR(50) NOT NULL,
  `hash_senha` VARCHAR(255) NOT NULL,
  `permissao` ENUM('admin','operador') NOT NULL DEFAULT 'operador',
  `criado_em` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`usuario_id`),
  UNIQUE KEY `uk_usuarios_nome` (`nome_usuario`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_general_ci;

-- ===========================
-- Tabela: malhasdecontrole
-- ===========================
CREATE TABLE `malhasdecontrole` (
  `malha_id` INT NOT NULL AUTO_INCREMENT,
  `nome_malha` VARCHAR(50) NOT NULL,
  `setpoint` FLOAT DEFAULT 0,
  `modo_operacao` ENUM('automatico','manual') NOT NULL DEFAULT 'manual',
  `saida_manual_percent` FLOAT DEFAULT 0,
  `param_kp` FLOAT DEFAULT 0,
  `param_ki` FLOAT DEFAULT 0,
  `param_kd` FLOAT DEFAULT 0,
  `ultima_modificacao` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `modificado_por_usuario_id` INT DEFAULT NULL,
  PRIMARY KEY (`malha_id`),
  UNIQUE KEY `uk_malhasdecontrole_nome` (`nome_malha`),
  KEY `idx_malhas_modificado_por` (`modificado_por_usuario_id`),
  CONSTRAINT `fk_malhas_usuario`
    FOREIGN KEY (`modificado_por_usuario_id`)
    REFERENCES `usuarios` (`usuario_id`)
    ON DELETE SET NULL
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_general_ci;

-- ===========================
-- Tabela: historicodados
-- ===========================
CREATE TABLE `historicodados` (
  `log_id` BIGINT NOT NULL AUTO_INCREMENT,
  `malha_id` INT NOT NULL,
  `timestamp` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `nivel_sensor_medido` FLOAT DEFAULT NULL,
  `saida_atuador_calculada` FLOAT DEFAULT NULL,
  `setpoint_no_momento` FLOAT DEFAULT NULL,
  PRIMARY KEY (`log_id`),
  KEY `idx_historico_malha_ts` (`malha_id`, `timestamp`),
  CONSTRAINT `fk_historico_malha`
    FOREIGN KEY (`malha_id`)
    REFERENCES `malhasdecontrole` (`malha_id`)
    ON DELETE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_general_ci;

-- ===========================
-- Dados iniciais (exemplo)
-- ===========================
INSERT INTO `malhasdecontrole`
  (`malha_id`, `nome_malha`, `setpoint`, `modo_operacao`, `saida_manual_percent`,
   `param_kp`, `param_ki`, `param_kd`, `ultima_modificacao`, `modificado_por_usuario_id`)
VALUES
  (1, 'Tanque 1', 0, 'manual', 0, 0, 0, 0, NOW(), NULL),
  (2, 'Tanque 2', 0, 'manual', 0, 0, 0, 0, NOW(), NULL);

ALTER TABLE `malhasdecontrole` AUTO_INCREMENT = 3;

-- ===========================
-- Usuário para o Node-RED
-- ===========================
-- Cria para localhost e 127.0.0.1 (ambos, para evitar "access denied" por host)
CREATE USER IF NOT EXISTS 'PIntegrador'@'localhost' IDENTIFIED BY 'BancoDados';
CREATE USER IF NOT EXISTS 'PIntegrador'@'127.0.0.1' IDENTIFIED BY 'BancoDados';

-- Garante a senha se o usuário já existia
ALTER USER 'PIntegrador'@'localhost' IDENTIFIED BY 'BancoDados';
ALTER USER 'PIntegrador'@'127.0.0.1' IDENTIFIED BY 'BancoDados';

-- (Opcional – MySQL 8 com clientes que não suportam caching_sha2_password)
-- ALTER USER 'PIntegrador'@'localhost' IDENTIFIED WITH mysql_native_password BY 'BancoDados';
-- ALTER USER 'PIntegrador'@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY 'BancoDados';

-- Permissões necessárias ao app
GRANT SELECT, INSERT, UPDATE, DELETE ON `projetointegrador`.* TO 'PIntegrador'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON `projetointegrador`.* TO 'PIntegrador'@'127.0.0.1';
FLUSH PRIVILEGES;

-- ===========================
-- Tabela: logs_atividades
-- ===========================
CREATE TABLE `logs_atividades` (
  `log_id` BIGINT NOT NULL AUTO_INCREMENT,
  `timestamp` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `categoria` ENUM('auth', 'comando', 'erro', 'sistema') NOT NULL,
  `evento` VARCHAR(50) NOT NULL,
  `detalhes` VARCHAR(512) DEFAULT NULL,
  `usuario_id` INT DEFAULT NULL,
  `ip_origem` VARCHAR(45) DEFAULT NULL,
  PRIMARY KEY (`log_id`),
  KEY `idx_logs_categoria` (`categoria`),
  KEY `idx_logs_usuario` (`usuario_id`),
  CONSTRAINT `fk_logs_usuario`
    FOREIGN KEY (`usuario_id`)
    REFERENCES `usuarios` (`usuario_id`)
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;