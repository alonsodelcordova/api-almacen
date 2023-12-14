<?php
namespace Api\Routes;
use Api\Services\ProductService;
use Api\Config\BaseRoute;

class UnidadMedidaRoute extends BaseRoute{

    private $productService;

    public function __construct() {
        parent::__construct();
        $this->productService = new ProductService();
    }

    public function MainUnidades() {
        if($this->method == 'GET') {
            return $this->obtenerUnidades();
        }
        
    }

    function obtenerUnidades() {
        $unidades = $this->productService->consultarUnidadesMedida();
        $this->success_rpta($unidades);
    }
    

}