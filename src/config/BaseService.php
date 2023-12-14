<?php
namespace Api\Config;
use Api\Config\Database;
use PDO;
use PDOException;

class BaseService extends Database{

	protected $conexion;

	public function __construct(){
		parent::__construct();
		$this->conexion = $this->connect();
	}


	public function consultarAll($query){
		try{	
			$stm = $this->conexion->prepare($query);
			$stm->execute();
			return $stm->fetchAll(PDO::FETCH_OBJ);
		}catch(PDOException $ex){
			exit($ex->getMessage());
		}
	}

	public function consultarById($query){
		try{	
			$stm = $this->conexion->prepare($query);
			$stm->execute();
			return $stm->fetchAll(PDO::FETCH_OBJ);
		}catch(PDOException $ex){
			exit($ex->getMessage());
		}
	}



	public function generarToken($usuario) {
        $header = [
            'typ' => 'JWT',
            'alg' => 'HS256'
        ];
        $header = json_encode($header);
        $header = base64_encode($header);
		$usuario->password = '';
		$usuario->time = time();
		$usuario->key = rand(0, 20000);
        $payload = json_encode($usuario);
        $payload = base64_encode($payload);
        $firma = hash_hmac('sha256', "$header.$payload", 'secret', true);
        $firma = base64_encode($firma);

        $token = "$header.$payload.$firma";
        return $token;
    }



	

}

?>