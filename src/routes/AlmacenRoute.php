<?php
namespace Api\Routes;
use Api\Services\ProductService;
use Api\Config\BaseRoute;

class AlmacenRoute extends BaseRoute{

    private $productService;

    public function __construct() {
        parent::__construct();
        $this->productService = new ProductService();
    }

    public function MainAlmacenes() {
        if($this->method == 'GET') {
            return $this->obtenerAlmacenes();
        }
        
    }

    function obtenerAlmacenes() {
        $almacenes = $this->productService->consultarAlmacenes();
        $this->success_rpta($almacenes);
    }
    

}