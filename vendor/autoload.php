<?php

// load files from src folder (all files in src folder must be loaded)
$file_error = array();

require_once __DIR__ . '/../src/Api.php';

foreach (glob(__DIR__ . '/../src/**/*.php') as $filename) {
    try {
        require_once $filename;
    } catch (Throwable  $e) {
        $file_error[] = $filename;
    }
}
while (count($file_error) > 0) {
    
    foreach ($file_error as $key => $filename) {
        try {
            require_once $filename;
            //echo "loaded: $filename - \n";
            unset($file_error[$key]);
        } catch (Throwable  $e) {
            //$file_error[] = $filename;
        }
    }
}

