<?php

namespace Api\Models;

class VentaModel{
    public int $id;
    public int $metodopago_id;
    public string $metodopago;
    public int $cliente_id;
    public string $cliente;
    public int $vendedor_id;
    public int $usuario_id;
    public string $vendedor;
    public int $tipocomprobante_id; 
    public float $precio_compra;
    public float $total;
    public float $subtotal;
    public float $igv;
    public int $n_detalles;
    public string $fecha_registro;
}