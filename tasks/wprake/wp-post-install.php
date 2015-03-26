<?php

// Load WordPress environment & get query string options
//
// This file is temporarily copied to the site's root for easier
// HTTP access, so we need to use its full include path.

$options = require_once 'tasks/wprake/wp-load-env.php';

// Add an editor user

if (!array_key_exists('users', $options) || !is_file($options['users'])) {

    exit('Error: Users file missing.');
}

$users =  parse_ini_file($options['users'], true);

if (!array_key_exists('editor', $users)) {

    exit('Error: Editor user missing.');
}

$name = array_keys($users['editor'])[0];
$pass = array_shift($users['editor']);

$user = array(

    'user_login' => $name,
    'user_pass'  => $pass,
    'user_email' => $name.'@example.com',
    'user_url'   => 'http://example.com',
    'role'       => 'editor',
);

$user_id = get_user_by('slug', $user['user_login']);

if (!$user_id) {

    $user_id = wp_insert_user($user);
}

// Don't split uploads into year & months folders

update_option('uploads_use_yearmonth_folders', 0);

// Activate plugins (w/o Akismet & Hello Dolly)

$plugins = array_filter(

    array_keys(get_plugins()),
    function ($value) {

        return strpos($value, 'akismet') === false && strpos($value, 'hello.php') === false;
    }
);

activate_plugins($plugins);

// Exclude search engines

update_option('blog_public', 0);

// Shut down comments

update_option('default_comment_status', 'closed');
update_option('comment_moderation', 1);
update_option('comment_registration', 1);
update_option('require_name_email', 1);
update_option('comments_notify', 0);

// Misc

update_option('posts_per_page', 20);
update_option('use_smilies', 0);

// Set permalink structure

update_option('permalink_structure', '/%category%/%postname%/');
flush_rewrite_rules();

// Disable some widgets

$widgets = array('widget_meta', 'widget_archives', 'widget_recent-comments');

foreach ($widgets as $name) {

    $widget = get_option($name);
    $count  = count($widget);

    if ($count > 1) {

        $widget = array_slice($widget, $count - 1);
        update_option($name, $widget);
    }
}

// Wipe default comment

wp_delete_comment(1, true);

// Rename 'uncategorized'

wp_update_term(1, 'category', array(

  'name' => 'Home',
  'slug' => 'home'
));

