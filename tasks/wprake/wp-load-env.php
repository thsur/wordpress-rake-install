<?php

// Load WP environment

$options = $_GET;

if (!array_key_exists('wp-dir', $options) || !is_dir($options['wp-dir'])) {

    exit('Error: WordPress directory missing.');
}

require_once $options['wp-dir'].'/wp-load.php';
require_once(ABSPATH . 'wp-admin/includes/plugin.php');

return $options;