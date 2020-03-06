#!/bin/bash

# @title: FCFS - Según Necesidades - Memoria No Continua - Memoria No Reubicable
# @author: Iván Ruiz Gázquez <a>ivanaluubu@gmail.com</a>
# @version: 2019-2020
#
# El código se ha hecho de la forma más óptima para que la revisión del
# mismo sea lo más sencilla prosible, lo único que hay que hacer es ir bajando en las
# llamadas de las funciones para cambiar lo que se quiera. Se observará entonces que
# hay muchas variables que cambian la estética, como el tipo de marco, colores, etc.
# Esto es para testeo de distintas opciones pero si se quiere cambiar, se deja a gusto
# del siguiente programador :)
# pd:no hay variables globales, yihaaa!
#
# Consejo útil, en VSCODE usa ctr + k + 0 para hacer collapse de las funciones
# y ctr + k + j para hacer expand

######################## 1. ASIGNACION DE DATOS

# Almacen de los estilos de las tablas con sus códigos ASCII
# @param Numero de estilo
# ----------------------------------
function asignarEstiloGeneral() {
  local estilo1=("═" "╔" "╠" "╚" "╦" "╬" "╩" "╗" "╣" "╝" "║")
  local estilo2=("─" "╭" "├" "╰" "┬" "┼" "┴" "╮" "┤" "╯" "│")
  local estilo3=("━" "┏" "┣" "┗" "┳" "╋" "┻" "┓" "┫" "┛" "┃")

  case "$1" in
  1)
    estiloGeneral=("${estilo1[@]}")
    ;;
  2)
    estiloGeneral=("${estilo2[@]}")
    ;;
  3)
    estiloGeneral=("${estilo3[@]}")
    ;;
  *)
    estiloGeneral=("${estilo3[@]}")
    ;;
  esac
}

# Devuelve los datos extraidos del archivo de configuracion
# @param parametro a leer del config
# ----------------------------------
function extraerDeConfig() {
  local salida

  # Lee el config y devuelve la linea solicitada
  # ----------------------------------
  function leeConfig() {
    grep -o '".*"' "$configFile" | sed 's/"//g' | head -"$1" | tail -1
  }

  # Lee el config si es un array
  # ----------------------------------
  function leeConfigArray() {
    grep -o '".*"' "$configFile" | head -"$1" | tail -1 | tr -d ","
  }

  if [ "$1" == "introduccion" ]; then
    local salidaArray
    salida="$(leeConfigArray "1")"
    salida+=" "
    salida+="$(leeConfigArray "2")"

    declare -a "salidaArray=( $(echo "$salida" | tr '`$<>' '????') )"
    for ((i = 0; i < ${#salidaArray[@]}; i++)); do
      echo "${salidaArray[$i]}"
      if [[ "$i" == "2" || "$i" == "4" ]]; then
        echo " "
      fi
    done
  else
    case "$1" in
    error)
      salida=$(leeConfig "3")
      ;;
    acierto)
      salida=$(leeConfig "4")
      ;;
    advertencia)
      salida=$(leeConfig "5")
      ;;
    archivoSalida)
      salida=$(leeConfig "6")
      ;;
    archivoEntrada)
      salida=$(leeConfig "7")
      ;;
    esac

    echo "$salida"
  fi
}

######################## 2. MENU Y ENTRADA DE DATOS

# Funcion tipo de entrada de datos comun a todas las peticiones del programa
# ----------------------------------
function recibirEntrada() {
  local mensaje
  mensaje="$(printf "\n$(cc Neg 3)%15s$(fc)" "Respuesta:")"

  read -r -p "$mensaje "
  echo "$REPLY"
}

# Funcion para elegir el tipo de entrada de datos
# @param archivo externo para la opcion de archivo
# ----------------------------------
function elegirTipoDeEntrada() {
  local tipo
  local opcionesEntrada
  opcionesEntrada=(
    "1.- Entrada manual por teclado"
    "2.- Entrada automática por archivo"
    "3.- Entrada automática con valores aleatorios"
    "4.- Ayuda"
    "0.- Salir"
  )

  centrarEnPantalla "$(imprimirCuadro "50" "default" "MENÚ PRINCIPAL")" | sacarHaciaArchivo "$archivoSalida" -a
  centrarEnPantalla "$(imprimirCuadro "50" "0" "${opcionesEntrada[@]}")" | sacarHaciaArchivo "$archivoSalida" -a
  tipo=$(recibirEntrada)

  while [[ ! "$tipo" =~ ^[0-4]$ ]]; do
    centrarEnPantalla "$(imprimirCuadro "80" "error" "Inserta un valor numérico entre 0 y 4")"
    tipo=$(recibirEntrada)
  done

  # Funcion que imprime el tipo de asignacion al archivo,
  # para posterior conocimiento
  # ----------------------------------
  function guardaTipoEnArchivo() {
    centrarEnPantalla "$(imprimirCuadro "50" "blanco" "Asignación de datos $1")" >>"$archivoSalida"
  }

  case "$tipo" in
  1)
    guardaTipoEnArchivo "manual"
    asignarManual
    ;;
  2)
    guardaTipoEnArchivo "automática desde archivo"
    asignarDesdeArchivo "$1"
    ;;
  3)
    guardaTipoEnArchivo "aleatoria"
    asignarValoresAleatorios
    ;;
  4)
    imprimirAyuda
    ;;
  0)
    centrarEnPantalla "$(imprimirCuadro "60" "advertencia" "Ha salido del programa mediante el menú de opciones")" | sacarHaciaArchivo "$archivoSalida"
    exit 99
    ;;
  *)
    centrarEnPantalla "$(imprimirCuadro "100" "error" "Ha ocurrido algún tipo de error")" | sacarHaciaArchivo "$archivoSalida" -a
    exit 99
    ;;
  esac
}

# Asigna valores en el array de forma manual
# ----------------------------------
function asignarManual() {
  local masProcesos

  # Comprueba si la entrada pasada es entero
  # @param Numero a comprobar
  # @param Minimo entero válido
  # ----------------------------------
  function entradaEsEntero() {
    if [[ "$1" =~ ^[0-9]+$ ]] && [[ "$1" -ge "$2" ]]; then
      echo "true"
    fi
  }

  # Comprueba si la entrada pasada es un string valido
  # ----------------------------------
  function entradaEsStringValido() {
    if [[ "$1" =~ [A-Za-z] ]]; then
      echo "true"
    fi
  }

  # Imprime tabla limpia
  # ----------------------------------
  function comienzoPregunta() {
    clear
    centrarEnPantalla "$(imprimirCuadro "50" "blanco" "$2")"
    centrarEnPantalla "$(imprimirTabla "$1" "4")"
  }

  # Guarda el tamaño de la memoria
  # ----------------------------------
  function tamMemoria() {
    clear
    centrarEnPantalla "$(imprimirCuadro "50" "blanco" "Tamaño de la memoria")"
    MEM_TAM=$(recibirEntrada)

    while [[ $(entradaEsEntero "$MEM_TAM" "1") != "true" ]]; do
      centrarEnPantalla "$(imprimirCuadro "80" "error" "Valor de tamaño de memoria no válido, mayor que 0")"
      MEM_TAM=$(recibirEntrada)
    done
  }

  # Guarda el nombre del proceso i
  # ----------------------------------
  function guardarNombreDelProceso() {
    local nombre

    comienzoPregunta "$1" "Nombre del proceso $1"
    nombre=$(recibirEntrada)

    # Comprueba si el nombre esta repetido
    function estaRepetido() {
      local nombreRepetido="false"
      for ((i = 0; i < NUM_FIL; i++)); do
        if [ "$nombre" == "${array[$PROC_NUM, $i]}" ]; then
          nombreRepetido="true"
        fi
      done

      echo "$nombreRepetido"
    }

    while [[ $(entradaEsStringValido "$nombre") != "true" ]] || [[ "$(estaRepetido)" == "true" ]]; do
      centrarEnPantalla "$(imprimirCuadro "80" "error" "Nombre del proceso erróneo, al menos una letra y no repetido")"
      nombre=$(recibirEntrada)
    done

    array[$PROC_NUM, $1]="$nombre"
  }

  # Guarda el tiempo de llegada del proceso i
  # ----------------------------------
  function guardarLlegadaProceso() {
    local llegada

    comienzoPregunta "$1" "Llegada del proceso $1"
    llegada=$(recibirEntrada)

    while [[ $(entradaEsEntero "$llegada" "0") != "true" ]]; do
      centrarEnPantalla "$(imprimirCuadro "80" "error" "Valor de llegada del proceso no válido, entero 0 o mayor")"
      llegada=$(recibirEntrada)
    done

    array[$PROC_LLE, $1]="$llegada"
  }

  # Guarda el tiempo de ejecucion del proceso i
  # ----------------------------------
  function guardarTiempoEjecucion() {
    local ejecucion

    comienzoPregunta "$1" "Tiempo ejecución proceso $1"
    ejecucion=$(recibirEntrada)

    while [[ $(entradaEsEntero "$ejecucion" "1") != "true" ]]; do
      centrarEnPantalla "$(imprimirCuadro "80" "error" "Valor de tiempo de ejecución no válido, entero mayor que 0")"
      ejecucion=$(recibirEntrada)
    done

    array[$PROC_EJE, $1]="$ejecucion"
  }

  # Guarda el tiempo de ejecucion del proceso i
  # ----------------------------------
  function guardarTamMemoria() {
    local tam

    comienzoPregunta "$1" "Tamaño del proceso $1 - (Memoria: $MEM_TAM)"
    tam=$(recibirEntrada)

    while [[ $(entradaEsEntero "$tam" "1") != "true" ]]; do
      centrarEnPantalla "$(imprimirCuadro "80" "error" "Valor de tiempo de tamaño no válido, entero mayor que 0")"
      tam=$(recibirEntrada)
    done

    if [[ "$tam" -gt "$MEM_TAM" ]]; then
      centrarEnPantalla "$(imprimirCuadro "80" "advertencia" "⚠ ¡El tamaño del proceso es mayor que la memoria! No podrá ejecutarse ⚠")"
      avanzarAlgoritmo
    fi

    array[$PROC_TAM, $1]="$tam"
  }

  # Comprueba si queremos introducir más procesos
  # ----------------------------------
  function comprobarSiMasProcesos() {
    local temp

    comienzoPregunta "$1" "¿Quieres introducir otro proceso? [S/N]"
    temp=$(recibirEntrada)

    while [[ ! "$temp" =~ ^([sS][iI]|[sS]|[nN][oO]|[nN])$ ]]; do
      centrarEnPantalla "$(imprimirCuadro "80" "error" "Entrada de datos errónea")"
      temp=$(recibirEntrada)
    done

    if [[ $temp =~ [nN][oO]|[nN] ]]; then
      masProcesos="false"
    elif [[ $temp =~ [sS][iI]|[sS] ]]; then
      ((NUM_FIL++))
    fi
  }

  # Main de la asignación manual
  # ----------------------------------
  NUM_FIL="1"
  tamMemoria
  while [[ "$masProcesos" != "false" && "$NUM_FIL" -lt "100" ]]; do
    guardarNombreDelProceso "$NUM_FIL"
    guardarLlegadaProceso "$NUM_FIL"
    guardarTiempoEjecucion "$NUM_FIL"
    guardarTamMemoria "$NUM_FIL"
    comprobarSiMasProcesos "$NUM_FIL"
  done
}

# Devuelve los datos del archivo de entrada en un array
# ----------------------------------
function asignarDesdeArchivo() {
  local archivo
  archivo=$(dirname "$0")
  archivo+="/$1"

  # Si hay algun error
  [ ! -f "$archivo" ] && {
    centrarEnPantalla "$(imprimirCuadro "100" "error" "Archivo no encontrado")" | sacarHaciaArchivo "$archivoSalida" -a
    avanzarAlgoritmo
    elegirTipoDeEntrada "$archivoEntrada"
  }

  # Leer todas las lineas y guardar los datos por columnas en el array
  # Valor -1 para saltarnos la primera linea
  local i
  i="-1"

  # Separador para leer datos
  IFS=","

  while read -r proceso llegada ejecucion tam; do

    if [ "$i" == "-1" ]; then
      MEM_TAM="$(cut -d "=" -f 2 <<<"$proceso")"
    elif [[ "$i" -ge "1" && "$i" -lt "100" ]]; then
      array[$PROC_NUM, $i]=$proceso
      array[$PROC_LLE, $i]=$llegada
      array[$PROC_EJE, $i]=$ejecucion
      array[$PROC_TAM, $i]=$tam
    fi
    ((i++))
  done <"$archivo"

  # Leemos ultima linea
  array[$PROC_NUM, $i]=$proceso
  array[$PROC_LLE, $i]=$llegada
  array[$PROC_EJE, $i]=$ejecucion
  array[$PROC_TAM, $i]=$tam

  NUM_FIL="$((i))"
}

# Crea un array con valores aleatorio para fase desarrollo o entrada
# de datos automatica, (ni manual ni por archivo)
# @param Numero de filas a generar de manera aleatorio (num. proceos)
# ----------------------------------
function asignarValoresAleatorios() {
  local numValAleatorios

  # Tamaño de memoria aleatorio
  MEM_TAM=$(((RANDOM % 20) + 5)) # 5-20

  clear
  centrarEnPantalla "$(imprimirCuadro "50" "blanco" "¿Cuántos valores aleatorios quieres generar?")" | sacarHaciaArchivo "$archivoSalida" -a
  numValAleatorios=$(recibirEntrada)

  while [[ ! "$numValAleatorios" =~ ^[0-9]+$ || "$numValAleatorios" -lt "1" || "$numValAleatorios" -ge "100" ]]; do
    centrarEnPantalla "$(imprimirCuadro "80" "error" "Inserta un valor numérico entre 1 y 99, recomendamos menos de 30")"
    numValAleatorios=$(recibirEntrada)
  done

  NUM_FIL=$numValAleatorios

  # Solo ponemos aleatorios los 4 primeros atributos, que son los que meteria el usuario por teclado
  for ((i = 1; i <= 4; i++)); do
    for ((j = 1; j <= NUM_FIL; j++)); do
      case "$i" in
      1)
        if [[ "$j" -lt "10" ]]; then
          array[$i, $j]="P0"${j} # Nombre
        else
          array[$i, $j]="P"${j}
        fi
        ;;
      2)
        array[$i, $j]=$((RANDOM % 20)) # Llegada [0-20]
        ;;
      3)
        array[$i, $j]=$(((RANDOM % 20) + 1)) # Ejecucion

        ;;
      4)
        array[$i, $j]=$(((RANDOM % (MEM_TAM + 2)) + 1)) # Tamaño
        ;;
      esac
    done
  done
}

# Ayuda del algoritmo
# ----------------------------------
function imprimirAyuda() {
  local ayuda
  local funciona
  funciona=(
    "Algoritmo FCFS según necesidades memoria no reubicable memoria no continua"
    " "
    "Este algoritmo funciona introduciendo los procesos en CPU según el orden de llegada de los mismos."
    "Se ejecutarán los procesos siempre que entren en memoria, en caso contrario quedarán bloqueados"
  )
  ayuda=(
    "Puedes introducir los datos de tres formas:"
    " "
    "- Forma manual: Inserta el valor de memoria y despues todos los procesos uno a uno"
    "- Forma automática desde archivo: Introduce los datos desde el archivo externo de datos"
    "- Forma automática: Asigna todos los valores de forma automática"
  )

  clear
  centrarEnPantalla "$(imprimirCuadro "50" "default" "AYUDA")" | sacarHaciaArchivo "$archivoSalida" -a
  centrarEnPantalla "$(imprimirCuadro "150" "random" "${funciona[@]}")" | sacarHaciaArchivo "$archivoSalida" -a
  centrarEnPantalla "$(imprimirCuadro "150" "random" "${ayuda[@]}")" | sacarHaciaArchivo "$archivoSalida" -a
  read -r -p "$(centrarEnPantalla "$(imprimirCuadro "35" "default" "Pulsa intro para volver al menú")")"
  clear
  elegirTipoDeEntrada "$archivoEntrada"
}

######################## 3. ALGORITMO
# Imprime el uso de la memoria según los procesos en ella
# ----------------------------------
function imprimirMemoria() {
  local -a coloresMemoria
  local colorVacio
  local espacios
  espacios="   "

  # Guarda los colores aleatorios de la memoria
  # ----------------------------------
  function asignarColores() {
    colorVacio="$(cc Neg blanco)" # Cuando la memoria esta vacia debe ser blanco
    for ((i = 1; i <= NUM_FIL; i++)); do
      coloresMemoria[$i]=$(cc Neg "$((i + 4))")
    done
  }

  # Si hay algún cambio que altere la memoria, la  cambiamos, si no la imprimimos como estaba
  # para no mover los procesos, ya que no es reubicable
  # ----------------------------------
  function comprobarMovimientosDeMemoria() {
    local -i posicion

    for ((i = 1; i <= NUM_FIL; i++)); do
      # Si algún proceso ha pasado de Fuera a En Memoria o Ejecutando -> Entra en los huecos
      if [[ "${arrayCopia[$PROC_EST, $i]}" == "${estados[0]}" ]] && [[ "${array[$PROC_EST, $i]}" == "${estados[2]}" || "${array[$PROC_EST, $i]}" == "${estados[4]}" ]]; then
        # Vamos añadiendolo a los huecos que están vacios
        for ((tamProc = 0; tamProc < array[$PROC_TAM, $i]; tamProc++)); do
          posicion="0"
          while [[ "${procesosEnMemoria[posicion]}" != "$stringVacio" ]]; do
            ((posicion++))
          done
          # Guardamos la ID para igualar colores
          procesosEnMemoria[$posicion]="$i"
        done
      # Si algún proceso pasa de Ejecutando a Terminado (lo contrario) -> Sale de los huecos
      elif [[ "${arrayCopia[$PROC_EST, $i]}" == "${estados[4]}" ]] && [[ "${array[$PROC_EST, $i]}" == "${estados[5]}" ]]; then
        # Quitar del dibujo y ponerlo en hueco vacio
        # vamos añadiendolo a los huecos que están vacios
        for ((j = 0; j < MEM_TAM; j++)); do
          if [[ "${procesosEnMemoria[$j]}" == "$i" ]]; then
            procesosEnMemoria[$j]="$stringVacio"
          fi
        done
      fi
    done
  }

  # Imprime cuadro de memoria o nulo si no hay nada que imprimir
  # ----------------------------------
  function imprimir() {
    printf "%s" "${procesosEnMemoria[@]}"
    printf "\n"
    for ((pos = 0; pos < MEM_TAM; pos++)); do
      if [[ "${procesosEnMemoria[$pos]}" == "$stringVacio" ]]; then
        printf "$colorVacio%s$(fc)" "$espacios"
      else
        local idProceso="${procesosEnMemoria[$pos]}"
        printf "${coloresMemoria[$idProceso]}%s$(fc)" "$espacios"
      fi
    done
  }

  # Main de cuadro de memoria
  # ----------------------------------
  asignarColores
  comprobarMovimientosDeMemoria
  imprimir
}

# Imprime la linea de procesos de CPU
# @param Instante actual
# ----------------------------------
function imprimirLineaProcesos() {
  local -a coloresLinea
  local terminalWidth
  terminalWidth="$(tput cols)"

  # Guarda los colores aleatorios de la linea
  # ----------------------------------
  function asignarColores() {
    for ((i = 1; i <= NUM_FIL; i++)); do
      coloresLinea[$i]=$(cc Neg "$((i + 4))")
    done
  }

  # Imprime lineas de procesos
  # ----------------------------------
  function imprimirLineas() {
    printf "${coloresLinea[$i]}%s" ""
    printf " %s %s " "${array[$PROC_ESP, $i]}" "${array[$PROC_NUM, $i]}"
    printf "%*s" "$((array[$PROC_EJE, $i] - array[$PROC_EJE_RES, $i]))" ""
    if [[ "${array[$PROC_EST, $i]}" == "${estados[5]}" ]]; then
      printf " %s " "${array[$PROC_RES, $i]}"
    elif [[ "${array[$PROC_EST, $i]}" == "${estados[4]}" ]]; then
      printf " %s " "$1"
    fi
    printf "$(fc)%s" ""
  }

  # Imprimir si no hay procesos en la linea
  # ----------------------------------
  function imprimirVacio() {
    imprimirCuadro "100" "advertencia" "$(printf "%s" "⚠ No hay procesos ejecutando o ya terminados ⚠")"
  }

  # Imprime la linea de procesos en la CPU
  # @param Instante
  # ----------------------------------
  function imprimir() {
    local procesosAMostrar
    procesosAMostrar="0"

    for ((i = 1; i <= NUM_FIL; i++)); do
      if [[ "${array[$PROC_EST, $i]}" == "${estados[5]}" || "${array[$PROC_EST, $i]}" == "${estados[4]}" ]]; then
        ((procesosAMostrar++))
        imprimirLineas "$1"
      fi
    done

    if [[ "$procesosAMostrar" == "0" ]]; then
      imprimirVacio
    fi
  }

  # Main de cuadro de memoria
  # ----------------------------------
  asignarColores
  imprimir "$1"
}

# Asigna los estados de los procesos
# ----------------------------------
function asignarDatosInicial() {
  for ((i = 1; i <= NUM_FIL; i++)); do
    array[$PROC_EST, $i]="Fuera"
    array[$PROC_EJE_RES, $i]="${array[$PROC_EJE, $i]}"
    array[$PROC_RES, $i]="-"
    array[$PROC_ESP, $i]="-"
  done
}

# Función que calcula la memoria restante
# ------------------------------------------------
function calcularMemoriaRestante() {
  MEM_USE="0"

  for ((k = 0; k <= NUM_FIL; k++)); do
    if [[ "${array[$PROC_EST, $k]}" == "${estados[2]}" || "${array[$PROC_EST, $k]}" == "${estados[4]}" ]]; then
      MEM_USE+="${array[$PROC_TAM, $k]}"
    fi
  done
}

# Asigna los estados segun avanza el algoritmo
# ----------------------------------
function asignarEstadosSegunInstante() {
  local -i instante="$1"
  local procesoEjecutando="false"
  local ningunProcesoEnCola="true"
  local memRestante

  # Asignamos los estados segun varias cosas, que el proceso haya llegado (llegada <= instante), que quepa en memoria (en los huecos que queden) y que no haya finalizado
  for ((i = 1; i <= NUM_FIL; i++)); do

    memRestante=$((MEM_TAM - MEM_USE))

    # Fuera
    if [[ "${array[$PROC_EST, $i]}" == "${estados[0]}" ]]; then
      if [[ "${array[$PROC_LLE, $i]}" -le "$instante" ]]; then
        array[$PROC_EST, $i]="${estados[1]}"
      fi
    fi

    # En Espera
    if [[ "${array[$PROC_EST, $i]}" == "${estados[1]}" ]]; then
      # Si ningun proceso anterior esta en espera, ejecutamos

      for ((cola = 1; cola < i; cola++)); do
        if [[ "${array[$PROC_EST, $cola]}" == "${estados[1]}" ]]; then
          ningunProcesoEnCola="false"
        fi
      done

      if [[ "$ningunProcesoEnCola" == "true" ]]; then
        if [[ "${array[$PROC_TAM, $i]}" -gt "$MEM_TAM" ]]; then
          array[$PROC_EST, $i]="${estados[3]}"
        elif [[ "${array[$PROC_TAM, $i]}" -le "$memRestante" ]]; then
          array[$PROC_EST, $i]="${estados[2]}"
        fi
      fi
    fi

    # En Memoria
    if [[ "${array[$PROC_EST, $i]}" == "${estados[2]}" ]]; then
      for ((j = 1; j <= NUM_FIL; j++)); do
        if [[ "${array[$PROC_EST, $j]}" == "${estados[4]}" ]]; then
          procesoEjecutando="true"
        fi
      done

      if [[ "$procesoEjecutando" != "true" ]]; then
        array[$PROC_EST, $i]="${estados[4]}"
        array[$PROC_ESP, $i]="$((instante - array[$PROC_LLE, $i]))"
      fi
    fi

    # Ejecutando
    if [[ "${array[$PROC_EST, $i]}" == "${estados[4]}" ]]; then
      if [[ "${array[$PROC_EJE_RES, $i]}" == "0" ]]; then
        array[$PROC_EST, $i]="${estados[5]}"
        array[$PROC_RES, $i]="$((instante - array[$PROC_LLE, $i]))" # Que coincide con el tiempo de ejcución por ser FCFS
      fi
    fi

    calcularMemoriaRestante
  done
}

# Comprueba si el programa ha acabado
# ----------------------------------
function procesosHanTerminado() {
  local procHanTerminado="true"

  for ((i = 1; i <= NUM_FIL; i++)); do
    if [[ "${array[$PROC_EST, $i]}" != "${estados[5]}" && "${array[$PROC_EST, $i]}" != "${estados[3]}" ]]; then
      procHanTerminado="false"
    fi
  done

  echo "$procHanTerminado"
}

# Comprueba los procesos que se estan ejecutando
# ----------------------------------
function comprobarProcesosEjecutando() {
  for ((i = 1; i <= NUM_FIL; i++)); do
    if [[ "${array[$PROC_EST, $i]}" == "${estados[4]}" ]]; then
      ((array[$PROC_EJE_RES, $i]--))
    fi
  done
}

######################## 4. OTRAS FUNCIONES UTILES USADAS EN TODO EL PROGRAMA

# Saca la información del comando que acompaña
# @param "-a" para append
# ----------------------------------
function sacarHaciaArchivo() {
  local archivo
  archivo=$(dirname "$0")
  archivo+="/$1"

  if [ "$2" == "-a" ]; then
    tee -a "$archivo"
  else
    tee "$archivo"
  fi
}

# Devuelve la expresión completa de color, pasándole los parámetros
# que queremos en orden
# @param tipoEspecial (Negrita=Neg, Subrayado=Sub, Normal=Nor, Parpadeo=Par)
# @param (valor random, default,  error, acierto, fg aleatorio sobre bg negro
# o lista de colores en orden)
# ----------------------------------
function cc() {

  # Devuelve un color de letra si se pide explicitamente,
  # o un color de fondo si no se pide
  # 0=N; 1=R; 2=G; 3=O; 4=B; 5=P; 6=C; 7=W
  # ----------------------------------
  function generarColor() {
    if [ "$1" == "fg" ]; then
      echo $((RANDOM % 7 + 31))
    elif [ "$1" == "fg_negro" ]; then
      echo "30"
    elif [ "$1" == "bg" ]; then
      echo $((RANDOM % 7 + 41))
    elif [ "$1" == "bg_negro" ]; then
      echo "40"
    fi
  }

  local salida
  salida="\e["

  case "$1" in
  Neg)
    salida+="1;"
    ;;
  Sub)
    salida+="4;"
    ;;
  Nor)
    salida+="0;"
    ;;
  Par)
    salida+="5;"
    ;;
  *)
    salida+="1;"
    ;;
  esac

  if [[ "$2" != "" ]]; then
    case "$2" in
    random)
      salida+="$(generarColor fg_negro);$(generarColor bg)m"
      ;;
    default)
      salida+="$(($(generarColor fg_negro) + 7));$(generarColor bg_negro)m"
      ;;
    error)
      salida+="$(($(generarColor fg_negro) + 7));$(($(generarColor bg_negro) + 1))m"
      ;;
    acierto)
      salida+="$(($(generarColor fg_negro)));$(($(generarColor bg_negro) + 2))m"
      ;;
    advertencia)
      salida+="$(($(generarColor fg_negro)));$(($(generarColor bg_negro) + 3))m"
      ;;
    0)
      salida+="$(generarColor fg);$(generarColor bg_negro)m"
      ;;
    blanco)
      salida+="$(generarColor fg_negro);$(($(generarColor bg_negro) + 7))m"
      ;;
    *)
      salida+="$(generarColor fg_negro);$(($(generarColor bg_negro) + 1 + $(($2 % 6))))m"
      ;;
    esac
  fi

  echo "$salida"
}

# Finaliza el uso de colores
# ----------------------------------
function fc() {
  echo "\033[0m"
}

# Devuelve la longitud del string
# @param String del que queremos calcular la longitud
# ----------------------------------
function calcularLongitud() {
  local elementoArray # Elemento a ser centrado
  elementoArray=$1
  echo ${#elementoArray}
}

# Imprime la introduccion del programa
# @param Array del contenido del cuadro
# @param Ancho del cuadro
# ----------------------------------
function imprimirCuadro() {
  local estilo
  local titulos
  local encTabla
  local pieTabla
  local anchoCuadro
  local color

  # Asigna un estilo a la tabla, de doble linea, linea basica,
  # esquinas redondeadas, etc...
  # ----------------------------------
  function asignarEstiloCuadro() {
    local simboloHorizontal

    estilo=("${estiloGeneral[@]}")

    for ((i = 1; i <= anchoCuadro; i++)); do
      simboloHorizontal+=${estilo[0]}
    done

    encTabla=${estilo[1]}$simboloHorizontal
    pieTabla=${estilo[3]}$simboloHorizontal

    encTabla+=${estilo[7]}
    pieTabla+=${estilo[9]}
  }

  # Asigna el color principal de la introduccion
  function asignacolor() {
    if [[ "$2" == "" ]]; then
      color=$(cc Neg "$1")
    else
      color=$(cc "$2" "$1")
    fi
  }

  # Asigna el ancho de la celda
  # ----------------------------------
  function asignarAncho() {
    anchoCuadro="$1"

    if [ "$((anchoCuadro % 2))" == "1" ]; then
      ((anchoCuadro++))
    fi
  }

  # Imprime los elementos del array
  # ----------------------------------
  function imprimirTitulos() {

    IFS=$'\n' titulos=($@)
    local longitudArray # Para centrar en la tabla

    for ((i = 2; i < ${#titulos[@]}; i++)); do
      longitudArray=$(calcularLongitud "${titulos[$i]}")
      printf "$color%s" ""
      printf "${estilo[10]}%-*s" "$((anchoCuadro / 2 - longitudArray / 2))" ""
      printf "%s" "${titulos[$i]}" ""
      printf "$color%s" ""
      printf "%*s${estilo[10]}" "$((anchoCuadro / 2 - (longitudArray + 1) / 2))" ""
      printf "$(fc)\n%s" ""
    done
  }

  # Imprime la tabla de introduccion
  # ----------------------------------
  function imprimir() {
    local longitudArray

    # Encabezado
    printf "$color%s" ""
    printf "%s" "$encTabla"
    printf "$(fc)\n%s" ""

    # Fila de titulos
    imprimirTitulos "$@"

    # Fila de pie
    printf "$color%s" ""
    printf "%s" "$pieTabla"
    printf "$(fc)\n%s" ""
  }

  # Main de cuadro
  # ----------------------------------
  asignarAncho "$1"
  asignacolor "$2" "$4"
  asignarEstiloCuadro
  imprimir "$@"
}

# Imprime una tabla según el tamaño del array de datos
# @param numeroFilasImprimir
# @param numeroColumnasImprimir
# ----------------------------------
function imprimirTabla() {
  local titulos
  local colorEncabezado
  local -a coloresTabla
  local estiloTabla
  local anchoCelda
  local filasImprimir
  local columnasImprimir
  local encTabla
  local interTabla
  local pieTabla

  # Asigna el titulo de la tabla
  # ----------------------------------
  function asignarTitulosYNumCol() {
    titulos=("Proceso" "Llegada" "Ejecución" "Tamaño" "Estado" "Respuesta" "Espera" "Restante")
  }

  # Guarda los colores aleatorio de la tabla
  # ----------------------------------
  function guardarColoresDeTabla() {
    local random="false"

    if [ "$random" == "true" ]; then
      colorEncabezado=$(cc Neg)
      for ((i = 1; i <= NUM_FIL; i++)); do
        coloresTabla[$i]=$(cc Neg random)
      done
    else
      colorEncabezado=$(cc Neg default)
      for ((i = 1; i <= NUM_FIL; i++)); do
        coloresTabla[$i]=$(cc Neg "$((i + 4))")
      done
    fi
  }

  # Imprime los titulos de las columnas de datos
  # ----------------------------------
  function imprimirTitulos() {
    local longitudArray # Para centrar en la tabla

    for ((i = 0; i < columnasImprimir; i++)); do
      longitudArray=$(calcularLongitud "${titulos[$i]}")
      printf "${estiloTabla[10]}%-*s" "$((anchoCelda / 2 - longitudArray / 2))" ""
      printf "%s" "${titulos[$i]}" ""
      printf "%*s" "$((anchoCelda / 2 - (longitudArray + 1) / 2))" ""
    done

    printf "${estiloTabla[10]}%s" ""
  }

  # Asigna el ancho de la celda y el numero de filas a mostrar
  # desde el indice
  # ----------------------------------
  function asignarAnchoYFilasYColumnas() {
    local longitudElemento
    filasImprimir="$1"
    columnasImprimir="$2"
    anchoCelda="12"

    if [ "$filasImprimir" -gt "$NUM_FIL" ]; then
      filasImprimir="$NUM_FIL"
    fi

    if [ "$columnasImprimir" -gt "$NUM_COL" ]; then
      columnasImprimir="$NUM_COL"
    fi

    for ((i = 1; i <= columnasImprimir; i++)); do
      for ((j = 1; j <= filasImprimir; j++)); do
        longitudElemento=$(calcularLongitud "${array[$i, $j]}")
        if [[ "$anchoCelda" -lt "$longitudElemento" ]]; then
          anchoCelda="$longitudElemento"
        fi
      done
    done

    if [ "$((anchoCelda % 2))" == "1" ]; then
      ((anchoCelda++))
    fi
  }

  # Asigna un estilo a la tabla, de doble linea, linea basica,
  # esquinas redondeadas, etc...
  # ----------------------------------
  function asignarEstiloDeTabla() {
    local simboloHorizontal

    estiloTabla=("${estiloGeneral[@]}")

    for ((i = 1; i <= anchoCelda; i++)); do
      simboloHorizontal+=${estiloTabla[0]}
    done

    encTabla=${estiloTabla[1]}$simboloHorizontal
    interTabla=${estiloTabla[2]}$simboloHorizontal
    pieTabla=${estiloTabla[3]}$simboloHorizontal

    for ((i = 1; i < columnasImprimir; i++)); do
      encTabla+=${estiloTabla[4]}$simboloHorizontal
      interTabla+=${estiloTabla[5]}$simboloHorizontal
      pieTabla+=${estiloTabla[6]}$simboloHorizontal
    done

    encTabla+=${estiloTabla[7]}
    interTabla+=${estiloTabla[8]}
    pieTabla+=${estiloTabla[9]}
  }

  # Imprime la tabla final en orden
  # ----------------------------------
  function imprimir() {
    local longitudArray

    # Encabezado
    printf "$colorEncabezado%s" ""
    printf "%s" "$encTabla"
    printf "$(fc)\n%s" ""

    # Fila de titulos
    printf "$colorEncabezado%s" ""
    printf "%s" ""
    imprimirTitulos
    printf "$(fc)\n%s" ""

    for ((k = 1; k <= filasImprimir; k++)); do
      # Fila de datos
      printf "${coloresTabla[$k]}%s" ""
      printf "%s" "$interTabla"
      printf "$(fc)\n%s" ""
      printf "${coloresTabla[$k]}%s" ""
      for ((j = 1; j <= columnasImprimir; j++)); do
        # Celda
        longitudArray=$(calcularLongitud "${array[$j, $k]}")
        printf "${estiloTabla[10]}%-*s" "$((anchoCelda / 2 - longitudArray / 2))" ""
        printf "%s" "${array[$j, $k]}" ""
        printf "%*s" "$((anchoCelda / 2 - (longitudArray + 1) / 2))" ""
      done
      printf "${estiloTabla[10]}%s" ""
      printf "$(fc)\n%s" ""
      if [ "$k" == "$filasImprimir" ]; then
        # Fila de pie
        printf "${coloresTabla[$k]}%s" ""
        printf "%s" "$pieTabla"
        printf "$(fc)\n%s" ""
      fi
    done
  }

  # Main de impresion
  # ----------------------------------
  asignarTitulosYNumCol
  guardarColoresDeTabla
  asignarAnchoYFilasYColumnas "$1" "$2"
  asignarEstiloDeTabla
  imprimir
}

# Ordena el array según tiempo de llegada para mostrar la tabla
# ------------------------------------------------
function ordenarArray() {

  # Funcion que mueve la fila completa por la siguiente
  # ------------------------------------------------
  function moverFilaCompleta() {
    local temp

    for ((col = 1; col <= NUM_COL; col++)); do
      temp="${array[$col, $1]}"
      array[$col, $1]="${array[$col, $(($1 + 1))]}"
      array[$col, $(($1 + 1))]="$temp"
    done
  }

  # Ejecuta el algoritmo burbuja
  # ------------------------------------------------
  function burbuja() {
    local tempOrigen
    local tempDestino

    for ((i = 1; i <= NUM_FIL; i++)); do
      for ((j = 1; j < NUM_FIL; j++)); do
        tempOrigen="${array[$PROC_LLE, $j]}"
        tempDestino="${array[$PROC_LLE, $((j + 1))]}"

        if [ "$tempOrigen" -gt "$tempDestino" ]; then
          moverFilaCompleta "$j"
        fi
      done
    done
  }

  burbuja
}

# Centra en pantalla el valor pasado, si es un string, divide por saltos de
# linea y coloca cada linea en el centro
# @param string a centrar
# ----------------------------------
function centrarEnPantalla() {
  local string
  local termwidth
  local padding
  local longitudElemento

  echo ""

  IFS=$'\n' string=($1)
  termwidth="$(tput cols)"
  padding="$(printf '%0.1s' ' '{1..500})"
  longitudElemento=$(calcularLongitud "${string[0]}")

  for ((i = 0; i < ${#string[@]}; i++)); do
    printf "%*.*s %s %*.*s\n" 0 "$(((termwidth - 2 - longitudElemento) / 2))" "$padding" "${string[$i]}" 0 "$(((termwidth - 1 - longitudElemento) / 2))" "$padding"
  done
}

# Funcion basica de avance de algoritmo
# ----------------------------------
function avanzarAlgoritmo() {
  # printf "%s\n\n" ""
  read -r -p "$(centrarEnPantalla "$(imprimirCuadro "35" "default" "Pulsa intro para avanzar")")"
  clear
}

######################## Main
# Main, eje central del algoritmo, única llamada en cuerpo
# ----------------------------------
function main() {
  # Variables globales de subfunciones
  # ----------------------------------
  declare -a estiloGeneral
  declare -A array
  declare -i NUM_COL
  declare -i NUM_FIL
  declare -i MEM_TAM
  declare -i MEM_USE
  # Variables de columnas, para saber que hay en cada una - Usadas para aclarar el código
  # ----------------------------------
  declare -i PROC_NUM
  declare -i PROC_LLE
  declare -i PROC_EJE
  declare -i PROC_TAM
  declare -i PROC_EST
  declare -i PROC_RES
  declare -i PROC_ESP
  declare -i PROC_EJE_RES
  # Variables locales
  # ----------------------------------
  local configFile
  local introduccion
  local error
  local acierto
  local advertencia
  local archivoSalida
  local archivoEntrada
  local salirDePractica

  # Extraccion de variables del archivo de config
  # ------------------------------------------------
  function asignaciones() {

    # Asigna las variables extraidas del archivo de ocnfiguración
    # ------------------------------------------------
    function asignarConfigs() {
      configFile=$(dirname "$0")
      configFile+="/config.toml"
      introduccion=$(extraerDeConfig "introduccion")
      error=$(extraerDeConfig "error")
      acierto=$(extraerDeConfig "acierto")
      advertencia=$(extraerDeConfig "advertencia")
      archivoSalida=$(extraerDeConfig "archivoSalida")
      archivoEntrada=$(extraerDeConfig "archivoEntrada")
    }

    # Asigna el numero de cada columna para asignarlo en las diferentes funciones
    # ------------------------------------------------
    function asignarPosicionYNumColumnas() {
      PROC_NUM="1"
      PROC_LLE="2"
      PROC_EJE="3"
      PROC_TAM="4"
      PROC_EST="5"
      PROC_RES="6"
      PROC_ESP="7"
      PROC_EJE_RES="8"

      NUM_COL="$PROC_EJE_RES" # Ya que siempre esta columna va a ser la última
    }

    asignarConfigs
    asignarEstiloGeneral "2"
    asignarPosicionYNumColumnas
  }
  # ------------------------------------------------

  # Introduccion
  # ------------------------------------------------
  function introduccion() {
    # Imprime introducción
    centrarEnPantalla "$(imprimirCuadro "50" "0" "$introduccion")" | sacarHaciaArchivo "$archivoSalida"
    # Imprime mensaje error
    centrarEnPantalla "$(imprimirCuadro "100" "error" "$error")"
    # Imprime mensaje advertencia
    centrarEnPantalla "$(imprimirCuadro "100" "advertencia" "$advertencia")"
    # Avanza de fase
    avanzarAlgoritmo
  }
  # ------------------------------------------------

  # Elección menú, entrada de datos y tipo de tiempo
  # ------------------------------------------------
  function menu() {
    elegirTipoDeEntrada "$archivoEntrada"
  }
  # ------------------------------------------------

  # Ejecuta Algoritmo
  # ------------------------------------------------
  function algoritmo() {
    local -a estados=("Fuera" "En Espera" "En Memoria" "Bloqueado" "Ejecutando" "Terminado")
    local -a procesosEnMemoria
    local stringVacio
    local -A arrayCopia
    local instante
    local acabarAlgoritmo
    acabarAlgoritmo="false"
    instante="0"
    stringVacio="null"

    # Imprime una cabecera muy simple
    # ----------------------------------
    function algCabecera() {
      centrarEnPantalla "$(imprimirCuadro "100" "acierto" "$acierto")"
    }

    # Calcula los siguientes datos a mostrar
    # ----------------------------------
    function algCalcularSigIns() {
      centrarEnPantalla "$(imprimirCuadro "100" "3" "Instante $instante - Memoria usada: $MEM_USE/$MEM_TAM")"
    }

    # Calcula los tiempos medios de respuesta y espera
    # ----------------------------------
    function algTiemposMedios() {
      local -i mediaRespuesta
      local -i mediaEspera
      mediaEspera="0"
      mediaRespuesta="0"

      for ((i = 1; i <= NUM_FIL; i++)); do
        if [[ "${array[$PROC_RES, $i]}" != "-" ]]; then
          mediaRespuesta+="${array[$PROC_RES, $i]}"
        fi
        if [[ "${array[$PROC_ESP, $i]}" != "-" ]]; then
          mediaEspera+="${array[$PROC_ESP, $i]}"
        fi
      done

      mediaRespuesta="$((mediaRespuesta * 100))"
      mediaEspera="$((mediaEspera * 100))"

      # Saca la media de respuesta en formato decimal
      # ----------------------------------
      function sacarMediaRespuesta() {
        printf "%.2f" "$((mediaRespuesta / NUM_FIL))e-2"
      }

      # Saca la media de espera en formato decimal
      # ----------------------------------
      function sacarMediaEspera() {
        printf "%.2f" "$((mediaEspera / NUM_FIL))e-2"
      }

      centrarEnPantalla "$(imprimirCuadro "100" "3" "Tiempo Medio de Respuesta: $(sacarMediaRespuesta) - Tiempo Medio de Espera: $(sacarMediaEspera)")"
    }

    # Funcion que calcula el tiempo y estado de todos los proceos en cada instante,
    # sirve para saber como colcarlos en memoria y calcular el tiempo medio final
    # ----------------------------------
    function algCalcularDatos() {
      comprobarProcesosEjecutando
      asignarEstadosSegunInstante "$instante"
    }

    # Funcion que asigna la memoria vacia
    # ----------------------------------
    function algAsignarMemoriaInicial() {
      MEM_USE="0"

      for ((i = 0; i < MEM_TAM; i++)); do
        procesosEnMemoria[$i]="$stringVacio"
      done
    }

    # Imprime el dibujo de la tabla
    # ----------------------------------
    function algImprimirTabla() {
      centrarEnPantalla "$(imprimirCuadro "100" "default" "TABLA DE PROCESOS")"
      centrarEnPantalla "$(imprimirTabla "$NUM_FIL" "10")"
    }

    # Imprime la linea de tiempo
    # ----------------------------------
    function algImprimirLineaTiempo() {
      centrarEnPantalla "$(imprimirCuadro "100" "default" "LINEA DE TIEMPO")"
      centrarEnPantalla "$(imprimirLineaProcesos "$instante")"
    }

    # Imprime el dibujo de la memoria
    # ----------------------------------
    function algImprimirMemoria() {
      centrarEnPantalla "$(imprimirCuadro "100" "default" "USO DE MEMORIA")"
      imprimirMemoria
    }

    # Funcion para avanzar el algoritmo o terminarlo
    # ----------------------------------
    function algAvanzarAlgoritmo() {
      local temp
      temp=""

      read -r -p "$(centrarEnPantalla "$(imprimirCuadro "50" "blanco" "Pulsa intro para avanzar o [F] para finalizar")")" temp

      # Doble clear para limpiar pantalla (ya que el conetenido es mayor que la pantalla y solo hace el salto)
      clear
      clear

      if [[ "$temp" =~ ^([fF])$ ]]; then
        acabarAlgoritmo="true"
        centrarEnPantalla "$(imprimirCuadro "100" "3" "Ejecutando y exportando algoritmo en segundo plano. Serán solo unos segundos")"
      fi
    }

    # Hace una copia del array antes de cambiarlo en la ejecucion
    # ----------------------------------
    function copiarArray() {
      for ((i = 1; i <= NUM_FIL; i++)); do
        for ((j = 1; j <= NUM_COL; j++)); do
          arrayCopia[$j, $i]="${array[$j, $i]}"
        done
      done
    }

    # Comprueba si en el instante de ejucion pasa algo importante para mostrar o no
    # Consideramos que algo importante pasa si cambia algún estado de los procesos
    # ----------------------------------
    function algoImportantePasa() {
      local algoImportantePasa="false"

      for ((i = 1; i <= NUM_FIL; i++)); do
        if [[ "${array[$PROC_EST, $i]}" != "${arrayCopia[$PROC_EST, $i]}" ]]; then
          algoImportantePasa="true"
        fi
      done

      echo "$algoImportantePasa"
    }

    # Main del cuerpo del algoritmo
    # ----------------------------------
    function algCuerpoAlgoritmo() {
      algCalcularSigIns
      algImprimirTabla
      algTiemposMedios
      algImprimirMemoria
      algImprimirLineaTiempo
    }

    # Main de las llamadas de la parte de calculo de algoritmo
    # ----------------------------------
    clear
    ordenarArray
    asignarDatosInicial
    algAsignarMemoriaInicial
    algCabecera >>"$archivoSalida"

    while [[ $(procesosHanTerminado) != "true" ]]; do
      copiarArray
      algCalcularDatos

      # Si pasa algo importante lo mostramos en pantalla y/o sacamos por archivo
      if [[ "$(algoImportantePasa)" == "true" ]]; then
        if [[ "$acabarAlgoritmo" == "true" ]]; then
          algCuerpoAlgoritmo >>"$archivoSalida"
        else
          algCabecera
          algCuerpoAlgoritmo | sacarHaciaArchivo "$archivoSalida" -a
          algAvanzarAlgoritmo
        fi
      fi
      ((instante++))
    done
  }
  # ------------------------------------------------

  # Pregunta al usuario si quiere salir del programa
  # ------------------------------------------------
  function preguntarSiQuiereInforme() {
    local temp

    clear
    centrarEnPantalla "$(imprimirCuadro "50" "default" "¿Quieres ver el informe? [S/N]")"
    temp=$(recibirEntrada)

    while [[ ! "$temp" =~ ^([sS][iI]|[sS]|[nN][oO]|[nN])$ ]]; do
      centrarEnPantalla "$(imprimirCuadro "80" "error" "Entrada de datos errónea")"
      temp=$(recibirEntrada)
    done

    if [[ $temp =~ [sS][iI]|[sS] ]]; then
      less -r -N "$archivoSalida"
    fi
  }
  # ------------------------------------------------

  # Pregunta al usuario si quiere sacar el informe
  # ------------------------------------------------
  function preguntarSiQuiereSalir() {
    local temp

    clear
    centrarEnPantalla "$(imprimirCuadro "50" "default" "¿Quieres volver a ejecutar el algoritmo? [S/N]")"
    temp=$(recibirEntrada)

    while [[ ! "$temp" =~ ^([sS][iI]|[sS]|[nN][oO]|[nN])$ ]]; do
      centrarEnPantalla "$(imprimirCuadro "80" "error" "Entrada de datos errónea")"
      temp=$(recibirEntrada)
    done

    if [[ $temp =~ [nN][oO]|[nN] ]]; then
      salirDePractica="true"
    elif [[ "$temp" =~ [sS][iI]|[sS] ]]; then
      array=()
    fi
  }
  # ------------------------------------------------

  # Saca spam
  # ------------------------------------------------
  function imprimirSpam() {
    local spam
    local gitSpam=("¡Gracias por usar nuestro algoritmo!" "Visita nuestro repositorio aquí abajo")
    spam="
 ▄▄▄▄▄▄▄   ▄ ▄▄▄▄   ▄▄  ▄▄ ▄▄▄▄▄▄▄
 █ ▄▄▄ █ ▀ ▀ ▄█▀█▀ █ ▀▄█▄▀ █ ▄▄▄ █
 █ ███ █ ▀█▀ ▀ ▀█▄▀ █▄▄█▄  █ ███ █
 █▄▄▄▄▄█ █▀▄▀█ ▄ ▄ ▄ ▄ ▄ ▄ █▄▄▄▄▄█
 ▄▄▄▄▄ ▄▄▄█▀█  ▀ █▄█▀▄▀█ ▄▄ ▄ ▄ ▄ 
 ▀▄▄ ▀▄▄▄▄ █ ▀███▄█▀▀█▄ ▀▄ ▀▄▄▄▀█▀
 █▀██ ▄▄ ▄▄▄ █▀▄█ ▄ ▀ ▀█ ▄█▀▄█▄▀  
 █▄█ █ ▄ ██▄▄▄  ▀▀  ▀█▀▀  ▄██▄  █▀
 ▄▄▀▄██▄▄█▄▀█  ▀ ▀▄▀▀▄▀█  █▀█▄ ▀▄ 
  ▀▄▀▄█▄█ █▀ ▀███ ▄▄▀█ ▄▀▄▄█  █ █▀
 ▄▄▄  ▀▄█ █▀ █▀▄ ▀▄▀▄▀▀██▄▀  ▄ ▀▄ 
 █ █  █▄▄▀██▄▄  ▄█ ▀▀ █▀▀ ▄█▄ █ █▀
 █ ▄███▄▀█ ▄█  ▀█ ▄ ▄ ▀  █████▀▀ ▄
 ▄▄▄▄▄▄▄ █▀█ ▀██▄▀ ▀▀█▄▄▄█ ▄ ██▀▄▀
 █ ▄▄▄ █ ▄█▄ █▀▄▄█▄▄▀▄▀█▀█▄▄▄█▀▀█▀
 █ ███ █ █ █▄▄  ▄██▀▀█▀ ▄▄▀▄▀▀▄▄▀▀
 █▄▄▄▄▄█ █▄▄█  ▀▀     ▀▄█▄▄▀▀ █▀▄ 
 "
    clear
    centrarEnPantalla "$(imprimirCuadro "50" "acierto" "${gitSpam[@]}")" | sacarHaciaArchivo "$archivoSalida" -a
    centrarEnPantalla "$(imprimirCuadro "38" "default" "$spam")" | sacarHaciaArchivo "$archivoSalida" -a
  }
  # ------------------------------------------------

  # Main de main xD
  # ------------------------------------------------
  clear
  asignaciones
  introduccion
  while [[ "$salirDePractica" != "true" ]]; do
    menu
    algoritmo
    preguntarSiQuiereInforme
    preguntarSiQuiereSalir
  done
  imprimirSpam
}

main

# TODO-> Arreglar que la linea de cpu se vea bien, truncado
# TODO-> Imprimir doble linea en la linea de memoria, o cambiar la forma en la que se imprime

# TODO-> Ir donde lolo y que me diga que cambiar, y luego ezz
