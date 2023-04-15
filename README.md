# sistema-conversion-cloud
Sistema que convierte un archivo de un tipo a otro


## Commands

Abra una terminal en la raíz del proyecto y ejecute lo siguiente para el desarrollo local:
```shell
docker-compose -f local.yml build
```

Y luego ejecuta:
```shell
docker-compose -f local.yml up
```

Este comando se utiliza para inicializar una base de datos en una aplicación Flask que se ejecuta dentro de un contenedor Docker.
```shell
docker-compose -f local.yml run --rm app flask db init
```

Este comando se utiliza para generar un archivo de migración en una aplicación Flask que utiliza la extensión Flask-Migrate.
```shell
docker-compose -f local.yml run --rm app flask db migrate
```


Este comando se utiliza para aplicar una migración a la base de datos en una aplicación Flask que utiliza la extensión Flask-Migrate
```shell
docker-compose -f local.yml run --rm app flask db upgrade
```


