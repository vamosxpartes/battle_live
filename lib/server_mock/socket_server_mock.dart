// MOCK SERVER PARA PRUEBAS

/*
Este archivo contiene instrucciones para configurar un servidor Socket.io simple 
usando Node.js para probar la aplicación durante el desarrollo.

Sigue estos pasos para configurar un servidor de prueba:

1. Crea una carpeta para el servidor (por ejemplo, 'server')
2. Inicia un proyecto Node.js:
   ```
   npm init -y
   ```

3. Instala las dependencias necesarias:
   ```
   npm install express socket.io cors
   ```

4. Crea un archivo 'server.js' con el siguiente contenido:
*/

/*
// server.js - Código para el servidor Node.js

const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');

const app = express();
app.use(cors());

const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Datos para el ejemplo
let contadores = {
  contador1: 0,
  contador2: 0
};

let donaciones = [];

// Cuando un cliente se conecta
io.on('connection', (socket) => {
  console.log('Cliente conectado:', socket.id);
  
  // Enviar estado actual
  socket.emit('updateContador', contadores);
  
  // Escuchar evento de donación
  socket.on('donacion', (data) => {
    console.log('Donación recibida:', data);
    
    // Generar ID único
    const donacion = {
      ...data,
      id: Date.now().toString()
    };
    
    // Actualizar contadores
    if (donacion.contendienteId === 1) {
      contadores.contador1 += donacion.cantidad;
    } else {
      contadores.contador2 += donacion.cantidad;
    }
    
    // Guardar donación
    donaciones.push(donacion);
    
    // Emitir a todos los clientes
    io.emit('donacion', donacion);
    io.emit('updateContador', contadores);
  });
  
  // Escuchar solicitud de estado actual
  socket.on('getContadores', () => {
    socket.emit('updateContador', contadores);
  });
  
  // Escuchar activación de live
  socket.on('activarLive', (data) => {
    console.log('Live activado:', data);
    io.emit('liveActivado', data);
  });
  
  // Escuchar desactivación de live
  socket.on('desactivarLive', (data) => {
    console.log('Live desactivado:', data);
    io.emit('liveDesactivado', data);
  });
  
  // Escuchar desconexión
  socket.on('disconnect', () => {
    console.log('Cliente desconectado:', socket.id);
  });
});

// Ruta de prueba
app.get('/', (req, res) => {
  res.send('Servidor de Battle Live funcionando!');
});

// Puerto
const PORT = process.env.PORT || 3000;

server.listen(PORT, () => {
  console.log(`Servidor escuchando en el puerto ${PORT}`);
});
*/

/*
5. Inicia el servidor:
   ```
   node server.js
   ```

6. Para probar la conexión con el servidor, puedes usar la URL:
   http://localhost:3000

7. En la aplicación Flutter, asegúrate de que AppConfig().socketServerUrl
   esté configurado como 'http://TU_IP_LOCAL:3000' (reemplaza TU_IP_LOCAL
   con la IP de tu máquina en la red local para pruebas desde dispositivos
   físicos, o usa 10.0.2.2 para el emulador de Android, o localhost para web).

8. Para desarrollo y pruebas avanzadas, puedes considerar usar:
   - Postman para probar las emisiones de socket.io
   - socket.io-client-tool para ver eventos en tiempo real
*/
