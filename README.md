# RideUPT – Conecta tu camino universitario

<div align="center">

![Logo](./media/logo-upt.png)

**UNIVERSIDAD PRIVADA DE TACNA**

**FACULTAD DE INGENIERIA**

**Escuela Profesional de Ingeniería de Sistemas**

**Proyecto RideUPT – Conecta tu camino universitario**

**Curso:** Patrones de Software

**Docente:** Mag. Ing. Patrick Cuadros Quiroga

---

**Integrantes:**

- Jorge Luis BRICEÑO DIAZ (2017059611)
- Mirian CUADROS GARCIA (2021071083)
- Brayar Christian LOPEZ CATUNTA (2020068946)
- Ricardo Miguel DE LA CRUZ CHOQUE (2019063329)

**Tacna – Perú | 2025**

---

[![Issues](https://img.shields.io/badge/Issue-%238-blue)](https://github.com/your-repo/issues/8)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Activo-success)]()

</div>

---

## 📋 Tabla de Contenidos

1. [Introducción](#-introducción)
2. [Descripción del Proyecto](#-descripción-del-proyecto)
3. [Arquitectura del Sistema](#-arquitectura-del-sistema)
4. [Tecnologías Utilizadas](#-tecnologías-utilizadas)
5. [Modelo de Base de Datos](#-modelo-de-base-de-datos)
6. [Componentes del Sistema](#-componentes-del-sistema)
7. [Flujos de Usuario](#-flujos-de-usuario)
8. [Casos de Uso](#-casos-de-uso)
9. [Estados del Sistema](#-estados-del-sistema)
10. [Despliegue](#-despliegue)
11. [Características Principales](#-características-principales)
12. [Instalación y Configuración](#-instalación-y-configuración)
13. [Estructura del Proyecto](#-estructura-del-proyecto)

---

## 🎯 Introducción

RideUPT es una plataforma de carpooling universitario diseñada para conectar estudiantes de la Universidad Privada de Tacna (UPT) que necesitan viajar desde y hacia el campus. La aplicación facilita el compartir vehículos entre estudiantes, promoviendo la movilidad sostenible, la reducción de costos de transporte y el fortalecimiento de la comunidad universitaria.

RideUPT es una plataforma de carpooling universitario diseñada para conectar estudiantes de la Universidad Privada de Tacna (UPT) que necesitan viajar desde y hacia el campus. La aplicación facilita el compartir vehículos entre estudiantes, promoviendo la movilidad sostenible, la reducción de costos de transporte y el fortalecimiento de la comunidad universitaria.

### Problema que Resuelve

Los estudiantes universitarios enfrentan desafíos diarios para llegar al campus:
- **Costos elevados** de transporte público o privado
- **Falta de opciones** de movilidad asequibles
- **Horarios limitados** de transporte público
- **Inseguridad** en rutas de transporte público

### Solución Propuesta

RideUPT ofrece una plataforma segura y confiable donde:
- Los estudiantes **conducen** pueden ofrecer asientos disponibles en sus vehículos
- Los estudiantes **pasajeros** pueden buscar y reservar viajes
- Se implementa un **sistema de calificaciones** para garantizar seguridad y confianza
- Se proporciona **seguimiento en tiempo real** de viajes
- Se integra **autenticación con Google** para mayor seguridad

---

## 📖 Descripción del Proyecto

RideUPT es una aplicación móvil multiplataforma desarrollada con Flutter, respaldada por un backend robusto en Node.js con Express y MongoDB. El sistema implementa comunicación en tiempo real mediante Socket.io, notificaciones push con Firebase Cloud Messaging, y un sistema completo de autenticación y autorización.

### Objetivos del Proyecto

#### Objetivo General
Desarrollar una plataforma de carpooling universitario que permita a los estudiantes de la UPT compartir viajes de manera segura, eficiente y económica.

#### Objetivos Específicos
1. Implementar un sistema de registro y autenticación seguro con validación de identidad universitaria
2. Desarrollar funcionalidades para creación y búsqueda de viajes con geolocalización
3. Integrar sistema de calificaciones y comentarios para garantizar confianza
4. Implementar comunicación en tiempo real entre conductores y pasajeros
5. Desarrollar panel de administración para gestión de usuarios y viajes

---

## 🏗️ Arquitectura del Sistema

El sistema RideUPT sigue una arquitectura cliente-servidor con separación de responsabilidades entre frontend y backend, utilizando servicios externos para funcionalidades específicas.

```mermaid
graph TB
    subgraph "Cliente"
        A[App Flutter<br/>iOS/Android/Web]
    end
    
    subgraph "Backend API"
        B[Node.js + Express<br/>Server RESTful]
        C[Socket.io<br/>Tiempo Real]
        D[Middleware<br/>Auth & Validation]
    end
    
    subgraph "Servicios Externos"
        E[(MongoDB Atlas<br/>Base de Datos)]
        F[Firebase<br/>Auth & Storage & FCM]
        G[Google Maps API<br/>Geolocalización]
    end
    
    A -->|HTTP/HTTPS| B
    A -->|WebSocket| C
    B --> D
    D --> E
    B --> F
    B --> G
    C --> E
    
    style A fill:#1E88E5,color:#fff
    style B fill:#0288D1,color:#fff
    style C fill:#00ACC1,color:#fff
    style E fill:#10B981,color:#fff
    style F fill:#FF6F00,color:#fff
    style G fill:#4285F4,color:#fff
```

### Capas de la Arquitectura

1. **Capa de Presentación (Frontend)**: Flutter multiplataforma
2. **Capa de Aplicación (Backend)**: Node.js con Express
3. **Capa de Datos**: MongoDB Atlas con Mongoose ODM
4. **Capa de Servicios**: Firebase, Google Maps, Socket.io

---

## 💻 Tecnologías Utilizadas

### Stack Tecnológico Completo

```mermaid
mindmap
  root((RideUPT))
    Frontend
      Flutter
      Dart
      Provider
      Google Maps
      Socket.io Client
      Firebase Auth
    Backend
      Node.js
      Express.js
      Socket.io
      Mongoose
      JWT
      Bcrypt
    Base de Datos
      MongoDB Atlas
      Mongoose ODM
      Índices Geoespaciales
    Servicios Cloud
      Firebase
        Authentication
        Cloud Messaging
        Storage
      Google Maps API
        Geocoding
        Directions
        Places
    Infraestructura
      Docker
      Nginx
      HTTPS
      SSL/TLS
```

### Tecnologías por Capa

#### Frontend
- **Framework**: Flutter 3.7.2+
- **Lenguaje**: Dart
- **State Management**: Provider
- **Mapas**: Google Maps Flutter
- **Comunicación**: Socket.io Client, HTTP
- **Autenticación**: Google Sign-In, Firebase Auth
- **Notificaciones**: Firebase Cloud Messaging
- **Almacenamiento**: Shared Preferences, Secure Storage

#### Backend
- **Runtime**: Node.js
- **Framework**: Express.js
- **Base de Datos**: MongoDB con Mongoose
- **Autenticación**: JWT, Bcrypt
- **Tiempo Real**: Socket.io
- **Validación**: Express-validator
- **Upload**: Multer, Firebase Storage
- **Notificaciones**: Firebase Admin SDK

#### DevOps
- **Contenedores**: Docker, Docker Compose
- **Proxy Reverso**: Nginx
- **CI/CD**: Scripts de despliegue
- **Hosting**: VPS con HTTPS

---

## 🗄️ Modelo de Base de Datos

El modelo de datos está diseñado para soportar usuarios (conductores y pasajeros), viajes, calificaciones y documentos de conductores.

```mermaid
erDiagram
    USER ||--o{ TRIP : "crea (driver)"
    USER ||--o{ RATING : "recibe"
    USER ||--o{ RATING : "da"
    TRIP ||--o{ PASSENGER : "contiene"
    TRIP ||--o{ RATING : "tiene"
    USER ||--o{ DRIVER_DOCUMENT : "tiene"
    
    USER {
        ObjectId _id PK
        string firstName
        string lastName
        string email UK
        string password
        string phone
        string university
        string studentId
        number age
        string gender
        string bio
        string role
        boolean isAdmin
        string profilePhoto
        boolean isDriverProfileComplete
        string driverApprovalStatus
        object vehicle
        array driverDocuments
        string fcmToken
        number averageRating
        number totalRatings
        timestamp createdAt
        timestamp updatedAt
    }
    
    TRIP {
        ObjectId _id PK
        ObjectId driver FK
        object origin
        object destination
        date departureTime
        date expiresAt
        number availableSeats
        number seatsBooked
        number pricePerSeat
        string description
        string status
        array passengers
        timestamp createdAt
        timestamp updatedAt
    }
    
    RATING {
        ObjectId _id PK
        ObjectId rater FK
        ObjectId rated FK
        ObjectId trip FK
        number rating
        string comment
        string ratingType
        timestamp createdAt
        timestamp updatedAt
    }
    
    PASSENGER {
        ObjectId user FK
        string status
        date bookedAt
        boolean inVehicle
    }
    
    DRIVER_DOCUMENT {
        string tipoDocumento
        string urlImagen
        date subidoEn
    }
    
    VEHICLE {
        string make
        string model
        number year
        string color
        string licensePlate UK
        number totalSeats
    }
```

### Relaciones Principales

1. **USER → TRIP**: Un usuario (conductor) puede crear múltiples viajes
2. **TRIP → PASSENGER**: Un viaje puede tener múltiples pasajeros
3. **USER → RATING**: Un usuario puede recibir y dar múltiples calificaciones
4. **TRIP → RATING**: Un viaje puede tener múltiples calificaciones asociadas
5. **USER → DRIVER_DOCUMENT**: Un conductor puede tener múltiples documentos

### Índices Clave

- Índice geoespacial en `origin` y `destination` de TRIP para búsquedas por ubicación
- Índice único en `email` de USER
- Índice único SPARSE en `vehicle.licensePlate` de USER
- Índices en campos de búsqueda frecuente (status, driver, rater, rated)

---

## 🔧 Componentes del Sistema

### Backend - Componentes y Módulos

```mermaid
graph LR
    subgraph "Backend Architecture"
        A[Server.js<br/>Entry Point] --> B[Routes]
        B --> C[Controllers]
        C --> D[Models]
        C --> E[Services]
        C --> F[Middleware]
        
        B --> B1[Auth Routes]
        B --> B2[User Routes]
        B --> B3[Trip Routes]
        B --> B4[Rating Routes]
        B --> B5[Admin Routes]
        
        C --> C1[Auth Controller]
        C --> C2[User Controller]
        C --> C3[Trip Controller]
        C --> C4[Rating Controller]
        C --> C5[Admin Controller]
        
        E --> E1[Socket Service]
        E --> E2[Notification Service]
        E --> E3[Trip Chat Service]
        
        F --> F1[Auth Middleware]
        F --> F2[Error Handler]
        
        D --> D1[User Model]
        D --> D2[Trip Model]
        D --> D3[Rating Model]
    end
    
    style A fill:#1E88E5,color:#fff
    style E1 fill:#00ACC1,color:#fff
    style E2 fill:#FF6F00,color:#fff
```

#### Módulos Backend

- **Routes**: Define endpoints de la API REST
- **Controllers**: Lógica de negocio y manejo de requests
- **Models**: Esquemas de MongoDB con Mongoose
- **Services**: Servicios auxiliares (Socket, Notificaciones, Chat)
- **Middleware**: Autenticación JWT, validación, manejo de errores

### Frontend - Arquitectura de Componentes

```mermaid
graph TB
    subgraph "Frontend Architecture"
        A[main.dart<br/>Entry Point] --> B[Providers]
        A --> C[Screens]
        A --> D[Services]
        A --> E[Widgets]
        
        B --> B1[Auth Provider]
        B --> B2[Trip Provider]
        
        C --> C1[Auth Screens]
        C --> C2[Home Screens]
        C --> C3[Trip Screens]
        C --> C4[Profile Screens]
        C --> C5[Admin Screens]
        
        D --> D1[API Service]
        D --> D2[Socket Service]
        D --> D3[Auth Services]
        D --> D4[Notification Service]
        
        E --> E1[Reusable Widgets]
        E --> E2[Custom Widgets]
    end
    
    style A fill:#1E88E5,color:#fff
    style B1 fill:#0288D1,color:#fff
    style B2 fill:#0288D1,color:#fff
```

#### Módulos Frontend

- **Providers**: Gestión de estado con Provider pattern
- **Screens**: Pantallas de la aplicación organizadas por módulo
- **Services**: Servicios para comunicación con backend y APIs externas
- **Widgets**: Componentes reutilizables de UI
- **Models**: Modelos de datos Dart
- **Utils**: Utilidades (mapas, imágenes, config)

---

## 🔄 Flujos de Usuario

### Flujo Principal: Búsqueda y Reserva de Viaje

```mermaid
sequenceDiagram
    participant P as Pasajero
    participant A as App Flutter
    participant B as Backend API
    participant D as Conductor
    participant DB as MongoDB
    participant S as Socket.io
    
    P->>A: 1. Abre app y busca viajes
    A->>B: 2. GET /api/trips/search
    B->>DB: 3. Busca viajes disponibles
    DB-->>B: 4. Retorna lista de viajes
    B-->>A: 5. Lista de viajes disponibles
    A-->>P: 6. Muestra viajes en mapa
    
    P->>A: 7. Selecciona viaje
    A->>B: 8. POST /api/trips/:id/book
    B->>DB: 9. Actualiza viaje (añade pasajero)
    DB-->>B: 10. Confirma reserva
    B->>S: 11. Emite evento "trip:booked"
    S->>D: 12. Notifica al conductor
    B-->>A: 13. Confirmación de reserva
    A-->>P: 14. Muestra confirmación
    
    Note over P,D: Viaje en proceso
    D->>A: 15. Inicia viaje
    A->>B: 16. PUT /api/trips/:id/start
    B->>S: 17. Emite "trip:started"
    S->>P: 18. Notifica inicio de viaje
    
    Note over P,D: Viaje completado
    D->>A: 19. Completa viaje
    A->>B: 20. PUT /api/trips/:id/complete
    B->>S: 21. Emite "trip:completed"
    S->>P: 22. Notifica finalización
    B-->>A: 23. Solicita calificación
    A-->>P: 24. Muestra formulario de calificación
```

### Flujo: Creación de Viaje por Conductor

```mermaid
flowchart TD
    A[Conductor abre app] --> B[Selecciona 'Crear Viaje']
    B --> C[Ingresa origen]
    C --> D[Ingresa destino]
    D --> E[Selecciona fecha/hora]
    E --> F[Ingresa precio y asientos]
    F --> G[Publica viaje]
    G --> H{Validación exitosa?}
    H -->|No| I[Muestra errores]
    I --> F
    H -->|Sí| J[Backend crea viaje]
    J --> K[Viaje visible para pasajeros]
    K --> L[Espera reservas]
    L --> M{Pasajero reserva?}
    M -->|Sí| N[Recibe notificación]
    N --> O[Viaje con pasajeros]
    M -->|No| P{Expira tiempo?}
    P -->|Sí| Q[Viaje expirado]
    P -->|No| L
    O --> R[Inicia viaje]
    R --> S[Completa viaje]
    S --> T[Recibe calificaciones]
    
    style A fill:#1E88E5,color:#fff
    style K fill:#10B981,color:#fff
    style Q fill:#EF4444,color:#fff
```

---

## 👥 Casos de Uso

### Diagrama de Casos de Uso Principal

```mermaid
graph TB
    subgraph "Actores"
        A1[Pasajero]
        A2[Conductor]
        A3[Administrador]
    end
    
    subgraph "Casos de Uso - Autenticación"
        UC1[Registrarse]
        UC2[Iniciar Sesión]
        UC3[Autenticación Google]
        UC4[Recuperar Contraseña]
    end
    
    subgraph "Casos de Uso - Pasajero"
        UC5[Buscar Viajes]
        UC6[Reservar Viaje]
        UC7[Ver Mis Viajes]
        UC8[Cancelar Reserva]
        UC9[Calificar Conductor]
        UC10[Chat con Conductor]
    end
    
    subgraph "Casos de Uso - Conductor"
        UC11[Crear Viaje]
        UC12[Ver Mis Viajes Creados]
        UC13[Aceptar/Rechazar Reserva]
        UC14[Iniciar Viaje]
        UC15[Completar Viaje]
        UC16[Calificar Pasajero]
        UC17[Subir Documentos]
        UC18[Registrar Vehículo]
    end
    
    subgraph "Casos de Uso - Administrador"
        UC19[Gestionar Usuarios]
        UC20[Aprobar/Rechazar Conductores]
        UC21[Ver Estadísticas]
        UC22[Gestionar Viajes]
        UC23[Ver Reportes]
    end
    
    A1 --> UC1
    A1 --> UC2
    A1 --> UC3
    A1 --> UC5
    A1 --> UC6
    A1 --> UC7
    A1 --> UC8
    A1 --> UC9
    A1 --> UC10
    
    A2 --> UC1
    A2 --> UC2
    A2 --> UC11
    A2 --> UC12
    A2 --> UC13
    A2 --> UC14
    A2 --> UC15
    A2 --> UC16
    A2 --> UC17
    A2 --> UC18
    
    A3 --> UC19
    A3 --> UC20
    A3 --> UC21
    A2 --> UC22
    A3 --> UC23
    
    style A1 fill:#1E88E5,color:#fff
    style A2 fill:#10B981,color:#fff
    style A3 fill:#F59E0B,color:#fff
```

### Descripción de Casos de Uso Clave

#### UC-001: Buscar Viajes (Pasajero)
**Actor**: Pasajero  
**Precondiciones**: Usuario autenticado, ubicación disponible  
**Flujo Principal**:
1. Usuario abre la pantalla de búsqueda
2. Sistema muestra mapa con ubicación actual
3. Usuario ingresa destino
4. Sistema busca viajes disponibles cerca del origen y destino
5. Sistema muestra lista de viajes en el mapa
6. Usuario puede filtrar por fecha, precio, asientos disponibles

#### UC-002: Crear Viaje (Conductor)
**Actor**: Conductor  
**Precondiciones**: Usuario autenticado como conductor, perfil completo  
**Flujo Principal**:
1. Conductor selecciona "Crear Viaje"
2. Sistema solicita origen, destino, fecha/hora, precio, asientos
3. Conductor completa información
4. Sistema valida datos y crea viaje
5. Sistema publica viaje para que pasajeros lo vean
6. Viaje expira automáticamente después de 6 minutos si no hay reservas

#### UC-003: Reservar Viaje (Pasajero)
**Actor**: Pasajero  
**Precondiciones**: Viaje disponible, asientos libres  
**Flujo Principal**:
1. Pasajero selecciona un viaje
2. Sistema muestra detalles del viaje
3. Pasajero confirma reserva
4. Sistema notifica al conductor
5. Sistema actualiza disponibilidad de asientos
6. Pasajero recibe confirmación

---

## 🔀 Estados del Sistema

### Máquina de Estados: Viaje

```mermaid
stateDiagram-v2
    [*] --> esperando: Conductor crea viaje
    
    esperando --> completo: Pasajeros reservan todos los asientos
    esperando --> en_proceso: Conductor inicia viaje
    esperando --> expirado: Tiempo de expiración (6 min)
    esperando --> cancelado: Conductor cancela
    
    completo --> en_proceso: Conductor inicia viaje
    completo --> cancelado: Conductor cancela
    
    en_proceso --> completado: Viaje finalizado exitosamente
    en_proceso --> cancelado: Viaje cancelado durante trayecto
    
    expirado --> [*]
    cancelado --> [*]
    completado --> [*]
    
    note right of esperando
        Viaje creado y visible
        para pasajeros
        Esperando reservas
    end note
    
    note right of completo
        Todos los asientos
        reservados
        Listo para iniciar
    end note
    
    note right of en_proceso
        Viaje en curso
        Tracking activo
    end note
```

### Estados de Reserva de Pasajero

```mermaid
stateDiagram-v2
    [*] --> pending: Pasajero reserva viaje
    
    pending --> confirmed: Conductor acepta reserva
    pending --> rejected: Conductor rechaza reserva
    pending --> cancelled: Pasajero cancela antes de aceptación
    
    confirmed --> in_vehicle: Pasajero sube al vehículo
    confirmed --> cancelled: Pasajero cancela después de aceptación
    
    in_vehicle --> completed: Viaje completado
    
    rejected --> [*]
    cancelled --> [*]
    completed --> [*]
    
    note right of pending
        Reserva pendiente
        Esperando confirmación
        del conductor
    end note
    
    note right of confirmed
        Reserva confirmada
        Viaje programado
    end note
```

### Estados de Aprobación de Conductor

```mermaid
stateDiagram-v2
    [*] --> sin_solicitud: Usuario es pasajero
    
    sin_solicitud --> pending: Usuario solicita ser conductor
    pending --> approved: Administrador aprueba
    pending --> rejected: Administrador rechaza
    
    approved --> [*]: Conductor activo
    rejected --> [*]: Solicitud rechazada
    
    note right of pending
        Usuario ha subido
        documentos requeridos
        Esperando revisión
    end note
    
    note right of approved
        Conductor puede
        crear viajes
    end note
```

---

## 🚀 Despliegue

### Arquitectura de Despliegue

```mermaid
graph TB
    subgraph "Cliente"
        U[Usuarios]
        M[Móvil iOS/Android]
        W[Web Browser]
    end
    
    subgraph "CDN & Load Balancer"
        LB[Nginx<br/>Reverse Proxy<br/>SSL/TLS]
    end
    
    subgraph "Servidor de Aplicación"
        D[Docker Container]
        API[Node.js API<br/>Express + Socket.io]
    end
    
    subgraph "Servicios Cloud"
        MONGO[(MongoDB Atlas<br/>Cluster)]
        FIREBASE[Firebase<br/>Auth + FCM + Storage]
        MAPS[Google Maps API]
    end
    
    subgraph "Infraestructura"
        VPS[VPS Server<br/>Ubuntu]
        SSL[Certbot<br/>SSL Certificates]
    end
    
    U --> M
    U --> W
    M --> LB
    W --> LB
    LB --> D
    D --> API
    API --> MONGO
    API --> FIREBASE
    API --> MAPS
    D -.-> VPS
    LB -.-> SSL
    
    style LB fill:#1E88E5,color:#fff
    style API fill:#0288D1,color:#fff
    style MONGO fill:#10B981,color:#fff
    style FIREBASE fill:#FF6F00,color:#fff
```

### Proceso de Despliegue

```mermaid
flowchart LR
    A[Código en GitHub] --> B[Git Pull en VPS]
    B --> C[Build Docker Image]
    C --> D[Detener Contenedores]
    D --> E[Iniciar Nuevos Contenedores]
    E --> F[Verificar Health Checks]
    F --> G{Servicio OK?}
    G -->|No| H[Rollback]
    G -->|Sí| I[Despliegue Exitoso]
    H --> D
    
    style A fill:#1E88E5,color:#fff
    style I fill:#10B981,color:#fff
    style H fill:#EF4444,color:#fff
```

### Configuración de Producción

- **Servidor**: VPS Ubuntu con Docker
- **Proxy**: Nginx con SSL/TLS (Certbot)
- **Base de Datos**: MongoDB Atlas (Cloud)
- **Almacenamiento**: Firebase Storage para imágenes
- **Notificaciones**: Firebase Cloud Messaging
- **Monitoreo**: Health checks y logs

---

## ✨ Características Principales

### Funcionalidades Clave

#### 🔐 Autenticación y Seguridad
- ✅ Registro con validación de identidad universitaria
- ✅ Autenticación con Google OAuth
- ✅ JWT para sesiones seguras
- ✅ Hash de contraseñas con Bcrypt
- ✅ Validación de documentos de conductores

#### 🗺️ Gestión de Viajes
- ✅ Creación de viajes con geolocalización
- ✅ Búsqueda avanzada de viajes por ubicación
- ✅ Sistema de reservas en tiempo real
- ✅ Expiración automática de viajes (6 minutos)
- ✅ Seguimiento en tiempo real con Socket.io

#### ⭐ Sistema de Calificaciones
- ✅ Calificación bidireccional (conductor ↔ pasajero)
- ✅ Comentarios y reseñas
- ✅ Cálculo automático de promedios
- ✅ Historial de calificaciones

#### 💬 Comunicación
- ✅ Chat en tiempo real durante viajes
- ✅ Notificaciones push para eventos importantes
- ✅ Notificaciones de nuevas reservas
- ✅ Alertas de inicio y finalización de viajes

#### 👤 Perfiles de Usuario
- ✅ Perfiles completos con foto
- ✅ Registro de vehículos (conductores)
- ✅ Historial de viajes
- ✅ Estadísticas de usuario

#### 🛡️ Panel de Administración
- ✅ Gestión de usuarios
- ✅ Aprobación/rechazo de conductores
- ✅ Visualización de estadísticas
- ✅ Gestión de viajes
- ✅ Reportes y analytics

---

## 📦 Instalación y Configuración

### Prerrequisitos

- Node.js 18+ y npm
- Flutter SDK 3.7.2+
- MongoDB Atlas (o MongoDB local)
- Cuenta de Firebase
- Cuenta de Google Cloud (para Maps API)
- Docker y Docker Compose (opcional, para producción)

### Backend

```bash
# 1. Navegar a la carpeta del backend
cd Codigo_Fuente_RideUpt/rideupt_backend

# 2. Instalar dependencias
npm install

# 3. Configurar variables de entorno
cp env.example.txt .env
# Editar .env con tus credenciales

# 4. Iniciar servidor de desarrollo
npm run dev

# 5. Crear usuario administrador
node create_admin.js
```

### Frontend

```bash
# 1. Navegar a la carpeta del frontend
cd Codigo_Fuente_RideUpt/rideupt_frontend

# 2. Instalar dependencias
flutter pub get

# 3. Configurar Firebase
# Agregar google-services.json (Android)
# Configurar firebase_options.dart

# 4. Ejecutar aplicación
flutter run

# Para Android
flutter run -d android

# Para iOS
flutter run -d ios

# Para Web
flutter run -d chrome
```

### Variables de Entorno (.env)

```env
# Base de Datos
MONGO_URI=mongodb+srv://user:pass@cluster.mongodb.net/rideupt

# JWT
JWT_SECRET=your-secret-key-here

# Servidor
PORT=3000
NODE_ENV=development
SERVER_URL=http://localhost:3000

# Firebase
FIREBASE_PROJECT_ID=your-project-id
# Configurar firebase-service-account.json

# Google Maps
GOOGLE_MAPS_API_KEY=your-google-maps-api-key
```

### Docker (Producción)

```bash
# 1. Construir imagen
docker-compose -f docker-compose.prod.yml build

# 2. Iniciar servicios
docker-compose -f docker-compose.prod.yml up -d

# 3. Ver logs
docker-compose -f docker-compose.prod.yml logs -f
```

---

## 📁 Estructura del Proyecto

```
proyecto-si889-2025-ii-u3-rideupt_briceno_cuadros_lopez/
│
├── Codigo_Fuente_RideUpt/
│   │
│   ├── rideupt_backend/          # Backend Node.js
│   │   ├── config/               # Configuraciones
│   │   │   ├── database.js
│   │   │   ├── storage.js
│   │   │   └── firebase-service-account.json
│   │   ├── controllers/          # Controladores
│   │   │   ├── authController.js
│   │   │   ├── userController.js
│   │   │   ├── tripController.js
│   │   │   ├── ratingController.js
│   │   │   ├── adminController.js
│   │   │   └── ...
│   │   ├── models/               # Modelos MongoDB
│   │   │   ├── User.js
│   │   │   ├── Trip.js
│   │   │   └── Rating.js
│   │   ├── routes/               # Rutas API
│   │   │   ├── auth.js
│   │   │   ├── users.js
│   │   │   ├── trips.js
│   │   │   └── ...
│   │   ├── services/             # Servicios
│   │   │   ├── socketService.js
│   │   │   ├── notificationService.js
│   │   │   └── tripChatService.js
│   │   ├── middleware/           # Middleware
│   │   │   ├── auth.js
│   │   │   └── errorHandler.js
│   │   ├── server.js             # Entry point
│   │   ├── package.json
│   │   └── Dockerfile
│   │
│   ├── rideupt_frontend/         # Frontend Flutter
│   │   ├── lib/
│   │   │   ├── api/              # Servicios API
│   │   │   ├── models/           # Modelos Dart
│   │   │   ├── providers/        # State management
│   │   │   ├── screens/          # Pantallas
│   │   │   │   ├── auth/
│   │   │   │   ├── home/
│   │   │   │   ├── trips/
│   │   │   │   ├── profile/
│   │   │   │   └── admin/
│   │   │   ├── services/         # Servicios Flutter
│   │   │   ├── widgets/          # Widgets reutilizables
│   │   │   ├── theme/            # Tema de la app
│   │   │   └── utils/            # Utilidades
│   │   ├── assets/               # Recursos
│   │   │   └── lottie/           # Animaciones
│   │   ├── android/              # Config Android
│   │   ├── ios/                  # Config iOS
│   │   ├── web/                  # Config Web
│   │   ├── pubspec.yaml
│   │   └── main.dart
│   │
│   └── apk/                      # APK compilado
│       └── RideUPT.apk
│
├── FD01-Informe-Factibilidad.md
├── FD02-Informe-Vision.md
├── FD03-EPIS-Informe Especificación Requerimientos.docx
├── FD04-EPIS-Informe Arquitectura de Software.docx
├── FD05-EPIS-Informe ProyectoFinal.docx
├── FD06-EPIS-PropuestaProyecto.docx
├── media/
│   └── logo-upt.png
└── README.md                     # Este archivo
```

---

## 📚 Documentación Adicional

- [Informe de Factibilidad](./FD01-Informe-Factibilidad.md)
- [Informe de Visión](./FD02-Informe-Vision.md)
- [Especificación de Requerimientos](./FD03-EPIS-Informe%20Especificación%20Requerimientos.docx)
- [Arquitectura de Software](./FD04-EPIS-Informe%20Arquitectura%20de%20Software.docx)
- [Informe del Proyecto Final](./FD05-EPIS-Informe%20ProyectoFinal.docx)

---

## 🤝 Contribución

Este es un proyecto académico desarrollado para el curso de Patrones de Software de la Universidad Privada de Tacna.

### Integrantes del Equipo

- **Jorge Luis BRICEÑO DIAZ** (2017059611)
- **Mirian CUADROS GARCIA** (2021071083)
- **Brayar Christian LOPEZ CATUNTA** (2020068946)
- **Ricardo Miguel DE LA CRUZ CHOQUE** (2019063329)

---

## 📝 Licencia

Este proyecto es parte de un trabajo académico y está sujeto a los términos de uso de la Universidad Privada de Tacna.

---

## 📞 Contacto

Para más información sobre el proyecto, contactar a los integrantes del equipo o al docente del curso:

- **Docente**: Mag. Ing. Patrick Cuadros Quiroga
- **Curso**: Patrones de Software
- **Universidad**: Universidad Privada de Tacna

---

<div align="center">

**Desarrollado con ❤️ por el equipo RideUPT**

**Universidad Privada de Tacna - 2025**

![Status](https://img.shields.io/badge/Status-Activo-success)
[![Issue #8](https://img.shields.io/badge/Issue-%238-blue)](https://github.com/your-repo/issues/8)

</div>
