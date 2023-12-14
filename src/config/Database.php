<?php


class Database {
  private $host='';
  private $port='';
  private $db='';
  private $user='';
  private $pass='';

  public function __construct() {
    $this->host = 'localhost';
    $this->port ='3306';
    $this->db   = 'api_maestria';
    $this->user = 'root';
    $this->pass = '';
  }

  public function connect(){
    try {
        $dbConnection = new PDO( 
          "mysql:host=$this->host;port=$this->port;dbname=$this->db",
          $this->user, $this->pass
        );
        return $dbConnection;
    } catch (PDOException $e) {
      exit($e->getMessage());
    }
    
  }
}