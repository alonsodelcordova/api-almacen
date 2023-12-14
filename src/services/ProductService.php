<?php

class ProductService extends BaseService{


    public function __construct() {
        parent::__construct();
    }

    public function consultarProductos(): array {
        $listPersona = array();
        try{
            $query = 'SELECT pro.id_producto, pro.nombre, pro.descripcion, cat.categoria, pro.precio_venta,
                pro.stock, pro.id_categoria, pro.id_unidad, pro.idAlmacen, uni.unidad, alm.almacen
                FROM productos pro
                left join categorias cat on cat.id_categoria=pro.id_categoria
                left join unidad uni on uni.id_unidad=pro.id_unidad
                left join almacen alm on alm.id_almacen=pro.idAlmacen
                order by pro.id_producto desc';
            $productos = $this->consultarAll($query);
            // Obtiene los resultados    
            foreach ($productos as $pro){
                $newProd = new ProductoModel();
                $newProd->id = $pro->id_producto;
                $newProd->nombre = $pro->nombre;
                $newProd->descripcion = $pro->descripcion;
                $newProd->precio = $pro->precio_venta;
                $newProd->stock = $pro->stock;
                $newProd->category_id = $pro->id_categoria;
                $newProd->unidad_id = $pro->id_unidad;
                $newProd->almacen_id = $pro->idAlmacen;
                // validar que tenga categoria
                $newProd->categoria_nombre = $pro->categoria == null ? '' : $pro->categoria;
                $newProd->unidad_nombre = $pro->unidad == null ? '' : $pro->unidad;
                $newProd->almacen_nombre = $pro->almacen == null ? '' : $pro->almacen;

                $listPersona[] = $newProd;
            }
        } catch (Exception  $e) {
            exit($e->getMessage());
        }
        
        return $listPersona;
    }

    public function consultarProductoById(int $id) {
        $producto = null;
        try{
            $cadena = 'SELECT 
                id_producto, id_categoria, nombre, descripcion, precio_venta, stock, id_unidad, idAlmacen
                FROM productos where id_producto= ? ';
            $query = $this->conexion->prepare($cadena);
            $query->bindParam(1, $id, PDO::PARAM_INT);
            $query->execute();
            $productoSQL = $query->fetchObject();
            if ($productoSQL == null) {
                return $producto;
            }
            $producto = new ProductoModel();
            $producto->id = $productoSQL->id_producto;
            $producto->nombre = $productoSQL->nombre;
            $producto->descripcion = $productoSQL->descripcion;
            $producto->precio = $productoSQL->precio_venta;
            $producto->stock = $productoSQL->stock;
            $producto->category_id = $productoSQL->id_categoria;
            $producto->unidad_id = $productoSQL->id_unidad;
            $producto->almacen_id = $productoSQL->idAlmacen;

        } catch (Exception  $e) {
            exit($e->getMessage());
        }
        
        return $producto;
    }


    public function consultarCategorias(): array {
        $listCategories = array();
        $cadena_sql = 'SELECT id_categoria, categoria FROM categorias ORDER BY id_categoria DESC';
        $categorias = $this->consultarAll($cadena_sql);
        foreach ($categorias as $cat){
            $newCat = new CategoriaModel();
            $newCat->category_id = $cat->id_categoria;
            $newCat->categoria_nombre = $cat->categoria;
            $listCategories[] = $newCat;
        }
        return $listCategories;
    }


    public function consultarAlmacenes(): array {
        $listAlmacenes = array();
        $cadena_sql = 'SELECT id_almacen, almacen FROM almacen ORDER BY id_almacen DESC';
        $almacenes = $this->consultarAll($cadena_sql);
        foreach ($almacenes as $cat){
            $newCat = new AlmacenModel();
            $newCat->almacen_id = $cat->id_almacen;
            $newCat->almacen_nombre = $cat->almacen;
            $listAlmacenes[] = $newCat;
        }
        return $listAlmacenes;
    }

    public function consultarUnidadesMedida(): array {
        $listUnidades = array();
        $cadena_sql = 'SELECT id_unidad, unidad FROM unidad ORDER BY id_unidad DESC';
        $unidadesRes = $this->consultarAll($cadena_sql);
        foreach ($unidadesRes as $cat){
            $newCat = new UnidadMedidaModel();
            $newCat->unidad_id = $cat->id_unidad;
            $newCat->unidad_nombre = $cat->unidad;
            $listUnidades[] = $newCat;
        }
        return $listUnidades;
    }

    public function consultarMovimientos(): array {
        $listMovimientos = array();
        $cadena_sql = 'SELECT id_movimiento, movimiento FROM movimientos ORDER BY id_movimiento DESC';
        $movimientos = $this->consultarAll($cadena_sql);
        foreach ($movimientos as $cat){
            $newCat = new MovimientoModel();
            $newCat->movimiento_id = $cat->id_movimiento;
            $newCat->movimiento_nombre = $cat->movimiento;
            $listMovimientos[] = $newCat;
        }
        return $listMovimientos;
    }

    public function crearProducto(ProductoModel $data): array {
        $response = [
            'id' => 0
        ];
        try{
            $stmt = $this->conexion->prepare(
                'INSERT INTO productos (nombre, descripcion, precio_venta, stock, id_categoria, id_unidad, idAlmacen)
                VALUES (:nombre, :descripcion, 0, 0, :id_categoria, :id_unidad, :idAlmacen)'
            );
            $stmt->bindParam(':nombre', $data->nombre);
            $stmt->bindParam(':descripcion', $data->descripcion);
            $stmt->bindParam(':id_categoria', $data->category_id);
            $stmt->bindParam(':id_unidad', $data->unidad_id);
            $stmt->bindParam(':idAlmacen', $data->almacen_id);
            $stmt->execute();
            $response['id'] = $this->conexion->lastInsertId();
        } catch (Exception  $e) {
            exit($e->getMessage());
        }
        
        return $response;
    }

    public function eliminarProducto(int $id){
        $response = [
            'success' => false
        ];
        try{
            $cadena_sql = 'DELETE FROM productos WHERE id_producto = ?';
            $query = $this->conexion->prepare($cadena_sql);
            $query->bindParam(1, $id, PDO::PARAM_INT);
            $query->execute();
            $affected = $query->rowCount();
            if($affected > 0){
                $response['success'] = true;
            }
        } catch (Exception  $e) {
            exit($e->getMessage());
        }
        return $response;
    }



}