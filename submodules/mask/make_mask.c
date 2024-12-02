#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>

int main(int argc, char **argv) {
  // parse flags
  const char *sourcePath = NULL,
             *targetPath = NULL,
             *outPath = NULL;

  for (uint8_t i = 0; i < argc; i++) {
    const char *arg = argv[i];

    if (strncmp(arg, "-s", 2) == 0) {
      arg += 2;
      sourcePath = arg;
      continue;
    }
    
    if (strncmp(arg, "-t", 2) == 0) {
      arg += 2;
      targetPath = arg;
      continue;
    }

    if (strncmp(arg, "-o", 2) == 0) {
      arg += 2;
      outPath = arg;
      continue;
    }
  }

  if (!sourcePath) {
    printf("Source path unspecified\n");
    return 1;
  }

  if (!targetPath) {
    printf("Target path unspecified\n");
    return 1;
  }

  if (!outPath) {
    printf("Out path unspecified\n");
    return 1;
  }

  // open files
  FILE *sourceFile, *targetFile, *outFile;

  sourceFile = fopen(sourcePath, "rb");
  if (sourceFile == NULL) {
    printf("Error opening source file\n");
    return 1;
  }

  targetFile = fopen(targetPath, "rb");
  if (targetFile == NULL) {
    printf("Error opening target file\n");
    return 1;
  }

  outFile = fopen(outPath, "wb");
  if (outFile == NULL) {
    printf("Error opening out file\n");
    return 1;
  }

  // read source file into buffer
  fseek(sourceFile, 0, SEEK_END);
  size_t sourceSize = ftell(sourceFile);
  fseek(sourceFile, 0, SEEK_SET);

  unsigned char *sourceBuffer = (unsigned char *)malloc(sourceSize);
  if (sourceBuffer == NULL) {
    printf("Error allocating buffer for source file\n");
    fclose(sourceFile);
    fclose(targetFile);
    fclose(outFile);
    return 1;
  }

  size_t bytesRead = fread(sourceBuffer, 1, sourceSize, sourceFile);
  if (bytesRead != sourceSize) {
    printf("Error reading from source file\n");
    fclose(sourceFile);
    fclose(targetFile);
    fclose(outFile);
    free(sourceBuffer);
    return 1;
  }
  fclose(sourceFile);

  // read target file into buffer
  fseek(targetFile, 0, SEEK_END);
  size_t targetSize = ftell(targetFile);
  fseek(targetFile, 0, SEEK_SET);

  unsigned char *targetBuffer = (unsigned char *)malloc(targetSize);
  if (targetBuffer == NULL) {
    printf("Error allocating buffer for target file\n");
    fclose(targetFile);
    fclose(outFile);
    free(sourceBuffer);
    return 1;
  }
  
  bytesRead = fread(targetBuffer, 1, targetSize, targetFile);
  if (bytesRead != targetSize) {
    printf("Error reading from target file\n");
    fclose(targetFile);
    fclose(outFile);
    free(sourceBuffer);
    free(targetBuffer);
    return 1;
  }
  fclose(targetFile);

  // calculate and write mask
  unsigned char *outBuffer = (unsigned char *)malloc(targetSize);
  if (outBuffer == NULL) {
    printf("Error allocating buffer for out file\n");
    fclose(outFile);
    free(sourceBuffer);
    free(targetBuffer);  
    return 1;
  }

  size_t posSource = 0;
  unsigned char byteSource, byteTarget;
  for (size_t posTarget = 0; posTarget < targetSize; posTarget++) {
    byteSource = sourceBuffer[posSource];
    byteTarget = targetBuffer[posTarget];
    outBuffer[posTarget] = byteTarget < byteSource
      ? byteTarget + (0xff - byteSource) + 1
      : byteTarget - byteSource;
    posSource = (posSource + 1) % sourceSize;
  }

  fwrite(outBuffer, 1, targetSize, outFile);

  fclose(outFile);
  free(sourceBuffer);
  free(targetBuffer);
  free(outBuffer);

  return 0;
}
