<?php

require __DIR__.'/vendor/autoload.php';

// Inicio de la aplicación -  sin dependencias

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: OPTIONS,GET,POST,PUT,DELETE");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Allow-Origin: *');


$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$uri = str_replace('/api-almacen/', '', $uri);

$uri = explode('/', $uri);

$apiMain = new Api();

$is_exist = $apiMain->ExistsController($uri[0]);

if (!$is_exist) {
    echo json_encode(['error' => 'Endpoint not found. ']);
    exit();
}


// llamando a servicio
$response =  $apiMain->callRoute($uri[0]);


/*
* fin del app
*/




