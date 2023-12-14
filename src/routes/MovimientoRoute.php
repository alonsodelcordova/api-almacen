<?php

class MovimientoRoute extends BaseRoute{

    private $productService;

    public function __construct() {
        parent::__construct();
        $this->productService = new ProductService();
    }

    public function MainMovimiento() {
        if($this->method == 'GET') {
            return $this->obtenerMovimiento();
        }
        
    }

    function obtenerMovimiento() {
        $movimientos = $this->productService->consultarMovimientos();
        $this->success_rpta($movimientos);
    }
    

}