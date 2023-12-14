<?php
namespace Api\Config;

use DateTime;

class BaseRoute{

	protected string $method;
    protected string $request;
    protected $args;
    protected $data;

	public function __construct(){
		$this->method = $_SERVER['REQUEST_METHOD'];
        $this->request = $_SERVER['REQUEST_URI'];
        $this->args = $_GET;
        $this->data = json_decode(file_get_contents('php://input'), true);
	}

	public function getTokenAuth() {
		$headers = apache_request_headers();
		if (isset($headers['Authorization'])) {
			$token = $headers['Authorization'];
			$token = str_replace('Bearer ', '', $token);
			//limpiar token
			$token = str_replace('"', '', $token);
			$token = str_replace(' ', '', $token);
			return $token;
		}
		return null;
	}

	public function success_rpta($data, $msg="success process") {
		$response = [
            'success' => true, 
            'data' => $data, 
            'args' => $this->args,
            'msg' => $msg
        ];
        exit(json_encode($response));
	}

	public function error_rpta($msg="error process") {
		$response = [
            'success' => false, 
            'data' => [], 
            'args' => $this->args,
            'msg' => $msg
        ];
		// return respuesta status 400
		http_response_code(400);
        exit(json_encode($response));
	}

	private function unprocessableEntityResponse() {
		$response['status_code_header'] = 'HTTP/1.1 422 Unprocessable Entity';
		$response['body'] = json_encode([
		  'error' => 'Invalid input'
		]);
		return $response;
	}

	private function notFoundResponse() {
		$response['status_code_header'] = 'HTTP/1.1 404 Not Found';
		$response['body'] = null;
		return $response;
	}


	public function validarParamsInput($params) {
		foreach ($params as $param) {
			if (!isset($this->data[$param])) {
				$this->error_rpta("El campo $param es requerido");
			}
		}
	}

	public function validarArgQueryInput($params) {
		foreach ($params as $param) {
			if (!isset($this->args[$param])) {
				$this->error_rpta("El parametro $param es requerido");
			}
		}
	}

	public function validarFormatoFecha($fecha, $formato = 'Y-m-d') {
		$d = DateTime::createFromFormat($formato, $fecha);
		if(!($d && $d->format($formato) == $fecha)){
			$this->error_rpta("El formato de fecha es incorrecto, debe ser yyyy/mm/dd");
		}
	}

}

?>