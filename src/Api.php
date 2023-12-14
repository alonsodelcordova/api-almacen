
<?php
use Api\Routes\ProductsRoute;
use Api\Routes\UsuarioRoute;
use Api\Routes\CategoriaRoute;
use Api\Routes\AlmacenRoute;
use Api\Routes\UnidadMedidaRoute;
use Api\Routes\ClienteRoute;
use Api\Routes\MovimientoRoute;
use Api\Routes\SeguridadRoute;
use Api\Routes\VentasRoute;

class Api{
    
    protected $controladores = [
        'productos', 'usuarios', 'ventas', 'clientes', 'proveedores', 
        'categorias', 'almacenes', 'compras', 'unidad-medida', 'movimientos',
        'seguridad'
    ];

    public function __constructor(){

    }

    public function ExistsController(string $route):bool{
        return in_array($route, $this->controladores);
    }   

    public function callRoute($route) {
        if($route == 'productos') {
            $product = new ProductsRoute();
            $product->MainProductos();
        }

        if($route == 'usuarios') {
            $usuario = new UsuarioRoute();
            $usuario->MainUsuarios();
        }

        if($route == 'categorias') {
            $categoria = new CategoriaRoute();
            $categoria->MainCategorias();
        }

        if($route == 'almacenes') {
            $almacen = new AlmacenRoute();
            $almacen->MainAlmacenes();
        }
        
        if($route == 'unidad-medida') {
            $unidades = new UnidadMedidaRoute();
            $unidades->MainUnidades();
        }
        if($route == 'clientes') {
            $cliente = new ClienteRoute();
            $cliente->MainClientes();
        }
        if($route == 'movimientos') {
            $movimiento = new MovimientoRoute();
            $movimiento->MainMovimiento();
        }
        if($route == 'seguridad') {
            $seguridad = new SeguridadRoute();
            $seguridad->MainUnidades();
        }
        if($route == 'ventas') {
            $ventas = new VentasRoute();
            $ventas->MainAlmacenes();
        }
    }    

}
