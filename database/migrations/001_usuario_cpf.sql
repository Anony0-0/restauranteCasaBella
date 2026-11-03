/*
  Migração para uma BDcasaBella já existente.
  1) Esta migração cria a coluna de CPF opcional para permitir o backfill.
  2) Preencha o CPF dos usuários existentes (somente 11 dígitos).
  3) Depois de preencher todos os registros, altere cpf para NOT NULL.
  Instalações novas devem usar ../schema.sql, que já define CPF como obrigatório.
*/
IF COL_LENGTH(N'dbo.usuarios', N'cpf') IS NULL
BEGIN
    ALTER TABLE dbo.usuarios ADD cpf CHAR(11) NULL;
END;
GO

IF EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.usuarios')
      AND name = N'email'
      AND is_nullable = 0
)
BEGIN
    ALTER TABLE dbo.usuarios ALTER COLUMN email NVARCHAR(254) NULL;
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.usuarios')
      AND name = N'UX_usuarios_cpf'
)
BEGIN
    CREATE UNIQUE INDEX UX_usuarios_cpf
        ON dbo.usuarios(cpf)
        WHERE cpf IS NOT NULL;
END;
GO
