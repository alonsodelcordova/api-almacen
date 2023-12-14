<?php
namespace Api\Services;
use Api\Config\Database;
use Api\Config\BaseService;
use Api\Models\UsuarioModel;
use Api\Services\UsuarioService;
use Exception;
use PDO;


class SeguridadService extends BaseService {

    private $usuarioService;

    public function __construct() {
        parent::__construct();
        $this->usuarioService = new UsuarioService();
    }

    public function login($username, $password) {
        $usuario = $this->usuarioService->consultarByUsername($username);
        if($usuario == null || $usuario->password != $password){
            return null;
        }
        //clean password
        $usuario->password = '';
        $token = $this->obtenerToken($usuario);
        $respuesta = [
            'token' => $token,
            'usuario' => $usuario
        ];
        return $respuesta;
    }

    public function obtenerToken(UsuarioModel $usuario) : string {
        $token = $this->getTokenByUsuario($usuario->id);
        if($token == null){
            // crear token
            $token = $this->generarToken($usuario);
            try{
                // guardar token en la base de datos
                $query = 'INSERT INTO token (token, id_usuario) VALUES (:token, :id_usuario)';
                $stmt = $this->conexion->prepare($query);
                $stmt->bindParam(':token', $token);
                $stmt->bindParam(':id_usuario', $usuario->id);
                $stmt->execute();
            } catch (Exception  $e) {
                exit($e->getMessage());
            }
        }
        return $token;
    }

    public function getTokenByUsuario(int $id) : string {
        $token = '';
        try{
            $query = 'SELECT token FROM token where id_usuario = :id_usuario';
            $stmt = $this->conexion->prepare($query);
            $stmt->bindParam(':id_usuario', $id);
            $stmt->execute();
            $token = $stmt->fetchColumn();
        } catch (Exception  $e) {
            exit($e->getMessage());
        }
        return $token;
    }

    public function getToken($token) {
        try{
            $query = 'SELECT id, id_usuario FROM token where token=:token_cad';
            $stmt = $this->conexion->prepare($query);
            $stmt->bindParam(':token_cad', $token, PDO::PARAM_STR);
            $stmt->execute();
            $token = $stmt->fetch(PDO::FETCH_OBJ);
            if($token != null){
                return $token;
            }
        } catch (Exception  $e) {
            exit($e->getMessage());
        }
        return null;
    }


   

    public function logOut($token): bool{
        $token_DB = $this->getToken($token);
        if($token_DB == null){
            return false;
        }
        try{
            $query = 'DELETE FROM token where token = :token';
            $stmt = $this->conexion->prepare($query);
            $stmt->bindParam(':token', $token);
            $stmt->execute();
            return true;
        } catch (Exception  $e) {
            exit($e->getMessage());
        }
    }


}