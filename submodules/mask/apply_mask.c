#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>

int main(int argc, char **argv) {
  // parse flags
  const char *sourcePath = NULL,
             *maskPath = NULL,
             *outPath = NULL;

  for (uint8_t i = 0; i < argc; i++) {
    const char *arg = argv[i];

    if (strncmp(arg, "-s", 2) == 0) {
      arg += 2;
      sourcePath = arg;
      continue;
    }
    
    if (strncmp(arg, "-m", 2) == 0) {
      arg += 2;
      maskPath = arg;
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

  if (!maskPath) {
    printf("Mask path unspecified\n");
    return 1;
  }

  if (!outPath) {
    printf("Out path unspecified\n");
    return 1;
  }

  // open files
  FILE *sourceFile, *maskFile, *outFile;

  sourceFile = fopen(sourcePath, "rb");
  if (sourceFile == NULL) {
    printf("Error opening source file\n");
    return 1;
  }

  maskFile = fopen(maskPath, "rb");
  if (maskFile == NULL) {
    printf("Error opening mask file\n");
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
    fclose(maskFile);
    fclose(outFile);
    return 1;
  }

  size_t bytesRead = fread(sourceBuffer, 1, sourceSize, sourceFile);
  if (bytesRead != sourceSize) {
    printf("Error reading from source file\n");
    fclose(sourceFile);
    fclose(maskFile);
    fclose(outFile);
    free(sourceBuffer);
    return 1;
  }
  fclose(sourceFile);

  // read mask file into buffer
  fseek(maskFile, 0, SEEK_END);
  size_t maskSize = ftell(maskFile);
  fseek(maskFile, 0, SEEK_SET);

  unsigned char *maskBuffer = (unsigned char *)malloc(maskSize);
  if (maskBuffer == NULL) {
    printf("Error allocating buffer for target file\n");
    fclose(maskFile);
    fclose(outFile);
    free(sourceBuffer);
    return 1;
  }
  
  bytesRead = fread(maskBuffer, 1, maskSize, maskFile);
  if (bytesRead != maskSize) {
    printf("Error reading from mask file\n");
    fclose(maskFile);
    fclose(outFile);
    free(sourceBuffer);
    free(maskBuffer);
    return 1;
  }
  fclose(maskFile);

  // apply mask and write output
  unsigned char *outBuffer = (unsigned char *)malloc(maskSize);
  if (outBuffer == NULL) {
    printf("Error allocating buffer for out file\n");
    fclose(outFile);
    free(sourceBuffer);
    free(maskBuffer);  
    return 1;
  }

  size_t posSource = 0;
  unsigned char byteSource, byteMask, byteLeft;
  for (size_t posMask = 0; posMask < maskSize; posMask++) {
    byteSource = sourceBuffer[posSource];
    byteMask = maskBuffer[posMask];
    byteLeft = 0xff - byteSource;
    outBuffer[posMask] = byteMask > byteLeft
      ? byteMask - byteLeft - 1
      : byteSource + byteMask;
    posSource = (posSource + 1) % sourceSize;
  }

  fwrite(outBuffer, 1, maskSize, outFile);

  fclose(outFile);
  free(sourceBuffer);
  free(maskBuffer);
  free(outBuffer);

  return 0;
}
