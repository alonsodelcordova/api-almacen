<?php
namespace Api\Routes;
use Api\Services\SeguridadService;
use Api\Config\BaseRoute;

class SeguridadRoute extends BaseRoute{

    private SeguridadService $seguridadService;

    public function __construct() {
        parent::__construct();
        $this->seguridadService = new SeguridadService();
    }

    public function MainUnidades() {
        if($this->method == 'POST') {
            if(isset($this->args['action'])){
                if($this->args['action'] == 'login'){
                    return $this->login();
                }
                if($this->args['action'] == 'logout'){
                    return $this->logout();
                }
            }
        }
        
    }

    function login() {
        // verified data
        $params = ['username', 'password'];
        $this->validarParamsInput($params);

        $username = $this->data['username'];
        $password = $this->data['password'];
        $respuesta = $this->seguridadService->login($username, $password);
        if ($respuesta == null) {
            $this->error_rpta("Usuario o contraseña incorrectos");
        }else{
            $this->success_rpta($respuesta);
        }
    }

    function logout() {
        $token = $this->getTokenAuth();
        if($token == null){
            $this->error_rpta("No se encontro el token");
        }
       
        $respuesta = $this->seguridadService->logout($token);
        if($respuesta){
            $this->success_rpta('Se cerro sesión correctamente');
        }else{
            $this->error_rpta('Token no encontrado');
        }
    }
    

}