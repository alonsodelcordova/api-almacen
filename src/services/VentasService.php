<?php
namespace Api\Services;
use Api\Models\VentaModel;
use Api\Config\BaseService;
use Api\Models\DetalleVentaModel;
use Api\Models\MetodoPagoModel;
use Exception;
use PDO;

class VentasService extends BaseService{

    public function __construct() {
        parent::__construct();
    }

    public function registrarVenta(VentaModel $dato){
        $response=null;
        try{
            $stmt = $this->conexion->prepare(
                'CALL crearVenta(:id_metodopago, :id_cliente, :id_usuario, :id_tipocomprobante, @respuesta)'
            );
            $stmt->bindParam(':id_metodopago', $dato->metodopago_id);
            $stmt->bindParam(':id_cliente', $dato->cliente_id);
            $stmt->bindParam(':id_usuario', $dato->usuario_id);
            $stmt->bindParam(':id_tipocomprobante', $dato->tipocomprobante_id);
            $stmt->execute();
            
            $stmt2 = $this->conexion->query('SELECT @respuesta as respuesta');
            $stmt2->execute();
            $response = $stmt2->fetchObject();
        } catch (Exception  $e) {
            exit($e->getMessage());
        }        
        return $response;
    }

    public function getVentas(int $id = 0):array{
        $response = [];
        try{
            $cadena = 'SELECT * from ver_venta ';
            if($id > 0){
                $cadena = $cadena.' where id_venta = :id';
            }
            $cadena = $cadena.' order by id_venta desc';
            $stmt = $this->conexion->prepare($cadena);
            if($id > 0){
                $stmt->bindParam(':id', $id, PDO::PARAM_INT);
            }
            $stmt->execute();
            $data = $stmt->fetchAll(PDO::FETCH_OBJ);
            foreach ($data as $key => $value) {
                $venta = new VentaModel();
                $venta->id = $value->id_venta;
                $venta->metodopago_id = $value->id_metodopago;
                $venta->metodopago = $value->metodopago;
                $venta->cliente_id = $value->id_cliente;
                $venta->cliente = $value->razon_social;
                $venta->vendedor_id = $value->id_vendedor;
                $venta->vendedor = $value->nombre_completo;
                $venta->tipocomprobante_id = $value->id_tipocomprobante;
                $venta->total = $value->total_venta;
                $venta->subtotal = $value->subtotal_venta;
                $venta->igv = $value->igv_venta;
                $venta->n_detalles = $value->n_detalles;
                $venta->fecha_registro = $value->fecha_registro;
                $response[] = $venta;
            }
        }catch(Exception $e){
            exit($e->getMessage());
        }
        return $response;
    }

    public function deleteVenta($id)  {
        $response = [
            'success' => false
        ];
        try{
            $cadena_sql = 'DELETE FROM venta WHERE id_venta = ?';
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

    public function registrarDetalleVenta(DetalleVentaModel $dato){
        $response=null;
        try{
            $stmt = $this->conexion->prepare(
                'CALL crearDetalleVenta(:id_venta, :id_producto, :precio_venta, :cantidad_venta, @respuesta)'
            );
            $stmt->bindParam(':id_venta', $dato->venta_id);
            $stmt->bindParam(':id_producto', $dato->producto_id);
            $stmt->bindParam(':precio_venta', $dato->precio_venta);
            $stmt->bindParam(':cantidad_venta', $dato->cantidad);
            $stmt->execute();

            $stmt2 = $this->conexion->query('SELECT @respuesta as respuesta');
            $stmt2->execute();
            $response = $stmt2->fetchObject();
        } catch (Exception  $e) {
            exit($e->getMessage());
        }
        return $response;
    }

    public function getDetallesVentas(int $id):array{
        $response = [];
        try{
            $stmt = $this->conexion->prepare(
                'SELECT * from ver_detalle_venta where id_venta = :id order by id_detalleventa desc'
            );
            $stmt->bindParam(':id', $id);
            $stmt->execute();
            $data = $stmt->fetchAll(PDO::FETCH_OBJ);
            foreach ($data as $key => $value) {
                $venta = new DetalleVentaModel();
                $venta->id = $value->id_detalleventa;
                $venta->venta_id = $value->id_venta;
                $venta->serie = $value->serie;
                $venta->codigo = $value->codigo;
                $venta->producto_id = $value->id_producto;
                $venta->producto = $value->nombre_producto;
                $venta->cantidad = $value->cantidad;
                $venta->precio_venta = $value->precio_venta;
                $venta->total = $value->total;
                $venta->subtotal = $value->subtotal;
                $venta->igv = $value->igv;
                $venta->fecha = $value->fecha_creacion;
                $response[] = $venta;
            }
        }catch(Exception $e){
            exit($e->getMessage());
        }
        return $response;
    }

    public function deleteDetalleVenta($id)  {
        $response = [
            'success' => false
        ];
        try{
            $cadena_sql = 'DELETE FROM detalle_ventas WHERE id_detalleventa = ?';
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

    public function getMetodosPagos():array{
        $response = [];
        try{
            $stmt = $this->conexion->prepare(
                'SELECT * from metodopago order by id_metodopago desc'
            );
            $stmt->execute();
            $data = $stmt->fetchAll(PDO::FETCH_OBJ);
            foreach ($data as $key => $value) {
                $metodo = new MetodoPagoModel();
                $metodo->id = $value->id_metodopago;
                $metodo->nombre = $value->metodopago;
                $response[] = $metodo;
            }
        }catch(Exception $e){
            exit($e->getMessage());
        }
        return $response;
    }

    public function getTipoComprobantes():array{
        $response = [];
        try{
            $stmt = $this->conexion->prepare(
                'SELECT * from tipo_comprobante order by id_comprobante desc'
            );
            $stmt->execute();
            $data = $stmt->fetchAll(PDO::FETCH_OBJ);
            foreach ($data as $key => $value) {
                $metodo = new MetodoPagoModel();
                $metodo->id = $value->id_comprobante;
                $metodo->nombre = $value->comprobante;
                $response[] = $metodo;
            }
        }catch(Exception $e){
            exit($e->getMessage());
        }
        return $response;
    }
}

