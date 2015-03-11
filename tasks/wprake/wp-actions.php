<?php

// Load WordPress environment
//
// This file is temporarily copied to the site's
// root for easier HTTP access, so we need the
// full include path here.

$options = require_once 'tasks/wprake/wp-load-env.php';

// Switch theme

if (array_key_exists('theme', $options)) {

    switch_theme($options['theme'], $options['theme']);
}
