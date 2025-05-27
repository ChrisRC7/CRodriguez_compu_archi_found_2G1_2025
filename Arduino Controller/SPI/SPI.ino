#include <SPI.h>

const int ssPin = 10;
byte led_command = 0; // Comando actual para los LEDs

// Asegúrate de que la velocidad de Serial.begin coincida con tu Monitor Serie
// 9600 es una opción segura y común.
const long SERIAL_BAUD_RATE = 9600;

// Intentar una velocidad muy lenta, por ejemplo 1000 Hz (1 kHz)
SPISettings spiSettings(800, MSBFIRST, SPI_MODE0);

// Ya no necesitamos MAX_RETRIES, se reintentará indefinidamente
// const int MAX_RETRIES = 3;

void setup() {
  Serial.begin(SERIAL_BAUD_RATE);
  while (!Serial); // Para Arduinos como Leonardo que necesitan que el puerto serie se abra

  pinMode(ssPin, OUTPUT);
  digitalWrite(ssPin, HIGH); // Deseleccionar esclavo inicialmente

  SPI.begin();
  Serial.println("Arduino Maestro SPI - Handshake con Eco, Reintentos Infinitos y Pausas.");
}

// Función para enviar un comando y verificar el eco, con reintentos indefinidos
// Devuelve true si el comando fue verificado, false si algo extraordinario ocurriera (no aplicable aquí)
bool sendAndVerifyCommandPersistent(byte command_to_send) {
  byte byte_to_transmit;
  byte byte_received_from_fpga;
  byte fpga_led_status_echo;
  bool command_verified = false;
  int attempt_count = 0;

  while (!command_verified) { // Continuar hasta que el comando sea verificado
    attempt_count++;
    byte_to_transmit = (command_to_send & 0x0F) << 4;

    if (attempt_count == 1) {
      Serial.print("Enviando Comando LED: ");
    } else {
      Serial.print("Re-enviando Comando LED (Intento ");
      Serial.print(attempt_count);
      Serial.print("): ");
    }
    Serial.print(command_to_send);
    Serial.print(" (Byte Tx: 0b");
    for (int i = 7; i >= 0; i--) Serial.print(bitRead(byte_to_transmit, i));
    Serial.print(")... ");

    SPI.beginTransaction(spiSettings);
    digitalWrite(ssPin, LOW);
    byte_received_from_fpga = SPI.transfer(byte_to_transmit);
    digitalWrite(ssPin, HIGH);
    SPI.endTransaction();

    fpga_led_status_echo = (byte_received_from_fpga >> 4) & 0x0F;

    Serial.print("FPGA reporta LEDs: ");
    Serial.print(fpga_led_status_echo);
    Serial.print(" (Byte Rx: 0b");
    for (int i = 7; i >= 0; i--) Serial.print(bitRead(byte_received_from_fpga, i));
    Serial.println(")");

    if (fpga_led_status_echo == command_to_send) {
      Serial.println("  -> Verificación OK: FPGA confirmó el comando.");
      command_verified = true; // Esto romperá el bucle while
    } else {
      Serial.println("  -> Verificación FALLIDA: FPGA no confirmó el comando.");
      Serial.println("     Esperando 3 segundo antes de reintentar...");
      delay(3000); // <--- ESPERA DE 3 SEGUNDO ENTRE INTENTOS FALLIDOS
    }
  }
  return command_verified; // Siempre será true si sale del bucle
}

void loop() {
  Serial.println("-----------------------------------------");
  sendAndVerifyCommandPersistent(led_command); // Esta función ahora bloqueará hasta el éxito

  // El comando fue procesado con éxito por la FPGA porque sendAndVerifyCommandPersistent
  // solo retorna 'true' después de una verificación exitosa.
  Serial.println("Comando procesado con éxito por la FPGA.");
  Serial.println("Esperando 3 segundos antes de enviar el siguiente comando...");
  delay(3000); // Pausa de 3 segundos ANTES de pasar al siguiente comando

  // Avanzar al siguiente comando para la próxima iteración del loop
  led_command++;
  if (led_command > 15) {
    led_command = 0;
  }
}