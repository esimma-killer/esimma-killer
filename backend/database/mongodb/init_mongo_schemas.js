// =============================================================================
// Script de Inicializacion NoSQL MongoDB — E-SIIMA Killer (E-SIIMA 3)
// Issue #20: Esquema de colecciones documentales desnormalizadas para auditoria,
// telemetria de accesos e historial de entregas con JSON Schema e indices.
// =============================================================================

const dbName = "esimma_analytics";
const dbRef = db.getSiblingDB(dbName);

// -----------------------------------------------------------------------------
// 1. Coleccion: logs_auditoria (Auditoria de transacciones y eventos de dominio)
// -----------------------------------------------------------------------------
dbRef.createCollection("logs_auditoria", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: [
        "id_usuario",
        "rol",
        "id_campus",
        "accion",
        "resultado",
        "ip_origen",
        "timestamp"
      ],
      properties: {
        id_usuario: {
          bsonType: "string",
          description: "Matricula o identificador del usuario que ejecuta la accion."
        },
        rol: {
          bsonType: "string",
          enum: ["visitante", "estudiante", "profesor", "coordinador", "administrativo"],
          description: "Rol RBAC del usuario."
        },
        id_campus: {
          bsonType: "int",
          enum: [1, 2],
          description: "Shard Key del campus (1 = Campus Central, 2 = Campus Sur)."
        },
        accion: {
          bsonType: "string",
          description: "Nombre de la operacion auditada."
        },
        entidad_afectada: {
          bsonType: "string",
          description: "Entidad de negocio involucrada (Inscripcion, Pago, Entrega, etc.)."
        },
        resultado: {
          bsonType: "string",
          enum: ["EXITO", "ERROR"],
          description: "Resultado final registrado en el bloque finally."
        },
        ip_origen: {
          bsonType: "string",
          description: "Direccion IP del cliente."
        },
        timestamp: {
          bsonType: "string",
          description: "Marca de tiempo UTC en formato ISO-8601."
        },
        detalle: {
          bsonType: "string",
          description: "Mensaje descriptivo o codigo de error del evento."
        }
      }
    }
  },
  validationLevel: "strict",
  validationAction: "error"
});

dbRef.logs_auditoria.createIndex(
  { id_campus: 1, timestamp: -1 },
  { name: "idx_auditoria_campus_fecha" }
);
dbRef.logs_auditoria.createIndex(
  { id_usuario: 1, timestamp: -1 },
  { name: "idx_auditoria_usuario_fecha" }
);
dbRef.logs_auditoria.createIndex(
  { accion: 1, resultado: 1 },
  { name: "idx_auditoria_accion_resultado" }
);

// -----------------------------------------------------------------------------
// 2. Coleccion: telemetria_accesos (Concurrencia y picos de trafico por hora)
// -----------------------------------------------------------------------------
dbRef.createCollection("telemetria_accesos", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: [
        "id_sesion",
        "id_usuario",
        "rol",
        "id_campus",
        "endpoint",
        "metodo_http",
        "status_code",
        "latencia_ms",
        "franja_horaria",
        "timestamp"
      ],
      properties: {
        id_sesion: {
          bsonType: "string",
          description: "Identificador unico de la sesion o peticion."
        },
        id_usuario: {
          bsonType: "string",
          description: "Identificador del usuario o 'ANONIMO' en portal publico."
        },
        rol: {
          bsonType: "string",
          enum: ["visitante", "estudiante", "profesor", "coordinador", "administrativo"]
        },
        id_campus: {
          bsonType: "int",
          enum: [1, 2]
        },
        endpoint: {
          bsonType: "string",
          description: "Ruta HTTP invocada (ej. /api/v1/academico/entregas)."
        },
        metodo_http: {
          bsonType: "string",
          enum: ["GET", "POST", "PUT", "PATCH", "DELETE"]
        },
        status_code: {
          bsonType: "int",
          minimum: 100,
          maximum: 599
        },
        latencia_ms: {
          bsonType: ["double", "int"],
          minimum: 0
        },
        plataforma_cliente: {
          bsonType: "string",
          enum: ["web", "mobile", "desktop"]
        },
        franja_horaria: {
          bsonType: "int",
          minimum: 0,
          maximum: 23,
          description: "Hora del dia (0-23) para Grafica 3 de Picos de Trafico."
        },
        timestamp: {
          bsonType: "string"
        }
      }
    }
  },
  validationLevel: "strict",
  validationAction: "error"
});

dbRef.telemetria_accesos.createIndex(
  { id_campus: 1, franja_horaria: 1, timestamp: -1 },
  { name: "idx_telemetria_campus_franja_fecha" }
);
dbRef.telemetria_accesos.createIndex(
  { id_usuario: 1, timestamp: -1 },
  { name: "idx_telemetria_usuario_fecha" }
);
dbRef.telemetria_accesos.createIndex(
  { endpoint: 1, status_code: 1 },
  { name: "idx_telemetria_endpoint_status" }
);

// -----------------------------------------------------------------------------
// 3. Coleccion: eventos_entregas (Historial masivo para puntualidad y carga)
// -----------------------------------------------------------------------------
dbRef.createCollection("eventos_entregas", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: [
        "id_entrega",
        "id_tarea",
        "materia_clave",
        "departamento",
        "alumno_matricula",
        "id_campus",
        "fecha_limite",
        "fecha_entrega",
        "estado_entrega",
        "ponderacion",
        "calificacion",
        "hash_sha256"
      ],
      properties: {
        id_entrega: { bsonType: "string" },
        id_tarea: { bsonType: "string" },
        materia_clave: { bsonType: "string" },
        departamento: { bsonType: "string" },
        docente_empleado: { bsonType: "string" },
        alumno_matricula: { bsonType: "string" },
        id_campus: {
          bsonType: "int",
          enum: [1, 2]
        },
        fecha_limite: { bsonType: "string" },
        fecha_entrega: { bsonType: "string" },
        estado_entrega: {
          bsonType: "string",
          enum: ["A_TIEMPO", "TARDIA"]
        },
        ponderacion: {
          bsonType: ["double", "int"],
          minimum: 0.1,
          maximum: 100.0
        },
        calificacion: {
          bsonType: ["double", "int"],
          minimum: 0.0,
          maximum: 10.0
        },
        hash_sha256: {
          bsonType: "string",
          minLength: 64,
          maxLength: 64,
          description: "Hash criptografico SHA-256 del archivo entregado (Integridad CIA)."
        }
      }
    }
  },
  validationLevel: "strict",
  validationAction: "error"
});

dbRef.eventos_entregas.createIndex(
  { id_campus: 1, estado_entrega: 1, fecha_entrega: -1 },
  { name: "idx_entregas_campus_estado_fecha" }
);
dbRef.eventos_entregas.createIndex(
  { materia_clave: 1, id_campus: 1 },
  { name: "idx_entregas_materia_campus" }
);
dbRef.eventos_entregas.createIndex(
  { alumno_matricula: 1, id_tarea: 1 },
  { name: "idx_entregas_alumno_tarea_unique", unique: true }
);

// -----------------------------------------------------------------------------
// 4. Sembrado de Eventos Sinteticos de Validacion y Prueba con explain()
// -----------------------------------------------------------------------------
dbRef.logs_auditoria.insertMany([
  {
    id_usuario: "ID300001",
    rol: "estudiante",
    id_campus: 1,
    accion: "inscripcion_materia",
    entidad_afectada: "Inscripcion",
    resultado: "EXITO",
    ip_origen: "10.10.1.15",
    timestamp: "2026-11-23T14:00:00Z",
    detalle: "Inscripcion confirmada en ISC-0101"
  },
  {
    id_usuario: "ID300002",
    rol: "estudiante",
    id_campus: 2,
    accion: "procesar_pago_simulado",
    entidad_afectada: "Pago",
    resultado: "ERROR",
    ip_origen: "10.20.1.44",
    timestamp: "2026-11-23T14:05:00Z",
    detalle: "PAGO_RECHAZADO: FONDOS_INSUFICIENTES"
  }
]);

dbRef.telemetria_accesos.insertMany([
  {
    id_sesion: "SES-2026-0001",
    id_usuario: "ID300001",
    rol: "estudiante",
    id_campus: 1,
    endpoint: "/api/v1/academico/entregas",
    metodo_http: "POST",
    status_code: 201,
    latencia_ms: 42.5,
    plataforma_cliente: "web",
    franja_horaria: 23,
    timestamp: "2026-11-23T23:55:10Z"
  },
  {
    id_sesion: "SES-2026-0002",
    id_usuario: "ID300002",
    rol: "estudiante",
    id_campus: 2,
    endpoint: "/api/v1/informacion",
    metodo_http: "GET",
    status_code: 200,
    latencia_ms: 11.2,
    plataforma_cliente: "mobile",
    franja_horaria: 10,
    timestamp: "2026-11-23T10:15:00Z"
  }
]);

dbRef.eventos_entregas.insertMany([
  {
    id_entrega: "ENT-2026-000001",
    id_tarea: "TAR-0001",
    materia_clave: "ISC-0101",
    departamento: "Sistemas de Informacion",
    docente_empleado: "DOC-00001",
    alumno_matricula: "ID300001",
    id_campus: 1,
    fecha_limite: "2026-11-23T23:59:00Z",
    fecha_entrega: "2026-11-23T22:40:00Z",
    estado_entrega: "A_TIEMPO",
    ponderacion: 20.0,
    calificacion: 9.5,
    hash_sha256: "2477803baffb4b892477803baffb4b892477803baffb4b892477803baffb4b89"
  },
  {
    id_entrega: "ENT-2026-000002",
    id_tarea: "TAR-0002",
    materia_clave: "ISC-0102",
    departamento: "Redes y Telecomunicaciones",
    docente_empleado: "DOC-00002",
    alumno_matricula: "ID300002",
    id_campus: 2,
    fecha_limite: "2026-11-23T23:59:00Z",
    fecha_entrega: "2026-11-24T00:12:00Z",
    estado_entrega: "TARDIA",
    ponderacion: 25.0,
    calificacion: 7.0,
    hash_sha256: "9b881a2c3d4e5f609b881a2c3d4e5f609b881a2c3d4e5f609b881a2c3d4e5f60"
  }
]);

// Verificacion de indices mediante explain("executionStats")
const explainAuditoria = dbRef.logs_auditoria
  .find({ id_campus: 1 })
  .sort({ timestamp: -1 })
  .explain("executionStats");

const explainEntregas = dbRef.eventos_entregas
  .find({ id_campus: 1, estado_entrega: "A_TIEMPO" })
  .explain("executionStats");

print("Esquema MongoDB inicializado exitosamente en base:", dbName);
print("Total indices logs_auditoria:", dbRef.logs_auditoria.getIndexes().length);
print("Total indices telemetria_accesos:", dbRef.telemetria_accesos.getIndexes().length);
print("Total indices eventos_entregas:", dbRef.eventos_entregas.getIndexes().length);
print("Explain logs_auditoria totalKeysExamined:", explainAuditoria.executionStats.totalKeysExamined);
print("Explain eventos_entregas totalKeysExamined:", explainEntregas.executionStats.totalKeysExamined);
