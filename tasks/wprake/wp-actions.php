<?php

// Load WordPress environment & get query string options
//
// This file is temporarily copied to the site's root for easier
// HTTP access, so we need to use its full include path.

$options = require_once 'tasks/wprake/wp-load-env.php';

// Switch theme

if (array_key_exists('theme', $options)) {

    switch_theme($options['theme'], $options['theme']);
}
