# ChoreBuddy — Aplicație mobilă pentru gestionarea sarcinilor casnice


## 1. Descriere

ChoreBuddy este o aplicație mobilă cross-platform dezvoltată cu Flutter, destinată gestionării și monitorizării sarcinilor casnice în cadrul unui household. 
Aplicația permite crearea de gospodării, invitarea membrilor prin cod unic, distribuirea sarcinilor, completarea acestora cu dovadă foto, liste de cumpărături cu recunoaștere vocală și recomandări AI personalizate bazate pe performanța fiecărui membru.

Tehnologii folosite:
- Flutter (client)
- Node.js + Express.js (server)
- MongoDB Atlas (baza de date)


## 2. Adresa repository-ului

https://github.com/cristinapetea/Licenta.git


## 3. Livrabile

- Aplicația mobilă Flutter, platforma Android 
- Cod sursă Dart/JavaScript:
  - client/lib/pages/     — ecranele aplicației: autentificare, home, taskuri grup, taskuri personale, ranking, recomandări
  - client/lib/           — configurare API (api.dart) și punctul de intrare (main.dart)
  - server/routers/       — rutele API: auth, tasks, households, performance, ai
  - server/controller/   — logica de business: autentificare, taskuri, gospodărie
  - server/model/         — modelele Mongoose: User, Task, Household
  - server/middleware/     — autentificare (authMiddleware) și upload fișiere (multer)
  - server/workers/        — Worker threads (calcul performanță)

     
## 4. Pași de compilare ai aplicației
       
Clonare repository:
- git clone https://github.com/cristinapetea/Licenta.git
- cd ChoreBuddy

Configurare fișier .env:
Creați un fișier `.env` în folderul `server/` cu următorul conținut:

PORT=3000
MONGO_URI=mongodb+srv://USER:PAROLA@cluster.mongodb.net/chorebuddy
GROQ_API_KEY=gsk_...        # din console.groq.com → API Keys
ANTHROPIC_API_KEY=sk-ant-... # din console.anthropic.com → API Keys
       
       
## 5. Pași de instalare și lansare ai aplicației
       
### Server:
```bash
cd server
npm install
npm run dev
```

### Client:
```bash
cd client
flutter pub get
flutter run
```
       
 