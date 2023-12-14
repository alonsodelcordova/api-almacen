<?php


class ClienteRoute extends BaseRoute{

    private UsuarioService $usuarioService;

    public function __construct() {
        parent::__construct();
        //$this->usuarioService = new UsuarioService();
    }

    public function MainClientes() {
        if($this->method == 'GET') {
            return $this->obtenerClientes();
        }
        else if($this->method == 'POST') {
            return $this->registrarCliente();
        }else if($this->method == 'DELETE') {
            return $this->eliminarCliente();
        }
    }

    function obtenerClientes() {
        $this->usuarioService = new UsuarioService();
        $clientes = $this->usuarioService->consultarClientes();
        $this->success_rpta($clientes);
    }


    function registrarCliente() {
        // verified data
        $params = ['tipo_documento', 'numero_documento', 'nombre', 'direccion'];
        $this->validarParamsInput($params);

        // create product
        $clienteModel = new ClienteModel();
        $clienteModel->tipo_documento = $this->data['tipo_documento'];
        $clienteModel->numero_documento = $this->data['numero_documento'];
        $clienteModel->nombre = $this->data['nombre'];
        $clienteModel->direccion = $this->data['direccion'];
        
        $cliente = $this->usuarioService->registrarCliente($clienteModel);
        $this->success_rpta($cliente);
    }

    function eliminarCliente() {
        // verified data
        $params = ['id'];
        $this->validarArgQueryInput($params);

        $id = $this->args['id'];
        
        $respuesta = $this->usuarioService->eliminarCliente($id);
        if(!$respuesta['success']){
            $this->error_rpta("No se pudo eliminar el cliente");
        }
        $this->success_rpta("Se elimino correctamente el cliente");
    }
    

}