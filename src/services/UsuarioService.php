<?php

class UsuarioService extends BaseService{

    public function __construct() {
        parent::__construct();
    }

    public function consultarUsuarios(): array {
        $listUsuarios = array();
        try{
            $query = 'SELECT id, nombre, usuario, tipo_usuario, estado FROM usuarios order by id desc';
            $usuarios = $this->consultarAll($query);
            foreach ($usuarios as $user){
                $usuarioModel = new UsuarioModel();
                $usuarioModel->id = $user->id;
                $usuarioModel->nombre = $user->nombre;
                $usuarioModel->usuario = $user->usuario;
                $usuarioModel->tipo_usuario = $user->tipo_usuario;
                $usuarioModel->estado = $user->estado;
                $listUsuarios[] = $usuarioModel;
            }
        } catch (Exception  $e) {
            exit($e->getMessage());
        }
        
        return $listUsuarios;
    }

    public function consultarByUsername($username): UsuarioModel|null {
        $usuario = null;
        try{
            $query = 'SELECT id, nombre, usuario, password, tipo_usuario, estado FROM usuarios where usuario = :username';
            $stmt = $this->conexion->prepare($query);
            $stmt->bindParam(':username', $username);
            $stmt->execute();
            $user = $stmt->fetch(PDO::FETCH_OBJ);
            if($user != null){
                $usuario = new UsuarioModel();
                $usuario->id = $user->id;
                $usuario->nombre = $user->nombre;
                $usuario->usuario = $user->usuario;
                $usuario->password = $user->password;
                $usuario->tipo_usuario = $user->tipo_usuario;
                $usuario->estado = $user->estado;
            }
        } catch (Exception  $e) {
            exit($e->getMessage());
        }
        
        return $usuario;
    }

    public function consultarClientes(){
        $listClientes = array();
        try{
            $query = 'SELECT id_cliente, documento, ruc, razon_social, direccion FROM clientes order by id_cliente desc';
            $clientes = $this->consultarAll($query);
            foreach ($clientes as $cli){
                $clienteModel = new ClienteModel();
                $clienteModel->id = $cli->id_cliente;
                $clienteModel->tipo_documento = $cli->documento;
                $clienteModel->numero_documento = $cli->ruc;
                $clienteModel->nombre = $cli->razon_social;
                $clienteModel->direccion = $cli->direccion;
                $listClientes[] = $clienteModel;
            }
        } catch (Exception  $e) {
            exit($e->getMessage());
        }
        
        return $listClientes;
    }

    public function registrarCliente($clienteModel){
        $response = [
            'id' => 0
        ];
        try{
            $query = 'INSERT INTO clientes (documento, ruc, razon_social, direccion) VALUES (:documento, :ruc, :razon_social, :direccion)';
            $stmt = $this->conexion->prepare($query);
            $stmt->bindParam(':documento', $clienteModel->tipo_documento);
            $stmt->bindParam(':ruc', $clienteModel->numero_documento);
            $stmt->bindParam(':razon_social', $clienteModel->nombre);
            $stmt->bindParam(':direccion', $clienteModel->direccion);
            $stmt->execute();
            $response['id'] = $this->conexion->lastInsertId();
        } catch (Exception  $e) {
            exit($e->getMessage());
        }
        return $response;
    }

    public function eliminarCliente($id){
        $response = [
            'success' => false
        ];
        try{
            $query = 'DELETE FROM clientes WHERE id_cliente = :id';
            $stmt = $this->conexion->prepare($query);
            $stmt->bindParam(':id', $id);
            $stmt->execute();
            $affected = $stmt->rowCount();
            if($affected > 0){
                $response['success'] = true;
            }
        } catch (Exception  $e) {
            exit($e->getMessage());
        }
        return $response;
    }



}