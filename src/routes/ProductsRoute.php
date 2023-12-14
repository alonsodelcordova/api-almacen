<?php

class ProductsRoute extends BaseRoute{

    private $productService;
    private $kardexService;

    public function __construct() {
        parent::__construct();
        $this->productService = new ProductService();
        $this->kardexService = new KardexService();
    }

    public function MainProductos() {
        if($this->method == 'GET') {
            if (isset($this->args['id'])) {
                $id = $this->args['id'];
                return $this->obtenerProductoById($id);
            }
            if(isset($this->args['action'])){
                if($this->args['action'] == 'kardex'){
                    return $this->obtenerKardex();
                }
            }
            return $this->obtenerProductos();
        }
    
        if($this->method == 'POST') {
            if(isset($this->args['action'])){
                if($this->args['action'] == 'ingreso'){
                    return $this->ingresoProducto();
                }
                if($this->args['action'] == 'salida'){
                    return $this->salidaProducto();
                }
            }
            return $this->crearProducto();
        }

        if($this->method == 'DELETE') {
            return $this->eliminarProducto();
        }
        
    }

    function obtenerProductos() {
        $productos = $this->productService->consultarProductos();
        $this->success_rpta($productos);
    }

    function obtenerProductoById($id) {
        $producto = $this->productService->consultarProductoById($id);
        if ($producto == null) {
            $this->error_rpta("No se encontro el producto");
        }else{
            $this->success_rpta($producto);
        }
    }

    function obtenerKardex()  {
        $params = ['fecha_inicio', 'fecha_fin'];
        $this->validarArgQueryInput($params);
        
        $fecha_inicio = $this->args['fecha_inicio'];
        $fecha_fin = $this->args['fecha_fin'];

        $this->validarFormatoFecha($fecha_inicio);
        $this->validarFormatoFecha($fecha_fin);

        

        $kardex = $this->kardexService->obtenerKardexByFechas( $fecha_inicio, $fecha_fin);
        $this->success_rpta($kardex);
        
    }
    
    function crearProducto() {
        // verified data
        $params = ['nombre', 'descripcion', 'category_id', 'unidad_id', 'almacen_id'];
        $this->validarParamsInput($params);

        // create product
        $productModel = new ProductoModel();
        $productModel->nombre = $this->data['nombre'];
        $productModel->descripcion = $this->data['descripcion'];
        $productModel->category_id = $this->data['category_id'];
        $productModel->unidad_id = $this->data['unidad_id'];
        $productModel->almacen_id = $this->data['almacen_id'];
        
        $producto = $this->productService->crearProducto($productModel);
        $this->success_rpta($producto);
    }

    function eliminarProducto() {
        // verified data
        $params = ['id'];
        $this->validarArgQueryInput($params);
        $id = $this->args['id'];
        $respuesta = $this->productService->eliminarProducto($id);
        if(!$respuesta['success']){
            $this->error_rpta("No se pudo eliminar el producto");
        }
        $this->success_rpta("Producto eliminado correctamente");
    }

    function ingresoProducto() {
        $id_operacion = 1; // 1: Ingreso, 2: Salida
        $params = ['id_producto', 'id_movimiento', 'id_usuario', 'cantidad', 'precio_compra'];
        $this->validarParamsInput($params);

        $datosIngreso = new KardexMovimientoModel();
        $datosIngreso->producto_id = $this->data['id_producto'];
        $datosIngreso->operacion_id = $id_operacion;
        $datosIngreso->movimiento_id = $this->data['id_movimiento'];
        $datosIngreso->usuario_id = $this->data['id_usuario'];
        $datosIngreso->cantidad = $this->data['cantidad'];
        $datosIngreso->precio_compra = $this->data['precio_compra'];
        
        $producto = $this->kardexService->registrarIngresoProducto($datosIngreso);
        $this->success_rpta($producto);
    }

    function salidaProducto() {
        $id_operacion = 2; // 1: Ingreso, 2: Salida
        $params = ['id_producto', 'id_movimiento', 'id_usuario', 'cantidad'];
        $this->validarParamsInput($params);

        $datosIngreso = new KardexMovimientoModel();
        $datosIngreso->producto_id = $this->data['id_producto'];
        $datosIngreso->operacion_id = $id_operacion;
        $datosIngreso->movimiento_id = $this->data['id_movimiento'];
        $datosIngreso->usuario_id = $this->data['id_usuario'];
        $datosIngreso->cantidad = $this->data['cantidad'];
        
        $producto = $this->kardexService->registrarSalidaProducto($datosIngreso);
        $this->success_rpta($producto);
    }

}
