<?php

class KardexService extends BaseService{


    public function __construct() {
        parent::__construct();
    }


    public function registrarIngresoProducto(KardexMovimientoModel $datosIngreso){
        $response=null;

        try{
            $stmt = $this->conexion->prepare(
                'CALL crearIngresoProducto(:id_producto, :id_movimiento, :id_usuario, :cantidad, :precio_compra, @respuestaSalida)'
            );
            $stmt->bindParam(':id_producto', $datosIngreso->producto_id);
            $stmt->bindParam(':id_movimiento', $datosIngreso->movimiento_id);
            $stmt->bindParam(':id_usuario', $datosIngreso->usuario_id);
            $stmt->bindParam(':cantidad', $datosIngreso->cantidad);
            $stmt->bindParam(':precio_compra', $datosIngreso->precio_compra);
            $stmt->execute();
            
            $stmt2 = $this->conexion->query('SELECT @respuestaSalida as respuesta');
            $stmt2->execute();
            $response = $stmt2->fetchObject();
        } catch (Exception  $e) {
            exit($e->getMessage());
        }
        
        return $response;
    }

    public function registrarSalidaProducto(KardexMovimientoModel $datosIngreso){
        $response=null;
        try{
            $stmt = $this->conexion->prepare(
                'CALL crearSalidaProducto(:id_producto, :id_movimiento, :id_usuario, :cantidad, @respuestaSalida)'
            );
            $stmt->bindParam(':id_producto', $datosIngreso->producto_id);
            $stmt->bindParam(':id_movimiento', $datosIngreso->movimiento_id);
            $stmt->bindParam(':id_usuario', $datosIngreso->usuario_id);
            $stmt->bindParam(':cantidad', $datosIngreso->cantidad);
            $stmt->execute();

            $stmt2 = $this->conexion->query('SELECT @respuestaSalida as respuesta');
            $stmt2->execute();
            $response = $stmt2->fetchObject();
        } catch (Exception  $e) {
            exit($e->getMessage());
        }
        
        return $response;
    }


    public function obtenerKardexByFechas($fechaInicio, $fechaFin): array{
        $response = [];

        try{
            $stmt = $this->conexion->prepare(
                'SELECT * from ver_kardex WHERE fecha_creacion BETWEEN :fecha_inicio and :fecha_fin ORDER BY fecha_creacion DESC'
            );
            $stmt->bindParam(':fecha_inicio', $fechaInicio);
            $stmt->bindParam(':fecha_fin', $fechaFin);
            $stmt->execute();
            $data = $stmt->fetchAll(PDO::FETCH_OBJ);
            foreach ($data as $key => $value) {
               $movimiento = new KardexMovimientoModel();
                $movimiento->id = $value->codigo_transaccion;
                $movimiento->producto_id = $value->id_producto;
                $movimiento->producto_nombre = $value->nombre;
                $movimiento->operacion_id = $value->id_operacion;
                $movimiento->operacion_nombre = $value->operacion;
                $movimiento->movimiento_id = $value->id_movimiento;
                $movimiento->movimiento_nombre = $value->movimiento;
                $movimiento->cantidad = $value->cantidad;
                $movimiento->fecha_registro = $value->fecha_creacion;
                $response[] = $movimiento;
            }

        } catch (Exception  $e) {
            exit($e->getMessage());
        }
        
        return $response;
    }

}

