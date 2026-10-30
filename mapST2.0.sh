#!/usr/bin/env bash
# =============================================================================
# pinginfo.sh - Herramienta de reconocimiento básico
#
#   FLUJO:  ping  ->  IP + TTL + SO probable  ->  GeoIP (ip-api.com)  ->  nmap
#
#   USO AUTORIZADO ÚNICAMENTE. Escanea solo sistemas de tu propiedad o para
#   los que tengas permiso explícito y por escrito. El escaneo de puertos sin
#   autorización es ilegal en la mayoría de los países.
#
#   Uso: ./pinginfo.sh <dominio|ip> [opciones]
#     -q            Escaneo rápido: puertos top-100 (-sS -F)
#     -s            Escaneo sigiloso SYN completo + versión (-sS -sV -T2)
#     -p PUERTOS    Puertos concretos (ej: -p 22,80,443  o  -p 1-1000)
#     -A            Escaneo agresivo: OS + versión + scripts (-A) [ruidoso]
#     -c            Salida compacta: solo PUERTO / ESTADO / SERVICIO
#     -m            Ejecuta tu herramienta personalizada (mi_herramienta)
#     -n            Solo reconocimiento (ping + GeoIP), sin nmap
#     -y            No preguntar antes de escanear (modo automático)
#     -j            Muestra el JSON crudo de ip-api y sale
#     -o ARCHIVO    Guarda el resultado completo de nmap en ARCHIVO
#     -h            Ayuda
# =============================================================================

# 'pipefail' hace que una tubería (cmd1 | cmd2) falle si falla CUALQUIER parte,
# no solo la última. Útil para detectar errores en 'ping | grep', etc.
set -o pipefail

# --- Paleta de colores ANSI (solo estética para la terminal) ---------------
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; B='\033[0;34m'; C='\033[0;36m'; N='\033[0m'

# -----------------------------------------------------------------------------
# banner(): imprime el encabezado decorativo al inicio.
# -----------------------------------------------------------------------------
banner() {
  echo -e "${C}===================================================${N}"
  echo -e "${C}   PingInfo - Recon: IP/TTL/OS + GeoIP + nmap       ${N}"
  echo -e "${C}===================================================${N}"
}

# -----------------------------------------------------------------------------
# uso(): muestra la ayuda y termina. Extrae las líneas de comentario del propio
#        encabezado del archivo (las que empiezan con '#') y las imprime limpias.
# -----------------------------------------------------------------------------
uso() {
  grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'
  exit 1
}

# =============================================================================
# mi_herramienta(): ESPACIO RESERVADO PARA TI XELAST
# -----------------------------------------------------------------------------
# Aquí implementas tu propia lógica usando los datos que el script ya recolectó.
# Se ejecuta al final (después del recon y de nmap) solo si pasas la opción -m.
#
# VARIABLES GLOBALES DISPONIBLES (ya tienen valor cuando llega aquí):
#   $OBJETIVO           -> dominio o IP que escribió el usuario (ya limpio)
#   $IP                 -> IP resuelta del objetivo
#   $TTL                -> TTL recibido (vacío si no hubo respuesta a ping)
#   $TIEMPO             -> tiempo de respuesta del ping (ej: "12.3 ms")
#   $SO                 -> sistema operativo probable
#   $SALTOS             -> saltos aproximados de red
#   $JSON               -> respuesta completa de ip-api.com en JSON
#   $MODO_NMAP          -> modo de escaneo usado
#   $OUT                -> archivo donde se guardó nmap (vacío si no se usó -o)
#   $NMAP_SALIDA        -> salida de texto completa de nmap
#   ${PUERTOS_ABIERTOS[@]} -> arreglo con los puertos ABIERTOS (ej: 22 80 443)
#   ${SERVICIOS[@]}        -> arreglo paralelo con el servicio de cada puerto
#   $PUERTO_ELEGIDO     -> el puerto que selecciona el usuario en el menú
#
# También puedes reutilizar campo() para leer el JSON:
#   PAIS=$(campo country)     CIUDAD=$(campo city)     ISP=$(campo isp)
#
# Colores listos para usar: $R $G $Y $B $C  y  $N (reset).
# =============================================================================
mi_herramienta() {
  echo
  echo -e "${C}===================================================${N}"
  echo -e "${C}   Para detener el ddos usa control C                    ${N}"
  echo -e "${C}===================================================${N}"

  # --- Si no hay puertos abiertos, no hay nada que elegir ------------------
  if [[ ${#PUERTOS_ABIERTOS[@]} -eq 0 ]]; then
    echo -e "${R}[!] No se encontraron puertos abiertos. Nada que procesar.${N}"
    echo -e "${C}===================================================${N}"
    return
  fi

  # --- Menú: el usuario elige qué puerto abierto usar ---------------------
  echo -e "${B}[*] IP objetivo:${N} $IP"
  echo -e "${B}[*] Puertos abiertos encontrados:${N}"
  local i
  for i in "${!PUERTOS_ABIERTOS[@]}"; do
    # Numera cada opción: 1) 22  (ssh)
    printf "    ${G}%d)${N} %-6s ${Y}%s${N}\n" "$((i+1))" "${PUERTOS_ABIERTOS[$i]}" "${SERVICIOS[$i]}"
  done

  echo -e "${Y}[?] Elige el número del puerto a usar:${N}"
  local sel
  read -r sel
  # Validar: que sea un número dentro del rango de opciones.
  if ! [[ "$sel" =~ ^[0-9]+$ ]] || (( sel < 1 || sel > ${#PUERTOS_ABIERTOS[@]} )); then
    echo -e "${R}[!] Opción inválida.${N}"
    echo -e "${C}===================================================${N}"
    return
  fi
  sleep  .2
  # Guardamos la elección (el arreglo empieza en 0, por eso sel-1).
  PUERTO_ELEGIDO="${PUERTOS_ABIERTOS[$((sel-1))]}"
  local SERVICIO_ELEGIDO="${SERVICIOS[$((sel-1))]}"
  echo -e "${G}[+] Elegiste:${N} $IP:$PUERTO_ELEGIDO ($SERVICIO_ELEGIDO)"
  tiempo=1000
  # =======================================================================
  # >>> ESCRIBE TU CÓDIGO AQUÍ <<<
  # Ya tienes todo listo para tu herramienta:
  #     $IP               -> la IP objetivo
  #     $PUERTO_ELEGIDO   -> el puerto que eligió el usuario
  #     $SERVICIO_ELEGIDO -> el servicio de ese puerto (ssh, http, ...)
  #
  # Ejemplo de a qué conectar tu lógica:
  #     echo "Conectando a $IP en el puerto $PUERTO_ELEGIDO ..."
  #     # mi_comando --host "$IP" --port "$PUERTO_ELEGIDO"
  # =======================================================================
	python dd.py $IP $PUERTO_ELEGIDO $tiempo

  echo -e "${C}===================================================${N}"
}

# --- Valores por defecto de las opciones -------------------------------------
MODO_NMAP="quick"   # tipo de escaneo: quick | stealth | ports | aggressive
PUERTOS=""          # lista de puertos cuando se usa -p
SOLO_RECON=0        # -n : 1 = no escanear, solo recon
RAW_JSON=0          # -j : 1 = volcar JSON crudo de ip-api y salir
OUT=""              # -o : ruta del archivo para guardar la salida de nmap
AUTO=0              # -y : 1 = no preguntar antes de escanear
COMPACTO=0          # -c : 1 = filtrar la salida de nmap a puerto/estado/servicio
MI_TOOL=0           # -m : 1 = ejecutar tu función mi_herramienta al final
NMAP_SALIDA=""      # aquí se guarda la salida de nmap para tu herramienta
PUERTO_ELEGIDO=""   # puerto que el usuario selecciona en mi_herramienta
declare -a PUERTOS_ABIERTOS=()  # arreglo de puertos abiertos (ej: 22 80 443)
declare -a SERVICIOS=()         # arreglo paralelo: servicio de cada puerto

# El primer argumento SIEMPRE es el objetivo (dominio o IP).
[[ -z "$1" ]] && uso          # si no hay argumentos, muestra la ayuda
OBJETIVO="$1"; shift          # guarda el objetivo y 'shift' lo quita de la lista

# -----------------------------------------------------------------------------
# getopts: recorre las opciones (-q, -s, -p ..., etc.) y enciende las variables.
#   La cadena "qsp:Anycjo:h" declara qué letras son válidas.
#   Una letra seguida de ':' (como p: y o:) ESPERA un valor; las demás son
#   simples interruptores.
# -----------------------------------------------------------------------------
while getopts "qsp:Anycmjo:h" opt; do
  case "$opt" in
    q) MODO_NMAP="quick" ;;                    # escaneo rápido
    s) MODO_NMAP="stealth" ;;                  # escaneo sigiloso
    p) MODO_NMAP="ports"; PUERTOS="$OPTARG" ;; # puertos concretos ($OPTARG = valor tras -p)
    A) MODO_NMAP="aggressive" ;;               # escaneo agresivo
    n) SOLO_RECON=1 ;;                          # no escanear
    y) AUTO=1 ;;                                # sin confirmación
    c) COMPACTO=1 ;;                            # salida compacta
    m) MI_TOOL=1 ;;                             # ejecutar tu herramienta
    j) RAW_JSON=1 ;;                            # JSON crudo
    o) OUT="$OPTARG" ;;                         # archivo de salida
    h) uso ;;                                   # ayuda
    *) uso ;;                                   # opción desconocida -> ayuda
  esac
done

# -----------------------------------------------------------------------------
# Comprobación de dependencias: 'ping' y 'curl' son obligatorios.
#   command -v <cmd> devuelve éxito si el comando existe en el sistema.
# -----------------------------------------------------------------------------
for dep in ping curl; do
  command -v "$dep" >/dev/null 2>&1 || { echo -e "${R}[!] Falta '$dep'.${N}"; exit 1; }
done
# 'jq' (para leer JSON) y 'nmap' son opcionales: si existen, se usan.
TIENE_JQ=0;   command -v jq   >/dev/null 2>&1 && TIENE_JQ=1
TIENE_NMAP=0; command -v nmap >/dev/null 2>&1 && TIENE_NMAP=1

# -----------------------------------------------------------------------------
# Limpieza del objetivo: por si el usuario pega una URL completa.
#   Quita 'http://', 'https://', la ruta (/algo) y el puerto (:8080).
#   ${var#patron}  borra el patrón del INICIO.
#   ${var%%patron} borra desde el patrón hasta el FINAL.
# -----------------------------------------------------------------------------
OBJETIVO="${OBJETIVO#http://}"; OBJETIVO="${OBJETIVO#https://}"
OBJETIVO="${OBJETIVO%%/*}";     OBJETIVO="${OBJETIVO%%:*}"

banner
echo -e "${Y}[i] Uso autorizado únicamente. Escanea solo lo que te pertenece o tengas permiso.${N}"
echo -e "${B}[*] Objetivo:${N} $OBJETIVO"

# =============================================================================
# ETAPA 1A - PING: obtener IP, TTL y tiempo de respuesta
# =============================================================================
echo -e "${B}[*] Enviando ping...${N}"
# ping -c 1 : envía 1 paquete.  -W 3 : espera máximo 3 segundos.
# Guardamos toda la salida (y errores con 2>&1) en la variable SALIDA.
SALIDA=$(ping -c 1 -W 3 "$OBJETIVO" 2>&1)

if [[ $? -ne 0 ]]; then
  # $? es el código de salida del último comando; distinto de 0 = falló el ping.
  echo -e "${R}[!] Sin respuesta al ping (puede filtrar ICMP). Intento resolver la IP igual...${N}"
  # getent resuelve el nombre a IP usando el DNS del sistema, sin hacer ping.
  IP=$(getent hosts "$OBJETIVO" 2>/dev/null | awk '{print $1; exit}')
  # Si el objetivo ya era una IP, la tomamos directamente.
  [[ -z "$IP" ]] && IP=$(echo "$OBJETIVO" | grep -oE '^([0-9]{1,3}\.){3}[0-9]{1,3}$')
  TTL=""   # sin ping no hay TTL
else
  # La IP aparece entre paréntesis en la primera línea: PING host (1.2.3.4) ...
  IP=$(echo "$SALIDA" | head -n1 | grep -oE '\(([0-9]{1,3}\.){3}[0-9]{1,3}\)' | head -n1 | tr -d '()')
  [[ -z "$IP" ]] && IP=$(echo "$SALIDA" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n1)
  # TTL: aparece como 'ttl=117' (Linux) o 'TTL=117' (Windows). -i = sin distinguir mayúsculas.
  TTL=$(echo "$SALIDA" | grep -oiE 'ttl=[0-9]+' | head -n1 | cut -d= -f2)
  # Tiempo de ida y vuelta: 'time=12.3 ms'
  TIEMPO=$(echo "$SALIDA" | grep -oE 'time=[0-9.]+ ?ms' | head -n1 | cut -d= -f2)
fi

# Sin IP no podemos continuar.
[[ -z "$IP" ]] && { echo -e "${R}[!] No se pudo resolver la IP del objetivo.${N}"; exit 1; }

# =============================================================================
# ETAPA 1B - Mostrar IP, TTL y SISTEMA OPERATIVO probable
# =============================================================================
echo
echo -e "${G}[+] IP:${N}             $IP"
if [[ -n "$TTL" ]]; then
  # Los SO parten de un TTL inicial típico y va bajando 1 por cada salto (router).
  #   64  -> Linux/Unix/macOS      128 -> Windows      255 -> equipos de red
  # Como el TTL recibido es menor al inicial, comparamos por rangos.
  if   (( TTL <= 64 ));  then SO="Linux / Unix / macOS"; TTL_INI=64
  elif (( TTL <= 128 )); then SO="Windows";              TTL_INI=128
  else                        SO="Solaris / AIX / Cisco"; TTL_INI=255; fi
  SALTOS=$(( TTL_INI - TTL ))   # cuántos routers aproximadamente hay en medio
  echo -e "${G}[+] TTL:${N}            $TTL"
  [[ -n "$TIEMPO" ]] && echo -e "${G}[+] Tiempo:${N}         $TIEMPO"
  echo -e "${G}[+] SO probable:${N}    ${Y}$SO${N} (TTL inicial $TTL_INI, ~$SALTOS saltos)"
  echo -e "${Y}    El TTL es solo un indicio; CDNs/firewalls pueden alterarlo.${N}"
fi

# =============================================================================
# ETAPA 2 - GeoIP: información de la IP vía ip-api.com
# =============================================================================
echo
echo -e "${B}[*] Consultando ip-api.com...${N}"
# Pedimos solo los campos que nos interesan (más rápido y limpio).
CAMPOS="status,message,country,countryCode,regionName,city,zip,lat,lon,timezone,isp,org,as,reverse,mobile,proxy,hosting,query"
# curl -s = silencioso (sin barra de progreso).  --max-time 8 = corta a los 8s.
# OJO: la versión gratis de ip-api solo funciona por HTTP (no HTTPS).
JSON=$(curl -s --max-time 8 "http://ip-api.com/json/${IP}?fields=${CAMPOS}")

# Si se pidió -j, mostramos el JSON tal cual y salimos.
if (( RAW_JSON )); then
  if (( TIENE_JQ )); then echo "$JSON" | jq .; else echo "$JSON"; fi
  exit 0
fi

# -----------------------------------------------------------------------------
# campo(): extrae un valor del JSON por su nombre de clave.
#   Si existe 'jq', lo usa (fiable). Si no, lo saca con grep/sed (plan B).
# -----------------------------------------------------------------------------
campo() {
  if (( TIENE_JQ )); then
    echo "$JSON" | jq -r --arg k "$1" '.[$k] // empty'
  else
    echo "$JSON" | grep -oE "\"$1\":(\"[^\"]*\"|[^,}]*)" | head -n1 | cut -d: -f2- | sed 's/^"//;s/"$//'
  fi
}

# ip-api responde "status":"success" si todo fue bien.
if [[ "$(campo status)" == "success" ]]; then
  # printf alinea las etiquetas en columnas de 14 caracteres (%-14s).
  printf "${G}%-14s${N} %s\n" \
    "País:"      "$(campo country) ($(campo countryCode))" \
    "Región:"    "$(campo regionName)" \
    "Ciudad:"    "$(campo city) $(campo zip)" \
    "Coords:"    "$(campo lat), $(campo lon)" \
    "Zona hor.:" "$(campo timezone)" \
    "ISP:"       "$(campo isp)" \
    "Org:"       "$(campo org)" \
    "ASN:"       "$(campo as)" \
    "Reverse:"   "$(campo reverse)" \
    "Hosting:"   "$(campo hosting)" \
    "Proxy/VPN:" "$(campo proxy)"
else
  echo -e "${R}[!] ip-api: $(campo message)${N}"
fi

# Si se pidió -n (solo recon), terminamos aquí sin escanear.
# (pero si además pediste -m, tu herramienta se ejecuta antes de salir)
if (( SOLO_RECON )); then
  (( MI_TOOL )) && mi_herramienta
  echo -e "${C}===================================================${N}"; exit 0
fi

# =============================================================================
# ETAPA 3 - NMAP: escaneo de puertos sobre la MISMA IP del recon
# =============================================================================
echo
# Si nmap no está instalado, avisamos y salimos sin error.
if (( ! TIENE_NMAP )); then
  echo -e "${R}[!] nmap no está instalado. Instálalo con:${N} sudo apt install nmap"
  echo -e "${C}===================================================${N}"
  exit 0
fi

# --- Confirmación: separa claramente el recon del escaneo --------------------
# Solo pregunta si NO está el modo automático (-y) y hay terminal interactiva.
# [[ -t 0 ]] comprueba que la entrada estándar es un teclado (no un archivo/pipe).
if (( ! AUTO )) && [[ -t 0 ]]; then
  echo -e "${Y}[?] Reconocimiento terminado. ¿Escanear la IP ${IP} con nmap? [s/N]${N}"
  read -r RESP
  case "$RESP" in
    s|S|si|SI|y|Y) ;;   # continúa
    *) echo -e "${B}[*] Escaneo cancelado. Solo se mostró el reconocimiento.${N}"
       echo -e "${C}===================================================${N}"; exit 0 ;;
  esac
fi

# --- Construir los argumentos de nmap según el modo elegido ------------------
#   -sS : SYN scan ("medio abierto", sigiloso; no completa la conexión TCP)
#   -sV : detecta versión del servicio
#   -F  : solo los 100 puertos más comunes (rápido)
#   -T2/-T4 : velocidad (2 = lento/discreto, 4 = rápido)
#   -Pn : no hacer ping previo (útil si el host filtra ICMP)
#   -A  : agresivo (OS + versión + scripts + traceroute)
case "$MODO_NMAP" in
  quick)      ARGS=(-sS -F -T4);                 DESC="rápido SYN top-100 puertos" ;;
  stealth)    ARGS=(-sS -sV -T2 -Pn);            DESC="sigiloso SYN + versión (lento, -T2)" ;;
  ports)      ARGS=(-sS -sV -T4 -p "$PUERTOS");  DESC="puertos $PUERTOS SYN + versión" ;;
  aggressive) ARGS=(-A -T4);                     DESC="agresivo: OS+versión+scripts (RUIDOSO)" ;;
esac

# --- Privilegios: -sS y -A necesitan root ------------------------------------
# Si no eres root, se usa sudo; y si no hay sudo, se cae a -sT (connect scan),
# que no requiere privilegios pero deja más rastro.
NEED_ROOT=0
for a in "${ARGS[@]}"; do [[ "$a" == "-sS" || "$a" == "-A" ]] && NEED_ROOT=1; done
PREFIJO=""
if (( NEED_ROOT )) && [[ $EUID -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then
    PREFIJO="sudo"
    echo -e "${Y}[i] El escaneo SYN requiere root; se usará sudo.${N}"
  else
    echo -e "${Y}[i] Sin root: cambio de -sS (SYN) a -sT (connect, más ruidoso).${N}"
    for i in "${!ARGS[@]}"; do [[ "${ARGS[$i]}" == "-sS" ]] && ARGS[$i]="-sT"; done
  fi
fi

# Si se pidió -o, añadimos -oN para guardar la salida COMPLETA en archivo.
# (El guardado es siempre completo, aunque en pantalla se filtre con -c.)
[[ -n "$OUT" ]] && ARGS+=(-oN "$OUT")

echo -e "${B}[*] nmap ($DESC):${N} nmap ${ARGS[*]} $IP"
echo -e "${C}---------------------------------------------------${N}"

# --- Ejecutar nmap -----------------------------------------------------------
# Guardamos la salida completa en $NMAP_SALIDA (para que mi_herramienta la use)
# y a la vez la mostramos en pantalla.
NMAP_SALIDA=$($PREFIJO nmap "${ARGS[@]}" "$IP")

# Con -c: solo la cabecera 'PORT' y las filas de puertos (PUERTO/ESTADO/SERVICIO).
# Sin -c: la salida completa.
if (( COMPACTO )); then
  echo "$NMAP_SALIDA" | grep -E '^PORT|^[0-9]+/(tcp|udp)'
else
  echo "$NMAP_SALIDA"
fi

echo -e "${C}---------------------------------------------------${N}"
[[ -n "$OUT" ]] && echo -e "${G}[+] Resultado completo guardado en:${N} $OUT"

# --- Extraer puertos ABIERTOS de la salida de nmap ---------------------------
# Las filas de puertos abiertos lucen así:  22/tcp  open  ssh
#   campo 1 = "22/tcp"  ->  cortamos en "/" y nos quedamos con 22
#   campo 2 = estado    ->  filtramos solo "open"
#   campo 3 = servicio  ->  ssh / http / ...
# Rellenamos los arreglos PUERTOS_ABIERTOS y SERVICIOS (en paralelo).
while read -r col1 estado servicio _; do
  if [[ "$estado" == "open" ]]; then
    PUERTOS_ABIERTOS+=( "${col1%%/*}" )            # quita "/tcp"
    SERVICIOS+=( "${servicio:-desconocido}" )      # servicio o "desconocido"
  fi
done < <(echo "$NMAP_SALIDA" | grep -E '^[0-9]+/(tcp|udp)')

# --- Tu herramienta personalizada (si pediste -m) ----------------------------
# Se ejecuta al final, con todos los datos ya disponibles:
#   $IP, $NMAP_SALIDA, ${PUERTOS_ABIERTOS[@]}, ${SERVICIOS[@]}
(( MI_TOOL )) && mi_herramienta

echo -e "${C}===================================================${N}"
