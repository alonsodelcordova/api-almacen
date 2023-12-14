<?php


class AlmacenRoute extends BaseRoute{

    private ProductService $productService;

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