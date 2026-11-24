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
