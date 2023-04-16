# sistema-conversion-cloud
Sistema que convierte un archivo de un tipo a otro


## Commands

Abra una terminal en la raíz del proyecto y ejecute lo siguiente para el desarrollo local:
```shell
docker-compose -f local.yml build
```

Y luego ejecuta:
```shells
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

## Commands for docker metrics with prometheus and grafana

```shell
docker-compose -f local.test.yml build
```

```shell
docker-compose -f local.test.yml up
```

or this for arm64

```shell
docker-compose -f local.arm.test.yml build
```
```shell
docker-compose -f local.arm.test.yml up
```


### Locust

```shell
docker-compose -f local.yml run -p 8089:8089 --rm locust -f /mnt/locust/locustfile.py --host=http://nginx:80
```

or with headless

```shell
docker-compose -f local.yml run --rm locust -f /mnt/locust/locustfile.py --host=http://nginx:80 --headless -u 100 -r 5
```
