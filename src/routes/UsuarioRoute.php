<?php

class UsuarioRoute extends BaseRoute{

    private $usuarioService;

    public function __construct() {
        parent::__construct();
        $this->usuarioService = new UsuarioService();
    }

    public function MainUsuarios() {
        if($this->method == 'GET') {
            return $this->obtenerUsuarios();
        }
        
    }

    function obtenerUsuarios() {
        $usuarios = $this->usuarioService->consultarUsuarios();
        $this->success_rpta($usuarios);
    }
    
    

}