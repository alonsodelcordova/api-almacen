--- HU de almacen y ventas

Almacenero
-> HU1 - Registrar producto -> Almacen

INPUT: Categoria, unidad, almacen, nombre, descripcion

*stock = 0
*precio venta = precio de compra * (1 + 0.18(IGV) + 0.20(Ganancia))
*codigo -> 2 almacen |2 categoria | 2 producto | idproducto 

-> HU2 - Ingreso de producto 
INPUT: producto, operacion, movimiento, usuario, cantidad, precio compra

registro de kardex
en producto, actualización del precio de venta y stock

-> HU3 - Salida de producto
registro de kardex
en producto, actualización del stock

-> HU7

Vendedor
-> HU4 - Consultar productos 
-> HU7 - Registrar Venta 
-> HU5 - Registrar Clientes
-> HU6 - Consultar Clientes


Administrados del sistema
-> Registrar usuarios 
-> Registrar metodos de pago
-> Registrar tipos de operaciones
-> Registrar almacenes
-> Registrar categorias
-> Registrar unidades de medida







## Tablas
-- productos
    - producto
    - categoria
    - unidad

-- almacen
    - almacen
    

-- usuario
    - usuario
    
-- clientes
    - cliente

-- proveedores
    - proveedor

-- kardex
    - kardex
    - operacion
    - movimiento

-- ventas
    - comprobante
    - detalle_ventas
    - medida
    - metodo_pago
    - 