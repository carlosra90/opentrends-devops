
# opentrends-devops
 - El repositorio se encuentra modularizado. Para Descargar este proyecto ejecutar el siguiente comando:
 ```
git clone --branch [dev|main] --recurse-submodules https://github.com/carlosra90/opentrends-devops.git
git submodule foreach git checkout [dev|main]
 ```
 - para lanzar el despliegue de api-builder o builder seguir las instrucciones del script deploy.sh; ejecutando el mismo 
 ```
sh deploy.sh --help o ./deploy.sh --help
 ```
 - Para los Ingress se asume el uso de nginx-ingress y su class-name "nginx" en caso de cambiar el class-name, modificar el ingress previo o posterior la instalación
 - para la Persistencia de Datos se usa H2 en ram, al momento de ejecutar el api-builder leer consola y se tendrá las url de acceso
