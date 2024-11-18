#!/bin/bash

cat << 'EOF' | sudo tee /usr/local/bin/VelascoAltaUser-groups.sh
#!/bin/bash

# Rutas de la consigna B:
# Ubicación: /usr/local/bin/<tu-apellido>AltaUser-Groups.sh
# Párametro 1: (Usuario del cual se obtendrá la clave)
# Párametro 2: <Path_Repo>/202406/bash_script/Lista_Usuarios.txt

# Obtener la clave del usuario (primer parámetro)
CLAVE_USUARIO=$(sudo cat /etc/shadow | grep "$1" | cut -d ':' -f 2)
echo "Clave de usuario $1: $CLAVE_USUARIO"

# Guardar la lista de usuarios desde el segundo parámetro
LISTA_USUARIOS=$(cat "$2")

# Procesar cada línea de Lista_Usuarios.txt, omitiendo los comentarios y la primera línea de cabecera
echo "$LISTA_USUARIOS" | awk -F ',' 'NR > 5 && NF == 3 {
    NOMBRE_USUARIO=$1
    GRUPO_PRIMARIO=$2
    DIRECTORIO_HOME=$3

    # Crear el grupo primario si no existe
    system("sudo groupadd -f " GRUPO_PRIMARIO)

    # Crear el usuario con su grupo y directorio, utilizando la contraseña original
    system("sudo useradd -m -s /bin/bash -c \"" NOMBRE_USUARIO "\" -p \"" CLAVE_USUARIO "\" -g " GRUPO_PRIMARIO " -d " DIRECTORIO_HOME " " NOMBRE_USUARIO)

    # Crear el directorio home si no existe y cambiar la propiedad
    system("sudo mkdir -p " DIRECTORIO_HOME)
    system("sudo chown " NOMBRE_USUARIO ":" GRUPO_PRIMARIO " " DIRECTORIO_HOME)
}'

EOF

# Permisos de ejecución (Por las dudas)
sudo chmod 755 /usr/local/bin/VelascoAltaUser-groups.sh

# Ejecución del script con mi apellido
sudo -E bash /usr/local/bin/VelascoAltaUser-groups.sh $(whoami) $HOME/repogit/UTNFRA_SO_2do_Parcial_Velasco/202406/bash_script/Lista_Usuarios.txt
