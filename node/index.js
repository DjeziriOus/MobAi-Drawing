const express = require("express");
const http = require("http");
const { Server } = require("socket.io");
const cors = require("cors");
const mongoose = require("mongoose");

const Item = require("./models/Item");
const Prompt = require("./models/prompt");

const app = express();
const server = http.createServer(app);

mongoose.connect("mongodb://admin:secret@localhost:27017/mydb?authSource=admin", {
    useNewUrlParser: true,
    useUnifiedTopology: true,
})
.then(() => {console.log("✅ Connecté à MongoDB")
insertPrompts();})
.catch(err => console.error("❌ Erreur de connexion à MongoDB", err));


const promptsData = [
    
    { prompt: "Helicopter", action: "Medium" },
    { prompt: "Computer", action: "Hard" },
    { prompt: "Cat", action: "Easy" },
    { prompt: "Mountain", action: "Medium" },
    { prompt: "Robot", action: "Hard" },
    { prompt: "Sun", action: "Easy" },
    { prompt: "Airplane", action: "Medium" },
    { prompt: "Castle", action: "Hard" },
    { prompt: "Fish", action: "Easy" },
    { prompt: "Bicycle", action: "Medium" },
    { prompt: "Spaceship", action: "Hard" },
    { prompt: "Tree", action: "Easy" },
    { prompt: "Bridge", action: "Medium" },
    { prompt: "Dragon", action: "Hard" },
    { prompt: "Car", action: "Easy" },
    { prompt: "Train", action: "Medium" },
    { prompt: "Portrait", action: "Hard" },
    { prompt: "Apple", action: "Easy" },
    { prompt: "Clock", action: "Medium" },
    { prompt: "Eagle", action: "Hard" },
    { prompt: "House", action: "Easy" },
    { prompt: "Ship", action: "Medium" },
    { prompt: "Galaxy", action: "Hard" },
    { prompt: "Leaf", action: "Easy" },
    { prompt: "Guitar", action: "Medium" },
    { prompt: "Tiger", action: "Hard" },
    { prompt: "Candle", action: "Easy" },
    { prompt: "Windmill", action: "Medium" },
    { prompt: "Knight", action: "Hard" }
];

async function insertPrompts() {
    try {
        for (const promptData of promptsData) {
            await Prompt.updateOne(
                { prompt: promptData.prompt }, // Condition pour trouver un document existant
                { $set: promptData }, // Mise à jour ou insertion
                { upsert: true } // Insère si le document n'existe pas
            );
        }
        console.log("✅ Prompts insérés ou mis à jour avec succès !");
    
    } catch (error) {
        console.error("❌ Erreur lors de l'insertion :", error.message);
        mongoose.connection.close();
    }
}






// Ajout de CORS pour Express
app.use(cors({
    origin: "*",  
    methods: ["GET", "POST"],
    allowedHeaders: ["Content-Type"]
}));

// Ajout de CORS pour Socket.IO
const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

// Middleware JSON
app.use(express.json());

// Route principale
app.get("/", (req, res) => {
    res.send("Hello, Express avec Socket.IO!");
});

// Gestion des connexions Socket.IO
io.on("connection", (socket) => {
    console.log(`Un utilisateur connecté : ${socket.id}`);
    const id = socket.id;

    socket.on("send_data", async (data) => {
        console.log(`Message reçu : ${data}`);
        const { time, accuracy, action } = data;

        // Simulation de la réponse Flask
        

        let item = await Item.findOne({ id }); // Recherche dans la base de données
        console.log("hi")
        if (!item) {
            item = new Item({ id, level:0 }); // Crée un nouvel élément
            await item.save();
        }

        console.log(item)
        let level=item.level
        const response = { level:0, newActionction: "Medium" }; 

        console.log("Réponse simulée du serveur Flask:", response);
        let { newAction } = response;
        level=response.level
        // Ancienne requête vers Flask (désactivée)
        /*
        axios.post("http://localhost:5000/api/receive", data)
        .then(async (response) => {
        */

         
        await Item.findOneAndUpdate(
                { id },  // Condition pour trouver l'élément
                { level },  // Champs à mettre à jour
                { new: true } // Retourne l'élément mis à jour
            );
        

        console.log(action)
        const prompts = await Prompt.find({ newAction }).select("prompt -_id");
        console.log(prompts)
        const randomIndex = Math.floor(Math.random() * prompts.length);
        const responseData = { level, prompt: prompts[randomIndex] };

        io.emit("message", responseData);
        
        // Ancienne gestion d'erreur Axios (désactivée)
        /*
        })
        .catch(error => {
            console.error("Erreur lors de la requête:", error.message);
        });
        */
    }
    
);

    socket.on("play_vs_1",async(data)=>{
        let item = await Item.findOne({ id }); // Recherche dans la base de données
        console.log("hi")
        if (!item) {
            item = new Item({ id, level:0 }); // Crée un nouvel élément
            await item.save();
        }
        await Item.findOneAndUpdate(
            { id },  // Condition pour trouver l'élément
            { level },  // Champs à mettre à jour
            { new: true } // Retourne l'élément mis à jour
        );

        let item2= await Item.findOne({level,id: { $ne: id }} )
        
    })

    socket.on("disconnect", () => {
        console.log(`Utilisateur déconnecté : ${socket.id}`);
    });


});

// Démarrer le serveur
const PORT = 3000;
server.listen(PORT, () => {
    console.log(`Serveur WebSocket démarré sur http://localhost:${PORT}`);
});
