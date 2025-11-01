<?php
/**
 * phpMyAdmin configuration override
 * Fixes token mismatch issues behind reverse proxy
 */

// Disable configuration file permissions check
$cfg['CheckConfigurationPermissions'] = false;

// Session configuration for reverse proxy
$cfg['SessionSavePath'] = '/sessions';
$cfg['LoginCookieValidityCheckMode'] = 0;
$cfg['LoginCookieValidity'] = 7200;

// Fix CSRF token issues
$cfg['AllowThirdPartyFraming'] = false;

// Memory and execution limits
$cfg['MemoryLimit'] = '512M';
$cfg['ExecTimeLimit'] = 600;

// Disable version check
$cfg['VersionCheck'] = false;

// Trust reverse proxy headers
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
    $_SERVER['SERVER_PORT'] = 443;
}

// Set absolute URI properly
if (isset($_SERVER['HTTP_HOST'])) {
    $cfg['PmaAbsoluteUri'] = 'https://' . $_SERVER['HTTP_HOST'] . '/';
}
?>