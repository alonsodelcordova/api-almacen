

-- registrar crear ingreso de producto
DELIMITER $$
CREATE PROCEDURE crearIngresoProducto(
    IN idProducto INT,
    IN idMovimiento INT,
    IN idUsuario INT,
    IN cantidad INT,
    IN precioCompra FLOAT,
    OUT respuesta varchar(50)
)
BEGIN
    declare codigo varchar(25);
    declare precioVenta float;
    declare igv float;
    declare ganancia float;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            set respuesta = 'ERROR: INGRESO PRODUCTO';
        END;

    -- Codigo de kardex
    set codigo = CONCAT(idProducto, idUsuario, DATE_FORMAT(NOW(), '%y%m%d%H%i%s'));
    -- igv del 18%
    set igv = precioCompra * 0.18;
    -- ganancia del 20%
    set ganancia = precioCompra * 0.20 ;
    set precioVenta = precioCompra + igv + ganancia;

    -- Insertar detalles del ingreso en la tabla kardex
    INSERT INTO kardex (codigo_transaccion,id_producto, id_operacion, id_movimiento, id_usuario, cantidad)
        VALUES (codigo, idProducto, 1, idMovimiento, idUsuario, cantidad);

    -- Actualizar el stock del producto
    UPDATE productos SET stock = stock + cantidad, precio_venta = precioVenta
        WHERE id_producto = idProducto;
    set respuesta = codigo;
END$$
DELIMITER ;


-- registrar crear salida de producto
DELIMITER $$
CREATE PROCEDURE crearSalidaProducto(
    IN idProducto INT,
    IN idMovimiento INT,
    IN idUsuario INT,
    IN cantidad INT,
    OUT respuesta varchar(50)
)
BEGIN
    declare codigo varchar(25);
    declare stockActual INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            set respuesta = 'ERROR:SALIDA PRODUCTO';
        END;

    select stock into stockActual from productos where id_producto = idProducto;
    if stockActual < cantidad then
        set respuesta = 'ERROR:STOCK_INSUFICIENTE';
    ELSE 
        -- Codigo de kardex
        set codigo = CONCAT(idProducto, idUsuario, DATE_FORMAT(NOW(), '%y%m%d%H%i%s'));

        -- Insertar detalles del ingreso en la tabla kardex
        INSERT INTO kardex (codigo_transaccion,id_producto, id_operacion, id_movimiento, id_usuario, cantidad)
            VALUES (codigo, idProducto, 2, idMovimiento, idUsuario, cantidad);

        -- Actualizar el stock del producto
        UPDATE productos SET stock = stock - cantidad
            WHERE id_producto = idProducto;
        set respuesta = codigo;
    end if;
END$$
DELIMITER ;



-- crear venta
DELIMITER $$
CREATE PROCEDURE crearVenta(
    IN idMetodoPago INT,
    IN idCliente INT,
    IN idUsuario INT,
    IN idTipoComprobante TEXT,
    OUT respuesta varchar(50)
)
sp:BEGIN
    declare existMetPag int;
    declare existClient int;
    declare existVended int;
    declare existTipCom int;
    declare idVendedor INT;
    declare idVenta int;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            set respuesta = 'ERROR: VENTA';
        END;   
	START TRANSACTION;    	
		select count(*) into existMetPag from metodopago where id_metodopago=idMetodoPago;
		select count(*) into existClient from clientes where  id_cliente=idCliente;
		select count(*) into existVended from vendedor where id_usuario=idUsuario;
		select count(*) into existTipCom from tipo_comprobante where id_comprobante=idTipoComprobante;
		
		if existMetPag = 0 then
			set respuesta = 'ERROR:NO_METODOPAGO';
			leave sp;
		end if;
		if existClient = 0 then
			set respuesta = 'ERROR:NO_CLIENTE';
			leave sp;
		end if;
		if existVended = 0 then
			set respuesta = 'ERROR:NO_VENDEDOR';
			leave sp;
		end if; 
		if existTipCom = 0 then
			set respuesta = 'ERROR:NO_TIPOCOMPROBANTE';
			leave sp;
		end if;
    
        -- Insertar venta
        select id_vendedor into idVendedor from vendedor where id_usuario=idUsuario;
        INSERT INTO venta (id_metodopago, id_cliente, id_vendedor, id_tipocomprobante)
            VALUES (idMetodoPago, idCliente, idVendedor, idTipoComprobante);
        SELECT LAST_INSERT_ID() into idVenta;
        set respuesta = CONCAT('',idVenta);
    COMMIT;   
END$$
DELIMITER ;


-- crear detalle venta
DELIMITER $$
CREATE PROCEDURE crearDetalleVenta(
    IN idVenta INT,
    IN idProducto INT,
    IN precioVenta FLOAT,
    IN cantidad_venta INT,
    OUT respuesta varchar(50)
)
sp:BEGIN
    declare existVenta int;
    declare existProdu int;
    declare idDetalle int;
    declare subtotal float;
    declare igv float;
    declare total float;
    declare idUsuario INT;
    declare codigoVenta varchar(100);
    declare serieVenta varchar(100);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            set respuesta = 'ERROR: DETALLE VENTA';
        END;
		set @respuestaStock = '';
        set serieVenta = CONCAT('V', idProducto,idVenta,DATE_FORMAT(NOW(), '%y%m%d%H%i%s'));
        set codigoVenta = CONCAT(idProducto,idVenta,cantidad_venta);
        
		/* validar los datos */
        select count(*) into existVenta from venta where  id_venta=idVenta;
		select count(*) into existProdu from productos where id_producto=idProducto;
        if existVenta = 0 then
			set respuesta = 'ERROR:NO_VENTA';
			leave sp;
		end if;
        
        if existProdu = 0 then
			set respuesta = 'ERROR:NO_PRODUCTO';
			leave sp;
		end if;
        
        select vn.id_usuario into idUsuario from venta v 
		inner join vendedor vn ON vn.id_vendedor=v.id_vendedor 
		where v.id_venta=idVenta;
        
         -- proceso de salida de producto
        call crearSalidaProducto(idProducto, 6 ,idUsuario, cantidad_venta, @respuestaStock);
		if LOCATE('ERROR', @respuestaStock) > 0 then
            set respuesta = @respuestaStock;
            leave sp;
        end if;
        
        -- Calcular el subtotal y el igv
        -- set subtotal = cantidad_venta * precioVenta; -- con IGV
		-- set igv = subtotal * 0.18;
        -- set total = subtotal + igv;

        set total = cantidad_venta * precioVenta;
        -- calcular el subtotal y el igv
        set subtotal = total / 1.18;
        set igv = total - subtotal;
        
		-- Insertar detalles de la venta en la tabla venta
		INSERT INTO detalle_ventas (id_venta, serie, codigo, id_producto, cantidad, precio_venta, total, subtotal, igv, fecha_creacion)
		VALUES (idVenta, serieVenta, codigoVenta, idProducto, cantidad_venta, precioVenta, total, subtotal, igv, NOW());

		SELECT LAST_INSERT_ID() into idDetalle;
        SET respuesta = CONCAT('',idDetalle);
END$$
DELIMITER ;