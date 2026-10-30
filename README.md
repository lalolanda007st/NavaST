# NavaST
Una herramienta que te da la ip de un sitio web, te indica que sistema operativo es mediante el ttl, tambien una consulta de Geoip y escanea la ip para darte los posibles puertos abiertos para luego usar un script en python 
#NavaSt
esta herramienta fue hecha por una comunidad y esta es la version 2.0 que edite para mejor flujo de  funciones 

  Uso: ./mapST2.0.sh <dominio|ip> [opciones]
     -q            Escaneo rápido: puertos top-100 (-sS -F)
     -s            Escaneo sigiloso SYN completo + versión (-sS -sV -T2)
     -p PUERTOS    Puertos concretos (ej: -p 22,80,443  o  -p 1-1000)
     -A            Escaneo agresivo: OS + versión + scripts (-A) [ruidoso]
     -c            Salida compacta: solo PUERTO / ESTADO / SERVICIO
     -m            Ejecuta tu herramienta personalizada (mi_herramienta)
     -n            Solo reconocimiento (ping + GeoIP), sin nmap
     -y            No preguntar antes de escanear (modo automático)
     -j            Muestra el JSON crudo de ip-api y sale
     -o ARCHIVO    Guarda el resultado completo de nmap en ARCHIVO
     -h            Ayuda

#USO AUTORIZADO ÚNICAMENTE. 
  Escanea solo sistemas de tu propiedad o para los que tengas permiso explícito y por escrito. El escaneo de
  puertos sin autorización es ilegal en la mayoría de los países 
#   Guiño Guiño 
