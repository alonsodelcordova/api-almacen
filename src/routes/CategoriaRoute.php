<?php

class CategoriaRoute extends BaseRoute{

    private $productService;

    public function __construct() {
        parent::__construct();
        $this->productService = new ProductService();
    }

    public function MainCategorias() {
        if($this->method == 'GET') {
            return $this->obtenerCategorias();
        }
        
    }

    function obtenerCategorias() {
        $Categorias = $this->productService->consultarCategorias();
        $this->success_rpta($Categorias);
    }
    

}