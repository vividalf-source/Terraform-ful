## Estructura de Archivos en Terraform

Terraform lee todos los archivos `.tf` de la carpeta como si fueran uno solo, pero por orden y buenas prácticas (exigidas en la evaluación), cada bloque va en un archivo específico:

| Archivo | Qué va adentro (en palabras simples) |
| :--- | :--- |
| **`variables.tf`** | **Las "cajas" vacías (definiciones):** Aquí solo declaras cómo se llaman tus variables (`ambiente`, `subredes`, `servidores`, `db_password`) y qué tipo de dato aceptan (`string`, `bool`, `map(object)`). **Aquí NO van los datos del cliente.** |
| **`terraform.tfvars`** | **Los datos reales del caso:** Aquí rellenas esas cajas con la info de la prueba (por ejemplo: `"dev"`, los 3 servidores `biblioteca-a/b/c`, sus discos `30/60`, etc.). *Ojo: la contraseña `db_password` NO se pone aquí para que no quede escrita en archivos.* |
| **`main.tf`** | **Toda la infraestructura y lógica:** Aquí van el `provider "aws"`, los `locals` (tags comunes y filtros), los `data`, y todos los `resource` (VPC, subredes con `for_each`, Security Groups, instancias EC2, NLB, RDS y Bucket S3). |
| **`outputs.tf`** | **Lo que quieres ver en pantalla al terminar:** Aquí van solo los bloques `output` para que Terraform te imprima el DNS del NLB, el endpoint de la RDS y el nombre del Bucket S3 cuando termine el `apply`. |

### Flujo de conexión entre los archivos

```text
terraform.tfvars (Valores) ➔ variables.tf (Estructura) ➔ main.tf (Recursos) ➔ outputs.tf (Resultados)



clase 3.1.1
Introducción a las Funciones Predefinidas (Built-in Functions) en Terraform

¿Qué son las built-in functions?

Son herramientas integradas dentro del lenguaje de Terraform que permiten manipular, transformar y evaluar datos directamente en los archivos de configuración. Su uso permite crear infraestructura como código (IaC) más dinámica, reutilizable, limpia y eficiente, evitando la repetición manual de valores.

Categorías Principales de Funciones

Terraform organiza sus funciones integradas en distintos grupos según el tipo de dato u operación a realizar:

String Functions: Manipulación y transformación de cadenas de texto.

Numeric & Arithmetic Functions: Operaciones matemáticas básicas, avanzadas y cálculos numéricos.

Collection Functions: Operaciones para trabajar con listas, mapas y conjuntos (sets).

Date and Time Functions: Manejo, formateo y cálculo de fechas y horas.

Encoding Functions: Conversión de datos entre formatos (ej. Base64, JSON, YAML).

Filesystem Functions: Lectura e interacción con archivos locales del sistema.

Hash and Crypto Functions: Generación de hashes (MD5, SHA256) y operaciones criptográficas.

IP Network Functions: Cálculo de subredes y manipulación de direcciones IP (CIDR).

Type Conversion Functions: Conversión explícita entre tipos de datos (tolist, toset, tostring, etc.).

Template & Dynamic Blocks Functions: Renderizado de plantillas dinámicas y generación de bloques repetitivos.

Utility Functions: Herramientas misceláneas de uso general.

Ejemplos Prácticos (Probados en terraform console)

La herramienta terraform console permite probar estas funciones de forma interactiva antes de llevarlas al código.

1. String Functions (Cadenas de texto)

Permiten dividir, unir o reemplazar partes de un texto:

# Divide un texto en una lista usando un separador (en este caso, un espacio)
> split(" ", "Esto es un ejemplo")
tolist([
  "Esto",
  "es",
  "un",
  "ejemplo",
])

# Une los elementos de una lista en un solo texto usando un separador
> join(" ", ["Esto", "es", "un", "ejemplo"])
"Esto es un ejemplo"

# Reemplaza todas las coincidencias de una subcadena por otra
> replace("Password@123", "a", "@")
"P@ssword@123"


2. Numeric Functions (Números)

Evalúan conjuntos de valores numéricos:

# Devuelve el número mayor
> max(5, 12, 9)
12

# Devuelve el número menor
> min(5, 12, 9)
5


3. Collection Functions (Listas, Mapas y Longitud)

Facilitan la combinación, ordenamiento y medición de estructuras de datos:

# Combina dos o más listas en una sola
> concat(["a", ""], ["b", "c"])
[
  "a",
  "",
  "b",
  "c",
]

# Devuelve la longitud de una cadena, lista o mapa
> length("hello")
5

# Ordena los elementos de una lista alfabéticamente
> sort(["e", "d", "a", "x"])
tolist([
  "a",
  "d",
  "e",
  "x",
])

# Combina dos mapas (si hay claves repetidas, prevalece la del último mapa)
> merge({a="b", c="d"}, {e="f", c="z"})
{
  "a" = "b"
  "c" = "z"
  "e" = "f"
}

clase 3.1.2

Introducción al Manejo de Condicionales en Terraform

¿Qué son los condicionales en Terraform?

Los condicionales son expresiones que permiten crear configuraciones de infraestructura dinámicas y flexibles basadas en condiciones específicas.

Su objetivo principal es simplificar las configuraciones y evitar la duplicación de código, permitiendo que un mismo bloque de Terraform se adapte a distintos escenarios (por ejemplo, diferentes entornos o creación opcional de recursos).

Sintaxis Básica (Expresión Ternaria)

Terraform utiliza el operador ternario para evaluar una expresión booleana y devolver uno de dos posibles resultados:

condition ? true_value : false_value


condition: Expresión que evalúa a true (verdadero) o false (falso).

true_value: Valor que se asigna si la condición se cumple.

false_value: Valor que se asigna si la condición no se cumple.

Ejemplos Prácticos

Ejemplo 1: Asignación dinámica de atributos según el entorno

Permite modificar propiedades de un recurso (como el tamaño de una máquina virtual) dependiendo del entorno de despliegue (production, dev, etc.).

variable "environment" {
  description = "Deployment environment"
  type        = string
}

resource "aws_instance" "example" {
  # Si el entorno es 'production', usa 't3.large'; de lo contrario, usa 't3.micro'
  instance_type = var.environment == "production" ? "t3.large" : "t3.micro"
  
  # ... otras configuraciones ...
}


Ejemplo 2: Creación condicional de recursos usando count

Es uno de los patrones más comunes en Terraform. Permite decidir si un recurso debe crearse (count = 1) o ignorarse (count = 0) a partir de una variable booleana.

variable "add_storage_account" {
  description = "boolean to determine whether to create a storage account or not"
  type        = bool
}

resource "azurerm_storage_account" "my_storage_account" {
  # Si la variable es true, crea 1 instancia del recurso; si es false, crea 0
  count = var.add_storage_account ? 1 : 0

  resource_group_name      = "rg-conditional-demo"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  name = "stspacelift${count.index}${local.rand_suffix}"
}


clase 4

Clase 4: HCL Avanzado — Funciones, Expresiones y Ciclo de Vida

Guía de estudio y referencia rápida basada en la preparación para la certificación HashiCorp Terraform Associate.

1. Funciones Integradas (Built-in Functions)

Terraform incluye más de 100 funciones integradas que se usan directamente en expresiones (no se pueden crear funciones personalizadas).

Strings

upper(s) / lower(s): Convierte a mayúsculas o minúsculas.

format(plantilla, args...): Formatea cadenas (ej. format("server-%02d", 5) $\rightarrow$ "server-05").

join(sep, lista): Une una lista en un string (join("-", ["a", "b"]) $\rightarrow$ "a-b").

split(sep, s): Divide un string en una lista (split(",", "a,b") $\rightarrow$ ["a", "b"]).

replace(s, viejo, nuevo): Reemplaza subcadenas.

trimspace(s): Elimina espacios al inicio y final.

substr(s, offset, length): Extrae una subcadena.

Colecciones

length(v): Devuelve el largo de una lista, mapa o string.

toset(lista) / tolist(set): Convierte entre listas y conjuntos (sets eliminan duplicados y orden).

merge(m1, m2, ...): Combina mapas (en caso de claves repetidas, gana el último).

lookup(map, key, default): Busca una clave en un mapa o devuelve un valor por defecto.

keys(map) / values(map): Extrae listas de claves o valores de un mapa.

flatten(lista): Aplana listas anidadas en una sola lista.

distinct(lista): Elimina elementos duplicados manteniendo el orden.

contains(lista, val): Devuelve true si el valor existe en la lista.

element(lista, idx): Obtiene un elemento por índice (con wrap circular si el índice supera el largo).

Tipos y Sistema de Archivos

Conversión: tostring(42), tonumber("3.14"), tobool("true").

Archivos: file("${path.module}/config.json") lee el contenido de un archivo como string.

Plantillas: templatefile("${path.module}/userdata.tpl", { var = val }) renderiza archivos dinámicos inyectando variables.

2. terraform console

Comando interactivo para evaluar expresiones HCL y consultar el estado actual sin modificar infraestructura.

Usos principales: Probar funciones (cidrsubnet("10.0.0.0/16", 8, 1)), depurar expresiones complejas e inspeccionar atributos del state (aws_instance.web.public_ip).

3. Iteración: count vs for_each

Ambos meta-argumentos crean múltiples instancias de un recurso, pero son mutuamente excluyentes en un mismo bloque.

count (Basado en índice numérico)

Ideal cuando los recursos son idénticos/fungibles y solo importa la cantidad.

resource "aws_instance" "servidor" {
  count         = 3
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  tags = {
    Name = "servidor-${count.index}" # 0, 1, 2
  }
}


⚠️ Limitación: Si se usa con una lista y se elimina un elemento intermedio, los índices posteriores se desplazan, provocando que Terraform destruya y recree recursos innecesariamente.

for_each (Basado en clave de string)

Ideal cuando cada instancia tiene una identidad única o configuración distinta. Acepta un map o un set de strings.

resource "aws_iam_user" "equipo" {
  for_each = toset(["alice", "bob", "charlie"])
  name     = each.key # También existe each.value (en sets son iguales)
}
# Referencia: aws_iam_user.equipo["alice"].arn


✅ Ventaja: Si eliminas "bob", solo se destruye ese recurso; "alice" y "charlie" quedan intactos.

4. Expresiones for, Condicionales y Splat

Expresiones for (Transformación y filtrado)

Equivalentes a map() y filter() en otros lenguajes:

De lista a lista: [for s in var.nombres : upper(s)]

De lista a mapa: {for s in var.nombres : s => upper(s)}

Con filtro (if): [for s in var.nombres : s if length(s) > 3]

Sobre un mapa: {for k, v in var.tags : k => upper(v)}

Expresiones Condicionales (Operador Ternario)

# condición ? valor_si_verdadero : valor_si_falso
instance_type = var.ambiente == "prod" ? "t3.large" : "t3.micro"


Nota: Ambos valores resultantes deben ser del mismo tipo o tipos compatibles.

Splat Expressions ([*])

Extraen un atributo específico de todos los elementos de una lista o recurso creado con count:

aws_instance.servidor[*].public_ip # Devuelve una lista de IPs
# Equivalente a: [for i in aws_instance.servidor : i.public_ip]


(Nota para examen: usar siempre el full splat [*], ya que el legacy .* está obsoleto para expresiones complejas).

5. Bloques dynamic

Generan múltiples bloques anidados dentro de un recurso a partir de una colección (como reglas de firewall o etiquetas).

resource "aws_security_group" "web" {
  name = "sg-web"

  dynamic "ingress" {
    for_each = var.reglas_ingreso
    content {
      from_port   = ingress.value.puerto
      to_port     = ingress.value.puerto
      protocol    = ingress.value.protocolo
      cidr_blocks = [ingress.value.cidr]
    }
  }
}


Por defecto, el iterador lleva el nombre del bloque dinámico (ingress.value), a menos que se especifique el argumento iterator.

6. Meta-argumentos de lifecycle

Controlan cómo Terraform crea, actualiza o destruye un recurso específico:

Argumento

Función

Caso de uso típico

create_before_destroy

Crea el nuevo recurso antes de destruir el anterior.

Evitar downtime en instancias detrás de un Load Balancer o certificados SSL.

prevent_destroy

Bloquea con error cualquier plan que intente destruir el recurso.

Proteger bases de datos de producción (RDS) contra borrados accidentales.

ignore_changes

Ignora modificaciones externas en los atributos listados (ej. [tags]).

Evitar que Terraform revierta cambios hechos por un Auto Scaling Group.

replace_triggered_by

Fuerza la recreación del recurso si cambia una dependencia referenciada.

Recrear un servicio cuando cambia su configuración externa asociada.

7. Validaciones y Controles de Calidad

precondition y postcondition (Dentro de lifecycle)

Detienen la ejecución con un error si no se cumplen:

precondition: Se evalúa antes de crear/modificar el recurso (ej. validar que la AMI obtenida por un data sea arquitectura x86_64).

postcondition: Se evalúa después de crear/modificar el recurso. Permite usar el objeto self para inspeccionar atributos generados (ej. self.public_dns != "").

El bloque check (Nivel superior)

Ejecuta validaciones de alto nivel después del apply, fuera del ciclo de vida de un recurso particular:

check "endpoint_web_responde" {
  data "http" "prueba" {
    url = "https://${aws_lb.web.dns_name}/health"
  }

  assert {
    condition     = data.http.prueba.status_code == 200
    error_message = "El endpoint de salud no responde 200."
  }
}


💡 Diferencia clave: Si un bloque check falla, emite una advertencia (warning), no un error que detenga ni revierta el apply.

Resumen Rápido

Herramienta

Cuándo usarla

count

Crear $N$ instancias idénticas/fungibles.

for_each

Crear instancias con identidad propia usando un map o set.

Expresión for

Transformar o filtrar listas y mapas.

Ternario (? :)

Elegir entre dos valores según una condición booleana.

dynamic

Generar bloques internos repetitivos dentro de un recurso.

lifecycle

Alterar el comportamiento de creación, actualización o destrucción.

pre/postcondition

Bloquear despliegues si no se cumplen reglas críticas (genera error).

check

Verificar salud/estado post-despliegue (genera advertencia).
