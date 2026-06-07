#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

static uint32_t actualizar_crc32(uint32_t crc, unsigned char byte) {
  crc = crc ^ byte;

  for (int i = 0; i < 8; i++) {
    if (crc & 1) {
      crc = (crc >> 1) ^ 0xEDB88320U;
    } else {
      crc = crc >> 1;
    }
  }
  return crc;
}

static int calcular_checksum(const char *datos, uint32_t *resultado) {
  unsigned char buffer[4096];
  uint32_t crc = 0xFFFFFFFFU;
  FILE *file = fopen(datos, "rb");

  if (file == NULL) {
    return 2;
  }

  while (1) {
    size_t bytes_read = fread(buffer, 1, sizeof(buffer), file);

    for (size_t i = 0; i < bytes_read; i++) {
      crc = actualizar_crc32(crc, buffer[i]);
    }

    if (bytes_read < sizeof(buffer)) {
      if (ferror(file)) {
        fclose(file);
        return 3;
      }

      break;
    }
  }

  fclose(file);
  *resultado = crc ^ 0xFFFFFFFFU;

  return 0;
}

int main(int argc, char *argv[]) {
  uint32_t resultado;
  int status;

  if (argc != 2) {
    fprintf(stderr, "Uso: checksum <archivo>\n");
    return 1;
  }

  status = calcular_checksum(argv[1], &resultado);

  if (status == 2) {
    fprintf(stderr, "Error: no se pudo abrir '%s'\n", argv[1]);
    return 2;
  }

  if (status == 3) {
    fprintf(stderr, "Error: no se pudo leer '%s'\n", argv[1]);
    return 3;
  }

  printf("%08x %s\n", resultado, argv[1]);

  return 0;
}
