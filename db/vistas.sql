-----   ver kardex --------------
CREATE VIEW ver_kardex AS
    SELECT 
        kar.codigo_transaccion AS codigo_transaccion,
        kar.id_producto AS id_producto,
        pro.nombre AS nombre,
        pro.idAlmacen AS id_almacen,
        kar.id_operacion AS id_operacion,
        op.operacion AS operacion,
        kar.id_movimiento AS id_movimiento,
        mov.movimiento AS movimiento,
        kar.cantidad AS cantidad,
        kar.fecha_creacion AS fecha_creacion
    FROM
        (((api_maestria.kardex kar
        JOIN api_maestria.productos pro ON (pro.id_producto = kar.id_producto))
        JOIN api_maestria.operaciones op ON (op.id_operacion = kar.id_operacion))
        JOIN api_maestria.movimientos mov ON (mov.id_movimiento = kar.id_movimiento));

go;

-----   ver venta --------------
CREATE VIEW ver_venta AS
select v.id_venta, v.id_metodopago, mp.metodopago, v.id_cliente, cl.razon_social, 
v.id_vendedor, vn.nombre_completo, v.id_tipocomprobante, 
(
	select coalesce(cast(sum(total) as decimal(18,2)),0)
    from detalle_ventas where  id_venta=v.id_venta
) as total_venta,
(select coalesce(cast(sum(subtotal) as decimal(18,2)),0) from detalle_ventas where  id_venta=v.id_venta) as subtotal_venta,
(select coalesce(cast(sum(igv) as decimal(18,2)),0) from detalle_ventas where  id_venta=v.id_venta) as igv_venta,
(select count(id_detalleventa) from detalle_ventas where  id_venta=v.id_venta) as n_detalles,
v.fecha_registro
from venta v
left join metodopago mp on mp.id_metodopago=v.id_metodopago
left join clientes cl ON cl.id_cliente = v.id_cliente
left join vendedor vn on vn.id_vendedor=v.id_vendedor;

-----   ver detalle venta --------------
CREATE VIEW ver_detalle_venta AS
select dv.id_detalleventa, dv.id_venta, dv.serie, dv.codigo, dv.id_producto, p.nombre as nombre_producto,
dv.cantidad, dv.precio_venta, dv.total, dv.subtotal, dv.igv, dv.fecha_creacion
from detalle_ventas dv
inner join productos p on p.id_producto=dv.id_producto;
