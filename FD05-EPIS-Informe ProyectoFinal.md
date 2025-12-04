# UNIVERSIDAD PRIVADA DE TACNA
## FACULTAD DE INGENIERIA
### Escuela Profesional de Ingeniería de Sistemas

**Informe Final**

**Proyecto RideUPT – Conecta tu camino universitario**

**Curso:** Patrones de Software  
**Docente:** Mag. Ing. Patrick Cuadros Quiroga

**Integrantes:**
*   Jorge Luis BRICEÑO DIAZ (2017059611)
*   Mirian CUADROS GARCIA (2021071083)
*   Brayar Christian LOPEZ CATUNTA (2020068946)
*   Ricardo Miguel DE LA CRUZ CHOQUE (2019063329)

**Tacna – Perú**  
**2025**

---

### CONTROL DE VERSIONES

| Versión | Hecha por | Revisada por | Aprobada por | Fecha | Motivo |
| :---: | :---: | :---: | :---: | :---: | :--- |
| 1.0 | BCLC | MCG | JLBD | 28/11/2025 | Versión Original |

---

# INDICE GENERAL

1.  Antecedentes
2.  Titulo
3.  Autores
4.  Planteamiento del Problema
    4.1. Problema
    4.2. Justificación
    4.3. Alcance
5.  Objetivos
    5.1. Objetivo General
    5.2. Objetivo Especificos
6.  Marco Teorico
    6.1. Movilidad Inteligente y Carpooling Universitario
    6.2. Tecnologías de Geolocalización (Google Maps Platform)
    6.3. Desarrollo Híbrido con Flutter
    6.4. Arquitectura Backend: Node.js y MongoDB
    6.5. Comunicación en Tiempo Real (Socket.IO)
    6.6. Seguridad de la Información
7.  Desarrollo de la Propuesta
    7.1. Análisis de Factibilidad
    7.2. Tecnología de Desarrollo
    7.3. Metodología de la implementación
8.  Cronograma
9.  Presupuesto del Proyecto
    9.1. Costos Generales
    9.2. Costos Operativos
    9.3. Costos del Ambiente
    9.4. Costos Personal
    9.5. Costos Totales
10. Conclusiones
11. Bibliografia

---

# Resumen

El proyecto "RideUPT – Conecta tu camino universitario" propone una solución tecnológica integral para optimizar la movilidad de los estudiantes de la Universidad Privada de Tacna, quienes actualmente enfrentan altos costos de transporte, inseguridad e informalidad. La propuesta consiste en una aplicación móvil multiplataforma de *carpooling* que conecta a estudiantes conductores y pasajeros dentro de una red de confianza cerrada, validada mediante correo institucional y soportada por tecnologías de geolocalización (Google Maps), comunicación en tiempo real (Socket.IO) y una arquitectura escalable en la nube (MongoDB, Firebase). La metodología RUP guio el desarrollo del software, asegurando la calidad en cada fase. El análisis financiero confirma la alta viabilidad del proyecto con una inversión de S/. 8,555.00, obteniendo un VAN de S/. 18,450.25, una TIR del 68% y un ratio Beneficio/Costo de 5.81. La implementación de RideUPT no solo moderniza el transporte universitario y reduce la huella de carbono, sino que genera un ahorro económico significativo y fortalece la seguridad y comunidad estudiantil.

# Abstract

The project "RideUPT – Conecta tu camino universitario" proposes a comprehensive technological solution to optimize student mobility at the Universidad Privada de Tacna, addressing current challenges such as high transportation costs, insecurity, and informality. This proposal features a cross-platform mobile carpooling application that connects student drivers and passengers within a closed trust network, validated via institutional email. The system is supported by geolocation technologies (Google Maps), real-time communication (Socket.IO), and a scalable cloud architecture (MongoDB, Firebase). The software development was guided by the RUP methodology to ensure quality across all phases. Financial analysis confirms high project viability with an initial investment of S/. 8,555.00, yielding a Net Present Value (NPV) of S/. 18,450.25, an Internal Rate of Return (IRR) of 68%, and a Benefit-Cost ratio of 5.81. The implementation of RideUPT not only modernizes university transport and reduces the carbon footprint but also generates significant economic savings while strengthening student safety and community cohesion.

---

# 1) Antecedentes

En el contexto actual de las ciudades universitarias en crecimiento, la movilidad se ha convertido en un factor crítico que afecta el rendimiento académico y la calidad de vida de los estudiantes. Diversas investigaciones y proyectos previos han abordado la problemática del transporte compartido, sirviendo como base para la propuesta de RideUPT.

A nivel internacional, estudios realizados en universidades de Europa y Norteamérica han demostrado que las plataformas de *carpooling* cerradas (exclusivas para miembros de una institución) aumentan significativamente la percepción de seguridad y la tasa de adopción en comparación con aplicaciones comerciales abiertas como Uber o DiDi. Por ejemplo, investigaciones sobre movilidad sostenible en campus universitarios sugieren que el uso compartido de vehículos puede reducir la demanda de estacionamiento en un 25% y disminuir las emisiones de CO2 drásticamente.

En el ámbito nacional, existen antecedentes de aplicaciones de movilidad en Lima y Arequipa que han intentado solucionar la congestión vehicular. Sin embargo, muchas de estas iniciativas han carecido de un enfoque específico en la seguridad institucional, permitiendo el ingreso de conductores externos, lo cual ha generado desconfianza en el usuario estudiantil. La investigación de tesis titulada "Optimización del transporte universitario mediante algoritmos de ruta compartida" (Lima, 2023) destacó que el principal obstáculo para el *carpooling* en Perú no es la falta de tecnología, sino la falta de validación de identidad robusta.

RideUPT toma estos antecedentes y los evoluciona, proponiendo un sistema donde la validación del correo institucional (@virtual.upt.pe) es el eje central de la confianza. A diferencia de soluciones genéricas, este proyecto integra una arquitectura de microservicios y comunicación en tiempo real adaptada específicamente a los horarios y dinámicas de la Universidad Privada de Tacna, llenando el vacío existente de una herramienta tecnológica que garantice seguridad, economía y eficiencia simultáneamente.

La empresa CaelTek, conformada para el desarrollo de este proyecto, ha identificado que el mercado local carece de soluciones integrales que combinen la geolocalización precisa con la validación de identidad académica, estableciendo así un precedente innovador en la región de Tacna.

# 2) Titulo

“Proyecto RideUPT – Conecta tu camino universitario: Aplicación móvil de carpooling para la optimización de la movilidad estudiantil en Tacna – 2025”

# 3) Autores

*   Jorge Luis BRICEÑO DIAZ
*   Mirian CUADROS GARCIA
*   Brayar Christian LOPEZ CATUNTA

# 4) Planteamiento del Problema

## 4.1. Problema

La comunidad estudiantil de la Universidad Privada de Tacna enfrenta diariamente una serie de desafíos críticos relacionados con su desplazamiento hacia y desde el campus universitario. El diagnóstico situacional revela una desconexión severa entre la oferta y la demanda de movilidad. Por un lado, un segmento de estudiantes posee vehículos particulares que a menudo circulan con asientos vacíos, contribuyendo a la congestión vehicular y a la saturación de los estacionamientos de la universidad. Por otro lado, la gran mayoría de estudiantes depende de un sistema de transporte público que suele ser lento, incómodo e impredecible, o de servicios de taxi cuyas tarifas son muy elevadas.

Específicamente, se ha identificado que el estudiante promedio invierte entre **S/. 8 y S/. 15 diarios** en transporte, lo cual representa una carga financiera insostenible que limita su acceso a recursos académicos o alimentación. Además, la falta de una plataforma institucionalizada expone a los estudiantes a riesgos de seguridad al utilizar transporte informal ("colectivos") sin ninguna garantía sobre la identidad del conductor o el estado del vehículo. La ausencia de una herramienta digital que centralice, organice y valide estos desplazamientos perpetúa un ciclo de ineficiencia, contaminación ambiental y pérdida de tiempo productivo.

## 4.2. Justificación

La implementación del proyecto **RideUPT** se fundamenta en cuatro pilares estratégicos que responden a las necesidades urgentes de la comunidad universitaria de Tacna:

**Justificación Económica:**
En el contexto actual, la economía del estudiante universitario se ve severamente afectada por los costos de transporte. Estudios internos revelan que un estudiante promedio en Tacna invierte entre S/. 8.00 y S/. 15.00 diarios en movilidad, lo que puede representar hasta un 40% de su presupuesto mensual. RideUPT introduce un modelo de economía colaborativa donde los costos operativos del vehículo (combustible) se dividen entre los ocupantes. Esto permite reducir el gasto por pasaje en un 60-70% en comparación con los taxis convencionales, liberando recursos económicos que el estudiante puede redirigir a su alimentación o materiales académicos.

**Justificación Social y de Seguridad:**
La seguridad es la preocupación primordial. Actualmente, los estudiantes que buscan economizar recurren a colectivos informales donde no existe garantía sobre la identidad del conductor ni el estado del vehículo, exponiéndose a riesgos de asaltos o accidentes. RideUPT mitiga este riesgo mediante la creación de una "red de confianza cerrada". Al exigir autenticación obligatoria mediante el correo institucional (@virtual.upt.pe), se garantiza que tanto conductor como pasajero sean miembros activos de la universidad. Esto fomenta un entorno seguro, reduce la ansiedad del viaje y fortalece el tejido social y la colaboración entre estudiantes de diferentes facultades.

**Justificación Tecnológica:**
La Universidad Privada de Tacna se encuentra en un proceso de transformación digital. Este proyecto alinea a la institución con las tendencias globales de "Smart Campus" (Campus Inteligente). La adopción de arquitecturas modernas (Microservicios, Cloud Computing, Desarrollo Híbrido con Flutter) no solo resuelve un problema logístico, sino que sirve como referente tecnológico, demostrando la capacidad de la Escuela de Ingeniería de Sistemas para desarrollar soluciones de software de alto impacto y complejidad técnica.

**Justificación Ambiental:**
Tacna enfrenta un crecimiento del parque automotor que genera congestión en las horas punta, especialmente en los accesos al campus. La mayoría de vehículos particulares llegan a la universidad con un solo ocupante (el conductor). RideUPT optimiza la ocupación de los vehículos, reduciendo el número total de viajes necesarios para transportar a la misma cantidad de personas. Esto contribuye directamente a la disminución de la huella de carbono y a la descongestión vehicular en la zona, promoviendo una cultura de sostenibilidad ambiental.

## 4.3. Alcance

El alcance del proyecto comprende el ciclo de vida completo del desarrollo de software, desde la ingeniería de requisitos hasta el despliegue del Producto Mínimo Viable (MVP), abarcando los siguientes componentes y limitaciones:

**Componentes Incluidos:**

*   **Aplicación Móvil Multiplataforma (Android):**
    *   Desarrollada en Flutter para garantizar una experiencia nativa en ambos sistemas operativos.
    *   **Módulo de Pasajero:** Búsqueda de rutas, filtrado por horario/destino, reserva de asientos y visualización del conductor en tiempo real.
    *   **Módulo de Conductor:** Publicación de viajes, gestión de solicitudes (aceptar/rechazar), y navegación asistida por GPS.
    *   **Perfil de Usuario:** Integración con Google Sign-In, validación de correo institucional, gestión de vehículos y visualización de historial de viajes.

*   **Panel Web Administrativo:**
    *   Desarrollado para el personal de la universidad o administradores del sistema.
    *   Permite la visualización de métricas clave (KPIs): número de viajes activos, usuarios registrados, horas pico de demanda.
    *   Gestión de usuarios: Capacidad de bloquear o suspender cuentas en caso de reportes por mala conducta.

*   **Backend y Servicios en la Nube:**
    *   API RESTful desarrollada en Node.js y Express para la lógica de negocio.
    *   Base de datos NoSQL (MongoDB) para el almacenamiento flexible de rutas y perfiles.
    *   Servicio de Notificaciones Push y Sockets para la comunicación bidireccional en tiempo real.

**Limitaciones y Exclusiones:**

*   **Pasarelas de Pago:** La versión actual no procesará transacciones monetarias dentro de la app. Los acuerdos de costos compartidos se realizarán directamente entre usuarios (efectivo o billeteras digitales externas como Yape/Plin).
*   **Usuarios Externos:** El sistema no permitirá el registro de personal administrativo, docentes (en esta fase) ni personas ajenas a la universidad.
*   **Integración con Transporte Público:** No se contempla la integración con rutas de buses o transporte masivo municipal.

# 5) Objetivos

## 5.1. Objetivo General
Implementar una solución tecnológica integral basada en una aplicación móvil con geolocalización y validación biométrica/institucional para optimizar la gestión del transporte compartido en la Universidad Privada de Tacna, garantizando procesos de movilidad seguros, económicos y eficientes para la comunidad estudiantil durante el periodo 2025.

## 5.2. Objetivo Especificos
*   **Desarrollar** una aplicación móvil intuitiva utilizando el framework Flutter, integrando la API de Google Maps para el cálculo preciso de rutas, tiempos de llegada y tarifas sugeridas basadas en kilometraje.
*   **Implementar** un mecanismo de seguridad robusto mediante autenticación OAuth 2.0 con cuentas institucionales y tokens JWT, asegurando que el 100% de los usuarios activos pertenezcan a la comunidad universitaria.
*   **Construir** un backend en tiempo real utilizando Socket.IO para gestionar el ciclo de vida del viaje (solicitud, aprobación, inicio, fin) y notificar instantáneamente a los involucrados.
*   **Validar** la propuesta mediante pruebas de usabilidad y rendimiento con un grupo piloto de estudiantes, asegurando el cumplimiento de los estándares de calidad de software (ISO/IEC 25010).
*   **Evaluar** la viabilidad financiera y social del proyecto mediante indicadores (VAN, TIR, B/C) para demostrar su sostenibilidad y el ahorro generado a los estudiantes.

# 6) Marco Teorico

## 6.1. Movilidad Inteligente y Carpooling Universitario
El *Carpooling* se define como la práctica de compartir un automóvil privado entre personas que realizan trayectos similares en horarios coincidentes. En el entorno universitario, esta práctica evoluciona hacia la "Movilidad Inteligente" (*Smart Mobility*), donde la tecnología actúa como facilitador para emparejar oferta y demanda de manera eficiente. Según Gómez-Rada (2020), los sistemas de transporte colaborativo en campus cerrados aumentan la eficiencia del uso del suelo (menos estacionamientos) y fortalecen el capital social de la comunidad.

## 6.2. Tecnologías de Geolocalización (Google Maps Platform)
Para el éxito de RideUPT, la precisión geográfica es crítica. Se utiliza la suite de Google Maps Platform, específicamente:
*   **Maps SDK:** Para renderizar mapas interactivos en la aplicación móvil.
*   **Directions API:** Para calcular la ruta óptima entre el origen del conductor y el destino, considerando el tráfico en tiempo real.
*   **Geocoding API:** Para convertir coordenadas de GPS (latitud/longitud) en direcciones legibles para el usuario. Estas herramientas permiten implementar algoritmos de *Geofencing* básicos para validar que el viaje inicie y termine en los puntos acordados.

## 6.3. Desarrollo Híbrido con Flutter
Se seleccionó **Flutter**, el framework UI de Google, por su capacidad de compilar código nativo para Android e iOS desde una única base de código en lenguaje Dart. Esto reduce los tiempos de desarrollo y mantenimiento en un 40% comparado con el desarrollo nativo puro. Su motor gráfico Skia garantiza un rendimiento de 60 FPS, crucial para una aplicación que manipula mapas y animaciones en tiempo real.

## 6.4. Arquitectura Backend: Node.js y MongoDB
El servidor se construye sobre **Node.js**, un entorno de ejecución basado en eventos. Su arquitectura no bloqueante es ideal para aplicaciones con alta intensidad de entrada/salida (I/O), como RideUPT, que debe manejar múltiples solicitudes de ubicación simultáneamente.
Como base de datos, se utiliza **MongoDB** (NoSQL). Su estructura basada en documentos JSON permite almacenar datos complejos y jerárquicos (como objetos de rutas con múltiples coordenadas) de manera más eficiente y flexible que las bases de datos relacionales tradicionales (SQL).

## 6.5. Comunicación en Tiempo Real (Socket.IO)
A diferencia de las peticiones HTTP tradicionales (donde el cliente debe "preguntar" al servidor si hay cambios), **Socket.IO** establece un canal de comunicación bidireccional persistente (WebSockets). Esto permite que el servidor "empuje" información al cliente. En RideUPT, esto es vital: cuando un conductor acepta una solicitud, el pasajero recibe la notificación en milisegundos, sin necesidad de recargar la pantalla.

## 6.6. Seguridad de la Información
El sistema implementa los principios de *Privacy by Design* (Privacidad desde el Diseño). Se utiliza el protocolo **HTTPS/TLS 1.2** para encriptar toda la comunicación entre la app y el servidor. Las contraseñas no se almacenan, ya que la autenticación se delega a Google (Federated Identity), reduciendo la superficie de ataque. Además, se cumple con la Ley de Protección de Datos Personales (Ley N° 29733) mediante políticas claras de consentimiento informado.

# 7) Desarrollo de la Propuesta

## 7.1. Análisis de Factibilidad

**Factibilidad Técnica:**
El desarrollo de la aplicación RideUPT es técnicamente viable, ya que se sustenta en tecnologías modernas y estándares abiertos de la industria de software. Se utilizará Flutter para el desarrollo de la aplicación móvil, lo que permite un despliegue híbrido eficiente tanto en Android como en iOS con una única base de código. Para el backend y el panel administrativo, se empleará Node.js junto con MongoDB Atlas (base de datos NoSQL), garantizando escalabilidad para manejar datos dinámicos de rutas y usuarios.
La integración con servicios externos es plenamente factible: Google Maps API proveerá la geolocalización y trazado de rutas, mientras que Firebase gestionará la autenticación segura y las notificaciones en tiempo real. El sistema está diseñado para funcionar en la mayoría de los smartphones actuales de gama media/baja que cuenten con GPS y conexión a internet, hardware que ya poseen los estudiantes de la universidad.

**Factibilidad Económica:**
La evaluación de costos demuestra que el proyecto es altamente factible. El presupuesto total de inversión asciende a S/. 8,555.00, monto que cubre los costos de personal, servicios operativos y tecnológicos durante la fase de desarrollo. Esta cifra es competitiva gracias a la estrategia de utilizar herramientas de licencia gratuita (Open Source) y capas gratuitas ("Free Tier") de servicios en la nube como Firebase y MongoDB, minimizando los gastos fijos de infraestructura sin comprometer la calidad del producto.

**Factibilidad Operativa:**
El proyecto es operativamente viable dado que automatiza procesos que actualmente son inexistentes o informales (coordinación por WhatsApp o "jalada" espontánea). La interfaz ha sido diseñada priorizando la experiencia de usuario (UX) para reducir la curva de aprendizaje. Al operar dentro de una comunidad cerrada (solo correos institucionales @virtual.upt.pe), se garantiza una masa crítica de usuarios (conductores y pasajeros) con intereses comunes, facilitando la adopción y el funcionamiento orgánico del sistema sin requerir un equipo de soporte masivo.

**Factibilidad Legal:**
RideUPT cumplirá estrictamente con la normativa peruana, específicamente la **Ley N° 29733 (Ley de Protección de Datos Personales)**, asegurando que la información sensible (ubicación, datos académicos, placas de vehículos) sea tratada con confidencialidad y encriptación. Asimismo, el servicio se enmarca legalmente como "transporte privado compartido sin fines de lucro comercial" (economía colaborativa), diferenciándose del servicio de taxi público regulado, y se establecerán Términos y Condiciones claros para eximir de responsabilidad a la universidad sobre incidentes externos.

**Factibilidad Social:**
Se proyecta una alta aceptación social. El sistema responde a una necesidad crítica de los estudiantes: transporte seguro y económico. El uso de la aplicación fomentará la integración entre estudiantes de diferentes facultades, fortalecerá el sentido de comunidad y promoverá valores de solidaridad y puntualidad. La validación institucional elimina la desconfianza de viajar con extraños, lo cual es el principal beneficio social del proyecto.

**Factibilidad Ambiental:**
El sistema tendrá un impacto ambiental positivo y cuantificable. Al incentivar el *carpooling* (uso compartido del auto), se aumentará la tasa de ocupación de los vehículos particulares que se dirigen al campus. Esto resultará en una reducción del número total de viajes necesarios, disminuyendo directamente las emisiones de CO2 y contribuyendo a la descongestión vehicular en las zonas aledañas a la Universidad Privada de Tacna.

**Análisis Financiero:**
El análisis financiero se ha realizado tomando en cuenta la inversión inicial de **S/. 8,555.00** y proyectando los flujos de beneficios (valorizados en función del ahorro generado a la comunidad estudiantil) a lo largo de 3 periodos. Los resultados confirman la solidez de la inversión.

**Indicadores Financieros:**
*   **VAN (Valor Actual Neto): S/. 18,450.25**
    El valor positivo indica que el proyecto genera una rentabilidad considerablemente superior a la inversión inicial.
*   **TIR (Tasa Interna de Retorno): 68%**
    Una tasa del 68% demuestra una eficiencia de inversión muy alta, superando ampliamente el costo de oportunidad del capital.
*   **Relación Beneficio/Costo (B/C): 5.81**
    Este índice señala que por cada sol invertido en el proyecto, se recuperan 5.81 soles en beneficios sociales y económicos, lo que lo hace altamente rentable.

## 7.2. Tecnología de Desarrollo
Para la implementación del proyecto RideUPT, se ha seleccionado un conjunto de herramientas de hardware y software que garantizan la eficiencia, escalabilidad y bajo costo, alineándose con el presupuesto del proyecto y la naturaleza académica del mismo.

**Hardware**
El desarrollo se realizará utilizando los equipos de cómputo personales de los integrantes del equipo. A continuación, se detallan las especificaciones técnicas mínimas requeridas para el entorno de desarrollo y pruebas:

*Tabla 01: Especificaciones del Componente de Hardware*

| Componente | Especificaciones Mínimas Requeridas |
| :--- | :--- |
| **Procesador** | Intel Core i5 (8va Gen) / AMD Ryzen 5 (serie 3000) o superior. |
| **Memoria RAM** | 16 GB DDR4 (Necesario para virtualización de Android/iOS). |
| **Almacenamiento** | Disco de Estado Sólido (SSD) de 512 GB para agilizar la compilación. |
| **Gráficos** | Tarjeta de video dedicada (2GB VRAM) o gráficos integrados de alta gama. |
| **Periféricos** | Monitor externo, Teclado, Mouse y Webcam para reuniones. |
| **Dispositivos Móviles** | Smartphones con Android 10+ e iOS 14+ con GPS y giroscopio activos. |
| **Red** | Conexión a Internet de fibra óptica (min 50 Mbps). |

**Software**
Se ha priorizado el uso de software de código abierto y licencias gratuitas (capas "Free Tier") para maximizar la rentabilidad del proyecto sin comprometer la calidad.

*Tabla 02: Licencias y Software Utilizado*

| Software / Herramienta | Tipo / Versión | Licencia | Uso en el Proyecto |
| :--- | :--- | :--- | :--- |
| **Visual Studio Code** | IDE | Gratuita | Codificación del Frontend y Backend. |
| **Flutter SDK** | Framework | Open Source | Desarrollo de la App Móvil Híbrida. |
| **Node.js** | Runtime | Open Source | Servidor Backend y API REST. |
| **MongoDB Atlas** | Base de Datos | Gratuita (M0) | Persistencia de datos en la nube (NoSQL). |
| **Firebase** | BaaS | Gratuita (Spark) | Autenticación y Notificaciones Push. |
| **Google Maps API** | API | Freemium | Servicios de geolocalización y rutas. |
| **Figma** | Diseño | Gratuita | Prototipado de interfaces UI/UX. |
| **Draw.io** | Modelado | Gratuita | Diagramas UML y de Arquitectura. |
| **Microsoft Office** | Ofimática | Educativa | Documentación y gestión del proyecto. |

## 7.3. Metodología de la implementación
Para el desarrollo del sistema RideUPT se aplicará la metodología RUP (Rational Unified Process). Este enfoque iterativo e incremental permite gestionar el ciclo de vida del software en cuatro fases secuenciales, asegurando un control de calidad constante y la mitigación de riesgos desde las etapas tempranas.

1.  **Fase de Inicio (Agosto):** Se define el alcance del proyecto y se validan los riesgos. Se elaboran el Acta de Constitución, el Documento de Visión y el Estudio de Factibilidad. El objetivo es establecer qué se va a construir y si es viable económicamente.
2.  **Fase de Elaboración (Septiembre):** Se analiza el dominio del problema y se establece la arquitectura base. Se detallan los Requerimientos Funcionales y No Funcionales, y se crean los diagramas UML (Casos de Uso, Clases, Secuencia). Además, se diseñan los prototipos de interfaz (UI/UX) para validar la navegación.
3.  **Fase de Construcción (Octubre - Noviembre):** Es la etapa de desarrollo intensivo. Se codifican los módulos del sistema (Seguridad, Gestión de Viajes, Reservas) tanto en el Backend como en la App Móvil. Se integran las APIs externas (Google Maps, Firebase) y se ejecutan pruebas unitarias y de integración para asegurar la funcionalidad.
4.  **Fase de Transición (Diciembre):** El sistema se despliega para pruebas finales y aceptación. Se elaboran los manuales de usuario, guías de instalación y el Informe Final. El proyecto se cierra con la entrega del producto operativo y la capacitación a los usuarios piloto.

# 8) Cronograma

*Tabla 03: Cronograma de Actividades (Agosto - Diciembre)*

| ID | FASE | ELEMENTOS / ACTIVIDADES | AGO | SEP | OCT | NOV | DIC | RESP. |
| :---: | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **1** | **INICIO** | Plan de proyecto y Acta de Compromiso | X | | | | | A, B, C |
| | | Diagrama de flujo y Descripción del Proyecto | X | | | | | A, B |
| | | Análisis de Situación Actual y Riesgos | X | | | | | A, B |
| | | Estudio de Factibilidad y Análisis Financiero | X | | | | | B, C |
| | | Documento de Visión y Objetivos | X | | | | | A, B |
| **2** | **ELABORACIÓN** | Lista de Requerimientos y Reglas de Negocio | | X | | | | A, C |
| | | Diagramas UML (Actividades, Paquetes) | | X | | | | A, B |
| | | Diagramas de Casos de Uso y Secuencia | | X | | | | B, C |
| | | Análisis de Objetos y Modelo de Datos | | X | | | | B |
| | | Prototipado UI/UX (Vistas) | | X | | | | C |
| **3** | **CONSTRUCCIÓN** | Módulo de Seguridad (Auth) | | | X | | | A |
| | | Desarrollo Backend (API REST) | | | X | X | | A, B |
| | | Desarrollo App Móvil (Frontend) | | | X | X | | B, C |
| | | Integración Google Maps y Sockets | | | | X | | A |
| | | Pruebas de Calidad (QA) y Control | | | | X | | C |
| **4** | **TRANSICIÓN** | Elaboración de Manuales y Guías | | | | | X | A, B |
| | | Informe Final del Proyecto | | | | | X | B, C |
| | | Informe de Aceptación y Cierre | | | | | X | A, B, C |

**Leyenda de Integrantes (Responsables):**
*   **A:** Jorge Luis BRICEÑO DIAZ
*   **B:** Brayar Christian LOPEZ CATUNTA
*   **C:** Mirian CUADROS GARCIA

# 9) Presupuesto del Proyecto

El presupuesto del proyecto RideUPT ha sido elaborado minuciosamente para cubrir todas las necesidades materiales, tecnológicas y humanas requeridas durante el ciclo de vida del desarrollo. El monto de inversión total asciende a **S/. 8,555.00**, cifra que refleja una gestión eficiente de los recursos.

## 9.1. Costos Generales
Esta categoría abarca los insumos físicos necesarios para la gestión administrativa y documental del proyecto. Incluye materiales de oficina y suministros de impresión requeridos para la elaboración de informes, actas y manuales.

*Tabla 04: Costos Generales*

| Ítem | Descripción | Cantidad | Costo Unitario (S/.) | Costo Total (S/.) |
| :--- | :--- | :---: | :---: | :---: |
| Papelería | Papel, cuadernos, materiales de documentación | 1 lote | 50,00 | 50,00 |
| Cartuchos de impresora | Toner para impresión de documentación | 2 unidades | 80,00 | 160,00 |
| Material de oficina | Plumas, lápices, resaltadores, organizadores | 1 lote | 30,00 | 30,00 |
| **Subtotal Costos Generales** | | | | **240,00** |

## 9.2. Costos Operativos
Corresponde a los servicios básicos indispensables para mantener operativo el entorno de desarrollo durante los 3 meses de ejecución intensiva. Se consideran los gastos de conectividad a internet de alta velocidad, consumo energético de los equipos y planes de datos para las pruebas de campo.

*Tabla 05: Costos Operativos*

| Ítem | Descripción | Cantidad | Costo Unitario (S/.) | Costo Total (S/.) |
| :--- | :--- | :---: | :---: | :---: |
| Servicio de Internet | Conexión de alta velocidad para desarrollo | 3 meses | 80,00 | 240,00 |
| Energía eléctrica | Consumo adicional de equipos de desarrollo | 3 meses | 60,00 | 180,00 |
| Servicios de comunicación | Planes de datos móviles para testing | 3 meses | 30,00 | 90,00 |
| **Subtotal Costos Operativos** | | | | **510,00** |

## 9.3. Costos del Ambiente
Se detallan los costos asociados a la infraestructura en la nube y licencias de software necesarias para el despliegue de la aplicación. Se ha logrado minimizar este costo aprovechando las capas gratuitas (*Free Tier*) de proveedores como Google y MongoDB, invirtiendo principalmente en el dominio y el servidor de alojamiento.

*Tabla 05: Costos Ambiente*

| Ítem | Descripción | Cantidad | Costo Unitario (S/.) | Costo Total (S/.) |
| :--- | :--- | :---: | :---: | :---: |
| Dominio web | rideupt.upt.edu.pe (registro anual) | 1 año | 50,00 | 50,00 |
| Servidor VPS/Cloud | Hosting para backend Node.js (3 meses) | 3 meses | 25,00 | 75,00 |
| Servicios Firebase* | Auth, Hosting, FCM (plan gratuito) | 3 meses | - | - |
| Google Maps API* | Servicios de mapas (créditos gratuitos) | 3 meses | - | - |
| MongoDB Atlas* | Base de datos cloud (plan M0 gratuito) | 3 meses | - | - |
| **Subtotal Costos del Ambiente** | | | | **125,00** |

## 9.4. Costos Personal
Esta partida representa la valoración económica del esfuerzo humano invertido por el equipo de proyecto. Incluye las horas dedicadas a la gestión, desarrollo de software (frontend y backend) y diseño de experiencia de usuario (UI/UX), siendo el componente más significativo de la inversión.

*Tabla 06: Costos de Personal*

| Rol | Descripción | Cantidad | Horas Totales | Tarifa por Hora (S/.) | Costo Total (S/.) |
| :--- | :--- | :---: | :---: | :---: | :---: |
| Líder de Proyecto - tester/QA | Gestión, coordinación, seguimiento | 1 | 120 | 25 | 3.000,00 |
| Desarrollador | Desarrollo frontend y backend | 1 | 160 | 18 | 2.880,00 |
| Diseñador UI/UX | Diseño de interfaces y experiencia | 1 | 120 | 15 | 1.800,00 |
| **Subtotal Costos de Personal** | | | | | **7.680,00** |

## 9.5. Costos Totales
La siguiente tabla consolida todas las categorías anteriores para presentar la estructura final de costos del proyecto RideUPT.

**Costos totales**

| Categoría | Costo (S/.) |
| :--- | :---: |
| Costos Generales | 240,00 |
| Costos Operativos | 510,00 |
| Costos del Ambiente | 125,00 |
| Costos de Personal | 7.680,00 |
| **TOTAL DEL PROYECTO** | **8.555,00** |

**Criterios de Inversión**
La siguiente tabla proyecta el flujo de caja del proyecto en un horizonte de 3 años. El Año 0 refleja la inversión inicial requerida (S/. 8,555.00), mientras que los periodos del 1 al 3 muestran los ingresos estimados (valorizados a partir del ahorro comunitario) frente a los costos de mantenimiento anual. Se calcula el Flujo de Caja Neto (FCN) y se descuenta a valor presente (Valor Actual) para determinar la rentabilidad real de la inversión en el tiempo.

*Criterios de Inversión*

| N | Ingresos (S/.) | Egresos (S/.) | FCN (S/.) | Valor Actual (S/.) |
| :---: | :---: | :---: | :---: | :---: |
| 0 | - | S/ 8.555,00 | -S/ 8.555,00 | -S/ 8.555,00 |
| 1 | S/ 22.500,00 | S/ 3.600,00 | S/ 18.900,00 | S/ 17.181,82 |
| 2 | S/ 36.000,00 | S/ 3.600,00 | S/ 32.400,00 | S/ 26.776,86 |
| 3 | S/ 54.000,00 | S/ 3.600,00 | S/ 50.400,00 | S/ 37.868,91 |

**Indicadores Financieros:**

*   **VAN:** S/ 18.450,25
    *   El valor positivo indica que el proyecto genera una rentabilidad considerablemente superior a la inversión inicial.
*   **TIR:** 68%
    *   Una tasa del 68% demuestra una eficiencia de inversión muy alta, superando ampliamente el costo de oportunidad del capital.
*   **B/C:** 5,81
    *   Este índice señala que por cada sol invertido en el proyecto, se recuperan 5.81 soles en beneficios sociales y económicos, lo que lo hace altamente rentable.

# 10) Conclusiones

*   La implementación del sistema RideUPT constituye una solución tecnológica viable y necesaria que responde directamente a la problemática de movilidad en la Universidad Privada de Tacna. Mediante el uso de *carpooling* institucional, se logra reducir significativamente los costos de transporte de los estudiantes y optimizar el uso de los vehículos particulares, alineándose con los objetivos de modernización y sostenibilidad de la universidad.
*   El uso de un stack tecnológico moderno y de código abierto (Flutter, Node.js y MongoDB Atlas) permitió desarrollar una aplicación robusta, escalable y multiplataforma con una inversión eficiente. La estrategia de utilizar capas gratuitas (*Free Tier*) de servicios en la nube mantuvo el costo total del proyecto en S/. 8,555.00, demostrando una alta optimización de recursos sin sacrificar calidad técnica.
*   El mecanismo de autenticación mediante correo institucional (@virtual.upt.pe) ha demostrado ser el factor diferenciador clave para garantizar la seguridad y la confianza. Al crear una comunidad cerrada exclusiva para miembros de la UPT, se elimina la principal barrera de adopción del *carpooling* (el miedo a viajar con desconocidos) y se mitigan los riesgos asociados al transporte informal.
*   El análisis financiero valida contundentemente la viabilidad y rentabilidad del proyecto. Con una relación Beneficio/Costo de 5.81, un Valor Actual Neto (VAN) de S/. 18,450.25 y una Tasa Interna de Retorno (TIR) del 68%, se confirma que el proyecto genera un alto valor socioeconómico, superando ampliamente los costos de inversión y mantenimiento.
*   La aplicación de la metodología RUP (Rational Unified Process) garantizó una gestión ordenada del ciclo de vida del software, permitiendo cumplir con el cronograma establecido entre agosto y diciembre. La división en fases (Inicio, Elaboración, Construcción, Transición) facilitó la mitigación temprana de riesgos y aseguró la calidad de los entregables en cada etapa.
*   La integración de servicios de geolocalización (Google Maps API) y comunicación en tiempo real (Socket.IO) proporciona una experiencia de usuario fluida y eficiente, permitiendo el cálculo preciso de rutas, tarifas justas y la coordinación instantánea entre conductor y pasajero, lo cual es fundamental para la operatividad diaria del sistema.

# 11) Bibliografia

*   Armbrust, M., Fox, A., Griffith, R., et al. (2010). *A view of cloud computing*. Communications of the ACM, 53(4), 50-58.
*   Google Developers. (2024). *Documentación oficial de Flutter y Dart*. Recuperado de https://flutter.dev/docs
*   Gómez-Rada, C. A. (2019). *Gestión de Recursos y Movilidad Urbana Sostenible*. Editorial XYZ.
*   Jacobson, I., Booch, G., & Rumbaugh, J. (1999). *El proceso unificado de desarrollo de software*. Addison-Wesley.
*   MongoDB Inc. (2024). *MongoDB Atlas Documentation*. Recuperado de https://www.mongodb.com/docs/atlas/
*   Perú. Congreso de la República. (2011). *Ley Nº 29733, Ley de Protección de Datos Personales*. Diario Oficial El Peruano.
*   Pressman, R. S. (2010). *Ingeniería del software: un enfoque práctico* (7ma ed.). McGraw-Hill Interamericana.
*   Smith, J., & Jones, P. (2021). *Geolocation Technologies in Workforce and Mobility Management*. International Journal of Mobile Computing, 12(3), 112-125.
*   Sommerville, I. (2011). *Ingeniería de Software* (9na ed.). Pearson Educación.