-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 14-12-2023 a las 18:50:20
-- Versión del servidor: 10.4.28-MariaDB
-- Versión de PHP: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `api_maestria`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `crearDetalleVenta` (IN `idVenta` INT, IN `idProducto` INT, IN `precioVenta` FLOAT, IN `cantidad_venta` INT, OUT `respuesta` VARCHAR(50))   sp:BEGIN
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `crearIngresoProducto` (IN `idProducto` INT, IN `idMovimiento` INT, IN `idUsuario` INT, IN `cantidad` INT, IN `precioCompra` FLOAT, OUT `respuesta` VARCHAR(50))   BEGIN
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `crearSalidaProducto` (IN `idProducto` INT, IN `idMovimiento` INT, IN `idUsuario` INT, IN `cantidad` INT, OUT `respuesta` VARCHAR(50))   BEGIN
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `crearVenta` (IN `idMetodoPago` INT, IN `idCliente` INT, IN `idUsuario` INT, IN `idTipoComprobante` TEXT, OUT `respuesta` VARCHAR(50))   sp:BEGIN
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

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `almacen`
--

CREATE TABLE `almacen` (
  `id_almacen` int(11) NOT NULL COMMENT 'PK',
  `almacen` text NOT NULL COMMENT 'Nombre del almacen',
  `fecha_create` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'fecha de creacion'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci COMMENT='Tabla de Almacenes';

--
-- Volcado de datos para la tabla `almacen`
--

INSERT INTO `almacen` (`id_almacen`, `almacen`, `fecha_create`) VALUES
(1, 'Almacen Principal', '2023-08-18 01:20:36'),
(2, 'Almacen Lima', '2023-12-13 12:53:01');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categorias`
--

CREATE TABLE `categorias` (
  `id_categoria` int(11) NOT NULL COMMENT 'pk',
  `categoria` text NOT NULL COMMENT 'nombre categoria',
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'fecha creacion'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci COMMENT='Categoria del Producto';

--
-- Volcado de datos para la tabla `categorias`
--

INSERT INTO `categorias` (`id_categoria`, `categoria`, `fecha_creacion`) VALUES
(1, 'Valvula Industrial', '2021-01-05 16:40:12'),
(2, 'Pinzas', '2023-12-13 12:50:21'),
(3, 'Nanometro', '2023-12-13 12:50:28'),
(4, 'Soldadura', '2021-01-05 16:33:32'),
(5, 'Regulador', '2021-01-05 16:35:38'),
(6, 'Mascarilla', '2021-01-05 16:35:38'),
(7, 'Extension', '2021-01-05 16:35:54'),
(8, 'Tanque', '2021-01-05 16:36:38'),
(9, 'Oximetro', '2021-01-05 16:37:17'),
(10, 'Maquina de Soldar', '2021-01-05 16:39:25'),
(11, 'Equipo de Corte', '2023-12-13 12:50:57'),
(13, 'Accesorios Varios', '2022-11-14 02:36:06');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `clientes`
--

CREATE TABLE `clientes` (
  `id_cliente` int(11) NOT NULL COMMENT 'pk',
  `documento` text CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT 'RUC o DNI',
  `ruc` char(11) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT 'numero de documento',
  `razon_social` text CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT 'nombre del cliente',
  `direccion` text CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT 'direccion del cliente',
  `fecha_registro` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'fecha registro'
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci COMMENT='Clientes';

--
-- Volcado de datos para la tabla `clientes`
--

INSERT INTO `clientes` (`id_cliente`, `documento`, `ruc`, `razon_social`, `direccion`, `fecha_registro`) VALUES
(1, 'RUC', '20554230165', 'CLIMATIZACION ASIS S.A.C.', 'AV. LOS FICUS MZA. O2 LOTE. 2 URB.  VISTA ALEGRE DE VILLA  (IGLESIA SAN FRANCISCO DE ASIS)', '2021-03-09 22:03:56'),
(2, 'RUC', '20483894814', 'ECO', 'NRO. S/N CAS.  CHAPAIRA  (FRENTE A CASERIO CHAPAIRA)', '2021-03-09 22:07:16'),
(3, 'RUC', '20530184596', 'ECOSAC AGRICOLA S.A.C.', 'CAR.CHAPAIRA NRO. S N CAS.  CHAPAIRA  (FRENTE AL CASERIO CHAPAIRA)', '2021-03-09 22:09:32'),
(4, 'RUC', '20525342914', 'FACTORIA AQUILINO MARTINEZ PAZOS SOCIEDAD COMERCIAL DE RESPONSABILIDAD LIMITADA', 'CAL.HUAYNA CAPAC NRO. 1111 A.H.  CAMPO POLO  (CDRA. 19 DE AV. PROGRESO)', '2021-03-09 22:10:27'),
(5, 'RUC', '20529932881', 'SERVICIOS PESQUEROS DISMAR SOCIEDAD ANONIMA CERRADA', 'CAL.LOS LAURELES NRO. 311 A.H.  VICTOR RAUL  (A ESPALDAS DEL ESTADIO)', '2021-03-09 22:14:03'),
(7, 'RUC', '20600411978', 'SANEAMIENTO Y SOLUCIONES S.A.C.', 'AV. JOSE CARLOS MARIATEGUI NRO. 517 SAN MARTIN  (A 1 CDRA. DE CIRCUNVALACION)', '2021-03-09 22:14:51'),
(8, 'RUC', '20605353810', 'INOXIDABLES PIURA M & N S.R.L.', 'MZA. E LOTE. 12 PQ. RESID. MONTEVERDE II 3 ETAPA  (CERCA A CENTRO RECREAT. ACUALANDIA)', '2021-03-09 22:16:07'),
(9, 'RUC', '20525871747', 'FACTONOR E.I.R.L.', 'MZA. X LOTE. 8A Z.I.  ZONA INDUSTRIAL  (PARTE POSTERIOR DE EMAUS)', '2021-03-09 22:22:56'),
(10, 'RUC', '20601158257', 'TORNERIA Y SOLDADURA DE CALIDAD SOCIEDAD ANONIMA CERRADA', 'SUB LOTE 2 B2A MZA. 231 Z.I.  SECCION A  (A ESPALDAS DE COSTA GAS)', '2021-03-09 22:23:44'),
(11, 'RUC', '20483899379', 'CORPORACION CRUZ SOCIEDAD ANONIMA CERRADA', 'MZA. 246 LOTE. 03 Z.I.  ZONA INDUSTRIAL PIURA  (ESPALDAS DE AGENCIA EPPO)', '2021-03-09 22:24:36'),
(12, 'RUC', '10036888291', 'SOSA MENDOZA ANA MARIA', 'CAL. LA BREA 513 A.H. SANTA TERESITA      ', '2021-03-09 22:25:21'),
(13, 'RUC', '20115886381', 'DOIG CONTRATISTAS GENERALES SRL', 'JR. DOMINGO SAVIO NRO. 175 URB.  ANGAMOS', '2021-03-09 22:26:21'),
(14, 'RUC', '20356922311', 'SEAFROST S.A.C.', 'MZA. D LOTE. 01 Z.I.  II', '2021-03-09 22:26:58'),
(15, 'RUC', '20523552903', 'PETREVEN PERU S.A', 'CAL.MENDIBURU NRO. 878 INT. 602 (878 880)', '2021-03-09 22:27:47'),
(45, 'DNI', '10908070', 'alonso', 'piura', '2023-11-30 12:37:25'),
(46, 'RUC', '906012312', 'Humberto Carlos', 'Piura peru', '2023-12-13 12:38:49');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_ventas`
--

CREATE TABLE `detalle_ventas` (
  `id_detalleventa` int(11) NOT NULL COMMENT 'PK',
  `id_venta` int(11) NOT NULL,
  `serie` varchar(100) NOT NULL COMMENT 'serie del comprobante',
  `codigo` varchar(100) NOT NULL COMMENT 'correlativo',
  `id_producto` int(11) DEFAULT NULL COMMENT 'Producto',
  `cantidad` int(11) NOT NULL COMMENT 'Cantidad por producto',
  `precio_venta` float NOT NULL COMMENT 'Precio x Producto',
  `total` float DEFAULT NULL COMMENT 'Total x Producto',
  `subtotal` float NOT NULL COMMENT 'Subtotal',
  `igv` float NOT NULL COMMENT 'IGV',
  `fecha_creacion` date NOT NULL,
  `fecha_actualizacion` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Venta de Gases';

--
-- Volcado de datos para la tabla `detalle_ventas`
--

INSERT INTO `detalle_ventas` (`id_detalleventa`, `id_venta`, `serie`, `codigo`, `id_producto`, `cantidad`, `precio_venta`, `total`, `subtotal`, `igv`, `fecha_creacion`, `fecha_actualizacion`) VALUES
(18, 1, '123', '99', 32, 5, 1, 14, 6, 8, '2023-12-01', '2023-12-01 12:35:49'),
(19, 1, '123', '99', 32, 5, 1, 14, 6, 8, '2023-12-01', '2023-12-01 12:36:43'),
(20, 1, '123', '99', 32, 5, 1, 14, 6, 8, '2023-12-01', '2023-12-01 12:36:55'),
(21, 8, '123', '99', 32, 5, 1, 14, 6, 8, '2023-12-01', '2023-12-01 12:39:40'),
(22, 1, '123', '99', 32, 5, 1, 14, 6, 8, '2023-12-01', '2023-12-01 12:40:12'),
(23, 3, '123', '99', 32, 5, 1, 14, 6, 8, '2023-12-01', '2023-12-01 12:40:22'),
(24, 8, '123', '99', 32, 5, 1, 14, 6, 8, '2023-12-01', '2023-12-01 12:41:29'),
(25, 1, '123', '99', 32, 5, 1, 14, 6, 8, '2023-12-01', '2023-12-01 12:45:07'),
(26, 3, '123', '99', 32, 5, 1, 14, 6, 8, '2023-12-01', '2023-12-01 12:46:06'),
(27, 1, '123', '99', 32, 5, 1, 14, 6, 8, '2023-12-01', '2023-12-01 12:47:08'),
(28, 1, '123', '99', 32, 5, 1, 14, 6, 8, '2023-12-09', '2023-12-09 21:35:09'),
(30, 4, '190', '1212', 1, 1, 1, 1.18, 1, 0.18, '2023-12-09', '2023-12-09 21:50:44'),
(31, 1, 'HY1', '90', 1, 1, 1, 1.18, 1, 0.18, '2023-12-09', '2023-12-09 21:52:34'),
(32, 7, 'V11231209171202', '111', 1, 1, 1, 1.18, 1, 0.18, '2023-12-09', '2023-12-09 22:12:02'),
(33, 1, 'V21231212194140', '213', 2, 3, 1, 3.54, 3, 0.54, '2023-12-12', '2023-12-13 00:41:40'),
(34, 20, 'V3220231212225711', '32201', 32, 1, 3, 3.54, 3, 0.54, '2023-12-12', '2023-12-13 03:57:11'),
(35, 21, 'V221231212225930', '22110', 2, 10, 70, 826, 700, 126, '2023-12-12', '2023-12-13 03:59:30'),
(36, 22, 'V222231212230137', '22212', 2, 12, 90, 1274.4, 1080, 194.4, '2023-12-12', '2023-12-13 04:01:37'),
(37, 23, 'V123231212230530', '1235', 1, 5, 10, 59, 50, 9, '2023-12-12', '2023-12-13 04:05:30'),
(38, 23, 'V223231212230554', '22310', 2, 10, 70, 826, 700, 126, '2023-12-12', '2023-12-13 04:05:54'),
(39, 26, 'V3226231213073603', '32261', 32, 1, 190, 224.2, 190, 34.2, '2023-12-13', '2023-12-13 12:36:03'),
(40, 26, 'V226231213073654', '2261', 2, 1, 70, 82.6, 70, 12.6, '2023-12-13', '2023-12-13 12:36:54'),
(41, 27, 'V3527231213075602', '352710', 35, 10, 0.5, 5.9, 5, 0.9, '2023-12-13', '2023-12-13 12:56:02'),
(42, 27, 'V3427231213075629', '34271', 34, 1, 50, 59, 50, 9, '2023-12-13', '2023-12-13 12:56:29'),
(43, 28, 'V3428231213080642', '34281', 34, 1, 60, 60, 50.8475, 9.15254, '2023-12-13', '2023-12-13 13:06:42'),
(44, 28, 'V228231213080702', '2281', 2, 1, 69, 69, 58.4746, 10.5254, '2023-12-13', '2023-12-13 13:07:02');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `kardex`
--

CREATE TABLE `kardex` (
  `codigo_transaccion` varchar(25) NOT NULL COMMENT 'Codigo unico de transaccion',
  `id_producto` int(11) NOT NULL COMMENT 'FK Producto',
  `id_operacion` int(11) NOT NULL COMMENT 'Entrada[1] | Salid[2]',
  `id_movimiento` int(11) NOT NULL COMMENT 'Movimiento',
  `id_usuario` int(11) DEFAULT NULL COMMENT 'usuario de la accion',
  `cantidad` int(11) NOT NULL COMMENT 'cantidad a cambiar',
  `fecha_creacion` datetime DEFAULT current_timestamp() COMMENT 'fecha actual del servidor'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Graba entradas y salidas de productos al inventario';

--
-- Volcado de datos para la tabla `kardex`
--

INSERT INTO `kardex` (`codigo_transaccion`, `id_producto`, `id_operacion`, `id_movimiento`, `id_usuario`, `cantidad`, `fecha_creacion`) VALUES
('100120231122233603', 1, 1, 2, 1, 100, '2023-11-22 00:00:00'),
('100120231122234930', 1, 2, 2, 1, 100, '2023-11-22 00:00:00'),
('112023112107414', 1, 1, 1, 1, 10, '2023-11-21 00:00:00'),
('112023112107424', 1, 1, 1, 1, 88, '2023-11-21 00:00:00'),
('1120231122233541', 1, 1, 2, 1, 100, '2023-11-22 00:00:00'),
('1120231123220956', 1, 1, 1, 1, 90, '2023-11-23 00:00:00'),
('1120231201062452', 1, 2, 2, 1, 5, '2023-12-01 00:00:00'),
('1120231201062552', 1, 2, 2, 1, 5, '2023-12-01 00:00:00'),
('1120231201062632', 1, 2, 2, 1, 5, '2023-12-01 00:00:00'),
('1320231201074101', 1, 2, 6, 3, 5, '2023-12-01 00:00:00'),
('1320231201074253', 1, 2, 6, 3, 5, '2023-12-01 00:00:00'),
('1320231201074422', 1, 2, 6, 3, 5, '2023-12-01 00:00:00'),
('1320231201074720', 1, 2, 6, 3, 5, '2023-12-01 00:00:00'),
('1320231209163357', 1, 2, 6, 3, 5, '2023-12-09 00:00:00'),
('1320231209163437', 1, 2, 6, 3, 1, '2023-12-09 00:00:00'),
('1320231209164511', 1, 2, 6, 3, 1, '2023-12-09 00:00:00'),
('1320231209164546', 1, 2, 6, 3, 1, '2023-12-09 00:00:00'),
('1320231209164623', 1, 2, 6, 3, 1, '2023-12-09 00:00:00'),
('1320231209164800', 1, 2, 6, 3, 1, '2023-12-09 00:00:00'),
('1320231209165010', 1, 2, 6, 3, 1, '2023-12-09 00:00:00'),
('1320231209165044', 1, 2, 6, 3, 1, '2023-12-09 00:00:00'),
('1320231209165234', 1, 2, 6, 3, 1, '2023-12-09 00:00:00'),
('1320231209171202', 1, 2, 6, 3, 1, '2023-12-09 00:00:00'),
('1320231212230530', 1, 2, 6, 3, 5, '2023-12-12 00:00:00'),
('13231212231231', 1, 1, 5, 3, 90, '2023-12-12 23:12:31'),
('2120231121075759', 1, 2, 4, 1, 100, '2023-11-21 00:00:00'),
('2120231121080836', 1, 1, 1, 1, 100, '2023-11-21 00:00:00'),
('2120231123215737', 2, 1, 2, 1, 10, '2023-11-23 00:00:00'),
('2120231123215908', 2, 1, 2, 1, 20, '2023-11-23 00:00:00'),
('2120231123220004', 2, 1, 2, 1, 90, '2023-11-23 00:00:00'),
('2120231123220936', 2, 2, 4, 1, 10, '2023-11-23 00:00:00'),
('2120231123221209', 2, 1, 2, 1, 10, '2023-11-23 00:00:00'),
('2120231123221221', 2, 2, 5, 1, 90, '2023-11-23 00:00:00'),
('2120231201063703', 2, 2, 5, 1, 5, '2023-12-01 00:00:00'),
('2320231212191112', 2, 1, 2, 3, 100, '2023-12-12 00:00:00'),
('2320231212194140', 2, 2, 6, 3, 3, '2023-12-12 00:00:00'),
('2320231212225930', 2, 2, 6, 3, 10, '2023-12-12 00:00:00'),
('2320231212230137', 2, 2, 6, 3, 12, '2023-12-12 00:00:00'),
('2320231212230554', 2, 2, 6, 3, 10, '2023-12-12 00:00:00'),
('23231213073654', 2, 2, 6, 3, 1, '2023-12-13 07:36:54'),
('23231213080702', 2, 2, 6, 3, 1, '2023-12-13 08:07:02'),
('271202311210745', 1, 1, 1, 1, 100, '2023-11-21 00:00:00'),
('32120231125161105', 32, 1, 1, 1, 100, '2023-11-25 00:00:00'),
('32120231201063827', 32, 2, 4, 1, 10, '2023-12-01 00:00:00'),
('32120231201063844', 32, 2, 4, 1, 10, '2023-12-01 00:00:00'),
('32120231201064302', 32, 2, 5, 1, 5, '2023-12-01 00:00:00'),
('32120231201064330', 32, 1, 1, 1, 80, '2023-12-01 00:00:00'),
('32320231201072504', 32, 2, 6, 3, 5, '2023-12-01 00:00:00'),
('32320231201072545', 32, 2, 6, 3, 5, '2023-12-01 00:00:00'),
('32320231201072613', 32, 2, 6, 3, 5, '2023-12-01 00:00:00'),
('32320231201072852', 32, 2, 6, 3, 5, '2023-12-01 00:00:00'),
('32320231201072927', 32, 2, 6, 3, 5, '2023-12-01 00:00:00'),
('32320231201073112', 32, 2, 6, 3, 5, '2023-12-01 00:00:00'),
('32320231201073153', 32, 2, 6, 3, 5, '2023-12-01 00:00:00'),
('32320231201073837', 32, 2, 6, 3, 5, '2023-12-01 00:00:00'),
('32320231212191015', 32, 1, 2, 3, 50, '2023-12-12 00:00:00'),
('32320231212225711', 32, 2, 6, 3, 1, '2023-12-12 00:00:00'),
('323231213073603', 32, 2, 6, 3, 1, '2023-12-13 07:36:03'),
('333231213075448', 33, 1, 1, 3, 100, '2023-12-13 07:54:48'),
('343231213075506', 34, 1, 1, 3, 10, '2023-12-13 07:55:06'),
('343231213075629', 34, 2, 6, 3, 1, '2023-12-13 07:56:29'),
('343231213080642', 34, 2, 6, 3, 1, '2023-12-13 08:06:42'),
('353231213075527', 35, 1, 1, 3, 1000, '2023-12-13 07:55:27'),
('353231213075602', 35, 2, 6, 3, 10, '2023-12-13 07:56:02');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `metodopago`
--

CREATE TABLE `metodopago` (
  `id_metodopago` int(11) NOT NULL,
  `metodopago` char(40) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Metodo de pago';

--
-- Volcado de datos para la tabla `metodopago`
--

INSERT INTO `metodopago` (`id_metodopago`, `metodopago`) VALUES
(1, 'Efectivo'),
(2, 'Tarjeta');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `movimientos`
--

CREATE TABLE `movimientos` (
  `id_movimiento` int(11) NOT NULL COMMENT 'llave primaria',
  `movimiento` text NOT NULL COMMENT 'describe movimiento'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Motivo de movimientos';

--
-- Volcado de datos para la tabla `movimientos`
--

INSERT INTO `movimientos` (`id_movimiento`, `movimiento`) VALUES
(1, 'Apertura Stock'),
(2, 'Aumento de Stock'),
(3, 'Error Apertura Stock'),
(4, 'Devolucion Producto'),
(5, 'Transferencia entre almacenes'),
(6, 'Venta de Producto');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `operaciones`
--

CREATE TABLE `operaciones` (
  `id_operacion` int(11) NOT NULL,
  `operacion` varchar(25) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Operaciones en el sistema';

--
-- Volcado de datos para la tabla `operaciones`
--

INSERT INTO `operaciones` (`id_operacion`, `operacion`) VALUES
(1, 'entrada'),
(2, 'salida');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `id_producto` int(11) NOT NULL COMMENT 'PK',
  `id_categoria` int(11) NOT NULL COMMENT 'categoria',
  `id_unidad` int(11) NOT NULL COMMENT 'Unidad medida del producto',
  `idAlmacen` int(11) NOT NULL COMMENT 'almacen dnde se regsitra',
  `codigo` varchar(25) NOT NULL COMMENT 'codigo unico',
  `nombre` text NOT NULL COMMENT 'nombre del producto',
  `descripcion` text NOT NULL COMMENT 'descripcion',
  `stock` int(11) NOT NULL COMMENT 'stock inicial',
  `precio_venta` float NOT NULL COMMENT 'precio de venta',
  `fecha_registro` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'fecha de registro'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci COMMENT='Productos a la venta';

--
-- Volcado de datos para la tabla `productos`
--

INSERT INTO `productos` (`id_producto`, `id_categoria`, `id_unidad`, `idAlmacen`, `codigo`, `nombre`, `descripcion`, `stock`, `precio_venta`, `fecha_registro`) VALUES
(1, 2, 8, 1, '', 'Pinzas pequeñas', '1 pulgada', 126, 13.8, '2023-12-13 12:51:51'),
(2, 11, 4, 1, '', 'Cuchilo de alumnio', '12', 88, 69, '2023-12-13 13:07:02'),
(32, 3, 3, 1, '', 'Nametro de mercurio', 'adasda', 163, 193.2, '2023-12-13 12:52:25'),
(33, 13, 3, 1, '', 'Imperdible 34 x 5 ', '', 100, 1.38, '2023-12-13 12:54:48'),
(34, 8, 3, 1, '', 'Balon de Gas de 5Kg', '', 8, 69, '2023-12-13 13:06:42'),
(35, 6, 3, 1, '', 'Mascarilla de Tela doble capa', '', 990, 0.69, '2023-12-13 12:56:02');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipo_comprobante`
--

CREATE TABLE `tipo_comprobante` (
  `id_comprobante` int(11) NOT NULL,
  `comprobante` char(80) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Volcado de datos para la tabla `tipo_comprobante`
--

INSERT INTO `tipo_comprobante` (`id_comprobante`, `comprobante`) VALUES
(1, 'Boleta'),
(2, 'Factura');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `token`
--

CREATE TABLE `token` (
  `id` int(11) NOT NULL,
  `token` varchar(256) NOT NULL,
  `id_usuario` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `token`
--

INSERT INTO `token` (`id`, `token`, `id_usuario`) VALUES
(19, 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpZCI6Mywibm9tYnJlIjoianVhbiIsInVzdWFyaW8iOiJqdWFuIiwicGFzc3dvcmQiOiIiLCJ0aXBvX3VzdWFyaW8iOiIyIiwiZXN0YWRvIjoxLCJ0aW1lIjoxNzAyNDI1NTA0LCJrZXkiOjk4MzB9.9fqpR1pCO5eVtU4gGpzjrab+jOstmGbBlC5DzpVTMVk=', 3);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `unidad`
--

CREATE TABLE `unidad` (
  `id_unidad` int(11) NOT NULL COMMENT 'pk',
  `unidad` text NOT NULL COMMENT 'descripcion'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Unidad del Gas';

--
-- Volcado de datos para la tabla `unidad`
--

INSERT INTO `unidad` (`id_unidad`, `unidad`) VALUES
(1, 'M3'),
(2, 'KG'),
(3, 'UND'),
(4, 'lata'),
(5, 'Galon'),
(6, 'caja'),
(7, 'millar'),
(8, 'Lb'),
(9, 'L'),
(10, 'Barril'),
(11, 'mts'),
(12, 'servicio');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id` int(11) NOT NULL COMMENT 'pk',
  `nombre` varchar(50) NOT NULL,
  `usuario` varchar(40) NOT NULL COMMENT 'usuario',
  `password` varchar(256) NOT NULL COMMENT 'contraseña',
  `estado` int(11) NOT NULL COMMENT 'activo(1)',
  `ultimo_login` datetime NOT NULL,
  `fecha` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `tipo_usuario` int(1) NOT NULL COMMENT '1- admi,2- ven,3- alma'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci COMMENT='Usuarios del sistema';

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id`, `nombre`, `usuario`, `password`, `estado`, `ultimo_login`, `fecha`, `tipo_usuario`) VALUES
(1, 'Administrador', 'admin', '12345678', 1, '2023-08-13 13:26:41', '2023-11-02 12:38:12', 1),
(2, 'ADOLFO', 'GCALVO', '12345678\r\n', 1, '2021-09-15 22:53:26', '2023-11-02 12:38:43', 1),
(3, 'juan', 'juan', '123', 1, '2023-11-23 23:45:26', '2023-11-23 22:46:17', 2);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `vendedor`
--

CREATE TABLE `vendedor` (
  `id_vendedor` int(11) NOT NULL COMMENT 'pk',
  `dni` char(8) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT 'RUC',
  `id_usuario` int(11) DEFAULT NULL COMMENT 'usuario',
  `nombre_completo` text NOT NULL COMMENT 'nombre',
  `direccion` text DEFAULT NULL COMMENT 'direccion',
  `estado` int(1) NOT NULL COMMENT 'estado empresa'
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Volcado de datos para la tabla `vendedor`
--

INSERT INTO `vendedor` (`id_vendedor`, `dni`, `id_usuario`, `nombre_completo`, `direccion`, `estado`) VALUES
(1, '90807060', 3, 'juan torres', 'piura', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `venta`
--

CREATE TABLE `venta` (
  `id_venta` int(11) NOT NULL,
  `id_metodopago` int(11) DEFAULT NULL,
  `id_cliente` int(11) DEFAULT NULL,
  `id_vendedor` int(11) DEFAULT NULL,
  `id_tipocomprobante` int(11) DEFAULT NULL,
  `fecha_registro` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `venta`
--

INSERT INTO `venta` (`id_venta`, `id_metodopago`, `id_cliente`, `id_vendedor`, `id_tipocomprobante`, `fecha_registro`) VALUES
(1, 1, 1, 1, 1, '2023-12-12 09:17:57'),
(3, 1, 1, 1, 1, '2023-12-12 09:17:57'),
(4, 1, 1, 1, 1, '2023-12-12 09:17:57'),
(7, 2, 2, 1, 1, '2023-12-12 09:17:57'),
(8, 2, 2, 1, 1, '2023-12-12 09:17:57'),
(20, 2, 5, 1, 1, '2023-12-12 22:56:09'),
(21, 1, 4, 1, 2, '2023-12-12 22:59:16'),
(22, 2, 7, 1, 1, '2023-12-12 23:01:25'),
(23, 1, 15, 1, 2, '2023-12-12 23:05:14'),
(26, 1, 3, 1, 2, '2023-12-13 07:35:21'),
(27, 1, 46, 1, 1, '2023-12-13 07:55:48'),
(28, 1, 14, 1, 1, '2023-12-13 08:06:31');

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `ver_detalle_venta`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `ver_detalle_venta` (
`id_detalleventa` int(11)
,`id_venta` int(11)
,`serie` varchar(100)
,`codigo` varchar(100)
,`id_producto` int(11)
,`nombre_producto` text
,`cantidad` int(11)
,`precio_venta` float
,`total` float
,`subtotal` float
,`igv` float
,`fecha_creacion` date
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `ver_kardex`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `ver_kardex` (
`codigo_transaccion` varchar(25)
,`id_producto` int(11)
,`nombre` text
,`id_almacen` int(11)
,`id_operacion` int(11)
,`operacion` varchar(25)
,`id_movimiento` int(11)
,`movimiento` text
,`cantidad` int(11)
,`fecha_creacion` datetime
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `ver_venta`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `ver_venta` (
`id_venta` int(11)
,`id_metodopago` int(11)
,`metodopago` char(40)
,`id_cliente` int(11)
,`razon_social` text
,`id_vendedor` int(11)
,`nombre_completo` text
,`id_tipocomprobante` int(11)
,`total_venta` decimal(18,2)
,`subtotal_venta` decimal(18,2)
,`igv_venta` decimal(18,2)
,`n_detalles` bigint(21)
,`fecha_registro` datetime
);

-- --------------------------------------------------------

--
-- Estructura para la vista `ver_detalle_venta`
--
DROP TABLE IF EXISTS `ver_detalle_venta`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `ver_detalle_venta`  AS SELECT `dv`.`id_detalleventa` AS `id_detalleventa`, `dv`.`id_venta` AS `id_venta`, `dv`.`serie` AS `serie`, `dv`.`codigo` AS `codigo`, `dv`.`id_producto` AS `id_producto`, `p`.`nombre` AS `nombre_producto`, `dv`.`cantidad` AS `cantidad`, `dv`.`precio_venta` AS `precio_venta`, `dv`.`total` AS `total`, `dv`.`subtotal` AS `subtotal`, `dv`.`igv` AS `igv`, `dv`.`fecha_creacion` AS `fecha_creacion` FROM (`detalle_ventas` `dv` join `productos` `p` on(`p`.`id_producto` = `dv`.`id_producto`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `ver_kardex`
--
DROP TABLE IF EXISTS `ver_kardex`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `ver_kardex`  AS SELECT `kar`.`codigo_transaccion` AS `codigo_transaccion`, `kar`.`id_producto` AS `id_producto`, `pro`.`nombre` AS `nombre`, `pro`.`idAlmacen` AS `id_almacen`, `kar`.`id_operacion` AS `id_operacion`, `op`.`operacion` AS `operacion`, `kar`.`id_movimiento` AS `id_movimiento`, `mov`.`movimiento` AS `movimiento`, `kar`.`cantidad` AS `cantidad`, `kar`.`fecha_creacion` AS `fecha_creacion` FROM (((`kardex` `kar` join `productos` `pro` on(`pro`.`id_producto` = `kar`.`id_producto`)) join `operaciones` `op` on(`op`.`id_operacion` = `kar`.`id_operacion`)) join `movimientos` `mov` on(`mov`.`id_movimiento` = `kar`.`id_movimiento`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `ver_venta`
--
DROP TABLE IF EXISTS `ver_venta`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `ver_venta`  AS SELECT `v`.`id_venta` AS `id_venta`, `v`.`id_metodopago` AS `id_metodopago`, `mp`.`metodopago` AS `metodopago`, `v`.`id_cliente` AS `id_cliente`, `cl`.`razon_social` AS `razon_social`, `v`.`id_vendedor` AS `id_vendedor`, `vn`.`nombre_completo` AS `nombre_completo`, `v`.`id_tipocomprobante` AS `id_tipocomprobante`, (select coalesce(cast(sum(`detalle_ventas`.`total`) as decimal(18,2)),0) from `detalle_ventas` where `detalle_ventas`.`id_venta` = `v`.`id_venta`) AS `total_venta`, (select coalesce(cast(sum(`detalle_ventas`.`subtotal`) as decimal(18,2)),0) from `detalle_ventas` where `detalle_ventas`.`id_venta` = `v`.`id_venta`) AS `subtotal_venta`, (select coalesce(cast(sum(`detalle_ventas`.`igv`) as decimal(18,2)),0) from `detalle_ventas` where `detalle_ventas`.`id_venta` = `v`.`id_venta`) AS `igv_venta`, (select count(`detalle_ventas`.`id_detalleventa`) from `detalle_ventas` where `detalle_ventas`.`id_venta` = `v`.`id_venta`) AS `n_detalles`, `v`.`fecha_registro` AS `fecha_registro` FROM (((`venta` `v` left join `metodopago` `mp` on(`mp`.`id_metodopago` = `v`.`id_metodopago`)) left join `clientes` `cl` on(`cl`.`id_cliente` = `v`.`id_cliente`)) left join `vendedor` `vn` on(`vn`.`id_vendedor` = `v`.`id_vendedor`)) ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `almacen`
--
ALTER TABLE `almacen`
  ADD PRIMARY KEY (`id_almacen`);

--
-- Indices de la tabla `categorias`
--
ALTER TABLE `categorias`
  ADD PRIMARY KEY (`id_categoria`);

--
-- Indices de la tabla `clientes`
--
ALTER TABLE `clientes`
  ADD PRIMARY KEY (`id_cliente`),
  ADD UNIQUE KEY `ruc_dni` (`ruc`);

--
-- Indices de la tabla `detalle_ventas`
--
ALTER TABLE `detalle_ventas`
  ADD PRIMARY KEY (`id_detalleventa`),
  ADD KEY `id_producto` (`id_producto`),
  ADD KEY `id_venta` (`id_venta`);

--
-- Indices de la tabla `kardex`
--
ALTER TABLE `kardex`
  ADD PRIMARY KEY (`codigo_transaccion`),
  ADD KEY `id_producto` (`id_producto`),
  ADD KEY `id_operacion` (`id_operacion`),
  ADD KEY `kardex_ibfk_1` (`id_usuario`),
  ADD KEY `id_movimiento` (`id_movimiento`);

--
-- Indices de la tabla `metodopago`
--
ALTER TABLE `metodopago`
  ADD PRIMARY KEY (`id_metodopago`);

--
-- Indices de la tabla `movimientos`
--
ALTER TABLE `movimientos`
  ADD PRIMARY KEY (`id_movimiento`);

--
-- Indices de la tabla `operaciones`
--
ALTER TABLE `operaciones`
  ADD PRIMARY KEY (`id_operacion`);

--
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`id_producto`),
  ADD KEY `id_categoria` (`id_categoria`),
  ADD KEY `id_unidad` (`id_unidad`),
  ADD KEY `idAlmacen` (`idAlmacen`);

--
-- Indices de la tabla `tipo_comprobante`
--
ALTER TABLE `tipo_comprobante`
  ADD PRIMARY KEY (`id_comprobante`);

--
-- Indices de la tabla `token`
--
ALTER TABLE `token`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_usuario` (`id_usuario`);

--
-- Indices de la tabla `unidad`
--
ALTER TABLE `unidad`
  ADD PRIMARY KEY (`id_unidad`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `usuario` (`usuario`);

--
-- Indices de la tabla `vendedor`
--
ALTER TABLE `vendedor`
  ADD PRIMARY KEY (`id_vendedor`),
  ADD UNIQUE KEY `dni_proveedor` (`dni`) USING BTREE,
  ADD KEY `id_usuario` (`id_usuario`);

--
-- Indices de la tabla `venta`
--
ALTER TABLE `venta`
  ADD PRIMARY KEY (`id_venta`),
  ADD KEY `id_metodopago` (`id_metodopago`),
  ADD KEY `id_cliente` (`id_cliente`),
  ADD KEY `id_vendedor` (`id_vendedor`),
  ADD KEY `id_tipocomprobante` (`id_tipocomprobante`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `almacen`
--
ALTER TABLE `almacen`
  MODIFY `id_almacen` int(11) NOT NULL AUTO_INCREMENT COMMENT 'PK', AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `categorias`
--
ALTER TABLE `categorias`
  MODIFY `id_categoria` int(11) NOT NULL AUTO_INCREMENT COMMENT 'pk', AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT de la tabla `clientes`
--
ALTER TABLE `clientes`
  MODIFY `id_cliente` int(11) NOT NULL AUTO_INCREMENT COMMENT 'pk', AUTO_INCREMENT=47;

--
-- AUTO_INCREMENT de la tabla `detalle_ventas`
--
ALTER TABLE `detalle_ventas`
  MODIFY `id_detalleventa` int(11) NOT NULL AUTO_INCREMENT COMMENT 'PK', AUTO_INCREMENT=45;

--
-- AUTO_INCREMENT de la tabla `movimientos`
--
ALTER TABLE `movimientos`
  MODIFY `id_movimiento` int(11) NOT NULL AUTO_INCREMENT COMMENT 'llave primaria', AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `operaciones`
--
ALTER TABLE `operaciones`
  MODIFY `id_operacion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT de la tabla `productos`
--
ALTER TABLE `productos`
  MODIFY `id_producto` int(11) NOT NULL AUTO_INCREMENT COMMENT 'PK', AUTO_INCREMENT=36;

--
-- AUTO_INCREMENT de la tabla `tipo_comprobante`
--
ALTER TABLE `tipo_comprobante`
  MODIFY `id_comprobante` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `token`
--
ALTER TABLE `token`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT de la tabla `unidad`
--
ALTER TABLE `unidad`
  MODIFY `id_unidad` int(11) NOT NULL AUTO_INCREMENT COMMENT 'pk', AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT COMMENT 'pk', AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `vendedor`
--
ALTER TABLE `vendedor`
  MODIFY `id_vendedor` int(11) NOT NULL AUTO_INCREMENT COMMENT 'pk', AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT de la tabla `venta`
--
ALTER TABLE `venta`
  MODIFY `id_venta` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `detalle_ventas`
--
ALTER TABLE `detalle_ventas`
  ADD CONSTRAINT `detalle_ventas_ibfk_2` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE SET NULL ON UPDATE SET NULL,
  ADD CONSTRAINT `detalle_ventas_ibfk_3` FOREIGN KEY (`id_venta`) REFERENCES `venta` (`id_venta`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `kardex`
--
ALTER TABLE `kardex`
  ADD CONSTRAINT `kardex_ibfk_1` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `kardex_ibfk_2` FOREIGN KEY (`id_operacion`) REFERENCES `operaciones` (`id_operacion`),
  ADD CONSTRAINT `kardex_ibfk_3` FOREIGN KEY (`id_movimiento`) REFERENCES `movimientos` (`id_movimiento`),
  ADD CONSTRAINT `kardex_ibfk_4` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`);

--
-- Filtros para la tabla `productos`
--
ALTER TABLE `productos`
  ADD CONSTRAINT `productos_ibfk_1` FOREIGN KEY (`idAlmacen`) REFERENCES `almacen` (`id_almacen`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `productos_ibfk_2` FOREIGN KEY (`id_categoria`) REFERENCES `categorias` (`id_categoria`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `productos_ibfk_3` FOREIGN KEY (`id_unidad`) REFERENCES `unidad` (`id_unidad`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `token`
--
ALTER TABLE `token`
  ADD CONSTRAINT `token_ibfk_1` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `vendedor`
--
ALTER TABLE `vendedor`
  ADD CONSTRAINT `vendedor_ibfk_1` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL ON UPDATE SET NULL;

--
-- Filtros para la tabla `venta`
--
ALTER TABLE `venta`
  ADD CONSTRAINT `venta_ibfk_1` FOREIGN KEY (`id_vendedor`) REFERENCES `vendedor` (`id_vendedor`) ON DELETE SET NULL ON UPDATE SET NULL,
  ADD CONSTRAINT `venta_ibfk_2` FOREIGN KEY (`id_metodopago`) REFERENCES `metodopago` (`id_metodopago`) ON DELETE SET NULL ON UPDATE SET NULL,
  ADD CONSTRAINT `venta_ibfk_3` FOREIGN KEY (`id_cliente`) REFERENCES `clientes` (`id_cliente`),
  ADD CONSTRAINT `venta_ibfk_4` FOREIGN KEY (`id_tipocomprobante`) REFERENCES `tipo_comprobante` (`id_comprobante`) ON DELETE SET NULL ON UPDATE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
