<?php
namespace Api\Models;

class ProductoModel{
    
    public int $id;
    public int $category_id;
    public string $categoria_nombre;
    public int $unidad_id;
    public string $unidad_nombre;
    public int $almacen_id;
    public string $almacen_nombre;
    public string $nombre;
    public string $descripcion;
    public int $stock;
    public float $precio;
    public string $fecha_registro;
    
}