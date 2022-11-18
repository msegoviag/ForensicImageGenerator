#!/bin/bash
#Author: Miguel Segovia Gil
# Utilidad para la asignatura de Análisis Forense del Master FP Ciberseguridad PTA CAMPANILLAS.
# Permite obtener una imagen forense de cualquier disco o fichero, obtener el hash y comprimir la imagen.
# Ejemplo de uso con parámetros: sudo ./ForensicImageGenerator.sh /dev/sdb1 sdb1.img md5sum y
# Si ejecutas ./ForensicImageGenerator.sh sin parámetros se abrirá el modo asistente.
# chmod +x para añadir permiso de ejecución al fichero. 
# Se necesita sudo ./ForensicImageGenerator.sh o root para analizar dispositivos sdxx

checkArgsAndFileExist() {

    if ! [[ -b "$pathDevice" || -f "$pathDevice" || -d "$pathDevice" ]]; then
        echo "El dispositivo $pathDevice no se encuentra en la ruta especificada o no es posible procesarlo."
        return
    fi

    if choosingCheckSum $1; then
        forensicImageGenerator
    else
        echo -e "Hash criptográfico de suma NO aceptado, intenta los siguientes\n -md5sum\n -sha1sum\n -sha224sum\n -shasha256\n -sha512sum\n -b2sum\n -cksum\n -sum"
        return
    fi

}

choosingCheckSum() {

    checkSumType=("md5sum" "sha1sum" "sha224sum" "sha256sum"
        "sha512sum" "b2sum" "cksum" "sum")

    if printf '%s\0' "${checkSumType[@]}" | grep -Fxqz -- "$hashtype"; then
        return 0
    else
        return 1
    fi

}

forensicImageGenerator() {

    echo "Creando imagen forense de $pathDevice..."

    case $compression in
    Yes | yes | Y | y)
        if dd if=$pathDevice status=progress | gzip -c -9 >"$(dirname $destinationForenseFile)/$(basename $destinationForenseFile.gz)" |
            $hashtype >"$(dirname $destinationForenseFile)/hash.log"; then
            echo "Imagen forense creada: $destinationForenseFile"
            echo "Se ha comprimido la imagen forense: $(basename $destinationForenseFile.gz) "
            echo "Imagen forense con hash: $(cat hash.log)"
        else
            echo "Error al crear imagen forense, verifica que la ruta de destino existe y tenga los permisos requeridos."
        fi
        ;;

    No | no | N | n)
        if dd if=$pathDevice of=$destinationForenseFile status=progress |
            $hashtype >"$(dirname $destinationForenseFile)/hash.log"; then
            echo "Imagen forense creada: $destinationForenseFile"
            echo "Imagen forense con hash: $(cat hash.log)"
        else
            echo "Error al crear imagen forense, verifica que la ruta de destino existe y tenga los permisos requeridos."
        fi
        ;;
    *)
        echo "$compression parámetro no válido, introduce y / n para indicar si deseas comprimir la imagen forense."
        ;;

    esac

}

pathDevice=''
destinationForenseFile=''
hashtype=''
compression=''

if ! [ $# -ne 4 ]; then
    pathDevice=$1
    destinationForenseFile=$2
    hashtype=$3
    compression=$4
    checkArgsAndFileExist

fi

if [ $# -eq 0 ]; then
    read -p "Introduce ruta dispositivo origen: " pathDevice
    read -p "Introduce ruta de destino: " destinationForenseFile
    read -p "Elige el tipo de hash (md5sum, sha1sum, sha256sum, sha512sum): " hashtype
    read -p "¿Requiere compresión? y/n: " compression
    checkArgsAndFileExist

fi

if (($# > 0)) && (($# < 4)) || (($# >= 5)); then
    echo "Debes introducir únicamente 4 argumentos: ./$(basename "$0") [ruta dispositivo] [ruta dispositivo] [checksum] [compresion(y/n)]"
fi
