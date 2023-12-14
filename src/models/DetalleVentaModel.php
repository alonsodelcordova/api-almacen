<?php


class DetalleVentaModel{
    public int $id;
    public int $venta_id;
    public string $serie;
    public string $codigo;
    public string $producto_id;
    public string $producto;
    public string $cantidad;
    public float $precio_venta;
    public float $total;
    public string $subtotal;
    public string $igv;
    public string $fecha;
}