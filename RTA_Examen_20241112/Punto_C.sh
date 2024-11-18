#!/bin/bash

sudo usermod -a -G docker $(whoami)

# Guardo la ruta de la carpeta de docker en una variable
RUTA_DOCKER=$(find $HOME -type d -name "202406" | awk 'NR==1')/docker

# Sobreescribo el index.html con mis datos
cat <<EOF > $RUTA_DOCKER/index.html
<div>
  <h1> Sistemas Operativos - UTNFRA </h1></br>
  <h2> 2do Parcial - Junio 2024 </h2> </br>
  <h3> Lucas Velasco</h3>
  <h3> División: 113-2°</h3>
</div>
EOF

# Creo el archivo Dockerfile
cat <<EOF > $RUTA_DOCKER/Dockerfile
FROM nginx:latest

COPY index.html /usr/share/nginx/html
EOF

# Guardo la ruta del volúmen lógico de docker y aumento su tamaño
LV_DOCKER=$(sudo fdisk -l | grep "lv_docker" | awk '{print $2}' | awk -F ':' '{print $1}')
sudo lvextend -L +200M $LV_DOCKER
sudo resize2fs $LV_DOCKER

# Voy a la carpeta de docker, construyo la imagen y luego etiqueto
cd $RUTA_DOCKER
docker build -t web1-velasco .
docker tag web1-velasco luvlsco/web1-velasco

# Creo el script, agrego el puerto y la imagen creada
cat <<EOF > $RUTA_DOCKER/run.sh
#!/bin/bash
docker run -d -p 8080:80 luvlsco/web1-velasco

EOF

# Pusheo la imagen a mi repositorio
docker push luvlsco/web1-velasco

# Cambio los permisos del script
chmod 755 $RUTA_DOCKER/run.sh

# Ejecuto el script
bash $RUTA_DOCKER/run.sh
