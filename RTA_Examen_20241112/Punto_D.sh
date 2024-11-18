#!/bin/bash

# Creo las claves SSH por primera vez (por si el usuario no las tiene)
ssh-keygen -t ed25519 -N "" << OEF



OEF

# Sobreescribo las claves generadas para que este script pueda funcionar en usuarios con claves ya generadas
ssh-keygen -t ed25519 -N "" << OEF

y


OEF

sudo systemctl restart ssh


# Copio la clave pública en el archivo autorized_keys
cp $HOME/.ssh/id_ed25519.pub $HOME/.ssh/authorized_keys

# Guardo la ruta de la carpeta de ansible en una variable
RUTA_ANSIBLE=$(find $HOME -type d -name "202406" | awk 'NR==1')/ansible

ansible-galaxy role init $RUTA_ANSIBLE/roles/crear_estructura_directorios
ansible-galaxy role init $RUTA_ANSIBLE/roles/generar_archivos
ansible-galaxy role init $RUTA_ANSIBLE/roles/configurar_sudoers

# Crear la estructura de directorios
cat << EOF > $RUTA_ANSIBLE/roles/crear_estructura_directorios/tasks/main.yml
---
# tasks file for crear_estructura_directorios
- name: Crear directorio base
  file:
    path: /tmp/2do_parcial
    state: directory

- name: Crear subdirectorio alumno
  file:
    path: /tmp/2do_parcial/alumno
    state: directory

- name: Crear subdirectorio equipo
  file:
    path: /tmp/2do_parcial/equipo
    state: directory
EOF

# Dar las tareas
cat << EOF > $RUTA_ANSIBLE/roles/generar_archivos/tasks/main.yml
---
# tasks file for generar_archivos
- name: "Generar datos del alumno"
  template:
    src: "datos_alumno.txt.j2"
    dest: "/tmp/2do_parcial/alumno/datos_alumno.txt"

- name: "Generar datos del equipo"
  template:
    src: "datos_equipo.txt.j2"
    dest: "/tmp/2do_parcial/equipo/datos_equipo.txt"
EOF

mkdir -p $RUTA_ANSIBLE/roles/generar_archivos/templates
cat << EOF > $RUTA_ANSIBLE/roles/generar_archivos/templates/datos_alumno.txt.j2
Nombre: {{ nombre }} Apellido: {{ apellido }}
División: {{ division }}
EOF

cat << EOF > $RUTA_ANSIBLE/roles/generar_archivos/templates/datos_equipo.txt.j2
IP: {{ ansible_default_ipv4.address }}
Distribución: {{ ansible_facts.distribution }}
Cantidad de Cores: {{ ansible_processor_cores }}
EOF

mkdir -p $RUTA_ANSIBLE/roles/generar_archivos/vars
cat << EOF > $RUTA_ANSIBLE/roles/generar_archivos/vars/main.yml
---
# vars file for generar_archivos
nombre: "Lucas"
apellido: "Velasco"
division: "113-2°"
EOF

cat << EOF > $RUTA_ANSIBLE/roles/configurar_sudoers/tasks/main.yml
---
# tasks file for configurar_sudoers
- name: "Configuración de sudoers"
  lineinfile:
    path: /etc/sudoers
    line: '%2PSupervisores ALL=(ALL) NOPASSWD: ALL'
    validate: 'visudo -cf %s'
    state: present
EOF

cat << EOF > $RUTA_ANSIBLE/playbook.yml
---
- hosts: all

  tasks:
    - include_role:
        name: 2do_parcial
    
    - name: "Otra tarea"
      debug:
        msg: "Despues de la ejecucion del rol"

    - name: "ROL: crear_estructura_directorios"
      import_role:
        name: crear_estructura_directorios

    - name: "ROL: generar_archivos"
      import_role:
        name: generar_archivos

    - name: "ROL: configurar_sudoers"
      import_role:
        name: configurar_sudoers
EOF

cd $RUTA_ANSIBLE
ansible-playbook -i inventory playbook.yml
