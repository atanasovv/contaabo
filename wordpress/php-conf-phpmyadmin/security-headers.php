<?php
/**
 * Security Headers for phpMyAdmin
 * This file is auto-prepended to every PHP request
 */

// Only set headers if they haven't been sent already
if (!headers_sent()) {
    
    // Prevent MIME type sniffing
    header('X-Content-Type-Options: nosniff');
    
    // Prevent clickjacking attacks
    header('X-Frame-Options: DENY');
    
    // Enable XSS protection in browsers
    header('X-XSS-Protection: 1; mode=block');
    
    // Control referrer information
    header('Referrer-Policy: strict-origin-when-cross-origin');
    
    // Content Security Policy - restrict resource loading
    header('Content-Security-Policy: default-src \'self\'; script-src \'self\' \'unsafe-inline\' \'unsafe-eval\'; style-src \'self\' \'unsafe-inline\'; img-src \'self\' data: blob:; font-src \'self\'; connect-src \'self\'; frame-ancestors \'none\';');
    
    // Prevent caching of sensitive data
    header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
    header('Pragma: no-cache');
    header('Expires: Thu, 01 Jan 1970 00:00:00 GMT');
    
    // Additional security headers
    header('X-Robots-Tag: noindex, nofollow');
    header('Permissions-Policy: geolocation=(), microphone=(), camera=()');
}
?>