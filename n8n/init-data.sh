#!/bin/bash
set -e

# Script to initialize PostgreSQL for n8n
# This script creates a non-root user and grants permissions

# Log the initialization start
echo "Initializing PostgreSQL for n8n..."

# Create the non-root user if it doesn't exist
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    DO
    \$\$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$POSTGRES_NON_ROOT_USER') THEN
            CREATE USER $POSTGRES_NON_ROOT_USER WITH PASSWORD '$POSTGRES_NON_ROOT_PASSWORD';
            RAISE NOTICE 'User $POSTGRES_NON_ROOT_USER created';
        ELSE
            RAISE NOTICE 'User $POSTGRES_NON_ROOT_USER already exists';
        END IF;
    END
    \$\$;
    
    -- Grant privileges to the non-root user
    GRANT CONNECT ON DATABASE $POSTGRES_DB TO $POSTGRES_NON_ROOT_USER;
    GRANT USAGE ON SCHEMA public TO $POSTGRES_NON_ROOT_USER;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $POSTGRES_NON_ROOT_USER;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $POSTGRES_NON_ROOT_USER;
    GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO $POSTGRES_NON_ROOT_USER;

    -- Set default privileges for future tables, sequences, and functions
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $POSTGRES_NON_ROOT_USER;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $POSTGRES_NON_ROOT_USER;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO $POSTGRES_NON_ROOT_USER;
    
    -- Optional: Make the non-root user the owner of the database
    -- Uncomment if you want the non-root user to have full ownership
    -- ALTER DATABASE $POSTGRES_DB OWNER TO $POSTGRES_NON_ROOT_USER;
    
    -- Log successful completion
    \echo 'PostgreSQL initialization completed successfully';
EOSQL

# Create any necessary extensions
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create any extensions that n8n might need
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
EOSQL

echo "PostgreSQL initialization completed successfully."
echo "User '$POSTGRES_NON_ROOT_USER' has been set up with appropriate permissions on database '$POSTGRES_DB'."