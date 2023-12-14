<?php

class VentasRoute extends BaseRoute{

    private VentasService $ventasService;

    public function __construct() {
        parent::__construct();
        $this->ventasService = new VentasService();
    }

    public function MainAlmacenes() {
        if($this->method == 'GET') {
            if(isset($this->args['action'])){
                if($this->args['action'] == 'detalles'){
                    return $this->obtenerDetallesVentas();
                }
                else if($this->args['action'] == 'metodo-pago'){
                    return $this->obtenerMetodosPagos();
                }
                else if($this->args['action'] == 'tipo-comprobante'){
                    return $this->obtenerTipoComprobantes();
                }
            }

            return $this->obtenerVentas();
        }
        if($this->method == 'POST') {
            if(isset($this->args['action'])){
                if($this->args['action'] == 'detalles'){
                    return $this->registrarDetallesVentas();
                }
            }
            return $this->registrarVenta(); 
        }

        if($this->method == 'DELETE') {
            if(isset($this->args['action'])){
                if($this->args['action'] == 'detalles'){
                    return $this->eliminarDetalleVenta();
                }
            }
            return $this->eliminarVenta();
        }
    }

    function obtenerVentas() {
        $id = 0;
        if(isset($this->args['id'])){
            $id = $this->args['id'];
        }
        $ventas = $this->ventasService->getVentas($id);
        $this->success_rpta($ventas);
    }

    function registrarVenta() {
        $params = ['metodopago_id', 'cliente_id', 'usuario_id', 'tipocomprobante_id'];
        $this->validarParamsInput($params);
        $venta = new VentaModel();
        $venta->metodopago_id = $this->data['metodopago_id'];
        $venta->cliente_id = $this->data['cliente_id'];
        $venta->usuario_id = $this->data['usuario_id'];
        $venta->tipocomprobante_id = $this->data['tipocomprobante_id'];

        $response = $this->ventasService->registrarVenta($venta);
        $this->success_rpta($response);
    }

    function obtenerDetallesVentas() {
        // verified data
        $params = ['id'];
        $this->validarArgQueryInput($params);
        $id = $this->args['id'];
        $detalles = $this->ventasService->getDetallesVentas($id);
        $this->success_rpta($detalles);
    }

    function registrarDetallesVentas() {
        // verified data
        $params = ['venta_id', 'producto_id', 'cantidad', 'precio'];
        $this->validarParamsInput($params);

        $detalle = new DetalleVentaModel();
        $detalle->venta_id = $this->data['venta_id'];
        $detalle->producto_id = $this->data['producto_id'];
        $detalle->cantidad = $this->data['cantidad'];
        $detalle->precio_venta = $this->data['precio'];

        $response = $this->ventasService->registrarDetalleVenta($detalle);
        $this->success_rpta($response);
    }

    function eliminarVenta () {
        $params = ['id'];
        $this->validarArgQueryInput($params);
        $id = $this->args['id'];
        $response = $this->ventasService->deleteVenta($id);
        $this->success_rpta($response);
    }

    function eliminarDetalleVenta() {
        $params = ['id'];
        $this->validarArgQueryInput($params);
        $id = $this->args['id'];
        $response = $this->ventasService->deleteDetalleVenta($id);
        $this->success_rpta($response);
    }
    
    function obtenerMetodosPagos() {
        $metodos = $this->ventasService->getMetodosPagos();
        $this->success_rpta($metodos);
    }

    function obtenerTipoComprobantes() {
        $tipos = $this->ventasService->getTipoComprobantes();
        $this->success_rpta($tipos);
    }

}