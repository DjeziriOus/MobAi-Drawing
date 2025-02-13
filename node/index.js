const express = require("express");
const http = require("http");
const { Server } = require("socket.io");

const app = express();
const server = http.createServer(app);
const io = new Server(server);

const PORT = 3000;

// Middleware pour parser le JSON
app.use(express.json());

// Route principale
app.get("/", (req, res) => {
    res.send("Hello, Express avec Socket.IO!");
});

// Gestion des connexions Socket.IO
io.on("connection", (socket) => {
    console.log(`Un utilisateur connecté : ${socket.id}`);

    // Réception d'un message du client
    socket.on("message", (data) => {
        console.log(`Message reçu : ${data}`);
        io.emit("message", data); // Renvoie le message à tous les clients
    });

    socket.on("disconnect", () => {
        console.log(`Utilisateur déconnecté : ${socket.id}`);
    });
});

// Démarrer le serveur
server.listen(PORT, () => {
    console.log(`Serveur WebSocket démarré sur http://localhost:${PORT}`);
});
