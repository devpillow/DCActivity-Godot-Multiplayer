const express = require('express');
const http = require('http');
const WebSocket = require('ws');

const dotenv = require('dotenv')
const axios = require('axios');
const path = require('path');
dotenv.config({ path: "../.env" });

const app = express();
// // Allow express to parse JSON bodies
app.use(express.json());

app.use(express.static(path.join(__dirname, 'public')));

const port = process.env.WSPORT;

const clientId = process.env.APPID;
const clientSecret = process.env.SECRET;

app.use((req, res, next) => {
    console.log(`\n========== 🔔 NEW REQUEST: ${new Date().toLocaleTimeString()} ==========`);
    console.log(`📦 Body Payload:`);
    if (Object.keys(req.body).length > 0) {
        console.log(JSON.stringify(req.body, null, 2)); // จัดรูปแบบให้อ่านง่าย
    } else {
        console.log("   (Empty Body)");
    }
    console.log(`======================================================\n`);

    next();
});


// -------------------------------------------------
// 🔑 ระบบ API สำหรับแลก Token
// -------------------------------------------------
app.post('/api/token', async (req, res) => {
    try {
        const code = req.body.code;
        if (!code) {
            return res.status(400).json({ error: "Missing code" });
        }
        console.log("/api/token (at server.js) , Code is : " + code)
        const params = new URLSearchParams({
            client_id: clientId,
            client_secret: clientSecret,
            grant_type: 'authorization_code',
            code: code,
        });
        const response = await axios.post('https://discord.com/api/oauth2/token', params.toString(), {
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
        });
        const data = await response.data;

        console.log("✅ [API] แลก Token สำเร็จ!");
        let access_token = data.access_token
        res.send({ access_token });
    }
    catch (error) {
        console.error("❌ [API] โค้ดพัง:", error.message);
        res.status(500).json({ error: "Internal Server Error", details: error.message });
    }
});

app.post('/api/users', (req, res) => {
    console.log("Express ได้รับ JSON:", req.body);
    //res.json({ message_: "รับข้อมูล JSON ผ่าน Express สำเร็จ!" });
    res.send({ message_: "อิ_อิ" })
});

// -------------------------------------------------
//  ระบบ WebSocket 
// -------------------------------------------------
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

wss.on('connection', (ws) => {
    console.log('Godot Client connected');
    ws.on('message', (data, isBinary) => {
        // โค้ด Broadcast เดิมของคุณใส่ตรงนี้ได้เลย
        wss.clients.forEach((client) => {
            if (client !== ws && client.readyState === WebSocket.OPEN) {
                client.send(data, { binary: isBinary });
            }
        });
    });
});

// เริ่มรัน Server
server.listen(port, () => {
    console.log("Server & API started on port 3000");
});
