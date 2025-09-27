# N8N Encryption Key Guide

## Importance of the Encryption Key

The N8N encryption key is used to encrypt sensitive data in your workflows and credentials. This includes:

- API keys
- Passwords
- OAuth tokens
- Other sensitive data stored in credentials

## Key Characteristics

- **Length**: The key should be at least 32 characters long
- **Complexity**: Use a mix of letters, numbers, and symbols
- **Uniqueness**: Never use the same key across different environments

## Critical Warning

**DO NOT CHANGE THE ENCRYPTION KEY** after you have created workflows or credentials. If you change the key:

1. All existing encrypted credentials will become unusable
2. Workflows using those credentials will fail
3. You will need to recreate all credentials

## Security Best Practices

1. **Backup your key**: Store a secure copy of your encryption key
2. **Restrict access**: Only authorized personnel should have access to the .env file
3. **Don't commit to version control**: Ensure your .env file is in .gitignore
4. **Use different keys**: Use different encryption keys for development, staging, and production

## Recovering From a Lost Key

If you lose your encryption key:

1. All encrypted credentials will be permanently inaccessible
2. You'll need to recreate all credentials from scratch
3. Make sure to update all workflows using those credentials

## Key Rotation (Advanced)

If you need to rotate your encryption key:

1. Export all workflows and credentials
2. Change the encryption key
3. Restart n8n
4. Import all credentials (they will be re-encrypted with the new key)
5. Import all workflows

Remember that security is only as strong as its weakest link. Protect your encryption key carefully.