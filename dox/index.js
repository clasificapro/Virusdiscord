const express = require('express');
const fs = require('fs');
const app = express();

app.use(express.json());

app.post('/api/log', (req, res) => {
    const data = req.body;
    
    // Formatear la fecha y hora actual
    const timestamp = new Date().toISOString();
    
    // Crear un texto estructurado con la información recibida
    const logEntry = `[${timestamp}] IP: ${data.ip} | User: ${data.username} (ID: ${data.userid}) | HWID: ${data.hwid} | Ubicación: ${data.city}, ${data.country}\n`;
    
    console.log("Nuevo registro recibido:\n", data);

    // Guardar el registro en un archivo de texto en la nube
    fs.appendFile('logs.txt', logEntry, (err) => {
        if (err) {
            console.err("Error al guardar el registro:", err);
        }
    });

    res.status(200).json({ status: "success", message: "Datos almacenados en la nube correctamente" });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Servidor de nube corriendo en el puerto ${PORT}`);
});